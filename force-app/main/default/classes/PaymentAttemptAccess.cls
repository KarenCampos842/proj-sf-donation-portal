/**
 * DON-18. The only class that reads and writes Payment_Attempt__c on behalf of an anonymous visitor.
 *
 * WHY WITHOUT SHARING. The guest user of the site has no permission on Payment_Attempt__c and no
 * record of it is shared with the guest. The queries and the updates of this class therefore need
 * both mechanisms: "without sharing" ignores the sharing of records, and WITH SYSTEM_MODE and
 * AccessLevel.SYSTEM_MODE ignore the permissions of object and fields. One does not replace the other.
 *
 * WHY IT IS SAFE. Every method works on one attempt that the caller has already proved to hold,
 * by its Id coming from the server or by the hash of its access token (DonationAccessToken). There is
 * no method that lists attempts or that looks one up by an Id sent by the browser. It reads only the
 * fields that the review needs, and it writes only the three fields of the access control. It is only
 * called from DonationReview, so it is not added to the profile of the guest user.
 *
 * It is the only "without sharing" class of this work; the other classes keep "with sharing".
 */
public without sharing class PaymentAttemptAccess {
    /**
     * Stores the hash of the token of a new attempt.
     *
     * @param attemptId attempt created by the payment code a moment ago
     * @param tokenHash SHA-256 hash of the token (never the token)
     */
    public static void storeTokenHash(Id attemptId, String tokenHash) {
        updateAttempt(new Payment_Attempt__c(Id = attemptId, Portal_Access_Token_Hash__c = tokenHash));
    }

    /**
     * Finds the attempt of a token. This is the only way to reach an attempt: the browser never sends an Id.
     *
     * @param tokenHash SHA-256 hash of the token that the browser sent
     * @return the attempt that the hash belongs to with the fields of the review, or null when there is none
     */
    public static Payment_Attempt__c findByTokenHash(String tokenHash) {
        List<Payment_Attempt__c> attempts = [
            SELECT
                Id, CreatedDate, Status__c, Amount__c, Email__c, Visibility__c, Public_Name__c,
                Invoice_Requested__c, Preference_Id__c, Donor_Confirmed_At__c, Superseded_At__c, Campaign__r.Name
            FROM Payment_Attempt__c
            WHERE Portal_Access_Token_Hash__c = :tokenHash
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        return attempts.isEmpty() ? null : attempts[0];
    }

    /**
     * Registers that the donor confirmed the summary.
     *
     * @param attemptId attempt found by findByTokenHash
     * @param confirmedAt date and time of the server
     */
    public static void markConfirmed(Id attemptId, Datetime confirmedAt) {
        updateAttempt(new Payment_Attempt__c(Id = attemptId, Donor_Confirmed_At__c = confirmedAt));
    }

    /**
     * Retires an attempt because the donor chose to edit the donation: its token stops working (the hash
     * is cleared) and the audit date is set. Status__c is not changed: PAY-07 deletes the attempt later.
     *
     * @param attemptId attempt found by findByTokenHash
     * @param supersededAt date and time of the server
     */
    public static void supersede(Id attemptId, Datetime supersededAt) {
        updateAttempt(new Payment_Attempt__c(Id = attemptId, Portal_Access_Token_Hash__c = null, Superseded_At__c = supersededAt));
    }

    private static void updateAttempt(Payment_Attempt__c changes) {
        Database.update(changes, AccessLevel.SYSTEM_MODE);
    }
}
