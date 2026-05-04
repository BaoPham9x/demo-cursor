-- Fact: Visitors (Daily Aggregated)
-- Daily aggregated website visitor metrics for conversion analysis
-- Can be joined to fact_ad_spend for ROI analysis (many-to-one: multiple ad_spend rows per visitor row)
-- Create as view: CREATE OR REPLACE VIEW steep-demo.steep_demo_v2.fact_visitors AS
SELECT
    v.visitor_date,
    dd.date_key,
    v.network,
    v.channel,
    v.country,
    v.campaign_name,
    
    -- Composite key for joining from fact_ad_spend (many-to-one relationship)
    -- Format: date|network|channel|country|campaign_name
    CONCAT(
        v.visitor_date, '|',
        v.network, '|',
        v.channel, '|',
        v.country, '|',
        COALESCE(v.campaign_name, '')
    ) as visitor_key,
    
    -- Aggregated metrics
    v.total_sessions,
    v.total_visitors,
    v.total_conversions,
    v.total_page_views,
    v.avg_time_on_site_seconds,
    
    -- Calculated metrics (for convenience)
    ROUND(SAFE_DIVIDE(v.total_conversions, v.total_visitors) * 100, 2) as conversion_rate_pct,
    ROUND(SAFE_DIVIDE(v.total_page_views, v.total_sessions), 2) as avg_page_views_per_session
    
FROM `steep-demo.steep_demo_v2.raw_visitors` v
LEFT JOIN `steep-demo.steep_demo_v2.dim_date` dd ON v.visitor_date = dd.date
WHERE v.visitor_date <= CURRENT_DATE()
