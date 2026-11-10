/**
 * Tests for DonationIntakeService: server-side validation of the donation form and the mapping
 * to the payment gateway. The gateway is replaced by a capturing double, so nothing is saved
 * and no callout is made. Tests run as the simulated guest (read-only access to public
 * campaign fields, no access to Donation__c or Payment_Attempt__c).
 */
@IsTest
private class DonationIntakeServiceTest {
    private static final String OPEN_CAMPAIGN = 'Campaña abierta';
    private static final String PAUSED_CAMPAIGN = 'Campaña pausada';
    private static final String CLOSED_CAMPAIGN = 'Campaña cerrada';
    private static final String DRAFT_CAMPAIGN = 'Campaña en borrador';
    private static final String FUTURE_CAMPAIGN = 'Campaña activa futura';
    private static final String ENDED_CAMPAIGN = 'Campaña activa vencida';

    private static final String PERSON_RFC = 'GODE561231GR8';
    private static final String COMPANY_RFC = 'ABC010203XY1';

    private class CapturingGateway implements DonationIntakeService.PaymentGateway {
        public Integer attemptCalls = 0;
        public Integer checkoutCalls = 0;
        public DonationIntakeService.DonationFormInputDTO capturedRequest;
        public Id capturedAttemptId;
        public String attemptIdToReturn = 'placeholder';
        public String urlToReturn = 'https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=TEST';
        public Exception errorToThrow;

        public String createAttempt(DonationIntakeService.DonationFormInputDTO request) {
            attemptCalls++;
            capturedRequest = request;
            if (errorToThrow != null) {
                throw errorToThrow;
            }
            return attemptIdToReturn;
        }

        public String createCheckout(Id attemptId) {
            checkoutCalls++;
            capturedAttemptId = attemptId;
            if (errorToThrow != null) {
                throw errorToThrow;
            }
            return urlToReturn;
        }
    }

    @TestSetup
    static void setupTestData() {
        PortalTestDataFactory.createSimulatedGuest();
        PortalTestDataFactory.createUserWithoutAccess();

        Date today = Date.today();
        PortalTestDataFactory.insertRecords(
            new List<Fundraising_Campaign__c>{
                PortalTestDataFactory.buildCampaign(OPEN_CAMPAIGN, 'Active', today.addDays(-10), today.addDays(30)),
                PortalTestDataFactory.buildCampaign(PAUSED_CAMPAIGN, 'Paused', today.addDays(-10), null),
                PortalTestDataFactory.buildCampaign(CLOSED_CAMPAIGN, 'Closed', today.addDays(-60), today.addDays(-10)),
                PortalTestDataFactory.buildCampaign(DRAFT_CAMPAIGN, 'Draft', today.addDays(-10), null),
                PortalTestDataFactory.buildCampaign(FUTURE_CAMPAIGN, 'Active', today.addDays(5), today.addDays(60)),
                PortalTestDataFactory.buildCampaign(ENDED_CAMPAIGN, 'Active', today.addDays(-30), today.addDays(-1))
            }
        );
    }

    // startDonation: valid requests and mapping

    @IsTest
    static void shouldReturnAttemptIdFromGateway_WhenAnonymousRequestIsValid() {
        CapturingGateway gateway = useCapturingGateway();
        String attemptId;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            attemptId = DonationIntakeService.startDonation(validAnonymousRequest());
        }
        Test.stopTest();

        Assert.areEqual(validAttemptId(), attemptId, 'The Id comes from the payment code of Workstream A');
        Assert.areEqual(1, gateway.attemptCalls, 'The gateway is called once');
    }

    @IsTest
    static void shouldNotSendPublicNameOrFiscalData_WhenDonationIsAnonymousWithoutInvoice() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
        request.publicName = 'Nombre que debe ignorarse';
        request.legalName = 'Dato fiscal que debe ignorarse';
        request.rfc = 'dato inválido';

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        DonationIntakeService.DonationFormInputDTO sent = gateway.capturedRequest;
        Assert.areEqual('Anonymous', sent.visibility, 'Visibility');
        Assert.isNull(sent.publicName, 'An anonymous donation never carries a public name');
        Assert.isFalse(sent.invoiceRequested, 'No invoice requested');
        Assert.isNull(sent.legalName, 'Fiscal data is ignored when no invoice is requested');
        Assert.isNull(sent.rfc, 'RFC is ignored when no invoice is requested');
        Assert.isNull(sent.taxPostalCode, 'Postal code is ignored when no invoice is requested');
        Assert.isNull(sent.taxRegime, 'Regime is ignored when no invoice is requested');
    }

    @IsTest
    static void shouldMapAllFields_WhenRequestIsPublicWithInvoice() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        DonationIntakeService.DonationFormInputDTO sent = gateway.capturedRequest;
        Assert.areEqual(request.campaignId, sent.campaignId, 'campaignId');
        Assert.areEqual(500, sent.amount, 'amount');
        Assert.areEqual('donante@example.com', sent.email, 'email');
        Assert.areEqual('Public', sent.visibility, 'visibility');
        Assert.areEqual('Familia Pérez', sent.publicName, 'publicName');
        Assert.isTrue(sent.invoiceRequested, 'invoiceRequested');
        Assert.areEqual('Familia Pérez S.A. de C.V.', sent.legalName, 'legalName');
        Assert.areEqual(COMPANY_RFC, sent.rfc, 'rfc');
        Assert.areEqual('97000', sent.taxPostalCode, 'taxPostalCode');
        Assert.areEqual('601', sent.taxRegime, 'taxRegime');
    }

    @IsTest
    static void shouldKeepAnonymousVisibility_WhenInvoiceIsRequested() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
        request.visibility = 'Anonymous';

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.areEqual('Anonymous', gateway.capturedRequest.visibility, 'Invoice does not change visibility');
        Assert.isNull(gateway.capturedRequest.publicName, 'Anonymous still has no public name');
        Assert.isTrue(gateway.capturedRequest.invoiceRequested, 'The invoice request is independent from visibility');
        Assert.areEqual(COMPANY_RFC, gateway.capturedRequest.rfc, 'Fiscal data is sent');
    }

    @IsTest
    static void shouldNormalizeSpacesInPublicName_WhenRequestIsPublic() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = '   Familia    Pérez \t López  ';

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.areEqual('Familia Pérez López', gateway.capturedRequest.publicName, 'Spaces are normalized');
    }

    @IsTest
    static void shouldKeepHtmlAsPlainText_WhenPublicNameContainsTags() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = '<script>alert(1)</script>';

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.areEqual('<script>alert(1)</script>', gateway.capturedRequest.publicName, 'The text is kept; the interface shows it as text');
    }

    @IsTest
    static void shouldAcceptPublicName_WhenItHasExactlyEightyCharacters() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = 'a'.repeat(80);

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.areEqual(80, gateway.capturedRequest.publicName.length(), 'The limit is inclusive');
    }

    @IsTest
    static void shouldNormalizeRfc_WhenItHasLowercaseAndSpaces() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
        request.rfc = '  gode 561231 gr8 ';
        request.taxRegime = '612';

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.areEqual(PERSON_RFC, gateway.capturedRequest.rfc, 'RFC is uppercase without spaces');
    }

    @IsTest
    static void shouldAcceptPersonAndCompanyRfc_WhenStructureIsValid() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO person = validPublicInvoiceRequest();
        person.rfc = PERSON_RFC;
        person.taxRegime = '612';
        DonationIntakeService.DonationFormInputDTO company = validPublicInvoiceRequest();

        Test.startTest();
        runAsGuestStart(person);
        runAsGuestStart(company);
        Test.stopTest();

        Assert.areEqual(2, gateway.attemptCalls, 'Both examples of the story are accepted');
    }

    @IsTest
    static void shouldAcceptRegimesOfBothTypes_WhenCatalogAllowsIt() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO person = validPublicInvoiceRequest();
        person.rfc = PERSON_RFC;
        person.taxRegime = '626';
        DonationIntakeService.DonationFormInputDTO company = validPublicInvoiceRequest();
        company.taxRegime = '610';

        Test.startTest();
        runAsGuestStart(person);
        runAsGuestStart(company);
        Test.stopTest();

        Assert.areEqual(2, gateway.attemptCalls, 'Regimes 610 and 626 are valid for persons and companies');
    }

    @IsTest
    static void shouldNotSaveRecordsOrUseDml_WhenRequestIsValid() {
        useCapturingGateway();
        Integer dmlBefore = Limits.getDmlStatements();

        Test.startTest();
        runAsGuestStart(validPublicInvoiceRequest());
        Test.stopTest();

        Assert.areEqual(dmlBefore, Limits.getDmlStatements(), 'The service performs no DML');
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is saved by Workstream B');
        Assert.areEqual(0, [SELECT COUNT() FROM Donation__c WITH SYSTEM_MODE], 'No donation is saved by Workstream B');
    }

    // startDonation: rejections

    @IsTest
    static void shouldRejectRequest_WhenItIsNull() {
        CapturingGateway gateway = useCapturingGateway();

        Test.startTest();
        assertStartRejected(null, DonationIntakeService.MSG_MISSING_DATA, 'null request');
        Test.stopTest();

        Assert.areEqual(0, gateway.attemptCalls, 'The gateway is never called with invalid data');
    }

    @IsTest
    static void shouldRejectCampaign_WhenItDoesNotAcceptDonations() {
        CapturingGateway gateway = useCapturingGateway();
        List<String> blockedIds = new List<String>{
            idOf(PAUSED_CAMPAIGN),
            idOf(CLOSED_CAMPAIGN),
            idOf(DRAFT_CAMPAIGN),
            idOf(FUTURE_CAMPAIGN),
            idOf(ENDED_CAMPAIGN),
            Fundraising_Campaign__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix() + '000000000000'
        };

        Test.startTest();
        for (String blockedId : blockedIds) {
            DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
            request.campaignId = blockedId;
            assertStartRejected(request, DonationIntakeService.MSG_CAMPAIGN_CLOSED, 'campaign ' + blockedId);
        }
        Test.stopTest();

        Assert.areEqual(0, gateway.attemptCalls, 'The server blocks the payment start, not only the interface');
    }

    @IsTest
    static void shouldShowFriendlyError_WhenUserCannotReadCampaigns() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.NO_ACCESS_LAST_NAME)) {
            try {
                DonationIntakeService.startDonation(request);
                Assert.fail('Expected a rejection');
            } catch (AuraHandledException e) {
                Assert.areEqual(DonationIntakeService.MSG_START_FAILED, e.getMessage(), 'No technical detail reaches the donor');
            }
        }
        Test.stopTest();

        Assert.areEqual(0, gateway.attemptCalls, 'The gateway is not called when the campaign cannot be checked');
    }

    @IsTest
    static void shouldRejectCampaign_WhenIdIsMissingOrMalformed() {
        useCapturingGateway();
        List<String> invalidIds = new List<String>{ null, '', '   ', 'no-es-un-id', UserInfo.getUserId() };

        Test.startTest();
        for (String invalidId : invalidIds) {
            DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
            request.campaignId = invalidId;
            assertStartRejected(request, DonationIntakeService.MSG_CAMPAIGN_CLOSED, 'campaignId ' + invalidId);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectAmount_WhenItIsMissing() {
        useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
        request.amount = null;

        Test.startTest();
        assertStartRejected(request, DonationIntakeService.MSG_AMOUNT_REQUIRED, 'amount null');
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectAmount_WhenItIsNotOneOfTheSuggestedOnes() {
        useCapturingGateway();

        Test.startTest();
        for (Decimal amount : new List<Decimal>{ 0, -100, 49, 50, 150, 2500, 20001, 100000 }) {
            DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
            request.amount = amount;
            assertStartRejected(request, DonationIntakeService.MSG_AMOUNT_INVALID, 'amount ' + amount);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldAcceptEveryAmount_WhenItIsOneOfTheEightSuggested() {
        CapturingGateway gateway = useCapturingGateway();

        Test.startTest();
        for (Integer amount : new List<Integer>{ 100, 250, 500, 1000, 2000, 5000, 10000, 20000 }) {
            DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
            request.amount = amount;
            runAsGuestStart(request);
        }
        Test.stopTest();

        Assert.areEqual(8, gateway.attemptCalls, 'The eight amounts of DON-08 are accepted');
    }

    @IsTest
    static void shouldRejectEmail_WhenItIsBlankOrInvalid() {
        useCapturingGateway();
        List<String> invalidEmails = new List<String>{
            null, '', '   ', 'sin-arroba', 'a@b', 'a b@example.com', '@example.com', 'a@@example.com',
            'a'.repeat(80) + '@example.com'
        };

        Test.startTest();
        for (String email : invalidEmails) {
            DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
            request.email = email;
            assertStartRejected(request, DonationIntakeService.MSG_EMAIL_INVALID, 'email ' + email);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRequireEmail_WhenDonationIsAnonymous() {
        useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
        request.email = null;

        Test.startTest();
        assertStartRejected(request, DonationIntakeService.MSG_EMAIL_INVALID, 'anonymous without email');
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectVisibility_WhenItIsNotAnonymousOrPublic() {
        useCapturingGateway();

        Test.startTest();
        for (String visibility : new List<String>{ null, '', 'Anónima', 'anonymous', 'PUBLIC', 'Private' }) {
            DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
            request.visibility = visibility;
            assertStartRejected(request, DonationIntakeService.MSG_VISIBILITY_INVALID, 'visibility ' + visibility);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectPublicName_WhenItIsEmptyOrOnlySpaces() {
        useCapturingGateway();

        Test.startTest();
        for (String name : new List<String>{ null, '', '     ', '\t \n ' }) {
            DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
            request.publicName = name;
            assertStartRejected(request, DonationIntakeService.MSG_PUBLIC_NAME_REQUIRED, 'publicName ' + name);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectPublicName_WhenItHasMoreThanEightyCharacters() {
        useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = 'a'.repeat(81);

        Test.startTest();
        assertStartRejected(request, DonationIntakeService.MSG_PUBLIC_NAME_TOO_LONG, 'publicName 81');
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectInvoice_WhenAnyFiscalFieldIsMissing() {
        useCapturingGateway();
        List<String> missingFields = new List<String>{ 'legalName', 'rfc', 'taxPostalCode', 'taxRegime' };

        Test.startTest();
        for (String missingField : missingFields) {
            DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
            clearField(request, missingField);
            assertStartRejected(request, DonationIntakeService.MSG_INVOICE_DATA_MISSING, 'missing ' + missingField);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectInvoice_WhenFiscalFieldsAreOnlySpaces() {
        useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
        request.legalName = '    ';

        Test.startTest();
        assertStartRejected(request, DonationIntakeService.MSG_INVOICE_DATA_MISSING, 'legalName spaces');
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectRfc_WhenFormatIsNotValid() {
        useCapturingGateway();
        List<String> invalidRfcs = new List<String>{
            'GODE56123GR8', // 12 characters with a person structure (day lost)
            'GODE5612311GR8', // 14 characters
            'ABC01020XY1', // 11 characters
            'GODE561331GR8', // month 13
            'GODE561232GR8', // day 32
            'GODE56AB31GR8', // letters where the date goes
            'GO1E561231GR8', // digit inside the initial letters
            'GODE561231G-8', // special character
            'GODE561231GR*'
        };

        Test.startTest();
        for (String rfc : invalidRfcs) {
            DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
            request.rfc = rfc;
            request.taxRegime = '612';
            assertStartRejected(request, DonationIntakeService.MSG_RFC_INVALID, 'rfc ' + rfc);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectPostalCode_WhenItDoesNotHaveFiveDigits() {
        useCapturingGateway();

        Test.startTest();
        for (String postalCode : new List<String>{ '1234', '123456', '12a45', '12 45', '9700O' }) {
            DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
            request.taxPostalCode = postalCode;
            assertStartRejected(request, DonationIntakeService.MSG_POSTAL_CODE_INVALID, 'postal ' + postalCode);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectRegime_WhenItIsNotInTheCatalog() {
        useCapturingGateway();

        Test.startTest();
        for (String regime : new List<String>{ '999', '600', '61', 'abc', '6012' }) {
            DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
            request.taxRegime = regime;
            assertStartRejected(request, DonationIntakeService.MSG_REGIME_INVALID, 'regime ' + regime);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectRegime_WhenItDoesNotMatchTheTaxpayerType() {
        useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO companyWithPersonRegime = validPublicInvoiceRequest();
        companyWithPersonRegime.taxRegime = '605';
        DonationIntakeService.DonationFormInputDTO personWithCompanyRegime = validPublicInvoiceRequest();
        personWithCompanyRegime.rfc = PERSON_RFC;
        personWithCompanyRegime.taxRegime = '601';

        Test.startTest();
        assertStartRejected(companyWithPersonRegime, DonationIntakeService.MSG_REGIME_MISMATCH, 'company with person regime');
        assertStartRejected(personWithCompanyRegime, DonationIntakeService.MSG_REGIME_MISMATCH, 'person with company regime');
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectLegalName_WhenItHasMoreThanTwoHundredFiftyFourCharacters() {
        useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
        request.legalName = 'a'.repeat(255);

        Test.startTest();
        assertStartRejected(request, DonationIntakeService.MSG_LEGAL_NAME_TOO_LONG, 'legalName 255');
        Test.stopTest();
    }

    // startDonation: gateway errors

    @IsTest
    static void shouldPassThroughMessage_WhenGatewayThrowsFriendlyError() {
        CapturingGateway gateway = useCapturingGateway();
        gateway.errorToThrow = CampaignPortalController.userFacingError('Esta campaña ya no acepta donaciones.');

        Test.startTest();
        assertStartRejected(validAnonymousRequest(), 'Esta campaña ya no acepta donaciones.', 'friendly error from A');
        Test.stopTest();
    }

    @IsTest
    static void shouldHideTechnicalDetail_WhenGatewayThrowsUnexpectedError() {
        CapturingGateway gateway = useCapturingGateway();
        gateway.errorToThrow = new DmlException('FIELD_CUSTOM_VALIDATION_EXCEPTION: detalle técnico');

        Test.startTest();
        assertStartRejected(validAnonymousRequest(), DonationIntakeService.MSG_START_FAILED, 'technical error');
        Test.stopTest();
    }

    // openPayment

    @IsTest
    static void shouldReturnCheckoutUrlFromGateway_WhenAttemptIdIsValid() {
        CapturingGateway gateway = useCapturingGateway();
        String url;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            url = DonationIntakeService.openPayment(validAttemptId());
        }
        Test.stopTest();

        Assert.areEqual(gateway.urlToReturn, url, 'The URL comes from the payment code of Workstream A');
        Assert.areEqual(1, gateway.checkoutCalls, 'The gateway is called once');
    }

    @IsTest
    static void shouldPassAttemptIdToGateway_WhenOpeningPayment() {
        CapturingGateway gateway = useCapturingGateway();
        String attemptId = Payment_Attempt__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix() + '000000000007';
        gateway.attemptIdToReturn = attemptId;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            DonationIntakeService.openPayment(attemptId);
        }
        Test.stopTest();

        Assert.areEqual(Id.valueOf(attemptId), gateway.capturedAttemptId, 'The same Id reaches Workstream A');
    }

    @IsTest
    static void shouldRejectAttemptId_WhenItIsMissingMalformedOrFromAnotherObject() {
        CapturingGateway gateway = useCapturingGateway();

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            for (String attemptId : new List<String>{ null, '', '   ', 'no-es-un-id', idOf(OPEN_CAMPAIGN) }) {
                assertPaymentRejected(attemptId, DonationIntakeService.MSG_PAYMENT_FAILED, 'attemptId ' + attemptId);
            }
        }
        Test.stopTest();

        Assert.areEqual(0, gateway.checkoutCalls, 'The gateway is never called with an invalid attempt');
    }

    @IsTest
    static void shouldRejectUrl_WhenGatewayReturnsSomethingThatIsNotHttps() {
        CapturingGateway gateway = useCapturingGateway();

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            for (String url : new List<String>{ null, '', 'http://www.mercadopago.com.mx', 'javascript:alert(1)', '//evil.example' }) {
                gateway.urlToReturn = url;
                assertPaymentRejected(validAttemptId(), DonationIntakeService.MSG_PAYMENT_FAILED, 'url ' + url);
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldPassThroughMessage_WhenGatewayThrowsFriendlyErrorOnPayment() {
        CapturingGateway gateway = useCapturingGateway();
        gateway.errorToThrow = CampaignPortalController.userFacingError('Esta campaña ya no acepta donaciones.');

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            assertPaymentRejected(validAttemptId(), 'Esta campaña ya no acepta donaciones.', 'friendly error from A');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldHideTechnicalDetail_WhenGatewayThrowsUnexpectedErrorOnPayment() {
        CapturingGateway gateway = useCapturingGateway();
        gateway.errorToThrow = new CalloutException('Unauthorized endpoint: detalle técnico');

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            assertPaymentRejected(validAttemptId(), DonationIntakeService.MSG_PAYMENT_FAILED, 'technical error');
        }
        Test.stopTest();
    }

    // Real gateway: Workstream A's DonationPaymentController and flows. Only the Mercado Pago
    // HTTP response is simulated.

    private class ProviderMock implements HttpCalloutMock {
        public Integer calls = 0;
        private final Integer statusCode;
        private final String body;

        ProviderMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest request) {
            calls++;
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(body);
            return response;
        }
    }

    private static final String PROVIDER_CHECKOUT_URL = 'https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=123-pref';
    private static final String PROVIDER_APPROVED_BODY = '{"id":"123-pref","init_point":"' + PROVIDER_CHECKOUT_URL + '"}';

    private static String startWithRealGateway(DonationIntakeService.DonationFormInputDTO request) {
        String attemptId;
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            attemptId = DonationIntakeService.startDonation(request);
        }
        return attemptId;
    }

    private static Payment_Attempt__c attemptOf(String attemptId) {
        return [
            SELECT
                Campaign__c, Amount__c, Email__c, Visibility__c, Public_Name__c, Invoice_Requested__c,
                Legal_Name__c, RFC__c, Taxpayer_Type__c, Tax_Postal_Code__c, Tax_Regime__c, Status__c, Preference_Id__c
            FROM Payment_Attempt__c
            WHERE Id = :attemptId
            WITH SYSTEM_MODE
        ];
    }

    @IsTest
    static void shouldSaveAttemptThroughWorkstreamA_WhenAnonymousRequestIsValid() {
        DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();

        Test.startTest();
        String attemptId = startWithRealGateway(request);
        Test.stopTest();

        Assert.areEqual(Payment_Attempt__c.SObjectType, Id.valueOf(attemptId).getSObjectType(), 'A Payment_Attempt__c Id');
        Payment_Attempt__c attempt = attemptOf(attemptId);
        Assert.areEqual(request.campaignId, String.valueOf(attempt.Campaign__c), 'Campaign');
        Assert.areEqual(500, attempt.Amount__c, 'Amount');
        Assert.areEqual('donante@example.com', attempt.Email__c, 'Email');
        Assert.areEqual('Anonymous', attempt.Visibility__c, 'Visibility');
        Assert.isNull(attempt.Public_Name__c, 'No public name for an anonymous donation');
        Assert.isFalse(attempt.Invoice_Requested__c, 'No invoice');
        Assert.areEqual('Started', attempt.Status__c, 'A new attempt starts as Started');
        Assert.areEqual(0, [SELECT COUNT() FROM Donation__c WITH SYSTEM_MODE], 'An attempt is not a donation');
    }

    @IsTest
    static void shouldSavePublicNameAndFiscalData_WhenPublicInvoiceRequestIsSent() {
        DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
        request.rfc = '  abc 010203 xy1 ';

        Test.startTest();
        String attemptId = startWithRealGateway(request);
        Test.stopTest();

        Payment_Attempt__c attempt = attemptOf(attemptId);
        Assert.areEqual('Public', attempt.Visibility__c, 'Visibility');
        Assert.areEqual('Familia Pérez', attempt.Public_Name__c, 'Public name');
        Assert.isTrue(attempt.Invoice_Requested__c, 'Invoice requested');
        Assert.areEqual('Familia Pérez S.A. de C.V.', attempt.Legal_Name__c, 'Legal name');
        Assert.areEqual(COMPANY_RFC, attempt.RFC__c, 'RFC is stored uppercase without spaces');
        Assert.areEqual('Moral', attempt.Taxpayer_Type__c, 'Taxpayer type comes from the RFC length');
        Assert.areEqual('97000', attempt.Tax_Postal_Code__c, 'Postal code');
        Assert.areEqual('601', attempt.Tax_Regime__c, 'Regime');
    }

    @IsTest
    static void shouldSaveFiscalDataAndStayAnonymous_WhenInvoiceIsRequestedWithAnonymousVisibility() {
        DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
        request.visibility = 'Anonymous';

        Test.startTest();
        String attemptId = startWithRealGateway(request);
        Test.stopTest();

        Payment_Attempt__c attempt = attemptOf(attemptId);
        Assert.areEqual('Anonymous', attempt.Visibility__c, 'Visibility');
        Assert.isNull(attempt.Public_Name__c, 'Anonymous has no public name');
        Assert.isTrue(attempt.Invoice_Requested__c, 'The invoice is independent from visibility');
        Assert.areEqual(COMPANY_RFC, attempt.RFC__c, 'Fiscal data is saved');
    }

    @IsTest
    static void shouldReturnCheckoutUrlAndKeepAttemptUnconfirmed_WhenProviderApprovesThePreference() {
        String attemptId = startWithRealGateway(validAnonymousRequest());
        ProviderMock provider = new ProviderMock(201, PROVIDER_APPROVED_BODY);
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        String url = DonationIntakeService.openPayment(attemptId);
        Test.stopTest();

        Assert.areEqual(PROVIDER_CHECKOUT_URL, url, 'The Checkout URL comes from Mercado Pago');
        Assert.areEqual(1, provider.calls, 'One preference is created');
        Payment_Attempt__c attempt = attemptOf(attemptId);
        Assert.areEqual('123-pref', attempt.Preference_Id__c, 'The preference Id is stored');
        Assert.areEqual('Started', attempt.Status__c, 'Opening the payment does not confirm it');
        Assert.areEqual(0, [SELECT COUNT() FROM Donation__c WITH SYSTEM_MODE], 'No donation exists until the provider confirms the payment');
    }

    @IsTest
    static void shouldDeleteAttemptAndShowFriendlyMessage_WhenProviderFails() {
        String attemptId = startWithRealGateway(validAnonymousRequest());
        Test.setMock(HttpCalloutMock.class, new ProviderMock(500, '{}'));

        Test.startTest();
        try {
            DonationIntakeService.openPayment(attemptId);
            Assert.fail('Expected a friendly error');
        } catch (AuraHandledException e) {
            Assert.areEqual(DonationIntakeService.MSG_PAYMENT_FAILED, e.getMessage(), 'Message from Workstream A');
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'A failed attempt is deleted so the donor can try again');
        Assert.areEqual(0, [SELECT COUNT() FROM Donation__c WITH SYSTEM_MODE], 'No donation');
    }

    @IsTest
    static void shouldNotOpenThePaymentTwice_WhenTheSameAttemptIsOpenedAgain() {
        String attemptId = startWithRealGateway(validAnonymousRequest());
        ProviderMock provider = new ProviderMock(201, PROVIDER_APPROVED_BODY);
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        DonationIntakeService.openPayment(attemptId);
        try {
            DonationIntakeService.openPayment(attemptId);
            Assert.fail('Expected the second opening to be rejected');
        } catch (AuraHandledException e) {
            Assert.isFalse(String.isBlank(e.getMessage()), 'The donor receives a message');
        }
        Test.stopTest();

        Assert.areEqual(1, provider.calls, 'Mercado Pago is called once per attempt');
    }

    // Helpers

    private static String validAttemptId() {
        String keyPrefix = Payment_Attempt__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix();
        return keyPrefix + '000000000001';
    }

    private static CapturingGateway useCapturingGateway() {
        CapturingGateway gateway = new CapturingGateway();
        gateway.attemptIdToReturn = validAttemptId();
        DonationIntakeService.gateway = gateway;
        return gateway;
    }

    private static String idOf(String campaignName) {
        return [SELECT Id FROM Fundraising_Campaign__c WHERE Name = :campaignName WITH SYSTEM_MODE LIMIT 1].Id;
    }

    private static DonationIntakeService.DonationFormInputDTO validAnonymousRequest() {
        DonationIntakeService.DonationFormInputDTO request = new DonationIntakeService.DonationFormInputDTO();
        request.campaignId = idOf(OPEN_CAMPAIGN);
        request.amount = 500;
        request.email = 'donante@example.com';
        request.visibility = 'Anonymous';
        request.invoiceRequested = false;
        return request;
    }

    private static DonationIntakeService.DonationFormInputDTO validPublicRequest() {
        DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
        request.visibility = 'Public';
        request.publicName = 'Familia Pérez';
        return request;
    }

    private static DonationIntakeService.DonationFormInputDTO validPublicInvoiceRequest() {
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.invoiceRequested = true;
        request.legalName = 'Familia Pérez S.A. de C.V.';
        request.rfc = COMPANY_RFC;
        request.taxPostalCode = '97000';
        request.taxRegime = '601';
        return request;
    }

    private static void clearField(DonationIntakeService.DonationFormInputDTO request, String fieldName) {
        switch on fieldName {
            when 'legalName' {
                request.legalName = null;
            }
            when 'rfc' {
                request.rfc = null;
            }
            when 'taxPostalCode' {
                request.taxPostalCode = null;
            }
            when 'taxRegime' {
                request.taxRegime = null;
            }
        }
    }

    private static void runAsGuestStart(DonationIntakeService.DonationFormInputDTO request) {
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            DonationIntakeService.startDonation(request);
        }
    }

    private static void assertStartRejected(
        DonationIntakeService.DonationFormInputDTO request,
        String expectedMessage,
        String scenario
    ) {
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            try {
                DonationIntakeService.startDonation(request);
                Assert.fail('Expected a rejection for: ' + scenario);
            } catch (AuraHandledException e) {
                Assert.areEqual(expectedMessage, e.getMessage(), 'Message for: ' + scenario);
            }
        }
    }

    private static void assertPaymentRejected(String attemptId, String expectedMessage, String scenario) {
        try {
            DonationIntakeService.openPayment(attemptId);
            Assert.fail('Expected a rejection for: ' + scenario);
        } catch (AuraHandledException e) {
            Assert.areEqual(expectedMessage, e.getMessage(), 'Message for: ' + scenario);
        }
    }
}
