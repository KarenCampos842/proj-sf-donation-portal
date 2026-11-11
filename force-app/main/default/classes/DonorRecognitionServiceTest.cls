/**
 * Tests for DonorRecognitionService (DON-04). They run as a user that can read the public
 * campaign fields but has no access to Donation__c, like the site guest, to prove that the
 * explicit system-mode query is what makes the list work and that it stays narrow.
 */
@IsTest
private class DonorRecognitionServiceTest {
    private static final String WITH_DONORS = 'Campaña con donantes';
    private static final String ONLY_ANONYMOUS = 'Campaña solo con anónimos';
    private static final String OTHER = 'Otra campaña';
    private static final String CLOSED = 'Campaña cerrada con donantes';
    private static final String CLOSED_FUTURE_START = 'Campaña cerrada con inicio futuro y donantes';
    private static final String DRAFT = 'Campaña en borrador con donantes';
    private static final String FUTURE_ACTIVE = 'Campaña futura con donantes';
    private static final String SCRIPT_NAME = '<script>alert(1)</script>';
    private static final String HIDDEN_NAME = 'Nombre que no debe mostrarse';

    @TestSetup
    static void setupTestData() {
        PortalTestDataFactory.createSimulatedGuest();
        PortalTestDataFactory.createUserWithoutAccess();

        Date today = Date.today();
        PortalTestDataFactory.insertRecords(
            new List<Fundraising_Campaign__c>{
                PortalTestDataFactory.buildCampaign(WITH_DONORS, 'Active', today.addDays(-10), null),
                PortalTestDataFactory.buildCampaign(ONLY_ANONYMOUS, 'Active', today.addDays(-10), null),
                PortalTestDataFactory.buildCampaign(OTHER, 'Active', today.addDays(-10), null),
                PortalTestDataFactory.buildCampaign(CLOSED, 'Closed', today.addDays(-60), today.addDays(-10)),
                PortalTestDataFactory.buildCampaign(CLOSED_FUTURE_START, 'Closed', today.addDays(10), today.addDays(20)),
                PortalTestDataFactory.buildCampaign(DRAFT, 'Draft', today.addDays(-10), null),
                PortalTestDataFactory.buildCampaign(FUTURE_ACTIVE, 'Active', today.addDays(5), today.addDays(60))
            }
        );

        Datetime now = Datetime.now();
        PortalTestDataFactory.insertRecords(
            new List<SObject>{
                PortalTestDataFactory.buildDonation(idOf(WITH_DONORS), 300, 'Public', 'Ana López', now.addDays(-2)),
                PortalTestDataFactory.buildDonation(idOf(WITH_DONORS), 500, 'Public', 'Familia   Pérez', now.addDays(-1)),
                PortalTestDataFactory.buildDonation(idOf(WITH_DONORS), 100, 'Public', SCRIPT_NAME, now.addDays(-3)),
                PortalTestDataFactory.buildDonation(idOf(WITH_DONORS), 200, 'Anonymous', null, now),
                PortalTestDataFactory.buildDonation(idOf(WITH_DONORS), 250, 'Anonymous', HIDDEN_NAME, now),
                PortalTestDataFactory.buildPaymentAttempt(idOf(WITH_DONORS), 90),
                PortalTestDataFactory.buildDonation(idOf(ONLY_ANONYMOUS), 150, 'Anonymous', null, now),
                PortalTestDataFactory.buildDonation(idOf(OTHER), 700, 'Public', 'Donante de otra campaña', now),
                PortalTestDataFactory.buildDonation(idOf(CLOSED), 800, 'Public', 'Empresa Cerrada', now),
                PortalTestDataFactory.buildDonation(idOf(CLOSED_FUTURE_START), 900, 'Public', 'Empresa Cerrada Futura', now),
                PortalTestDataFactory.buildDonation(idOf(DRAFT), 50, 'Public', 'Donante de borrador', now),
                PortalTestDataFactory.buildDonation(idOf(FUTURE_ACTIVE), 60, 'Public', 'Donante de campaña futura', now)
            }
        );
    }

    @IsTest
    static void shouldReturnOnlyPublicConfirmedDonors_WhenCampaignHasDonations() {
        List<DonorRecognitionDTO> donors = getDonorsAsGuest(idOf(WITH_DONORS));

        Assert.areEqual(3, donors.size(), 'Only the three public confirmed donations should appear');
        Assert.areEqual(
            new Set<String>{ 'Ana López', 'Familia Pérez', SCRIPT_NAME },
            namesOf(donors),
            'The public names are returned with normalized spaces'
        );
    }

    @IsTest
    static void shouldOrderByConfirmationDateDescending_WhenSeveralDonorsExist() {
        List<DonorRecognitionDTO> donors = getDonorsAsGuest(idOf(WITH_DONORS));

        Assert.areEqual('Familia Pérez', donors[0].publicName, 'Most recent confirmation first');
        Assert.areEqual('Ana López', donors[1].publicName, 'Second most recent');
        Assert.areEqual(SCRIPT_NAME, donors[2].publicName, 'Oldest confirmation last');
    }

    @IsTest
    static void shouldReturnAmounts_WhenDonorsAreListed() {
        List<DonorRecognitionDTO> donors = getDonorsAsGuest(idOf(WITH_DONORS));

        Assert.areEqual(500, donors[0].amount, 'Amount of Familia Pérez');
        Assert.areEqual(300, donors[1].amount, 'Amount of Ana López');
    }

    @IsTest
    static void shouldExcludeAnonymousDonations_WhenListingDonors() {
        Set<String> names = namesOf(getDonorsAsGuest(idOf(WITH_DONORS)));

        Assert.isFalse(names.contains(HIDDEN_NAME), 'An anonymous donation never appears, even if it carries a name');
    }

    @IsTest
    static void shouldNotIncludePaymentAttempts_WhenListingDonors() {
        Set<String> names = namesOf(getDonorsAsGuest(idOf(WITH_DONORS)));

        Assert.isFalse(names.contains('Nombre de un intento'), 'A payment attempt is not a donation');
    }

    @IsTest
    static void shouldNotIncludeDonorsOfOtherCampaigns_WhenListingDonors() {
        Set<String> names = namesOf(getDonorsAsGuest(idOf(WITH_DONORS)));

        Assert.isFalse(names.contains('Donante de otra campaña'), 'Only the requested campaign is queried');
    }

    @IsTest
    static void shouldReturnOnlyNameAndAmount_WhenSerialized() {
        List<DonorRecognitionDTO> donors = getDonorsAsGuest(idOf(WITH_DONORS));
        String serializedDonors = JSON.serialize(donors);
        Map<String, Object> firstEntry = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(donors[0]));

        Assert.areEqual(new Set<String>{ 'publicName', 'amount' }, firstEntry.keySet(), 'The DTO exposes only name and amount');
        Assert.isFalse(serializedDonors.contains('donante.privado@example.com'), 'No email in the response');
        Assert.isFalse(serializedDonors.contains('GODE561231GR8'), 'No RFC in the response');
        Assert.isFalse(serializedDonors.contains('Razón Social Privada'), 'No legal name in the response');
        Assert.isFalse(serializedDonors.contains('97000'), 'No tax postal code in the response');
    }

    @IsTest
    static void shouldReturnNameAsPlainText_WhenItContainsHtml() {
        List<DonorRecognitionDTO> donors = getDonorsAsGuest(idOf(WITH_DONORS));

        Assert.isTrue(namesOf(donors).contains(SCRIPT_NAME), 'The server returns the text untouched; the interface renders it as text');
    }

    @IsTest
    static void shouldReturnEmptyList_WhenCampaignOnlyHasAnonymousDonations() {
        Assert.isTrue(getDonorsAsGuest(idOf(ONLY_ANONYMOUS)).isEmpty(), 'No public donors means an empty list');
    }

    @IsTest
    static void shouldReturnDonors_WhenCampaignIsClosed() {
        List<DonorRecognitionDTO> donors = getDonorsAsGuest(idOf(CLOSED));

        Assert.areEqual(1, donors.size(), 'A closed campaign still shows its donors');
        Assert.areEqual('Empresa Cerrada', donors[0].publicName, 'Public name');
    }

    @IsTest
    static void shouldReturnDonors_WhenClosedCampaignStartsInTheFuture() {
        List<DonorRecognitionDTO> donors = getDonorsAsGuest(idOf(CLOSED_FUTURE_START));

        Assert.areEqual(1, donors.size(), 'Recognition follows the same eligibility as the detail');
        Assert.areEqual('Empresa Cerrada Futura', donors[0].publicName, 'Public name');
    }

    @IsTest
    static void shouldReturnEmptyList_WhenCampaignIsDraft() {
        Assert.isTrue(getDonorsAsGuest(idOf(DRAFT)).isEmpty(), 'A draft campaign is not publicly consultable');
    }

    @IsTest
    static void shouldReturnEmptyList_WhenActiveCampaignStartsInTheFuture() {
        Assert.isTrue(getDonorsAsGuest(idOf(FUTURE_ACTIVE)).isEmpty(), 'A future campaign is not publicly consultable');
    }

    @IsTest
    static void shouldReturnEmptyList_WhenCampaignIdIsNotValid() {
        Assert.isTrue(getDonorsAsGuest(null).isEmpty(), 'Null Id');
        Assert.isTrue(getDonorsAsGuest('').isEmpty(), 'Blank Id');
        Assert.isTrue(getDonorsAsGuest('no-es-un-id').isEmpty(), 'Malformed Id');
        Assert.isTrue(getDonorsAsGuest(UserInfo.getUserId()).isEmpty(), 'An Id of another object');
    }

    @IsTest
    static void shouldHaveNoDonationAccess_WhenUserIsTheSimulatedGuest() {
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            try {
                Database.query('SELECT Id FROM Donation__c', AccessLevel.USER_MODE);
                Assert.fail('The simulated guest must not be able to query Donation__c in user mode');
            } catch (QueryException e) {
                Assert.isNotNull(e.getMessage(), 'The user-mode query is rejected, so the system-mode query is the only way to list donors');
            }
        }
    }

    @IsTest
    static void shouldLimitList_WhenCampaignHasMoreThanTwoHundredPublicDonors() {
        String campaignId = idOf(OTHER);
        List<Donation__c> donations = new List<Donation__c>();
        for (Integer i = 0; i < 251; i++) {
            donations.add(PortalTestDataFactory.buildDonation(campaignId, 50, 'Public', 'Donante ' + i, Datetime.now()));
        }
        PortalTestDataFactory.insertRecords(donations);

        Assert.areEqual(200, getDonorsAsGuest(campaignId).size(), 'The list is bounded to 200 entries');
    }

    @IsTest
    static void shouldThrowFriendlyError_WhenUserCannotReadCampaigns() {
        String campaignId = idOf(WITH_DONORS);
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.NO_ACCESS_LAST_NAME)) {
            try {
                DonorRecognitionService.getDonorRecognition(campaignId);
                Assert.fail('Expected an AuraHandledException');
            } catch (AuraHandledException e) {
                Assert.areEqual(DonorRecognitionService.MSG_LOAD_ERROR, e.getMessage(), 'The visitor sees a Spanish message');
            }
        }
    }

    private static String idOf(String campaignName) {
        return [SELECT Id FROM Fundraising_Campaign__c WHERE Name = :campaignName WITH SYSTEM_MODE LIMIT 1].Id;
    }

    private static List<DonorRecognitionDTO> getDonorsAsGuest(String campaignId) {
        List<DonorRecognitionDTO> donors;
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            donors = DonorRecognitionService.getDonorRecognition(campaignId);
        }
        return donors;
    }

    private static Set<String> namesOf(List<DonorRecognitionDTO> donors) {
        Set<String> names = new Set<String>();
        for (DonorRecognitionDTO donor : donors) {
            names.add(donor.publicName);
        }
        return names;
    }
}
