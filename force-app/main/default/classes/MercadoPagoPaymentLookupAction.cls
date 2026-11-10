/**
 * DON-21 / PAY-02. Reads a payment from Mercado Pago (GET /v1/payments/{id}).
 *
 * The thank-you page only passes the payment id it received in the URL. Status,
 * amount, date and external_reference always come from this authenticated query,
 * never from URL parameters (DON-21 TAC). The flow Payment_Return_Process does the
 * rest; this action exists only so provider responses can be tested with
 * HttpCalloutMock.
 *
 * The access token is added by the Named Credential MercadoPagoAPI.
 */
public with sharing class MercadoPagoPaymentLookupAction {
    @TestVisible
    private static final String ENDPOINT_PREFIX = 'callout:MercadoPagoAPI/v1/payments/';
    private static final Integer TIMEOUT_MS = 20000;
    private static final String CURRENCY_MXN = 'MXN';

    public static final String ERROR_INVALID_ID = 'InvalidId';
    public static final String ERROR_NOT_FOUND = 'NotFound';
    public static final String ERROR_PROVIDER = 'ProviderError';
    public static final String ERROR_UNAVAILABLE = 'Unavailable';
    public static final String ERROR_INVALID_RESPONSE = 'InvalidResponse';

    /**
     * Input from the flow: the payment id received in the return URL.
     */
    public class Request {
        @InvocableVariable(label='Id del pago' description='payment_id que regresó Mercado Pago.' required=true)
        public String paymentId;
    }

    /**
     * Output to the flow. When found is false, errorType says why.
     */
    public class Result {
        @InvocableVariable(label='Encontrado')
        public Boolean found = false;

        @InvocableVariable(label='Id del pago')
        public String paymentId;

        @InvocableVariable(label='Estado' description='approved, pending, in_process, rejected, cancelled, ...')
        public String status;

        @InvocableVariable(label='Referencia externa' description='Id del intento de pago.')
        public String externalReference;

        @InvocableVariable(label='Monto confirmado')
        public Decimal transactionAmount;

        @InvocableVariable(label='Fecha de aprobación')
        public DateTime dateApproved;

        @InvocableVariable(label='Tipo de error' description='InvalidId, NotFound, ProviderError, Unavailable o InvalidResponse.')
        public String errorType;
    }

    /**
     * Looks up each payment in Mercado Pago.
     * @param requests payment ids to look up
     * @return one result per request, in the same order
     */
    @InvocableMethod(label='Consultar pago de Mercado Pago' category='Mercado Pago' callout=true)
    public static List<Result> lookupPayments(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request request : requests) {
            results.add(lookupPayment(request));
        }
        return results;
    }

    private static Result lookupPayment(Request request) {
        Result result = new Result();
        // Only digits are accepted, so the id can never change the request path.
        if (String.isBlank(request.paymentId) || !request.paymentId.isNumeric()) {
            result.errorType = ERROR_INVALID_ID;
            return result;
        }

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(ENDPOINT_PREFIX + request.paymentId);
        httpRequest.setMethod('GET');
        httpRequest.setTimeout(TIMEOUT_MS);

        try {
            HttpResponse response = new Http().send(httpRequest);
            Integer status = response.getStatusCode();
            if (status == 404) {
                result.errorType = ERROR_NOT_FOUND;
                return result;
            }
            if (status != 200) {
                result.errorType = ERROR_PROVIDER;
                return result;
            }
            readPayment((Map<String, Object>) JSON.deserializeUntyped(response.getBody()), result);
        } catch (CalloutException e) {
            result.errorType = ERROR_UNAVAILABLE;
        } catch (JSONException e) {
            result.errorType = ERROR_INVALID_RESPONSE;
        } catch (TypeException e) {
            result.errorType = ERROR_INVALID_RESPONSE;
        }
        return result;
    }

    private static void readPayment(Map<String, Object> body, Result result) {
        Object id = body.get('id');
        Object amount = body.get('transaction_amount');
        Object approved = body.get('date_approved');
        result.paymentId = id == null ? null : String.valueOf(id);
        result.status = (String) body.get('status');
        result.externalReference = (String) body.get('external_reference');
        result.transactionAmount = amount == null ? null : Decimal.valueOf(String.valueOf(amount));
        result.dateApproved = approved == null ? null : parseDateTime((String) approved);

        if (String.isBlank(result.paymentId) || String.isBlank(result.status)
                || body.get('currency_id') != CURRENCY_MXN) {
            result.errorType = ERROR_INVALID_RESPONSE;
            return;
        }
        result.found = true;
    }

    @TestVisible
    private static DateTime parseDateTime(String isoValue) {
        // Mercado Pago sends ISO 8601 with offset, e.g. 2026-11-09T12:00:00.000-06:00.
        return (DateTime) JSON.deserialize(JSON.serialize(isoValue), DateTime.class);
    }
}
