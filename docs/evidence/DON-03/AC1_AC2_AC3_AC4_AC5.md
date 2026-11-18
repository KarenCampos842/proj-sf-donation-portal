# DON-03 — Evidence for AC1–AC5: Campaign progress

**Story:** [DON-03 — View campaign progress](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/4)  
**Implementation PR:** [PR #49 — Workstream B E1](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49)

This document links the implementation and automated tests that support the campaign-progress acceptance criteria. It distinguishes automated/code evidence from the remaining live end-to-end payment check.

## AC1. Total raised is the sum of confirmed donations

**Evidence**

- [CampaignPortalControllerTest.cls — `shouldReturnProgressBelowGoal_WhenCampaignHasConfirmedDonations()`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L327-L334) creates two donations for the same campaign (MXN 300 and MXN 200) and asserts a total raised of MXN 500, a 50% progress value and a count of two donations.
- [Total_Raised__c field metadata](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/objects/Fundraising_Campaign__c/fields/Total_Raised__c.field-meta.xml#L1-L13) defines a roll-up summary that sums `Donation__c.Amount__c` through `Donation__c.Campaign__c`.
- [Payment_Status__c field metadata](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/objects/Donation__c/fields/Payment_Status__c.field-meta.xml) defines `Confirmed` as the only picklist value and its default.

The test and field metadata support the expected sum: the campaign total is calculated from related donation records, not from payment attempts.

## AC2. Anonymous confirmed donations are included

**Evidence**

- [CampaignPortalControllerTest.cls — `shouldIncludeAnonymousDonations_WhenCalculatingProgress()`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L336-L341) asserts that the MXN 400 anonymous donation contributes to the campaign's total.
- [CampaignPortalControllerTest.cls — test setup](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L40-L55) creates an anonymous donation with amount MXN 400.

The roll-up sums the donation amount; it does not filter by public/anonymous visibility.

## AC3. The real percentage can exceed 100%, and an open campaign remains donatable

**Evidence**

- [CampaignPortalControllerTest.cls — `shouldReturnExactlyOneHundredPercent_WhenGoalIsReached()`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L350-L356) verifies 100% and confirms that reaching the goal does not disable donations.
- [CampaignPortalControllerTest.cls — `shouldReturnRealProgressAboveOneHundredPercent_WhenGoalIsExceeded()`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L358-L364) verifies a real value of 120% when MXN 600 has been raised against a MXN 500 goal.
- [campaignDetail.test.js — `keeps showing the real progress above 100 % without disabling an open campaign`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/__tests__/campaignDetail.test.js#L177-L183) verifies that an open campaign can show 150% progress while its donation button remains enabled.
- [campaignProgress.test.js — `shows the real percentage above 100 %`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignProgress/__tests__/campaignProgress.test.js#L49-L60) verifies that the text and accessible value show 120%, while the visual bar itself is capped at 100% of its track.
- [Progress_Percent__c field metadata](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/objects/Fundraising_Campaign__c/fields/Progress_Percent__c.field-meta.xml#L1-L13) defines the formula as `Total_Raised__c / Goal__c` without capping the percentage.
- [CampaignPortalController.cls — `toDto`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalController.cls#L228-L243) sets `canDonate` according to campaign availability and `Accepts_Donations__c`, not according to whether the goal has been reached.

## AC4. The progress reflects a newly confirmed donation after reloading the portal

**Implementation evidence**

- [Donation_Register.flow-meta.xml — payment status decision](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/flows/Donation_Register.flow-meta.xml#L263-L285) routes to donation registration only for a provider status of `approved`.
- [Donation_Register.flow-meta.xml — Create Donation](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/flows/Donation_Register.flow-meta.xml#L388-L455) creates `Donation__c`, sets `Payment_Status__c` to `Confirmed`, and copies the confirmed amount and campaign relationship from the payment attempt.
- [CampaignPortalController.cls — `getAvailableCampaigns()`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalController.cls#L43-L93) queries the campaign's roll-up and formula fields when the catalog is loaded. The Apex method is not declared `cacheable=true`.
- [CampaignPortalController.cls — `toDto`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalController.cls#L228-L243) passes the current `Total_Raised__c` and `Progress_Percent__c` values to the portal.
- [campaignList.js](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignList/campaignList.js#L12-L20) loads campaigns when the catalog component is initialized and exposes a refresh method. [campaignDetail.js](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/campaignDetail.js#L25-L43) and [lines 139–164](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/lwc/campaignDetail/campaignDetail.js#L139-L164) load the detail again when the component is initialized or refreshed.

**Important validation limitation**

The repository's [Experience Builder guide, §7](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/docs/experience-builder-guide.md#L278-L306) records that the manual end-to-end Checkout Pro test with the Mercado Pago test buyer was still pending. Therefore, the code path for registering an approved payment and re-querying campaign progress is documented, but this evidence does **not** by itself prove a real approved payment was completed and then observed in the live portal after a browser reload. To mark AC4 fully demonstrated, attach a sanitized screenshot or recording showing: (1) the confirmed donation in Salesforce, and (2) the updated campaign total/progress after reloading the public portal.

## AC5. Unconfirmed payments are excluded from progress

**Evidence**

- [CampaignPortalControllerTest.cls — `shouldNotCountPaymentAttempts_WhenCalculatingProgress()`](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/CampaignPortalControllerTest.cls#L343-L348) creates a MXN 500 payment attempt alongside a MXN 500 donation and asserts that the campaign total remains MXN 500. The attempt is not added to the total.
- [Total_Raised__c field metadata](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/objects/Fundraising_Campaign__c/fields/Total_Raised__c.field-meta.xml#L1-L13) confirms that the summary uses `Donation__c.Amount__c` and the campaign relationship, not `Payment_Attempt__c`.
- [Donation_Register.flow-meta.xml — payment status decision](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/flows/Donation_Register.flow-meta.xml#L263-L285) confirms that an attempt with a provider status other than `approved` follows the not-confirmed path rather than the donation-creation path.

## Overall evidence summary

| Criterion | Automated / implementation evidence | Live evidence status |
|---|---|---|
| AC1 | Apex test + roll-up summary metadata | Supported by automated tests |
| AC2 | Apex test with anonymous donation | Supported by automated tests |
| AC3 | Apex + Jest tests; formula and donation-eligibility logic | Supported by automated tests |
| AC4 | Registration Flow + fresh campaign query on component load | Live approved-payment-and-reload demonstration still required |
| AC5 | Apex test with a payment attempt + roll-up metadata + registration Flow | Supported by automated tests |

**Previously reported test run:** the Experience Builder guide records deployment `0AfVC00000PBhkn0AD` as succeeded with 137/137 Apex tests, and 136 Jest tests across 7 suites. These are the results recorded in the guide, not a claim that the suites were rerun while preparing this evidence file.

**Related implementation:** [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49) (Workstream B) and [PR #47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47) (payment flow / registration).
