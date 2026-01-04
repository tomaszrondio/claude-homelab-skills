#!/bin/bash
# Check host system health (CPU, Memory, Disk, Uptime)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/alerts.sh"
source "$SCRIPT_DIR/utils/format.sh"

check_host_health() {
    local output=""

    # Get hostname and IP
    local hostname=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')

    # Get uptime
    local uptime_info=$(uptime -p | sed 's/up //')

    # Get load average
    local load_avg=$(uptime | grep -oP 'load average: \K[\d., ]+')
    local load_1=$(echo "$load_avg" | cut -d',' -f1 | tr -d ' ')
    local load_5=$(echo "$load_avg" | cut -d',' -f2 | tr -d ' ')
    local load_15=$(echo "$load_avg" | cut -d',' -f3 | tr -d ' ')

    # Get CPU usage (from top, 1 sample)
    local cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
    local cpu_used=$(awk "BEGIN {printf \"%.0f\", 100 - $cpu_idle}")

    # Check CPU threshold
    check_cpu_threshold "$cpu_used" "Host"

    # Get memory info
    local mem_info=$(free -m | grep Mem:)
    local mem_total=$(echo "$mem_info" | awk '{print $2}')
    local mem_used=$(echo "$mem_info" | awk '{print $3}')
    local mem_available=$(echo "$mem_info" | awk '{print $7}')
    local mem_percent=$(awk "BEGIN {printf \"%.0f\", ($mem_used / $mem_total) * 100}")

    # Check memory threshold
    check_memory_threshold "$mem_percent" "Host"

    # Get disk info
    local disk_root=$(df -h / | tail -1)
    local disk_root_percent=$(echo "$disk_root" | awk '{print $5}' | tr -d '%')
    local disk_root_used=$(echo "$disk_root" | awk '{print $3}')
    local disk_root_total=$(echo "$disk_root" | awk '{print $2}')

    # Check root disk threshold
    check_disk_threshold "$disk_root_percent" "/"

    # Get /opt disk info (if different mount)
    local disk_opt=""
    local disk_opt_percent=""
    local opt_mount=$(df /opt | tail -1 | awk '{print $6}')
    if [ "$opt_mount" != "/" ]; then
        disk_opt=$(df -h /opt | tail -1)
        disk_opt_percent=$(echo "$disk_opt" | awk '{print $5}' | tr -d '%')
        local disk_opt_used=$(echo "$disk_opt" | awk '{print $3}')
        local disk_opt_total=$(echo "$disk_opt" | awk '{print $2}')
        check_disk_threshold "$disk_opt_percent" "/opt"
    fi

    # Format output
    print_section "HOST SYSTEM ($ip)"

    # Status line
    local status="OK"
    if [ "$cpu_used" -ge "$THRESHOLD_CPU_CRIT" ] || [ "$mem_percent" -ge "$THRESHOLD_MEM_CRIT" ] || [ "$disk_root_percent" -ge "$THRESHOLD_DISK_CRIT" ]; then
        status="CRIT"
    elif [ "$cpu_used" -ge "$THRESHOLD_CPU_WARN" ] || [ "$mem_percent" -ge "$THRESHOLD_MEM_WARN" ] || [ "$disk_root_percent" -ge "$THRESHOLD_DISK_WARN" ]; then
        status="WARN"
    fi

    print_status "Status" "$status" "HEALTHY"
    printf "${BOX_V} Uptime: %-54s${BOX_V}\n" "$uptime_info"
    printf "${BOX_V}%-64s${BOX_V}\n" ""

    # Resources header
    printf "${BOX_V} ${BOLD}Resources:${NC}%-53s${BOX_V}\n" ""

    # CPU with progress bar
    print_resource "CPU" "$cpu_used" "(Load: $load_1, $load_5, $load_15)"

    # Memory with progress bar
    local mem_details="(${mem_used}M / ${mem_total}M)"
    print_resource "Memory" "$mem_percent" "$mem_details"

    # Disk with progress bar
    local disk_details="($disk_root_used / $disk_root_total)"
    print_resource "Disk /" "$disk_root_percent" "$disk_details"

    # /opt disk if separate
    if [ -n "$disk_opt_percent" ]; then
        local opt_details="($disk_opt_used / $disk_opt_total)"
        print_resource "Disk /opt" "$disk_opt_percent" "$opt_details"
    fi

    print_section_footer

    # Return status for summary
    if [ "$status" = "CRIT" ]; then
        return 2
    elif [ "$status" = "WARN" ]; then
        return 1
    fi
    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    check_host_health
fi
