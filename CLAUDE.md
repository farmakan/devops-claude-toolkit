# DevOps Analysis Toolkit

## Project Context
This is an ad-hoc infrastructure analysis toolkit for a cybersecurity startup.
Primary cloud platform is GCP (Cloud Run, GKE, Cloud SQL, BigQuery).
Primary language is Go for custom tooling.

## Environment Variables Required
- GCP_PROJECT: Target GCP project ID
- ANTHROPIC_API_KEY: For Claude API calls (if using SDK directly)
- SLACK_WEBHOOK_URL: Optional, for notifications

## Team Conventions
- All analysis outputs in Markdown format
- Incident reports follow template in docs/templates/incident.md
- ADRs stored in docs/decisions/ with sequential numbering
- Use structured JSON for machine-parseable intermediate outputs
- Security considerations are always paramount

## Available Tools
- `./scripts/`: Team shell scripts (fetch-logs.sh, health-check.sh, etc.)
- `./bin/`: Compiled Go binaries (log-parser, cost-analyzer, etc.)
- gcloud: GCP CLI for logs, monitoring, compute
- bq: BigQuery CLI for cost analysis
- kubectl: Kubernetes CLI for cluster inspection

## Analysis Guidelines
1. **MANDATORY**: All analysis must reference actual code (files, line numbers, functions)
2. **MANDATORY**: Access to code repository (local or GitHub) required before analysis
3. Always check for cost implications of issues found
4. Correlate errors with recent deployments (git log) and specific code changes
5. Consider security implications of any findings
6. Provide actionable recommendations with specific code changes, not abstract observations
7. Include severity assessment (Critical/High/Medium/Low)
8. Reference specific IaC files (Terraform, K8s manifests) when discussing infrastructure

## Output Locations
- Reports: ./reports/{date}-{type}.md
- ADRs: ./docs/decisions/ADR-{number}-{topic}.md
- Temporary data: /tmp/claude-devops-*/
