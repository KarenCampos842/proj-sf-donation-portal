# AI Context File

Base context to give any AI assistant at the start of a session (paste it as the first message or save it as `CLAUDE.md`, a skill or system instructions). Keep this file up to date; it is part of the deliverables.

## Project

Public donation portal on Salesforce Developer Edition + Stripe **test mode** to fund student trips to Mexico Dreamin 2026. All data is fictitious. Nothing goes to production.

## Hard rules

- Never output or ask for real keys. Use placeholders such as `<STRIPE_SECRET_KEY>`.
- Stripe secrets go in Named/External Credentials or protected settings, never in code or versioned metadata.
- Guest user: least privilege only (read campaigns, create donations; no read/edit on donations).
- No SOQL/DML inside loops. No hard-coded IDs. Friendly error messages.
- Any Apex must include unit tests and pass Salesforce Code Analyzer.
- Anonymous donations never expose the donor name (site, thank-you page, receipt email) and cannot request an invoice.
- RFC validation is pattern-only (no SAT lookup, no CFDI).

## Data model (working draft)

- Campaign (`Campaign` or custom): name, goal, progress (sum of Paid donations only)
- `Donation__c`: amount, status (Pending / Paid), modality (Anonymous / Credit / Invoice), donor name, email, RFC, invoice requested, gateway reference, confirmation method (Manual / Automatic)
- `Rejected_Notice__c` (Delivery 2): date/time, rejection reason

## Response style we want

Explain trade-offs, cite official docs when stating platform limits, and flag anything that must be verified in our org.
