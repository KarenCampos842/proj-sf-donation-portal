#!/usr/bin/env bash
# Creates labels and a GitHub Project board for the backlog.
# Prereqs: gh CLI installed and authenticated, run from inside the cloned repo.
#   gh auth login
#   gh auth refresh -s project      # needed once to manage Projects
#
# Usage: ./scripts/setup_project.sh "Mexico Dreamin Donation Portal - Backlog"
set -euo pipefail

TITLE="${1:-Mexico Dreamin Donation Portal - Backlog}"

echo "Creating labels..."
mk() { gh label create "$1" --color "$2" --description "$3" --force >/dev/null; }
mk user-story    0E8A16 "Backlog user story"
mk delivery-1    1D76DB "Due 2026-11-10"
mk delivery-2    5319E7 "Due 2026-11-17"
mk security      B60205 "Security / least privilege / secrets"
mk blocked       D93F0B "Platform blocker - report to professor same day"
mk ai-error      FBCA04 "AI produced a wrong result (log it in docs/ai-log.md)"
for rf in rf-d1a rf-d1b rf-d2 rf-d3 rf-d4 rf-d5 rf-c1 rf-f1 rf-f2 rf-s1 rf-s2 rf-s3 rf-s4 rf-v1 rf-v2 rf-v3a rf-v3b; do
  mk "$rf" C5DEF5 "Requirement ${rf^^}"
done

echo "Creating project..."
gh project create --owner "@me" --title "$TITLE" --format json

cat <<'EOF'

Project created. Finish the board in the GitHub UI (about 2 minutes):

  1. Open the project -> Settings -> Fields -> "Status".
     Set the options to:  Backlog | Ready | In progress | In review | Done
  2. Link the project to the repo (Project -> Settings -> "Link a repository").
  3. Add custom fields: "RF" (text), "Milestone" (single select: Delivery 1 / Delivery 2),
     "Evidence" (text), "Fulfilled" (single select: Yes / No).
  4. Create the views: Board (group by Status), Table (all fields), Roadmap by Milestone.
  5. Make it public: Project -> Settings -> Visibility -> Public, and link it in README.md.

Then add your user stories as issues using the "User story" issue template
(Issues -> New issue) and add them to the project.
EOF
