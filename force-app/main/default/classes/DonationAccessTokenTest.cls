/**
 * DON-18: the access token that authorizes the review of one payment attempt. It must be random, long,
 * different every time, and only its hash may be kept.
 */
@IsTest
private class DonationAccessTokenTest {
    @IsTest
    static void shouldCreateA256BitToken_WrittenAs64HexadecimalCharacters() {
        String token = DonationAccessToken.newToken();

        Assert.areEqual(64, token.length(), '256 bits in hexadecimal');
        Assert.isTrue(DonationAccessToken.isWellFormed(token), 'It has the shape of a token');
        Assert.isTrue(Pattern.matches('^[0-9a-f]+$', token), 'Lowercase hexadecimal only');
    }

    @IsTest
    static void shouldNeverRepeatAToken_WhenManyAreCreated() {
        Set<String> tokens = new Set<String>();
        Set<String> hashes = new Set<String>();

        for (Integer i = 0; i < 200; i++) {
            String token = DonationAccessToken.newToken();
            tokens.add(token);
            hashes.add(DonationAccessToken.hashOf(token));
        }

        Assert.areEqual(200, tokens.size(), 'Every token is different');
        Assert.areEqual(200, hashes.size(), 'Every hash is different');
    }

    @IsTest
    static void shouldHashWithSha256_WhenTheTokenIsStored() {
        String token = DonationAccessToken.newToken();
        String hash = DonationAccessToken.hashOf(token);

        Assert.areEqual(64, hash.length(), 'SHA-256 in hexadecimal');
        Assert.areEqual(hash, DonationAccessToken.hashOf(token), 'The same token always gives the same hash');
        Assert.areNotEqual(token, hash, 'The hash is not the token');
        Assert.areEqual(
            EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf('abc'))),
            DonationAccessToken.hashOf('abc'),
            'It is a plain SHA-256 digest'
        );
        Assert.areNotEqual(hash, DonationAccessToken.hashOf(DonationAccessToken.newToken()), 'Another token gives another hash');
    }

    @IsTest
    static void shouldRecognizeOnlyTheShapeOfAToken_WhenTextComesFromTheBrowser() {
        String token = DonationAccessToken.newToken();
        List<String> notTokens = new List<String>{
            null, '', ' ', 'abc', token.substring(1), token + '0', token.toUpperCase(), token.replace(token.substring(0, 1), 'g'),
            'a1d000000000001AAA', '<script>alert(1)</script>', ' ' + token, token + '\n'
        };

        Assert.isTrue(DonationAccessToken.isWellFormed(token));
        for (String notToken : notTokens) {
            Assert.isFalse(DonationAccessToken.isWellFormed(notToken), 'Not a token: "' + notToken + '"');
        }
    }

    @IsTest
    static void shouldNotOutliveTheAttempt_WhenTheLifetimeIsCompared() {
        Integer pay07RetentionMinutes = 7 * 24 * 60;

        Assert.isTrue(DonationReview.TOKEN_LIFETIME_MINUTES > 0, 'A token has a lifetime');
        Assert.isTrue(DonationReview.TOKEN_LIFETIME_MINUTES < pay07RetentionMinutes, 'PAY-07 deletes the attempt after 7 days');
    }
}
