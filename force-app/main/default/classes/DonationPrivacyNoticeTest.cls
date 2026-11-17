/**
 * DON-13: acceptance of the privacy notice when an invoice is requested. Covers the controller called
 * directly (as the site guest can do), the flows that save and copy the acceptance, the portal
 * service, and the two ways a payment is confirmed (return page and webhook), which share the
 * Donation_Register flow. Runs against the real flows, as the guest simulation user.
 */
@IsTest
private class DonationPrivacyNoticeTest {
    private static final String OPEN_CAMPAIGN = 'Campaña abierta DON-13';
    private static final String PERSON_RFC = 'GODE561231GR8';
    private static final String NOTICE_REQUIRED = 'Acepta el aviso de privacidad para solicitar factura.';

    private class ProviderMock implements HttpCalloutMock {
        private final String body;

        ProviderMock(String body) {
            this.body = body;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(body);
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

    // AC3: the server refuses an invoice request without acceptance

    @IsTest
    static void shouldRejectInvoiceRequest_WhenPrivacyNoticeIsNotAccepted() {
        for (Boolean accepted : new List<Boolean>{ false, null }) {
            DonationPaymentController.DonationRequest request = invoiceRequest();
            request.privacyNoticeAccepted = accepted;

            assertControllerRejects(request, 'accepted=' + accepted);
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is created without acceptance');
    }

    @IsTest
    static void shouldRejectInvoiceRequest_WhenTheFieldIsOmittedByADirectCall() {
        DonationPaymentController.DonationRequest request = invoiceRequest();
        // The property is simply not set, as when a caller skips the browser and the form.
        Assert.isNull(request.privacyNoticeAccepted, 'The request really omits the acceptance');

        assertControllerRejects(request, 'omitted field');
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is created');
    }

    @IsTest
    static void shouldRejectInvoiceRequestInTheFlow_WhenTheControllerIsSkipped() {
        Test.startTest();
        Flow.Interview interview = Flow.Interview.createInterview(
            'Payment_Attempt_Create',
            flowInputs(invoiceRequest(), false)
        );
        interview.start();
        Test.stopTest();

        Assert.areEqual(NOTICE_REQUIRED, (String) interview.getVariableValue('errorMessage'), 'The flow validates it as well');
        Assert.isNull(interview.getVariableValue('attemptId'), 'The flow creates no attempt');
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is saved');
    }

    @IsTest
    static void shouldRejectInvoiceRequestWithFieldMessage_WhenTheNoticeIsMissingInThePortalService() {
        DonationIntakeService.DonationFormInputDTO request = invoiceFormRequest();
        request.privacyNoticeAccepted = false;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            try {
                DonationIntakeService.startDonation(request);
                Assert.fail('The portal service must refuse it');
            } catch (AuraHandledException e) {
                Assert.areEqual(
                    DonationIntakeService.FIELD_PRIVACY_NOTICE + '|' + DonationIntakeService.MSG_PRIVACY_NOTICE_REQUIRED,
                    e.getMessage(),
                    'The message is tied to the checkbox and is safe to show'
                );
            }
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is created');
    }

    // AC2: acceptance and server-side date and time in the attempt

    @IsTest
    static void shouldSaveAcceptanceWithServerTimestamp_WhenInvoiceIsRequestedAndAccepted() {
        DonationPaymentController.DonationRequest request = invoiceRequest();
        request.privacyNoticeAccepted = true;
        Datetime before = Datetime.now();

        Test.startTest();
        String attemptId = startAsGuest(request);
        Test.stopTest();
        Datetime after = Datetime.now();

        Payment_Attempt__c attempt = attemptOf(attemptId);
        Assert.isTrue(attempt.Privacy_Notice_Accepted__c, 'The acceptance is saved');
        Assert.isNotNull(attempt.Privacy_Notice_Accepted_At__c, 'The date and time are saved');
        Assert.isTrue(attempt.Privacy_Notice_Accepted_At__c >= before.addSeconds(-1), 'Not earlier than the request');
        Assert.isTrue(attempt.Privacy_Notice_Accepted_At__c <= after.addSeconds(1), 'Not later than the request: it is the server clock');
    }

    @IsTest
    static void shouldSaveAcceptanceThroughThePortalService_WhenInvoiceIsRequestedAndAccepted() {
        DonationIntakeService.DonationFormInputDTO request = invoiceFormRequest();
        request.privacyNoticeAccepted = true;
        String attemptId;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            attemptId = DonationIntakeService.startDonation(request);
        }
        Test.stopTest();

        Payment_Attempt__c attempt = attemptOf(attemptId);
        Assert.isTrue(attempt.Privacy_Notice_Accepted__c, 'The acceptance travels through the portal service');
        Assert.isNotNull(attempt.Privacy_Notice_Accepted_At__c, 'The server sets the date and time');
    }

    // AC4: no invoice, nothing is required or stored

    @IsTest
    static void shouldNotRequireNorStoreAcceptance_WhenNoInvoiceIsRequested() {
        DonationPaymentController.DonationRequest request = anonymousRequest();

        Test.startTest();
        String attemptId = startAsGuest(request);
        Test.stopTest();

        Payment_Attempt__c attempt = attemptOf(attemptId);
        Assert.isFalse(attempt.Invoice_Requested__c, 'No invoice');
        Assert.isFalse(attempt.Privacy_Notice_Accepted__c, 'Acceptance stays false');
        Assert.isNull(attempt.Privacy_Notice_Accepted_At__c, 'The date stays empty');
    }

    @IsTest
    static void shouldIgnoreAcceptance_WhenItIsSentWithoutInvoice() {
        DonationPaymentController.DonationRequest request = anonymousRequest();
        request.privacyNoticeAccepted = true;

        Test.startTest();
        String attemptId = startAsGuest(request);
        Test.stopTest();

        Payment_Attempt__c attempt = attemptOf(attemptId);
        Assert.isFalse(attempt.Privacy_Notice_Accepted__c, 'An acceptance without invoice is not recorded');
        Assert.isNull(attempt.Privacy_Notice_Accepted_At__c, 'And it gets no date');
    }

    @IsTest
    static void shouldKeepAnonymousVisibility_WhenInvoiceIsAccepted() {
        DonationPaymentController.DonationRequest request = invoiceRequest();
        request.privacyNoticeAccepted = true;

        Test.startTest();
        String attemptId = startAsGuest(request);
        Test.stopTest();

        Payment_Attempt__c attempt = attemptOf(attemptId);
        Assert.areEqual('Anonymous', attempt.Visibility__c, 'Invoice and acceptance do not change the visibility');
        Assert.isNull(attempt.Public_Name__c, 'An anonymous donation still has no public name');
    }

    // AC2: the donation receives the acceptance (Donation_Register is shared by the return page and the webhook)

    @IsTest
    static void shouldCopyAcceptanceToTheDonation_WhenTheRegisterFlowConfirmsAnAcceptedAttempt() {
        DonationPaymentController.DonationRequest request = invoiceRequest();
        request.privacyNoticeAccepted = true;
        String attemptId = startAsGuest(request);
        Payment_Attempt__c attempt = attemptOf(attemptId);

        Test.startTest();
        Flow.Interview interview = register(attemptId, 'DON13-PAY-1', attempt.Amount__c);
        Test.stopTest();

        Assert.areEqual('Registered', (String) interview.getVariableValue('outcome'), 'The donation is registered');
        Donation__c donation = donationOf('DON13-PAY-1');
        Assert.isTrue(donation.Privacy_Notice_Accepted__c, 'The acceptance is copied');
        Assert.areEqual(attempt.Privacy_Notice_Accepted_At__c, donation.Privacy_Notice_Accepted_At__c, 'The same server date and time');
        Assert.areEqual('Confirmed', attemptOf(attemptId).Status__c, 'The attempt is confirmed');
        Assert.areEqual('Anonymous', donation.Visibility__c, 'An anonymous donation stays anonymous');
    }

    @IsTest
    static void shouldCopyAcceptanceToTheDonation_WhenTheReturnPageConfirmsThePayment() {
        DonationPaymentController.DonationRequest request = invoiceRequest();
        request.privacyNoticeAccepted = true;
        String attemptId = startAsGuest(request);
        Payment_Attempt__c attempt = attemptOf(attemptId);
        Test.setMock(HttpCalloutMock.class, new ProviderMock(approvedPayment(987654321L, attemptId, attempt.Amount__c)));

        Test.startTest();
        String state = DonationPaymentController.getPaymentResult('987654321');
        Test.stopTest();

        Assert.areEqual('Confirmed', state, 'The return page confirms the verified payment');
        Donation__c donation = donationOf('987654321');
        Assert.isTrue(donation.Privacy_Notice_Accepted__c, 'The acceptance reaches the donation');
        Assert.areEqual(attempt.Privacy_Notice_Accepted_At__c, donation.Privacy_Notice_Accepted_At__c, 'With the same date and time');
    }

    // Attempts created before DON-13 are never blocked

    @IsTest
    static void shouldRegisterTheDonation_WhenAHistoricAttemptHasNoAcceptance() {
        Fundraising_Campaign__c campaign = campaign();
        Payment_Attempt__c historic = new Payment_Attempt__c(
            Campaign__c = campaign.Id,
            Amount__c = 500,
            Email__c = 'historico@example.com',
            Visibility__c = 'Anonymous',
            Invoice_Requested__c = true,
            Legal_Name__c = 'Persona Histórica',
            RFC__c = PERSON_RFC,
            Tax_Postal_Code__c = '97000',
            Tax_Regime__c = '612',
            Status__c = 'Started'
        );
        PortalTestDataFactory.insertRecords(new List<SObject>{ historic });

        Test.startTest();
        Flow.Interview interview = register(historic.Id, 'DON13-HIST-1', 500);
        Test.stopTest();

        Assert.areEqual('Registered', (String) interview.getVariableValue('outcome'), 'A historic attempt is not blocked');
        Donation__c donation = donationOf('DON13-HIST-1');
        Assert.isFalse(donation.Privacy_Notice_Accepted__c, 'It has no acceptance to copy');
        Assert.isNull(donation.Privacy_Notice_Accepted_At__c, 'And no date');
        Assert.areEqual('Confirmed', attemptOf(historic.Id).Status__c, 'The attempt is confirmed');
    }

    @IsTest
    static void shouldRegisterTheDonationAsBefore_WhenThePaymentHadNoInvoice() {
        String attemptId = startAsGuest(anonymousRequest());

        Test.startTest();
        Flow.Interview interview = register(attemptId, 'DON13-NOINV-1', attemptOf(attemptId).Amount__c);
        Test.stopTest();

        Assert.areEqual('Registered', (String) interview.getVariableValue('outcome'), 'Donations without invoice are not affected');
        Donation__c donation = donationOf('DON13-NOINV-1');
        Assert.isFalse(donation.Privacy_Notice_Accepted__c, 'No acceptance');
        Assert.isNull(donation.Privacy_Notice_Accepted_At__c, 'No date');
    }

    // Helpers

    private static Fundraising_Campaign__c campaign() {
        return [SELECT Id FROM Fundraising_Campaign__c WHERE Name = :OPEN_CAMPAIGN WITH SYSTEM_MODE LIMIT 1];
    }

    private static DonationPaymentController.DonationRequest anonymousRequest() {
        DonationPaymentController.DonationRequest request = new DonationPaymentController.DonationRequest();
        request.campaignId = String.valueOf(campaign().Id);
        request.amount = 500;
        request.email = 'donante@example.com';
        request.visibility = 'Anonymous';
        request.invoiceRequested = false;
        return request;
    }

    private static DonationPaymentController.DonationRequest invoiceRequest() {
        DonationPaymentController.DonationRequest request = anonymousRequest();
        request.invoiceRequested = true;
        request.legalName = 'Persona de Prueba';
        request.rfc = PERSON_RFC;
        request.taxPostalCode = '97000';
        request.taxRegime = '612';
        return request;
    }

    private static DonationIntakeService.DonationFormInputDTO invoiceFormRequest() {
        DonationIntakeService.DonationFormInputDTO request = new DonationIntakeService.DonationFormInputDTO();
        request.campaignId = String.valueOf(campaign().Id);
        request.amount = 500;
        request.email = 'donante@example.com';
        request.visibility = 'Anonymous';
        request.invoiceRequested = true;
        request.legalName = 'Persona de Prueba';
        request.rfc = PERSON_RFC;
        request.taxPostalCode = '97000';
        request.taxRegime = '612';
        return request;
    }

    private static Map<String, Object> flowInputs(DonationPaymentController.DonationRequest request, Boolean includeNotice) {
        Map<String, Object> inputs = new Map<String, Object>{
            'campaignId' => request.campaignId,
            'amount' => request.amount,
            'email' => request.email,
            'visibility' => request.visibility,
            'invoiceRequested' => request.invoiceRequested,
            'legalName' => request.legalName,
            'rfc' => request.rfc,
            'taxPostalCode' => request.taxPostalCode,
            'taxRegime' => request.taxRegime
        };
        if (includeNotice) {
            inputs.put('privacyNoticeAccepted', true);
        }
        return inputs;
    }

    private static String startAsGuest(DonationPaymentController.DonationRequest request) {
        String attemptId;
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            attemptId = DonationPaymentController.startDonation(request);
        }
        return attemptId;
    }

    private static void assertControllerRejects(DonationPaymentController.DonationRequest request, String scenario) {
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            try {
                DonationPaymentController.startDonation(request);
                Assert.fail('Expected a rejection for: ' + scenario);
            } catch (AuraHandledException e) {
                Assert.areEqual(DonationPaymentController.PRIVACY_NOTICE_REQUIRED, e.getMessage(), 'Message for: ' + scenario);
            }
        }
    }

    private static Flow.Interview register(String attemptId, String providerPaymentId, Decimal amount) {
        Flow.Interview interview = Flow.Interview.createInterview(
            'Donation_Register',
            new Map<String, Object>{
                'attemptId' => attemptId,
                'providerPaymentId' => providerPaymentId,
                'paymentStatus' => 'approved',
                'confirmedAmount' => amount,
                'approvedAt' => Datetime.now()
            }
        );
        interview.start();
        return interview;
    }

    private static String approvedPayment(Long paymentId, String attemptId, Decimal amount) {
        return JSON.serialize(
            new Map<String, Object>{
                'id' => paymentId,
                'status' => 'approved',
                'external_reference' => attemptId,
                'transaction_amount' => amount,
                'currency_id' => 'MXN',
                'date_approved' => '2026-11-09T12:00:00.000-06:00'
            }
        );
    }

    private static Payment_Attempt__c attemptOf(String attemptId) {
        return [
            SELECT
                Amount__c, Visibility__c, Public_Name__c, Invoice_Requested__c, Status__c,
                Privacy_Notice_Accepted__c, Privacy_Notice_Accepted_At__c
            FROM Payment_Attempt__c
            WHERE Id = :attemptId
            WITH SYSTEM_MODE
        ];
    }

    private static Donation__c donationOf(String providerPaymentId) {
        return [
            SELECT Visibility__c, Privacy_Notice_Accepted__c, Privacy_Notice_Accepted_At__c
            FROM Donation__c
            WHERE Provider_Payment_Id__c = :providerPaymentId
            WITH SYSTEM_MODE
        ];
    }
}
