#!/bin/bash

export LANG=C
LOGFILE="/var/log/zram_swap_check.log"

echo "=== ZRAM Swap Check ===" | tee -a "$LOGFILE"
echo "Running as $(whoami) on $(date)" | tee -a "$LOGFILE"

# Check if swap is enabled
if ! swapon --show > /dev/null 2>&1; then
    echo "No swap is active on this system." | tee -a "$LOGFILE"
    exit 1
fi

# Get swap usage summary
echo "Checking active swap devices..." | tee -a "$LOGFILE"
swapon --summary | tee -a "$LOGFILE"

# Check for any storage-based swap
STORAGE_SWAP=$(swapon --summary | awk '!/zram/ && !/Filename/ {print $1}')

if [[ -z "$STORAGE_SWAP" ]]; then
    echo "✅ No storage-based swap is active." | tee -a "$LOGFILE"
else
    echo "⚠️ Storage swap detected: $STORAGE_SWAP" | tee -a "$LOGFILE"
    echo "Disabling storage swap..." | tee -a "$LOGFILE"
    sudo swapoff -a
    if swapon --summary | grep -q "$STORAGE_SWAP"; then
        echo "❌ Failed to disable storage swap!" | tee -a "$LOGFILE"
        exit 1
    else
        echo "✅ Storage swap disabled successfully." | tee -a "$LOGFILE"
    fi
fi

# Check if ZRAM swap is active
ZRAM_ACTIVE=$(swapon --summary | grep "zram")

if [[ -z "$ZRAM_ACTIVE" ]]; then
    echo "❌ No ZRAM swap is active. Check ZRAM configuration!" | tee -a "$LOGFILE"
    exit 1
else
    echo "✅ ZRAM is active and handling swap." | tee -a "$LOGFILE"
    echo "$ZRAM_ACTIVE" | tee -a "$LOGFILE"
fi

# Check detailed memory & swap usage
echo "=== Memory and Swap Usage ===" | tee -a "$LOGFILE"
free -h | tee -a "$LOGFILE"
vmstat -s | grep "used swap" | tee -a "$LOGFILE"

echo "✅ ZRAM swap verification complete!" | tee -a "$LOGFILE"
