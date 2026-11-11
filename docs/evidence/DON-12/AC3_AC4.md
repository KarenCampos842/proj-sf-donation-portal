# DON-12 — Evidence for AC3 and AC4

**Story:** [DON-12 — Solicitar factura](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/11)  
**Repository:** [KarenCampos842/proj-sf-donation-portal](https://github.com/KarenCampos842/proj-sf-donation-portal)

This document consolidates the implementation and test references for the RFC validation and normalization acceptance criteria.

## AC3 — RFC structure validation

**Acceptance criterion**  
Given that I enter an RFC, when I continue, its structure is validated (initial letters, date and homoclave), allowing 13 characters for an individual and 12 for a legal entity. The SAT is not queried.

**Evidence**

- `DonationIntakeServiceTest.shouldAcceptPersonAndCompanyRfc_WhenStructureIsValid` verifies that the valid individual and legal-entity RFC examples are accepted.
- `DonationIntakeServiceTest.shouldRejectRfc_WhenFormatIsNotValid` verifies rejection of malformed values, including 11- and 14-character values, month 13, day 32, letters in the date portion, an invalid initial character and special characters.
- `DonationIntakeService` applies a local Apex regular-expression check through `RFC_PATTERN`. The validation path does not query the SAT or invoke a SAT service.

**Source references**

1. [Apex tests — valid individual and legal-entity RFCs (lines 196–207)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/DonationIntakeServiceTest.cls#L196-L207)
2. [Apex tests — invalid RFC formats (lines 441–458)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/DonationIntakeServiceTest.cls#L441-L458)
3. [RFC regular expression in `DonationIntakeService` (lines 73–78)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/DonationIntakeService.cls#L73-L78)
4. [Server-side RFC normalization and format validation (lines 269–299)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/DonationIntakeService.cls#L269-L299)
5. [PR #49 — Workstream B implementation and Apex test results](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49)

## AC4 — RFC normalization

**Acceptance criterion**  
Given that I enter the RFC in lowercase or with spaces at the beginning or end, when I continue, it is saved in uppercase and without spaces.

**Evidence**

- `DonationIntakeServiceTest.shouldNormalizeRfc_WhenItHasLowercaseAndSpaces` submits `  gode 561231 gr8 ` and asserts that the value passed forward is `GODE561231GR8`.
- `DonationIntakeService.applyInvoiceData` removes whitespace and converts the RFC to uppercase before passing the validated request to the payment-attempt creation process.
- A before-save record-triggered Flow on `Payment_Attempt__c` applies `UPPER(SUBSTITUTE(RFC__c, " ", ""))` so the stored value is uppercase and has ordinary spaces removed before the record is saved.

**Source references**

1. [Apex test — lowercase and spaces normalized (lines 182–193)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/DonationIntakeServiceTest.cls#L182-L193)
2. [Apex normalization before creating the payment attempt (lines 269–280)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/force-app/main/default/classes/DonationIntakeService.cls#L269-L280)
3. [PR #46 — before-save Flow for RFC normalization](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46)
4. [Data model — documented before-save normalization formula (lines 309–310)](https://github.com/KarenCampos842/proj-sf-donation-portal/blob/main/docs/data-model.md#L309-L310)

## Execution record

PR #49 reports that the sandbox deployment completed with **137/137 Apex tests passing**. The PR contains the DON-12 implementation and the test class referenced above.

[Open PR #49 and its deployment/test summary](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49)

---

**Evidence note:** The Apex test for AC4 asserts normalization in the server-side request before it is passed to the payment-attempt process. The before-save Flow reference is included separately because it is the automation that normalizes the value on the `Payment_Attempt__c` record itself.
