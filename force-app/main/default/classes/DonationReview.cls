/**
 * DON-18. The review step of a donation: summary, confirmation, edit and the permission to open the
 * payment. DonationIntakeService exposes these operations to the form and delegates to this class.
 *
 * Every operation starts from the access token that the server gave to the browser when the attempt was
 * created (DonationAccessToken). The token is checked first and only then is the attempt read or
 * changed, always through PaymentAttemptAccess. An Id sent by the browser, a hidden value or a variable
 * of the form is never an authorization.
 *
 * An attempt can be reviewed while all of this is true: its token matches, it is still Started, it was
 * not replaced by an edit, no payment was opened for it and the token has not expired. Any other case
 * gives the same message, so nobody learns whether a token ever existed.
 *
 * A donor who reloads the page loses the token and starts again from the form; that is expected.
 */
public with sharing class DonationReview {
    /**
     * How long a token works, counted from the creation of the attempt. It only has to cover the time
     * a donor takes to read the summary and confirm it. It is much shorter than the 7 days after which
     * PAY-07 deletes an attempt that was not confirmed, so a token can never outlive its attempt.
     */
    @TestVisible
    private static final Integer TOKEN_LIFETIME_MINUTES = 60;
    private static final String STATUS_STARTED = 'Started';
    private static final String VISIBILITY_PUBLIC = 'Public';

    @TestVisible
    private static final String MSG_NOT_AVAILABLE = 'Tu donación ya no está disponible. Edítala para volver a capturar tus datos.';
    @TestVisible
    private static final String MSG_NOT_CONFIRMED = 'Confirma el resumen de tu donación antes de continuar al pago.';

    /**
     * Creates the token of a new attempt and keeps its hash. Called right after the payment code of
     * Workstream A saved the attempt.
     *
     * @param attemptId Id returned by the payment code
     * @return the token, to hand to the browser once
     * @throws StringException when the text is not an Id, and DmlException when the hash cannot be saved
     */
    public static DonationStartDTO issueToken(String attemptId) {
        String token = DonationAccessToken.newToken();
        PaymentAttemptAccess.storeTokenHash(Id.valueOf(attemptId), DonationAccessToken.hashOf(token));
        return new DonationStartDTO(token);
    }

    /**
     * The summary of the donation, from the values saved in the server.
     *
     * @param token access token of the attempt
     * @return the summary to show to the donor
     * @throws AuraHandledException with a Spanish message when the token does not allow a review
     */
    public static DonationSummaryDTO summary(String token) {
        Payment_Attempt__c attempt = reviewableAttempt(token);
        DonationSummaryDTO summary = new DonationSummaryDTO();
        summary.campaignName = attempt.Campaign__r.Name;
        summary.amount = DonationAmountValidator.toExactText(attempt.Amount__c);
        summary.email = attempt.Email__c;
        summary.visibility = attempt.Visibility__c;
        summary.publicName = VISIBILITY_PUBLIC.equals(attempt.Visibility__c) ? attempt.Public_Name__c : null;
        summary.invoiceRequested = attempt.Invoice_Requested__c == true;
        return summary;
    }

    /**
     * Registers that the donor confirmed the summary, with the date and time of the server. Confirming
     * twice keeps the first date.
     *
     * @param token access token of the attempt
     * @throws AuraHandledException with a Spanish message when the token does not allow a review
     */
    public static void confirm(String token) {
        Payment_Attempt__c attempt = reviewableAttempt(token);
        if (attempt.Donor_Confirmed_At__c == null) {
            saveConfirmation(attempt.Id);
        }
    }

    /**
     * Tells which attempt may open its payment. It only reads: the callout to Mercado Pago must come in a
     * later transaction with no change pending (a callout after a DML is not allowed).
     *
     * @param token access token of the attempt
     * @return the Id of the attempt whose payment may be opened
     * @throws AuraHandledException when the token is not valid, the attempt is not reviewable or the donor
     * has not confirmed the summary
     */
    public static Id attemptToPay(String token) {
        Payment_Attempt__c attempt = reviewableAttempt(token);
        if (attempt.Donor_Confirmed_At__c == null) {
            throw failure(MSG_NOT_CONFIRMED);
        }
        return attempt.Id;
    }

    /**
     * The donor chose to edit: the token and the confirmation of the attempt stop working. Only an attempt
     * that can still be reviewed is changed. A token that is unknown, expired or of an attempt that already
     * opened a payment does nothing and gives no answer about why.
     *
     * @param token access token of the attempt
     */
    public static void invalidate(String token) {
        Payment_Attempt__c attempt = findAttempt(token);
        if (attempt == null || !canBeReviewed(attempt)) {
            return;
        }
        saveReplacement(attempt.Id);
    }

    private static Payment_Attempt__c reviewableAttempt(String token) {
        Payment_Attempt__c attempt = findAttempt(token);
        if (attempt == null || !canBeReviewed(attempt)) {
            throw failure(MSG_NOT_AVAILABLE);
        }
        return attempt;
    }

    private static Payment_Attempt__c findAttempt(String token) {
        return DonationAccessToken.isWellFormed(token)
            ? PaymentAttemptAccess.findByTokenHash(DonationAccessToken.hashOf(token))
            : null;
    }

    private static Boolean canBeReviewed(Payment_Attempt__c attempt) {
        Boolean notExpired = attempt.CreatedDate.addMinutes(TOKEN_LIFETIME_MINUTES) >= System.now();
        return attempt.Status__c == STATUS_STARTED &&
            attempt.Superseded_At__c == null &&
            String.isBlank(attempt.Preference_Id__c) &&
            notExpired;
    }

    // A failed save never shows the donor a technical message.
    @TestVisible
    private static void saveConfirmation(Id attemptId) {
        try {
            PaymentAttemptAccess.markConfirmed(attemptId, System.now());
        } catch (DmlException e) {
            throw failure(MSG_NOT_AVAILABLE);
        }
    }

    @TestVisible
    private static void saveReplacement(Id attemptId) {
        try {
            PaymentAttemptAccess.supersede(attemptId, System.now());
        } catch (DmlException e) {
            throw failure(MSG_NOT_AVAILABLE);
        }
    }

    private static AuraHandledException failure(String message) {
        // Same shape as the errors of DonationIntakeService: "<field>|<message>", with no field.
        return CampaignPortalController.userFacingError('|' + message);
    }
}
