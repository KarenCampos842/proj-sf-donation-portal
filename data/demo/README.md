# Demo data (fictitious)

Fictitious campaigns and confirmed donations for demos and screenshots. **No real people, no real payments.**

- 5 campaigns: the always-open general campaign, two active, one paused and one draft (the draft has no description on purpose, to demo `Activation_Requires_Description`).
- 6 confirmed donations: public, anonymous, with invoice (company and individual) and anonymous with invoice.
- Emails use the reserved `example.com` domain, so nothing reaches a real inbox. Use team-controlled emails when testing receipts.
- RFCs are generic or test values published by the SAT (`XAXX010101000`, `EKU9003173C9`), not real donors.
- Donations here are loaded directly by an admin for demo purposes; in the real flow they are created only by the payment confirmation process.
- Every record has "(demo)" in its name or a `DEMO-PAY-` payment id, so it is easy to find and delete.

Load:

```bash
sf data import tree --plan data/demo/plan.json --target-org donations-dev
```
