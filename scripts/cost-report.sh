#!/bin/bash
# Generate cost report from BigQuery billing export
# Usage: ./scripts/cost-report.sh [days-lookback]

set -euo pipefail

DAYS="${1:-7}"
PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
BILLING_TABLE="${PROJECT}.billing_export.gcp_billing_export_v1_*"

if [[ -z "$PROJECT" ]]; then
    echo "Error: No GCP project configured" >&2
    exit 1
fi

echo "=== GCP Cost Report ==="
echo "Project: ${PROJECT}"
echo "Period: Last ${DAYS} days"
echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "======================="
echo ""

# Total spend
echo "### Total Spend ###"
bq query --format=prettyjson --use_legacy_sql=false "
SELECT
  ROUND(SUM(cost), 2) AS total_cost,
  ROUND(SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) c), 0)), 2) AS total_credits,
  ROUND(SUM(cost) + SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) c), 0)), 2) AS net_cost
FROM \`${BILLING_TABLE}\`
WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ${DAYS} DAY)
" 2>/dev/null || echo "Query failed - check billing export configuration"
echo ""

# Cost by service
echo "### Cost by Service ###"
bq query --format=prettyjson --use_legacy_sql=false "
SELECT
  service.description AS service,
  ROUND(SUM(cost), 2) AS cost,
  ROUND(SUM(cost) / (SELECT SUM(cost) FROM \`${BILLING_TABLE}\` WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ${DAYS} DAY)) * 100, 1) AS pct_of_total
FROM \`${BILLING_TABLE}\`
WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ${DAYS} DAY)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 15
" 2>/dev/null || echo "Query failed"
echo ""

# Daily trend
echo "### Daily Cost Trend ###"
bq query --format=prettyjson --use_legacy_sql=false "
SELECT
  DATE(usage_start_time) AS date,
  ROUND(SUM(cost), 2) AS daily_cost
FROM \`${BILLING_TABLE}\`
WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ${DAYS} DAY)
GROUP BY 1
ORDER BY 1 DESC
" 2>/dev/null || echo "Query failed"
echo ""

# Anomalies
echo "### Cost Anomalies (>50% above baseline) ###"
bq query --format=prettyjson --use_legacy_sql=false "
WITH daily_costs AS (
  SELECT
    DATE(usage_start_time) AS date,
    service.description AS service,
    SUM(cost) AS cost
  FROM \`${BILLING_TABLE}\`
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
  date,
  service,
  ROUND(cost, 2) AS cost,
  ROUND(baseline, 2) AS baseline_7d,
  ROUND((cost - baseline) / NULLIF(baseline, 0) * 100, 1) AS pct_above_baseline
FROM with_baseline
WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  AND cost > baseline * 1.5
  AND baseline > 1
ORDER BY pct_above_baseline DESC
LIMIT 10
" 2>/dev/null || echo "Query failed or no anomalies"

echo ""
echo "=== End of Report ==="
