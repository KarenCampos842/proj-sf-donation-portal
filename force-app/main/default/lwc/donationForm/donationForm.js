import { LightningElement, api, track, wire } from 'lwc';
import startDonation from '@salesforce/apex/DonationIntakeService.startDonation';
import openPayment from '@salesforce/apex/DonationIntakeService.openPayment';
import getAmountSettings from '@salesforce/apex/DonationIntakeService.getAmountSettings';
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
    parseServerError,
    sanitizeRfc,
    validateEmail,
    validateLegalName,
    validatePostalCode,
    validatePrivacyNotice,
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

    // DON-17. True only while errorMessage is the "check the marked fields" notice, so it can go away
    // when the fields are fixed. A general error of the server never sets it.
    validationNoticeActive = false;
    // Fields already validated once. Only these show their error while the donor is still typing.
    validatedFields = new Set();
    // Fields marked by an error of the server that the donor has not edited since.
    serverMarkedFields = new Set();
    // One-item list used as the key of the regime combobox. A new id creates the combobox again.
    regimeFieldKeys = [{ id: 0 }];

    @track form = {
        email: '',
        publicName: '',
        legalName: '',
        rfc: '',
        taxPostalCode: '',
        taxRegime: '',
        privacyNoticeAccepted: false
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

    // ADM-13. Amounts set by the administrator. Until they arrive, or if the server fails, the
    // amounts of Delivery 1 are shown; the server validates the amount again in any case.
    suggestedAmounts = SUGGESTED_AMOUNTS;

    @wire(getAmountSettings)
    wiredAmountSettings({ data }) {
        const amounts = data?.suggestedAmounts?.map(Number).filter((amount) => amount > 0);
        if (amounts?.length) {
            this.suggestedAmounts = amounts;
            if (this.selectedAmount && !amounts.includes(this.selectedAmount)) {
                this.selectedAmount = undefined;
            }
        }
    }

    get amountOptions() {
        return this.suggestedAmounts.map((amount) => ({
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
        this.clearValidationNoticeIfFormIsValid();
    }

    handleAnonymousToggle(event) {
        this.isAnonymous = event.target.checked;
        this.forgetFields(['publicName']);
    }

    handleInvoiceToggle(event) {
        this.invoiceRequested = event.target.checked;
        this.forgetFields(['legalName', 'rfc', 'taxPostalCode', 'taxRegime', 'privacyNoticeAccepted']);
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        if (field === 'rfc') {
            this.handleRfcChange(event);
        } else if (field === 'privacyNoticeAccepted') {
            this.form.privacyNoticeAccepted = event.target.checked === true;
        } else {
            this.form[field] = event.target.value;
        }
        this.refreshFieldAfterEdit(field, event.target);
    }

    handleRfcChange(event) {
        const rfc = sanitizeRfc(event.target.value);
        this.form.rfc = rfc;
        event.target.value = rfc;
        const regimeIsStillAllowed = getRegimeOptions(getTaxpayerType(rfc)).some(
            (option) => option.value === this.form.taxRegime
        );
        if (this.form.taxRegime && !regimeIsStillAllowed) {
            this.dropIncompatibleRegime();
        }
    }

    // The chosen regime no longer fits the taxpayer type of the RFC. It is cleared without showing a
    // new error while the donor is still typing the RFC; the field is validated again when the donor
    // leaves it or tries to continue. The combobox is created again so that it loses any error it
    // was showing, because setCustomValidity alone does not repaint it.
    dropIncompatibleRegime() {
        this.form.taxRegime = '';
        this.validatedFields.delete('taxRegime');
        this.serverMarkedFields.delete('taxRegime');
        this.regimeFieldKeys = [{ id: this.regimeFieldKeys[0].id + 1 }];
    }

    handleRegimeChange(event) {
        this.form.taxRegime = event.detail.value;
        this.refreshFieldAfterEdit('taxRegime', event.target);
    }

    handleFieldBlur(event) {
        this.reportField(event.target.dataset.field, event.target);
    }

    async handleSubmit() {
        if (this.isSubmitting) {
            return;
        }
        this.errorMessage = '';
        this.validationNoticeActive = false;
        this.serverMarkedFields.clear();
        if (!this.validateAll()) {
            this.errorMessage = FORM_MESSAGES.submit.fixFields;
            this.validationNoticeActive = true;
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
            this.isSubmitting = false;
            this.showServerError(error);
        }
    }

    activeFields() {
        const fields = ['email'];
        if (!this.isAnonymous) {
            fields.push('publicName');
        }
        if (this.invoiceRequested) {
            fields.push('legalName', 'rfc', 'taxPostalCode', 'taxRegime', 'privacyNoticeAccepted');
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
            case 'privacyNoticeAccepted':
                return validatePrivacyNotice(this.form.privacyNoticeAccepted);
            default:
                return '';
        }
    }

    reportField(field, element) {
        this.validatedFields.add(field);
        const message = this.fieldMessage(field);
        element.setCustomValidity(message);
        element.reportValidity();
        return message === '';
    }

    // DON-17. Runs after the donor edits a field, with the same local rules and without any Apex call.
    // A field that was already validated updates its error at once, so it does not wait for the blur.
    // A field that was never validated shows nothing yet.
    refreshFieldAfterEdit(field, element) {
        this.serverMarkedFields.delete(field);
        if (this.validatedFields.has(field)) {
            this.reportField(field, element);
        } else {
            element.setCustomValidity(field === 'rfc' ? validateRfc(this.form.rfc) : '');
        }
        this.clearValidationNoticeIfFormIsValid();
    }

    // Fields that leave the screen start again as never validated.
    forgetFields(fields) {
        fields.forEach((field) => {
            this.validatedFields.delete(field);
            this.serverMarkedFields.delete(field);
        });
        this.clearValidationNoticeIfFormIsValid();
    }

    isFormValid() {
        return (
            Boolean(this.selectedAmount) &&
            !this.amountError &&
            this.serverMarkedFields.size === 0 &&
            this.activeFields().every((field) => this.fieldMessage(field) === '')
        );
    }

    // Only the "check the marked fields" notice goes away by itself. An error of the server that
    // belongs to no field stays until the donor tries again.
    clearValidationNoticeIfFormIsValid() {
        if (this.validationNoticeActive && this.isFormValid()) {
            this.errorMessage = '';
            this.validationNoticeActive = false;
        }
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
            taxRegime: withInvoice ? this.form.taxRegime : null,
            // Only the acceptance travels; the server sets its date and time.
            privacyNoticeAccepted: withInvoice ? this.form.privacyNoticeAccepted === true : false
        };
    }

    // DON-17. Only messages from DonationIntakeService (Spanish and safe to show) are displayed; an
    // error that belongs to a field is marked on that field, the others go to the general notice.
    // Whatever else fails gets a friendly text, never the technical message.
    showServerError(error) {
        const serverError = parseServerError(error);
        if (!serverError) {
            this.errorMessage = FORM_MESSAGES.submit.genericError;
            return;
        }
        const marked = this.markServerField(serverError);
        this.errorMessage = marked ? FORM_MESSAGES.submit.fixFields : serverError.message;
        this.validationNoticeActive = marked;
    }

    // Returns false when the field is not on the screen, so its message is not lost.
    markServerField({ field, message }) {
        if (field === 'amount') {
            this.amountError = message;
            this.template.querySelector('input[name="amount"]')?.focus();
            return true;
        }
        const element = field ? this.template.querySelector(`[data-field="${field}"]`) : null;
        if (!element) {
            return false;
        }
        this.validatedFields.add(field);
        this.serverMarkedFields.add(field);
        element.setCustomValidity(message);
        element.reportValidity();
        element.focus();
        return true;
    }
}
