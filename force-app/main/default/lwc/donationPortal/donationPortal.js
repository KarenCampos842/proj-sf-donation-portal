import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

const PARAM_CAMPAIGN = 'campana';
const PARAM_DONATE = 'donar';
const DONATE_VALUE = '1';
const PARAM_VIEW = 'vista';
const HISTORY_VALUE = 'historial';
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
 *   ?vista=historial             -> history of closed campaigns (DON-05)
 * A campaign in the URL always wins over the history parameter for what is shown. The parameter
 * still travels with the campaign (?campana=<Id>&vista=historial) when the visitor opened it from
 * the history, so the back button of the detail returns there; without it, back goes to the
 * catalog. Because the context is in the URL, Back, Forward and reloads keep it.
 * Every change goes through NavigationMixin, so the browser's Back and Forward buttons work
 * and CurrentPageReference delivers the new state without reloading the page.
 */
export default class DonationPortal extends NavigationMixin(LightningElement) {
    /** API name of the Experience Cloud page that hosts this component. */
    @api pageName = DEFAULT_PAGE_NAME;

    /**
     * Unused. It stays declared because the published Home page already stores a value for it and
     * Experience Builder does not allow removing a property of a component that is in use.
     */
    @api eventDate;

    isReady = false;
    campaignId = '';
    isDonating = false;
    isHistory = false;
    fromHistory = false;
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
        this.fromHistory = readParam(state[PARAM_VIEW]) === HISTORY_VALUE;
        this.isHistory = !this.campaignId && this.fromHistory;
        this.isReady = true;

        const nextView = this.viewName;
        if (this.currentView && this.currentView !== nextView) {
            this.scrollToTop();
        }
        this.currentView = nextView;
    }

    get viewName() {
        if (!this.campaignId) {
            return this.isHistory ? 'history' : 'list';
        }
        return this.isDonating ? 'form' : 'detail';
    }

    get showList() {
        return this.isReady && this.viewName === 'list';
    }

    get showHistory() {
        return this.isReady && this.viewName === 'history';
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
        const state = { [PARAM_CAMPAIGN]: event.detail.campaignId };
        if (this.isHistory) {
            state[PARAM_VIEW] = HISTORY_VALUE;
        }
        this.navigateTo(state);
    }

    handleShowHistory() {
        this.navigateTo({ [PARAM_VIEW]: HISTORY_VALUE });
    }

    // Back from a detail that was opened in the history goes to the history; any other back goes to the catalog.
    handleBackToList() {
        this.navigateTo(this.campaignId && this.fromHistory ? { [PARAM_VIEW]: HISTORY_VALUE } : {});
    }

    // "Ver campañas disponibles" of the not-found state: always the catalog, without campana or vista.
    handleViewCatalog() {
        this.navigateTo({});
    }

    handleDonationStart(event) {
        const { campaignId, campaignName } = event.detail;
        this.knownCampaign = { id: campaignId, name: campaignName };
        this.navigateTo({ ...this.contextState(campaignId), [PARAM_DONATE]: DONATE_VALUE });
    }

    handleBackToCampaign() {
        this.navigateTo(this.contextState(this.campaignId));
    }

    // State of a campaign view, keeping the history context when there is one.
    contextState(campaignId) {
        return this.fromHistory
            ? { [PARAM_CAMPAIGN]: campaignId, [PARAM_VIEW]: HISTORY_VALUE }
            : { [PARAM_CAMPAIGN]: campaignId };
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
