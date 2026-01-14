#!/usr/bin/env bash

set -euo pipefail

out_dir=".github/scripts/out"
lint_out="$out_dir/lint.out"

if [[ -z "${GITHUB_EVENT_PATH:-}" || ! -f "$GITHUB_EVENT_PATH" ]]; then
    echo "GITHUB_EVENT_PATH is missing; cannot create issues."
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI not found; cannot create issues."
    exit 1
fi

repo_full=$(jq -r '.repository.full_name' "$GITHUB_EVENT_PATH")
pr_number=$(jq -r '.pull_request.number // .number // empty' "$GITHUB_EVENT_PATH")
pr_url=$(jq -r '.pull_request.html_url // empty' "$GITHUB_EVENT_PATH")

if [[ -z "$pr_number" ]]; then
    echo "PR number not found; cannot create issues."
    exit 1
fi

if [[ -z "$pr_url" ]]; then
    pr_url="https://github.com/$repo_full/pull/$pr_number"
fi

extract_section() {
    local header="$1"
    if [[ ! -f "$lint_out" ]]; then
        return 0
    fi
    awk -v header="$header" '
        $0 == "## " header {show=1; next}
        /^## / {show=0}
        show {print}
    ' "$lint_out"
}

issue_exists() {
    local title="$1"
    gh issue list --repo "$repo_full" --state open --search "$title in:title" --json title --jq '.[].title' | grep -Fxq "$title"
}

create_issue() {
    local category="$1"
    local details="$2"
    local title="Bulk Review PR #${pr_number}: ${category}"

    if issue_exists "$title"; then
        echo "Issue already open: $title"
        return 0
    fi

    if [[ -z "$details" ]]; then
        details="(No output captured.)"
    fi

    gh issue create --repo "$repo_full" --title "$title" --body "This issue was created from PR #${pr_number}: ${pr_url}

Category: ${category}

How to fix:
1. Run \\`make lint\\` locally.
2. Address the ${category} findings.
3. Push updates to the PR and re-run the checks.

Details:
\\`\\`\\`
${details}
\\`\\`\\`
"
}

categories=(
    "ShellCheck:shellcheck.rc:ShellCheck"
    "shfmt:shfmt.rc:shfmt"
    "bash -n:bash-n.rc:bash -n"
)

for entry in "${categories[@]}"; do
    IFS=: read -r title rc_file header <<< "$entry"
    rc_path="$out_dir/$rc_file"

    if [[ ! -f "$rc_path" ]]; then
        continue
    fi

    if [[ "$(cat "$rc_path")" == "0" ]]; then
        continue
    fi

    section=$(extract_section "$header")
    create_issue "$title" "$section"
done
