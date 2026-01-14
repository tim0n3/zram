# Gemini Code Assist Automation

This repository uses GitHub automation to coordinate Gemini Code Assist reviews.

## GitHub workflow control
The review kickoff is handled by:
- `.github/workflows/review-automation.yml`

That workflow runs on pull request events and:
- Ensures review labels exist.
- Adds the Gemini review label to the PR.
- Posts a kickoff comment describing the review roles.

To change labels, the comment body, or trigger conditions, edit the workflow file.

## Configuration options
Gemini Code Assist can be configured using repository files:
- Create a `.gemini/` folder at the repo root.
- Add configuration files per Gemini documentation (for example, review style guides).

Repository-specific guidance for Gemini should live in:
- `GEMINI_INSTRUCTIONS.md`

## Disabling Gemini review automation
To disable the automated kickoff, remove or disable:
- `.github/workflows/review-automation.yml`
