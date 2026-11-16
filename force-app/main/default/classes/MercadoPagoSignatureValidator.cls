/**
 * PAY-01. Checks that a payment notice really comes from Mercado Pago.
 *
 * Mercado Pago signs each webhook with the secret of the Webhooks panel and sends
 * x-signature: ts=<timestamp>,v1=<hex HMAC-SHA256>. The signed text is
 * id:{data.id};request-id:{x-request-id};ts:{ts};  (parts that did not arrive are left
 * out). A notice is valid only when the HMAC matches and ts is within 5 minutes.
 */
public with sharing class MercadoPagoSignatureValidator {
    @TestVisible
    private static final Long TOLERANCE_MS = 5L * 60L * 1000L;

    public enum Outcome { VALID, MISSING_SIGNATURE, INVALID_SIGNATURE, EXPIRED, MISSING_SECRET }

    /**
     * @param xSignature value of the x-signature header
     * @param requestId value of the x-request-id header
     * @param dataId data.id of the notice (query parameter)
     * @param secret webhook secret
     * @param nowMs current time in milliseconds
     * @return VALID, or why the notice is not authentic
     */
    public static Outcome validate(String xSignature, String requestId, String dataId, String secret, Long nowMs) {
        if (String.isBlank(secret)) {
            return Outcome.MISSING_SECRET;
        }
        if (String.isBlank(xSignature)) {
            return Outcome.MISSING_SIGNATURE;
        }
        String ts;
        String v1;
        for (String part : xSignature.split(',')) {
            List<String> pair = part.split('=', 2);
            if (pair.size() != 2) {
                continue;
            }
            String key = pair[0].trim();
            if (key == 'ts') {
                ts = pair[1].trim();
            } else if (key == 'v1') {
                v1 = pair[1].trim().toLowerCase();
            }
        }
        if (String.isBlank(ts) || !ts.isNumeric() || String.isBlank(v1)) {
            return Outcome.INVALID_SIGNATURE;
        }

        String expected = EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256',
            Blob.valueOf(manifest(dataId, requestId, ts)), Blob.valueOf(secret)));
        if (!constantTimeEquals(expected, v1)) {
            return Outcome.INVALID_SIGNATURE;
        }
        if (Math.abs(nowMs - toMillis(ts)) > TOLERANCE_MS) {
            return Outcome.EXPIRED;
        }
        return Outcome.VALID;
    }

    /**
     * Signed text as Mercado Pago builds it. Alphanumeric data.id values are lowercased.
     */
    @TestVisible
    private static String manifest(String dataId, String requestId, String ts) {
        String text = '';
        if (String.isNotBlank(dataId)) {
            text += 'id:' + (dataId.isAlphanumeric() ? dataId.toLowerCase() : dataId) + ';';
        }
        if (String.isNotBlank(requestId)) {
            text += 'request-id:' + requestId + ';';
        }
        return text + 'ts:' + ts + ';';
    }

    // ts may come in seconds (10 digits) or milliseconds (13 digits).
    private static Long toMillis(String ts) {
        Long value = Long.valueOf(ts);
        return ts.length() <= 10 ? value * 1000L : value;
    }

    // Compares every character, so the time taken does not reveal how much matched.
    private static Boolean constantTimeEquals(String a, String b) {
        if (a.length() != b.length()) {
            return false;
        }
        Integer diff = 0;
        for (Integer i = 0; i < a.length(); i++) {
            diff |= a.charAt(i) ^ b.charAt(i);
        }
        return diff == 0;
    }
}
