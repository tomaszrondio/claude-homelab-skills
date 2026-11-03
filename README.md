# Claude Homelab Skills

Claude Code agent skills and a slash command for monitoring and operating a self-hosted homelab: Proxmox VE, UniFi networking, Docker services, and AdGuard Home DNS.

## What it is

This repository is the version-controlled `.claude/` directory from my homelab server. It packages operational knowledge as [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills): each skill has a `SKILL.md` that tells the agent *when* to use it and *how*, plus deterministic Bash/Python scripts that do the actual data collection. That way the agent doesn't improvise shell commands. It runs tested scripts and reasons over their output.

The `/00:healthcheck` command ties it together. It runs a full infrastructure health check, then has Claude analyse the report, apply targeted fixes (for example restarting a stopped container), re-test, and report the outcome.

Skill descriptions include English and Polish trigger phrases (e.g. "check proxmox" / "sprawdź proxmoxa").

> **Note:** This is a personal setup, not a general-purpose package. Paths (`/opt/.claude`, `/opt/backups`, `/opt/stacks`), container names and some LAN addresses are specific to my environment and need adjusting before reuse.

## Components

### Skills

| Skill | What it does |
|---|---|
| `proxmox-health-check` | Connects to a Proxmox VE node over SSH and reports system info, VMs (`qm list`), LXC containers (`pct list`), memory/disk, storage pools, network interfaces, `pve-*` service status, and recent syslog errors. |
| `unifi-management` | Python wrapper around the UniFi Controller API (API key or username/password via `pyunifi`, UniFi OS and classic controllers). CLI scripts for network health, client listing (filter wired/wireless, sort by name/IP/bandwidth/uptime), device listing (APs, switches, gateways), and configuration backup. The client module also exposes block/unblock/reconnect client and restart/upgrade device methods for programmatic use. |
| `setup-glance` | Generates a Docker Compose stack and `glance.yml` for the [Glance](https://github.com/glanceapp/glance) dashboard (v0.7.0+ layout), with a Docker containers widget and bookmarks auto-discovered from running containers. Ports, stack name and stacks directory are configurable. |
| `skill-creator` | Guidance and helper scripts (`init_skill.py`, `quick_validate.py`, `package_skill.py`) for authoring new skills. Third-party, Apache 2.0 licensed (see `skills/skill-creator/LICENSE.txt`). |

### Infrastructure health check (scripts)

`skills/infrastructure-health-check/` is a modular Bash health-check suite used by the slash command. It has no `SKILL.md`; it is invoked directly by `/00:healthcheck`.

- `health_check.sh` is the orchestrator. It runs every check, renders a boxed terminal report, aggregates alerts, and exits `0`/`1`/`2` (OK / warning / critical).
- `check_host.sh` covers CPU, memory, disk (`/` and `/opt`), load and uptime against thresholds.
- `check_docker.sh` covers container state, uptime, CPU/memory per container, critical-service detection, and suggested fixes.
- `check_dns.sh` covers AdGuard Home container state, DNS resolution, block-rate stats, and `systemd-resolved` port-53 conflict diagnosis.
- `check_backups.sh` covers UniFi backup age, Obsidian vault freshness, and uncommitted changes in the `.claude` git repo.
- `check_connectivity.sh` covers internet reachability, external DNS, and GitHub API reachability.
- It also calls the UniFi and Proxmox skills for network and virtualization status.
- `config/thresholds.json` holds the warning/critical thresholds.

### Slash command

| Command | What it does |
|---|---|
| `/00:healthcheck` | Runs `health_check.sh`, then Claude diagnoses warnings/critical alerts, applies fixes within a restricted `allowed-tools` list (docker, systemctl, ping, ssh, dig, the two skills), verifies them, and reports results. |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- Linux host with Bash, Docker, `dig`, `curl`, `jq`, and GNU `grep` (`-P`)
- `sshpass` (Proxmox check)
- Python 3 with `requests` and `pyunifi` (UniFi skill)
- Access to a Proxmox VE node and a UniFi controller (optional; those sections report "Not configured" if missing)

## Setup

```bash
# Clone into the Claude Code config directory used by the scripts
git clone https://github.com/tomaszrondio/claude-homelab-skills.git /opt/.claude

# Create local credentials (git-ignored)
cp /opt/.claude/config.json.example /opt/.claude/config.json
# edit config.json: Proxmox host/user/password, UniFi host/API key/site
```

Then adjust environment-specific values (LAN IPs, critical container names, backup paths) in the scripts and `config/thresholds.json`.

## Usage

In Claude Code, ask in natural language. Skills trigger on their descriptions:

- "Check Proxmox status"
- "Show connected WiFi clients sorted by bandwidth"
- "Back up the UniFi config"
- "Set up a Glance dashboard on port 8080"

Or run the full check with automated remediation:

```
/00:healthcheck
```

Scripts can also be run directly, e.g.:

```bash
bash /opt/.claude/skills/infrastructure-health-check/scripts/health_check.sh
python3 /opt/.claude/skills/unifi-management/scripts/list_clients.py --wireless --sort bandwidth
```

## Repository structure

```
.
├── commands/
│   └── 00:healthcheck.md              # slash command: health check + AI remediation
├── skills/
│   ├── infrastructure-health-check/
│   │   ├── config/thresholds.json
│   │   └── scripts/                   # orchestrator, per-component checks, utils/
│   ├── proxmox-health-check/          # SKILL.md, scripts/, references/
│   ├── unifi-management/              # SKILL.md, scripts/ (API client + CLIs), references/
│   ├── setup-glance/                  # SKILL.md, scripts/, assets/ (templates), references/
│   └── skill-creator/                 # third-party skill-authoring guide (Apache 2.0)
├── config.json.example                # credentials template (real config.json is git-ignored)
└── .gitignore
```

## Design notes

- **Progressive disclosure:** `SKILL.md` files stay short. Detailed command references and troubleshooting live in `references/` and are loaded only when needed.
- **Deterministic scripts and AI reasoning:** scripts gather facts and emit structured output with exit codes. The agent interprets the results and decides on remediation.
- **Scoped permissions:** the slash command limits which tools the agent may use during auto-remediation.
- **Secrets out of git:** credentials live in a git-ignored `config.json`, and only a template is committed.
