---
description: Quick infrastructure health check across all components
allowed-tools:
  - Bash(gcloud *)
  - Bash(kubectl *)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*)
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
!`[ -f ${CLAUDE_PLUGIN_ROOT}/scripts/health-check.sh ] && ${CLAUDE_PLUGIN_ROOT}/scripts/health-check.sh ${ARGUMENTS:-production} 2>/dev/null || echo "No custom health check script found"`
```

## Output Format

Provide traffic-light summary:

```
## Infrastructure Health: [Healthy | Degraded | Critical]

### Component Status
| Component | Status | Details |
|-----------|--------|---------|
| Cloud Run | Status | X services running |
| Kubernetes | Status | X/Y pods healthy |
| Error Rate | Status | X errors in last 15m |

### Issues Requiring Attention
- [List any degraded or critical items with brief description]

### Recent Changes
- [Any deployments in last 4 hours]
```
