# **Technical Design Specification**
## **ZRAM Setup Automation Script**

---

### **Document Version**
**Version:** 1.0
**Date:** 2024-05-27
**Author:** Tim
**Purpose:** Automate the configuration of compressed swap space using ZRAM.

---

## **1. Overview**

This document outlines the design and functionality of a Bash script to automate the setup and teardown of ZRAM-based swap devices in a Linux system. ZRAM allows RAM compression to create fast swap devices without requiring physical disks. This automation ensures optimal memory utilization and system responsiveness, especially on low-memory or embedded systems.

---

## **2. Goals and Objectives**

- Automatically configure one ZRAM swap device per CPU core.
- Use a specified compression algorithm (default: `zstd`).
- Evenly distribute available memory across all ZRAM devices.
- Ensure safe teardown and reconfiguration.
- Provide logging for traceability and diagnostics.
- Fail gracefully with appropriate error handling.

---

## **3. Assumptions and Dependencies**

### **3.1 Prerequisites**

- Operating system supports ZRAM (`zram` kernel module present or installable).
- `zramctl` (from `zram-tools`) is available or can be installed.
- The script is run as root or via `sudo`.

### **3.2 Tested Environment**

- Debian-based systems (e.g., Ubuntu, Raspberry Pi OS).
- Kernel version supporting dynamic ZRAM setup via `/sys/block/zramX`.

---

## **4. Functional Specifications**

### **4.1 Input**

- Optional command-line argument:
  - `stop`: Disables and removes ZRAM configuration.

### **4.2 Output**

- `/var/log/zram_setup.log`: Persistent log for auditing actions and errors.
- Console output (also logged via `tee`).

### **4.3 Script Flow**

#### **Initialization**

- Set `LANG=C` for consistent locale behavior.
- Create and append to `/var/log/zram_setup.log`.
- Check for root privileges; exit if not root.

#### **Teardown Phase**

- For each `/dev/zramX` device:
  - Disable swap with `swapoff`.
- Unload ZRAM kernel module (`rmmod zram`).
- Exit if `stop` is passed as an argument.

#### **Setup Phase**

1. **Ensure Dependencies**
   - Install `linux-modules-extra-$(uname -r)` if `zram` module is missing.
   - Install `zram-tools` if `zramctl` is missing.

2. **Disable All Swap**
   - Prevent conflicts with other swap devices using `swapoff -a`.

3. **Load ZRAM Module**
   - Use `modprobe zram num_devices=$cores`.

4. **Set Compression Algorithm**
   - Default: `zstd`, configurable in `COMPRESSION_ALGO`.

5. **Memory Allocation**
   - Total memory is divided evenly across all cores.
   - Each `/dev/zramX` is assigned `disksize` and formatted as swap.

6. **Activate Swap**
   - Use `swapon -p 100` for each ZRAM device.

7. **Final Output**
   - Confirm ZRAM swap is active using `swapon --summary`.

---

## **5. Error Handling**

- Centralized `log_and_fail()` function:
  - Logs error messages to both console and file.
  - Terminates execution upon critical failure.

---

## **6. Configuration Parameters**

| Parameter           | Description                                      | Default   |
|--------------------|--------------------------------------------------|-----------|
| `COMPRESSION_ALGO` | Compression algorithm used for ZRAM              | `zstd`    |
| `LOGFILE`          | Log file path for output                         | `/var/log/zram_setup.log` |

---

## **7. Security Considerations**

- Script must be executed with elevated privileges.
- Use caution when auto-installing packages; ensure system is trusted.

---

## **8. Maintenance Notes**

- Adjust memory allocation logic if physical memory size changes.
- Periodically review and test compression algorithm compatibility.
- Confirm module paths and package names remain accurate across kernel updates.

---

## **9. Potential Enhancements**

- Add configuration via external file (`/etc/zram.conf`).
- Support for cgroup-aware setups (e.g., systemd integration).
- Auto-unmount support for filesystems on ZRAM (not applicable to swap).
- Systemd unit file for persistent service-style behavior.

---

## **10. Appendix**

### **10.1 Example Invocation**

To **start** ZRAM swap:
```bash
sudo ./zram_setup.sh
```

To **stop** ZRAM swap:
```bash
sudo ./zram_setup.sh stop
```

---
