@IsTest
private class DonationAmountSettingsTest {
    // Expected amounts with two decimals, as DonationAmountSettings returns them.
    private static List<Decimal> amounts(List<Decimal> values) {
        List<Decimal> result = new List<Decimal>();
        for (Decimal value : values) {
            result.add(value.setScale(2));
        }
        return result;
    }

    // Custom metadata fields are read-only in Apex, so the test record is built from JSON.
    private static Donation_Amount_Setting__mdt record(Decimal minimum, List<Decimal> amounts) {
        Map<String, Object> values = new Map<String, Object>{ 'Minimum_Amount__c' => minimum };
        for (Integer i = 0; i < amounts.size(); i++) {
            values.put('Amount_' + (i + 1) + '__c', amounts[i]);
        }
        return (Donation_Amount_Setting__mdt) JSON.deserialize(JSON.serialize(values), Donation_Amount_Setting__mdt.class);
    }

    @IsTest
    static void deployedRecordHasTheValuesOfDeliveryOne() {
        // Technical task 2: initial values are the eight amounts of DON-08 and a minimum of $50.
        Donation_Amount_Setting__mdt deployed = Donation_Amount_Setting__mdt.getInstance('Default');
        Assert.isNotNull(deployed, 'The Default record is deployed with the metadata');
        DonationAmountSettingsDTO s = DonationAmountSettings.current();
        Assert.areEqual(DonationAmountSettings.DEFAULT_MINIMUM.setScale(2), s.minimumAmount);
        Assert.areEqual(amounts(DonationAmountSettings.DEFAULT_AMOUNTS), s.suggestedAmounts);
    }

    @IsTest
    static void changedAmountsAreUsed() {
        // AC1: the visitor gets the updated options, in the order the administrator set them.
        DonationAmountSettings.recordOverride = record(80, new List<Decimal>{ 150, 300, 900 });
        DonationAmountSettingsDTO s = DonationAmountSettings.current();
        Assert.areEqual(amounts(new List<Decimal>{ 150, 300, 900 }), s.suggestedAmounts);
        Assert.isTrue(DonationAmountSettings.isSuggested(150.0), 'The scale of the number does not matter');
        Assert.isTrue(DonationAmountSettings.isSuggested(300));
        Assert.isFalse(DonationAmountSettings.isSuggested(250), 'An amount removed from the configuration is no longer valid');
    }

    @IsTest
    static void changedMinimumIsApplied() {
        // AC2: the new minimum applies to an amount the donor enters.
        DonationAmountSettings.recordOverride = record(80, new List<Decimal>{ 100 });
        Assert.areEqual(((Decimal) 80).setScale(2), DonationAmountSettings.current().minimumAmount);
        Assert.isFalse(DonationAmountSettings.meetsMinimum(79.99));
        Assert.isTrue(DonationAmountSettings.meetsMinimum(80));
        Assert.isFalse(DonationAmountSettings.meetsMinimum(null));
    }

    @IsTest
    static void emptyAndRepeatedAmountsAreLeftOut() {
        DonationAmountSettings.recordOverride = record(50, new List<Decimal>{ 100, null, 100, 500 });
        Assert.areEqual(amounts(new List<Decimal>{ 100, 500 }), DonationAmountSettings.current().suggestedAmounts);
    }

    @IsTest
    static void missingRecordFallsBackToDeliveryOne() {
        DonationAmountSettings.recordMissing = true;
        DonationAmountSettingsDTO s = DonationAmountSettings.current();
        Assert.areEqual(DonationAmountSettings.DEFAULT_MINIMUM.setScale(2), s.minimumAmount);
        Assert.areEqual(amounts(DonationAmountSettings.DEFAULT_AMOUNTS), s.suggestedAmounts);
    }

    @IsTest
    static void recordWithoutAmountsFallsBackToDeliveryOneAmounts() {
        DonationAmountSettings.recordOverride = record(60, new List<Decimal>());
        DonationAmountSettingsDTO s = DonationAmountSettings.current();
        Assert.areEqual(((Decimal) 60).setScale(2), s.minimumAmount, 'The minimum still comes from the record');
        Assert.areEqual(amounts(DonationAmountSettings.DEFAULT_AMOUNTS), s.suggestedAmounts);
    }

    @IsTest
    static void configurationDoesNotChangeExistingAttempts() {
        // Technical task 3: changing the configuration never touches an attempt already saved.
        Fundraising_Campaign__c c = PortalTestDataFactory.buildCampaign('Boletos', 'Active', Date.today(), null);
        Database.insert(c, AccessLevel.SYSTEM_MODE);
        Payment_Attempt__c a = new Payment_Attempt__c(Campaign__c = c.Id, Amount__c = 250,
            Email__c = 'donor@example.com', Visibility__c = 'Anonymous', Status__c = 'Started');
        Database.insert(a, AccessLevel.SYSTEM_MODE);
        DonationAmountSettings.recordOverride = record(500, new List<Decimal>{ 1000 });
        Assert.areEqual((Decimal) 250, [SELECT Amount__c FROM Payment_Attempt__c WHERE Id = :a.Id WITH SYSTEM_MODE].Amount__c);
    }
}
