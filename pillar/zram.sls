zram:
  compression: zstd         # zstd, lz4, lzo, etc.
  swap_priority: 100        # Optional: swap priority (default 100)
  max_cores: 4              # Optional: limit max zram devices regardless of CPU count
  per_core_memory_mb: 256   # Optional: override auto-calculated size per core

