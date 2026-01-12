---
description: Quick cost anomaly detection comparing current spend against baseline
allowed-tools:
  - Bash(bq:*)
  - Bash(gcloud:*)
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
   - Warning: 20-50% above baseline
   - Alert: >50% above baseline
4. Check for new services not in baseline

## Output Format

Provide a quick status summary:

```
## Cost Status: [Normal | Elevated | Anomaly Detected]

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
