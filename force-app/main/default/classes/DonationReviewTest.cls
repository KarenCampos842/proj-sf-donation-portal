/**
 * DON-18: review and confirmation of the donation before the payment. It runs against the real flows of
 * Workstream A, as the simulated guest (no access to Payment_Attempt__c or Donation__c); only the answers
 * of Mercado Pago are simulated. The access token is the only thing that authorizes a step.
 */
@IsTest
private class DonationReviewTest {
    private static final String OPEN_CAMPAIGN = 'Campaña abierta DON-18';
    private static final String COMPANY_RFC = 'ABC010203XY1';
    private static final String CHECKOUT_URL = 'https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=123-pref';

    /** Answers the preference request and the payment lookup of Mercado Pago, and keeps what was sent. */
    private class ProviderMock implements HttpCalloutMock {
        public Integer preferenceCalls = 0;
        public String preferenceRequestBody;
        public String paymentBody;

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(request.getEndpoint().contains('checkout/preferences') ? 201 : 200);
            if (request.getEndpoint().contains('checkout/preferences')) {
                preferenceCalls++;
                preferenceRequestBody = request.getBody();
                response.setBody('{"id":"123-pref","init_point":"' + CHECKOUT_URL + '"}');
            } else {
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

    // AC1 and AC2: what the summary shows

    @IsTest
    static void shouldShowCampaignExactAmountEmailVisibilityAndInvoice_WhenTheDonorReviews() {
        String token = start(request('1234.5', 'Anonymous', false));

        DonationSummaryDTO summary = summaryAsGuest(token);

        Assert.areEqual(OPEN_CAMPAIGN, summary.campaignName, 'Campaign');
        Assert.areEqual('1234.50', summary.amount, 'The exact amount, with two decimals');
        Assert.areEqual('donante@example.com', summary.email, 'Email');
        Assert.areEqual('Anonymous', summary.visibility, 'Visibility');
        Assert.isFalse(summary.invoiceRequested, 'No invoice');
    }

    @IsTest
    static void shouldShowThePublicName_OnlyWhenTheDonationIsPublic() {
        DonationSummaryDTO publicSummary = summaryAsGuest(start(request('500', 'Public', false)));
        DonationSummaryDTO anonymousSummary = summaryAsGuest(start(request('500', 'Anonymous', false)));

        Assert.areEqual('Public', publicSummary.visibility);
        Assert.areEqual('Familia Pérez', publicSummary.publicName, 'The name that will be shown');
        Assert.areEqual('Anonymous', anonymousSummary.visibility);
        Assert.isNull(anonymousSummary.publicName, 'An anonymous donation shows no name, even if the form sent one');
    }

    @IsTest
    static void shouldKeepTheInvoiceIndependentFromTheVisibility_WhenTheDonorReviews() {
        DonationSummaryDTO anonymousWithInvoice = summaryAsGuest(start(request('500', 'Anonymous', true)));
        DonationSummaryDTO publicWithInvoice = summaryAsGuest(start(request('500', 'Public', true)));
        DonationSummaryDTO publicWithoutInvoice = summaryAsGuest(start(request('500', 'Public', false)));

        Assert.isTrue(anonymousWithInvoice.invoiceRequested, 'An anonymous donation can ask for an invoice');
        Assert.isNull(anonymousWithInvoice.publicName, 'and its name stays hidden');
        Assert.isTrue(publicWithInvoice.invoiceRequested);
        Assert.isFalse(publicWithoutInvoice.invoiceRequested);
    }

    @IsTest
    static void shouldBuildTheSummaryFromTheSavedValues_NotFromWhatTheBrowserSends() {
        String token = start(request('250', 'Anonymous', false));
        Payment_Attempt__c attempt = attemptOf(token);
        updateAttempt(new Payment_Attempt__c(Id = attempt.Id, Amount__c = 777.77, Email__c = 'guardado@example.com'));

        DonationSummaryDTO summary = summaryAsGuest(token);

        Assert.areEqual('777.77', summary.amount, 'The summary reads the saved attempt');
        Assert.areEqual('guardado@example.com', summary.email);
    }

    @IsTest
    static void shouldExposeOnlyTheFieldsOfTheReview_WhenTheSummaryIsSerialized() {
        String token = start(request('500', 'Public', true));
        Payment_Attempt__c attempt = attemptOf(token);

        String serialized = JSON.serialize(summaryAsGuest(token));
        Map<String, Object> fields = (Map<String, Object>) JSON.deserializeUntyped(serialized);

        Assert.areEqual(
            new Set<String>{ 'campaignName', 'amount', 'email', 'visibility', 'publicName', 'invoiceRequested' },
            fields.keySet(),
            'No Id, no hash, no fiscal or internal field'
        );
        Assert.isFalse(serialized.contains(String.valueOf(attempt.Id)), 'The Id of the attempt is not exposed');
        Assert.isFalse(serialized.contains(attempt.Portal_Access_Token_Hash__c), 'The hash is not exposed');
        Assert.isFalse(serialized.contains(COMPANY_RFC), 'No RFC');
        Assert.isFalse(serialized.contains('Familia Pérez S.A. de C.V.'), 'No legal name');
    }

    // The token is the only authorization

    @IsTest
    static void shouldGiveNoDataAndChangeNothing_WhenTheTokenIsInvalidEmptyOrOfNobody() {
        start(request('500', 'Anonymous', false));
        List<String> tokens = new List<String>{ null, '', '  ', 'no-es-un-token', DonationAccessToken.newToken() };

        for (String token : tokens) {
            assertNotAvailable(token, 'summary');
            assertNotAvailable(token, 'confirm');
            assertNotAvailable(token, 'attemptToPay');
        }
        DonationIntakeService.invalidateDonation(null);
        DonationIntakeService.invalidateDonation(DonationAccessToken.newToken());

        Payment_Attempt__c attempt = [
            SELECT Donor_Confirmed_At__c, Superseded_At__c, Portal_Access_Token_Hash__c FROM Payment_Attempt__c WITH SYSTEM_MODE
        ];
        Assert.isNull(attempt.Donor_Confirmed_At__c, 'Nothing was confirmed');
        Assert.isNull(attempt.Superseded_At__c, 'Nothing was replaced');
        Assert.isNotNull(attempt.Portal_Access_Token_Hash__c, 'The token still works');
    }

    @IsTest
    static void shouldNotAcceptTheIdOfTheAttemptOrTheHash_WhenTheyAreUsedAsToken() {
        String token = start(request('500', 'Anonymous', false));
        Payment_Attempt__c attempt = attemptOf(token);

        assertNotAvailable(String.valueOf(attempt.Id), 'summary');
        assertNotAvailable(String.valueOf(attempt.Id), 'attemptToPay');
        assertNotAvailable(attempt.Portal_Access_Token_Hash__c, 'summary');
        assertNotAvailable(attempt.Portal_Access_Token_Hash__c, 'confirm');
    }

    @IsTest
    static void shouldOnlyAuthorizeItsOwnAttempt_WhenAnotherDonationIsInProgress() {
        String tokenA = start(request('100', 'Anonymous', false));
        String tokenB = start(request('200', 'Anonymous', false));

        confirmAsGuest(tokenA);

        Assert.isNotNull(attemptOf(tokenA).Donor_Confirmed_At__c, 'A is confirmed');
        Assert.isNull(attemptOf(tokenB).Donor_Confirmed_At__c, 'The token of A does not confirm B');
        Assert.areEqual('200.00', summaryAsGuest(tokenB).amount, 'Each token shows its own donation');
        assertNotConfirmed(tokenB);
    }

    // AC5: confirmation recorded by the server

    @IsTest
    static void shouldRegisterTheServerDate_WhenTheDonorConfirms() {
        String token = start(request('500', 'Anonymous', false));
        Datetime before = System.now();

        confirmAsGuest(token);

        Datetime confirmedAt = attemptOf(token).Donor_Confirmed_At__c;
        Assert.isNotNull(confirmedAt, 'The confirmation is saved in the server');
        // The platform keeps whole seconds, so the window starts one second early.
        Assert.isTrue(confirmedAt >= before.addSeconds(-1) && confirmedAt <= System.now(), 'The date is the one of the server');
    }

    @IsTest
    static void shouldKeepTheFirstDate_WhenTheDonorConfirmsTwice() {
        String token = start(request('500', 'Anonymous', false));
        confirmAsGuest(token);
        Datetime first = attemptOf(token).Donor_Confirmed_At__c;

        confirmAsGuest(token);

        Assert.areEqual(first, attemptOf(token).Donor_Confirmed_At__c, 'Confirming again changes nothing');
    }

    @IsTest
    static void shouldNotChangeTheStatus_WhenTheDonorConfirms() {
        String token = start(request('500', 'Anonymous', false));

        confirmAsGuest(token);

        Assert.areEqual('Started', attemptOf(token).Status__c, 'Only the states of Workstream A exist: confirming is not a state');
    }

    @IsTest
    static void shouldNotOpenThePayment_WhenTheDonorDidNotConfirm_ForSuggestedAndCustomAmounts() {
        ProviderMock provider = new ProviderMock();
        Test.setMock(HttpCalloutMock.class, provider);
        String suggested = start(request('500', 'Anonymous', false));
        String custom = start(request('333.33', 'Anonymous', false));

        Test.startTest();
        for (String token : new List<String>{ suggested, custom }) {
            System.runAs(guest()) {
                try {
                    DonationIntakeService.openPayment(token);
                    Assert.fail('The payment must not open without a confirmation');
                } catch (AuraHandledException e) {
                    Assert.isTrue(e.getMessage().endsWith(DonationReview.MSG_NOT_CONFIRMED), 'The donor is asked to confirm');
                }
            }
        }
        Test.stopTest();

        Assert.areEqual(0, provider.preferenceCalls, 'Mercado Pago is never called');
        Assert.areEqual(0, [SELECT COUNT() FROM Payment_Attempt__c WHERE Preference_Id__c != NULL WITH SYSTEM_MODE], 'No payment was opened');
    }

    // AC3: the payment opens with exactly the reviewed amount and campaign

    @IsTest
    static void shouldOpenThePaymentWithTheReviewedAmountAndCampaign_WhenTheDonorConfirmed() {
        String token = start(request('1234.56', 'Public', false));
        DonationSummaryDTO reviewed = summaryAsGuest(token);
        confirmAsGuest(token);
        ProviderMock provider = new ProviderMock();
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        String url = DonationIntakeService.openPayment(token);
        Test.stopTest();

        Assert.areEqual(CHECKOUT_URL, url);
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(provider.preferenceRequestBody);
        Map<String, Object> item = (Map<String, Object>) ((List<Object>) body.get('items'))[0];
        Assert.areEqual(Decimal.valueOf(reviewed.amount), Decimal.valueOf(String.valueOf(item.get('unit_price'))), 'The provider charges the reviewed amount');
        Assert.isTrue(String.valueOf(item.get('title')).contains(reviewed.campaignName), 'for the reviewed campaign');
        Assert.areEqual(String.valueOf(attemptOf(token).Id), body.get('external_reference'), 'tied to the confirmed attempt');
    }

    @IsTest
    static void shouldNotLetTheDonorChangeTheAmountAfterTheReview_WhenTheBrowserSendsAnotherOne() {
        String token = start(request('250', 'Anonymous', false));
        confirmAsGuest(token);
        // Starting another donation with a different amount creates another attempt and another token.
        String otherToken = start(request('9999', 'Anonymous', false));
        ProviderMock provider = new ProviderMock();
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        DonationIntakeService.openPayment(token);
        Test.stopTest();

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(provider.preferenceRequestBody);
        Map<String, Object> item = (Map<String, Object>) ((List<Object>) body.get('items'))[0];
        Assert.areEqual(250, Decimal.valueOf(String.valueOf(item.get('unit_price'))), 'The amount of the reviewed attempt is charged');
        Assert.isNull(attemptOf(otherToken).Preference_Id__c, 'The other attempt did not open a payment');
    }

    // Attempts that can no longer open a payment

    @IsTest
    static void shouldRejectAnAttemptThatWasAlreadyOpened_WhenTheTokenIsUsedAgain() {
        String token = start(request('500', 'Anonymous', false));
        confirmAsGuest(token);
        updateAttempt(new Payment_Attempt__c(Id = attemptOf(token).Id, Preference_Id__c = 'pref-ya-creada'));
        Test.setMock(HttpCalloutMock.class, new ProviderMock());

        Test.startTest();
        assertNotAvailable(token, 'attemptToPay');
        assertNotAvailable(token, 'summary');
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectAnAttemptThatIsNoLongerStarted_WhenItWasRejectedCancelledOrConfirmed() {
        for (String status : new List<String>{ 'Rejected', 'Cancelled', 'Confirmed' }) {
            String token = start(request('500', 'Anonymous', false));
            confirmAsGuest(token);
            updateAttempt(new Payment_Attempt__c(Id = attemptOf(token).Id, Status__c = status));

            assertNotAvailable(token, 'attemptToPay');
            assertNotAvailable(token, 'summary');
        }
    }

    @IsTest
    static void shouldRejectAnExpiredToken_WhenTheLifetimeIsOver() {
        String expired = start(request('500', 'Anonymous', false));
        String fresh = start(request('500', 'Anonymous', false));
        confirmAsGuest(expired);
        confirmAsGuest(fresh);
        Test.setCreatedDate(attemptOf(expired).Id, System.now().addMinutes(-(DonationReview.TOKEN_LIFETIME_MINUTES + 1)));

        assertNotAvailable(expired, 'attemptToPay');
        assertNotAvailable(expired, 'summary');
        Assert.areEqual('500.00', summaryAsGuest(fresh).amount, 'A token inside its lifetime keeps working');
    }

    @IsTest
    static void shouldNotRetireTheAttempt_WhenEditingAnAttemptThatAlreadyOpenedAPayment() {
        String token = start(request('500', 'Anonymous', false));
        confirmAsGuest(token);
        updateAttempt(new Payment_Attempt__c(Id = attemptOf(token).Id, Preference_Id__c = 'pref-ya-creada'));

        Test.startTest();
        System.runAs(guest()) {
            DonationIntakeService.invalidateDonation(token);
        }
        Test.stopTest();

        Payment_Attempt__c attempt = attemptOf(token);
        Assert.isNull(attempt.Superseded_At__c, 'An attempt with a preference must not be marked as superseded');
        Assert.areEqual(DonationAccessToken.hashOf(token), attempt.Portal_Access_Token_Hash__c, 'The hash must be kept');
        Assert.areEqual('pref-ya-creada', attempt.Preference_Id__c, 'The preference is untouched');
    }

    @IsTest
    static void shouldNotRetireTheAttempt_WhenEditingAnAttemptThatIsNotStartedOrIsExpired() {
        for (String status : new List<String>{ 'Rejected', 'Cancelled', 'Confirmed' }) {
            String token = start(request('500', 'Anonymous', false));
            updateAttempt(new Payment_Attempt__c(Id = attemptOf(token).Id, Status__c = status));

            DonationIntakeService.invalidateDonation(token);

            Assert.isNull(attemptOf(token).Superseded_At__c, 'Status ' + status + ' is not retired by an edit');
        }
        String expired = start(request('500', 'Anonymous', false));
        Test.setCreatedDate(attemptOf(expired).Id, System.now().addMinutes(-(DonationReview.TOKEN_LIFETIME_MINUTES + 1)));

        DonationIntakeService.invalidateDonation(expired);

        Payment_Attempt__c attempt = attemptOf(expired);
        Assert.isNull(attempt.Superseded_At__c, 'An expired attempt is not retired by an edit');
        Assert.isNotNull(attempt.Portal_Access_Token_Hash__c, 'The hash is kept');
    }

    // AC4: edit and confirm again

    @IsTest
    static void shouldStopTheOldToken_WhenTheDonorEdits() {
        String token = start(request('500', 'Anonymous', false));
        confirmAsGuest(token);
        Datetime before = System.now();

        System.runAs(guest()) {
            DonationIntakeService.invalidateDonation(token);
        }

        Payment_Attempt__c attempt = [
            SELECT Status__c, Portal_Access_Token_Hash__c, Superseded_At__c, Donor_Confirmed_At__c FROM Payment_Attempt__c WITH SYSTEM_MODE
        ];
        Assert.isNull(attempt.Portal_Access_Token_Hash__c, 'The hash is cleared');
        Assert.isTrue(attempt.Superseded_At__c >= before.addSeconds(-1), 'The audit date is the one of the server');
        Assert.areEqual('Started', attempt.Status__c, 'The status does not change');
        assertNotAvailable(token, 'summary');
        assertNotAvailable(token, 'confirm');
        assertNotAvailable(token, 'attemptToPay');
    }

    @IsTest
    static void shouldRequireANewConfirmation_WhenTheDonorEditsAndContinuesWithAnotherAmount() {
        String oldToken = start(request('500', 'Anonymous', false));
        confirmAsGuest(oldToken);
        System.runAs(guest()) {
            DonationIntakeService.invalidateDonation(oldToken);
        }

        String newToken = start(request('750.25', 'Anonymous', false));

        Assert.areNotEqual(oldToken, newToken, 'A new token');
        Assert.areEqual(2, [SELECT COUNT() FROM Payment_Attempt__c WITH SYSTEM_MODE], 'A new attempt with the updated data');
        Assert.areEqual('750.25', summaryAsGuest(newToken).amount, 'A new summary');
        assertNotConfirmed(newToken);
        Assert.isNull(attemptOf(newToken).Donor_Confirmed_At__c, 'The old confirmation does not carry over');
    }

    @IsTest
    static void shouldPayOnlyTheNewAttempt_WhenTheDonorEditedAndConfirmedAgain() {
        String oldToken = start(request('500', 'Anonymous', false));
        confirmAsGuest(oldToken);
        System.runAs(guest()) {
            DonationIntakeService.invalidateDonation(oldToken);
        }
        String newToken = start(request('750.25', 'Anonymous', false));
        confirmAsGuest(newToken);
        ProviderMock provider = new ProviderMock();
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        DonationIntakeService.openPayment(newToken);
        assertNotAvailable(oldToken, 'attemptToPay');
        Test.stopTest();

        Assert.areEqual(1, provider.preferenceCalls, 'One payment only');
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(provider.preferenceRequestBody);
        Map<String, Object> item = (Map<String, Object>) ((List<Object>) body.get('items'))[0];
        Assert.areEqual(750.25, Decimal.valueOf(String.valueOf(item.get('unit_price'))), 'The new amount is charged');
    }

    // The guest keeps no direct access

    @IsTest
    static void shouldWorkForTheGuestWithoutDirectAccessToThePaymentAttempts() {
        String token = start(request('500', 'Anonymous', false));

        System.runAs(guest()) {
            try {
                Database.query('SELECT Id FROM Payment_Attempt__c', AccessLevel.USER_MODE);
                Assert.fail('The guest has no permission on Payment_Attempt__c');
            } catch (QueryException e) {
                Assert.isNotNull(e.getMessage(), 'Direct reads are refused');
            }
            Assert.areEqual('500.00', DonationIntakeService.getDonationSummary(token).amount, 'but the token lets the server read its own attempt');
        }
    }

    // The thank-you page keeps working

    @IsTest
    static void shouldConfirmThePaymentOnTheReturnPage_WhenTheDonorWentThroughTheReview() {
        String token = start(request('500', 'Anonymous', false));
        confirmAsGuest(token);
        Payment_Attempt__c attempt = attemptOf(token);
        ProviderMock provider = new ProviderMock();
        provider.paymentBody = '{"id":98765432,"status":"approved","external_reference":"' + attempt.Id + '","transaction_amount":500.00,' +
            '"currency_id":"MXN","date_approved":"2026-11-09T12:00:00.000-06:00"}';
        Test.setMock(HttpCalloutMock.class, provider);

        Test.startTest();
        String state = DonationPaymentController.getPaymentResult('98765432');
        Test.stopTest();

        Assert.areEqual('Confirmed', state, 'The return page still verifies the payment and registers the donation');
        Assert.areEqual(1, [SELECT COUNT() FROM Donation__c WHERE Provider_Payment_Id__c = '98765432' WITH SYSTEM_MODE]);
    }

    // A save that fails must never show the donor a technical message

    @IsTest
    static void shouldGiveTheSafeMessage_WhenTheConfirmationCannotBeSaved() {
        Id deletedAttemptId = deletedAttemptId();

        try {
            DonationReview.saveConfirmation(deletedAttemptId);
            Assert.fail('Saving the confirmation of a deleted attempt must fail');
        } catch (AuraHandledException e) {
            Assert.areEqual('|' + DonationReview.MSG_NOT_AVAILABLE, e.getMessage(), 'A safe message, with no field');
        }
    }

    @IsTest
    static void shouldGiveTheSafeMessage_WhenTheReplacementCannotBeSaved() {
        Id deletedAttemptId = deletedAttemptId();

        try {
            DonationReview.saveReplacement(deletedAttemptId);
            Assert.fail('Saving the replacement of a deleted attempt must fail');
        } catch (AuraHandledException e) {
            Assert.areEqual('|' + DonationReview.MSG_NOT_AVAILABLE, e.getMessage(), 'A safe message, with no field');
        }
    }

    // Helpers

    private static Id deletedAttemptId() {
        String token = start(request('500', 'Anonymous', false));
        Payment_Attempt__c attempt = attemptOf(token);
        Database.delete(attempt, AccessLevel.SYSTEM_MODE);
        return attempt.Id;
    }

    // Updates in system mode, like the flows and PaymentAttemptAccess: the test user has no access to every field.
    private static void updateAttempt(Payment_Attempt__c changes) {
        Database.update(changes, AccessLevel.SYSTEM_MODE);
    }

    private static User guest() {
        return PortalTestDataFactory.getUser(PortalTestDataFactory.GUEST_LAST_NAME);
    }

    private static DonationIntakeService.DonationFormInputDTO request(String amount, String visibility, Boolean invoice) {
        DonationIntakeService.DonationFormInputDTO request = new DonationIntakeService.DonationFormInputDTO();
        request.campaignId = [SELECT Id FROM Fundraising_Campaign__c WHERE Name = :OPEN_CAMPAIGN WITH SYSTEM_MODE LIMIT 1].Id;
        request.amount = amount;
        request.email = 'donante@example.com';
        request.visibility = visibility;
        request.publicName = 'Familia Pérez';
        request.invoiceRequested = invoice;
        if (invoice) {
            request.legalName = 'Familia Pérez S.A. de C.V.';
            request.rfc = COMPANY_RFC;
            request.taxPostalCode = '97000';
            request.taxRegime = '601';
            request.privacyNoticeAccepted = true;
        }
        return request;
    }

    private static String start(DonationIntakeService.DonationFormInputDTO request) {
        String token;
        System.runAs(guest()) {
            token = DonationIntakeService.startDonation(request).accessToken;
        }
        return token;
    }

    private static DonationSummaryDTO summaryAsGuest(String token) {
        DonationSummaryDTO summary;
        System.runAs(guest()) {
            summary = DonationIntakeService.getDonationSummary(token);
        }
        return summary;
    }

    private static void confirmAsGuest(String token) {
        System.runAs(guest()) {
            DonationIntakeService.confirmDonation(token);
        }
    }

    private static Payment_Attempt__c attemptOf(String token) {
        return [
            SELECT Id, Status__c, Preference_Id__c, Donor_Confirmed_At__c, Superseded_At__c, Portal_Access_Token_Hash__c
            FROM Payment_Attempt__c
            WHERE Portal_Access_Token_Hash__c = :DonationAccessToken.hashOf(token)
            WITH SYSTEM_MODE
        ];
    }

    private static void assertNotConfirmed(String token) {
        System.runAs(guest()) {
            try {
                DonationIntakeService.openPayment(token);
                Assert.fail('The payment must not open without a confirmation');
            } catch (AuraHandledException e) {
                Assert.areEqual('|' + DonationReview.MSG_NOT_CONFIRMED, e.getMessage());
            }
        }
    }

    // Every operation answers a token that does not allow it with the same message, whoever asks.
    private static void assertNotAvailable(String token, String operation) {
        System.runAs(guest()) {
            try {
                if (operation == 'summary') {
                    DonationIntakeService.getDonationSummary(token);
                } else if (operation == 'confirm') {
                    DonationIntakeService.confirmDonation(token);
                } else {
                    DonationIntakeService.openPayment(token);
                }
                Assert.fail('Expected a rejection of ' + operation + ' for token "' + token + '"');
            } catch (AuraHandledException e) {
                Assert.areEqual('|' + DonationReview.MSG_NOT_AVAILABLE, e.getMessage(), operation + ' for "' + token + '"');
            }
        }
    }
}
