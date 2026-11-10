/**
 * Public view of a Fundraising_Campaign__c for the donation portal (DON-01, DON-02, DON-03).
 *
 * Only the fields the model defines as public are exposed. It never carries donor data:
 * progress comes from the campaign roll-ups, not from individual donations.
 */
public with sharing class CampaignDTO {
    @AuraEnabled public Id id;
    @AuraEnabled public String name;
    /** Filled only in the detail view; the catalog does not need the long text. */
    @AuraEnabled public String description;
    /** Always an https URL, or null when the campaign has no valid image. */
    @AuraEnabled public String imageUrl;
    @AuraEnabled public String imageAltText;
    @AuraEnabled public Decimal goal;
    @AuraEnabled public Decimal totalRaised;
    @AuraEnabled public Integer donationCount;
    /** Real percentage (50 means 50 %). It is never capped at 100. */
    @AuraEnabled public Decimal progressPercent;
    @AuraEnabled public Date startDate;
    @AuraEnabled public Date endDate;
    /** Status__c API value: Active, Paused or Closed. */
    @AuraEnabled public String status;
    /** OPEN, PAUSED, CLOSED or ENDED (Active, but its end date has passed). */
    @AuraEnabled public String availability;
    /** True only when the server confirms the campaign accepts donations today. */
    @AuraEnabled public Boolean canDonate;
    @AuraEnabled public Boolean isGeneral;
}
