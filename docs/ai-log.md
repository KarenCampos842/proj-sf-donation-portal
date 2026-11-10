# AI Usage Log

Record relevant AI use when it happens. Never paste API keys, tokens, credentials, payment-card details or personal donor data into an AI tool or this file.

This log keeps only the most useful **best-prompt** and **worst-result** examples. Each entry includes author, date, tool, related stories, verification and estimated time saved (or lost), as required by the project guide. Estimates are not measured unless explicitly stated.

## Summary

| # | Date | Author | Tool / model | Related story | Result | Verification / speed-up |
|---|---|---|---|---|---|---|
| 1 | 2026-11-08 | Karen Elizabeth Campos | Claude | All 44 backlog stories | Best | 43 issues created in bulk; dry run and sample issues checked. ~30 min vs. 3–4 h, team estimate. |
| 2 | 2026-11-08 | Karen Elizabeth Campos | Claude | All backlog stories | Worst | Windows encoding broke Spanish accents; corrected with UTF-8 and a safe `--fix` mode. ~20 min lost. |
| 3 | 2026-11-09 | Karen Elizabeth Campos | ChatGPT + Agentforce (VS Code) | Shared Delivery 1 data model | Best | 55 metadata components deployed successfully; org objects/fields checked. ~2–3 h vs. 5–6 h, estimate. |
| 4 | 2026-11-09 | Rodrigo Colli | Claude Code (Opus 5.5) | PAY-07, PAY-02, ADM-07, DON-19/20/21 | Best | Payment flows and Mercado Pago callout actions delivered in PR #47; check-only deployments and tests passed. ~6 h vs. 16–20 h, estimate. |
| 5 | 2026-11-09 | Rodrigo Colli | Claude Code (Opus 5.5) | PAY-07, PAY-02 | Worst | AI proposed Apex against the declarative-first rule and generated rejected Flow metadata; fixed after check-only validation. ~30 min lost. |
| 6 | 2026-11-09 | Karen Elizabeth Campos | ChatGPT + Agentforce (VS Code) | Shared D1 data model: DON-01/02/03/04/08/10/11/12/17/18/19/20/21; GES-02/03/06/07/09; ADM-03/05/07; PAY-02/PAY-07; SEG-01 | Best | Generated and incorporated metadata for `Fundraising_Campaign__c`, `Payment_Attempt__c` and `Donation__c`; Salesforce reported 55/55 components deployed successfully. |
| 7 | 2026-11-10 | Karen Elizabeth Campos | ChatGPT + Agentforce (VS Code) | DON-01/02/03/04/10/11; campaign data and Guest catalog | Best | Five existing campaigns updated, three visible `[PRUEBA]` campaigns moved to Draft, three seeded recognition records made Anonymous; Guest catalog and direct URLs checked. Time not measured. |

---

## Selected entries

### Entry 1 — Bulk creation of backlog issues from the PDF

- **Date:** 2026-11-08
- **Author:** Karen Elizabeth Campos
- **Tool / model:** Claude
- **Related stories:** All 44 stories; RNF-12 and GitHub board structure
- **Result type:** Best prompt
- **Verification:** Dry run counted 44 stories (22 Delivery 1, 21 Delivery 2, 1 unscheduled). 43 issues were created because DON-01 already existed; a sample of issues was checked in GitHub.
- **Estimated speed-up:** About 30 minutes with AI vs. 3–4 hours manually; team estimate, not timed.

**Prompt summary**

```text
Create the project stories in bulk from backlog v2, using the exact structure
of issue #1: RF covered, Story, Given/When/Then acceptance criteria, technical
tasks and evidence. Apply the agreed Delivery 1 / Delivery 2 scope changes,
remove the excluded extra criteria, preserve Spanish text, and include the
required board fields: ID, RF, milestone, story, AC, status and evidence.
```

**Result and lesson**

The AI produced `scripts/crear_issues.py` to create issues through GitHub CLI rather than one by one. The exact issue format, source backlog and explicit scope changes made the task repeatable. The first output still had the encoding problem described in Entry 2.

### Entry 2 — Windows encoding error in generated issue content

- **Date:** 2026-11-08
- **Author:** Karen Elizabeth Campos
- **Tool / model:** Claude
- **Related stories:** All backlog stories
- **Result type:** Worst result
- **Verification:** Several GitHub issues were opened and showed missing or corrupted Spanish accents and `ñ` characters.
- **Estimated time lost:** About 20 minutes.

**Prompt used**

```text
Same request as Entry 1. The operating system and encoding requirements
were not stated.
```

**What went wrong**

The generated script passed Spanish issue text through the Windows console encoding instead of UTF-8. It worked in the AI environment but corrupted text on the team's Windows machines.

**Correction and lesson**

The script was changed to force UTF-8 and provide a `--fix` mode that rewrites existing issue titles and bodies without deleting issues or changing milestones, assignees or board fields.

**Better prompt**

```text
We use Windows 11 and PowerShell. The issue content is Spanish and includes
accented characters and ñ. Make every file and GitHub CLI input UTF-8, and
provide a dry-run or preview so we can inspect the output before creating or
rewriting issues.
```

### Entry 3 — Delivery 1 data model: inspect, generate, validate and deploy

- **Date:** 2026-11-09
- **Author:** Karen Elizabeth Campos
- **Tool / model:** ChatGPT + Agentforce (VS Code)
- **Related stories:** Shared D1 dependencies for DON-01/02/03/04/08/10/11/12/17/18/19/20/21, GES-02/03/06/07/09, ADM-03/05/07, PAY-02/PAY-07 and SEG-01
- **Result type:** Best prompt
- **Verification:** Salesforce reported 55/55 metadata components deployed successfully, with zero component failures and zero test errors. The three objects, fields and validation rules were checked in the org. Formula and roll-up behavior with records was not part of that deployment check.
- **Estimated speed-up:** Approximately 2–3 hours vs. 5–6 hours; conservative estimate, not timed.

**Prompt used (key requirements, condensed from the full prompt)**

```text
Act as a Salesforce architect and Salesforce DX developer. Work in the
existing VS Code project and implement only the Delivery 1 metadata for:
Fundraising_Campaign__c, Payment_Attempt__c and Donation__c.

Before editing, inspect the repository and connected Salesforce org. Read
these project documents first:
- docs/data-model.md (source of truth for API names, labels, field types,
  relationships, formulas, validation rules and Delivery 1 scope)
- docs/ai-context/PROJECT_CONTEXT.md
- docs/backlog/README.md

Initial situation to verify, not blindly assume:
- Fundraising_Campaign__c exists in the org but may have no records; its
  metadata may not yet be present locally.
- Payment_Attempt__c and Donation__c must be created only if they do not
  already exist.
- Distinguish object metadata from Salesforce records. This task creates
  metadata only: do not create campaign or donation records.

Implementation requirements:
1. Retrieve Fundraising_Campaign__c from the org, compare it with the data
   model and complete only missing or incorrect metadata; do not duplicate
   the object, fields or valid settings.
2. Create or retrieve Payment_Attempt__c with its Lookup to the campaign,
   auto-number folio, documented fields, picklists and D1 validation rules.
3. Create or retrieve Donation__c with its Master-Detail relationship to
   the campaign, read-only relationship behavior, documented fields,
   formulas, unique External ID provider payment field and Confirmed status.
4. Implement the campaign roll-up SUM and COUNT fields, progress formula,
   donation-eligibility formula, public-visibility formula and documented
   validation rules exactly as specified in docs/data-model.md.
5. Preserve English API names, Spanish labels, exact field lengths,
   precision, scale, defaults, restricted picklist values and history
   settings. Do not add undocumented rules or constraints.
6. Do not implement Delivery 2 fields or features (including privacy-notice
   fields, receipt flags, rejected notices, amount custom metadata or the
   MOD-03 / RF-D2 moderation rules).
7. Do not add unrelated Flows, Apex, LWCs, permission sets or sharing rules.

Generate standard Salesforce DX metadata under
force-app/main/default/objects/. Validate XML, filenames, references,
relationships, formulas, roll-ups and validation rules. Do not deploy or
create records. Do not commit or push. Report initial state, objects,
files, relationships, formulas, validation rules, unresolved decisions
(including SAT tax-regime verification V-05) and validation results.
Never claim an object or setting was retrieved, created or verified unless
it was actually checked.
```

**Result and lesson**

The existing `Fundraising_Campaign__c` metadata was retrieved and completed
rather than duplicated; `Payment_Attempt__c` and `Donation__c` metadata were
created for Delivery 1. The resulting model included the three custom
objects, 42 custom fields, Lookup and Master-Detail relationships, two
roll-up summaries, formulas and nine validation rules. After review and
separate explicit authorization, Salesforce reported a successful deployment
of 55/55 metadata components with zero component failures and zero test
errors. No campaign or donation records were created by this metadata task.

The prompt was especially valuable because it separated metadata from data
records, established `docs/data-model.md` as the authority, required retrieval
of the pre-existing campaign object, prevented duplicates, and explicitly
excluded Delivery 2 scope. The main lesson was to inspect both the org and
repository before generation and keep deployment as a separate authorized
step. Iterative review was still needed to align history settings and help
text with the documented model.

### Entry 4 — Mercado Pago payment flows with Flow-first implementation

- **Date:** 2026-11-09
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5), VS Code
- **Related stories:** PAY-07, PAY-02, ADM-07, DON-19, DON-20 and DON-21
- **Result type:** Best prompt
- **Verification:** Check-only deployments and tests were run before deployment; Code Analyzer reported no severity 1–3 findings. The Mercado Pago test account `/users/me` endpoint identified a `test_user`, a preference was created and a fake payment lookup returned NotFound. Delivered in PR #47.
- **Estimated speed-up:** About 6 hours vs. 16–20 hours; estimate, not timed.

**Prompt / decision summary**

```text
Use the class Sandbox donations-dev and compare the existing D1 objects with
docs/data-model.md before implementing. Use Flow wherever possible and Apex
only where Flow cannot perform the required callout. For Checkout Pro, create
the preference server-side and let Mercado Pago capture card data. Keep all
credentials in Named/External Credentials, validate with check-only deploys
and tests, and do not commit or push without authorization.
```

**Result and lesson**

Five payment-related flows, the `Rejected_Notice__c` object, two invocable Apex callout actions with `HttpCalloutMock` tests, and the ADM-07 layout/search were delivered. Flow-first instructions, org inspection and validation gates reduced rework and protected credentials.

### Entry 5 — Wrong Apex recommendation and rejected Flow metadata

- **Date:** 2026-11-09
- **Author:** Rodrigo Colli
- **Tool / model:** Claude Code (Opus 5.5)
- **Related stories:** PAY-07 and PAY-02
- **Result type:** Worst result
- **Verification:** Check-only deployment exposed the invalid Flow metadata before it was deployed to the Sandbox.
- **Estimated time lost:** About 30 minutes.

**Initial prompt summary**

```text
“Start with the card” (PAY-07), without restating the project's Flow-first
rule, the org context or the required payment architecture.
```

**What went wrong**

The assistant first proposed Apex for a task that should be declarative, then produced Flow metadata with an unsupported element placement and a rollback setting that the flow type did not allow. It also made incorrect assumptions about the team's Sandbox and the scheduled cleanup time.

**Correction and lesson**

The implementation was changed to Flow with only the necessary invocable Apex for callouts. Every Flow was checked with a dry run before deployment.

**Better prompt**

```text
Implement PAY-07 in donations-dev using docs/data-model.md. Use Flow first
and Apex only where Flow cannot meet a requirement; justify each Apex class.
Revalidate campaign, amount, visibility and tax data on the server. The Guest
user must have no Payment_Attempt__c permissions. Check every metadata change
with a dry-run and tests before deployment. Do not commit to main.
```

### Entry 6 — Salesforce custom-object metadata implementation for Delivery 1

- **Date:** 2026-11-09
- **Author:** Karen Elizabeth Campos
- **Tool / model:** ChatGPT + Agentforce (VS Code)
- **Related stories:** Shared D1 data-model dependencies for DON-01/02/03/04/08/10/11/12/17/18/19/20/21, GES-02/03/06/07/09, ADM-03/05/07, PAY-02/PAY-07 and SEG-01
- **Result type:** Best prompt
- **Verification:** The metadata deployment to `donations-dev` reported `Succeeded`: 55 of 55 components, zero component failures and zero test errors. The objects, fields and validation rules were checked in the org. This metadata task did not create campaign or donation records; formula and roll-up behavior with records was not verified as part of the deployment.
- **Estimated speed-up:** Approximately 2–3 hours with AI vs. 5–6 hours without AI; conservative estimate, not timed.

**Prompt used (structured summary of the detailed implementation prompt)**

```text
Act as an experienced Salesforce architect and Salesforce DX (SFDX)
developer. Work directly in the existing VS Code project to implement only
the Delivery 1 metadata for these three custom objects:

1. Fundraising_Campaign__c — Campaign.
2. Payment_Attempt__c — Payment Attempt (PAY-07).
3. Donation__c — Donation.

Before changing files, inspect the repository and the connected Salesforce
organization. Read these documents first:
- docs/data-model.md (authoritative source for API names, labels, field
  types, relationships, formulas, validation rules and D1 scope).
- docs/ai-context/PROJECT_CONTEXT.md.
- docs/backlog/README.md.

Do not assume the initial state is still true: verify it. At the time of the
task, Fundraising_Campaign__c existed in the org but its metadata was not yet
in the local repository; Payment_Attempt__c and Donation__c had to be created
only if absent. Distinguish object metadata from Salesforce records: this
task creates metadata only, not demo campaign or donation records.

Implementation:
1. Retrieve the existing Fundraising_Campaign__c metadata. Compare it with
   docs/data-model.md and complete only missing or incorrect items. Never
   create a duplicate object or field and do not remove valid configuration.
2. Create or retrieve Payment_Attempt__c, including its auto-number folio,
   documented fields, Lookup to Fundraising_Campaign__c, picklists and D1
   validation rules.
3. Create or retrieve Donation__c, including its auto-number folio,
   Master-Detail relationship to Fundraising_Campaign__c, read-only
   relationship behavior, documented fields and formulas.
4. Implement the campaign roll-up summaries (SUM of confirmed donation
   amounts and COUNT of related donations), progress percentage,
   donation-eligibility and public-visibility formulas, and all D1
   validation rules exactly as documented.
5. Preserve exact API names, Spanish labels, field types and lengths,
   currency precision/scale, picklist API values and labels, defaults,
   restricted-picklist settings, unique/External ID configuration and
   Goal__c field history. Do not make Description__c required at field
   level; its requirement is enforced when activating a campaign.
6. Preserve the documented 19 tax-regime values and their eligibility
   reference for physical/legal persons. Do not invent extra filtering
   behavior in object metadata. Report SAT Anexo 20 verification V-05 as
   pending, as documented.
7. Exclude Delivery 2 features, including Close_Reason__c, privacy-notice
   fields, Confirmation_Source__c, Receipt_Sent__c, Rejected_Notice__c,
   Donation_Amount_Setting__mdt and additional moderation rules for MOD-03
   / RF-D2. Also do not add unrelated permission sets, sharing rules,
   list views, flows, Apex classes, LWCs, test records or automations.

Generate standard Salesforce DX metadata under
force-app/main/default/objects/. Validate XML well-formedness, filenames,
object and field references, relationship types, formula compatibility,
roll-up relationships, validation conditions and messages. Adapt to valid
metadata already present; do not overwrite files without reviewing them.

Do not modify sfdx-project.json or API version without a documented reason.
Do not modify unrelated files. Do not create Salesforce records, deploy,
apply org changes, commit or push. If org access is unavailable, report the
blocker; never simulate a retrieve or claim an unverified setting.

Final report must cover: initial org/repository state; each object's API
name, labels, name field, sharing model and deployment status; generated or
updated paths; Lookup and Master-Detail relationships; formulas and
validation rules; unresolved documentation items (especially V-05); XML
and structural validation; and whether the metadata is ready for a later
authorized deployment check.
```

**Result and lesson**

The existing `Fundraising_Campaign__c` metadata was retrieved and completed rather than duplicated. `Payment_Attempt__c` and `Donation__c` were added according to the D1 data model. The implementation covered the three objects, 42 custom fields, Lookup and Master-Detail relationships, two roll-up summaries, formulas and nine validation rules. After review and separate explicit authorization, Salesforce reported a successful deployment of 55/55 components with zero failures and zero test errors.

The prompt worked because it set `docs/data-model.md` as the source of truth, required inspection before generation, clearly separated object metadata from records, protected existing metadata, made the D1/D2 boundary explicit and separated validation from deployment authorization. The remaining lesson is to report unverified runtime behavior separately: a successful metadata deployment does not by itself prove formula and roll-up results with actual records.

---

### Entry 7 — Existing campaign records and public Guest catalog cleanup

- **Date:** 2026-11-10
- **Author:** Karen Elizabeth Campos
- **Tool / model:** ChatGPT + Agentforce (VS Code)
- **Related stories:** DON-01, DON-02, DON-03, DON-04, DON-10 and DON-11
- **Result type:** Best prompt
- **Verification:** The five existing campaign records were updated by ID without duplication; three visible `[PRUEBA]` records were changed to Draft; three seeded public-recognition donations were changed to Anonymous. Agentforce reported a Guest-browser check of 32/32 at 1280 px and 360 px, with the catalog showing four intended cards and Draft records unavailable by direct URL. Campaign totals and donation relationships were rechecked.
- **Estimated speed-up:** Approximately 1–2 h with AI vs. 3–4 h without AI (rough estimate; not timed).

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

**Result and lesson**

The five intended portal campaigns retained their Salesforce IDs and donation
relationships while their public names/descriptions were updated. The three
test campaigns that had appeared publicly were set to Draft; their records
and donations were preserved. Three seeded recognition entries were
anonymized, and the public totals continued to display correctly. The key
safeguard was to inspect existing records and update by ID rather than reload
demo JSON. The four recently uploaded campaign images still require
confirmation of their public distributions and field updates before they can
be marked complete.
