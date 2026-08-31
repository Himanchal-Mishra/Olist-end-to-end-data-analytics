-- marketing analysis - olist dataset
-- two tables here, checking them first

select top 5 * from [marketing].[olist_closed_deals]
select top 5 * from [marketing].[olist_marketing_qualified_leads]


-- ============================================
-- section a: funnel performance
-- ============================================

-- q1. total marketing qualified leads (mqls)
-- this is basically the top of the funnel - how many potential sellers
-- entered the pipeline at all
select
    count(*) as total_mqls
from marketing.olist_marketing_qualified_leads;

-- result: 8,000 mqls


-- q2. total closed deals
-- how many of those 8,000 actually converted into sellers
select
    count(*) as total_closed_deals
from marketing.olist_closed_deals;

-- result: 842 closed deals


-- q3. overall lead-to-seller conversion rate
select
    count(c.mql_id) as total_closed_deals,
    count(m.mql_id) as total_mqls,
    cast(
        count(c.mql_id) * 100.0 / count(m.mql_id)
        as decimal(5,2)
    ) as conversion_rate
from marketing.olist_marketing_qualified_leads m
left join marketing.olist_closed_deals c
    on m.mql_id = c.mql_id;

-- 842 out of 8,000 = 10.53% conversion rate.
-- so roughly 1 in 10 leads becomes an actual seller.
-- whether that's good or bad depends on industry benchmarks,
-- but the 89.47% drop-off is worth digging into by channel (q5 onwards)


-- q4. non-conversion breakdown (just flipping q3 to see the drop-off side)
select
    count(*) as total_mqls,
    count(c.mql_id) as converted_mqls,
    count(*) - count(c.mql_id) as unconverted_mqls,
    cast(
        (count(*) - count(c.mql_id)) * 100.0 / count(*)
        as decimal(5,2)
    ) as non_conversion_rate
from marketing.olist_marketing_qualified_leads m
left join marketing.olist_closed_deals c
    on m.mql_id = c.mql_id;

-- 7,158 leads didn't convert (89.47%). not necessarily alarming on its own
-- but if certain channels are driving most of those non-conversions,
-- that's where budget is being wasted


-- ============================================
-- section b: lead source analysis
-- ============================================

-- q5. which channels generate the most mqls?
select
    isnull(origin, 'unknown') as acquisition_channel,
    count(*) as total_mqls,
    cast(
        count(*) * 100.0 / sum(count(*)) over ()
        as decimal(5,2)
    ) as percentage_of_mqls
from marketing.olist_marketing_qualified_leads
group by
    origin
order by
    total_mqls desc;

-- organic search = highest mql volume, followed by paid search and social.
-- digital channels together are over 65% of total leads.
-- volume alone doesn't mean much though, need to check which channels
-- actually convert (q7)


-- q6. which channels generate the most closed deals?
select
    isnull(m.origin, 'unknown') as acquisition_channel,
    count(*) as total_closed_deals
from marketing.olist_closed_deals c
join marketing.olist_marketing_qualified_leads m
    on c.mql_id = m.mql_id
group by
    m.origin
order by
    total_closed_deals desc;

-- organic search leads here too. but the ranking shifts a bit compared
-- to q5 - some channels that sent a lot of leads don't show up as
-- strongly in closed deals, which is the whole point of q7


-- q7. which channels have the highest conversion rate?
-- this is the more useful cut - volume from q5/q6 doesn't matter
-- if the leads aren't converting
select
    isnull(m.origin, 'unknown') as acquisition_channel,
    count(m.mql_id) as total_mqls,
    count(c.mql_id) as closed_deals,
    cast(
        count(c.mql_id) * 100.0 / count(m.mql_id)
        as decimal(5,2)
    ) as conversion_rate
from marketing.olist_marketing_qualified_leads m
left join marketing.olist_closed_deals c
    on m.mql_id = c.mql_id
group by
    m.origin
order by
    conversion_rate desc;

-- paid search = highest conversion rate among the major channels.
-- social and email generate decent lead volume (q5) but convert poorly.
-- so those channels might look productive on a leads dashboard but
-- aren't actually delivering quality sellers


-- q8. which channels bring in sellers with the highest declared revenue?
select
    isnull(m.origin, 'unknown') as acquisition_channel,
    count(*) as total_sellers,
    cast(avg(c.declared_monthly_revenue) as decimal(15,2)) as avg_monthly_revenue,
    cast(sum(c.declared_monthly_revenue) as decimal(15,2)) as total_monthly_revenue
from marketing.olist_closed_deals c
join marketing.olist_marketing_qualified_leads m
    on c.mql_id = m.mql_id
where
    c.declared_monthly_revenue is not null
group by
    m.origin
order by
    avg_monthly_revenue desc;

-- organic search wins again here - most sellers and highest declared revenue.
-- so it's not just high volume, it's also better quality sellers.
-- note: declared_monthly_revenue is self-reported so take the exact
-- numbers with some skepticism, but the relative ranking across channels
-- is still useful


-- ============================================
-- section c: seller analysis
-- ============================================

-- q9. which business segments have the most converted sellers?
select
    business_segment,
    count(*) as total_sellers,
    cast(
        count(*) * 100.0 / sum(count(*)) over ()
        as decimal(5,2)
    ) as percentage_of_sellers
from marketing.olist_closed_deals
group by
    business_segment
order by
    total_sellers desc;

-- home decor and health beauty = top two segments by seller count.
-- top 5 segments together are close to half of all acquired sellers,
-- so acquisition is fairly concentrated in a handful of industries


-- q10. which business segments have the highest avg declared revenue?
-- wanted to split this from q9 since count and revenue tell different stories
select
    business_segment,
    count(*) as total_sellers,
    cast(avg(declared_monthly_revenue) as decimal(15,2)) as avg_monthly_revenue,
    cast(sum(declared_monthly_revenue) as decimal(15,2)) as total_monthly_revenue
from marketing.olist_closed_deals
where declared_monthly_revenue is not null
group by
    business_segment
order by
    avg_monthly_revenue desc;

-- construction tools/house garden and phone/mobile = highest avg revenue
-- per seller. these aren't the top segments by count (q9) but the sellers
-- that do come from these industries seem to be bigger businesses.
-- again, self-reported numbers, but the pattern is interesting


-- q11. does catalog size relate to seller revenue?
-- first just plotting the raw numbers to eyeball if there's a pattern

select
    declared_product_catalog_size,
    declared_monthly_revenue
from marketing.olist_closed_deals
where
    declared_product_catalog_size is not null
    and declared_monthly_revenue is not null
order by
    declared_product_catalog_size;

-- hard to read as a raw list, so bucketing it below


-- q11 (grouped). catalog size buckets vs avg revenue
select
    case
        when declared_product_catalog_size <= 10 then '0-10 products'
        when declared_product_catalog_size <= 50 then '11-50 products'
        when declared_product_catalog_size <= 100 then '51-100 products'
        else 'above 100 products'
    end as catalog_group,
    count(*) as sellers,
    cast(avg(declared_monthly_revenue) as decimal(15,2)) as avg_monthly_revenue
from marketing.olist_closed_deals
where
    declared_product_catalog_size is not null
    and declared_monthly_revenue is not null
group by
    case
        when declared_product_catalog_size <= 10 then '0-10 products'
        when declared_product_catalog_size <= 50 then '11-50 products'
        when declared_product_catalog_size <= 100 then '51-100 products'
        else 'above 100 products'
    end
order by
    min(declared_product_catalog_size);

-- no clear pattern between catalog size and revenue.
-- some sellers with very few products are generating high revenue,
-- which suggests product quality/niche matters more than just
-- listing a lot of products. bigger catalog doesn't automatically
-- mean bigger seller.


