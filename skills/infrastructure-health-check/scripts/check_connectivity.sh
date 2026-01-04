#!/bin/bash
# Check external connectivity

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/alerts.sh"
source "$SCRIPT_DIR/utils/format.sh"

check_connectivity_health() {
    print_section "EXTERNAL CONNECTIVITY"

    # Test internet connectivity
    local internet_ok=false
    local ping_output=$(ping -c 2 -W 2 1.1.1.1 2>&1)
    if echo "$ping_output" | grep -q "2 received"; then
        internet_ok=true
        printf "${BOX_V} Internet: ${GREEN}${ICON_OK} Connected${NC} (ping to 1.1.1.1 successful)%-17s${BOX_V}\n" ""
    else
        add_alert_crit "Internet connection down - cannot ping 1.1.1.1"
        printf "${BOX_V} Internet: ${RED}${ICON_DOWN} Offline${NC}%-43s${BOX_V}\n" ""
        printf "${BOX_V}   Diagnostic: Cannot reach 1.1.1.1, check network/router%-7s${BOX_V}\n" ""
    fi

    printf "${BOX_V}%-64s${BOX_V}\n" ""

    # Test external DNS with detailed diagnostics
    local dns_ok=false
    local dns_result=$(dig github.com +short +time=2 2>&1)
    local dns_time_start=$(date +%s%3N)
    if echo "$dns_result" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
        dns_ok=true
        local resolved_ip=$(echo "$dns_result" | head -1)
        printf "${BOX_V} External DNS: ${GREEN}${ICON_OK} Working${NC} (resolved github.com to $resolved_ip)%-5s${BOX_V}\n" ""
    else
        # Try to diagnose the issue
        local dns_servers=$(grep "nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ')
        add_alert_warn "DNS resolution failing - check DNS servers: $dns_servers"
        printf "${BOX_V} External DNS: ${YELLOW}${ICON_WARN} Failed${NC}%-45s${BOX_V}\n" ""
        printf "${BOX_V}   Diagnostic: Cannot resolve github.com%-26s${BOX_V}\n" ""
        printf "${BOX_V}   DNS servers: %-49s${BOX_V}\n" "$dns_servers"

        # Test if it's systemd-resolved interfering
        if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
            printf "${BOX_V}   ${YELLOW}Issue: systemd-resolved is running (may interfere)${NC}%-8s${BOX_V}\n" ""
        fi
    fi

    printf "${BOX_V}%-64s${BOX_V}\n" ""

    # Test GitHub API
    local github_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://api.github.com 2>/dev/null)
    if [ "$github_status" = "200" ]; then
        printf "${BOX_V} GitHub API: ${GREEN}${ICON_OK} Reachable${NC} (HTTP 200)%-33s${BOX_V}\n" ""
    else
        add_alert_info "GitHub API unreachable (HTTP $github_status) - may be network/firewall"
        printf "${BOX_V} GitHub API: ${YELLOW}${ICON_WARN} Failed${NC} (HTTP $github_status)%-32s${BOX_V}\n" ""
        printf "${BOX_V}   Diagnostic: Check firewall/proxy settings%-23s${BOX_V}\n" ""
    fi

    printf "${BOX_V}%-64s${BOX_V}\n" ""

    # Overall status
    if [ "$internet_ok" = false ]; then
        print_status "Status" "CRIT" "Internet connection down"
        print_section_footer
        return 2
    elif [ "$dns_ok" = false ]; then
        print_status "Status" "WARN" "DNS resolution failing"
        print_section_footer
        return 1
    else
        print_status "Status" "OK" "All external services reachable"
    fi

    print_section_footer
    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    check_connectivity_health
fi
