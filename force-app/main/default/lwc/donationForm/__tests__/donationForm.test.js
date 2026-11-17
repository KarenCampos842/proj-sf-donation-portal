import { createElement } from 'lwc';
import DonationForm from 'c/donationForm';
import startDonation from '@salesforce/apex/DonationIntakeService.startDonation';
import openPayment from '@salesforce/apex/DonationIntakeService.openPayment';
import getAmountSettings from '@salesforce/apex/DonationIntakeService.getAmountSettings';

jest.mock('@salesforce/apex/DonationIntakeService.startDonation', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/DonationIntakeService.openPayment', () => ({ default: jest.fn() }), { virtual: true });
jest.mock(
    '@salesforce/apex/DonationIntakeService.getAmountSettings',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

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

async function setPrivacyNotice(element, checked) {
    const input = field(element, 'privacyNoticeAccepted');
    input.checked = checked;
    input.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();
}

// DON-13: a complete invoice request includes accepting the privacy notice, unless a test says otherwise.
async function fillInvoice(element, rfc = COMPANY_RFC, regime = '601', acceptNotice = true) {
    await setToggle(element, 'invoice', true);
    await typeInto(element, 'legalName', 'Familia Pérez S.A. de C.V.');
    await typeInto(element, 'rfc', rfc);
    await typeInto(element, 'taxPostalCode', '97000');
    await chooseRegime(element, regime);
    if (acceptNotice) {
        await setPrivacyNotice(element, true);
    }
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

    describe('configurable amounts (ADM-13)', () => {
        const pillLabels = (element) =>
            Array.from(element.shadowRoot.querySelectorAll('.pill__label')).map((node) => normalize(node.textContent));

        it('shows the amounts of the configuration, in their order', async () => {
            const element = createComponent();
            getAmountSettings.emit({ minimumAmount: 80, suggestedAmounts: [150, 300, 900] });
            await flushPromises();

            expect(pillLabels(element)).toEqual(['$150 MXN', '$300 MXN', '$900 MXN']);
        });

        it('keeps the amounts of Delivery 1 when the configuration cannot be read', async () => {
            const element = createComponent();
            getAmountSettings.error();
            await flushPromises();

            expect(pillLabels(element)).toHaveLength(8);
            expect(pillLabels(element)[0]).toBe('$100 MXN');
        });

        it('clears a selected amount that the configuration no longer offers', async () => {
            const element = createComponent();
            await selectAmount(element, 250);
            getAmountSettings.emit({ minimumAmount: 50, suggestedAmounts: [500, 1000] });
            await flushPromises();

            expect(radios(element).some((radio) => radio.checked)).toBe(false);
        });
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
                taxRegime: null,
                privacyNoticeAccepted: false
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
                taxRegime: '601',
                privacyNoticeAccepted: true
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
            startDonation.mockRejectedValue({ body: { message: '|Esta campaña ya no acepta donaciones.' } });
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
            openPayment.mockRejectedValue({ body: { message: '|No pudimos abrir el pago, intenta de nuevo' } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);

            expect(errorBanner(element).textContent).toContain('No pudimos abrir el pago, intenta de nuevo');
            expect(window.location.assign).not.toHaveBeenCalled();
            expect(submitButton(element).disabled).toBe(false);
        });

        it('lets the donor try again after an error', async () => {
            startDonation.mockRejectedValueOnce({ body: { message: 'email|Escribe un correo válido.' } });
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
            startDonation.mockRejectedValue({ body: { message: '|<img src=x onerror=alert(1)>' } });
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

    describe('invalid data: fields marked and nothing lost (DON-17)', () => {
        async function fillCompleteDonation(element) {
            await fillAnonymousDonation(element);
            await setToggle(element, 'anonymous', false);
            await typeInto(element, 'publicName', 'Familia Pérez');
            await fillInvoice(element, PERSON_RFC, '612');
        }

        const FIELDS = ['email', 'publicName', 'legalName', 'rfc', 'taxPostalCode', 'taxRegime'];

        function spyOnFields(element) {
            const spies = {};
            FIELDS.forEach((name) => {
                spies[name] = jest.spyOn(field(element, name), 'setCustomValidity');
            });
            return spies;
        }

        it('marks every empty required field with its own message before calling the server', async () => {
            const element = createComponent();
            await selectAmount(element, 500);
            await setToggle(element, 'anonymous', false);
            await setToggle(element, 'invoice', true);
            const spies = spyOnFields(element);

            await submit(element);

            expect(spies.email).toHaveBeenLastCalledWith('Escribe tu correo.');
            expect(spies.publicName).toHaveBeenLastCalledWith('Escribe el nombre con el que quieres aparecer.');
            expect(spies.legalName).toHaveBeenLastCalledWith('Escribe tu nombre o razón social.');
            expect(spies.rfc).toHaveBeenLastCalledWith('Escribe tu RFC.');
            expect(spies.taxPostalCode).toHaveBeenLastCalledWith('Escribe tu código postal fiscal.');
            expect(spies.taxRegime).toHaveBeenLastCalledWith('Selecciona tu régimen fiscal.');
            expect(startDonation).not.toHaveBeenCalled();
            expect(errorBanner(element).textContent).toContain('Revisa los campos marcados');
        });

        it('marks every field with an invalid format and says what to correct', async () => {
            const element = createComponent();
            await selectAmount(element, 500);
            await typeInto(element, 'email', 'sin-arroba');
            await setToggle(element, 'anonymous', false);
            await typeInto(element, 'publicName', 'a'.repeat(81));
            await fillInvoice(element, 'GODE561331GR8', '601');
            await typeInto(element, 'legalName', 'a'.repeat(255));
            await typeInto(element, 'taxPostalCode', '1234');
            const spies = spyOnFields(element);

            await submit(element);

            expect(spies.email).toHaveBeenLastCalledWith('Escribe un correo válido.');
            expect(spies.publicName).toHaveBeenLastCalledWith('El nombre público no puede tener más de 80 caracteres.');
            expect(spies.legalName).toHaveBeenLastCalledWith(
                'El nombre o razón social no puede tener más de 254 caracteres.'
            );
            expect(spies.rfc).toHaveBeenLastCalledWith('El RFC no tiene un formato válido.');
            expect(spies.taxPostalCode).toHaveBeenLastCalledWith('El código postal debe tener 5 dígitos.');
            expect(startDonation).not.toHaveBeenCalled();
        });

        it.each([
            ['email', 'Escribe un correo válido.'],
            ['publicName', 'Escribe el nombre con el que quieres aparecer.'],
            ['legalName', 'El nombre o razón social no puede tener más de 254 caracteres.'],
            ['rfc', 'El RFC no tiene un formato válido.'],
            ['taxPostalCode', 'El código postal debe tener 5 dígitos.'],
            ['taxRegime', 'El régimen fiscal no corresponde al tipo de persona.']
        ])('marks the %s field with the message that the server returns for it', async (name, message) => {
            startDonation.mockRejectedValue({ body: { message: name + '|' + message } });
            const element = createComponent();
            await fillCompleteDonation(element);
            const input = field(element, name);
            const markValidity = jest.spyOn(input, 'setCustomValidity');
            const reportValidity = jest.spyOn(input, 'reportValidity');

            await submit(element);

            expect(markValidity).toHaveBeenLastCalledWith(message);
            expect(reportValidity).toHaveBeenCalled();
            expect(errorBanner(element).textContent).toContain('Revisa los campos marcados');
            expect(errorBanner(element).textContent).not.toContain('|');
            expect(openPayment).not.toHaveBeenCalled();
            expect(submitButton(element).disabled).toBe(false);
        });

        it('shows the amount message that the server returns next to the amount options', async () => {
            startDonation.mockRejectedValue({ body: { message: 'amount|El monto elegido no es válido.' } });
            const element = createComponent();
            await fillAnonymousDonation(element);

            await submit(element);

            expect(element.shadowRoot.querySelector('.field-error').textContent).toBe('El monto elegido no es válido.');
            expect(radios(element).find((radio) => radio.checked).value).toBe('500');
            expect(errorBanner(element).textContent).toContain('Revisa los campos marcados');
        });

        it('keeps an error that belongs to no field in the general notice and marks no field', async () => {
            startDonation.mockRejectedValue({ body: { message: '|Esta campaña ya no acepta donaciones.' } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            const markValidity = jest.spyOn(field(element, 'email'), 'setCustomValidity');

            await submit(element);

            expect(errorBanner(element).textContent).toContain('Esta campaña ya no acepta donaciones.');
            expect(markValidity).not.toHaveBeenCalledWith('Esta campaña ya no acepta donaciones.');
            expect(markValidity).toHaveBeenLastCalledWith('');
        });

        it('shows the message in the general notice when its field is not on the screen', async () => {
            startDonation.mockRejectedValue({ body: { message: 'rfc|El RFC no tiene un formato válido.' } });
            const element = createComponent();
            await fillAnonymousDonation(element);

            await submit(element);

            expect(errorBanner(element).textContent).toContain('El RFC no tiene un formato válido.');
        });

        it('keeps everything the donor typed after the server marks one field', async () => {
            startDonation.mockRejectedValue({ body: { message: 'rfc|El RFC no tiene un formato válido.' } });
            const element = createComponent();
            await fillCompleteDonation(element);

            await submit(element);

            expect(radios(element).find((radio) => radio.checked).value).toBe('500');
            expect(field(element, 'email').value).toBe('donante@example.com');
            expect(toggle(element, 'anonymous').checked).toBe(false);
            expect(field(element, 'publicName').value).toBe('Familia Pérez');
            expect(toggle(element, 'invoice').checked).toBe(true);
            expect(field(element, 'legalName').value).toBe('Familia Pérez S.A. de C.V.');
            expect(field(element, 'rfc').value).toBe(PERSON_RFC);
            expect(field(element, 'taxPostalCode').value).toBe('97000');
            expect(field(element, 'taxRegime').value).toBe('612');
            expect(submitButton(element).disabled).toBe(false);
        });

        it('lets the donor correct only the marked field and then pay with the same data', async () => {
            startDonation.mockRejectedValueOnce({
                body: { message: 'taxPostalCode|El código postal debe tener 5 dígitos.' }
            });
            const element = createComponent();
            await fillCompleteDonation(element);
            await submit(element);
            expect(errorBanner(element)).not.toBeNull();

            const markValidity = jest.spyOn(field(element, 'taxPostalCode'), 'setCustomValidity');
            await typeInto(element, 'taxPostalCode', '97010');
            expect(markValidity).toHaveBeenLastCalledWith('');

            await submit(element);

            expect(startDonation).toHaveBeenCalledTimes(2);
            expect(startDonation.mock.calls[1][0].request).toEqual({
                campaignId: CAMPAIGN_ID,
                amount: 500,
                email: 'donante@example.com',
                visibility: 'Public',
                publicName: 'Familia Pérez',
                invoiceRequested: true,
                legalName: 'Familia Pérez S.A. de C.V.',
                rfc: PERSON_RFC,
                taxPostalCode: '97010',
                taxRegime: '612',
                privacyNoticeAccepted: true
            });
            expect(window.location.assign).toHaveBeenCalledWith(CHECKOUT_URL);
            expect(errorBanner(element)).toBeNull();
        });

        it.each([
            [
                'an Apex exception',
                'System.NullPointerException: Attempt to de-reference a null object (Class.DonationIntakeService.startDonation: line 12)'
            ],
            ['an access error of the platform', 'You do not have access to the Apex class named DonationIntakeService.'],
            ['a message that carries the donor email', 'FIELD_CUSTOM_VALIDATION_EXCEPTION|donante@example.com'],
            ['a Spanish text without the shape of the server', 'Esta campaña ya no acepta donaciones.'],
            ['a field name that the form does not have', 'password|Escribe un correo válido.']
        ])('shows only a friendly text for %s and keeps the data', async (scenario, technicalMessage) => {
            startDonation.mockRejectedValue({ body: { message: technicalMessage } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            const markValidity = jest.spyOn(field(element, 'email'), 'setCustomValidity');

            await submit(element);

            const text = errorBanner(element).querySelector('.alert__message').textContent;
            expect(text).toBe('No pudimos abrir el pago, intenta de nuevo');
            expect(element.shadowRoot.textContent).not.toContain(technicalMessage);
            expect(element.shadowRoot.textContent).not.toContain('Exception');
            expect(element.shadowRoot.textContent).not.toContain('Class.');
            expect(markValidity).toHaveBeenLastCalledWith('');
            expect(field(element, 'email').value).toBe('donante@example.com');
            expect(radios(element).find((radio) => radio.checked).value).toBe('500');
            expect(window.location.assign).not.toHaveBeenCalled();
        });

        it('shows only a friendly text when openPayment fails with a technical error', async () => {
            openPayment.mockRejectedValue({ body: { message: 'Callout exception: endpoint https://api.mercadopago.com' } });
            const element = createComponent();
            await fillAnonymousDonation(element);

            await submit(element);

            expect(errorBanner(element).querySelector('.alert__message').textContent).toBe(
                'No pudimos abrir el pago, intenta de nuevo'
            );
            expect(element.shadowRoot.textContent).not.toContain('mercadopago.com');
            expect(window.location.assign).not.toHaveBeenCalled();
            expect(submitButton(element).disabled).toBe(false);
        });
    });

    describe('errors update while the donor edits (DON-17)', () => {
        const FIX_NOTICE = 'Revisa los campos marcados';

        const validity = (element, name) => jest.spyOn(field(element, name), 'setCustomValidity');
        const report = (element, name) => jest.spyOn(field(element, name), 'reportValidity');
        const noticeText = (element) => (errorBanner(element) ? errorBanner(element).textContent : '');

        it('shows the general notice after trying to continue with invalid fields', async () => {
            const element = createComponent();
            await selectAmount(element, 500);

            await submit(element);

            expect(noticeText(element)).toContain(FIX_NOTICE);
            expect(startDonation).not.toHaveBeenCalled();
        });

        it('clears the error of a field as soon as its value is corrected, without a blur', async () => {
            const element = createComponent();
            await selectAmount(element, 500);
            await submit(element);
            const markValidity = validity(element, 'email');
            const showValidity = report(element, 'email');

            await typeInto(element, 'email', 'donante@example.com');

            expect(markValidity).toHaveBeenLastCalledWith('');
            expect(showValidity).toHaveBeenCalled();
        });

        it('keeps the error of a field while its value is still invalid', async () => {
            const element = createComponent();
            await selectAmount(element, 500);
            await submit(element);
            const markValidity = validity(element, 'email');
            const showValidity = report(element, 'email');

            await typeInto(element, 'email', 'sin-arroba');

            expect(markValidity).toHaveBeenLastCalledWith('Escribe un correo válido.');
            expect(showValidity).toHaveBeenCalled();
            expect(noticeText(element)).toContain(FIX_NOTICE);
        });

        it('does not show an error for a field that was never validated', async () => {
            const element = createComponent();
            await selectAmount(element, 500);
            await setToggle(element, 'anonymous', false);
            await setToggle(element, 'invoice', true);
            const showEmail = report(element, 'email');
            const showName = report(element, 'publicName');
            const showRfc = report(element, 'rfc');
            const markRfc = validity(element, 'rfc');

            await typeInto(element, 'email', 'sin-arroba');
            await typeInto(element, 'publicName', '   ');
            await typeInto(element, 'rfc', 'GODE5612');

            expect(showEmail).not.toHaveBeenCalled();
            expect(showName).not.toHaveBeenCalled();
            expect(showRfc).not.toHaveBeenCalled();
            expect(markRfc).toHaveBeenLastCalledWith('El RFC no tiene un formato válido.');
            expect(errorBanner(element)).toBeNull();
        });

        it('keeps the general notice while another field or the amount is still invalid', async () => {
            const element = createComponent();
            await setToggle(element, 'anonymous', false);
            await submit(element);
            expect(noticeText(element)).toContain(FIX_NOTICE);

            await typeInto(element, 'email', 'donante@example.com');
            expect(noticeText(element)).toContain(FIX_NOTICE);

            await typeInto(element, 'publicName', 'Familia Pérez');
            expect(noticeText(element)).toContain(FIX_NOTICE);

            await selectAmount(element, 500);
            expect(errorBanner(element)).toBeNull();
        });

        it('removes the general notice when every active field and the amount are valid', async () => {
            const element = createComponent();
            await setToggle(element, 'invoice', true);
            await submit(element);
            expect(noticeText(element)).toContain(FIX_NOTICE);

            await selectAmount(element, 500);
            await typeInto(element, 'email', 'donante@example.com');
            await typeInto(element, 'legalName', 'Familia Pérez S.A. de C.V.');
            await typeInto(element, 'taxPostalCode', '97000');
            await typeInto(element, 'rfc', PERSON_RFC);
            expect(noticeText(element)).toContain(FIX_NOTICE);

            await chooseRegime(element, '612');
            expect(noticeText(element)).toContain(FIX_NOTICE);

            await setPrivacyNotice(element, true);

            expect(errorBanner(element)).toBeNull();
            expect(startDonation).not.toHaveBeenCalled();
        });

        it('removes the notice when the donor turns off the option whose fields were invalid', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await setToggle(element, 'invoice', true);
            await submit(element);
            expect(noticeText(element)).toContain(FIX_NOTICE);

            await setToggle(element, 'invoice', false);

            expect(errorBanner(element)).toBeNull();
        });

        it('clears the error that Apex returned for a field when the donor corrects that field', async () => {
            startDonation.mockRejectedValueOnce({ body: { message: 'taxPostalCode|El código postal debe tener 5 dígitos.' } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element, PERSON_RFC, '612');
            await submit(element);
            expect(noticeText(element)).toContain(FIX_NOTICE);
            const markValidity = validity(element, 'taxPostalCode');
            const showValidity = report(element, 'taxPostalCode');

            await typeInto(element, 'taxPostalCode', '97010');

            expect(markValidity).toHaveBeenLastCalledWith('');
            expect(showValidity).toHaveBeenCalled();
            expect(errorBanner(element)).toBeNull();
            expect(startDonation).toHaveBeenCalledTimes(1);
        });

        it('keeps the notice while the field that Apex marked has not been edited', async () => {
            startDonation.mockRejectedValueOnce({ body: { message: 'email|Escribe un correo válido.' } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);
            expect(noticeText(element)).toContain(FIX_NOTICE);

            await selectAmount(element, 1000);
            expect(noticeText(element)).toContain(FIX_NOTICE);

            await typeInto(element, 'email', 'otro@example.com');
            expect(errorBanner(element)).toBeNull();
        });

        it('does not remove an error of the server that belongs to no field when a field is edited', async () => {
            startDonation.mockRejectedValueOnce({ body: { message: '|Esta campaña ya no acepta donaciones.' } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);

            await typeInto(element, 'email', 'otro@example.com');
            await selectAmount(element, 1000);
            await setToggle(element, 'anonymous', false);
            await setToggle(element, 'anonymous', true);

            expect(noticeText(element)).toContain('Esta campaña ya no acepta donaciones.');
        });

        it('does not remove a failure to open the payment when a field is edited', async () => {
            openPayment.mockRejectedValueOnce({ body: { message: '|No pudimos abrir el pago, intenta de nuevo' } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            await submit(element);

            await typeInto(element, 'email', 'otro@example.com');

            expect(noticeText(element)).toContain('No pudimos abrir el pago, intenta de nuevo');
        });

        describe('regime after the RFC changes', () => {
            const REGIME_REQUIRED = 'Selecciona tu régimen fiscal.';

            // A company RFC with its regime already validated, as after an earlier attempt or blur.
            async function withValidatedCompanyRegime() {
                const element = createComponent();
                await fillAnonymousDonation(element);
                await fillInvoice(element, COMPANY_RFC, '601');
                field(element, 'taxRegime').dispatchEvent(new CustomEvent('blur'));
                await Promise.resolve();
                return element;
            }

            it('drops the regime that no longer fits and wipes its error state by creating the field again', async () => {
                const element = await withValidatedCompanyRegime();
                const before = field(element, 'taxRegime');
                const showBefore = jest.spyOn(before, 'reportValidity');
                expect(before.value).toBe('601');

                await typeInto(element, 'rfc', PERSON_RFC);

                const after = field(element, 'taxRegime');
                expect(after.value).toBe('');
                expect(after).not.toBe(before);
                expect(showBefore).not.toHaveBeenCalled();
            });

            it('does not show a regime error while the donor keeps typing the RFC', async () => {
                const element = await withValidatedCompanyRegime();
                await typeInto(element, 'rfc', PERSON_RFC);
                const regime = field(element, 'taxRegime');
                const markRegime = jest.spyOn(regime, 'setCustomValidity');
                const showRegime = jest.spyOn(regime, 'reportValidity');

                await typeInto(element, 'rfc', 'GODE56123');
                await typeInto(element, 'rfc', 'GODE561231GR9');
                await flushPromises();

                expect(markRegime).not.toHaveBeenCalledWith(REGIME_REQUIRED);
                expect(showRegime).not.toHaveBeenCalled();
                expect(errorBanner(element)).toBeNull();
            });

            it('shows the regime error when the donor leaves the empty regime field', async () => {
                const element = await withValidatedCompanyRegime();
                await typeInto(element, 'rfc', PERSON_RFC);
                const regime = field(element, 'taxRegime');
                const markRegime = jest.spyOn(regime, 'setCustomValidity');
                const showRegime = jest.spyOn(regime, 'reportValidity');

                regime.dispatchEvent(new CustomEvent('blur'));
                await Promise.resolve();

                expect(markRegime).toHaveBeenLastCalledWith(REGIME_REQUIRED);
                expect(showRegime).toHaveBeenCalled();
            });

            it('flags the empty regime when the donor tries to continue, without calling Apex', async () => {
                const element = await withValidatedCompanyRegime();
                await typeInto(element, 'rfc', PERSON_RFC);
                const markRegime = jest.spyOn(field(element, 'taxRegime'), 'setCustomValidity');

                await submit(element);

                expect(markRegime).toHaveBeenLastCalledWith(REGIME_REQUIRED);
                expect(noticeText(element)).toContain(FIX_NOTICE);
                expect(startDonation).not.toHaveBeenCalled();
            });

            it('removes the regime error and the notice when a valid regime is chosen for the new RFC', async () => {
                const element = await withValidatedCompanyRegime();
                await typeInto(element, 'rfc', PERSON_RFC);
                await submit(element);
                expect(noticeText(element)).toContain(FIX_NOTICE);
                const markRegime = jest.spyOn(field(element, 'taxRegime'), 'setCustomValidity');

                await chooseRegime(element, '612');

                expect(markRegime).toHaveBeenLastCalledWith('');
                expect(field(element, 'taxRegime').value).toBe('612');
                expect(errorBanner(element)).toBeNull();
            });

            it('keeps the general notice while the dropped regime or another field is still pending', async () => {
                startDonation.mockRejectedValueOnce({
                    body: { message: 'taxPostalCode|El código postal debe tener 5 dígitos.' }
                });
                const element = createComponent();
                await fillAnonymousDonation(element);
                await fillInvoice(element, COMPANY_RFC, '601');
                await submit(element);
                expect(noticeText(element)).toContain(FIX_NOTICE);

                await typeInto(element, 'rfc', PERSON_RFC);
                expect(noticeText(element)).toContain(FIX_NOTICE);

                await typeInto(element, 'taxPostalCode', '97010');
                expect(noticeText(element)).toContain(FIX_NOTICE);

                await chooseRegime(element, '612');
                expect(errorBanner(element)).toBeNull();
            });

            it('makes no Apex call while the donor changes the RFC or the regime', async () => {
                const element = await withValidatedCompanyRegime();

                await typeInto(element, 'rfc', PERSON_RFC);
                await chooseRegime(element, '612');
                await typeInto(element, 'rfc', COMPANY_RFC);
                await flushPromises();

                expect(startDonation).not.toHaveBeenCalled();
                expect(openPayment).not.toHaveBeenCalled();
            });
        });

        it('makes no Apex call while the donor types, corrects or changes options', async () => {
            const element = createComponent();
            await selectAmount(element, 500);
            await submit(element);

            await typeInto(element, 'email', 'sin-arroba');
            await typeInto(element, 'email', 'donante@example.com');
            await setToggle(element, 'anonymous', false);
            await typeInto(element, 'publicName', 'Familia Pérez');
            await setToggle(element, 'invoice', true);
            await typeInto(element, 'legalName', 'Familia Pérez S.A. de C.V.');
            await typeInto(element, 'rfc', PERSON_RFC);
            await typeInto(element, 'taxPostalCode', '97000');
            await chooseRegime(element, '612');
            await selectAmount(element, 1000);
            await flushPromises();

            expect(startDonation).not.toHaveBeenCalled();
            expect(openPayment).not.toHaveBeenCalled();
        });

        it('keeps the payment flow: after the corrections, one startDonation and then one openPayment', async () => {
            const element = createComponent();
            await selectAmount(element, 500);
            await submit(element);
            await typeInto(element, 'email', 'donante@example.com');
            expect(errorBanner(element)).toBeNull();

            await submit(element);

            expect(startDonation).toHaveBeenCalledTimes(1);
            expect(openPayment).toHaveBeenCalledTimes(1);
            expect(openPayment).toHaveBeenCalledWith({ attemptId: ATTEMPT_ID });
            expect(startDonation.mock.invocationCallOrder[0]).toBeLessThan(openPayment.mock.invocationCallOrder[0]);
            expect(window.location.assign).toHaveBeenCalledWith(CHECKOUT_URL);
        });
    });

    describe('privacy notice when an invoice is requested (DON-13)', () => {
        const NOTICE_REQUIRED = 'Acepta el aviso de privacidad para solicitar factura.';

        it('shows the checkbox "Acepto el aviso de privacidad" only when the invoice is requested, unchecked and with no extra text or link', async () => {
            const element = createComponent();
            expect(field(element, 'privacyNoticeAccepted')).toBeNull();

            await setToggle(element, 'invoice', true);

            const checkbox = field(element, 'privacyNoticeAccepted');
            expect(checkbox).not.toBeNull();
            expect(checkbox.type).toBe('checkbox');
            expect(checkbox.label).toBe('Acepto el aviso de privacidad');
            expect(checkbox.checked).toBe(false);
            expect(checkbox.required).toBe(true);
            expect(element.shadowRoot.querySelector('.invoice a')).toBeNull();
            expect(normalize(element.shadowRoot.querySelector('.invoice').textContent)).not.toMatch(/privacidad/i);
        });

        it('hides the checkbox again, and asks for nothing, when the invoice is turned off', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await setToggle(element, 'invoice', true);
            await setToggle(element, 'invoice', false);

            expect(field(element, 'privacyNoticeAccepted')).toBeNull();
            await submit(element);

            expect(startDonation).toHaveBeenCalledTimes(1);
            expect(startDonation.mock.calls[0][0].request.privacyNoticeAccepted).toBe(false);
        });

        it('does not require the acceptance and sends it as false when there is no invoice', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);

            await submit(element);

            const request = startDonation.mock.calls[0][0].request;
            expect(request.invoiceRequested).toBe(false);
            expect(request.privacyNoticeAccepted).toBe(false);
            expect(window.location.assign).toHaveBeenCalledWith(CHECKOUT_URL);
        });

        it('blocks the payment and marks the checkbox when the invoice data is complete but the notice is not accepted', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element, PERSON_RFC, '612', false);
            const spy = jest.spyOn(field(element, 'privacyNoticeAccepted'), 'setCustomValidity');

            await submit(element);

            expect(spy).toHaveBeenLastCalledWith(NOTICE_REQUIRED);
            expect(startDonation).not.toHaveBeenCalled();
            expect(openPayment).not.toHaveBeenCalled();
            expect(errorBanner(element).textContent).toContain('Revisa los campos marcados');
        });

        it('clears the checkbox error and lets the donor continue once the notice is accepted, keeping the other data', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element, PERSON_RFC, '612', false);
            await submit(element);
            const spy = jest.spyOn(field(element, 'privacyNoticeAccepted'), 'setCustomValidity');

            await setPrivacyNotice(element, true);

            expect(spy).toHaveBeenLastCalledWith('');
            expect(errorBanner(element)).toBeNull();
            expect(field(element, 'legalName').value).toBe('Familia Pérez S.A. de C.V.');
            await submit(element);
            expect(startDonation).toHaveBeenCalledTimes(1);
            expect(startDonation.mock.calls[0][0].request).toMatchObject({
                invoiceRequested: true,
                rfc: PERSON_RFC,
                privacyNoticeAccepted: true
            });
        });

        it('marks the checkbox again if the donor unchecks it', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element, PERSON_RFC, '612');
            await setPrivacyNotice(element, false);
            const spy = jest.spyOn(field(element, 'privacyNoticeAccepted'), 'setCustomValidity');

            await submit(element);

            expect(spy).toHaveBeenLastCalledWith(NOTICE_REQUIRED);
            expect(startDonation).not.toHaveBeenCalled();
        });

        it('sends only the acceptance: no date or time ever comes from the browser', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element, PERSON_RFC, '612');

            await submit(element);

            const request = startDonation.mock.calls[0][0].request;
            expect(request.privacyNoticeAccepted).toBe(true);
            expect(Object.keys(request).filter((key) => /accepted.*at|timestamp|date/i.test(key))).toEqual([]);
            expect(JSON.stringify(request)).not.toMatch(/privacyNoticeAcceptedAt/);
        });

        it('sends false when the notice was accepted but the invoice was later turned off', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element, PERSON_RFC, '612');
            await setToggle(element, 'invoice', false);

            await submit(element);

            const request = startDonation.mock.calls[0][0].request;
            expect(request.invoiceRequested).toBe(false);
            expect(request.privacyNoticeAccepted).toBe(false);
            expect(request.rfc).toBeNull();
        });

        it('marks the checkbox with the message the server returns for it and shows no technical text', async () => {
            startDonation.mockRejectedValue({ body: { message: `privacyNoticeAccepted|${NOTICE_REQUIRED}` } });
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element, PERSON_RFC, '612');
            const spy = jest.spyOn(field(element, 'privacyNoticeAccepted'), 'setCustomValidity');

            await submit(element);

            expect(spy).toHaveBeenLastCalledWith(NOTICE_REQUIRED);
            expect(errorBanner(element).textContent).toContain('Revisa los campos marcados');
            expect(openPayment).not.toHaveBeenCalled();
        });

        it('keeps the accepted notice while the donor corrects another field', async () => {
            const element = createComponent();
            await fillAnonymousDonation(element);
            await fillInvoice(element, PERSON_RFC, '612');
            await typeInto(element, 'taxPostalCode', '1234');
            await submit(element);
            expect(startDonation).not.toHaveBeenCalled();

            await typeInto(element, 'taxPostalCode', '97010');
            await submit(element);

            expect(field(element, 'privacyNoticeAccepted').checked).toBe(true);
            expect(startDonation.mock.calls[0][0].request.privacyNoticeAccepted).toBe(true);
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
