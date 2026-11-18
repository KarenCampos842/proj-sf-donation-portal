# AI Usage Log

Record relevant AI use when it happens. Never paste API keys, tokens, credentials, payment-card details or personal donor data into an AI tool or this file.

This log keeps the most useful **best-prompt** and **worst-result** examples. Each entry records the author, date, tool, related stories, result, verification and estimated time saved or lost. Time estimates are not measured unless explicitly stated.

## Summary

| # | Date | Author | Tool / model | Related stories / work | Result | Verification / estimated time impact |
|---|---|---|---|---|---|---|
| 1 | 2026-11-08 | Karen Elizabeth Campos | Claude | All 44 backlog stories; GitHub board | Best | 43 issues created in bulk because DON-01 already existed; dry run and sample issues checked. ~30 min vs. 3–4 h, team estimate. |
| 2 | 2026-11-08 | Karen Elizabeth Campos | Claude | All backlog stories | Worst | Windows encoding corrupted Spanish accents and `ñ`; corrected with UTF-8 and a safe `--fix` mode. ~20 min lost. |
| 3 | 2026-11-08 | Alan Pérez | Claude (Opus 5.5) | Backlog v2; all stories | Best | Compared backlog v2 with the project guide and Q&A; identified an incorrect 75% coverage requirement in the DoD. ~1 h vs. 3 h, estimate. |
| 4 | 2026-11-08 | Alan Pérez | Claude (Opus 5.5) | GES-02/03/06/07/09, ADM-03/05, SEG-01 | Worst | First data-model draft needed corrections to voice, language, Apex usage and privacy controls. ~3 h vs. 8 h, estimate. |
| 5 | 2026-11-09 | Karen Elizabeth Campos | ChatGPT + Agentforce (VS Code) | Shared Delivery 1 data-model dependencies: DON-01/02/03/04/08/10/11/12/17/18/19/20/21; GES-02/03/06/07/09; ADM-03/05/07; PAY-02/PAY-07; SEG-01 | Best | Salesforce reported 55/55 metadata components deployed successfully; the three objects, fields and validation rules were checked. ~2–3 h vs. 5–6 h, estimate. |
| 6 | 2026-11-09 | Rodrigo Colli | Claude Code (Opus 5.5), VS Code | PAY-07, PAY-02, ADM-07, DON-19/20/21 | Best | Payment flows and Mercado Pago callout actions delivered in PR #47; check-only deployments, tests and Code Analyzer checks passed. ~6 h vs. 16–20 h, estimate. |
| 7 | 2026-11-09 | Rodrigo Colli | Claude Code (Opus 5.5) | PAY-07, PAY-02 | Worst | AI initially proposed Apex against the Flow-first rule and generated invalid Flow metadata; check-only validation caught the errors before deployment. ~30 min lost. |
| 8 | 2026-11-09 | Alan Pérez | Claude (Opus 5.5) | GES-02/03/06/07/09, ADM-03/05 | Worst | Workstream C configuration was deployed, but the initial command and verification guidance needed correction for PowerShell and permission-dependent visibility. ~1.5 h vs. 5 h, estimate. |
| 9 | 2026-11-10 | Karen Elizabeth Campos | ChatGPT + Agentforce (VS Code) | DON-01/02/03/04/10/11; existing campaign records and public Guest catalog | Best | Existing campaigns updated by ID, test campaigns moved to Draft and seeded public-recognition records anonymized; Guest catalog and direct URLs checked. ~1–2 h vs. 3–4 h, rough estimate. |
| 10 | 2026-11-16 | Rodrigo Colli | Claude Code (Opus 5.5), VS Code | PAY-06, PAY-01, PAY-03, DON-24, ADM-12; bug #54 | Best | Signed Mercado Pago webhook built from the issue ACs; dry-run deployment with 52 passing tests before the real deployment; public endpoint checked from the internet. Time not measured. |
| 11 | 2026-11-10 | Rodrigo Colli | Claude Code (Opus 5.5), VS Code | Delivery 1 evidence (DON-19/20/21, PAY-02/07, ADM-07) | Worst | The AI changed and deployed two page layouts owned by another workstream to make a screenshot easier, and first gave wrong advice about Mercado Pago test emails; both were reverted or corrected. ~45 min lost. |
| 12 | 2026-11-16 | Rodrigo Colli | Claude Code (Opus 5.5), VS Code | PAY-06, PAY-01, PAY-03, DON-24, ADM-12; bug #54 | Best | Real test payments got no webhook. The AI checked the payment with the Mercado Pago API (`live_mode=true`), and after the owner refused the first fix (registering a business for production webhooks) it sent `notification_url` in the preference. Notices then arrived 1–3 s after each payment; 16 screenshots taken. Time not measured. |
| 13 | 2026-11-16 | Rodrigo Colli | Claude Code (Opus 5.5), VS Code | PAY-08 (#60) | Best | Hourly reconciliation built from the owner's concern that notices can be lost. The AI tested the Mercado Pago search endpoint live before designing, and the first dry run caught an invalid Schedulable+Queueable class; 56 tests passed after the fix. Time not measured. |
| 14 | 2026-11-16 | Karen Elizabeth Campos | Claude Code, VS Code | DON-13 (privacy notice with invoice) | Best | Server check in the controller and the flow, server-side timestamp and copy to the donation, with Jest and Apex tests; check-only validation passed (115/115 tests); a real paid sandbox payment confirmed the copy of the acceptance to the donation. Time not measured. |
| 15 | 2026-11-17 | Rodrigo Colli | Claude Code (Opus 5.5), VS Code | PAY-08 (#60) | Worst | A teammate's review of PR #61 found two problems the AI missed: an amount mismatch would log the same rejected notice every hour, and more than ~50 pending payments would exceed Apex limits and fail the whole run. Fixed with Batch Apex (chunks of 20) and a filter on existing mismatch notices; 61 tests passed. Time not measured. |
| 16 | 2026-11-17 | Rodrigo Colli | Claude Code (Opus 5.5), VS Code | ADM-13 (#39) | Best | Configurable amounts built from the data-model design; the AI changed the planned comma-separated field to eight number fields so AC3 can be enforced by a validation rule. The first Apex validation failed 56 tests: amounts read from custom metadata (150.0) did not match the form's amounts (150) in List.contains; fixed by normalizing to two decimals. Then 242/242 Apex tests and 231 Jest tests passed. Time not measured. |
| 17 | 2026-11-17 | Karen Elizabeth Campos | Claude Code, VS Code | DON-09 (#8), DON-18 (#14) | Best | Custom amount as exact text and a review step with a server-side token; the AI found that an Id alone could open a payment and closed it. Jest 336/336 and a check-only with 177/177 Apex tests before any deployment. Time impact not measured. |
| 18 | 2026-11-17 | Karen Elizabeth Campos | Claude Code, VS Code | DON-09 (#8), DON-18 (#14) | Worst | An independent read-only review found five problems in the first pass: `BigInt` untested under Lightning Web Security, a payment error message that offered a retry that no longer exists, `invalidate` acting on an attempt that already opened a payment, no focus tests, and gaps in this log. All were corrected. Final check-only `0AfVC00000PJ0h40AD` is **Failed**: 459/465 tests, and the 6 failures belong to org code outside the repository. Time impact not measured. |
| 19 | 2026-11-17 | Rodrigo Colli | Claude Code (Opus 5.5), VS Code | DON-18 (#14), ADM-13 (#39) | Best | Workstream A review of PR #72. The AI noticed that the minimum-amount rule ran on every save of an attempt, so raising the minimum could revert the donation of a payment already charged; the rule now runs only on create or amount change. The generic payment message was copied in two classes; it is now one constant, checked against the flow by tests. Double-payment mitigation decided: not applied. Time not measured. |
| 20 | 2026-11-17 | Alan Pérez | Claude (Opus 5.5) | GES-10/11/12/15, MOD-01/03/06, ADM-01/04; DON-23 | Worst | Workstream C Delivery 2 metadata deployed (15 components). The dry run caught a missing permission dependency; the AI also prepared ADM-13 while a teammate had already built it, and suggested the wrong evidence-folder naming. ~2 h vs. ~5 h, estimate. |

---

## Selected entries

### Entry 1 — Bulk creation of backlog issues from the PDF

- **Date:** 2026-11-08
- **Author:** Karen Elizabeth Campos
- **Tool / model:** Claude
- **Related stories:** All 44 stories; RNF-12 and GitHub board structure
- **Result type:** Best prompt
- **Verification:** A dry run counted 44 stories (22 Delivery 1, 21 Delivery 2 and 1 unscheduled). The script created 43 issues because DON-01 already existed; a sample of issues was checked in GitHub.
- **Estimated speed-up:** About 30 minutes with AI vs. 3–4 hours manually; team estimate, not timed.

**Prompt summary**

```text
Create the project stories in bulk from backlog v2, using the exact structure
of issue #1: RF covered, Story, Given/When/Then acceptance criteria, technical
tasks and evidence. Apply the agreed Delivery 1 / Delivery 2 scope changes,
remove the excluded extra criteria, preserve Spanish text, and include the
required board fields: ID, RF, milestone, story, AC, status and evidence.
```

**What we got**

A Python script (`scripts/crear_issues.py`) that uses the GitHub CLI to create the stories in the format of issue #1, with their milestones, assignees and board entries. The script initially wrote the board to `docs/tablero.md`; the current board path is `docs/story-tracking-board.md`.

**Why it worked**

The prompt supplied the exact output format, the source document and the agreed scope changes. It also specified the board columns required by the project guide, leaving fewer decisions for the AI to guess.

**What we corrected**

The first script output had the encoding problem described in Entry 2.

---

### Entry 2 — Windows encoding error in generated issue content

- **Date:** 2026-11-08
- **Author:** Karen Elizabeth Campos
- **Tool / model:** Claude
- **Related stories:** All backlog stories
- **Result type:** Worst result
- **Verification:** Several GitHub issues were opened and showed missing or corrupted Spanish accents and `ñ` characters.
- **Estimated time lost:** About 20 minutes.

**Initial prompt**

```text
Same request as Entry 1. The operating system and encoding requirements
were not stated.
```

**What went wrong**

The generated script passed Spanish issue text through the Windows console encoding instead of UTF-8. It worked in the AI environment but corrupted text on the team's Windows machines.

**Correction and lesson**

The script was changed to force UTF-8 and provide a `--fix` mode that rewrites existing issue titles and bodies without deleting issues or changing milestones, assignees or board fields. The team ran `--fix` and checked the affected issues again.

**Better prompt**

```text
We use Windows 11 and PowerShell. The issue content is Spanish and includes
accented characters and ñ. Make every file and GitHub CLI input UTF-8, and
provide a dry-run or preview so we can inspect the output before creating or
rewriting issues.
```

---

### Entry 3 — Backlog v2 review against the project guide and Q&A

- **Date:** 2026-11-08
- **Author:** Alan Pérez
- **Tool / model:** Claude (Opus 5.5)
- **Related stories:** Backlog v2; all stories
- **Result type:** Best prompt
- **Verification:** The project guide was checked and found not to require a 75% coverage percentage. Salesforce documentation was checked for the scope of the 75% production coverage requirement. Mercado Pago documentation was checked for the test seller and buyer accounts required for Checkout Pro testing.
- **Estimated speed-up:** About 1 hour with AI vs. about 3 hours without; estimate.

**Prompt record**

The original prompt text was not preserved in the supplied log. The recorded task was to review backlog v2 against the project guide and the Q&A session, and identify inconsistencies or scope risks.

**What we got**

A list of risks: Delivery 1 appeared too large (27 stories and approximately 130 acceptance criteria), no shared org had yet been decided, and the draft Definition of Done included a requirement not present in the guide. The review also proposed stories to move to Delivery 2.

**What worked**

The review included the source documents (guide, session and backlog), allowing the AI to compare them rather than answer from general knowledge alone.

**What we corrected**

- **AI error in backlog v2:** the DoD stated that 75% code coverage was required “to deploy to Developer Edition.” Official documentation and the project guide showed that this was not a project requirement. The 75% target was removed from the DoD; tests remained required.
- The assistant assumed the team used Developer Edition and warned about its license limits. The team later confirmed it used the program's Sandbox, so that warning did not apply.

---

### Entry 4 — First data-model draft

- **Date:** 2026-11-08
- **Author:** Alan Pérez
- **Tool / model:** Claude (Opus 5.5)
- **Related stories:** GES-02, GES-03, GES-06, GES-07, GES-09, ADM-03, ADM-05 and SEG-01
- **Result type:** Worst result
- **Verification:** Salesforce documentation was checked for criteria-based sharing rules and master-detail sharing behavior. The RFC validation pattern was tested against valid and invalid backlog examples. The team checked that every field referenced by formulas and rules existed in the document.
- **Estimated speed-up:** About 3 hours with AI vs. about 8 hours without; estimate.

**Prompt record**

The original prompt text was not preserved in the supplied log. The recorded task was to produce an initial data-model draft covering objects, fields, formulas, validation rules, permissions and personal-data classification.

**What went wrong**

The first draft needed several rounds of corrections. The prompt did not specify the document's audience, the repository's language conventions or the preference for declarative implementation over Apex. The AI filled those gaps with incorrect assumptions.

**What we corrected**

- **AI error:** it proposed normalizing the RFC in the code that creates the record. The agreed solution was a before-save Flow, which runs before validation rules.
- **AI error:** giving the moderator permission to change visibility could allow an anonymous donation to become public, contrary to RF-D2. The issue was addressed with the `Anonymous_Cannot_Become_Public` validation rule.
- API names were initially in Spanish; they were changed to English API names with Spanish labels.
- Personal notes such as “my stories” and “useful for the oral defense” were rewritten as project documentation for the team and reviewers.
- The final model was checked against Salesforce sharing behavior and the RFC examples. The final version is `docs/data-model.md`.

---

### Entry 5 — Delivery 1 custom-object metadata implementation

- **Date:** 2026-11-09
- **Author:** Karen Elizabeth Campos
- **Tool / model:** ChatGPT + Agentforce (VS Code)
- **Related stories:** Shared D1 data-model dependencies for DON-01/02/03/04/08/10/11/12/17/18/19/20/21, GES-02/03/06/07/09, ADM-03/05/07, PAY-02/PAY-07 and SEG-01
- **Result type:** Best prompt
- **Verification:** Salesforce reported `Succeeded`: 55 of 55 metadata components, zero component failures and zero test errors. The three objects, fields and validation rules were checked in the org. Formula and roll-up behavior with records was not verified as part of this metadata deployment check.
- **Estimated speed-up:** Approximately 2–3 hours with AI vs. 5–6 hours without AI; conservative estimate, not timed.

**Prompt summary**

```text
Act as an experienced Salesforce architect and Salesforce DX developer.
Implement only the Delivery 1 metadata for Fundraising_Campaign__c,
Payment_Attempt__c and Donation__c in the existing VS Code project.

Before editing, inspect the repository and connected Salesforce org. Read
 docs/data-model.md as the source of truth for API names, labels, field types,
relationships, formulas, validation rules and D1 scope, plus the project
context and backlog documentation.

Retrieve the existing Fundraising_Campaign__c metadata and complete only
missing or incorrect items. Create or retrieve Payment_Attempt__c and
Donation__c only if needed, preserving the documented Lookup and
Master-Detail relationships, fields, formulas, roll-ups, picklists and
validation rules. Distinguish metadata from Salesforce records: do not
create campaign or donation records.

Preserve exact API names, Spanish labels, field lengths, precision, scale,
defaults, restricted picklist values, External ID settings and history
settings. Exclude Delivery 2 fields and features, and do not add unrelated
Flows, Apex, LWCs, permission sets or sharing rules.

Generate standard Salesforce DX metadata under
force-app/main/default/objects/. Validate XML, filenames, references,
relationships, formulas, roll-ups and validation rules. Do not deploy,
create records, commit or push without separate authorization. Report the
initial state, generated files, unresolved decisions and validation results.
```

**What we got**

The existing `Fundraising_Campaign__c` metadata was retrieved and completed rather than duplicated. `Payment_Attempt__c` and `Donation__c` were created for Delivery 1. The resulting model included the three custom objects, 42 custom fields, Lookup and Master-Detail relationships, two roll-up summaries, formulas and nine validation rules. The retrieved campaign list view was preserved.

After review and separate explicit authorization, the metadata was deployed to the `donations-dev` Sandbox. Salesforce reported `Succeeded`: 55 of 55 components, zero component failures and zero test errors. No campaign or donation records were created by this metadata task.

**Why it worked**

The prompt identified `docs/data-model.md` as the source of truth, required inspection and retrieval of the existing campaign object, prevented duplicate metadata, separated object metadata from records, defined the D1/D2 boundary and kept deployment as a separately authorized step. Iterative review was still needed to align field-history settings and help text with the documented model.

**What we verified and corrected**

- Validated the 55 metadata components with a dry run against `donations-dev`; Salesforce reported 55/55 components and zero errors.
- After explicit authorization, deployed to `donations-dev`; Salesforce reported 55/55 components, zero failures and zero test errors. Deployment ID: `0AfVC00000PBFdF0AX`.
- Listed metadata after deployment and confirmed the three objects existed with 13, 13 and 16 custom fields respectively, and that the nine validation rules were present.
- Confirmed the repository metadata and deployed object/field definitions were consistent.
- Formula and roll-up behavior was not tested with records during this task.
- Retrieved `Fundraising_Campaign__c` and updated it instead of creating a duplicate; created the other two D1 objects.
- Confirmed the documented history settings for `Goal__c` and `Donation__c.Public_Name__c`.
- Checked the external sharing model, Lookup and Master-Detail settings, and roll-up summary references.
- Corrected help text and descriptions that implied automations not yet implemented.
- Updated `docs/data-model.md` and `docs/ai-context/PROJECT_CONTEXT.md` to align with the D1 model and distinguish D1 field history from D2 moderation behavior.
- Kept D2 elements and unrelated pre-existing Salesforce objects out of this deployment.

---

### Entry 6 — Mercado Pago payment flows with Flow-first implementation

- **Date:** 2026-11-09
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5), VS Code
- **Related stories:** PAY-07, PAY-02, ADM-07, DON-19, DON-20 and DON-21
- **Result type:** Best prompt
- **Verification:** Check-only deployments and tests were run before deployment; Code Analyzer reported no severity 1–3 findings. The Mercado Pago test account `/users/me` endpoint identified a `test_user`, a preference was created and a fake payment lookup returned `NotFound`. Delivered in PR #47.
- **Estimated speed-up:** About 6 hours with AI vs. 16–20 hours without; estimate, not timed.

**Prompt / decision summary**

```text
Use the class Sandbox donations-dev and compare the existing D1 objects with
 docs/data-model.md before implementing. Use Flow wherever possible and Apex
only where Flow cannot perform the required callout. For Checkout Pro, create
the preference server-side and let Mercado Pago capture card data. Keep all
credentials in Named/External Credentials, validate with check-only deploys
and tests, and do not commit or push without authorization.
```

**What we got**

Five flows (`Payment_Attempt_Create`, `Payment_Preference_Create`, `Payment_Return_Process`, `Donation_Register` and `Payment_Attempt_Delete_Stale`), the `Rejected_Notice__c` object, two invocable Apex classes for Mercado Pago callouts with `HttpCalloutMock` tests, and the ADM-07 layout and search. Credential setup was documented in `security.md`. The work was delivered in PR #47.

**Why it worked**

The assistant checked the org, repository and data model before changing anything, validated changes with check-only deployments before real deployments, and separated decisions requiring the owner's authorization (org selection, Flow vs. Apex, deployment, commit and push).

**What we verified and corrected**

- Check-only deployments with tests before each real deployment: 34 temporary tests for the first flows (not committed), then 12 and 17 permanent tests for the callout actions, with 96% coverage each.
- Code Analyzer (Recommended): no severity 1–3 issues.
- Live checks against the Mercado Pago test account: `/users/me` returned an account tagged `test_user`, a preference was created, and a payment lookup returned `NotFound` for a fake ID.
- Git history was searched for Mercado Pago tokens; no matches were found at that time.
- The pre-commit hook initially checked only Stripe keys; it was updated to also block Mercado Pago tokens.
- The initial AI errors are described in Entry 7.

---

### Entry 7 — Wrong first recommendations and rejected Flow metadata

- **Date:** 2026-11-09
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5)
- **Related stories:** PAY-07 and PAY-02
- **Result type:** Worst result
- **Verification:** Every Flow was validated with a check-only deployment before deployment. The metadata errors were caught during validation, not deployed to the org.
- **Estimated time lost:** About 30 minutes.

**Initial prompt / context**

The initial request was essentially “start with the card” (PAY-07), without restating the project's Flow-first rule, the Sandbox context or the required payment architecture.

**What went wrong**

The assistant initially proposed an Apex class for PAY-07, even though the project rule was to use declarative tools first. It later generated Flow XML by hand that Salesforce rejected. The generated metadata placed `environmentTypes` in an invalid location and used “Roll Back Records” in an autolaunched Flow, where that setting was not supported. The assistant also made incorrect assumptions about the team's Sandbox and the scheduled cleanup time.

**What we corrected**

- **AI error:** proposed Apex for PAY-07 against the project rule. The design was changed to Flow, with Apex only for callouts that Flow could not perform.
- **AI error:** generated unsupported Flow metadata. The invalid element placement was removed and transaction rollback was left to the unhandled error.
- **AI error:** claimed the class Sandbox could not be the team org because the guide mentioned Developer Edition. The team org was the program Sandbox.
- **AI error:** stated that daily cleanup would run at 21:00; the org scheduled it at 03:00 Mérida time.

**Better prompt**

```text
Implement PAY-07 in donations-dev following docs/data-model.md. Use Flow first
and Apex only where Flow cannot meet a requirement, and justify each Apex class.
Revalidate campaign, amount, visibility and tax regime on the server; the Guest
user must have no permission on Payment_Attempt__c. Validate every metadata
change with a check-only deployment and tests before deploying, and do not
commit to main.
```

**Lesson**

Restate the architecture rules, target org, shell/runtime context and validation gates in each implementation prompt. A check-only deployment should precede any deployment.

---

### Entry 8 — Workstream C configuration: permission sets, list views, rules and Flow

- **Date:** 2026-11-09
- **Author:** Alan Pérez
- **Tool / model:** Claude (Opus 5.5)
- **Related stories:** GES-02, GES-03, GES-06, GES-07, GES-09, ADM-03 and ADM-05
- **Result type:** Worst result
- **Verification:** The deployment was run with `--dry-run` first and then deployed successfully. The team checked the permission sets in Setup, the active RFC-normalization Flow, list views and tabs. The RFC Flow was tested from the CLI. Permission-set behavior with a separate test user had not yet been tested.
- **Estimated speed-up:** About 1.5 hours with AI vs. about 5 hours without; estimate.

**Prompt summary**

```text
Compare the metadata already in the repository against docs/data-model.md,
list what is missing for Workstream C in Delivery 1, generate that metadata,
and provide step-by-step instructions to deploy only those files to the Sandbox.
```

**What we got**

A comparison of the deployed objects against the data model and 14 metadata files, including permission sets, list views, tabs, `Donation__c` validation rules, a before-save Flow to normalize the RFC, and the `Visibility__c` field configuration. The deployment command was scoped to the intended files so it would not overwrite unrelated org changes.

**Why it worked / why it failed**

The comparison and metadata were correct and deployed successfully on the first try. However, the prompt did not identify Windows and PowerShell, so the AI supplied a command format that did not work in PowerShell. One verification step also assumed the admin user could see the new tabs.

**What we verified and corrected**

- The deployment was run with `--dry-run` first, then deployed successfully.
- In the org, the three permission sets appeared in Setup; the Flow “Intento de pago - Normalizar RFC” was active; the views “Estado y avance de campañas”, “Todas las donaciones” and “Solicitan factura” existed; and both tabs showed their icons.
- Tested the RFC Flow from the CLI: `eku 9003173c9` was saved as `EKU9003173C9` (taxpayer type “Moral”).
- Permission-set behavior with a separate test user was not yet tested at the time of the entry.
- **AI error:** the deployment command used `\` line continuations, which work in Bash but not PowerShell. It was replaced with a one-line command.
- **AI error:** the AI suggested checking tabs in the App Launcher. They were not visible to the admin user because that user did not have one of the new permission sets. The objects were verified through their list URLs instead.
- **AI error:** the AI supplied a data-import command without checking field access. The import failed with `FlsError` on `Description__c`, because fields deployed through metadata did not grant access to a profile. A team-only `Portal_Developer` permission set was created and assigned to team members.

**Better prompt**

```text
I am on Windows with PowerShell in VS Code. Give commands that work in
PowerShell. For each verification step, tell me which user or permission
set it requires.
```

---

### Entry 9 — Existing campaign records and public Guest catalog cleanup

- **Date:** 2026-11-10
- **Author:** Karen Elizabeth Campos
- **Tool / model:** ChatGPT + Agentforce (VS Code)
- **Related stories:** DON-01, DON-02, DON-03, DON-04, DON-10 and DON-11
- **Result type:** Best prompt
- **Verification:** Five existing campaign records were updated by ID without duplication; three visible `[PRUEBA]` campaigns were changed to Draft; three seeded public-recognition donations were changed to Anonymous. Agentforce reported a Guest-browser check of 32/32 at 1280 px and 360 px, with four intended catalog cards and Draft records unavailable by direct URL. Campaign totals and donation relationships were rechecked.
- **Estimated speed-up:** Approximately 1–2 hours with AI vs. 3–4 hours without AI; rough estimate, not timed.

**Prompt summary**

```text
Inspect the existing campaign records by Salesforce ID and update those
records in place. Preserve IDs, goals, dates, statuses unless explicitly
approved, and all donation relationships. Never rerun the original tree
import because it inserts records and may create duplicates. Retire only the
three identified test campaigns from the public catalog by changing their
status to Draft after checking validation rules. Preserve donations. For the
three seeded recognition records, change only Visibility__c to Anonymous;
do not invent donor identities or alter amounts, payment status or campaign
relationships. Verify the public catalog and direct URLs as an unauthenticated
Guest, and make no code, permission or payment changes.
```

**What we got**

The five intended portal campaigns retained their Salesforce IDs and donation relationships while their public names and descriptions were updated. The three test campaigns that had appeared publicly were set to Draft; their records and donations were preserved. Three seeded recognition entries were anonymized, and public totals continued to display correctly.

**Why it worked**

The key safeguard was to inspect existing records and update them by ID rather than reload demo JSON, which could create duplicates. The prompt also limited the allowed field changes and explicitly protected donation amounts, statuses and relationships.

**Remaining verification noted at the time**

The public distribution and field updates for four recently uploaded campaign images still required confirmation. This note records that follow-up separately from the acceptance status of the stories.

---

---

### Entry 10 — Signed Mercado Pago webhook from the acceptance criteria

- **Date:** 2026-11-16
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5), VS Code
- **Related stories:** PAY-06, PAY-01, PAY-03, DON-24, ADM-12 and bug #54 (DON-20 AC4)
- **Result type:** Best prompt
- **Verification:** Dry-run deployment with 52 tests passing (validator 100%, service 93%, REST entry 94% coverage) before the real deployment; unsigned `POST` sent from the internet to the public endpoint was answered and logged as a rejected notice.
- **Estimated speed-up:** Not measured.

**Prompt / decision summary**

```text
Do all my Delivery 2 cards, but give me the plan first. Read the ACs of each
issue and the current code before planning. Do not modify components owned by
other team members. Keep the webhook secret out of the repo and out of the chat.
```

**What we got**

- A written plan, approved before any change: the order of work, what the owner must do by hand (the Mercado Pago panel and the secret in Salesforce), and the risks.
- Three Apex classes: `MercadoPagoWebhookResource`, `MercadoPagoSignatureValidator` and `MercadoPagoNotificationService`. The webhook is Apex because a public REST endpoint cannot be built with Flow; the donation is still registered by the existing `Donation_Register` flow.
- A protected custom setting for the secret, a new picklist value, the `Rejected_Notice_Viewer` permission set, and a tab and list view for the rejection history.
- The `Payment_Return_Process` fix for #54.

**Why it worked**

- The plan came from the real ACs and the existing flows. The assistant found that duplicates, amount checks and rejection logging already existed in `Donation_Register`, so it reused them instead of rebuilding them.
- It noticed that the #54 fix also needs a one-line change in the portal component of Workstream B. It did not change that component, and reported the change to its owner instead.

**What we verified and corrected**

- The first dry run failed: a permission-set description was over 255 characters. It was shortened and the dry run was run again.
- Callouts after DML are not allowed in one transaction, so "the same notice twice" is tested by simulating the first registration with an existing donation.
- The guest access is granted through the payments permission set; the guest profile was not changed.

---

### Entry 11 — Changing another workstream's layouts while collecting evidence

- **Date:** 2026-11-10
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5), VS Code
- **Related stories:** Delivery 1 evidence for DON-19/20/21, PAY-02, PAY-07, ADM-07
- **Result type:** Worst prompt
- **Estimated time lost:** About 45 minutes.

**What went wrong**

- To make some fields visible for a screenshot, the AI edited and deployed the `Donation__c` and `Payment_Attempt__c` page layouts. Those layouts belong to Workstream B. The owner stopped it ("no modifiques lo de karen"); both layouts were deployed back to their original version, and the evidence was taken with SOQL queries in the terminal instead.
- The AI first said that Mercado Pago test payments could not use `@testuser.com` emails. After research, the right answer was the opposite: guest checkout in test mode works with the payer email `test@testuser.com`.

**Lesson**

Before changing any component, check who owns it. For evidence, prefer read-only ways (queries, list views in our own objects) over changing shared configuration.

---

### Entry 12 — Real payments did not trigger the webhook

- **Date:** 2026-11-16
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5), VS Code
- **Related stories:** PAY-06, PAY-01, PAY-03, DON-24, ADM-12 and bug #54
- **Result type:** Best prompt
- **Verification:** Signed notices registered donations `DON-000022`, `DON-000023` and `DON-000024` 1–3 seconds after each payment; a rejected payment created no donation; no rejected notice was logged for valid notices.
- **Estimated speed-up:** Not measured.

**Prompt / decision summary**

```text
I paid the first one but I am not sure if I closed in time, check it.
[later] It asks me to register my organization and I do not want to do that.
```

**What happened**

- The panel simulator reached Salesforce, but a real approved test payment did not: no log, no donation, no rejected notice after 15 minutes.
- The AI asked Mercado Pago for that payment through the existing Named Credential (without showing the token) and found `live_mode=true`. Payments made with a test seller account count as "production" for Mercado Pago, so their notices go to the production webhook URL, not the test-mode one.
- Its first proposal was to set the production URL in the panel. The owner refused, because it requires registering a business. The second proposal was to send `notification_url` in each preference. The action already had that input; only a custom label and one flow input were added, validated (22 tests) and then deployed.
- That first approved payment was registered by resending its notice from the panel simulator with the real payment id. This is written down in the issue evidence.

**What we verified and corrected**

- After the change, three real test payments were registered by the webhook without returning to the portal, including one whose campaign was closed while the payment was open (DON-24).
- The owner pointed out that, in production, Mercado Pago notices can be hours late or never arrive. The gap was documented in `security.md` and a scheduled reconciliation was proposed for the backlog; it was not built, because Delivery 2 was due the next day.


### Entry 13 — Reconciliation for notices that never arrive

- **Date:** 2026-11-16
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5), VS Code
- **Related stories:** PAY-08 (#60)
- **Result type:** Best prompt
- **Verification:** Dry-run deployment with 56 tests passing (service 89%, job 100%) before the real deployment; one manual run in `donations-dev` read 18 approved payments and changed nothing, because all were already registered.
- **Estimated speed-up:** Not measured.

**Prompt / decision summary**

```text
Sometimes Mercado Pago does not send webhooks; it happened to me in production,
hours can pass and it never arrives. [later] Implement it and open the PR.
```

**What we got**

- Before designing, the AI called `GET /v1/payments/search` once through the existing Named Credential (only ids, statuses and amounts were printed). One search returns all approved payments of the last 7 days with their attempt reference, so the design asks Mercado Pago a few times per run instead of once per attempt. Abandoned attempts can no longer push the useful ones out of a fixed batch.
- The registration reuses `Donation_Register`, so duplicates, amount checks and rejection logging behave as in the webhook.

**What we verified and corrected**

- The first dry run failed: one Apex class cannot be both Schedulable and Queueable. The Queueable part was moved to an inner class.
- Scheduling the job was not done by the AI; the owner schedules it with one documented line.

---

### Entry 14 — Privacy notice when an invoice is requested (DON-13)

- **Date:** 2026-11-16
- **Author:** Karen Elizabeth Campos
- **Tool / model:** Claude Code, VS Code
- **Related stories:** DON-13 (#12)
- **Result type:** Best prompt
- **Verification:** Jest (227/227) and check-only deployments against `donations-dev` before merging. After PR #63 was merged (merge `2e1337f`), a check-only (`0AfVC00000PIC7Z0AX`) and the real deployment (`0AfVC00000PICFd0AP`) of the four fields, the two flows, the Apex classes, the form and the two permission sets: 15/15 components and 222/222 Apex tests in the selected payment and portal test classes. The site was published (job `08PVC00000gD7QB2A0`) and the guest checks ran against the published site.
- **Estimated speed-up:** Not measured.

**Prompt / decision summary**

```text
Record the acceptance of the privacy notice when the donor asks for an invoice, without breaking the Mercado Pago payment flow.
Validate on the server, set the date and time on the server, copy both to the donation, and never block attempts created before DON-13.
```

**What happened**

- The AI read the payment contract and the two flows first and found the smallest change: a new input in `Payment_Attempt_Create` with a decision and server-clock formulas, two copied fields in `Donation_Register`, and a new flag in `DonationPaymentController`. Both confirmation routes already run `Donation_Register`, so nothing was duplicated.
- It used a check in the flow and the controller instead of a validation rule, because a rule would also block status updates of older attempts without acceptance. A test registers such an attempt and passes.
- The new tests call the controller directly with the field false, null and omitted, call the flow without the controller, and confirm the payment through the return page and through the shared register flow.

**What we verified and corrected**

- The first check-only run failed: nine existing portal tests built invoice requests without the acceptance, which is now rejected by design. They were adapted and four tests were added. The first run also selected too few test classes, so the coverage warnings were an artifact of the selection.
- Rodrigo (Workstream A) reviewed the changes to `Payment_Attempt_Create`, `Donation_Register` and `DonationPaymentController` and approved the PR.
- After deployment, we found that the System Administrator profile has no access to the four new fields. The consent evidence is therefore readable through `Donation_Admin` and `Payment_Attempt_Viewer`. Karen's user was temporarily assigned both permission sets so real records could be inspected. The two attempts created with invoice and accepted privacy notice store `true` and a server-generated date; the attempt without invoice stores `false` and no date. The seven donations with invoice that existed before DON-13 remain `false` with no date, and five of their attempts were confirmed without being blocked.
- A paid sandbox payment made by the owner with the test buyer account (attempt `a1dVC00000GpiFVYAZ`, 100 MXN, invoice and acceptance) completed the verification on real records: the attempt is `Confirmed`, exactly one donation (`DON-000025`, `a1cVC00000AID5tYAH`) exists for it, and both records hold acceptance `true` and the same date and time. The AI did not make the payment or touch any record. The temporary permission-set assignments of Karen's user were then removed. Issue #66 tracks the missing visible content of the privacy notice.

---

### Entry 15 — Limits and repeated notices missed in the first reconciliation

- **Date:** 2026-11-17
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5), VS Code
- **Related stories:** PAY-08 (#60)
- **Result type:** Worst prompt
- **Estimated time lost:** Not measured; the first version was never scheduled, so no data was affected.

**What went wrong**

- The first version (PR #61) registered every pending payment in one transaction. Each payment runs `Donation_Register` (about 2 queries and 3 writes), so more than about 50 pending payments would exceed the Apex limits and the whole run would fail every hour.
- When the amount does not match, `Donation_Register` logs a rejected notice but leaves the attempt `Started`. The first version would pick it up again every hour and log the same notice again, for up to 7 days.
- Both problems were found by Karen Campos in her review, not by the AI.

**What we changed and verified**

- The reconciliation became a Batch Apex: `start` makes the callouts and picks the payments, oldest attempt first, and leaves out payments that already have an "Amount_Mismatch" notice; `execute` registers chunks of 20, each in its own transaction.
- 61 tests passed in a dry run before deployment, including a test that a failing payment does not stop its chunk and a test for the mismatch filter. A manual batch run in `donations-dev` completed without errors.

**Lesson**

When a loop calls a flow, count the queries and writes per item and design for the worst case; and check what the reused flow leaves behind in each outcome.

---

### Entry 16 — Configurable suggested amounts and minimum (ADM-13)

- **Date:** 2026-11-17
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5), VS Code
- **Related stories:** ADM-13 (#39); touches DON-08 and DON-09
- **Result type:** Best prompt
- **Verification:** Check-only deployment with 242/242 Apex tests (DonationAmountSettings and DonationIntakeService at 100% coverage) and all Jest suites (231 tests), before the real deployment.
- **Estimated speed-up:** Not measured.

**Prompt / decision summary**

```text
ADM-13 is the only one that will be uploaded and it is urgent. Do it, but do not push
or change the org until I review what was done.
```

**What we got**

- `Donation_Amount_Setting__mdt` with a `Default` record (minimum 50 and the eight amounts of DON-08) and two validation rules for AC3 and AC4.
- `DonationAmountSettings` reads it, and the attempt rule `Minimum_Amount` reads the minimum from it.
- The form gets the amounts from the server and keeps the D1 amounts if the server fails.

**What we verified and corrected**

- The data model planned one text field with comma-separated amounts. A validation rule cannot check each value of such a list, so AC3 would not be enforced; it was changed to eight number fields.
- Custom metadata fields are read-only in Apex, so the tests build the record from JSON.
- The first Apex validation failed 56 tests, 51 of them existing Workstream B tests: custom metadata returns 150.0, the form sends 150, and `List.contains` treats Decimals with different scale as different values, so every donation was rejected as "monto no válido". Amounts are now normalized to two decimals before comparing. The bug was caught by the check-only run, before anything was deployed.
- The form and `DonationIntakeService` belong to Workstream B; those changes are in a separate commit for its owner to review.

### Entry 17 — Custom amount and review before paying (DON-09, DON-18)

- **Date:** 2026-11-17
- **Author:** Karen Elizabeth Campos
- **Tool / model:** Claude Code, VS Code
- **Related stories:** DON-09 (#8), DON-18 (#14); touches DON-08, DON-13 and DON-17
- **Result type:** Best prompt
- **Verification:** First pass: Jest 336/336 (9 suites). Targeted check-only against `donations-dev` (`0AfVC00000PIpNS0A1`, 22/22 components, 177/177 Apex tests, no deployment). Code Analyzer on the new and changed files. Nothing was deployed, committed or published when this entry was written. The final figures after the corrections are in Entry 18.
- **Estimated speed-up:** Not measured.

**Prompt / decision summary**

```text
Let the donor type another amount (exact decimal, minimum from ADM-13) and review a summary before paying.
The server is the only source of truth: nobody can read or confirm another donor's attempt, and an Id must never authorize a payment.
```

**What happened**

- The AI read the form, the services and the flows of Workstream A first and found that `openPayment(attemptId)` was callable by the guest with only an Id. The review step would have been decoration, because the browser could skip it. The fix was a random token whose hash is the only thing stored, the confirmation recorded with the server clock, and removing `@AuraEnabled` from the two methods of A that the portal does not call directly.
- The amount travels as text and is checked by `DonationAmountValidator`; the form compares amounts as strings of digits normalized to cents (by length first, then in lexicographic order) because a JavaScript `Number` turns `99999999999999.99` into `...98`. A test shows it. The first version of this entry used `BigInt` for that comparison; it was replaced in Entry 18.
- The AI did not invent a Mercado Pago limit or an idempotency key: the page it could reach mentions neither. The duplicate opening is documented as a risk that is not completely prevented.

**What we verified and corrected**

- The first check-only failed to compile: a local variable named `json` hid the `JSON` class (Apex ignores case), and the old `DonationPrivacyNoticeTest` still built the DTO with a number. The second run found tests that updated fields in user mode, an invoice without fiscal data in a test double, and a callout after a DML in the same test. All were test problems and none weakened an assertion.
- Mutation checks: five deliberate defects in the form (open without confirming, amount sent as a number, suggested amount not clearing the typed one, edit without retiring the old attempt, summary built from form values) were all caught by tests. The scripts that applied those mutations are not in the repository, so the result cannot be reproduced from it.
- Code Analyzer reported a constructor with six parameters in the summary DTO and missing ApexDoc; both were fixed. The complexity of `DonationIntakeService` went from 83 (origin/main) to 77.
- Not verified: the real Experience Cloud site (the amount comparison under Lightning Web Security, keyboard and screen reader), and the Guest user of the site; the tests simulate the guest with a minimum-access profile.

---

### Entry 18 — Corrections after the independent review (DON-09, DON-18)

- **Date:** 2026-11-17
- **Author:** Karen Elizabeth Campos
- **Tool / model:** Claude Code, VS Code
- **Related stories:** DON-09 (#8), DON-18 (#14)
- **Result type:** Worst result (of the first pass)
- **Verification:** Jest (whole project, `npx jest`, run on the final code after the four focus tests of H7 were added): 9 suites, 376/376 tests passed, 0 failed, 0 skipped. Check-only `0AfVC00000PJ0h40AD` (`--dry-run --test-level RunLocalTests`, `donations-dev`, nothing saved in the org): status **Failed**; 201/201 components with 0 component errors; 465 tests run, 459 passed, 6 failed. Against the previous reference (457/463) the difference is the 2 new Apex tests of H6. None of the 6 failures is in a class of DON-09 or DON-18. Nothing was deployed, pushed or published.
- **Estimated speed-up:** Not measured.

**Prompt / decision summary**

```text
Act as an independent reviewer and try to break the implementation; then apply only the corrections that belong to this branch.
```

**What happened**

- A separate read-only pass over the finished work (also run with Claude Code, at the author's request) found five points that the author's own checks had not shown (H3, H5, H6, H7 and H10). H3 to H7 are corrected in code and tests below; H10 is the gaps of this log (no `RunLocalTests` result and mutation scripts outside the repository), corrected in Entries 17 and 18. The known risks H2, H8 and `getPaymentResult` are written in `docs/security.md`.
- **H3, no `BigInt`.** `donationFormRules.js` no longer uses `BigInt`, `Number` or `parseFloat` in the rules of the custom amount. An amount is normalized to a string of digits in cents and two amounts are compared by length first and then in lexicographic order. Reason: `Currency(16, 2)` holds 16 digits in cents, more than `Number.MAX_SAFE_INTEGER`, and `BigInt` was not tested under Lightning Web Security. Tests: `compares 16-digit amounts exactly, where a Number would lose a cent`, `compares %p with %p as %p, by length first and then by string order`, `classifies %p as %p with a minimum of $50.50: the same amount passes and one cent less does not` and `accepts the minimum when it has a different number of digits than the amount typed`.
- **H5, payment error message.** `MSG_PAYMENT_FAILED` no longer says «o inténtalo de nuevo»: Workstream A's flow deletes the attempt when the provider fails, so the only way forward is to edit the donation. After a message from the server the form disables «Confirmar y continuar al pago» (`confirmBlocked`, `confirmDisabled` in `donationSummary`); a failure that is not a server message keeps it available. Tests: `leaves only «Editar donación» after the server refuses the payment, and confirms again after editing`, `keeps «Confirmar» available when the failure is not a message of the server, so the donor can retry` and `disables only the confirm button when the server refused the attempt`. **Assertions changed on purpose** (authorized behavior change): the existing test `shows the Spanish message of openPayment next to the summary and does not redirect` now expects the confirm button disabled, and `shows the message that lets the donor choose another amount when Mercado Pago cannot process it` now compares the new message, checks that it does not offer to retry and expects the confirm button disabled. The text of one assertion message in `DonationIntakeServiceTest` was also reworded.
- **H6, `invalidate`.** `DonationReview.invalidate` uses the same `canBeReviewed` check as the other operations: with `Preference_Id__c` filled, with a status other than `Started` or with an expired attempt it changes nothing. Apex tests: `shouldNotRetireTheAttempt_WhenEditingAnAttemptThatAlreadyOpenedAPayment` and `shouldNotRetireTheAttempt_WhenEditingAnAttemptThatIsNotStartedOrIsExpired`.
- **H7, focus.** Four Jest tests: `moves the focus to the title of the summary when the donor reaches the review step`, `moves the focus back to the title of the form when the donor chooses «Editar donación»`, `moves the focus to the custom amount field when its amount is not valid` and `moves the focus to the amount options when no amount was chosen`.

**What we verified and corrected**

- The four focus tests fail when the focus code is broken on purpose; the code was restored afterwards. That check was done by hand and is not a script in the repository.
- **The 6 failed tests are inherited debt outside this branch.** None of their classes (nor `OpportunityTrigger`) is in the repository: they exist only in `donations-dev`. The same 6 test names failed in validation `0AfVC00000PI9EX0A1`, which ran code based on `main`; no new direct comparison against `main` was made in this session.
  - `AccountExplorerControllerTest` (4): `getAccountsReturnsAllAccountsSortedByName`, `getContactsReturnsChildrenOfTheGivenAccount`, `getOpportunitiesReturnsChildrenOfTheGivenAccount` and `relatedListsAreEmptyNotNullForAnAccountWithoutChildren`. Cause investigated and checked in the org with read-only queries: `makeData()` inserts an `Opportunity`; the chain of errors ends in `OpportunityTrigger` (a trigger of the org), which queries a single `Campaign` named `FONDOS SDU` (`List has no rows for assignment to SObject`, line 22). That campaign does not exist in the org and the test does not create it. **Not verified:** why NPSP (`npsp.TDTM_Opportunity`) triggers the update that reaches the trigger.
  - `CancelSuscriptionEmailTest.sendEmail` and `testRecordatorioFormularios.probarEnviarCorreo` (2): `NO_MASS_MAIL_PERMISSION` («Single email is not enabled for your organization or profile»). Both use `Messaging.SingleEmailMessage`; the name of the error is only a label. The hypothesis is a mail setting of the org (Setup > Email > Deliverability); that setting could not be read, so the cause is **not confirmed**.
- Not verified: the real Experience Cloud site (the amount comparison under Lightning Web Security, keyboard and screen reader), a real payment with the Comprador account, and the Guest user of the site.

**Pending**

- Evidence on the published site and a real payment with the Comprador account.
- Review by Rodrigo of `DonationPaymentController` (two methods lost `@AuraEnabled`) and of the `Donation_Register` flow (risk H2 in `docs/security.md`).
- Deployment and publication in one window, then a smoke test.

---

### Entry 19 — Workstream A review of DON-09 / DON-18 (PR #72)

- **Date:** 2026-11-17
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5), VS Code
- **Related stories:** DON-18 (#14), DON-09 (#8), ADM-13 (#39)
- **Result type:** Best prompt

**Prompt / decision summary**

```text
Review Karen's new PR. Then, in another branch, fix what you reported and open the PR.
```

**What happened**

- The AI read the payment changes of PR #72 (the token, `PaymentAttemptAccess`, `DonationReview`, and `startDonation` / `openPayment` losing `@AuraEnabled`). It approved removing `@AuraEnabled`: no other caller exists, `getPaymentResult` is unchanged and `Payment_Preference_Create` still checks `Started` and an empty `Preference_Id__c`.
- **Minimum rule (bug found by the AI, not reported in PR #72).** `Payment_Attempt__c.Minimum_Amount` ran on every save. If the administrator raises the minimum (ADM-13) while a donation is in progress, saving the confirmation, the preference or the `Confirmed` status fails, and in `Donation_Register` that failure reverts the donation of a payment already charged. The rule now runs only with `ISNEW()` or `ISCHANGED(Amount__c)`. It is not covered by an Apex test: tests read the custom metadata of the org and cannot raise the minimum.
- **Generic payment message.** `DonationIntakeService` kept its own copy of «No pudimos abrir el pago, intenta de nuevo» to recognize it. It now reads `DonationPaymentController.GENERIC_ERROR` (made public), and the five `MercadoPagoPreferenceActionTest` assertions compare the flow output with that constant, so a change of the text in the flow fails a test instead of silently showing another message.
- **Double payment (risk H2).** Decision of Workstream A: the mitigation is not applied; registering both charged payments keeps Salesforce equal to Mercado Pago. Written in `docs/security.md`.

**What we verified**

- Before the fixes, on PR #72 as it is: Jest 9 suites, 376/376; check-only `0AfVC00000PJ8Uv0AL` with `RunSpecifiedTests` (the 32 test classes of the repository, which avoids the 6 org-only failures): Succeeded, 201/201 components, 320/320 tests.
- After the fixes: Jest 376/376; check-only `0AfVC00000PJAEz0AP` with the same `RunSpecifiedTests`: Succeeded, 201/201 components, 320/320 tests. The first check-only of the fixes failed because a validation rule description cannot pass 255 characters; the description was shortened. Nothing was deployed or published.

---

### Entry 20 — Workstream C, Delivery 2: closing campaigns, moderation views and role assignment

- **Date:** 2026-11-17
- **Author:** Alan Pérez
- **Tool / model:** Claude (Opus 5.5)
- **Related stories:** GES-10, GES-11, GES-12, GES-15, MOD-01, MOD-03, MOD-06, ADM-01, ADM-04; DON-23 (not built)
- **Result type:** Worst result (useful output, but with avoidable errors)
- **Verification:** `--dry-run` first, then a deployment of 15 components. In the org: the scheduled job "Campaign_Close_Expired" shows its next run at 00:05 on 2026-11-18; a test campaign saved as Closed got the close reason "Manual"; the four new list views appear for the team.
- **Estimated speed-up:** About 2 hours with AI vs. about 5 hours without; estimate, not timed.

**Prompt summary**

```text
Read the acceptance criteria of my Delivery 2 stories and the current metadata in main.
Tell me which stories already work and only need evidence, and generate the metadata
for the rest, Flow first. Do not deploy or push anything: I review and deploy it myself.
```

**What we got**

- An analysis of which stories already worked with the Delivery 1 configuration (MOD-03, MOD-06) and which needed new metadata.
- `Close_Reason__c`, field history on status and dates, a scheduled flow for GES-11, a before-save flow for GES-12, four list views (GES-15, MOD-01, ADM-04) and the system permissions for ADM-01.

**What we verified and corrected**

- **AI error:** the AI added "View Setup" to `Donation_Admin` without "View Roles", which Salesforce requires. The dry run failed on that component only; the permission was added and the second dry run passed 15/15.
- **AI error:** the AI prepared ADM-13 without checking open branches; a teammate had already built it (PR #70). The work was discarded and the teammate's version was used.
- **AI error:** it suggested evidence folders named like another workstream (`27-ges-11`) instead of the `GES-11` style used by workstream C; corrected before saving.
- **AI error:** it first said GES-10 was already met, but the campaign's donations related list only showed the folio; amount, date, payment reference and modality were added to the layout.
- **AI error:** it set a personal address as author of a local commit; it was replaced with the GitHub no-reply address before anything was pushed.
- DON-23 was not built: the sandbox only sends system email, and a failing email action could roll back the donation. Documented in `security.md` §7 and `data-model.md` V-06.

**Better prompt**

```text
Before generating anything, list the open branches and PRs that touch my stories,
and check every permission you add for dependencies before the dry run.
```
