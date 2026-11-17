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
| 14 | 2026-11-16 | Karen Elizabeth Campos | Claude Code, VS Code | DON-13 (privacy notice with invoice) | Best | Server check in the controller and the flow, server-side timestamp and copy to the donation, with Jest and Apex tests; check-only validation passed (115/115 tests). Time not measured. |

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


### Entry 14 — Privacy notice when an invoice is requested (DON-13)

- **Date:** 2026-11-16
- **Author:** Karen Elizabeth Campos
- **Tool / model:** Claude Code, VS Code
- **Related stories:** DON-13 (#12)
- **Result type:** Best prompt
- **Verification:** Jest (all suites) and a check-only deployment against `donations-dev` of the four fields, the two flows, the Apex classes and the form (115/115 Apex tests in the selected classes, nothing saved). No real deployment, commit or push.
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
- The owner of the payment flows (Workstream A) still has to review the changes to `Payment_Attempt_Create`, `Donation_Register` and `DonationPaymentController`. The permission sets do not give anyone read access to the four new fields yet.
