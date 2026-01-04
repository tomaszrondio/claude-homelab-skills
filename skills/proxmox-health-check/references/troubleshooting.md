# Proxmox Health Check - Troubleshooting Guide

## Interpreting Results

### Healthy System Indicators
- All VMs/containers showing "running" status
- System load < number of CPU cores
- Memory usage < 90%
- Storage usage < 85%
- All pve-* services "active"
- No recent critical errors in logs

### Warning Signs
- VMs/containers stopped unexpectedly
- High system load (> CPU cores)
- Memory usage > 90%
- Storage usage > 85%
- Services showing "inactive" or "failed"
- Error messages in recent logs

## Known Infrastructure

### Virtual Machines
- **VM 100:** haos-16.3 (Home Assistant OS) - 3GB RAM, 32GB disk
- **VM 101:** docker - 2GB RAM, 64GB disk

## Common Issues

### Connection Issues
If SSH fails, verify:
1. Proxmox host is reachable: `ping 192.168.1.100`
2. SSH service is running on Proxmox
3. Credentials are correct
4. sshpass is installed: `apt-get install -y sshpass`

### Permission Errors
The script requires sshpass to be installed:
```bash
apt-get update && apt-get install -y sshpass
```

### Timeout Issues
If checks are slow, increase timeout in script or check network connectivity.

## Advanced Usage

### Manual VM Checks
```bash
# SSH to Proxmox and check specific VM
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@192.168.1.100 "qm status 100"
```

### Manual Container Checks
```bash
# Check specific container
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@192.168.1.100 "pct status 101"
```

### Resource Deep Dive
```bash
# Detailed resource analysis
sshpass -p "$PROXMOX_PASSWORD" ssh -o StrictHostKeyChecking=no root@192.168.1.100 "top -bn1 | head -20"
```

## Output Format

The script outputs emoji-labeled sections for easy scanning:
- 📊 System Info
- 🖥️ Virtual Machines
- 📦 LXC Containers
- 💾 Resource Usage
- 💿 Storage Pools
- 🌐 Network
- ⚙️ Key Services
- ⚠️ Recent Logs

This makes it easy to quickly identify issues in specific areas.
