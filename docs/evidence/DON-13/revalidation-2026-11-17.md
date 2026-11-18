# DON-13: revalidation after DON-09 and DON-18 (2026-11-17)

DON-13 (#12) was evidenced before DON-09 and DON-18, which changed the same components (`donationForm`, `donationFormRules`, `donationFormMessages`, `DonationIntakeService`). Re-checked on the published site as a guest, with the code of merge `1ba02f3` deployed by `0AfVC00000PJJLV0A5`. Only `prueba.portal@example.com` and fictitious fiscal data were used.

| Check | Result | Evidence |
|---|---|---|
| With «Solicitar factura» on, the checkbox «Acepto el aviso de privacidad» appears unchecked and has no link or extra text (the `*` is the required marker of `lightning-input`) | Passes | `revalidation_casilla-sin-marcar-1280.png`, `revalidation-checks.txt` |
| Continuing without accepting shows «Acepta el aviso de privacidad para solicitar factura.», stays on the form and does not call `startDonation` | Passes | `revalidation_sin-aceptar-1280.png` |
| With the checkbox marked the summary shows the invoice request («Sí, solicitaste factura.»), also for an anonymous donation | Passes | `revalidation_resumen-con-factura-1280.png` |

Not re-verified: AC2 of DON-13, that the acceptance and its date are stored in the attempt and copied to the donation. The privacy fields of `Payment_Attempt__c` and `Donation__c` could not be read in this session (no field permission), so the new payment (attempt `a1dVC00000Gr2thYAB`, donation `DON-000026`) was not checked for them. The original evidence in `technical-evidence.md` stays valid for that criterion, and `DonationPrivacyNoticeTest` passed in the deployment (192/192).
