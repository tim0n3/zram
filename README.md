# 🧠 ZRAM Setup Script (systemd-ready)

A production-safe Bash script to configure compressed swap with ZRAM on Linux systems. It is designed to run as a systemd-managed, one-shot daemon at boot, creating one ZRAM device per CPU core, setting a high ZRAM priority, and keeping any system swap configured in `/etc/fstab` enabled with a lower priority.

## 🚀 Features

- One ZRAM swap device per CPU core.
- Default compression algorithm: `zstd` (configurable).
- Works as a systemd one-shot daemon (`zram.service`).
- Keeps system swap active but ensures it is used **after** ZRAM.
- Fails gracefully when dependencies are missing or cannot be installed.
- Logs to `/var/log/zram_setup.log` and the systemd journal.

## 📦 Requirements

- Linux with ZRAM support (`zram` kernel module).
- Root privileges.
- Optional internet access for package installation when needed.

## 🛠️ Installation (systemd)

```bash
sudo install -m 0755 zram.sh /usr/local/sbin/zram.sh
sudo install -m 0644 systemd/zram.service /etc/systemd/system/zram.service
sudo systemctl daemon-reload
sudo systemctl enable --now zram.service
```

## ⚙️ Usage

- Start or reconfigure:
  ```bash
  sudo systemctl start zram.service
  ```

- Stop ZRAM (system swap remains enabled):
  ```bash
  sudo systemctl stop zram.service
  ```

- Manual run (without systemd):
  ```bash
  sudo /usr/local/sbin/zram.sh
  sudo /usr/local/sbin/zram.sh stop
  ```

## 🔧 Configuration

Create `/etc/zram-daemon.conf` to override defaults:

Permissions: ensure the file is owned by `root:root` and not writable by non-root users (mode `0644`).

```bash
COMPRESSION_ALGO="zstd"
ZRAM_PRIORITY=100
SYSTEM_SWAP_PRIORITY=10
```

## 📝 Documentation

- [Installation, usage, and troubleshooting](docs/installation_and_usage.md)
- [Technical design specification](docs/technical_design_specification.md)
- [Choosing between ZRAM and Zswap](docs/choosing_between_zram_and_zswap_-_practical_guide.md)

---

**Author**: [tim0n3](https://github.com/tim0n3)
