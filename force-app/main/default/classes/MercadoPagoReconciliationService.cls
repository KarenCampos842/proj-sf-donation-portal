/**
 * PAY-08. Registers approved payments whose notice never arrived and whose donor never
 * returned to the portal, before PAY-07 deletes the attempt after 7 days.
 *
 * How it works:
 *  1. Asks Mercado Pago for the approved payments of the last 7 days
 *     (GET /v1/payments/search, a few calls in total, no matter how many attempts exist).
 *  2. Keeps the payments whose external_reference is an attempt that is still Started and
 *     was created more than 30 minutes ago (the webhook and the return page had their chance).
 *  3. Registers each one with the same Donation_Register flow used by the webhook and the
 *     return page. The payment id is unique, so a payment that was registered in the meantime
 *     is not registered twice (AC2).
 *
 * Amount, status and approval date always come from Mercado Pago. All callouts happen before
 * any write, as Salesforce requires. If Mercado Pago does not answer, nothing changes and the
 * next run tries again (AC4).
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

    /**
     * What one run did. Written to the debug log by the job.
     */
    public class Summary {
        public Integer paymentsRead = 0;
        public Integer candidates = 0;
        public Integer registered = 0;
        public Integer alreadyRegistered = 0;
        public Integer notRegistered = 0;
        public Boolean providerFailed = false;

        public override String toString() {
            return 'Conciliación Mercado Pago: pagos aprobados leídos=' + paymentsRead
                + ', intentos sin registrar=' + candidates + ', registrados=' + registered
                + ', ya registrados=' + alreadyRegistered + ', no registrados=' + notRegistered
                + (providerFailed ? ', Mercado Pago no respondió' : '');
        }
    }

    /**
     * Runs one reconciliation.
     * @return what was done
     */
    public static Summary run() {
        Summary summary = new Summary();
        List<MercadoPagoPaymentLookupAction.Result> approved = readApprovedPayments(summary);
        if (summary.providerFailed || approved.isEmpty()) {
            return summary;
        }

        Map<Id, MercadoPagoPaymentLookupAction.Result> byAttempt = new Map<Id, MercadoPagoPaymentLookupAction.Result>();
        for (MercadoPagoPaymentLookupAction.Result payment : approved) {
            Id attemptId = toId(payment.externalReference);
            if (attemptId != null && !byAttempt.containsKey(attemptId)) {
                byAttempt.put(attemptId, payment);
            }
        }

        DateTime createdBefore = DateTime.now().addMinutes(-MIN_AGE_MINUTES);
        Set<Id> attemptIds = byAttempt.keySet();
        List<Payment_Attempt__c> pending = [
            SELECT Id FROM Payment_Attempt__c
            WHERE Id IN :attemptIds AND Status__c = 'Started' AND CreatedDate <= :createdBefore
            WITH SYSTEM_MODE
        ];
        summary.candidates = pending.size();
        for (Payment_Attempt__c attempt : pending) {
            register(byAttempt.get(attempt.Id), summary);
        }
        return summary;
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

    // Writes only. One payment failing does not stop the others.
    private static void register(MercadoPagoPaymentLookupAction.Result payment, Summary summary) {
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
