#!/usr/bin/env bash

set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI not found."
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "Run: gh auth login"
    exit 1
fi

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
default_branch=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)

cat <<MSG
This script will apply branch protection to:
- Repo: $repo
- Branch: $default_branch

Settings:
- Require PR reviews (1) and code owner review
- Dismiss stale reviews
- Require status checks: CI / lint, Bulk Review / bulk-review
- Require conversation resolution (best-effort)
- Enforce for admins
- Restrict force pushes and deletions
MSG

if [[ ${APPLY:-} != "1" ]]; then
    echo "Dry run only. Re-run with APPLY=1 to apply changes."
    exit 1
fi

apply_protection() {
    gh api -X PUT "repos/$repo/branches/$default_branch/protection" --input - <<'PAYLOAD'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI / lint", "Bulk Review / bulk-review"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "required_conversation_resolution": true,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
PAYLOAD
}

if ! apply_protection; then
    echo "Branch protection update failed. Retrying without conversation resolution."
    gh api -X PUT "repos/$repo/branches/$default_branch/protection" --input - <<'PAYLOAD'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI / lint", "Bulk Review / bulk-review"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
PAYLOAD
    echo "Note: enable 'Require conversation resolution' manually in the UI if needed."
fi
