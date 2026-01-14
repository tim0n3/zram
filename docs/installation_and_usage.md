# ZRAM Daemon Installation, Usage, and Troubleshooting

## Overview

The `zram.sh` script is designed to run as a systemd-managed, one-shot daemon on boot. It configures one ZRAM swap device per CPU core, sets a high priority for ZRAM, and keeps any system swap configured in `/etc/fstab` active with a lower priority so it is only used as a last resort.

## Installation (systemd)

1. **Copy the script**:
   ```bash
   sudo install -m 0755 zram.sh /usr/local/sbin/zram.sh
   ```

2. **Install the systemd unit**:
   ```bash
   sudo install -m 0644 systemd/zram.service /etc/systemd/system/zram.service
   sudo systemctl daemon-reload
   ```

3. **Enable on boot**:
   ```bash
   sudo systemctl enable --now zram.service
   ```

## Usage

- **Start (or reconfigure) ZRAM**:
  ```bash
  sudo systemctl start zram.service
  ```

- **Stop ZRAM (leave system swap enabled)**:
  ```bash
  sudo systemctl stop zram.service
  ```

- **Manual run**:
  ```bash
  sudo /usr/local/sbin/zram.sh
  sudo /usr/local/sbin/zram.sh stop
  ```

## Configuration

Create `/etc/zram-daemon.conf` to override defaults:

Permissions: ensure the file is owned by `root:root` and not writable by non-root users (mode `0644`).

```bash
# Example configuration overrides
COMPRESSION_ALGO="zstd"
ZRAM_PRIORITY=100
SYSTEM_SWAP_PRIORITY=10
```

Reload the service after changes:

```bash
sudo systemctl restart zram.service
```

## Logging

- Primary log file: `/var/log/zram_setup.log`
- systemd journal: `journalctl -u zram.service`

## Troubleshooting

- **ZRAM not created**: verify the kernel module is available.
  ```bash
  lsmod | grep zram
  modinfo zram
  ```

- **Missing dependencies**: the script logs a warning and leaves system swap untouched. Ensure `modprobe`, `mkswap`, `swapon`, and `swapoff` are available.

- **System swap priority is higher than ZRAM**: the script attempts to lower swap priority for non-ZRAM devices. If swap is in use, it logs a warning and leaves it unchanged.

- **Verify swap priorities**:
  ```bash
  swapon --summary
  ```

## Uninstallation

```bash
sudo systemctl disable --now zram.service
sudo rm -f /etc/systemd/system/zram.service
sudo rm -f /usr/local/sbin/zram.sh
sudo systemctl daemon-reload
```
