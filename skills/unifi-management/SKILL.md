---
name: unifi-management
description: Comprehensive UniFi network management and monitoring via API. Monitor network health, manage clients (block/unblock/reconnect), view devices (APs, switches, gateways), analyze bandwidth usage, and backup configurations. Supports both UniFi OS (Express, Dream Machine) and traditional controllers. Use when the user asks about UniFi network status, connected clients, device management, WiFi networks, bandwidth usage, blocking devices, or backing up UniFi configuration. Triggers on phrases like "sprawdź unifi", "pokaż klientów wifi", "unifi status", "zablokuj urządzenie", "lista urządzeń unifi", "backup unifi", or any question about UniFi network management.
---

# UniFi Network Management

Manage and monitor UniFi network infrastructure (192.168.1.1) using the UniFi Controller API.

## Available Scripts

```bash
# Network health overview
python3 /opt/.claude/skills/unifi-management/scripts/check_network.py

# List all clients (--wireless, --sort bandwidth)
python3 /opt/.claude/skills/unifi-management/scripts/list_clients.py

# List devices (APs, switches, gateways)
python3 /opt/.claude/skills/unifi-management/scripts/list_devices.py

# Backup configuration
python3 /opt/.claude/skills/unifi-management/scripts/backup_config.py -o /opt/backups
```

## References

- **[api-usage.md](references/api-usage.md)** - Python API examples, configuration details, network infrastructure info
