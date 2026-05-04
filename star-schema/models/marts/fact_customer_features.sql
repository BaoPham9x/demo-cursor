-- Fact: Customer Features
-- Create as view: CREATE OR REPLACE VIEW steep-demo.steep_demo_v2.fact_customer_features AS
SELECT
    cf.customer_feature_id,
    dc.customer_key,
    cf.feature_name,
    cf.feature_category,
    cf.is_active,
    cf.activated_at,
    cf.last_used_at
FROM `steep-demo.steep_demo_v2.raw_customer_features` cf
LEFT JOIN `steep-demo.steep_demo_v2.dim_customer` dc ON cf.customer_id = dc.customer_id
WHERE DATE(cf.activated_at) <= CURRENT_DATE()
