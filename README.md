# DevOps Claude Toolkit

A comprehensive Claude Code plugin for ad-hoc infrastructure analysis and DevOps automation.

## Installation

### From GitHub Marketplace

1. Add the marketplace to Claude Code:
   ```
   /plugin marketplace add farmakan/devops-claude-toolkit
   ```

2. Install the plugin:
   ```
   /plugin install devops-toolkit@devops-claude-toolkit
   ```

### Manual Installation

```bash
# Clone and install locally
git clone https://github.com/farmakan/devops-claude-toolkit.git
claude --plugin-dir ./devops-claude-toolkit
```

### Verify Installation

```
/devops-toolkit:health-status
```

## Overview

This plugin provides interactive, on-demand infrastructure analysis capabilities:

- **Skills**: Auto-loaded expertise packages for GCP logging, cost analysis, incident response, and ADR generation
- **Slash Commands**: Human-triggered workflows for common DevOps tasks
- **Subagents**: Specialized parallel workers for concurrent data collection and analysis
- **Scripts**: Shell scripts for common infrastructure operations

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed and configured
- Google Cloud SDK (`gcloud`) authenticated
- BigQuery CLI (`bq`) for cost analysis
- `kubectl` configured for Kubernetes clusters (optional)
- `jq` for JSON processing

## Available Commands

All commands are namespaced with `devops-toolkit:` when installed as a plugin.

### Quick Commands (Fast - Haiku model)

| Command | Description |
|---------|-------------|
| `/devops-toolkit:health-status` | Infrastructure health check across all components |
| `/devops-toolkit:cost-check` | Quick cost anomaly detection |

### Analysis Commands (Opus model)

| Command | Description |
|---------|-------------|
| `/devops-toolkit:analyze-logs [service] [time]` | Fetch and analyze GCP Cloud Logging data |
| `/devops-toolkit:incident-investigate <service>` | Deep dive investigation into service issues |
| `/devops-toolkit:parallel-collect [time-range]` | Parallel data collection from all sources |

### Documentation Commands (Opus model)

| Command | Description |
|---------|-------------|
| `/devops-toolkit:generate-adr <topic>` | Generate Architecture Decision Record |

### DevOps Namespaced Commands (Opus model)

| Command | Description |
|---------|-------------|
| `/devops-toolkit:devops:k8s-audit [namespace]` | Kubernetes security and configuration audit |
| `/devops-toolkit:devops:terraform-plan [dir]` | Terraform plan analysis |
| `/devops-toolkit:devops:security-scan [scope]` | Security posture scan |

## Skills (Auto-Loaded)

Skills are automatically activated when the conversation context matches:

- **gcp-logging**: Log analysis, error clustering, timeline construction
- **cost-analysis**: BigQuery billing analysis, anomaly detection
- **incident-response**: Structured investigation workflow
- **adr-generation**: Architecture Decision Record creation

## Subagents

Specialized agents for parallel execution:

- **log-analyzer**: Error pattern detection and clustering (Haiku)
- **metrics-collector**: Resource utilization metrics (Haiku)
- **cost-analyzer**: Cloud spending analysis (Opus)
- **security-auditor**: Security posture analysis (Opus)

## Plugin Structure

```
devops-claude-toolkit/
├── .claude-plugin/
│   ├── plugin.json             # Plugin manifest
│   └── marketplace.json        # Marketplace definition
├── commands/                   # Slash commands
│   ├── analyze-logs.md
│   ├── cost-check.md
│   ├── health-status.md
│   ├── incident-investigate.md
│   ├── generate-adr.md
│   ├── parallel-collect.md
│   └── devops/                 # Namespaced commands
│       ├── k8s-audit.md
│       ├── terraform-plan.md
│       └── security-scan.md
├── agents/                     # Subagent definitions
│   ├── log-analyzer.md
│   ├── metrics-collector.md
│   ├── cost-analyzer.md
│   └── security-auditor.md
├── skills/                     # Auto-loaded skills
│   ├── gcp-logging/
│   ├── cost-analysis/
│   ├── incident-response/
│   └── adr-generation/
├── scripts/                    # Shell scripts
├── docs/
│   ├── decisions/              # ADR output directory
│   └── templates/              # Report templates
├── CLAUDE.md                   # Project context
└── README.md
```

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GCP_PROJECT` | Target GCP project ID | Yes |
| `KUBECONFIG` | Path to kubeconfig file | No (defaults to ~/.kube/config) |
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications | No |

### Recommended Project Settings

Add this to your project's `.claude/settings.json` for optimal permissions:

```json
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Write(docs/**)",
      "Write(reports/**)",
      "Glob(**)",
      "Grep(**)",
      "Bash(gcloud *)",
      "Bash(bq *)",
      "Bash(kubectl get *)",
      "Bash(kubectl describe *)",
      "Bash(kubectl logs *)",
      "Bash(git log *)",
      "Bash(git diff *)",
      "Bash(jq *)"
    ],
    "deny": [
      "Bash(kubectl delete *)",
      "Bash(kubectl apply *)",
      "Bash(gcloud * delete *)",
      "Bash(gcloud * create *)",
      "Bash(bq rm *)"
    ]
  }
}
```

## Analysis Guidelines

**MANDATORY**: All analysis must be grounded in actual code:
- Findings must reference specific files, functions, and line numbers
- Suggestions must include actionable code changes with specific paths
- No abstract recommendations - must be concrete and specific

## Workflow Examples

### Morning Standup Prep
```
/devops-toolkit:health-status
/devops-toolkit:cost-check
```

### Incident Response
```
/devops-toolkit:incident-investigate payment-service
# After resolution:
/devops-toolkit:generate-adr incident-remediation
```

### Weekly Security Review
```
/devops-toolkit:devops:security-scan
/devops-toolkit:devops:k8s-audit
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Related

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [GCP Cloud Logging](https://cloud.google.com/logging)
- [BigQuery Billing Export](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)
