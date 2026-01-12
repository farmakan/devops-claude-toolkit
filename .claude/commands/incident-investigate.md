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
