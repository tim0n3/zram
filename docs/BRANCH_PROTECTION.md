# Branch Protection

To enforce PR-only merges and required reviews, protect the default branch.

## Recommended UI settings
1. Go to Settings -> Branches (or Rulesets).
2. Add a rule for the default branch.
3. Require pull request reviews (minimum 1).
4. Require Code Owner reviews.
5. Require status checks to pass before merging:
   - `CI / lint`
   - `Bulk Review / bulk-review`
6. Require conversation resolution.
7. Enforce for admins (optional, recommended).
8. Restrict force pushes and branch deletions.

These required checks are what enforce review gates on merges.

## Scripted option
Use `scripts/enable-branch-protection.sh` to apply branch protection via the GitHub API. The script is safe by default and requires `APPLY=1` to make changes.
