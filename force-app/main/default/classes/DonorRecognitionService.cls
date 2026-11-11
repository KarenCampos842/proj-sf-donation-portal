/**
 * Public donor recognition for a campaign (DON-04).
 *
 * SECURITY EXCEPTION (deliberate and narrow). The guest user has no access to Donation__c
 * (docs/data-model.md, section 6.2; docs/security.md, section 2), so a user-mode query would
 * return nothing. This class is `without sharing` and runs ONE query WITH SYSTEM_MODE. The
 * elevated access is limited by these controls:
 *   1. The campaign is first checked through CampaignPortalController.findConsultableCampaign,
 *      the same eligibility as the campaign detail: Active and Paused campaigns only after
 *      they start (read with sharing, in user mode) and Closed campaigns whatever their start
 *      date (temporary workaround documented there). If the campaign cannot be consulted
 *      (Draft, not started, unknown or malformed Id), nothing is queried and the list is empty.
 *   2. The query is bound to that single campaign Id.
 *   3. It only returns donations with Payment_Status__c = Confirmed and Visibility__c = Public,
 *      so anonymous donations and payment attempts never appear.
 *   4. It selects only Public_Name__c, Amount__c and Confirmed_At__c (the last one only to sort).
 *   5. The response is a DonorRecognitionDTO with the name and the amount, never the SObject.
 *      Email, tax data and internal Ids are neither selected nor returned.
 *   6. The result is bounded by MAX_ROWS.
 *
 * The public name is returned as plain text. The interface must render it as text and never
 * as HTML.
 */
public without sharing class DonorRecognitionService {
    @TestVisible
    private static final String MSG_LOAD_ERROR = 'No pudimos cargar el reconocimiento de donantes. Intenta de nuevo en unos momentos.';

    private static final String PAYMENT_STATUS_CONFIRMED = 'Confirmed';
    private static final String VISIBILITY_PUBLIC = 'Public';
    private static final Integer MAX_ROWS = 200;

    /**
     * Public donors of a campaign, newest confirmation first.
     *
     * @param campaignId Id of the campaign, as text
     * @return name and amount of each public confirmed donation; empty when there are none or
     *         when the campaign is not publicly consultable
     * @throws AuraHandledException when the list cannot be read
     * @example
     * List<DonorRecognitionDTO> donors = DonorRecognitionService.getDonorRecognition(campaignId);
     */
    @AuraEnabled
    public static List<DonorRecognitionDTO> getDonorRecognition(String campaignId) {
        List<DonorRecognitionDTO> donors = new List<DonorRecognitionDTO>();
        Id parsedId = CampaignPortalController.toCampaignId(campaignId);
        if (parsedId == null) {
            return donors;
        }
        try {
            if (CampaignPortalController.findConsultableCampaign(parsedId) == null) {
                return donors;
            }
            for (Donation__c donation : queryPublicDonations(parsedId)) {
                String publicName = donation.Public_Name__c?.normalizeSpace();
                if (String.isNotBlank(publicName)) {
                    donors.add(new DonorRecognitionDTO(publicName, donation.Amount__c));
                }
            }
        } catch (QueryException e) {
            throw CampaignPortalController.userFacingError(MSG_LOAD_ERROR);
        }
        return donors;
    }

    private static List<Donation__c> queryPublicDonations(Id campaignId) {
        return [
            SELECT Public_Name__c, Amount__c, Confirmed_At__c
            FROM Donation__c
            WHERE
                Campaign__c = :campaignId
                AND Payment_Status__c = :PAYMENT_STATUS_CONFIRMED
                AND Visibility__c = :VISIBILITY_PUBLIC
                AND Public_Name__c != NULL
            WITH SYSTEM_MODE
            ORDER BY Confirmed_At__c DESC NULLS LAST
            LIMIT :MAX_ROWS
        ];
    }
}
