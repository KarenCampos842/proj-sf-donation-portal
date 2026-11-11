# proj-sf-donation-portal

A public, login-free donation portal built on **Salesforce Developer Edition** with **Mercado Pago (test mode, Checkout Pro)** to help SF Vibe Lab students fund their participation in Mexico Dreamin 2026. Staff and treasury manage campaigns and track donations inside Salesforce.

> **Academic project (SF Vibe Lab, UADY x Salesforce, Mérida, Mexico).** This project is for academic demonstration only. All donor data and campaign contributions are fictitious or test data. Mercado Pago runs exclusively in test mode. No real money is collected, no production credentials are used, and no production transactions are processed.

## Project status

Figures verified on 2026-11-10 (the Delivery 1 due date) against GitHub Issues and [Project 13](https://github.com/users/KarenCampos842/projects/13).

| Milestone | Due date | Tag | Stories | Issues closed | Project 13 status |
|---|---|---|---:|---:|---|
| Delivery 1 | 2026-11-10 | `entrega-1` | 22 | 15 | 8 Done · 7 In review · 6 In progress · 1 Ready |
| Delivery 2 | 2026-11-17 | `entrega-2` | 21 | 0 | 21 Backlog |
| Unscheduled | TBD | — | 1 (DON-26) | 0 | Backlog |

The backlog contains **44 user stories**: 22 for Delivery 1, 21 for Delivery 2 and 1 without a milestone (DON-26). In total 15 issues are closed and 29 are open. The full per-story table is in [`docs/story-tracking-board.md`](docs/story-tracking-board.md).

### Implementation, issue closure and formal acceptance

These are three different things in this project:

- **Implemented:** the code or configuration exists, is merged in `main` and has automated tests. The Delivery 1 stories were implemented across the three workstreams: A (payments, 6 stories), B (portal, 8 stories) and C (internal operation, security and data model, 8 stories). Some Workstream C stories are still In progress.
- **Issue closed / Project status Done:** a team decision recorded in GitHub. All 8 Workstream B stories are Done and closed with every acceptance criterion ticked. Seven other Delivery 1 issues are closed but still show In review in Project 13.
- **Accepted:** the Definition of Done below is met. The 8 Workstream B stories are accepted. The Workstream A stories are closed but still In review, and the Workstream C stories are partly In progress, so they are not counted as accepted until their owners move them to Done. The “Evidence” section of the issues still holds the original placeholder “Pendiente de evidencia”, and part of the Workstream B evidence folders is not committed yet (see [Evidence](#evidence)); neither affects the accepted status of the Workstream B stories.

### Pull requests

| PR | State | Content |
|---|---|---|
| [#2](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/2) | Merged | Data model draft |
| [#46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) | Merged | Workstream C configuration: permission sets, list views, rules, RFC flow |
| [#47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47) | Merged | Workstream A: Mercado Pago payment flows and `DonationPaymentController` |
| [#49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) | Merged | Workstream B: portal, LWR site, Guest profile, sharing rule |
| [#50](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/50) | Merged | Field configurations, documentation and first evidence images |
| [#48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) | **Open, not merged** (conflicts with `main` in `docs/ai-log.md` and `docs/contributions.md`) | Demo data under `data/demo/`, `Portal_Developer` permission set and logs. The demo records and the permission set already exist in the Sandbox, but their source is not in `main` |

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
- Server-side validation of campaign visibility and donation eligibility.
- Donation form with suggested and custom amounts.
- Anonymous or public donor recognition.
- Optional invoice information and field validation. The data is only captured and stored; no CFDI is generated.
- Public thank-you page after returning from the payment provider.
- Responsive Experience Cloud LWR interface.

### Payment integration — Workstream A

- Mercado Pago Checkout Pro.
- Test-mode payment preferences and buyer accounts.
- Server-side payment lookup and confirmation.
- Payment attempts separated from confirmed donations.
- Payment return handling through the portal: in Delivery 1 the donation is registered when the donor returns to `/portal/gracias`. There is no webhook yet; recovering a payment confirmed when the donor does not return is planned for Delivery 2 (PAY-06, DON-24).

### Internal operation

- Salesforce records for campaigns, donations and payment attempts.
- Internal permission sets for campaign and donation operations.
- Campaign and donation information managed inside Salesforce.

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
│           ├── objects/           # custom objects, fields, validation rules and list views
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
- `CampaignPortalController` — public campaign catalog and detail, with server-side eligibility.
- `CampaignDTO` — public view of a campaign.
- `DonorRecognitionService` — public donor recognition (name and amount only).
- `DonorRecognitionDTO` — public view of a recognition entry.
- `DonationIntakeService` — donation form validation and bridge to the payment code.
- `DonationPaymentController` — payment API used by the portal (Workstream A).
- `MercadoPagoPreferenceAction` — Mercado Pago preference callout.
- `MercadoPagoPaymentLookupAction` — Mercado Pago payment lookup.

Each class has its test class (`*Test`), and `PortalTestDataFactory` provides shared test data.

**Lightning Web Components** (`force-app/main/default/lwc/`)
- `donationPortal` — main portal container and navigation.
- `campaignList` — public campaign catalog.
- `campaignDetail` — campaign information.
- `campaignProgress` — fundraising progress.
- `donorRecognitionList` — public donor recognition.
- `donationForm` — donation form.
- `donationThankYou` — payment return and thank-you page.
- Supporting modules: `donationFormMessages`, `donationFormRules`, `donationThankYouMessages`, `portalMessages`, `portalTheme`, `portalUtils` and `portalDemoData`.

**Custom objects** (`force-app/main/default/objects/`)
- `Fundraising_Campaign__c`
- `Donation__c`
- `Payment_Attempt__c`
- `Rejected_Notice__c`

**Flows** (`force-app/main/default/flows/`)
- `Payment_Attempt_Create` — validates the form data on the server and creates the payment attempt.
- `Payment_Preference_Create` — opens the Mercado Pago payment for an attempt.
- `Payment_Return_Process` — checks the real payment when the donor returns.
- `Donation_Register` — registers the donation only after the provider confirms the payment.
- `Payment_Attempt_Normalize_RFC` — normalizes the RFC before saving.
- `Payment_Attempt_Delete_Stale` — daily deletion of attempts that are not Confirmed and are older than 7 days. This is the deployed behavior; the data model proposes deleting all attempts (D-01), which is not decided yet.

**Permission sets** (`force-app/main/default/permissionsets/`)
- `Campaign_Manager`, `Donation_Admin`, `Moderator` — internal roles.
- `Mercado_Pago_Callout` — callout access to Mercado Pago (assigned to the Guest user and one administrator in the Sandbox).
- `Portal_Developer` exists in the Sandbox but its source is only in the unmerged PR #48.

The Experience Cloud site is built with the **Build Your Own (LWR)** template and uses the `portal` URL prefix.

### Evidence

Acceptance evidence lives in `docs/evidence/`, in one folder per story (`DON-01`, `DON-02`, …). There is no `Evidence/` folder. File names such as `AC1.png` or `AC3_AC4.md` indicate the acceptance criteria they cover.

- **Committed to Git today:** `DON-01/`, `DON-02/` and `DON-03/`, with the earlier numbered screenshots (`1.png`, …).
- **Local only, not yet committed or pushed:** the reorganized AC files of `DON-01` to `DON-03`, and the whole `DON-04`, `DON-08`, `DON-10`, `DON-11` and `DON-12` folders. They are not available on GitHub until the owner commits them. One DON-11 screenshot shows a personal email address and must be cropped first.
- The [story tracking board](docs/story-tracking-board.md) lists the evidence of every story and marks which folders are tracked.

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

- The demo campaign and donation records are **already loaded** in the Sandbox and have been adjusted by hand since (names, descriptions, states, images). Do not run `sf data import tree` or `data/demo/plan.json` (the plan is only in the unmerged PR #48) again: the import uses inserts and would create duplicates, and the plan files no longer match the current records.
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