# DON-13: revalidation after DON-09 and DON-18 (2026-11-17)

DON-13 (#12) was evidenced before DON-09 and DON-18, which changed the same components (`donationForm`, `donationFormRules`, `donationFormMessages`, `DonationIntakeService`). Re-checked on the published site as a guest, with the code of merge `1ba02f3` deployed by `0AfVC00000PJJLV0A5`. Only `prueba.portal@example.com` and fictitious fiscal data were used.

| Check | Result | Evidence |
|---|---|---|
| With «Solicitar factura» on, the checkbox «Acepto el aviso de privacidad» appears unchecked and has no link or extra text (the `*` is the required marker of `lightning-input`) | Passes | `revalidation_casilla-sin-marcar-1280.png`, `revalidation-checks.txt` |
| Continuing without accepting shows «Acepta el aviso de privacidad para solicitar factura.», stays on the form and does not call `startDonation` | Passes | `revalidation_sin-aceptar-1280.png` |
| With the checkbox marked the summary shows the invoice request («Sí, solicitaste factura.»), also for an anonymous donation | Passes | `revalidation_resumen-con-factura-1280.png` |

## AC2 re-verified on real records (read at 19:54 hora de México)

With field permission assigned temporarily (see below), `Payment_Attempt__c` and `Donation__c` were read again after DON-09 and DON-18 (`records-recheck-2026-11-17.txt`).

| Field | Attempt `a1dVC00000Gr2thYAB` | Donation `a1cVC00000AJ9WTYA1` (`DON-000026`) |
|---|---|---|
| Status | `Confirmed` | `Confirmed` (`Payment_Status__c`) |
| Amount | $250.50 | $250.50 |
| Invoice requested | true | n/a |
| `Privacy_Notice_Accepted__c` | true | true |
| `Privacy_Notice_Accepted_At__c` | 2026-11-18T01:07:17Z | 2026-11-18T01:07:17Z |

- **DON-13 AC2 is verified again with real records:** the acceptance is true in both, and the date and time are identical (copied unchanged from the attempt). The attempt asked for an invoice and was public, and it was created through the new review step of DON-18.
- Exactly one donation exists for the attempt. `Preference_Id__c` of the attempt is set (the value was not read).
- The check covers one real payment with an invoice request. Attempts without an invoice were not paid, so the donation of an attempt without acceptance was not re-checked after DON-18.

## Temporary use of permission sets

The owner authorized, for this check only, assigning `Payment_Attempt_Viewer` and `Donation_Admin` to the verifier user, and the AI removed them itself.

| Step | Detail | Time (server) |
|---|---|---|
| Assignment | `Payment_Attempt_Viewer` `0PaVC00000buR3S0AU`, `Donation_Admin` `0PaVC00000buoPr0AI` (`sf org assign permset`) | 01:53:42Z and 01:53:43Z (19:53 hora de México) |
| Reading | SELECT only | about 01:54Z (19:54) |
| Removal | the two records deleted by Id (`sf data delete record`), `success: true` both | 01:55:16 to 01:55:24 GMT (19:55) |
| Check | 0 assignments of the verifier user remain; the two assignments of another person (`0PaVC00000bYaAE0A0`, `0PaVC00000bYVL50AO`) are untouched; `Status__c` and the privacy fields are unreadable again | 01:55:36 GMT |

No other permission, profile or permission set was changed. `Portal_Access_Token_Hash__c`, `Donor_Confirmed_At__c` and `Superseded_At__c` are in no permission set and were not read.
