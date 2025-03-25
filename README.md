# 🧠 ZRAM Setup Script

A simple and robust Bash script to configure compressed swap using ZRAM on Linux systems. This script automatically disables any existing ZRAM configurations, sets up new ZRAM swap devices across all CPU cores, and applies a chosen compression algorithm (`zstd` by default). Ideal for performance tuning and memory-constrained systems.

## 🚀 Features

- Automatically detects CPU cores and configures one ZRAM device per core.
- Applies the `zstd` compression algorithm (easily configurable).
- Gracefully disables existing ZRAM configurations and modules.
- Logs all actions to `/var/log/zram_setup.log`.
- Optionally disables ZRAM via the `stop` parameter.
- Installs missing dependencies like `zram-tools` and `linux-modules-extra-*`.

## 📦 Requirements

- Linux (Debian-based systems tested)
- Root privileges
- Internet access (for installing dependencies if missing)

## 🛠️ Installation

Clone the repository and make the script executable:

```
git clone https://github.com/yourusername/zram-setup-script.git
cd zram-setup-script
chmod +x zram_setup.sh
```

## ⚙️ Usage

To **enable ZRAM swap**:

```
sudo ./zram_setup.sh
```

To **stop ZRAM swap and remove the module**:

```
sudo ./zram_setup.sh stop
```

## 📝 Log File

All activity is logged to:

```
/var/log/zram_setup.log
```

Use this to troubleshoot or verify ZRAM activation.

## 🔧 Configuration

- **Compression algorithm**: Default is `zstd`. You can modify the `COMPRESSION_ALGO` variable inside the script to use alternatives like `lz4`, `lzo`, or `zlib`.

## 🧪 Example Output

```
Detected 4 CPU cores.
Disabling swap on /dev/zram0
Removing zram module...
Enabling ZRAM with 4 devices...
Using compression algorithm: zstd
Configuring /dev/zram0 with 2147483648 bytes
ZRAM swap enabled successfully!
```

## ❗ Notes

- On first run, the script may install missing kernel modules (`linux-modules-extra-$(uname -r)`) and tools (`zram-tools`).
- Suitable for lightweight systems like Raspberry Pi or VM hosts where physical RAM is limited.
---

**Author**: [tim0n3](https://github.com/tim0n3)
Feel free to contribute or open issues on GitHub!

---
