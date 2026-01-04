# UniFi Management API Usage

## Python API Examples

Use the `unifi_client.py` module for custom automation:

```python
from unifi_client import UniFiClient

client = UniFiClient()

# Get network health
health = client.get_health()

# List clients
clients = client.get_clients()

# Block/unblock client
client.block_client('aa:bb:cc:dd:ee:ff')
client.unblock_client('aa:bb:cc:dd:ee:ff')

# Get devices
devices = client.get_devices()

# Restart device
client.restart_device('device_mac_address')

# Get WiFi networks
wlans = client.get_wlan_conf()
```

## Configuration

Controller settings: `/opt/.claude/skills/unifi-management/config/controller.json`

Current setup:
- Host: 192.168.1.1 (UniFi Express 7)
- Authentication: API Key
- Port: 443

For traditional controllers, use port 8443 and set `is_unifi_os: false`.

## Network Infrastructure

- **UniFi Controller:** 192.168.1.1 (UniFi Express 7 - UXMAX)
- **Devices:** USW Flex 2.5G 8 PoE (192.168.1.104), Router (192.168.100.2)
- **WiFi Networks:** main network (2.4/5/6 GHz), 2.4 GHz-only network
- **Access:** API key authentication via HTTPS
