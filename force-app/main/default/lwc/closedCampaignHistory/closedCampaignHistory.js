import { LightningElement, api } from 'lwc';
import getClosedCampaigns from '@salesforce/apex/CampaignPortalController.getClosedCampaigns';
import { MESSAGES, formatMessage } from 'c/portalMessages';
import { formatDate, formatMxn, formatPercent, getAvailabilityInfo } from 'c/portalUtils';

/**
 * History of closed campaigns (DON-05). Read-only: it shows the name, the goal and the final total
 * of each closed campaign and lets the visitor open its detail. It never offers a donation action.
 * Events: campaignselect (detail: { campaignId }) and backtolist, handled by donationPortal.
 */
export default class ClosedCampaignHistory extends LightningElement {
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
        return MESSAGES.history;
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && this.campaigns.length === 0;
    }

    get hasCampaigns() {
        return !this.isLoading && !this.hasError && this.campaigns.length > 0;
    }

    get countText() {
        return this.campaigns.length === 1
            ? this.messages.countOne
            : formatMessage(this.messages.countMany, this.campaigns.length);
    }

    handleSelect(event) {
        const campaignId = event.currentTarget.dataset.id;
        this.dispatchEvent(new CustomEvent('campaignselect', { detail: { campaignId } }));
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('backtolist'));
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
            const result = await getClosedCampaigns();
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
        const badge = getAvailabilityInfo('CLOSED');
        const donationCount = Number(campaign.donationCount) || 0;
        const progressPercent = Number(campaign.progressPercent) || 0;
        return {
            id: campaign.id,
            name: campaign.name,
            imageUrl: campaign.imageUrl,
            hasImage: Boolean(campaign.imageUrl),
            imageAlt: campaign.imageAltText || formatMessage(MESSAGES.list.imageAlt, campaign.name),
            placeholderLabel: formatMessage(MESSAGES.list.noImageAlt, campaign.name),
            badgeLabel: badge.label,
            badgeClass: badge.badgeClass,
            totalText: formatMxn(campaign.totalRaised),
            goalText: formatMxn(campaign.goal),
            percentText: formatMessage(this.messages.percentOfGoal, formatPercent(progressPercent)),
            isGoalReached: progressPercent >= 100,
            donationText: this.donationText(donationCount),
            closedOnText: campaign.endDate ? formatMessage(this.messages.closedOn, formatDate(campaign.endDate)) : '',
            actionLabel: formatMessage(MESSAGES.list.viewDetailOf, campaign.name)
        };
    }

    donationText(donationCount) {
        if (donationCount === 0) {
            return '';
        }
        return donationCount === 1
            ? MESSAGES.progress.donationOne
            : formatMessage(MESSAGES.progress.donationMany, donationCount);
    }

    get goalReachedText() {
        return MESSAGES.progress.goalReached;
    }

    get viewDetailText() {
        return MESSAGES.list.viewDetail;
    }
}
