-- ecommerce sales analysis - olist dataset
-- just exploring the data first to understand what's in each table

select top 5 * from ecommerce.olist_order_items
select top 5 * from ecommerce.olist_customers
select top 5 * from ecommerce.olist_orders
select top 5 * from ecommerce.olist_geolocation
select top 5 * from ecommerce.olist_products
select top 5 * from ecommerce.olist_order_payments
select top 5 * from ecommerce.olist_order_reviews
select top 5 * from ecommerce.olist_sellers
select top 5 * from ecommerce.product_category_name_translation


-- ============================================
-- Section A: Sales Overview
-- ============================================

-- Q1. total revenue
-- just the sum of price across all order items
select 
    cast(round(SUM(price),2) as decimal(15,2)) as Total_revenue 
from ecommerce.olist_order_items

-- result: 13,591,643.70
-- around 13.59M total. this is only product price, doesn't include freight.
-- will use this in the KPI card


-- Q2. total orders placed
select 
    Count(*) as total_orders
from ecommerce.olist_orders

-- result: 99,441 orders


-- Q3. total products sold
-- note: this counts order_items rows, so one order with 3 items = 3 here, not 1
select
    count(*) AS total_products_sold
from ecommerce.olist_order_items;

-- result: 112,650


-- Q4. average order value (AOV)
select
    cast(
        sum(oi.price) * 1.0 / count(distinct o.order_id)
        as decimal(10,2)
    ) as average_order_value
from ecommerce.olist_orders o
join ecommerce.olist_order_items oi
on o.order_id = oi.order_id;

-- result: 137.75
-- avg revenue per order. makes sense since most orders have just 1-2 items


-- combined version of Q1-Q4 so i don't have to run 4 separate queries
-- every time i want the kpi numbers
select
    cast(sum(price) as decimal(15,2)) as total_revenue,
    count(distinct order_id) as total_orders,
    count(*) as total_products_sold,
    cast(sum(price) * 1.0 / count(distinct order_id) as decimal(10,2))
        as average_order_value
from ecommerce.olist_order_items;


-- Q5. monthly sales trend
-- want to see if sales are growing over time or flat
select
    FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS products_sold,
    CAST(SUM(oi.price) AS DECIMAL(15,2)) AS total_revenue,
    CAST(SUM(oi.price) * 1.0 / COUNT(DISTINCT o.order_id) AS DECIMAL(10,2))
        AS average_order_value
from ecommerce.olist_orders o
join ecommerce.olist_order_items oi
    on o.order_id = oi.order_id
group by FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
order by sales_month;

-- data goes from sep 2016 to sep 2018.
-- sales ramp up through 2017, peak is nov 2017 (1,010,271.37) - probably black friday/
-- black november since that's a thing in brazil. stays decent through 2018 too.
-- sep 2018 looks really low but that's just because the data was probably pulled
-- mid-month, not an actual drop


-- Q6. month-over-month growth
-- wanted actual % numbers instead of just eyeballing the chart from Q5
with monthly_sales as
(
    select
        YEAR(o.order_purchase_timestamp) as sales_year,
        MONTH(o.order_purchase_timestamp) as sales_month,
        SUM(oi.price) as total_revenue
    from ecommerce.olist_orders o
    join ecommerce.olist_order_items oi
        on o.order_id = oi.order_id
    where o.order_purchase_timestamp >= '2016-10-01'
      and o.order_purchase_timestamp < '2018-09-01'
    group by
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp)
)

select
    sales_year,
    sales_month,
    cast(total_revenue as decimal(15,2)) as total_revenue,
    cast(
        LAG(total_revenue) over (order by sales_year, sales_month)
        as decimal(15,2)
    ) as previous_month_revenue,
    cast(
        (total_revenue - LAG(total_revenue) over (order by sales_year, sales_month)) * 100.0
        / NULLIF(LAG(total_revenue) over (order by sales_year, sales_month), 0)
        as decimal(10,2)
    ) as mom_growth_percent
from monthly_sales
order by sales_year, sales_month;

-- cut off before oct 2016 and after aug 2018 since those months had basically
-- no data and were messing up the growth %
--
-- nov 2017 = +52.10% growth, highest revenue month overall. matches what i
-- guessed in Q5. revenue dips a bit after that (normal post-peak behavior)
-- and then stays fairly stable through 2018, roughly between 0.84M-1.00M


-- =====================================
-- Section B: Customer Analysis
-- =====================================

-- Q7. customer overview - unique customers, repeat %, avg orders per customer
with customer_orders as(
    select c.customer_unique_id,
        count(o.order_id) as Total_orders
    from ecommerce.olist_customers c
    join ecommerce.olist_orders o
    on c.customer_id = o.customer_id
    group by c.customer_unique_id
)

select 
    count(customer_unique_id) as total_unique_customer,
    round(sum(case 
        when total_orders > 1 then 1 else 0
        end )*100.0 / count(*),2) as repeat_customer_percentage,
     avg(Total_orders)*1.00 as avg_order_per_customer
from customer_orders

-- repeat customer % came out pretty low. most people order once and
-- don't come back, which kind of makes sense for stuff like this dataset
-- (mostly one-off purchases, not subscription-type products)


-- Q8. top 10 highest spending customers
select top 10
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) as total_orders,
    CAST(SUM(oi.price) AS DECIMAL(15,2)) as total_spent,
    CAST(
        SUM(oi.price) * 1.0 / COUNT(DISTINCT o.order_id)
        AS DECIMAL(10,2)
    ) as average_order_value
from ecommerce.olist_customers c
join ecommerce.olist_orders o
    on c.customer_id = o.customer_id
join ecommerce.olist_order_items oi
    on o.order_id = oi.order_id
group by c.customer_unique_id
order by total_spent desc;

-- top spenders range from 4,590 to 13,440 in total spend.
-- checked their order counts too - most of them got there with like
-- 1-2 big orders, not lots of small repeat orders. so "highest spending"
-- here isn't really "most loyal", just worth keeping in mind


-- Q9. customer state performance
select
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) as unique_customers,
    COUNT(DISTINCT o.order_id) as total_orders,
    CAST(SUM(oi.price) AS DECIMAL(15,2)) as total_revenue,
    CAST(
        SUM(oi.price) * 1.0 / COUNT(DISTINCT o.order_id)
        AS DECIMAL(10,2)
    ) as average_order_value
from ecommerce.olist_customers c
join ecommerce.olist_orders o
    on c.customer_id = o.customer_id
join ecommerce.olist_order_items oi
    on o.order_id = oi.order_id
group by c.customer_state
order by total_revenue desc;

-- SP (Sao Paulo state) is way ahead - 5.20M revenue, ~40k unique customers.
-- makes sense, it's the biggest state population-wise too.
-- some smaller states had a noticeably higher AOV though even with way
-- fewer customers - worth a closer look, maybe niche/premium buyers there

-- quick takeaways for this section:
-- - SP drives the most volume so logistics/retention there matters most
-- - smaller states like PB, AC, AP punch above their weight on AOV,
--   could be worth testing more marketing spend there
-- - RJ and MG are already solid, room to push harder


-- Q10. top 10 cities by order count
select top 10
    c.customer_city,
    c.customer_state,
    count(distinct o.order_id) as total_orders,
    cast(sum(oi.price) as decimal(15,2)) as total_revenue,
    cast(
        sum(oi.price) * 1.0 / count(distinct o.order_id)
        as decimal(10,2)
    ) as average_order_value
from ecommerce.olist_customers c
join ecommerce.olist_orders o
    on c.customer_id = o.customer_id
join ecommerce.olist_order_items oi
    on o.order_id = oi.order_id
group by
    c.customer_city,
    c.customer_state
order by
    total_orders desc;

-- sao paulo (city) = 15,402 orders, 1.91M revenue, easily #1.
-- rio and a few others have lower order counts but spend more per order


-- =====================================
-- Section C: Product & Category Analysis
-- =====================================

-- Q11. category performance
select
    pct.product_category_name_english as category,
    count(*) as products_sold,
    sum(oi.price) as total_revenue,
    avg(oi.price) as average_price
from ecommerce.olist_order_items oi
join ecommerce.olist_products p
    on oi.product_id = p.product_id
join ecommerce.product_category_name_translation pct
    on p.product_category_name = pct.product_category_name
group by
    pct.product_category_name_english
order by
    total_revenue desc;

-- health_beauty = highest revenue category
-- bed_bath_table = highest volume (most units sold)
-- so volume leader and revenue leader aren't the same category, which
-- tells me some categories make money through price not quantity


-- Q12. category revenue contribution (% of total)
select
    pct.product_category_name_english as category,
    round(sum(oi.price),2) as total_revenue,
    round(sum(oi.price) * 100.0 /
    sum(sum(oi.price)) over (),2 ) as revenue_percentage
from ecommerce.olist_order_items oi
join ecommerce.olist_products p
    on oi.product_id = p.product_id
join ecommerce.product_category_name_translation pct
    on p.product_category_name = pct.product_category_name
group by
    pct.product_category_name_english
order by
    total_revenue desc;

-- health_beauty alone = 9.39% of total revenue, highest single share.
-- but no category is dominating completely, top 5 together are still
-- under half of total revenue. seems like a fairly diversified catalog


-- Q13. top 10 best-selling products (by revenue)
select top 10
    oi.product_id,
    pct.product_category_name_english as category,
    count(*) as products_sold,
    sum(oi.price) as total_revenue,
    avg(oi.price) as average_price
from ecommerce.olist_order_items oi
join ecommerce.olist_products p
    on oi.product_id = p.product_id
join ecommerce.product_category_name_translation pct
    on p.product_category_name = pct.product_category_name
group by
    oi.product_id,
    pct.product_category_name_english
order by
    total_revenue desc;

-- health_beauty shows up again here at product level too.
-- a couple of these products have low sales count but high avg price,
-- so they're "premium" products rather than bestsellers, still good revenue though


-- Q14. categories with highest freight cost
select
    pct.product_category_name_english as category,
    count(*) as products_sold,
    avg(oi.freight_value) as average_freight,
    sum(oi.freight_value) as total_freight
from ecommerce.olist_order_items oi
join ecommerce.olist_products p
    on oi.product_id = p.product_id
join ecommerce.product_category_name_translation pct
    on p.product_category_name = pct.product_category_name
group by
    pct.product_category_name_english
order by
    average_freight desc;

-- computers has the highest avg freight, then home appliances and furniture.
-- pretty much what you'd expect - bigger/heavier stuff costs more to ship


-- Q15. products where freight cost > product price
-- found this kind of by accident while checking freight numbers, but it's
-- actually a real issue worth flagging
select
    oi.product_id,
    pct.product_category_name_english as category,
    count(*) as occurrences,
    avg(oi.price) as average_price,
    avg(oi.freight_value) as average_freight,
    avg(oi.freight_value - oi.price) as average_extra_freight
from ecommerce.olist_order_items oi
join ecommerce.olist_products p
    on oi.product_id = p.product_id
join ecommerce.product_category_name_translation pct
    on p.product_category_name = pct.product_category_name
where oi.freight_value > oi.price
group by
    oi.product_id,
    pct.product_category_name_english
order by
    average_extra_freight desc;

-- there's a chunk of products where shipping literally costs more than
-- the item itself. probably low-priced/small items being shipped far
-- distances. these are likely losing money or barely breaking even
-- once you factor in logistics, even though the "sale" looks fine on paper


-- Q16. product weight vs price/freight
select
    case
        when p.product_weight_g <= 500 then '0 - 500 g'
        when p.product_weight_g <= 1000 then '501 - 1000 g'
        when p.product_weight_g <= 5000 then '1 - 5 kg'
        when p.product_weight_g <= 10000 then '5 - 10 kg'
        else 'Above 10 kg'
    end as weight_range,
    count(*) as products_sold,
    avg(oi.price) as average_price,
    avg(oi.freight_value) as average_freight
from ecommerce.olist_order_items oi
join ecommerce.olist_products p
    on oi.product_id = p.product_id
where p.product_weight_g is not null
group by
    case
        when p.product_weight_g <= 500 then '0 - 500 g'
        when p.product_weight_g <= 1000 then '501 - 1000 g'
        when p.product_weight_g <= 5000 then '1 - 5 kg'
        when p.product_weight_g <= 10000 then '5 - 10 kg'
        else 'Above 10 kg'
    end
order by
    min(p.product_weight_g);

-- yep, confirmed - price and freight both increase pretty consistently
-- with weight. not really a surprise but good to have the actual numbers


-- Q17. category profitability (revenue - freight, rough estimate)
-- not real profit since this ignores product cost/COGS, just revenue
-- minus shipping cost as a proxy
select
    pct.product_category_name_english as category,
    count(*) as products_sold,
    sum(oi.price) as total_revenue,
    sum(oi.freight_value) as total_freight,
    sum(oi.price) - sum(oi.freight_value) as estimated_profit,
    avg(oi.price - oi.freight_value) as average_profit_per_product
from ecommerce.olist_order_items oi
join ecommerce.olist_products p
    on oi.product_id = p.product_id
join ecommerce.product_category_name_translation pct
    on p.product_category_name = pct.product_category_name
group by
    pct.product_category_name_english
order by
    estimated_profit desc;

-- watches_gifts comes out on top here, ahead of health_beauty even though
-- health_beauty had higher raw revenue (Q11). makes sense - watches/gifts
-- probably ship lighter/cheaper so they keep more of the revenue.
-- good example of why revenue alone doesn't tell the full story


-- =====================================
-- Section D: Delivery & Logistics
-- =====================================

-- Q18. categories with highest late delivery %
select
    pct.product_category_name_english as category,
    count(*) as total_orders,
    sum(
        case
            when o.order_delivered_customer_date > o.order_estimated_delivery_date
            then 1 else 0
        end
    ) as late_deliveries,
    100.0 * sum(
        case
            when o.order_delivered_customer_date > o.order_estimated_delivery_date
            then 1 else 0
        end
    ) / count(*) as late_delivery_percentage
from ecommerce.olist_order_items oi
join ecommerce.olist_products p
    on oi.product_id = p.product_id
join ecommerce.product_category_name_translation pct
    on p.product_category_name = pct.product_category_name
join ecommerce.olist_orders o
    on oi.order_id = o.order_id
where o.order_delivered_customer_date is not null
group by
    pct.product_category_name_english
having count(*) >= 30  -- filtering out tiny categories, % isn't meaningful below this
order by
    late_delivery_percentage desc;

-- furniture/home comfort type categories and audio show up with the
-- worst late % - probably more handling steps involved = more chances
-- for delay


-- Q19. top 10 sellers by revenue
select top 10
    s.seller_id,
    s.seller_state,
    count(distinct oi.order_id) as total_orders,
    count(*) as products_sold,
    sum(oi.price) as total_revenue,
    sum(oi.price) * 1.0 / count(distinct oi.order_id) as average_order_value
from ecommerce.olist_sellers s
join ecommerce.olist_order_items oi
    on s.seller_id = oi.seller_id
group by
    s.seller_id,
    s.seller_state
order by
    total_revenue desc;

-- top seller did over 229k in sales. most of the top 10 are based in
-- sao paulo (state), not surprising given how much of the overall
-- marketplace activity is there


-- Q20. top 10 sellers by order volume
select top 10
    s.seller_id,
    s.seller_state,
    count(distinct oi.order_id) as total_orders,
    count(*) as products_sold,
    sum(oi.price) as total_revenue,
    sum(oi.price) * 1.0 / count(distinct oi.order_id) as average_order_value
from ecommerce.olist_sellers s
join ecommerce.olist_order_items oi
    on s.seller_id = oi.seller_id
group by
    s.seller_id,
    s.seller_state
order by
    total_orders desc;

-- top seller by volume = 1,854 orders. interesting that this is a
-- different list than Q19 (revenue) - so high order count doesn't
-- automatically mean highest revenue, depends on what they're selling


-- Q21. sellers with highest AOV (min 30 orders so it's not a fluke)
select top 10
    s.seller_id,
    s.seller_state,
    count(distinct oi.order_id) as total_orders,
    count(*) as products_sold,
    sum(oi.price) as total_revenue,
    sum(oi.price) * 1.0 / count(distinct oi.order_id) as average_order_value
from ecommerce.olist_sellers s
join ecommerce.olist_order_items oi
    on s.seller_id = oi.seller_id
group by
    s.seller_id,
    s.seller_state
having
    count(distinct oi.order_id) >= 30
order by
    average_order_value desc;

-- highest AOV seller = 1,687.63 per order. these "premium" sellers are
-- scattered across different states, not just concentrated in SP like
-- the volume leaders were


-- Q22. average delivery time by seller (fastest sellers)
select top 10
    s.seller_id,
    s.seller_state,
    count(distinct oi.order_id) as total_orders,
    avg(
        datediff(day, o.order_purchase_timestamp, o.order_delivered_customer_date)
    ) as average_delivery_days
from ecommerce.olist_sellers s
join ecommerce.olist_order_items oi
    on s.seller_id = oi.seller_id
join ecommerce.olist_orders o
    on oi.order_id = o.order_id
where
    o.order_delivered_customer_date is not null
group by
    s.seller_id,
    s.seller_state
having
    count(distinct oi.order_id) >= 30
order by
    average_delivery_days asc;

-- fastest sellers average around 4 days, and all of them are in SP again.
-- pattern keeps repeating - SP just has better logistics infra overall


-- Q23. sellers with highest late delivery %
select top 10
    s.seller_id,
    s.seller_state,
    count(distinct oi.order_id) as total_orders,
    sum(
        case
            when o.order_delivered_customer_date > o.order_estimated_delivery_date
            then 1 else 0
        end
    ) as late_deliveries,
    100.0 * sum(
        case
            when o.order_delivered_customer_date > o.order_estimated_delivery_date
            then 1 else 0
        end
    ) / count(distinct oi.order_id) as late_delivery_percentage
from ecommerce.olist_sellers s
join ecommerce.olist_order_items oi
    on s.seller_id = oi.seller_id
join ecommerce.olist_orders o
    on oi.order_id = o.order_id
where o.order_delivered_customer_date is not null
group by
    s.seller_id,
    s.seller_state
having count(distinct oi.order_id) >= 30
order by late_delivery_percentage desc;

-- worst seller here is late 37.21% of the time. bit surprising that
-- some of these are also SP sellers - so being in SP helps on average
-- but doesn't guarantee good delivery performance, still seller-specific

-- seller section takeaways:
-- - SP dominates revenue, volume, and speed, but individual seller
--   performance still varies a lot even within SP
-- - high order volume sellers aren't always the highest revenue ones
-- - might be worth flagging the worst late-delivery sellers for review


-- Q24. seller performance by state
select
    s.seller_state,
    count(distinct s.seller_id) as total_sellers,
    count(distinct oi.order_id) as total_orders,
    count(*) as products_sold,
    sum(oi.price) as total_revenue,
    sum(oi.price) * 1.0 / count(distinct s.seller_id) as average_revenue_per_seller
from ecommerce.olist_sellers s
join ecommerce.olist_order_items oi
    on s.seller_id = oi.seller_id
group by
    s.seller_state
order by
    total_revenue desc;

-- SP leads on basically everything in raw numbers, but a couple smaller
-- states (bahia, pernambuco) have higher avg revenue per seller - so
-- fewer sellers there but they're doing well individually


-- Q25. average delivery time (overall)
select
    count(*) as completed_orders,
    avg(
        datediff(day, order_purchase_timestamp, order_delivered_customer_date)
    ) as average_delivery_days,
    min(
        datediff(day, order_purchase_timestamp, order_delivered_customer_date)
    ) as minimum_delivery_days,
    max(
        datediff(day, order_purchase_timestamp, order_delivered_customer_date)
    ) as maximum_delivery_days
from ecommerce.olist_orders
where order_delivered_customer_date is not null;

-- 96,476 completed orders, avg 12 days delivery time. range is huge
-- though - 0 to 210 days. that max number seems extreme, might be a
-- data entry issue or a genuinely lost/delayed package, would want to
-- dig into that specific order if i had more time


-- Q26. delivery performance vs estimated date (on-time vs late)
select
    count(*) as total_delivered_orders,
    sum(
        case when order_delivered_customer_date <= order_estimated_delivery_date
        then 1 else 0 end
    ) as on_time_orders,
    sum(
        case when order_delivered_customer_date > order_estimated_delivery_date
        then 1 else 0 end
    ) as late_orders,
    100.0 * sum(
        case when order_delivered_customer_date > order_estimated_delivery_date
        then 1 else 0 end
    ) / count(*) as late_delivery_percentage,
    100.0 * sum(
        case when order_delivered_customer_date <= order_estimated_delivery_date
        then 1 else 0 end
    ) / count(*) as on_time_delivery_percentage
from ecommerce.olist_orders
where order_delivered_customer_date is not null;

-- 91.89% on-time, 8.11% late out of 96,476 orders. honestly better than
-- i expected going in


-- Q27. customer states with longest delivery times
select
    c.customer_state,
    count(distinct o.order_id) as total_orders,
    avg(
        datediff(day, o.order_purchase_timestamp, o.order_delivered_customer_date)
    ) as average_delivery_days
from ecommerce.olist_orders o
join ecommerce.olist_customers c
    on o.customer_id = c.customer_id
where
    o.order_delivered_customer_date is not null
group by
    c.customer_state
having
    count(distinct o.order_id) >= 30
order by
    average_delivery_days desc;

-- roraima, amapa, amazonas = longest delivery times (these are the
-- northern states, makes sense geographically since they're far from
-- the main SP/southeast hub). SP itself has the fastest delivery


-- Q28. categories with longest delivery time
select
    pct.product_category_name_english as category,
    count(distinct o.order_id) as total_orders,
    avg(
        datediff(day, o.order_purchase_timestamp, o.order_delivered_customer_date)
    ) as average_delivery_days
from ecommerce.olist_orders o
join ecommerce.olist_order_items oi
    on o.order_id = oi.order_id
join ecommerce.olist_products p
    on oi.product_id = p.product_id
join ecommerce.product_category_name_translation pct
    on p.product_category_name = pct.product_category_name
where
    o.order_delivered_customer_date is not null
group by
    pct.product_category_name_english
having
    count(distinct o.order_id) >= 30
order by
    average_delivery_days desc;

-- office furniture is slowest at ~20 days avg, with other furniture/home
-- categories not far behind. ties back to Q18 too - the slow categories
-- here mostly overlap with the ones that had higher late delivery %


-- Q29. average delay length for late orders specifically
select
    count(*) as late_orders,
    avg(
        datediff(day, order_estimated_delivery_date, order_delivered_customer_date)
    ) as average_delay_days,
    min(
        datediff(day, order_estimated_delivery_date, order_delivered_customer_date)
    ) as minimum_delay_days,
    max(
        datediff(day, order_estimated_delivery_date, order_delivered_customer_date)
    ) as maximum_delay_days
from ecommerce.olist_orders
where
    order_delivered_customer_date is not null
    and order_delivered_customer_date > order_estimated_delivery_date;

-- 7,827 late orders, avg delay is 8 days, worst case 188 days late.
-- so even though only ~8% of orders are late (Q26), when they are late
-- it's not just by a day or two, 8 days on average is a real delay


-- Q30. early / on-time / late breakdown (more detailed than Q26)
select
    delivery_status,
    total_orders,
    total_orders * 100.0 / sum(total_orders) over () as percentage_of_orders
from (
    select
        case
            when convert(date, order_delivered_customer_date) < convert(date, order_estimated_delivery_date)
                then 'Before Estimated Date'
            when convert(date, order_delivered_customer_date) = convert(date, order_estimated_delivery_date)
                then 'On Estimated Date'
            else 'After Estimated Date'
        end as delivery_status,
        count(*) as total_orders
    from ecommerce.olist_orders
    where order_delivered_customer_date is not null
    group by
        case
            when convert(date, order_delivered_customer_date) < convert(date, order_estimated_delivery_date)
                then 'Before Estimated Date'
            when convert(date, order_delivered_customer_date) = convert(date, order_estimated_delivery_date)
                then 'On Estimated Date'
            else 'After Estimated Date'
        end
) as delivery_summary
order by
    case delivery_status
        when 'Before Estimated Date' then 1
        when 'On Estimated Date' then 2
        else 3
    end;

-- 91.89% before estimated date, 1.34% exactly on the date, 6.77% after.
-- so basically almost everything arrives early or on time, which honestly
-- makes me think the estimated delivery dates might just be set
-- conservatively (padded) rather than delivery being THAT fast -
-- can't fully confirm that from this data alone though, just a guess


-- ============================================
-- section e: payment analysis
-- ============================================

-- q31. most frequently used payment methods
select
    payment_type,
    count(*) as total_transactions,
    count(distinct order_id) as total_orders,
    count(*) * 100.0 /
    sum(count(*)) over () as transaction_percentage
from ecommerce.olist_order_payments
group by
    payment_type
order by
    total_transactions desc;

-- credit card = almost 75% of all transactions, dominates by a lot.
-- boleto is second. voucher is interesting because same order can have
-- multiple voucher rows (partial payments stacked), so transaction count
-- there is a bit inflated vs actual orders


-- q32. revenue by payment method
select
    op.payment_type,
    count(distinct op.order_id) as total_orders,
    sum(op.payment_value) as total_revenue,
    avg(op.payment_value) as average_payment_value
from ecommerce.olist_order_payments op
group by
    op.payment_type
order by
    total_revenue desc;

-- credit card = 12.54m, boleto = 2.87m. voucher avg payment value is
-- the lowest of all methods, makes sense since vouchers are usually
-- discounts/promos being partially applied to an order


-- q33. average order value by payment method
-- doing this separately from q32 because avg(payment_value) in q32
-- counts each payment row, not each order. this one is more accurate
-- for aov since it sums per order first, then averages

with order_payments as (
    select
        order_id,
        payment_type,
        sum(payment_value) as order_value
    from ecommerce.olist_order_payments
    group by
        order_id,
        payment_type
)

select
    payment_type,
    count(*) as total_orders,
    sum(order_value) as total_revenue,
    avg(order_value) as average_order_value
from order_payments
group by
    payment_type
order by
    average_order_value desc;

-- credit card aov = 163.94, voucher = 98.15 (lowest).
-- people spending more tend to use cards, lower-spend orders lean on
-- vouchers. could also mean voucher users are more price-sensitive


-- q34. installment usage - what % of orders use installments vs single payment
with order_installments as (
    select
        order_id,
        max(payment_installments) as installments
    from ecommerce.olist_order_payments
    group by
        order_id
)

select
    case
        when installments <= 1 then 'single payment'
        else 'installment payment'
    end as payment_category,
    count(*) as total_orders,
    count(*) * 100.0 /
    sum(count(*)) over () as percentage_of_orders
from order_installments
group by
    case
        when installments <= 1 then 'single payment'
        else 'installment payment'
    end
order by
    total_orders desc;

-- 51.46% installments vs 48.54% single payment - basically a 50/50 split.
-- installments slightly edging out single payments suggests customers
-- really do rely on splitting payments here, probably because of how
-- common installment culture is in brazil (parcelamento)


-- ============================================
-- section f: customer review analysis
-- ============================================

-- quick peek at the translation table, needed this to verify category
-- names before writing the category rating query below
select top 5 * from ecommerce.product_category_name_translation


-- q35. overall average review score
select
    count(*) as total_reviews,
    cast(avg(review_score * 1.0) as decimal(10,2)) as average_review_score,
    min(review_score) as minimum_review_score,
    max(review_score) as maximum_review_score
from ecommerce.olist_order_reviews;

-- 99,224 reviews, avg score = 4.09 out of 5. pretty good overall.
-- but avg alone doesn't tell the full story, need the distribution (q36)


-- q36. review score distribution
select
    review_score,
    count(*) as total_reviews,
    cast(
        count(*) * 100.0 / sum(count(*)) over ()
        as decimal(5,2)
    ) as percentage_of_reviews
from ecommerce.olist_order_reviews
group by review_score
order by review_score;

-- 5-star = ~58% of all reviews, which pushes the avg up in q35.
-- 1-star is the second most common score which is a bit surprising -
-- pattern suggests customers are mostly happy, but when something goes
-- wrong they rate it harshly (not many 2 or 3 star "mediocre" reviews,
-- more of a polarized distribution)


-- q37. impact of delivery timing on review scores
select
    case
        when o.order_delivered_customer_date <= o.order_estimated_delivery_date
            then 'on-time delivery'
        else 'late delivery'
    end as delivery_status,
    count(*) as total_reviews,
    cast(avg(r.review_score * 1.0) as decimal(10,2)) as average_review_score
from ecommerce.olist_orders o
join ecommerce.olist_order_reviews r
    on o.order_id = r.order_id
where o.order_delivered_customer_date is not null
group by
    case
        when o.order_delivered_customer_date <= o.order_estimated_delivery_date
            then 'on-time delivery'
        else 'late delivery'
    end
order by average_review_score desc;

-- on-time = 4.29 avg, late = 2.57 avg. that's a 1.72 star drop just
-- from being late. this is probably the single most actionable finding
-- in the whole dataset - delivery timing is clearly driving a huge chunk
-- of review scores, more than almost anything else i've looked at


-- q38. average review score by product category
select
    pct.product_category_name_english as product_category,
    count(*) as total_reviews,
    cast(avg(r.review_score * 1.0) as decimal(10,2)) as average_review_score
from ecommerce.olist_order_reviews r
join ecommerce.olist_orders o
    on r.order_id = o.order_id
join ecommerce.olist_order_items oi
    on o.order_id = oi.order_id
join ecommerce.olist_products p
    on oi.product_id = p.product_id
left join ecommerce.product_category_name_translation pct
    on p.product_category_name = pct.product_category_name
group by
    pct.product_category_name_english
having
    count(*) >= 30  -- need enough reviews for the avg to be meaningful
order by
    average_review_score desc,
    total_reviews desc;

-- books = highest rated categories, furniture/office = lowest.
-- lines up with what i found in the delivery section - furniture takes
-- longer to deliver and has more late deliveries, so the bad review
-- scores there probably aren't just about the product itself,
-- it's the whole experience including shipping


-- ============================================
-- section g: business insight queries
-- (cross-section analysis pulling things together)
-- ============================================

-- q39. which states have high revenue but also slow delivery?
-- wanted to see if the big revenue states are actually getting served well

with state_metrics as (
    select
        c.customer_state,
        count(distinct o.order_id) as total_orders,
        sum(oi.price) as total_revenue,
        avg(
            datediff(day, o.order_purchase_timestamp, o.order_delivered_customer_date) * 1.0
        ) as avg_delivery_days
    from ecommerce.olist_orders o
    join ecommerce.olist_customers c
        on o.customer_id = c.customer_id
    join ecommerce.olist_order_items oi
        on o.order_id = oi.order_id
    where o.order_delivered_customer_date is not null
    group by
        c.customer_state
)

select
    customer_state,
    total_orders,
    cast(total_revenue as decimal(15,2)) as total_revenue,
    cast(avg_delivery_days as decimal(10,2)) as avg_delivery_days
from state_metrics
order by
    total_revenue desc;

-- sp = highest revenue and fastest delivery, which explains a lot of why
-- it dominates. the northern states that had slow delivery (from q27)
-- also have low revenue - probably a chicken-and-egg thing, bad delivery
-- experience = fewer repeat customers = lower revenue over time


-- q40. high revenue categories with poor ratings
-- checking if any category is making a lot of money but quietly has bad reviews

with category_metrics as (
    select
        pct.product_category_name_english,
        sum(oi.price) as revenue,
        avg(r.review_score * 1.0) as avg_rating,
        count(distinct o.order_id) as total_orders
    from ecommerce.olist_orders o
    join ecommerce.olist_order_items oi
        on o.order_id = oi.order_id
    join ecommerce.olist_products p
        on oi.product_id = p.product_id
    left join ecommerce.product_category_name_translation pct
        on p.product_category_name = pct.product_category_name
    join ecommerce.olist_order_reviews r
        on o.order_id = r.order_id
    group by
        pct.product_category_name_english
)

select
    product_category_name_english,
    total_orders,
    cast(revenue as decimal(15,2)) as revenue,
    cast(avg_rating as decimal(10,2)) as avg_rating
from category_metrics
order by
    revenue desc;

-- some categories doing solid revenue but with below-average ratings.
-- worth flagging these specifically because high revenue with poor reviews
-- is a warning sign - customers are buying but not satisfied, which
-- usually means churn risk down the line


-- q41. delivery timing vs review score (simplified version)
-- similar to q37 but just confirming the pattern holds as a standalone check

select
    case
        when o.order_delivered_customer_date <= o.order_estimated_delivery_date
        then 'on time'
        else 'late'
    end as delivery_status,
    cast(avg(r.review_score * 1.0) as decimal(10,2)) as avg_review_score,
    count(*) as reviews
from ecommerce.olist_orders o
join ecommerce.olist_order_reviews r
    on o.order_id = r.order_id
where o.order_delivered_customer_date is not null
group by
    case
        when o.order_delivered_customer_date <= o.order_estimated_delivery_date
        then 'on time'
        else 'late'
    end;

-- same result as q37, just a cleaner version. keeping both since q37 had
-- more detail on total review counts too


-- ============================================
-- summary of key findings (payment + reviews)
-- ============================================

/*
payment side:
- credit card dominates both usage (~75%) and revenue (12.54m)
- installments are slightly more common than single payments (51/49 split),
  typical for brazil where installment buying is a cultural norm
- voucher users tend to spend less per order, likely promo/discount driven

review side:
- overall avg is 4.09 which looks healthy, but the distribution matters:
  5-star is ~58%, but 1-star is the second most common score - very polarized
- delivery timing is the biggest driver of review scores by far.
  on-time = 4.29 avg vs late = 2.57 avg (1.72 star gap)
- furniture/home categories consistently get the worst ratings, which
  connects directly to the delivery delay findings from the earlier section

main thing i'd flag: fixing late deliveries would likely do more for
customer satisfaction than almost any other change. the 1.72 star gap is large.
*/
-- same result as Q37, just a cleaner version. keeping both since Q37 had
-- more detail on total review counts too



/* 
Revenue & Sales
The marketplace did ~13.59M in product revenue across 99,441 orders. Average order value was 137.75. 
Sales grew steadily through 2017, peaked hard in November 2017 (+52% MoM, 1.01M that month — almost certainly Black Friday/Black November), then settled into a stable 0.84M–1.00M range through 2018. 
Nothing alarming in the trend, just normal post-peak behavior.

Customers
96,000+ unique customers, but repeat purchase rate is very low — most people order once and don't come back. 
The top spenders (up to 13,440 total) mostly got there through one or two big purchases, not loyal repeat buying. 
São Paulo state dominates on volume (5.2M revenue, ~40k customers) but smaller northern states like PB and AC actually have higher AOV, suggesting a different buyer profile there.

Products & Categories
Health & Beauty is the revenue leader (9.39% of total). Bed Bath Table leads on volume. 
Watches & Gifts wins on estimated profit once freight is subtracted — meaning high revenue doesn't always mean most profitable. 
There are products where shipping literally costs more than the item price, which is a real margin problem hiding inside otherwise normal-looking sales numbers.

Delivery
Average delivery time is 12 days, 91.89% of orders arrive on time or early. 
But when orders are late, they're late by an average of 8 days — not just a day or two. 
Northern states (Roraima, Amapá, Amazonas) wait the longest. Furniture categories are consistently the slowest and most delayed. 
The 210-day maximum delivery is an outlier worth investigating separately.

Sellers
Top sellers by revenue and top sellers by volume are mostly different people — high order count doesn't automatically mean high revenue. 
All fastest-delivering sellers are in São Paulo. Some SP sellers still have late delivery rates up to 37%, so geography helps on average but isn't a guarantee. 
Bahia and Pernambuco have fewer sellers but higher revenue per seller than most other states.

Payments
Credit card = ~75% of transactions, 12.54M in revenue, highest AOV at 163.94. 
Installments vs single payments is almost exactly 50/50 (51.5% installments) — very normal for Brazil given how embedded installment culture is there. 
Voucher users spend the least per order, likely promo-driven buyers.

Reviews
Overall avg is 4.09/5 which looks good, but the distribution is polarized — 58% give 5 stars, and 1-star is the second most common rating. 
There aren't many 2s or 3s, people either love it or hate it. The single biggest driver of a bad review is late delivery: on-time orders average 4.29 stars, late orders average 2.57. 
That's a 1.72 star gap from one variable alone. Furniture categories get the worst ratings, which connects directly back to their delivery problems.

The one thing that ties everything together:
Delivery performance is the lever that affects almost everything else — review scores, customer retention, repeat purchase rate, and regional revenue gaps all connect back to it. 
Fixing late deliveries, especially for furniture categories and northern states, would likely have a bigger positive impact on the business than almost any other single change.
*/

SELECT
    seller_id,
    COUNT(*) AS cnt
FROM marketing.olist_closed_deals
GROUP BY seller_id
HAVING COUNT(*) > 1;

SELECT
    mql_id,
    COUNT(*)
FROM marketing.olist_closed_deals
GROUP BY mql_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) FROM marketing.olist_closed_deals;
SELECT COUNT(DISTINCT seller_id) FROM marketing.olist_closed_deals;