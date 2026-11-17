/**
 * Server side of the donation form (DON-08, DON-10, DON-11, DON-12). Workstream B.
 *
 * This class only validates and cleans what the form sends, then hands the data to the payment
 * code of Workstream A through a PaymentGateway. It never saves records and never makes
 * callouts itself, so there is no DML before a callout in the same transaction. The form must
 * call startDonation and openPayment as two separate Apex calls (docs/payments-api.md).
 *
 * PAYMENT CODE. The default gateway, DonationPaymentGateway, delegates to Workstream A's
 * DonationPaymentController (startDonation and openPayment). That controller runs the flows
 * Payment_Attempt_Create and Payment_Preference_Create in system mode, so the guest user needs no
 * permission on Payment_Attempt__c. docs/payments-api.md describes the contract.
 *
 * Every rule that the form checks in the browser is repeated here, because the browser can
 * never be trusted. Messages are in Spanish and safe to show to the donor.
 *
 * The public name is cleaned by PublicNameSanitizer before the payment code of Workstream A saves
 * it (DON-11). DonationPaymentController applies the same cleaning, because the guest user can call
 * it directly. The interface also shows names as text, never as HTML.
 */
public with sharing class DonationIntakeService {
    public static final String VISIBILITY_ANONYMOUS = 'Anonymous';
    public static final String VISIBILITY_PUBLIC = 'Public';

    // DON-17. Every error thrown by this class has the form "<field>|<message>". The field is the
    // data-field name used by the form (empty for errors that belong to no field). The form shows
    // only messages with this shape, so a platform or unexpected error never reaches the donor.
    @TestVisible
    private static final String ERROR_SEPARATOR = '|';
    @TestVisible
    private static final String FIELD_AMOUNT = 'amount';
    @TestVisible
    private static final String FIELD_EMAIL = 'email';
    @TestVisible
    private static final String FIELD_PUBLIC_NAME = 'publicName';
    @TestVisible
    private static final String FIELD_LEGAL_NAME = 'legalName';
    @TestVisible
    private static final String FIELD_RFC = 'rfc';
    @TestVisible
    private static final String FIELD_POSTAL_CODE = 'taxPostalCode';
    @TestVisible
    private static final String FIELD_REGIME = 'taxRegime';
    @TestVisible
    private static final String FIELD_PRIVACY_NOTICE = 'privacyNoticeAccepted';
    // What Salesforce puts in an AuraHandledException that was created without a message.
    private static final String PLATFORM_DEFAULT_MESSAGE = 'Script-thrown exception';

    @TestVisible
    private static final String MSG_MISSING_DATA = 'Faltan datos obligatorios de tu donación.';
    @TestVisible
    private static final String MSG_CAMPAIGN_CLOSED = 'Esta campaña ya no acepta donaciones.';
    @TestVisible
    private static final String MSG_AMOUNT_REQUIRED = 'Elige un monto para continuar.';
    @TestVisible
    private static final String MSG_AMOUNT_INVALID = 'El monto elegido no es válido.';
    @TestVisible
    private static final String MSG_EMAIL_INVALID = 'Escribe un correo válido.';
    @TestVisible
    private static final String MSG_VISIBILITY_INVALID = 'Elige si tu donación será anónima o pública.';
    @TestVisible
    private static final String MSG_PUBLIC_NAME_REQUIRED = 'Escribe el nombre con el que quieres aparecer.';
    @TestVisible
    private static final String MSG_PUBLIC_NAME_TOO_LONG = 'El nombre público no puede tener más de 80 caracteres.';
    @TestVisible
    private static final String MSG_INVOICE_DATA_MISSING = 'Para pedir factura faltan datos fiscales.';
    @TestVisible
    private static final String MSG_LEGAL_NAME_TOO_LONG = 'El nombre o razón social no puede tener más de 254 caracteres.';
    @TestVisible
    private static final String MSG_RFC_INVALID = 'El RFC no tiene un formato válido.';
    @TestVisible
    private static final String MSG_POSTAL_CODE_INVALID = 'El código postal debe tener 5 dígitos.';
    @TestVisible
    private static final String MSG_REGIME_INVALID = 'El régimen fiscal no es válido.';
    @TestVisible
    private static final String MSG_REGIME_MISMATCH = 'El régimen fiscal no corresponde al tipo de persona.';
    @TestVisible
    private static final String MSG_PRIVACY_NOTICE_REQUIRED = 'Acepta el aviso de privacidad para solicitar factura.';
    @TestVisible
    private static final String MSG_START_FAILED = 'No pudimos registrar tus datos, intenta de nuevo.';
    @TestVisible
    private static final String MSG_PAYMENT_FAILED = 'No pudimos abrir el pago, intenta de nuevo';

    // ADM-13: the suggested amounts come from the configuration (DonationAmountSettings), not from a fixed list.
    private static final Integer MAX_EMAIL_LENGTH = 80;
    private static final Integer MAX_LEGAL_NAME_LENGTH = 254;
    private static final Integer RFC_LENGTH_COMPANY = 12;

    private static final Pattern EMAIL_PATTERN = Pattern.compile('^[^@\\s]+@[^@\\s]+\\.[^@\\s]{2,}$');
    // Same pattern as the RFC_Format validation rule (docs/data-model.md, section 3). It checks
    // structure, month and day ranges; it does not check that the RFC exists or ask the SAT.
    private static final Pattern RFC_PATTERN = Pattern.compile(
        '^[A-ZÑ&]{3,4}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[A-Z0-9]{2}[0-9A]$'
    );
    private static final Pattern POSTAL_CODE_PATTERN = Pattern.compile('^[0-9]{5}$');

    // SAT c_RegimenFiscal codes by taxpayer type (docs/data-model.md, appendix). Pending
    // verification against the SAT Annex 20 (V-05).
    private static final Set<String> PERSON_REGIMES = new Set<String>{
        '605', '606', '607', '608', '610', '611', '612', '614', '615', '616', '621', '625', '626'
    };
    private static final Set<String> COMPANY_REGIMES = new Set<String>{
        '601', '603', '610', '620', '622', '623', '624', '626'
    };

    @TestVisible
    private static PaymentGateway gateway = new DonationPaymentGateway();

    /**
     * Bridge to the payment code of Workstream A. Implementations must not be called with data
     * that has not been validated by this class.
     */
    public interface PaymentGateway {
        /**
         * @param request validated and cleaned form data
         * @return Id of the saved payment attempt
         */
        String createAttempt(DonationFormInputDTO request);

        /**
         * @param attemptId Id returned by createAttempt
         * @return Mercado Pago checkout URL
         */
        String createCheckout(Id attemptId);
    }

    /**
     * What the donation form sends. The names are the Payment_Attempt__c field names in
     * camelCase without __c (docs/data-model.md, section 11).
     */
    public class DonationFormInputDTO {
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
        // DON-13. Only the acceptance comes from the browser; its date and time are set on the server.
        @AuraEnabled
        public Boolean privacyNoticeAccepted { get; set; }
    }

    /**
     * ADM-13. Suggested amounts and minimum amount of the current configuration, for the form.
     * Cacheable: the configuration changes rarely and holds no personal data.
     *
     * @return minimum amount and suggested amounts, in the order set by the administrator
     */
    @AuraEnabled(cacheable=true)
    public static DonationAmountSettings.Settings getAmountSettings() {
        return DonationAmountSettings.current();
    }

    /**
     * Step 1. Validates the form data and asks Workstream A to save the payment attempt. This is
     * where A's flow Payment_Attempt_Create runs, through DonationPaymentController. It does not
     * create a donation and does not call Mercado Pago.
     *
     * @param request form data
     * @return Id of the payment attempt, to pass to openPayment
     * @throws AuraHandledException with a Spanish message that is safe to show to the donor
     * @example
     * String attemptId = DonationIntakeService.startDonation(request);
     */
    @AuraEnabled
    public static String startDonation(DonationFormInputDTO request) {
        DonationFormInputDTO cleanRequest = validateAndClean(request);
        try {
            return gateway.createAttempt(cleanRequest);
        } catch (AuraHandledException e) {
            throw donorError(null, donorSafeMessage(e.getMessage(), MSG_START_FAILED));
        } catch (Exception e) {
            throw donorError(null, MSG_START_FAILED);
        }
    }

    /**
     * Step 2. Asks Workstream A to open the Mercado Pago payment of an attempt. This is where
     * A's flow Payment_Preference_Create makes the callout, through DonationPaymentController. Call
     * it only after startDonation has returned, as a separate Apex call.
     *
     * @param attemptId value returned by startDonation
     * @return Mercado Pago checkout URL (always https)
     * @throws AuraHandledException with a Spanish message that is safe to show to the donor
     * @example
     * String checkoutUrl = DonationIntakeService.openPayment(attemptId);
     */
    @AuraEnabled
    public static String openPayment(String attemptId) {
        Id parsedId = toAttemptId(attemptId);
        if (parsedId == null) {
            throw donorError(null, MSG_PAYMENT_FAILED);
        }
        String checkoutUrl;
        try {
            checkoutUrl = gateway.createCheckout(parsedId);
        } catch (AuraHandledException e) {
            throw donorError(null, donorSafeMessage(e.getMessage(), MSG_PAYMENT_FAILED));
        } catch (Exception e) {
            throw donorError(null, MSG_PAYMENT_FAILED);
        }
        if (String.isBlank(checkoutUrl) || !checkoutUrl.startsWithIgnoreCase('https://')) {
            throw donorError(null, MSG_PAYMENT_FAILED);
        }
        return checkoutUrl;
    }

    private static DonationFormInputDTO validateAndClean(DonationFormInputDTO request) {
        if (request == null) {
            throw donorError(null, MSG_MISSING_DATA);
        }
        DonationFormInputDTO clean = new DonationFormInputDTO();
        clean.campaignId = validateCampaign(request.campaignId);
        clean.amount = validateAmount(request.amount);
        clean.email = validateEmail(request.email);
        clean.visibility = validateVisibility(request.visibility);
        if (clean.visibility.equals(VISIBILITY_PUBLIC)) {
            clean.publicName = validatePublicName(request.publicName);
        }
        clean.invoiceRequested = request.invoiceRequested == true;
        clean.privacyNoticeAccepted = false;
        if (clean.invoiceRequested) {
            applyInvoiceData(request, clean);
        }
        return clean;
    }

    private static String validateCampaign(String rawCampaignId) {
        Id campaignId = CampaignPortalController.toCampaignId(rawCampaignId);
        if (campaignId == null) {
            throw donorError(null, MSG_CAMPAIGN_CLOSED);
        }
        Fundraising_Campaign__c campaign;
        try {
            campaign = CampaignPortalController.findConsultableCampaign(campaignId);
        } catch (QueryException e) {
            throw donorError(null, MSG_START_FAILED);
        }
        Boolean acceptsDonations =
            campaign != null &&
            campaign.Status__c == CampaignPortalController.STATUS_ACTIVE &&
            campaign.Accepts_Donations__c == true &&
            (campaign.End_Date__c == null || campaign.End_Date__c >= Date.today());
        if (!acceptsDonations) {
            throw donorError(null, MSG_CAMPAIGN_CLOSED);
        }
        return String.valueOf(campaignId);
    }

    private static Decimal validateAmount(Decimal amount) {
        if (amount == null) {
            throw donorError(FIELD_AMOUNT, MSG_AMOUNT_REQUIRED);
        }
        if (DonationAmountSettings.isSuggested(amount)) {
            return amount;
        }
        throw donorError(FIELD_AMOUNT, MSG_AMOUNT_INVALID);
    }

    private static String validateEmail(String rawEmail) {
        String email = rawEmail?.trim();
        if (String.isBlank(email) || email.length() > MAX_EMAIL_LENGTH || !EMAIL_PATTERN.matcher(email).matches()) {
            throw donorError(FIELD_EMAIL, MSG_EMAIL_INVALID);
        }
        return email;
    }

    // equals is case sensitive; == and != on Strings ignore case and would accept "PUBLIC".
    private static String validateVisibility(String visibility) {
        if (visibility == null || !(visibility.equals(VISIBILITY_ANONYMOUS) || visibility.equals(VISIBILITY_PUBLIC))) {
            throw donorError(null, MSG_VISIBILITY_INVALID);
        }
        return visibility;
    }

    private static String validatePublicName(String rawName) {
        if (PublicNameSanitizer.isTooLong(rawName)) {
            throw donorError(FIELD_PUBLIC_NAME, MSG_PUBLIC_NAME_TOO_LONG);
        }
        String name = PublicNameSanitizer.sanitize(rawName);
        if (String.isBlank(name)) {
            throw donorError(FIELD_PUBLIC_NAME, MSG_PUBLIC_NAME_REQUIRED);
        }
        return name;
    }

    private static void applyInvoiceData(DonationFormInputDTO request, DonationFormInputDTO clean) {
        String legalName = normalizeText(request.legalName);
        String rfc = request.rfc?.replaceAll('\\s+', '')?.toUpperCase();
        String postalCode = request.taxPostalCode?.trim();
        String regime = request.taxRegime?.trim();
        assertInvoiceFieldsPresent(legalName, rfc, postalCode, regime);
        assertInvoiceFormats(legalName, rfc, postalCode);
        assertRegimeMatches(regime, rfc);
        assertPrivacyNoticeAccepted(request.privacyNoticeAccepted);
        clean.privacyNoticeAccepted = true;
        clean.legalName = legalName;
        clean.rfc = rfc;
        clean.taxPostalCode = postalCode;
        clean.taxRegime = regime;
    }

    // The message is the one of Payment_Attempt__c; the field is the first fiscal field that is empty.
    private static void assertInvoiceFieldsPresent(String legalName, String rfc, String postalCode, String regime) {
        String missingField = String.isBlank(legalName)
            ? FIELD_LEGAL_NAME
            : String.isBlank(rfc) ? FIELD_RFC : String.isBlank(postalCode) ? FIELD_POSTAL_CODE : String.isBlank(regime) ? FIELD_REGIME : null;
        if (missingField != null) {
            throw donorError(missingField, MSG_INVOICE_DATA_MISSING);
        }
    }

    // DON-13. An invoice request without the acceptance never reaches the payment code.
    private static void assertPrivacyNoticeAccepted(Boolean accepted) {
        if (accepted != true) {
            throw donorError(FIELD_PRIVACY_NOTICE, MSG_PRIVACY_NOTICE_REQUIRED);
        }
    }

    private static void assertInvoiceFormats(String legalName, String rfc, String postalCode) {
        if (legalName.length() > MAX_LEGAL_NAME_LENGTH) {
            throw donorError(FIELD_LEGAL_NAME, MSG_LEGAL_NAME_TOO_LONG);
        }
        if (!RFC_PATTERN.matcher(rfc).matches()) {
            throw donorError(FIELD_RFC, MSG_RFC_INVALID);
        }
        if (!POSTAL_CODE_PATTERN.matcher(postalCode).matches()) {
            throw donorError(FIELD_POSTAL_CODE, MSG_POSTAL_CODE_INVALID);
        }
    }

    // The taxpayer type comes from the RFC length, like the Taxpayer_Type__c formula.
    private static void assertRegimeMatches(String regime, String rfc) {
        if (!PERSON_REGIMES.contains(regime) && !COMPANY_REGIMES.contains(regime)) {
            throw donorError(FIELD_REGIME, MSG_REGIME_INVALID);
        }
        Set<String> allowedRegimes = rfc.length() == RFC_LENGTH_COMPANY ? COMPANY_REGIMES : PERSON_REGIMES;
        if (!allowedRegimes.contains(regime)) {
            throw donorError(FIELD_REGIME, MSG_REGIME_MISMATCH);
        }
    }

    private static AuraHandledException donorError(String field, String message) {
        return CampaignPortalController.userFacingError((field == null ? '' : field) + ERROR_SEPARATOR + message);
    }

    // Workstream A throws AuraHandledExceptions with Spanish messages made for the donor. A blank
    // message, or the default one of the platform, is replaced by a safe text.
    private static String donorSafeMessage(String message, String fallback) {
        return String.isBlank(message) || message.equals(PLATFORM_DEFAULT_MESSAGE) ? fallback : message;
    }

    // Removes control characters and collapses spaces.
    private static String normalizeText(String value) {
        return value?.replaceAll('\\p{Cntrl}', ' ')?.normalizeSpace();
    }

    private static Id toAttemptId(String rawId) {
        if (String.isBlank(rawId)) {
            return null;
        }
        try {
            Id parsedId = Id.valueOf(rawId.trim());
            return parsedId.getSObjectType() == Payment_Attempt__c.SObjectType ? parsedId : null;
        } catch (StringException e) {
            return null;
        }
    }

    /**
     * Delegates to Workstream A's DonationPaymentController, which validates again and runs the
     * flows that save the payment attempt and open the Mercado Pago payment. Errors thrown by A are
     * AuraHandledExceptions with Spanish messages and reach the donor as they are.
     */
    @TestVisible
    private class DonationPaymentGateway implements PaymentGateway {
        public String createAttempt(DonationFormInputDTO request) {
            DonationPaymentController.DonationRequest paymentRequest = new DonationPaymentController.DonationRequest();
            paymentRequest.campaignId = request.campaignId;
            paymentRequest.amount = request.amount;
            paymentRequest.email = request.email;
            paymentRequest.visibility = request.visibility;
            paymentRequest.publicName = request.publicName;
            paymentRequest.invoiceRequested = request.invoiceRequested;
            paymentRequest.legalName = request.legalName;
            paymentRequest.rfc = request.rfc;
            paymentRequest.taxPostalCode = request.taxPostalCode;
            paymentRequest.taxRegime = request.taxRegime;
            paymentRequest.privacyNoticeAccepted = request.privacyNoticeAccepted;
            return DonationPaymentController.startDonation(paymentRequest);
        }

        public String createCheckout(Id attemptId) {
            return DonationPaymentController.openPayment(String.valueOf(attemptId));
        }
    }
}
