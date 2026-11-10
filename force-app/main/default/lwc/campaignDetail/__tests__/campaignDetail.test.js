import { createElement } from 'lwc';
import CampaignDetail from 'c/campaignDetail';
import getCampaignDetail from '@salesforce/apex/CampaignPortalController.getCampaignDetail';

jest.mock(
    '@salesforce/apex/CampaignPortalController.getCampaignDetail',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/DonorRecognitionService.getDonorRecognition',
    () => ({ default: jest.fn().mockResolvedValue([]) }),
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));
const normalize = (text) => text.replace(/\s+/g, ' ').trim();
const CAMPAIGN_ID = 'a00000000000001AAA';

function buildCampaign(overrides = {}) {
    return {
        id: CAMPAIGN_ID,
        name: 'Viaje a Mexico Dreamin´',
        description: 'Primera línea.\nSegunda línea.',
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
        isGeneral: false,
        ...overrides
    };
}

async function createComponent(campaign, campaignId = CAMPAIGN_ID) {
    getCampaignDetail.mockResolvedValue(campaign);
    const element = createElement('c-campaign-detail', { is: CampaignDetail });
    element.campaignId = campaignId;
    document.body.appendChild(element);
    await flushPromises();
    return element;
}

function donationButton(element) {
    return element.shadowRoot.querySelector('.panel__action');
}

describe('c-campaign-detail', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('requests the campaign by its Id and shows its public information', async () => {
        const element = await createComponent(buildCampaign());

        expect(getCampaignDetail).toHaveBeenCalledWith({ campaignId: CAMPAIGN_ID });
        expect(element.shadowRoot.querySelector('h1').textContent).toBe('Viaje a Mexico Dreamin´');
        expect(element.shadowRoot.querySelector('.about__text').textContent).toBe('Primera línea.\nSegunda línea.');
        expect(element.shadowRoot.querySelector('img.media__image').getAttribute('alt')).toBe('Estudiantes en el evento');
        const dates = Array.from(element.shadowRoot.querySelectorAll('.dates li')).map((item) => item.textContent);
        expect(dates).toEqual(['Inicio: 1 de octubre de 2026', 'Cierre: 12 de diciembre de 2026']);
    });

    it('does not show a closing date when the campaign has none', async () => {
        const element = await createComponent(buildCampaign({ endDate: null }));

        expect(element.shadowRoot.querySelectorAll('.dates li')).toHaveLength(1);
    });

    it('shows the progress and the donor recognition of the campaign', async () => {
        const element = await createComponent(buildCampaign());

        const progress = element.shadowRoot.querySelector('c-campaign-progress');
        expect(progress.totalRaised).toBe(500);
        expect(progress.progressPercent).toBe(50);
        expect(progress.compact).toBeFalsy();
        expect(element.shadowRoot.querySelector('c-donor-recognition-list').campaignId).toBe(CAMPAIGN_ID);
    });

    it('does not enable the recognition demo mode by default', async () => {
        const element = await createComponent(buildCampaign());

        expect(element.shadowRoot.querySelector('c-donor-recognition-list').demoMode).toBeFalsy();
    });

    it('shows the description as text and never as HTML', async () => {
        const element = await createComponent(buildCampaign({ description: '<b>Hola</b><script>alert(1)</script>' }));

        const text = element.shadowRoot.querySelector('.about__text');
        expect(text.textContent).toBe('<b>Hola</b><script>alert(1)</script>');
        expect(text.querySelector('b')).toBeNull();
    });

    it('lets the visitor start a donation on an open campaign', async () => {
        const element = await createComponent(buildCampaign());
        const handler = jest.fn();
        element.addEventListener('donationstart', handler);

        const button = donationButton(element);
        expect(button.label).toBe('Donar');
        expect(button.disabled).toBeFalsy();
        button.click();

        expect(handler).toHaveBeenCalledTimes(1);
        expect(handler.mock.calls[0][0].detail).toEqual({ campaignId: CAMPAIGN_ID, campaignName: 'Viaje a Mexico Dreamin´' });
        expect(element.shadowRoot.querySelector('.notice')).toBeNull();
    });

    it('shows a paused campaign as «Pausada» and blocks the donation', async () => {
        const element = await createComponent(buildCampaign({ status: 'Paused', availability: 'PAUSED', canDonate: false }));
        const handler = jest.fn();
        element.addEventListener('donationstart', handler);

        expect(element.shadowRoot.querySelector('.badge').textContent).toBe('Pausada');
        expect(element.shadowRoot.querySelector('.notice').textContent).toBe(
            'Esta campaña está pausada y por ahora no acepta donaciones.'
        );
        const button = donationButton(element);
        expect(button.label).toBe('Donaciones en pausa');
        expect(button.disabled).toBe(true);
        button.click();
        expect(handler).not.toHaveBeenCalled();
    });

    it('shows a closed campaign as informative only', async () => {
        const element = await createComponent(buildCampaign({ status: 'Closed', availability: 'CLOSED', canDonate: false }));
        const handler = jest.fn();
        element.addEventListener('donationstart', handler);

        expect(element.shadowRoot.querySelector('.badge').textContent).toBe('Cerrada');
        expect(element.shadowRoot.querySelector('.notice').textContent).toBe(
            'Esta campaña está cerrada y ya no acepta donaciones.'
        );
        const button = donationButton(element);
        expect(button.label).toBe('Donaciones cerradas');
        expect(button.disabled).toBe(true);
        button.click();
        expect(handler).not.toHaveBeenCalled();
    });

    it('shows an expired active campaign as «Campaña finalizada» with the agreed texts', async () => {
        const element = await createComponent(buildCampaign({ availability: 'ENDED', canDonate: false, endDate: '2026-01-01' }));

        const badge = element.shadowRoot.querySelector('.badge');
        expect(badge.textContent).toBe('Campaña finalizada');
        expect(badge.classList.contains('slds-badge_lightest')).toBe(true);
        expect(element.shadowRoot.querySelector('.notice').textContent).toBe(
            'Esta campaña ha finalizado su periodo de recaudación y ya no acepta donaciones.'
        );
        const button = donationButton(element);
        expect(button.label).toBe('Donaciones cerradas');
        expect(button.disabled).toBe(true);
    });

    it('blocks the donation when the server says an open campaign cannot receive donations', async () => {
        const element = await createComponent(buildCampaign({ canDonate: false }));
        const handler = jest.fn();
        element.addEventListener('donationstart', handler);

        expect(element.shadowRoot.querySelector('.notice').textContent).toBe(
            'En este momento esta campaña no acepta donaciones.'
        );
        expect(donationButton(element).disabled).toBe(true);
        donationButton(element).click();
        expect(handler).not.toHaveBeenCalled();
    });

    it('keeps showing the real progress above 100 % without disabling an open campaign', async () => {
        const element = await createComponent(buildCampaign({ totalRaised: 1500, progressPercent: 150 }));

        expect(element.shadowRoot.querySelector('c-campaign-progress').progressPercent).toBe(150);
        expect(donationButton(element).disabled).toBeFalsy();
    });

    it('shows the general campaign tag', async () => {
        const element = await createComponent(buildCampaign({ isGeneral: true }));

        expect(element.shadowRoot.querySelector('.tag').textContent).toBe('Campaña general');
    });

    it('uses a placeholder with descriptive text when the campaign has no image', async () => {
        const element = await createComponent(buildCampaign({ imageUrl: null, imageAltText: null }));

        expect(element.shadowRoot.querySelector('img')).toBeNull();
        expect(element.shadowRoot.querySelector('.media__placeholder').getAttribute('aria-label')).toBe(
            'Imagen no disponible para la campaña Viaje a Mexico Dreamin´'
        );
    });

    it('shows a not-found message when the campaign is not publicly available', async () => {
        const element = await createComponent(null);

        expect(normalize(element.shadowRoot.querySelector('[role="status"]').textContent)).toContain(
            'No encontramos esta campaña.'
        );
        expect(element.shadowRoot.querySelector('article')).toBeNull();
    });

    it('does not call the server when there is no campaign Id', async () => {
        const element = await createComponent(buildCampaign(), null);

        expect(getCampaignDetail).not.toHaveBeenCalled();
        expect(element.shadowRoot.querySelector('article')).toBeNull();
        expect(element.shadowRoot.querySelector('[role="status"]')).not.toBeNull();
    });

    it('goes back to the list from the back button and from the not-found state', async () => {
        const element = await createComponent(null);
        const handler = jest.fn();
        element.addEventListener('backtolist', handler);

        element.shadowRoot.querySelector('.detail__back lightning-button').click();
        element.shadowRoot.querySelector('.state lightning-button').click();

        expect(handler).toHaveBeenCalledTimes(2);
    });

    it('shows a Spanish error without technical detail and retries on request', async () => {
        getCampaignDetail.mockRejectedValueOnce({ body: { message: 'System.QueryException: technical' } });
        getCampaignDetail.mockResolvedValueOnce(buildCampaign());
        const element = createElement('c-campaign-detail', { is: CampaignDetail });
        element.campaignId = CAMPAIGN_ID;
        document.body.appendChild(element);
        await flushPromises();

        const alert = element.shadowRoot.querySelector('[role="alert"]');
        expect(alert.textContent).toContain('No pudimos cargar la campaña.');
        expect(alert.textContent).not.toContain('QueryException');

        alert.querySelector('lightning-button').click();
        await flushPromises();

        expect(element.shadowRoot.querySelector('h1').textContent).toBe('Viaje a Mexico Dreamin´');
    });

    it('loads the new campaign when the Id changes', async () => {
        const element = await createComponent(buildCampaign());
        getCampaignDetail.mockResolvedValue(buildCampaign({ id: 'a00000000000002AAA', name: 'Otra campaña' }));

        element.campaignId = 'a00000000000002AAA';
        await flushPromises();

        expect(getCampaignDetail).toHaveBeenLastCalledWith({ campaignId: 'a00000000000002AAA' });
        expect(element.shadowRoot.querySelector('h1').textContent).toBe('Otra campaña');
    });

    it('ignores a slow answer for a campaign that is no longer shown', async () => {
        let resolveFirst;
        getCampaignDetail.mockImplementationOnce(() => new Promise((resolve) => (resolveFirst = resolve)));
        getCampaignDetail.mockResolvedValueOnce(buildCampaign({ id: 'a00000000000002AAA', name: 'Campaña nueva' }));
        const element = createElement('c-campaign-detail', { is: CampaignDetail });
        element.campaignId = CAMPAIGN_ID;
        document.body.appendChild(element);
        element.campaignId = 'a00000000000002AAA';
        await flushPromises();

        resolveFirst(buildCampaign({ name: 'Campaña vieja' }));
        await flushPromises();

        expect(element.shadowRoot.querySelector('h1').textContent).toBe('Campaña nueva');
    });
});
