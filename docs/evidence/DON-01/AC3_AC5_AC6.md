# DON-01 — Evidence for AC3, AC5 and AC6

**Story:** [DON-01 — Consultar las campañas disponibles](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/1)  
**Implementation PR:** [PR #49 — Workstream B E1](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49)  
**Sandbox portal:** https://uady--class2026b.sandbox.my.site.com/portal/

This document consolidates the code and automated-test evidence for the three acceptance criteria. The tests cover the server-side campaign filtering and the client-side empty state. They are not a substitute for a live screenshot of the deployed portal; no screenshot specifically covering AC3, AC5 or AC6 is currently referenced in `docs/tablero.md`.

---

## AC3 — Active campaign with a future start date is not listed

**Acceptance criterion**  
Given a campaign is Active but its start date has not arrived, when I open the portal, then it does not appear.

**Automated test**  
`CampaignPortalControllerTest.shouldExcludeActiveCampaign_WhenStartDateIsInTheFuture`

The test data creates an Active campaign named `Campaña activa futura` with a start date five days after the test's current date. The test calls the catalog as the simulated guest user and asserts that the campaign name is not present in the returned list.

**Implementation reference**  
`CampaignPortalController.getAvailableCampaigns()` filters records using `Start_Date__c <= :today`. The condition is applied server-side in the SOQL query, not only in the UI.

**References**

- [Apex test — future Active campaign excluded (lines 84–87)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L84-L87)
- [Apex controller — catalog date and status filter (lines 39–81)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalController.cls#L39-L81)
- [PR #49 — portal implementation and test results](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49)

---

## AC5 — Exact empty-state message when no campaigns are available

**Acceptance criterion**  
Given there are no available campaigns, when I enter the portal, then I see: `No hay campañas disponibles por ahora`.

**Automated tests**

1. `CampaignPortalControllerTest.shouldReturnEmptyList_WhenNoCampaignIsAvailable` changes all test campaigns to `Draft`, calls the catalog as the simulated guest user, and asserts that the returned campaign list is empty.
2. `campaignList.test.js` — `shows the exact empty message when there are no campaigns` mocks an empty response from `getAvailableCampaigns()` and asserts that the campaign grid is not rendered and the exact message `No hay campañas disponibles por ahora` appears in the status paragraph.

**Implementation reference**  
`campaignList.html` renders `messages.empty` when `isEmpty` is true. `portalMessages.js` defines that value as `No hay campañas disponibles por ahora`.

**References**

- [Apex test — empty catalog response (lines 143–154)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L143-L154)
- [Jest test — exact empty-state message (lines 160–171)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignList/__tests__/campaignList.test.js#L160-L171)
- [Template — empty-state rendering (lines 21–24)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignList/campaignList.html#L21-L24)
- [Spanish message definition (lines 13–18)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/portalMessages/portalMessages.js#L13-L18)
- [PR #49 — portal implementation and test results](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49)

---

## AC6 — Draft and Closed campaigns are not listed

**Acceptance criterion**  
Given a campaign is Draft or Closed, when I open the catalog, then it does not appear.

**Automated tests**

- `CampaignPortalControllerTest.shouldExcludeDraftCampaign_WhenGuestOpensCatalog` asserts that `Campaña en borrador` is absent from the catalog.
- `CampaignPortalControllerTest.shouldExcludeClosedCampaign_WhenGuestOpensCatalog` asserts that `Campaña cerrada` is absent from the catalog.
- `CampaignPortalControllerTest.shouldExcludeClosedCampaignWithFutureStart_WhenGuestOpensCatalog` also asserts that a Closed campaign with a future start date is absent.

**Implementation reference**  
The `getAvailableCampaigns()` query only returns eligible Active campaigns within their dates and Paused campaigns whose start date has arrived. Draft and Closed are not included in the allowed status conditions.

**References**

- [Apex tests — Draft and Closed campaigns excluded (lines 89–103)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L89-L103)
- [Apex controller — catalog status and date filter (lines 39–81)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalController.cls#L39-L81)
- [PR #49 — portal implementation and test results](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49)

---

## Test and deployment context

The PR #49 description reports that the Workstream B deployment to the Sandbox completed successfully with **137/137 Apex tests** and **136 Jest tests across 7 suites**. These are the overall reported results for that deployment, not individual execution logs for each test named above.

- [PR #49 — deployment and test summary](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49)
- [Experience Builder guide — deployed portal and validation notes](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/docs/experience-builder-guide.md)
- [DON-01 tracking row in `docs/tablero.md`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/docs/tablero.md#L50-L53)

## Evidence scope and remaining visual check

The automated tests provide evidence for the filtering logic and empty-state rendering. For a visual demonstration against the currently deployed Sandbox, capture the following without changing production or test data:

1. AC3: show the portal catalog with an Active campaign whose start date is in the future excluded. The Apex test uses isolated test data, so it does not identify a real Sandbox record for this screenshot.
2. AC5: show the portal's exact empty-state message. This requires a safe test environment or a controlled dataset with no eligible public campaigns; do not change shared Sandbox campaigns just to obtain the screenshot.
3. AC6: show the catalog with Draft and Closed campaigns omitted. The Apex test uses isolated test data; a screenshot should use a controlled dataset and must not expose internal or personal data.

No claim is made here that those three visual screenshots already exist. The evidence currently cited is code plus automated tests.
