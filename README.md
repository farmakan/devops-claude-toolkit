# DevOps Claude Toolkit

A comprehensive Claude Code toolkit for ad-hoc infrastructure analysis and DevOps automation.

## Overview

This toolkit provides interactive, on-demand infrastructure analysis capabilities using Claude Code's native extensibility features:

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

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/farmakan/devops-claude-toolkit.git
   cd devops-claude-toolkit
   ```

2. Set your GCP project:
   ```bash
   export GCP_PROJECT=your-project-id
   # Or configure in gcloud
   gcloud config set project your-project-id
   ```

3. Start Claude Code in the toolkit directory:
   ```bash
   claude
   ```

4. Run a health check:
   ```
   /health-status
   ```

## Available Commands

### Quick Commands (Fast)

| Command | Description |
|---------|-------------|
| `/health-status` | Infrastructure health check across all components |
| `/cost-check` | Quick cost anomaly detection |

### Analysis Commands

| Command | Description |
|---------|-------------|
| `/analyze-logs [service] [time]` | Fetch and analyze GCP Cloud Logging data |
| `/incident-investigate <service>` | Deep dive investigation into service issues |
| `/parallel-collect [time-range]` | Parallel data collection from all sources |

### Documentation Commands

| Command | Description |
|---------|-------------|
| `/generate-adr <topic>` | Generate Architecture Decision Record |

### DevOps Namespaced Commands

| Command | Description |
|---------|-------------|
| `/devops:k8s-audit [namespace]` | Kubernetes security and configuration audit |
| `/devops:terraform-plan [dir]` | Terraform plan analysis |
| `/devops:security-scan [scope]` | Security posture scan |

## Skills (Auto-Loaded)

Skills are automatically activated when the conversation context matches:

- **gcp-logging**: Log analysis, error clustering, timeline construction
- **cost-analysis**: BigQuery billing analysis, anomaly detection
- **incident-response**: Structured investigation workflow
- **adr-generation**: Architecture Decision Record creation

## Subagents

Specialized agents for parallel execution:

- **log-analyzer**: Error pattern detection and clustering
- **metrics-collector**: Resource utilization metrics
- **cost-analyzer**: Cloud spending analysis
- **security-auditor**: Security posture analysis

## Scripts

Shell scripts in `./scripts/`:

```bash
# Fetch logs
./scripts/fetch-logs.sh [service-name] [time-range] [severity]

# Health check
./scripts/health-check.sh [environment]

# Cost report
./scripts/cost-report.sh [days-lookback]

# Security audit
./scripts/security-audit.sh [project-id]
```

## Project Structure

```
devops-toolkit/
├── .claude/
│   ├── settings.json           # Permissions and configuration
│   ├── commands/               # Slash commands
│   │   ├── analyze-logs.md
│   │   ├── cost-check.md
│   │   ├── health-status.md
│   │   ├── incident-investigate.md
│   │   ├── generate-adr.md
│   │   ├── parallel-collect.md
│   │   └── devops/             # Namespaced commands
│   │       ├── k8s-audit.md
│   │       ├── terraform-plan.md
│   │       └── security-scan.md
│   ├── agents/                 # Subagent definitions
│   │   ├── log-analyzer.md
│   │   ├── metrics-collector.md
│   │   ├── cost-analyzer.md
│   │   └── security-auditor.md
│   └── skills/                 # Auto-loaded skills
│       ├── gcp-logging/
│       ├── cost-analysis/
│       ├── incident-response/
│       └── adr-generation/
├── scripts/                    # Shell scripts
├── docs/
│   ├── decisions/              # ADR output directory
│   └── templates/              # Report templates
├── reports/                    # Generated reports
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

### Permissions

The toolkit is configured with read-only access to:
- GCP Cloud Logging
- BigQuery billing data
- Kubernetes resources (get, describe, logs)
- Git history

Destructive operations (delete, apply, create) are blocked by default.

## Analysis Guidelines

**MANDATORY**: All analysis must be grounded in actual code:
- Findings must reference specific files, functions, and line numbers
- Suggestions must include actionable code changes with specific paths
- No abstract recommendations - must be concrete and specific

## Output Locations

- **Reports**: `./reports/{date}-{type}.md`
- **ADRs**: `./docs/decisions/ADR-{number}-{topic}.md`
- **Temporary data**: `/tmp/claude-devops-*/`

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
