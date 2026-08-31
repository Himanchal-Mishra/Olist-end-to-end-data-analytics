-- MARKETING VALIDATION


---------------------------
--Marketing qualifies leads
---------------------------

SELECT TOP 5 *
FROM marketing.olist_marketing_qualified_leads;

-- Check MQL key uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT mql_id) AS unique_mql_ids
FROM marketing.olist_marketing_qualified_leads;


-- Check missing values
SELECT
    SUM(CASE WHEN mql_id IS NULL THEN 1 ELSE 0 END) AS mql_id_nulls,
    SUM(CASE WHEN first_contact_date IS NULL THEN 1 ELSE 0 END) AS contact_date_nulls,
    SUM(CASE WHEN landing_page_id IS NULL THEN 1 ELSE 0 END) AS landing_page_nulls,
    SUM(CASE WHEN origin IS NULL THEN 1 ELSE 0 END) AS origin_nulls
FROM marketing.olist_marketing_qualified_leads;


-- Check duplicate MQL IDs
SELECT
    mql_id,
    COUNT(*) AS occurrences
FROM marketing.olist_marketing_qualified_leads
GROUP BY mql_id
HAVING COUNT(*) > 1;


-- Check missing landing page IDs
SELECT COUNT(*) AS missing_landing_pages
FROM marketing.olist_marketing_qualified_leads
WHERE landing_page_id IS NULL;

-- Check lead origin distribution
SELECT
    origin,
    COUNT(*) AS lead_count
FROM marketing.olist_marketing_qualified_leads
GROUP BY origin
ORDER BY lead_count DESC;

-- Lead origin distribution
SELECT
    ISNULL(origin, 'Missing') AS origin,
    COUNT(*) AS lead_count
FROM marketing.olist_marketing_qualified_leads
GROUP BY origin
ORDER BY lead_count DESC;

/*
The Marketing Qualified Leads table contains 8,000 unique lead records with no duplicate MQL IDs. 
The origin field has 60 missing values, while the remaining records are distributed across 10 distinct lead acquisition channels. 
Organic Search is the largest source of qualified leads, followed by Paid Search and Social.
*/

---------------------------
--closed deal validation 
---------------------------

-- Check closed deal key uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT mql_id) AS unique_mql_ids
FROM marketing.olist_closed_deals;

-- Check missing values
SELECT
    SUM(CASE WHEN mql_id IS NULL THEN 1 ELSE 0 END) AS mql_id_nulls,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS seller_id_nulls,
    SUM(CASE WHEN sdr_id IS NULL THEN 1 ELSE 0 END) AS sdr_id_nulls,
    SUM(CASE WHEN sr_id IS NULL THEN 1 ELSE 0 END) AS sr_id_nulls,
    SUM(CASE WHEN won_date IS NULL THEN 1 ELSE 0 END) AS won_date_nulls,
    SUM(CASE WHEN business_segment IS NULL THEN 1 ELSE 0 END) AS business_segment_nulls,
    SUM(CASE WHEN lead_type IS NULL THEN 1 ELSE 0 END) AS lead_type_nulls,
    SUM(CASE WHEN lead_behaviour_profile IS NULL THEN 1 ELSE 0 END) AS behaviour_profile_nulls,
    SUM(CASE WHEN has_company IS NULL THEN 1 ELSE 0 END) AS has_company_nulls,
    SUM(CASE WHEN has_gtin IS NULL THEN 1 ELSE 0 END) AS has_gtin_nulls,
    SUM(CASE WHEN average_stock IS NULL THEN 1 ELSE 0 END) AS average_stock_nulls,
    SUM(CASE WHEN business_type IS NULL THEN 1 ELSE 0 END) AS business_type_nulls,
    SUM(CASE WHEN declared_product_catalog_size IS NULL THEN 1 ELSE 0 END) AS catalog_size_nulls,
    SUM(CASE WHEN declared_monthly_revenue IS NULL THEN 1 ELSE 0 END) AS revenue_nulls
FROM marketing.olist_closed_deals;

-- Check duplicate MQL IDs
SELECT
    mql_id,
    COUNT(*) AS occurrences
FROM marketing.olist_closed_deals
GROUP BY mql_id
HAVING COUNT(*) > 1;


-- Check negative revenue
SELECT COUNT(*) AS negative_revenue
FROM marketing.olist_closed_deals
WHERE declared_monthly_revenue < 0;

-- Check negative catalog size
SELECT COUNT(*) AS negative_catalog_size
FROM marketing.olist_closed_deals
WHERE declared_product_catalog_size < 0;


-- Closed deals without a matching MQL
SELECT COUNT(*) AS orphan_closed_deals
FROM marketing.olist_closed_deals cd
LEFT JOIN marketing.olist_marketing_qualified_leads m
ON cd.mql_id = m.mql_id
WHERE m.mql_id IS NULL;


/*
The Closed Deals table contains 842 unique converted leads with no duplicate MQL IDs. 
All records successfully map to the Marketing Qualified Leads table, confirming referential integrity. 
Missing values are primarily concentrated in optional business attributes such as catalog size and behaviour profile, 
while critical identifiers and revenue information remain complete.
/*


