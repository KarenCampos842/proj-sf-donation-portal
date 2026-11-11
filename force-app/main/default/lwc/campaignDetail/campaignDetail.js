import { LightningElement, api } from 'lwc';
import getCampaignDetail from '@salesforce/apex/CampaignPortalController.getCampaignDetail';
import { MESSAGES, formatMessage } from 'c/portalMessages';
import { formatDate, getAvailabilityInfo } from 'c/portalUtils';

export default class CampaignDetail extends LightningElement {
    /** Fictitious recognition data for design reviews. Off by default and never real data. */
    @api demoMode = false;

    _campaignId;
    _connected = false;
    requestId = 0;
    isLoading = true;
    hasError = false;
    campaign;
    imageFailed = false;

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
            this.loadCampaign();
        }
    }

    connectedCallback() {
        this._connected = true;
        this.loadCampaign();
    }

    @api
    refresh() {
        this.loadCampaign();
    }

    get messages() {
        return MESSAGES.detail;
    }

    get isNotFound() {
        return !this.isLoading && !this.hasError && !this.campaign;
    }

    get hasCampaign() {
        return !this.isLoading && !this.hasError && Boolean(this.campaign);
    }

    get badge() {
        return getAvailabilityInfo(this.campaign.availability);
    }

    get badgeLabel() {
        return this.badge.label;
    }

    get badgeClass() {
        return this.badge.badgeClass;
    }

    get showImage() {
        return Boolean(this.campaign.imageUrl) && !this.imageFailed;
    }

    get imageAlt() {
        return this.campaign.imageAltText || formatMessage(this.messages.imageAlt, this.campaign.name);
    }

    get placeholderLabel() {
        return formatMessage(this.messages.noImageAlt, this.campaign.name);
    }

    get startText() {
        return formatMessage(this.messages.startsOn, formatDate(this.campaign.startDate));
    }

    get hasEndDate() {
        return Boolean(this.campaign.endDate);
    }

    get endText() {
        return formatMessage(this.messages.endsOn, formatDate(this.campaign.endDate));
    }

    get canDonate() {
        return this.campaign.canDonate === true;
    }

    get cannotDonate() {
        return !this.canDonate;
    }

    /** Text that explains why donating is not possible. It never depends on color. */
    get notice() {
        switch (this.campaign.availability) {
            case 'PAUSED':
                return this.messages.pausedNotice;
            case 'CLOSED':
                return this.messages.closedNotice;
            case 'ENDED':
                return this.messages.endedNotice;
            default:
                return this.messages.notAcceptingNotice;
        }
    }

    get disabledButtonLabel() {
        return this.campaign.availability === 'PAUSED' ? this.messages.donationsPaused : this.messages.donationsClosed;
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('backtolist'));
    }

    handleDonate() {
        if (!this.canDonate) {
            return;
        }
        this.dispatchEvent(
            new CustomEvent('donationstart', {
                detail: { campaignId: this.campaign.id, campaignName: this.campaign.name }
            })
        );
    }

    handleRetry() {
        this.loadCampaign();
    }

    handleImageError() {
        this.imageFailed = true;
    }

    async loadCampaign() {
        const currentRequest = ++this.requestId;
        this.hasError = false;
        this.imageFailed = false;
        if (!this._campaignId) {
            this.campaign = undefined;
            this.isLoading = false;
            return;
        }

        this.isLoading = true;
        try {
            const result = await getCampaignDetail({ campaignId: this._campaignId });
            if (currentRequest === this.requestId) {
                this.campaign = result || undefined;
            }
        } catch {
            if (currentRequest === this.requestId) {
                this.campaign = undefined;
                this.hasError = true;
            }
        } finally {
            if (currentRequest === this.requestId) {
                this.isLoading = false;
            }
        }
    }
}
