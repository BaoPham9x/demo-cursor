-- Dimension: Date
-- Generate date dimension for 2024-01-01 to 2026-12-31
-- Create as view: CREATE OR REPLACE VIEW steep-demo.steep_demo_v2.dim_date AS
WITH date_spine AS (
    SELECT date_day
    FROM UNNEST(GENERATE_DATE_ARRAY('2024-01-01', '2026-12-31')) AS date_day
)
SELECT
    FORMAT_DATE('%Y%m%d', date_day) as date_key,
    date_day as date,
    EXTRACT(YEAR FROM date_day) as year,
    EXTRACT(QUARTER FROM date_day) as quarter,
    EXTRACT(MONTH FROM date_day) as month,
    FORMAT_DATE('%B', date_day) as month_name,
    EXTRACT(WEEK FROM date_day) as week,
    EXTRACT(DAYOFWEEK FROM date_day) as day_of_week,
    FORMAT_DATE('%A', date_day) as day_name,
    CASE WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) THEN 1 ELSE 0 END as is_weekend,
    CASE WHEN date_day = LAST_DAY(date_day, MONTH) THEN 1 ELSE 0 END as is_month_end
FROM date_spine
