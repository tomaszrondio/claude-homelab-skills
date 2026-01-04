#!/usr/bin/env python3
"""
Glance Dashboard Setup Script

Automates the creation of Glance dashboard stack with proper
v0.7.0+ configuration structure.
"""

import argparse
import os
import socket
import subprocess
import sys
from pathlib import Path


def get_server_ip():
    """Detect server IP address."""
    try:
        result = subprocess.run(
            ["hostname", "-I"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.split()[0]
    except (subprocess.CalledProcessError, IndexError):
        return "localhost"


def create_compose_yaml(stack_path, http_port, https_port):
    """Generate docker-compose.yaml configuration."""
    compose_content = f"""services:
  glance:
    image: glanceapp/glance:latest
    container_name: glance
    restart: unless-stopped
    ports:
      - "{http_port}:8080/tcp"
      - "{https_port}:8080/tcp"
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - TZ=UTC
"""

    compose_file = stack_path / "compose.yaml"
    compose_file.write_text(compose_content)
    print(f"✓ Created {compose_file}")


def discover_services():
    """Discover running Docker containers and their ports."""
    services = []

    try:
        result = subprocess.run(
            ["docker", "ps", "--format", "{{.Names}}:{{.Ports}}"],
            capture_output=True,
            text=True,
            check=True
        )

        # Map common services to ports
        service_map = {
            "dockge": (5001, "si:docker", "Dockge"),
            "technitiumdns": (5380, "mdi:dns", "TechnitiumDNS"),
            "portainer": (9000, "si:portainer", "Portainer"),
            "nginx-proxy": (81, "mdi:nginx", "Nginx Proxy Manager"),
        }

        for line in result.stdout.strip().split("\n"):
            if not line:
                continue

            name = line.split(":")[0].lower()
            for service_key, (port, icon, title) in service_map.items():
                if service_key in name:
                    services.append({
                        "title": title,
                        "url": f"http://{{SERVER_IP}}:{port}",
                        "icon": icon
                    })
                    break

    except subprocess.CalledProcessError:
        pass

    return services


def create_glance_config(config_path, server_ip, services):
    """Generate glance.yml configuration."""

    # Build bookmarks section
    bookmark_links = []

    # Always add Glance itself
    bookmark_links.append({
        "title": "Glance Dashboard",
        "url": f"http://{server_ip}",
        "icon": "mdi:view-dashboard"
    })

    # Add discovered services
    for service in services:
        service_copy = service.copy()
        service_copy["url"] = service_copy["url"].replace("{SERVER_IP}", server_ip)
        bookmark_links.append(service_copy)

    # Build YAML content
    bookmarks_yaml = ""
    for link in bookmark_links:
        bookmarks_yaml += f"""                  - title: {link['title']}
                    url: {link['url']}
                    icon: {link['icon']}
"""

    config_content = f"""server:
  port: 8080

branding:
  app_name: Dashboard

theme:
  light: false

pages:
  - name: Home
    columns:
      - size: small
        widgets:
          - type: bookmarks
            groups:
              - title: Services
                links:
{bookmarks_yaml}
      - size: full
        widgets:
          - type: docker-containers
            title: Docker Containers
            limit: 20
            running-only: false
            show-status: true
"""

    config_file = config_path / "glance.yml"
    config_file.write_text(config_content)
    print(f"✓ Created {config_file}")


def main():
    parser = argparse.ArgumentParser(
        description="Set up Glance dashboard for Docker monitoring"
    )
    parser.add_argument(
        "--name",
        default="glance",
        help="Stack name (default: glance)"
    )
    parser.add_argument(
        "--http-port",
        type=int,
        default=80,
        help="HTTP port (default: 80)"
    )
    parser.add_argument(
        "--https-port",
        type=int,
        default=443,
        help="HTTPS port (default: 443)"
    )
    parser.add_argument(
        "--stacks-dir",
        default="/opt/stacks",
        help="Stacks directory (default: /opt/stacks)"
    )

    args = parser.parse_args()

    print(f"Setting up Glance dashboard: {args.name}")
    print(f"Ports: {args.http_port} (HTTP), {args.https_port} (HTTPS)")

    # Detect server IP
    server_ip = get_server_ip()
    print(f"Server IP: {server_ip}")

    # Create directory structure
    stack_path = Path(args.stacks_dir) / args.name
    config_path = stack_path / "config"
    config_path.mkdir(parents=True, exist_ok=True)
    print(f"✓ Created directory: {stack_path}")

    # Discover services
    print("Discovering services...")
    services = discover_services()
    if services:
        print(f"✓ Found {len(services)} service(s)")

    # Create configuration files
    create_compose_yaml(stack_path, args.http_port, args.https_port)
    create_glance_config(config_path, server_ip, services)

    print("\n" + "="*50)
    print(f"✓ Glance stack created: {stack_path}")
    print("\nTo start:")
    print(f"  cd {stack_path} && docker compose up -d")
    print(f"\nAccess dashboard:")
    print(f"  http://{server_ip}:{args.http_port}")
    if args.https_port != args.http_port:
        print(f"  http://{server_ip}:{args.https_port}")
    print("\nConfiguration:")
    print(f"  {config_path}/glance.yml")
    print("="*50)


if __name__ == "__main__":
    main()
