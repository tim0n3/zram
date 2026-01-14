#!/usr/bin/env bash

set -euo pipefail

install_deps_debian() {
    local sudo_cmd=()
    if [[ ${EUID} -ne 0 ]]; then
        if command -v sudo >/dev/null 2>&1; then
            sudo_cmd=(sudo)
        else
            echo "sudo is required to install packages."
            exit 1
        fi
    fi

    "${sudo_cmd[@]}" apt-get update
    "${sudo_cmd[@]}" apt-get install -y make shellcheck shfmt
}

install_deps_macos() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required. Install from https://brew.sh"
        exit 1
    fi

    brew install make shellcheck shfmt
}

if command -v apt-get >/dev/null 2>&1; then
    install_deps_debian
elif command -v brew >/dev/null 2>&1; then
    install_deps_macos
else
    echo "Unsupported platform. Please install make, shellcheck, and shfmt manually."
    exit 1
fi
