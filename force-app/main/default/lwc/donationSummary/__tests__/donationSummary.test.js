import { createElement } from 'lwc';
import DonationSummary from 'c/donationSummary';

const SUMMARY = {
    campaignName: 'Viaje a Mexico Dreamin´',
    amount: '1234.50',
    email: 'donante@example.com',
    visibility: 'Anonymous',
    publicName: null,
    invoiceRequested: false
};

const normalize = (text) => text.replace(/\s+/g, ' ').trim();

function createComponent(props = {}) {
    const element = createElement('c-donation-summary', { is: DonationSummary });
    Object.assign(element, { summary: SUMMARY, ...props });
    document.body.appendChild(element);
    return element;
}

const text = (element, selector) => normalize(element.shadowRoot.querySelector(selector).textContent);
const button = (element, name) => element.shadowRoot.querySelector(`.actions__${name}`);

describe('c-donation-summary (DON-18)', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('shows the title, the campaign, the exact amount in MXN and the email', () => {
        const element = createComponent();

        expect(text(element, 'h1')).toBe('Revisa tu donación');
        expect(text(element, '.summary__campaign')).toBe('Viaje a Mexico Dreamin´');
        expect(text(element, '.summary__amount')).toBe('$1,234.50 MXN');
        expect(text(element, '.summary__email')).toBe('donante@example.com');
    });

    it('writes a whole amount without decimals and keeps every digit of a long one', () => {
        const whole = createComponent({ summary: { ...SUMMARY, amount: '500.00' } });
        expect(text(whole, '.summary__amount')).toBe('$500 MXN');

        const long = createComponent({ summary: { ...SUMMARY, amount: '99999999999999.99' } });
        expect(text(long, '.summary__amount')).toBe('$99,999,999,999,999.99 MXN');
    });

    it('says that the name will not be visible when the donation is anonymous', () => {
        const element = createComponent();

        expect(text(element, '.summary__visibility')).toBe('Anónima. Tu nombre no será visible en el portal.');
    });

    it('does not show a public name when the donation is anonymous, even if one arrives', () => {
        const element = createComponent({ summary: { ...SUMMARY, publicName: 'Nombre que no debe verse' } });

        expect(element.shadowRoot.textContent).not.toContain('Nombre que no debe verse');
    });

    it('shows the name that will appear when the donation is public, as plain text', () => {
        const element = createComponent({
            summary: { ...SUMMARY, visibility: 'Public', publicName: '<b>Familia</b> Pérez' }
        });

        expect(text(element, '.summary__visibility')).toBe('Pública. Aparecerá como: <b>Familia</b> Pérez');
        expect(element.shadowRoot.querySelector('b')).toBeNull();
    });

    it('shows the invoice request independently from the visibility', () => {
        const anonymousWithInvoice = createComponent({ summary: { ...SUMMARY, invoiceRequested: true } });
        expect(text(anonymousWithInvoice, '.summary__invoice')).toBe('Sí, solicitaste factura.');
        expect(text(anonymousWithInvoice, '.summary__visibility')).toContain('no será visible');

        const withoutInvoice = createComponent();
        expect(text(withoutInvoice, '.summary__invoice')).toBe('No solicitaste factura.');
    });

    it('does not show any fiscal data, Id or token: only the six values of the review', () => {
        const element = createComponent({
            summary: { ...SUMMARY, rfc: 'GODE561231GR8', legalName: 'Razón social', attemptId: 'a1d000000000001AAA' }
        });

        expect(element.shadowRoot.textContent).not.toContain('GODE561231GR8');
        expect(element.shadowRoot.textContent).not.toContain('Razón social');
        expect(element.shadowRoot.textContent).not.toContain('a1d000000000001AAA');
        expect(element.shadowRoot.querySelectorAll('dt')).toHaveLength(5);
    });

    it('offers «Editar donación» and «Confirmar y continuar al pago»', () => {
        const element = createComponent();

        expect(button(element, 'edit').label).toBe('Editar donación');
        expect(button(element, 'confirm').label).toBe('Confirmar y continuar al pago');
        expect(button(element, 'edit').disabled).toBe(false);
        expect(button(element, 'confirm').disabled).toBe(false);
    });

    it('tells the form that the donor wants to edit, and does nothing else', () => {
        const element = createComponent();
        const onEdit = jest.fn();
        const onConfirm = jest.fn();
        element.addEventListener('edit', onEdit);
        element.addEventListener('confirm', onConfirm);

        button(element, 'edit').click();

        expect(onEdit).toHaveBeenCalledTimes(1);
        expect(onConfirm).not.toHaveBeenCalled();
    });

    it('tells the form that the donor confirmed, and does nothing else', () => {
        const element = createComponent();
        const onEdit = jest.fn();
        const onConfirm = jest.fn();
        element.addEventListener('edit', onEdit);
        element.addEventListener('confirm', onConfirm);

        button(element, 'confirm').click();

        expect(onConfirm).toHaveBeenCalledTimes(1);
        expect(onEdit).not.toHaveBeenCalled();
    });

    it('disables both buttons while the form waits for the server', () => {
        const element = createComponent({ isBusy: true });

        expect(button(element, 'edit').disabled).toBe(true);
        expect(button(element, 'confirm').disabled).toBe(true);
    });

    it('announces, politely, that the payment is opening, and changes the label of the button', () => {
        const element = createComponent({ isBusy: true, isOpeningPayment: true });

        expect(button(element, 'confirm').label).toBe('Abriendo el pago…');
        const status = element.shadowRoot.querySelector('[role="status"]');
        expect(status.getAttribute('aria-live')).toBe('polite');
        expect(normalize(status.textContent)).toBe('Abriendo el pago…');
    });

    it('announces that the donor is going back while editing', () => {
        const element = createComponent({ isBusy: true });

        expect(normalize(element.shadowRoot.querySelector('[role="status"]').textContent)).toBe('Volviendo a tu donación…');
    });

    it('shows an error as an alert, as text, and nothing when there is none', () => {
        const withoutError = createComponent();
        expect(withoutError.shadowRoot.querySelector('[role="alert"]')).toBeNull();

        const element = createComponent({ errorMessage: '<img src=x onerror=alert(1)>' });
        const alert = element.shadowRoot.querySelector('[role="alert"]');
        expect(alert.textContent).toContain('<img src=x onerror=alert(1)>');
        expect(alert.querySelector('img')).toBeNull();
    });

    it('disables only the confirm button when the server refused the attempt', () => {
        const element = createComponent({ confirmDisabled: true });

        expect(button(element, 'confirm').disabled).toBe(true);
        expect(button(element, 'edit').disabled).toBe(false);
    });

    it('moves the focus to the title so a screen reader announces the new step', () => {
        const element = createComponent();
        const title = element.shadowRoot.querySelector('h1');
        const focus = jest.spyOn(title, 'focus');

        element.focusTitle();

        expect(title.getAttribute('tabindex')).toBe('-1');
        expect(focus).toHaveBeenCalledTimes(1);
    });

    it('has one h1 and labels the section with it', () => {
        const element = createComponent();

        expect(element.shadowRoot.querySelectorAll('h1')).toHaveLength(1);
        // LWC rewrites ids at run time, so the section and the title are compared with each other.
        expect(element.shadowRoot.querySelector('section').getAttribute('aria-labelledby')).toBe(
            element.shadowRoot.querySelector('h1').id
        );
    });
});
