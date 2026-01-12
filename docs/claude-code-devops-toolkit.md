# Claude Code DevOps Toolkit - Implementation Specification

> **Document Purpose**: This document specifies a local Claude Code toolkit for ad-hoc DevOps analysis. It is designed to be read by Claude Code to scaffold skills, commands, subagents, and supporting configurations.

---

## Executive Summary

This toolkit provides interactive, on-demand infrastructure analysis capabilities using Claude Code's native extensibility features:

- **Skills**: Auto-loaded expertise packages (model-invoked when context matches)
- **Slash Commands**: Human-triggered workflows (`/analyze-logs`, `/cost-check`)
- **Subagents**: Isolated parallel workers for concurrent data collection
- **Integration**: Direct execution of existing Go tools and shell scripts

**Complement to**: The scheduled daily automation tool (separate system)

---

## Mandatory Requirements: Code-Based Analysis

> **CRITICAL**: All analysis performed by this toolkit MUST be grounded in actual code. Abstract recommendations without code context are not permitted.

### Code Repository Access (REQUIRED)

Before any analysis can begin, the toolkit MUST have access to the relevant code repository through one of these methods:

1. **Local Files**: The codebase must be available in the local filesystem
2. **GitHub Integration**: Use `gh` CLI to access repository files and PRs
3. **Git Clone**: Repository must be cloned locally for analysis

### Analysis Principles

1. **All findings must reference specific code**
   - Error analysis must trace back to specific files, functions, and line numbers
   - Cost anomalies must correlate to specific services defined in infrastructure code
   - Performance issues must map to actual code paths

2. **All suggestions must be actionable code changes**
   - Recommendations must include specific file paths to modify
   - When suggesting fixes, provide concrete code snippets
   - Reference existing code patterns in the repository

3. **No abstract recommendations**
   - ❌ "Consider implementing caching" (too vague)
   - ✅ "Add Redis caching in `src/services/api.go:142` using the existing `cache.Client` from `pkg/cache/redis.go`" (specific)

4. **Validation against codebase**
   - Before suggesting architectural changes, verify existing patterns
   - Cross-reference with IaC files (Terraform, Kubernetes manifests)
   - Check for existing implementations before proposing new ones

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Claude Code DevOps Toolkit                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Human Trigger                                                              │
│       │                                                                     │
│       ▼                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Slash Commands (Explicit)                         │   │
│  │  /analyze-logs  /cost-check  /health-status  /incident-investigate  │   │
│  └────────────────────────────────┬────────────────────────────────────┘   │
│                                   │                                         │
│                                   ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      Skills (Auto-Loaded)                            │   │
│  │   gcp-logging │ cost-analysis │ incident-response │ adr-generation  │   │
│  └────────────────────────────────┬────────────────────────────────────┘   │
│                                   │                                         │
│                                   ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   Subagents (Parallel Workers)                       │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌────────────┐  │   │
│  │  │ log-analyzer │ │   metrics-   │ │    cost-     │ │  security- │  │   │
│  │  │              │ │  collector   │ │   analyzer   │ │   auditor  │  │   │
│  │  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └─────┬──────┘  │   │
│  └─────────┼────────────────┼────────────────┼───────────────┼─────────┘   │
│            │                │                │               │             │
│            └────────────────┴────────┬───────┴───────────────┘             │
│                                      ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Tool Execution Layer                              │   │
│  │   Bash(gcloud) │ Bash(bq) │ Bash(kubectl) │ Bash(./scripts/*)       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                      │
│                                      ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         Output Generation                            │   │
│  │        Markdown Reports │ ADRs │ Slack Notifications                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
devops-toolkit/
├── .claude/
│   ├── settings.json               # Permissions, MCP servers
│   ├── commands/                   # Slash commands (human-triggered)
│   │   ├── analyze-logs.md
│   │   ├── cost-check.md
│   │   ├── health-status.md
│   │   ├── incident-investigate.md
│   │   ├── generate-adr.md
│   │   ├── parallel-collect.md
│   │   └── devops/                 # Namespaced: /devops:k8s-audit
│   │       ├── k8s-audit.md
│   │       ├── terraform-plan.md
│   │       └── security-scan.md
│   ├── agents/                     # Subagent definitions
│   │   ├── log-analyzer.md
│   │   ├── metrics-collector.md
│   │   ├── cost-analyzer.md
│   │   └── security-auditor.md
│   └── skills/                     # Skills (model-invoked)
│       ├── gcp-logging/
│       │   ├── SKILL.md
│       │   └── queries.md
│       ├── cost-analysis/
│       │   ├── SKILL.md
│       │   └── bigquery-templates.sql
│       ├── incident-response/
│       │   └── SKILL.md
│       └── adr-generation/
│           ├── SKILL.md
│           └── template.md
├── scripts/                        # Team shell scripts
│   ├── fetch-logs.sh
│   ├── health-check.sh
│   ├── cost-report.sh
│   └── security-audit.sh
├── bin/                            # Compiled Go tools
│   ├── log-parser
│   ├── cost-analyzer
│   └── metrics-aggregator
├── docs/
│   ├── decisions/                  # ADR output directory
│   │   └── .gitkeep
│   └── templates/
│       ├── incident.md
│       └── adr.md
├── reports/                        # Generated analysis reports
│   └── .gitkeep
├── CLAUDE.md                       # Root project context
└── README.md
```

---

## Configuration Files

### 1. Root CLAUDE.md

**Location**: `devops-toolkit/CLAUDE.md`

```markdown
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
```

### 2. Settings Configuration

**Location**: `.claude/settings.json`

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
      "Bash(./scripts/*)",
      "Bash(./bin/*)",
      "Bash(go run cmd/*.go)",
      "Bash(git log *)",
      "Bash(git diff *)",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(jq *)",
      "Bash(grep *)",
      "Bash(awk *)",
      "Bash(sort *)",
      "Bash(uniq *)",
      "Bash(wc *)",
      "Bash(date *)",
      "Bash(mkdir -p *)",
      "Bash(rm /tmp/claude-devops-*)"
    ],
    "deny": [
      "Bash(kubectl delete *)",
      "Bash(kubectl apply *)",
      "Bash(kubectl create *)",
      "Bash(kubectl patch *)",
      "Bash(gcloud * delete *)",
      "Bash(gcloud * create *)",
      "Bash(bq rm *)",
      "Bash(rm -rf /*)",
      "Bash(rm -rf ~/*)",
      "Bash(> /etc/*)",
      "Bash(chmod 777 *)",
      "Bash(curl * | bash)",
      "Bash(wget * | bash)"
    ]
  },
  "env": {
    "GCP_PROJECT": "",
    "KUBECONFIG": "~/.kube/config"
  },
  "model": {
    "default": "opus",
    "fast": "haiku",
    "deep": "opus"
  }
}
```

---

## Skills Implementation

### Skill 1: GCP Logging

**Location**: `.claude/skills/gcp-logging/SKILL.md`

```markdown
---
name: gcp-logging
description: Fetch and analyze GCP Cloud Logging data. Automatically invoked when analyzing logs, investigating errors, debugging latency issues, or examining service behavior in GCP.
allowed-tools:
  - Bash(gcloud logging *)
  - Bash(jq *)
  - Read
  - Grep
---

# GCP Cloud Logging Analysis Skill

## When to Use
This skill activates when the conversation involves:
- Error log analysis
- Service debugging
- Latency investigation
- Audit log review
- Request tracing across services

## Quick Reference Commands

### Fetch recent errors (last 1 hour)
```bash
gcloud logging read \
  'severity>=ERROR AND timestamp>="'"$(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')"'"' \
  --project=${GCP_PROJECT:-$(gcloud config get-value project)} \
  --format=json \
  --limit=100
```

### Fetch errors for specific service
```bash
SERVICE_NAME="$1"
gcloud logging read \
  "resource.labels.service_name=\"${SERVICE_NAME}\" AND severity>=ERROR" \
  --project=${GCP_PROJECT:-$(gcloud config get-value project)} \
  --format=json \
  --limit=200
```

### Fetch by trace ID
```bash
TRACE_ID="$1"
gcloud logging read \
  "trace=\"projects/${GCP_PROJECT}/traces/${TRACE_ID}\"" \
  --format=json \
  --limit=500
```

### Fetch audit logs
```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com"' \
  --project=${GCP_PROJECT:-$(gcloud config get-value project)} \
  --format=json \
  --limit=50
```

## Analysis Methodology

### Step 1: Error Clustering
Group errors by message signature:
```bash
gcloud logging read 'severity>=ERROR' --format=json --limit=500 | \
  jq -r '.[] | .jsonPayload.message // .textPayload // "unknown"' | \
  sort | uniq -c | sort -rn | head -20
```

### Step 2: Timeline Construction
Sort by timestamp to identify cascade patterns:
```bash
gcloud logging read 'severity>=ERROR' --format=json --limit=200 | \
  jq -r '.[] | "\(.timestamp) \(.resource.labels.service_name // "unknown") \(.severity)"' | \
  sort
```

### Step 3: Service Correlation
For each error, check if related services have corresponding logs.

### Step 4: Root Cause Hypothesis
Based on patterns, form hypothesis about root cause.

## Output Format

Always structure findings as:

```markdown
## Log Analysis Summary

**Time Range**: [start] to [end]
**Services Analyzed**: [list]
**Total Errors Found**: [count]

### Error Clusters

| Rank | Count | Error Signature | First Seen | Services Affected |
|------|-------|-----------------|------------|-------------------|
| 1    | 45    | "Connection refused..." | 14:32:01 | api-gateway, auth |

### Timeline of Events
1. **14:30:00** - First error appears in auth service
2. **14:32:00** - Cascade to api-gateway
3. ...

### Root Cause Hypothesis
[Description based on evidence]

### Recommended Actions
1. [Action with priority]
2. ...
```

## Advanced Query Patterns

See [queries.md](queries.md) for:
- Custom log filters by resource type
- Aggregation queries
- Log-based metrics queries
- Export to BigQuery patterns
```

**Location**: `.claude/skills/gcp-logging/queries.md`

```markdown
# Advanced GCP Logging Queries

## Filter by Resource Type

### Cloud Run
```
resource.type="cloud_run_revision"
resource.labels.service_name="SERVICE"
resource.labels.location="REGION"
```

### GKE
```
resource.type="k8s_container"
resource.labels.cluster_name="CLUSTER"
resource.labels.namespace_name="NAMESPACE"
resource.labels.pod_name:"POD_PREFIX"
```

### Cloud SQL
```
resource.type="cloudsql_database"
resource.labels.database_id="PROJECT:INSTANCE"
```

### Cloud Functions
```
resource.type="cloud_function"
resource.labels.function_name="FUNCTION"
```

## Complex Filters

### Errors excluding known noise
```
severity>=ERROR
AND NOT textPayload:"health check"
AND NOT textPayload:"readiness probe"
AND NOT jsonPayload.message:"expected disconnect"
```

### Slow requests (latency > 1s)
```
httpRequest.latency>"1s"
AND httpRequest.status>=200
AND httpRequest.status<300
```

### Failed authentication
```
protoPayload.authenticationInfo.principalEmail:*
AND protoPayload.status.code!=0
```

## Aggregation Patterns

### Error rate per minute
```bash
gcloud logging read 'severity>=ERROR' --format=json | \
  jq -r '.[] | .timestamp[:16]' | \
  sort | uniq -c
```

### Top error sources
```bash
gcloud logging read 'severity>=ERROR' --format=json | \
  jq -r '.[] | .resource.labels.service_name // .resource.type' | \
  sort | uniq -c | sort -rn
```
```

---

### Skill 2: Cost Analysis

**Location**: `.claude/skills/cost-analysis/SKILL.md`

```markdown
---
name: cost-analysis
description: Analyze GCP costs using BigQuery billing export. Automatically invoked for cost anomaly detection, budget tracking, spend optimization, or resource efficiency analysis.
allowed-tools:
  - Bash(bq *)
  - Bash(gcloud billing *)
  - Read
---

# GCP Cost Analysis Skill

## Prerequisites
- BigQuery billing export enabled
- Dataset: `${GCP_PROJECT}.billing_export`
- Table pattern: `gcp_billing_export_v1_*`

## Quick Analysis Commands

### Today's cost by service
```bash
bq query --format=json --use_legacy_sql=false "
SELECT 
  service.description AS service,
  ROUND(SUM(cost), 2) AS cost_today,
  ROUND(SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) c), 0)), 2) AS credits
FROM \`${GCP_PROJECT:-$(gcloud config get-value project)}.billing_export.gcp_billing_export_v1_*\`
WHERE DATE(usage_start_time) = CURRENT_DATE()
GROUP BY 1
ORDER BY 2 DESC
LIMIT 20"
```

### 7-day cost trend
```bash
bq query --format=json --use_legacy_sql=false "
SELECT 
  DATE(usage_start_time) AS date,
  ROUND(SUM(cost), 2) AS daily_cost
FROM \`${GCP_PROJECT}.billing_export.gcp_billing_export_v1_*\`
WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY 1
ORDER BY 1 DESC"
```

### Cost anomaly detection
```bash
bq query --format=json --use_legacy_sql=false "
WITH daily_costs AS (
  SELECT 
    DATE(usage_start_time) AS date,
    service.description AS service,
    SUM(cost) AS cost
  FROM \`${GCP_PROJECT}.billing_export.gcp_billing_export_v1_*\`
  WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY)
  GROUP BY 1, 2
),
with_baseline AS (
  SELECT 
    *,
    AVG(cost) OVER (PARTITION BY service ORDER BY date ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) AS baseline
  FROM daily_costs
)
SELECT 
  date, service, 
  ROUND(cost, 2) AS cost,
  ROUND(baseline, 2) AS baseline_7d,
  ROUND((cost - baseline) / NULLIF(baseline, 0) * 100, 1) AS pct_change
FROM with_baseline
WHERE date = CURRENT_DATE()
  AND cost > baseline * 1.5
  AND baseline > 1
ORDER BY cost DESC"
```

## Analysis Methodology

### Step 1: Identify Top Spenders
Query top 10 services by cost for the analysis period.

### Step 2: Calculate Baselines
Compute 7-day and 30-day rolling averages per service.

### Step 3: Detect Anomalies
Flag services exceeding thresholds:
- Minor: 20-50% above baseline
- Major: 50-100% above baseline  
- Critical: >100% above baseline OR any single day >$1000 unexpected

### Step 4: SKU Analysis
For flagged services, drill into SKU-level to identify cause.

### Step 5: Recommendations
Suggest specific optimizations based on findings.

## Thresholds Configuration

| Severity | Threshold | Action |
|----------|-----------|--------|
| Info | <20% above baseline | Log for tracking |
| Warning | 20-50% above | Review within 24h |
| Major | 50-100% above | Review immediately |
| Critical | >100% above OR >$1000 unexpected | Alert + investigate |

## Output Format

```markdown
## Cost Analysis Report

**Period**: [start] to [end]
**Total Spend**: $X,XXX.XX
**vs 7-day Average**: +/-XX%

### Top Services by Spend
| Service | Today | 7d Avg | Change |
|---------|-------|--------|--------|
| Compute Engine | $XXX | $XXX | +XX% |

### Anomalies Detected
🚨 **Critical**: [service] - $XXX (+XXX%)
⚠️ **Warning**: [service] - $XXX (+XX%)

### Optimization Recommendations
1. [Specific recommendation with estimated savings]
```

## Additional Templates
See [bigquery-templates.sql](bigquery-templates.sql) for more queries.
```

---

### Skill 3: Incident Response

**Location**: `.claude/skills/incident-response/SKILL.md`

```markdown
---
name: incident-response
description: Structured incident investigation workflow. Automatically invoked when investigating production issues, outages, service degradation, or customer-impacting problems.
allowed-tools:
  - Bash(gcloud *)
  - Bash(kubectl *)
  - Bash(./scripts/*)
  - Read
  - Grep
  - Glob
---

# Incident Response Skill

## Investigation Framework

### Phase 1: Rapid Triage (Target: 2 minutes)

**Objective**: Understand scope and severity immediately.

```bash
# 1. Check overall service status
./scripts/health-check.sh ${SERVICE:-all}

# 2. Recent deployments (correlation check)
git log --oneline --since="4 hours ago" --all

# 3. Quick error count
gcloud logging read "severity>=ERROR" --format=json --limit=10 | \
  jq -r 'length'
```

**Output**: Initial severity assessment (SEV1/SEV2/SEV3/SEV4)

### Phase 2: Data Collection (Target: 5 minutes)

**Objective**: Gather all relevant data in parallel.

```bash
# Create collection directory
COLLECT_DIR="/tmp/claude-devops-$(date +%s)"
mkdir -p ${COLLECT_DIR}

# Parallel collection
{
  gcloud logging read "severity>=ERROR" --format=json --limit=200 \
    > ${COLLECT_DIR}/errors.json 2>&1 &
  
  gcloud logging read "resource.labels.service_name=\"${SERVICE}\"" \
    --format=json --limit=500 \
    > ${COLLECT_DIR}/service_logs.json 2>&1 &
  
  kubectl get pods -A -o json \
    > ${COLLECT_DIR}/pods.json 2>&1 &
  
  kubectl get events -A --sort-by='.lastTimestamp' -o json \
    > ${COLLECT_DIR}/events.json 2>&1 &
  
  wait
}

echo "Data collected in ${COLLECT_DIR}"
ls -la ${COLLECT_DIR}
```

### Phase 3: Analysis (Target: 10 minutes)

**Objective**: Identify root cause from collected data.

Analysis Checklist:
1. [ ] Parse error logs - identify unique error signatures
2. [ ] Build timeline - when did issues start?
3. [ ] Check deployments - correlate with git history AND identify specific code changes
4. [ ] **Trace to code** - map errors to specific files, functions, and line numbers
5. [ ] Review K8s events - pod restarts, OOM kills, scheduling issues
6. [ ] Check external dependencies - database, APIs, third-party services
7. [ ] Resource analysis - CPU, memory, disk, connections
8. [ ] **Verify code access** - ensure repository is available for deep analysis

### Phase 4: Mitigation

**Objective**: Stop the bleeding.

Common mitigations (read-only investigator should RECOMMEND, not execute):
- Rollback deployment
- Scale up resources
- Enable circuit breaker
- Redirect traffic
- Disable problematic feature flag

### Phase 5: Documentation

**Objective**: Create incident record.

```markdown
# Incident Report: [Brief Title]

## Summary
One paragraph description of what happened.

## Timeline
| Time (UTC) | Event |
|------------|-------|
| HH:MM | First alert/error detected |
| HH:MM | Investigation started |
| HH:MM | Root cause identified |
| HH:MM | Mitigation applied |
| HH:MM | Service restored |

## Impact
- **Duration**: X hours Y minutes
- **Users Affected**: Estimated N users
- **Services Affected**: [list]
- **Revenue Impact**: $X (if applicable)

## Root Cause
Detailed technical explanation of what went wrong.

## Resolution
What was done to fix the immediate issue.

## Action Items
| Item | Owner | Due Date | Status |
|------|-------|----------|--------|
| [Preventive measure] | [Name] | [Date] | Open |

## Lessons Learned
What we learned and how to prevent recurrence.
```

## Severity Definitions

| Level | Criteria | Response Time |
|-------|----------|---------------|
| SEV1 | Complete outage, all users affected | Immediate, all hands |
| SEV2 | Major feature broken, many users affected | <15 minutes |
| SEV3 | Minor feature broken, some users affected | <1 hour |
| SEV4 | Degraded performance, minimal impact | <24 hours |

## Escalation Contacts
(Configure in your CLAUDE.md)
```

---

### Skill 4: ADR Generation

**Location**: `.claude/skills/adr-generation/SKILL.md`

```markdown
---
name: adr-generation
description: Generate Architecture Decision Records from analysis findings. Invoked when documenting technical decisions, recording architectural choices, or creating decision records.
allowed-tools:
  - Read
  - Write(docs/**)
  - Glob
---

# ADR Generation Skill

## Purpose
Create standardized Architecture Decision Records to document significant technical decisions made during or after analysis.

## ADR Numbering
```bash
# Get next ADR number
NEXT_NUM=$(ls docs/decisions/ADR-*.md 2>/dev/null | wc -l | awk '{print $1 + 1}')
printf "ADR-%03d" ${NEXT_NUM}
```

## Standard Template

```markdown
# ADR-{NUMBER}: {Title}

## Status
{Proposed | Accepted | Deprecated | Superseded by ADR-XXX}

## Date
{YYYY-MM-DD}

## Context
What is the issue that we're seeing that motivates this decision or change?

## Decision
What is the change that we're proposing and/or doing?

## Consequences

### Positive
- What becomes easier?
- What problems does this solve?

### Negative  
- What becomes harder?
- What new problems might this create?

### Neutral
- What other effects does this have?

## Alternatives Considered

### Alternative 1: {Name}
- **Description**: What was this option?
- **Pros**: Why might we choose this?
- **Cons**: Why did we not choose this?

### Alternative 2: {Name}
...

## References
- [Link to relevant documentation]
- [Link to analysis that led to this decision]
```

## Generation Process

### Step 1: Identify the Decision
Extract from conversation:
- What technical choice was made?
- What problem does it solve?
- What triggered this decision?

### Step 2: Document Context
Pull evidence from the analysis:
- Error patterns found
- Performance data
- Cost implications
- Security considerations

### Step 3: Record Alternatives
Even if not explicitly discussed, document:
- Status quo (do nothing)
- Obvious alternatives
- Why they were rejected

### Step 4: List Consequences
Be specific and measurable where possible:
- "Reduces p99 latency from 500ms to 200ms"
- "Increases monthly cost by ~$500"
- "Requires 2 weeks of migration effort"

### Step 5: Write and Save
Save to: `docs/decisions/ADR-{number}-{slug}.md`

Slug format: lowercase, hyphens, no special chars
Example: `ADR-015-migrate-to-cloud-sql.md`

## Common Decision Categories

- **Infrastructure**: Cloud provider, regions, scaling approach
- **Architecture**: Microservices, event-driven, caching strategy
- **Technology**: Language, framework, database, queue
- **Security**: Authentication, encryption, access control
- **Operations**: Monitoring, alerting, deployment strategy
- **Cost**: Resource optimization, reserved capacity
```

---

## Slash Commands Implementation

### Command 1: /analyze-logs

**Location**: `.claude/commands/analyze-logs.md`

```markdown
---
description: Fetch and analyze recent error logs from GCP Cloud Logging
allowed-tools:
  - Bash(gcloud logging *)
  - Bash(jq *)
  - Read
  - Grep
argument-hint: [service-name] [time-range]
model: opus
---

# Log Analysis Command

## Arguments
- `$1`: Service name (optional, default: all services)
- `$2`: Time range (optional, default: 1h)

## Environment
- **GCP Project**: !`gcloud config get-value project 2>/dev/null`
- **Current Time**: !`date -u '+%Y-%m-%d %H:%M:%S UTC'`

## Data Collection

### Recent Errors (All Services)
```
!`gcloud logging read "severity>=ERROR AND timestamp>=\"$(date -u -d '${2:-1 hour} ago' '+%Y-%m-%dT%H:%M:%SZ')\"" --format=json --limit=100 2>/dev/null | head -c 12000 || echo "[]"`
```

### Service-Specific Logs (if service specified)
```
!`[ -n "$1" ] && gcloud logging read "resource.labels.service_name=\"$1\" AND timestamp>=\"$(date -u -d '${2:-1 hour} ago' '+%Y-%m-%dT%H:%M:%SZ')\"" --format=json --limit=200 2>/dev/null | head -c 12000 || echo "No service filter applied"`
```

### Error Count by Service
```
!`gcloud logging read "severity>=ERROR" --format=json --limit=500 2>/dev/null | jq -r '.[].resource.labels.service_name // "unknown"' | sort | uniq -c | sort -rn | head -10`
```

## Your Analysis Task

Using the gcp-logging skill, analyze the collected data:

1. **Cluster errors** by message signature - what are the unique error types?
2. **Build timeline** - when did errors start, any patterns?
3. **Identify root causes** - what's actually failing and why?
4. **Assess impact** - which services/users are affected?
5. **Recommend fixes** - specific, actionable next steps

## Output Requirements

Produce a structured report:
- Executive summary (2-3 sentences)
- Error clusters table with counts
- Timeline of significant events
- Root cause hypothesis with **specific code references** (file:line)
- Prioritized recommendations with **concrete code changes**

**MANDATORY**: All suggestions must reference specific code locations:
- Include file paths and line numbers for problematic code
- Provide code snippets for suggested fixes
- Reference existing patterns in the codebase when proposing solutions
- If stack traces are available, trace to the root source file
```

### Command 2: /cost-check

**Location**: `.claude/commands/cost-check.md`

```markdown
---
description: Quick cost anomaly detection comparing current spend against baseline
allowed-tools:
  - Bash(bq *)
  - Bash(gcloud *)
  - Read
argument-hint: [days-lookback]
model: haiku
---

# Cost Anomaly Check

## Environment
- **GCP Project**: !`gcloud config get-value project 2>/dev/null`
- **Analysis Date**: !`date -u '+%Y-%m-%d'`

## Current Day Spend

```
!`bq query --format=json --use_legacy_sql=false "SELECT service.description as service, ROUND(SUM(cost),2) as cost_today FROM \\\`$(gcloud config get-value project).billing_export.gcp_billing_export_v1_*\\\` WHERE DATE(usage_start_time) = CURRENT_DATE() GROUP BY 1 HAVING cost_today > 0.01 ORDER BY 2 DESC LIMIT 15" 2>/dev/null || echo "Query failed - check billing export setup"`
```

## 7-Day Baseline

```
!`bq query --format=json --use_legacy_sql=false "SELECT service.description as service, ROUND(AVG(daily_cost),2) as avg_7d FROM (SELECT service.description, DATE(usage_start_time) as d, SUM(cost) as daily_cost FROM \\\`$(gcloud config get-value project).billing_export.gcp_billing_export_v1_*\\\` WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY) AND usage_start_time < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY) GROUP BY 1,2) GROUP BY 1 HAVING avg_7d > 0.01 ORDER BY 2 DESC LIMIT 15" 2>/dev/null || echo "Baseline query failed"`
```

## Quick Analysis Required

1. Compare today's spend against 7-day average for each service
2. Calculate percentage change
3. Flag anomalies using thresholds:
   - ⚠️ Warning: 20-50% above baseline
   - 🚨 Alert: >50% above baseline
4. Check for new services not in baseline

## Output Format

Provide a quick status summary:

```
## Cost Status: [✅ Normal | ⚠️ Elevated | 🚨 Anomaly Detected]

**Today's Total**: $XXX.XX
**vs 7-day Average**: +/-XX%

### Flagged Services
| Service | Today | Baseline | Change | Status |
|---------|-------|----------|--------|--------|

### New Services (not in baseline)
- [list if any]

### Recommendation
[One sentence on whether action needed]
```
```

### Command 3: /health-status

**Location**: `.claude/commands/health-status.md`

```markdown
---
description: Quick infrastructure health check across all components
allowed-tools:
  - Bash(gcloud *)
  - Bash(kubectl *)
  - Bash(./scripts/*)
  - Read
argument-hint: [environment]
model: haiku
---

# Infrastructure Health Check

## Environment
- **Target**: $ARGUMENTS (default: production)
- **Timestamp**: !`date -u '+%Y-%m-%d %H:%M:%S UTC'`

## Cloud Run Services

```
!`gcloud run services list --format="table(SERVICE,REGION,URL:label=URL,LAST_DEPLOYED_BY:label='DEPLOYED BY',LAST_DEPLOYED_AT:label='DEPLOYED AT')" 2>/dev/null | head -15 || echo "No Cloud Run services or insufficient permissions"`
```

## Kubernetes Status

### Unhealthy Pods
```
!`kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | head -20 || echo "No K8s context available or all pods healthy"`
```

### Recent Events (Warnings)
```
!`kubectl get events -A --field-selector=type=Warning --sort-by='.lastTimestamp' 2>/dev/null | tail -10 || echo "No warning events"`
```

## Recent Errors (Last 15 min)

```
!`gcloud logging read "severity>=ERROR AND timestamp>=\"$(date -u -d '15 minutes ago' '+%Y-%m-%dT%H:%M:%SZ')\"" --format=json --limit=20 2>/dev/null | jq -r '.[].resource.labels.service_name // "unknown"' | sort | uniq -c | sort -rn || echo "No recent errors"`
```

## Custom Health Checks

```
!`[ -f ./scripts/health-check.sh ] && ./scripts/health-check.sh ${ARGUMENTS:-production} 2>/dev/null || echo "No custom health check script found"`
```

## Output Format

Provide traffic-light summary:

```
## Infrastructure Health: [🟢 Healthy | 🟡 Degraded | 🔴 Critical]

### Component Status
| Component | Status | Details |
|-----------|--------|---------|
| Cloud Run | 🟢/🟡/🔴 | X services running |
| Kubernetes | 🟢/🟡/🔴 | X/Y pods healthy |
| Error Rate | 🟢/🟡/🔴 | X errors in last 15m |

### Issues Requiring Attention
- [List any 🟡 or 🔴 items with brief description]

### Recent Changes
- [Any deployments in last 4 hours]
```
```

### Command 4: /incident-investigate

**Location**: `.claude/commands/incident-investigate.md`

```markdown
---
description: Deep dive investigation into specific service issues
allowed-tools:
  - Bash(gcloud *)
  - Bash(kubectl *)
  - Bash(./scripts/*)
  - Bash(git *)
  - Bash(jq *)
  - Read
  - Grep
  - Glob
argument-hint: <service-name>
model: opus
---

# Incident Investigation: $ARGUMENTS

## Prerequisites Check
- **Service**: $ARGUMENTS (REQUIRED - specify service name)
- **GCP Project**: !`gcloud config get-value project 2>/dev/null`
- **Timestamp**: !`date -u '+%Y-%m-%d %H:%M:%S UTC'`

---

## Phase 1: Rapid Context (Automated)

### Service Status
```
!`gcloud run services describe $ARGUMENTS --format="yaml(status)" 2>/dev/null || kubectl get deployment $ARGUMENTS -o yaml 2>/dev/null | head -30 || echo "Service not found in Cloud Run or K8s"`
```

### Recent Deployments
```
!`git log --oneline --since="24 hours ago" -- "*$ARGUMENTS*" "*${ARGUMENTS//-/_}*" 2>/dev/null | head -10 || echo "No git history for this service path"`
```

### Error Spike Check
```
!`gcloud logging read "resource.labels.service_name=\"$ARGUMENTS\" AND severity>=ERROR AND timestamp>=\"$(date -u -d '2 hours ago' '+%Y-%m-%dT%H:%M:%SZ')\"" --format=json --limit=50 2>/dev/null | head -c 8000 || echo "[]"`
```

### Resource Metrics (if K8s)
```
!`kubectl top pods -l app=$ARGUMENTS 2>/dev/null || echo "Metrics not available"`
```

---

## Phase 2: Deep Analysis (Your Task)

Using the incident-response skill, investigate:

1. **Timeline Reconstruction**
   - When did the first error occur?
   - What was the error rate before vs during incident?
   - Any patterns in timing?

2. **Error Analysis**
   - What are the unique error types?
   - Are errors correlated (same root cause)?
   - Any stack traces pointing to specific code?

3. **Change Correlation**
   - Were there recent deployments?
   - Any config changes?
   - External dependency changes?

4. **Resource Analysis**
   - CPU/Memory pressure?
   - Connection limits hit?
   - Disk space issues?

5. **Dependency Check**
   - Database connectivity?
   - External API failures?
   - Network issues?

---

## Phase 3: Output Requirements

Produce a structured incident report:

```markdown
## Incident Summary
[One paragraph description]

## Severity Assessment
[SEV1/SEV2/SEV3/SEV4] - [Justification]

## Timeline
| Time | Event |
|------|-------|

## Root Cause
[Confirmed or Most Likely Hypothesis]

## Evidence
- [Specific log entries, metrics, or data points]

## Customer Impact
- Affected users/requests: [estimate]
- Duration: [time range]

## Recommended Mitigations
1. [Immediate action]
2. [Short-term fix]
3. [Long-term prevention]

## Follow-up Items
- [ ] [Action item with owner]
```
```

### Command 5: /generate-adr

**Location**: `.claude/commands/generate-adr.md`

```markdown
---
description: Generate an Architecture Decision Record from analysis conversation
allowed-tools:
  - Read
  - Write(docs/**)
  - Glob
  - Bash(ls *)
  - Bash(date *)
argument-hint: <decision-topic>
model: opus
---

# Generate ADR: $ARGUMENTS

## Context Gathering

### Existing ADRs
```
!`ls -la docs/decisions/ADR-*.md 2>/dev/null | tail -10 || echo "No existing ADRs found"`
```

### Next ADR Number
```
!`printf "ADR-%03d" $(( $(ls docs/decisions/ADR-*.md 2>/dev/null | wc -l) + 1 ))`
```

### Current Date
```
!`date '+%Y-%m-%d'`
```

---

## Your Task

Using the adr-generation skill, create an ADR for: **$ARGUMENTS**

### Step 1: Extract Decision from Conversation
Review our conversation to identify:
- What technical decision was made or is being proposed?
- What problem does this address?
- What evidence supports this decision?

### Step 2: Document Thoroughly
Create a complete ADR with:
- Clear, specific title
- Full context from our analysis
- Concrete consequences (positive and negative)
- Alternatives that were considered

### Step 3: Save the ADR
Write the ADR to: `docs/decisions/[ADR-NUMBER]-[slug].md`

Where slug is derived from the topic:
- Lowercase
- Hyphens instead of spaces
- No special characters
- Example: "migrate-auth-to-oauth2"

---

## Quality Checklist

Before saving, verify:
- [ ] Title clearly describes the decision
- [ ] Context explains WHY this decision was needed
- [ ] Decision is stated in present tense ("We will...")
- [ ] Consequences are specific and measurable where possible
- [ ] At least 2 alternatives are documented
- [ ] References link to relevant analysis/data

---

## Output

After creating the ADR:
1. Show the full content
2. Confirm the file path
3. Summarize the key decision in 1-2 sentences
```

### Command 6: /parallel-collect

**Location**: `.claude/commands/parallel-collect.md`

```markdown
---
description: Parallel data collection from all infrastructure sources
allowed-tools:
  - Bash(gcloud *)
  - Bash(bq *)
  - Bash(kubectl *)
  - Bash(./scripts/*)
  - Bash(mkdir *)
  - Bash(cat *)
  - Bash(rm /tmp/claude-*)
  - Read
argument-hint: [time-range]
model: opus
---

# Parallel Infrastructure Data Collection

## Setup
```
COLLECT_DIR="/tmp/claude-devops-$(date +%s)"
TIME_RANGE="${1:-1h}"
!`mkdir -p /tmp/claude-devops-$$ && echo "Collection dir: /tmp/claude-devops-$$"`
```

## Parallel Execution

Execute all collectors simultaneously:

```bash
!`COLLECT_DIR="/tmp/claude-devops-$$" && mkdir -p $COLLECT_DIR && {
  # Logs
  gcloud logging read "severity>=ERROR" --format=json --limit=200 \
    > $COLLECT_DIR/errors.json 2>&1 &
  
  # Metrics summary
  gcloud logging read "severity>=WARNING" --format=json --limit=100 \
    | jq -r '.[].resource.labels.service_name // "unknown"' \
    | sort | uniq -c | sort -rn \
    > $COLLECT_DIR/error_counts.txt 2>&1 &
  
  # K8s pods
  kubectl get pods -A -o json \
    > $COLLECT_DIR/pods.json 2>&1 &
  
  # K8s events
  kubectl get events -A --sort-by='.lastTimestamp' -o json \
    > $COLLECT_DIR/events.json 2>&1 &
  
  # Cost summary (if billing configured)
  bq query --format=json --use_legacy_sql=false \
    "SELECT service.description, ROUND(SUM(cost),2) as cost FROM \\\`$(gcloud config get-value project).billing_export.gcp_billing_export_v1_*\\\` WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) GROUP BY 1 ORDER BY 2 DESC LIMIT 10" \
    > $COLLECT_DIR/costs.json 2>&1 &
  
  # Custom scripts
  [ -f ./scripts/collect-all.sh ] && ./scripts/collect-all.sh \
    > $COLLECT_DIR/custom.json 2>&1 &
  
  wait
} && echo "Collection complete" && ls -la $COLLECT_DIR`
```

## Collected Data Summary

```
!`COLLECT_DIR="/tmp/claude-devops-$$" && for f in $COLLECT_DIR/*.json $COLLECT_DIR/*.txt; do echo "=== $(basename $f) ===" && head -c 3000 "$f" 2>/dev/null && echo -e "\n"; done`
```

## Analysis Task

With all data collected, provide:

1. **Overall Health Assessment**
   - Traffic light status for each data source
   - Key metrics summary

2. **Cross-Source Correlation**
   - Do errors correlate with K8s events?
   - Any cost anomalies related to error spikes?
   - Pattern matching across sources

3. **Priority Issues**
   - Rank findings by severity
   - Identify anything requiring immediate attention

4. **Recommendations**
   - Specific next steps
   - Which issues to investigate first

## Cleanup
```
!`rm -rf /tmp/claude-devops-$$ 2>/dev/null; echo "Cleaned up temp files"`
```
```

---

## Subagent Definitions

### Agent 1: Log Analyzer

**Location**: `.claude/agents/log-analyzer.md`

```markdown
---
name: log-analyzer
description: Specialized agent for log analysis and error pattern detection
tools:
  - Bash(gcloud logging *)
  - Bash(jq *)
  - Read
  - Grep
model: haiku
max_turns: 10
---

# Log Analyzer Subagent

You are a specialized log analysis agent. Your sole purpose is to:

1. Execute provided log queries
2. Parse JSON log output
3. Identify patterns and anomalies
4. Return structured findings

## Constraints
- Focus ONLY on log analysis
- Do NOT investigate other systems
- Do NOT make changes to any systems
- Return findings in the exact format specified

## Standard Workflow

1. Execute the log query provided
2. Parse the JSON response
3. Cluster errors by signature
4. Identify timing patterns
5. Return structured summary

## Required Output Format

```json
{
  "status": "complete",
  "query_executed": "description of what was queried",
  "time_range": "start to end",
  "total_entries": 123,
  "error_clusters": [
    {
      "signature": "error message pattern",
      "count": 45,
      "first_seen": "timestamp",
      "last_seen": "timestamp",
      "services_affected": ["svc1", "svc2"]
    }
  ],
  "timeline": [
    {"time": "HH:MM", "event": "description"}
  ],
  "anomalies": [
    "description of unusual pattern"
  ],
  "hypothesis": "most likely root cause based on logs"
}
```

## Execution Rules
- Always use `--format=json` for parseable output
- Limit queries to prevent timeout: `--limit=500` max
- Truncate large payloads in output
- If query fails, report error and suggest alternative
```

### Agent 2: Metrics Collector

**Location**: `.claude/agents/metrics-collector.md`

```markdown
---
name: metrics-collector
description: Specialized agent for GCP metrics collection and analysis
tools:
  - Bash(gcloud monitoring *)
  - Bash(kubectl top *)
  - Read
model: haiku
max_turns: 8
---

# Metrics Collector Subagent

You are a specialized metrics collection agent focused on resource utilization and performance data.

## Responsibilities
1. Query GCP Cloud Monitoring
2. Collect Kubernetes resource metrics
3. Calculate statistics (avg, p50, p95, p99, max)
4. Identify anomalies against baseline

## Key Metrics to Collect

### Compute
- CPU utilization
- Memory usage
- Disk I/O

### Application
- Request latency
- Error rates
- Request counts

### Infrastructure
- Instance count
- Scaling events
- Network throughput

## Required Output Format

```json
{
  "status": "complete",
  "collection_time": "ISO timestamp",
  "period_analyzed": "1h",
  "services": [
    {
      "name": "service-name",
      "cpu": {
        "avg": 45.2,
        "p95": 78.1,
        "max": 92.3
      },
      "memory": {
        "avg": 1024,
        "p95": 1536,
        "max": 1800
      },
      "latency_ms": {
        "p50": 45,
        "p95": 234,
        "p99": 567
      },
      "error_rate_pct": 0.5
    }
  ],
  "anomalies": [
    {
      "metric": "cpu",
      "service": "api-gateway",
      "description": "CPU spike to 95% at 14:32",
      "severity": "warning"
    }
  ],
  "recommendations": [
    "Consider scaling api-gateway"
  ]
}
```

## Execution Rules
- Query metrics for specified time range only
- Calculate percentiles from available data points
- Flag any metric >80% of limit as warning
- Flag any metric >95% of limit as critical
```

### Agent 3: Cost Analyzer

**Location**: `.claude/agents/cost-analyzer.md`

```markdown
---
name: cost-analyzer
description: Specialized agent for GCP cost analysis using BigQuery billing data
tools:
  - Bash(bq *)
  - Read
model: opus
max_turns: 12
---

# Cost Analyzer Subagent

You are a specialized cloud cost analyst. Investigate spending patterns using BigQuery billing export data.

## Data Source
- Table: `{project}.billing_export.gcp_billing_export_v1_*`
- Always use `--use_legacy_sql=false`
- Format output as JSON for parsing

## Analysis Tasks

### 1. Identify Top Spenders
Query top services by cost for the analysis period.

### 2. Calculate Trends
- Day-over-day change
- Week-over-week change
- Month-over-month change (if data available)

### 3. Detect Anomalies
Flag costs exceeding thresholds:
- >20% above 7-day average: Warning
- >50% above 7-day average: Alert
- >100% above 7-day average: Critical

### 4. SKU Analysis
For anomalous services, drill into SKU-level detail.

### 5. Optimization Opportunities
Identify:
- Idle resources
- Over-provisioned instances
- Missing committed use discounts
- Unattached disks/IPs

## Required Output Format

```json
{
  "status": "complete",
  "analysis_period": {
    "start": "YYYY-MM-DD",
    "end": "YYYY-MM-DD"
  },
  "total_cost": 1234.56,
  "cost_trend": {
    "vs_yesterday": "+5.2%",
    "vs_last_week": "-2.1%"
  },
  "top_services": [
    {
      "service": "Compute Engine",
      "cost": 456.78,
      "pct_of_total": 37.0,
      "trend": "+12.3%"
    }
  ],
  "anomalies": [
    {
      "service": "Cloud Storage",
      "cost": 234.56,
      "baseline": 100.00,
      "pct_increase": 134.5,
      "severity": "critical",
      "likely_cause": "Large data transfer or new bucket"
    }
  ],
  "optimization_opportunities": [
    {
      "type": "idle_resource",
      "resource": "Unattached persistent disk",
      "potential_savings": 45.00,
      "recommendation": "Delete or snapshot and remove"
    }
  ]
}
```
```

### Agent 4: Security Auditor

**Location**: `.claude/agents/security-auditor.md`

```markdown
---
name: security-auditor
description: Specialized agent for security posture analysis and audit log review
tools:
  - Bash(gcloud logging *)
  - Bash(gcloud iam *)
  - Bash(gcloud asset *)
  - Read
  - Grep
model: opus
max_turns: 15
---

# Security Auditor Subagent

You are a specialized security analyst. Review audit logs, IAM policies, and security configurations.

## Analysis Scope

### 1. Audit Log Review
```bash
gcloud logging read 'logName:"cloudaudit.googleapis.com"' \
  --format=json --limit=100
```

Look for:
- Unusual admin activities
- Permission changes
- Resource deletions
- Access from unusual IPs/locations

### 2. IAM Policy Analysis
```bash
gcloud projects get-iam-policy ${PROJECT} --format=json
```

Check for:
- Overly permissive roles (Owner, Editor on service accounts)
- External users with access
- Service accounts with excessive permissions
- Missing least-privilege principles

### 3. Service Account Review
```bash
gcloud iam service-accounts list --format=json
gcloud iam service-accounts keys list --iam-account=SA_EMAIL
```

Check for:
- User-managed keys (security risk)
- Unused service accounts
- Accounts with admin roles

### 4. Security Findings
```bash
gcloud scc findings list ORGANIZATION --format=json
```

## Required Output Format

```json
{
  "status": "complete",
  "scan_time": "ISO timestamp",
  "risk_summary": {
    "critical": 0,
    "high": 2,
    "medium": 5,
    "low": 12
  },
  "findings": [
    {
      "id": "SEC-001",
      "severity": "high",
      "category": "iam",
      "title": "Service account has Owner role",
      "description": "SA xxx@project.iam has roles/owner",
      "resource": "projects/xxx/serviceAccounts/xxx",
      "recommendation": "Replace with minimum required roles",
      "remediation_steps": [
        "Identify actual permissions needed",
        "Create custom role with those permissions",
        "Update service account binding"
      ]
    }
  ],
  "audit_events_of_interest": [
    {
      "timestamp": "ISO timestamp",
      "actor": "user@domain.com",
      "action": "SetIamPolicy",
      "resource": "projects/xxx",
      "details": "Added external user to project"
    }
  ],
  "compliance_gaps": [
    "Missing VPC Service Controls",
    "Audit logs not exported to SIEM"
  ]
}
```

## Security Principles
- Never expose credentials or secrets in output
- Flag any public access to sensitive resources
- Alert on any privilege escalation patterns
- Report unusual geographic access patterns
```

---

## Integration with Existing Go Tools

### Example: Custom Go Binary Integration

If you have existing Go tools, reference them in commands:

```markdown
---
description: Run custom log parser
allowed-tools:
  - Bash(./bin/log-parser *)
  - Read
---

# Custom Log Analysis

!`./bin/log-parser --project=${GCP_PROJECT} --since=1h --format=json`

Analyze the output and provide insights.
```

### Building Go Tools for Claude Code

Your Go tools should:
1. Accept `--format=json` flag for machine-readable output
2. Support `--since` or `--time-range` parameters
3. Output to stdout (not files) for easy piping
4. Exit with appropriate codes (0=success, 1=error)

Example interface:
```go
// cmd/log-parser/main.go
func main() {
    format := flag.String("format", "text", "Output format: text|json")
    since := flag.Duration("since", time.Hour, "Time range to analyze")
    // ...
}
```

---

## Usage Patterns

### Quick Commands (< 1 minute)

| Command | Use Case | Model |
|---------|----------|-------|
| `/health-status` | Morning check, after deploy | Haiku |
| `/cost-check` | Daily cost monitoring | Haiku |

### Analysis Commands (2-5 minutes)

| Command | Use Case | Model |
|---------|----------|-------|
| `/analyze-logs api-gateway` | Investigate errors | Opus |
| `/incident-investigate payment-svc` | Active incident | Opus |

### Documentation Commands (5-10 minutes)

| Command | Use Case | Model |
|---------|----------|-------|
| `/generate-adr caching-strategy` | Document decisions | Opus |
| `/parallel-collect` | Comprehensive data gather | Opus |

### Workflow Examples

**Morning Standup Prep**:
```
/health-status
/cost-check
```

**Incident Response**:
```
/incident-investigate affected-service
[after resolution]
/generate-adr incident-remediation
```

**Weekly Review**:
```
/parallel-collect 7d
/generate-adr weekly-observations
```

---

## Implementation Checklist

### Phase 1: Core Setup
- [ ] Create `.claude/` directory structure
- [ ] Write `CLAUDE.md` with project context
- [ ] Configure `settings.json` with permissions
- [ ] Test basic bash tool access

### Phase 2: Skills
- [ ] Implement `gcp-logging` skill
- [ ] Implement `cost-analysis` skill
- [ ] Implement `incident-response` skill
- [ ] Implement `adr-generation` skill
- [ ] Test skill auto-loading

### Phase 3: Commands
- [ ] Implement `/analyze-logs`
- [ ] Implement `/cost-check`
- [ ] Implement `/health-status`
- [ ] Implement `/incident-investigate`
- [ ] Implement `/generate-adr`
- [ ] Implement `/parallel-collect`

### Phase 4: Subagents
- [ ] Configure `log-analyzer` agent
- [ ] Configure `metrics-collector` agent
- [ ] Configure `cost-analyzer` agent
- [ ] Configure `security-auditor` agent
- [ ] Test parallel agent execution

### Phase 5: Integration
- [ ] Integrate existing Go tools
- [ ] Create custom scripts directory
- [ ] Test end-to-end workflows
- [ ] Document team-specific customizations

---

## Limitations and Considerations

1. **Code repository access is MANDATORY** - Analysis cannot proceed without access to actual code via local files or GitHub
2. **All recommendations must reference specific code** - Abstract suggestions are not permitted
3. **Skills cannot call other skills** - Claude uses multiple skills, but they don't chain directly
4. **Subagents cannot spawn sub-subagents** - Hierarchy is flat
5. **Token costs scale with parallelism** - Multiple subagents = multiple API calls
6. **Large outputs may truncate** - Use `--limit` and `head` to manage size
7. **Background processes need tracking** - Use `/bashes` to monitor long-running commands
8. **Read-only by design** - This toolkit investigates but doesn't modify infrastructure

---

*Document Version: 1.0*  
*Last Updated: January 2026*  
*Purpose: Claude Code implementation specification for ad-hoc DevOps analysis toolkit*
