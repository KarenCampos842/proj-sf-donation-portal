# DON-02 — Evidence for AC3 and AC4

**Story:** View campaign details  
**Repository:** [KarenCampos842/proj-sf-donation-portal](https://github.com/KarenCampos842/proj-sf-donation-portal)  
**Related implementation:** [PR #49 — Workstream B portal](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49)

This document records the code and automated-test evidence for the behavior of paused and closed campaign details.

## AC3 — A paused or closed campaign remains consultable and explains that donations are unavailable

**Acceptance criterion**  
Given that a campaign is Paused or Closed, when I open its detail, then I can read its information and see that it does not accept donations.

### Evidence

1. **Server-side detail retrieval — Apex**
   - [`CampaignPortalControllerTest.shouldReturnDetailWithoutDonation_WhenCampaignIsPaused`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L219-L226) verifies that the guest user receives a non-null detail for a paused campaign and that its availability is `PAUSED`.
   - [`CampaignPortalControllerTest.shouldReturnDetailWithoutDonation_WhenCampaignIsClosedAndOpenedByDirectLink`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L228-L235) verifies that a closed campaign can be opened by its Id and is returned with availability `CLOSED`.
   - [`CampaignPortalController.getCampaignDetail` and `findConsultableCampaign`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalController.cls#L128-L165) implement retrieval of public campaign details, including the closed-campaign read path.

2. **Visible detail and unavailable-donation notice — Jest**
   - [`campaignDetail.test.js` — paused campaign](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/__tests__/campaignDetail.test.js#L118-L132) verifies the `Pausada` badge and the message: “Esta campaña está pausada y por ahora no acepta donaciones.”
   - [`campaignDetail.test.js` — closed campaign](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/__tests__/campaignDetail.test.js#L134-L148) verifies the `Cerrada` badge and the message: “Esta campaña está cerrada y ya no acepta donaciones.”
   - [`campaignDetail.html`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/campaignDetail.html#L90-L105) renders the campaign description in the detail section while the campaign record is available.

**Result:** The Apex tests verify that paused and closed campaign details are returned; the component tests verify the corresponding status badge and explanatory notice.

## AC4 — The donor cannot start a donation from a paused or closed campaign detail

**Acceptance criterion**  
Given that a campaign is Paused or Closed, when I try to donate from its detail, then I cannot start the donation.

### Evidence

1. **Apex eligibility result**
   - The paused and closed detail tests above also assert `detail.canDonate == false`.
   - [`CampaignPortalController.toDto`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalController.cls#L228-L243) calculates `canDonate` as true only when availability is `OPEN` and `Accepts_Donations__c` is true.

2. **Disabled action and blocked event — Jest**
   - [`campaignDetail.test.js` — paused campaign](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/__tests__/campaignDetail.test.js#L118-L132) verifies that the button is disabled, simulates a click, and confirms that no `donationstart` event is emitted.
   - [`campaignDetail.test.js` — closed campaign](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/__tests__/campaignDetail.test.js#L134-L148) verifies the same behavior for a closed campaign.
   - [`campaignDetail.html`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/campaignDetail.html#L78-L95) displays the normal “Donar” action only when `canDonate` is true; otherwise it renders an informational notice and a disabled button.
   - [`campaignDetail.js`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/campaignDetail.js#L88-L124) also guards `handleDonate()` and returns without emitting `donationstart` when `canDonate` is false.

3. **Server-side revalidation**
   - [`Payment_Attempt_Create` Flow](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/flows/Payment_Attempt_Create.flow-meta.xml) checks that the campaign exists and `Accepts_Donations__c` is true before it proceeds to create a payment attempt. This provides a server-side eligibility check in addition to the disabled UI action.

**Result:** Both the Apex response and the component tests establish that Paused and Closed campaigns have `canDonate = false`; the interface disables the action and does not emit the event that starts the donation flow. The payment-attempt Flow independently rechecks campaign eligibility on the server.

## Test and implementation references

- [PR #49 — portal implementation and test report](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49)
- [CampaignPortalControllerTest.cls](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls)
- [campaignDetail.test.js](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/__tests__/campaignDetail.test.js)
- [CampaignPortalController.cls](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalController.cls)
- [campaignDetail.html](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/campaignDetail.html)
- [campaignDetail.js](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/campaignDetail.js)
- [Payment_Attempt_Create.flow-meta.xml](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/flows/Payment_Attempt_Create.flow-meta.xml)

## Evidence limitations

- The automated component tests simulate the Apex response; they verify the component behavior for both statuses but are not themselves a new manual checkout in the live Sandbox.
- The repository's `docs/tablero.md` records one local, uncommitted screenshot at `docs/evidence/DON-02/1.png` showing a paused campaign detail with the disabled “Donaciones en pausa” button. That screenshot is supplementary and does not visually demonstrate the closed-campaign case.
- No claim is made here that a real payment was attempted against a paused or closed campaign. The automated UI tests verify that the detail component does not emit the event that would start the donation flow, and the server Flow provides a separate eligibility check.
