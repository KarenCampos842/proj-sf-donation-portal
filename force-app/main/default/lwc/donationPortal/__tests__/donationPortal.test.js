import { createElement } from 'lwc';
import DonationPortal from 'c/donationPortal';
import { CurrentPageReference, __navigateMock } from 'lightning/navigation';
import getAvailableCampaigns from '@salesforce/apex/CampaignPortalController.getAvailableCampaigns';
import getCampaignDetail from '@salesforce/apex/CampaignPortalController.getCampaignDetail';
import getClosedCampaigns from '@salesforce/apex/CampaignPortalController.getClosedCampaigns';

// The mocked router behaves like the LWR one: Navigate publishes a new page reference with the state.
jest.mock('lightning/navigation', () => {
    const { createTestWireAdapter } = require('@salesforce/wire-service-jest-util');
    const CurrentPageReference = createTestWireAdapter(jest.fn());
    const Navigate = Symbol('Navigate');
    const navigateMock = jest.fn();
    const NavigationMixin = (Base) =>
        class extends Base {
            [Navigate](pageReference, replace) {
                navigateMock(pageReference, replace);
                CurrentPageReference.emit(pageReference);
            }
        };
    NavigationMixin.Navigate = Navigate;
    return { CurrentPageReference, NavigationMixin, __navigateMock: navigateMock };
});
jest.mock('@salesforce/apex/CampaignPortalController.getAvailableCampaigns', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/CampaignPortalController.getCampaignDetail', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/CampaignPortalController.getClosedCampaigns', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/DonorRecognitionService.getDonorRecognition', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/DonationIntakeService.startDonation', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/DonationIntakeService.openPayment', () => ({ default: jest.fn() }), { virtual: true });

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));
const CAMPAIGN_ID = 'a00000000000001AAA';
const OTHER_CAMPAIGN_ID = 'a00000000000002AAA';

function pageReference(state = {}) {
    return { type: 'comm__namedPage', attributes: { name: 'Home' }, state };
}

function campaign(overrides = {}) {
    return {
        id: CAMPAIGN_ID,
        name: 'Viaje a Mexico Dreamin´',
        description: 'Descripción',
        imageUrl: null,
        imageAltText: null,
        goal: 1000,
        totalRaised: 500,
        donationCount: 2,
        progressPercent: 50,
        startDate: '2026-10-01',
        endDate: null,
        status: 'Active',
        availability: 'OPEN',
        canDonate: true,
        isGeneral: false,
        ...overrides
    };
}

function createComponent(props = {}) {
    const element = createElement('c-donation-portal', { is: DonationPortal });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
}

async function openAt(state, props) {
    const element = createComponent(props);
    CurrentPageReference.emit(pageReference(state));
    await flushPromises();
    return element;
}

const list = (element) => element.shadowRoot.querySelector('c-campaign-list');
const detail = (element) => element.shadowRoot.querySelector('c-campaign-detail');
const form = (element) => element.shadowRoot.querySelector('c-donation-form');
const history = (element) => element.shadowRoot.querySelector('c-closed-campaign-history');

describe('c-donation-portal', () => {
    beforeEach(() => {
        window.scrollTo = jest.fn();
        getAvailableCampaigns.mockResolvedValue([]);
        getClosedCampaigns.mockResolvedValue([]);
        getCampaignDetail.mockResolvedValue(campaign());
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    describe('initial view from the URL', () => {
        it('shows nothing until the page reference arrives, so there is no flash of the wrong view', async () => {
            const element = createComponent();
            await flushPromises();

            expect(list(element)).toBeNull();
            expect(detail(element)).toBeNull();
            expect(getAvailableCampaigns).not.toHaveBeenCalled();
        });

        it('shows the catalog when the URL has no parameters', async () => {
            const element = await openAt({});

            expect(list(element)).not.toBeNull();
            expect(detail(element)).toBeNull();
            expect(getAvailableCampaigns).toHaveBeenCalledTimes(1);
        });

        it('opens the detail of the campaign in ?campana=<Id> without loading the catalog', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID });

            expect(detail(element).campaignId).toBe(CAMPAIGN_ID);
            expect(list(element)).toBeNull();
            expect(getAvailableCampaigns).not.toHaveBeenCalled();
            expect(getCampaignDetail).toHaveBeenCalledWith({ campaignId: CAMPAIGN_ID });
        });

        it('opens a closed campaign by direct link like any other detail', async () => {
            getCampaignDetail.mockResolvedValue(campaign({ status: 'Closed', availability: 'CLOSED', canDonate: false }));
            const element = await openAt({ campana: CAMPAIGN_ID });

            const badge = detail(element).shadowRoot.querySelector('.badge');
            expect(badge.textContent).toBe('Cerrada');
        });

        it('opens the donation form with ?campana=<Id>&donar=1', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID, donar: '1' });

            expect(form(element).campaignId).toBe(CAMPAIGN_ID);
            expect(detail(element)).toBeNull();
            expect(list(element)).toBeNull();
        });

        it('ignores donar=1 when there is no campaign and shows the catalog', async () => {
            const element = await openAt({ donar: '1' });

            expect(list(element)).not.toBeNull();
            expect(form(element)).toBeNull();
        });

        it('ignores a donar value other than 1', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID, donar: 'true' });

            expect(detail(element)).not.toBeNull();
            expect(form(element)).toBeNull();
        });

        it('trims the campaign Id and accepts a list of values', async () => {
            const withSpaces = await openAt({ campana: `  ${CAMPAIGN_ID}  ` });
            expect(detail(withSpaces).campaignId).toBe(CAMPAIGN_ID);

            CurrentPageReference.emit(pageReference({ campana: [OTHER_CAMPAIGN_ID, CAMPAIGN_ID] }));
            await flushPromises();
            expect(detail(withSpaces).campaignId).toBe(OTHER_CAMPAIGN_ID);
        });

        it('shows the catalog when the campaign parameter is empty', async () => {
            const element = await openAt({ campana: '   ' });

            expect(list(element)).not.toBeNull();
        });
    });

    describe('invalid campaign Id in the URL', () => {
        it('shows the not-found message of the detail instead of failing', async () => {
            getCampaignDetail.mockResolvedValue(null);
            const element = await openAt({ campana: 'no-es-un-id' });

            const message = detail(element).shadowRoot.querySelector('.state__message');
            expect(message.textContent).toContain('No encontramos esta campaña.');
            expect(list(element)).toBeNull();
        });

        it('shows the not-found message for a well formed Id that does not resolve', async () => {
            getCampaignDetail.mockResolvedValue(null);
            const element = await openAt({ campana: 'a00000000000999AAA' });

            expect(detail(element).shadowRoot.textContent).toContain('No encontramos esta campaña.');
        });

        it('returns to the catalog from the not-found message', async () => {
            getCampaignDetail.mockResolvedValue(null);
            const element = await openAt({ campana: 'no-es-un-id' });

            detail(element).shadowRoot.querySelector('.state lightning-button').click();
            await flushPromises();

            expect(__navigateMock).toHaveBeenLastCalledWith(pageReference({}), undefined);
            expect(list(element)).not.toBeNull();
        });

        it('shows a friendly error when the campaign cannot be loaded', async () => {
            getCampaignDetail.mockRejectedValue(new Error('boom'));
            const element = await openAt({ campana: CAMPAIGN_ID });

            const alert = detail(element).shadowRoot.querySelector('[role="alert"]');
            expect(alert.textContent).toContain('No pudimos cargar la campaña.');
            expect(alert.textContent).not.toContain('boom');
        });
    });

    describe('navigation by events', () => {
        it('goes from the catalog to the detail on campaignselect, updating the URL state', async () => {
            const element = await openAt({});

            list(element).dispatchEvent(new CustomEvent('campaignselect', { detail: { campaignId: CAMPAIGN_ID } }));
            await flushPromises();

            expect(__navigateMock).toHaveBeenCalledTimes(1);
            expect(__navigateMock).toHaveBeenCalledWith(pageReference({ campana: CAMPAIGN_ID }), undefined);
            expect(detail(element).campaignId).toBe(CAMPAIGN_ID);
            expect(list(element)).toBeNull();
        });

        it('goes back to the catalog on backtolist and clears the parameters', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID });

            detail(element).dispatchEvent(new CustomEvent('backtolist'));
            await flushPromises();

            expect(__navigateMock).toHaveBeenCalledWith(pageReference({}), undefined);
            expect(list(element)).not.toBeNull();
            expect(detail(element)).toBeNull();
        });

        it('opens the form inside the campaign context on donationstart', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID });

            detail(element).dispatchEvent(
                new CustomEvent('donationstart', {
                    detail: { campaignId: CAMPAIGN_ID, campaignName: 'Viaje a Mexico Dreamin´' }
                })
            );
            await flushPromises();

            expect(__navigateMock).toHaveBeenCalledWith(pageReference({ campana: CAMPAIGN_ID, donar: '1' }), undefined);
            expect(form(element).campaignId).toBe(CAMPAIGN_ID);
            expect(form(element).campaignName).toBe('Viaje a Mexico Dreamin´');
            expect(detail(element)).toBeNull();
        });

        it('goes back from the form to the detail of the same campaign', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID, donar: '1' });

            form(element).dispatchEvent(new CustomEvent('backtocampaign'));
            await flushPromises();

            expect(__navigateMock).toHaveBeenCalledWith(pageReference({ campana: CAMPAIGN_ID }), undefined);
            expect(detail(element).campaignId).toBe(CAMPAIGN_ID);
            expect(form(element)).toBeNull();
        });

        it('does not know the campaign name when the form is opened by a direct link', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID, donar: '1' });

            expect(form(element).campaignName).toBe('');
        });

        it('does not reuse the name of another campaign in the form', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID });
            detail(element).dispatchEvent(
                new CustomEvent('donationstart', { detail: { campaignId: CAMPAIGN_ID, campaignName: 'Campaña A' } })
            );
            await flushPromises();

            CurrentPageReference.emit(pageReference({ campana: OTHER_CAMPAIGN_ID, donar: '1' }));
            await flushPromises();

            expect(form(element).campaignName).toBe('');
        });

        it('uses the configured page name when navigating', async () => {
            const element = await openAt({}, { pageName: 'Portal' });

            list(element).dispatchEvent(new CustomEvent('campaignselect', { detail: { campaignId: CAMPAIGN_ID } }));

            expect(__navigateMock.mock.calls[0][0].attributes.name).toBe('Portal');
        });

        it('falls back to the Home page when the page name is empty', async () => {
            const element = await openAt({}, { pageName: '' });

            list(element).dispatchEvent(new CustomEvent('campaignselect', { detail: { campaignId: CAMPAIGN_ID } }));

            expect(__navigateMock.mock.calls[0][0].attributes.name).toBe('Home');
        });

        it('navigates through the router and never reloads the page', async () => {
            const originalLocation = window.location;
            delete window.location;
            window.location = { assign: jest.fn(), replace: jest.fn(), reload: jest.fn() };
            const element = await openAt({});

            list(element).dispatchEvent(new CustomEvent('campaignselect', { detail: { campaignId: CAMPAIGN_ID } }));
            await flushPromises();

            expect(window.location.assign).not.toHaveBeenCalled();
            expect(window.location.replace).not.toHaveBeenCalled();
            expect(window.location.reload).not.toHaveBeenCalled();
            window.location = originalLocation;
        });
    });

    describe('history of closed campaigns (DON-05)', () => {
        const closedCampaign = (overrides = {}) =>
            campaign({ status: 'Closed', availability: 'CLOSED', canDonate: false, ...overrides });

        it('shows the history at ?vista=historial without loading the catalog or any detail', async () => {
            getClosedCampaigns.mockResolvedValue([closedCampaign()]);
            const element = await openAt({ vista: 'historial' });

            expect(history(element)).not.toBeNull();
            expect(list(element)).toBeNull();
            expect(detail(element)).toBeNull();
            expect(getAvailableCampaigns).not.toHaveBeenCalled();
            expect(getClosedCampaigns).toHaveBeenCalledTimes(1);
            expect(history(element).shadowRoot.querySelectorAll('article.card')).toHaveLength(1);
        });

        it('goes from the catalog to the history on showhistory, updating the URL state', async () => {
            const element = await openAt({});

            list(element).dispatchEvent(new CustomEvent('showhistory'));
            await flushPromises();

            expect(__navigateMock).toHaveBeenCalledTimes(1);
            expect(__navigateMock).toHaveBeenCalledWith(pageReference({ vista: 'historial' }), undefined);
            expect(history(element)).not.toBeNull();
            expect(list(element)).toBeNull();
        });

        it('opens the detail of a closed campaign from the history and keeps donating impossible', async () => {
            getClosedCampaigns.mockResolvedValue([closedCampaign()]);
            getCampaignDetail.mockResolvedValue(closedCampaign());
            const element = await openAt({ vista: 'historial' });

            history(element).dispatchEvent(new CustomEvent('campaignselect', { detail: { campaignId: CAMPAIGN_ID } }));
            await flushPromises();

            expect(__navigateMock).toHaveBeenCalledWith(
                pageReference({ campana: CAMPAIGN_ID, vista: 'historial' }),
                undefined
            );
            expect(history(element)).toBeNull();
            const buttons = Array.from(detail(element).shadowRoot.querySelectorAll('lightning-button'));
            const disabled = buttons.find((button) => button.label === 'Donaciones cerradas');
            expect(disabled.disabled).toBe(true);
            expect(buttons.some((button) => button.label === 'Donar')).toBe(false);
            expect(form(element)).toBeNull();
        });

        it('returns to the catalog from the history', async () => {
            const element = await openAt({ vista: 'historial' });

            history(element).dispatchEvent(new CustomEvent('backtolist'));
            await flushPromises();

            expect(__navigateMock).toHaveBeenLastCalledWith(pageReference({}), undefined);
            expect(list(element)).not.toBeNull();
            expect(history(element)).toBeNull();
        });

        it('follows Back and Forward between catalog, history and detail', async () => {
            const element = await openAt({});

            CurrentPageReference.emit(pageReference({ vista: 'historial' }));
            await flushPromises();
            expect(history(element)).not.toBeNull();

            CurrentPageReference.emit(pageReference({ campana: CAMPAIGN_ID }));
            await flushPromises();
            expect(detail(element)).not.toBeNull();

            // Back: detail -> history -> catalog
            CurrentPageReference.emit(pageReference({ vista: 'historial' }));
            await flushPromises();
            expect(history(element)).not.toBeNull();
            CurrentPageReference.emit(pageReference({}));
            await flushPromises();
            expect(list(element)).not.toBeNull();

            // Forward: catalog -> history
            CurrentPageReference.emit(pageReference({ vista: 'historial' }));
            await flushPromises();
            expect(history(element)).not.toBeNull();
        });

        it('lets a campaign in the URL win over the history parameter', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID, vista: 'historial' });

            expect(detail(element).campaignId).toBe(CAMPAIGN_ID);
            expect(history(element)).toBeNull();
        });

        it('shows the catalog for any other value of the view parameter and accepts a list of values', async () => {
            const element = await openAt({ vista: 'otra' });
            expect(list(element)).not.toBeNull();
            expect(history(element)).toBeNull();

            CurrentPageReference.emit(pageReference({ vista: ['historial', 'otra'] }));
            await flushPromises();
            expect(history(element)).not.toBeNull();
        });

        it('scrolls to the top when the view changes to the history', async () => {
            const element = await openAt({});
            window.scrollTo.mockClear();

            list(element).dispatchEvent(new CustomEvent('showhistory'));
            await flushPromises();

            expect(window.scrollTo).toHaveBeenCalledWith(0, 0);
        });
    });

    describe('back button of the detail respects where it was opened from (DON-05)', () => {
        const closedCampaign = () => campaign({ status: 'Closed', availability: 'CLOSED', canDonate: false });
        const backFromDetail = async (element) => {
            detail(element).dispatchEvent(new CustomEvent('backtolist'));
            await flushPromises();
        };
        const select = async (element, source, campaignId = CAMPAIGN_ID) => {
            source(element).dispatchEvent(new CustomEvent('campaignselect', { detail: { campaignId } }));
            await flushPromises();
        };
        const lastState = () => __navigateMock.mock.calls[__navigateMock.mock.calls.length - 1][0].state;

        beforeEach(() => {
            getClosedCampaigns.mockResolvedValue([closedCampaign()]);
            getCampaignDetail.mockResolvedValue(closedCampaign());
        });

        it('opens a campaign from the history with the history context and goes back to the history', async () => {
            const element = await openAt({ vista: 'historial' });

            await select(element, history);
            expect(__navigateMock).toHaveBeenLastCalledWith(
                pageReference({ campana: CAMPAIGN_ID, vista: 'historial' }),
                undefined
            );
            expect(detail(element).campaignId).toBe(CAMPAIGN_ID);
            expect(history(element)).toBeNull();

            await backFromDetail(element);
            expect(__navigateMock).toHaveBeenLastCalledWith(pageReference({ vista: 'historial' }), undefined);
            expect(Object.keys(lastState())).toEqual(['vista']);
            expect(history(element)).not.toBeNull();
            expect(detail(element)).toBeNull();
            expect(list(element)).toBeNull();
        });

        it('opens a campaign from the catalog without the history context and goes back to the catalog', async () => {
            const element = await openAt({});

            await select(element, list);
            expect(__navigateMock).toHaveBeenLastCalledWith(pageReference({ campana: CAMPAIGN_ID }), undefined);
            expect(Object.keys(lastState())).toEqual(['campana']);

            await backFromDetail(element);
            expect(__navigateMock).toHaveBeenLastCalledWith(pageReference({}), undefined);
            expect(Object.keys(lastState())).toEqual([]);
            expect(list(element)).not.toBeNull();
            expect(history(element)).toBeNull();
            expect(detail(element)).toBeNull();
        });

        it('goes back to the catalog from a direct link without context', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID });
            expect(detail(element)).not.toBeNull();

            await backFromDetail(element);

            expect(__navigateMock).toHaveBeenLastCalledWith(pageReference({}), undefined);
            expect(list(element)).not.toBeNull();
            expect(history(element)).toBeNull();
        });

        it('goes back to the history from a direct link that carries the history context', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID, vista: 'historial' });
            expect(detail(element).campaignId).toBe(CAMPAIGN_ID);
            expect(history(element)).toBeNull();

            await backFromDetail(element);

            expect(__navigateMock).toHaveBeenLastCalledWith(pageReference({ vista: 'historial' }), undefined);
            expect(history(element)).not.toBeNull();
        });

        it('lets the campaign win over the view parameter when both are present', async () => {
            const element = await openAt({ vista: 'historial', campana: CAMPAIGN_ID });

            expect(detail(element).campaignId).toBe(CAMPAIGN_ID);
            expect(history(element)).toBeNull();
            expect(list(element)).toBeNull();
            expect(form(element)).toBeNull();
        });

        it('keeps the origin of each opening when the visitor goes back and opens another campaign', async () => {
            const element = await openAt({ vista: 'historial' });

            await select(element, history, CAMPAIGN_ID);
            await backFromDetail(element);
            await select(element, history, OTHER_CAMPAIGN_ID);
            expect(lastState()).toEqual({ campana: OTHER_CAMPAIGN_ID, vista: 'historial' });
            await backFromDetail(element);

            expect(lastState()).toEqual({ vista: 'historial' });
            expect(history(element)).not.toBeNull();
            // The catalog is a different origin: it never inherits the history context.
            history(element).dispatchEvent(new CustomEvent('backtolist'));
            await flushPromises();
            expect(lastState()).toEqual({});
            await select(element, list);
            expect(lastState()).toEqual({ campana: CAMPAIGN_ID });
        });

        it('follows browser Back and Forward through history, detail and catalog keeping the context', async () => {
            const element = await openAt({});

            await select(element, list); // catalog -> detail (no context)
            CurrentPageReference.emit(pageReference({}));
            await flushPromises();
            expect(list(element)).not.toBeNull();

            CurrentPageReference.emit(pageReference({ vista: 'historial' })); // catalog -> history
            await flushPromises();
            expect(history(element)).not.toBeNull();

            CurrentPageReference.emit(pageReference({ campana: CAMPAIGN_ID, vista: 'historial' })); // -> detail
            await flushPromises();
            expect(detail(element)).not.toBeNull();

            // Back: detail -> history -> catalog
            CurrentPageReference.emit(pageReference({ vista: 'historial' }));
            await flushPromises();
            expect(history(element)).not.toBeNull();
            expect(detail(element)).toBeNull();
            CurrentPageReference.emit(pageReference({}));
            await flushPromises();
            expect(list(element)).not.toBeNull();
            expect(history(element)).toBeNull();

            // Forward: catalog -> history -> detail, and its back button still returns to the history
            CurrentPageReference.emit(pageReference({ vista: 'historial' }));
            await flushPromises();
            CurrentPageReference.emit(pageReference({ campana: CAMPAIGN_ID, vista: 'historial' }));
            await flushPromises();
            expect(detail(element).campaignId).toBe(CAMPAIGN_ID);
            await backFromDetail(element);
            expect(lastState()).toEqual({ vista: 'historial' });
            expect(history(element)).not.toBeNull();
        });

        it('never sends repeated or unexpected parameters in a full round trip', async () => {
            const element = await openAt({});

            list(element).dispatchEvent(new CustomEvent('showhistory'));
            await flushPromises();
            await select(element, history);
            await backFromDetail(element);
            history(element).dispatchEvent(new CustomEvent('backtolist'));
            await flushPromises();
            await select(element, list);
            await backFromDetail(element);

            const sent = __navigateMock.mock.calls.map(([reference]) => Object.keys(reference.state).sort().join(','));
            expect(sent).toEqual(['vista', 'campana,vista', 'vista', '', 'campana', '']);
            __navigateMock.mock.calls.forEach(([reference]) => {
                expect(reference.attributes).toEqual({ name: 'Home' });
                Object.values(reference.state).forEach((value) => expect(Array.isArray(value)).toBe(false));
            });
            expect(list(element)).not.toBeNull();
        });

        it('keeps the history context through the donation form of a campaign opened with it', async () => {
            getCampaignDetail.mockResolvedValue(campaign());
            const element = await openAt({ campana: CAMPAIGN_ID, vista: 'historial' });

            detail(element).dispatchEvent(
                new CustomEvent('donationstart', { detail: { campaignId: CAMPAIGN_ID, campaignName: 'Viaje' } })
            );
            await flushPromises();
            expect(lastState()).toEqual({ campana: CAMPAIGN_ID, vista: 'historial', donar: '1' });
            expect(form(element)).not.toBeNull();

            form(element).dispatchEvent(new CustomEvent('backtocampaign'));
            await flushPromises();
            expect(lastState()).toEqual({ campana: CAMPAIGN_ID, vista: 'historial' });

            await backFromDetail(element);
            expect(lastState()).toEqual({ vista: 'historial' });
            expect(history(element)).not.toBeNull();
        });
    });

    describe('"Ver campañas disponibles" of the not-found state always leads to the catalog (DON-05)', () => {
        const lastState = () => __navigateMock.mock.calls[__navigateMock.mock.calls.length - 1][0].state;
        const clickViewCatalog = async (element) => {
            const button = detail(element).shadowRoot.querySelector('.state lightning-button');
            expect(button.label).toBe('Ver campañas disponibles');
            button.click();
            await flushPromises();
        };
        const clickGenericBack = async (element) => {
            detail(element).shadowRoot.querySelector('.detail__back lightning-button').click();
            await flushPromises();
        };

        beforeEach(() => {
            getCampaignDetail.mockResolvedValue(null);
        });

        it('goes to the catalog when the campaign does not exist and the URL carries the history context', async () => {
            const element = await openAt({ campana: 'a00000000000999AAA', vista: 'historial' });
            expect(detail(element).shadowRoot.textContent).toContain('No encontramos esta campaña.');

            await clickViewCatalog(element);

            expect(__navigateMock).toHaveBeenLastCalledWith(pageReference({}), undefined);
            expect(Object.keys(lastState())).toEqual([]);
            expect(list(element)).not.toBeNull();
            expect(history(element)).toBeNull();
            expect(detail(element)).toBeNull();
        });

        it('goes to the catalog when the campaign does not exist and there is no history context', async () => {
            const element = await openAt({ campana: 'no-es-un-id' });

            await clickViewCatalog(element);

            expect(__navigateMock).toHaveBeenLastCalledWith(pageReference({}), undefined);
            expect(Object.keys(lastState())).toEqual([]);
            expect(list(element)).not.toBeNull();
            expect(history(element)).toBeNull();
        });

        it('leaves neither campana nor vista in the state when it returns to the catalog', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID, vista: 'historial' });

            detail(element).dispatchEvent(new CustomEvent('viewcatalog'));
            await flushPromises();

            expect(lastState()).toEqual({});
            expect(lastState()).not.toHaveProperty('campana');
            expect(lastState()).not.toHaveProperty('vista');
            expect(__navigateMock).toHaveBeenCalledTimes(1);
            expect(list(element)).not.toBeNull();
        });

        it('keeps "Volver a las campañas" going back to the history from a detail opened in the history', async () => {
            getClosedCampaigns.mockResolvedValue([campaign({ status: 'Closed', availability: 'CLOSED', canDonate: false })]);
            getCampaignDetail.mockResolvedValue(campaign({ status: 'Closed', availability: 'CLOSED', canDonate: false }));
            const element = await openAt({ vista: 'historial' });
            history(element).dispatchEvent(new CustomEvent('campaignselect', { detail: { campaignId: CAMPAIGN_ID } }));
            await flushPromises();
            expect(lastState()).toEqual({ campana: CAMPAIGN_ID, vista: 'historial' });

            await clickGenericBack(element);

            expect(lastState()).toEqual({ vista: 'historial' });
            expect(history(element)).not.toBeNull();
            expect(list(element)).toBeNull();
        });

        it('keeps "Volver a las campañas" going back to the catalog from a detail opened in the catalog', async () => {
            getCampaignDetail.mockResolvedValue(campaign());
            const element = await openAt({});
            list(element).dispatchEvent(new CustomEvent('campaignselect', { detail: { campaignId: CAMPAIGN_ID } }));
            await flushPromises();
            expect(lastState()).toEqual({ campana: CAMPAIGN_ID });

            await clickGenericBack(element);

            expect(lastState()).toEqual({});
            expect(list(element)).not.toBeNull();
            expect(history(element)).toBeNull();
        });

        it('keeps the generic back button on the history for a not-found campaign with the history context', async () => {
            const element = await openAt({ campana: 'a00000000000999AAA', vista: 'historial' });

            await clickGenericBack(element);

            expect(lastState()).toEqual({ vista: 'historial' });
            expect(history(element)).not.toBeNull();
        });
    });

    describe('browser Back and Forward', () => {
        it('follows the page reference when the history moves between views', async () => {
            const element = await openAt({});
            expect(list(element)).not.toBeNull();

            CurrentPageReference.emit(pageReference({ campana: CAMPAIGN_ID }));
            await flushPromises();
            expect(detail(element)).not.toBeNull();

            CurrentPageReference.emit(pageReference({ campana: CAMPAIGN_ID, donar: '1' }));
            await flushPromises();
            expect(form(element)).not.toBeNull();

            // Back, Back
            CurrentPageReference.emit(pageReference({ campana: CAMPAIGN_ID }));
            await flushPromises();
            expect(detail(element)).not.toBeNull();
            CurrentPageReference.emit(pageReference({}));
            await flushPromises();
            expect(list(element)).not.toBeNull();

            // Forward
            CurrentPageReference.emit(pageReference({ campana: CAMPAIGN_ID }));
            await flushPromises();
            expect(detail(element).campaignId).toBe(CAMPAIGN_ID);
        });

        it('shows the other campaign when Back leads to a different detail', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID });
            getCampaignDetail.mockResolvedValue(campaign({ id: OTHER_CAMPAIGN_ID, name: 'Otra campaña' }));

            CurrentPageReference.emit(pageReference({ campana: OTHER_CAMPAIGN_ID }));
            await flushPromises();

            expect(detail(element).campaignId).toBe(OTHER_CAMPAIGN_ID);
            expect(detail(element).shadowRoot.querySelector('h1').textContent).toBe('Otra campaña');
        });
    });

    describe('scroll', () => {
        it('does not scroll on the first render', async () => {
            await openAt({ campana: CAMPAIGN_ID });

            expect(window.scrollTo).not.toHaveBeenCalled();
        });

        it('scrolls to the top when the view changes and not when only the campaign changes', async () => {
            await openAt({});

            CurrentPageReference.emit(pageReference({ campana: CAMPAIGN_ID }));
            await flushPromises();
            expect(window.scrollTo).toHaveBeenCalledTimes(1);
            expect(window.scrollTo).toHaveBeenCalledWith(0, 0);

            CurrentPageReference.emit(pageReference({ campana: OTHER_CAMPAIGN_ID }));
            await flushPromises();
            expect(window.scrollTo).toHaveBeenCalledTimes(1);
        });
    });

    describe('safety of the public site', () => {
        it('never turns on the recognition demo mode', async () => {
            const element = await openAt({ campana: CAMPAIGN_ID });

            expect(detail(element).demoMode).toBeFalsy();
        });
    });
});
