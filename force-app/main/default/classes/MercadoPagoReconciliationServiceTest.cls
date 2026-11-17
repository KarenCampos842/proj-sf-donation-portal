@IsTest
private class MercadoPagoReconciliationServiceTest {
    private static final String PAYMENT_ID = '1234567890';

    /**
     * Simulates GET /v1/payments/search. Each page is chosen by the offset of the request.
     */
    private class SearchMock implements HttpCalloutMock {
        private final Map<Integer, List<Object>> pages;
        private final Integer status;
        private final Boolean fail;
        public List<String> endpoints = new List<String>();

        SearchMock(Map<Integer, List<Object>> pages) {
            this.pages = pages;
            this.status = 200;
            this.fail = false;
        }

        SearchMock(Integer status, Boolean fail) {
            this.pages = new Map<Integer, List<Object>>();
            this.status = status;
            this.fail = fail;
        }

        public HttpResponse respond(HttpRequest request) {
            endpoints.add(request.getEndpoint());
            if (fail) {
                throw new CalloutException('Read timed out');
            }
            Integer offset = Integer.valueOf(request.getEndpoint().substringAfter('&offset='));
            List<Object> results = pages.containsKey(offset) ? pages.get(offset) : new List<Object>();
            HttpResponse response = new HttpResponse();
            response.setStatusCode(status);
            response.setBody(JSON.serialize(new Map<String, Object>{ 'results' => results }));
            return response;
        }
    }

    // ---- Helpers ----

    private static Payment_Attempt__c attempt(Integer minutesAgo) {
        Fundraising_Campaign__c c = PortalTestDataFactory.buildCampaign('Boletos del evento', 'Active', Date.today(), null);
        Database.insert(c, AccessLevel.SYSTEM_MODE);
        Payment_Attempt__c a = new Payment_Attempt__c(Campaign__c = c.Id, Amount__c = 250,
            Email__c = 'donor@example.com', Visibility__c = 'Anonymous', Status__c = 'Started');
        Database.insert(a, AccessLevel.SYSTEM_MODE);
        Test.setCreatedDate(a.Id, DateTime.now().addMinutes(-minutesAgo));
        return a;
    }

    private static Map<String, Object> payment(String id, String status, String externalReference, Decimal amount) {
        return new Map<String, Object>{
            'id' => Long.valueOf(id),
            'status' => status,
            'external_reference' => externalReference,
            'transaction_amount' => amount,
            'currency_id' => 'MXN',
            'date_approved' => status == 'approved' ? '2026-11-09T12:00:00.000-06:00' : null
        };
    }

    private static SearchMock onePage(List<Object> results) {
        return new SearchMock(new Map<Integer, List<Object>>{ 0 => results });
    }

    private static MercadoPagoReconciliationService.Summary run(HttpCalloutMock mock) {
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        MercadoPagoReconciliationService.Summary summary = MercadoPagoReconciliationService.run();
        Test.stopTest();
        return summary;
    }

    private static List<Donation__c> donations() {
        return [SELECT Amount__c, Provider_Payment_Id__c, Attempt_Id__c FROM Donation__c WITH SYSTEM_MODE];
    }

    private static String statusOf(Payment_Attempt__c a) {
        return [SELECT Status__c FROM Payment_Attempt__c WHERE Id = :a.Id WITH SYSTEM_MODE].Status__c;
    }

    // ---- PAY-08 ----

    @IsTest
    static void approvedPaymentWithoutNoticeIsRegistered() {
        // AC1: approved in Mercado Pago, no notice and no return: the donation is registered.
        Payment_Attempt__c a = attempt(60);
        MercadoPagoReconciliationService.Summary summary = run(onePage(new List<Object>{
            payment(PAYMENT_ID, 'approved', a.Id, 250)
        }));
        List<Donation__c> ds = donations();
        Assert.areEqual(1, ds.size(), 'The missing donation is registered');
        Assert.areEqual(PAYMENT_ID, ds[0].Provider_Payment_Id__c);
        Assert.areEqual((Decimal) 250, ds[0].Amount__c, 'The amount comes from Mercado Pago');
        Assert.areEqual('Confirmed', statusOf(a));
        Assert.areEqual(1, summary.registered);
    }

    @IsTest
    static void paymentRegisteredMeanwhileIsNotDuplicated() {
        // AC2: the webhook or the return page registered it, but the attempt still looks Started.
        Payment_Attempt__c a = attempt(60);
        Database.insert(new Donation__c(Campaign__c = a.Campaign__c, Amount__c = 250, Visibility__c = 'Anonymous',
            Payment_Status__c = 'Confirmed', Provider_Payment_Id__c = PAYMENT_ID, Attempt_Id__c = a.Id),
            AccessLevel.SYSTEM_MODE);
        MercadoPagoReconciliationService.Summary summary = run(onePage(new List<Object>{
            payment(PAYMENT_ID, 'approved', a.Id, 250)
        }));
        Assert.areEqual(1, donations().size(), 'No second donation');
        Assert.areEqual(0, summary.registered);
    }

    @IsTest
    static void confirmedAttemptIsNotLookedAtAgain() {
        // AC2: an attempt that is already Confirmed is not a candidate.
        Payment_Attempt__c a = attempt(60);
        a.Status__c = 'Confirmed';
        Database.update(a, AccessLevel.SYSTEM_MODE);
        MercadoPagoReconciliationService.Summary summary = run(onePage(new List<Object>{
            payment(PAYMENT_ID, 'approved', a.Id, 250)
        }));
        Assert.areEqual(0, summary.candidates);
        Assert.areEqual(0, donations().size());
    }

    @IsTest
    static void paymentsThatAreNotApprovedAreIgnored() {
        // AC3: rejected, pending or no payment at all: nothing is registered.
        Payment_Attempt__c rejected = attempt(60);
        Payment_Attempt__c pending = attempt(60);
        Payment_Attempt__c abandoned = attempt(60);
        MercadoPagoReconciliationService.Summary summary = run(onePage(new List<Object>{
            payment('1111111111', 'rejected', rejected.Id, 250),
            payment('2222222222', 'in_process', pending.Id, 250)
        }));
        Assert.areEqual(0, donations().size());
        Assert.areEqual(0, summary.candidates);
        Assert.areEqual('Started', statusOf(rejected), 'The webhook or the return page decide rejections');
        Assert.areEqual('Started', statusOf(abandoned), 'An attempt without a payment is left for PAY-07');
    }

    @IsTest
    static void providerDownChangesNothing() {
        // AC4: Mercado Pago does not answer: nothing changes, the next run tries again.
        Payment_Attempt__c a = attempt(60);
        MercadoPagoReconciliationService.Summary summary = run(new SearchMock(null, true));
        Assert.isTrue(summary.providerFailed);
        Assert.areEqual(0, donations().size());
        Assert.areEqual('Started', statusOf(a));
    }

    @IsTest
    static void providerErrorChangesNothing() {
        // AC4 with an HTTP error instead of a timeout.
        Payment_Attempt__c a = attempt(60);
        MercadoPagoReconciliationService.Summary summary = run(new SearchMock(500, false));
        Assert.isTrue(summary.providerFailed);
        Assert.areEqual(0, donations().size());
        Assert.areEqual('Started', statusOf(a));
    }

    @IsTest
    static void recentAttemptIsLeftToTheWebhook() {
        // Attempts younger than 30 minutes are left to the webhook and the return page.
        Payment_Attempt__c a = attempt(5);
        MercadoPagoReconciliationService.Summary summary = run(onePage(new List<Object>{
            payment(PAYMENT_ID, 'approved', a.Id, 250)
        }));
        Assert.areEqual(0, summary.candidates);
        Assert.areEqual(0, donations().size());
    }

    @IsTest
    static void amountMismatchIsNotRegistered() {
        // The amount always comes from Mercado Pago; a different amount is not registered (ADM-12 logs it).
        Payment_Attempt__c a = attempt(60);
        MercadoPagoReconciliationService.Summary summary = run(onePage(new List<Object>{
            payment(PAYMENT_ID, 'approved', a.Id, 999)
        }));
        Assert.areEqual(0, donations().size());
        Assert.areEqual(1, summary.notRegistered);
    }

    @IsTest
    static void foreignReferencesAreIgnored() {
        // Payments of other integrations (no reference, text, or an id of another object) are skipped.
        Payment_Attempt__c a = attempt(60);
        MercadoPagoReconciliationService.Summary summary = run(onePage(new List<Object>{
            payment('3333333333', 'approved', null, 250),
            payment('4444444444', 'approved', 'pedido-123', 250),
            payment('5555555555', 'approved', a.Campaign__c, 250)
        }));
        Assert.areEqual(3, summary.paymentsRead);
        Assert.areEqual(0, summary.candidates);
        Assert.areEqual(0, donations().size());
    }

    @IsTest
    static void nextPageIsReadWhenThePageIsFull() {
        Payment_Attempt__c a = attempt(60);
        List<Object> fullPage = new List<Object>();
        for (Integer i = 0; i < MercadoPagoReconciliationService.PAGE_SIZE; i++) {
            fullPage.add(payment(String.valueOf(9000000000L + i), 'approved', 'otro-' + i, 100));
        }
        SearchMock mock = new SearchMock(new Map<Integer, List<Object>>{
            0 => fullPage,
            MercadoPagoReconciliationService.PAGE_SIZE => new List<Object>{ payment(PAYMENT_ID, 'approved', a.Id, 250) }
        });
        MercadoPagoReconciliationService.Summary summary = run(mock);
        Assert.areEqual(2, mock.endpoints.size(), 'A full page means there may be more');
        Assert.areEqual(1, summary.registered);
        Assert.isTrue(mock.endpoints[0].startsWith('callout:MercadoPagoAPI/v1/payments/search?'));
        Assert.isTrue(mock.endpoints[0].contains('status=approved'));
    }

    @IsTest
    static void scheduledJobRunsTheReconciliation() {
        Payment_Attempt__c a = attempt(60);
        Test.setMock(HttpCalloutMock.class, onePage(new List<Object>{ payment(PAYMENT_ID, 'approved', a.Id, 250) }));
        Test.startTest();
        new MercadoPagoReconciliationJob().execute((SchedulableContext) null);
        Test.stopTest();
        Assert.areEqual(1, donations().size(), 'The scheduled job queues the reconciliation');
    }

    @IsTest
    static void summaryIsReadable() {
        MercadoPagoReconciliationService.Summary summary = new MercadoPagoReconciliationService.Summary();
        summary.providerFailed = true;
        Assert.isTrue(summary.toString().contains('Mercado Pago no respondió'));
    }

    @IsTest
    static void paymentInAnotherCurrencyIsNotFound() {
        Map<String, Object> body = payment(PAYMENT_ID, 'approved', 'x', 250);
        body.put('currency_id', 'USD');
        Assert.isFalse(MercadoPagoPaymentLookupAction.fromPayment(body).found);
        body.put('transaction_amount', 'no es número');
        Assert.isFalse(MercadoPagoPaymentLookupAction.fromPayment(body).found);
    }
}
