/**
 * DON-09: the amount the donor types is validated on the server as text, whatever the browser did.
 * The minimum is the one of the ADM-13 configuration, replaced in the tests through
 * DonationAmountSettings.recordOverride.
 */
@IsTest
private class DonationAmountValidatorTest {
    @IsTest
    static void shouldReturnTheExactAmount_WhenTheTextIsAValidAmount() {
        Map<String, Decimal> valid = new Map<String, Decimal>{
            '50' => 50, '250' => 250, '250.5' => 250.5, '250.50' => 250.50, '1234.56' => 1234.56,
            '0050.25' => 50.25, '  75  ' => 75, '99999999999999.99' => Decimal.valueOf('99999999999999.99')
        };

        for (String text : valid.keySet()) {
            Decimal amount = DonationAmountValidator.validate(text);
            Assert.areEqual(valid.get(text), amount, 'Amount typed as "' + text + '"');
        }
    }

    @IsTest
    static void shouldKeepEveryCentOfAnAmountWith16Digits_WhenItIsConverted() {
        // A JavaScript Number would turn this into ...98; the server keeps the exact digits.
        Decimal amount = DonationAmountValidator.validate('99999999999999.99');

        Assert.areEqual('99999999999999.99', DonationAmountValidator.toExactText(amount));
    }

    @IsTest
    static void shouldWriteTwoDecimals_WhenTheAmountIsConvertedToText() {
        Assert.areEqual('250.00', DonationAmountValidator.toExactText(DonationAmountValidator.validate('250')));
        Assert.areEqual('250.50', DonationAmountValidator.toExactText(DonationAmountValidator.validate('250.5')));
        Assert.areEqual('0.10', DonationAmountValidator.toExactText(DonationAmountValidator.parse('0.1')));
    }

    @IsTest
    static void shouldRejectTheAmount_WhenItIsEmpty() {
        for (String text : new List<String>{ null, '', '   ' }) {
            assertRejected(text, DonationAmountValidator.MSG_REQUIRED);
        }
    }

    @IsTest
    static void shouldRejectTheAmount_WhenItIsNotAPlainDecimalNumber() {
        for (String text : new List<String>{ 'abc', '12a', '1e3', '1E3', '1,000', '1 000', '$250', '250 MXN', '.5', '5.', '1..5', '0x10', '+5', '١٢٣' }) {
            assertRejected(text, DonationAmountValidator.MSG_FORMAT);
        }
    }

    @IsTest
    static void shouldRejectTheAmount_WhenItIsZeroOrNegative() {
        for (String text : new List<String>{ '0', '0.0', '0.00', '000', '-1', '-0.5', '-250.50' }) {
            assertRejected(text, DonationAmountValidator.MSG_POSITIVE);
        }
    }

    @IsTest
    static void shouldRejectTheAmount_WhenItHasMoreThanTwoDecimals() {
        for (String text : new List<String>{ '250.555', '250.001', '0.001', '250.10000' }) {
            assertRejected(text, DonationAmountValidator.MSG_DECIMALS);
        }
    }

    @IsTest
    static void shouldRejectTheAmount_WhenItDoesNotFitInTheAmountField() {
        Assert.areEqual(14, DonationAmountValidator.integerDigitCapacity(), 'Currency(16, 2) holds 14 whole digits');
        for (String text : new List<String>{ '100000000000000', '999999999999999.99', '123456789012345678' }) {
            assertRejected(text, DonationAmountValidator.MSG_TOO_MANY_DIGITS);
        }
    }

    @IsTest
    static void shouldAcceptTheAmount_WhenLeadingZerosDoNotCountAsDigits() {
        Assert.areEqual(100, DonationAmountValidator.validate('0000000000000000100'));
    }

    @IsTest
    static void shouldRejectTheAmount_WhenItIsBelowTheCurrentMinimum() {
        assertRejected('49.99', 'El monto mínimo es de $50 MXN.');
        assertRejected('1', 'El monto mínimo es de $50 MXN.');
        Assert.areEqual(50, DonationAmountValidator.validate('50.00'), 'The minimum itself is accepted');
    }

    @IsTest
    static void shouldFollowTheConfiguredMinimum_WhenTheAdministratorChangesIt() {
        DonationAmountSettings.recordOverride = (Donation_Amount_Setting__mdt) JSON.deserialize(
            '{"Minimum_Amount__c": 75.5, "Amount_1__c": 100}', Donation_Amount_Setting__mdt.class);

        assertRejected('75.49', 'El monto mínimo es de $75.5 MXN.');
        Assert.areEqual(75.5, DonationAmountValidator.validate('75.50'));

        DonationAmountSettings.recordOverride = (Donation_Amount_Setting__mdt) JSON.deserialize(
            '{"Minimum_Amount__c": 20, "Amount_1__c": 100}', Donation_Amount_Setting__mdt.class);

        Assert.areEqual(20, DonationAmountValidator.validate('20'), 'A lower minimum is applied at once');
    }

    @IsTest
    static void shouldNotUseTheSuggestedList_WhenTheAmountIsCustom() {
        DonationAmountSettings.recordOverride = (Donation_Amount_Setting__mdt) JSON.deserialize(
            '{"Minimum_Amount__c": 50, "Amount_1__c": 100}', Donation_Amount_Setting__mdt.class);

        Assert.isFalse(DonationAmountSettings.isSuggested(333), '333 is not suggested');
        Assert.areEqual(333, DonationAmountValidator.validate('333'), 'but it is a valid custom amount');
    }

    @IsTest
    static void shouldWorkForTheGuestSimulation_WhenTheAmountIsValidated() {
        PortalTestDataFactory.createSimulatedGuest();

        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            Assert.areEqual(14, DonationAmountValidator.integerDigitCapacity(), 'The field capacity is readable by the guest');
            Assert.areEqual(250.5, DonationAmountValidator.validate('250.5'));
        }
    }

    private static void assertRejected(String text, String expectedMessage) {
        try {
            DonationAmountValidator.validate(text);
            Assert.fail('Expected a rejection for "' + text + '"');
        } catch (DonationAmountValidator.AmountException e) {
            Assert.areEqual(expectedMessage, e.getMessage(), 'Message for "' + text + '"');
        }
    }
}
