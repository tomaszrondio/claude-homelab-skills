---
name: setup-glance
description: Set up Glance dashboard with Docker containers monitoring and service bookmarks. Use when deploying Glance, creating dashboard, monitoring Docker containers, setting up container web interface, or user mentions Glance, dashboard setup, or container monitoring.
---

# Setup Glance

Automate deployment of Glance dashboard for Docker container monitoring with proper v0.7.0+ configuration structure.

## Usage

```bash
# Basic deployment (ports 80, 443)
python /opt/.claude/skills/setup-glance/scripts/setup_glance.py

# Custom configuration
python /opt/.claude/skills/setup-glance/scripts/setup_glance.py --name my-dashboard --http-port 8080 --https-port 8443 --stacks-dir /custom/path
```

**Critical**: Config must be in `config/` subdirectory (Glance v0.7.0+ requirement). Config auto-reloads without restart.

## References

- **[glance-config.md](references/glance-config.md)** - Complete configuration options and widget reference
- **[troubleshooting.md](references/troubleshooting.md)** - Workflow details, common patterns, troubleshooting
