import { createElement } from 'lwc';
import CampaignList from 'c/campaignList';
import getAvailableCampaigns from '@salesforce/apex/CampaignPortalController.getAvailableCampaigns';

jest.mock(
    '@salesforce/apex/CampaignPortalController.getAvailableCampaigns',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));
const normalize = (text) => text.replace(/\s+/g, ' ').trim();

const OPEN_CAMPAIGN = {
    id: 'a00000000000001AAA',
    name: 'Viaje a Mexico Dreamin´',
    imageUrl: 'https://example.com/viaje.png',
    imageAltText: 'Estudiantes en el evento',
    goal: 1000,
    totalRaised: 500,
    donationCount: 2,
    progressPercent: 50,
    startDate: '2026-10-01',
    endDate: '2026-12-12',
    status: 'Active',
    availability: 'OPEN',
    canDonate: true,
    isGeneral: false
};

const PAUSED_CAMPAIGN = {
    id: 'a00000000000002AAA',
    name: 'Campaña pausada',
    imageUrl: null,
    imageAltText: null,
    goal: 2000,
    totalRaised: 0,
    donationCount: 0,
    progressPercent: 0,
    startDate: '2026-10-01',
    endDate: null,
    status: 'Paused',
    availability: 'PAUSED',
    canDonate: false,
    isGeneral: true
};

function createComponent() {
    const element = createElement('c-campaign-list', { is: CampaignList });
    document.body.appendChild(element);
    return element;
}

describe('c-campaign-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows the loading state before the campaigns arrive', async () => {
        getAvailableCampaigns.mockReturnValue(new Promise(() => {}));
        const element = createComponent();
        await Promise.resolve();

        expect(element.shadowRoot.querySelector('.state--loading[role="status"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.grid')).toBeNull();
    });

    it('shows one consistent card per campaign', async () => {
        getAvailableCampaigns.mockResolvedValue([OPEN_CAMPAIGN, PAUSED_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();

        const cards = element.shadowRoot.querySelectorAll('article.card');
        expect(cards).toHaveLength(2);
        expect(cards[0].querySelector('.card__link').textContent.trim()).toBe('Viaje a Mexico Dreamin´');
        expect(cards[1].querySelector('.card__link').textContent.trim()).toBe('Campaña pausada');
    });

    it('passes the progress data to the progress indicator of each card', async () => {
        getAvailableCampaigns.mockResolvedValue([OPEN_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();

        const progress = element.shadowRoot.querySelector('c-campaign-progress');
        expect(progress.totalRaised).toBe(500);
        expect(progress.goal).toBe(1000);
        expect(progress.progressPercent).toBe(50);
        expect(progress.donationCount).toBe(2);
        expect(progress.compact).toBe(true);
    });

    it('marks a paused campaign with text and explains it cannot receive donations', async () => {
        getAvailableCampaigns.mockResolvedValue([PAUSED_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();

        const card = element.shadowRoot.querySelector('article.card');
        expect(card.querySelector('.badge').textContent).toBe('Pausada');
        expect(card.querySelector('.card__note').textContent).toContain('no recibe donaciones');
        expect(card.querySelector('lightning-button')).toBeNull();
    });

    it('marks an open campaign as active and shows its closing date', async () => {
        getAvailableCampaigns.mockResolvedValue([OPEN_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();

        const card = element.shadowRoot.querySelector('article.card');
        expect(card.querySelector('.badge').textContent).toBe('Activa');
        expect(card.querySelector('.card__date').textContent).toBe('Cierra el 12 de diciembre de 2026');
        expect(card.querySelector('.card__note')).toBeNull();
    });

    it('shows the general campaign tag only for the general campaign', async () => {
        getAvailableCampaigns.mockResolvedValue([OPEN_CAMPAIGN, PAUSED_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();

        const tags = element.shadowRoot.querySelectorAll('.card__tag');
        expect(tags).toHaveLength(1);
        expect(tags[0].textContent).toBe('Campaña general');
    });

    it('shows the image with its alt text', async () => {
        getAvailableCampaigns.mockResolvedValue([OPEN_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();

        const image = element.shadowRoot.querySelector('img.media__image');
        expect(image.getAttribute('src')).toBe('https://example.com/viaje.png');
        expect(image.getAttribute('alt')).toBe('Estudiantes en el evento');
    });

    it('uses a neutral placeholder with descriptive text when there is no image', async () => {
        getAvailableCampaigns.mockResolvedValue([PAUSED_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();

        const placeholder = element.shadowRoot.querySelector('.media__placeholder');
        expect(element.shadowRoot.querySelector('img')).toBeNull();
        expect(placeholder.getAttribute('role')).toBe('img');
        expect(placeholder.getAttribute('aria-label')).toBe('Imagen no disponible para la campaña Campaña pausada');
    });

    it('falls back to the placeholder when the image cannot be loaded', async () => {
        getAvailableCampaigns.mockResolvedValue([OPEN_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();

        element.shadowRoot.querySelector('img.media__image').dispatchEvent(new CustomEvent('error'));
        await flushPromises();

        expect(element.shadowRoot.querySelector('img')).toBeNull();
        expect(element.shadowRoot.querySelector('.media__placeholder')).not.toBeNull();
    });

    it('shows the exact empty message when there are no campaigns', async () => {
        getAvailableCampaigns.mockResolvedValue([]);
        const element = createComponent();
        await flushPromises();

        expect(element.shadowRoot.querySelector('.grid')).toBeNull();
        expect(normalize(element.shadowRoot.querySelector('p[role="status"]').textContent)).toBe(
            'No hay campañas disponibles por ahora'
        );
    });

    it('shows a Spanish error without technical detail and retries on request', async () => {
        getAvailableCampaigns.mockRejectedValueOnce({ body: { message: 'System.QueryException: technical' } });
        getAvailableCampaigns.mockResolvedValueOnce([OPEN_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();

        const alert = element.shadowRoot.querySelector('[role="alert"]');
        expect(alert.textContent).toContain('No pudimos cargar las campañas.');
        expect(alert.textContent).not.toContain('QueryException');

        alert.querySelector('lightning-button').click();
        await flushPromises();

        expect(getAvailableCampaigns).toHaveBeenCalledTimes(2);
        expect(element.shadowRoot.querySelectorAll('article.card')).toHaveLength(1);
        expect(element.shadowRoot.querySelector('[role="alert"]')).toBeNull();
    });

    it('opens the detail of a campaign through an event with its Id', async () => {
        getAvailableCampaigns.mockResolvedValue([OPEN_CAMPAIGN, PAUSED_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();
        const handler = jest.fn();
        element.addEventListener('campaignselect', handler);

        element.shadowRoot.querySelectorAll('.card__link')[1].click();

        expect(handler).toHaveBeenCalledTimes(1);
        expect(handler.mock.calls[0][0].detail).toEqual({ campaignId: 'a00000000000002AAA' });
    });

    it('gives every card button an accessible name that includes the campaign name', async () => {
        getAvailableCampaigns.mockResolvedValue([OPEN_CAMPAIGN]);
        const element = createComponent();
        await flushPromises();

        const label = element.shadowRoot.querySelector('.card__link').getAttribute('aria-label');
        expect(label).toBe('Ver detalle de la campaña Viaje a Mexico Dreamin´');
    });

    it('refreshes on demand', async () => {
        getAvailableCampaigns.mockResolvedValue([]);
        const element = createComponent();
        await flushPromises();

        element.refresh();
        await flushPromises();

        expect(getAvailableCampaigns).toHaveBeenCalledTimes(2);
    });
});
