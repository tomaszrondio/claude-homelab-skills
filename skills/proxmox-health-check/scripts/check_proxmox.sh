#!/bin/bash
# Proxmox Health Check Script
# Checks VMs, containers, resources, and system health

set -e

# Load configuration from central config file (relative to script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$(cd "$SCRIPT_DIR/../../.." && pwd)/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Config file not found at $CONFIG_FILE"
    echo "   Please copy config.json.example to config.json and fill in your credentials"
    exit 1
fi

PROXMOX_HOST=$(jq -r '.proxmox.host' "$CONFIG_FILE")
PROXMOX_USER=$(jq -r '.proxmox.user' "$CONFIG_FILE")
PROXMOX_PASS=$(jq -r '.proxmox.password' "$CONFIG_FILE")

# SSH command wrapper
ssh_cmd() {
    sshpass -p "$PROXMOX_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${PROXMOX_USER}@${PROXMOX_HOST}" "$@"
}

echo "=== PROXMOX HEALTH CHECK ==="
echo "Host: $PROXMOX_HOST"
echo "Time: $(date)"
echo ""

# 1. System Info
echo "📊 SYSTEM INFO"
ssh_cmd "echo \"Hostname: \$(hostname)\" && echo \"Uptime: \$(uptime -p)\" && echo \"Load: \$(uptime | awk -F'load average:' '{print \$2}')\" && echo \"OS: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'\"' -f2)\""
echo ""

# 2. VM Status
echo "🖥️  VIRTUAL MACHINES"
ssh_cmd "qm list" || echo "No VMs or qm command not available"
echo ""

# 3. LXC Container Status
echo "📦 LXC CONTAINERS"
ssh_cmd "pct list" || echo "No containers or pct command not available"
echo ""

# 4. Resource Usage
echo "💾 RESOURCE USAGE"
ssh_cmd "free -h | grep -E 'Mem:|Swap:' && echo '' && df -h | grep -E '^/dev/|Filesystem' | head -5"
echo ""

# 5. Storage Status
echo "💿 STORAGE POOLS"
ssh_cmd "pvesm status 2>/dev/null || echo 'Storage info not available'"
echo ""

# 6. Network Status
echo "🌐 NETWORK"
ssh_cmd "ip -br addr | grep -v 'lo' | head -5"
echo ""

# 7. Running Services
echo "⚙️  KEY SERVICES"
ssh_cmd "systemctl is-active pve-cluster pvedaemon pveproxy pvestatd 2>/dev/null | paste <(echo -e 'pve-cluster\npvedaemon\npveproxy\npvestatd') - | column -t || echo 'Service status not available'"
echo ""

# 8. Recent Errors (last 10 lines of syslog)
echo "⚠️  RECENT LOGS (last 10 lines)"
ssh_cmd "tail -n 10 /var/log/syslog 2>/dev/null | grep -i -E 'error|warning|fail' || echo 'No recent errors found'"
echo ""

echo "✅ Health check complete!"
