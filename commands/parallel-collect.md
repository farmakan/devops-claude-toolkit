---
description: Parallel data collection from all infrastructure sources
allowed-tools:
  - Bash(gcloud *)
  - Bash(bq *)
  - Bash(kubectl *)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*)
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
  [ -f ${CLAUDE_PLUGIN_ROOT}/scripts/collect-all.sh ] && ${CLAUDE_PLUGIN_ROOT}/scripts/collect-all.sh \
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
