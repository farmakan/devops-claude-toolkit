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
