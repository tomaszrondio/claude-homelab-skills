#!/usr/bin/env python3
"""
UniFi Client Wrapper
Provides a consistent interface to the UniFi Controller API using pyunifi.
"""

import json
import os
import requests
import urllib3
from pyunifi.controller import Controller

# Disable SSL warnings for self-signed certs
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class UniFiClient:
    """Wrapper around pyunifi Controller for consistent error handling and configuration."""

    def __init__(self, config_path=None):
        """
        Initialize UniFi Controller connection.

        Args:
            config_path: Path to config file.
                        Defaults to config.json in .claude directory (relative to script).
                        For backwards compatibility, can specify custom path.
        """
        if config_path is None:
            # Get path relative to this script: skills/unifi-management/scripts/ -> .claude/
            script_dir = os.path.dirname(os.path.abspath(__file__))
            claude_dir = os.path.dirname(os.path.dirname(os.path.dirname(script_dir)))
            config_path = os.path.join(claude_dir, 'config.json')

        # Load configuration
        with open(config_path) as f:
            full_config = json.load(f)

        # Extract UniFi section from central config, or use full config if it's a legacy controller.json
        if 'unifi' in full_config:
            config = full_config['unifi']
        else:
            # Legacy mode - entire file is the UniFi config
            config = full_config

        self.config = config
        self.site = config.get('site', 'default')
        self.base_url = f"https://{config['host']}:{config.get('port', 443)}"
        self.api_key = None
        self.session = requests.Session()
        self.session.verify = config.get('ssl_verify', False)

        # Detect UniFi OS (Express, Dream Machine, etc.) - uses /proxy/network prefix
        self.is_unifi_os = config.get('is_unifi_os', True)  # Default to True for modern devices

        # Check if using API key authentication
        if len(config['password']) > 30:  # API keys are typically long
            self.api_key = config['password']
            self.session.headers.update({'X-API-Key': self.api_key})
            self.controller = None
        else:
            # Use traditional username/password with pyunifi
            try:
                self.controller = Controller(
                    host=config['host'],
                    username=config['username'],
                    password=config['password'],
                    port=config.get('port', 8443),
                    version=config.get('version', 'v5'),
                    ssl_verify=config.get('ssl_verify', False)
                )
            except Exception as e:
                # Fallback: try UniFi OS style
                try:
                    self.controller = Controller(
                        host=config['host'],
                        username=config['username'],
                        password=config['password'],
                        port=config.get('port', 443),
                        version='UDMP-unifiOS',
                        ssl_verify=config.get('ssl_verify', False)
                    )
                except:
                    raise e

    def _api_request(self, endpoint, method='GET', data=None):
        """
        Make API request (for API key authentication).

        Args:
            endpoint: API endpoint path (e.g., '/api/s/default/stat/sta')
            method: HTTP method
            data: Request payload

        Returns:
            Response JSON data
        """
        # Add UniFi OS proxy prefix if needed
        if self.is_unifi_os and not endpoint.startswith('/proxy/network'):
            endpoint = f'/proxy/network{endpoint}'

        url = f"{self.base_url}{endpoint}"

        if method == 'GET':
            response = self.session.get(url)
        elif method == 'POST':
            response = self.session.post(url, json=data)
        elif method == 'PUT':
            response = self.session.put(url, json=data)
        elif method == 'DELETE':
            response = self.session.delete(url)
        else:
            raise ValueError(f"Unsupported method: {method}")

        response.raise_for_status()
        return response.json()

    # ========== Client Methods ==========

    def get_clients(self):
        """Get all connected clients."""
        if self.controller:
            return self.controller.get_clients()
        else:
            # API key method
            result = self._api_request(f'/api/s/{self.site}/stat/sta')
            return result.get('data', [])

    def get_client(self, mac):
        """
        Get specific client by MAC address.

        Args:
            mac: MAC address of client (e.g., "aa:bb:cc:dd:ee:ff")

        Returns:
            Client dict or None if not found
        """
        clients = self.get_clients()
        return next((c for c in clients if c.get('mac', '').lower() == mac.lower()), None)

    def block_client(self, mac):
        """Block a client by MAC address."""
        if self.controller:
            return self.controller.block_client(mac)
        else:
            data = {'cmd': 'block-sta', 'mac': mac}
            return self._api_request(f'/api/s/{self.site}/cmd/stamgr', 'POST', data)

    def unblock_client(self, mac):
        """Unblock a client by MAC address."""
        if self.controller:
            return self.controller.unblock_client(mac)
        else:
            data = {'cmd': 'unblock-sta', 'mac': mac}
            return self._api_request(f'/api/s/{self.site}/cmd/stamgr', 'POST', data)

    def authorize_guest(self, mac, minutes=60, up_bandwidth=None, down_bandwidth=None, quota=None):
        """
        Authorize a guest client.

        Args:
            mac: MAC address of guest
            minutes: Duration in minutes
            up_bandwidth: Upload bandwidth limit in Kbps
            down_bandwidth: Download bandwidth limit in Kbps
            quota: Data quota in MB
        """
        if self.controller:
            return self.controller.authorize_guest(
                mac, minutes, up_bandwidth, down_bandwidth, quota
            )
        else:
            data = {
                'cmd': 'authorize-guest',
                'mac': mac,
                'minutes': minutes
            }
            if up_bandwidth:
                data['up'] = up_bandwidth
            if down_bandwidth:
                data['down'] = down_bandwidth
            if quota:
                data['bytes'] = quota * 1024 * 1024  # Convert MB to bytes

            return self._api_request(f'/api/s/{self.site}/cmd/stamgr', 'POST', data)

    def reconnect_client(self, mac):
        """Force client reconnection."""
        if self.controller:
            return self.controller.reconnect_client(mac)
        else:
            data = {'cmd': 'kick-sta', 'mac': mac}
            return self._api_request(f'/api/s/{self.site}/cmd/stamgr', 'POST', data)

    # ========== Device Methods ==========

    def get_devices(self):
        """Get all UniFi devices (APs, switches, gateways)."""
        if self.controller:
            return self.controller.get_aps()  # Despite the name, returns all devices
        else:
            result = self._api_request(f'/api/s/{self.site}/stat/device')
            return result.get('data', [])

    def get_device(self, mac):
        """
        Get specific device by MAC address.

        Args:
            mac: MAC address of device

        Returns:
            Device dict or None if not found
        """
        devices = self.get_devices()
        return next((d for d in devices if d.get('mac', '').lower() == mac.lower()), None)

    def restart_device(self, mac):
        """Restart a device by MAC address."""
        if self.controller:
            return self.controller.restart_ap(mac)
        else:
            data = {'cmd': 'restart', 'mac': mac}
            return self._api_request(f'/api/s/{self.site}/cmd/devmgr', 'POST', data)

    def upgrade_device(self, mac):
        """Upgrade device firmware."""
        if self.controller:
            return self.controller.upgrade_external(mac)
        else:
            data = {'cmd': 'upgrade', 'mac': mac}
            return self._api_request(f'/api/s/{self.site}/cmd/devmgr', 'POST', data)

    # ========== Network & Health Methods ==========

    def get_health(self):
        """Get network health information."""
        if self.controller:
            return self.controller.get_healthinfo()
        else:
            result = self._api_request(f'/api/s/{self.site}/stat/health')
            return result.get('data', [])

    def get_wlan_conf(self):
        """Get WiFi network (WLAN) configurations."""
        if self.controller:
            return self.controller.get_wlan_conf()
        else:
            result = self._api_request(f'/api/s/{self.site}/rest/wlanconf')
            return result.get('data', [])

    def get_network_conf(self):
        """Get network configurations (including VLANs)."""
        if self.controller:
            return self.controller.get_networkconf()
        else:
            result = self._api_request(f'/api/s/{self.site}/rest/networkconf')
            return result.get('data', [])

    # ========== Statistics Methods ==========

    def get_5min_stats(self):
        """Get 5-minute statistics."""
        if self.controller:
            return self.controller.get_5minutes_stats()
        else:
            result = self._api_request(f'/api/s/{self.site}/stat/5minutes')
            return result.get('data', [])

    def get_hourly_stats(self):
        """Get hourly statistics."""
        if self.controller:
            return self.controller.get_hourly_stats()
        else:
            result = self._api_request(f'/api/s/{self.site}/stat/hourly')
            return result.get('data', [])

    def get_daily_stats(self):
        """Get daily statistics."""
        if self.controller:
            return self.controller.get_daily_stats()
        else:
            result = self._api_request(f'/api/s/{self.site}/stat/daily')
            return result.get('data', [])

    # ========== Backup Method ==========

    def get_backup(self):
        """
        Get controller backup data.

        Returns:
            Backup data as bytes
        """
        if self.controller:
            return self.controller.get_backup()
        else:
            # For API key authentication, use it to create backup, then download
            # Step 1: Trigger backup creation using API key
            # days=0 means config only, no historical metrics
            backup_url = f'{self.base_url}/proxy/network/api/s/{self.site}/cmd/backup'
            response = self.session.post(backup_url, json={'cmd': 'backup', 'days': '0'})
            response.raise_for_status()

            # Step 2: Parse response to get download URL
            result = response.json()
            if 'data' not in result or len(result['data']) == 0 or 'url' not in result['data'][0]:
                raise Exception(f"Unexpected backup response format: {result}")

            download_path = result['data'][0]['url']

            # Step 3: Login with password to get session cookies for download
            backup_password = self.config.get('backup_password', self.config['password'])
            download_session = requests.Session()
            download_session.verify = self.config.get('ssl_verify', False)

            login_url = f'{self.base_url}/api/auth/login'
            login_data = {
                'username': self.config['username'],
                'password': backup_password
            }
            login_response = download_session.post(login_url, json=login_data)
            login_response.raise_for_status()

            # Step 4: Download the backup file (try without proxy prefix first)
            # The download URL is typically /dl/backup/filename.unf
            download_url = f'{self.base_url}{download_path}'
            download_response = download_session.get(download_url, allow_redirects=True)

            # If we got HTML (login page), try with /proxy/network prefix
            if download_response.headers.get('content-type', '').startswith('text/html'):
                download_url = f'{self.base_url}/proxy/network{download_path}'
                download_response = download_session.get(download_url, allow_redirects=True)

            download_response.raise_for_status()

            # Verify we got a backup file, not HTML
            if download_response.headers.get('content-type', '').startswith('text/html'):
                raise Exception("Download returned HTML instead of backup file - authentication may have failed")

            return download_response.content

    # ========== Utility Methods ==========

    def resolve_mac(self, identifier):
        """
        Resolve IP address or hostname to MAC address.

        Args:
            identifier: MAC address, IP address, or hostname

        Returns:
            MAC address string, or identifier if already MAC
        """
        # If already MAC format, return as-is
        if ':' in identifier or '-' in identifier:
            return identifier.replace('-', ':').lower()

        # Try to find by IP or hostname
        clients = self.get_clients()
        for client in clients:
            if client.get('ip') == identifier or client.get('hostname') == identifier:
                return client.get('mac')

        # Not found, return original
        return identifier


def format_bytes(bytes_val):
    """Format bytes to human-readable string."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if bytes_val < 1024.0:
            return f"{bytes_val:.2f} {unit}"
        bytes_val /= 1024.0
    return f"{bytes_val:.2f} PB"


def format_uptime(seconds):
    """Format uptime in seconds to human-readable string."""
    days = seconds // 86400
    hours = (seconds % 86400) // 3600
    minutes = (seconds % 3600) // 60

    parts = []
    if days > 0:
        parts.append(f"{days}d")
    if hours > 0:
        parts.append(f"{hours}h")
    if minutes > 0:
        parts.append(f"{minutes}m")

    return ' '.join(parts) if parts else '0m'


if __name__ == '__main__':
    # Test connection
    try:
        client = UniFiClient()
        print("✅ Successfully connected to UniFi Controller")
        print(f"   Host: {client.config['host']}")
        print(f"   Site: {client.site}")

        # Test API call
        health = client.get_health()
        print(f"   Health checks: {len(health)} subsystems")

    except Exception as e:
        print(f"❌ Failed to connect: {e}")
        exit(1)
