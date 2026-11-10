/**
 * Tests for CampaignPortalController: DON-01 (catalog), DON-02 (detail) and DON-03 (progress).
 * The catalog and detail tests run as a user that only has read access to the public campaign
 * fields, the closest simulation of the site guest that does not need the site to exist.
 */
@IsTest
private class CampaignPortalControllerTest {
    private static final String OPEN_WITH_END = 'Campaña abierta con cierre';
    private static final String OPEN_NO_END = 'Campaña abierta sin cierre';
    private static final String EXACT_GOAL = 'Campaña con meta exacta';
    private static final String GENERAL = 'Campaña general';
    private static final String PAUSED = 'Campaña pausada';
    private static final String FUTURE_ACTIVE = 'Campaña activa futura';
    private static final String DRAFT = 'Campaña en borrador';
    private static final String CLOSED = 'Campaña cerrada';
    private static final String ENDED_ACTIVE = 'Campaña activa vencida';
    private static final String CLOSED_FUTURE_START = 'Campaña cerrada con inicio futuro';
    private static final String PAUSED_FUTURE_START = 'Campaña pausada con inicio futuro';

    @TestSetup
    static void setupTestData() {
        PortalTestDataFactory.createSimulatedGuest();
        PortalTestDataFactory.createUserWithoutAccess();

        Date today = Date.today();
        Fundraising_Campaign__c exactGoal = PortalTestDataFactory.buildCampaign(EXACT_GOAL, 'Active', today.addDays(-5), null);
        exactGoal.Goal__c = 400;
        Fundraising_Campaign__c generalCampaign = PortalTestDataFactory.buildCampaign(GENERAL, 'Active', today.addDays(-100), null);
        generalCampaign.Is_General__c = true;
        Fundraising_Campaign__c closedCampaign = PortalTestDataFactory.buildCampaign(CLOSED, 'Closed', today.addDays(-60), today.addDays(-10));
        closedCampaign.Goal__c = 500;
        Fundraising_Campaign__c pausedCampaign = PortalTestDataFactory.buildCampaign(PAUSED, 'Paused', today.addDays(-10), today.addDays(30));
        pausedCampaign.Image_URL__c = null;
        pausedCampaign.Image_Alt_Text__c = null;
        PortalTestDataFactory.insertRecords(
            new List<Fundraising_Campaign__c>{
                PortalTestDataFactory.buildCampaign(OPEN_WITH_END, 'Active', today.addDays(-10), today.addDays(30)),
                PortalTestDataFactory.buildCampaign(OPEN_NO_END, 'Active', today.addDays(-5), null),
                exactGoal,
                generalCampaign,
                pausedCampaign,
                PortalTestDataFactory.buildCampaign(FUTURE_ACTIVE, 'Active', today.addDays(5), today.addDays(60)),
                PortalTestDataFactory.buildCampaign(DRAFT, 'Draft', today.addDays(-10), null),
                closedCampaign,
                PortalTestDataFactory.buildCampaign(ENDED_ACTIVE, 'Active', today.addDays(-30), today.addDays(-1)),
                PortalTestDataFactory.buildCampaign(CLOSED_FUTURE_START, 'Closed', today.addDays(10), today.addDays(20)),
                PortalTestDataFactory.buildCampaign(PAUSED_FUTURE_START, 'Paused', today.addDays(5), today.addDays(30))
            }
        );

        Datetime now = Datetime.now();
        PortalTestDataFactory.insertRecords(
            new List<SObject>{
                PortalTestDataFactory.buildDonation(idOf(OPEN_WITH_END), 300, 'Public', 'Ana López', now),
                PortalTestDataFactory.buildDonation(idOf(OPEN_WITH_END), 200, 'Anonymous', null, now),
                PortalTestDataFactory.buildPaymentAttempt(idOf(OPEN_WITH_END), 500),
                PortalTestDataFactory.buildDonation(idOf(EXACT_GOAL), 400, 'Anonymous', null, now),
                PortalTestDataFactory.buildDonation(idOf(CLOSED), 600, 'Public', 'Familia Pérez', now)
            }
        );
    }

    // DON-01: catalog

    @IsTest
    static void shouldListOpenCampaignsBeforePausedOnes_WhenGuestOpensCatalog() {
        List<CampaignDTO> campaigns = getCatalogAsGuest();

        Assert.areEqual(5, campaigns.size(), 'Four open campaigns and one paused campaign are available');
        Assert.areEqual(
            new Set<String>{ OPEN_WITH_END, OPEN_NO_END, EXACT_GOAL, GENERAL, PAUSED },
            namesOf(campaigns),
            'Only the campaigns that can be shown in the main catalog should be listed'
        );
        Assert.areEqual(PAUSED, campaigns[4].name, 'Paused campaigns should come after the open ones');
    }

    @IsTest
    static void shouldIncludeActiveCampaign_WhenItHasNoEndDate() {
        Assert.isTrue(namesOf(getCatalogAsGuest()).contains(OPEN_NO_END), 'A blank end date means the campaign stays open');
    }

    @IsTest
    static void shouldExcludeActiveCampaign_WhenStartDateIsInTheFuture() {
        Assert.isFalse(namesOf(getCatalogAsGuest()).contains(FUTURE_ACTIVE), 'A future campaign must not be listed');
    }

    @IsTest
    static void shouldExcludeDraftCampaign_WhenGuestOpensCatalog() {
        Assert.isFalse(namesOf(getCatalogAsGuest()).contains(DRAFT), 'A draft campaign must never be listed');
    }

    @IsTest
    static void shouldExcludeClosedCampaign_WhenGuestOpensCatalog() {
        Assert.isFalse(namesOf(getCatalogAsGuest()).contains(CLOSED), 'A closed campaign must not be in the main catalog');
    }

    @IsTest
    static void shouldExcludeClosedCampaignWithFutureStart_WhenGuestOpensCatalog() {
        Assert.isFalse(namesOf(getCatalogAsGuest()).contains(CLOSED_FUTURE_START), 'A closed campaign never appears in the catalog');
    }

    @IsTest
    static void shouldExcludePausedCampaign_WhenStartDateIsInTheFuture() {
        Assert.isFalse(namesOf(getCatalogAsGuest()).contains(PAUSED_FUTURE_START), 'A paused campaign is listed only after it starts');
    }

    @IsTest
    static void shouldExcludeActiveCampaign_WhenEndDateHasPassed() {
        Assert.isFalse(namesOf(getCatalogAsGuest()).contains(ENDED_ACTIVE), 'An expired active campaign is outside its dates');
    }

    @IsTest
    static void shouldMarkPausedCampaignAsNotDonatable_WhenListed() {
        CampaignDTO pausedDto = findByName(getCatalogAsGuest(), PAUSED);

        Assert.areEqual('PAUSED', pausedDto.availability, 'A paused campaign should be flagged as paused');
        Assert.isFalse(pausedDto.canDonate, 'A paused campaign must not allow donating');
    }

    @IsTest
    static void shouldMarkOpenCampaignAsDonatable_WhenListed() {
        CampaignDTO openDto = findByName(getCatalogAsGuest(), OPEN_WITH_END);

        Assert.areEqual('OPEN', openDto.availability, 'An active campaign inside its dates is open');
        Assert.isTrue(openDto.canDonate, 'An open campaign should allow donating');
    }

    @IsTest
    static void shouldKeepGeneralCampaignOpen_WhenListed() {
        CampaignDTO generalDto = findByName(getCatalogAsGuest(), GENERAL);

        Assert.isTrue(generalDto.isGeneral, 'The general campaign flag should be exposed');
        Assert.isTrue(generalDto.canDonate, 'The general campaign stays open while it is active');
    }

    @IsTest
    static void shouldNotIncludeDescription_WhenListingCampaigns() {
        Assert.isNull(findByName(getCatalogAsGuest(), OPEN_WITH_END).description, 'The catalog does not need the long description');
    }

    @IsTest
    static void shouldReturnEmptyList_WhenNoCampaignIsAvailable() {
        List<Fundraising_Campaign__c> all = [SELECT Id FROM Fundraising_Campaign__c WITH SYSTEM_MODE];
        for (Fundraising_Campaign__c campaign : all) {
            campaign.Status__c = 'Draft';
        }
        Database.update(all, AccessLevel.SYSTEM_MODE);

        List<CampaignDTO> campaigns = getCatalogAsGuest();

        Assert.isTrue(campaigns.isEmpty(), 'With no available campaigns the list is empty and the interface shows the empty state');
    }

    @IsTest
    static void shouldLimitCatalogSize_WhenThereAreManyCampaigns() {
        Date today = Date.today();
        List<Fundraising_Campaign__c> extra = new List<Fundraising_Campaign__c>();
        for (Integer i = 0; i < 110; i++) {
            extra.add(PortalTestDataFactory.buildCampaign('Campaña masiva ' + i, 'Active', today.addDays(-1), null));
        }
        PortalTestDataFactory.insertRecords(extra);

        Assert.areEqual(100, getCatalogAsGuest().size(), 'The catalog is bounded to 100 campaigns');
    }

    @IsTest
    static void shouldReturnImageOnlyWhenHttps_WhenListingCampaigns() {
        Fundraising_Campaign__c insecure = [
            SELECT Id
            FROM Fundraising_Campaign__c
            WHERE Name = :OPEN_NO_END
            WITH SYSTEM_MODE
        ];
        insecure.Image_URL__c = 'http://example.com/imagen-sin-https.png';
        Database.update(insecure, AccessLevel.SYSTEM_MODE);

        List<CampaignDTO> campaigns = getCatalogAsGuest();

        Assert.isNull(findByName(campaigns, OPEN_NO_END).imageUrl, 'A non-https image must not be returned');
        Assert.isTrue(findByName(campaigns, OPEN_WITH_END).imageUrl.startsWith('https://'), 'An https image is returned');
    }

    @IsTest
    static void shouldReturnNoImage_WhenCampaignHasNone() {
        CampaignDTO pausedDto = findByName(getCatalogAsGuest(), PAUSED);

        Assert.isNull(pausedDto.imageUrl, 'Without Image_URL__c there is no image URL');
        Assert.isNull(pausedDto.imageAltText, 'Without alt text the interface must supply its own');
    }

    @IsTest
    static void shouldThrowFriendlyError_WhenUserCannotReadCampaigns() {
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.NO_ACCESS_LAST_NAME)) {
            try {
                CampaignPortalController.getAvailableCampaigns();
                Assert.fail('Expected an AuraHandledException');
            } catch (AuraHandledException e) {
                Assert.areEqual(CampaignPortalController.MSG_LOAD_ERROR, e.getMessage(), 'The visitor sees a Spanish message');
            }
        }
    }

    // DON-02: detail

    @IsTest
    static void shouldReturnFullDetail_WhenCampaignIsActive() {
        CampaignDTO detail = getDetailAsGuest(idOf(OPEN_WITH_END));

        Assert.areEqual(OPEN_WITH_END, detail.name, 'Name');
        Assert.areEqual('Descripción de la campaña ' + OPEN_WITH_END, detail.description, 'The detail includes the full description');
        Assert.areEqual('Imagen de ' + OPEN_WITH_END, detail.imageAltText, 'Alt text');
        Assert.areEqual(1000, detail.goal, 'Goal');
        Assert.areEqual(Date.today().addDays(30), detail.endDate, 'End date');
        Assert.areEqual('OPEN', detail.availability, 'Availability');
        Assert.isTrue(detail.canDonate, 'An active campaign inside its dates allows donating');
    }

    @IsTest
    static void shouldReturnDetailWithoutDonation_WhenCampaignIsPaused() {
        CampaignDTO detail = getDetailAsGuest(idOf(PAUSED));

        Assert.isNotNull(detail, 'A paused campaign can be consulted');
        Assert.areEqual('PAUSED', detail.availability, 'Availability');
        Assert.isFalse(detail.canDonate, 'A paused campaign must not allow donating');
    }

    @IsTest
    static void shouldReturnDetailWithoutDonation_WhenCampaignIsClosedAndOpenedByDirectLink() {
        CampaignDTO detail = getDetailAsGuest(idOf(CLOSED));

        Assert.isNotNull(detail, 'A closed campaign can be consulted by its Id');
        Assert.areEqual('CLOSED', detail.availability, 'Availability');
        Assert.isFalse(detail.canDonate, 'A closed campaign must not allow donating');
    }

    @IsTest
    static void shouldReturnDetailWithoutDonation_WhenClosedCampaignStartsInTheFuture() {
        CampaignDTO detail = getDetailAsGuest(idOf(CLOSED_FUTURE_START));

        Assert.isNotNull(detail, 'DON-02 sets no start-date condition for closed campaigns');
        Assert.areEqual('CLOSED', detail.availability, 'Availability');
        Assert.isFalse(detail.canDonate, 'A closed campaign never allows donating');
    }

    @IsTest
    static void shouldEnforceObjectPermissions_WhenClosedCampaignReaderRunsWithoutSharing() {
        Id closedId = idOf(CLOSED);
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.NO_ACCESS_LAST_NAME)) {
            try {
                new CampaignPortalController.ClosedCampaignReader().find(closedId);
                Assert.fail('The workaround must skip sharing only, never object or field permissions');
            } catch (QueryException e) {
                Assert.isNotNull(e.getMessage(), 'A user without access to the object is rejected');
            }
        }
    }

    @IsTest
    static void shouldReturnClosedCampaignOnly_WhenClosedCampaignReaderIsUsed() {
        Id activeId = idOf(OPEN_WITH_END);
        Id closedId = idOf(CLOSED);
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            CampaignPortalController.ClosedCampaignReader reader = new CampaignPortalController.ClosedCampaignReader();

            Assert.isNotNull(reader.find(closedId), 'A closed campaign is returned');
            Assert.isNull(reader.find(activeId), 'The elevated read never returns a campaign that is not closed');
        }
    }

    @IsTest
    static void shouldReturnNull_WhenPausedCampaignStartsInTheFuture() {
        Assert.isNull(getDetailAsGuest(idOf(PAUSED_FUTURE_START)), 'A paused campaign follows the visibility rule: only after it starts');
    }

    @IsTest
    static void shouldReturnDetailWithoutDonation_WhenActiveCampaignEndDateHasPassed() {
        CampaignDTO detail = getDetailAsGuest(idOf(ENDED_ACTIVE));

        Assert.isNotNull(detail, 'An expired active campaign can still be consulted');
        Assert.areEqual('ENDED', detail.availability, 'It is shown as finished, not as paused or closed');
        Assert.areEqual('Active', detail.status, 'Salesforce still has it as Active');
        Assert.isFalse(detail.canDonate, 'An expired campaign must not allow donating even when it is still Active');
    }

    @IsTest
    static void shouldReturnNull_WhenCampaignIsDraft() {
        Assert.isNull(getDetailAsGuest(idOf(DRAFT)), 'A draft campaign is never accessible');
    }

    @IsTest
    static void shouldReturnNull_WhenActiveCampaignStartsInTheFuture() {
        Assert.isNull(getDetailAsGuest(idOf(FUTURE_ACTIVE)), 'A future campaign is not accessible before its start date');
    }

    @IsTest
    static void shouldReturnNull_WhenCampaignIdIsNotValid() {
        Assert.isNull(getDetailAsGuest(null), 'Null Id');
        Assert.isNull(getDetailAsGuest('   '), 'Blank Id');
        Assert.isNull(getDetailAsGuest('no-es-un-id'), 'Malformed Id');
        Assert.isNull(getDetailAsGuest(UserInfo.getUserId()), 'An Id of another object');
    }

    @IsTest
    static void shouldReturnNull_WhenCampaignDoesNotExist() {
        String missingId = Fundraising_Campaign__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix() + '000000000000';

        Assert.isNull(getDetailAsGuest(missingId), 'An unknown Id gives the same answer as a hidden campaign');
    }

    @IsTest
    static void shouldThrowFriendlyError_WhenUserCannotReadCampaignDetail() {
        String campaignId = idOf(OPEN_WITH_END);
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.NO_ACCESS_LAST_NAME)) {
            try {
                CampaignPortalController.getCampaignDetail(campaignId);
                Assert.fail('Expected an AuraHandledException');
            } catch (AuraHandledException e) {
                Assert.areEqual(CampaignPortalController.MSG_DETAIL_ERROR, e.getMessage(), 'The visitor sees a Spanish message');
            }
        }
    }

    // DON-03: progress

    @IsTest
    static void shouldReturnProgressBelowGoal_WhenCampaignHasConfirmedDonations() {
        CampaignDTO detail = getDetailAsGuest(idOf(OPEN_WITH_END));

        Assert.areEqual(500, detail.totalRaised, 'Total raised is the sum of confirmed donations');
        Assert.areEqual(50, detail.progressPercent, 'Progress is total raised over goal');
        Assert.areEqual(2, detail.donationCount, 'Donation count');
    }

    @IsTest
    static void shouldIncludeAnonymousDonations_WhenCalculatingProgress() {
        CampaignDTO detail = getDetailAsGuest(idOf(EXACT_GOAL));

        Assert.areEqual(400, detail.totalRaised, 'The only donation of this campaign is anonymous and still counts');
    }

    @IsTest
    static void shouldNotCountPaymentAttempts_WhenCalculatingProgress() {
        CampaignDTO detail = getDetailAsGuest(idOf(OPEN_WITH_END));

        Assert.areEqual(500, detail.totalRaised, 'The 500 MXN payment attempt must not be added to the 500 MXN confirmed');
    }

    @IsTest
    static void shouldReturnExactlyOneHundredPercent_WhenGoalIsReached() {
        CampaignDTO detail = getDetailAsGuest(idOf(EXACT_GOAL));

        Assert.areEqual(100, detail.progressPercent, 'Progress at the goal');
        Assert.isTrue(detail.canDonate, 'Reaching the goal does not close or disable a campaign');
    }

    @IsTest
    static void shouldReturnRealProgressAboveOneHundredPercent_WhenGoalIsExceeded() {
        CampaignDTO detail = getDetailAsGuest(idOf(CLOSED));

        Assert.areEqual(600, detail.totalRaised, 'Total raised');
        Assert.areEqual(120, detail.progressPercent, 'Progress is not capped at 100 %');
    }

    @IsTest
    static void shouldReturnZeroProgress_WhenCampaignHasNoDonations() {
        CampaignDTO detail = getDetailAsGuest(idOf(OPEN_NO_END));

        Assert.areEqual(0, detail.totalRaised, 'Total raised');
        Assert.areEqual(0, detail.progressPercent, 'Progress');
        Assert.areEqual(0, detail.donationCount, 'Donation count');
    }

    // Helpers and internal rules

    @IsTest
    static void shouldResolveAvailability_ForEachStatusAndDate() {
        Date today = Date.today();

        Assert.areEqual(
            'OPEN',
            CampaignPortalController.resolveAvailability(new Fundraising_Campaign__c(Status__c = 'Active', End_Date__c = today), today),
            'Active campaign that closes today is still open'
        );
        Assert.areEqual(
            'ENDED',
            CampaignPortalController.resolveAvailability(new Fundraising_Campaign__c(Status__c = 'Active', End_Date__c = today.addDays(-1)), today),
            'Active campaign past its end date'
        );
        Assert.areEqual(
            'PAUSED',
            CampaignPortalController.resolveAvailability(new Fundraising_Campaign__c(Status__c = 'Paused'), today),
            'Paused'
        );
        Assert.areEqual(
            'CLOSED',
            CampaignPortalController.resolveAvailability(new Fundraising_Campaign__c(Status__c = 'Closed'), today),
            'Closed'
        );
    }

    @IsTest
    static void shouldKeepMessage_WhenBuildingUserFacingError() {
        AuraHandledException error = CampaignPortalController.userFacingError('Mensaje de prueba');

        Assert.areEqual('Mensaje de prueba', error.getMessage(), 'The message must not be replaced by a generic one');
    }

    private static String idOf(String campaignName) {
        return [SELECT Id FROM Fundraising_Campaign__c WHERE Name = :campaignName WITH SYSTEM_MODE LIMIT 1].Id;
    }

    private static List<CampaignDTO> getCatalogAsGuest() {
        List<CampaignDTO> campaigns;
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            campaigns = CampaignPortalController.getAvailableCampaigns();
        }
        return campaigns;
    }

    private static CampaignDTO getDetailAsGuest(String campaignId) {
        CampaignDTO detail;
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            detail = CampaignPortalController.getCampaignDetail(campaignId);
        }
        return detail;
    }

    private static Set<String> namesOf(List<CampaignDTO> campaigns) {
        Set<String> names = new Set<String>();
        for (CampaignDTO campaign : campaigns) {
            names.add(campaign.name);
        }
        return names;
    }

    private static CampaignDTO findByName(List<CampaignDTO> campaigns, String name) {
        for (CampaignDTO campaign : campaigns) {
            if (campaign.name == name) {
                return campaign;
            }
        }
        Assert.fail('Campaign not found in the response: ' + name);
        return null;
    }
}
