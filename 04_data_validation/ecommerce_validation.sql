USE OlistAnalytics;
GO

-- Customers
SELECT COUNT(*) AS customer_count
FROM ecommerce.olist_customers;

-- Orders
SELECT COUNT(*) AS order_count
FROM ecommerce.olist_orders;

-- Order Items
SELECT COUNT(*) AS order_item_count
FROM ecommerce.olist_order_items;

-- Payments
SELECT COUNT(*) AS payment_count
FROM ecommerce.olist_order_payments;

-- Reviews
SELECT COUNT(*) AS review_count
FROM ecommerce.olist_order_reviews;

-- Products
SELECT COUNT(*) AS product_count
FROM ecommerce.olist_products;

-- Sellers
SELECT COUNT(*) AS seller_count
FROM ecommerce.olist_sellers;

-- Geolocation
SELECT COUNT(*) AS geolocation_count
FROM ecommerce.olist_geolocation;

-- Category Translation
SELECT COUNT(*) AS category_translation_count
FROM ecommerce.product_category_name_translation;


/* customer table validation */


-- Check customer key uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customer_unique_ids
FROM ecommerce.olist_customers;

-- Check missing values
SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS customer_unique_id_nulls,
    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS zip_code_nulls,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS state_nulls
FROM ecommerce.olist_customers;

-- Check duplicate customer IDs
SELECT customer_id, COUNT(*) AS occurrences
FROM ecommerce.olist_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check customer geographic coverage
SELECT
    COUNT(DISTINCT customer_city) AS unique_cities,
    COUNT(DISTINCT customer_state) AS unique_states
FROM ecommerce.olist_customers;

/*The customer dataset contains customers from 4,119 unique cities across 27 Brazilian states, 
indicating broad geographic coverage suitable for regional sales and customer behavior analysis.*/

-- Check for invalid state codes
SELECT DISTINCT customer_state
FROM ecommerce.olist_customers
WHERE LEN(customer_state) <> 2;

/*All customer state codes follow the expected two-character Brazilian state format.*/


-- ORDERS VALIDATION

-- Check order key uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids
FROM ecommerce.olist_orders;

-- Check missing values
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulls,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS status_nulls,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS purchase_nulls,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS approved_nulls,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS carrier_nulls,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS delivered_nulls,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS estimated_nulls
FROM ecommerce.olist_orders;

/*The Orders table contains 99,441 records with a unique order_id for every transaction. 
Missing values are limited to approval and delivery-related timestamps, 
which are expected for cancelled, unavailable, or undelivered orders. 
No missing values were found in key business fields. */

-- Check for duplicate order IDs
SELECT
    order_id,
    COUNT(*) AS occurrences
FROM ecommerce.olist_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Approval date should not be before purchase date
SELECT COUNT(*)
FROM ecommerce.olist_orders
WHERE order_approved_at < order_purchase_timestamp;

-- Delivered before payment approval
SELECT COUNT(*)
FROM ecommerce.olist_orders
WHERE order_delivered_customer_date < order_approved_at;

-- Orders delivered later than estimated
SELECT COUNT(*)
FROM ecommerce.olist_orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;

-- Delivery before carrier pickup
SELECT COUNT(*)
FROM ecommerce.olist_orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;


/*Timestamp validation identified no orders approved before purchase. 
However, 61 orders were delivered before payment approval and 23 orders showed delivery occurring before carrier handoff, indicating minor timestamp inconsistencies. 
Additionally, 7,827 orders were delivered later than the estimated delivery date, highlighting a potential logistics performance issue. */



--ORDER ITEMS VALIDATION

-- Business key validation
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id,'-',order_item_id)) AS unique_order_items
FROM ecommerce.olist_order_items;

-- Null value validation
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulls,
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS order_item_id_nulls,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS product_id_nulls,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS seller_id_nulls,
    SUM(CASE WHEN shipping_limit_date IS NULL THEN 1 ELSE 0 END) AS shipping_limit_nulls,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS price_nulls,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS freight_nulls
FROM ecommerce.olist_order_items;

/*The Order Items table contains 112,650 records with no missing values across key attributes. 
The combination of order_id and order_item_id uniquely identifies each record, 
confirming the expected item-level grain of the dataset. */

-- Duplicate check
SELECT order_id, order_item_id, COUNT(*) AS occurrences
FROM ecommerce.olist_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


-- Invalid pricing
SELECT COUNT(*) AS invalid_price_rows
FROM ecommerce.olist_order_items
WHERE price <= 0
   OR freight_value <= 0;   

-- Freight cost higher than product price
SELECT COUNT(*) AS freight_greater_than_price
FROM ecommerce.olist_order_items
WHERE freight_value > price;

--4,124 order items have freight charges higher than the product price. 
--These records were retained, as they likely represent low-value products with relatively high shipping costs rather than invalid data.

-- Check for invalid product prices
SELECT COUNT(*) AS invalid_price
FROM ecommerce.olist_order_items
WHERE price <= 0;


-- Check for zero or negative freight charges
SELECT COUNT(*) AS zero_or_negative_freight
FROM ecommerce.olist_order_items
WHERE freight_value <= 0;

/*The Order Items table contains no invalid product prices. 
A total of 383 records have zero freight charges, which are considered valid business cases such as free shipping or promotional offers. 
Additionally, 4,124 order items have freight costs greater than the product price, 
indicating high shipping costs for low-value products rather than data quality issues. */

---------------------------------------------------------------------------------------------------------------------------------------
--ORDER ITEMS VALIDATION
---------------------------------------------------------------------------------------------------------------------------------------

-- Check product key uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids
FROM ecommerce.olist_products;


-- Check missing values
SELECT
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS product_id_nulls,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS category_nulls,
    SUM(CASE WHEN product_name_lenght IS NULL THEN 1 ELSE 0 END) AS name_length_nulls,
    SUM(CASE WHEN product_description_lenght IS NULL THEN 1 ELSE 0 END) AS description_nulls,
    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS photos_nulls,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS weight_nulls,
    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS length_nulls,
    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS height_nulls,
    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS width_nulls
FROM ecommerce.olist_products;


-- Check duplicate product IDs
SELECT
    product_id,
    COUNT(*) AS occurrences
FROM ecommerce.olist_products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- Check invalid product dimensions
SELECT COUNT(*) AS invalid_dimensions
FROM ecommerce.olist_products
WHERE product_weight_g <= 0
   OR product_length_cm <= 0
   OR product_height_cm <= 0
   OR product_width_cm <= 0;


-- Check unusually heavy products
SELECT COUNT(*) AS heavy_products
FROM ecommerce.olist_products
WHERE product_weight_g > 30000;


-- Check unusually large products
SELECT COUNT(*) AS oversized_products
FROM ecommerce.olist_products
WHERE product_length_cm > 200
   OR product_height_cm > 200
   OR product_width_cm > 200;

-- Products without category
SELECT COUNT(*) AS products_without_category
FROM ecommerce.olist_products
WHERE product_category_name IS NULL;

------------------------------------------------------------------------------------------------------------

SELECT *
FROM ecommerce.olist_products
WHERE product_weight_g <= 0
   OR product_length_cm <= 0
   OR product_height_cm <= 0
   OR product_width_cm <= 0;

/* The Products table contains 32,951 unique products with no duplicate product IDs. 
Product metadata is missing for 610 products, while only 2 products have missing physical dimensions. 
One unusually heavy product was identified as an outlier, and no oversized products were found. 
These records were retained as they represent source data rather than import errors.
------------------------------------------------------------------------------------------------------------
Four products have a recorded weight of 0 grams. Their dimensions are valid, 
indicating that the weight is likely missing or incorrectly recorded rather than representing an invalid product. 
These records were retained for analysis.
------------------------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------------------------------------------------
-- sellers Validation 
--------------------------------------------------------------------------------------------------------------------------

-- Check seller key uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS unique_seller_ids
FROM ecommerce.olist_sellers;

-- Check missing values
SELECT
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS seller_id_nulls,
    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS zip_code_nulls,
    SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
    SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS state_nulls
FROM ecommerce.olist_sellers;


-- Check duplicate seller IDs
SELECT
    seller_id,
    COUNT(*) AS occurrences
FROM ecommerce.olist_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- Check seller geographic coverage
SELECT
    COUNT(DISTINCT seller_city) AS unique_cities,
    COUNT(DISTINCT seller_state) AS unique_states
FROM ecommerce.olist_sellers;

-- Check invalid state codes
SELECT DISTINCT seller_state
FROM ecommerce.olist_sellers
WHERE LEN(seller_state) <> 2;

/* 
The Sellers table contains 3,095 unique sellers with no missing values or duplicate seller IDs. 
Sellers are distributed across 611 cities and 23 Brazilian states. 
All state codes follow the expected two-character format, indicating good data quality for seller and geographic analysis.
*/

--------------------------------------------------------------------------------------------------------------------------------------------
-- Payments Validation
---------------------------------------------------------------------------------------------------------------------------------------------

-- Check payment key uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential)) AS unique_payment_records
FROM ecommerce.olist_order_payments;

select count(*), count(distinct(order_id)) as needed from ecommerce.olist_order_payments

--combination of both is the unique key here in the table of payment.

-- Check missing values
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulls,
    SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) AS payment_seq_nulls,
    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) AS payment_type_nulls,
    SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) AS installments_nulls,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS payment_value_nulls
FROM ecommerce.olist_order_payments;


-- Check duplicate payment records
SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS occurrences
FROM ecommerce.olist_order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;


-- Check negative payment amounts
SELECT COUNT(*) AS negative_payment_values
FROM ecommerce.olist_order_payments
WHERE payment_value < 0;

-- Check invalid installments
SELECT COUNT(*) AS negative_installments
FROM ecommerce.olist_order_payments
WHERE payment_installments < 0;

-- List available payment methods
SELECT DISTINCT payment_type
FROM ecommerce.olist_order_payments
ORDER BY payment_type;

-- Orders paid using multiple payment records
SELECT COUNT(*) AS orders_with_multiple_payments
FROM (
    SELECT order_id
    FROM ecommerce.olist_order_payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS t;

-- A total of 2,961 orders were paid using multiple payment transactions. 
--This is valid business behavior and indicates that the payment dataset operates at the payment transaction level rather than the order level.

/*
The Payments table contains 103,886 payment records with no missing values, duplicate records, or invalid payment amounts. 
The combination of order_id and payment_sequential uniquely identifies each payment transaction. 
Five valid payment methods were identified, and 2,961 orders were paid using multiple payment transactions, reflecting legitimate customer payment behavior.
*/

---------------------------------------------------------------
--Review Validation 
---------------------------------------------------------------

-- Check review key uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    COUNT(DISTINCT order_id) AS unique_order_ids
FROM ecommerce.olist_order_reviews;

-- Check missing values
SELECT
    SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) AS review_id_nulls,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulls,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS review_score_nulls,
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) AS review_title_nulls,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS review_message_nulls,
    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS creation_date_nulls,
    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS answer_timestamp_nulls
FROM ecommerce.olist_order_reviews;


SELECT COUNT(*) AS duplicate_review_ids
FROM (
    SELECT review_id
    FROM ecommerce.olist_order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
) AS t;


 SELECT COUNT(*) AS duplicate_order_ids
FROM (
    SELECT order_id
    FROM ecommerce.olist_order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS t;

-- Check duplicate review IDs
SELECT
    review_id,
    COUNT(*) AS occurrences
FROM ecommerce.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

-- Check invalid review scores
SELECT COUNT(*) AS invalid_review_scores
FROM ecommerce.olist_order_reviews
WHERE review_score NOT BETWEEN 1 AND 5;

-- Review created before purchase
SELECT COUNT(*) AS reviews_before_purchase
FROM ecommerce.olist_order_reviews r
JOIN ecommerce.olist_orders o
    ON r.order_id = o.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp;

-- Review created before delivery
SELECT COUNT(*) AS reviews_before_delivery
FROM ecommerce.olist_order_reviews r
JOIN ecommerce.olist_orders o
    ON r.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND r.review_creation_date < o.order_delivered_customer_date;


-- Seller responded before review creation
SELECT COUNT(*) AS invalid_response_timestamp
FROM ecommerce.olist_order_reviews
WHERE review_answer_timestamp < review_creation_date;

-- Reviews without matching orders
SELECT COUNT(*) AS orphan_reviews
FROM ecommerce.olist_order_reviews r
LEFT JOIN ecommerce.olist_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


/* The Reviews table contains 99,224 records. 
Validation confirmed that neither review_id nor order_id is unique, with 789 duplicate review IDs and 547 duplicate order IDs. 
Review scores are fully valid (1–5), and all reviews reference an existing order. 
Missing review titles and messages are expected because many customers submitted ratings without written feedback.
*/

---------------------------------------------------
--Geolocation Validation
---------------------------------------------------

-- Check total records and unique ZIP codes
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_codes
FROM ecommerce.olist_geolocation;


-- Check missing values
SELECT
    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS zip_nulls,
    SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) AS latitude_nulls,
    SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) AS longitude_nulls,
    SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
    SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) AS state_nulls
FROM ecommerce.olist_geolocation;


-- Check duplicate geolocation records
SELECT COUNT(*) AS duplicate_records
FROM (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state,
        COUNT(*) AS cnt
    FROM ecommerce.olist_geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    HAVING COUNT(*) > 1
) AS t;


-- Check latitude and longitude range
SELECT COUNT(*) AS invalid_coordinates
FROM ecommerce.olist_geolocation
WHERE geolocation_lat NOT BETWEEN -90 AND 90
   OR geolocation_lng NOT BETWEEN -180 AND 180;

-- Check invalid state codes
SELECT COUNT(*) AS invalid_state_codes
FROM ecommerce.olist_geolocation
WHERE LEN(geolocation_state) <> 2;

-- Inspect rows with missing coordinates
SELECT TOP 20 *
FROM ecommerce.olist_geolocation
WHERE geolocation_lat IS NULL
   OR geolocation_lng IS NULL;

/*
The Geolocation table contains 1,000,163 records covering 19,015 ZIP code prefixes. 
Duplicate geographic records are expected because multiple coordinate observations exist for the same ZIP code. 
No invalid coordinate ranges or state codes were found. 
A small number of missing coordinate values were identified after import and should be reviewed. 
*/


--------------------------------
--Product Category Translation Validation
--------------------------------

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ecommerce'
  AND TABLE_NAME = 'product_category_name_translation';

EXEC sp_rename
'ecommerce.product_category_name_translation.Column1',
'product_category_name',
'COLUMN';

EXEC sp_rename
'ecommerce.product_category_name_translation.Column2',
'product_category_name_english',
'COLUMN';

select * from ecommerce.product_category_name_translation

-- Check category key uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_category_name) AS unique_categories
FROM ecommerce.product_category_name_translation;

-- Check missing values
SELECT
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS category_name_nulls,
    SUM(CASE WHEN product_category_name_english IS NULL THEN 1 ELSE 0 END) AS english_name_nulls
FROM ecommerce.product_category_name_translation;

-- Check duplicate category names
SELECT
    product_category_name,
    COUNT(*) AS occurrences
FROM ecommerce.product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- Check empty English translations
SELECT COUNT(*) AS empty_translations
FROM ecommerce.product_category_name_translation
WHERE LTRIM(RTRIM(product_category_name_english)) = '';

SELECT *
FROM ecommerce.product_category_name_translation
WHERE product_category_name = 'product_category_name';

DELETE
FROM ecommerce.product_category_name_translation
WHERE product_category_name = 'product_category_name';

SELECT COUNT(*)
FROM ecommerce.product_category_name_translation;
