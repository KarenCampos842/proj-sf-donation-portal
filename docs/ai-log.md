# AI Usage Log

> Log each relevant AI use **at the time it happens**, not at the end. Never paste keys, tokens or personal data into an AI tool or into this file.
>
> Per class instructions, the focus is on the prompts that produced the **best** and the **worst** results. Keep the short metadata line on every entry so the log also satisfies the written project guide (author, date, tool, story, verification, speed-up).

## Summary

| # | Date | Author | Tool | Story | Type | Result |
|---|---|---|---|---|---|---|
| 1 | 2026-11-08 | Alan Pérez | Claude (Opus 5.5) | Backlog v2 (all) | Best | Review of backlog v2 against the guide and the Q&A session; found an AI error in the DoD |
| 2 | 2026-11-08 | Alan Pérez | Claude (Opus 5.5) | GES-02/03/06/07/09, ADM-03/05, SEG-01 | Worst | First data model draft needed several corrections (voice, language, Apex, a privacy gap) |

## Entry template (copy for each new entry)

### Entry N - short title

- **Date:** YYYY-MM-DD
- **Author:** _name_
- **Tool / model:** _e.g. Claude Sonnet_
- **Related story:** _US-xx (RF-xxx)_
- **Result type:** Best prompt / Worst prompt

**Prompt used**

```text
Paste the prompt (or a summary + link). No secrets, no personal data.
```

**What we got**

_Short description of the output._

**Why it worked / why it failed**

_What made the prompt effective (context, constraints, examples) or what went wrong (vague request, missing context, hallucinated feature...)._

**What we verified and how**

_e.g. "Checked the Apex against the official Salesforce docs, ran the test class, tested in the org with a guest user."_

**What we corrected**

_Changes made to the AI output. If the AI made a mistake, write **AI ERROR** here and describe how it was detected._

**Estimated speed-up**

_e.g. "About 2 h with AI vs about 6 h without."_

**Better prompt (for worst results)**

_How we would rewrite the prompt next time._

---

## Entries

<!-- Add entries below, newest last. -->

### Entry 1 - Backlog v2 review

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

### Entry 2 - Data model first draft

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
