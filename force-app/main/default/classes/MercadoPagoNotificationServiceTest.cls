@IsTest
private class MercadoPagoNotificationServiceTest {
    private static final String SECRET = 'test-webhook-secret';
    private static final Long NOW_MS = 1763300000000L;
    private static final String PAYMENT_ID = '1234567890';

    /**
     * Simulates GET /v1/payments/{id}.
     */
    private class ProviderMock implements HttpCalloutMock {
        private final Integer status;
        private final String body;
        private final Boolean fail;
        public Integer calls = 0;

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
            if (fail) {
                throw new CalloutException('Read timed out');
            }
            HttpResponse response = new HttpResponse();
            response.setStatusCode(status);
            response.setBody(body);
            return response;
        }
    }

    @TestSetup
    static void setup() {
        Database.insert(new Mercado_Pago_Webhook__c(SetupOwnerId = UserInfo.getOrganizationId(), Secret__c = SECRET),
            AccessLevel.SYSTEM_MODE);
        PortalTestDataFactory.createSimulatedGuest();
    }

    // ---- Helpers ----

    private static Payment_Attempt__c attempt() {
        Fundraising_Campaign__c c = PortalTestDataFactory.buildCampaign('Boletos del evento', 'Active', Date.today(), null);
        Database.insert(c, AccessLevel.SYSTEM_MODE);
        Payment_Attempt__c a = new Payment_Attempt__c(Campaign__c = c.Id, Amount__c = 250,
            Email__c = 'donor@example.com', Visibility__c = 'Anonymous', Status__c = 'Started');
        Database.insert(a, AccessLevel.SYSTEM_MODE);
        return a;
    }

    private static String payment(String status, String externalReference, Decimal amount) {
        return JSON.serialize(new Map<String, Object>{
            'id' => Long.valueOf(PAYMENT_ID),
            'status' => status,
            'external_reference' => externalReference,
            'transaction_amount' => amount,
            'currency_id' => 'MXN',
            'date_approved' => status == 'approved' ? '2026-11-09T12:00:00.000-06:00' : null
        });
    }

    // A notice signed the way Mercado Pago signs it.
    private static MercadoPagoNotificationService.Notice notice(String dataId, String type) {
        String ts = String.valueOf(NOW_MS / 1000L);
        MercadoPagoNotificationService.Notice n = new MercadoPagoNotificationService.Notice();
        n.dataId = dataId;
        n.type = type;
        n.requestId = 'req-' + dataId;
        String v1 = EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256',
            Blob.valueOf('id:' + dataId + ';request-id:' + n.requestId + ';ts:' + ts + ';'), Blob.valueOf(SECRET)));
        n.signature = 'ts=' + ts + ',v1=' + v1;
        return n;
    }

    private static Integer process(MercadoPagoNotificationService.Notice n) {
        MercadoPagoNotificationService.nowMs = NOW_MS;
        return MercadoPagoNotificationService.process(n);
    }

    private static List<Donation__c> donations() {
        return [SELECT Amount__c, Provider_Payment_Id__c, Confirmed_At__c FROM Donation__c WITH SYSTEM_MODE];
    }

    private static List<Rejected_Notice__c> notices() {
        return [SELECT Reason__c, Detail__c, Technical_Id__c, Received_At__c FROM Rejected_Notice__c WITH SYSTEM_MODE];
    }

    private static Donation__c existingDonation(Payment_Attempt__c a) {
        Donation__c d = new Donation__c(Campaign__c = a.Campaign__c, Amount__c = 250, Visibility__c = 'Anonymous',
            Payment_Status__c = 'Confirmed', Provider_Payment_Id__c = PAYMENT_ID, Attempt_Id__c = a.Id);
        Database.insert(d, AccessLevel.SYSTEM_MODE);
        a.Status__c = 'Confirmed';
        Database.update(a, AccessLevel.SYSTEM_MODE);
        return d;
    }

    // ---- PAY-06 / PAY-01 ----

    @IsTest
    static void authenticApprovedNoticeRegistersTheDonation() {
        // PAY-06 AC1, PAY-01 AC1. Run as the simulated guest: no permission on any object.
        Payment_Attempt__c a = attempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', a.Id, 250)));
        Integer status;
        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            status = process(notice(PAYMENT_ID, 'payment'));
        }
        Test.stopTest();
        Assert.areEqual(200, status);
        List<Donation__c> ds = donations();
        Assert.areEqual(1, ds.size());
        Assert.areEqual(PAYMENT_ID, ds[0].Provider_Payment_Id__c);
        Assert.areEqual((Decimal) 250, ds[0].Amount__c);
        Assert.areEqual(0, notices().size(), 'An accepted notice is not in the rejection history (ADM-12 AC2)');
    }

    @IsTest
    static void rejectedPaymentCreatesNoDonation() {
        // PAY-06 AC2
        Payment_Attempt__c a = attempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('rejected', a.Id, 250)));
        Test.startTest();
        Integer status = process(notice(PAYMENT_ID, 'payment'));
        Test.stopTest();
        Assert.areEqual(200, status);
        Assert.areEqual(0, donations().size());
    }

    @IsTest
    static void refundIsLoggedAndIgnored() {
        // PAY-06 AC3
        Payment_Attempt__c a = attempt();
        existingDonation(a);
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('refunded', a.Id, 250)));
        Test.startTest();
        Integer status = process(notice(PAYMENT_ID, 'payment'));
        Test.stopTest();
        Assert.areEqual(200, status);
        Assert.areEqual(1, donations().size(), 'The donation is not changed');
        Assert.areEqual('Refund_Ignored', notices()[0].Reason__c);
    }

    @IsTest
    static void paymentWithoutAnAttemptChangesNothing() {
        // PAY-06 AC4: the reference points to an attempt that does not exist.
        Payment_Attempt__c a = attempt();
        Id missingAttemptId = a.Id;
        Database.delete(a, AccessLevel.SYSTEM_MODE);
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', missingAttemptId, 250)));
        Test.startTest();
        Integer status = process(notice(PAYMENT_ID, 'payment'));
        Test.stopTest();
        Assert.areEqual(200, status);
        Assert.areEqual(0, donations().size());
        Assert.areEqual('Attempt_Not_Found', notices()[0].Reason__c);
    }

    @IsTest
    static void providerDownLeavesNothingHalfDone() {
        // PAY-06 AC5: Mercado Pago will retry; nothing is saved meanwhile.
        attempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(true));
        Test.startTest();
        Integer status = process(notice(PAYMENT_ID, 'payment'));
        Test.stopTest();
        Assert.areEqual(500, status);
        Assert.areEqual(0, donations().size());
    }

    @IsTest
    static void unknownPaymentIsLogged() {
        Test.setMock(HttpCalloutMock.class, new ProviderMock(404, '{"message":"not found"}'));
        Test.startTest();
        Integer status = process(notice('555', 'payment'));
        Test.stopTest();
        Assert.areEqual(200, status);
        Assert.areEqual('Attempt_Not_Found', notices()[0].Reason__c);
    }

    @IsTest
    static void otherNoticeTypesAreNotProcessed() {
        // PAY-06 TAC: only "payment".
        ProviderMock mock = new ProviderMock(200, '{}');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Integer status = process(notice('123456789012', 'merchant_order'));
        Test.stopTest();
        Assert.areEqual(200, status);
        Assert.areEqual(0, mock.calls);
        Rejected_Notice__c n = notices()[0];
        Assert.areEqual('Unsupported_Type', n.Reason__c);
        Assert.areEqual('Tipo recibido: merchant_order', n.Detail__c);
    }

    @IsTest
    static void alteredNoticeIsRejectedAndVisible() {
        // PAY-01 AC2 and AC3, ADM-12 AC1 and AC3.
        Payment_Attempt__c a = attempt();
        ProviderMock mock = new ProviderMock(200, payment('approved', a.Id, 250));
        Test.setMock(HttpCalloutMock.class, mock);
        MercadoPagoNotificationService.Notice n = notice(PAYMENT_ID, 'payment');
        n.dataId = '9876543210';
        Test.startTest();
        Integer status = process(n);
        Test.stopTest();
        Assert.areEqual(400, status);
        Assert.areEqual(0, mock.calls, 'Nothing is asked to the provider before the signature is valid');
        Assert.areEqual(0, donations().size());
        Rejected_Notice__c rejected = notices()[0];
        Assert.areEqual('Invalid_Signature', rejected.Reason__c);
        Assert.areEqual('9876…3210', rejected.Technical_Id__c, 'Data from an unauthenticated notice is masked');
        Assert.isNotNull(rejected.Received_At__c);
    }

    @IsTest
    static void lateNoticeIsRejected() {
        // PAY-01 AC4
        MercadoPagoNotificationService.Notice n = notice(PAYMENT_ID, 'payment');
        Test.startTest();
        MercadoPagoNotificationService.nowMs = NOW_MS + 10L * 60L * 1000L;
        Integer status = MercadoPagoNotificationService.process(n);
        Test.stopTest();
        Assert.areEqual(400, status);
        Assert.areEqual('El aviso llegó fuera de la ventana de 5 minutos.', notices()[0].Detail__c);
    }

    @IsTest
    static void unsignedNoticeIsRejected() {
        MercadoPagoNotificationService.Notice n = notice(PAYMENT_ID, 'payment');
        n.signature = null;
        Test.startTest();
        Integer status = process(n);
        Test.stopTest();
        Assert.areEqual(400, status);
        Assert.areEqual('El aviso no trae firma.', notices()[0].Detail__c);
    }

    @IsTest
    static void missingSecretAsksForARetry() {
        Database.delete([SELECT Id FROM Mercado_Pago_Webhook__c WITH SYSTEM_MODE], AccessLevel.SYSTEM_MODE);
        Test.startTest();
        Integer status = process(notice(PAYMENT_ID, 'payment'));
        Test.stopTest();
        Assert.areEqual(500, status);
        Assert.areEqual(0, donations().size());
    }

    // ---- PAY-03 ----

    @IsTest
    static void repeatedNoticeDoesNotDuplicate() {
        // PAY-03 AC1 and AC2: the first notice (or the return page) already registered the
        // payment; each notice is its own transaction, so the first one is simulated by
        // the donation it created.
        Payment_Attempt__c a = attempt();
        existingDonation(a);
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', a.Id, 250)));
        Test.startTest();
        Integer status = process(notice(PAYMENT_ID, 'payment'));
        Test.stopTest();
        Assert.areEqual(200, status, 'A repeated notice is answered 200 so it is not retried');
        Assert.areEqual(1, donations().size());
        Assert.areEqual('Duplicate_Notice', notices()[0].Reason__c);
    }

    // ---- DON-24 ----

    @IsTest
    static void paymentConfirmedAfterTheCampaignClosedIsRegistered() {
        // DON-24 AC1: the attempt was valid when created; the campaign closed later.
        Payment_Attempt__c a = attempt();
        Database.update(new Fundraising_Campaign__c(Id = a.Campaign__c, Status__c = 'Closed'), AccessLevel.SYSTEM_MODE);
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', a.Id, 250)));
        Test.startTest();
        Integer status = process(notice(PAYMENT_ID, 'payment'));
        Test.stopTest();
        Assert.areEqual(200, status);
        List<Donation__c> ds = donations();
        Assert.areEqual(1, ds.size());
        Assert.areEqual(DateTime.newInstanceGmt(2026, 11, 9, 18, 0, 0), ds[0].Confirmed_At__c,
            'The date documents when the donor paid (date_approved)');
    }

    // ---- REST entry ----

    @IsTest
    static void restEntryReadsHeadersAndQuery() {
        Payment_Attempt__c a = attempt();
        Test.setMock(HttpCalloutMock.class, new ProviderMock(200, payment('approved', a.Id, 250)));
        MercadoPagoNotificationService.Notice signed = notice(PAYMENT_ID, 'payment');
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestURI = '/services/apexrest/mp/notifications';
        request.addParameter('data.id', PAYMENT_ID);
        request.addParameter('type', 'payment');
        request.addHeader('X-Signature', signed.signature);
        request.addHeader('x-request-id', signed.requestId);
        request.requestBody = Blob.valueOf('{"action":"payment.created","type":"payment","data":{"id":"' + PAYMENT_ID + '"}}');
        RestContext.request = request;
        RestContext.response = new RestResponse();
        MercadoPagoNotificationService.nowMs = NOW_MS;
        Test.startTest();
        MercadoPagoWebhookResource.receive();
        Test.stopTest();
        Assert.areEqual(200, RestContext.response.statusCode);
        Assert.areEqual(1, donations().size());
    }

    @IsTest
    static void restEntryFallsBackToTheBody() {
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{"type":"payment","data":{"id":"42"}}');
        RestContext.request = request;
        RestContext.response = new RestResponse();
        Test.startTest();
        MercadoPagoWebhookResource.receive();
        Test.stopTest();
        Assert.areEqual(400, RestContext.response.statusCode, 'No signature');
        Assert.areEqual('****', notices()[0].Technical_Id__c);
    }

    @IsTest
    static void maskKeepsOnlyTheEnds() {
        Assert.isNull(MercadoPagoNotificationService.mask(null));
        Assert.areEqual('****', MercadoPagoNotificationService.mask('12345'));
        Assert.areEqual('abcd…6789', MercadoPagoNotificationService.mask('abcd<script>456789'.replace('<script>', '-x-')));
    }
}
