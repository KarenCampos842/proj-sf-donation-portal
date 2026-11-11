# Contribution Log

One table per milestone. Every row must link to evidence (commits, AI log entries, stories, screenshots, or project-tracking records). For planned work, the evidence link documents the assignment and current status; it is not implementation evidence.

Focus of each member (from the backlog split):
- **Rodrigo Colli (@RodrigoPeraza):** payments with Mercado Pago.
- **Karen Elizabeth Campos (@KarenCampos842):** public portal and Salesforce object implementation.
- **Alan Perez Romero (@Alambrep):** internal operation, security testing, and data model.

Stories link to their GitHub issues through the [story-tracking board](story-tracking-board.md). Record hours as estimates unless they were actually measured. Do not invent per-story hours when only an aggregate estimate is available.

## Delivery 1

| Member | Stories / tasks | Evidence | Approx. hours |
|---|---|---|---:|
| Rodrigo Colli | DON-19, DON-20, DON-21, PAY-02, PAY-07, ADM-07; TEC-02 (Mercado Pago testing), TEC-05 (credentials), TEC-08 (professor clarifications) | Implementation: [PR #47](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/47); [Mercado Pago integration](payments-api.md). Acceptance evidence: [PR #55](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/55) (24 screenshots in `docs/evidence/15-don-19` … `44-pay-07`, linked per AC in the "Evidence" section of issues [#15](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/15), [#16](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/16), [#17](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/17), [#37](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/37), [#41](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/41), [#44](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/44)); `Payment_Attempt_Viewer` permission set ([security](security.md) §2); [AI usage log](ai-log.md) | Not recorded |
| Alan Perez Romero | GES-02, GES-03, GES-06, GES-07, GES-09, ADM-03, ADM-05, SEG-01; TEC-01 (org setup), TEC-04 (data model), TEC-06 (demo data) | [Data model](data-model.md); [PR #46](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/46); [PR #48](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/48) (merged); [AI usage log](ai-log.md); [Questions and reports](questions-and-reports.md) (Q-07) | Approx. 8 h (estimate; not timed) |
| Karen Elizabeth Campos | DON-01, DON-02, DON-03, DON-04, DON-08, DON-10, DON-11, DON-12; TEC-03 (Experience Cloud site); implementation of `Fundraising_Campaign__c`, `Payment_Attempt__c` and `Donation__c`; backlog creation and story-tracking board (AI usage log entry #1) | [PR #49](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/49); [PR #50](https://github.com/KarenCampos842/proj-sf-donation-portal/pull/50); [AI usage log](ai-log.md); [Story-tracking board](story-tracking-board.md) | Approx. 16 h (aggregate estimate; not timed) |

## Delivery 2

| Member | Stories / tasks | Evidence | Approx. hours |
|---|---|---|---:|
| Rodrigo Colli | DON-24, PAY-01, PAY-03, PAY-06, ADM-12; bug [#54](https://github.com/KarenCampos842/proj-sf-donation-portal/issues/54) (DON-20 AC4) | [Story-tracking board](story-tracking-board.md) and [GitHub Project 13](https://github.com/users/KarenCampos842/projects/13) (assignment and tracking; implementation evidence pending) | Not recorded |
| Alan Perez Romero | DON-23, GES-10, GES-11, GES-12, GES-15, MOD-01, MOD-03, MOD-06, ADM-01, ADM-04, ADM-13 | [Story-tracking board](story-tracking-board.md) and [GitHub Project 13](https://github.com/users/KarenCampos842/projects/13) (assignment and tracking; implementation evidence pending) | Not recorded |
| Karen Elizabeth Campos | DON-05, DON-09, DON-13, DON-17, DON-18; DON-26 (no fixed date) | [Story-tracking board](story-tracking-board.md) and [GitHub Project 13](https://github.com/users/KarenCampos842/projects/13) (assignment and tracking; implementation evidence pending) | Not recorded |

## Shared tasks

| Task | Owner | Evidence |
|---|---|---|
| `ai-log.md` — each person records their own relevant AI use | All | [AI usage log](ai-log.md) |
| `security.md` | Alan | [Security documentation](security.md) |
| `questions-and-reports.md` | Rodrigo | [Questions and reports](questions-and-reports.md) |
| `contributions.md` | All | This contribution log and the linked [story-tracking board](story-tracking-board.md) |

## Notes

- Karen's eight Delivery 1 Workstream B stories are accepted and closed. This log records their contribution; it does not reopen their acceptance or add new acceptance requirements.
- PR #48 (demo data and `Portal_Developer`, Alan's work) is merged into `main`.
- Workstream A, Delivery 1 (status on 2026-11-11): PAY-07, PAY-02 and ADM-07 are Done with every AC evidenced. DON-19, DON-20 and DON-21 stay In review: DON-19 AC3 (closed campaign) and DON-21 AC4 (anonymous donation) still need a screenshot, and DON-20 AC4 is only partly met. The fix for DON-20 AC4 is planned for Delivery 2 in issue #54.
- Delivery 2 rows document assignments and tracking only. Do not treat those links as proof that the implementation is complete.
- Karen's approximately 16 hours are an aggregate estimate for her Delivery 1 work, not a per-story breakdown. Alan's approximately 8 hours are also an estimate, not a timed measurement. Rodrigo's hours have not been recorded.
