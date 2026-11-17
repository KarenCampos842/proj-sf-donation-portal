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

    private static DonationPaymentController.DonationRequest publicRequest(String publicName) {
        DonationPaymentController.DonationRequest r = request(campaign().Id);
        r.visibility = 'Public';
        r.publicName = publicName;
        return r;
    }

    private static Payment_Attempt__c savedAttempt(DonationPaymentController.DonationRequest r) {
        String attemptId = DonationPaymentController.startDonation(r);
        return [SELECT Visibility__c, Public_Name__c FROM Payment_Attempt__c WHERE Id = :attemptId WITH SYSTEM_MODE];
    }

    private static String startRejectionOf(DonationPaymentController.DonationRequest r) {
        String message;
        try {
            DonationPaymentController.startDonation(r);
        } catch (AuraHandledException e) {
            message = errorOf(e);
        }
        return message;
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
    static void startDonationSavesCleanPublicName_WhenNameHasScriptTag() {
        Test.startTest();
        Payment_Attempt__c attempt = savedAttempt(publicRequest('<script>alert(1)</script>'));
        Test.stopTest();
        Assert.areEqual('Public', attempt.Visibility__c, 'Visibility');
        Assert.areEqual('alert(1)', attempt.Public_Name__c, 'Tags are removed before the attempt is saved');
    }

    @IsTest
    static void startDonationKeepsWordsApart_WhenTagsSeparateThem() {
        Test.startTest();
        Payment_Attempt__c attempt = savedAttempt(publicRequest('Ana<b>López</b> Ruiz'));
        Test.stopTest();
        Assert.areEqual('Ana López Ruiz', attempt.Public_Name__c, 'A removed tag leaves a space between words');
    }

    @IsTest
    static void startDonationRemovesStandaloneAngleBrackets_WhenNameHasThem() {
        Test.startTest();
        Payment_Attempt__c attempt = savedAttempt(publicRequest('Ana <3 López > Ruiz'));
        Test.stopTest();
        Assert.areEqual('Ana 3 López Ruiz', attempt.Public_Name__c, 'No angle bracket is saved');
    }

    @IsTest
    static void startDonationRemovesAngleBrackets_WhenTagIsNeverClosed() {
        Test.startTest();
        Payment_Attempt__c attempt = savedAttempt(publicRequest('<img src=x onerror=alert(1)'));
        Test.stopTest();
        Assert.areEqual('img src=x onerror=alert(1)', attempt.Public_Name__c, 'No angle bracket is saved');
    }

    @IsTest
    static void startDonationKeepsPlainName_WhenItHasNoMarkup() {
        Test.startTest();
        Payment_Attempt__c attempt = savedAttempt(publicRequest('Familia Pérez'));
        Test.stopTest();
        Assert.areEqual('Familia Pérez', attempt.Public_Name__c, 'A plain name is saved as typed');
    }

    @IsTest
    static void startDonationRejectsName_WhenItIsEmptyAfterCleaning() {
        DonationPaymentController.DonationRequest r = publicRequest('<b></b>');
        Test.startTest();
        String message = startRejectionOf(r);
        Test.stopTest();
        Assert.areEqual(DonationPaymentController.PUBLIC_NAME_REQUIRED, message, 'Only markup leaves no name');
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is saved');
    }

    @IsTest
    static void startDonationRejectsName_WhenItIsOnlyAngleBrackets() {
        DonationPaymentController.DonationRequest r = publicRequest('<<>>');
        Test.startTest();
        String message = startRejectionOf(r);
        Test.stopTest();
        Assert.areEqual(DonationPaymentController.PUBLIC_NAME_REQUIRED, message, 'Brackets alone leave no name');
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is saved');
    }

    @IsTest
    static void startDonationRejectsName_WhenPublicDonationHasNoName() {
        DonationPaymentController.DonationRequest r = publicRequest(null);
        Test.startTest();
        String message = startRejectionOf(r);
        Test.stopTest();
        Assert.areEqual(DonationPaymentController.PUBLIC_NAME_REQUIRED, message, 'A public donation needs a name');
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is saved');
    }

    @IsTest
    static void startDonationAcceptsEightyCharacters_WhenNameHasExactlyThatMany() {
        Test.startTest();
        Payment_Attempt__c attempt = savedAttempt(publicRequest('a'.repeat(80)));
        Test.stopTest();
        Assert.areEqual('a'.repeat(80), attempt.Public_Name__c, 'The limit is inclusive');
    }

    @IsTest
    static void startDonationAcceptsEightyCharacters_WhenMarkupIsRemoved() {
        Test.startTest();
        Payment_Attempt__c attempt = savedAttempt(publicRequest('<b>' + 'a'.repeat(80) + '</b>'));
        Test.stopTest();
        Assert.areEqual('a'.repeat(80), attempt.Public_Name__c, 'The limit applies to the cleaned text');
    }

    @IsTest
    static void startDonationRejectsName_WhenItHasEightyOneCharacters() {
        DonationPaymentController.DonationRequest r = publicRequest('a'.repeat(81));
        Test.startTest();
        String message = startRejectionOf(r);
        Test.stopTest();
        Assert.areEqual(DonationPaymentController.PUBLIC_NAME_TOO_LONG, message, 'One character over the limit');
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is saved');
    }

    @IsTest
    static void startDonationRejectsName_WhenCleanedTextHasEightyOneCharacters() {
        DonationPaymentController.DonationRequest r = publicRequest('<b>' + 'a'.repeat(81) + '</b>');
        Test.startTest();
        String message = startRejectionOf(r);
        Test.stopTest();
        Assert.areEqual(DonationPaymentController.PUBLIC_NAME_TOO_LONG, message, 'The cleaned text is over the limit');
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is saved');
    }

    @IsTest
    static void startDonationSavesNoName_WhenDonationIsAnonymous() {
        DonationPaymentController.DonationRequest r = request(campaign().Id);
        r.publicName = '<script>' + 'a'.repeat(500) + '</script>';
        Test.startTest();
        Payment_Attempt__c attempt = savedAttempt(r);
        Test.stopTest();
        Assert.areEqual('Anonymous', attempt.Visibility__c, 'Visibility stays Anonymous');
        Assert.isNull(attempt.Public_Name__c, 'An anonymous donation never saves a name and is not rejected for it');
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
    static void paymentResultWithoutPaymentIdIsUnknown() {
        Test.startTest();
        String blank = DonationPaymentController.getPaymentResult('');
        String missing = DonationPaymentController.getPaymentResult(null);
        Test.stopTest();
        Assert.areEqual('Unknown', blank);
        Assert.areEqual('Unknown', missing);
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
