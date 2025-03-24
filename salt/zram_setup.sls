{# zram_setup.sls - Idempotent ZRAM setup via SaltStack #}

{% set compression_algo = salt['pillar.get']('zram:compression', 'zstd') %}
{% set cores = salt['grains.get']('num_cpus', 2) %}
{% set max_cores = salt['pillar.get']('zram:max_cores', None) %}
{% if max_cores and max_cores < cores %}
  {% set cores = max_cores %}
{% endif %}
{% set totalmem_kb = salt['cmd.run']("awk '/MemTotal/ {print $2}' /proc/meminfo", python_shell=True) | int %}
{% set per_core_mb = salt['pillar.get']('zram:per_core_memory_mb', None) %}
{% if per_core_mb %}
  {% set mem_per_core = per_core_mb * 1024 * 1024 %}
{% else %}
  {% set mem_per_core = (totalmem_kb * 1024) // cores %}
{% endif %}
{% set swap_priority = salt['pillar.get']('zram:swap_priority', 100) %}

install_zram_packages:
  pkg.installed:
    - pkgs:
      - zram-tools
      - linux-modules-extra-{{ grains['kernelrelease'] }}

unload_zram:
  cmd.run:
    - name: |
        for i in $(seq 0 $(({{ cores }} - 1))); do
          if [ -b /dev/zram$i ]; then
            swapoff /dev/zram$i || true
          fi
        done
        modprobe -r zram || true
    - onlyif: lsmod | grep -q zram
    - require:
      - pkg: install_zram_packages

load_zram:
  kmod.present:
    - name: zram
    - opts: num_devices={{ cores }}
    - require:
      - cmd: unload_zram

{% for core in range(cores) %}
configure_zram_{{ core }}:
  cmd.run:
    - name: |
        echo {{ compression_algo }} > /sys/block/zram{{ core }}/comp_algorithm
        echo {{ mem_per_core }} > /sys/block/zram{{ core }}/disksize
        mkswap /dev/zram{{ core }}
        swapon -p {{ swap_priority }} /dev/zram{{ core }}
    - unless: swapon --summary | grep -q /dev/zram{{ core }}
    - require:
      - kmod: load_zram
{% endfor %}

show_swap_summary:
  cmd.run:
    - name: swapon --summary

