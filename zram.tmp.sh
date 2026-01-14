#!/bin/bash

export LANG=C
LOGFILE="/var/log/zram_setup.log"

echo "=== ZRAM Setup Script ===" | tee -a "$LOGFILE"
echo "Running as $(whoami) on $(date)" | tee -a "$LOGFILE"

# Detect the number of CPU cores
cores=$(nproc --all)
echo "Detected $cores CPU cores." | tee -a "$LOGFILE"

# Disable existing ZRAM swap
core=0
while (( core < cores )); do
    if [[ -b "/dev/zram${core}" ]]; then
        echo "Disabling swap on /dev/zram${core}" | tee -a "$LOGFILE"
        swapoff "/dev/zram${core}"
    fi
    ((core++))
done

# Unload the ZRAM module if it's active
if lsmod | grep -q zram; then
    echo "Removing zram module..." | tee -a "$LOGFILE"
    rmmod zram
fi

# If stop is requested, exit after disabling ZRAM
if [[ ${1:-} == "stop" ]]; then
    echo "ZRAM stopped successfully." | tee -a "$LOGFILE"
    exit 0
fi

# Ensure necessary packages are installed
if ! command -v zramctl &> /dev/null; then
    echo "Installing zram-tools..." | tee -a "$LOGFILE"
    sudo apt update && sudo apt install -y zram-tools
fi

# Disable all existing swap before enabling ZRAM
swapoff -a

# Load ZRAM module with multiple devices equal to CPU cores
echo "Enabling ZRAM with $cores devices..." | tee -a "$LOGFILE"
modprobe zram num_devices="$cores"

# Select compression algorithm (best balance of speed & compression)
COMPRESSION_ALGO="zstd"  # Change to lz4, lzo, or gzip if needed
echo "Using compression algorithm: $COMPRESSION_ALGO" | tee -a "$LOGFILE"

# Get total system memory in KB
totalmem=$(awk '/MemTotal/ {print $2}' /proc/meminfo)

# Allocate memory per ZRAM device (total RAM divided by number of cores)
mem_per_core=$((totalmem * 1024 / cores))

core=0
while (( core < cores )); do
    echo "Configuring /dev/zram${core} with ${mem_per_core} bytes" | tee -a "$LOGFILE"
    echo "$COMPRESSION_ALGO" > "/sys/block/zram${core}/comp_algorithm"
    echo "$mem_per_core" > "/sys/block/zram${core}/disksize"
    mkswap "/dev/zram${core}"
    swapon -p 100 "/dev/zram${core}"  # Higher priority than disk-based swap
    ((core++))
done

echo "ZRAM swap enabled successfully!" | tee -a "$LOGFILE"
swapon --summary | tee -a "$LOGFILE"
