# Questions and Problem Reports

Every entry has an author, a date, and the five parts below. After the answer arrives, add **What we did next** to the same entry.
Business questions go to the professor as **client**; technical questions go to the professor as **advisor**. No keys or personal data in screenshots or error text.

Our six business questions were sent on **2026-11-03**. The answers came on **2026-11-04**, in Slack and in the Q&A class session (Wednesday), which went through every question.

## Entry template

### Q-00 - Short title

- **Author:** _name_
- **Date:** YYYY-MM-DD
- **Type:** Business question / Technical question / Platform blocker / Leaked key
- **Where asked:** Class (session) / Slack
- **Related story:** _US-xx_

1. **What we were trying to achieve (story and criterion):**
2. **What we did (concrete steps):**
3. **What we expected to happen:**
4. **What happened (exact error or screenshot):**
5. **What we consulted (AI / docs) and the outcome:**

**Answer received:**

**What we did next / resolved?:**

---

## Business questions for the client (status)

| # | Question | Status | Entry |
|---|---|---|---|
| B1 | Should an "Invoice" donor be able to opt out of the public credit list? | Answered: independent decisions | Q-01 |
| B2 | Is an email required for anonymous donors so they can get a receipt? | Answered: yes, always | Q-02 |
| B3 | What happens to Pending donations that are never paid (expire after N days)? | Answered: the payment provider decides; no pending donation | Q-03 |
| B4 | Suggested amounts, minimum and maximum donation? | Answered | Q-04 |
| B5 | Does a campaign close when it reaches its goal or the event date passes? | Answered: only the date closes it | Q-05 |
| B6 | Minimum content of the receipt email? | Answered: our proposal was accepted | Q-06 |
| B7 | Ticket price for Mexico Dreamin 2026 and fictitious goals for the demo? | Open | |
| B8 | Can a Closed campaign be reopened? | Open | |
| B9 | If there are no active campaigns, do we offer a general fund or only the "No campaigns available" message? | Client's view: there should always be an open general-donation campaign (Q-05). Team to confirm how to show it. | Q-05 |
| B10 | Does the receipt carry a logo, folio or other legend? | The client has no checklist; the team decides (Q-06) | Q-06 |

## Professor clarifications to register (TEC-08)

| Topic | Clarification | Date |
|---|---|---|
| RF-D3 | Do not create records before the payment: create them after the provider confirms it. We save a technical payment attempt instead of a Pending donation (PAY-07). | 2026-11-04 (Q&A session) |
| RF-S2 | Internal views list only confirmed donations. Derived from the same statement as RF-D3; confirm with the professor. | 2026-11-04 (Q&A session) |
| RF-S3 | No manual payment confirmation. The professor said that requirement came from AI and he would not touch it (WON-04). The part of RF-S4 that tells automatic from manual confirmation does not apply. | 2026-11-04 (Q&A session) |
| Payment provider | Mercado Pago in test mode (Checkout Pro), not Stripe. This is not in the recording of 2026-11-04. | _YYYY-MM-DD, add the date_ |

## Entries

### Q-01 - Visibility of donors who request an invoice

- **Author:** Karen Elizabeth Campos (for the team)
- **Date:** 2026-11-03
- **Answered:** 2026-11-04 (Slack and Q&A session)
- **Type:** Business question
- **Where asked:** Slack
- **Related story:** DON-10, DON-12, DON-13 (RF-D2, RF-F1)

1. **What we were trying to achieve:** decide whether a donor who asks for an invoice appears in the public recognition list (DON-04, DON-11, DON-12).
2. **What we did:** asked the professor as client: should a donor who chooses "With Invoice" appear in the public list, or stay private unless they ask otherwise?
3. **What we expected:** a rule telling us if the invoice option forces or forbids public credit.
4. **What happened:** see the answer below.
5. **What we consulted:** the project guide (RF-D2).

**Answer received:**
- Slack: "I think those kinds of donations must always be public, to prove the donation was actually made for SAT purposes. We need to investigate if there are any edge-case scenarios here."
- Q&A session: the professor first repeated that an invoice request should be public. After the discussion, the professors explained that being credited publicly and asking for an invoice are two different decisions: for tax purposes the evidence is the receipt the organization issues, not the public list. The class was told to treat them as separate decisions. A student added that anonymity only means the name is not shown in the portal. A professor suggested one checkbox ("I consent to the use of my data to issue my invoice"), saved in the backend, with no terms and conditions page.

**What we did next** Resolved. Anonymous or public, and with or without invoice, are independent (DON-10 AC3, DON-12 AC2). The consent checkbox became DON-13, saved with date and time.

---

### Q-02 - Email for anonymous donors

- **Author:** Karen Elizabeth Campos (for the team)
- **Date:** 2026-11-03
- **Answered:** 2026-11-04 (Slack and Q&A session)
- **Type:** Business question
- **Where asked:** Slack
- **Related story:** DON-10, DON-23 (RF-D2 CA2)

1. **What we were trying to achieve:** know if an anonymous donor must give an email to receive a receipt.
2. **What we did:** asked the professor as client.
3. **What we expected:** a yes/no on whether the email is mandatory.
4. **What happened:** see the answer below.
5. **What we consulted:** RF-D2 CA2 of the guide.

**Answer received:** Slack: a ticket (receipt) in their email is the minimum. Session: the email is always required; for an anonymous donor without invoice it is the only data we need.

**What we did next:** Resolved. The email is always required. It is used only for the process and the receipt, and never shown publicly (DON-10, DON-23).

---

### Q-03 - Pending donations that are never paid

- **Author:** Karen Elizabeth Campos (for the team)
- **Date:** 2026-11-03
- **Answered:** 2026-11-04 (Slack and Q&A session)
- **Type:** Business question
- **Where asked:** Slack
- **Related story:** PAY-07, PAY-02 (RF-D3)

1. **What we were trying to achieve:** define what happens to payments that start and are never completed.
2. **What we did:** asked the professor as client whether they expire after some days or stay pending.
3. **What we expected:** a number of days after which they expire.
4. **What happened:** see the answer below.
5. **What we consulted:** Mercado Pago documentation on payment statuses (`pending`, `in_process`, `rejected`, `cancelled`).

**Answer received:** Slack: it is controlled by the payment gateway; a donation is only "Pending" while the payment has not been authorized, so nothing stays pending forever; review the documentation. Session: the gateway owns those states. A pending payment must not show in the portal yet, because we cannot confirm if it will be authorized. He asked to minimize records created before the payment and to create them after the provider confirms it.

**What we did next:** Resolved. We do not create a Pending donation. A donation exists only after the provider confirms the payment. Before that we save a separate payment attempt (PAY-07), and attempts not confirmed are deleted after 7 days (team proposal, so we do not keep personal data of people who did not donate).

---

### Q-04 - Suggested amounts, minimum and maximum

- **Author:** Karen Elizabeth Campos (for the team)
- **Date:** 2026-11-03
- **Answered:** 2026-11-04 (Slack and Q&A session)
- **Type:** Business question
- **Where asked:** Slack
- **Related story:** DON-08, DON-09, DON-18, ADM-13 (RF-D1a, RF-D1b)

1. **What we were trying to achieve:** choose the suggested amounts and the limits.
2. **What we did:** the professor asked us to suggest, so we proposed $100, $250, $500 and $1,000 MXN plus a custom amount, a $50 minimum and a $20,000 maximum (enough for one student's trip, and it stops entry mistakes like an extra zero).
3. **What we expected:** approval or adjustments.
4. **What happened:** see the answer below.
5. **What we consulted:** limits of the Mercado Pago test account (to document in TEC-02).

**Answer received:** the professor liked the proposal and added $2,000, $5,000, $10,000 and $20,000. He would not set a maximum: any money is welcome for a non-profit, unless the payment gateway sets one, and that is for us to check in its documentation. For amounts of $1,000 or more, a dialog should ask the donor to confirm the amount. In the session a classmate noted that a double check helps in both directions (typing 50 when you meant 500). The minimum and the increments are ours to define; if the client wants to change them, they can be configurable, and if not, they are hard-coded.

**What we did next:** Resolved. Eight quick amounts ($100 to $20,000), minimum $50, adjustable by the administrator (ADM-13), no maximum of our own beyond Mercado Pago's limit (TEC-02). The team decided that everyone confirms a summary before paying, whatever the amount (DON-18), which covers the $1,000 case.

---

### Q-05 - Campaigns that reach their goal or pass their date

- **Author:** Karen Elizabeth Campos (for the team)
- **Date:** 2026-11-03
- **Answered:** 2026-11-04 (Slack and Q&A session)
- **Type:** Business question
- **Where asked:** Slack
- **Related story:** GES-11, GES-02, DON-03 (RF-S1)

1. **What we were trying to achieve:** know when a campaign stops receiving donations.
2. **What we did:** asked the professor as client about reaching 100 % and about the end date.
3. **What we expected:** a rule for both cases.
4. **What happened:** see the answer below.
5. **What we consulted:** RF-S1 of the guide.

**Answer received:** if the date has passed, stop receiving donations. Reaching 100 % does not stop them: the goal can be exceeded and donations keep coming (the session compared it with crowdfunding sites). The only case to close a campaign is the date. He also said there should always be an open campaign for general donations, so people can donate even when no main campaign is running.

**What we did next:** Resolved. A campaign stops accepting donations at the end of its closing date (Merida time) or when it is closed by hand. Progress can exceed 100 % (DON-03). An alert at 100 % was left out of scope (WON-12). About the general campaign (B9): it fits our model as one more campaign without closing date; add it to the demo data (TEC-06).

---

### Q-06 - Information needed for the receipt and the invoice

- **Author:** Karen Elizabeth Campos (for the team)
- **Date:** 2026-11-03
- **Answered:** 2026-11-04 (Slack and Q&A session)
- **Type:** Business question
- **Where asked:** Slack
- **Related story:** DON-12, DON-23 (RF-F1, RF-D5)

1. **What we were trying to achieve:** define the content of the receipt email (RF-D5).
2. **What we did:** proposed reference number, campaign name, amount, date, donation type and donor name (if not anonymous), and asked if more institutional text is needed.
3. **What we expected:** approval or extra wording.
4. **What happened:** see the answer below.
5. **What we consulted:** the fiscal data a Mexican invoice needs.

**Answer received:** Slack: he asked us back what the minimum information is to send an invoice; a ticket in the email is the minimum. Session: there is no checklist; our list (campaign, amount, date, donation type, donor name, reference number) is fine, and we should check what online receipts usually include. For the invoice, ask for what is needed to issue one. One receipt is enough, and if the payment gateway already sends it we do not have to send another. The language is Spanish. He also said the project will not ask for electronic signature or stamping (no timbrado).

**What we did next:** Resolved. Receipt: campaign, amount, date and operation reference, in Spanish, sent once by the portal (the Mercado Pago receipt goes to a fictitious test buyer email), with a note that it is a test operation without fiscal value; no name if the donation is anonymous (DON-23). Invoice: name or business name, RFC, fiscal postal code and fiscal regime; the system only captures the data and does not issue or stamp invoices (DON-12, WON-03). Logo, folio or other legend (B10) is our decision.