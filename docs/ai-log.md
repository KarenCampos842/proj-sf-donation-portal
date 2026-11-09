# AI Usage Log

Log each relevant AI use at the time it happens, not at the end. Never paste keys, tokens or personal data into an AI tool or into this file.
Per class instructions, the focus is on the prompts that produced the best and the worst results. Keep the short metadata line on every entry so the log also satisfies the written project guide (author, date, tool, story, verification, speed-up).

## Summary

| # | Date | Author | Tool | Story | Type | Result |
|---|---|---|---|---|---|---|
| 1 | 2026-11-08 | Karen Elizabeth Campos | Claude | All (board) | Best | Created 43 GitHub issues from the backlog PDF with one script. |
| 2 | 2026-11-08 | Karen Elizabeth Campos | Claude | All (board) | Worst | AI ERROR: script lost accents and the letter n with tilde in every issue. |
| 3 | 2026-11-08 | Alan Pérez | Claude (Opus 5.5) | Backlog v2 (all) | Best | Review of backlog v2 against the guide and the Q&A session; found an AI error in the DoD |
| 4 | 2026-11-08 | Alan Pérez | Claude (Opus 5.5) | GES-02/03/06/07/09, ADM-03/05, SEG-01 | Worst | First data model draft needed several corrections (voice, language, Apex, a privacy gap) |
| 5 | 2026-11-09 | Karen Elizabeth Campos | ChatGPT + Agentforce (VS Code) | Shared D1 data model: DON-01/02/03/04/08/10/11/12/17/18/19/20/21; GES-02/03/06/07/09; ADM-03/05/07; PAY-02/PAY-07; SEG-01 | Best | Generated, reviewed and deployed the three D1 custom objects: 55 metadata components succeeded in donations-dev. |

---

## Entries

<!-- Add entries below, newest last. -->

### Entry 1 - Backlog PDF to GitHub issues in bulk

- **Date:** 2026-11-08
- **Author:** Karen Elizabeth Campos
- **Tool / model:** Claude
- **Related story:** all 44 stories (RNF-12, board with ID, RF, milestone, story, AC, status and evidence)
- **Result type:** Best prompt

**Prompt used**

```text
I need to create my project stories but I do not want to do it one by one.
[Pasted the format of issue #1: RF covered, Story, Acceptance criteria
(Given / When / Then), Technical tasks (TAC), Evidence.]
The stories must be based on the attached PDF (backlog v2) and these changes:
move DON-09, DON-17, DON-18, GES-11 and ADM-01 to Delivery 2, remove the extra
criteria (360 px, pagination, image validation, change history), remove the 75 %
coverage rule from the Definition of Done. The board needs ID, RF, milestone,
story, AC, status and evidence, and must be linked from the README.
```

**What we got**

A Python script (`scripts/crear_issues.py`) that uses the GitHub CLI to create every story in the format of issue #1, with its milestone, assignee and board entry, and that writes `docs/tablero.md`.

**Why it worked / why it failed**

We gave the exact output format, the source document and the list of cuts, so the AI had nothing to guess. We also asked for the board columns the guide requires.

**What we verified and how**

- Dry run before creating anything: 44 stories, 22 in Delivery 1, 21 in Delivery 2, 1 without date. After running it, 43 issues were created (DON-01 already existed).
- Checked a few issues in GitHub.

**What we corrected**

See entry 2: error in this same output.

**Estimated speed-up**

About 30 min with AI vs about 3 to 4 h creating 44 issues by hand (team to confirm).

---

### Entry 2 - Script that lost accents and special characters

- **Date:** 2026-11-08
- **Author:** Karen Elizabeth Campos
- **Tool / model:** Claude
- **Related story:** all stories (board)
- **Result type:** Worst prompt

**Prompt used**

```text
Same prompt as entry 1. We did not say anything about accents, because we
assumed the AI would handle Spanish text.
```

**What we got**

A script that created the 43 issues with the Spanish accents and the letter n with tilde missing or broken.

**Why it worked / why it failed**

The script passed the issue text to the GitHub CLI using the Windows console encoding instead of UTF-8. It worked in the AI's test environment and failed on our Windows machines. Our prompt did not say which operating system we use.

**What we verified and how**

Opened several issues in GitHub and saw the wrong characters.

**What we corrected**

AI ERROR. The AI forced UTF-8 in the script and added a `--fix` mode that rewrites the title and body of the issues that already exist, without deleting them, so milestones, assignees and board columns stayed as they were. We ran `--fix` and checked again.

**Estimated speed-up**

It cost us about 20 min instead of saving time.

**Better prompt (for worst results)**

```text
I use Windows 11 with PowerShell. The text is in Spanish with accents and special characters; make sure everything is sent as UTF-8 and give me a way to check it before creating the issues.
```

---

### Entry 3 - Backlog v2 review

- **Date:** 2026-11-08
- **Author:** Alan Pérez
- **Tool / model:** Claude (Opus 5.5)
- **Related story:** Backlog v2 (all stories)
- **Result type:** Best prompt

**Prompt used**

```text
Summary: shared the project guide, the Q&A session transcript, backlog v2 and a summary of the team's status, and asked for a review against the guide's minimums and acceptance criteria before splitting the work.
```

**What we got**

A list of risks: Delivery 1 scope too large (27 stories, ~130 acceptance criteria), no shared org decided yet, and a Definition of Done requirement that was not in the guide. It also proposed which stories to move to Delivery 2.

**Why it worked / why it failed**

The prompt included all the sources (guide, session, backlog), so the AI could compare them against each other instead of answering from general knowledge.

**What we verified and how**

- Checked in Salesforce's documentation that the 75% code coverage requirement applies to production deployments, not to sandbox or Developer Edition orgs.
- Checked in Mercado Pago's documentation that testing Checkout Pro requires test seller and buyer accounts.
- Checked the guide: it does not require a coverage percentage.

**What we corrected**

**AI ERROR** (in backlog v2, which was also produced with AI): the DoD said 75% coverage was required "to deploy to Developer Edition". Detected by checking the official documentation. The 75% target was removed from the DoD; tests are still required.

The assistant also assumed we were on Developer Edition and warned about its license limits; that did not apply once we confirmed the team uses the program's sandbox.

**Estimated speed-up**

About 1 h with AI vs about 3 h without.

---

### Entry 4 - Data model first draft

- **Date:** 2026-11-08
- **Author:** Alan Pérez
- **Tool / model:** Claude (Opus 5.5)
- **Related story:** GES-02, GES-03, GES-06, GES-07, GES-09, ADM-03, ADM-05, SEG-01
- **Result type:** Worst prompt

**Prompt used**

```text
Summary: asked for the data model (objects, fields, API names, access) for workstream C, based on backlog v2 and the client's answers on Slack.
```

**What we got**

A complete first draft (objects, fields, formulas, validation rules, permissions, personal data classification). It needed several rounds of corrections before it was ready: final version in `docs/data-model.md`.

**Why it worked / why it failed**

The prompt did not say who the document was for, which language the repo uses, or that we prefer declarative tools over Apex. The AI filled those gaps with wrong assumptions.

**What we verified and how**

- Checked in Salesforce's documentation that criteria-based sharing rules cannot use formula fields, and how the master-detail sharing setting works.
- Tested the RFC validation pattern against the examples in backlog v2 (valid and invalid cases).
- Checked that every field used in formulas and rules exists in the document.

**What we corrected**

- **AI ERROR:** it proposed normalizing the RFC "in the code that creates the record". I asked why we would use Apex if it should be avoided; the fix is a before-save flow, which runs before validation rules.
- **AI ERROR:** giving the moderator permission to change visibility allowed turning an anonymous donation into a public one, against RF-D2. Found when reviewing the draft; fixed with the `Anonymous_Cannot_Become_Public` validation rule.
- API names were in Spanish while the repo is in English; changed to English API names with Spanish labels.
- The text was written as personal notes ("my stories", "useful for the oral defense"); rewritten as a project document for the team and reviewers.

**Estimated speed-up**

About 3 h with AI vs about 8 h without.

**Better prompt (for worst results)**

```text
Write docs/data-model.md for a team repo that is read by teammates and graders. Use English API names and Spanish labels. Prefer declarative tools (Flow, validation rules) over Apex and say where Apex is unavoidable. Include design decisions with the alternatives considered.
```

---

### Entry 5 - D1 data model generation, review and deployment

- **Date:** 2026-11-09
- **Author:** Karen Elizabeth Campos
- **Tool / model:** ChatGPT + Agentforce (VS Code)
- **Related story:** Shared D1 data-model dependencies: DON-01/02/03/04/08/10/11/12/17/18/19/20/21, GES-02/03/06/07/09, ADM-03/05/07, PAY-02/PAY-07 and SEG-01. The objects support these stories; deploying the data model does not by itself complete their UI, automation, payment or security behavior.
- **Result type:** Best prompt

**Prompt used**

```text
Inspect the existing Salesforce DX project and the connected sandbox before making changes.
Use docs/data-model.md as the source of truth and implement only Delivery 1.
Recover the existing Fundraising_Campaign__c metadata from the org instead of
creating a duplicate. Create Payment_Attempt__c and Donation__c if they do not
exist. Generate the SFDX object, field, relationship, formula, roll-up summary
and validation-rule metadata in force-app/main/default/objects/. Preserve
existing metadata, use English API names and Spanish labels, validate the XML
and run a deployment check only. Do not create records or deploy without
explicit authorization.
```

**What we got**

The three D1 custom objects were represented in the repository: `Fundraising_Campaign__c` was retrieved and completed, while `Payment_Attempt__c` and `Donation__c` were created. The metadata included 42 custom fields, the Lookup and Master-Detail relationships, two roll-up summaries, formulas and nine validation rules. The retrieved campaign list view was preserved. The documentation was also aligned with the implemented D1 model.

After review and explicit authorization, the metadata was deployed to the `donations-dev` sandbox. Salesforce reported `Succeeded`: 55 of 55 components, zero component failures and zero test errors. The objects and their fields were checked in the org after deployment. No records, production changes, commits or pushes were made.

**Why it worked / why it failed**

The prompt identified the project documentation as the source of truth, separated D1 from D2, specified the existing campaign object and required Agentforce to inspect and retrieve it rather than create a duplicate. It also required a review and dry-run before deployment. Iterative review was still necessary to correct field-history settings, align help text with the documentation and resolve a discrepancy about `Public_Name__c` history.

**What we verified and how**

- Validated the 55 metadata components with a dry-run against `donations-dev`: `Succeeded`, 55/55 components and zero errors.
- After explicit authorization, deployed to `donations-dev`: Salesforce confirmed `Succeeded`, 55/55 components, zero failures and zero test errors. Deployment ID: `0AfVC00000PBFdF0AX`.
- Listed metadata after deployment and confirmed that all three objects existed with 13, 13 and 16 custom fields respectively, and that the nine validation rules were present.
- Confirmed that the repository metadata and the deployed object/field definitions were consistent.
- Formula and roll-up behavior was not tested with records during this task.

**What we corrected**

- Retrieved `Fundraising_Campaign__c` from the org and updated it instead of creating a duplicate; created the other two D1 objects.
- Confirmed `enableHistory=true` and `trackHistory=true` for `Goal__c`; enabled object and field history for `Donation__c.Public_Name__c` in accordance with the explicit field definition in `docs/data-model.md`.
- Set and checked the external sharing model for campaigns, the Lookup and Master-Detail settings, and the roll-up summary references.
- Corrected help text and descriptions that implied automations not yet implemented, such as RFC normalization and scheduled deletion of old payment attempts.
- Updated `docs/data-model.md` and `docs/ai-context/PROJECT_CONTEXT.md` to align their descriptions with the current D1 model and distinguish D1 field history from D2 moderation behavior.
- Kept D2 elements and unrelated pre-existing Salesforce objects out of this deployment.

**Estimated speed-up**

Approximately 2–3 h with AI vs about 5–6 h without AI (conservative estimate for metadata creation, review, validation and deployment; not timed).
