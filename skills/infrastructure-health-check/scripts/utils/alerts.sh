#!/bin/bash
# Alert management and threshold checking

# Global alert arrays
declare -g -A ALERTS_CRIT
declare -g -A ALERTS_WARN
declare -g -A ALERTS_INFO
declare -g ALERT_COUNT_CRIT=0
declare -g ALERT_COUNT_WARN=0
declare -g ALERT_COUNT_INFO=0

# Load thresholds from config
load_thresholds() {
    local config_file="$1"

    if [ -f "$config_file" ]; then
        # Read JSON config - simple key extraction
        THRESHOLD_CPU_WARN=$(grep -oP '"cpu_warning":\s*\K\d+' "$config_file" | head -1)
        THRESHOLD_CPU_CRIT=$(grep -oP '"cpu_critical":\s*\K\d+' "$config_file" | head -1)
        THRESHOLD_MEM_WARN=$(grep -oP '"memory_warning":\s*\K\d+' "$config_file" | head -1)
        THRESHOLD_MEM_CRIT=$(grep -oP '"memory_critical":\s*\K\d+' "$config_file" | head -1)
        THRESHOLD_DISK_WARN=$(grep -oP '"disk_warning":\s*\K\d+' "$config_file" | head -1)
        THRESHOLD_DISK_CRIT=$(grep -oP '"disk_critical":\s*\K\d+' "$config_file" | head -1)
        THRESHOLD_BACKUP_DAYS=$(grep -oP '"unifi_age_warning_days":\s*\K\d+' "$config_file" | head -1)
    else
        # Defaults
        THRESHOLD_CPU_WARN=70
        THRESHOLD_CPU_CRIT=90
        THRESHOLD_MEM_WARN=75
        THRESHOLD_MEM_CRIT=90
        THRESHOLD_DISK_WARN=80
        THRESHOLD_DISK_CRIT=90
        THRESHOLD_BACKUP_DAYS=7
    fi

    export THRESHOLD_CPU_WARN THRESHOLD_CPU_CRIT
    export THRESHOLD_MEM_WARN THRESHOLD_MEM_CRIT
    export THRESHOLD_DISK_WARN THRESHOLD_DISK_CRIT
    export THRESHOLD_BACKUP_DAYS
}

# Add critical alert
add_alert_crit() {
    local message="$1"
    ALERTS_CRIT[$ALERT_COUNT_CRIT]="$message"
    ((ALERT_COUNT_CRIT++))
}

# Add warning alert
add_alert_warn() {
    local message="$1"
    ALERTS_WARN[$ALERT_COUNT_WARN]="$message"
    ((ALERT_COUNT_WARN++))
}

# Add info alert
add_alert_info() {
    local message="$1"
    ALERTS_INFO[$ALERT_COUNT_INFO]="$message"
    ((ALERT_COUNT_INFO++))
}

# Check CPU threshold
check_cpu_threshold() {
    local cpu_percent=$1
    local context="$2"

    # Remove decimal point for comparison
    cpu_percent=${cpu_percent%.*}

    if [ "$cpu_percent" -ge "$THRESHOLD_CPU_CRIT" ]; then
        add_alert_crit "$context CPU usage at ${cpu_percent}% (critical threshold: ${THRESHOLD_CPU_CRIT}%)"
        return 2
    elif [ "$cpu_percent" -ge "$THRESHOLD_CPU_WARN" ]; then
        add_alert_warn "$context CPU usage at ${cpu_percent}% (warning threshold: ${THRESHOLD_CPU_WARN}%)"
        return 1
    fi
    return 0
}

# Check memory threshold
check_memory_threshold() {
    local mem_percent=$1
    local context="$2"

    # Remove decimal point for comparison
    mem_percent=${mem_percent%.*}

    if [ "$mem_percent" -ge "$THRESHOLD_MEM_CRIT" ]; then
        add_alert_crit "$context memory usage at ${mem_percent}% (critical threshold: ${THRESHOLD_MEM_CRIT}%)"
        return 2
    elif [ "$mem_percent" -ge "$THRESHOLD_MEM_WARN" ]; then
        add_alert_warn "$context memory usage at ${mem_percent}% (warning threshold: ${THRESHOLD_MEM_WARN}%)"
        return 1
    fi
    return 0
}

# Check disk threshold
check_disk_threshold() {
    local disk_percent=$1
    local mount="$2"

    # Remove % sign if present
    disk_percent=${disk_percent%\%}

    if [ "$disk_percent" -ge "$THRESHOLD_DISK_CRIT" ]; then
        add_alert_crit "Disk $mount at ${disk_percent}% (critical threshold: ${THRESHOLD_DISK_CRIT}%)"
        return 2
    elif [ "$disk_percent" -ge "$THRESHOLD_DISK_WARN" ]; then
        add_alert_warn "Disk $mount at ${disk_percent}% (warning threshold: ${THRESHOLD_DISK_WARN}%)"
        return 1
    fi
    return 0
}

# Check if service is down
check_service_down() {
    local service_name="$1"
    local is_critical="${2:-true}"

    if [ "$is_critical" = "true" ]; then
        add_alert_crit "$service_name is DOWN"
        return 2
    else
        add_alert_warn "$service_name is DOWN"
        return 1
    fi
}

# Check backup age (in days)
check_backup_age() {
    local backup_file="$1"
    local max_age_days="$2"
    local backup_name="$3"

    if [ ! -f "$backup_file" ]; then
        add_alert_warn "$backup_name not found"
        return 1
    fi

    local file_time=$(stat -c %Y "$backup_file")
    local current_time=$(date +%s)
    local age_seconds=$((current_time - file_time))
    local age_days=$((age_seconds / 86400))

    if [ "$age_days" -ge "$max_age_days" ]; then
        add_alert_warn "$backup_name is ${age_days} days old (threshold: ${max_age_days} days)"
        return 1
    fi

    return 0
}

# Get all alerts formatted
get_all_alerts() {
    local has_alerts=false

    # Critical alerts
    if [ "$ALERT_COUNT_CRIT" -gt 0 ]; then
        has_alerts=true
        for i in "${!ALERTS_CRIT[@]}"; do
            echo "CRIT|${ALERTS_CRIT[$i]}"
        done
    fi

    # Warning alerts
    if [ "$ALERT_COUNT_WARN" -gt 0 ]; then
        has_alerts=true
        for i in "${!ALERTS_WARN[@]}"; do
            echo "WARN|${ALERTS_WARN[$i]}"
        done
    fi

    # Info alerts
    if [ "$ALERT_COUNT_INFO" -gt 0 ]; then
        has_alerts=true
        for i in "${!ALERTS_INFO[@]}"; do
            echo "INFO|${ALERTS_INFO[$i]}"
        done
    fi

    if [ "$has_alerts" = false ]; then
        echo "OK|No alerts - all systems healthy"
    fi
}

# Get alert counts
get_alert_counts() {
    echo "$ALERT_COUNT_CRIT $ALERT_COUNT_WARN $ALERT_COUNT_INFO"
}

# Clear all alerts
clear_alerts() {
    ALERTS_CRIT=()
    ALERTS_WARN=()
    ALERTS_INFO=()
    ALERT_COUNT_CRIT=0
    ALERT_COUNT_WARN=0
    ALERT_COUNT_INFO=0
}

# Export functions
export -f load_thresholds
export -f add_alert_crit
export -f add_alert_warn
export -f add_alert_info
export -f check_cpu_threshold
export -f check_memory_threshold
export -f check_disk_threshold
export -f check_service_down
export -f check_backup_age
export -f get_all_alerts
export -f get_alert_counts
export -f clear_alerts
