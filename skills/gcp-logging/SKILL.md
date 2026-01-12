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
