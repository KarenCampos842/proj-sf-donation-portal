import { createElement } from 'lwc';
import DonationThankYou from 'c/donationThankYou';
import { CurrentPageReference, __navigateMock } from 'lightning/navigation';
import getPaymentResult from '@salesforce/apex/DonationPaymentController.getPaymentResult';

jest.mock('lightning/navigation', () => {
    const { createTestWireAdapter } = require('@salesforce/wire-service-jest-util');
    const CurrentPageReference = createTestWireAdapter(jest.fn());
    const Navigate = Symbol('Navigate');
    const navigateMock = jest.fn();
    const NavigationMixin = (Base) =>
        class extends Base {
            [Navigate](pageReference) {
                navigateMock(pageReference);
            }
        };
    NavigationMixin.Navigate = Navigate;
    return { CurrentPageReference, NavigationMixin, __navigateMock: navigateMock };
});
jest.mock('@salesforce/apex/DonationPaymentController.getPaymentResult', () => ({ default: jest.fn() }), {
    virtual: true
});

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

async function openWith(state, props = {}) {
    const element = createElement('c-donation-thank-you', { is: DonationThankYou });
    Object.assign(element, props);
    document.body.appendChild(element);
    CurrentPageReference.emit({ type: 'comm__namedPage', attributes: { name: 'gracias' }, state });
    await flushPromises();
    return element;
}

const message = (element) => element.shadowRoot.querySelector('.result__message').textContent;
const buttons = (element) =>
    Array.from(element.shadowRoot.querySelectorAll('lightning-button')).map((button) => button.label);

describe('c-donation-thank-you', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('asks the server about the payment using only payment_id', async () => {
        getPaymentResult.mockResolvedValue('Confirmed');
        await openWith({ payment_id: '123456', status: 'approved', external_reference: 'a01000000000001AAA' });

        expect(getPaymentResult).toHaveBeenCalledTimes(1);
        expect(getPaymentResult).toHaveBeenCalledWith({ paymentId: '123456' });
    });

    it('shows the server result and ignores the status written in the URL', async () => {
        getPaymentResult.mockResolvedValue('Rejected');
        const element = await openWith({ payment_id: '123456', status: 'approved' });

        expect(message(element)).toBe('Tu pago fue rechazado y no se registró tu donación.');
        expect(element.shadowRoot.textContent).not.toContain('Recibimos tu aportación');
    });

    it('thanks the donor only when the server confirms the payment', async () => {
        getPaymentResult.mockResolvedValue('Confirmed');
        const element = await openWith({ payment_id: '123456' });

        expect(message(element)).toBe('¡Gracias! Recibimos tu aportación.');
        expect(buttons(element)).toEqual(['Volver a las campañas']);
    });

    it('shows the texts agreed with Workstream A for every state', async () => {
        const expected = {
            Pending: 'Estamos confirmando tu pago. No necesitas pagar otra vez.',
            Rejected: 'Tu pago fue rechazado y no se registró tu donación.',
            Cancelled: 'Tu pago se canceló y no se registró tu donación.',
            NoPayment: 'No se completó el pago; no se registró tu donación.',
            Unknown: 'Aún no podemos confirmar tu pago.'
        };
        for (const [state, text] of Object.entries(expected)) {
            getPaymentResult.mockResolvedValue(state);
            const element = await openWith({ payment_id: '1' });
            expect(message(element)).toBe(text);
            document.body.removeChild(element);
        }
    });

    it('never says rejected, cancelled or confirmed for Pending and Unknown', async () => {
        for (const state of ['Pending', 'Unknown']) {
            getPaymentResult.mockResolvedValue(state);
            const element = await openWith({ payment_id: '1' });
            expect(message(element)).not.toMatch(/rechazad|cancelad|confirmad/i);
            document.body.removeChild(element);
        }
    });

    it('offers a new attempt only when the payment was rejected, cancelled or not completed', async () => {
        for (const state of ['Rejected', 'Cancelled', 'NoPayment']) {
            getPaymentResult.mockResolvedValue(state);
            const element = await openWith({ payment_id: '1' });
            expect(buttons(element)).toContain('Intentar de nuevo');
            document.body.removeChild(element);
        }
        for (const state of ['Confirmed', 'Pending', 'Unknown']) {
            getPaymentResult.mockResolvedValue(state);
            const element = await openWith({ payment_id: '1' });
            expect(buttons(element)).not.toContain('Intentar de nuevo');
            document.body.removeChild(element);
        }
    });

    it('lets the donor check again while the payment is pending, without paying twice', async () => {
        getPaymentResult.mockResolvedValueOnce('Pending').mockResolvedValueOnce('Confirmed');
        const element = await openWith({ payment_id: '1' });
        expect(buttons(element)).toContain('Revisar de nuevo');

        element.shadowRoot.querySelector('lightning-button').click();
        await flushPromises();

        expect(getPaymentResult).toHaveBeenCalledTimes(2);
        expect(message(element)).toBe('¡Gracias! Recibimos tu aportación.');
    });

    it('shows the unknown state when the server fails, without technical detail', async () => {
        getPaymentResult.mockRejectedValue({ body: { message: 'System.QueryException: detalle técnico' } });
        const element = await openWith({ payment_id: '1' });

        expect(message(element)).toBe('Aún no podemos confirmar tu pago.');
        expect(element.shadowRoot.textContent).not.toContain('QueryException');
    });

    it('treats a state it does not know as unknown', async () => {
        getPaymentResult.mockResolvedValue('Approved');
        const element = await openWith({ payment_id: '1' });

        expect(message(element)).toBe('Aún no podemos confirmar tu pago.');
    });

    it('asks the server with the text "null" when the URL has no payment_id, so the answer is NoPayment', async () => {
        getPaymentResult.mockResolvedValue('NoPayment');
        const element = await openWith({});

        expect(getPaymentResult).toHaveBeenCalledWith({ paymentId: 'null' });
        expect(message(element)).toBe('No se completó el pago; no se registró tu donación.');
    });

    it('does not ask twice when the page reference is delivered again', async () => {
        getPaymentResult.mockResolvedValue('Confirmed');
        await openWith({ payment_id: '1' });

        CurrentPageReference.emit({ type: 'comm__namedPage', attributes: { name: 'gracias' }, state: { payment_id: '2' } });
        await flushPromises();

        expect(getPaymentResult).toHaveBeenCalledTimes(1);
    });

    it('goes back to the portal page through the router', async () => {
        getPaymentResult.mockResolvedValue('Rejected');
        const element = await openWith({ payment_id: '1' }, { homePageName: 'Portal' });

        Array.from(element.shadowRoot.querySelectorAll('lightning-button'))
            .find((button) => button.label === 'Intentar de nuevo')
            .click();

        expect(__navigateMock).toHaveBeenCalledWith({ type: 'comm__namedPage', attributes: { name: 'Portal' } });
    });
});
