import { createElement } from 'lwc';
import CampaignProgress from 'c/campaignProgress';

const normalize = (text) => text.replace(/\s+/g, ' ').trim();

function createComponent(props = {}) {
    const element = createElement('c-campaign-progress', { is: CampaignProgress });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
}

describe('c-campaign-progress', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.restoreAllMocks();
        delete window.matchMedia;
    });

    it('shows the raised amount and the goal in MXN', async () => {
        const element = createComponent({ totalRaised: 500, goal: 1000, progressPercent: 50 });
        await Promise.resolve();

        const text = normalize(element.shadowRoot.textContent);
        expect(text).toContain('Recaudado: $500 MXN');
        expect(text).toContain('Meta: $1,000 MXN');
    });

    it('shows the real percentage below the goal without the goal-reached text', async () => {
        const element = createComponent({ totalRaised: 500, goal: 1000, progressPercent: 50 });
        await Promise.resolve();

        const bar = element.shadowRoot.querySelector('[role="progressbar"]');
        expect(bar.getAttribute('aria-valuenow')).toBe('50');
        expect(normalize(element.shadowRoot.querySelector('.meta__percent').textContent)).toBe('50%');
        expect(element.shadowRoot.querySelector('.meta__reached')).toBeNull();
    });

    it('shows 100 % and the goal-reached text when the goal is met exactly', async () => {
        const element = createComponent({ totalRaised: 400, goal: 400, progressPercent: 100 });
        await Promise.resolve();

        expect(normalize(element.shadowRoot.querySelector('.meta__percent').textContent)).toBe('100%');
        expect(element.shadowRoot.querySelector('.meta__reached').textContent).toBe('Meta alcanzada');
    });

    it('shows the real percentage above 100 % while the bar stops at its track', async () => {
        const element = createComponent({ totalRaised: 600, goal: 500, progressPercent: 120 });
        await Promise.resolve();

        const bar = element.shadowRoot.querySelector('[role="progressbar"]');
        expect(normalize(element.shadowRoot.querySelector('.meta__percent').textContent)).toBe('120%');
        expect(bar.getAttribute('aria-valuenow')).toBe('100');
        expect(normalize(bar.getAttribute('aria-valuetext'))).toBe('120% de la meta');
        expect(element.shadowRoot.querySelector('.fill').getAttribute('style')).toContain('width: 100%');
    });

    it('exposes the progress bar to assistive technology with a Spanish label', async () => {
        const element = createComponent({ totalRaised: 0, goal: 1000, progressPercent: 0 });
        await Promise.resolve();

        const bar = element.shadowRoot.querySelector('[role="progressbar"]');
        expect(bar.getAttribute('aria-label')).toBe('Avance de la campaña');
        expect(bar.getAttribute('aria-valuemin')).toBe('0');
        expect(bar.getAttribute('aria-valuemax')).toBe('100');
        expect(bar.getAttribute('aria-valuenow')).toBe('0');
    });

    it('hides the donation count when there are no donations', async () => {
        const element = createComponent({ totalRaised: 0, goal: 1000, progressPercent: 0, donationCount: 0 });
        await Promise.resolve();

        expect(element.shadowRoot.querySelector('.meta__count')).toBeNull();
    });

    it('uses the singular for one donation and the plural for several', async () => {
        const element = createComponent({ totalRaised: 100, goal: 1000, progressPercent: 10, donationCount: 1 });
        await Promise.resolve();
        expect(element.shadowRoot.querySelector('.meta__count').textContent).toBe('1 donación confirmada');

        element.donationCount = 3;
        await Promise.resolve();
        expect(element.shadowRoot.querySelector('.meta__count').textContent).toBe('3 donaciones confirmadas');
    });

    it('applies the compact style when requested', async () => {
        const element = createComponent({ totalRaised: 100, goal: 1000, progressPercent: 10, compact: true });
        await Promise.resolve();

        expect(element.shadowRoot.querySelector('.progress_compact')).not.toBeNull();
    });

    it('shows the final amount at once when the visitor prefers reduced motion', async () => {
        window.matchMedia = jest.fn().mockReturnValue({ matches: true });
        const frame = jest.spyOn(window, 'requestAnimationFrame');
        const element = createComponent({ totalRaised: 750, goal: 1000, progressPercent: 75 });
        await Promise.resolve();

        expect(normalize(element.shadowRoot.querySelector('.raised__value').textContent)).toBe('$750 MXN');
        expect(frame).not.toHaveBeenCalled();
    });

    it('counts up to the final amount when motion is allowed', async () => {
        window.matchMedia = jest.fn().mockReturnValue({ matches: false });
        jest.spyOn(window.performance, 'now').mockReturnValue(0);
        let nextFrame;
        jest.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => {
            nextFrame = callback;
            return 1;
        });
        const element = createComponent({ totalRaised: 800, goal: 1000, progressPercent: 80 });
        await Promise.resolve();
        expect(normalize(element.shadowRoot.querySelector('.raised__value').textContent)).toBe('$0 MXN');

        nextFrame(5000);
        await Promise.resolve();
        expect(normalize(element.shadowRoot.querySelector('.raised__value').textContent)).toBe('$800 MXN');
    });

    it('keeps the full amount available to screen readers while the counter runs', async () => {
        window.matchMedia = jest.fn().mockReturnValue({ matches: false });
        jest.spyOn(window, 'requestAnimationFrame').mockReturnValue(1);
        const element = createComponent({ totalRaised: 800, goal: 1000, progressPercent: 80 });
        await Promise.resolve();

        expect(element.shadowRoot.querySelector('.raised__value').getAttribute('aria-hidden')).toBe('true');
        expect(normalize(element.shadowRoot.querySelector('.visually-hidden').textContent)).toBe('Recaudado: $800 MXN');
    });
});
