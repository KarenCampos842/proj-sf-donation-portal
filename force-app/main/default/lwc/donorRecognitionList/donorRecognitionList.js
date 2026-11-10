import { LightningElement, api } from 'lwc';
import getDonorRecognition from '@salesforce/apex/DonorRecognitionService.getDonorRecognition';
import { MESSAGES } from 'c/portalMessages';
import { formatMxn } from 'c/portalUtils';
import { DEMO_DONORS } from 'c/portalDemoData';

const PAGE_SIZE = 10;

export default class DonorRecognitionList extends LightningElement {
    /** Fictitious data, clearly labeled. It never calls the server and is off by default. */
    @api demoMode = false;

    _campaignId;
    _connected = false;
    requestId = 0;
    isLoading = false;
    hasError = false;
    donors = [];
    visibleCount = PAGE_SIZE;

    @api
    get campaignId() {
        return this._campaignId;
    }
    set campaignId(value) {
        if (value === this._campaignId) {
            return;
        }
        this._campaignId = value;
        if (this._connected) {
            this.loadDonors();
        }
    }

    connectedCallback() {
        this._connected = true;
        this.loadDonors();
    }

    @api
    refresh() {
        this.loadDonors();
    }

    get messages() {
        return MESSAGES.recognition;
    }

    get visibleDonors() {
        return this.donors.slice(0, this.visibleCount).map((donor, index) => ({
            key: `${index}-${donor.publicName}`,
            publicName: donor.publicName,
            amountText: formatMxn(donor.amount)
        }));
    }

    get hasDonors() {
        return this.donors.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && this.donors.length === 0;
    }

    get showList() {
        return !this.isLoading && !this.hasError && this.hasDonors;
    }

    get hasMore() {
        return this.donors.length > this.visibleCount;
    }

    handleShowMore() {
        this.visibleCount += PAGE_SIZE;
    }

    handleRetry() {
        this.loadDonors();
    }

    async loadDonors() {
        const currentRequest = ++this.requestId;
        this.visibleCount = PAGE_SIZE;
        this.hasError = false;

        if (this.demoMode) {
            this.donors = DEMO_DONORS;
            this.isLoading = false;
            return;
        }
        if (!this._campaignId) {
            this.donors = [];
            this.isLoading = false;
            return;
        }

        this.isLoading = true;
        try {
            const result = await getDonorRecognition({ campaignId: this._campaignId });
            if (currentRequest === this.requestId) {
                this.donors = result || [];
            }
        } catch {
            if (currentRequest === this.requestId) {
                this.donors = [];
                this.hasError = true;
            }
        } finally {
            if (currentRequest === this.requestId) {
                this.isLoading = false;
            }
        }
    }
}
