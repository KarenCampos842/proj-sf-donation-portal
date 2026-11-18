# DON-09: technical evidence (2026-11-17)

Sandbox `donations-dev` (`uady--class2026b`). Screenshots taken as a guest (no session) on the published site, with Chrome driven by Playwright, at 1280 px and, where named, 360 px. No personal data: the only email used by the verifier is `prueba.portal@example.com`. The owner's own captures are included where stated; an email in one of them is covered with a black box.

**Status: AC1 to AC6 are verified. AC4 and AC6 rest on real records and on a real rejection by Mercado Pago. Not covered: screen reader, the maximum of the test account (TEC-02), and the double payment risk.**

## Deployment and tests

| Step | ID | Result |
|---|---|---|
| Merge of PR #72 into `main` (includes the Workstream A fix of PR #73, `dbc27d9`) | `1ba02f3` | Same code as the reviewed branch |
| Check-only | `0AfVC00000PJGST0A5` | Succeeded, 24/24 components, 192/192 tests (`RunSpecifiedTests`) |
| Real deployment | `0AfVC00000PJJLV0A5` | Succeeded, 24/24 components, 192/192 tests, 2026-11-17 22:02-22:04 UTC |
| Site publication | done by the owner after the deployment | Job id not provided |

- Jest, whole project: 9 suites, 376 of 376 (`jest-results.txt`).
- Apex: 192 of 192 in the deployment above. `RunLocalTests` of the whole org did **not** pass in the earlier check-only `0AfVC00000PJ0h40AD` (459 of 465): six inherited tests outside this repository fail (four of `AccountExplorerControllerTest` because of `OpportunityTrigger`, two of email with `NO_MASS_MAIL_PERMISSION`; the cause of the email ones is not confirmed).
- Configuration read from the org: `Donation_Amount_Setting__mdt` (`Default`) minimum 50; suggested amounts 100, 250, 500, 1000, 2000, 5000, 10000 and 20000.

## Acceptance criteria

| Criterion | Result | How it was checked |
|---|---|---|
| AC1 | Verified | In the same step as the eight quick options there is «Otro monto»; choosing it shows «Otro monto (MXN)» without leaving the step. At 1280 and 360 px, no horizontal scroll (`AC1_opciones-1280.png`, `AC1_otro-monto-1280.png`, `AC1_opciones-360.png`, `AC1_otro-monto-360.png`, `ui-checks.txt`). |
| AC2 | Verified | A valid amount that is not suggested (250.50) advances and the summary shows exactly `$250.50 MXN` (`AC2_formulario-250-50-1280.png`, `AC2_resumen-250-50-1280.png`). The provider accepted it: the Mercado Pago page showed `$ 250.50` and the owner paid it (see AC4). The field accepts the minimum, 50, and `99999999999999.99` without an error (`AC2_minimo-aceptado-1280.png`, `AC2_maximo-campo-aceptado-1280.png`; these two were not submitted). |
| AC3 | Verified | Quick option $250, then «Otro monto» with 75: the quick option is no longer marked (`AC3_otro-sobre-sugerido-1280.png`). Then $500 again: the custom field disappears and only $500 is marked (`AC3_sugerido-sobre-otro-1280.png`). The summary shows only `$500 MXN` and the request sent `"amount":"500"` (`AC3_resumen-ultimo-monto-1280.png`, `ui-checks.txt`, `DON-18/summary-checks.txt`). |
| AC4 | Verified on real records | The owner paid the 250.50 attempt with the Mercado Pago test buyer account and a test card. Attempt `a1dVC00000Gr2thYAB` $250.50, payment page $ 250.50 and donation `DON-000026` (`a1cVC00000AJ9WTYA1`, Confirmed, `Provider_Payment_Id__c` 189169112107) $250.50. Exactly one donation for the attempt (`records-check.txt`). Server side: `DonationCustomAmountTest` (`shouldSaveTheExactAmountInTheAttempt_WhenTheDonorTypesACustomAmount`, `shouldSendTheSavedAmountToMercadoPago_WhenThePaymentIsOpened`, `shouldRegisterTheDonationWithTheTypedAmount_WhenTheAmountUsesEverySignificantDigit`). |
| AC5 | Verified | Each case below shows its reason next to the field and stays on the amount step and creates no attempt: empty, `abc`, `1,000`, `0`, `-5`, `0.001` and `49.99` (one cent below the minimum 50: «El monto mínimo es de $50 MXN.»). Also `1e3`, `.5` and `5.` (text only, `ui-checks.txt`). Captures: `AC5_vacio-1280.png`, `AC5_texto-1280.png`, `AC5_coma-1280.png`, `AC5_cero-1280.png`, `AC5_negativo-1280.png`, `AC5_decimales-1280.png`, `AC5_bajo-minimo-1280.png`. Server side: `DonationAmountValidatorTest` (`shouldRejectTheAmount_WhenItIsEmpty`, `..._WhenItIsNotAPlainDecimalNumber`, `..._WhenItIsZeroOrNegative`, `..._WhenItHasMoreThanTwoDecimals`, `..._WhenItIsBelowTheCurrentMinimum`). |
| AC6 | Verified on a real rejection | The owner created by hand, on the published site, an attempt of 99999999999999.99 (19:27:40 Mérida, `a1dVC00000Gr47VYAR`, exact amount in the org; `records-check.txt`) and pressed «Confirmar y continuar al pago». Mercado Pago did not process it. The portal showed, in the summary: «No pudimos abrir el pago. Puede que Mercado Pago no acepte esta cantidad: edita tu donación y elige otra cantidad.», with «Editar donación» enabled and «Confirmar y continuar al pago» disabled (`AC6_rechazo-real-1280.png`; the owner's original is `AC6_resumen-monto-enorme-1280.png`). Server side with simulated answers: `DonationCustomAmountTest.shouldOfferToChooseAnotherAmount_WhenMercadoPagoRejectsTheAmount`. |

Technical criteria: the amount travels as text and is stored exactly (the request body shows `"amount":"500"`; the 16-digit amount is stored as exactly 99999999999999.99, confirmed with `FORMAT()` and exact filters, `records-check.txt`); the server validates again (`DonationAmountValidatorTest.shouldKeepEveryCentOfAnAmountWith16Digits_WhenItIsConverted`); one active amount (AC3); the minimum comes from ADM-13.

## Other checks

- Keyboard focus: choosing «Otro monto» puts the focus in the new field, and a failed amount returns it to that field (`focus-check.txt`).
- No attempt was created by the AC5 cases or by the two accepted limits: they were not submitted, and the live attempts created that evening are only the seven listed in `records-check.txt`.
- The verifier created six attempts (summaries and the payment attempt) and the owner one (AC6): live attempts went from 51 to 58 (`records-check.txt`).

## Not covered by this evidence

- **Screen reader:** not tested. Keyboard focus was checked by program only.
- **Maximum of the test account (TEC-02):** the real rejection shows that 99999999999999.99 is refused, but the portal hides the reason and the limit of the test account was not found. Nothing is claimed about it.
- **Edit after the rejection:** the owner's capture shows the enabled «Editar donación» button; the click itself was not captured on the real site. The behavior is covered by Jest (`shows the message that lets the donor choose another amount when Mercado Pago cannot process it`).
- **Observation, not a DON-09 defect:** after this real rejection the attempt still exists (not deleted), while `docs/payments-api.md` says the payment flow deletes it. The cause was not investigated (a rollback of the failed call is a hypothesis, not verified). The donor sees the right message either way.
- **Double payment of one attempt:** accepted risk documented in `docs/security.md`; not tested.
- **Amounts read with the CLI:** it prints 16-digit amounts one cent low; see the method in `records-check.txt`.

## Recheck with field permission (added later the same day)

Read again at 19:54 hora de México with `Payment_Attempt_Viewer` and `Donation_Admin` assigned temporarily and removed afterwards (`DON-13/records-recheck-2026-11-17.txt`, `DON-13/revalidation-2026-11-17.md`):

- Attempt `a1dVC00000Gr2thYAB` (the 250.50 payment): `Status__c` = `Confirmed`, amount $250.50, `Preference_Id__c` set; the donation `DON-000026` is `Confirmed` with $250.50. This backs AC4.
- Attempt `a1dVC00000Gr47VYAR` (the real AC6 rejection, 99999999999999.99 read exactly): `Status__c` = `Started` and `Preference_Id__c` **not set**. After the provider failed, the attempt was not deleted and no preference was saved.
