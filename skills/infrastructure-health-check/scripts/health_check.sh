#!/bin/bash
# Infrastructure Health Check - Main Orchestrator
# Comprehensive monitoring of all infrastructure components

# Ensure UTF-8 encoding
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source utilities
source "$SCRIPT_DIR/utils/alerts.sh"
source "$SCRIPT_DIR/utils/format.sh"

# Source check scripts
source "$SCRIPT_DIR/check_host.sh"
source "$SCRIPT_DIR/check_docker.sh"
source "$SCRIPT_DIR/check_dns.sh"
source "$SCRIPT_DIR/check_backups.sh"
source "$SCRIPT_DIR/check_connectivity.sh"

# Configuration
CONFIG_FILE="$SKILL_DIR/config/thresholds.json"

main() {
    # Start timer
    local start_time=$(date +%s)

    # Load thresholds
    load_thresholds "$CONFIG_FILE"

    # Clear any previous alerts
    clear_alerts

    # Print header
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')

    print_header "INFRASTRUCTURE HEALTH CHECK" "$timestamp | Host: $ip ($hostname)"

    # Track component statuses
    local status_host=0
    local status_docker=0
    local status_dns=0
    local status_backups=0
    local status_connectivity=0

    # Run checks
    check_host_health || status_host=$?
    check_docker_health || status_docker=$?
    check_dns_health || status_dns=$?
    check_backups_health || status_backups=$?
    check_connectivity_health || status_connectivity=$?

    # Run skills for external components
    echo ""
    echo "${BOLD}Running external checks...${NC}"
    echo ""

    # UniFi Network Check
    print_section "NETWORK INFRASTRUCTURE (UniFi)"
    if command -v python3 &>/dev/null && [ -f "/opt/.claude/skills/unifi-management/scripts/check_network.py" ]; then
        local unifi_output=$(python3 /opt/.claude/skills/unifi-management/scripts/check_network.py 2>&1)
        local unifi_status=$?

        if [ $unifi_status -eq 0 ]; then
            # Parse output for key metrics - look for the actual data lines
            local clients_count=$(echo "$unifi_output" | grep -i "clients\|users" | grep -oE '[0-9]+ (client|user)' | grep -oE '[0-9]+' | head -1)
            local devices_count=$(echo "$unifi_output" | grep -i "device" | grep -oE '[0-9]+ device' | grep -oE '[0-9]+' | head -1)

            # If parsing failed, try alternate format
            if [ -z "$clients_count" ]; then
                clients_count=$(echo "$unifi_output" | grep -oP 'Connected clients:\s*\K\d+' || echo "unknown")
            fi

            printf "${BOX_V} Status: ${GREEN}${ICON_OK} HEALTHY${NC}%-46s${BOX_V}\n" ""
            printf "${BOX_V} Controller: 192.168.1.1%-40s${BOX_V}\n" ""

            if [ -n "$devices_count" ] && [ "$devices_count" != "unknown" ]; then
                printf "${BOX_V} Devices: ${devices_count} online%-43s${BOX_V}\n" ""
            fi

            if [ -n "$clients_count" ] && [ "$clients_count" != "unknown" ] && [ "$clients_count" != "0" ]; then
                printf "${BOX_V} Connected clients: ${clients_count}%-40s${BOX_V}\n" ""
            else
                printf "${BOX_V} ${YELLOW}Connected clients: 0 (may be API parsing issue)${NC}%-14s${BOX_V}\n" ""
            fi
        else
            add_alert_warn "UniFi controller unreachable at 192.168.1.1"
            printf "${BOX_V} Status: ${YELLOW}${ICON_WARN} DEGRADED${NC}%-44s${BOX_V}\n" ""
            printf "${BOX_V} Controller: 192.168.1.1%-40s${BOX_V}\n" ""
            printf "${BOX_V}%-64s${BOX_V}\n" ""

            # Diagnostic information
            printf "${BOX_V} ${YELLOW}Diagnostics:${NC}%-52s${BOX_V}\n" ""

            # Test if controller is pingable
            if ping -c 1 -W 2 192.168.1.1 &>/dev/null; then
                printf "${BOX_V}   - Ping: Controller is up%-35s${BOX_V}\n" ""
                printf "${BOX_V}   - Issue: API authentication or network port blocked%-10s${BOX_V}\n" ""
                printf "${BOX_V}   - Action: Check API key in /opt/.claude/config.json%-11s${BOX_V}\n" ""
            else
                printf "${BOX_V}   - Ping: Controller unreachable%-31s${BOX_V}\n" ""
                printf "${BOX_V}   - Action: Check if UniFi controller is online%-17s${BOX_V}\n" ""
            fi

            # Show error from script if available
            local error_msg=$(echo "$unifi_output" | grep -i "error\|failed\|timeout" | head -1 | cut -c1-50)
            if [ -n "$error_msg" ]; then
                printf "${BOX_V}   - Error: %-51s${BOX_V}\n" "$error_msg"
            fi
        fi
    else
        printf "${BOX_V} Status: ${GRAY}Not configured${NC}%-42s${BOX_V}\n" ""
    fi
    print_section_footer

    # Proxmox Check
    print_section "VIRTUALIZATION LAYER (Proxmox)"
    if [ -f "/opt/.claude/skills/proxmox-health-check/scripts/check_proxmox.sh" ]; then
        local proxmox_output=$(bash /opt/.claude/skills/proxmox-health-check/scripts/check_proxmox.sh 2>&1)
        local proxmox_status=$?

        # Parse key metrics from the actual output
        local hostname=$(echo "$proxmox_output" | grep "Hostname:" | awk '{print $2}')
        local uptime=$(echo "$proxmox_output" | grep "Uptime:" | cut -d: -f2- | xargs)
        local vms_running=$(echo "$proxmox_output" | grep -A10 "VIRTUAL MACHINES" | grep "running" | wc -l)
        local vms_total=$(echo "$proxmox_output" | grep -A10 "VIRTUAL MACHINES" | grep -E "^\s+[0-9]+" | wc -l)

        if [ $proxmox_status -eq 0 ]; then
            printf "${BOX_V} Status: ${GREEN}${ICON_OK} HEALTHY${NC}%-46s${BOX_V}\n" ""
            printf "${BOX_V} Node: ${hostname} (192.168.1.100)%-$((36 - ${#hostname}))s${BOX_V}\n" ""
            if [ -n "$uptime" ]; then
                printf "${BOX_V} Uptime: %-55s${BOX_V}\n" "$uptime"
            fi
            if [ "$vms_total" -gt 0 ]; then
                printf "${BOX_V} VMs: ${vms_running}/${vms_total} running%-$((47 - ${#vms_running} - ${#vms_total}))s${BOX_V}\n" ""
            fi
        else
            add_alert_warn "Proxmox node unreachable - check API access to 192.168.1.100"
            printf "${BOX_V} Status: ${YELLOW}${ICON_WARN} DEGRADED${NC}%-44s${BOX_V}\n" ""
            printf "${BOX_V} Node: 192.168.1.100 (unreachable)%-29s${BOX_V}\n" ""
            printf "${BOX_V}%-64s${BOX_V}\n" ""

            # Diagnostic information
            printf "${BOX_V} ${YELLOW}Diagnostics:${NC}%-52s${BOX_V}\n" ""

            # Check if API is accessible
            if ping -c 1 -W 2 192.168.1.100 &>/dev/null; then
                printf "${BOX_V}   - Ping: Host is up%-42s${BOX_V}\n" ""
                printf "${BOX_V}   - Issue: Proxmox API not responding%-26s${BOX_V}\n" ""
                printf "${BOX_V}   - Suggested fix: Check credentials in config.json%-15s${BOX_V}\n" ""
            else
                printf "${BOX_V}   - Ping: Host unreachable%-36s${BOX_V}\n" ""
                printf "${BOX_V}   - Suggested fix: Check if Proxmox server is powered on${BOX_V}\n" ""
            fi
        fi
    else
        printf "${BOX_V} Status: ${GRAY}Not configured${NC}%-42s${BOX_V}\n" ""
    fi
    print_section_footer

    # Get all alerts
    local alerts=$(get_all_alerts)
    local alert_counts=$(get_alert_counts)
    local count_crit=$(echo "$alert_counts" | awk '{print $1}')
    local count_warn=$(echo "$alert_counts" | awk '{print $2}')
    local count_info=$(echo "$alert_counts" | awk '{print $3}')

    # Count healthy components
    local count_healthy=0
    [ $status_host -eq 0 ] && ((count_healthy++))
    [ $status_docker -eq 0 ] && ((count_healthy++))
    [ $status_dns -eq 0 ] && ((count_healthy++))
    [ $status_backups -eq 0 ] && ((count_healthy++))
    [ $status_connectivity -eq 0 ] && ((count_healthy++))

    # Print overall status
    print_overall_status "$count_healthy" "$count_warn" "$count_crit"

    # Print alerts if any
    if [ "$count_crit" -gt 0 ] || [ "$count_warn" -gt 0 ] || [ "$count_info" -gt 0 ]; then
        echo ""
        print_section "ALERTS & WARNINGS"

        while IFS='|' read -r severity message; do
            case "$severity" in
                CRIT) print_alert "CRIT" "$message" ;;
                WARN) print_alert "WARN" "$message" ;;
                INFO) print_alert "INFO" "$message" ;;
                OK)   printf "${BOX_V} ${GREEN}${ICON_OK} %-58s${NC}${BOX_V}\n" "$message" ;;
            esac
        done <<< "$alerts"

        print_section_footer
    fi

    # Build quick stats
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Get quick stats
    local docker_running=$(docker ps -q | wc -l)
    local unifi_clients="${clients_count:-N/A}"
    local dns_container=$(docker inspect -f '{{.State.Status}}' adguardhome 2>/dev/null)
    local dns_status="unknown"
    [ "$dns_container" = "running" ] && dns_status="active"

    local unifi_backup=$(ls -t /opt/backups/unifi_backup_*.unf 2>/dev/null | head -1)
    local backup_info="not found"
    if [ -n "$unifi_backup" ]; then
        local backup_age=$(( ($(date +%s) - $(stat -c %Y "$unifi_backup")) / 86400 ))
        backup_info="${backup_age}d ago"
    fi

    local quick_stats="Network:  $unifi_clients clients | UniFi: online | DNS: $dns_status
Containers: $docker_running running
Backups:  Latest UniFi backup $backup_info"

    # Print footer
    print_footer "$quick_stats" "$duration"

    # Exit with appropriate code
    if [ "$count_crit" -gt 0 ]; then
        exit 2
    elif [ "$count_warn" -gt 0 ]; then
        exit 1
    fi
    exit 0
}

# Run main
main "$@"
