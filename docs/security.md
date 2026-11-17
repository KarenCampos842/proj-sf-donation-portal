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
| Payment attempt | None | Server code creates it after validating everything again; the guest has no permission on the object |
| "API Enabled" | Not granted | Stops REST access as guest |
| "Run Flows" | Not granted | The guest does not run flows directly; the flows run from Apex |
| Apex classes | Execute: `CampaignPortalController`, `DonationIntakeService`, `DonationPaymentController`, `DonorRecognitionService` | Each one returns aggregates or public fields only, or validates the request again on the server |
| Permission set `Mercado_Pago_Callout` | Assigned to the guest user (and to one administrator account) | Grants the External Credential principal needed to call Mercado Pago from server code and, since Delivery 2, execute access to `MercadoPagoWebhookResource` (the payment-notice endpoint, see section 6). It grants no object access |

Owner of the records created by the guest: to be confirmed (TEC-01).

No permission set other than the integration one `Mercado_Pago_Callout` and the team set `Portal_Developer` gives read access to the fields of `Payment_Attempt__c`. The source of `Portal_Developer` is only in the unmerged PR #48 although the set exists in the Sandbox.

Internal read access to payment attempts: permission set `Payment_Attempt_Viewer` (read-only, view all, no create/edit/delete) lets the payments owner audit attempts and take evidence. `Donation_Admin` still has no access to attempts. Never assign `Payment_Attempt_Viewer` to the site guest user. Assigned to the payments developer on 2026-11-10.

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
| Privacy notice acceptance and its date | Yes | Yes (invoice request only) | Proof of consent | Staff only |
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
- **Payment confirmed without a return to the portal.** Solved in Delivery 2 by the webhook (section 6). Remaining risk: unconfirmed attempts are deleted after 7 days, so a notice that arrives more than 7 days after the attempt (for example a long-pending payment) can no longer be matched and is logged as "Intento no encontrado".
- **Silent failure outcome.** When the return check fails for a reason other than a missing attempt or an amount mismatch, the flow returns a generic error and does not log a rejected notice (`Rejected_Notice__c` is deployed and used only for those two reasons).
- **Public name cleaning (DON-11).** The public name is cleaned on the server (HTML tags and control characters removed, 80-character limit) by `PublicNameSanitizer`. It is deployed to the Sandbox on 2026-11-10, but its Apex source is not committed yet, so the repository does not match the Sandbox for those classes. Public attempts saved before the cleaning were not changed.
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
- **Check (2026-11-16).** An unsigned `POST` from the internet was answered and logged (`REJ-000001`, secret not configured yet).

