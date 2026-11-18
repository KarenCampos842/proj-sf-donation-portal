# DON-18: technical evidence (2026-11-17)

Sandbox `donations-dev` (`uady--class2026b`). Screenshots taken as a guest (no session) on the published site, with Chrome driven by Playwright, at 1280 px and, where named, 360 px. No personal data: the only email used is `prueba.portal@example.com`. The access token is never shown: every file records only presence, counts and lengths.

**Status: AC1 to AC5 are verified in the browser and with server answers. The stored values of `Donor_Confirmed_At__c`, `Superseded_At__c` and the hash could not be read (no field permission, and anonymous Apex does not read them either); they are backed by the user-visible behavior and by the Apex tests. Not covered: screen reader.**

## Deployment and tests

Same as DON-09: merge `1ba02f3`; check-only `0AfVC00000PJGST0A5` and real deployment `0AfVC00000PJJLV0A5` (Succeeded, 24/24, 192/192, `RunSpecifiedTests`); Jest 9 suites 376/376 (`jest-results.txt`). `RunLocalTests` of the whole org did not pass (`0AfVC00000PJ0h40AD`, 459/465, six inherited tests outside the repository).

## Acceptance criteria

| Criterion | Result | How it was checked |
|---|---|---|
| AC1 | Verified | The summary shows campaign, amount in MXN, email, visibility and invoice (`AC1_AC2_resumen-anonimo-1280.png` $500; `AC1_AC2_resumen-anonimo-factura-1280.png` $100 with «Sí, solicitaste factura.»; `AC1_AC2_resumen-publico-factura-1280.png` $250.50). The calls before the summary were only `startDonation` and `getDonationSummary` (`summary-checks.txt`). At 360 px: `AC1_formulario-360.png`, `AC1_resumen-360.png`, no horizontal scroll (`focus-check.txt`). Server: `DonationReviewTest.shouldShowCampaignExactAmountEmailVisibilityAndInvoice_WhenTheDonorReviews`, `shouldBuildTheSummaryFromTheSavedValues_NotFromWhatTheBrowserSends`. |
| AC2 | Verified | Public: «Pública. Aparecerá como: Donante de Prueba». Anonymous: «Anónima. Tu nombre no será visible en el portal.». An anonymous donation that asks for an invoice shows both, so the invoice is independent of the visibility. Server: `shouldShowThePublicName_OnlyWhenTheDonationIsPublic`, `shouldKeepTheInvoiceIndependentFromTheVisibility_WhenTheDonorReviews`. |
| AC3 | Verified on a real payment | «Confirmar y continuar al pago» called `confirmDonation` and then `openPayment` (both HTTP 200) and led to the Mercado Pago page that shows «Donación: Fondo general SF Vibe Lab» and `$ 250.50` (`AC3_mercado-pago-1280.png`). The owner paid it and donation `DON-000026` has the same amount (`DON-09/records-check.txt`). Server: `shouldOpenThePaymentWithTheReviewedAmountAndCampaign_WhenTheDonorConfirmed`, `shouldNotLetTheDonorChangeTheAmountAfterTheReview_WhenTheBrowserSendsAnotherOne`. |
| AC4 | Verified in the browser and by server answers; stored fields not read | «Editar donación» returns the form with the data kept (custom 90, same email, «Otro monto» marked; `AC4_editar-datos-conservados-1280.png`). Changing the amount to 95 creates a new summary with a new token and asks to confirm again (`AC4_resumen-nuevo-1280.png`). The calls were `startDonation > getDonationSummary > invalidateDonation > startDonation > getDonationSummary`, with no `confirmDonation` and no `openPayment`. The old token now answers «Tu donación ya no está disponible. Edítala para volver a capturar tus datos.» and the new one answers the summary (`token-check.txt`). Both attempts exist (`a1dVC00000Gr2ldYAB` $90 and `a1dVC00000Gr2nFYAR` $95), but `Superseded_At__c` and the hash of the first one could not be read to show them as not null and null. Server: `shouldStopTheOldToken_WhenTheDonorEdits`, `shouldRequireANewConfirmation_WhenTheDonorEditsAndContinuesWithAnotherAmount`, `shouldPayOnlyTheNewAttempt_WhenTheDonorEditedAndConfirmedAgain`. |
| AC5 | Verified in the browser; the refusal of an unconfirmed attempt only by Apex tests | In the summary the only way to the payment is «Confirmar y continuar al pago» (controls: «Editar donación» and «Confirmar y continuar al pago»; `summary-checks.txt`). Until it is pressed, no `confirmDonation` or `openPayment` call exists in the network log of the first summary, of the edit flow and of the payment attempt (`summary-checks.txt`, `token-check.txt`). With an invented token or an attempt Id, `openPayment` and `confirmDonation` are refused (`guest-checks.txt`). That the server refuses a real unconfirmed attempt was not tried live (it could have opened a payment); it is covered by `DonationReviewTest.shouldNotOpenThePayment_WhenTheDonorDidNotConfirm_ForSuggestedAndCustomAmounts`. |

## Token and access

- The token is returned once, in the response of `startDonation`. It is in no URL, not in the DOM (shadow roots included), not in `localStorage`, `sessionStorage` or cookies, and only the later calls send it in their POST body. After a reload the form starts again (`token_recarga-reinicia-1280.png`, `token-check.txt`).
- Guest checks, 11 of 11 pass (`guest-checks.txt`): the REST API without a session answers 401 for `Payment_Attempt__c` and `Donation__c` on the site and on the sandbox domain; `DonationPaymentController.startDonation` and `openPayment` can no longer be called from the browser («The Apex request is invalid»), with `getPaymentResult` (still exposed) answering 200 as the control; a made-up token or an attempt Id is rejected.
- Keyboard focus: to the title of the summary on arrival, to the title of the form after «Editar donación» (`focus-check.txt`).
- Records and method: `DON-09/records-check.txt`.

## Not covered by this evidence

- **Screen reader:** not tested.
- **Stored fields:** `Donor_Confirmed_At__c`, `Superseded_At__c` and the hash were not read (see the method in `DON-09/records-check.txt`). The value of the hash was never read or printed.
- **Double payment of one attempt:** accepted risk of `docs/security.md`; not tested.
- **`getPaymentResult`:** anonymous and pre-existing, outside DON-18.
- **Observation:** a real provider failure left the attempt alive, while `docs/payments-api.md` says the flow deletes it (see DON-09). Not investigated.
