#!/bin/bash

export LANG=C
LOGFILE="/var/log/zram_setup.log"

echo "=== ZRAM Setup Script ===" | tee -a $LOGFILE
echo "Running as $(whoami) on $(date)" | tee -a $LOGFILE

# Check if running as root (unless started from rc.local)
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo!" | tee -a $LOGFILE
    exit 1
fi

cores=$(nproc --all)
echo "Detected $cores CPU cores." | tee -a $LOGFILE

# Function to log and handle errors
log_and_fail() {
    echo "ERROR: $1" | tee -a $LOGFILE
    exit 1
}

# Disable existing ZRAM swap
core=0
while [ $core -lt $cores ]; do
    if [[ -b /dev/zram$core ]]; then
        echo "Disabling swap on /dev/zram$core" | tee -a $LOGFILE
        swapoff /dev/zram$core || log_and_fail "Failed to disable swap on /dev/zram$core"
    fi
    let core=core+1
done

# Unload the ZRAM module if it's active
if lsmod | grep -q zram; then
    echo "Removing zram module..." | tee -a $LOGFILE
    rmmod zram || log_and_fail "Failed to remove zram module"
fi

# If script is called with "stop", exit now
if [[ $1 == "stop" ]]; then
    echo "ZRAM stopped successfully." | tee -a $LOGFILE
    exit 0
fi

# Ensure zram module is available, otherwise install missing kernel modules
if ! modinfo zram &>/dev/null; then
    echo "ZRAM module not found! Attempting to install missing kernel modules..." | tee -a $LOGFILE
    apt update && apt install -y linux-modules-extra-$(uname -r) || log_and_fail "Failed to install linux-modules-extra-$(uname -r)"

    # Retry loading the module
    modprobe zram || log_and_fail "ZRAM module is still missing after installation."
fi

# Install zram-tools if missing
if ! command -v zramctl &> /dev/null; then
    echo "Installing zram-tools..." | tee -a $LOGFILE
    apt update && apt install -y zram-tools || log_and_fail "Failed to install zram-tools"
fi

swapoff -a || log_and_fail "Failed to disable all swap"

echo "Enabling ZRAM with $cores devices..." | tee -a $LOGFILE
modprobe zram num_devices=$cores || log_and_fail "Failed to load ZRAM module"

# Select compression algorithm (modify if needed)
COMPRESSION_ALGO="zstd"
echo "Using compression algorithm: $COMPRESSION_ALGO" | tee -a $LOGFILE

# Set compression algorithm
for core in $(seq 0 $((cores-1))); do
    echo "$COMPRESSION_ALGO" | tee /sys/block/zram$core/comp_algorithm || log_and_fail "Failed to set compression algorithm on /dev/zram$core"
done

# Allocate memory per ZRAM device (split across cores)
totalmem=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_per_core=$(( totalmem * 1024 / cores ))

core=0
while [ $core -lt $cores ]; do
    echo "Configuring /dev/zram$core with ${mem_per_core} bytes" | tee -a $LOGFILE
    echo $mem_per_core | tee /sys/block/zram$core/disksize || log_and_fail "Failed to set disksize on /dev/zram$core"
    mkswap /dev/zram$core || log_and_fail "Failed to create swap on /dev/zram$core"
    swapon -p 100 /dev/zram$core || log_and_fail "Failed to enable swap on /dev/zram$core"
    let core=core+1
done

echo "ZRAM swap enabled successfully!" | tee -a $LOGFILE
swapon --summary | tee -a $LOGFILE
