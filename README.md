# proj-sf-donation-portal

A public, login-free donation portal built on **Salesforce Developer Edition** with **Mercado Pago (test mode, Checkout Pro)** to help SF Vibe Lab students fund their participation in Mexico Dreamin 2026. Staff and treasury manage campaigns and track donations inside Salesforce.

> **Academic project (SF Vibe Lab, UADY x Salesforce, Mérida, Mexico).** This project is for academic demonstration only. All donor data and campaign contributions are fictitious or test data. Mercado Pago runs exclusively in test mode. No real money is collected, no production credentials are used, and no production transactions are processed.

## Project status

Figures verified on 2026-11-17 (Delivery 2 due date) against GitHub Issues, [Project 13](https://github.com/users/KarenCampos842/projects/13) and the merged pull requests.

| Milestone | Due date | Tag | Stories | Issues closed | Project 13 status |
|---|---|---|---:|---:|---|
| Delivery 1 | 2026-11-10 | `entrega-1` | 22 | 21 | 21 Done · 1 Ready (SEG-01) |
| Delivery 2 | 2026-11-17 | `entrega-2` (not created yet) | 21 | 19 | 19 Done · 2 Backlog (DON-23, ADM-13) |
| No milestone | — | — | 1 (PAY-08) | 1 | Done |

The backlog has **44 user stories in scope**: 22 for Delivery 1, 21 for Delivery 2 and PAY-08, which was added later and has no milestone. **41 are Done in Project 13 (93.2 %)**: Delivery 1 21 of 22 (95.5 %), Delivery 2 19 of 21 (90.5 %) and PAY-08. The three that are not Done are SEG-01, DON-23 and ADM-13; their issues are open.

**DON-26 (view the portal in another language) is out of scope:** the team decided it will not be built, so it is not counted. Its issue ([#20](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/20)) is still open and its Project 13 card is still in Backlog. Issue #54 is a bug found while collecting the Delivery 1 evidence; it is not a story and is not counted either. The full per-story table is in [`docs/story-tracking-board.md`](docs/story-tracking-board.md).

### Implementation, issue closure and formal acceptance

These are three different things in this project:

- **Implemented:** the code or configuration exists and is merged in `main`. Delivery 1 was implemented across the three workstreams: A (payments, 6 stories), B (portal, 8 stories) and C (internal operation, security and data model, 8 stories). Delivery 2 added the signed webhook, the hourly reconciliation (A), the closed-campaign history, custom amount, review step, privacy-notice acceptance and field-level errors (B), and campaign closing, moderation and admin views (C).
- **Issue closed / Project status Done:** a team decision recorded in GitHub. At this cut-off every closed story issue is Done in Project 13 and every Done story is closed.
- **Accepted:** the Definition of Done below is met (every AC evidenced, M1–M3 respected). For Workstreams A and B (25 stories) every AC box is ticked and the "Evidence" section of the issue is filled, and the evidence folders are in `docs/evidence/`. The 16 Done stories of Workstream C are Done and closed, with evidence folders in the repository, but their issues still have unticked AC boxes and the original placeholder "Pendiente de evidencia"; the board reports their Project 13 status and does not tick anything on their behalf.

Known open points: the SEG-01 table in `docs/security.md` is not filled in and has not been repeated by a second team member; DON-23 (receipt email) is not built because the shared sandbox only sends system email; no screen-reader test was done; the 39 payment attempts that were not linked to a donation in the 2026-11-10 audit were not classified (see `docs/experience-builder-guide.md` §7).

### Pull requests

No pull request is open. Pull requests that only merge or sync branches are not listed, and ADM-13 is tracked by its owner in its own issue.

| PR | State | Content |
|---|---|---|
| [#2](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/2) | Merged | Data model draft |
| [#46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) | Merged | Workstream C configuration: permission sets, list views, rules, RFC flow |
| [#47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47) | Merged | Workstream A: Mercado Pago payment flows and `DonationPaymentController` |
| [#49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) | Merged | Workstream B: portal, LWR site, Guest profile, sharing rule |
| [#50](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/50) | Merged | Field configurations, documentation and first evidence images |
| [#48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) | Merged | Demo data under `data/demo/`, `Portal_Developer` permission set and logs |
| [#51](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/51), [#53](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/53) | Merged | Workstream B documentation, project tracking and evidence |
| [#55](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/55) | Merged | Workstream A: Delivery 1 payment evidence, `Payment_Attempt_Viewer` permission set and attempt list view |
| [#56](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/56) | Merged | Workstream C evidence and campaign layout |
| [#58](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/58) | Merged | Workstream B: public name cleaning and form validation (DON-11, DON-17) |
| [#59](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/59) | Merged | Workstream A, Delivery 2: signed Mercado Pago webhook (PAY-06, PAY-01, PAY-03, DON-24, ADM-12), server fix for #54 and evidence |
| [#61](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/61), [#65](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/65) | Merged | Workstream A: hourly reconciliation of approved payments without a notice (PAY-08), as Batch Apex |
| [#62](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/62) | Merged | Workstream B: closed-campaign history (DON-05) |
| [#63](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/63) | Merged | Workstream B: privacy-notice acceptance with an invoice request (DON-13) |
| [#64](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/64) | Merged | Workstream A: thank-you page sends an empty `payment_id` when the URL has none (bug #54) |
| [#67](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/67), [#69](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/69) | Merged | Workstream B: DON-13 evidence, documentation and final verification |
| [#68](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/68) | Merged | Workstream A: DON-19 AC3 evidence |
| [#71](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/71) | Merged | Workstream B: DON-05 evidence and board closeout |
| [#72](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/72), [#73](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/73) | Merged | Workstream B: custom amount as exact text and review step with an access token (DON-09, DON-18); Workstream A review fixes |
| [#74](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/74), [#75](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/75) | Merged | Workstream B: evidence for DON-01, DON-02, DON-03, DON-09, DON-13, DON-17 and DON-18, AI log entry 20 |
| [#76](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/76) | Merged | Workstream C, Delivery 2: campaign closing, moderation and admin views, evidence |

## Definition of Done (DoD)

The Definition of Done establishes the minimum quality and completion requirements that apply to all user stories and deliverables across the project, regardless of workstream or team member.

- Requirements implemented: All acceptance criteria (ACs) defined for the story have been implemented.

- Acceptance criteria verified: Every AC has been verified through an appropriate method, such as automated tests, manual testing, or a demonstration.

- Evidence documented: Sufficient evidence is available to demonstrate that the expected behavior works. Evidence may include test results, screenshots, videos, demonstrations, commits, or technical documentation. A single piece of evidence may support multiple ACs or user stories when relevant. Separate screenshots or files for every individual AC are not required.

- Security requirements met: The implementation complies with the project's minimum security requirements (M1–M3).

- GitHub tracking updated: The story's status, relevant evidence, and completion information are recorded in GitHub Projects.

## Quick links

| Resource | Link |
|---|---|
| GitHub repository | [proj-sf-donation-portal](https://github.com/KarenCampos842/proj-sf-donation-portal) |
| Backlog board | [GitHub Projects – Project 13](https://github.com/users/KarenCampos842/projects/13) |
| User stories and acceptance criteria | [GitHub Issues](https://github.com/KarenCampos842/proj-sf-donation-portal/issues) |
| Public donation portal | [Open Mexico Dreamin Donation Portal](https://uady--class2026b.sandbox.my.site.com/portal/) |
| Story tracking board (status, hours, evidence, issue links) | [`docs/story-tracking-board.md`](docs/story-tracking-board.md) |
| Experience Builder setup and deployment guide | [`docs/experience-builder-guide.md`](docs/experience-builder-guide.md) |
| Data model | [`docs/data-model.md`](docs/data-model.md) |
| Mercado Pago integration | [`docs/payments-api.md`](docs/payments-api.md) |
| Security and personal data | [`docs/security.md`](docs/security.md) |
| AI usage log | [`docs/ai-log.md`](docs/ai-log.md) |
| AI project context | [`docs/ai-context/PROJECT_CONTEXT.md`](docs/ai-context/PROJECT_CONTEXT.md) |
| Backlog notes and client answers | [`docs/backlog/README.md`](docs/backlog/README.md) |
| Questions and problem reports | [`docs/questions-and-reports.md`](docs/questions-and-reports.md) |
| Team contributions | [`docs/contributions.md`](docs/contributions.md) |

**Public site notice:** the portal link points to a published Salesforce Sandbox for demonstration. It is not a production donation website.

**Demo video:** to be added when the final recording is available.

## Main features

### Public donation portal — Workstream B

- Public campaign catalog without login.
- Campaign details, goals, confirmed donation totals and progress indicators.
- Campaign states: Active, Paused, Closed and Draft.
- Closed-campaign history (DON-05): name, goal and final total of closed campaigns, read-only, with no way to donate.
- Server-side validation of campaign visibility and donation eligibility.
- Donation form with suggested and custom amounts (DON-09). The amount travels as exact text and is validated again in Apex.
- Review step before paying (DON-18): summary of the donation, confirmation recorded on the server, and "Editar donación". The attempt is authorized by a random access token of which only the SHA-256 hash is stored.
- Field-level, safe error messages in Spanish with live correction (DON-17).
- Anonymous or public donor recognition. Public names are cleaned on the server (DON-11).
- Optional invoice information and field validation. The data is only captured and stored; no CFDI is generated. Requesting an invoice requires accepting the privacy notice, and the acceptance and its server timestamp are saved on the attempt and copied to the donation (DON-13). The portal does not show the text of the notice.
- Public thank-you page after returning from the payment provider.
- Responsive Experience Cloud LWR interface.

### Payment integration — Workstream A

- Mercado Pago Checkout Pro.
- Test-mode payment preferences and buyer accounts.
- Server-side payment lookup and confirmation.
- Payment attempts separated from confirmed donations.
- Payment return handling through the portal: the donation is registered when the donor returns to `/portal/gracias` (Delivery 1).
- Signed Mercado Pago webhook (Delivery 2): the donation is also registered when the donor never returns (PAY-06), only after the `x-signature` check (PAY-01), once per payment (PAY-03), even if the campaign closed while paying (DON-24). Rejected notices are listed in the **Avisos rechazados** tab (ADM-12). Details in [`docs/payments-api.md`](docs/payments-api.md), section 5.
- Hourly reconciliation (PAY-08): approved payments whose notice never arrived and whose donor never returned are registered by a scheduled Batch Apex, in chunks of 20. Details in [`docs/payments-api.md`](docs/payments-api.md), section 6.

### Internal operation

- Salesforce records for campaigns, donations and payment attempts.
- Internal permission sets for campaign and donation operations.
- Campaign and donation information managed inside Salesforce.
- Campaign closing by date (scheduled flow) or manually with a recorded reason; list views for closed campaigns, published names and anonymous or named donations; public-name correction by the moderator role (Workstream C, Delivery 2).
- Receipt email (DON-23) is **not built**: the shared sandbox only sends system email.

## Repository structure

The following structure reflects the current repository (local tool folders such as `.sf`, `.sfdx` and `.vscode`, `node_modules/` and `coverage/` are not listed):

```text
proj-sf-donation-portal/
├── README.md
├── .forceignore                   # keeps Jest tests (__tests__) and editor config out of deployments
├── .gitignore
├── .githooks/
│   └── pre-commit                 # scans staged files for payment-provider keys
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   └── user-story.md
│   └── pull_request_template.md
│
├── data/
│   └── demo/                      # demo campaigns and donations already loaded in the Sandbox; do not import again
│
├── docs/
│   ├── ai-context/
│   │   └── PROJECT_CONTEXT.md     # context supplied to AI tools
│   ├── backlog/
│   │   └── README.md              # backlog notes and client answers
│   ├── evidence/                  # acceptance evidence, one DON-xx folder per story (see "Evidence")
│   ├── ai-log.md                  # AI usage log and prompt evaluation
│   ├── contributions.md           # contribution log by team member
│   ├── data-model.md              # objects, fields, formulas and rules
│   ├── experience-builder-guide.md # Experience Cloud LWR setup, checks and test results
│   ├── payments-api.md            # Mercado Pago API and payment flow
│   ├── questions-and-reports.md   # client questions and problem reports
│   ├── security.md                # security tests and personal-data handling
│   └── story-tracking-board.md    # story tracking board: status, hours, evidence and issue links
│
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/           # Apex controllers, services, DTOs, tests and test data factory
│           ├── customMetadata/    # records of custom metadata types
│           ├── digitalExperienceConfigs/
│           ├── digitalExperiences/
│           │   └── site/
│           │       └── Mexico_Dreamin_Donation_Portal1/   # LWR site content and branding
│           ├── externalCredentials/   # MercadoPago (credentials are not stored in the repository)
│           ├── flows/             # payment attempt, preference, return and donation registration flows
│           ├── labels/            # custom labels
│           ├── layouts/
│           ├── lwc/               # Lightning Web Components and their Jest tests (__tests__)
│           ├── namedCredentials/  # MercadoPagoAPI
│           ├── networks/
│           ├── objects/           # custom objects and metadata types, fields, validation rules and list views
│           ├── permissionsets/
│           ├── profiles/          # Guest profile of the portal
│           ├── sharingRules/      # Guest sharing rule for public campaigns
│           ├── sites/
│           └── tabs/
│
├── jest-stubs/
│   └── cssModuleStub.js           # stub for CSS-only module imports in Jest
├── scripts/
│   ├── crear_issues.py            # creates backlog stories as GitHub issues
│   └── setup_project.sh           # creates labels and GitHub Project resources
│
├── jest.config.js                 # LWC Jest configuration
├── package.json                   # Node.js project and test scripts
├── package-lock.json
└── sfdx-project.json              # Salesforce DX project configuration (API 67.0)
```

### Main Salesforce components

**Apex classes** (`force-app/main/default/classes/`)
- `CampaignPortalController` — public campaign catalog, closed-campaign history and detail, with server-side eligibility.
- `CampaignDTO` — public view of a campaign.
- `DonorRecognitionService` — public donor recognition (name and amount only).
- `DonorRecognitionDTO` — public view of a recognition entry.
- `DonationIntakeService` — the five calls of the donation form (`startDonation`, `getDonationSummary`, `confirmDonation`, `openPayment`, `invalidateDonation`) and the bridge to the payment code.
- `DonationReview`, `DonationAccessToken`, `PaymentAttemptAccess`, `DonationStartDTO`, `DonationSummaryDTO` — review step: access token, summary and confirmation. `PaymentAttemptAccess` is the only `without sharing` class.
- `DonationAmountValidator` — server-side validation of the amount text.
- `PublicNameSanitizer` — cleaning of the public name.
- `DonationPaymentController` — payment API used by the portal (Workstream A).
- `MercadoPagoPreferenceAction` — Mercado Pago preference callout.
- `MercadoPagoPaymentLookupAction` — Mercado Pago payment lookup.
- `MercadoPagoWebhookResource`, `MercadoPagoNotificationService`, `MercadoPagoSignatureValidator` — signed webhook (Workstream A).
- `MercadoPagoReconciliationBatch`, `MercadoPagoReconciliationJob`, `MercadoPagoReconciliationService` — hourly reconciliation (PAY-08).

Each class has its test class (`*Test`), and `PortalTestDataFactory` provides shared test data.

**Lightning Web Components** (`force-app/main/default/lwc/`)
- `donationPortal` — main portal container and navigation.
- `campaignList` — public campaign catalog.
- `campaignDetail` — campaign information.
- `campaignProgress` — fundraising progress.
- `donorRecognitionList` — public donor recognition.
- `closedCampaignHistory` — closed-campaign history (DON-05).
- `donationForm` — donation form, with the "Otro monto" field and the review step.
- `donationSummary` — summary shown before the donor confirms.
- `donationThankYou` — payment return and thank-you page.
- Supporting modules: `donationFormMessages`, `donationFormRules`, `donationThankYouMessages`, `portalMessages`, `portalTheme`, `portalUtils` and `portalDemoData`.

**Custom objects** (`force-app/main/default/objects/`)
- `Fundraising_Campaign__c`
- `Donation__c`
- `Payment_Attempt__c`
- `Rejected_Notice__c`
- `Mercado_Pago_Webhook__c` — protected custom setting for the webhook secret (the value is not versioned).

**Flows** (`force-app/main/default/flows/`)
- `Payment_Attempt_Create` — validates the form data on the server and creates the payment attempt.
- `Payment_Preference_Create` — opens the Mercado Pago payment for an attempt.
- `Payment_Return_Process` — checks the real payment when the donor returns.
- `Donation_Register` — registers the donation only after the provider confirms the payment.
- `Payment_Attempt_Normalize_RFC` — normalizes the RFC before saving.
- `Payment_Attempt_Delete_Stale` — daily deletion of attempts that are not Confirmed and are older than 7 days. This is the deployed behavior; the data model proposes deleting all attempts (D-01), which is not decided yet.
- `Campaign_Close_Expired` — daily close of campaigns whose end date has passed (GES-11).
- `Campaign_Set_Close_Reason` — records the reason when a campaign is closed manually (GES-12).

**Permission sets** (`force-app/main/default/permissionsets/`)
- `Campaign_Manager`, `Donation_Admin`, `Moderator` — internal roles.
- `Mercado_Pago_Callout` — callout access to Mercado Pago (assigned to the Guest user and one administrator in the Sandbox).
- `Payment_Attempt_Viewer` — read-only access to payment attempts for the payments owner (audit and evidence). Never assigned to the Guest user.
- `Rejected_Notice_Viewer` — read-only access to rejected payment notices (ADM-12). Never assigned to the Guest user.
- `Portal_Developer` — developer access (PR #48).

The Experience Cloud site is built with the **Build Your Own (LWR)** template and uses the `portal` URL prefix.

### Evidence

Acceptance evidence lives in `docs/evidence/`, in one folder per story. There is no `Evidence/` folder.

All folders below are tracked in `main`.

- **Workstream B:** `DON-01`, `DON-02`, `DON-03`, `DON-04`, `DON-05`, `DON-08`, `DON-09`, `DON-10`, `DON-11`, `DON-12`, `DON-13`, `DON-17` and `DON-18`. File names such as `AC1.png` or `AC3_AC4.md` indicate the acceptance criteria they cover; `DON-05`, `DON-09`, `DON-13` and `DON-18` also have a `technical-evidence.md`. `DON-01` to `DON-03` still hold older numbered screenshots taken before the campaigns were renamed. `DON-04/AC1.png`, `DON-08/AC1.png` and `DON-11/AC1.png` are the same image and show a personal email address; they should be cropped or replaced by their owner.
- **Workstream A:** named `<issue>-<story>`: `15-don-19`, `16-don-20`, `17-don-21`, `37-adm-07`, `41-pay-02` and `44-pay-07` (Delivery 1) and `19-don-24`, `38-adm-12`, `40-pay-01`, `42-pay-03`, `43-pay-06`, `54-don-20-ac4` and `60-pay-08` (Delivery 2). File names start with the AC number (for example `16-1-rechazado.png` covers DON-20 AC1–AC2). Each issue's "Evidence" section links every AC to its screenshot.
  - All payments in these screenshots were made in Mercado Pago test mode, with test cards and the test payer email.
  - Every image of the Delivery 1 folders was checked: none shows tokens or real personal data.
- **Workstream C:** `GES-02`, `GES-03`, `GES-06`, `GES-07`, `GES-09`, `ADM-03` and `ADM-05` (Delivery 1) and `GES-10`, `GES-11`, `GES-12`, `GES-15`, `MOD-01`, `MOD-03`, `MOD-06`, `ADM-01` and `ADM-04` (Delivery 2). There is no folder for SEG-01, DON-23 or ADM-13.
- The [story tracking board](docs/story-tracking-board.md) lists the evidence of every story.

## Getting started

### Requirements

- Git
- Salesforce CLI (`sf`)
- Node.js and npm
- Access to the project repository
- Authorization to the team's Salesforce Sandbox

### 1. Clone the repository

```bash
git clone https://github.com/KarenCampos842/proj-sf-donation-portal.git
cd proj-sf-donation-portal
```

### 2. Enable the pre-commit security hook

Run once per local clone:

```bash
git config core.hooksPath .githooks
```

The hook scans staged files for payment-provider credentials before commits.

### 3. Install dependencies

```bash
npm ci
```

### 4. Run Lightning Web Component tests

```bash
npm run test:unit
```

### 5. Authorize the Salesforce Sandbox

Use the alias configured on your machine:

```bash
sf org login web --alias donations-dev --instance-url https://test.salesforce.com
```

Check the authorized organization:

```bash
sf org display --target-org donations-dev
```

### 6. Retrieve Salesforce metadata

Retrieve the current metadata before making changes, and back it up regularly:

```bash
sf project retrieve start --target-org donations-dev
```

The `sfdx-project.json` file is already included in the repository. There is no need to generate a new Salesforce project.

### 7. Validate a deployment

A check-only deployment can be used to validate metadata before applying changes:

```bash
sf project deploy start --source-dir force-app --target-org donations-dev --dry-run
```

Remove `--dry-run` only when an actual deployment is authorized and the target organization has been verified.

## Security rules — minimums M1–M3

1. **Mercado Pago test mode only.** Use test seller and buyer accounts and test cards. Never use production credentials or real payment cards.
2. **Guest user least privilege.** The public Guest user can read only the campaign fields required by the portal. It does not receive direct object access to donations or payment attempts. Public donor recognition is returned only through the controlled server-side service.
3. **No secrets in the repository.** Mercado Pago access tokens and webhook secrets must live in Salesforce Named Credentials, External Credentials or protected settings. Never store them in source code, metadata, screenshots, AI prompts, logs or commits.
4. **No card data in Salesforce.** Card details are captured by Mercado Pago and must not be stored by this application.
5. **Server-side validation.** Campaign eligibility, donation amounts and payment confirmation must be validated on the server. Browser parameters are never proof of a successful payment.
6. **Protect personal data.** Email addresses, RFCs, fiscal details and private donor information must not be exposed through public portal responses or committed to the repository.

If a credential is exposed, rotate it immediately and notify the project supervisor.

## Important development notes

- The demo campaign and donation records are **already loaded** in the Sandbox and have been adjusted by hand since (names, descriptions, states, images). Do not run `sf data import tree` or `data/demo/plan.json` (added by PR #48) again: the import uses inserts and would create duplicates, and the plan files no longer match the current records.
- Demo campaign and donation records are stored in the Salesforce Sandbox, not generated by deploying metadata.
- Local test-account data for Mercado Pago must stay in untracked files such as `docs/payment-test-data.local`, which is listed in `.gitignore`. Never commit it.
- Keep fictitious records clearly identified internally and never present test-mode amounts as real funds raised.
- Do not modify payment credentials or protected Salesforce configuration in versioned files.
- Preserve existing campaign and donation relationships when updating demonstration records.
- The public portal must continue to work without requiring a visitor to create an account.

## Team

| Member | Role | GitHub |
|---|---|---|
| Rodrigo Colli | Payments with Mercado Pago — Workstream A | [@RodrigoPeraza](https://github.com/RodrigoPeraza) |
| Alan Perez Romero | Internal operation and security testing — Workstream C | [@Alambrep](https://github.com/Alambrep) |
| Karen Elizabeth Campos | Public donation portal — Workstream B | [@KarenCampos842](https://github.com/KarenCampos842) |

## Academic context

**SF Vibe Lab — UADY x Salesforce**  
Mérida, Yucatán, Mexico  
Academic project — November 2026

All payment activity is simulated. The project is not intended for production use or real fundraising.