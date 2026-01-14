#!/usr/bin/env bash

# ZRAM setup for systemd startup.
# - Configures one ZRAM device per CPU core.
# - Keeps system swap active and lower priority than ZRAM.
# - Fails gracefully if requirements are missing or not installable.
# - Logs to /var/log/zram_setup.log and stdout/stderr for systemd journal.

set -u

LOGFILE="/var/log/zram_setup.log"
CONFIG_FILE="/etc/zram-daemon.conf"

COMPRESSION_ALGO="zstd"
ZRAM_PRIORITY=100
SYSTEM_SWAP_PRIORITY=10

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date -Is)
    printf '%s [%s] %s\n' "$timestamp" "$level" "$message" | tee -a "$LOGFILE"
}

fail_gracefully() {
    log "WARN" "$1"
    ensure_system_swap_active
    exit 0
}

require_root() {
    if [[ ${EUID} -ne 0 ]]; then
        log "ERROR" "This script must be run as root."
        exit 1
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        log "INFO" "Loaded configuration from $CONFIG_FILE"
    fi
}

cpu_cores() {
    if command_exists nproc; then
        nproc --all
    else
        getconf _NPROCESSORS_ONLN
    fi
}

install_package() {
    local package="$1"
    if command_exists apt-get; then
        apt-get update && apt-get install -y "$package"
    elif command_exists dnf; then
        dnf install -y "$package"
    elif command_exists yum; then
        yum install -y "$package"
    elif command_exists pacman; then
        pacman -Sy --noconfirm "$package"
    elif command_exists zypper; then
        zypper --non-interactive install "$package"
    else
        return 1
    fi
}

ensure_dependencies() {
    local missing=()

    for binary in awk modinfo modprobe mkswap swapon swapoff; do
        if ! command_exists "$binary"; then
            missing+=("$binary")
        fi
    done

    if (( ${#missing[@]} )); then
        log "WARN" "Missing required binaries: ${missing[*]}"
        fail_gracefully "Cannot configure ZRAM without required binaries."
    fi

    if ! modinfo zram >/dev/null 2>&1; then
        log "WARN" "ZRAM module not found. Attempting to install kernel modules."
        if ! install_package "linux-modules-extra-$(uname -r)"; then
            fail_gracefully "ZRAM module not available and installation failed."
        fi
    fi
}

ensure_system_swap_active() {
    if ! command_exists swapon; then
        log "WARN" "swapon is unavailable; skipping system swap checks."
        return 0
    fi

    if [[ ! -f /etc/fstab ]]; then
        log "INFO" "No /etc/fstab found; skipping system swap checks."
        return 0
    fi

    if ! swapon --all --ifexists; then
        log "WARN" "Failed to enable swap from /etc/fstab."
    fi

    if command_exists swapoff; then
        lower_system_swap_priority
    fi
}

list_active_swaps() {
    awk 'NR>1 {print $1" "$5" "$4}' /proc/swaps
}

lower_system_swap_priority() {
    local name priority used
    while read -r name priority used; do
        [[ -z "$name" ]] && continue
        if [[ "$name" == /dev/zram* ]]; then
            continue
        fi
        if [[ "$priority" -ge "$ZRAM_PRIORITY" ]]; then
            if [[ "$used" -gt 0 ]]; then
                log "WARN" "Swap $name in use; cannot lower priority safely."
                continue
            fi
            log "INFO" "Lowering priority for $name to $SYSTEM_SWAP_PRIORITY."
            if swapoff "$name"; then
                if ! swapon -p "$SYSTEM_SWAP_PRIORITY" "$name"; then
                    log "WARN" "Failed to re-enable $name with lower priority."
                fi
            else
                log "WARN" "Failed to disable $name to adjust priority."
            fi
        fi
    done < <(list_active_swaps)
}

disable_existing_zram() {
    local device
    for device in /dev/zram*; do
        [[ -b "$device" ]] || continue
        log "INFO" "Disabling swap on $device"
        swapoff "$device" || log "WARN" "Failed to disable swap on $device"
    done

    local sys_device
    for sys_device in /sys/block/zram*; do
        [[ -d "$sys_device" ]] || continue
        if [[ -w "$sys_device/reset" ]]; then
            echo 1 > "$sys_device/reset"
            log "INFO" "Reset $sys_device"
        fi
    done
}

ensure_zram_devices() {
    local cores="$1"

    if ! modprobe zram num_devices="$cores"; then
        if [[ ! -d /sys/class/zram-control ]]; then
            fail_gracefully "Unable to load ZRAM module."
        fi
    fi

    if [[ -d /sys/class/zram-control ]]; then
        local existing
        existing=$(ls /sys/block/zram* 2>/dev/null | wc -l | tr -d ' ')
        while [[ "$existing" -lt "$cores" ]]; do
            if ! echo 1 > /sys/class/zram-control/hot_add; then
                fail_gracefully "Unable to create additional ZRAM devices."
            fi
            existing=$((existing + 1))
        done
    fi
}

configure_zram_devices() {
    local cores="$1"
    local mem_total_kb
    local mem_per_core

    mem_total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    if [[ -z "$mem_total_kb" ]]; then
        fail_gracefully "Unable to read total memory."
    fi

    mem_per_core=$((mem_total_kb * 1024 / cores))

    log "INFO" "Using compression algorithm: $COMPRESSION_ALGO"
    log "INFO" "Configuring $cores ZRAM devices with ${mem_per_core} bytes each"

    for core in $(seq 0 $((cores - 1))); do
        local device="/dev/zram${core}"
        local sys_device="/sys/block/zram${core}"

        if [[ ! -b "$device" ]]; then
            log "WARN" "Skipping missing device $device"
            continue
        fi

        if [[ -w "$sys_device/comp_algorithm" ]]; then
            if ! echo "$COMPRESSION_ALGO" > "$sys_device/comp_algorithm"; then
                log "WARN" "Failed to set compression on $device"
            fi
        fi

        if [[ -w "$sys_device/disksize" ]]; then
            if ! echo "$mem_per_core" > "$sys_device/disksize"; then
                log "WARN" "Failed to set disksize on $device"
                continue
            fi
        fi

        if ! mkswap "$device" >/dev/null 2>&1; then
            log "WARN" "Failed to create swap on $device"
            continue
        fi

        if ! swapon -p "$ZRAM_PRIORITY" "$device"; then
            log "WARN" "Failed to enable swap on $device"
        fi
    done
}

main() {
    log "INFO" "=== ZRAM Setup Script ==="
    log "INFO" "Running as $(whoami) on $(date)"

    require_root
    load_config

    local cores
    cores=$(cpu_cores)
    if [[ -z "$cores" || "$cores" -lt 1 ]]; then
        fail_gracefully "Unable to determine CPU core count."
    fi

    log "INFO" "Detected $cores CPU cores."

    if [[ ${1:-} == "stop" ]]; then
        disable_existing_zram
        ensure_system_swap_active
        log "INFO" "ZRAM stopped successfully."
        exit 0
    fi

    ensure_dependencies

    disable_existing_zram
    ensure_system_swap_active

    ensure_zram_devices "$cores"
    configure_zram_devices "$cores"

    ensure_system_swap_active

    log "INFO" "ZRAM swap enabled successfully."
    swapon --summary | tee -a "$LOGFILE"
}

main "$@"
