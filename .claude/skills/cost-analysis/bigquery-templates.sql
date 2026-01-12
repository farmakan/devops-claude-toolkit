-- BigQuery Cost Analysis Templates
-- Use with: bq query --format=json --use_legacy_sql=false

-- ============================================
-- DAILY COST BREAKDOWN
-- ============================================

-- Cost by service for specific date
SELECT
  service.description AS service,
  ROUND(SUM(cost), 2) AS cost,
  ROUND(SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) c), 0)), 2) AS credits,
  ROUND(SUM(cost) + SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) c), 0)), 2) AS net_cost
FROM `PROJECT.billing_export.gcp_billing_export_v1_*`
WHERE DATE(usage_start_time) = DATE('YYYY-MM-DD')
GROUP BY 1
ORDER BY cost DESC;

-- Cost by SKU for specific service
SELECT
  sku.description AS sku,
  ROUND(SUM(cost), 2) AS cost,
  SUM(usage.amount) AS usage_amount,
  usage.unit AS usage_unit
FROM `PROJECT.billing_export.gcp_billing_export_v1_*`
WHERE DATE(usage_start_time) = CURRENT_DATE()
  AND service.description = 'SERVICE_NAME'
GROUP BY 1, 4
ORDER BY cost DESC
LIMIT 20;

-- ============================================
-- TREND ANALYSIS
-- ============================================

-- 30-day cost trend by service
SELECT
  DATE(usage_start_time) AS date,
  service.description AS service,
  ROUND(SUM(cost), 2) AS daily_cost
FROM `PROJECT.billing_export.gcp_billing_export_v1_*`
WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY 1, 2
ORDER BY 1 DESC, 3 DESC;

-- Week-over-week comparison
WITH current_week AS (
  SELECT
    service.description AS service,
    SUM(cost) AS cost
  FROM `PROJECT.billing_export.gcp_billing_export_v1_*`
  WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  GROUP BY 1
),
previous_week AS (
  SELECT
    service.description AS service,
    SUM(cost) AS cost
  FROM `PROJECT.billing_export.gcp_billing_export_v1_*`
  WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY)
    AND usage_start_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  GROUP BY 1
)
SELECT
  COALESCE(c.service, p.service) AS service,
  ROUND(c.cost, 2) AS current_week,
  ROUND(p.cost, 2) AS previous_week,
  ROUND((c.cost - p.cost) / NULLIF(p.cost, 0) * 100, 1) AS pct_change
FROM current_week c
FULL OUTER JOIN previous_week p ON c.service = p.service
ORDER BY c.cost DESC NULLS LAST;

-- ============================================
-- ANOMALY DETECTION
-- ============================================

-- Services with cost spike (>50% above 7-day average)
WITH daily_costs AS (
  SELECT
    DATE(usage_start_time) AS date,
    service.description AS service,
    SUM(cost) AS cost
  FROM `PROJECT.billing_export.gcp_billing_export_v1_*`
  WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY)
  GROUP BY 1, 2
),
with_baseline AS (
  SELECT
    *,
    AVG(cost) OVER (
      PARTITION BY service
      ORDER BY date
      ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
    ) AS baseline_7d,
    STDDEV(cost) OVER (
      PARTITION BY service
      ORDER BY date
      ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
    ) AS stddev_7d
  FROM daily_costs
)
SELECT
  date,
  service,
  ROUND(cost, 2) AS cost,
  ROUND(baseline_7d, 2) AS baseline,
  ROUND((cost - baseline_7d) / NULLIF(baseline_7d, 0) * 100, 1) AS pct_above_baseline,
  ROUND((cost - baseline_7d) / NULLIF(stddev_7d, 0), 1) AS z_score
FROM with_baseline
WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  AND cost > baseline_7d * 1.5
  AND baseline_7d > 1
ORDER BY pct_above_baseline DESC;

-- ============================================
-- RESOURCE-LEVEL ANALYSIS
-- ============================================

-- Cost by project
SELECT
  project.id AS project_id,
  ROUND(SUM(cost), 2) AS cost
FROM `PROJECT.billing_export.gcp_billing_export_v1_*`
WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY 1
ORDER BY 2 DESC;

-- Cost by label (if using labels)
SELECT
  labels.key,
  labels.value,
  ROUND(SUM(cost), 2) AS cost
FROM `PROJECT.billing_export.gcp_billing_export_v1_*`,
UNNEST(labels) AS labels
WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 50;

-- ============================================
-- OPTIMIZATION OPPORTUNITIES
-- ============================================

-- Potential committed use discount candidates
-- (Services with consistent high spend)
WITH daily_spend AS (
  SELECT
    service.description AS service,
    DATE(usage_start_time) AS date,
    SUM(cost) AS cost
  FROM `PROJECT.billing_export.gcp_billing_export_v1_*`
  WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  GROUP BY 1, 2
)
SELECT
  service,
  ROUND(AVG(cost), 2) AS avg_daily_cost,
  ROUND(MIN(cost), 2) AS min_daily_cost,
  ROUND(STDDEV(cost) / NULLIF(AVG(cost), 0) * 100, 1) AS coefficient_of_variation,
  COUNT(*) AS days_with_spend
FROM daily_spend
GROUP BY 1
HAVING AVG(cost) > 10
  AND STDDEV(cost) / NULLIF(AVG(cost), 0) < 0.3  -- Low variance = good CUD candidate
ORDER BY avg_daily_cost DESC;
