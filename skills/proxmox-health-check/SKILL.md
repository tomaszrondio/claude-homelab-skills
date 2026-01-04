---
name: proxmox-health-check
description: Comprehensive Proxmox VE health monitoring and status checking. Automatically checks VM status, LXC containers, system resources, storage, network, and service health. Use when the user asks to check Proxmox, verify infrastructure status, or troubleshoot Proxmox issues. Triggers on phrases like "sprawdź proxmoxa", "check proxmox", "proxmox status", "czy wszystko działa na proxmox", or any question about Proxmox health or status.
---

# Proxmox Health Check

Comprehensive health monitoring for Proxmox VE infrastructure at 192.168.1.100.

## Usage

Run the health check script:

```bash
/opt/.claude/skills/proxmox-health-check/scripts/check_proxmox.sh
```

The script checks: system health, VMs, LXC containers, resources, storage, network, services, and logs.

## References

- **[proxmox-commands.md](references/proxmox-commands.md)** - Proxmox CLI command reference
- **[troubleshooting.md](references/troubleshooting.md)** - Troubleshooting guide, result interpretation, advanced usage
