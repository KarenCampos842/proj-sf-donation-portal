# DON-13: technical evidence (2026-11-17)

Sandbox `donations-dev` (`uady--class2026b`). No personal data: the only email used is `prueba.portal@example.com`. Screenshots taken as a guest (no session) on the published site. Only Salesforce record IDs, status, amount and the privacy fields are quoted here.

**Status: AC1 to AC4 are verified. AC2 is backed by real records: a paid sandbox payment became a confirmed donation with the acceptance and date copied from the attempt.**

## Deployment

| Step | ID | Result |
|---|---|---|
| Merge of PR #63 into `main` (merged by Rodrigo) | `2e1337fe752a2229af38d0648467ea38a3d2e208` | Same tree as the reviewed branch |
| Check-only | `0AfVC00000PIC7Z0AX` | Succeeded, 15/15 components, 222/222 tests |
| Real deployment | `0AfVC00000PICFd0AP` | Succeeded, 15/15 components, 222/222 tests |
| Site publication (`Mexico Dreamin Donation Portal`) | job `08PVC00000gD7QB2A0` | Complete, no error |

Components: 4 fields, flows `Payment_Attempt_Create` and `Donation_Register` (version 2, active), `DonationIntakeService`, `DonationPaymentController`, their tests and `DonationPrivacyNoticeTest`, LWC `donationForm`, `donationFormRules`, `donationFormMessages`, permission sets `Donation_Admin` and `Payment_Attempt_Viewer`.

Automated tests (run on 2026-11-17 during the deployment, not repeated afterwards): Jest 8 suites and 227 tests. Apex with `RunSpecifiedTests`, 222 tests: `CampaignPortalControllerTest` 47, `DonationIntakeServiceTest` 63, `DonationPaymentControllerTest` 9, `DonationPrivacyNoticeTest` 13, `DonorRecognitionServiceTest` 17, `MercadoPagoNotificationServiceTest` 16, `MercadoPagoPaymentLookupActionTest` 18, `MercadoPagoPreferenceActionTest` 13, `MercadoPagoSignatureValidatorTest` 9, `PublicNameSanitizerTest` 17. Coverage: `DonationIntakeService` 175/175, `DonationPaymentController` 64/70. `RunLocalTests` was not repeated; the last run (`0AfVC00000PI9EX0A1`) failed on 6 legacy tests of the org.

## Acceptance criteria

| Criterion | Result | How it was checked |
|---|---|---|
| AC1 | Verified | Guest on the published site: the checkbox «Acepto el aviso de privacidad» appears only after turning on «Solicitar factura», starts unchecked, and has no link or extra text. Its visible text is `* Acepto el aviso de privacidad`; the `*` is the standard required marker of `lightning-input`, not extra text (`AC1_aceptado.png`). |
| AC2 | Verified on real records | See the comparison below. |
| AC3 | Verified | Browser: continuing without accepting shows «Acepta el aviso de privacidad para solicitar factura.» and stays on the form (`AC1_AC3_sin-aceptar.png`). Server: an invoice request with the acceptance omitted, `false` or `null` is rejected on both routes (`DonationIntakeService.startDonation` and a direct call to `DonationPaymentController.startDonation`), and no attempt is created. |
| AC4 | Verified | Without invoice the checkbox is not shown (`AC4_sin-factura.png`) and nothing is required. A request without invoice and acceptance is accepted, and the attempt stores false and no date (`a1dVC00000GpiIjYAJ`). |

Guest checks on the published site: 21 checks, 20 pass. The one that fails compared the label text for exact equality and did not allow for the `*` marker.

## AC2 on real records (read with SOQL, 2026-11-17)

The link between the two objects is `Donation__c.Attempt_Id__c` = `Payment_Attempt__c.Id`; there is no lookup. A paid attempt has `Status__c = Confirmed`.

A paid sandbox payment was made by the owner of the project with the Mercado Pago test buyer account, from the attempt created by the portal and prepared earlier. The AI did not pay, did not change any record, and did not run any flow by hand.

| Field | Attempt `a1dVC00000GpiFVYAZ` | Donation `a1cVC00000AID5tYAH` (`DON-000025`) |
|---|---|---|
| Status | `Confirmed` | `Confirmed` (`Payment_Status__c`) |
| Amount | 100 | 100 |
| `Privacy_Notice_Accepted__c` | true | true |
| `Privacy_Notice_Accepted_At__c` | 2026-11-17T05:45:58Z | 2026-11-17T05:45:58Z |
| Link | n/a | `Attempt_Id__c` = `a1dVC00000GpiFVYAZ` |
| Mercado Pago payment reference | n/a | `Provider_Payment_Id__c` = 188999395839 (sandbox payment, according to the owner who made it) |
| Confirmation | n/a | `Confirmed_At__c` 2026-11-17T06:19:48Z; record created 06:19:53Z by the site guest user |

- Exactly one donation exists for the attempt. The acceptance is `true` in both records, and the date and time are identical (the date was generated on the server when the attempt was created, 05:45:58Z, and copied unchanged).
- Attempt `Preference_Id__c` is informed; the attempt was last modified at 06:19:53Z, the moment the donation was created.
- The donation was created by the site guest user, which is the user that both the return page and the webhook run as. The records alone do not show whether the return page or the webhook registered it. No new `Rejected_Notice__c` was created after the payment (the latest are from 2026-11-17 00:14Z or earlier).
- That the payment belongs to the sandbox rests on the owner having used the test buyer account and a test card; the AI did not query Mercado Pago and has no access to its credentials.
- Donations went from 24 to 25 and attempts stayed at 69 after the payment.

Other real attempts (created by the guest checks):

| Attempt | Status | Invoice | Acceptance | Date |
|---|---|---|---|---|
| `a1dVC00000GpiH7YAJ` | Started | true | true | 2026-11-17T05:45:59Z (server creation time) |
| `a1dVC00000GpiIjYAJ` | Started | false | false | empty |

Attempts created before DON-13 are not blocked: 5 attempts with invoice and no acceptance (`a1dVC00000GgvjpYAB`, `a1dVC00000GhGJeYAN`, `a1dVC00000GhVfFYAV`, `a1dVC00000GhWD7YAN`, `a1dVC00000GkTU1YAN`) were confirmed before the deployment, and their donations (`a1cVC00000AC0XxYAL`, `a1cVC00000ACHH3YAP`, `a1cVC00000ACNI1YAP`, `a1cVC00000ACOIXYA5`, `a1cVC00000AEWofYAH`) hold false and no date. The two unpaid test attempts above are deleted by the scheduled flow after 7 days.

## Permissions checked in the Sandbox

- `Donation_Admin` reads the two `Donation__c` fields and `Payment_Attempt_Viewer` the two `Payment_Attempt__c` fields; read true, edit false for all four entries. Neither set can create, edit or delete records of those objects.
- The site guest profile has no object permission on `Donation__c` or `Payment_Attempt__c`, no field permission on the four fields, and `API Enabled` is off.
- The System Administrator profile has no field permission on the four fields. To read the records above, the verifier user was temporarily assigned `Donation_Admin` (assignment `0PaVC00000brzCz0AI`) and `Payment_Attempt_Viewer` (assignment `0PaVC00000bsFmN0AU`). **Both assignments were removed on 2026-11-17** after all the reads; the verifier user has neither set now. Only the payments owner's assignments of those sets remain.

## Not part of DON-13

- The portal shows no text of the privacy notice and no link, as AC1 asks. There is no approved notice text in the repository. Tracked separately in issue #66 (user-experience follow-up).
- Keyboard and screen reader checks were not done.
