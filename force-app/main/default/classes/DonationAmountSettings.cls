/**
 * ADM-13. Reads the suggested amounts and the minimum donation amount from the global
 * configuration Donation_Amount_Setting__mdt (record "Default"), which an administrator edits
 * in Setup without a code change.
 *
 * Custom metadata is read without object or field permissions, so the guest user of the portal
 * gets the same values. If the record is missing, the values of Delivery 1 are used (DON-08:
 * eight fixed amounts and a minimum of $50 MXN), so the form never stays without options.
 *
 * Amounts are compared with two decimals (setScale(2)): custom metadata returns 150.0 while the
 * form sends 150, and List.contains treats Decimals with a different scale as different values.
 *
 * The configuration only affects new donations: the amount of an attempt or a donation that
 * already exists is stored in its own record and never changes here (ADM-13, technical task 3).
 */
public with sharing class DonationAmountSettings {
    @TestVisible
    private static final String RECORD_NAME = 'Default';
    @TestVisible
    private static final Decimal DEFAULT_MINIMUM = 50;
    @TestVisible
    private static final List<Decimal> DEFAULT_AMOUNTS = new List<Decimal>{ 100, 250, 500, 1000, 2000, 5000, 10000, 20000 };
    private static final List<SObjectField> AMOUNT_FIELDS = new List<SObjectField>{
        Donation_Amount_Setting__mdt.Amount_1__c,
        Donation_Amount_Setting__mdt.Amount_2__c,
        Donation_Amount_Setting__mdt.Amount_3__c,
        Donation_Amount_Setting__mdt.Amount_4__c,
        Donation_Amount_Setting__mdt.Amount_5__c,
        Donation_Amount_Setting__mdt.Amount_6__c,
        Donation_Amount_Setting__mdt.Amount_7__c,
        Donation_Amount_Setting__mdt.Amount_8__c
    };

    // Lets a test replace the record (custom metadata cannot be inserted in a test).
    @TestVisible
    private static Donation_Amount_Setting__mdt recordOverride;
    @TestVisible
    private static Boolean recordMissing = false;

    /**
     * What the donation form needs.
     */
    public class Settings {
        @AuraEnabled
        public Decimal minimumAmount;
        @AuraEnabled
        public List<Decimal> suggestedAmounts;
    }

    /**
     * Current configuration, in the order the administrator set the amounts. Empty amounts are left out.
     * @return minimum amount and suggested amounts
     */
    public static Settings current() {
        Donation_Amount_Setting__mdt record = recordMissing
            ? null
            : (recordOverride != null ? recordOverride : Donation_Amount_Setting__mdt.getInstance(RECORD_NAME));
        Settings settings = new Settings();
        if (record == null || record.Minimum_Amount__c == null) {
            settings.minimumAmount = normalize(DEFAULT_MINIMUM);
            settings.suggestedAmounts = normalize(DEFAULT_AMOUNTS);
            return settings;
        }
        settings.minimumAmount = normalize(record.Minimum_Amount__c);
        settings.suggestedAmounts = new List<Decimal>();
        for (SObjectField field : AMOUNT_FIELDS) {
            Decimal amount = normalize((Decimal) record.get(field));
            if (amount != null && !settings.suggestedAmounts.contains(amount)) {
                settings.suggestedAmounts.add(amount);
            }
        }
        if (settings.suggestedAmounts.isEmpty()) {
            settings.suggestedAmounts = normalize(DEFAULT_AMOUNTS);
        }
        return settings;
    }

    /**
     * @param amount amount chosen by the donor
     * @return true when it is one of the current suggested amounts
     */
    public static Boolean isSuggested(Decimal amount) {
        return amount != null && current().suggestedAmounts.contains(normalize(amount));
    }

    /**
     * @param amount any amount
     * @return the same amount with two decimals, or null
     */
    @TestVisible
    private static Decimal normalize(Decimal amount) {
        return amount == null ? null : amount.setScale(2);
    }

    private static List<Decimal> normalize(List<Decimal> amounts) {
        List<Decimal> result = new List<Decimal>();
        for (Decimal amount : amounts) {
            result.add(normalize(amount));
        }
        return result;
    }

    /**
     * @param amount amount entered by the donor
     * @return true when it is equal to or above the current minimum
     */
    public static Boolean meetsMinimum(Decimal amount) {
        return amount != null && amount >= current().minimumAmount;
    }
}
