@IsTest
private class MercadoPagoPaymentLookupActionTest {
    /**
     * Simulates Mercado Pago: a fixed status and body, or a timeout.
     */
    private class ProviderMock implements HttpCalloutMock {
        private final Integer status;
        private final String body;
        private final Boolean fail;
        public Integer calls = 0;
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
            calls++;
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

    private static String payment(String status, String externalReference, Decimal amount) {
        Map<String, Object> body = new Map<String, Object>{
            'id' => 1234567890L,
            'status' => status,
            'external_reference' => externalReference,
            'transaction_amount' => amount,
            'currency_id' => 'MXN',
            'date_approved' => status == 'approved' ? '2026-11-09T12:00:00.000-06:00' : null
        };
        return JSON.serialize(body);
    }

    private static MercadoPagoPaymentLookupAction.Result lookup(String paymentId) {
        MercadoPagoPaymentLookupAction.Request r = new MercadoPagoPaymentLookupAction.Request();
        r.paymentId = paymentId;
        return MercadoPagoPaymentLookupAction.lookupPayments(new List<MercadoPagoPaymentLookupAction.Request>{ r })[0];
    }

    // ---- Action: provider responses ----

    @IsTest
    static void approvedPaymentIsRead() {
        ProviderMock mock = new ProviderMock(200, payment('approved', 'a0XATTEMPT', 250));
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        MercadoPagoPaymentLookupAction.Result r = lookup('1234567890');
        Test.stopTest();

        Assert.isTrue(r.found);
        Assert.areEqual('1234567890', r.paymentId);
        Assert.areEqual('approved', r.status);
        Assert.areEqual('a0XATTEMPT', r.externalReference);
        Assert.areEqual((Decimal) 250, r.transactionAmount);
        Assert.areEqual(DateTime.newInstanceGmt(2026, 11, 9, 18, 0, 0), r.dateApproved);
        Assert.areEqual('callout:MercadoPagoAPI/v1/payments/1234567890', mock.lastRequest.getEndpoint());
        Assert.areEqual('GET', mock.lastRequest.getMethod());
        Assert.isNull(mock.lastRequest.getHeader('Authorization'), 'The token must come from the Named Credential');
    }

    @IsTest
    static void nonNumericIdIsRejectedWithoutCallout() {
        ProviderMock mock = new ProviderMock(200, payment('approved', 'x', 1));
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        MercadoPagoPaymentLookupAction.Result r = lookup('123/../../users/me');
        Test.stopTest();
        Assert.isFalse(r.found);
        Assert.areEqual(MercadoPagoPaymentLookupAction.ERROR_INVALID_ID, r.errorType);
        Assert.areEqual(0, mock.calls);
    }

    @IsTest
    static void unknownPaymentIsNotFound() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(404, '{"message":"Payment not found"}'));
        Test.startTest();
        MercadoPagoPaymentLookupAction.Result r = lookup('999');
        Test.stopTest();
        Assert.areEqual(MercadoPagoPaymentLookupAction.ERROR_NOT_FOUND, r.errorType);
    }

    @IsTest
    static void providerErrorIsReported() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(500, '{}'));
        Test.startTest();
        MercadoPagoPaymentLookupAction.Result r = lookup('999');
        Test.stopTest();
        Assert.areEqual(MercadoPagoPaymentLookupAction.ERROR_PROVIDER, r.errorType);
    }

    @IsTest
    static void timeoutIsReported() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(true));
        Test.startTest();
        MercadoPagoPaymentLookupAction.Result r = lookup('999');
        Test.stopTest();
        Assert.areEqual(MercadoPagoPaymentLookupAction.ERROR_UNAVAILABLE, r.errorType);
    }

    @IsTest
    static void otherCurrencyIsInvalid() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', 'x', 250).replace('MXN', 'USD')));
        Test.startTest();
        MercadoPagoPaymentLookupAction.Result r = lookup('999');
        Test.stopTest();
        Assert.isFalse(r.found);
        Assert.areEqual(MercadoPagoPaymentLookupAction.ERROR_INVALID_RESPONSE, r.errorType);
    }

    @IsTest
    static void malformedResponseIsInvalid() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, 'not json'));
        Test.startTest();
        MercadoPagoPaymentLookupAction.Result r = lookup('999');
        Test.stopTest();
        Assert.areEqual(MercadoPagoPaymentLookupAction.ERROR_INVALID_RESPONSE, r.errorType);
    }

    // ---- Flow Payment_Return_Process end to end, with the provider simulated ----

    private static Payment_Attempt__c attempt() {
        Fundraising_Campaign__c c = new Fundraising_Campaign__c(Name = 'Boletos del evento', Description__c = 'd',
            Goal__c = 1000, Start_Date__c = Date.today(), Status__c = 'Active');
        Database.insert(c, AccessLevel.SYSTEM_MODE);
        Payment_Attempt__c a = new Payment_Attempt__c(Campaign__c = c.Id, Amount__c = 250,
            Email__c = 'donor@example.com', Visibility__c = 'Anonymous', Status__c = 'Started');
        Database.insert(a, AccessLevel.SYSTEM_MODE);
        return a;
    }

    private static String runFlow(String paymentId) {
        Flow.Interview i = Flow.Interview.createInterview('Payment_Return_Process',
            new Map<String, Object>{ 'paymentId' => paymentId });
        i.start();
        return (String) i.getVariableValue('resultState');
    }

    private static Integer donations() {
        return [SELECT COUNT() FROM Donation__c WITH SYSTEM_MODE];
    }

    private static String attemptStatus(Id attemptId) {
        return [SELECT Status__c FROM Payment_Attempt__c WHERE Id = :attemptId WITH SYSTEM_MODE].Status__c;
    }

    @IsTest
    static void approvedPaymentIsConfirmedAndRegistered() {
        Payment_Attempt__c a = attempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', a.Id, 250)));
        Test.startTest();
        String state = runFlow('1234567890');
        Test.stopTest();
        Assert.areEqual('Confirmed', state);
        Donation__c d = [SELECT Provider_Payment_Id__c, Amount__c, Confirmed_At__c FROM Donation__c WITH SYSTEM_MODE];
        Assert.areEqual('1234567890', d.Provider_Payment_Id__c);
        Assert.areEqual((Decimal) 250, d.Amount__c);
        Assert.areEqual(DateTime.newInstanceGmt(2026, 11, 9, 18, 0, 0), d.Confirmed_At__c);
        Assert.areEqual('Confirmed', attemptStatus(a.Id));
    }

    @IsTest
    static void reloadingThePageDoesNotDuplicate() {
        // Each page load is its own transaction; the first load is simulated by the
        // donation it would have registered.
        Payment_Attempt__c a = attempt();
        Database.insert(new Donation__c(Campaign__c = a.Campaign__c, Amount__c = 250, Visibility__c = 'Anonymous',
            Payment_Status__c = 'Confirmed', Provider_Payment_Id__c = '1234567890'), AccessLevel.SYSTEM_MODE);
        a.Status__c = 'Confirmed';
        Database.update(a, AccessLevel.SYSTEM_MODE);
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', a.Id, 250)));
        Test.startTest();
        String state = runFlow('1234567890');
        Test.stopTest();
        Assert.areEqual('Confirmed', state);
        Assert.areEqual(1, donations());
    }

    @IsTest
    static void pendingPaymentIsNotConfirmed() {
        Payment_Attempt__c a = attempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('in_process', a.Id, 250)));
        Test.startTest();
        String state = runFlow('1234567890');
        Test.stopTest();
        Assert.areEqual('Pending', state);
        Assert.areEqual(0, donations());
        Assert.areEqual('Started', attemptStatus(a.Id));
    }

    @IsTest
    static void rejectedPaymentIsReported() {
        Payment_Attempt__c a = attempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('rejected', a.Id, 250)));
        Test.startTest();
        String state = runFlow('1234567890');
        Test.stopTest();
        Assert.areEqual('Rejected', state);
        Assert.areEqual(0, donations());
        Assert.areEqual('Rejected', attemptStatus(a.Id));
    }

    @IsTest
    static void cancelledPaymentIsReported() {
        Payment_Attempt__c a = attempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('cancelled', a.Id, 250)));
        Test.startTest();
        String state = runFlow('1234567890');
        Test.stopTest();
        Assert.areEqual('Cancelled', state);
        Assert.areEqual('Cancelled', attemptStatus(a.Id));
    }

    @IsTest
    static void returnWithoutPaymentMeansNotCompleted() {
        ProviderMock mock = new ProviderMock(200, payment('approved', 'x', 1));
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Assert.areEqual('NoPayment', runFlow(null));
        Assert.areEqual('NoPayment', runFlow('null'));
        Test.stopTest();
        Assert.areEqual(0, mock.calls, 'Nothing to ask the provider');
    }

    @IsTest
    static void providerDownIsUnknownNotRejected() {
        Payment_Attempt__c a = attempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(true));
        Test.startTest();
        String state = runFlow('1234567890');
        Test.stopTest();
        Assert.areEqual('Unknown', state);
        Assert.areEqual('Started', attemptStatus(a.Id));
    }

    @IsTest
    static void tamperedIdIsUnknown() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', 'x', 1)));
        Test.startTest();
        String state = runFlow('123?status=approved');
        Test.stopTest();
        Assert.areEqual('Unknown', state);
        Assert.areEqual(0, donations());
    }

    @IsTest
    static void approvedWithWrongAmountIsUnknown() {
        Payment_Attempt__c a = attempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', a.Id, 1)));
        Test.startTest();
        String state = runFlow('1234567890');
        Test.stopTest();
        Assert.areEqual('Unknown', state);
        Assert.areEqual(0, donations());
    }

    @IsTest
    static void approvedForUnknownAttemptIsUnknown() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', 'prueba-sin-intento', 250)));
        Test.startTest();
        String state = runFlow('1234567890');
        Test.stopTest();
        Assert.areEqual('Unknown', state);
        Assert.areEqual(0, donations());
    }
}
