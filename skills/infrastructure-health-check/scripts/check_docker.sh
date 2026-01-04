#!/bin/bash
# Check Docker containers status and resource usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/alerts.sh"
source "$SCRIPT_DIR/utils/format.sh"

check_docker_health() {
    # Count containers by state
    local running=$(docker ps -q | wc -l)
    local stopped=$(docker ps -aq --filter "status=exited" | wc -l)
    local total=$(docker ps -aq | wc -l)

    # Critical services list
    local critical_services=("dockge" "adguardhome")

    # Get container stats
    local stats=$(docker stats --no-stream --format "{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}" 2>/dev/null)

    # Get container status
    local containers=$(docker ps -a --format "{{.Names}}|{{.Status}}|{{.State}}" | sort)

    print_section "DOCKER SERVICES"

    # Summary line
    local status_icon="$ICON_OK"
    local status_color="$GREEN"
    if [ "$stopped" -gt 0 ]; then
        # Check if any critical service is down
        while IFS='|' read -r name status state; do
            if [ "$state" != "running" ]; then
                for critical in "${critical_services[@]}"; do
                    if [ "$name" = "$critical" ]; then
                        check_service_down "$name" "true"
                        status_icon="$ICON_CRIT"
                        status_color="$RED"
                        break 2
                    fi
                done
            fi
        done <<< "$containers"

        if [ "$status_icon" = "$ICON_OK" ]; then
            status_icon="$ICON_WARN"
            status_color="$YELLOW"
        fi
    fi

    printf "${BOX_V} Containers: ${status_color}${status_icon}${NC} %-47s${BOX_V}\n" "$running running, $stopped stopped, $total total"
    printf "${BOX_V}%-64s${BOX_V}\n" ""

    # Table header
    printf "${BOX_V} %-16s %-10s %-9s %-6s %-14s${BOX_V}\n" "Service" "Status" "Uptime" "CPU%" "Memory"
    printf "${BOX_V} $(printf '─%.0s' {1..60})${BOX_V}\n"

    # Track if we attempted any fixes
    local attempted_fixes=false
    local containers_fixed=0

    # Process each container
    while IFS='|' read -r name status state; do
        # Parse uptime from status
        local uptime="N/A"
        if [[ "$status" =~ Up[[:space:]](.+) ]]; then
            uptime=$(echo "$status" | sed -E 's/Up ([^(]+).*/\1/' | sed 's/About //' | sed 's/ ago//')
            # Shorten uptime format
            uptime=$(echo "$uptime" | sed 's/ weeks/w/' | sed 's/ week/w/' | sed 's/ days/d/' | sed 's/ day/d/' | sed 's/ hours/h/' | sed 's/ hour/h/' | sed 's/ minutes/m/' | sed 's/ minute/m/' | sed 's/ seconds/s/')
        fi

        # Get stats for this container
        local cpu="0%"
        local mem="0MB"
        local mem_percent="0"

        if [ "$state" = "running" ]; then
            local stat_line=$(echo "$stats" | grep "^$name|" | head -1)
            if [ -n "$stat_line" ]; then
                cpu=$(echo "$stat_line" | cut -d'|' -f2)
                local mem_usage=$(echo "$stat_line" | cut -d'|' -f3)
                mem=$(echo "$mem_usage" | cut -d'/' -f1 | tr -d ' ')
                mem_percent=$(echo "$stat_line" | cut -d'|' -f4 | tr -d '%')
            fi

            print_service_row "$name" "UP" "$uptime" "$cpu" "$mem"
        else
            print_service_row "$name" "DOWN" "$uptime" "---" "---"

            # Check if critical
            local is_critical="false"
            for critical in "${critical_services[@]}"; do
                if [ "$name" = "$critical" ] || [[ "$name" == *"$critical"* ]]; then
                    is_critical="true"
                    break
                fi
            done

            if [ "$is_critical" = "false" ]; then
                add_alert_warn "Container $name is not running"
            fi
        fi
    done <<< "$containers"

    # If any containers are down, show suggested fixes
    if [ "$stopped" -gt 0 ]; then
        printf "${BOX_V}%-64s${BOX_V}\n" ""
        printf "${BOX_V} ${YELLOW}Suggested fixes:${NC}%-48s${BOX_V}\n" ""

        while IFS='|' read -r name status state; do
            if [ "$state" != "running" ]; then
                printf "${BOX_V}   - docker start %-46s${BOX_V}\n" "$name"
            fi
        done <<< "$containers"
    fi

    print_section_footer

    # Return status
    if [ "$status_icon" = "$ICON_CRIT" ]; then
        return 2
    elif [ "$status_icon" = "$ICON_WARN" ]; then
        return 1
    fi
    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    check_docker_health
fi
