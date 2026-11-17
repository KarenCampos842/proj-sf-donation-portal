import { LightningElement, api, track, wire } from 'lwc';
import startDonation from '@salesforce/apex/DonationIntakeService.startDonation';
import openPayment from '@salesforce/apex/DonationIntakeService.openPayment';
import getDonationSummary from '@salesforce/apex/DonationIntakeService.getDonationSummary';
import confirmDonation from '@salesforce/apex/DonationIntakeService.confirmDonation';
import invalidateDonation from '@salesforce/apex/DonationIntakeService.invalidateDonation';
import getAmountSettings from '@salesforce/apex/DonationIntakeService.getAmountSettings';
import { formatMessage } from 'c/portalMessages';
import { formatMxn } from 'c/portalUtils';
import { FORM_MESSAGES } from 'c/donationFormMessages';
import {
    MAX_LEGAL_NAME_LENGTH,
    MAX_PUBLIC_NAME_LENGTH,
    OTHER_AMOUNT,
    SUGGESTED_AMOUNTS,
    TAXPAYER_PERSON,
    VISIBILITY_ANONYMOUS,
    VISIBILITY_PUBLIC,
    getRegimeOptions,
    getTaxpayerType,
    minimumToCents,
    normalizeText,
    parseServerError,
    sanitizeRfc,
    validateCustomAmount,
    validateEmail,
    validateLegalName,
    validatePostalCode,
    validatePrivacyNotice,
    validatePublicName,
    validateRegime,
    validateRfc
} from 'c/donationFormRules';

const HTTPS_URL = /^https:\/\//i;
// DON-09. Only one amount is active at a time: a suggested one or the one the donor types.
const MODE_SUGGESTED = 'suggested';
const MODE_CUSTOM = 'custom';
// DON-18. The donation has two steps on screen: the form and the review of the summary.
const STEP_FORM = 'form';
const STEP_REVIEW = 'review';

export default class DonationForm extends LightningElement {
    @api campaignId;
    @api campaignName;

    // Text of the suggested amount chosen (for example '500'), or undefined. Amounts travel as text.
    selectedAmount;
    amountMode = '';
    // Minimum of the configuration in cents, as the digit string of toCents, or null until it arrives.
    minimumCents = null;
    focusCustomAmount = false;
    isAnonymous = true;

    // DON-18. The token that startDonation returns authorizes the review, the confirmation and the payment
    // of this attempt only. It stays in memory: not in the DOM, not in the URL, not stored. Reloading the
    // page loses it and starts again from the form.
    accessToken = '';
    step = STEP_FORM;
    summary;
    reviewError = '';
    // True after the server refused to open the payment: that attempt cannot be confirmed again, so the
    // only way forward is «Editar donación».
    confirmBlocked = false;
    isOpeningPayment = false;
    // Step whose title receives the focus after the next render.
    focusStep = '';
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
        customAmount: '',
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
            this.isOpeningPayment = false;
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

    get isReviewing() {
        return this.step === STEP_REVIEW;
    }

    get showBack() {
        return !this.isReviewing;
    }

    get campaignLabel() {
        return this.campaignName ? formatMessage(FORM_MESSAGES.campaign, this.campaignName) : '';
    }

    // ADM-13. Amounts set by the administrator. Until they arrive, or if the server fails, the
    // amounts of Delivery 1 are shown; the server validates the amount again in any case.
    suggestedAmounts = SUGGESTED_AMOUNTS;

    @wire(getAmountSettings)
    wiredAmountSettings({ data }) {
        if (!data) {
            return;
        }
        this.minimumCents = minimumToCents(data.minimumAmount);
        const amounts = data.suggestedAmounts?.map(Number).filter((amount) => amount > 0);
        if (amounts?.length) {
            this.suggestedAmounts = amounts;
            if (this.selectedAmount && !amounts.map(String).includes(this.selectedAmount)) {
                this.selectedAmount = undefined;
                this.amountMode = '';
            }
        }
    }

    get amountOptions() {
        return this.suggestedAmounts.map((amount) => ({
            value: String(amount),
            label: formatMxn(amount),
            checked: this.amountMode === MODE_SUGGESTED && String(amount) === this.selectedAmount
        }));
    }

    get isCustomAmount() {
        return this.amountMode === MODE_CUSTOM;
    }

    get otherAmountValue() {
        return OTHER_AMOUNT;
    }

    // The amount that is sent: the suggested one or the text typed, as text. Never converted to Number.
    get amountText() {
        if (this.amountMode === MODE_SUGGESTED) {
            return this.selectedAmount;
        }
        return this.isCustomAmount ? this.form.customAmount.trim() : '';
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

    // The suggested amounts and "Otro monto" share one radio group, so choosing one leaves the other
    // without a value: the last choice is the only one that counts (DON-09, AC3).
    handleAmountChange(event) {
        const value = event.target.value;
        this.amountError = '';
        if (value === OTHER_AMOUNT) {
            this.amountMode = MODE_CUSTOM;
            this.selectedAmount = undefined;
            this.focusCustomAmount = true;
        } else {
            this.amountMode = MODE_SUGGESTED;
            this.selectedAmount = value;
            this.form.customAmount = '';
            this.forgetFields(['customAmount']);
        }
        this.clearValidationNoticeIfFormIsValid();
    }

    renderedCallback() {
        if (this.focusCustomAmount) {
            this.focusCustomAmount = false;
            this.template.querySelector('[data-field="customAmount"]')?.focus();
        }
        if (this.focusStep) {
            const step = this.focusStep;
            this.focusStep = '';
            if (step === STEP_REVIEW) {
                this.template.querySelector('c-donation-summary')?.focusTitle();
            } else {
                this.template.querySelector('.form__title')?.focus();
            }
        }
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
            // The server saves the attempt, gives the token and then returns the summary of what it saved.
            const started = await startDonation({ request: this.buildRequest() });
            this.accessToken = started.accessToken;
            this.summary = await getDonationSummary({ accessToken: this.accessToken });
            this.reviewError = '';
            this.confirmBlocked = false;
            this.step = STEP_REVIEW;
            this.focusStep = STEP_REVIEW;
        } catch (error) {
            this.accessToken = '';
            this.showServerError(error);
        } finally {
            this.isSubmitting = false;
        }
    }

    // DON-18. «Editar donación»: the server retires the attempt and its token, and the form comes back with
    // everything the donor typed. Continuing creates a new attempt and a new summary to confirm.
    async handleEdit() {
        if (this.isSubmitting) {
            return;
        }
        this.isSubmitting = true;
        this.reviewError = '';
        try {
            await invalidateDonation({ accessToken: this.accessToken });
            this.accessToken = '';
            this.summary = undefined;
            this.confirmBlocked = false;
            this.errorMessage = '';
            this.validationNoticeActive = false;
            this.step = STEP_FORM;
            this.focusStep = STEP_FORM;
        } catch {
            this.reviewError = FORM_MESSAGES.summary.editError;
        } finally {
            this.isSubmitting = false;
        }
    }

    // DON-18. «Confirmar y continuar al pago». Two separate Apex calls: the server records the confirmation
    // and then opens the payment, because the callout to Mercado Pago cannot follow a save in the same
    // transaction. The page leaves for the checkout and the buttons stay disabled until it does.
    async handleConfirm() {
        if (this.isSubmitting || this.confirmBlocked) {
            return;
        }
        this.isSubmitting = true;
        this.isOpeningPayment = true;
        this.reviewError = '';
        try {
            await confirmDonation({ accessToken: this.accessToken });
            const checkoutUrl = await openPayment({ accessToken: this.accessToken });
            if (!HTTPS_URL.test(checkoutUrl || '')) {
                throw new Error('Invalid checkout URL');
            }
            window.location.assign(checkoutUrl);
        } catch (error) {
            this.isSubmitting = false;
            this.isOpeningPayment = false;
            const serverError = parseServerError(error);
            this.confirmBlocked = Boolean(serverError);
            this.reviewError = serverError?.message ?? FORM_MESSAGES.submit.genericError;
        }
    }

    activeFields() {
        const fields = this.isCustomAmount ? ['customAmount', 'email'] : ['email'];
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
            case 'customAmount':
                return validateCustomAmount(this.form.customAmount, this.minimumCents);
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
            Boolean(this.amountMode) &&
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
        if (!this.amountMode) {
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
            amount: this.amountText,
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
        if (field === 'amount' && this.isCustomAmount) {
            return this.markServerField({ field: 'customAmount', message });
        }
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
