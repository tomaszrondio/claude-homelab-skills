# Glance Setup - Troubleshooting and Patterns

## Common Patterns

### Pattern 1: Default Setup

User: "Set up Glance dashboard"

Actions:
1. Detect server IP
2. Create `/opt/stacks/glance/config/`
3. Generate compose.yaml (ports 80, 443)
4. Generate config/glance.yml with discovered services
5. Deploy and verify

### Pattern 2: Custom Ports

User: "Set up Glance on port 8080"

Actions:
1. Use ports 8080 and 8443
2. Update all bookmark URLs
3. Deploy

### Pattern 3: Add Service to Existing

User: "Add Portainer to Glance dashboard"

Actions:
1. Read existing `config/glance.yml`
2. Add to bookmarks section:
   ```yaml
   - title: Portainer
     url: http://SERVER_IP:9000
     icon: si:portainer
   ```
3. No restart needed (auto-reloads)

## Troubleshooting

### Config Not Loading

**Symptom**: Warning about config location

**Solution**:
- Verify `config/glance.yml` exists (not `glance.yml` in root)
- Check volume mount: `./config:/app/config`
- Restart container

### Containers Not Showing

**Symptom**: Docker widget empty

**Solution**:
- Verify Docker socket mounted: `/var/run/docker.sock:/var/run/docker.sock:ro`
- Check widget type: `docker-containers` (with hyphen)
- Review logs: `docker logs glance`

### Port Conflicts

**Symptom**: Address already in use

**Solution**:
- Check what's using port: `sudo lsof -i :80`
- Change container external ports (don't modify system)
- Update bookmarks with new ports

## Workflow Details

### 1. Gather Requirements

Determine configuration:
- Stack name (default: `glance`)
- HTTP port (default: `80`)
- HTTPS port (default: `443`)
- Stacks directory (default: `/opt/stacks`)

### 2. Create Directory Structure

Glance v0.7.0+ requires config in subdirectory:

```bash
mkdir -p /opt/stacks/glance/config
```

**Critical**: Config must be in `config/` subdirectory, not root.

### 3. Generate Docker Compose Configuration

Create `compose.yaml`:

```yaml
services:
  glance:
    image: glanceapp/glance:latest
    container_name: glance
    restart: unless-stopped
    ports:
      - "80:8080/tcp"
      - "443:8080/tcp"
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - TZ=UTC
```

**Key points**:
- Internal port is always `8080`
- Mount directory `./config:/app/config` (not individual file)
- Docker socket read-only (`:ro`)

### 4. Create Glance Configuration

Generate `config/glance.yml` with:
- Server settings (port 8080)
- Theme (dark mode default)
- Docker containers widget
- Service bookmarks

See [glance-config.md](glance-config.md) for complete configuration options.

### 5. Discover Existing Services

Scan for running containers to auto-populate bookmarks:

```bash
docker ps --format "{{.Names}}:{{.Ports}}"
```

Common services:
- Dockge (5001)
- TechnitiumDNS (5380)
- Portainer (9000)
- Nginx Proxy Manager (81)

### 6. Handle Port Conflicts

If ports 80/443 are in use:

**Do NOT modify system services** (follows `/opt/claude.md` rule).

Instead:
1. Ask user for alternative ports
2. Update compose.yaml with new ports
3. Update bookmarks with correct URLs

### 7. Deploy Container

```bash
cd /opt/stacks/glance
docker compose up -d
```

Verify:
```bash
docker ps --filter "name=glance"
docker logs glance
```

### 8. Verify Access

Provide user with:
- Access URL: `http://SERVER_IP:PORT`
- Configuration location
- How to add services
