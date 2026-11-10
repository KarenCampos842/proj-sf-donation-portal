@IsTest
private class DonationPaymentControllerTest {
    private static final String CHECKOUT_URL = 'https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=123-pref';

    /**
     * Simulates Mercado Pago with a fixed status and body.
     */
    private class ProviderMock implements HttpCalloutMock {
        private final Integer status;
        private final String body;

        ProviderMock(Integer status, String body) {
            this.status = status;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(status);
            response.setBody(body);
            return response;
        }
    }

    private static Fundraising_Campaign__c campaign() {
        Fundraising_Campaign__c c = new Fundraising_Campaign__c(Name = 'Boletos del evento', Description__c = 'd',
            Goal__c = 1000, Start_Date__c = Date.today(), Status__c = 'Active');
        Database.insert(c, AccessLevel.SYSTEM_MODE);
        return c;
    }

    private static DonationPaymentController.DonationRequest request(Id campaignId) {
        DonationPaymentController.DonationRequest r = new DonationPaymentController.DonationRequest();
        r.campaignId = campaignId;
        r.amount = 250;
        r.email = 'donor@example.com';
        r.visibility = 'Anonymous';
        return r;
    }

    private static Payment_Attempt__c startedAttempt() {
        Payment_Attempt__c a = new Payment_Attempt__c(Campaign__c = campaign().Id, Amount__c = 250,
            Email__c = 'donor@example.com', Visibility__c = 'Anonymous', Status__c = 'Started');
        Database.insert(a, AccessLevel.SYSTEM_MODE);
        return a;
    }

    private static String errorOf(Exception e) {
        return e.getMessage();
    }

    @IsTest
    static void startDonationReturnsAttemptId() {
        Fundraising_Campaign__c c = campaign();
        Test.startTest();
        String attemptId = DonationPaymentController.startDonation(request(c.Id));
        Test.stopTest();
        Payment_Attempt__c a = [SELECT Campaign__c, Amount__c, Status__c FROM Payment_Attempt__c
            WHERE Id = :attemptId WITH SYSTEM_MODE];
        Assert.areEqual(c.Id, a.Campaign__c);
        Assert.areEqual((Decimal) 250, a.Amount__c);
        Assert.areEqual('Started', a.Status__c);
    }

    @IsTest
    static void startDonationShowsValidationMessage() {
        DonationPaymentController.DonationRequest r = request(campaign().Id);
        r.amount = 10;
        String message;
        Test.startTest();
        try {
            DonationPaymentController.startDonation(r);
        } catch (AuraHandledException e) {
            message = errorOf(e);
        }
        Test.stopTest();
        Assert.areEqual('El monto mínimo es de $50 MXN.', message);
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE]);
    }

    @IsTest
    static void startDonationRejectsEmptyRequest() {
        String message;
        try {
            DonationPaymentController.startDonation(null);
        } catch (AuraHandledException e) {
            message = errorOf(e);
        }
        Assert.areEqual('Faltan datos obligatorios de tu donación.', message);
    }

    @IsTest
    static void openPaymentReturnsCheckoutUrl() {
        Payment_Attempt__c a = startedAttempt();
        Test.setMock(HttpCalloutMock.class,
            new ProviderMock(201, '{"id":"123-pref","init_point":"' + CHECKOUT_URL + '"}'));
        Test.startTest();
        String url = DonationPaymentController.openPayment(a.Id);
        Test.stopTest();
        Assert.areEqual(CHECKOUT_URL, url);
    }

    @IsTest
    static void openPaymentShowsProviderMessage() {
        Payment_Attempt__c a = startedAttempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(500, '{}'));
        String message;
        Test.startTest();
        try {
            DonationPaymentController.openPayment(a.Id);
        } catch (AuraHandledException e) {
            message = errorOf(e);
        }
        Test.stopTest();
        Assert.areEqual(DonationPaymentController.GENERIC_ERROR, message);
    }

    @IsTest
    static void paymentResultWithoutPayment() {
        Test.startTest();
        String state = DonationPaymentController.getPaymentResult('null');
        Test.stopTest();
        Assert.areEqual('NoPayment', state);
    }

    @IsTest
    static void paymentResultConfirmsApprovedPayment() {
        Payment_Attempt__c a = startedAttempt();
        String body = JSON.serialize(new Map<String, Object>{
            'id' => 1234567890L, 'status' => 'approved', 'external_reference' => (String) a.Id,
            'transaction_amount' => 250, 'currency_id' => 'MXN',
            'date_approved' => '2026-11-09T12:00:00.000-06:00' });
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, body));
        Test.startTest();
        String state = DonationPaymentController.getPaymentResult('1234567890');
        Test.stopTest();
        Assert.areEqual('Confirmed', state);
        Assert.areEqual(1, [SELECT COUNT() FROM Donation__c WITH SYSTEM_MODE]);
    }

    @IsTest
    static void userWithoutObjectPermissionsCanDonate() {
        Fundraising_Campaign__c c = campaign();
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User u = new User(ProfileId = prof.Id, LastName = 'Visitor', Alias = 'visitor',
            Email = 'visitor@example.com', Username = 'visitor' + DateTime.now().getTime() + '@example.com',
            TimeZoneSidKey = 'America/Mexico_City', LocaleSidKey = 'es_MX',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'es');
        insert u;
        String attemptId;
        Test.startTest();
        System.runAs(u) {
            attemptId = DonationPaymentController.startDonation(request(c.Id));
            Boolean blocked = false;
            try {
                Database.query('SELECT Id FROM Payment_Attempt__c', AccessLevel.USER_MODE);
            } catch (QueryException e) {
                blocked = true;
            }
            Assert.isTrue(blocked, 'The caller must not be able to read attempts');
        }
        Test.stopTest();
        Assert.isNotNull(attemptId);
    }
}
