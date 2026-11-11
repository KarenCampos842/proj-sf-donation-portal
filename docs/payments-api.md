# Payments API for the portal (LWC)

Owner: Rodrigo Colli (workstream A). For: the public portal (workstream B).
Everything below is deployed in `donations-dev`. Stories: PAY-07, DON-19, DON-20, DON-21, PAY-02.

**Delivery 1 scope.** The donation is registered when the donor returns to the thank-you page (`/portal/gracias`): `getPaymentResult` looks the payment up in Mercado Pago and registers the donation. Delivery 1 has no webhook (`notification_url` is not sent). Registering a payment that was confirmed when the donor did not return is part of Delivery 2 (PAY-06, DON-24), together with signature validation (PAY-01) and duplicate handling (PAY-03). This is a planned scope boundary, not a Delivery 1 defect.

**Repository note.** The public-name cleaning described in section 1 (`PublicNameSanitizer`, and the matching changes in `DonationIntakeService` and `DonationPaymentController`) was deployed to the Sandbox on 2026-11-10, but its Apex source is not committed yet, so the version of this class in the repository does not include it.

The portal talks to one Apex class, `DonationPaymentController`, with three methods. Each method runs a flow in system mode, so the portal never touches `Payment_Attempt__c` or `Donation__c` directly and the guest user has no permission on them.

```
Form ──► startDonation(request) ──► attemptId
     ──► openPayment(attemptId) ──► checkoutUrl ──► redirect to Mercado Pago
                                                        │
Thank-you page ◄── Mercado Pago returns with ?payment_id=…
     ──► getPaymentResult(paymentId) ──► resultState ──► show message
```

## 1. Donation form

### `startDonation(request)` → `String attemptId`

Validates everything again on the server and saves the payment attempt. It does not create a donation and does not call Mercado Pago.

`request` fields (names from `data-model.md`, section 11):

| Field | Type | Required | Notes |
|---|---|---|---|
| `campaignId` | String | Yes | Campaign Id. The campaign must accept donations (`Accepts_Donations__c`). |
| `amount` | Number | Yes | MXN, minimum 50. The amount charged is the one saved here, not one sent later. |
| `email` | String | Yes | Valid email. |
| `visibility` | String | Yes | `Anonymous` or `Public` (API values, not the Spanish labels). |
| `publicName` | String | If `Public` | Cleaned on the server before it is saved (DON-11): HTML tags, stray `<` and `>` and control characters are removed and spaces are collapsed, keeping the text between tags. Maximum 80 characters after cleaning; raw text over 320 characters is rejected before cleaning. Rejected if it is empty after cleaning or too long. Ignored and not stored when `Anonymous`. |
| `invoiceRequested` | Boolean | No | Independent from visibility: an anonymous donation can request an invoice. |
| `legalName` | String | If invoice | Ignored when no invoice is requested. |
| `rfc` | String | If invoice | Spaces removed and uppercased on the server. |
| `taxPostalCode` | String | If invoice | 5 digits. |
| `taxRegime` | String | If invoice | SAT code, e.g. `612` (picklist API value). |

Errors: throws an `AuraHandledException` whose message is already in Spanish and safe to show, for example "El monto mínimo es de $50 MXN.", "El RFC no tiene un formato válido.", "Esta campaña ya no acepta donaciones.", "Escribe el nombre con el que quieres aparecer." (public name empty after cleaning) and "El nombre público no puede tener más de 80 caracteres.".

The public name is cleaned by `PublicNameSanitizer`. `startDonation` applies it itself, so the cleaning also covers direct calls to this method, and `DonationIntakeService` (the portal form) applies it before delegating here. Attempts saved before this cleaning existed are not changed.

### `openPayment(attemptId)` → `String checkoutUrl`

Creates the Mercado Pago Checkout Pro payment for the attempt and returns the URL to send the donor to. Each attempt can be opened only once.

Errors (Spanish, safe to show): "No pudimos abrir el pago, intenta de nuevo" (provider failed; the attempt is deleted, the donor can simply try again) or "Esta campaña ya no acepta donaciones.".

### Important: two separate calls

Call `openPayment` **after** `startDonation` has returned, as a second Apex call. Do not wrap both in one Apex method: Salesforce does not allow a callout after saving data in the same transaction.

### Example (form LWC)

```js
import startDonation from '@salesforce/apex/DonationPaymentController.startDonation';
import openPayment from '@salesforce/apex/DonationPaymentController.openPayment';

async handlePay() {
    this.isLoading = true;
    this.errorMessage = undefined;
    try {
        const attemptId = await startDonation({
            request: {
                campaignId: this.campaignId,
                amount: this.amount,
                email: this.email,
                visibility: this.isAnonymous ? 'Anonymous' : 'Public',
                publicName: this.isAnonymous ? null : this.publicName,
                invoiceRequested: this.invoiceRequested,
                legalName: this.legalName,
                rfc: this.rfc,
                taxPostalCode: this.taxPostalCode,
                taxRegime: this.taxRegime
            }
        });
        const checkoutUrl = await openPayment({ attemptId });
        window.location.assign(checkoutUrl); // same tab, to Mercado Pago
    } catch (error) {
        this.errorMessage = error?.body?.message || 'No pudimos abrir el pago, intenta de nuevo';
        this.isLoading = false;
    }
}
```

Disable the "Continuar al pago" button while `isLoading` is true, so the donor cannot start two attempts with a double click.

## 2. Thank-you page

Mercado Pago sends the donor back to the URL in the custom label `Donation_Return_Url` with parameters such as `payment_id`, `status`, `external_reference`. **Use only `payment_id`.** Never use `status` or any other parameter to decide what to show: they can be edited by anyone (DON-21 AC6).

### `getPaymentResult(paymentId)` → `String resultState`

Asks Mercado Pago for the real payment and, if it is approved and the amount matches, registers the donation (once, even if the page is reloaded). It never throws: if something fails it returns `Unknown`. It returns no donor or payment data, so the page cannot leak another donor's data (AC7) and anonymous donors are never named (AC4).

| `resultState` | Message to show (suggested) | Offer "try again"? |
|---|---|---|
| `Confirmed` | ¡Gracias! Recibimos tu aportación. | No |
| `Pending` | Estamos confirmando tu pago. No necesitas pagar otra vez. | No |
| `Rejected` | Tu pago fue rechazado y no se registró tu donación. | Yes |
| `Cancelled` | Tu pago se canceló y no se registró tu donación. | Yes |
| `NoPayment` | No se completó el pago; no se registró tu donación. | Yes |
| `Unknown` | Aún no podemos confirmar tu pago. | No |

Rules from DON-20 / DON-21: always show a thank-you page; only `Confirmed` may say the contribution was received; `Unknown` and `Pending` must never say "rechazado", "cancelado" or "confirmado".

### Example (thank-you LWC)

```js
import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getPaymentResult from '@salesforce/apex/DonationPaymentController.getPaymentResult';

export default class DonationThankYou extends LightningElement {
    resultState;
    requested = false;

    @wire(CurrentPageReference)
    async handlePage(pageRef) {
        if (!pageRef || this.requested) {
            return;
        }
        this.requested = true;
        const paymentId = pageRef.state?.payment_id
            || new URLSearchParams(window.location.search).get('payment_id');
        this.resultState = await getPaymentResult({ paymentId });
    }
}
```

`getPaymentResult` is not cacheable (it can write records), so call it imperatively as above, not with `@wire`.

## 3. Portal setup (done)

Checked in the Sandbox on 2026-11-10:

1. The custom label `Donation_Return_Url` is `https://uady--class2026b.sandbox.my.site.com/portal/gracias`, the thank-you page of the Mexico Dreamin Donation Portal site (URL prefix `portal`).
2. The site guest user has:
   - Apex class access to `DonationPaymentController` (and to the three portal classes `CampaignPortalController`, `DonationIntakeService` and `DonorRecognitionService`).
   - The permission set `Mercado_Pago_Callout` (access to the Mercado Pago credential; no object permissions). It is also assigned to one administrator account.

   Both are recorded in `docs/security.md`, section 2.

## 4. Testing a full payment

- Use the Mercado Pago **test buyer** account and the test cards from the Mercado Pago panel ("Pagos de prueba"). The cardholder name decides the result: `APRO` approved, `OTHE` rejected (as in DON-20 AC2).
- Never use a real card or a real Mercado Pago account (minimum M1).
- After an approved payment, the donation appears in Salesforce with its Mercado Pago payment id (ADM-07), and the campaign progress goes up.
