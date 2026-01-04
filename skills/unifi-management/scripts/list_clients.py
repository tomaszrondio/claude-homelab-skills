#!/usr/bin/env python3
"""
List UniFi Connected Clients
Shows all connected clients with details like hostname, IP, MAC, bandwidth usage.
"""

import sys
import os
import argparse

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from unifi_client import UniFiClient, format_bytes, format_uptime


def list_clients(filter_type=None, sort_by='name'):
    """
    List all connected clients.

    Args:
        filter_type: Filter clients by type ('wireless', 'wired', or None for all)
        sort_by: Sort by 'name', 'ip', 'bandwidth', or 'connection'
    """
    try:
        client = UniFiClient()
    except Exception as e:
        print(f"❌ Failed to connect to UniFi Controller: {e}")
        return 1

    print("=== UNIFI CONNECTED CLIENTS ===")
    print()

    try:
        clients = client.get_clients()

        # Apply filter
        if filter_type == 'wireless':
            clients = [c for c in clients if not c.get('is_wired', True)]
            print(f"📡 WIRELESS CLIENTS ({len(clients)} connected)")
        elif filter_type == 'wired':
            clients = [c for c in clients if c.get('is_wired', False)]
            print(f"🔌 WIRED CLIENTS ({len(clients)} connected)")
        else:
            print(f"👥 ALL CLIENTS ({len(clients)} connected)")
        print()

        # Sort clients
        if sort_by == 'name':
            clients.sort(key=lambda c: c.get('hostname', 'zzz_unknown').lower())
        elif sort_by == 'ip':
            clients.sort(key=lambda c: c.get('ip', '255.255.255.255'))
        elif sort_by == 'bandwidth':
            clients.sort(
                key=lambda c: c.get('tx_bytes', 0) + c.get('rx_bytes', 0),
                reverse=True
            )
        elif sort_by == 'connection':
            clients.sort(
                key=lambda c: c.get('uptime', 0),
                reverse=True
            )

        # Print header
        print(f"{'HOSTNAME':<30} {'IP ADDRESS':<15} {'MAC ADDRESS':<17} {'TYPE':<8} {'BANDWIDTH':<12} {'UPTIME':<12}")
        print("-" * 110)

        for c in clients:
            hostname = c.get('hostname', 'Unknown')[:29]
            ip = c.get('ip', 'N/A')
            mac = c.get('mac', 'N/A')
            conn_type = "WiFi" if not c.get('is_wired', True) else "Wired"
            total_bytes = c.get('tx_bytes', 0) + c.get('rx_bytes', 0)
            bandwidth = format_bytes(total_bytes)
            uptime = format_uptime(c.get('uptime', 0))

            # Add signal strength for wireless
            if conn_type == "WiFi":
                signal = c.get('signal', 0)
                rssi = c.get('rssi', 0)
                if rssi:
                    conn_type = f"WiFi {rssi}dBm"

            print(f"{hostname:<30} {ip:<15} {mac:<17} {conn_type:<8} {bandwidth:<12} {uptime:<12}")

        print()
        print(f"Total: {len(clients)} clients")

    except Exception as e:
        print(f"❌ Failed to get clients: {e}")
        return 1

    return 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='List UniFi connected clients')
    parser.add_argument('--wireless', action='store_true', help='Show only wireless clients')
    parser.add_argument('--wired', action='store_true', help='Show only wired clients')
    parser.add_argument('--sort', choices=['name', 'ip', 'bandwidth', 'connection'],
                       default='name', help='Sort by field (default: name)')

    args = parser.parse_args()

    filter_type = None
    if args.wireless:
        filter_type = 'wireless'
    elif args.wired:
        filter_type = 'wired'

    sys.exit(list_clients(filter_type, args.sort))
