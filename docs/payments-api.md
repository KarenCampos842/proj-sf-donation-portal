# Payments API for the portal (LWC)

Owner: Rodrigo Colli (workstream A). For: the public portal (workstream B).
Everything below is deployed in `donations-dev`. Stories: PAY-07, DON-19, DON-20, DON-21, PAY-02.

**Two ways a donation is registered.**
- **Return page (Delivery 1):** when the donor returns to the thank-you page (`/portal/gracias`), `getPaymentResult` looks the payment up in Mercado Pago and registers the donation.
- **Webhook (Delivery 2):** Mercado Pago also sends a signed payment notice, so the donation is registered even if the donor never returns (PAY-06, DON-24). See section 5.

Both paths use the same flow, `Donation_Register`, and the payment id is unique, so a payment is registered only once (PAY-03).

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

Which state the page gets without a payment (DON-20 AC4, #54):

| How the donor reaches the page | `paymentId` sent | `resultState` |
|---|---|---|
| "Volver al sitio" button of Mercado Pago | `"null"` | `NoPayment` |
| No `payment_id` in the URL (window closed, page opened directly) | empty or `null` | `Unknown`: the result is not known, so the page must not say the payment was not completed |

For the second row to reach the server, the thank-you page must send an empty value when the URL has no `payment_id`, not the text `"null"`.

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

## 5. Payment notices (webhook) — Delivery 2

Stories: PAY-06, PAY-01, PAY-03, DON-24, ADM-12. Deployed in `donations-dev` on 2026-11-16.

**Endpoint** (public, through the site, runs as the guest user):

```
POST https://uady--class2026b.sandbox.my.site.com/portalvforcesite/services/apexrest/mp/notifications
```

It is configured in the Mercado Pago panel (test mode) under **Webhooks**, event **Pagos (legacy)** only. The preference does not send `notification_url`, so Mercado Pago sends each payment notice only once.

| Class | Role |
|---|---|
| `MercadoPagoWebhookResource` | REST entry. Reads `x-signature`, `x-request-id`, `data.id` and `type`; the body is used only when the query string does not bring `data.id` or `type`. |
| `MercadoPagoSignatureValidator` | PAY-01. HMAC-SHA256 of `id:{data.id};request-id:{x-request-id};ts:{ts};` with the webhook secret, compared with `v1` in constant time. Rejects `ts` older or newer than 5 minutes. |
| `MercadoPagoNotificationService` | Decides what to do, reads the payment again with `GET /v1/payments/{id}` and runs `Donation_Register`. |

**What happens with each notice**

| Notice | Result | HTTP |
|---|---|---|
| No signature, wrong signature or outside the 5-minute window | Saved as rejected, "Firma inválida". Nothing is asked to Mercado Pago. | 400 |
| Webhook secret not configured in Salesforce | Saved as rejected, "Firma inválida" (detail: secret not configured) | 500 (Mercado Pago retries) |
| Type other than `payment` | "Tipo de aviso no soportado" | 200 |
| Payment does not exist in Mercado Pago | "Intento no encontrado" | 200 |
| Mercado Pago does not answer | Nothing is saved | 500 (retry) |
| `refunded` or `charged_back` | "Reembolso o contracargo (ignorado)"; no donation changes (out of scope) | 200 |
| `approved`, amount matches | Donation registered | 200 |
| Already registered (return page or a previous notice) | "Aviso repetido"; no second donation | 200 |
| Reference without an attempt / amount does not match | "Intento no encontrado" / "Monto no coincide" (saved by `Donation_Register`) | 200 |
| `rejected`, `cancelled`, `pending`, `in_process` | Nothing to register | 200 |

The amount and the status always come from Mercado Pago's API, never from the notice body. If anything fails while the donation is being registered, the work is rolled back and the answer is 500, so there is never a half-registered donation (PAY-06 AC5).

**Closed campaigns (DON-24).** The campaign must accept donations when the attempt and the payment are created (`Payment_Attempt_Create`, `Payment_Preference_Create`). `Donation_Register` does not check it again, so a payment made before the close and confirmed after it is still registered. `Confirmed_At__c` is the payment's `date_approved`.

**Duplicates (PAY-03).** `Provider_Payment_Id__c` is unique. A second insert is treated as "already processed", not as an error. The system sends no receipts, so it cannot send a second one (PAY-03 AC3).

**Webhook secret.** It is stored in the protected custom setting `Mercado_Pago_Webhook__c.Secret__c` (Setup → Custom Settings → Mercado Pago Webhook → Manage → organization value). It is typed in by hand and is never in the repository, screenshots or AI prompts.

**Rejection history (ADM-12).** Tab **Avisos rechazados**, list view "Historial de rechazos": folio, received at, reason, detail and technical id. Read-only, through the `Rejected_Notice_Viewer` permission set. It never stores the notice body, card data, emails or secrets. Ids that come from a notice whose signature was not valid are masked (`9876…3210`).
