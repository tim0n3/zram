# **Technical Design Specification**
## **ZRAM Setup Automation (systemd)**

---

### **Document Version**
**Version:** 2.0  
**Date:** 2024-05-27  
**Author:** Tim  
**Purpose:** Automate the configuration of compressed swap space using ZRAM, designed for systemd startup.

---

## **1. Overview**

This document outlines the design and functionality of a Bash script to automate the setup and teardown of ZRAM-based swap devices on Linux systems. The script is intended to run as a systemd-managed, one-shot daemon on boot. It configures one ZRAM device per CPU core, prioritizes ZRAM over system swap, and keeps system swap configured in `/etc/fstab` enabled as a last resort.

---

## **2. Goals and Objectives**

- Configure one ZRAM swap device per CPU core.
- Use a specified compression algorithm (default: `zstd`).
- Evenly distribute memory across ZRAM devices.
- Keep system swap active but lower priority than ZRAM.
- Fail gracefully when dependencies are missing or not installable.
- Provide logging for traceability and diagnostics.
- Integrate cleanly with systemd as a one-shot daemon.

---

## **3. Assumptions and Dependencies**

### **3.1 Prerequisites**

- Operating system supports ZRAM (`zram` kernel module present or installable).
- Standard swap tooling is available (`swapon`, `swapoff`, `mkswap`).
- The script is run as root or via `sudo`.

### **3.2 Tested Environment**

- Debian-based systems (e.g., Ubuntu, Raspberry Pi OS).
- Kernel version supporting `/sys/block/zramX` configuration.

---

## **4. Functional Specifications**

### **4.1 Input**

- Optional command-line argument:
  - `stop`: Disables ZRAM devices and leaves system swap enabled.

### **4.2 Output**

- `/var/log/zram_setup.log`: Persistent log for auditing actions and errors.
- Console output (captured by systemd journal when run as a service).

### **4.3 Script Flow**

#### **Initialization**

- Set log file path and defaults.
- Load optional configuration file (`/etc/zram-daemon.conf`).
- Verify root privileges and core count.

#### **Teardown Phase (on `stop`)**

- Disable ZRAM swap devices.
- Reset ZRAM devices when supported by the kernel.
- Ensure system swap remains enabled.

#### **Setup Phase**

1. **Ensure Dependencies**
   - Validate availability of required binaries.
   - Attempt to install missing kernel modules if the ZRAM module is absent.
   - Fail gracefully if dependencies are missing or cannot be installed.

2. **Disable Existing ZRAM**
   - Swapoff existing ZRAM devices.
   - Reset ZRAM devices to a clean state.

3. **Keep System Swap Active**
   - Enable swap entries from `/etc/fstab`.
   - Lower system swap priority below ZRAM when safe to do so.

4. **Load/Ensure ZRAM Devices**
   - Load `zram` module and create required devices.
   - Use `hot_add` when available to reach the required device count.

5. **Configure ZRAM Devices**
   - Set compression algorithm.
   - Allocate per-device disk size.
   - Format and enable swap with high priority.

6. **Final Output**
   - Show active swap summary.

---

## **5. Error Handling**

- Dependency issues or module load failures fall back to leaving system swap unchanged.
- Swap priority adjustments skip devices that are in use.
- Logging is emitted for all warnings and errors.

---

## **6. Configuration Parameters**

| Parameter              | Description                                  | Default |
|-----------------------|----------------------------------------------|---------|
| `COMPRESSION_ALGO`    | Compression algorithm used for ZRAM          | `zstd`  |
| `ZRAM_PRIORITY`       | Swap priority for ZRAM devices               | `100`   |
| `SYSTEM_SWAP_PRIORITY`| Swap priority for non-ZRAM swap devices      | `10`    |
| `LOGFILE`             | Log file path for output                     | `/var/log/zram_setup.log` |

---

## **7. Security Considerations**

- Script must be executed with elevated privileges.
- Package installation is best-effort and may be disabled by administrators.

---

## **8. Maintenance Notes**

- Adjust memory allocation logic if requirements change.
- Confirm compression algorithms supported by target kernel.
- Ensure systemd unit path matches the installed script location.

---

## **9. Potential Enhancements**

- Configurable memory fraction of total RAM.
- Optional metrics or telemetry export.
- Distribution-specific packaging.

---

## **10. Appendix**

### **10.1 Example Invocation**

To **start** ZRAM swap:
```bash
sudo systemctl start zram.service
```

To **stop** ZRAM swap:
```bash
sudo systemctl stop zram.service
```
