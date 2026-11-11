import { LightningElement, api, track } from 'lwc';
import startDonation from '@salesforce/apex/DonationIntakeService.startDonation';
import openPayment from '@salesforce/apex/DonationIntakeService.openPayment';
import { formatMessage } from 'c/portalMessages';
import { formatMxn } from 'c/portalUtils';
import { FORM_MESSAGES } from 'c/donationFormMessages';
import {
    MAX_LEGAL_NAME_LENGTH,
    MAX_PUBLIC_NAME_LENGTH,
    SUGGESTED_AMOUNTS,
    TAXPAYER_PERSON,
    VISIBILITY_ANONYMOUS,
    VISIBILITY_PUBLIC,
    getRegimeOptions,
    getTaxpayerType,
    normalizeText,
    sanitizeRfc,
    validateEmail,
    validateLegalName,
    validatePostalCode,
    validatePublicName,
    validateRegime,
    validateRfc
} from 'c/donationFormRules';

const HTTPS_URL = /^https:\/\//i;

export default class DonationForm extends LightningElement {
    @api campaignId;
    @api campaignName;

    selectedAmount;
    isAnonymous = true;
    invoiceRequested = false;
    amountError = '';
    errorMessage = '';
    isSubmitting = false;

    @track form = {
        email: '',
        publicName: '',
        legalName: '',
        rfc: '',
        taxPostalCode: '',
        taxRegime: ''
    };

    pageShowHandler = (event) => {
        // Coming back from the payment page with the browser's back button must not leave the form locked.
        if (event.persisted) {
            this.isSubmitting = false;
        }
    };

    connectedCallback() {
        window.addEventListener('pageshow', this.pageShowHandler);
    }

    disconnectedCallback() {
        window.removeEventListener('pageshow', this.pageShowHandler);
    }

    get messages() {
        return FORM_MESSAGES;
    }

    get maxPublicNameLength() {
        return MAX_PUBLIC_NAME_LENGTH;
    }

    get maxLegalNameLength() {
        return MAX_LEGAL_NAME_LENGTH;
    }

    get hasCampaign() {
        return Boolean(this.campaignId);
    }

    get campaignLabel() {
        return this.campaignName ? formatMessage(FORM_MESSAGES.campaign, this.campaignName) : '';
    }

    get amountOptions() {
        return SUGGESTED_AMOUNTS.map((amount) => ({
            value: String(amount),
            label: formatMxn(amount),
            checked: amount === this.selectedAmount
        }));
    }

    get showPublicName() {
        return !this.isAnonymous;
    }

    get visibilityHelp() {
        return this.isAnonymous ? FORM_MESSAGES.visibility.anonymousHelp : '';
    }

    get taxpayerType() {
        return getTaxpayerType(sanitizeRfc(this.form.rfc));
    }

    get taxpayerTypeText() {
        if (!this.taxpayerType) {
            return '';
        }
        const type =
            this.taxpayerType === TAXPAYER_PERSON ? FORM_MESSAGES.invoice.person : FORM_MESSAGES.invoice.company;
        return formatMessage(FORM_MESSAGES.invoice.taxpayerType, type);
    }

    get regimeOptions() {
        return getRegimeOptions(this.taxpayerType);
    }

    get submitLabel() {
        return this.isSubmitting ? FORM_MESSAGES.submit.busy : FORM_MESSAGES.submit.label;
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('backtocampaign'));
    }

    handleAmountChange(event) {
        this.selectedAmount = Number(event.target.value);
        this.amountError = '';
    }

    handleAnonymousToggle(event) {
        this.isAnonymous = event.target.checked;
    }

    handleInvoiceToggle(event) {
        this.invoiceRequested = event.target.checked;
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        if (field === 'rfc') {
            this.handleRfcChange(event);
            return;
        }
        this.form[field] = event.target.value;
        event.target.setCustomValidity('');
    }

    handleRfcChange(event) {
        const rfc = sanitizeRfc(event.target.value);
        this.form.rfc = rfc;
        event.target.value = rfc;
        event.target.setCustomValidity(validateRfc(rfc));
        const regimeIsStillAllowed = getRegimeOptions(getTaxpayerType(rfc)).some(
            (option) => option.value === this.form.taxRegime
        );
        if (!regimeIsStillAllowed) {
            this.form.taxRegime = '';
        }
    }

    handleRegimeChange(event) {
        this.form.taxRegime = event.detail.value;
        event.target.setCustomValidity('');
    }

    handleFieldBlur(event) {
        this.reportField(event.target.dataset.field, event.target);
    }

    async handleSubmit() {
        if (this.isSubmitting) {
            return;
        }
        this.errorMessage = '';
        if (!this.validateAll()) {
            this.errorMessage = FORM_MESSAGES.submit.fixFields;
            return;
        }

        this.isSubmitting = true;
        try {
            // Two separate Apex calls: the payment callout cannot follow a save in the same transaction.
            const attemptId = await startDonation({ request: this.buildRequest() });
            const checkoutUrl = await openPayment({ attemptId });
            if (!HTTPS_URL.test(checkoutUrl || '')) {
                throw new Error('Invalid checkout URL');
            }
            window.location.assign(checkoutUrl);
        } catch (error) {
            this.errorMessage = this.readErrorMessage(error);
            this.isSubmitting = false;
        }
    }

    activeFields() {
        const fields = ['email'];
        if (!this.isAnonymous) {
            fields.push('publicName');
        }
        if (this.invoiceRequested) {
            fields.push('legalName', 'rfc', 'taxPostalCode', 'taxRegime');
        }
        return fields;
    }

    fieldMessage(field) {
        switch (field) {
            case 'email':
                return validateEmail(this.form.email);
            case 'publicName':
                return validatePublicName(this.form.publicName);
            case 'legalName':
                return validateLegalName(this.form.legalName);
            case 'rfc':
                return validateRfc(this.form.rfc);
            case 'taxPostalCode':
                return validatePostalCode(this.form.taxPostalCode);
            case 'taxRegime':
                return validateRegime(this.form.taxRegime, this.taxpayerType);
            default:
                return '';
        }
    }

    reportField(field, element) {
        const message = this.fieldMessage(field);
        element.setCustomValidity(message);
        element.reportValidity();
        return message === '';
    }

    validateAll() {
        let firstInvalid;
        if (!this.selectedAmount) {
            this.amountError = FORM_MESSAGES.amount.required;
            firstInvalid = this.template.querySelector('input[name="amount"]');
        }
        this.activeFields().forEach((field) => {
            const element = this.template.querySelector(`[data-field="${field}"]`);
            if (!element) {
                return;
            }
            if (!this.reportField(field, element) && !firstInvalid) {
                firstInvalid = element;
            }
        });
        if (firstInvalid && typeof firstInvalid.focus === 'function') {
            firstInvalid.focus();
        }
        return !firstInvalid;
    }

    buildRequest() {
        const withInvoice = this.invoiceRequested;
        return {
            campaignId: this.campaignId,
            amount: this.selectedAmount,
            email: this.form.email.trim(),
            visibility: this.isAnonymous ? VISIBILITY_ANONYMOUS : VISIBILITY_PUBLIC,
            publicName: this.isAnonymous ? null : normalizeText(this.form.publicName),
            invoiceRequested: this.invoiceRequested,
            legalName: withInvoice ? normalizeText(this.form.legalName) : null,
            rfc: withInvoice ? sanitizeRfc(this.form.rfc) : null,
            taxPostalCode: withInvoice ? this.form.taxPostalCode.trim() : null,
            taxRegime: withInvoice ? this.form.taxRegime : null
        };
    }

    // The server messages are already in Spanish and safe to show; anything else gets a friendly text.
    readErrorMessage(error) {
        const message = error?.body?.message;
        return typeof message === 'string' && message.trim() ? message : FORM_MESSAGES.submit.genericError;
    }
}
