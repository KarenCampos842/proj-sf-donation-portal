/**
 * PAY-06 / PAY-01 / PAY-03 / DON-24 / ADM-12. Processes a Mercado Pago payment notice.
 *
 * Order of work:
 *  1. The signature is checked first (PAY-01). Nothing privileged happens before that.
 *  2. Only notices of type "payment" are processed.
 *  3. The payment is always read again from Mercado Pago (GET /v1/payments/{id}); the
 *     notice body is never used for the amount or the status.
 *  4. Donation_Register registers the donation once (unique payment id, PAY-03). It does
 *     not check whether the campaign is still open: that is checked when the attempt and
 *     the payment are created, so a payment made before the close still counts (DON-24).
 *
 * Every rejected or ignored notice is saved in Rejected_Notice__c with a safe reason;
 * ids that come from an unauthenticated notice are stored masked (ADM-12 AC3).
 *
 * Runs without sharing because the site guest user, which receives the notice, has no
 * permission on attempts, donations or notices.
 *
 * Returns the HTTP status for Mercado Pago: 200 accepted, repeated or ignored (no retry);
 * 400 invalid signature; 500 temporary failure, so Mercado Pago retries later.
 */
public without sharing class MercadoPagoNotificationService {
    public static final Integer STATUS_OK = 200;
    public static final Integer STATUS_INVALID = 400;
    public static final Integer STATUS_RETRY = 500;

    @TestVisible
    private static final String TYPE_PAYMENT = 'payment';
    private static final Set<String> IGNORED_STATUSES = new Set<String>{ 'refunded', 'charged_back' };
    private static final Set<String> TEMPORARY_ERRORS = new Set<String>{
        MercadoPagoPaymentLookupAction.ERROR_UNAVAILABLE,
        MercadoPagoPaymentLookupAction.ERROR_PROVIDER,
        MercadoPagoPaymentLookupAction.ERROR_INVALID_RESPONSE
    };

    @TestVisible
    private static Long nowMs = null;

    /**
     * What the webhook received.
     */
    public class Notice {
        public String signature;
        public String requestId;
        public String dataId;
        public String type;
    }

    /**
     * @param notice headers and parameters of the received notice
     * @return HTTP status to answer
     */
    public static Integer process(Notice notice) {
        Mercado_Pago_Webhook__c settings = Mercado_Pago_Webhook__c.getOrgDefaults();
        String secret = settings == null ? null : settings.Secret__c;
        MercadoPagoSignatureValidator.Outcome check = MercadoPagoSignatureValidator.validate(
            notice.signature, notice.requestId, notice.dataId, secret,
            nowMs != null ? nowMs : DateTime.now().getTime());

        if (check == MercadoPagoSignatureValidator.Outcome.MISSING_SECRET) {
            saveNotice('Invalid_Signature', 'La firma secreta no está configurada en Salesforce.', mask(notice.dataId));
            return STATUS_RETRY;
        }
        if (check != MercadoPagoSignatureValidator.Outcome.VALID) {
            saveNotice('Invalid_Signature', signatureDetail(check), mask(notice.dataId));
            return STATUS_INVALID;
        }
        if (notice.type != TYPE_PAYMENT) {
            saveNotice('Unsupported_Type', 'Tipo recibido: ' + safeText(notice.type), mask(notice.dataId));
            return STATUS_OK;
        }

        MercadoPagoPaymentLookupAction.Result payment = lookup(notice.dataId);
        if (!payment.found) {
            if (TEMPORARY_ERRORS.contains(payment.errorType)) {
                return STATUS_RETRY;
            }
            saveNotice('Attempt_Not_Found', 'El pago no existe en Mercado Pago.', mask(notice.dataId));
            return STATUS_OK;
        }
        if (IGNORED_STATUSES.contains(payment.status)) {
            saveNotice('Refund_Ignored', 'Pago ' + payment.status + ': fuera de alcance, no se cambió ninguna donación.',
                payment.paymentId);
            return STATUS_OK;
        }
        return register(payment);
    }

    private static Integer register(MercadoPagoPaymentLookupAction.Result payment) {
        Savepoint beforeRegister = Database.setSavepoint();
        String outcome;
        try {
            Flow.Interview interview = Flow.Interview.createInterview('Donation_Register', new Map<String, Object>{
                'attemptId' => payment.externalReference,
                'providerPaymentId' => payment.paymentId,
                'paymentStatus' => payment.status,
                'confirmedAmount' => payment.transactionAmount,
                'approvedAt' => payment.dateApproved
            });
            interview.start();
            outcome = (String) interview.getVariableValue('outcome');
        } catch (Exception e) {
            // Nothing half-done stays saved (PAY-06 AC5); Mercado Pago will retry.
            Database.rollback(beforeRegister);
            return STATUS_RETRY;
        }

        switch on outcome {
            when 'AlreadyProcessed' {
                saveNotice('Duplicate_Notice', 'El pago ya estaba registrado; no se creó otra donación.', payment.paymentId);
            }
            when 'InvalidInput' {
                saveNotice('Attempt_Not_Found', 'El pago no trae una referencia de intento.', payment.paymentId);
            }
            when 'Error' {
                Database.rollback(beforeRegister);
                return STATUS_RETRY;
            }
        }
        // Registered, AmountMismatch and AttemptNotFound (already saved by the flow),
        // Rejected, Cancelled and NotConfirmed: answered, no retry.
        return STATUS_OK;
    }

    private static MercadoPagoPaymentLookupAction.Result lookup(String paymentId) {
        MercadoPagoPaymentLookupAction.Request request = new MercadoPagoPaymentLookupAction.Request();
        request.paymentId = paymentId;
        return MercadoPagoPaymentLookupAction.lookupPayments(
            new List<MercadoPagoPaymentLookupAction.Request>{ request })[0];
    }

    private static String signatureDetail(MercadoPagoSignatureValidator.Outcome check) {
        switch on check {
            when MISSING_SIGNATURE {
                return 'El aviso no trae firma.';
            }
            when EXPIRED {
                return 'El aviso llegó fuera de la ventana de 5 minutos.';
            }
            when else {
                return 'La firma no coincide con el aviso.';
            }
        }
    }

    private static void saveNotice(String reason, String detail, String technicalId) {
        Database.insert(new Rejected_Notice__c(
            Reason__c = reason,
            Detail__c = detail.left(255),
            Technical_Id__c = technicalId == null ? null : technicalId.left(64),
            Received_At__c = DateTime.now()
        ), AccessLevel.SYSTEM_MODE);
    }

    /**
     * Shows only the start and the end of a value that came from an unauthenticated notice.
     */
    @TestVisible
    private static String mask(String value) {
        String clean = safeText(value);
        if (String.isBlank(clean)) {
            return null;
        }
        return clean.length() > 8 ? clean.left(4) + '…' + clean.right(4) : '****';
    }

    // Keeps letters, digits, dot, dash and underscore only, up to 40 characters.
    private static String safeText(String value) {
        if (value == null) {
            return '';
        }
        return value.replaceAll('[^A-Za-z0-9._-]', '').left(40);
    }
}
