-- Fact: Transactions
-- Create as view: CREATE OR REPLACE VIEW steep-demo.steep_demo_v2.fact_transactions AS
SELECT
    t.transaction_id,
    t.customer_id,
    dc.customer_key,
    da.account_key,
    dm.merchant_key,
    t.merchant_name,
    t.merchant_category,
    t.transaction_type,
    t.status,
    t.amount,
    t.currency,
    t.fee_amount,
    t.payment_method,
    t.balance_before,
    t.balance_after,
    t.risk_flag,
    t.country,
    t.city,
    t.latitude,
    t.longitude,
    -- H3 geospatial indexes for different resolutions (1-10)
    -- H3 is a hierarchical geospatial indexing system for efficient location queries
    t.h3_res_1,
    t.h3_res_2,
    t.h3_res_3,
    t.h3_res_4,
    t.h3_res_5,
    t.h3_res_6,
    t.h3_res_7,
    t.h3_res_8,
    t.h3_res_9,
    t.h3_res_10,
    -- Location key for joining to dim_location in Steep (not joined in SQL)
    CASE 
        WHEN t.latitude IS NOT NULL AND t.longitude IS NOT NULL
        THEN CONCAT(
            COALESCE(t.country, 'Unknown'), '|',
            COALESCE(t.city, 'Unknown'), '|',
            CAST(ROUND(t.latitude, 4) AS STRING), '|',
            CAST(ROUND(t.longitude, 4) AS STRING)
        )
        ELSE NULL
    END AS location_key,
    t.created_at
FROM `steep-demo.steep_demo_v2.raw_transactions` t
LEFT JOIN `steep-demo.steep_demo_v2.dim_customer` dc ON t.customer_id = dc.customer_id
LEFT JOIN `steep-demo.steep_demo_v2.dim_account` da ON t.account_id = da.account_id
LEFT JOIN `steep-demo.steep_demo_v2.dim_merchant` dm 
    ON CONCAT(COALESCE(t.merchant_name, 'Unknown'), '|', COALESCE(t.merchant_category, 'other')) = dm.merchant_key
WHERE DATE(t.created_at) <= CURRENT_DATE()
