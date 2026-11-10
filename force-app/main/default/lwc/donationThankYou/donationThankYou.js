import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getPaymentResult from '@salesforce/apex/DonationPaymentController.getPaymentResult';
import { THANK_YOU_MESSAGES } from 'c/donationThankYouMessages';

const RESULT_UNKNOWN = 'Unknown';
const RETRY_STATES = ['Rejected', 'Cancelled', 'NoPayment'];
const CHECK_AGAIN_STATES = ['Pending', RESULT_UNKNOWN];

/**
 * Page the donor returns to from Mercado Pago. It uses only the payment_id of the URL: any other
 * parameter (status, external_reference...) can be edited by anyone and is never used to decide
 * what to show. The real state is asked to the server, which verifies it with Mercado Pago.
 */
export default class DonationThankYou extends NavigationMixin(LightningElement) {
    /** API name of the portal page the donor goes back to. */
    @api homePageName = 'Home';

    isLoading = true;
    resultState;
    paymentId = '';
    requested = false;

    @wire(CurrentPageReference)
    handlePageReference(pageReference) {
        if (!pageReference || this.requested) {
            return;
        }
        this.requested = true;
        this.paymentId = this.readPaymentId(pageReference.state);
        this.checkPayment();
    }

    get messages() {
        return THANK_YOU_MESSAGES;
    }

    get stateText() {
        return THANK_YOU_MESSAGES.states[this.resultState] || THANK_YOU_MESSAGES.states[RESULT_UNKNOWN];
    }

    get canTryAgain() {
        return RETRY_STATES.includes(this.resultState);
    }

    get canCheckAgain() {
        return CHECK_AGAIN_STATES.includes(this.resultState);
    }

    handleBackToPortal() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: this.homePageName || 'Home' }
        });
    }

    handleCheckAgain() {
        this.checkPayment();
    }

    readPaymentId(state) {
        const fromState = state?.payment_id;
        const fromUrl = new URLSearchParams(window.location.search).get('payment_id');
        const value = Array.isArray(fromState) ? fromState[0] : fromState || fromUrl;
        // Mercado Pago sends the text "null" when nothing was paid. The payment flow of Workstream A
        // handles that value, but fails with an empty one.
        return String(value ?? '').trim() || 'null';
    }

    async checkPayment() {
        this.isLoading = true;
        try {
            const state = await getPaymentResult({ paymentId: this.paymentId });
            this.resultState = THANK_YOU_MESSAGES.states[state] ? state : RESULT_UNKNOWN;
        } catch {
            this.resultState = RESULT_UNKNOWN;
        } finally {
            this.isLoading = false;
        }
    }
}
