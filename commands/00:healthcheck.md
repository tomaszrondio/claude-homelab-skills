---
allowed-tools: Bash(docker:**), Bash(systemctl:**), Bash(/opt/.claude/skills/infrastructure-health-check/**), Skill(proxmox-health-check), Skill(unifi-management), Read(/var/log/**), Bash(ping:**), Bash(ssh:**), Bash(dig:**)
description: Run comprehensive infrastructure health check with AI-powered auto-remediation
---

# Infrastructure Health Check with AI Remediation

This command runs a comprehensive health check and uses AI to diagnose and fix any issues found.

## Workflow:
1. Run health check script to gather diagnostics
2. Display output to user
3. AI analyzes results and identifies issues
4. AI attempts intelligent fixes based on the specific problems
5. AI reports back with outcomes

## Execute:

First, run the health check script:

!`bash /opt/.claude/skills/infrastructure-health-check/scripts/health_check.sh`

After the script runs, I will analyze the output. If any issues are found (warnings or critical alerts), I will:

1. **Identify the root causes** from the diagnostics
2. **Determine the best fix strategy** based on the specific issue
3. **Execute the fixes** using appropriate commands
4. **Verify the fixes worked** by re-testing
5. **Report detailed outcomes** to you

Common issues I can auto-fix:
- Stopped Docker containers → restart them
- systemd-resolved blocking DNS → stop and disable it
- Failed services → restart and verify
- Network connectivity issues → diagnose and suggest fixes
- SSH/access issues → test connectivity and provide guidance
