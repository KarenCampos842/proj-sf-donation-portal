# Security and Personal Data

> Status: draft for Delivery 1. Update for Delivery 2 (Stripe webhook).
> Never include secrets, real personal data or real emails in this file or its screenshots.

## 1. Unauthenticated visitor test (repeatable)

Goal: show that a visitor without login cannot **read** or **modify** other donors' donations.

### 1.1 Setup

- Org alias: _..._
- Site URL: _..._
- Seed data: _list the fictitious donations used (IDs not required, describe them)_

### 1.2 Read attempts

| # | Vector | Steps | Expected | Obtained | Evidence |
|---|---|---|---|---|---|
| R1 | Browse the public site | _..._ | Only campaigns, progress, credited donors (name + amount), donation form | _..._ | _screenshot_ |
| R2 | Direct record URL | _..._ | No access | _..._ | _..._ |
| R3 | Experience Cloud / Aura / LWR endpoints | _..._ | No donation data returned | _..._ | _..._ |
| R4 | REST API as guest | _..._ | Denied | _..._ | _..._ |
| R5 | Flow / Apex exposed to guest | _..._ | Returns only public fields | _..._ | _..._ |

### 1.3 Modify attempts

| # | Vector | Steps | Expected | Obtained | Evidence |
|---|---|---|---|---|---|
| M1 | Update existing donation | _..._ | Fails | _..._ | _..._ |
| M2 | Delete existing donation | _..._ | Fails | _..._ | _..._ |
| M3 | Force status to Paid from the site | _..._ | Fails | _..._ | _..._ |

## 2. Guest user permissions

| Object / feature | Permission | Why it is needed |
|---|---|---|
| Campaign | Read | Show campaigns and goals |
| Donation | Create only | Register the pending donation |
| _..._ | _..._ | _..._ |

## 3. Where the Stripe keys live

- Storage mechanism: _Named Credential / External Credential / protected setting_
- How we verified they are not in code, site, or repo history:
  - [ ] `git log -p | grep -E "(sk|rk)_(test|live)_|whsec_"` returns nothing
  - [ ] Pre-commit hook enabled (`git config core.hooksPath .githooks`)
  - [ ] No keys in screenshots, AI log, or prompts

## 4. Personal data classification

| Data item | Personal data? | Stored? | Why | Who can see it |
|---|---|---|---|---|
| Donor name | Yes | Yes | Needed for credit and invoice | Staff; public only if "Credit" and Paid |
| Email | Yes | Yes | Receipt delivery | Staff only |
| RFC | Yes | Yes (invoice modality only) | Invoice request | Staff only |
| Donation amount | No (linked to a person it becomes personal) | Yes | Progress and receipt | Staff; public for credited donors |
| Card number / CVC / expiry | Yes (sensitive) | **No** | Handled entirely by Stripe | Nobody on our side |
| Stripe reference / session ID | Indirect | Yes | Match payment to donation | Staff |
| _..._ | _..._ | _..._ | _..._ | _..._ |

## 5. Known risks

- **Spam on the public form** (known risk, not a requirement): _describe and possible mitigation_
- _Pending donations that are never paid_
- _Other risks_

## 6. Delivery 2 update: Stripe webhook

- Signature validation (`Stripe-Signature`, HMAC-SHA256): _..._
- Rejected notices logged (date and reason): _..._
- Idempotency (same event twice): _..._
- Permissions of the endpoint's guest/integration user: _..._
