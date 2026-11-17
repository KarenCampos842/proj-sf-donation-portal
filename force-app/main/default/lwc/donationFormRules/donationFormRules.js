import { FORM_MESSAGES } from 'c/donationFormMessages';

export const VISIBILITY_ANONYMOUS = 'Anonymous';
export const VISIBILITY_PUBLIC = 'Public';
export const TAXPAYER_PERSON = 'PERSON';
export const TAXPAYER_COMPANY = 'COMPANY';

export const MAX_EMAIL_LENGTH = 80;
export const MAX_PUBLIC_NAME_LENGTH = 80;
export const MAX_LEGAL_NAME_LENGTH = 254;

// Amounts of Delivery 1 (DON-08). Since ADM-13 the form shows the amounts of the configuration
// (DonationIntakeService.getAmountSettings); these are only shown while it loads or if it fails.
export const SUGGESTED_AMOUNTS = [100, 250, 500, 1000, 2000, 5000, 10000, 20000];

// DON-09. Value of the "Otro monto" option of the amount radio group.
export const OTHER_AMOUNT = 'other';

// Whole digits that Payment_Attempt__c.Amount__c (Currency(16, 2)) can hold. It is a limit of the field,
// not a business maximum. The server reads the same value from the field and is the authority.
export const MAX_INTEGER_DIGITS = 14;
const MAX_DECIMALS = 2;
const AMOUNT_PATTERN = /^[0-9]+(\.[0-9]+)?$/;
const NEGATIVE_AMOUNT_PATTERN = /^-[0-9]+(\.[0-9]+)?$/;
const MINIMUM_AMOUNT_PATTERN = /^[0-9]+(\.[0-9]{1,2})?$/;
const LEADING_ZEROS = /^0+(?=[0-9])/;
// Cents of an amount of zero, already normalized (see toCents).
const ZERO_CENTS = '0';

// Same patterns as the server (DonationIntakeService) and the RFC_Format validation rule.
const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/;
export const RFC_PATTERN = /^[A-ZÑ&]{3,4}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[A-Z0-9]{2}[0-9A]$/;
const POSTAL_CODE_PATTERN = /^[0-9]{5}$/;
const CONTROL_CHARACTERS = /\p{Cc}/gu;

// DON-17. DonationIntakeService throws every donor message as "<field>|<message>", where the field
// is one of the data-field names of the form, or empty when the error belongs to no field.
// Anything that does not have this shape (platform or unexpected errors) is never shown.
const SERVER_ERROR_PATTERN = /^(amount|email|publicName|legalName|rfc|taxPostalCode|taxRegime|privacyNoticeAccepted)?\|([\s\S]+)$/;

// SAT c_RegimenFiscal catalog (docs/data-model.md, appendix). The guest user cannot read the
// Payment_Attempt__c picklist, so the list is local. Pending verification against Annex 20 (V-05).
export const TAX_REGIMES = [
    { value: '601', label: '601 - General de Ley Personas Morales', person: false, company: true },
    { value: '603', label: '603 - Personas Morales con Fines no Lucrativos', person: false, company: true },
    { value: '605', label: '605 - Sueldos y Salarios e Ingresos Asimilados a Salarios', person: true, company: false },
    { value: '606', label: '606 - Arrendamiento', person: true, company: false },
    { value: '607', label: '607 - Régimen de Enajenación o Adquisición de Bienes', person: true, company: false },
    { value: '608', label: '608 - Demás ingresos', person: true, company: false },
    {
        value: '610',
        label: '610 - Residentes en el Extranjero sin Establecimiento Permanente en México',
        person: true,
        company: true
    },
    { value: '611', label: '611 - Ingresos por Dividendos (socios y accionistas)', person: true, company: false },
    {
        value: '612',
        label: '612 - Personas Físicas con Actividades Empresariales y Profesionales',
        person: true,
        company: false
    },
    { value: '614', label: '614 - Ingresos por intereses', person: true, company: false },
    { value: '615', label: '615 - Régimen de los ingresos por obtención de premios', person: true, company: false },
    { value: '616', label: '616 - Sin obligaciones fiscales', person: true, company: false },
    {
        value: '620',
        label: '620 - Sociedades Cooperativas de Producción que optan por diferir sus ingresos',
        person: false,
        company: true
    },
    { value: '621', label: '621 - Incorporación Fiscal', person: true, company: false },
    {
        value: '622',
        label: '622 - Actividades Agrícolas, Ganaderas, Silvícolas y Pesqueras',
        person: false,
        company: true
    },
    { value: '623', label: '623 - Opcional para Grupos de Sociedades', person: false, company: true },
    { value: '624', label: '624 - Coordinados', person: false, company: true },
    {
        value: '625',
        label: '625 - Actividades Empresariales con ingresos a través de Plataformas Tecnológicas',
        person: true,
        company: false
    },
    { value: '626', label: '626 - Régimen Simplificado de Confianza', person: true, company: true }
];

/**
 * Collapses spaces and removes control characters. Angle brackets stay as plain text because the
 * interface always shows names as text, never as HTML.
 * @param {string} value text typed by the donor
 * @returns {string} cleaned text
 */
export function normalizeText(value) {
    return String(value ?? '')
        .replace(CONTROL_CHARACTERS, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

/**
 * RFC in uppercase and without any space.
 * @param {string} value RFC as typed
 * @returns {string} sanitized RFC
 */
export function sanitizeRfc(value) {
    return String(value ?? '')
        .toUpperCase()
        .replace(/\s+/g, '');
}

/**
 * Taxpayer type derived from the RFC length, like the Taxpayer_Type__c formula: 12 characters
 * for a company and 13 for a person. It is never asked as an independent field.
 * @param {string} rfc sanitized RFC
 * @returns {string|null} TAXPAYER_PERSON, TAXPAYER_COMPANY or null when the length is not final
 */
export function getTaxpayerType(rfc) {
    if (rfc.length === 12) {
        return TAXPAYER_COMPANY;
    }
    return rfc.length === 13 ? TAXPAYER_PERSON : null;
}

/**
 * Regimes the donor can choose. Without a known taxpayer type the whole catalog is shown.
 * @param {string|null} taxpayerType TAXPAYER_PERSON, TAXPAYER_COMPANY or null
 * @returns {Array<{label: string, value: string}>} combobox options
 */
export function getRegimeOptions(taxpayerType) {
    return TAX_REGIMES.filter((regime) => {
        if (taxpayerType === TAXPAYER_PERSON) {
            return regime.person;
        }
        return taxpayerType === TAXPAYER_COMPANY ? regime.company : true;
    }).map(({ label, value }) => ({ label, value }));
}

/**
 * Reads the error of startDonation or openPayment.
 * @param {object} error error rejected by the Apex call
 * @returns {{field: string, message: string}|null} the field to correct (empty for a general
 * error) and the donor message, or null when the error is not a donor message
 */
export function parseServerError(error) {
    const raw = error?.body?.message;
    const match = typeof raw === 'string' ? SERVER_ERROR_PATTERN.exec(raw) : null;
    const message = match ? match[2].trim() : '';
    return message ? { field: match[1] || '', message } : null;
}

/**
 * Normalizes a decimal text with at most two decimals into its integer cents, written as a string of digits
 * without leading zeros (at least one digit): "0050.5" gives "5050" and "0.00" gives "0".
 *
 * Amounts are compared as strings on purpose. Currency(16, 2) holds 16 digits in cents, more than
 * Number.MAX_SAFE_INTEGER, so Number would lose cents; BigInt is not used because it has not been tested
 * under Lightning Web Security. The value sent to Apex stays the text the donor typed.
 * @param {string} text amount that already matches AMOUNT_PATTERN and has at most two decimals
 * @returns {string} integer cents as digits without leading zeros
 */
export function toCents(text) {
    const [whole, decimals = ''] = text.split('.');
    return `${whole}${decimals.padEnd(MAX_DECIMALS, '0')}`.replace(LEADING_ZEROS, '');
}

/**
 * Compares two amounts written by toCents: the longer one is the greater and, with the same length,
 * the string order is the numeric order.
 * @param {string} left integer cents as digits without leading zeros
 * @param {string} right integer cents as digits without leading zeros
 * @returns {number} negative when left is lower, 0 when equal, positive when left is greater
 */
export function compareCents(left, right) {
    if (left.length !== right.length) {
        return left.length - right.length;
    }
    if (left === right) {
        return 0;
    }
    return left < right ? -1 : 1;
}

/**
 * Writes an exact amount of the server for the donor, with thousands separators, without going through
 * Number: "1234.50" gives "$1,234.50" and "500.00" gives "$500". The text keeps every digit.
 * @param {string} text amount as text, for example "1234.50"
 * @returns {string} amount ready to show, without the currency name
 */
export function formatAmountText(text) {
    const [whole, decimals = ''] = String(text ?? '').split('.');
    const grouped = whole.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return /[1-9]/.test(decimals) ? `$${grouped}.${decimals}` : `$${grouped}`;
}

/**
 * Minimum amount of the configuration as cents.
 * @param {number|string|null|undefined} minimumAmount minimum received from the server
 * @returns {string|null} cents as written by toCents, or null when the value is missing or has no valid shape
 */
export function minimumToCents(minimumAmount) {
    const text = minimumAmount === null || minimumAmount === undefined ? '' : String(minimumAmount);
    return MINIMUM_AMOUNT_PATTERN.test(text) ? toCents(text) : null;
}

/**
 * Amount in cents written as a plain amount, without trailing zeros: "5000" gives "50" and "7550" "75.5".
 * @param {string} cents integer cents as written by toCents
 * @returns {string} plain amount
 */
export function centsToText(cents) {
    const digits = cents.padStart(MAX_DECIMALS + 1, '0');
    const whole = digits.slice(0, -MAX_DECIMALS).replace(LEADING_ZEROS, '');
    const decimals = digits.slice(-MAX_DECIMALS).replace(/0+$/, '');
    return decimals ? `${whole}.${decimals}` : whole;
}

function validateAmountShape(value) {
    if (!value) return 'empty';
    if (NEGATIVE_AMOUNT_PATTERN.test(value)) return 'positive';
    if (!AMOUNT_PATTERN.test(value)) return 'format';
    const [whole, decimals = ''] = value.split('.');
    if (decimals.length > MAX_DECIMALS) return 'decimals';
    return whole.replace(LEADING_ZEROS, '').length > MAX_INTEGER_DIGITS ? 'digits' : null;
}

/**
 * Checks the text of a custom amount. It mirrors DonationAmountValidator of the server, in the same order.
 * @param {string} text amount typed by the donor
 * @param {string|null} minimumCents current minimum as written by toCents, or null when it is unknown
 * @returns {string|null} key of FORM_MESSAGES.amount.errors, or null when the amount is valid
 */
export function validateAmountText(text, minimumCents) {
    const value = String(text ?? '').trim();
    const shapeError = validateAmountShape(value);
    if (shapeError) return shapeError;
    const cents = toCents(value);
    if (cents === ZERO_CENTS) return 'positive';
    if (!minimumCents) return 'configuration';
    return compareCents(cents, minimumCents) < 0 ? 'belowMinimum' : null;
}

/**
 * Message to show for a custom amount.
 * @param {string} text amount typed by the donor
 * @param {string|null} minimumCents current minimum as written by toCents, or null when it is unknown
 * @returns {string} Spanish message, or an empty string when the amount is valid
 */
export function validateCustomAmount(text, minimumCents) {
    const key = validateAmountText(text, minimumCents);
    if (!key) {
        return '';
    }
    const template = FORM_MESSAGES.amount.errors[key];
    return key === 'belowMinimum' ? template.replace('{0}', `$${centsToText(minimumCents)} MXN`) : template;
}

export function validateEmail(value) {
    const email = String(value ?? '').trim();
    if (!email) {
        return FORM_MESSAGES.email.required;
    }
    return email.length > MAX_EMAIL_LENGTH || !EMAIL_PATTERN.test(email) ? FORM_MESSAGES.email.invalid : '';
}

export function validatePublicName(value) {
    const name = normalizeText(value);
    if (!name) {
        return FORM_MESSAGES.visibility.publicNameRequired;
    }
    return name.length > MAX_PUBLIC_NAME_LENGTH ? FORM_MESSAGES.visibility.publicNameTooLong : '';
}

export function validateLegalName(value) {
    const name = normalizeText(value);
    if (!name) {
        return FORM_MESSAGES.invoice.legalNameRequired;
    }
    return name.length > MAX_LEGAL_NAME_LENGTH ? FORM_MESSAGES.invoice.legalNameTooLong : '';
}

export function validateRfc(value) {
    const rfc = sanitizeRfc(value);
    if (!rfc) {
        return FORM_MESSAGES.invoice.rfcRequired;
    }
    return RFC_PATTERN.test(rfc) ? '' : FORM_MESSAGES.invoice.rfcInvalid;
}

export function validatePostalCode(value) {
    const postalCode = String(value ?? '').trim();
    if (!postalCode) {
        return FORM_MESSAGES.invoice.postalCodeRequired;
    }
    return POSTAL_CODE_PATTERN.test(postalCode) ? '' : FORM_MESSAGES.invoice.postalCodeInvalid;
}

/**
 * DON-13. The notice must be accepted to ask for an invoice. The server checks it again.
 * @param {boolean} accepted state of the "Acepto el aviso de privacidad" checkbox
 * @returns {string} the message to show, or an empty string when it is accepted
 */
export function validatePrivacyNotice(accepted) {
    return accepted === true ? '' : FORM_MESSAGES.invoice.privacyNoticeRequired;
}

export function validateRegime(value, taxpayerType) {
    if (!value) {
        return FORM_MESSAGES.invoice.regimeRequired;
    }
    return getRegimeOptions(taxpayerType).some((option) => option.value === value)
        ? ''
        : FORM_MESSAGES.invoice.regimeRequired;
}
