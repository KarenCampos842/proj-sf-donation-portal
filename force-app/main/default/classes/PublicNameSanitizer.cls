/**
 * Cleans the public name of a donor before it is saved (DON-11, RNF-04).
 *
 * Every entry point that the site guest user can call and that saves a public name uses this
 * class: DonationIntakeService (the portal form) and DonationPaymentController.startDonation
 * (Workstream A, callable directly). The interface also shows names as text, never as HTML.
 *
 * Pure text processing: no queries, no DML.
 */
public with sharing class PublicNameSanitizer {
    /** Longest public name that can be saved (Payment_Attempt__c.Public_Name__c is Text(80)). */
    public static final Integer MAX_LENGTH = 80;
    /** Longer raw text is rejected before cleaning, so the regex never runs on oversized input. */
    public static final Integer MAX_RAW_LENGTH = 320;

    private static final Pattern HTML_TAG_PATTERN = Pattern.compile('<[/!?]?[A-Za-z][^>]*>');

    /**
     * Removes control characters and HTML tags, drops any leftover angle bracket and collapses
     * spaces. A removed tag leaves a space, so the words around it stay apart. The text between
     * tags is kept as plain text.
     *
     * @param rawName name as typed by the donor
     * @return the cleaned name; an empty text when the input is null, blank or only markup
     * @example
     * String name = PublicNameSanitizer.sanitize('Ana<b>López</b>'); // 'Ana López'
     */
    public static String sanitize(String rawName) {
        if (rawName == null) {
            return '';
        }
        String withoutControl = rawName.replaceAll('\\p{Cntrl}', ' ');
        String withoutTags = HTML_TAG_PATTERN.matcher(withoutControl).replaceAll(' ');
        return withoutTags.replaceAll('[<>]', '').normalizeSpace();
    }

    /**
     * Tells whether a name is too long to be saved. The raw length is checked first, then the
     * length of the cleaned text, so markup that is removed does not count against the limit.
     *
     * @param rawName name as typed by the donor
     * @return true when the raw text exceeds MAX_RAW_LENGTH or the cleaned text exceeds MAX_LENGTH
     * @example
     * Boolean tooLong = PublicNameSanitizer.isTooLong('a'.repeat(81)); // true
     */
    public static Boolean isTooLong(String rawName) {
        if (rawName == null) {
            return false;
        }
        return rawName.length() > MAX_RAW_LENGTH || sanitize(rawName).length() > MAX_LENGTH;
    }
}
