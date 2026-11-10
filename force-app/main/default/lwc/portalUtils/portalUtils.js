import { MESSAGES } from 'c/portalMessages';

const LOCALE = 'es-MX';
const CURRENCY_SUFFIX = 'MXN';

/**
 * Formats an amount as Mexican pesos, for example "$1,000 MXN".
 * @param {number|string} value amount in MXN
 * @returns {string} formatted amount
 */
export function formatMxn(value) {
    const amount = Number(value) || 0;
    const formatter = new Intl.NumberFormat(LOCALE, {
        style: 'currency',
        currency: 'MXN',
        minimumFractionDigits: Number.isInteger(amount) ? 0 : 2,
        maximumFractionDigits: 2
    });
    return `${formatter.format(amount)} ${CURRENCY_SUFFIX}`;
}

/**
 * Formats the real progress percentage. 120 gives "120 %"; it is never capped.
 * @param {number|string} percent percentage where 50 means 50 %
 * @returns {string} formatted percentage
 */
export function formatPercent(percent) {
    const formatter = new Intl.NumberFormat(LOCALE, { style: 'percent', maximumFractionDigits: 2 });
    return formatter.format((Number(percent) || 0) / 100);
}

/**
 * Formats a date-only value (YYYY-MM-DD) without shifting it by the time zone.
 * @param {string} isoDate date as returned by Apex
 * @returns {string} for example "12 de diciembre de 2026", or an empty string
 */
export function formatDate(isoDate) {
    if (!isoDate) {
        return '';
    }
    const [year, month, day] = String(isoDate).split('-').map(Number);
    if (!year || !month || !day) {
        return '';
    }
    return new Intl.DateTimeFormat(LOCALE, {
        day: 'numeric',
        month: 'long',
        year: 'numeric',
        timeZone: 'UTC'
    }).format(new Date(Date.UTC(year, month - 1, day)));
}

/**
 * Label and CSS classes for the availability badge. The label always carries the meaning, so
 * the state never depends on color alone.
 * @param {string} availability OPEN, PAUSED, CLOSED or ENDED
 * @returns {{label: string, badgeClass: string}} badge data
 */
export function getAvailabilityInfo(availability) {
    switch (availability) {
        case 'PAUSED':
            return { label: MESSAGES.availability.PAUSED, badgeClass: 'slds-badge badge badge_paused' };
        case 'CLOSED':
            return { label: MESSAGES.availability.CLOSED, badgeClass: 'slds-badge badge badge_closed' };
        case 'ENDED':
            return { label: MESSAGES.availability.ENDED, badgeClass: 'slds-badge slds-badge_lightest badge badge_ended' };
        default:
            return { label: MESSAGES.availability.OPEN, badgeClass: 'slds-badge badge badge_open' };
    }
}

/**
 * True when the visitor asked the system to reduce motion. Without matchMedia it is treated as
 * true so nothing animates in environments that cannot tell.
 * @returns {boolean} whether animations should be skipped
 */
export function prefersReducedMotion() {
    return typeof window.matchMedia !== 'function' || window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}
