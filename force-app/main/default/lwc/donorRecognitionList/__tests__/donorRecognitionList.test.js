import { createElement } from 'lwc';
import DonorRecognitionList from 'c/donorRecognitionList';
import getDonorRecognition from '@salesforce/apex/DonorRecognitionService.getDonorRecognition';

jest.mock(
    '@salesforce/apex/DonorRecognitionService.getDonorRecognition',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));
const normalize = (text) => text.replace(/\s+/g, ' ').trim();

function createComponent(props = {}) {
    const element = createElement('c-donor-recognition-list', { is: DonorRecognitionList });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
}

function manyDonors(count) {
    return Array.from({ length: count }, (value, index) => ({ publicName: `Donante ${index + 1}`, amount: 100 }));
}

describe('c-donor-recognition-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('lists the public donors with their name and amount in MXN', async () => {
        getDonorRecognition.mockResolvedValue([
            { publicName: 'Familia Pérez', amount: 500 },
            { publicName: 'Ana López', amount: 1000 }
        ]);
        const element = createComponent({ campaignId: 'a00000000000001AAA' });
        await flushPromises();

        const items = element.shadowRoot.querySelectorAll('.donor');
        expect(getDonorRecognition).toHaveBeenCalledWith({ campaignId: 'a00000000000001AAA' });
        expect(items).toHaveLength(2);
        expect(items[0].querySelector('.donor__name').textContent).toBe('Familia Pérez');
        expect(normalize(items[0].querySelector('.donor__amount').textContent)).toBe('$500 MXN');
        expect(normalize(items[1].querySelector('.donor__amount').textContent)).toBe('$1,000 MXN');
    });

    it('shows a donor name that contains HTML as harmless text', async () => {
        getDonorRecognition.mockResolvedValue([{ publicName: '<script>alert(1)</script>', amount: 100 }]);
        const element = createComponent({ campaignId: 'a00000000000001AAA' });
        await flushPromises();

        expect(element.shadowRoot.querySelector('.donor__name').textContent).toBe('<script>alert(1)</script>');
        expect(element.shadowRoot.querySelector('script')).toBeNull();
    });

    it('shows a message when there are no public donors', async () => {
        getDonorRecognition.mockResolvedValue([]);
        const element = createComponent({ campaignId: 'a00000000000001AAA' });
        await flushPromises();

        expect(element.shadowRoot.querySelector('.donors')).toBeNull();
        expect(element.shadowRoot.querySelector('[role="status"]').textContent).toBe(
            'Aún no hay donantes con reconocimiento público en esta campaña.'
        );
    });

    it('shows a Spanish error and retries on request', async () => {
        getDonorRecognition.mockRejectedValueOnce({ body: { message: 'System.QueryException: technical detail' } });
        getDonorRecognition.mockResolvedValueOnce([{ publicName: 'Ana López', amount: 100 }]);
        const element = createComponent({ campaignId: 'a00000000000001AAA' });
        await flushPromises();

        const alert = element.shadowRoot.querySelector('[role="alert"]');
        expect(alert.textContent).toContain('No pudimos cargar el reconocimiento de donantes.');
        expect(alert.textContent).not.toContain('QueryException');

        element.shadowRoot.querySelector('[role="alert"] lightning-button').click();
        await flushPromises();

        expect(getDonorRecognition).toHaveBeenCalledTimes(2);
        expect(element.shadowRoot.querySelectorAll('.donor')).toHaveLength(1);
    });

    it('does not call the server without a campaign', async () => {
        const element = createComponent();
        await flushPromises();

        expect(getDonorRecognition).not.toHaveBeenCalled();
        expect(element.shadowRoot.querySelector('[role="status"]')).not.toBeNull();
    });

    it('reloads when the campaign changes', async () => {
        getDonorRecognition.mockResolvedValue([]);
        const element = createComponent({ campaignId: 'a00000000000001AAA' });
        await flushPromises();

        element.campaignId = 'a00000000000002AAA';
        await flushPromises();

        expect(getDonorRecognition).toHaveBeenLastCalledWith({ campaignId: 'a00000000000002AAA' });
        expect(getDonorRecognition).toHaveBeenCalledTimes(2);
    });

    it('ignores a slow answer for a campaign that is no longer shown', async () => {
        let resolveFirst;
        getDonorRecognition.mockImplementationOnce(() => new Promise((resolve) => (resolveFirst = resolve)));
        getDonorRecognition.mockResolvedValueOnce([{ publicName: 'Donante nuevo', amount: 100 }]);
        const element = createComponent({ campaignId: 'a00000000000001AAA' });
        element.campaignId = 'a00000000000002AAA';
        await flushPromises();

        resolveFirst([{ publicName: 'Donante viejo', amount: 100 }]);
        await flushPromises();

        const names = Array.from(element.shadowRoot.querySelectorAll('.donor__name')).map((node) => node.textContent);
        expect(names).toEqual(['Donante nuevo']);
    });

    it('shows ten donors first and the rest on request', async () => {
        getDonorRecognition.mockResolvedValue(manyDonors(12));
        const element = createComponent({ campaignId: 'a00000000000001AAA' });
        await flushPromises();
        expect(element.shadowRoot.querySelectorAll('.donor')).toHaveLength(10);

        element.shadowRoot.querySelector('.more lightning-button').click();
        await flushPromises();

        expect(element.shadowRoot.querySelectorAll('.donor')).toHaveLength(12);
        expect(element.shadowRoot.querySelector('.more')).toBeNull();
    });

    it('is not in demo mode by default', async () => {
        getDonorRecognition.mockResolvedValue([]);
        const element = createComponent({ campaignId: 'a00000000000001AAA' });
        await flushPromises();

        expect(element.shadowRoot.querySelector('.demo')).toBeNull();
    });

    it('shows clearly labeled fictitious donors in demo mode without calling the server', async () => {
        const element = createComponent({ demoMode: true, campaignId: 'a00000000000001AAA' });
        await flushPromises();

        expect(getDonorRecognition).not.toHaveBeenCalled();
        const demo = element.shadowRoot.querySelector('.demo');
        expect(demo.textContent).toContain('Vista de demostración');
        expect(demo.textContent).toContain('ficticios');
        expect(element.shadowRoot.querySelectorAll('.donor').length).toBeGreaterThan(0);
    });
});
