import { LightningElement, api } from 'lwc';
import { MESSAGES, formatMessage } from 'c/portalMessages';
import { formatMxn, formatPercent, prefersReducedMotion } from 'c/portalUtils';

const COUNTER_DURATION_MS = 700;

export default class CampaignProgress extends LightningElement {
    @api compact = false;

    _totalRaised = 0;
    _goal = 0;
    _progressPercent = 0;
    _donationCount = 0;
    displayedRaised = 0;
    animationFrame;

    @api
    get totalRaised() {
        return this._totalRaised;
    }
    set totalRaised(value) {
        this._totalRaised = Number(value) || 0;
        this.animateRaisedAmount();
    }

    @api
    get goal() {
        return this._goal;
    }
    set goal(value) {
        this._goal = Number(value) || 0;
    }

    /** Real percentage, where 50 means 50 %. It can be higher than 100. */
    @api
    get progressPercent() {
        return this._progressPercent;
    }
    set progressPercent(value) {
        this._progressPercent = Number(value) || 0;
    }

    @api
    get donationCount() {
        return this._donationCount;
    }
    set donationCount(value) {
        this._donationCount = Number(value) || 0;
    }

    disconnectedCallback() {
        this.cancelAnimation();
    }

    get messages() {
        return MESSAGES.progress;
    }

    get rootClass() {
        return this.compact ? 'progress progress_compact' : 'progress';
    }

    get displayedRaisedText() {
        return formatMxn(this.displayedRaised);
    }

    get raisedText() {
        return formatMessage(this.messages.raised, formatMxn(this._totalRaised));
    }

    get goalText() {
        return formatMessage(this.messages.goal, formatMxn(this._goal));
    }

    get percentText() {
        return formatPercent(this._progressPercent);
    }

    get ariaValueText() {
        return formatMessage(this.messages.ofGoal, this.percentText);
    }

    /** The bar never goes past its track, but the text always shows the real value. */
    get barValue() {
        return Math.min(100, Math.max(0, this._progressPercent));
    }

    get fillStyle() {
        return `width: ${this.barValue}%`;
    }

    get isGoalReached() {
        return this._progressPercent >= 100;
    }

    get showDonationCount() {
        return this._donationCount > 0;
    }

    get donationCountText() {
        return this._donationCount === 1
            ? this.messages.donationOne
            : formatMessage(this.messages.donationMany, this._donationCount);
    }

    animateRaisedAmount() {
        this.cancelAnimation();
        const target = this._totalRaised;
        if (prefersReducedMotion() || target === 0 || typeof window.requestAnimationFrame !== 'function') {
            this.displayedRaised = target;
            return;
        }
        const start = this.displayedRaised;
        const startTime = window.performance.now();
        const step = (now) => {
            const elapsed = Math.min(1, (now - startTime) / COUNTER_DURATION_MS);
            const eased = 1 - Math.pow(1 - elapsed, 3);
            this.displayedRaised = Math.round(start + (target - start) * eased);
            if (elapsed < 1) {
                // Short counter animation; it is cancelled in disconnectedCallback.
                this.animationFrame = window.requestAnimationFrame(step);
            } else {
                this.displayedRaised = target;
                this.animationFrame = undefined;
            }
        };
        this.animationFrame = window.requestAnimationFrame(step);
    }

    cancelAnimation() {
        if (this.animationFrame !== undefined) {
            window.cancelAnimationFrame(this.animationFrame);
            this.animationFrame = undefined;
        }
    }
}
