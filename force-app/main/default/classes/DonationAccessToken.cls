/**
 * DON-18. The access token of a payment attempt.
 *
 * The portal has no login, so the Id of a Salesforce record can never authorize anything. When the
 * donor starts a donation the server creates a random token, hands it to the browser once and keeps
 * only its SHA-256 hash in Payment_Attempt__c.Portal_Access_Token_Hash__c. Whoever holds the token
 * can review, confirm, edit and pay that one attempt; nobody can derive the token from the hash.
 *
 * This class has no queries and no DML: it only makes and checks tokens.
 */
public with sharing class DonationAccessToken {
    // 256 random bits written in hexadecimal, and the SHA-256 hash of the token, also in hexadecimal.
    private static final Integer TOKEN_KEY_BITS = 256;
    private static final Pattern WELL_FORMED = Pattern.compile('^[0-9a-f]{64}$');
    private static final String HASH_ALGORITHM = 'SHA-256';

    /**
     * Creates an unguessable token. It comes from the cryptographic generator of the platform, never
     * from Math.random, a timestamp, an Id or a counter.
     *
     * @return the token, 64 lowercase hexadecimal characters. Return it to the browser once and never store it
     */
    public static String newToken() {
        return EncodingUtil.convertToHex(Crypto.generateAesKey(TOKEN_KEY_BITS));
    }

    /**
     * Hashes a token with SHA-256, so Salesforce never has to keep the token itself.
     *
     * @param token a token created by newToken
     * @return its SHA-256 hash, 64 lowercase hexadecimal characters, the only value kept in Salesforce
     */
    public static String hashOf(String token) {
        return EncodingUtil.convertToHex(Crypto.generateDigest(HASH_ALGORITHM, Blob.valueOf(token)));
    }

    /**
     * Cheap check done before any query, so text that cannot be a token never reaches the database.
     *
     * @param token text received from the browser
     * @return true when it has the shape of a token (this does not mean it is valid)
     */
    public static Boolean isWellFormed(String token) {
        return token != null && WELL_FORMED.matcher(token).matches();
    }
}
