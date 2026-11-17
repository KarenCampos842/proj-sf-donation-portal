/**
 * DON-18. The summary that the donor reviews before paying. It is built from the values saved in the
 * attempt, never from values that come back from the browser. It holds only what the donor needs to
 * review: no Id, no hash, no fiscal data and no internal field.
 */
public with sharing class DonationSummaryDTO {
    @AuraEnabled public String campaignName;
    /** Exact amount in MXN, as text with two decimals. */
    @AuraEnabled public String amount;
    @AuraEnabled public String email;
    /** Anonymous or Public. */
    @AuraEnabled public String visibility;
    /** The name that will be shown. Empty when the donation is anonymous. */
    @AuraEnabled public String publicName;
    /** Independent from the visibility: an anonymous donation can ask for an invoice. */
    @AuraEnabled public Boolean invoiceRequested;
}
