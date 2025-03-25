# 🔧 ZRAM Setup with SaltStack

This repository provides a fully idempotent SaltStack state (`zram_setup.sls`) for dynamically configuring compressed swap using **ZRAM**, along with customizable settings via **Pillar data**.

---

## 🚀 Features

- 📌 **Idempotent**: Won’t reconfigure already active ZRAM devices
- ⚙️ **Auto-detects CPU cores** and provisions one ZRAM device per core
- 🧠 **Splits system memory** across devices or uses fixed per-core memory
- 📦 **Customizable compression algorithm** (e.g., `zstd`, `lz4`, `lzo`)
- 🔧 **Swap priority and memory overrides** via Pillars
- 📋 **Provides swap summary** after setup

---

## 📁 Files Overview

| File | Description |
|------|-------------|
| `salt/zram_setup.sls` | Main Salt state to configure ZRAM swap devices |
| `pillar/zram.sls` | Pillar file with customizable ZRAM options |
| `pillar/top.sls` | Top file to apply ZRAM pillar to all minions |

---

## 📥 Pillar Configuration

Create `pillar/zram.sls`:

```
zram:
  compression: zstd          # Compression algorithm (zstd, lz4, lzo, etc.)
  swap_priority: 100         # Optional: swap priority (default: 100)
  max_cores: 4               # Optional: limit number of ZRAM devices
  per_core_memory_mb: 256    # Optional: memory per device (overrides auto split)
```

And update `pillar/top.sls`:

```
base:
  '*':
    - zram
```

---

## 🧪 Usage

Apply the state to a target minion:

```
salt '<minion_id>' state.apply zram_setup
```

Verify swap setup:

```
salt '<minion_id>' cmd.run 'swapon --summary'
```

---

## 🧹 Optional Teardown

If needed, disable and remove all ZRAM devices manually:

```
for i in /dev/zram*; do
  swapoff $i
done
modprobe -r zram
```

Or write a `zram_teardown.sls` state.

---

## 🧱 Requirements

- Debian-based distro (tested on Ubuntu/Debian)
- Salt minion
- Kernel module: `zram`
- `zram-tools` and `linux-modules-extra-*` packages

---

## 🤝 Contributing

Pull requests, feedback, and suggestions are welcome!

---
