# Security and Personal Data

> Status: draft for Delivery 1. Update for Delivery 2 (Mercado Pago webhook).
> Never include secrets, real personal data or real emails in this file or its screenshots.
> The payment provider is **Mercado Pago in test mode (Checkout Pro)**, not Stripe.
> The "Obtained" and "Evidence" columns stay empty until the test is really run. Do not fill them in advance.

## 1. Unauthenticated visitor test (repeatable)

Goal: show that a visitor without login cannot **read** or **modify** other donors' donations or payment attempts (SEG-01, RF-V2).

### 1.1 Setup

- Org alias: `donations-dev`
- Site URL: _add the Experience Cloud URL_
- Seed data: _list the fictitious donations and payment attempts used (IDs not required, describe them): e.g. two confirmed donations, one anonymous and one public with invoice, and one unconfirmed attempt._
- Tester: _name_. A second team member repeats the steps and records the result.

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
| Campaign (public fields only) | Read | Show campaigns, goals and progress |
| Donation | None | The guest never reads or writes donations; the portal returns only per-campaign totals and, for recognition, name and amount |
| Payment attempt | None | Server code creates it after validating everything again; the guest has no permission on the object |
| "API Enabled" | Not granted | Stops REST access as guest |
| _Apex classes exposed to the site_ | Execute only the ones the site needs | Each one returns aggregates or public fields only |

Created records are owned by an internal default user (TEC-01).

## 3. Where the Mercado Pago credentials live

- Storage mechanism: access token in a **Named Credential / External Credential**; webhook secret key in a **protected setting** (D2). Nothing in code, site or repo (TEC-05).
- Configured in `donations-dev` on 2026-11-09 by hand in Setup. `.gitignore` excludes `externalCredentials/` and `namedCredentials/`, so these components are never versioned. Names only, never values:

  | Component | Name | Notes |
  |---|---|---|
  | External Credential | `MercadoPago` (label "Mercado Pago") | Authentication protocol: Custom |
  | Principal | `MercadoPagoTest` (Named Principal) | Holds the authentication parameter `AccessToken`: the access token of a Mercado Pago **test** account |
  | Custom header | `Authorization` = `{!'Bearer ' & $Credential.MercadoPago.AccessToken}` | The token is resolved by Salesforce at callout time; it never appears in code, flows or logs |
  | Named Credential | `MercadoPagoAPI` (label "Mercado Pago API") | URL `https://api.mercadopago.com`. "Generate Authorization Header" off, "Allow Formulas in HTTP Header" on. No managed package namespaces allowed |
  | Permission set | `Mercado_Pago_Callout` (label "Mercado Pago Callout") | Grants External Credential Principal Access to `MercadoPago - MercadoPagoTest`. Assigned to the payments developer. The site guest user will need it when the portal starts the payment (DON-19); it grants no object access |

- Test-mode check (M1): `GET callout:MercadoPagoAPI/users/me` returned 200 for a Mexican account (`site_id` MLM) tagged `test_user` by Mercado Pago (2026-11-09).
- How we verified they are not in code, site, or repo history:
  - [x] `git log -p --all` searched for `APP_USR-<digits>` and `TEST-<digits>`: no matches (2026-11-09)
  - [x] Pre-commit hook enabled (`git config core.hooksPath .githooks`) and updated to look for Mercado Pago tokens (`APP_USR-…` / `TEST-…`), keeping the Stripe patterns. Each team member must enable it in their own clone
  - [ ] No keys in screenshots, AI log, or prompts
- If a key leaks: rotate it the same day and tell the professor.

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
| Unconfirmed payment attempt | Yes (same data as above) | Temporary | Register the donation when the provider confirms | Nobody except server code; deleted after 7 days |

## 5. Known risks

- **Spam on the public form** (accepted risk, WON-08): someone can fill the form many times. Minimum mitigation: limit attempts per email and per hour.
- **Abandoned attempts** keep personal data of people who did not donate. Mitigation: the scheduled flow `Payment_Attempt_Delete_Stale` runs daily and deletes attempts whose status is not `Confirmed` and that are older than 7 days (PAY-07). Two open points: deleted records stay in the Recycle Bin for up to 15 days (flows cannot hard-delete), and confirmed attempts are kept, which differs from decision D-01 in `data-model.md` (to be settled by the team).
- **Salesforce System Administrator profile** can edit everything in the org. No project role can edit amount, reference or payment status; this profile is outside that rule and is documented here (RNF-03).
- **Daily email limit** of the Developer Edition org for external addresses (DON-23). Tests use only team emails.
- **Anonymous with invoice** is allowed (confirmed in the 2026-11-04 session, Q-01). The name stays hidden in the portal and the fiscal data is used only for the invoice request, kept apart from public data and visible to staff only.

## 6. Delivery 2 update: Mercado Pago webhook

- Signature validation (`x-signature`, HMAC-SHA256): build `id:{data.id};request-id:{x-request-id};ts:{ts};`, compare with `v1`, reject if `ts` is outside a 5-minute window. Even with a valid signature, the payment status is always confirmed with `GET /v1/payments/{id}` (PAY-01): _..._
- Rejected notices logged (date and reason): "Firma inválida", "Aviso repetido", "Intento no encontrado", "Monto no coincide", "Tipo de aviso no soportado" (ADM-12): _..._
- Idempotency (same event twice): unique payment id, a second insert is treated as "already processed" (PAY-03): _..._
- Permissions of the endpoint's guest/integration user: _..._

