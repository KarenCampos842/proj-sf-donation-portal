/**
 * Payment API for the public portal (LWC). Workstream A.
 *
 * Thin entry point: each method runs one flow, where the validation and the record
 * work live. The flows run in system mode, so the site guest user only needs access
 * to this class (and the Mercado Pago Callout permission set for the callouts); it
 * never gets permissions on Payment_Attempt__c or Donation__c.
 *
 * The LWC must call startDonation and openPayment as two separate calls: Salesforce
 * does not allow a callout after saving data in the same transaction.
 * Usage guide: docs/payments-api.md.
 */
public with sharing class DonationPaymentController {
    @TestVisible
    private static final String GENERIC_ERROR = 'No pudimos abrir el pago, intenta de nuevo';
    @TestVisible
    private static final String RESULT_UNKNOWN = 'Unknown';

    /**
     * What the donation form sends (data-model.md, section 11).
     */
    public class DonationRequest {
        @AuraEnabled
        public String campaignId { get; set; }
        @AuraEnabled
        public Decimal amount { get; set; }
        @AuraEnabled
        public String email { get; set; }
        @AuraEnabled
        public String visibility { get; set; }
        @AuraEnabled
        public String publicName { get; set; }
        @AuraEnabled
        public Boolean invoiceRequested { get; set; }
        @AuraEnabled
        public String legalName { get; set; }
        @AuraEnabled
        public String rfc { get; set; }
        @AuraEnabled
        public String taxPostalCode { get; set; }
        @AuraEnabled
        public String taxRegime { get; set; }
    }

    /**
     * Step 1. Validates the form data on the server and saves the payment attempt.
     * @param request form data
     * @return attempt Id, to pass to openPayment
     * @throws AuraHandledException with a Spanish message ready to show to the donor
     */
    @AuraEnabled
    public static String startDonation(DonationRequest request) {
        if (request == null) {
            throw userError('Faltan datos obligatorios de tu donación.');
        }
        Map<String, Object> inputs = new Map<String, Object>{
            'campaignId' => request.campaignId,
            'amount' => request.amount,
            'email' => request.email,
            'visibility' => request.visibility,
            'publicName' => request.publicName,
            'invoiceRequested' => request.invoiceRequested == true,
            'legalName' => request.legalName,
            'rfc' => request.rfc,
            'taxPostalCode' => request.taxPostalCode,
            'taxRegime' => request.taxRegime
        };
        Flow.Interview interview = run('Payment_Attempt_Create', inputs);
        String errorMessage = (String) interview.getVariableValue('errorMessage');
        if (String.isNotBlank(errorMessage)) {
            throw userError(errorMessage);
        }
        return (String) interview.getVariableValue('attemptId');
    }

    /**
     * Step 2. Opens the Mercado Pago payment for an attempt. Call it after startDonation
     * has returned, never in the same Apex call.
     * @param attemptId value returned by startDonation
     * @return Mercado Pago checkout URL to redirect the donor to
     * @throws AuraHandledException with a Spanish message ready to show to the donor
     */
    @AuraEnabled
    public static String openPayment(String attemptId) {
        Flow.Interview interview = run('Payment_Preference_Create',
            new Map<String, Object>{ 'attemptId' => attemptId });
        String errorMessage = (String) interview.getVariableValue('errorMessage');
        String checkoutUrl = (String) interview.getVariableValue('checkoutUrl');
        if (String.isNotBlank(errorMessage) || String.isBlank(checkoutUrl)) {
            throw userError(String.isNotBlank(errorMessage) ? errorMessage : GENERIC_ERROR);
        }
        return checkoutUrl;
    }

    /**
     * Thank-you page. Checks the real payment with Mercado Pago and registers the
     * donation if it was approved. Not cacheable: it can write records.
     * @param paymentId value of payment_id in the return URL (may be blank or "null")
     * @return Confirmed, Pending, Rejected, Cancelled, NoPayment or Unknown
     */
    @AuraEnabled
    public static String getPaymentResult(String paymentId) {
        try {
            Flow.Interview interview = run('Payment_Return_Process',
                new Map<String, Object>{ 'paymentId' => paymentId });
            String state = (String) interview.getVariableValue('resultState');
            return String.isBlank(state) ? RESULT_UNKNOWN : state;
        } catch (AuraHandledException e) {
            return RESULT_UNKNOWN;
        }
    }

    private static Flow.Interview run(String flowName, Map<String, Object> inputs) {
        Flow.Interview interview = Flow.Interview.createInterview(flowName, inputs);
        try {
            interview.start();
        } catch (FlowException e) {
            // Unexpected flow error: the transaction is rolled back; show a safe message.
            throw userError(GENERIC_ERROR);
        }
        return interview;
    }

    private static AuraHandledException userError(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}
