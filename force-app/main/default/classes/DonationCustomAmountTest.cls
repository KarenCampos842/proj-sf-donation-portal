/**
 * DON-09 (AC2, AC4, AC5, AC6) against the real flows of Workstream A. Only the answers of Mercado Pago
 * are simulated. It checks that the amount the donor typed is the one saved in the payment attempt, the
 * one sent to the provider and the one of the donation registered after the approved payment.
 */
@IsTest
private class DonationCustomAmountTest {
    private static final String OPEN_CAMPAIGN = 'Campaña abierta DON-09';
    // Token of the last donation started by startAsGuest.
    private static String lastToken;
    private static final String PREFERENCE_ID = '123-pref';
    private static final String CHECKOUT_URL = 'https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=123-pref';
    private static final List<String> TYPED_AMOUNTS = new List<String>{ '50', '50.10', '75.5', '1234.56', '20001', '99999999999999.99' };

    /** Answers the preference request and the payment lookup of Mercado Pago, and keeps what was sent. */
    private class ProviderMock implements HttpCalloutMock {
        public Integer preferenceStatus = 201;
        public String preferenceRequestBody;
        public String paymentBody;
        public Integer preferenceCalls = 0;

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            if (request.getEndpoint().contains('checkout/preferences')) {
                preferenceCalls++;
                preferenceRequestBody = request.getBody();
                response.setStatusCode(preferenceStatus);
                response.setBody('{"id":"' + PREFERENCE_ID + '","init_point":"' + CHECKOUT_URL + '"}');
            } else {
                response.setStatusCode(200);
                response.setBody(paymentBody);
            }
            return response;
        }
    }

    @TestSetup
    static void setupTestData() {
        PortalTestDataFactory.createSimulatedGuest();
        Date today = Date.today();
        PortalTestDataFactory.insertRecords(
            new List<Fundraising_Campaign__c>{
                PortalTestDataFactory.buildCampaign(OPEN_CAMPAIGN, 'Active', today.addDays(-10), today.addDays(30))
            }
        );
    }

    // AC4: the attempt keeps exactly what the donor typed

    @IsTest
    static void shouldSaveTheExactAmountInTheAttempt_WhenTheDonorTypesACustomAmount() {
        Test.startTest();
        for (String typed : TYPED_AMOUNTS) {
            String attemptId = startAsGuest(typed);
            Payment_Attempt__c attempt = attemptOf(attemptId);
            Assert.areEqual(Decimal.valueOf(typed), attempt.Amount__c, 'Saved amount for ' + typed);
            Assert.areEqual(2, attempt.Amount__c.scale(), 'Two decimals for ' + typed);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldSaveNoAttempt_WhenTheServerRejectsTheAmount() {
        Test.startTest();
        for (String typed : new List<String>{ '', 'abc', '0', '-5', '49.99', '10.123', '100000000000000' }) {
            DonationIntakeService.DonationFormInputDTO request = request(typed);
            System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
                try {
                    DonationIntakeService.startDonation(request);
                    Assert.fail('Expected a rejection for "' + typed + '"');
                } catch (AuraHandledException e) {
                    Assert.isTrue(e.getMessage().startsWith(DonationIntakeService.FIELD_AMOUNT + '|'), 'The amount is marked: "' + typed + '"');
                }
            }
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'A rejected amount saves nothing');
    }

    @IsTest
    static void shouldKeepTheMinimumOfTheAttemptRuleInSync_WhenTheAdministratorLowersTheMinimum() {
        // ADM-13: the minimum is read in the portal and in the Minimum_Amount rule from the same record.
        DonationAmountSettings.recordOverride = (Donation_Amount_Setting__mdt) JSON.deserialize(
            '{"Minimum_Amount__c": 50, "Amount_1__c": 100}', Donation_Amount_Setting__mdt.class);

        Test.startTest();
        String attemptId = startAsGuest('50');
        Test.stopTest();

        Assert.areEqual(50, attemptOf(attemptId).Amount__c, 'The minimum itself is saved');
    }

    // AC4: the provider receives the same amount

    @IsTest
    static void shouldSendTheSavedAmountToMercadoPago_WhenThePaymentIsOpened() {
        String attemptId = startAsGuest('1234.56');
        ProviderMock provider = new ProviderMock();
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        String url = openAsGuest();
        Test.stopTest();

        Assert.areEqual(CHECKOUT_URL, url, 'The Checkout URL comes from Mercado Pago');
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(provider.preferenceRequestBody);
        Map<String, Object> item = (Map<String, Object>) ((List<Object>) body.get('items'))[0];
        Assert.areEqual(attemptOf(attemptId).Amount__c, Decimal.valueOf(String.valueOf(item.get('unit_price'))), 'The provider charges the saved amount');
        Assert.areEqual('MXN', item.get('currency_id'), 'In pesos');
        Assert.areEqual(attemptId, body.get('external_reference'), 'The payment is tied to the attempt');
    }

    // AC4: the donation registered after the approved payment has the same amount

    @IsTest
    static void shouldRegisterTheDonationWithTheTypedAmount_WhenTheAmountHasDecimals() {
        assertDonationKeepsTheTypedAmount('75.5', '987001');
    }

    @IsTest
    static void shouldRegisterTheDonationWithTheTypedAmount_WhenTheAmountIsNotSuggested() {
        assertDonationKeepsTheTypedAmount('1234.56', '987002');
    }

    @IsTest
    static void shouldRegisterTheDonationWithTheTypedAmount_WhenTheAmountUsesEverySignificantDigit() {
        assertDonationKeepsTheTypedAmount('99999999999999.99', '987003');
    }

    @IsTest
    static void shouldNotRegisterTheDonation_WhenTheProviderApprovesAnotherAmount() {
        String attemptId = startAsGuest('250.50');
        ProviderMock provider = new ProviderMock();
        provider.paymentBody = approvedPayment('987651', attemptId, '250.51');
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        String state = DonationPaymentController.getPaymentResult('987651');
        Test.stopTest();

        Assert.areNotEqual('Confirmed', state, 'A different amount is not confirmed');
        Assert.areEqual(0, [SELECT COUNT() FROM Donation__c WITH SYSTEM_MODE], 'No donation is registered');
    }

    // AC6: Mercado Pago cannot process the amount

    @IsTest
    static void shouldOfferToChooseAnotherAmount_WhenMercadoPagoRejectsTheAmount() {
        String attemptId = startAsGuest('99999999999999.99');
        ProviderMock provider = new ProviderMock();
        provider.preferenceStatus = 400;
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        try {
            openAsGuest();
            Assert.fail('Expected a friendly error');
        } catch (AuraHandledException e) {
            Assert.areEqual(DonationIntakeService.ERROR_SEPARATOR + DonationIntakeService.MSG_PAYMENT_FAILED, e.getMessage(), 'A safe message');
            Assert.isTrue(DonationIntakeService.MSG_PAYMENT_FAILED.contains('esta cantidad'), 'It names the amount');
            Assert.isTrue(DonationIntakeService.MSG_PAYMENT_FAILED.contains('elige otra'), 'It offers another amount');
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'The failed attempt is deleted');
        Assert.areEqual(0, [SELECT COUNT() FROM Donation__c WITH SYSTEM_MODE], 'No donation');
    }

    @IsTest
    static void shouldNotShowTheProviderAnswer_WhenMercadoPagoFails() {
        String attemptId = startAsGuest('500');
        ProviderMock provider = new ProviderMock();
        provider.preferenceStatus = 400;
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        try {
            openAsGuest();
            Assert.fail('Expected a friendly error');
        } catch (AuraHandledException e) {
            Assert.isFalse(e.getMessage().containsIgnoreCase('400'), 'No status code');
            Assert.isFalse(e.getMessage().containsIgnoreCase('exception'), 'No exception text');
            Assert.isFalse(e.getMessage().contains('donante@example.com'), 'No donor data');
        }
        Test.stopTest();
    }

    // Helpers

    // The attempt is saved before Test.startTest so the return page can call Mercado Pago in a new transaction.
    private static void assertDonationKeepsTheTypedAmount(String typed, String paymentId) {
        String attemptId = startAsGuest(typed);
        ProviderMock provider = new ProviderMock();
        provider.paymentBody = approvedPayment(paymentId, attemptId, typed);
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        String state = DonationPaymentController.getPaymentResult(paymentId);
        Test.stopTest();

        Decimal expected = Decimal.valueOf(typed);
        Assert.areEqual('Confirmed', state, 'The return page confirms the verified payment of ' + typed);
        Donation__c donation = [SELECT Amount__c FROM Donation__c WHERE Provider_Payment_Id__c = :paymentId WITH SYSTEM_MODE];
        Assert.areEqual(expected, donation.Amount__c, 'The registered amount is the typed one');
        Assert.areEqual(expected, attemptOf(attemptId).Amount__c, 'The charged and the registered amounts are the same');
    }

    private static DonationIntakeService.DonationFormInputDTO request(String amount) {
        DonationIntakeService.DonationFormInputDTO request = new DonationIntakeService.DonationFormInputDTO();
        request.campaignId = [SELECT Id FROM Fundraising_Campaign__c WHERE Name = :OPEN_CAMPAIGN WITH SYSTEM_MODE LIMIT 1].Id;
        request.amount = amount;
        request.email = 'donante@example.com';
        request.visibility = 'Anonymous';
        request.invoiceRequested = false;
        return request;
    }

    // Starts the donation as the guest and confirms the summary, as the form does before the payment. It
    // returns the Id of the saved attempt to read it back; the browser only ever holds the token.
    private static String startAsGuest(String amount) {
        DonationIntakeService.DonationFormInputDTO request = request(amount);
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            lastToken = DonationIntakeService.startDonation(request).accessToken;
            DonationIntakeService.confirmDonation(lastToken);
        }
        return [
            SELECT Id FROM Payment_Attempt__c WHERE Portal_Access_Token_Hash__c = :DonationAccessToken.hashOf(lastToken) WITH SYSTEM_MODE
        ].Id;
    }

    // Runs as the test user: the external credential of Mercado Pago is not given to the simulated guest.
    private static String openAsGuest() {
        return DonationIntakeService.openPayment(lastToken);
    }

    private static Payment_Attempt__c attemptOf(String attemptId) {
        return [SELECT Amount__c, Status__c FROM Payment_Attempt__c WHERE Id = :attemptId WITH SYSTEM_MODE];
    }

    private static String approvedPayment(String paymentId, String attemptId, String amount) {
        // The amount is written as a JSON number from its text, so no digit goes through a binary float.
        return '{"id":' + paymentId + ',"status":"approved","external_reference":"' + attemptId + '",' +
            '"transaction_amount":' + amount + ',"currency_id":"MXN","date_approved":"2026-11-09T12:00:00.000-06:00"}';
    }
}
