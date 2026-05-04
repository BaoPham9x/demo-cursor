-- Fact: Ad Spend
-- Create as view: CREATE OR REPLACE VIEW steep-demo.steep_demo_v2.fact_ad_spend AS
SELECT
    a.ad_spend_id,
    a.network,
    a.channel,
    a.campaign_name,
    a.country,
    a.currency,
    a.amount,
    a.conversions,
    a.created_at,
    -- Composite key for joining to fact_visitors (many-to-one relationship)
    -- Format: date|network|channel|country|campaign_name
    CONCAT(
        CAST(DATE(a.created_at) AS STRING), '|',
        a.network, '|',
        a.channel, '|',
        a.country, '|',
        COALESCE(a.campaign_name, '')
    ) as visitor_key
FROM `steep-demo.steep_demo_v2.raw_ad_spend` a
WHERE DATE(a.created_at) <= CURRENT_DATE()
