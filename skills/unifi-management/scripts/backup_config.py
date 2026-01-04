#!/usr/bin/env python3
"""
Backup UniFi Controller Configuration
Downloads and saves controller backup to local disk.
"""

import sys
import os
import argparse
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from unifi_client import UniFiClient


def backup_config(output_dir='/opt/backups'):
    """
    Backup UniFi Controller configuration.

    Args:
        output_dir: Directory to save backup file

    Returns:
        0 on success, 1 on failure
    """
    try:
        client = UniFiClient()
    except Exception as e:
        print(f"❌ Failed to connect to UniFi Controller: {e}")
        return 1

    print("=== UNIFI CONFIGURATION BACKUP ===")
    print(f"Controller: {client.config['host']}")
    print(f"Site: {client.site}")
    print()

    try:
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)

        # Generate backup filename with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"unifi_backup_{client.site}_{timestamp}.unf"
        filepath = os.path.join(output_dir, filename)

        print(f"📦 Requesting backup from controller...")

        # Get backup data
        backup_data = client.get_backup()

        if not backup_data:
            print("❌ No backup data received")
            return 1

        # Save to file
        with open(filepath, 'wb') as f:
            f.write(backup_data)

        file_size = os.path.getsize(filepath)
        file_size_mb = file_size / (1024 * 1024)

        print(f"✅ Backup saved successfully!")
        print(f"   File: {filepath}")
        print(f"   Size: {file_size_mb:.2f} MB")
        print()
        print("💡 To restore this backup:")
        print("   1. Log into UniFi Controller web interface")
        print("   2. Go to Settings > System > Backups")
        print("   3. Click 'Restore' and upload the .unf file")

    except PermissionError:
        print(f"❌ Permission denied: Cannot write to {output_dir}")
        print(f"   Try running with sudo or choose a different directory")
        return 1
    except Exception as e:
        print(f"❌ Failed to create backup: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Backup UniFi Controller configuration')
    parser.add_argument('-o', '--output', default='/opt/backups',
                       help='Output directory for backup file (default: /opt/backups)')

    args = parser.parse_args()

    sys.exit(backup_config(args.output))
