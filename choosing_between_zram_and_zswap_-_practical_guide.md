# Choosing Between zram and zswap: A Practical Guide

Linux offers multiple techniques to optimize memory usage under pressure, with **zram** and **zswap** being two of the most popular compressed swap solutions. Both aim to reduce I/O to slower storage devices and extend usable RAM, but each achieves this through different design philosophies. This document will help you understand the technical underpinnings of both options, their benefits and trade-offs, and real-world scenarios where one may be better suited than the other.

---

## What is zram?

**zram** creates a compressed block device in RAM, which is used as a swap device. Instead of swapping pages to disk, they are compressed and stored in RAM itself.

### Key Characteristics:
- Acts as a RAM-based swap device
- Data is compressed before being written to the zram device
- No disk I/O is involved
- Multiple zram devices can be created for use with swap, tmpfs, or other purposes

### Benefits:
- Significantly faster than disk-based swap
- Reduces wear on SSDs by avoiding I/O
- Useful on low-memory systems like embedded devices and Raspberry Pis
- Good for workloads with frequent swap pressure

### Limitations:
- Consumes RAM for compressed pages, reducing available memory
- Once the zram device is full, the system must fall back to other swap or OOM handling


## What is zswap?

**zswap** is a compressed write-back cache for swap pages. When a page is swapped out, it is compressed and stored in a dynamically allocated RAM pool. If that pool fills up or a page is evicted, it is written to the actual swap device (usually disk).

### Key Characteristics:
- Works in conjunction with a backing swap device (e.g. a swapfile or swap partition)
- Acts as a cache, not a full replacement for disk swap
- Evicted pages are written to disk

### Benefits:
- Reduces I/O by storing pages in RAM as long as possible
- Compresses memory contents, increasing effective RAM
- Pages that are never reused are eventually written to disk, allowing for long-term persistence
- Good for general-purpose systems with sufficient disk space

### Limitations:
- Still results in disk I/O under heavy memory pressure
- Requires a swap device to function
- Less effective on systems with slow disks or flash wear constraints

---

## Choosing the Right Tool for the Job

| Scenario | Recommendation |
|----------|----------------|
| Low-memory device (e.g. Raspberry Pi) with no disk swap configured | **zram** is ideal due to its speed and no disk requirement |
| Desktop/laptop with SSD and light swap usage | **zswap**, to reduce write wear and improve responsiveness |
| Server with high memory pressure and fallback swap enabled | **zswap**, for caching and disk offload if necessary |
| Embedded system or IoT device with no swap partition | **zram**, as it doesn’t need a backing device |
| Want to replace swap entirely with compressed RAM | **zram** |
| Need to retain pages for long durations under pressure | **zswap**, since pages eventually write to disk |
| Mixed workload desktop where disk space is abundant | **zswap** provides balanced RAM use and persistence |

---

## Summary Table: zram vs zswap

| Feature                          | zram                                   | zswap                                  |
|----------------------------------|----------------------------------------|----------------------------------------|
| Compression Location             | Compressed block device in RAM         | Compressed RAM cache before disk swap |
| Requires Backing Swap Device     | No                                     | Yes                                    |
| Persistence of Swapped Pages     | Lost on reboot                         | Can be persisted to disk              |
| I/O to Disk                      | None                                   | Only on eviction                      |
| RAM Usage                        | Static allocation                      | Dynamic pool                          |
| Configuration Complexity         | Moderate                               | Low                                    |
| Suitable for Low-Memory Systems | Excellent                              | Moderate                               |
| Ideal for SSDs                   | Yes (avoids all writes)                | Yes (minimizes writes)                |
| Scalability                      | Limited to RAM size                    | Scales with swap device               |
| Kernel Feature                   | Kernel module (zram)                   | Built-in feature                      |

---

## Conclusion

Both **zram** and **zswap** serve as effective memory compression tools, each tailored for different use cases. If you’re looking to extend memory without disk I/O and are working in a constrained environment, **zram** is the superior choice. If you want a transparent and efficient way to compress swap activity while retaining disk-based persistence, **zswap** is ideal.

Advanced users may even configure both for hybrid setups—using **zram** for primary compressed swap and **zswap** on a fallback swapfile. The best choice depends on your system's memory, disk type, workload pattern, and tolerance for configuration complexity.

> Use zram when every byte of RAM counts. Use zswap when your system needs to remain agile under load.


