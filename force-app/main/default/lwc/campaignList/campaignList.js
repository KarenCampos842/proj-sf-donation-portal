import { LightningElement, api } from 'lwc';
import getAvailableCampaigns from '@salesforce/apex/CampaignPortalController.getAvailableCampaigns';
import { MESSAGES, formatMessage } from 'c/portalMessages';
import { formatDate, getAvailabilityInfo } from 'c/portalUtils';

export default class CampaignList extends LightningElement {
    campaigns = [];
    isLoading = true;
    hasError = false;
    requestId = 0;

    connectedCallback() {
        this.loadCampaigns();
    }

    @api
    refresh() {
        this.loadCampaigns();
    }

    get messages() {
        return MESSAGES.list;
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && this.campaigns.length === 0;
    }

    get hasCampaigns() {
        return !this.isLoading && !this.hasError && this.campaigns.length > 0;
    }

    handleSelect(event) {
        const campaignId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('campaignselect', { detail: { campaignId } }));
    }

    handleRetry() {
        this.loadCampaigns();
    }

    handleImageError(event) {
        const failedId = event.currentTarget.dataset.id;
        this.campaigns = this.campaigns.map((campaign) =>
            campaign.id === failedId ? { ...campaign, hasImage: false } : campaign
        );
    }

    async loadCampaigns() {
        const currentRequest = ++this.requestId;
        this.isLoading = true;
        this.hasError = false;
        try {
            const result = await getAvailableCampaigns();
            if (currentRequest === this.requestId) {
                this.campaigns = (result || []).map((campaign) => this.toViewModel(campaign));
            }
        } catch {
            if (currentRequest === this.requestId) {
                this.campaigns = [];
                this.hasError = true;
            }
        } finally {
            if (currentRequest === this.requestId) {
                this.isLoading = false;
            }
        }
    }

    toViewModel(campaign) {
        const availability = getAvailabilityInfo(campaign.availability);
        const hasImage = Boolean(campaign.imageUrl);
        const isPaused = campaign.availability === 'PAUSED';
        return {
            id: campaign.id,
            name: campaign.name,
            imageUrl: campaign.imageUrl,
            hasImage,
            imageAlt: campaign.imageAltText || formatMessage(this.messages.imageAlt, campaign.name),
            placeholderLabel: formatMessage(this.messages.noImageAlt, campaign.name),
            badgeLabel: availability.label,
            badgeClass: availability.badgeClass,
            isGeneral: campaign.isGeneral === true,
            isPaused,
            closesOnText: campaign.endDate ? formatMessage(this.messages.closesOn, formatDate(campaign.endDate)) : '',
            actionLabel: formatMessage(this.messages.viewDetailOf, campaign.name),
            cardClass: isPaused ? 'card card_paused' : 'card',
            totalRaised: campaign.totalRaised,
            goal: campaign.goal,
            progressPercent: campaign.progressPercent,
            donationCount: campaign.donationCount
        };
    }
}
