/**
 * DON-18. What the browser receives when a donation is started: only the access token of the new
 * attempt. It is shown once; the server keeps just its hash. It holds no Id and no personal data.
 */
public with sharing class DonationStartDTO {
    @AuraEnabled public String accessToken;

    /**
     * Wraps the token that is returned to the browser once.
     *
     * @param accessToken token created by DonationAccessToken.newToken
     */
    public DonationStartDTO(String accessToken) {
        this.accessToken = accessToken;
    }
}
