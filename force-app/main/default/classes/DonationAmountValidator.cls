/**
 * DON-09. Validates the amount of a donation as the text the donor typed, before it becomes a Decimal.
 *
 * The browser sends the amount as text so that no digit is lost on the way (a JavaScript Number
 * cannot hold all the 16 digits of Currency(16, 2)). This class is the authority: the checks of the
 * form only help the donor. It checks, in this order: the text is not empty, it is a plain decimal
 * number, it has at most two decimals, it fits in Payment_Attempt__c.Amount__c, it is greater than
 * zero and it reaches the current minimum of the configuration (ADM-13, DonationAmountSettings).
 *
 * It sets no maximum of its own. The only upper limit is the capacity of the Amount__c field; any
 * other limit belongs to Mercado Pago, which rejects what it cannot process (DON-09, AC6).
 */
public with sharing class DonationAmountValidator {
    @TestVisible
    private static final String MSG_REQUIRED = 'Elige un monto para continuar.';
    @TestVisible
    private static final String MSG_FORMAT = 'Escribe solo números, con punto decimal. Por ejemplo: 250 o 250.50.';
    @TestVisible
    private static final String MSG_DECIMALS = 'Usa como máximo dos decimales.';
    @TestVisible
    private static final String MSG_POSITIVE = 'El monto debe ser mayor a cero.';
    @TestVisible
    private static final String MSG_TOO_MANY_DIGITS = 'Escribe un monto con menos dígitos.';
    @TestVisible
    private static final String MSG_BELOW_MINIMUM = 'El monto mínimo es de ${0} MXN.';

    private static final Integer MAX_DECIMALS = 2;
    // Whole and decimal digits of the text; the groups are read by parse.
    // [0-9] and not \d on purpose: only the ASCII digits are accepted.
    private static final Pattern NUMBER_PATTERN = Pattern.compile('^([0-9]+)(?:\\.([0-9]+))?$');
    private static final Pattern NEGATIVE_PATTERN = Pattern.compile('^-[0-9]+(?:\\.[0-9]+)?$');
    private static final String LEADING_ZEROS = '^0+(?=[0-9])';

    private static Integer integerDigitCapacity;

    /** Thrown with a Spanish message that is safe to show to the donor. */
    public class AmountException extends Exception {
    }

    /**
     * Full validation of the amount typed by the donor.
     *
     * @param rawAmount text of the amount, for example "250" or "250.50"
     * @return the exact amount as a Decimal
     * @throws AmountException with the message to show to the donor when the amount is not valid
     */
    public static Decimal validate(String rawAmount) {
        Decimal amount = parse(rawAmount);
        if (!DonationAmountSettings.meetsMinimum(amount)) {
            String minimum = DonationAmountSettings.current().minimumAmount.stripTrailingZeros().toPlainString();
            throw new AmountException(String.format(MSG_BELOW_MINIMUM, new List<String>{ minimum }));
        }
        return amount;
    }

    /**
     * Checks the text and converts it, without the minimum of the configuration.
     *
     * @param rawAmount text of the amount
     * @return the exact amount as a Decimal, greater than zero and with at most two decimals
     * @throws AmountException when the text is empty, is not a plain number, has more than two
     * decimals, does not fit in Amount__c or is not greater than zero
     */
    public static Decimal parse(String rawAmount) {
        String text = rawAmount?.trim();
        if (String.isBlank(text)) {
            throw new AmountException(MSG_REQUIRED);
        }
        if (NEGATIVE_PATTERN.matcher(text).matches()) {
            throw new AmountException(MSG_POSITIVE);
        }
        Matcher parts = NUMBER_PATTERN.matcher(text);
        if (!parts.matches()) {
            throw new AmountException(MSG_FORMAT);
        }
        assertShape(parts.group(1), parts.group(2));
        Decimal amount = Decimal.valueOf(text);
        if (amount <= 0) {
            throw new AmountException(MSG_POSITIVE);
        }
        return amount;
    }

    /**
     * Writes a validated amount as the text that travels to the payment code.
     *
     * @param amount a validated amount
     * @return the amount with exactly two decimals, as text
     */
    public static String toExactText(Decimal amount) {
        return amount.setScale(MAX_DECIMALS).toPlainString();
    }

    /**
     * Whole digits that Payment_Attempt__c.Amount__c can hold. It is read from the field (precision
     * minus scale), so it follows the field and is not repeated here. It is a technical limit of the
     * field, not a business maximum.
     *
     * @return number of whole digits, 14 for Currency(16, 2)
     */
    @TestVisible
    private static Integer integerDigitCapacity() {
        if (integerDigitCapacity == null) {
            Schema.DescribeFieldResult field = Payment_Attempt__c.Amount__c.getDescribe();
            integerDigitCapacity = field.getPrecision() - field.getScale();
        }
        return integerDigitCapacity;
    }

    private static void assertShape(String wholePart, String decimalPart) {
        if (decimalPart != null && decimalPart.length() > MAX_DECIMALS) {
            throw new AmountException(MSG_DECIMALS);
        }
        if (wholePart.replaceFirst(LEADING_ZEROS, '').length() > integerDigitCapacity()) {
            throw new AmountException(MSG_TOO_MANY_DIGITS);
        }
    }
}
