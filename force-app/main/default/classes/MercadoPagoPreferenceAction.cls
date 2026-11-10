/**
 * DON-19 / PAY-07. Creates a Mercado Pago Checkout Pro preference.
 *
 * This is the only piece of the payment start written in Apex: the flow
 * Payment_Preference_Create does the validation and record work, and calls this
 * action only for the HTTP request, so the provider responses can be tested with
 * HttpCalloutMock (approved, provider error, timeout), as DON-19 requires.
 *
 * The access token is never handled here: the Named Credential MercadoPagoAPI adds
 * the Authorization header (see docs/security.md, section 3).
 */
public with sharing class MercadoPagoPreferenceAction {
    @TestVisible
    private static final String ENDPOINT = 'callout:MercadoPagoAPI/checkout/preferences';
    private static final Integer TIMEOUT_MS = 20000;

    public static final String ERROR_PROVIDER = 'ProviderError';
    public static final String ERROR_UNAVAILABLE = 'Unavailable';
    public static final String ERROR_INVALID_RESPONSE = 'InvalidResponse';

    /**
     * Input from the flow: the attempt and the server-validated amount.
     */
    public class Request {
        @InvocableVariable(label='Id del intento' description='Se envía como external_reference.' required=true)
        public String attemptId;

        @InvocableVariable(label='Monto' description='Monto validado en el servidor (MXN).' required=true)
        public Decimal amount;

        @InvocableVariable(label='Título' description='Texto que ve el donante en Mercado Pago.' required=true)
        public String title;

        @InvocableVariable(label='URL de retorno' description='Página de agradecimiento (success, failure y pending).' required=true)
        public String returnUrl;

        @InvocableVariable(label='URL de avisos' description='Entrada pública de avisos (PAY-06, E2). Opcional.')
        public String notificationUrl;
    }

    /**
     * Output to the flow. errorType tells provider errors apart from an unavailable provider.
     */
    public class Result {
        @InvocableVariable(label='Éxito')
        public Boolean success = false;

        @InvocableVariable(label='Id de preferencia')
        public String preferenceId;

        @InvocableVariable(label='URL de pago')
        public String checkoutUrl;

        @InvocableVariable(label='Tipo de error' description='ProviderError, Unavailable o InvalidResponse.')
        public String errorType;
    }

    /**
     * Creates one Checkout Pro preference per request.
     * @param requests attempts to open a payment for
     * @return one result per request, in the same order
     */
    @InvocableMethod(label='Crear preferencia de Mercado Pago' category='Mercado Pago' callout=true)
    public static List<Result> createPreferences(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request request : requests) {
            results.add(createPreference(request));
        }
        return results;
    }

    private static Result createPreference(Request request) {
        Result result = new Result();
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(ENDPOINT);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setTimeout(TIMEOUT_MS);
        httpRequest.setBody(JSON.serialize(buildBody(request)));

        try {
            HttpResponse response = new Http().send(httpRequest);
            Integer status = response.getStatusCode();
            if (status != 200 && status != 201) {
                // The response body is not kept or logged: it may echo request data.
                result.errorType = ERROR_PROVIDER;
                return result;
            }
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            result.preferenceId = (String) body.get('id');
            result.checkoutUrl = (String) body.get('init_point');
            result.success = String.isNotBlank(result.preferenceId) && String.isNotBlank(result.checkoutUrl);
            if (!result.success) {
                result.errorType = ERROR_INVALID_RESPONSE;
            }
        } catch (CalloutException e) {
            result.errorType = ERROR_UNAVAILABLE;
        } catch (JSONException e) {
            result.errorType = ERROR_INVALID_RESPONSE;
        } catch (TypeException e) {
            result.errorType = ERROR_INVALID_RESPONSE;
        }
        return result;
    }

    @TestVisible
    private static Map<String, Object> buildBody(Request request) {
        Map<String, Object> item = new Map<String, Object>{
            'title' => request.title,
            'quantity' => 1,
            'unit_price' => request.amount.setScale(2),
            'currency_id' => 'MXN'
        };
        Map<String, Object> body = new Map<String, Object>{
            'items' => new List<Object>{ item },
            'external_reference' => request.attemptId,
            'back_urls' => new Map<String, Object>{
                'success' => request.returnUrl,
                'failure' => request.returnUrl,
                'pending' => request.returnUrl
            },
            'auto_return' => 'approved',
            // Cash and ATM payments can stay pending for days, longer than the
            // 7-day retention of attempts (PAY-07), so only cards are offered.
            'payment_methods' => new Map<String, Object>{
                'excluded_payment_types' => new List<Object>{
                    new Map<String, Object>{ 'id' => 'ticket' },
                    new Map<String, Object>{ 'id' => 'atm' }
                }
            }
        };
        if (String.isNotBlank(request.notificationUrl)) {
            body.put('notification_url', request.notificationUrl);
        }
        return body;
    }
}
