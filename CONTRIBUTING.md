# Contributing

Thanks for improving zram.

## Quickstart
- Install tooling: `./scripts/dev-setup.sh`
- Run lint checks: `make lint`

## Pull requests
- Keep diffs small and focused.
- Explain what changed and why.
- For behavior changes, include a manual test note.
- CI is lint-only; do not add tests that require kernel modules or root/system mutation.
- Update docs when behavior changes.

## Review
PRs are expected to go through review. See `docs/BRANCH_PROTECTION.md` for the recommended branch protection rules.
