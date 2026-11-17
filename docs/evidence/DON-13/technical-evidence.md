# DON-13: technical evidence (2026-11-17)

Sandbox `donations-dev` (`uady--class2026b`). No personal data: the only email used is `prueba.portal@example.com`. Screenshots taken as a guest (no session) on the published site. Only Salesforce record IDs and the privacy fields are quoted here.

**Status: AC1, AC3 and AC4 verified. AC2 is verified for the attempt (real records); the copy to a donation is not yet verified on a real paid donation. The story is not closed.**

## Deployment

| Step | ID | Result |
|---|---|---|
| Merge of PR #63 into `main` (merged by Rodrigo) | `2e1337fe752a2229af38d0648467ea38a3d2e208` | Same tree as the reviewed branch |
| Check-only | `0AfVC00000PIC7Z0AX` | Succeeded, 15/15 components, 222/222 tests |
| Real deployment | `0AfVC00000PICFd0AP` | Succeeded, 15/15 components, 222/222 tests |
| Site publication (`Mexico Dreamin Donation Portal`) | job `08PVC00000gD7QB2A0` | Complete, no error |

Components: 4 fields, flows `Payment_Attempt_Create` and `Donation_Register` (version 2, active), `DonationIntakeService`, `DonationPaymentController`, their tests and `DonationPrivacyNoticeTest`, LWC `donationForm`, `donationFormRules`, `donationFormMessages`, permission sets `Donation_Admin` and `Payment_Attempt_Viewer`.

Tests (Apex, selected classes): `CampaignPortalControllerTest` 47, `DonationIntakeServiceTest` 63, `DonationPaymentControllerTest` 9, `DonationPrivacyNoticeTest` 13, `DonorRecognitionServiceTest` 17, `MercadoPagoNotificationServiceTest` 16, `MercadoPagoPaymentLookupActionTest` 18, `MercadoPagoPreferenceActionTest` 13, `MercadoPagoSignatureValidatorTest` 9, `PublicNameSanitizerTest` 17. Coverage: `DonationIntakeService` 175/175, `DonationPaymentController` 64/70. Jest: 8 suites, 227 tests. `RunLocalTests` was not repeated; the last run (`0AfVC00000PI9EX0A1`) failed on 6 legacy tests of the org.

## Checks as a guest on the published site (21 checks, 20 pass)

- AC4: without invoice the checkbox is not shown (`AC4_sin-factura.png`).
- AC1: with «Solicitar factura» the checkbox «Acepto el aviso de privacidad» appears, unchecked, with no link or extra text. Its visible text is `* Acepto el aviso de privacidad`; the `*` is the standard required marker of `lightning-input`. The one failed check compared the text for exact equality and did not allow for that marker.
- AC3 (browser): continuing without accepting shows «Acepta el aviso de privacidad para solicitar factura.» and stays on the form (`AC1_AC3_sin-aceptar.png`); checking the box removes the error (`AC1_aceptado.png`).
- AC3 (server): an invoice request with the acceptance omitted, `false` or `null` is rejected on both routes (`DonationIntakeService.startDonation` and a direct call to `DonationPaymentController.startDonation`), and no attempt is created.
- AC4 and compatibility: a request without invoice and without acceptance is accepted. An invoice request with acceptance is accepted on both routes.

## AC2 on real records (read with SOQL, 2026-11-17)

The link between the two objects is `Donation__c.Attempt_Id__c` = `Payment_Attempt__c.Id`; there is no lookup. The paid state of an attempt is `Status__c = Confirmed`.

| Attempt | Status | Invoice | `Privacy_Notice_Accepted__c` | `Privacy_Notice_Accepted_At__c` | Note |
|---|---|---|---|---|---|
| `a1dVC00000GpiFVYAZ` | Started | true | true | 2026-11-17T05:45:58Z | Equal to its creation time (server clock); the browser sends no date |
| `a1dVC00000GpiH7YAJ` | Started | true | true | 2026-11-17T05:45:59Z | Same |
| `a1dVC00000GpiIjYAJ` | Started | false | false | empty | No invoice: not required, nothing saved |

- **Copy to a donation: not verified.** No donation has `Privacy_Notice_Accepted__c = true` or a date. The two accepted attempts above are unpaid, so no donation exists for them. The copy by `Donation_Register` is covered by `DonationPrivacyNoticeTest` (13/13 in the Sandbox), not by a real record.
- **Attempts created before DON-13 are not blocked.** 5 attempts with invoice and no acceptance (`a1dVC00000GgvjpYAB`, `a1dVC00000GhGJeYAN`, `a1dVC00000GhVfFYAV`, `a1dVC00000GhWD7YAN`, `a1dVC00000GkTU1YAN`) were confirmed before the deployment and their donations (`a1cVC00000AC0XxYAL`, `a1cVC00000ACHH3YAP`, `a1cVC00000ACNI1YAP`, `a1cVC00000ACOIXYA5`, `a1cVC00000AEWofYAH`) hold false and no date. This is evidence of the historical state; no attempt of that kind was confirmed after the new flow version was deployed.
- **Records created by these checks:** the 3 unpaid attempts above. The scheduled flow deletes them after 7 days. Donations stayed at 24; attempts went from 66 to 69.

## Pending: paid sandbox payment (the step that needs a person)

The purpose is to see an attempt with invoice and acceptance become a confirmed donation with both values copied.

1. The AI had no Mercado Pago **test buyer** account (the local test-data file is not on this machine, and no credentials are in the environment), so it could not pay.
2. Attempt `a1dVC00000GpiFVYAZ` (100 MXN, invoice, accepted) already has a Checkout Pro preference and can be paid with the project's test buyer account and a Mercado Pago test card (cardholder name `APRO` for an approved payment). The payment must go through the normal return page or the webhook; do not register the donation by hand.
3. Afterwards check: the attempt is `Confirmed`; a `Donation__c` with `Attempt_Id__c` = that attempt exists; both have `Privacy_Notice_Accepted__c = true` and the same `Privacy_Notice_Accepted_At__c`; `Provider_Payment_Id__c` is the id of a test payment.

## Permissions checked in the Sandbox

- `Donation_Admin` reads the two `Donation__c` fields and `Payment_Attempt_Viewer` the two `Payment_Attempt__c` fields; read true, edit false for all four entries. Neither set can create, edit or delete records of those objects.
- The site guest profile has no object permission on `Donation__c` or `Payment_Attempt__c`, no field permission on the four fields, and `API Enabled` is off (repeated 2026-11-17).
- System Administrator profile: no field permission on the four fields. To read the records above, the verifier user was temporarily assigned `Donation_Admin` (assignment `0PaVC00000brzCz0AI`) and `Payment_Attempt_Viewer` (assignment `0PaVC00000bsFmN0AU`). They are kept until the paid payment is checked, and then removed. Rodrigo's assignments are not touched.

## Content of the privacy notice

The portal shows the checkbox but no text of the notice and no link, as AC1 of DON-13 asks. There is no approved notice text in the repository. This is a user-experience follow-up, not a failure of the four criteria: issue #66.

## Not verified

- The copy of the acceptance and date to a donation on a real record, and the return page, webhook and reconciliation paths with the new version of `Donation_Register` on a real payment (see the pending payment above).
- Keyboard and screen reader checks.
