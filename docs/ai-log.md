AI Usage Log
Log each relevant AI use at the time it happens, not at the end. Never paste keys, tokens or personal data into an AI tool or into this file.
Per class instructions, the focus is on the prompts that produced the best and the worst results. Keep the short metadata line on every entry so the log also satisfies the written project guide (author, date, tool, story, verification, speed-up).

Summary
| # | Date | Author | Tool | Story | Type | Result |
|---|---|---|---|---|---|---|
| 1 | 2026-11-08 | Karen Elizabeth Campos | Claude | All (board) | Best | Created 43 GitHub issues from the backlog PDF with one script. |
| 2 | 2026-11-08 | Karen Elizabeth Campos | Claude | All (board) | Worst | AI ERROR: script lost accents and the letter n with tilde in every issue. |

Complete the author, tool and date if they differ from what is written here.

Entry 1 - Backlog PDF to GitHub issues in bulk
- Date: 2026-11-08
- Author: Karen Elizabeth Campos
- Tool / model: Claude
- Related story: all 44 stories (RNF-12, board with ID, RF, milestone, story, AC, status and evidence)
- Result type: Best prompt

Prompt used
I need to create my project stories but I do not want to do it one by one.
[Pasted the format of issue #1: RF covered, Story, Acceptance criteria
(Given / When / Then), Technical tasks (TAC), Evidence.]
The stories must be based on the attached PDF (backlog v2) and these changes:
move DON-09, DON-17, DON-18, GES-11 and ADM-01 to Delivery 2, remove the extra
criteria (360 px, pagination, image validation, change history), remove the 75 %
coverage rule from the Definition of Done. The board needs ID, RF, milestone,
story, AC, status and evidence, and must be linked from the README.

What we got
A Python script (scripts/crear_issues.py) that uses the GitHub CLI to create every story in the format of issue #1, with its milestone, assignee and board entry, and that writes docs/tablero.md.

Why it worked / why it failed
We gave the exact output format, the source document and the list of cuts, so the AI had nothing to guess. We also asked for the board columns the guide requires.

What we verified and how
Dry run before creating anything: 44 stories, 22 in Delivery 1, 21 in Delivery 2, 1 without date. After running it, 43 issues were created (DON-01 already existed). Checked a few issues in GitHub.

What we corrected
See entry 2: error in this same output.

Estimated speed-up
About 30 min with AI vs about 3 to 4 h creating 44 issues by hand (team to confirm).

Entry 2 - Script that lost accents and special characters
- Date: 2026-11-08
- Author: Karen Elizabeth Campos
- Tool / model: Claude
- Related story: all stories (board)
- Result type: Worst prompt

Prompt used
Same prompt as entry 1. We did not say anything about accents, because we
assumed the AI would handle Spanish text.

What we got
A script that created the 43 issues with the Spanish accents and the letter n with tilde missing or broken.

Why it worked / why it failed
The script passed the issue text to the GitHub CLI using the Windows console encoding instead of UTF-8. It worked in the AI's test environment and failed on our Windows machines. Our prompt did not say which operating system we use.

What we verified and how
Opened several issues in GitHub and saw the wrong characters.

What we corrected
AI ERROR. The AI forced UTF-8 in the script and added a --fix mode that rewrites the title and body of the issues that already exist, without deleting them, so milestones, assignees and board columns stayed as they were. We ran --fix and checked again.

Estimated speed-up
It cost us about 20 min instead of saving time.

Better prompt (for worst results)
"I use Windows 11 with PowerShell. The text is in Spanish with accents and special characters; make sure everything is sent as UTF-8 and give me a way to check it before creating the issues."