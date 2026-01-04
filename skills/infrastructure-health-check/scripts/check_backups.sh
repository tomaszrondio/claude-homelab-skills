#!/bin/bash
# Check backup status and sync health

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/alerts.sh"
source "$SCRIPT_DIR/utils/format.sh"

check_backups_health() {
    print_section "BACKUPS & SYNC"

    local has_issues=false

    # Check UniFi backup
    local unifi_backup=$(ls -t /opt/backups/unifi_backup_*.unf 2>/dev/null | head -1)
    if [ -n "$unifi_backup" ]; then
        check_backup_age "$unifi_backup" "$THRESHOLD_BACKUP_DAYS" "UniFi backup"
        local backup_age=$(( ($(date +%s) - $(stat -c %Y "$unifi_backup")) / 86400 ))
        local backup_size=$(du -h "$unifi_backup" | cut -f1)

        printf "${BOX_V} UniFi Backup:%-51s${BOX_V}\n" ""
        printf "${BOX_V}   Latest: %-56s${BOX_V}\n" "$(basename "$unifi_backup")"
        printf "${BOX_V}   Age: %-59s${BOX_V}\n" "${backup_age} days ago"
        printf "${BOX_V}   Size: %-58s${BOX_V}\n" "$backup_size"

        if [ "$backup_age" -ge "$THRESHOLD_BACKUP_DAYS" ]; then
            has_issues=true
        fi
    else
        add_alert_warn "UniFi backup not found"
        printf "${BOX_V} UniFi Backup: ${YELLOW}Not found${NC}%-42s${BOX_V}\n" ""
        has_issues=true
    fi

    printf "${BOX_V}%-64s${BOX_V}\n" ""

    # Check Obsidian sync (last modified file in vault)
    local obsidian_path="/opt/obsidian-vault"
    if [ -d "$obsidian_path" ]; then
        local latest_file=$(find "$obsidian_path" -type f -name "*.md" -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1)
        if [ -n "$latest_file" ]; then
            local file_time=$(echo "$latest_file" | cut -d' ' -f1 | cut -d'.' -f1)
            local file_path=$(echo "$latest_file" | cut -d' ' -f2-)
            local file_name=$(basename "$file_path")
            local age_hours=$(( ($(date +%s) - file_time) / 3600 ))

            printf "${BOX_V} Obsidian Sync:%-48s${BOX_V}\n" ""
            printf "${BOX_V}   Last modified: %-47s${BOX_V}\n" "$file_name"
            printf "${BOX_V}   Age: %-59s${BOX_V}\n" "${age_hours}h ago"

            if [ "$age_hours" -ge 24 ]; then
                add_alert_info "Obsidian vault not synced in ${age_hours} hours"
            fi
        fi
    else
        printf "${BOX_V} Obsidian Sync: ${GRAY}Not configured${NC}%-37s${BOX_V}\n" ""
    fi

    printf "${BOX_V}%-64s${BOX_V}\n" ""

    # Check GitHub sync (claude-setup repo)
    local claude_dir="/opt/.claude"
    if [ -d "$claude_dir/.git" ]; then
        local last_commit=$(git -C "$claude_dir" log -1 --format="%ar" 2>/dev/null)
        local uncommitted=$(git -C "$claude_dir" status --short 2>/dev/null | wc -l)

        printf "${BOX_V} GitHub Sync (claude-setup):%-36s${BOX_V}\n" ""
        printf "${BOX_V}   Last commit: %-49s${BOX_V}\n" "$last_commit"

        if [ "$uncommitted" -gt 0 ]; then
            add_alert_info "$uncommitted uncommitted changes in claude-setup"
            printf "${BOX_V}   Uncommitted: ${YELLOW}%d changes${NC}%-42s${BOX_V}\n" "$uncommitted" ""
        else
            printf "${BOX_V}   Uncommitted: ${GREEN}0 changes${NC}%-42s${BOX_V}\n" ""
        fi
    fi

    # Overall status
    printf "${BOX_V}%-64s${BOX_V}\n" ""
    if [ "$has_issues" = true ]; then
        print_status "Status" "WARN" "Some backups need attention"
    else
        print_status "Status" "OK" "All backups current"
    fi

    print_section_footer

    if [ "$has_issues" = true ]; then
        return 1
    fi
    return 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    check_backups_health
fi
