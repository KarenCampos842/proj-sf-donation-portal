/**
 * PAY-06. Public REST entry for Mercado Pago payment notices (Webhooks, event "Pagos").
 *
 * URL (through the site, as the guest user):
 *   https://<site domain>/portalvforcesite/services/apexrest/mp/notifications
 *
 * It only reads the request and hands it to MercadoPagoNotificationService, which checks
 * the signature before doing anything else. The guest user gets access to this class
 * through the Mercado_Pago_Callout permission set.
 */
@RestResource(urlMapping='/mp/notifications')
global without sharing class MercadoPagoWebhookResource {
    @HttpPost
    global static void receive() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        MercadoPagoNotificationService.Notice notice = new MercadoPagoNotificationService.Notice();
        notice.signature = header(request, 'x-signature');
        notice.requestId = header(request, 'x-request-id');
        notice.dataId = request.params.get('data.id');
        notice.type = request.params.get('type');
        readBody(request, notice);

        Integer status = MercadoPagoNotificationService.process(notice);
        response.statusCode = status;
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(status == MercadoPagoNotificationService.STATUS_OK
            ? '{"received":true}' : '{"received":false}');
    }

    private static String header(RestRequest request, String name) {
        for (String key : request.headers.keySet()) {
            if (key.equalsIgnoreCase(name)) {
                return request.headers.get(key);
            }
        }
        return null;
    }

    // The body only fills what the query string did not bring. It is never trusted for
    // amounts or statuses.
    private static void readBody(RestRequest request, MercadoPagoNotificationService.Notice notice) {
        if (request.requestBody == null || (String.isNotBlank(notice.dataId) && String.isNotBlank(notice.type))) {
            return;
        }
        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(request.requestBody.toString());
            if (String.isBlank(notice.type) && body.get('type') instanceof String) {
                notice.type = (String) body.get('type');
            }
            Object data = body.get('data');
            if (String.isBlank(notice.dataId) && data instanceof Map<String, Object>) {
                Object id = ((Map<String, Object>) data).get('id');
                notice.dataId = id == null ? null : String.valueOf(id);
            }
        } catch (Exception e) {
            // Not JSON: the signature check rejects it.
            return;
        }
    }
}
