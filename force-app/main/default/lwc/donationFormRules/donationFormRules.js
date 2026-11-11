import { FORM_MESSAGES } from 'c/donationFormMessages';

export const VISIBILITY_ANONYMOUS = 'Anonymous';
export const VISIBILITY_PUBLIC = 'Public';
export const TAXPAYER_PERSON = 'PERSON';
export const TAXPAYER_COMPANY = 'COMPANY';

export const MAX_EMAIL_LENGTH = 80;
export const MAX_PUBLIC_NAME_LENGTH = 80;
export const MAX_LEGAL_NAME_LENGTH = 254;

// Fixed amounts of Delivery 1 (DON-08). Free amounts and configurable amounts belong to E2.
export const SUGGESTED_AMOUNTS = [100, 250, 500, 1000, 2000, 5000, 10000, 20000];

// Same patterns as the server (DonationIntakeService) and the RFC_Format validation rule.
const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/;
export const RFC_PATTERN = /^[A-ZÑ&]{3,4}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[A-Z0-9]{2}[0-9A]$/;
const POSTAL_CODE_PATTERN = /^[0-9]{5}$/;
const CONTROL_CHARACTERS = /\p{Cc}/gu;

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

export function validateRegime(value, taxpayerType) {
    if (!value) {
        return FORM_MESSAGES.invoice.regimeRequired;
    }
    return getRegimeOptions(taxpayerType).some((option) => option.value === value)
        ? ''
        : FORM_MESSAGES.invoice.regimeRequired;
}
