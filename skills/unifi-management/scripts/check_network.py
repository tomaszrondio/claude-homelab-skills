#!/usr/bin/env python3
"""
UniFi Network Health Check
Displays comprehensive network status including health, devices, and clients.
"""

import sys
import os

# Add parent directory to path to import unifi_client
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from unifi_client import UniFiClient, format_bytes, format_uptime


def check_network_health():
    """Run comprehensive network health check."""
    try:
        client = UniFiClient()
    except Exception as e:
        print(f"❌ Failed to connect to UniFi Controller: {e}")
        return 1

    print("=== UNIFI NETWORK HEALTH CHECK ===")
    print(f"Controller: {client.config['host']}")
    print(f"Site: {client.site}")
    print()

    # 1. Health Status
    print("📊 SYSTEM HEALTH")
    try:
        health = client.get_health()
        for subsystem in health:
            name = subsystem.get('subsystem', 'Unknown')
            status = subsystem.get('status', 'unknown')

            if status == 'ok':
                icon = "✅"
            elif status == 'warning':
                icon = "⚠️"
            else:
                icon = "❌"

            print(f"  {icon} {name.upper():15} - {status}")
    except Exception as e:
        print(f"  ❌ Failed to get health info: {e}")
    print()

    # 2. Device Summary
    print("🖥️  DEVICES")
    try:
        devices = client.get_devices()
        online = sum(1 for d in devices if d.get('state') == 1)
        offline = len(devices) - online

        print(f"  Total: {len(devices)} devices")
        print(f"  Online: {online} ✅")
        if offline > 0:
            print(f"  Offline: {offline} ❌")
        print()

        for device in devices:
            state_icon = "✅" if device.get('state') == 1 else "❌"
            name = device.get('name', 'Unknown')
            model = device.get('model', 'Unknown')
            ip = device.get('ip', 'N/A')
            version = device.get('version', 'Unknown')
            uptime = format_uptime(device.get('uptime', 0))

            print(f"  {state_icon} {name:20} {model:15} {ip:15} v{version:10} Up: {uptime}")
    except Exception as e:
        print(f"  ❌ Failed to get devices: {e}")
    print()

    # 3. Client Summary
    print("👥 CONNECTED CLIENTS")
    try:
        clients = client.get_clients()
        wireless = sum(1 for c in clients if not c.get('is_wired', True))
        wired = len(clients) - wireless

        print(f"  Total: {len(clients)} clients")
        print(f"  Wireless: {wireless}")
        print(f"  Wired: {wired}")

        # Top bandwidth consumers
        clients_with_bandwidth = [
            (c, c.get('tx_bytes', 0) + c.get('rx_bytes', 0))
            for c in clients
        ]
        clients_with_bandwidth.sort(key=lambda x: x[1], reverse=True)

        if clients_with_bandwidth:
            print()
            print("  Top Bandwidth Consumers:")
            for client, total_bytes in clients_with_bandwidth[:5]:
                hostname = client.get('hostname', 'Unknown')
                ip = client.get('ip', 'N/A')
                print(f"    {hostname:30} {ip:15} {format_bytes(total_bytes)}")
    except Exception as e:
        print(f"  ❌ Failed to get clients: {e}")
    print()

    # 4. WiFi Networks
    print("📡 WIFI NETWORKS")
    try:
        wlans = client.get_wlan_conf()
        if wlans:
            for wlan in wlans:
                enabled_icon = "✅" if wlan.get('enabled', False) else "❌"
                name = wlan.get('name', 'Unknown')
                security = wlan.get('security', 'open')
                print(f"  {enabled_icon} {name:25} Security: {security}")
        else:
            print("  No WiFi networks configured")
    except Exception as e:
        print(f"  ⚠️  Could not fetch WiFi networks")
    print()

    print("✅ Health check complete!")
    return 0


if __name__ == '__main__':
    sys.exit(check_network_health())
