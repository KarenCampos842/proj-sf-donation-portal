@IsTest
private class MercadoPagoPreferenceActionTest {
    private static final String APPROVED_BODY =
        '{"id":"123-pref","init_point":"https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=123-pref"}';

    /**
     * Simulates Mercado Pago: a fixed status and body, or a timeout.
     */
    private class ProviderMock implements HttpCalloutMock {
        private final Integer status;
        private final String body;
        private final Boolean fail;
        public HttpRequest lastRequest;

        ProviderMock(Integer status, String body) {
            this.status = status;
            this.body = body;
            this.fail = false;
        }

        ProviderMock(Boolean fail) {
            this.fail = fail;
        }

        public HttpResponse respond(HttpRequest request) {
            lastRequest = request;
            if (fail) {
                throw new CalloutException('Read timed out');
            }
            HttpResponse response = new HttpResponse();
            response.setStatusCode(status);
            response.setBody(body);
            return response;
        }
    }

    private static MercadoPagoPreferenceAction.Request request() {
        MercadoPagoPreferenceAction.Request r = new MercadoPagoPreferenceAction.Request();
        r.attemptId = 'a0XATTEMPT000001';
        r.amount = 250;
        r.title = 'Donación: Boletos del evento';
        r.returnUrl = 'https://example.com/gracias';
        return r;
    }

    private static MercadoPagoPreferenceAction.Result call(MercadoPagoPreferenceAction.Request r) {
        return MercadoPagoPreferenceAction.createPreferences(new List<MercadoPagoPreferenceAction.Request>{ r })[0];
    }

    // ---- Action: provider responses (DON-19 TAC) ----

    @IsTest
    static void approvedResponseReturnsPreference() {
        ProviderMock mock = new ProviderMock(201, APPROVED_BODY);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        MercadoPagoPreferenceAction.Result result = call(request());
        Test.stopTest();

        Assert.isTrue(result.success);
        Assert.areEqual('123-pref', result.preferenceId);
        Assert.isTrue(result.checkoutUrl.startsWith('https://www.mercadopago.com.mx/'));
        Assert.isNull(result.errorType);

        Assert.areEqual('callout:MercadoPagoAPI/checkout/preferences', mock.lastRequest.getEndpoint());
        Assert.areEqual('POST', mock.lastRequest.getMethod());
        Assert.isNull(mock.lastRequest.getHeader('Authorization'), 'The token must come from the Named Credential');
        Map<String, Object> sent = (Map<String, Object>) JSON.deserializeUntyped(mock.lastRequest.getBody());
        Assert.areEqual('a0XATTEMPT000001', sent.get('external_reference'));
        Assert.areEqual('approved', sent.get('auto_return'));
        Map<String, Object> item = (Map<String, Object>) ((List<Object>) sent.get('items'))[0];
        Assert.areEqual(250.00, (Decimal) item.get('unit_price'));
        Assert.areEqual('MXN', item.get('currency_id'));
        Assert.areEqual(1, item.get('quantity'));
        Assert.isFalse(sent.containsKey('notification_url'));
        Assert.isFalse(mock.lastRequest.getBody().containsIgnoreCase('card'), 'No card data is ever sent');
    }

    @IsTest
    static void notificationUrlIsSentWhenGiven() {
        MercadoPagoPreferenceAction.Request r = request();
        r.notificationUrl = 'https://example.com/avisos';
        Map<String, Object> body = MercadoPagoPreferenceAction.buildBody(r);
        Assert.areEqual('https://example.com/avisos', body.get('notification_url'));
    }

    @IsTest
    static void providerErrorIsReported() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(400, '{"message":"invalid items"}'));
        Test.startTest();
        MercadoPagoPreferenceAction.Result result = call(request());
        Test.stopTest();
        Assert.isFalse(result.success);
        Assert.areEqual(MercadoPagoPreferenceAction.ERROR_PROVIDER, result.errorType);
    }

    @IsTest
    static void timeoutIsReported() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(true));
        Test.startTest();
        MercadoPagoPreferenceAction.Result result = call(request());
        Test.stopTest();
        Assert.isFalse(result.success);
        Assert.areEqual(MercadoPagoPreferenceAction.ERROR_UNAVAILABLE, result.errorType);
    }

    @IsTest
    static void malformedResponseIsReported() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, 'not json'));
        Test.startTest();
        MercadoPagoPreferenceAction.Result result = call(request());
        Test.stopTest();
        Assert.isFalse(result.success);
        Assert.areEqual(MercadoPagoPreferenceAction.ERROR_INVALID_RESPONSE, result.errorType);
    }

    @IsTest
    static void responseWithoutCheckoutUrlIsReported() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(201, '{"id":"123-pref"}'));
        Test.startTest();
        MercadoPagoPreferenceAction.Result result = call(request());
        Test.stopTest();
        Assert.isFalse(result.success);
        Assert.areEqual(MercadoPagoPreferenceAction.ERROR_INVALID_RESPONSE, result.errorType);
    }

    // ---- Flow Payment_Preference_Create end to end, with the provider simulated ----

    private static Payment_Attempt__c attempt(String campaignStatus) {
        Fundraising_Campaign__c c = new Fundraising_Campaign__c(Name = 'Boletos del evento', Description__c = 'd',
            Goal__c = 1000, Start_Date__c = Date.today(), Status__c = 'Active');
        Database.insert(c, AccessLevel.SYSTEM_MODE);
        Payment_Attempt__c a = new Payment_Attempt__c(Campaign__c = c.Id, Amount__c = 250,
            Email__c = 'donor@example.com', Visibility__c = 'Anonymous', Status__c = 'Started');
        Database.insert(a, AccessLevel.SYSTEM_MODE);
        if (campaignStatus != 'Active') {
            c.Status__c = campaignStatus;
            Database.update(c, AccessLevel.SYSTEM_MODE);
        }
        return a;
    }

    private static Flow.Interview runFlow(Id attemptId) {
        Flow.Interview i = Flow.Interview.createInterview('Payment_Preference_Create',
            new Map<String, Object>{ 'attemptId' => (String) attemptId });
        i.start();
        return i;
    }

    private static Integer attemptsLeft() {
        return [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE];
    }

    @IsTest
    static void flowReturnsCheckoutUrlAndSavesPreference() {
        Payment_Attempt__c a = attempt('Active');
        ProviderMock mock = new ProviderMock(201, APPROVED_BODY);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Flow.Interview i = runFlow(a.Id);
        Test.stopTest();

        Assert.isNull(i.getVariableValue('errorMessage'));
        Assert.isTrue(((String) i.getVariableValue('checkoutUrl')).contains('pref_id=123-pref'));
        Payment_Attempt__c saved = [SELECT Preference_Id__c, Status__c FROM Payment_Attempt__c WHERE Id = :a.Id WITH SYSTEM_MODE];
        Assert.areEqual('123-pref', saved.Preference_Id__c);
        Assert.areEqual('Started', saved.Status__c, 'Opening the payment must not confirm anything');
        Assert.areEqual(0, [SELECT COUNT() FROM Donation__c WITH SYSTEM_MODE], 'No donation before confirmation');

        Map<String, Object> sent = (Map<String, Object>) JSON.deserializeUntyped(mock.lastRequest.getBody());
        Assert.areEqual((String) a.Id, sent.get('external_reference'));
        Map<String, Object> item = (Map<String, Object>) ((List<Object>) sent.get('items'))[0];
        Assert.areEqual(250.00, (Decimal) item.get('unit_price'), 'Amount comes from the saved attempt');
        Assert.areEqual('Donación: Boletos del evento', item.get('title'));
    }

    @IsTest
    static void flowDeletesAttemptWhenProviderFails() {
        Payment_Attempt__c a = attempt('Active');
        Test.setMock(HttpCalloutMock.class, new ProviderMock(500, '{}'));
        Test.startTest();
        Flow.Interview i = runFlow(a.Id);
        Test.stopTest();
        Assert.areEqual('No pudimos abrir el pago, intenta de nuevo', i.getVariableValue('errorMessage'));
        Assert.isNull(i.getVariableValue('checkoutUrl'));
        Assert.areEqual(0, attemptsLeft(), 'No half-finished attempt is left (AC5)');
    }

    @IsTest
    static void flowDeletesAttemptWhenProviderTimesOut() {
        Payment_Attempt__c a = attempt('Active');
        Test.setMock(HttpCalloutMock.class, new ProviderMock(true));
        Test.startTest();
        Flow.Interview i = runFlow(a.Id);
        Test.stopTest();
        Assert.areEqual('No pudimos abrir el pago, intenta de nuevo', i.getVariableValue('errorMessage'));
        Assert.areEqual(0, attemptsLeft());
    }

    @IsTest
    static void flowStopsWhenCampaignNoLongerAcceptsDonations() {
        Payment_Attempt__c a = attempt('Paused');
        ProviderMock mock = new ProviderMock(201, APPROVED_BODY);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Flow.Interview i = runFlow(a.Id);
        Test.stopTest();
        Assert.areEqual('Esta campaña ya no acepta donaciones.', i.getVariableValue('errorMessage'));
        Assert.isNull(mock.lastRequest, 'Mercado Pago must not be called');
        Assert.areEqual(0, attemptsLeft());
    }

    @IsTest
    static void flowRejectsAttemptThatIsNotStarted() {
        Payment_Attempt__c a = attempt('Active');
        a.Status__c = 'Confirmed';
        Database.update(a, AccessLevel.SYSTEM_MODE);
        ProviderMock mock = new ProviderMock(201, APPROVED_BODY);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Flow.Interview i = runFlow(a.Id);
        Test.stopTest();
        Assert.areEqual('No pudimos abrir el pago, intenta de nuevo', i.getVariableValue('errorMessage'));
        Assert.isNull(mock.lastRequest);
        Assert.areEqual(1, attemptsLeft(), 'A confirmed attempt is never deleted here');
    }

    @IsTest
    static void flowOpensEachAttemptOnlyOnce() {
        Payment_Attempt__c a = attempt('Active');
        a.Preference_Id__c = 'already-opened';
        Database.update(a, AccessLevel.SYSTEM_MODE);
        ProviderMock mock = new ProviderMock(201, APPROVED_BODY);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Flow.Interview i = runFlow(a.Id);
        Test.stopTest();
        Assert.areEqual('No pudimos abrir el pago, intenta de nuevo', i.getVariableValue('errorMessage'));
        Assert.isNull(mock.lastRequest, 'Mercado Pago must not be called again');
        Assert.areEqual('already-opened',
            [SELECT Preference_Id__c FROM Payment_Attempt__c WHERE Id = :a.Id WITH SYSTEM_MODE].Preference_Id__c);
    }

    @IsTest
    static void flowRejectsUnknownAttempt() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(201, APPROVED_BODY));
        Test.startTest();
        Flow.Interview i = Flow.Interview.createInterview('Payment_Preference_Create',
            new Map<String, Object>{ 'attemptId' => 'abc' });
        i.start();
        Test.stopTest();
        Assert.areEqual('No pudimos abrir el pago, intenta de nuevo', i.getVariableValue('errorMessage'));
    }
}
