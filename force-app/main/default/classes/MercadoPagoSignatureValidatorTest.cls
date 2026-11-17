@IsTest
private class MercadoPagoSignatureValidatorTest {
    private static final String SECRET = 'test-webhook-secret';
    private static final Long NOW_MS = 1763300000000L;
    private static final String TS = String.valueOf(NOW_MS / 1000L);

    // Built by hand, as in the Mercado Pago documentation, not with the class under test.
    private static String sign(String manifest, String secret) {
        return EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', Blob.valueOf(manifest), Blob.valueOf(secret)));
    }

    private static String header(String ts, String v1) {
        return 'ts=' + ts + ',v1=' + v1;
    }

    @IsTest
    static void authenticNoticeIsValid() {
        String v1 = sign('id:123456;request-id:req-1;ts:' + TS + ';', SECRET);
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.VALID,
            MercadoPagoSignatureValidator.validate(header(TS, v1), 'req-1', '123456', SECRET, NOW_MS));
    }

    @IsTest
    static void orderAndSpacesInTheHeaderDoNotMatter() {
        String v1 = sign('id:123456;request-id:req-1;ts:' + TS + ';', SECRET);
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.VALID,
            MercadoPagoSignatureValidator.validate('v1=' + v1.toUpperCase() + ', ts=' + TS, 'req-1', '123456', SECRET, NOW_MS));
    }

    @IsTest
    static void timestampInMillisecondsIsAccepted() {
        String tsMs = String.valueOf(NOW_MS);
        String v1 = sign('id:123456;request-id:req-1;ts:' + tsMs + ';', SECRET);
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.VALID,
            MercadoPagoSignatureValidator.validate(header(tsMs, v1), 'req-1', '123456', SECRET, NOW_MS));
    }

    @IsTest
    static void missingPartsAreLeftOutOfTheSignedText() {
        String v1 = sign('id:abc123;ts:' + TS + ';', SECRET);
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.VALID,
            MercadoPagoSignatureValidator.validate(header(TS, v1), null, 'ABC123', SECRET, NOW_MS),
            'Alphanumeric ids are lowercased and a missing request id is skipped');
    }

    @IsTest
    static void alteredNoticeIsInvalid() {
        // PAY-01 AC3: the signature was made for another payment id.
        String v1 = sign('id:123456;request-id:req-1;ts:' + TS + ';', SECRET);
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.INVALID_SIGNATURE,
            MercadoPagoSignatureValidator.validate(header(TS, v1), 'req-1', '999999', SECRET, NOW_MS));
    }

    @IsTest
    static void signatureWithAnotherSecretIsInvalid() {
        // PAY-01 AC2: someone who does not know the secret.
        String v1 = sign('id:123456;request-id:req-1;ts:' + TS + ';', 'guessed-secret');
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.INVALID_SIGNATURE,
            MercadoPagoSignatureValidator.validate(header(TS, v1), 'req-1', '123456', SECRET, NOW_MS));
    }

    @IsTest
    static void oldNoticeIsExpired() {
        // PAY-01 AC4: a real notice sent again 6 minutes later.
        String v1 = sign('id:123456;request-id:req-1;ts:' + TS + ';', SECRET);
        Long sixMinutesLater = NOW_MS + 6L * 60L * 1000L;
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.EXPIRED,
            MercadoPagoSignatureValidator.validate(header(TS, v1), 'req-1', '123456', SECRET, sixMinutesLater));
    }

    @IsTest
    static void malformedHeadersAreInvalid() {
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.MISSING_SIGNATURE,
            MercadoPagoSignatureValidator.validate(null, 'req-1', '1', SECRET, NOW_MS));
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.INVALID_SIGNATURE,
            MercadoPagoSignatureValidator.validate('garbage', 'req-1', '1', SECRET, NOW_MS));
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.INVALID_SIGNATURE,
            MercadoPagoSignatureValidator.validate('ts=abc,v1=00', 'req-1', '1', SECRET, NOW_MS));
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.INVALID_SIGNATURE,
            MercadoPagoSignatureValidator.validate('ts=' + TS + ',v1=00', 'req-1', '1', SECRET, NOW_MS));
    }

    @IsTest
    static void missingSecretIsReported() {
        Assert.areEqual(MercadoPagoSignatureValidator.Outcome.MISSING_SECRET,
            MercadoPagoSignatureValidator.validate('ts=1,v1=2', 'req-1', '1', null, NOW_MS));
    }
}
