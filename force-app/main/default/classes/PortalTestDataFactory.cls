/**
 * Test data for the public portal tests (Workstream B). Test code only.
 *
 * Records are inserted in system mode on purpose: from API 67.0 Apex defaults to user mode,
 * and the user running the deployment does not necessarily have field-level security on the
 * project fields. The tests that need to prove access limits run as one of the users created
 * here instead.
 */
@IsTest
public with sharing class PortalTestDataFactory {
    public static final String GUEST_LAST_NAME = 'PortalGuestSim';
    public static final String NO_ACCESS_LAST_NAME = 'PortalNoAccess';

    private static final String LIMITED_PROFILE_NAME = 'Minimum Access - Salesforce';
    private static final String SIMULATION_PERMISSION_SET = 'Portal_Guest_Simulation';
    private static final List<String> PUBLIC_OPTIONAL_CAMPAIGN_FIELDS = new List<String>{
        'Description__c',
        'End_Date__c',
        'Status__c',
        'Is_General__c',
        'Image_URL__c',
        'Image_Alt_Text__c',
        'Total_Raised__c',
        'Donation_Count__c',
        'Progress_Percent__c',
        'Accepts_Donations__c',
        'Is_Publicly_Visible__c'
    };

    /**
     * Builds, without inserting, a campaign that satisfies the D1 validation rules.
     *
     * @param name campaign name
     * @param status Status__c API value
     * @param startDate Start_Date__c
     * @param endDate End_Date__c, or null for an open campaign
     * @return the campaign, with goal 1000 and a description
     */
    public static Fundraising_Campaign__c buildCampaign(String name, String status, Date startDate, Date endDate) {
        return new Fundraising_Campaign__c(
            Name = name,
            Description__c = 'Descripción de la campaña ' + name,
            Goal__c = 1000,
            Start_Date__c = startDate,
            End_Date__c = endDate,
            Status__c = status,
            Image_URL__c = 'https://example.com/imagenes/' + EncodingUtil.urlEncode(name, 'UTF-8') + '.png',
            Image_Alt_Text__c = 'Imagen de ' + name
        );
    }

    /**
     * Builds, without inserting, a confirmed donation.
     *
     * @param campaignId parent campaign
     * @param amount confirmed amount
     * @param visibility Anonymous or Public
     * @param publicName public name, required by the data model when visibility is Public
     * @param confirmedAt confirmation date and time
     * @return the donation, with private data that must never reach a public response
     */
    public static Donation__c buildDonation(
        Id campaignId,
        Decimal amount,
        String visibility,
        String publicName,
        Datetime confirmedAt
    ) {
        return new Donation__c(
            Campaign__c = campaignId,
            Amount__c = amount,
            Visibility__c = visibility,
            Public_Name__c = publicName,
            Confirmed_At__c = confirmedAt,
            Provider_Payment_Id__c = 'TEST-' + Math.abs(Crypto.getRandomLong()),
            Email__c = 'donante.privado@example.com',
            Invoice_Requested__c = true,
            Legal_Name__c = 'Razón Social Privada',
            RFC__c = 'GODE561231GR8',
            Tax_Postal_Code__c = '97000'
        );
    }

    /**
     * Builds, without inserting, a payment attempt that has not been confirmed.
     *
     * @param campaignId parent campaign
     * @param amount amount chosen by the donor
     * @return the attempt, in status Started
     */
    public static Payment_Attempt__c buildPaymentAttempt(Id campaignId, Decimal amount) {
        return new Payment_Attempt__c(
            Campaign__c = campaignId,
            Amount__c = amount,
            Email__c = 'intento.privado@example.com',
            Visibility__c = 'Public',
            Public_Name__c = 'Nombre de un intento'
        );
    }

    /**
     * Inserts records in system mode.
     *
     * @param records records to insert
     */
    public static void insertRecords(List<SObject> records) {
        Database.insert(records, AccessLevel.SYSTEM_MODE);
    }

    /**
     * Creates the user that simulates the site guest: it can read the public fields of
     * Fundraising_Campaign__c and has no access at all to Donation__c or Payment_Attempt__c.
     * Setup records are created inside runAs to avoid mixed DML errors.
     */
    public static void createSimulatedGuest() {
        Id profileId = getLimitedProfileId();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet simulation = new PermissionSet(
                Name = SIMULATION_PERMISSION_SET,
                Label = 'Simulación de invitado del portal'
            );
            Database.insert(simulation, AccessLevel.SYSTEM_MODE);

            List<SObject> grants = new List<SObject>{
                new ObjectPermissions(
                    ParentId = simulation.Id,
                    SobjectType = 'Fundraising_Campaign__c',
                    PermissionsRead = true
                )
            };
            for (String fieldName : PUBLIC_OPTIONAL_CAMPAIGN_FIELDS) {
                grants.add(
                    new FieldPermissions(
                        ParentId = simulation.Id,
                        SobjectType = 'Fundraising_Campaign__c',
                        Field = 'Fundraising_Campaign__c.' + fieldName,
                        PermissionsRead = true,
                        PermissionsEdit = false
                    )
                );
            }
            Database.insert(grants, AccessLevel.SYSTEM_MODE);

            User guest = buildUser(GUEST_LAST_NAME, profileId);
            Database.insert(guest, AccessLevel.SYSTEM_MODE);
            Database.insert(
                new PermissionSetAssignment(AssigneeId = guest.Id, PermissionSetId = simulation.Id),
                AccessLevel.SYSTEM_MODE
            );
        }
    }

    /**
     * Creates a user with no access to the project objects, to test the error paths.
     */
    public static void createUserWithoutAccess() {
        Id profileId = getLimitedProfileId();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Database.insert(buildUser(NO_ACCESS_LAST_NAME, profileId), AccessLevel.SYSTEM_MODE);
        }
    }

    /**
     * @param lastName GUEST_LAST_NAME or NO_ACCESS_LAST_NAME
     * @return the test user created in test setup
     */
    public static User getUser(String lastName) {
        return [SELECT Id FROM User WHERE LastName = :lastName WITH SYSTEM_MODE LIMIT 1];
    }

    private static Id getLimitedProfileId() {
        List<Profile> profiles = [
            SELECT Id
            FROM Profile
            WHERE Name = :LIMITED_PROFILE_NAME
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        Assert.isFalse(
            profiles.isEmpty(),
            'The profile "' + LIMITED_PROFILE_NAME + '" is required to simulate a user without permissions'
        );
        return profiles[0].Id;
    }

    private static User buildUser(String lastName, Id profileId) {
        String uniqueSuffix = String.valueOf(Math.abs(Crypto.getRandomLong()));
        return new User(
            LastName = lastName,
            Alias = 'pt' + uniqueSuffix.left(5),
            Email = 'portal.test@example.com',
            Username = 'portal.test.' + uniqueSuffix + '@example.com',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'es_MX',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
    }
}
