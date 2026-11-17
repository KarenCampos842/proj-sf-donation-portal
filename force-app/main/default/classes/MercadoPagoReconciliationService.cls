/**
 * PAY-08. Registers approved payments whose notice never arrived and whose donor never
 * returned to the portal, before PAY-07 deletes the attempt after 7 days.
 *
 * Used by MercadoPagoReconciliationBatch in two steps, so that every chunk of payments runs
 * in its own transaction with fresh limits:
 *  - findCandidates (batch start, callouts and queries, no writes):
 *     1. asks Mercado Pago for the approved payments of the last 7 days
 *        (GET /v1/payments/search, a few calls in total, no matter how many attempts exist);
 *     2. keeps the payments whose external_reference is an attempt that is still Started and
 *        was created more than 30 minutes ago (the webhook and the return page had their chance);
 *     3. leaves out payments that already have an "Amount_Mismatch" rejected notice, so the
 *        same notice is not logged again every hour;
 *     4. returns them oldest attempt first.
 *  - register (batch execute, writes only): runs the same Donation_Register flow used by the
 *    webhook and the return page. The payment id is unique, so a payment that was registered
 *    in the meantime is not registered twice (AC2).
 *
 * Amount, status and approval date always come from Mercado Pago. If Mercado Pago does not
 * answer, nothing changes and the next run tries again (AC4).
 *
 * Runs without sharing: it is started by the scheduled job and works on records that the
 * scheduling user may not see.
 */
public without sharing class MercadoPagoReconciliationService {
    @TestVisible
    private static final String SEARCH_ENDPOINT = 'callout:MercadoPagoAPI/v1/payments/search'
        + '?range=date_created&begin_date=NOW-7DAYS&end_date=NOW&status=approved'
        + '&sort=date_created&criteria=desc&limit=';
    @TestVisible
    private static final Integer PAGE_SIZE = 100;
    @TestVisible
    private static final Integer MAX_PAGES = 5;
    @TestVisible
    private static final Integer MIN_AGE_MINUTES = 30;
    private static final Integer TIMEOUT_MS = 20000;
    private static final String STATUS_APPROVED = 'approved';

    private static final String REASON_AMOUNT_MISMATCH = 'Amount_Mismatch';

    /**
     * What one run did. Kept across the chunks of the batch and written to the debug log.
     */
    public class Summary {
        public Integer paymentsRead = 0;
        public Integer candidates = 0;
        public Integer skippedMismatch = 0;
        public Integer registered = 0;
        public Integer alreadyRegistered = 0;
        public Integer notRegistered = 0;
        public Boolean providerFailed = false;

        public override String toString() {
            return 'Conciliación Mercado Pago: pagos aprobados leídos=' + paymentsRead
                + ', intentos sin registrar=' + candidates + ', omitidos por monto=' + skippedMismatch
                + ', registrados=' + registered + ', ya registrados=' + alreadyRegistered
                + ', no registrados=' + notRegistered
                + (providerFailed ? ', Mercado Pago no respondió' : '');
        }
    }

    /**
     * Step 1 (no writes): the approved payments that still have to be registered, oldest attempt first.
     * @param summary counters of this run
     * @return payments to register; empty when Mercado Pago did not answer
     */
    public static List<MercadoPagoPaymentLookupAction.Result> findCandidates(Summary summary) {
        List<MercadoPagoPaymentLookupAction.Result> candidates = new List<MercadoPagoPaymentLookupAction.Result>();
        List<MercadoPagoPaymentLookupAction.Result> approved = readApprovedPayments(summary);
        if (summary.providerFailed || approved.isEmpty()) {
            return candidates;
        }

        Map<Id, MercadoPagoPaymentLookupAction.Result> byAttempt = new Map<Id, MercadoPagoPaymentLookupAction.Result>();
        for (MercadoPagoPaymentLookupAction.Result payment : approved) {
            Id attemptId = toId(payment.externalReference);
            if (attemptId != null && !byAttempt.containsKey(attemptId)) {
                byAttempt.put(attemptId, payment);
            }
        }

        Set<String> mismatched = paymentsWithAmountMismatch(byAttempt.values());
        DateTime createdBefore = DateTime.now().addMinutes(-MIN_AGE_MINUTES);
        Set<Id> attemptIds = byAttempt.keySet();
        for (Payment_Attempt__c attempt : [
            SELECT Id FROM Payment_Attempt__c
            WHERE Id IN :attemptIds AND Status__c = 'Started' AND CreatedDate <= :createdBefore
            WITH SYSTEM_MODE
            ORDER BY CreatedDate ASC
        ]) {
            MercadoPagoPaymentLookupAction.Result payment = byAttempt.get(attempt.Id);
            if (mismatched.contains(payment.paymentId)) {
                summary.skippedMismatch++;
            } else {
                candidates.add(payment);
            }
        }
        summary.candidates = candidates.size();
        return candidates;
    }

    // Payment ids that were already logged as "Amount_Mismatch": registering them again would
    // only log the same rejected notice every hour.
    private static Set<String> paymentsWithAmountMismatch(List<MercadoPagoPaymentLookupAction.Result> payments) {
        Set<String> paymentIds = new Set<String>();
        for (MercadoPagoPaymentLookupAction.Result payment : payments) {
            paymentIds.add(payment.paymentId);
        }
        Set<String> mismatched = new Set<String>();
        for (Rejected_Notice__c notice : [
            SELECT Technical_Id__c FROM Rejected_Notice__c
            WHERE Reason__c = :REASON_AMOUNT_MISMATCH AND Technical_Id__c IN :paymentIds
            WITH SYSTEM_MODE
        ]) {
            mismatched.add(notice.Technical_Id__c);
        }
        return mismatched;
    }

    // Callouts only: reads up to MAX_PAGES pages of approved payments.
    private static List<MercadoPagoPaymentLookupAction.Result> readApprovedPayments(Summary summary) {
        List<MercadoPagoPaymentLookupAction.Result> payments = new List<MercadoPagoPaymentLookupAction.Result>();
        for (Integer page = 0; page < MAX_PAGES; page++) {
            List<Object> results = searchPage(page * PAGE_SIZE);
            if (results == null) {
                summary.providerFailed = true;
                return new List<MercadoPagoPaymentLookupAction.Result>();
            }
            for (Object item : results) {
                if (!(item instanceof Map<String, Object>)) {
                    continue;
                }
                MercadoPagoPaymentLookupAction.Result payment =
                    MercadoPagoPaymentLookupAction.fromPayment((Map<String, Object>) item);
                summary.paymentsRead++;
                if (payment.found && payment.status == STATUS_APPROVED) {
                    payments.add(payment);
                }
            }
            if (results.size() < PAGE_SIZE) {
                break;
            }
        }
        return payments;
    }

    // Returns the "results" list of one page, or null when Mercado Pago did not answer well.
    private static List<Object> searchPage(Integer offset) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(SEARCH_ENDPOINT + PAGE_SIZE + '&offset=' + offset);
        request.setMethod('GET');
        request.setTimeout(TIMEOUT_MS);
        try {
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() != 200) {
                return null;
            }
            Object results = ((Map<String, Object>) JSON.deserializeUntyped(response.getBody())).get('results');
            return results instanceof List<Object> ? (List<Object>) results : null;
        } catch (CalloutException e) {
            return null;
        } catch (JSONException e) {
            return null;
        } catch (TypeException e) {
            return null;
        }
    }

    /**
     * Step 2 (writes only): registers one payment. A failure is rolled back and does not stop the others.
     * @param payment approved payment returned by findCandidates
     * @param summary counters of this run
     */
    public static void register(MercadoPagoPaymentLookupAction.Result payment, Summary summary) {
        Savepoint beforeRegister = Database.setSavepoint();
        String outcome;
        try {
            Flow.Interview interview = Flow.Interview.createInterview('Donation_Register', new Map<String, Object>{
                'attemptId' => payment.externalReference,
                'providerPaymentId' => payment.paymentId,
                'paymentStatus' => payment.status,
                'confirmedAmount' => payment.transactionAmount,
                'approvedAt' => payment.dateApproved
            });
            interview.start();
            outcome = (String) interview.getVariableValue('outcome');
        } catch (Exception e) {
            Database.rollback(beforeRegister);
            summary.notRegistered++;
            return;
        }

        switch on outcome {
            when 'Registered' {
                summary.registered++;
            }
            when 'AlreadyProcessed' {
                summary.alreadyRegistered++;
            }
            when 'Error' {
                Database.rollback(beforeRegister);
                summary.notRegistered++;
            }
            when else {
                // AmountMismatch and AttemptNotFound are logged by the flow (ADM-12).
                summary.notRegistered++;
            }
        }
    }

    private static Id toId(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        try {
            Id candidate = Id.valueOf(value);
            return candidate.getSobjectType() == Payment_Attempt__c.SObjectType ? candidate : null;
        } catch (StringException e) {
            return null;
        }
    }
}
