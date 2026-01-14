# AGENTS

This repo contains Bash scripts that configure ZRAM swap on Linux systems.

## Guardrails
- CI is lint-only; do not add steps that load kernel modules, run swapon/swapoff, or require root/system mutation.
- Prefer safe, idempotent changes that are boot-safe.

## Review priorities
- Security and correctness first.
- Idempotency and boot safety next.
- Documentation typos are treated as P1.

## Local checks
- `make lint`

## PR expectations
- Keep diffs small and focused.
- For behavior changes, include a manual test note in the PR.
