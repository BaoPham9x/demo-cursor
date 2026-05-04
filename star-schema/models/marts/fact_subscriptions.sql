-- Fact: Subscriptions
-- Create as view: CREATE OR REPLACE VIEW steep-demo.steep_demo_v2.fact_subscriptions AS
SELECT
    s.subscription_id,
    dc.customer_key,
    s.plan_name,
    s.monthly_price,
    s.currency,
    s.status,
    s.billing_cycle,
    s.billing_paused_at,
    s.suspended_at,
    s.mrr,
    s.arr,
    s.started_at,
    s.ended_at,
    s.created_at
FROM `steep-demo.steep_demo_v2.raw_subscriptions` s
LEFT JOIN `steep-demo.steep_demo_v2.dim_customer` dc ON s.customer_id = dc.customer_id
WHERE DATE(s.started_at) <= CURRENT_DATE()
