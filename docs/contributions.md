# Contribution Log

One section per milestone, organized by workstream. Every row links to evidence that exists today (stories, PRs, commits, AI log entries, evidence folders). Cut-off date: 2026-11-10.

Workstreams (from the backlog split):
- **Workstream A — Rodrigo Colli (@RodrigoPeraza):** payments with Mercado Pago.
- **Workstream B — Karen Elizabeth Campos (@KarenCampos842):** public portal and Salesforce object implementation.
- **Workstream C — Alan Perez Romero (@Alambrep):** internal operation, security testing and data model.

Stories link to their GitHub issue in [`story-tracking-board.md`](story-tracking-board.md), which also holds the current Project 13 status, the open/closed state of each issue and the evidence per story.

**Reading this log:** a story listed here is implemented by that member, not necessarily formally accepted. Acceptance needs all acceptance criteria evidenced and security minimums M1–M3 met (Definition of Done in the [README](../README.md)).

## Delivery 1

### Workstream A — Rodrigo Colli

| Item | Detail |
|---|---|
| Stories | DON-19, DON-20, DON-21, PAY-02, PAY-07, ADM-07 (all closed; shown as In review in Project 13) |
| Other tasks | TEC-02 (Mercado Pago test), TEC-05 (credentials), TEC-08 (professor clarifications) |
| PR | [#47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47), merged |
| Commits | [`c4745a4`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/c4745a4) payment attempt and donation registration flows (PAY-07, PAY-02, ADM-07); [`9064f8c`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/9064f8c) Checkout Pro payment (DON-19); [`dac7ff1`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/dac7ff1) payment check on return (DON-21, DON-20); [`7c048b8`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/7c048b8) `DonationPaymentController`; [`1cf0dba`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/1cf0dba) AI log entries |
| AI log | Entries 4 and 5 |
| Documents | [`payments-api.md`](payments-api.md) |
| Evidence folders | None for these stories in `docs/evidence/` |
| Approx. hours | Not reported |

### Workstream B — Karen Elizabeth Campos

| Item | Detail |
|---|---|
| Stories | DON-01, DON-02, DON-03, DON-04, DON-08, DON-10, DON-11, DON-12 (all Done in Project 13 and closed, every AC ticked) |
| Other tasks | TEC-03 (Experience Cloud site); implementation of the three Salesforce objects (`Fundraising_Campaign__c`, `Payment_Attempt__c`, `Donation__c`); backlog as GitHub issues and board; Sandbox data work (campaign renames, descriptions, states and images) |
| PRs | [#49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) (portal, LWR site, Guest profile, sharing rule), [#50](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/50) (field configurations, documentation, first evidence images); both merged |
| Commits | [`384491f`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/384491f) D1 data model; [`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5) portal backend and LWC; [`6bcee0f`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/6bcee0f) form connected to the payment code; [`a9fdb8a`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/a9fdb8a) closed-campaign read check; [`d8f0ad6`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d8f0ad6) payment result page; [`f3ae52f`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/f3ae52f) guide with results; [`4a30afe`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/4a30afe) LWR site, Guest profile, sharing rule; [`dba1654`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/dba1654) field configurations and documentation |
| Not in Git yet | `PublicNameSanitizer` and its test, plus changes in `DonationIntakeService` and `DonationPaymentController` (DON-11 public-name cleaning). Deployed to the Sandbox on 2026-11-10 but still uncommitted local work |
| AI log | Entries 1, 2, 3, 6 and 7 |
| Documents | [`experience-builder-guide.md`](experience-builder-guide.md), [`data-model.md`](data-model.md) (implementation notes) |
| Evidence folders | [`evidence/DON-01/`](evidence/DON-01/), [`evidence/DON-02/`](evidence/DON-02/), [`evidence/DON-03/`](evidence/DON-03/) are tracked (earlier numbered screenshots only). `docs/evidence/DON-04/`, `DON-08/`, `DON-10/`, `DON-11/`, `DON-12/` and the reorganized AC files of DON-01 to DON-03 exist locally and are **not committed**. See the [evidence table](story-tracking-board.md#evidence-folders) |
| Approx. hours | **About 16 h in total**, the member's own estimate for the whole workstream. No hours per story are recorded |

### Workstream C — Alan Perez Romero

| Item | Detail |
|---|---|
| Stories | GES-02, GES-03, GES-06, GES-07, GES-09, ADM-03, ADM-05, SEG-01. GES-03 is closed (In review); GES-02, GES-06, GES-07, GES-09, ADM-03 and ADM-05 are In progress; SEG-01 is Ready |
| Other tasks | TEC-01 (org setup), TEC-04 (data model, `docs/data-model.md`), TEC-06 (demo data) |
| PRs | [#2](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/2) (data model draft), [#46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) (D1 configuration: permission sets, list views, tabs, donation rules, RFC flow); both merged. [#48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) (demo data, `Portal_Developer` permission set, logs) is **open and not merged**: it conflicts with `main` in `docs/ai-log.md` and `docs/contributions.md` |
| Commits | [`e51f5ee`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/e51f5ee) data model draft; [`0305978`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/0305978) AI usage log; [`44e8a0e`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/44e8a0e) D1 configuration. The commit messages do not name the stories |
| AI log | No entry attributed to Alan in the current `ai-log.md`; PR #48 also edits that file and is not merged |
| Documents | [`data-model.md`](data-model.md), [`security.md`](security.md) |
| Evidence folders | None for these stories in `docs/evidence/` |
| Approx. hours | Not reported |

## Delivery 2

All Delivery 2 stories are in the Backlog of Project 13 and their issues are open.

| Member | Stories / tasks | Evidence | Approx. hours |
|---|---|---|---|
| Rodrigo Colli | DON-24, PAY-01, PAY-03, PAY-06, ADM-12 | | |
| Alan Perez Romero | DON-23, GES-10, GES-11, GES-12, GES-15, MOD-01, MOD-03, MOD-06, ADM-01, ADM-04, ADM-13 | | |
| Karen Elizabeth Campos | DON-05, DON-09, DON-13, DON-17, DON-18 | | |

DON-26 (view the portal in another language) is assigned to Karen and has no milestone: it is not scheduled for Delivery 1 or Delivery 2.

GES-11 and DON-23 are assigned to Alan in GitHub; earlier versions of this log listed GES-11 under Karen.

## Shared tasks (all)

| Task | Owner | Evidence |
|---|---|---|
| `ai-log.md` (each person writes their part) | All | |
| `security.md` | Alan | |
| `questions-and-reports.md` | Rodrigo | |
| `contributions.md` | All | |
