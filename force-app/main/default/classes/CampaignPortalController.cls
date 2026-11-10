/**
 * Public read access to campaigns for the donation portal (DON-01, DON-02, DON-03).
 *
 * Security: the class is `with sharing` and every query uses WITH USER_MODE, so the guest
 * user only gets the records its sharing rule shares and the fields its permissions allow.
 * On top of that, eligibility (status and dates) is decided here on the server and is never
 * left to the interface, because the guest sharing rule can only filter by Status__c
 * (docs/data-model.md, section 6.2): an Active campaign with a future start date is shared
 * but must not be exposed.
 *
 * Results are not cacheable on purpose: progress must include a donation as soon as the
 * portal is reloaded (DON-03).
 *
 * TEMPORARY WORKAROUND (DON-02, closed campaigns). The guest sharing rule documented in the
 * data model only shares Active and Paused campaigns, and Workstream C has not extended it to
 * Closed. Until it does, Closed campaigns are read through the isolated inner class
 * ClosedCampaignReader. See findConsultableCampaign for the scope and how to remove it.
 */
public with sharing class CampaignPortalController {
    public static final String STATUS_ACTIVE = 'Active';
    public static final String STATUS_PAUSED = 'Paused';
    public static final String STATUS_CLOSED = 'Closed';

    public static final String AVAILABILITY_OPEN = 'OPEN';
    public static final String AVAILABILITY_PAUSED = 'PAUSED';
    public static final String AVAILABILITY_CLOSED = 'CLOSED';
    public static final String AVAILABILITY_ENDED = 'ENDED';

    @TestVisible
    private static final String MSG_LOAD_ERROR = 'No pudimos cargar las campañas. Intenta de nuevo en unos momentos.';
    @TestVisible
    private static final String MSG_DETAIL_ERROR = 'No pudimos cargar la campaña. Intenta de nuevo en unos momentos.';

    private static final Integer MAX_CAMPAIGNS = 100;
    private static final List<String> SHARED_DETAIL_STATUSES = new List<String>{ STATUS_ACTIVE, STATUS_PAUSED };
    private static final Pattern HTTPS_URL = Pattern.compile('(?i)^https://[^\\s<>"\']+$');

    /**
     * Campaigns for the main catalog: Active campaigns inside their dates and Paused campaigns
     * that already started. Draft, Closed, future and expired Active campaigns are excluded.
     * Open campaigns come first, then paused ones.
     *
     * @return public campaign data, without the long description
     * @throws AuraHandledException when the campaigns cannot be read
     * @example
     * List<CampaignDTO> campaigns = CampaignPortalController.getAvailableCampaigns();
     */
    @AuraEnabled
    public static List<CampaignDTO> getAvailableCampaigns() {
        Date today = Date.today();
        List<Fundraising_Campaign__c> records;
        try {
            records = [
                SELECT
                    Id,
                    Name,
                    Goal__c,
                    Start_Date__c,
                    End_Date__c,
                    Status__c,
                    Is_General__c,
                    Image_URL__c,
                    Image_Alt_Text__c,
                    Total_Raised__c,
                    Donation_Count__c,
                    Progress_Percent__c,
                    Accepts_Donations__c
                FROM Fundraising_Campaign__c
                WHERE
                    Start_Date__c <= :today
                    AND (
                        (Status__c = :STATUS_ACTIVE AND (End_Date__c = NULL OR End_Date__c >= :today))
                        OR Status__c = :STATUS_PAUSED
                    )
                WITH USER_MODE
                ORDER BY Name
                LIMIT :MAX_CAMPAIGNS
            ];
        } catch (QueryException e) {
            throw userFacingError(MSG_LOAD_ERROR);
        }

        List<CampaignDTO> openCampaigns = new List<CampaignDTO>();
        List<CampaignDTO> pausedCampaigns = new List<CampaignDTO>();
        for (Fundraising_Campaign__c record : records) {
            CampaignDTO dto = toDto(record, today, false);
            if (dto.availability == AVAILABILITY_PAUSED) {
                pausedCampaigns.add(dto);
            } else {
                openCampaigns.add(dto);
            }
        }
        openCampaigns.addAll(pausedCampaigns);
        return openCampaigns;
    }

    /**
     * Detail of one campaign (DON-02). Active and Paused campaigns that already started can be
     * read, and Closed campaigns can be read by a direct link whatever their start date.
     * Draft campaigns, Active or Paused campaigns that have not started, unknown Ids and
     * malformed Ids return null, so the response never reveals whether a hidden campaign exists.
     * The campaign can never be donated to unless it is open (see CampaignDTO.canDonate).
     *
     * WORKAROUND (temporary): Closed campaigns are not shared with the guest user yet, so they
     * are read by ClosedCampaignReader, a `without sharing` inner class that is limited to
     * Status__c = Closed and still enforces object and field permissions. Remove it when
     * Workstream C extends the guest sharing rule to Status__c = Closed (see findConsultableCampaign).
     *
     * @param campaignId Id of the campaign, as text (it usually comes from the URL)
     * @return the campaign, or null when it is not publicly consultable
     * @throws AuraHandledException when the campaign cannot be read
     * @example
     * CampaignDTO detail = CampaignPortalController.getCampaignDetail(campaignId);
     */
    @AuraEnabled
    public static CampaignDTO getCampaignDetail(String campaignId) {
        Id parsedId = toCampaignId(campaignId);
        if (parsedId == null) {
            return null;
        }
        try {
            Fundraising_Campaign__c record = findConsultableCampaign(parsedId);
            return record == null ? null : toDto(record, Date.today(), true);
        } catch (QueryException e) {
            throw userFacingError(MSG_DETAIL_ERROR);
        }
    }

    /**
     * Reads a campaign only if it is publicly consultable. It is shared by the campaign detail
     * (DON-02) and by the eligibility check of the donor recognition (DON-04), so both apply
     * the same rule:
     *   - Active and Paused: only after their start date. Read in user mode under this class'
     *     sharing, so the guest sharing rule still applies.
     *   - Closed: always, whatever the start date (DON-02 sets no date condition).
     *   - Draft: never.
     *
     * WORKAROUND (temporary, DON-02 and DON-04 for Closed campaigns): the guest sharing rule
     * does not share Closed campaigns yet, so they are read through ClosedCampaignReader, which
     * is `without sharing`. The elevation is limited to Status__c = Closed records, selects only
     * the public fields and enforces object and field permissions. TO REMOVE: when Workstream C
     * adds Closed to the guest sharing rule, delete ClosedCampaignReader and read Closed
     * campaigns in the first query with WITH USER_MODE.
     *
     * @param campaignId Id of a Fundraising_Campaign__c
     * @return the campaign with its public fields, or null when it is not consultable
     */
    public static Fundraising_Campaign__c findConsultableCampaign(Id campaignId) {
        Date today = Date.today();
        List<Fundraising_Campaign__c> records = [
            SELECT
                Id,
                Name,
                Description__c,
                Goal__c,
                Start_Date__c,
                End_Date__c,
                Status__c,
                Is_General__c,
                Image_URL__c,
                Image_Alt_Text__c,
                Total_Raised__c,
                Donation_Count__c,
                Progress_Percent__c,
                Accepts_Donations__c
            FROM Fundraising_Campaign__c
            WHERE Id = :campaignId AND Start_Date__c <= :today AND Status__c IN :SHARED_DETAIL_STATUSES
            WITH USER_MODE
            LIMIT 1
        ];
        return records.isEmpty() ? new ClosedCampaignReader().find(campaignId) : records[0];
    }

    /**
     * Converts text into the Id of a campaign.
     *
     * @param rawId text that should contain a Fundraising_Campaign__c Id
     * @return the Id, or null when the text is blank, malformed or belongs to another object
     */
    public static Id toCampaignId(String rawId) {
        if (String.isBlank(rawId)) {
            return null;
        }
        try {
            Id parsedId = Id.valueOf(rawId.trim());
            return parsedId.getSObjectType() == Fundraising_Campaign__c.SObjectType ? parsedId : null;
        } catch (StringException e) {
            return null;
        }
    }

    /**
     * Builds an exception whose message reaches the browser as is. AuraHandledException hides
     * its message unless it is set explicitly.
     *
     * @param message Spanish text that is safe to show to the visitor
     * @return the exception to throw
     */
    public static AuraHandledException userFacingError(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }

    @TestVisible
    private static String resolveAvailability(Fundraising_Campaign__c record, Date today) {
        String availability;
        switch on record.Status__c {
            when 'Paused' {
                availability = AVAILABILITY_PAUSED;
            }
            when 'Closed' {
                availability = AVAILABILITY_CLOSED;
            }
            when else {
                availability = record.End_Date__c != null && record.End_Date__c < today
                    ? AVAILABILITY_ENDED
                    : AVAILABILITY_OPEN;
            }
        }
        return availability;
    }

    private static CampaignDTO toDto(Fundraising_Campaign__c record, Date today, Boolean includeDescription) {
        CampaignDTO dto = new CampaignDTO();
        dto.id = record.Id;
        dto.name = record.Name;
        dto.description = includeDescription ? record.Description__c : null;
        dto.imageUrl = sanitizeImageUrl(record.Image_URL__c);
        dto.imageAltText = String.isBlank(record.Image_Alt_Text__c) ? null : record.Image_Alt_Text__c;
        dto.goal = record.Goal__c;
        dto.totalRaised = record.Total_Raised__c ?? 0;
        dto.donationCount = (record.Donation_Count__c ?? 0).intValue();
        dto.progressPercent = record.Progress_Percent__c ?? 0;
        dto.startDate = record.Start_Date__c;
        dto.endDate = record.End_Date__c;
        dto.status = record.Status__c;
        dto.availability = resolveAvailability(record, today);
        dto.canDonate = dto.availability == AVAILABILITY_OPEN && record.Accepts_Donations__c == true;
        dto.isGeneral = record.Is_General__c == true;
        return dto;
    }

    /**
     * TEMPORARY WORKAROUND, isolated on purpose. Reads one Closed campaign by Id ignoring record
     * sharing, because the guest sharing rule does not cover Closed campaigns yet. The class
     * keyword removes only the sharing check. The query has no access-level clause on purpose:
     * from API 67.0 a query in a `without sharing` class still enforces object and field
     * permissions (covered by ClosedCampaignReader tests). The filter is limited to
     * Status__c = Closed and only the public campaign fields are selected. It never touches
     * Donation__c or Payment_Attempt__c.
     * Delete this class when Workstream C shares Closed campaigns with the guest user.
     */
    @TestVisible
    private without sharing class ClosedCampaignReader {
        @TestVisible
        private Fundraising_Campaign__c find(Id campaignId) {
            List<Fundraising_Campaign__c> records = [
                SELECT
                    Id,
                    Name,
                    Description__c,
                    Goal__c,
                    Start_Date__c,
                    End_Date__c,
                    Status__c,
                    Is_General__c,
                    Image_URL__c,
                    Image_Alt_Text__c,
                    Total_Raised__c,
                    Donation_Count__c,
                    Progress_Percent__c,
                    Accepts_Donations__c
                FROM Fundraising_Campaign__c
                WHERE Id = :campaignId AND Status__c = :STATUS_CLOSED
                LIMIT 1
            ];
            return records.isEmpty() ? null : records[0];
        }
    }

    private static String sanitizeImageUrl(String rawUrl) {
        if (String.isBlank(rawUrl)) {
            return null;
        }
        String trimmed = rawUrl.trim();
        return HTTPS_URL.matcher(trimmed).matches() ? trimmed : null;
    }
}
