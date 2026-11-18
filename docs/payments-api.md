# Payments API for the portal (LWC)

Owner: Rodrigo Colli (workstream A). For: the public portal (workstream B).
Everything below is deployed in `donations-dev`. Stories: PAY-07, DON-19, DON-20, DON-21, PAY-02 (Delivery 1); PAY-06, PAY-01, PAY-03, DON-24, ADM-12 and PAY-08 (Delivery 2). The calls of the donation form also serve the Workstream B stories DON-09, DON-13, DON-17 and DON-18.

**Two ways a donation is registered.**
- **Return page (Delivery 1):** when the donor returns to the thank-you page (`/portal/gracias`), `getPaymentResult` looks the payment up in Mercado Pago and registers the donation.
- **Webhook (Delivery 2):** Mercado Pago also sends a signed payment notice, so the donation is registered even if the donor never returns (PAY-06, DON-24). See section 5.

Both paths use the same flow, `Donation_Register`, and the payment id is unique, so a payment is registered only once (PAY-03).

**Repository note.** The public-name cleaning described in section 1 (`PublicNameSanitizer`, and the matching changes in `DonationIntakeService` and `DonationPaymentController`) was deployed to the Sandbox on 2026-11-10 and its Apex source is in the repository since PR #58. On 2026-11-16 `PublicNameSanitizer` was checked against the Sandbox and both versions match.

The portal form talks to `DonationIntakeService` (workstream B), which validates, keeps the access token of the attempt and delegates to `DonationPaymentController` (workstream A). Each method of `DonationPaymentController` runs a flow in system mode, so the portal never touches `Payment_Attempt__c` or `Donation__c` directly and the guest user has no permission on them.

**DON-18 change in `DonationPaymentController`.** `startDonation` and `openPayment` are no longer `@AuraEnabled`: they stay `public static` and only `DonationIntakeService` calls them. Before, the guest could call `openPayment(attemptId)` directly and an Id was the only thing that authorized a payment. `getPaymentResult` keeps `@AuraEnabled` because the thank-you page calls it. The flows, the callouts and the request class of workstream A did not change. No LWC or flow called the two methods directly (checked in the source). The guest profile was not modified: it already had access to both classes, and the new classes are only called from `DonationIntakeService`, so they are not in the profile.

```
Form ──► startDonation(request) ──► accessToken          (the server saves the attempt and keeps only the token hash)
     ──► getDonationSummary(accessToken) ──► summary      (read from the saved attempt)
         [the donor reviews: «Editar donación» or «Confirmar y continuar al pago»]
     ──► invalidateDonation(accessToken)                  (edit: the old attempt can never open a payment)
     ──► confirmDonation(accessToken)                     (the server records the confirmation and its date)
     ──► openPayment(accessToken) ──► checkoutUrl ──► redirect to Mercado Pago
                                                        │
Thank-you page ◄── Mercado Pago returns with ?payment_id=…
     ──► getPaymentResult(paymentId) ──► resultState ──► show message
```

Every call is a separate Apex call. All of them are methods of `DonationIntakeService`.

## 1. Donation form

### The access token (DON-18)

The portal has no login, so the Id of a record never authorizes anything. `startDonation` creates a random 256-bit token (`Crypto.generateAesKey(256)`, 64 hexadecimal characters), returns it to the browser **once** and keeps only its SHA-256 hash in `Payment_Attempt__c.Portal_Access_Token_Hash__c` (unique, External ID). Every later call sends the token; the server hashes it and finds the attempt by the hash. A token authorizes one attempt only.

- The browser keeps it in memory: not in the URL, not in the page, not stored. If the donor reloads the page the token is lost and the donor starts again from the form. This is expected.
- It is valid for 60 minutes after the attempt was created (`DonationReview.TOKEN_LIFETIME_MINUTES`). It only has to cover the time to read the summary and confirm. It is far below the 7 days after which PAY-07 deletes an attempt that was not confirmed, so a token cannot outlive its attempt.
- An attempt can be reviewed only while all of this is true: the hash matches, `Status__c` is `Started`, it was not replaced by an edit (`Superseded_At__c` empty), no payment was opened (`Preference_Id__c` empty) and the token has not expired. Any other case answers the same text, so nobody learns whether a token ever existed: "Tu donación ya no está disponible. Edítala para volver a capturar tus datos."
- The hash, the confirmation date and the replacement date are not readable or editable by any permission set or by the guest. Only the server reads and writes them, through `PaymentAttemptAccess`.

### `startDonation(request)` → `DonationStartDTO { accessToken }`

Validates everything again on the server and asks workstream A to save the payment attempt, then creates the token. It does not create a donation and does not call Mercado Pago.

`request` fields of the form service (`DonationIntakeService.DonationFormInputDTO`; names from `data-model.md`, section 11):

| Field | Type | Required | Notes |
|---|---|---|---|
| `campaignId` | String | Yes | Campaign Id. The campaign must accept donations (`Accepts_Donations__c`). |
| `amount` | String | Yes | DON-09. The amount as text, exactly as the donor chose or typed it (for example `"250"` or `"1234.50"`). The server checks it with `DonationAmountValidator`: plain decimal number, at most two decimals, at most 14 whole digits (capacity of `Amount__c`, `Currency(16, 2)`), greater than zero and not below the current minimum (ADM-13). It is converted with `Decimal.valueOf` only after that and sent to workstream A as a `Decimal` with two decimals. There is no list to choose from and no maximum of ours. |
| `email` | String | Yes | Valid email. |
| `visibility` | String | Yes | `Anonymous` or `Public` (API values, not the Spanish labels). |
| `publicName` | String | If `Public` | Cleaned on the server before it is saved (DON-11): HTML tags, stray `<` and `>` and control characters are removed and spaces are collapsed, keeping the text between tags. Maximum 80 characters after cleaning; raw text over 320 characters is rejected before cleaning. Rejected if it is empty after cleaning or too long. Ignored and not stored when `Anonymous`. |
| `invoiceRequested` | Boolean | No | Independent from visibility: an anonymous donation can request an invoice. |
| `legalName` | String | If invoice | Ignored when no invoice is requested. |
| `rfc` | String | If invoice | Spaces removed and uppercased on the server. |
| `taxPostalCode` | String | If invoice | 5 digits. |
| `taxRegime` | String | If invoice | SAT code, e.g. `612` (picklist API value). |
| `privacyNoticeAccepted` | Boolean | If invoice | DON-13. Must be `true` when `invoiceRequested` is `true`; otherwise the call is rejected and no attempt is created (also when the field is omitted). The server saves it with the date and time of its own clock in `Privacy_Notice_Accepted_At__c`: do not send a date. Without invoice it is ignored and saved as false. |

`DonationPaymentController.DonationRequest` (workstream A) keeps `amount` as `Decimal`: the form service converts the validated text right before delegating. Nothing else of the contract of workstream A changed.

Errors: throws an `AuraHandledException` whose message is already in Spanish and safe to show. Since DON-17 every message of `DonationIntakeService` has the form `<field>|<message>`, where the field is empty for a general error: `amount|El monto mínimo es de $50 MXN.`, `rfc|El RFC no tiene un formato válido.`, `|Esta campaña ya no acepta donaciones.`. The amount messages are: "Elige un monto para continuar.", "Escribe solo números, con punto decimal. Por ejemplo: 250 o 250.50.", "Usa como máximo dos decimales.", "El monto debe ser mayor a cero.", "Escribe un monto con menos dígitos." and "El monto mínimo es de $X MXN." (the minimum comes from the configuration, ADM-13). Other messages: "Escribe el nombre con el que quieres aparecer." (public name empty after cleaning), "El nombre público no puede tener más de 80 caracteres." and "Acepta el aviso de privacidad para solicitar factura." (invoice requested without accepting the privacy notice).

The public name is cleaned by `PublicNameSanitizer`. `DonationPaymentController.startDonation` applies it itself, so the cleaning also covers direct calls to workstream A's method, and `DonationIntakeService` applies it before delegating. Attempts saved before this cleaning existed are not changed.

**Privacy notice (DON-13).** `DonationPaymentController.startDonation` checks `privacyNoticeAccepted` itself, and `Payment_Attempt_Create` checks it again and saves `Privacy_Notice_Accepted__c` and `Privacy_Notice_Accepted_At__c` (server clock). `Donation_Register` copies both to the donation. It is the flow that the thank-you page and the webhook (section 5) run, so both confirmation routes behave the same, and neither one is blocked when an attempt has no acceptance: attempts created before DON-13 are registered normally, with the acceptance false and no date. The portal form (`DonationIntakeService`) sends `privacyNoticeAccepted` and reports a missing acceptance on the checkbox field. Deploy the flows, the four fields and `DonationPaymentController` together: the controller passes the new flow input.

**Status (DON-13).** Deployed to `donations-dev` on 2026-11-17 together with the four fields, the two flows (`Payment_Attempt_Create` and `Donation_Register`, version 2 active), the Apex classes, the form and the two permission sets (deployment `0AfVC00000PICFd0AP`). The site was published afterwards (job `08PVC00000gD7QB2A0`). Checked as a guest: an invoice request with the acceptance omitted, `false` or `null` is rejected on both routes (the form service and a direct call to `DonationPaymentController.startDonation`), and no attempt is created. Real attempts created with invoice and acceptance store `true` and a server-generated date. A paid sandbox payment of 100 MXN (attempt `a1dVC00000GpiFVYAZ`, with invoice and acceptance) was registered as donation `a1cVC00000AID5tYAH` (`DON-000025`) by the new version of `Donation_Register`, with acceptance `true` and the same date and time copied from the attempt. The donation was created by the site guest user, which is the user both the return page and the webhook run as, so the record alone does not show which of the two registered it.

### `getDonationSummary(accessToken)` → `DonationSummaryDTO`

Returns what the donor reviews, built from the values saved in the attempt, never from values that come back from the browser: `campaignName`, `amount` (exact text with two decimals), `email`, `visibility`, `publicName` (only when the donation is `Public`) and `invoiceRequested`. It has no Id, no hash and no fiscal data. An anonymous donation can have `invoiceRequested = true`.

### `confirmDonation(accessToken)`

Records that the donor confirmed the summary: it sets `Payment_Attempt__c.Donor_Confirmed_At__c` with the date and time of the server clock. The date never comes from the browser. Confirming twice keeps the first date. `Status__c` does not change: `Started`, `Confirmed`, `Rejected` and `Cancelled` are the only states and the webhook, `Donation_Register`, PAY-07 and PAY-08 depend on them.

### `openPayment(accessToken)` → `String checkoutUrl`

Finds the attempt by the token and requires that it is reviewable and that `Donor_Confirmed_At__c` has a value, for every amount, suggested or custom. Without a confirmation it answers "Confirma el resumen de tu donación antes de continuar al pago." and never calls Mercado Pago. Then workstream A creates the Checkout Pro payment (`Payment_Preference_Create`) with the amount and the campaign saved in the attempt, and the method returns the URL to send the donor to. Each attempt can be opened only once.

It only reads before the callout, so the callout is not blocked by a pending save.

Errors (Spanish, safe to show): "No pudimos abrir el pago. Puede que Mercado Pago no acepte esta cantidad: edita tu donación y elige otra cantidad." (DON-09, AC6: the provider failed; the form disables «Confirmar y continuar al pago» and leaves «Editar donación» as the only way forward; the donor then continues with a new attempt. Observed on 2026-11-17 with a real rejection of 99999999999999.99: the failed attempt is **not** deleted. It stays with `Status__c` = `Started` and no `Preference_Id__c`, and PAY-07 deletes it after 7 days. Why the flow does not delete it was not investigated) or "Esta campaña ya no acepta donaciones.". Workstream A's flow does not keep the answer of Mercado Pago (it may echo request data), so the message cannot say which part was refused; it names the amount as a possible cause and offers to change it.

**Two openings at the same time.** `openPayment` rejects an attempt that already has `Preference_Id__c`, and `Payment_Preference_Create` checks the same again. Both checks happen **before** the callout and the preference is saved **after** it, so two simultaneous requests for the same attempt can both pass the check and create two preferences. `FOR UPDATE` does not help: Salesforce releases those locks when a callout starts. Disabling the button of the form does not stop direct or parallel calls to the server. The Mercado Pago documentation that was reachable (the page of test purchases) does not mention an idempotency key for creating preferences, so none is used; this is **not verified** and the duplicate opening is **not completely prevented**. What limits the damage: the donor needs a valid, confirmed token (a single browser holds it), the second preference overwrites `Preference_Id__c`, and both payments point to the same attempt through `external_reference`. `Donation_Register` registers one donation per payment and the first one marks the attempt `Confirmed`; a second approved payment of the same attempt would be registered as another donation (the payment id is the only uniqueness), and PAY-08 would reconcile it in the same way. Whether to accept that risk or to ask workstream A for a guard is a decision for the team.

### `invalidateDonation(accessToken)`

Called when the donor chooses «Editar donación». The server clears `Portal_Access_Token_Hash__c` and sets `Superseded_At__c` (audit). The old attempt can no longer be reviewed, confirmed or opened, even if someone kept its token; `Status__c` does not change and PAY-07 deletes the attempt later. Continuing creates a new attempt, a new token and a new summary that must be confirmed again. An unknown or expired token, or the token of an attempt that is no longer reviewable (for example one that already opened a payment), does nothing and answers nothing.

### Important: separate calls

Each step is its own Apex call. `openPayment` must not share a transaction with a save: Salesforce does not allow a callout after saving data in the same transaction. `confirmDonation` saves and `openPayment` calls Mercado Pago, so they are two calls.

### Example (form LWC)

The form of the portal (`donationForm`) does this; the summary is the component `donationSummary`.

```js
import startDonation from '@salesforce/apex/DonationIntakeService.startDonation';
import getDonationSummary from '@salesforce/apex/DonationIntakeService.getDonationSummary';
import confirmDonation from '@salesforce/apex/DonationIntakeService.confirmDonation';
import invalidateDonation from '@salesforce/apex/DonationIntakeService.invalidateDonation';
import openPayment from '@salesforce/apex/DonationIntakeService.openPayment';

// 1. Capture: the server saves the attempt and returns the token.
const { accessToken } = await startDonation({
    request: {
        campaignId: this.campaignId,
        amount: this.amountText, // text, never a Number
        email: this.email,
        visibility: this.isAnonymous ? 'Anonymous' : 'Public',
        publicName: this.isAnonymous ? null : this.publicName,
        invoiceRequested: this.invoiceRequested,
        legalName: this.legalName,
        rfc: this.rfc,
        taxPostalCode: this.taxPostalCode,
        taxRegime: this.taxRegime,
        privacyNoticeAccepted: this.invoiceRequested ? this.privacyNoticeAccepted : false
    }
});
// 2. Review: show the summary that the server built from the saved attempt.
const summary = await getDonationSummary({ accessToken });

// 3a. «Editar donación»
await invalidateDonation({ accessToken }); // then show the form again with the data the donor typed

// 3b. «Confirmar y continuar al pago»
await confirmDonation({ accessToken });
const checkoutUrl = await openPayment({ accessToken });
window.location.assign(checkoutUrl); // same tab, to Mercado Pago
```

Disable both buttons while a call is running, so the donor cannot start two attempts or open two payments with a double click. Show only messages with the form `<field>|<message>`; anything else gets a friendly text.

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

The thank-you page sends an empty value when the URL has no `payment_id`, and keeps the text `"null"` that Mercado Pago sends (fixed in #54, 2026-11-16).

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

Each preference sends this URL as `notification_url` (custom label `Donation_Notification_Url`, passed by `Payment_Preference_Create`), with `?source_news=webhooks` so that Mercado Pago sends only the signed webhook and not the older IPN notice.

Why not only the panel: the app uses the credentials of a Mercado Pago **test seller account**. Payments made with them come back with `live_mode=true`, so Mercado Pago sends their notices to the panel's **production** webhook URL, not to the test-mode one. Setting the production URL in the panel requires registering a business, which the team does not do for a school project. Found on 2026-11-16: an approved test payment got no notice for more than 15 minutes; after the change, notices arrived 1–3 seconds after each payment. The URL in the panel's **test mode** (event **Pagos (legacy)**) stays configured; it is used by the panel's notice simulator.

The notices sent through `notification_url` are signed with the same secret, so PAY-01 applies to them unchanged.

**Notices can be late or never arrive.** Mercado Pago retries failed notices, but it does not guarantee when they arrive. If the donor does not return to the portal and the notice never arrives, the attempt stays `Started` and is deleted after 7 days (PAY-07). The hourly reconciliation (PAY-08, section 6) covers that case.

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

## 6. Reconciliation of payments without a notice (PAY-08)

Safety net for the case where the donor never returns **and** the notice never arrives. Deployed in `donations-dev` on 2026-11-16.

| Class | Role |
|---|---|
| `MercadoPagoReconciliationJob` | Scheduled job. A scheduled job cannot make callouts, so it only queues its inner `Worker` (Queueable with callouts). |
| `MercadoPagoReconciliationService` | Does the work and returns a summary that the job writes to the debug log. |

**One run:**

1. Reads the **approved** payments of the last 7 days with `GET /v1/payments/search?range=date_created&begin_date=NOW-7DAYS&end_date=NOW&status=approved` (100 per page, at most 5 pages). The number of calls does not depend on how many attempts are abandoned.
2. *(batch start)* Keeps the payments whose `external_reference` is a `Payment_Attempt__c` that is still `Started` and was created more than 30 minutes ago, oldest attempt first. Younger attempts are left to the webhook and the return page. Payments that already have an "Amount_Mismatch" rejected notice are left out, so the same notice is not logged again every hour.
3. *(batch execute, 20 per chunk)* Registers each one with `Donation_Register`, like the webhook. A payment registered in the meantime is not registered twice (unique payment id). Amount mismatches are logged by the flow (ADM-12).

All callouts happen in `start`, before any write. Each payment costs about 2 queries and 3 writes (the savepoint counts), so a chunk of 20 stays far below the limits of 100 queries and 150 writes, however many payments are pending. If one chunk fails, only that chunk is rolled back; the next run tries its payments again. If Mercado Pago does not answer, nothing changes and the next run tries again. Payments that are not approved are never registered; rejections are still decided by the webhook and the return page.

**Scheduling (once, by an administrator, in Developer Console → Execute Anonymous):**

```apex
System.schedule('Conciliación Mercado Pago', '0 15 * * * ?', new MercadoPagoReconciliationJob());
```

**Guards:**

- If the previous run is still waiting or working, the scheduled job skips this hour instead of starting a second run over the same payments.
- One run reads at most 500 approved payments (5 pages of 100, newest first). If every page is full, older payments may not have been read: the summary says "LÍMITE ALCANZADO" and one warning "Conciliación incompleta (límite de pagos)" is added to the rejection history (ADM-12), at most once every 24 hours. Beyond that volume the design must change (go through the attempts instead of the payments); it is not needed at the volume of this project.

It runs at minute 15 of every hour, as the user who scheduled it. That user needs the `Mercado_Pago_Callout` permission set (External Credential access). To stop it: Setup → Scheduled Jobs → Delete.

**Check (2026-11-16):** a manual run read the 18 approved test payments of the last 7 days and found that all were already registered, so it changed nothing. After the batch change (review of PR #61), a manual batch run completed with 0 chunks and 0 errors: there was nothing left to register.
