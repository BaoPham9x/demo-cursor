-- Fact: Aggregated ARR (Annual Recurring Revenue)
-- Monthly snapshots of ARR per subscription
-- This creates a time-series fact table with one row per subscription per month
-- Create as view: CREATE OR REPLACE VIEW steep-demo.steep_demo_v2.fact_agg_arr AS

WITH 
-- Generate monthly date spine (first day of each month)
monthly_dates AS (
  SELECT DISTINCT
    DATE_TRUNC(date_day, MONTH) as snapshot_date,
    DATE_TRUNC(date_day, MONTH) as month_start,
    LAST_DAY(date_day, MONTH) as month_end,
    FORMAT_DATE('%Y%m', date_day) as month_key,
    EXTRACT(YEAR FROM date_day) as year,
    EXTRACT(MONTH FROM date_day) as month
  FROM UNNEST(GENERATE_DATE_ARRAY('2024-01-01', '2026-12-31')) AS date_day
),

-- Get all subscriptions with their details
subscriptions AS (
  SELECT
    s.subscription_id,
    s.customer_id,
    dc.customer_key,
    s.plan_name,
    s.monthly_price,
    s.currency,
    s.status,
    s.billing_cycle,
    s.mrr,
    s.arr,
    DATE(s.started_at) as started_date,
    DATE(s.ended_at) as ended_date,
    s.started_at,
    s.ended_at
  FROM `steep-demo.steep_demo_v2.raw_subscriptions` s
  LEFT JOIN `steep-demo.steep_demo_v2.dim_customer` dc ON s.customer_id = dc.customer_id
),

-- Cross join subscriptions with monthly dates to create snapshots
subscription_snapshots AS (
  SELECT
    md.snapshot_date,
    md.month_start,
    md.month_end,
    md.month_key,
    md.year,
    md.month,
    s.subscription_id,
    s.customer_id,
    s.customer_key,
    s.plan_name,
    s.monthly_price,
    s.currency,
    s.status,
    s.billing_cycle,
    s.mrr,
    s.arr,
    s.started_at,
    s.ended_at,
    -- Determine if subscription is active in this month
    CASE 
      WHEN s.started_date <= md.month_end 
        AND (s.ended_date IS NULL OR s.ended_date > md.month_start)
        AND s.status IN ('active', 'trialing', 'past_due')
      THEN 1 
      ELSE 0 
    END as is_active,
    -- Calculate ARR contribution for this month
    CASE 
      WHEN s.started_date <= md.month_end 
        AND (s.ended_date IS NULL OR s.ended_date > md.month_start)
        AND s.status IN ('active', 'trialing', 'past_due')
      THEN s.arr
      ELSE 0
    END as arr_amount
  FROM monthly_dates md
  CROSS JOIN subscriptions s
  WHERE s.started_date <= md.month_end  -- Only include months after subscription started
    AND (s.ended_date IS NULL OR s.ended_date >= md.month_start)  -- Only include months before subscription ended
)

SELECT
  snapshot_date,
  month_key,
  year,
  month,
  subscription_id,
  customer_id,
  customer_key,
  plan_name,
  monthly_price,
  currency,
  status,
  billing_cycle,
  mrr,
  arr as subscription_arr,
  arr_amount as arr_contribution,
  is_active,
  started_at,
  ended_at
FROM subscription_snapshots
WHERE is_active = 1  -- Only include active subscriptions in the snapshot
ORDER BY snapshot_date, subscription_id
