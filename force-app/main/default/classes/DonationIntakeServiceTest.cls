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
        public String urlToReturn = 'https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=TEST';
        public Exception errorToThrow;

        // Saves a real attempt, as the payment code of Workstream A does, because the service now
        // needs it to keep the hash of the access token.
        public String createAttempt(DonationIntakeService.DonationFormInputDTO request) {
            attemptCalls++;
            capturedRequest = request;
            if (errorToThrow != null) {
                throw errorToThrow;
            }
            Payment_Attempt__c attempt = PortalTestDataFactory.buildPaymentAttempt(Id.valueOf(request.campaignId), Decimal.valueOf(request.amount));
            attempt.Email__c = request.email;
            attempt.Visibility__c = request.visibility;
            attempt.Public_Name__c = request.publicName;
            attempt.Invoice_Requested__c = request.invoiceRequested;
            // The validation rules of Payment_Attempt__c reject an invoice request without its fiscal data.
            attempt.Legal_Name__c = request.legalName;
            attempt.RFC__c = request.rfc;
            attempt.Tax_Postal_Code__c = request.taxPostalCode;
            attempt.Tax_Regime__c = request.taxRegime;
            attempt.Privacy_Notice_Accepted__c = request.privacyNoticeAccepted == true;
            PortalTestDataFactory.insertRecords(new List<SObject>{ attempt });
            return String.valueOf(attempt.Id);
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
    static void shouldReturnOnlyAnAccessToken_WhenAnonymousRequestIsValid() {
        CapturingGateway gateway = useCapturingGateway();
        DonationStartDTO started;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            started = DonationIntakeService.startDonation(validAnonymousRequest());
        }
        Test.stopTest();

        Assert.isTrue(DonationAccessToken.isWellFormed(started.accessToken), 'The browser receives a token');
        Assert.areEqual(1, gateway.attemptCalls, 'The gateway is called once');
        Id attemptId = [SELECT Id FROM Payment_Attempt__c WITH SYSTEM_MODE].Id;
        Assert.isFalse(JSON.serialize(started).contains(String.valueOf(attemptId)), 'The Id of the attempt never reaches the browser');
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
        Assert.areEqual('500.00', sent.amount, 'amount, as exact text with two decimals');
        Assert.areEqual('donante@example.com', sent.email, 'email');
        Assert.areEqual('Public', sent.visibility, 'visibility');
        Assert.areEqual('Familia Pérez', sent.publicName, 'publicName');
        Assert.isTrue(sent.invoiceRequested, 'invoiceRequested');
        Assert.areEqual('Familia Pérez S.A. de C.V.', sent.legalName, 'legalName');
        Assert.areEqual(COMPANY_RFC, sent.rfc, 'rfc');
        Assert.areEqual('97000', sent.taxPostalCode, 'taxPostalCode');
        Assert.areEqual('601', sent.taxRegime, 'taxRegime');
    }

    // DON-13: the privacy notice is checked here, before the payment code, and only the acceptance is passed on.
    @IsTest
    static void shouldPassTheAcceptanceToThePaymentCode_WhenInvoiceIsRequestedAndAccepted() {
        CapturingGateway gateway = useCapturingGateway();

        Test.startTest();
        runAsGuestStart(validPublicInvoiceRequest());
        Test.stopTest();

        Assert.isTrue(gateway.capturedRequest.privacyNoticeAccepted, 'The acceptance reaches the payment code');
    }

    @IsTest
    static void shouldNeverCallThePaymentCode_WhenInvoiceIsRequestedWithoutAcceptance() {
        CapturingGateway gateway = useCapturingGateway();

        Test.startTest();
        for (Boolean accepted : new List<Boolean>{ false, null }) {
            DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
            request.privacyNoticeAccepted = accepted;
            assertStartRejected(
                request,
                DonationIntakeService.FIELD_PRIVACY_NOTICE,
                DonationIntakeService.MSG_PRIVACY_NOTICE_REQUIRED,
                'accepted=' + accepted
            );
        }
        Test.stopTest();

        Assert.areEqual(0, gateway.attemptCalls, 'The server blocks it before any attempt is created');
    }

    @IsTest
    static void shouldReportTheFiscalFieldFirst_WhenFiscalDataAndAcceptanceAreMissing() {
        useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
        request.rfc = null;
        request.privacyNoticeAccepted = false;

        Test.startTest();
        assertStartRejected(request, 'rfc', DonationIntakeService.MSG_INVOICE_DATA_MISSING, 'fiscal data comes first');
        Test.stopTest();
    }

    @IsTest
    static void shouldNotRequireAcceptanceAndPassFalse_WhenNoInvoiceIsRequested() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
        request.privacyNoticeAccepted = true;

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.isFalse(gateway.capturedRequest.privacyNoticeAccepted, 'An acceptance without invoice is not passed on');
        Assert.isFalse(gateway.capturedRequest.invoiceRequested, 'No invoice');
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
    static void shouldRemoveScriptTags_WhenPublicNameContainsMarkup() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = '<script>alert(1)</script>';

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.areEqual('alert(1)', gateway.capturedRequest.publicName, 'Tags are removed and the text between them is kept');
    }

    @IsTest
    static void shouldKeepWordsApart_WhenTagsSeparateThem() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = 'Ana<b>López</b> Ruiz';

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.areEqual('Ana López Ruiz', gateway.capturedRequest.publicName, 'A removed tag leaves a space between words');
    }

    @IsTest
    static void shouldRemoveAngleBrackets_WhenTagIsNeverClosed() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = '<img src=x onerror=alert(1)';

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.areEqual('img src=x onerror=alert(1)', gateway.capturedRequest.publicName, 'No angle bracket survives');
    }

    @IsTest
    static void shouldRemoveAngleBracket_WhenItDoesNotOpenATag() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = 'Ana <3 López';

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.areEqual('Ana 3 López', gateway.capturedRequest.publicName, 'Only the bracket is dropped');
    }

    @IsTest
    static void shouldAcceptPublicName_WhenMarkupIsRemovedAndTheResultFitsTheLimit() {
        CapturingGateway gateway = useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = '<b>' + 'a'.repeat(80) + '</b>';

        Test.startTest();
        runAsGuestStart(request);
        Test.stopTest();

        Assert.areEqual('a'.repeat(80), gateway.capturedRequest.publicName, 'The limit applies to the cleaned text');
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
    static void shouldKeepOnlyTheHashOfTheToken_WhenTheDonationStarts() {
        useCapturingGateway();
        DonationStartDTO started;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            started = DonationIntakeService.startDonation(validPublicInvoiceRequest());
        }
        Test.stopTest();

        Payment_Attempt__c attempt = [
            SELECT Portal_Access_Token_Hash__c, Donor_Confirmed_At__c, Superseded_At__c FROM Payment_Attempt__c WITH SYSTEM_MODE
        ];
        Assert.areEqual(DonationAccessToken.hashOf(started.accessToken), attempt.Portal_Access_Token_Hash__c, 'Only the hash is kept');
        Assert.areNotEqual(started.accessToken, attempt.Portal_Access_Token_Hash__c, 'The token itself is never stored');
        Assert.isNull(attempt.Donor_Confirmed_At__c, 'Starting is not confirming');
        Assert.isNull(attempt.Superseded_At__c, 'A new attempt is not replaced');
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

    // DON-05 AC3: a closed campaign cannot be donated to, even if the visitor skips the portal service.
    @IsTest
    static void shouldSaveNoAttempt_WhenClosedCampaignIsSentStraightToThePaymentController() {
        DonationPaymentController.DonationRequest request = new DonationPaymentController.DonationRequest();
        request.campaignId = idOf(CLOSED_CAMPAIGN);
        request.amount = 500;
        request.email = 'donante@example.com';
        request.visibility = 'Anonymous';
        request.invoiceRequested = false;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            try {
                DonationPaymentController.startDonation(request);
                Assert.fail('The payment code must refuse a closed campaign');
            } catch (AuraHandledException e) {
                Assert.isFalse(String.isBlank(e.getMessage()), 'The visitor gets a message');
            }
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No payment attempt is created for a closed campaign');
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
                Assert.areEqual(DonationIntakeService.MSG_START_FAILED, textOf(e), 'No technical detail reaches the donor');
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
        assertStartRejected(request, DonationAmountValidator.MSG_REQUIRED, 'amount null');
        Test.stopTest();
    }

    @IsTest
    static void shouldAcceptAnyAmountAboveTheMinimum_WhenItIsNotInTheSuggestedList() {
        // DON-09: the suggested list only offers options; a custom amount is valid when it reaches the minimum.
        DonationAmountSettings.recordOverride = (Donation_Amount_Setting__mdt) JSON.deserialize(
            '{"Minimum_Amount__c": 50, "Amount_1__c": 150, "Amount_2__c": 2500}', Donation_Amount_Setting__mdt.class);
        CapturingGateway gateway = useCapturingGateway();

        Test.startTest();
        for (String amount : new List<String>{ '150', '100', '1234.5', '7777.77' }) {
            DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
            request.amount = amount;
            runAsGuestStart(request);
        }
        Test.stopTest();

        Assert.areEqual(4, gateway.attemptCalls, 'Suggested and custom amounts start the donation');
        Assert.areEqual(new List<Decimal>{ 150.00, 2500.00 }, DonationIntakeService.getAmountSettings().suggestedAmounts);
        Assert.areEqual('7777.77', gateway.capturedRequest.amount, 'The gateway receives the exact amount as text');
    }

    @IsTest
    static void shouldPassTheAmountWithTwoDecimals_WhenTheDonorTypesFewerDecimals() {
        CapturingGateway gateway = useCapturingGateway();
        Map<String, String> expected = new Map<String, String>{
            '250' => '250.00', '250.5' => '250.50', '250.50' => '250.50', ' 0050.25 ' => '50.25', '99999999999999.99' => '99999999999999.99'
        };

        Test.startTest();
        for (String typed : expected.keySet()) {
            DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
            request.amount = typed;
            runAsGuestStart(request);
            Assert.areEqual(expected.get(typed), gateway.capturedRequest.amount, 'Amount typed as "' + typed + '"');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectAmount_WhenItIsNotAValidAmount() {
        // AC5 of DON-09 on the server, whatever the browser did. The exact messages are in DonationAmountValidatorTest.
        CapturingGateway gateway = useCapturingGateway();

        Test.startTest();
        for (String amount : new List<String>{ '', '   ', '0', '0.00', '-100', '49.99', 'abc', '1e3', '1,000', '$250', '250.555', '100000000000000' }) {
            DonationIntakeService.DonationFormInputDTO request = validAnonymousRequest();
            request.amount = amount;
            System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
                try {
                    DonationIntakeService.startDonation(request);
                    Assert.fail('Expected a rejection for amount "' + amount + '"');
                } catch (AuraHandledException e) {
                    Assert.areEqual(DonationIntakeService.FIELD_AMOUNT, fieldOf(e), 'The error belongs to the amount: "' + amount + '"');
                }
            }
        }
        Test.stopTest();

        Assert.areEqual(0, gateway.attemptCalls, 'The payment code is never called with an invalid amount');
    }

    @IsTest
    static void shouldAcceptEveryAmount_WhenItIsOneOfTheEightSuggested() {
        CapturingGateway gateway = useCapturingGateway();

        Test.startTest();
        for (String amount : new List<String>{ '100', '250', '500', '1000', '2000', '5000', '10000', '20000' }) {
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
    static void shouldRejectPublicName_WhenItIsOnlyMarkup() {
        useCapturingGateway();

        Test.startTest();
        for (String name : new List<String>{ '<b></b>', '<script></script>', '<br/>', '<<>>' }) {
            DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
            request.publicName = name;
            assertStartRejected(request, DonationIntakeService.MSG_PUBLIC_NAME_REQUIRED, 'publicName ' + name);
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectPublicName_WhenCleanedTextHasMoreThanEightyCharacters() {
        useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = '<b>' + 'a'.repeat(81) + '</b>';

        Test.startTest();
        assertStartRejected(request, DonationIntakeService.MSG_PUBLIC_NAME_TOO_LONG, 'cleaned publicName 81');
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectPublicName_WhenRawTextHasMoreThanThreeHundredTwentyCharacters() {
        useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = 'a'.repeat(321);

        Test.startTest();
        assertStartRejected(request, DonationIntakeService.MSG_PUBLIC_NAME_TOO_LONG, 'raw publicName 321');
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

    // DON-17: errors tied to a field and safe messages

    @IsTest
    static void shouldAssociateEachError_WithTheFieldThatMustBeCorrected() {
        CapturingGateway gateway = useCapturingGateway();

        Test.startTest();
        // Called straight on Apex, as when the browser validation is skipped.
        for (FieldCase item : fieldCases()) {
            assertStartRejected(item.request, item.field, item.message, item.scenario);
        }
        Test.stopTest();

        Assert.areEqual(0, gateway.attemptCalls, 'Invalid data never reaches the payment code');
    }

    @IsTest
    static void shouldNotAssociateAnyField_WhenTheErrorIsGeneral() {
        useCapturingGateway();
        DonationIntakeService.DonationFormInputDTO closedCampaign = validAnonymousRequest();
        closedCampaign.campaignId = idOf(PAUSED_CAMPAIGN);
        DonationIntakeService.DonationFormInputDTO badVisibility = validAnonymousRequest();
        badVisibility.visibility = 'Private';

        Test.startTest();
        assertStartRejected(null, '', DonationIntakeService.MSG_MISSING_DATA, 'null request');
        assertStartRejected(closedCampaign, '', DonationIntakeService.MSG_CAMPAIGN_CLOSED, 'campaign that does not accept donations');
        assertStartRejected(badVisibility, '', DonationIntakeService.MSG_VISIBILITY_INVALID, 'visibility');
        Test.stopTest();
    }

    @IsTest
    static void shouldKeepFriendlyMessageOfWorkstreamAWithoutField_WhenGatewayThrowsFriendlyError() {
        CapturingGateway gateway = useCapturingGateway();
        gateway.errorToThrow = CampaignPortalController.userFacingError('Esta campaña ya no acepta donaciones.');

        Test.startTest();
        assertStartRejected(validAnonymousRequest(), '', 'Esta campaña ya no acepta donaciones.', 'friendly error from A');
        Test.stopTest();
    }

    @IsTest
    static void shouldReplaceMessage_WhenWorkstreamAThrowsBlankOrDefaultPlatformMessage() {
        CapturingGateway gateway = useCapturingGateway();
        String token = confirmedToken();

        Test.startTest();
        for (AuraHandledException unsafe : new List<AuraHandledException>{
            CampaignPortalController.userFacingError(''),
            new AuraHandledException('detalle interno')
        }) {
            gateway.errorToThrow = unsafe;
            assertStartRejected(validAnonymousRequest(), '', DonationIntakeService.MSG_START_FAILED, 'unsafe message at startDonation');
            System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
                assertPaymentRejected(token, DonationIntakeService.MSG_PAYMENT_FAILED, 'unsafe message at openPayment');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldNotLeakDonorDataOrTechnicalDetail_WhenGatewayThrowsUnexpectedError() {
        CapturingGateway gateway = useCapturingGateway();
        String token = confirmedToken();
        gateway.errorToThrow = new DmlException(
            'FIELD_CUSTOM_VALIDATION_EXCEPTION at Class.DonationPaymentController: donante@example.com Familia Pérez ' + PERSON_RFC
        );
        DonationIntakeService.DonationFormInputDTO request = validPublicInvoiceRequest();
        request.email = 'donante@example.com';
        request.rfc = PERSON_RFC;
        request.taxRegime = '612';

        Test.startTest();
        assertStartRejected(request, '', DonationIntakeService.MSG_START_FAILED, 'unexpected error at startDonation');
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            try {
                DonationIntakeService.openPayment(token);
                Assert.fail('Expected a friendly error');
            } catch (AuraHandledException e) {
                Assert.areEqual(DonationIntakeService.MSG_PAYMENT_FAILED, textOf(e), 'Safe text at openPayment');
                Assert.isFalse(e.getMessage().containsIgnoreCase('example.com'), 'No email in the message');
                Assert.isFalse(e.getMessage().contains(PERSON_RFC), 'No RFC in the message');
                Assert.isFalse(e.getMessage().containsIgnoreCase('Class.'), 'No internal class name in the message');
            }
        }
        Test.stopTest();
    }

    // openPayment (with the double of the gateway)

    @IsTest
    static void shouldReturnCheckoutUrlFromGateway_WhenTheDonationWasConfirmed() {
        CapturingGateway gateway = useCapturingGateway();
        String token = confirmedToken();
        String url;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            url = DonationIntakeService.openPayment(token);
        }
        Test.stopTest();

        Assert.areEqual(gateway.urlToReturn, url, 'The URL comes from the payment code of Workstream A');
        Assert.areEqual(1, gateway.checkoutCalls, 'The gateway is called once');
    }

    @IsTest
    static void shouldPassTheIdOfTheAttemptOfTheToken_WhenOpeningPayment() {
        CapturingGateway gateway = useCapturingGateway();
        String token = confirmedToken();
        Id attemptId = [SELECT Id FROM Payment_Attempt__c WITH SYSTEM_MODE].Id;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            DonationIntakeService.openPayment(token);
        }
        Test.stopTest();

        Assert.areEqual(attemptId, gateway.capturedAttemptId, 'The server finds the attempt by the token; the browser never sends an Id');
    }

    @IsTest
    static void shouldNeverCallThePaymentCode_WhenTheTokenIsMissingMalformedOrNotATokenAtAll() {
        CapturingGateway gateway = useCapturingGateway();
        confirmedToken();
        String unknownToken = DonationAccessToken.newToken();
        Id attemptId = [SELECT Id FROM Payment_Attempt__c WITH SYSTEM_MODE].Id;

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            for (String token : new List<String>{ null, '', '   ', 'no-es-un-token', String.valueOf(attemptId), idOf(OPEN_CAMPAIGN), unknownToken }) {
                assertPaymentRejected(token, DonationReview.MSG_NOT_AVAILABLE, 'token ' + token);
            }
        }
        Test.stopTest();

        Assert.areEqual(0, gateway.checkoutCalls, 'The gateway is never called without a valid token');
    }

    @IsTest
    static void shouldRejectUrl_WhenGatewayReturnsSomethingThatIsNotHttps() {
        CapturingGateway gateway = useCapturingGateway();
        String token = confirmedToken();

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            for (String url : new List<String>{ null, '', 'http://www.mercadopago.com.mx', 'javascript:alert(1)', '//evil.example' }) {
                gateway.urlToReturn = url;
                assertPaymentRejected(token, DonationIntakeService.MSG_PAYMENT_FAILED, 'url ' + url);
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldPassThroughMessage_WhenGatewayThrowsFriendlyErrorOnPayment() {
        CapturingGateway gateway = useCapturingGateway();
        String token = confirmedToken();
        gateway.errorToThrow = CampaignPortalController.userFacingError('Esta campaña ya no acepta donaciones.');

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            assertPaymentRejected(token, 'Esta campaña ya no acepta donaciones.', 'friendly error from A');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldOfferAnotherAmount_WhenWorkstreamAReportsItsGenericPaymentFailure() {
        // Payment_Preference_Create answers with this generic text when Mercado Pago refuses the payment.
        CapturingGateway gateway = useCapturingGateway();
        String token = confirmedToken();
        gateway.errorToThrow = CampaignPortalController.userFacingError('No pudimos abrir el pago, intenta de nuevo');

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            assertPaymentRejected(token, DonationIntakeService.MSG_PAYMENT_FAILED, 'generic failure of A');
        }
        Test.stopTest();

        Assert.isTrue(DonationIntakeService.MSG_PAYMENT_FAILED.contains('elige otra'), 'The donor is told to choose another amount');
    }

    @IsTest
    static void shouldHideTechnicalDetail_WhenGatewayThrowsUnexpectedErrorOnPayment() {
        CapturingGateway gateway = useCapturingGateway();
        String token = confirmedToken();
        gateway.errorToThrow = new CalloutException('Unauthorized endpoint: detalle técnico');

        Test.startTest();
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            assertPaymentRejected(token, DonationIntakeService.MSG_PAYMENT_FAILED, 'technical error');
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

    // The token of the last donation started through the real gateway. The browser never sends an Id.
    private static String lastToken;

    // Starts the donation as the guest and returns the Id of the saved attempt, to read it back.
    private static String startWithRealGateway(DonationIntakeService.DonationFormInputDTO request) {
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            lastToken = DonationIntakeService.startDonation(request).accessToken;
        }
        return [
            SELECT Id FROM Payment_Attempt__c WHERE Portal_Access_Token_Hash__c = :DonationAccessToken.hashOf(lastToken) WITH SYSTEM_MODE
        ].Id;
    }

    // Starts and confirms, both before Test.startTest, so the payment can be opened with a callout afterwards.
    private static String startConfirmedWithRealGateway(DonationIntakeService.DonationFormInputDTO request) {
        String attemptId = startWithRealGateway(request);
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            DonationIntakeService.confirmDonation(lastToken);
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
    static void shouldSaveCleanPublicName_WhenFormSendsMarkupThroughWorkstreamA() {
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = '<b>Familia</b> <3 Pérez';

        Test.startTest();
        String attemptId = startWithRealGateway(request);
        Test.stopTest();

        Payment_Attempt__c attempt = attemptOf(attemptId);
        Assert.areEqual('Public', attempt.Visibility__c, 'Visibility');
        Assert.areEqual('Familia 3 Pérez', attempt.Public_Name__c, 'The saved name has no markup');
    }

    @IsTest
    static void shouldSaveNoAttempt_WhenFormSendsOnlyMarkupAsPublicName() {
        DonationIntakeService.DonationFormInputDTO request = validPublicRequest();
        request.publicName = '<b></b>';

        Test.startTest();
        assertStartRejected(request, DonationIntakeService.MSG_PUBLIC_NAME_REQUIRED, 'markup-only publicName');
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'No attempt is saved');
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
        String attemptId = startConfirmedWithRealGateway(validAnonymousRequest());
        ProviderMock provider = new ProviderMock(201, PROVIDER_APPROVED_BODY);
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        String url = DonationIntakeService.openPayment(lastToken);
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
        startConfirmedWithRealGateway(validAnonymousRequest());
        Test.setMock(HttpCalloutMock.class, new ProviderMock(500, '{}'));

        Test.startTest();
        try {
            DonationIntakeService.openPayment(lastToken);
            Assert.fail('Expected a friendly error');
        } catch (AuraHandledException e) {
            Assert.areEqual(DonationIntakeService.MSG_PAYMENT_FAILED, textOf(e), 'Message for the donor');
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'A failed attempt is deleted: the donor edits the donation and starts a new attempt');
        Assert.areEqual(0, [SELECT COUNT() FROM Donation__c WITH SYSTEM_MODE], 'No donation');
    }

    @IsTest
    static void shouldNotOpenThePaymentTwice_WhenTheSameTokenIsUsedAgain() {
        startConfirmedWithRealGateway(validAnonymousRequest());
        ProviderMock provider = new ProviderMock(201, PROVIDER_APPROVED_BODY);
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        DonationIntakeService.openPayment(lastToken);
        try {
            DonationIntakeService.openPayment(lastToken);
            Assert.fail('Expected the second opening to be rejected');
        } catch (AuraHandledException e) {
            Assert.areEqual(DonationReview.MSG_NOT_AVAILABLE, textOf(e), 'An attempt with a payment already opened cannot be reviewed or opened again');
        }
        Test.stopTest();

        Assert.areEqual(1, provider.calls, 'Mercado Pago is called once per attempt');
    }

    // Helpers

    // Starts a donation with the double of the gateway and confirms it. The attempt is saved here, before
    // the test that opens the payment calls Test.startTest.
    private static String confirmedToken() {
        String token;
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            token = DonationIntakeService.startDonation(validAnonymousRequest()).accessToken;
            DonationIntakeService.confirmDonation(token);
        }
        return token;
    }

    private static CapturingGateway useCapturingGateway() {
        CapturingGateway gateway = new CapturingGateway();
        DonationIntakeService.gateway = gateway;
        return gateway;
    }

    private static String idOf(String campaignName) {
        return [SELECT Id FROM Fundraising_Campaign__c WHERE Name = :campaignName WITH SYSTEM_MODE LIMIT 1].Id;
    }

    private static DonationIntakeService.DonationFormInputDTO validAnonymousRequest() {
        DonationIntakeService.DonationFormInputDTO request = new DonationIntakeService.DonationFormInputDTO();
        request.campaignId = idOf(OPEN_CAMPAIGN);
        request.amount = '500';
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
        request.privacyNoticeAccepted = true;
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
                Assert.areEqual(expectedMessage, textOf(e), 'Message for: ' + scenario);
            }
        }
    }

    private static void assertStartRejected(
        DonationIntakeService.DonationFormInputDTO request,
        String expectedField,
        String expectedMessage,
        String scenario
    ) {
        System.runAs(PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME)) {
            try {
                DonationIntakeService.startDonation(request);
                Assert.fail('Expected a rejection for: ' + scenario);
            } catch (AuraHandledException e) {
                Assert.areEqual(expectedField, fieldOf(e), 'Field for: ' + scenario);
                Assert.areEqual(expectedMessage, textOf(e), 'Message for: ' + scenario);
            }
        }
    }

    // Every error of the service has the form "<field>|<message>" (DON-17).
    private static String fieldOf(AuraHandledException e) {
        Integer separatorIndex = e.getMessage().indexOf(DonationIntakeService.ERROR_SEPARATOR);
        Assert.isTrue(separatorIndex >= 0, 'Every error has the form field|message');
        return e.getMessage().substring(0, separatorIndex);
    }

    private static String textOf(AuraHandledException e) {
        Integer separatorIndex = e.getMessage().indexOf(DonationIntakeService.ERROR_SEPARATOR);
        Assert.isTrue(separatorIndex >= 0, 'Every error has the form field|message');
        return e.getMessage().substring(separatorIndex + 1);
    }

    private class FieldCase {
        public String scenario;
        public DonationIntakeService.DonationFormInputDTO request;
        public String field;
        public String message;

        public FieldCase(
            String scenario,
            DonationIntakeService.DonationFormInputDTO request,
            String field,
            String message
        ) {
            this.scenario = scenario;
            this.request = request;
            this.field = field;
            this.message = message;
        }
    }

    private static List<FieldCase> fieldCases() {
        List<FieldCase> cases = new List<FieldCase>();

        DonationIntakeService.DonationFormInputDTO noAmount = validAnonymousRequest();
        noAmount.amount = null;
        cases.add(new FieldCase('amount missing', noAmount, 'amount', DonationAmountValidator.MSG_REQUIRED));

        DonationIntakeService.DonationFormInputDTO badEmail = validAnonymousRequest();
        badEmail.email = 'sin-arroba';
        cases.add(new FieldCase('email invalid', badEmail, 'email', DonationIntakeService.MSG_EMAIL_INVALID));

        DonationIntakeService.DonationFormInputDTO noName = validPublicRequest();
        noName.publicName = '   ';
        cases.add(new FieldCase('public name empty', noName, 'publicName', DonationIntakeService.MSG_PUBLIC_NAME_REQUIRED));

        DonationIntakeService.DonationFormInputDTO markupName = validPublicRequest();
        markupName.publicName = '<b></b>';
        cases.add(new FieldCase('public name only markup', markupName, 'publicName', DonationIntakeService.MSG_PUBLIC_NAME_REQUIRED));

        DonationIntakeService.DonationFormInputDTO longName = validPublicRequest();
        longName.publicName = 'a'.repeat(81);
        cases.add(new FieldCase('public name too long', longName, 'publicName', DonationIntakeService.MSG_PUBLIC_NAME_TOO_LONG));

        for (String missing : new List<String>{ 'legalName', 'rfc', 'taxPostalCode', 'taxRegime' }) {
            DonationIntakeService.DonationFormInputDTO incomplete = validPublicInvoiceRequest();
            clearField(incomplete, missing);
            cases.add(new FieldCase('invoice without ' + missing, incomplete, missing, DonationIntakeService.MSG_INVOICE_DATA_MISSING));
        }

        DonationIntakeService.DonationFormInputDTO longLegalName = validPublicInvoiceRequest();
        longLegalName.legalName = 'a'.repeat(255);
        cases.add(new FieldCase('legal name too long', longLegalName, 'legalName', DonationIntakeService.MSG_LEGAL_NAME_TOO_LONG));

        DonationIntakeService.DonationFormInputDTO badRfc = validPublicInvoiceRequest();
        badRfc.rfc = 'GODE561331GR8';
        badRfc.taxRegime = '612';
        cases.add(new FieldCase('rfc month 13', badRfc, 'rfc', DonationIntakeService.MSG_RFC_INVALID));

        DonationIntakeService.DonationFormInputDTO badPostalCode = validPublicInvoiceRequest();
        badPostalCode.taxPostalCode = '9700';
        cases.add(new FieldCase('postal code 4 digits', badPostalCode, 'taxPostalCode', DonationIntakeService.MSG_POSTAL_CODE_INVALID));

        DonationIntakeService.DonationFormInputDTO unknownRegime = validPublicInvoiceRequest();
        unknownRegime.taxRegime = '999';
        cases.add(new FieldCase('regime not in catalog', unknownRegime, 'taxRegime', DonationIntakeService.MSG_REGIME_INVALID));

        DonationIntakeService.DonationFormInputDTO wrongRegime = validPublicInvoiceRequest();
        wrongRegime.taxRegime = '605';
        cases.add(new FieldCase('regime for the other taxpayer type', wrongRegime, 'taxRegime', DonationIntakeService.MSG_REGIME_MISMATCH));

        return cases;
    }

    private static void assertPaymentRejected(String attemptId, String expectedMessage, String scenario) {
        try {
            DonationIntakeService.openPayment(attemptId);
            Assert.fail('Expected a rejection for: ' + scenario);
        } catch (AuraHandledException e) {
            Assert.areEqual(expectedMessage, textOf(e), 'Message for: ' + scenario);
        }
    }
}
