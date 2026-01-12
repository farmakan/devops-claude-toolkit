---
name: cost-analysis
description: Analyze GCP costs using BigQuery billing export. Automatically invoked for cost anomaly detection, budget tracking, spend optimization, or resource efficiency analysis.
allowed-tools:
  - Bash(bq:*)
  - Bash(gcloud billing:*)
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
- **Critical**: [service] - $XXX (+XXX%)
- **Warning**: [service] - $XXX (+XX%)

### Optimization Recommendations
1. [Specific recommendation with estimated savings]
```

## Additional Templates
See [bigquery-templates.sql](bigquery-templates.sql) for more queries.
