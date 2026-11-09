# proj-sf-donation-portal

A public, login-free donation portal built on **Salesforce Developer Edition** with **Mercado Pago (test mode, Checkout Pro)** to help SF Vibe Lab students fund their trip to Mexico Dreamin 2026. Staff and treasury track everything inside Salesforce.

> **Academic project (SF Vibe Lab, UADY x Salesforce, Merida).** All money is simulated, Mercado Pago runs in test mode only, all donor data is fictitious, and nothing reaches production.

## Status

| Milestone | Due | Tag | Progress | How it is calculated |
|---|---|---|---|---|
| Delivery 1 | 2026-11-10 | `entrega-1` | _0 / 22 (update before the delivery)_ | fulfilled Delivery 1 stories / total Delivery 1 stories |
| Delivery 2 | 2026-11-17 | `entrega-2` | _TBD_ | fulfilled stories (all) / total stories |

A story is **fulfilled** only when *all* of its acceptance criteria are demonstrated with evidence (demo, video or screenshot) without breaking any minimum (M1-M3).

The backlog has 44 stories: 22 in Delivery 1, 21 in Delivery 2 and 1 without a fixed date (DON-26).

## Quick links

- Backlog board: [GitHub Projects](https://github.com/users/KarenCampos842/projects/13)
- Story table (ID, RF, milestone, story, AC, status, evidence): [`docs/tablero.md`](docs/tablero.md)
- Public site: _add Experience Cloud URL here_
- Demo video (Delivery 1): _add URL here_
- Security and personal data: [`docs/security.md`](docs/security.md)
- AI usage log: [`docs/ai-log.md`](docs/ai-log.md)
- Questions to the client and problem reports: [`docs/questions-and-reports.md`](docs/questions-and-reports.md)
- Contributions: [`docs/contributions.md`](docs/contributions.md)

## Repository structure

```
.
├── README.md
├── .gitignore                  # blocks secrets, env files, local SF config
├── .githooks/pre-commit        # scans staged files for payment-provider keys
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
│   ├── setup_project.sh        # creates labels and the project board with gh CLI
│   └── crear_issues.py         # creates the backlog stories as GitHub issues
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

1. Mercado Pago **test mode** and test accounts and cards only. Never use a real account or activate production credentials.
2. The guest user gets least privilege only: it reads public campaign data and has no permission on donations or payment attempts. Server code creates them after validating the payment with the provider.
3. **No secrets in the repo, ever.** The Mercado Pago access token and the webhook secret live in Salesforce Named/External Credentials or protected settings, never in code, metadata, screenshots, AI prompts or commits. If a key leaks: rotate it the same day and tell the professor.

## Team

| Member | Role | GitHub |
|---|---|---|
| Rodrigo Colli | Payments with Mercado Pago | [@RodrigoPeraza](https://github.com/RodrigoPeraza) |
| Alan Perez Romero | Internal operation and security test | [@Alambrep](https://github.com/Alambrep) |
| Karen Elizabeth Campos | Public portal | [@KarenCampos842](https://github.com/KarenCampos842) |
