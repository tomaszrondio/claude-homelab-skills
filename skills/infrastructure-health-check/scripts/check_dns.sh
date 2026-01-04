#!/bin/bash
# Check AdGuard Home DNS service

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/alerts.sh"
source "$SCRIPT_DIR/utils/format.sh"

check_dns_health() {
    local dns_ip="192.168.1.55"
    local api_port="5381"

    print_section "DNS & SECURITY (AdGuard Home)"

    # Check if container is running
    local container_status=$(docker inspect -f '{{.State.Status}}' adguardhome 2>/dev/null)
    if [ "$container_status" != "running" ]; then
        check_service_down "AdGuard Home" "true"
        printf "${BOX_V} Status: ${RED}${ICON_CRIT} CRITICAL${NC} - Container not running%-25s${BOX_V}\n" ""
        printf "${BOX_V}%-64s${BOX_V}\n" ""

        # Get container exit code and reason
        local exit_code=$(docker inspect -f '{{.State.ExitCode}}' adguardhome 2>/dev/null)
        local state_error=$(docker inspect -f '{{.State.Error}}' adguardhome 2>/dev/null)

        printf "${BOX_V} ${YELLOW}Diagnostics:${NC}%-52s${BOX_V}\n" ""
        printf "${BOX_V}   - Container stopped (exit code: ${exit_code})%-24s${BOX_V}\n" ""
        if [ -n "$state_error" ] && [ "$state_error" != "<no value>" ]; then
            printf "${BOX_V}   - Error: %-51s${BOX_V}\n" "$state_error"
        fi
        printf "${BOX_V}   - Suggested fix: docker start adguardhome%-21s${BOX_V}\n" ""

        print_section_footer
        return 2
    fi

    # Test DNS resolution
    local dns_test=$(dig @"$dns_ip" google.com +short +time=2 2>&1)
    if ! echo "$dns_test" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
        add_alert_crit "DNS resolution failed - AdGuard not responding on port 53"
        printf "${BOX_V} Status: ${RED}${ICON_CRIT} CRITICAL${NC} - DNS not responding%-26s${BOX_V}\n" ""
        printf "${BOX_V}%-64s${BOX_V}\n" ""
        printf "${BOX_V} ${YELLOW}Diagnostics:${NC}%-52s${BOX_V}\n" ""

        # Check if port 53 is in use
        local port_check=$(docker port adguardhome 53 2>/dev/null)

        if [ -z "$port_check" ]; then
            printf "${BOX_V}   - Issue: Port 53 not exposed from container%-20s${BOX_V}\n" ""
            printf "${BOX_V}   - Suggested fix: Update docker-compose.yml%-23s${BOX_V}\n" ""
        else
            # Check if systemd-resolved is interfering
            if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
                printf "${BOX_V}   - Issue: systemd-resolved running (blocks port 53)%-15s${BOX_V}\n" ""
                printf "${BOX_V}   - Suggested fix: Stop systemd-resolved%-25s${BOX_V}\n" ""
                printf "${BOX_V}     systemctl stop systemd-resolved%-27s${BOX_V}\n" ""
                printf "${BOX_V}     systemctl disable systemd-resolved%-24s${BOX_V}\n" ""
                printf "${BOX_V}     docker restart adguardhome%-32s${BOX_V}\n" ""
            else
                printf "${BOX_V}   - Issue: Container up but DNS not answering%-20s${BOX_V}\n" ""
                printf "${BOX_V}   - Suggested fix: docker restart adguardhome%-21s${BOX_V}\n" ""
            fi
        fi

        print_section_footer
        return 2
    fi

    local resolved_ip=$(echo "$dns_test" | head -1)
    printf "${BOX_V} Status: ${GREEN}${ICON_OK} HEALTHY${NC} - DNS working (test: $resolved_ip)${NC}%-9s${BOX_V}\n" ""

    # Try to get stats from API (may not work without auth)
    local stats_output=$(docker exec adguardhome wget -qO- http://localhost/control/stats 2>/dev/null)

    if [ -n "$stats_output" ]; then
        # Parse basic stats
        local total_queries=$(echo "$stats_output" | grep -oP '"num_dns_queries":\K\d+' | head -1)
        local blocked_queries=$(echo "$stats_output" | grep -oP '"num_blocked_filtering":\K\d+' | head -1)

        if [ -n "$total_queries" ] && [ "$total_queries" -gt 0 ]; then
            local block_percent=$(awk "BEGIN {printf \"%.1f\", ($blocked_queries / $total_queries) * 100}")

            printf "${BOX_V} %-62s${BOX_V}\n" ""
            printf "${BOX_V} Last 24h Stats:%-48s${BOX_V}\n" ""
            printf "${BOX_V}   Total queries: %-47s${BOX_V}\n" "$(printf "%'d" "$total_queries")"
            printf "${BOX_V}   Blocked: %-54s${BOX_V}\n" "$(printf "%'d" "$blocked_queries") (${block_percent}%)"

            # Check if blocking percentage is too low (might indicate broken filter)
            if (( $(awk "BEGIN {print ($block_percent < 5)}") )); then
                add_alert_warn "DNS blocking percentage is low (${block_percent}%) - filters may be broken"
            fi
        fi
    else
        printf "${BOX_V} %-62s${BOX_V}\n" ""
        printf "${BOX_V} Stats: API not accessible (auth required)%-24s${BOX_V}\n" ""
    fi

    print_section_footer
    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    check_dns_health
fi
