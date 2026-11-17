# Security and Personal Data

> Status: draft for Delivery 1, reviewed against the Sandbox on 2026-11-10. Update for Delivery 2 (Mercado Pago webhook).
> Never include secrets, real personal data or real emails in this file or its screenshots.
> The payment provider is **Mercado Pago in test mode (Checkout Pro)**, not Stripe.
> The "Obtained" and "Evidence" columns stay empty until the test is really run. Do not fill them in advance.

## 1. Unauthenticated visitor test (repeatable)

Goal: show that a visitor without login cannot **read** or **modify** other donors' donations or payment attempts (SEG-01, RF-V2).

### 1.1 Setup

- Org alias: `donations-dev`
- Site URL: `https://uady--class2026b.sandbox.my.site.com/portal/` (published Sandbox site, prefix `portal`; academic demonstration, not a production website)
- Seed data: the Sandbox already holds the fictitious demo data: five campaigns and six confirmed donations loaded by an administrator (public, anonymous, with invoice for a company and for an individual, and anonymous with invoice), plus donations and payment attempts created later through the portal with test-mode payments. Describe in the evidence which of them each test used. Do not re-import the demo data: it would create duplicates.
- Tester: _name pending_. A second team member repeats the steps and records the result.

### 1.2 Read attempts

| # | Vector | Steps | Expected | Obtained | Evidence |
|---|---|---|---|---|---|
| R1 | Browse the public site | Open every page as a visitor without login | Only campaigns, progress, credited donors (name + amount), the donation form and the closed-campaign history | _..._ | _screenshot_ |
| R2 | Direct record URL | Type `/s/donation/<id>` and the record detail URL by hand, with a real donation Id | No access | _..._ | _..._ |
| R3 | Experience Cloud / Aura / Apex actions | From the browser console or Postman, call the site's actions with a real donation Id | No donation data returned | _..._ | _..._ |
| R4 | REST API as guest | Query donations and attempts through the REST API without a session | Denied | _..._ | _..._ |
| R5 | Global site search | Search for a donor name and an email | No donation data in results | _..._ | _..._ |
| R6 | Thank-you page parameters | Change `status`, `external_reference` or the payment id in the URL to another person's | No donation is registered and no data of another donor is shown | _..._ | _..._ |
| R7 | Emails and tax data | Try to read emails and RFC by any route above | Nothing returned | _..._ | _..._ |

### 1.3 Modify attempts

| # | Vector | Steps | Expected | Obtained | Evidence |
|---|---|---|---|---|---|
| M1 | Update an existing donation | Try to change its amount from the site and from the API | Fails | _..._ | _..._ |
| M2 | Delete an existing donation | Try to delete it | Fails | _..._ | _..._ |
| M3 | Create or force a confirmed donation | Try to create one already confirmed, or change its payment status | Fails | _..._ | _..._ |
| M4 | Read or modify a payment attempt | Try with your own attempt and with another person's | Fails | _..._ | _..._ |

## 2. Guest user permissions

| Object / feature | Permission | Why it is needed |
|---|---|---|
| Campaign (public fields only) | Read | Show campaigns, goals and progress. A sharing rule shares the campaigns in the states Cerrada, Activa and Pausada with the guest; Borrador campaigns are not shared |
| Donation | None | The guest never reads or writes donations; the portal returns only per-campaign totals and, for recognition, name and amount |
| Payment attempt | None | Server code creates it after validating everything again; the guest has no permission on the object. Since DON-18 the guest reaches its own attempt only with an access token (see below) |
| "API Enabled" | Not granted | Stops REST access as guest |
| "Run Flows" | Not granted | The guest does not run flows directly; the flows run from Apex |
| Apex classes | Execute: `CampaignPortalController`, `DonationIntakeService`, `DonationPaymentController`, `DonorRecognitionService` | Each one returns aggregates or public fields only, or validates the request again on the server |
| Permission set `Mercado_Pago_Callout` | Assigned to the guest user (and to one administrator account) | Grants the External Credential principal needed to call Mercado Pago from server code and, since Delivery 2, execute access to `MercadoPagoWebhookResource` (the payment-notice endpoint, see section 6). It grants no object access |

Owner of the records created by the guest: to be confirmed (TEC-01).

**Access token of a payment attempt (DON-18).** The portal has no login, so the Id of a Salesforce record never authorizes anything. When a donation starts, the server creates a random 256-bit token (`Crypto.generateAesKey(256)`), gives it to the browser once and keeps only its SHA-256 hash in `Payment_Attempt__c.Portal_Access_Token_Hash__c` (unique, External ID). Reviewing the summary, confirming, editing and opening the payment all need that token, and a token works for its own attempt only.

| Question | Answer |
|---|---|
| Where does the token live in the browser? | In memory only. It is not in the URL, the page, a cookie or the storage, and it is never written to a message, a log or a debug statement. A reload loses it and the donor starts again from the form (expected). |
| How long does it work? | 60 minutes from the creation of the attempt (`DonationReview.TOKEN_LIFETIME_MINUTES`): enough to read the summary and confirm, and far below the 7 days after which PAY-07 deletes an attempt that was not confirmed. |
| When does an attempt stop accepting its token? | When it is no longer `Started`, was replaced by an edit (`Superseded_At__c`), already opened a payment (`Preference_Id__c` has a value) or the token expired. Every case gives the same message, so nobody learns whether a token existed. |
| Who may read or write the three new fields (hash, confirmation date, replacement date)? | Only server code, through `PaymentAttemptAccess`. No permission set was changed, and neither the guest nor any internal role gets field permission on them. |
| What can the guest do with a stolen or guessed Id? | Nothing: an Id is not a token, and the hash cannot be used as a token (it would be hashed again and match nothing). |
| What does the summary expose? | Campaign name, exact amount, email, visibility, the public name only for a public donation, and whether an invoice was requested. No Id, no hash and no fiscal data. |

**The only `without sharing` class of this work is `PaymentAttemptAccess`.** The guest has no permission on `Payment_Attempt__c` and no record of it is shared with the guest, so the server needs two things: `without sharing` (ignores record sharing) and `WITH SYSTEM_MODE` / `AccessLevel.SYSTEM_MODE` (ignore object and field permissions). One does not replace the other. The class has no method that lists attempts or looks one up by an Id from the browser; it works on one attempt after the caller proved the token, reads only the fields of the review and writes only the three fields above. It is called only from `DonationReview`, so it is not in the profile of the guest. The other classes of this work (`DonationReview`, `DonationAccessToken`, `DonationAmountValidator` and the two DTOs) stay `with sharing`.

**Closed direct access (workstream A change).** `DonationPaymentController.startDonation` and `openPayment` lost `@AuraEnabled`: the guest could call `openPayment(attemptId)` straight from the browser and an Id was enough to open a payment. Now they can be called only from Apex, through `DonationIntakeService`, which checks the token. `getPaymentResult` stays `@AuraEnabled` because the thank-you page calls it. The guest profile was not changed.

**Known limit: two simultaneous openings.** Two parallel `openPayment` calls for the same confirmed attempt can both pass the `Preference_Id__c` check before either saves its preference, because the check comes before the callout and the save after it; `FOR UPDATE` is released when a callout starts. The Mercado Pago page that was consulted does not mention an idempotency key for preferences, so none is used and the case is **not completely prevented**. See `docs/payments-api.md`, section 1.

No permission set other than the integration one `Mercado_Pago_Callout` and the team set `Portal_Developer` gives read access to the fields of `Payment_Attempt__c`. The source of `Portal_Developer` is only in the unmerged PR #48 although the set exists in the Sandbox.

Internal read access to payment attempts: permission set `Payment_Attempt_Viewer` (read-only, view all, no create/edit/delete) lets the payments owner audit attempts and take evidence. `Donation_Admin` still has no access to attempts. Never assign `Payment_Attempt_Viewer` to the site guest user. Assigned to the payments developer on 2026-11-10.

**Privacy notice acceptance fields (DON-13), field-level security.** The four fields hold the proof of consent given when a donor asks for an invoice. They are read-only evidence: the flows `Payment_Attempt_Create` and `Donation_Register` write them in system mode, so no permission set needs edit access.

| Field | `Donation_Admin` | `Payment_Attempt_Viewer` | All other permission sets | Guest user |
|---|---|---|---|---|
| `Donation__c.Privacy_Notice_Accepted__c` | Read | No access to the object | None | None |
| `Donation__c.Privacy_Notice_Accepted_At__c` | Read | No access to the object | None | None |
| `Payment_Attempt__c.Privacy_Notice_Accepted__c` | No access to the object | Read | None | None |
| `Payment_Attempt__c.Privacy_Notice_Accepted_At__c` | No access to the object | Read | None | None |

- **Why these two sets.**
  - `Donation_Admin` handles the invoice requests (`data-model.md` D-04), and the consent is part of the invoice request data.
  - `Payment_Attempt_Viewer` exists so the payments owner can audit attempts as evidence and support; the attempt is where the consent is first recorded.
- **Sets without access.** `Campaign_Manager` and `Moderator` do not handle invoices, and D-04 (whether all three internal roles see tax data) is still open, so they get no consent fields. `Portal_Developer` and the integration sets (`Mercado_Pago_Callout`, `Rejected_Notice_Viewer`) get none either. If D-04 is settled in favor of the three roles, add read access to their `Donation__c` fields only.
- **Separation between viewing and changing.**
  - Each of the four entries has `readable=true` and `editable=false`.
  - Object permissions, view-all settings, sharing rules and the other fields of each set did not change.
  - No set was given access to an object it did not have: `Donation_Admin` still has none on `Payment_Attempt__c`, and `Payment_Attempt_Viewer` has none on `Donation__c`.
  - Only server code (the flows, in system mode) writes these fields.
- **Guest user.** The site guest profile and `Mercado_Pago_Callout` carry no permission on these fields or on either object; nothing was added. The guest only reaches the data through the Apex classes, which never return these fields.
- **System Administrator (checked after deployment, 2026-11-17).** The profile has **no** field permission on the four fields: an administrator query on them fails with "No such column", so an administrator cannot see the evidence unless a permission set that reads it is also assigned. The profile was not changed, because that is outside DON-13. Decision pending: assign `Donation_Admin` and `Payment_Attempt_Viewer` to the administrators who need the evidence, or add the field permissions to the profile. To read the evidence, the verifier user was assigned both permission sets temporarily; those two assignments were removed on 2026-11-17 once the checks were finished. Only the assignments of the payments owner remain.
- **Deployed.** The four fields, the two flows and the two permission sets were deployed in one operation on 2026-11-17 (deployment `0AfVC00000PICFd0AP`). Checked in the Sandbox: `Donation_Admin` and `Payment_Attempt_Viewer` read the fields they should and cannot edit them (`PermissionsEdit` false); the site guest profile has no object permission on `Donation__c` or `Payment_Attempt__c`, no field permission on the four fields and `API Enabled` off. The permission sets `sfdc_a360_sfcrm_data_extract` and `sfdc_slack`, which this project does not manage, also show read access to the four fields. The guest checks were repeated on 2026-11-17 with the same result.

## 3. Where the Mercado Pago credentials live

- Storage mechanism: access token in a **Named Credential / External Credential**; webhook secret key in a **protected setting** (D2). Nothing in code, site or repo (TEC-05).
- Configured in `donations-dev` on 2026-11-09 by hand in Setup. `.gitignore` excludes `externalCredentials/` and `namedCredentials/`, so these components are never versioned. Names only, never values:

  | Component | Name | Notes |
  |---|---|---|
  | External Credential | `MercadoPago` (label "Mercado Pago") | Authentication protocol: Custom |
  | Principal | `MercadoPagoTest` (Named Principal) | Holds the authentication parameter `AccessToken`: the access token of a Mercado Pago **test** account |
  | Custom header | `Authorization` = `{!'Bearer ' & $Credential.MercadoPago.AccessToken}` | The token is resolved by Salesforce at callout time; it never appears in code, flows or logs |
  | Named Credential | `MercadoPagoAPI` (label "Mercado Pago API") | URL `https://api.mercadopago.com`. "Generate Authorization Header" off, "Allow Formulas in HTTP Header" on. No managed package namespaces allowed |
  | Permission set | `Mercado_Pago_Callout` (label "Mercado Pago Callout") | Grants External Credential Principal Access to `MercadoPago - MercadoPagoTest`. Assigned (checked in the Sandbox on 2026-11-10) to the site guest user, which needs it to open the payment (DON-19) and to check it on return (DON-21), and to one administrator account; it grants no object access |

- Test-mode check (M1): `GET callout:MercadoPagoAPI/users/me` returned 200 for a Mexican account (`site_id` MLM) tagged `test_user` by Mercado Pago (2026-11-09).
- How we verified they are not in code, site, or repo history:
  - [x] `git log -p --all` searched for `APP_USR-<digits>` and `TEST-<digits>`: no matches (2026-11-09)
  - [x] Pre-commit hook enabled (`git config core.hooksPath .githooks`) and updated to look for Mercado Pago tokens (`APP_USR-…` / `TEST-…`), keeping the Stripe patterns. Each team member must enable it in their own clone
  - [ ] No keys in screenshots, AI log, or prompts
  - [ ] Repeat the `git log -p --all` search after the commit that removes `docs/payment-test-data.local` from tracking (the search above was run on 2026-11-09, before that file was committed)
- If a key leaks: rotate it the same day and tell the professor.
- **Exposed test-account data (2026-11-10):** `docs/payment-test-data.local` was committed in `dba1654` (PR #50) to this **public** repository. It holds sign-in data and test-card data for Mercado Pago **test** accounts (the values are not reproduced here); it contains no `APP_USR-` or `TEST-` access token. The file is now untracked and listed in `.gitignore`, but deleting it does **not** remove it from the Git history. Treat those test-account credentials as exposed: reset their passwords or recreate the test users, and keep the data only in untracked local files. The history was not rewritten.
  - 2026-11-11: Rodrigo Colli (payments) changed the passwords of the Mercado Pago test accounts; the values in the Git history no longer work.

## 4. Personal data classification

| Data item | Personal data? | Stored? | Why | Who can see it |
|---|---|---|---|---|
| Public name (person, family or company) | Yes | Yes | Public recognition | Public only if the donor chose recognition and the payment is confirmed; staff |
| Email | Yes | Yes | Receipt delivery | Staff only (never in public responses) |
| Fiscal name or business name | Yes | Yes (invoice request only) | Invoice request | Staff only |
| RFC | Yes | Yes (invoice request only) | Invoice request | Staff only |
| Fiscal postal code and fiscal regime | Yes | Yes (invoice request only) | Invoice request | Staff only |
| Privacy notice acceptance and its date | Yes | Yes (invoice request only) | Proof of consent | `Donation_Admin` (donations) and `Payment_Attempt_Viewer` (attempts), read-only; no other role |
| Donation amount | Not by itself; linked to a person it becomes personal | Yes | Progress and receipt | Totals public; amount per name public only for credited donors |
| Anonymous flag | No | Yes | Hide the name | Staff |
| Card number / CVC / expiry | Yes (sensitive) | **No** | Captured entirely by Mercado Pago | Nobody on our side |
| Payment id (`payment.id`) and `external_reference` | Indirect | Yes | Match the payment to the donation | Staff |
| Unconfirmed payment attempt | Yes (same data as above) | Temporary | Register the donation when the provider confirms | Nobody except server code and the `Portal_Developer` set; unconfirmed attempts are deleted after 7 days, confirmed ones are kept (see D-01) |

## 5. Known risks

- **Spam on the public form** (accepted risk, WON-08): someone can fill the form many times. Minimum mitigation: limit attempts per email and per hour.
- **Abandoned attempts** keep personal data of people who did not donate. Mitigation: the scheduled flow `Payment_Attempt_Delete_Stale` runs daily and deletes attempts whose status is not `Confirmed` and that are older than 7 days (PAY-07). Two open points: deleted records stay in the Recycle Bin for up to 15 days (flows cannot hard-delete), and confirmed attempts are kept, which differs from decision D-01 in `data-model.md` (to be settled by the team).
- **Salesforce System Administrator profile** can edit everything in the org. No project role can edit amount, reference or payment status; this profile is outside that rule and is documented here (RNF-03).
- **Daily email limit** of the Developer Edition org for external addresses (DON-23). Tests use only team emails.
- **Payment confirmed without a return to the portal.** Solved in Delivery 2 by the webhook (section 6). Remaining risks:
  - Unconfirmed attempts are deleted after 7 days, so a notice that arrives more than 7 days after the attempt (for example a long-pending payment) can no longer be matched and is logged as "Intento no encontrado".
  - Mercado Pago does not guarantee that a notice arrives. If the donor does not return and the notice never arrives, the payment is approved in Mercado Pago but no donation is registered, and the attempt is deleted after 7 days. Mitigated by the hourly reconciliation (PAY-08, `payments-api.md` section 6): it reads the approved payments of the last 7 days from Mercado Pago and registers those whose attempt is still `Started` after 30 minutes. It only reads Mercado Pago and writes through `Donation_Register`; it needs no new permission for the guest user. Remaining risk: it only helps if the job is scheduled, and it stops if the scheduling user is deactivated.
- **Silent failure outcome.** When the return check fails for a reason other than a missing attempt or an amount mismatch, the flow returns a generic error and does not log a rejected notice (`Rejected_Notice__c` is deployed and used only for those two reasons).
- **Public name cleaning (DON-11).** The public name is cleaned on the server (HTML tags and control characters removed, 80-character limit) by `PublicNameSanitizer`. It was deployed to the Sandbox on 2026-11-10 and its Apex source is in the repository (PR #58); on 2026-11-16 the repository version was checked against the Sandbox and they match. Public attempts saved before the cleaning were not changed.
- **Privacy notice content (DON-13).** The form records that the donor ticked «Acepto el aviso de privacidad», but the portal shows no text of the notice and no link to it, as the acceptance criteria of DON-13 ask (no extra text or separate page). There is no approved notice text in the repository, and none should be invented. Until the client decides, the recorded acceptance refers to a notice the donor cannot read in the portal. Follow-up: issue #66.
- **Two approved payments for one attempt (DON-18, review of 2026-11-17; owner: Workstream A).** `Donation_Register` avoids duplicates only by `Provider_Payment_Id__c`: it does not check whether the attempt already has a donation. If two preferences are created for one attempt (two simultaneous `openPayment` calls, see section 2) and both are paid, two `Donation__c` are registered. The donor needs a confirmed token to open a payment, so only the donor's own payments are affected. Proposed mitigation, not applied: in the approved path of `Donation_Register`, look for a donation of the same attempt with another payment id before creating one, and send the second payment to manual refund. It changes a flow of Workstream A and is pending their decision.
- **Orphan attempts (DON-18).** If `startDonation` succeeds but `getDonationSummary` fails, the token is lost and the attempt stays; every «Editar donación» also creates a new attempt, and `startDonation` has no rate limit (see spam above). All of them are bounded by PAY-07, which deletes attempts that were not confirmed after 7 days. Accepted as debt.
- **`getPaymentResult` is an anonymous `@AuraEnabled` method that can write (pre-existing, Workstream A).** The thank-you page calls it with the `payment_id` of the return URL; it runs `Payment_Return_Process`, which checks the payment with Mercado Pago and may register the donation. This work did not change it and did not audit it in depth; it is outside the scope of DON-09 and DON-18.
- **Anonymous with invoice** is allowed (confirmed in the 2026-11-04 session, Q-01). The name stays hidden in the portal and the fiscal data is used only for the invoice request, kept apart from public data and visible to staff only.

## 6. Delivery 2 update: Mercado Pago webhook

Deployed in `donations-dev` on 2026-11-16. Details in `payments-api.md`, section 5.

- **Signature validation (PAY-01).**
  - `MercadoPagoSignatureValidator` builds `id:{data.id};request-id:{x-request-id};ts:{ts};` and compares its HMAC-SHA256 with `v1` in constant time.
  - It rejects notices whose `ts` is outside a 5-minute window.
  - The signature is checked before anything else. An unsigned or altered notice gets HTTP 400 and causes no callout and no write, except its own rejection record.
  - Even with a valid signature, the status and the amount always come from `GET /v1/payments/{id}`.
- **Webhook secret.** It is stored in the protected custom setting `Mercado_Pago_Webhook__c.Secret__c`. The value is typed in by hand in Setup and is never versioned, shown in screenshots or given to AI tools.
- **Rejected notices logged (ADM-12).**
  - `Rejected_Notice__c` records the received date, a safe reason and a technical id. The reasons are "Firma inválida", "Aviso repetido", "Intento no encontrado", "Monto no coincide", "Tipo de aviso no soportado" and "Reembolso o contracargo (ignorado)".
  - The notice body, emails, card data and secrets are never stored. Ids taken from a notice that failed the signature check are masked (`9876…3210`).
  - Read access is given only through the permission set `Rejected_Notice_Viewer`: read-only, view all, no create, edit or delete. It is assigned to the payments developer (2026-11-16) and never to the guest user.
- **Idempotency (PAY-03).** `Provider_Payment_Id__c` is unique. A second insert is treated as "already processed", logged as "Aviso repetido" and answered with 200.
- **Permissions of the endpoint.**
  - The endpoint runs as the site guest user at `/portalvforcesite/services/apexrest/mp/notifications`. The guest only gets execute access to `MercadoPagoWebhookResource`, through `Mercado_Pago_Callout`. No object permission was added and the guest profile was not changed.
  - The class runs without sharing and writes in system mode, only after the signature is valid.
  - Records created by the endpoint are owned by the site's default record owner.
- **Check (2026-11-16).** An unsigned `POST` from the internet was answered and logged (`REJ-000001`, secret not configured yet). A forged signature sent from the internet got HTTP 400 and was logged with a masked id (`REJ-000004`, `REJ-000005`). Real approved and rejected test payments were processed by signed notices 1–3 seconds after payment (evidence in `docs/evidence/43-pay-06`).
- **Notice URL in the preference.** Each preference sends `notification_url` (custom label `Donation_Notification_Url`), because payments made with the test seller account are `live_mode=true` and Mercado Pago does not send their notices to the panel's test-mode URL. The URL is public by design; what protects it is the signature check, not the secrecy of the URL.

