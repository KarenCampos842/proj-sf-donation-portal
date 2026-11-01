# proj-sf-donation-portal

A public, login-free donation portal built on **Salesforce Developer Edition** with **Stripe (test mode)** to help SF Vibe Lab students fund their trip to Mexico Dreamin 2026. Staff and treasury track everything inside Salesforce.

> **Academic project (SF Vibe Lab, UADY x Salesforce, Merida).** All money is simulated, Stripe runs in test mode only, all donor data is fictitious, and nothing reaches production.

## Status

| Milestone | Due | Tag | Progress | How it is calculated |
|---|---|---|---|---|
| Delivery 1 | 2026-11-10 | `entrega-1` | _TBD_ | fulfilled Delivery 1 stories / total Delivery 1 stories |
| Delivery 2 | 2026-11-17 | `entrega-2` | _TBD_ | fulfilled stories (all) / total stories |

A story is **fulfilled** only when *all* of its acceptance criteria are demonstrated with evidence (demo, video or screenshot) without breaking any minimum (M1-M3).

## Quick links

- Backlog board: _add GitHub Projects URL here_
- Public site: _add Experience Cloud URL here_
- Demo video (Delivery 1): _add URL here_
- Security and personal data: [`docs/security.md`](docs/security.md)

## Repository structure

```
.
├── README.md
├── .gitignore                  # blocks secrets, env files, local SF config
├── .githooks/pre-commit        # scans staged files for Stripe keys
├── .github/                    # issue templates + PR template
├── docs/
│   ├── ai-log.md               # AI usage log (best / worst prompts)
│   ├── ai-context/             # context files given to the AI
│   ├── security.md             # visitor security test + personal data classification
│   ├── contributions.md        # per-member contribution log
│   ├── questions-and-reports.md# questions to client/advisor and problem reports
│   ├── backlog/                # backlog notes / exports (board is the source of truth)
│   └── evidence/               # screenshots (NO secrets, NO real personal data)
├── force-app/                  # Salesforce metadata (retrieved with SF CLI)
├── scripts/
│   └── setup_project.sh        # creates labels and the project board with gh CLI
└── sfdx-project.json           # (created by `sf project generate`)
```

## Getting started

```bash
# 1. Enable the secret-scanning hook (once per clone)
git config core.hooksPath .githooks

# 2. Create the Salesforce project files if they do not exist yet
sf project generate --name tmp && mv tmp/sfdx-project.json . && rm -rf tmp

# 3. Authorize your Developer Edition org
sf org login web --alias donations-dev

# 4. Back up metadata (do this at least weekly and before each delivery)
sf project retrieve start --target-org donations-dev
```

## Security rules (minimums M1-M3)

1. Stripe **test mode** and test cards only. Never activate the Stripe account.
2. The guest user gets least privilege only: read campaigns, create donations.
3. **No secrets in the repo, ever.** Stripe keys live in Salesforce Named/External Credentials or protected settings, never in code, metadata, screenshots, AI prompts or commits. If a key leaks: rotate it in Stripe the same day and tell the professor.

## Team

| Member | Role | GitHub |
|---|---|---|
| Rodrigo Colli | _TBD_ | _@user_ |
| Alan Perez Romero | _TBD_ | _@user_ |
| Karen Elizabeth Campos | _TBD_ | _@user_ |
