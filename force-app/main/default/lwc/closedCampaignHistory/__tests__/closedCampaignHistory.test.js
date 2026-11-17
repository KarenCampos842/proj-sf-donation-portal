import { createElement } from 'lwc';
import ClosedCampaignHistory from 'c/closedCampaignHistory';
import getClosedCampaigns from '@salesforce/apex/CampaignPortalController.getClosedCampaigns';

jest.mock(
    '@salesforce/apex/CampaignPortalController.getClosedCampaigns',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));
const normalize = (text) => text.replace(/\s+/g, ' ').trim();

const CLOSED_WITH_IMAGE = {
    id: 'a00000000000001AAA',
    name: 'Viaje a Mexico Dreamin´ 2025',
    imageUrl: 'https://example.com/viaje.png',
    imageAltText: 'Estudiantes en el evento',
    goal: 15000,
    totalRaised: 18000,
    donationCount: 12,
    progressPercent: 120,
    startDate: '2025-09-01',
    endDate: '2025-11-19',
    status: 'Closed',
    availability: 'CLOSED',
    canDonate: false,
    isGeneral: false
};

const CLOSED_WITHOUT_IMAGE = {
    id: 'a00000000000002AAA',
    name: 'Kits de bienvenida 2025',
    imageUrl: null,
    imageAltText: null,
    goal: 5000,
    totalRaised: 1250.5,
    donationCount: 1,
    progressPercent: 25.01,
    startDate: '2025-08-01',
    endDate: null,
    status: 'Closed',
    availability: 'CLOSED',
    canDonate: false,
    isGeneral: false
};

function createComponent() {
    const element = createElement('c-closed-campaign-history', { is: ClosedCampaignHistory });
    document.body.appendChild(element);
    return element;
}

const cards = (element) => element.shadowRoot.querySelectorAll('article.card');

describe('c-closed-campaign-history', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows the page title, the explanation and the way back, with a single h1', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITH_IMAGE]);
        const element = createComponent();
        await flushPromises();

        const headings = element.shadowRoot.querySelectorAll('h1');
        expect(headings).toHaveLength(1);
        expect(headings[0].textContent).toBe('Historial de campañas');
        expect(element.shadowRoot.querySelector('.history__subtitle').textContent).toContain('ya concluyeron');
        expect(element.shadowRoot.querySelector('.history__back lightning-button').label).toBe('Volver a las campañas');
    });

    it('shows the loading state, announced to assistive technology, before the data arrives', async () => {
        getClosedCampaigns.mockReturnValue(new Promise(() => {}));
        const element = createComponent();
        await Promise.resolve();

        const loading = element.shadowRoot.querySelector('.state--loading[role="status"]');
        expect(loading).not.toBeNull();
        expect(loading.querySelector('lightning-spinner').alternativeText).toBe('Cargando el historial…');
        expect(element.shadowRoot.querySelector('.grid')).toBeNull();
    });

    it('shows the name, the final total, the goal and the closed badge of a single campaign', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITH_IMAGE]);
        const element = createComponent();
        await flushPromises();

        expect(cards(element)).toHaveLength(1);
        const card = cards(element)[0];
        expect(card.querySelector('.card__link').textContent.trim()).toBe('Viaje a Mexico Dreamin´ 2025');
        expect(normalize(card.querySelector('.results__value_total').textContent)).toBe('$18,000 MXN');
        const values = card.querySelectorAll('.results__value');
        expect(normalize(values[1].textContent)).toBe('$15,000 MXN');
        const labels = Array.from(card.querySelectorAll('.results__label')).map((label) => label.textContent);
        expect(labels).toEqual(['Total final', 'Meta']);
        expect(card.querySelector('.badge').textContent).toBe('Cerrada');
        expect(element.shadowRoot.querySelector('.history__count').textContent).toBe('1 campaña cerrada');
    });

    it('shows several campaigns in the order received, with the count announced politely', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITH_IMAGE, CLOSED_WITHOUT_IMAGE]);
        const element = createComponent();
        await flushPromises();

        const titles = Array.from(cards(element)).map((card) => card.querySelector('.card__link').textContent.trim());
        expect(titles).toEqual(['Viaje a Mexico Dreamin´ 2025', 'Kits de bienvenida 2025']);
        const count = element.shadowRoot.querySelector('.history__count');
        expect(count.getAttribute('role')).toBe('status');
        expect(count.textContent).toBe('2 campañas cerradas');
    });

    it('shows the real percentage of the goal, even above 100 %, and says the goal was reached', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITH_IMAGE, CLOSED_WITHOUT_IMAGE]);
        const element = createComponent();
        await flushPromises();

        const [reached, notReached] = cards(element);
        expect(normalize(reached.querySelector('.card__percent').textContent)).toMatch(/^120 ?% de la meta$/);
        expect(reached.querySelector('.card__reached').textContent).toBe('Meta alcanzada');
        expect(normalize(notReached.querySelector('.card__percent').textContent)).toMatch(/^25\.01 ?% de la meta$/);
        expect(notReached.querySelector('.card__reached')).toBeNull();
    });

    it('formats amounts with cents when the final total has them', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITHOUT_IMAGE]);
        const element = createComponent();
        await flushPromises();

        expect(normalize(cards(element)[0].querySelector('.results__value_total').textContent)).toBe('$1,250.50 MXN');
    });

    it('shows the number of donations and the closing date only when they exist', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITH_IMAGE, CLOSED_WITHOUT_IMAGE]);
        const element = createComponent();
        await flushPromises();

        const [withDate, withoutDate] = cards(element);
        const notes = Array.from(withDate.querySelectorAll('.card__note')).map((note) => note.textContent);
        expect(notes).toEqual(['12 donaciones confirmadas', 'Fecha de cierre: 19 de noviembre de 2025']);
        expect(Array.from(withoutDate.querySelectorAll('.card__note')).map((note) => note.textContent)).toEqual([
            '1 donación confirmada'
        ]);
    });

    it('never offers a donation action on the cards', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITH_IMAGE, CLOSED_WITHOUT_IMAGE]);
        const element = createComponent();
        await flushPromises();

        cards(element).forEach((card) => {
            expect(card.querySelector('lightning-button')).toBeNull();
            expect(card.textContent).not.toMatch(/Donar\b/);
        });
        expect(element.shadowRoot.querySelectorAll('.card__link')).toHaveLength(2);
    });

    it('shows the image with its alt text and a described placeholder when there is none', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITH_IMAGE, CLOSED_WITHOUT_IMAGE]);
        const element = createComponent();
        await flushPromises();

        const image = element.shadowRoot.querySelector('img.media__image');
        expect(image.getAttribute('src')).toBe('https://example.com/viaje.png');
        expect(image.getAttribute('alt')).toBe('Estudiantes en el evento');
        const placeholder = element.shadowRoot.querySelector('.media__placeholder');
        expect(placeholder.getAttribute('role')).toBe('img');
        expect(placeholder.getAttribute('aria-label')).toBe('Imagen no disponible para la campaña Kits de bienvenida 2025');
    });

    it('falls back to the placeholder when an image cannot be loaded', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITH_IMAGE]);
        const element = createComponent();
        await flushPromises();

        element.shadowRoot.querySelector('img.media__image').dispatchEvent(new CustomEvent('error'));
        await flushPromises();

        expect(element.shadowRoot.querySelector('img')).toBeNull();
        expect(element.shadowRoot.querySelector('.media__placeholder')).not.toBeNull();
    });

    it('shows the empty message, and no invented cards, when there are no closed campaigns', async () => {
        getClosedCampaigns.mockResolvedValue([]);
        const element = createComponent();
        await flushPromises();

        expect(element.shadowRoot.querySelector('.grid')).toBeNull();
        expect(cards(element)).toHaveLength(0);
        const message = element.shadowRoot.querySelector('p.state__message[role="status"]');
        expect(normalize(message.textContent)).toBe('No hay campañas cerradas para consultar por ahora');
        expect(element.shadowRoot.querySelector('.history__count')).toBeNull();
    });

    it('shows a Spanish error without technical detail and retries on request', async () => {
        getClosedCampaigns.mockRejectedValueOnce({ body: { message: 'System.QueryException: technical' } });
        getClosedCampaigns.mockResolvedValueOnce([CLOSED_WITH_IMAGE]);
        const element = createComponent();
        await flushPromises();

        const alert = element.shadowRoot.querySelector('[role="alert"]');
        expect(alert.textContent).toContain('No pudimos cargar el historial de campañas.');
        expect(alert.textContent).not.toContain('QueryException');
        expect(cards(element)).toHaveLength(0);

        alert.querySelector('lightning-button').click();
        await flushPromises();

        expect(getClosedCampaigns).toHaveBeenCalledTimes(2);
        expect(cards(element)).toHaveLength(1);
        expect(element.shadowRoot.querySelector('[role="alert"]')).toBeNull();
    });

    it('ignores a slow answer that arrives after a newer request', async () => {
        let resolveFirst;
        getClosedCampaigns.mockReturnValueOnce(new Promise((resolve) => (resolveFirst = resolve)));
        getClosedCampaigns.mockResolvedValueOnce([CLOSED_WITHOUT_IMAGE]);
        const element = createComponent();
        element.refresh();
        await flushPromises();
        resolveFirst([CLOSED_WITH_IMAGE]);
        await flushPromises();

        const titles = Array.from(cards(element)).map((card) => card.querySelector('.card__link').textContent.trim());
        expect(titles).toEqual(['Kits de bienvenida 2025']);
    });

    it('opens the detail of a campaign through an event with its Id', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITH_IMAGE, CLOSED_WITHOUT_IMAGE]);
        const element = createComponent();
        await flushPromises();
        const handler = jest.fn();
        element.addEventListener('campaignselect', handler);

        element.shadowRoot.querySelectorAll('.card__link')[1].click();

        expect(handler).toHaveBeenCalledTimes(1);
        expect(handler.mock.calls[0][0].detail).toEqual({ campaignId: 'a00000000000002AAA' });
    });

    it('gives each campaign button an accessible name that says what it opens', async () => {
        getClosedCampaigns.mockResolvedValue([CLOSED_WITH_IMAGE]);
        const element = createComponent();
        await flushPromises();

        expect(element.shadowRoot.querySelector('.card__link').getAttribute('aria-label')).toBe(
            'Ver detalle de la campaña Viaje a Mexico Dreamin´ 2025'
        );
        expect(element.shadowRoot.querySelector('ul.grid').getAttribute('aria-label')).toBe('Campañas cerradas');
    });

    it('asks the portal to go back to the catalog', async () => {
        getClosedCampaigns.mockResolvedValue([]);
        const element = createComponent();
        await flushPromises();
        const handler = jest.fn();
        element.addEventListener('backtolist', handler);

        element.shadowRoot.querySelector('.history__back lightning-button').click();

        expect(handler).toHaveBeenCalledTimes(1);
    });
});
