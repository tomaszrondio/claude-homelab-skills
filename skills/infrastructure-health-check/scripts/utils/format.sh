#!/bin/bash
# Output formatting utilities for infrastructure health check

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;37m'  # Bright white instead of yellow (was rendering as pink)
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Status icons (simple ASCII)
ICON_OK="[OK]"
ICON_WARN="[WARN]"
ICON_CRIT="[CRIT]"
ICON_INFO="[INFO]"
ICON_UP="UP"
ICON_DOWN="DOWN"

# Box drawing characters (ASCII)
BOX_TL="+"
BOX_TR="+"
BOX_BL="+"
BOX_BR="+"
BOX_H="-"
BOX_V="|"
BOX_VR="+"
BOX_VL="+"

# Double box characters (ASCII)
DBOX_TL="+"
DBOX_TR="+"
DBOX_BL="+"
DBOX_BR="+"
DBOX_H="="
DBOX_V="|"
DBOX_VR="+"
DBOX_VL="+"

# Progress bar function
# Usage: progress_bar 75 10
progress_bar() {
    local percent=$1
    local width=${2:-10}
    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=0; i<empty; i++)); do bar+="-"; done

    echo "$bar"
}

# Print header box
print_header() {
    local title="$1"
    local subtitle="$2"
    local width=62

    echo -e "${BOLD}${DBOX_TL}$(printf '%*s' $width '' | tr ' ' "$DBOX_H")${DBOX_TR}${NC}"
    printf "${BOLD}${DBOX_V}  %-${width}s${DBOX_V}${NC}\n" "$title"
    if [ -n "$subtitle" ]; then
        printf "${BOLD}${DBOX_V}  %-${width}s${DBOX_V}${NC}\n" "$subtitle"
    fi
    echo -e "${BOLD}${DBOX_BL}$(printf '%*s' $width '' | tr ' ' "$DBOX_H")${DBOX_BR}${NC}"
}

# Print section header
print_section() {
    local title="$1"
    local width=62

    echo ""
    echo -e "${BOLD}${BOX_TL}$(printf '%*s' $width '' | tr ' ' "$BOX_H")${BOX_TR}${NC}"
    printf "${BOLD}${BOX_V} %-${width}s${BOX_V}${NC}\n" "$title"
    echo -e "${BOLD}${BOX_VR}$(printf '%*s' $width '' | tr ' ' "$BOX_H")${BOX_VL}${NC}"
}

# Print section footer
print_section_footer() {
    local width=62
    echo -e "${BOLD}${BOX_BL}$(printf '%*s' $width '' | tr ' ' "$BOX_H")${BOX_BR}${NC}"
}

# Print key-value line inside section
print_kv() {
    local key="$1"
    local value="$2"
    local width=62
    printf "${BOX_V} %-${width}s${BOX_V}\n" "$key: $value"
}

# Print status line with icon
print_status() {
    local label="$1"
    local status="$2"  # OK, WARN, CRIT, INFO
    local message="$3"
    local width=62

    local icon=""
    local color=""
    case "$status" in
        OK)    icon="$ICON_OK"; color="$GREEN" ;;
        WARN)  icon="$ICON_WARN"; color="$YELLOW" ;;
        CRIT)  icon="$ICON_CRIT"; color="$RED" ;;
        INFO)  icon="$ICON_INFO"; color="$CYAN" ;;
        *)     icon=""; color="$NC" ;;
    esac

    local text="$label: $icon $message"
    printf "${BOX_V} ${color}%-${width}s${NC}${BOX_V}\n" "$text"
}

# Print resource usage with progress bar
print_resource() {
    local label="$1"
    local percent="$2"
    local details="$3"
    local width=62

    local bar=$(progress_bar "$percent" 10)
    local status_color="$GREEN"

    # Color based on percentage
    if [ "$percent" -ge 90 ]; then
        status_color="$RED"
    elif [ "$percent" -ge 75 ]; then
        status_color="$YELLOW"
    fi

    local text=$(printf "  %-10s [%s] ${status_color}%3d%%${NC}  %s" "$label:" "$bar" "$percent" "$details")
    printf "${BOX_V} %-${width}s${BOX_V}\n" "$text"
}

# Print service table row
print_service_row() {
    local name="$1"
    local status="$2"  # UP or DOWN
    local uptime="$3"
    local cpu="$4"
    local mem="$5"
    local width=62

    local status_icon="$ICON_UP"
    local status_color="$GREEN"
    if [ "$status" = "DOWN" ]; then
        status_icon="$ICON_DOWN"
        status_color="$RED"
    fi

    local text=$(printf "%-16s ${status_color}%-8s${NC} %-9s %-6s %-8s" \
        "$name" "$status_icon" "$uptime" "$cpu" "$mem")
    printf "${BOX_V} %-${width}s${BOX_V}\n" "$text"
}

# Print alert line
print_alert() {
    local severity="$1"  # CRIT, WARN, INFO
    local message="$2"
    local width=62

    local icon=""
    local color=""
    case "$severity" in
        CRIT) icon="$ICON_CRIT"; color="$RED" ;;
        WARN) icon="$ICON_WARN"; color="$YELLOW" ;;
        INFO) icon="$ICON_INFO"; color="$CYAN" ;;
    esac

    local text="$icon  $severity: $message"
    printf "${BOX_V} ${color}%-${width}s${NC}${BOX_V}\n" "$text"
}

# Print footer with stats
print_footer() {
    local stats="$1"
    local duration="$2"
    local width=62

    echo ""
    echo -e "${BOLD}${DBOX_TL}$(printf '%*s' $width '' | tr ' ' "$DBOX_H")${DBOX_TR}${NC}"
    printf "${BOLD}${DBOX_V} %-${width}s${DBOX_V}${NC}\n" "QUICK STATS"
    echo -e "${BOLD}${DBOX_VR}$(printf '%*s' $width '' | tr ' ' "$DBOX_H")${DBOX_VL}${NC}"

    while IFS= read -r line; do
        printf "${DBOX_V} %-${width}s${DBOX_V}\n" "$line"
    done <<< "$stats"

    echo -e "${BOLD}${DBOX_BL}$(printf '%*s' $width '' | tr ' ' "$DBOX_H")${DBOX_BR}${NC}"
    echo ""
    echo "Check completed in ${duration}s"
}

# Print overall status banner
print_overall_status() {
    local healthy=$1
    local warnings=$2
    local critical=$3

    local status_text="HEALTHY"
    local status_color="$GREEN"

    if [ "$critical" -gt 0 ]; then
        status_text="CRITICAL"
        status_color="$RED"
    elif [ "$warnings" -gt 0 ]; then
        status_text="DEGRADED"
        status_color="$YELLOW"
    fi

    echo ""
    echo -e ">> Overall Status: ${status_color}${BOLD}${status_text}${NC} | ${GREEN}${healthy} OK${NC} | ${YELLOW}${warnings} WARNINGS${NC} | ${RED}${critical} CRITICAL${NC}"
}

# Print remediation action
print_remediation() {
    local action="$1"
    local result="$2"  # OK, WARN, CRIT
    local message="$3"
    local width=62

    local icon=""
    local color=""
    case "$result" in
        OK)    icon="[OK]"; color="$GREEN" ;;
        WARN)  icon="[WARN]"; color="$YELLOW" ;;
        CRIT)  icon="[FAIL]"; color="$RED" ;;
        *)     icon="[...]"; color="$CYAN" ;;
    esac

    printf "${BOX_V}   ${BOLD}> ${action}${NC}%-$((50 - ${#action}))s${BOX_V}\n" ""
    printf "${BOX_V}     ${color}${icon}${NC} %-$((57 - ${#icon}))s${BOX_V}\n" "$message"
}

# Export functions
export -f progress_bar
export -f print_header
export -f print_section
export -f print_section_footer
export -f print_kv
export -f print_status
export -f print_resource
export -f print_service_row
export -f print_alert
export -f print_footer
export -f print_overall_status
export -f print_remediation
