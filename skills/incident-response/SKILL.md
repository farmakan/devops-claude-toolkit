---
name: incident-response
description: Structured incident investigation workflow. Automatically invoked when investigating production issues, outages, service degradation, or customer-impacting problems.
allowed-tools:
  - Bash(gcloud *)
  - Bash(kubectl *)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*)
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
${CLAUDE_PLUGIN_ROOT}/scripts/health-check.sh ${SERVICE:-all}

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
