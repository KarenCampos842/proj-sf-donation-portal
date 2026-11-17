import { LightningElement, api } from 'lwc';
import { formatMessage } from 'c/portalMessages';
import { FORM_MESSAGES } from 'c/donationFormMessages';
import { formatAmountText } from 'c/donationFormRules';

const VISIBILITY_PUBLIC = 'Public';

/**
 * DON-18. The summary that the donor reviews before paying. It only shows what the server returned
 * (the values saved in the attempt) and tells the form what the donor decided: it never calls Apex and
 * never decides anything by itself. The form asks the server to confirm or to cancel the review.
 *
 * Events: `edit` (the donor wants to change the data) and `confirm` (the donor accepts the summary).
 */
export default class DonationSummary extends LightningElement {
    /** @type {{campaignName: string, amount: string, email: string, visibility: string, publicName: string, invoiceRequested: boolean}} */
    @api summary;
    /** True while the form waits for the server: both buttons stay disabled. */
    @api isBusy = false;
    /** Message of the last failed step, already safe to show. */
    @api errorMessage = '';
    /** True while the form opens the payment, to say so to assistive technology. */
    @api isOpeningPayment = false;
    /** True when the server refused this attempt: only «Editar donación» stays available. */
    @api confirmDisabled = false;

    /** Moves the focus to the title, so a screen reader announces the new step. */
    @api
    focusTitle() {
        this.template.querySelector('h1')?.focus();
    }

    get messages() {
        return FORM_MESSAGES.summary;
    }

    get amountLabel() {
        return `${formatAmountText(this.summary.amount)} ${FORM_MESSAGES.summary.currency}`;
    }

    get visibilityText() {
        return this.summary.visibility === VISIBILITY_PUBLIC
            ? formatMessage(FORM_MESSAGES.summary.public, this.summary.publicName)
            : FORM_MESSAGES.summary.anonymous;
    }

    get invoiceText() {
        return this.summary.invoiceRequested ? FORM_MESSAGES.summary.invoiceYes : FORM_MESSAGES.summary.invoiceNo;
    }

    get isConfirmDisabled() {
        return this.isBusy || this.confirmDisabled;
    }

    get confirmLabel() {
        return this.isOpeningPayment ? FORM_MESSAGES.summary.confirming : FORM_MESSAGES.summary.confirm;
    }

    get statusText() {
        if (this.isOpeningPayment) {
            return FORM_MESSAGES.summary.confirming;
        }
        return this.isBusy ? FORM_MESSAGES.summary.editing : '';
    }

    handleEdit() {
        this.dispatchEvent(new CustomEvent('edit'));
    }

    handleConfirm() {
        this.dispatchEvent(new CustomEvent('confirm'));
    }
}
