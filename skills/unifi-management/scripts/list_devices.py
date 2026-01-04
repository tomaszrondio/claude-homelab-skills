#!/usr/bin/env python3
"""
List UniFi Devices
Shows all UniFi devices (APs, switches, gateways) with status and details.
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from unifi_client import UniFiClient, format_bytes, format_uptime


def list_devices():
    """List all UniFi devices."""
    try:
        client = UniFiClient()
    except Exception as e:
        print(f"❌ Failed to connect to UniFi Controller: {e}")
        return 1

    print("=== UNIFI DEVICES ===")
    print()

    try:
        devices = client.get_devices()

        if not devices:
            print("No devices found")
            return 0

        # Group devices by type
        aps = [d for d in devices if d.get('type') == 'uap']
        switches = [d for d in devices if d.get('type') == 'usw']
        gateways = [d for d in devices if d.get('type') in ['ugw', 'udm', 'uxg']]
        other = [d for d in devices if d not in aps + switches + gateways]

        def print_device_list(device_list, title):
            """Helper to print a list of devices."""
            if not device_list:
                return

            print(f"\n{title} ({len(device_list)} devices)")
            print("-" * 120)
            print(f"{'STATUS':<8} {'NAME':<25} {'MODEL':<15} {'IP ADDRESS':<15} {'VERSION':<15} {'UPTIME':<15} {'CLIENTS':<8}")
            print("-" * 120)

            for device in device_list:
                # Status
                state = device.get('state', 0)
                if state == 1:
                    status = "✅ Online"
                else:
                    status = "❌ Offline"

                name = device.get('name', 'Unknown')[:24]
                model = device.get('model', 'Unknown')
                ip = device.get('ip', 'N/A')
                version = device.get('version', 'Unknown')
                uptime = format_uptime(device.get('uptime', 0))
                num_clients = device.get('num_sta', 0)

                print(f"{status:<8} {name:<25} {model:<15} {ip:<15} {version:<15} {uptime:<15} {num_clients:<8}")

                # Additional info for switches (port count)
                if device.get('type') == 'usw':
                    port_table = device.get('port_table', [])
                    ports_total = len(port_table)
                    ports_up = sum(1 for p in port_table if p.get('up', False))
                    if ports_total > 0:
                        print(f"         └─ Ports: {ports_up}/{ports_total} up")

                # Additional info for APs (radios)
                if device.get('type') == 'uap':
                    radio_table = device.get('radio_table', [])
                    for radio in radio_table:
                        radio_name = radio.get('name', 'Unknown')
                        channel = radio.get('channel', 'N/A')
                        tx_power = radio.get('tx_power', 'N/A')
                        print(f"         └─ {radio_name}: Ch {channel}, TX {tx_power} dBm")

        # Print device groups
        print_device_list(gateways, "🌐 GATEWAYS")
        print_device_list(switches, "🔌 SWITCHES")
        print_device_list(aps, "📡 ACCESS POINTS")
        print_device_list(other, "❓ OTHER DEVICES")

        print()
        print(f"Total: {len(devices)} devices")
        print(f"Online: {sum(1 for d in devices if d.get('state') == 1)} ✅")
        print(f"Offline: {sum(1 for d in devices if d.get('state') != 1)} ❌")

    except Exception as e:
        print(f"❌ Failed to get devices: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0


if __name__ == '__main__':
    sys.exit(list_devices())
