# DON-05: technical evidence (2026-11-17)

Story: **DON-05, view closed campaigns and their results** (issue #6). Sandbox `donations-dev` (`uady--class2026b`), site «Mexico Dreamin Donation Portal», `https://uady--class2026b.sandbox.my.site.com/portal/`.

No personal data appears in this folder: the only email used is `prueba.portal@example.com` (in the form screenshot). Only campaign names, amounts and Salesforce IDs are quoted. The campaigns are test campaigns.

**Result: AC1, AC2 and AC3 and the two technical tasks are verified.** AC2 is verified with automated tests, because the Sandbox has closed campaigns and no record was changed to build an empty state.

## What was already done before this verification

| Item | ID | Result |
|---|---|---|
| Implementation PR #62 (merge) | `0fa7685324694a87e54b64f5a55a557f2d2ee6a4` | Merged 2026-11-17 |
| Check-only before deployment | `0AfVC00000PI9Pp0AL` | Succeeded, 8/8 components, 149/149 Apex tests |
| Real deployment | `0AfVC00000PI9T30AL` | Succeeded, 8/8 components, 149/149 Apex tests |
| Site publication | job `08PVC00000gD9Bp2AK` | Complete |
| Earlier guest check (same day) | n/a | 40/40 checks at 1280 and 360 px, with 2 closed campaigns at that time |

The earlier screenshots in `Temp/don05-run/` were not reused: the catalog changed afterwards (more campaigns, images) and a third closed campaign appeared. All screenshots here were taken again.

## New verification (2026-11-17, nothing deployed, nothing published)

Data read from Salesforce (SOQL, read only), the 3 closed campaigns:

| Campaign | ID | Goal | `Total_Raised__c` | Closing date | Confirmed donations |
|---|---|---|---|---|---|
| [PRUEBA Rodrigo] DON-19 AC3 | `a1bVC000008q3EwYAI` | 1,000 | 0 | 2026-11-30 | 0 |
| [PRUEBA] Campaña cerrada | `a1bVC000008jevxYAA` | 2,000 | 0 | 2026-10-31 | 0 |
| [PRUEBA Rodrigo] DON-24 | `a1bVC000008pm2nYAA` | 1,000 | 100 | none | 1 (anonymous, 100) |

Counts before and after all the checks: 69 payment attempts, 25 donations (1 attempt belongs to a closed campaign). Nothing was created, changed or deleted.

Raw outputs: `guest-checks.txt` (59 of 59 checks pass), `focus-check.txt` (3 of 3), `jest-results.txt`, `apex-check-only.txt`.

## AC1: the history shows name, goal and final total

| | |
|---|---|
| Steps | 1. Open the portal as a guest (new browser context, no session). 2. Press «Ver campañas cerradas» in the catalog. 3. Read the three cards. 4. Compare with the Apex response a guest receives and with the SOQL above. |
| Expected | Each closed campaign shows its name, goal («Meta») and final total («Total final»), with the «Cerrada» label. |
| Obtained | The history opens at `/portal/?vista=historial` with title «Historial de campañas» and «3 campañas cerradas». The three cards show the names, goals and totals above: `$0 MXN` / `$1,000 MXN`, `$0 MXN` / `$2,000 MXN` and `$100 MXN` / `$1,000 MXN` (10 % of the goal, «1 donación confirmada»). Each card has the «Cerrada» label. The Apex response for the guest (`getClosedCampaigns`) returns exactly those three campaigns with the same name, goal and total, all with `status = Closed`, `availability = CLOSED` and `canDonate = false`, and no email or tax field. The same checks pass at 360 px. |
| Evidence | `AC1_catalogo-1280.png` (link «Ver campañas cerradas»), `AC1_historial-1280.png`, `AC1_historial-360.png`, `guest-checks.txt`. |

## AC2: message when there are no closed campaigns

| | |
|---|---|
| Steps | Run `npm run test:unit` and `npx jest force-app/main/default/lwc/closedCampaignHistory --verbose`. Run the Apex check-only (`apex-check-only.txt`). |
| Expected | With no closed campaigns the history shows «No hay campañas cerradas para consultar por ahora», with no cards or invented data. |
| Obtained | **Jest:** the test «shows the empty message, and no invented cards, when there are no closed campaigns» passes. It mocks an empty answer from Apex and checks that there is no grid and no card, that the `role="status"` paragraph reads exactly «No hay campañas cerradas para consultar por ahora», and that the count is not shown. The suite has 16 tests and all pass; the whole project has 8 suites and 228 tests, all passing. **Apex:** `shouldReturnEmptyList_WhenThereAreNoClosedCampaigns` passes in the check-only (`0AfVC00000PIB1q0AH`, 110/110 tests, `CampaignPortalController` 98/98 lines). The test works on its own test data. |
| Evidence | `jest-results.txt`, `apex-check-only.txt`. |
| Limit | There is no screenshot of the empty state in the Sandbox, on purpose: the Sandbox has 3 closed campaigns and no state or record was changed to hide them. The empty state is evidenced by the automated tests only. |

## AC3: a closed campaign cannot receive donations

| | |
|---|---|
| Steps | 1. From the history, open a closed campaign. 2. Look for a donate action. 3. Open `?campana=<closed Id>&donar=1`, choose 100 MXN, type a test email and press «Continuar al pago». 4. As a guest, call `startDonation` of `DonationIntakeService` and of `DonationPaymentController` for the two closed campaigns with no donations of their own (no payment is made). 5. Compare the record counts. |
| Expected | No way to donate in the portal; the server rejects the request; no payment attempt is created. |
| Obtained | **Portal:** the history cards have no donate button or text. The detail shows «Cerrada» and «Esta campaña está cerrada y ya no acepta donaciones.», and the button «Donaciones cerradas» is disabled; there is no enabled «Donar» button. At 1280 and 360 px. **Server:** both routes answer HTTP 400 with «Esta campaña ya no acepta donaciones.» for both campaigns tried (4 of 4). **Form:** with `donar=1` in the URL, pressing «Continuar al pago» shows «No pudimos continuar. Esta campaña ya no acepta donaciones.» and the browser stays in the portal (no redirect to Mercado Pago). **Records:** attempts stayed at 69 and donations at 25. Apex tests: `shouldNeverAllowDonating_WhenCampaignIsInTheHistory` and `shouldSaveNoAttempt_WhenClosedCampaignIsSentStraightToThePaymentController`. |
| Evidence | `AC3_detalle-cerrada-1280.png`, `AC3_detalle-cerrada-360.png`, `AC3_donar-bloqueado-1280.png`, `guest-checks.txt`, `apex-check-only.txt`. |

## Technical tasks

| Task | Result | How it was checked |
|---|---|---|
| The history query is read only and is the only public place where closed campaigns are listed | Verified | `getClosedCampaigns` only reads (query in user mode, `Status__c = Closed`). Apex test `shouldLeaveRecordsUnchanged_WhenGuestOpensHistory` passes. The catalog lists 5 campaigns and none of the 3 closed ones (`AC1_catalogo-1280.png`). Record counts did not change during the guest run. A closed campaign can still be opened by its direct link (DON-02), which shows information only. |
| Closed campaigns are not part of the set eligible for payments | Verified | The server rejects the payment request for closed campaigns on both entry points (see AC3), and the guest receives `canDonate = false`. |
| The history totals match the confirmed donations | Verified | `Total_Raised__c` is a roll-up of `Donation__c`. For the campaign with data, 100 equals the sum of its one confirmed donation, which is anonymous, so anonymous donations count. The other two have no donations and show 0. The totals do not include payment attempts: they equal the sum of donations. The status of the attempt that belongs to a closed campaign was not read (the verifier no longer has read access to attempt status). |

## Accessibility and responsive checks (not part of the original AC)

Done as a guest on the published site. Reported apart from AC1 to AC3.

| Check | Result |
|---|---|
| Layout at 1280 px and 360 px (catalog, history, detail) | No horizontal scroll in any of them; the history shows 3 columns at 1280 px and 1 column at 360 px. |
| Navigation | «Volver a las campañas» from a detail opened in the history returns to the history; Back returns to the detail; Forward returns to the history, with no reload. |
| Keyboard | Tab reaches «Volver a las campañas» and the three campaign buttons; Enter on a card opens its detail. Each card shows a solid 2 px outline when it has focus (`A11Y_foco-tarjeta-1280.png`, `focus-check.txt`); «Volver a las campañas» shows the Lightning focus shadow. The first measurement of this check read the button instead of the card, where the outline is defined, and reported a false failure; the check was corrected and repeated. |
| Structure for assistive technology (read from the accessibility tree, not with a screen reader) | One `h1`; the count is a `status`; the cards are a named list; each card has an image with a text alternative and a button with the name «Ver detalle de la campaña …». |
| Screen reader | **Not done.** No screen reader was run. |
| Contrast | Not measured in this verification. |

## Observations

- The campaign images in `AC1_catalogo-1280.png` include the «Kits de bienvenida» image, which shows the brand «CONNECT SUMMIT 2025» (another event). This is known and not part of DON-05.
- The three closed campaigns are test campaigns (names with `[PRUEBA]`), and none has an image, so the history shows the placeholder.
- The Project 13 status of DON-05 is the source of truth for the workflow status and is not changed by this document.
