# AI Workflow

## Review roles
- Gemini provides the first-pass review for general issues.
- Codex performs the deep design and logic review and is the tie-breaker.

## Bulk Review automation
Bulk Review runs on every PR update. It:
- Enumerates all commits in the PR and lists changed files per commit.
- Runs repo lint checks (ShellCheck, shfmt -d, bash -n).
- Posts or updates a single PR comment with a markdown report.

To enable issue creation when lint fails, add the label `bulk-review-issues` to the PR. Separate issues are created per failing lint category.
