#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

mapfile -t sh_files < <(find . -type d -name .git -prune -o -type f -name '*.sh' -print)

if ((${#sh_files[@]} == 0)); then
    echo "No shell scripts found."
    exit 0
fi

status_dir=${LINT_STATUS_DIR:-}
if [[ -n $status_dir ]]; then
    mkdir -p "$status_dir"
fi

shellcheck_rc=0
shfmt_rc=0
bash_rc=0

printf '## ShellCheck\n'
if ! shellcheck --shell=bash "${sh_files[@]}"; then
    shellcheck_rc=1
fi

printf '\n## shfmt\n'
if ! shfmt -d -ln bash -i 4 -bn -ci -s "${sh_files[@]}"; then
    shfmt_rc=1
fi

printf '\n## bash -n\n'
for file in "${sh_files[@]}"; do
    if ! bash -n "$file"; then
        bash_rc=1
    fi
done

if [[ -n $status_dir ]]; then
    printf '%s\n' "$shellcheck_rc" >"$status_dir/shellcheck.rc"
    printf '%s\n' "$shfmt_rc" >"$status_dir/shfmt.rc"
    printf '%s\n' "$bash_rc" >"$status_dir/bash-n.rc"
fi

if ((shellcheck_rc || shfmt_rc || bash_rc)); then
    exit 1
fi
