import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

const PARAM_CAMPAIGN = 'campana';
const PARAM_DONATE = 'donar';
const DONATE_VALUE = '1';
const DEFAULT_PAGE_NAME = 'Home';

/**
 * Reads a query string value that the router may deliver as text or as a list.
 * @param {string|string[]|undefined} value raw state value
 * @returns {string} trimmed text, or an empty string
 */
function readParam(value) {
    const text = Array.isArray(value) ? value[0] : value;
    return String(text ?? '').trim();
}

/**
 * Main container of the public portal. The URL is the only source of truth for the view:
 *   (no parameters)              -> campaign catalog
 *   ?campana=<Id>                -> campaign detail (also used for direct links)
 *   ?campana=<Id>&donar=1        -> donation form of that campaign
 * Every change goes through NavigationMixin, so the browser's Back and Forward buttons work
 * and CurrentPageReference delivers the new state without reloading the page.
 */
export default class DonationPortal extends NavigationMixin(LightningElement) {
    /** API name of the Experience Cloud page that hosts this component. */
    @api pageName = DEFAULT_PAGE_NAME;

    isReady = false;
    campaignId = '';
    isDonating = false;
    knownCampaign = { id: '', name: '' };
    currentView;

    @wire(CurrentPageReference)
    handlePageReference(pageReference) {
        if (!pageReference) {
            return;
        }
        const state = pageReference.state || {};
        this.campaignId = readParam(state[PARAM_CAMPAIGN]);
        this.isDonating = Boolean(this.campaignId) && readParam(state[PARAM_DONATE]) === DONATE_VALUE;
        this.isReady = true;

        const nextView = this.viewName;
        if (this.currentView && this.currentView !== nextView) {
            this.scrollToTop();
        }
        this.currentView = nextView;
    }

    get viewName() {
        if (!this.campaignId) {
            return 'list';
        }
        return this.isDonating ? 'form' : 'detail';
    }

    get showList() {
        return this.isReady && this.viewName === 'list';
    }

    get showDetail() {
        return this.isReady && this.viewName === 'detail';
    }

    get showForm() {
        return this.isReady && this.viewName === 'form';
    }

    // The name is only known when the donor came from the detail; a direct link to the form has none.
    get formCampaignName() {
        return this.knownCampaign.id === this.campaignId ? this.knownCampaign.name : '';
    }

    handleCampaignSelect(event) {
        this.navigateTo({ [PARAM_CAMPAIGN]: event.detail.campaignId });
    }

    handleBackToList() {
        this.navigateTo({});
    }

    handleDonationStart(event) {
        const { campaignId, campaignName } = event.detail;
        this.knownCampaign = { id: campaignId, name: campaignName };
        this.navigateTo({ [PARAM_CAMPAIGN]: campaignId, [PARAM_DONATE]: DONATE_VALUE });
    }

    handleBackToCampaign() {
        this.navigateTo({ [PARAM_CAMPAIGN]: this.campaignId });
    }

    navigateTo(state) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: this.pageName || DEFAULT_PAGE_NAME },
            state
        });
    }

    scrollToTop() {
        if (typeof window.scrollTo === 'function') {
            window.scrollTo(0, 0);
        }
    }
}
