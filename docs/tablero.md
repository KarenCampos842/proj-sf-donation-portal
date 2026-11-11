# Story Tracking Board

Tracking of the 44 user stories of **proj-sf-donation-portal** (SF Vibe Lab, UADY x Salesforce) by milestone and workstream. Cut-off date: **2026-11-10** (Delivery 1 is due at 23:59, Mérida time).

- **Source of truth for status:** the GitHub Projects board ([Project 13](https://github.com/users/KarenCampos842/projects/13)). This table reflects its status at the cut-off and does not change it.
- **Stories, acceptance criteria and owners:** the [GitHub Issues](https://github.com/KarenCampos842/proj-sf-donation-portal/issues). Owners are the assignees of each issue and were not changed.
- **Story names:** English translations of the Spanish GitHub issue titles. The issue links lead to the original titles and acceptance criteria. GitHub milestone names are “E1 - Primera entrega” and “E2 - Segunda entrega”.
- **Workstreams:** A = payments (Rodrigo Colli), B = public portal (Karen Elizabeth Campos), C = internal operation, security and data model (Alan Pérez Romero), following the split in `docs/contributions.md`. GitHub has no workstream field, so it is derived from the owner.
- **Implemented is not the same as fulfilled:** a story is fulfilled only when all its acceptance criteria, including negative ones, have evidence (demo, video or screenshot) without breaking M1–M3. TAC are not a condition. This table does not declare any story as fulfilled.

## Update rules

1. **Hours:** recorded only when verifiable data exists per story. Until then the cell says “Pending”. AI Log time-saving estimates are not hours spent and are not used here.
2. **Evidence:** only commits, PRs, tests, screenshots, documents or AI Log entries that exist. Local screenshots that are not committed are marked as such.
3. **Status:** copied from the board. If the board status and the issue state differ, it is listed under “Inconsistencies”.
4. **Owners:** not changed here. Any difference is reported under “Items to confirm”.

## Summary

| Milestone | WS | Stories | Backlog | Ready | In progress | In review | Done |
|---|---|---:|---:|---:|---:|---:|---:|
| E1 | A | 6 | 0 | 0 | 0 | 6 | 0 |
| E1 | B | 8 | 0 | 5 | 0 | 0 | 3 |
| E1 | C | 8 | 0 | 1 | 7 | 0 | 0 |
| E2 | A | 5 | 5 | 0 | 0 | 0 | 0 |
| E2 | B | 5 | 5 | 0 | 0 | 0 | 0 |
| E2 | C | 11 | 11 | 0 | 0 | 0 | 0 |
| No milestone | B | 1 | 0 | 1 | 0 | 0 | 0 |
| **Total** | | **44** | 21 | 7 | 7 | 6 | 3 |

Board states: Backlog → Ready → In progress → In review → Done.

## E1 — First delivery

### Workstream A · Payments with Mercado Pago (Rodrigo Colli) — 6 stories

| ID | Story | RF | Owner | Milestone · WS | Status (board · issue) | Hours | Evidence | Issue |
|---|---|---|---|---|---|---|---|---|
| DON-19 | Pay by card | RF-D3 | Rodrigo Colli (RodrigoPeraza) | E1 · A | In review · issue closed | Pending | [PR #47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47) (merged 2026-11-10); [`9064f8c`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/9064f8c) (Checkout Pro), [`7c048b8`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/7c048b8) (`DonationPaymentController`); `docs/payments-api.md`; AI Log #4 and #5. | [#15](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/15) |
| DON-20 | Understand a cancelled or rejected payment | RF-D4 | Rodrigo Colli (RodrigoPeraza) | E1 · A | In review · issue closed | Pending | [PR #47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47); [`dac7ff1`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/dac7ff1) (payment check on return, DON-21 and DON-20); AI Log #4. | [#16](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/16) |
| DON-21 | See the result of my payment on return | RF-D4 | Rodrigo Colli (RodrigoPeraza) | E1 · A | In review · issue closed | Pending | [PR #47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47); [`dac7ff1`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/dac7ff1); portal return page (B): [`d8f0ad6`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d8f0ad6) (`donationThankYou`); AI Log #4. | [#17](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/17) |
| ADM-07 | Trace a donation to its payment | RF-D3 | Rodrigo Colli (RodrigoPeraza) | E1 · A | In review · issue closed | Pending | [PR #47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47); [`c4745a4`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/c4745a4) (flows for PAY-07, PAY-02 and ADM-07); AI Log #4 and #5. | [#37](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/37) |
| PAY-02 | Register the donation only after confirmation | RF-D5 | Rodrigo Colli (RodrigoPeraza) | E1 · A | In review · issue closed | Pending | [PR #47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47); [`c4745a4`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/c4745a4); AI Log #4 and #5. | [#41](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/41) |
| PAY-07 | Save the payment attempt | RF-D3 | Rodrigo Colli (RodrigoPeraza) | E1 · A | In review · issue closed | Pending | [PR #47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47); [`c4745a4`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/c4745a4); AI Log #4 and #5. | [#44](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/44) |

### Workstream B · Public portal and Salesforce objects (Karen Elizabeth Campos) — 8 stories

| ID | Story | RF | Owner | Milestone · WS | Status (board · issue) | Hours | Evidence | Issue |
|---|---|---|---|---|---|---|---|---|
| DON-01 | View the available campaigns | RF-D1a, RFV1 | Karen Elizabeth Campos (KarenCampos842) | E1 · B | Done · issue closed | Pending | [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) (merged 2026-11-10); [`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5), [`a9fdb8a`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/a9fdb8a) (`CampaignPortalController`, `campaignList`); tests `CampaignPortalControllerTest`, `campaignList.test.js`; `docs/experience-builder-guide.md` §7 (per the guide: deployment `0AfVC00000PBhkn0AD`, 31/31 components and 137/137 Apex tests; Jest 136 tests in 7 suites); AI Log #7.<br>Local screenshots, **not committed**: `docs/evidence/DON-01/1.png` (donation form opened in an incognito window, no session), `2.png` (detail with image, goal and progress), `3.png` (catalog).<br>The screenshots show the earlier “(demo)” names and do not cover AC3, AC5 or AC6. | [#1](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/1) |
| DON-02 | View campaign details | RF-D1a | Karen Elizabeth Campos (KarenCampos842) | E1 · B | Done · issue closed | Pending | [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) (merged 2026-11-10); [`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5), [`a9fdb8a`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/a9fdb8a) (`getCampaignDetail`, `campaignDetail`); tests `CampaignPortalControllerTest`, `campaignDetail.test.js`; AI Log #7.<br>Local screenshot, **not committed**: `docs/evidence/DON-02/1.png` (paused campaign detail with the “Donaciones en pausa” button disabled).<br>The other AC have no screenshot in the repository. | [#3](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/3) |
| DON-03 | View campaign progress | RF-D1a | Karen Elizabeth Campos (KarenCampos842) | E1 · B | Done · issue closed | Pending | [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) (merged 2026-11-10); [`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5) (`CampaignDTO`, `campaignProgress`; progress from `Total_Raised__c`); tests `CampaignPortalControllerTest`, `campaignProgress.test.js`; AI Log #7.<br>Local screenshot, **not committed**: `docs/evidence/DON-03/1.png` (204 % with “Meta alcanzada” and 3 donations). That `[PRUEBA]` campaign is no longer public (Draft).<br>The other AC have no screenshot in the repository. | [#4](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/4) |
| DON-04 | See donor recognition | RF-C1 | Karen Elizabeth Campos (KarenCampos842) | E1 · B | Ready · issue open | Pending | [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) (merged 2026-11-10); [`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5) (`DonorRecognitionService`, `DonorRecognitionDTO`, `donorRecognitionList`); tests `DonorRecognitionServiceTest`, `donorRecognitionList.test.js`; AI Log #7. No screenshots in the repository.<br>Since AI Log #7 the 3 seeded public donations are Anonymous, so no public donors are visible today. | [#5](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/5) |
| DON-08 | Choose a suggested amount | RF-D1a | Karen Elizabeth Campos (KarenCampos842) | E1 · B | Ready · issue open | Pending | [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) (merged 2026-11-10); [`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5) (`donationForm`, `donationFormRules`), [`6bcee0f`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/6bcee0f) (`DonationIntakeService`); tests `donationForm.test.js`, `DonationIntakeServiceTest`; `docs/experience-builder-guide.md` §7 (per the guide: deployment `0AfVC00000PBhkn0AD`, 31/31 components and 137/137 Apex tests; Jest 136 tests in 7 suites).<br>`docs/evidence/DON-01/1.png` (not committed) shows the 8 amounts with none selected. No screenshot specific to DON-08. | [#7](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/7) |
| DON-10 | Donate anonymously | RF-D2 | Karen Elizabeth Campos (KarenCampos842) | E1 · B | Ready · issue open | Pending | [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) (merged 2026-11-10); [`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5), [`6bcee0f`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/6bcee0f) (`donationForm`, `DonationIntakeService`); tests `donationForm.test.js`, `DonationIntakeServiceTest`; AI Log #7.<br>`docs/evidence/DON-01/1.png` (not committed) shows the “Donar de forma anónima” toggle on by default. No screenshot specific to DON-10. | [#9](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/9) |
| DON-11 | Donate with public recognition | RF-C1 | Karen Elizabeth Campos (KarenCampos842) | E1 · B | Ready · issue open | Pending | [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) (merged 2026-11-10); [`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5), [`6bcee0f`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/6bcee0f) (`donationForm`, `DonationIntakeService`, `DonorRecognitionService`); tests `donationForm.test.js`, `DonationIntakeServiceTest`, `DonorRecognitionServiceTest`; AI Log #7. No screenshots in the repository. | [#10](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/10) |
| DON-12 | Request an invoice | RF-F1 | Karen Elizabeth Campos (KarenCampos842) | E1 · B | Ready · issue open | Pending | [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) (merged 2026-11-10); [`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5), [`6bcee0f`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/6bcee0f) (`donationForm`, `donationFormRules`, `DonationIntakeService`); tests `donationForm.test.js`, `DonationIntakeServiceTest`; `docs/experience-builder-guide.md` §7 (per the guide: deployment `0AfVC00000PBhkn0AD`, 31/31 components and 137/137 Apex tests; Jest 136 tests in 7 suites). No screenshots in the repository. | [#11](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/11) |

### Workstream C · Internal operation, security and data model (Alan Pérez Romero) — 8 stories

| ID | Story | RF | Owner | Milestone · WS | Status (board · issue) | Hours | Evidence | Issue |
|---|---|---|---|---|---|---|---|---|
| GES-02 | View campaign status and progress | RF-S1 | Alan Pérez Romero (Alambrep) | E1 · C | In progress · issue open | Pending | Related, but the commit does not name the story: [PR #46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) ([`44e8a0e`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/44e8a0e): permission sets, list views, tabs, donation rules and RFC flow; merged 2026-11-09). [PR #48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) (demo data, open). Per-story evidence to be confirmed by the owner. | [#21](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/21) |
| GES-03 | Prepare a campaign | RF-S1 | Alan Pérez Romero (Alambrep) | E1 · C | In progress · issue open | Pending | Related, but the commit does not name the story: [PR #46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) ([`44e8a0e`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/44e8a0e): permission sets, list views, tabs, donation rules and RFC flow; merged 2026-11-09). [PR #48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) (demo data, open). Per-story evidence to be confirmed by the owner. | [#22](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/22) |
| GES-06 | Activate a campaign | RF-S1 | Alan Pérez Romero (Alambrep) | E1 · C | In progress · issue open | Pending | Related, but the commit does not name the story: [PR #46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) ([`44e8a0e`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/44e8a0e): permission sets, list views, tabs, donation rules and RFC flow; merged 2026-11-09). [PR #48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) (demo data, open). Per-story evidence to be confirmed by the owner. | [#23](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/23) |
| GES-07 | Pause and resume a campaign | RF-S1 | Alan Pérez Romero (Alambrep) | E1 · C | In progress · issue open | Pending | Related, but the commit does not name the story: [PR #46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) ([`44e8a0e`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/44e8a0e): permission sets, list views, tabs, donation rules and RFC flow; merged 2026-11-09). [PR #48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) (demo data, open). Per-story evidence to be confirmed by the owner. | [#24](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/24) |
| GES-09 | Update a campaign | RF-S1 | Alan Pérez Romero (Alambrep) | E1 · C | In progress · issue open | Pending | Related, but the commit does not name the story: [PR #46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) ([`44e8a0e`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/44e8a0e): permission sets, list views, tabs, donation rules and RFC flow; merged 2026-11-09). [PR #48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) (demo data, open). Per-story evidence to be confirmed by the owner. | [#25](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/25) |
| ADM-03 | View all confirmed donations | RF-S2 | Alan Pérez Romero (Alambrep) | E1 · C | In progress · issue open | Pending | Related, but the commit does not name the story: [PR #46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) ([`44e8a0e`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/44e8a0e): permission sets, list views, tabs, donation rules and RFC flow; merged 2026-11-09). [PR #48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) (demo data, open). Per-story evidence to be confirmed by the owner. | [#34](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/34) |
| ADM-05 | Handle invoice requests | RF-F2 | Alan Pérez Romero (Alambrep) | E1 · C | In progress · issue open | Pending | Related, but the commit does not name the story: [PR #46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) ([`44e8a0e`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/44e8a0e): permission sets, list views, tabs, donation rules and RFC flow; merged 2026-11-09). [PR #48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) (demo data, open). Per-story evidence to be confirmed by the owner. | [#36](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/36) |
| SEG-01 | Test that a visitor cannot see other people's data | RF-V2 | Alan Pérez Romero (Alambrep) | E1 · C | Ready · issue open | Pending | Pending. The SEG-01 table in `docs/security.md` has its “Obtained” and “Evidence” cells empty; the guide (§7) lists the repeat run with a second team member as pending. | [#45](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/45) |

## E2 — Second delivery

### Workstream A · Payments with Mercado Pago (Rodrigo Colli) — 5 stories

| ID | Story | RF | Owner | Milestone · WS | Status (board · issue) | Hours | Evidence | Issue |
|---|---|---|---|---|---|---|---|---|
| DON-24 | Register a payment confirmed after closing | — | Rodrigo Colli (RodrigoPeraza) | E2 · A | Backlog · issue open | Pending | Pending. | [#19](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/19) |
| ADM-12 | View rejected-payment notices | RF-S4 | Rodrigo Colli (RodrigoPeraza) | E2 · A | Backlog · issue open | Pending | Pending. | [#38](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/38) |
| PAY-01 | Accept only authentic confirmations | RF-V3b | Rodrigo Colli (RodrigoPeraza) | E2 · A | Backlog · issue open | Pending | Pending. | [#40](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/40) |
| PAY-03 | Prevent duplicate donations | RF-V3b | Rodrigo Colli (RodrigoPeraza) | E2 · A | Backlog · issue open | Pending | Pending. | [#42](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/42) |
| PAY-06 | Receive the provider's confirmation | RF-V3a, RF-D5 | Rodrigo Colli (RodrigoPeraza) | E2 · A | Backlog · issue open | Pending | Pending. | [#43](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/43) |

### Workstream B · Public portal and Salesforce objects (Karen Elizabeth Campos) — 5 stories

| ID | Story | RF | Owner | Milestone · WS | Status (board · issue) | Hours | Evidence | Issue |
|---|---|---|---|---|---|---|---|---|
| DON-05 | View closed campaigns | — | Karen Elizabeth Campos (KarenCampos842) | E2 · B | Backlog · issue open | Pending | Pending. | [#6](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/6) |
| DON-09 | Enter another amount | RF-D1b | Karen Elizabeth Campos (KarenCampos842) | E2 · B | Backlog · issue open | Pending | Pending. | [#8](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/8) |
| DON-13 | Accept the privacy notice | — | Karen Elizabeth Campos (KarenCampos842) | E2 · B | Backlog · issue open | Pending | Pending. | [#12](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/12) |
| DON-17 | Correct invalid data | — | Karen Elizabeth Campos (KarenCampos842) | E2 · B | Backlog · issue open | Pending | Pending (E2). Reference: field validations already present in `donationForm` ([`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5)); they have not been evaluated formally against the AC. | [#13](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/13) |
| DON-18 | Review and confirm the donation | — | Karen Elizabeth Campos (KarenCampos842) | E2 · B | Backlog · issue open | Pending | Pending. | [#14](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/14) |

### Workstream C · Internal operation, security and data model (Alan Pérez Romero) — 11 stories

| ID | Story | RF | Owner | Milestone · WS | Status (board · issue) | Hours | Evidence | Issue |
|---|---|---|---|---|---|---|---|---|
| DON-23 | Receive a receipt by email | RF-D5 | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#18](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/18) |
| GES-10 | View the donations of a campaign | RF-S2 | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#26](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/26) |
| GES-11 | Stop accepting donations when the closing date arrives | — | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#27](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/27) |
| GES-12 | Close a campaign before its date | — | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#28](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/28) |
| GES-15 | View the final result of a campaign | — | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#29](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/29) |
| MOD-01 | View the published names | RF-C1 | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#30](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/30) |
| MOD-03 | Correct a public name | RF-C1 | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#31](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/31) |
| MOD-06 | View the donor's email | RF-S2 | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#32](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/32) |
| ADM-01 | Assign internal roles | — | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#33](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/33) |
| ADM-04 | Filter donations | RF-S2 | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#35](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/35) |
| ADM-13 | Adjust suggested amounts and minimum | RF-D1a | Alan Pérez Romero (Alambrep) | E2 · C | Backlog · issue open | Pending | Pending. | [#39](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/39) |

## No milestone

### Workstream B · Public portal and Salesforce objects (Karen Elizabeth Campos) — 1 story

| ID | Story | RF | Owner | Milestone · WS | Status (board · issue) | Hours | Evidence | Issue |
|---|---|---|---|---|---|---|---|---|
| DON-26 | View the portal in another language | — | Karen Elizabeth Campos (KarenCampos842) | No milestone · B | Ready · issue open | Pending | Pending. | [#20](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/20) |

## PR and commit traceability

| PR / commit | Date | Author | Content | Related stories |
|---|---|---|---|---|
| [PR #2](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/2) | 2026-11-09 | Alan Pérez | Data model draft (C) | Shared base |
| [`384491f`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/384491f) | 2026-11-09 | Karen Elizabeth Campos | D1 data model implementation (objects) | Shared base; AI Log #3 and #6 |
| [PR #46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46) · [`44e8a0e`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/44e8a0e) | 2026-11-09 | Alan Pérez | Workstream C D1 configuration: permission sets, list views, tabs, donation rules and RFC flow | C (E1) |
| [PR #47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47) · [`c4745a4`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/c4745a4), [`9064f8c`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/9064f8c), [`dac7ff1`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/dac7ff1), [`7c048b8`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/7c048b8) | 2026-11-09 and 2026-11-10 | Rodrigo Colli | Mercado Pago payment flows and `DonationPaymentController` | DON-19, DON-20, DON-21, PAY-02, PAY-07, ADM-07 |
| [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) · [`d792af5`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d792af5) | 2026-11-10 | Karen Elizabeth Campos | Portal backend and LWC (catalog, detail, progress, recognition, form, container) | DON-01, DON-02, DON-03, DON-04, DON-08, DON-10, DON-11, DON-12 |
| [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) · [`6bcee0f`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/6bcee0f) | 2026-11-10 | Karen Elizabeth Campos | Donation form connected to Workstream A payment code | DON-08, DON-10, DON-11, DON-12 |
| [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) · [`a9fdb8a`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/a9fdb8a) | 2026-11-10 | Karen Elizabeth Campos | Object read-access check in the closed-campaign reader | DON-02 |
| [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) · [`d8f0ad6`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/d8f0ad6) | 2026-11-10 | Karen Elizabeth Campos | Payment result page (`donationThankYou`) and return URL | DON-21 (return page in the portal) |
| [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) · [`f3ae52f`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/f3ae52f), [`4a30afe`](https://github.com/KarenCampos842/proj-sf-donation-portal/commit/4a30afe) | 2026-11-10 | Karen Elizabeth Campos | Experience Builder guide with results; LWR site, Guest profile and sharing rule | TEC-03 and Guest security (B) |
| [PR #48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) | open | Alan Pérez | Demo data, developer permission set and logs | Pending merge |

## Local evidence not committed

Files in `docs/evidence/` that are not versioned yet:

| File | What it shows | Story |
|---|---|---|
| `DON-01/1.png` | “Haz tu donación” form opened in an incognito window (URL `?campana=…&donar=1`), with the 8 amounts and the anonymous toggle | DON-01 AC1; also illustrates DON-08 and DON-10 |
| `DON-01/2.png` | Detail of “Boletos para Mexico Dreamin 2026 (demo)” with image, $15,000 goal, 10 % progress and the “Donar” button | DON-01 / DON-02 |
| `DON-01/3.png` | “Campañas disponibles” catalog (partial view, still showing `[PRUEBA]` campaigns and “(demo)” names) | DON-01 |
| `DON-02/1.png` | Detail of “Kits de bienvenida (demo pausada)” with the pause notice and the “Donaciones en pausa” button disabled | DON-02 |
| `DON-03/1.png` | Detail of “[PRUEBA] Campaña activa vigente”: $10,200 of $5,000, 204 %, “Meta alcanzada”, 3 donations | DON-03 |

The screenshots were taken before the campaigns were renamed and before the `[PRUEBA]` campaigns were removed from the catalog, so they show the earlier names.

## Hours

There are no verifiable hours per story, so the “Hours” column says “Pending” in every row. The only available data are aggregates:

| Member | D1 hours | Source |
|---|---|---|
| Karen Elizabeth Campos | Approximately 16 h (the member's own approximation, covering all her Workstream B stories, TEC-03, the three objects and the backlog as issues) | `docs/contributions.md`, local edit not committed |
| Rodrigo Colli | To be estimated | `docs/contributions.md` |
| Alan Pérez Romero | To be estimated | `docs/contributions.md` |

The AI Log entries (#4: “about 6 hours vs. 16–20 hours”, #7: “1–2 h vs. 3–4 h”) are time-saving estimates that the log itself marks as not timed; they are not recorded as hours spent.

## Inconsistencies

- **Rodrigo Colli, 6 Delivery 1 stories** (DON-19, DON-20, DON-21, ADM-07, PAY-02, PAY-07): the issue is **closed**, but the board shows them as **In review**.
- **DON-01, DON-02 and DON-03** are **Done** with every AC checkbox ticked, but the “Evidence” section of the three issues still says “Pendiente de evidencia”, and the repository screenshots (local, not committed) do not cover every AC.
- **No evidence in any issue:** in all 44 issues, the “Evidence” section still says “Pendiente de evidencia”.
- **DON-26** ([#20](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/20)) has no milestone in GitHub, so it appears under “No milestone”.
- **Workstream B status and code:** DON-04, DON-08, DON-10, DON-11 and DON-12 are still **Ready** although the code is merged in [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49). The status is kept as it is on the board.

## Items to confirm

- **Owners in `docs/contributions.md` versus GitHub** (none was changed):
  - **GES-11** ([#27](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/27)) is assigned to Alan Pérez Romero in GitHub, but `docs/contributions.md` lists it in Karen's Delivery 2.
  - **DON-23** ([#18](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/18)) is assigned to Alan Pérez Romero in GitHub and does not appear in any Delivery 2 row of `docs/contributions.md`.
- **Hours per story:** who records them and with what criterion.
- **Formal evidence for DON-04, DON-08, DON-10, DON-11 and DON-12:** no screenshots in the repository.
- **Local evidence:** decide whether `docs/evidence/` is versioned and how it is linked from the issues.
- **Uncommitted local changes** in `README.md`, `docs/ai-log.md`, `docs/contributions.md` and `docs/experience-builder-guide.md`; references to those documents refer to their local version.
- **Scope:** the issues cover 44 stories. The TEC-xx tasks cited in `docs/contributions.md` have no issue and are not in this board.
