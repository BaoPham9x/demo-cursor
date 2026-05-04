-- Fact: Risk Events
-- Create as view: CREATE OR REPLACE VIEW steep-demo.steep_demo_v2.fact_risk_events AS
SELECT
    r.risk_event_id,
    dc.customer_key,
    r.transaction_id,
    da.account_key,
    dr.risk_event_type_key,
    r.event_type,
    r.severity,
    r.status,
    r.created_at,
    r.resolved_at,
    CASE 
        WHEN r.resolved_at IS NOT NULL AND r.created_at IS NOT NULL
        THEN TIMESTAMP_DIFF(TIMESTAMP(r.resolved_at), TIMESTAMP(r.created_at), HOUR)
        ELSE NULL
    END as resolution_time_hours,
    r.description
FROM `steep-demo.steep_demo_v2.raw_risk_events` r
LEFT JOIN `steep-demo.steep_demo_v2.dim_customer` dc ON r.customer_id = dc.customer_id
LEFT JOIN `steep-demo.steep_demo_v2.dim_risk_event_type` dr ON r.event_type = dr.risk_event_type_key
LEFT JOIN `steep-demo.steep_demo_v2.fact_transactions` dt ON r.transaction_id = dt.transaction_id
LEFT JOIN `steep-demo.steep_demo_v2.dim_account` da ON r.account_id = da.account_id
WHERE DATE(r.created_at) <= CURRENT_DATE()
