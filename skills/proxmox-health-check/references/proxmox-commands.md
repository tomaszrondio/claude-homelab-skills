# Proxmox Common Commands Reference

## VM Management (qm)

```bash
# List all VMs
qm list

# Show VM config
qm config <vmid>

# Start/stop/restart VM
qm start <vmid>
qm stop <vmid>
qm restart <vmid>

# VM status
qm status <vmid>

# VM resource usage
qm monitor <vmid>
```

## Container Management (pct)

```bash
# List all containers
pct list

# Show container config
pct config <ctid>

# Start/stop/restart container
pct start <ctid>
pct stop <ctid>
pct restart <ctid>

# Container status
pct status <ctid>

# Enter container
pct enter <ctid>
```

## Storage Management

```bash
# List storage
pvesm status

# Storage usage
pvesm list <storage>

# Storage scan
pvesm scan <type> <storage>
```

## System Management

```bash
# Node status
pvesh get /nodes/$(hostname)/status

# Cluster status
pvecm status

# Service status
systemctl status pve-cluster
systemctl status pvedaemon
systemctl status pveproxy
systemctl status pvestatd

# System resources
free -h
df -h
uptime
```

## Network

```bash
# Network interfaces
ip addr
ip link

# Bridge status
brctl show
```

## Logs

```bash
# System logs
journalctl -u pve-cluster
journalctl -u pvedaemon
tail -f /var/log/syslog

# Task logs
pvesh get /cluster/tasks
```

## Backup

```bash
# List backups
pvesh get /nodes/$(hostname)/storage/local/content --content backup

# Create backup
vzdump <vmid>
```
