# AI Context File

Base context to give any AI assistant at the start of a session (paste it as the first message or save it as `CLAUDE.md`, a skill or system instructions). Keep this file up to date; it is part of the deliverables.

## Project

Public donation portal on a Salesforce sandbox (`donations-dev`) + **Mercado Pago (test mode, Checkout Pro)** to fund student trips to Mexico Dreamin 2026. All data is fictitious. Nothing goes to production.

## Hard rules

- Never output or ask for real keys. Use placeholders such as `<MERCADO_PAGO_ACCESS_TOKEN>`.
- Mercado Pago secrets go in Named/External Credentials or protected settings, never in code or versioned metadata.
- Guest user: least privilege only. Read access to the public fields of campaigns in the states Closed, Active or Paused (the sharing rule never shares Draft); no access to `Donation__c` or `Payment_Attempt__c` (attempts and donations are created by system-mode processes).
- No SOQL/DML inside loops. No hard-coded IDs. Friendly error messages.
- Any Apex must include unit tests and pass Salesforce Code Analyzer.
- Anonymous donations never expose the donor name (site, thank-you page, receipt email; the receipt email is DON-23, Delivery 2) and can request an invoice (separated from public visibility).
- RFC validation is pattern-only (no SAT lookup, no CFDI). Invoice requests only capture and store the data; no CFDI is generated.
- Delivery 1 registers a donation when the donor returns to `/portal/gracias` and the server checks the payment with Mercado Pago. There was no webhook in Delivery 1; do not report its absence as a Delivery 1 defect. Since Delivery 2 the signed webhook (PAY-06, DON-24) and an hourly reconciliation (PAY-08) also register payments when the donor does not return. All paths run the same flow, `Donation_Register`.
- The donation form (Delivery 2) is a review flow of five Apex calls in `DonationIntakeService`: `startDonation`, `getDonationSummary`, `confirmDonation`, `openPayment` and `invalidateDonation`. A random access token authorizes each call; only its SHA-256 hash is stored on the attempt. The browser never sends a Salesforce Id as authorization, and `DonationPaymentController.startDonation` and `openPayment` are no longer `@AuraEnabled`. Amounts travel as exact text, are validated again in Apex and converted to `Decimal` only when handed to the payment code. Requesting an invoice requires accepting the privacy notice (DON-13); the server saves the acceptance and its timestamp.
- Out of scope: DON-26 (view the portal in another language) will not be built. DON-23 (receipt email) is not built because the shared sandbox only sends system email.
- Never commit local test-account data (`docs/payment-test-data.local` is ignored by Git).

## Data model

Source of truth: `docs/data-model.md` (read it for fields, formulas and validation rules). Summary:

- `Fundraising_Campaign__c` (D1, custom object instead of the standard `Campaign`, decision D-02): name, description, goal, start/end dates, status (`Draft` / `Active` / `Paused` / `Closed`), general-campaign flag, image URL and alt text. Progress is calculated from confirmed donations: `Total_Raised__c` (roll-up SUM of `Donation__c.Amount__c`), `Donation_Count__c` (roll-up COUNT) and `Progress_Percent__c` (formula, not capped at 100%).
- `Payment_Attempt__c` (D1, Lookup to the campaign): what the donor entered before paying. It is not a donation and does not count toward progress. Status: `Started` (default) / `Confirmed` / `Rejected` / `Cancelled`. Holds email, visibility, public name, invoice request and tax data. Since Delivery 2 it also holds the privacy-notice acceptance and its timestamp (DON-13) and the review-step fields `Portal_Access_Token_Hash__c`, `Donor_Confirmed_At__c` and `Superseded_At__c` (DON-18); no permission set reads the last three.
- `Donation__c` (D1, Master-Detail to the campaign): created only after the provider confirms the payment, so there is no Pending state. `Payment_Status__c` has a single value, `Confirmed`. Visibility is `Anonymous` / `Public` and is independent from the invoice request; `Modality__c` is a formula ("Anónima" or "Con nombre", plus " + factura" when an invoice is requested). Provider reference: `Provider_Payment_Id__c` (unique, External ID).
- `Rejected_Notice__c` (deployed with the payment flows; webhook-related notices are Delivery 2) and `Donation_Amount_Setting__mdt` (Delivery 2): rejected provider notices and suggested/minimum amounts. Other D2 fields (privacy notice, confirmation source, receipt sent, close reason) are described in `docs/data-model.md`.

## Response style we want

Explain trade-offs, cite official docs when stating platform limits, and flag anything that must be verified in our org.