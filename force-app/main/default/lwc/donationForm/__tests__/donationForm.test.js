import { createElement } from 'lwc';
import DonationForm from 'c/donationForm';
import startDonation from '@salesforce/apex/DonationIntakeService.startDonation';
import openPayment from '@salesforce/apex/DonationIntakeService.openPayment';

jest.mock('@salesforce/apex/DonationIntakeService.startDonation', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/DonationIntakeService.openPayment', () => ({ default: jest.fn() }), { virtual: true });

const CAMPAIGN_ID = 'a00000000000001AAA';
const ATTEMPT_ID = 'a01000000000001AAA';
const CHECKOUT_URL = 'https://www.mercadopago.com.mx/checkout/v1/redirect?pref_id=TEST';
const PERSON_RFC = 'GODE561231GR8';
const COMPANY_RFC = 'ABC010203XY1';

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));
const normalize = (text) => text.replace(/\s+/g, ' ').trim();

let originalLocation;

function createComponent(props = { campaignId: CAMPAIGN_ID, campaignName: 'Viaje a Mexico Dreamin´' }) {
    const element = createElement('c-donation-form', { is: DonationForm });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
}

const radios = (element) => Array.from(element.shadowRoot.querySelectorAll('input[type="radio"]'));
const field = (element, name) => element.shadowRoot.querySelector(`[data-field="${name}"]`);
const toggle = (element, name) => element.shadowRoot.querySelector(`[data-name="${name}"]`);
const submitButton = (element) => element.shadowRoot.querySelector('.actions__submit');
const errorBanner = (element) => element.shadowRoot.querySelector('.alert[role="alert"]');

async function selectAmount(element, amount) {
    const radio = radios(element).find((item) => item.value === String(amount));
    radio.checked = true;
    radio.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();
}

async function typeInto(element, name, value) {
    const input = field(element, name);
    input.value = value;
    input.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();
    return input;
}

async function chooseRegime(element, value) {
    const combobox = field(element, 'taxRegime');
    combobox.value = value;
    combobox.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    await Promise.resolve();
}

async function setToggle(element, name, checked) {
    const input = toggle(element, name);
    input.checked = checked;
    input.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();
}

async function fillAnonymousDonation(element) {
    await selectAmount(element, 500);
    await typeInto(element, 'email', 'donante@example.com');
}

async function fillInvoice(element, rfc = COMPANY_RFC, regime = '601') {
    await setToggle(element, 'invoice', true);
    await typeInto(element, 'legalName', 'Familia Pérez S.A. de C.V.');
    await typeInto(element, 'rfc', rfc);
    await typeInto(element, 'taxPostalCode', '97000');
    await chooseRegime(element, regime);
}

async function submit(element) {
    submitButton(element).click();
    await flushPromises();
}

describe('c-donation-form', () => {
    beforeEach(() => {
        originalLocation = window.location;
        delete window.location;
        window.location = { assign: jest.fn() };
        startDonation.mockResolvedValue(ATTEMPT_ID);
        openPayment.mockResolvedValue(CHECKOUT_URL);
    });

    afterEach(() => {
        window.location = originalLocation;
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    describe('amount (DON-08)', () => {
        it('shows the eight fixed amounts as independent options, none selected', () => {
            const element = createComponent();

            const labels = Array.from(element.shadowRoot.querySelectorAll('.pill__label')).map((node) =>
                normalize(node.textContent)
            );
            expect(labels).toEqual([
                '$100 MXN',
                '$250 MXN',
                '$500 MXN',
                '$1,000 MXN',
                '$2,000 MXN',
                '$5,000 MXN',
                '$10,000 MXN',
                '$20,000 MXN'
            ]);
            expect(radios(element).every((radio) => !radio.checked)).toBe(true);
            expect(element.shadowRoot.querySelector('select')).toBeNull();
            expect(element.shadowRoot.querySelector('input[type="number"]')).toBeNull();
        });

        it('does not offer $2,500 and groups the options in a labeled fieldset', () => {
            const element = createComponent();

            expect(element.shadowRoot.textContent).not.toContain('2,500');
            expect(element.shadowRoot.querySelector('fieldset legend').textContent).toBe('Elige un monto');
        });

        it('marks only the chosen amount', async () => {
            const element = createComponent();
            await selectAmount(element, 1000);

            const checked = radios(element).filter((radio) => radio.checked);
            expect(checked).toHaveLength(1);
            expect(checked[0].value).toBe('1000');
        });

        it('blocks the payment and asks for an amount when none was chosen', async () => {
            const element = createComponent();
            await typeInto(element, 'email', 'donante@example.com');
            await submit(element);

            expect(element.shadowRoot.querySelector('.field-error').textContent).toBe('Elige un monto para continuar.');
            expect(startDonation).not.toHaveBeenCalled();
        });

        it('clears the amount message once an amount is chosen', async () => {
            const element = createComponent();
            await submit(element);
            expect(element.shadowRoot.querySelector('.field-error')).not.toBeNull();

            await selectAmount(element, 250);

            expect(element.shadowRoot.querySelector('.field-error')).toBeNull();
        });
    });

    describe('email and visibility (DON-10, DON-11)', () => {
        it('starts anonymous, without public name and without invoice fields', () => {
            const element = createComponent();

            expect(toggle(element, 'anonymous').checked).toBe(true);
            expect(field(element, 'publicName')).toBeNull();
            expect(toggle(element, 'invoice').checked).toBe(false);
            expect(field(element, 'rfc')).toBeNull();
        });

        it('labels the invoice option exactly «Solicitar factura» without mentioning CFDI', () => {
            const element = createComponent();

            expect(toggle(element, 'invoice').label).toBe('Solicitar factura');
            expect(element.shadowRoot.textContent).not.toContain('CFDI');
        });

        it('blocks the payment when the email is empty or malformed', async () => {
            const element = createComponent();
            await selectAmount(element, 500);

            await submit(element);
            expect(startDonation).not.toHaveBeenCalled();

            await typeInto(element, 'email', 'sin-arroba');
            await submit(element);
            expect(startDonation).not.toHaveBeenCalled();
        });

        it('only asks for the email when the donation is anonymous without invoice', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);

            expect(startDonation).toHaveBeenCalledTimes(1);
            expect(startDonation.mock.calls[0][0].request).toEqual({
                campaignId: CAMPAIGN_ID,
                amount: 500,
                email: 'donante@example.com',
                visibility: 'Anonymous',
                publicName: null,
                invoiceRequested: false,
                legalName: null,
                rfc: null,
                taxPostalCode: null,
                taxRegime: null
            });
        });

        it('shows the public name field only when the donor chooses recognition', async () => {
            const element = createComponent();
            await setToggle(element, 'anonymous', false);

            const input = field(element, 'publicName');
            expect(input).not.toBeNull();
            expect(input.maxLength).toBe(80);
            expect(input.required).toBe(true);

            await setToggle(element, 'anonymous', true);
            expect(field(element, 'publicName')).toBeNull();
        });

        it('blocks the payment when the public name is empty, only spaces or too long', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await setToggle(element, 'anonymous', false);

            await submit(element);
            await typeInto(element, 'publicName', '     ');
            await submit(element);
            await typeInto(element, 'publicName', 'a'.repeat(81));
            await submit(element);

            expect(startDonation).not.toHaveBeenCalled();
        });

        it('sends a public name with normalized spaces and the Public visibility', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await setToggle(element, 'anonymous', false);
            await typeInto(element, 'publicName', '  Familia   Pérez  ');
            await submit(element);

            const request = startDonation.mock.calls[0][0].request;
            expect(request.visibility).toBe('Public');
            expect(request.publicName).toBe('Familia Pérez');
        });

        it('sends HTML typed in the name as plain text, untouched', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await setToggle(element, 'anonymous', false);
            await typeInto(element, 'publicName', '<script>alert(1)</script>');
            await submit(element);

            expect(startDonation.mock.calls[0][0].request.publicName).toBe('<script>alert(1)</script>');
        });

        it('does not send the name when the donor goes back to anonymous', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await setToggle(element, 'anonymous', false);
            await typeInto(element, 'publicName', 'Familia Pérez');
            await setToggle(element, 'anonymous', true);
            await submit(element);

            const request = startDonation.mock.calls[0][0].request;
            expect(request.visibility).toBe('Anonymous');
            expect(request.publicName).toBeNull();
        });
    });

    describe('invoice (DON-12)', () => {
        it('shows the four fiscal fields only after activating the option', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);

            ['legalName', 'rfc', 'taxPostalCode', 'taxRegime'].forEach((name) => {
                expect(field(element, name)).not.toBeNull();
            });
            expect(field(element, 'legalName').label).toBe('Nombre o razón social');
            expect(field(element, 'taxPostalCode').label).toBe('Código postal fiscal');
            expect(field(element, 'taxRegime').label).toBe('Régimen fiscal');
        });

        it('does not ask for the taxpayer type as an independent field', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);

            expect(field(element, 'taxpayerType')).toBeNull();
        });

        it('turns the RFC into uppercase without spaces while typing', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);

            const input = await typeInto(element, 'rfc', '  gode 561231 gr8 ');

            expect(input.value).toBe(PERSON_RFC);
        });

        it('marks a valid RFC as valid and an invalid one with the agreed message', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);
            const input = field(element, 'rfc');
            const spy = jest.spyOn(input, 'setCustomValidity');

            await typeInto(element, 'rfc', PERSON_RFC);
            expect(spy).toHaveBeenLastCalledWith('');

            await typeInto(element, 'rfc', 'GODE561331GR8');
            expect(spy).toHaveBeenLastCalledWith('El RFC no tiene un formato válido.');
        });

        it('accepts the two RFC examples of the story', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element, PERSON_RFC, '612');
            await submit(element);
            expect(startDonation).toHaveBeenCalledTimes(1);
        });

        it('blocks RFCs with month 13, wrong length, letters in the date or special characters', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element, COMPANY_RFC, '601');

            for (const rfc of ['GODE561331GR8', 'GODE56123GR8', 'ABC01020XY1', 'GODE56AB31GR8', 'GODE561231G-8']) {
                await typeInto(element, 'rfc', rfc);
                // A valid regime for the length, so only the RFC can block the payment.
                await chooseRegime(element, rfc.length === 13 ? '612' : '601');
                await submit(element);
                expect(errorBanner(element).textContent).toContain('Revisa los campos marcados');
            }

            expect(startDonation).not.toHaveBeenCalled();
        });

        it('blocks a postal code that is not exactly five digits', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element);

            for (const postalCode of ['1234', '12a45', '123 5']) {
                await typeInto(element, 'taxPostalCode', postalCode);
                await submit(element);
            }

            expect(startDonation).not.toHaveBeenCalled();
        });

        it('blocks the payment when a fiscal field is missing', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await setToggle(element, 'invoice', true);
            await submit(element);

            expect(startDonation).not.toHaveBeenCalled();
            expect(errorBanner(element).textContent).toContain('Revisa los campos marcados');
        });

        it('shows the whole catalog before the RFC says the taxpayer type', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);

            expect(field(element, 'taxRegime').options).toHaveLength(19);
            expect(element.shadowRoot.textContent).not.toContain('Tipo de persona');
        });

        it('shows only person regimes for a 13 character RFC and names the type', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);
            await typeInto(element, 'rfc', PERSON_RFC);

            const values = field(element, 'taxRegime').options.map((option) => option.value);
            expect(values).toHaveLength(13);
            expect(values).toContain('605');
            expect(values).not.toContain('601');
            expect(element.shadowRoot.textContent).toContain('Tipo de persona: Física');
        });

        it('shows only company regimes for a 12 character RFC and names the type', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);
            await typeInto(element, 'rfc', COMPANY_RFC);

            const values = field(element, 'taxRegime').options.map((option) => option.value);
            expect(values).toHaveLength(8);
            expect(values).toContain('601');
            expect(values).not.toContain('605');
            expect(element.shadowRoot.textContent).toContain('Tipo de persona: Moral');
        });

        it('keeps regimes 610 and 626 for both taxpayer types', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);

            for (const rfc of [PERSON_RFC, COMPANY_RFC]) {
                await typeInto(element, 'rfc', rfc);
                const values = field(element, 'taxRegime').options.map((option) => option.value);
                expect(values).toEqual(expect.arrayContaining(['610', '626']));
            }
        });

        it('clears the chosen regime when it no longer matches the taxpayer type', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);
            await typeInto(element, 'rfc', COMPANY_RFC);
            await chooseRegime(element, '601');
            expect(field(element, 'taxRegime').value).toBe('601');

            await typeInto(element, 'rfc', PERSON_RFC);

            expect(field(element, 'taxRegime').value).toBe('');
        });

        it('sends the fiscal data of an anonymous donation: invoice is independent from visibility', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element);
            await submit(element);

            expect(startDonation.mock.calls[0][0].request).toEqual({
                campaignId: CAMPAIGN_ID,
                amount: 500,
                email: 'donante@example.com',
                visibility: 'Anonymous',
                publicName: null,
                invoiceRequested: true,
                legalName: 'Familia Pérez S.A. de C.V.',
                rfc: COMPANY_RFC,
                taxPostalCode: '97000',
                taxRegime: '601'
            });
        });

        it('sends public name and fiscal data together when the donor wants both', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await setToggle(element, 'anonymous', false);
            await typeInto(element, 'publicName', 'Familia Pérez');
            await fillInvoice(element, PERSON_RFC, '612');
            await submit(element);

            const request = startDonation.mock.calls[0][0].request;
            expect(request.visibility).toBe('Public');
            expect(request.publicName).toBe('Familia Pérez');
            expect(request.invoiceRequested).toBe(true);
            expect(request.rfc).toBe(PERSON_RFC);
            expect(request.taxRegime).toBe('612');
        });

        it('does not send fiscal data after the donor turns the invoice off again', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element);
            await setToggle(element, 'invoice', false);
            await submit(element);

            const request = startDonation.mock.calls[0][0].request;
            expect(request.invoiceRequested).toBe(false);
            expect(request.rfc).toBeNull();
            expect(request.legalName).toBeNull();
        });

        it('does not claim that the portal issues an invoice', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);

            expect(element.shadowRoot.textContent).toContain('el portal no emite facturas');
        });
    });

    describe('payment flow', () => {
        it('calls startDonation first, then openPayment with the attempt Id, then redirects', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);

            expect(openPayment).toHaveBeenCalledWith({ attemptId: ATTEMPT_ID });
            expect(startDonation.mock.invocationCallOrder[0]).toBeLessThan(openPayment.mock.invocationCallOrder[0]);
            expect(window.location.assign).toHaveBeenCalledWith(CHECKOUT_URL);
        });

        it('locks the button while the payment is being opened and ignores a second click', async () => {
            let finishStart;
            startDonation.mockReturnValue(new Promise((resolve) => (finishStart = resolve)));
            const element = createComponent();
            await fillAnonymousDonation(element);

            submitButton(element).click();
            await Promise.resolve();
            submitButton(element).click();
            await Promise.resolve();

            expect(submitButton(element).disabled).toBe(true);
            expect(submitButton(element).label).toBe('Abriendo el pago…');
            expect(startDonation).toHaveBeenCalledTimes(1);

            finishStart(ATTEMPT_ID);
            await flushPromises();
            expect(openPayment).toHaveBeenCalledTimes(1);
        });

        it('shows the Spanish message of startDonation and keeps what the donor typed', async () => {
            startDonation.mockRejectedValue({ body: { message: 'Esta campaña ya no acepta donaciones.' } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);

            expect(errorBanner(element).textContent).toContain('Esta campaña ya no acepta donaciones.');
            expect(openPayment).not.toHaveBeenCalled();
            expect(window.location.assign).not.toHaveBeenCalled();
            expect(field(element, 'email').value).toBe('donante@example.com');
            expect(radios(element).find((radio) => radio.checked).value).toBe('500');
            expect(submitButton(element).disabled).toBe(false);
        });

        it('shows the Spanish message of openPayment and does not redirect', async () => {
            openPayment.mockRejectedValue({ body: { message: 'No pudimos abrir el pago, intenta de nuevo' } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);

            expect(errorBanner(element).textContent).toContain('No pudimos abrir el pago, intenta de nuevo');
            expect(window.location.assign).not.toHaveBeenCalled();
            expect(submitButton(element).disabled).toBe(false);
        });

        it('lets the donor try again after an error', async () => {
            startDonation.mockRejectedValueOnce({ body: { message: 'Escribe un correo válido.' } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);
            expect(errorBanner(element)).not.toBeNull();

            await submit(element);

            expect(window.location.assign).toHaveBeenCalledWith(CHECKOUT_URL);
            expect(errorBanner(element)).toBeNull();
        });

        it('shows a friendly text when the error has no message', async () => {
            startDonation.mockRejectedValue(new Error('boom'));
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);

            expect(errorBanner(element).textContent).toContain('No pudimos abrir el pago, intenta de nuevo');
            expect(errorBanner(element).textContent).not.toContain('boom');
        });

        it('shows the server message as text and never as HTML', async () => {
            startDonation.mockRejectedValue({ body: { message: '<img src=x onerror=alert(1)>' } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);

            expect(errorBanner(element).querySelector('img')).toBeNull();
            expect(errorBanner(element).textContent).toContain('<img src=x onerror=alert(1)>');
        });

        it('does not redirect to a URL that is not https', async () => {
            openPayment.mockResolvedValue('javascript:alert(1)');
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);

            expect(window.location.assign).not.toHaveBeenCalled();
            expect(errorBanner(element).textContent).toContain('No pudimos abrir el pago, intenta de nuevo');
        });

        it('unlocks the form when the donor comes back with the browser back button', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);
            expect(submitButton(element).disabled).toBe(true);

            const event = new CustomEvent('pageshow');
            event.persisted = true;
            window.dispatchEvent(event);
            await Promise.resolve();

            expect(submitButton(element).disabled).toBe(false);
        });
    });

    describe('campaign and navigation', () => {
        it('shows the campaign name', () => {
            const element = createComponent();

            expect(element.shadowRoot.querySelector('.form__campaign').textContent).toBe(
                'Campaña: Viaje a Mexico Dreamin´'
            );
        });

        it('explains that a campaign is needed and does not show the form without one', () => {
            const element = createComponent({});

            expect(element.shadowRoot.querySelector('.form')).toBeNull();
            expect(element.shadowRoot.querySelector('[role="status"]').textContent).toContain(
                'No encontramos la campaña'
            );
        });

        it('goes back to the campaign through an event', () => {
            const element = createComponent();
            const handler = jest.fn();
            element.addEventListener('backtocampaign', handler);

            element.shadowRoot.querySelector('.donation__back lightning-button').click();

            expect(handler).toHaveBeenCalledTimes(1);
        });
    });
});
