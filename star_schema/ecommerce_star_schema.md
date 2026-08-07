# Star Schema Design

## Olist E-Commerce Analytics Project

## 1. Overview

After profiling, importing, and validating the Olist dataset, a logical star schema was designed to organize the data for business analysis and dashboard development.

The original dataset consists of multiple normalized tables representing customers, orders, products, sellers, payments, reviews, and supporting lookup information. While this structure is suitable for storing transactional data, it requires multiple joins for analytical queries.

A star schema simplifies these relationships by placing business transactions at the center and surrounding them with descriptive dimensions. This structure improves query readability, simplifies dashboard development, and follows common data warehousing practices.

> **Note:** This is a logical analytical model used for reporting and visualization. The raw SQL tables remain unchanged.

---

# 2. Why a Star Schema?

The star schema was chosen because it:

* Simplifies analytical queries
* Reduces complex joins during reporting
* Organizes business entities into dimensions
* Improves Power BI data modelling
* Reflects how analytical data is commonly structured in data warehouses

---

# 3. Fact Table

## Fact_Order_Items

The analytical model is centered around **Fact_Order_Items**.

Each row represents **one product sold within one order**.

This grain was selected because:

* A single order may contain multiple products.
* Different products within the same order may have different sellers.
* Revenue, freight cost, product performance, and seller performance are all measured at the item level.

Using the order item as the fact table provides greater analytical flexibility than using the orders table.

### Fact Table Grain

**1 row = 1 product sold in 1 order**

---

# 4. Dimension Tables

The following dimension tables provide descriptive information for the fact table.

## Dim_Customers

Contains customer-related information such as:

* Customer ID
* Customer Unique ID
* City
* State
* ZIP Code

Used for customer segmentation and geographic analysis.

---

## Dim_Orders

Contains order-level attributes including:

* Order Status
* Purchase Date
* Approval Date
* Delivery Dates
* Estimated Delivery Date

Used for delivery performance and order lifecycle analysis.

---

## Dim_Products

Contains product information including:

* Product Category
* Product Dimensions
* Product Weight

Used for product performance and category analysis.

---

## Dim_Sellers

Contains seller information including:

* Seller ID
* Seller City
* Seller State

Used for seller performance analysis.

---

## Dim_Order_Payments

Contains payment information including:

* Payment Method
* Installments
* Payment Amount

Used for payment behaviour analysis.

---

## Dim_Order_Reviews

Contains customer review information including:

* Review Score
* Review Title
* Review Message
* Review Dates

During validation it was observed that neither **review_id** nor **order_id** is unique in the raw review dataset. Therefore, this table is treated as a supporting analytical dimension rather than a source for defining primary keys.

---

## Dim_Geolocation

Contains ZIP code level geographic coordinates.

Used for map visualizations and regional analysis when required.

---

## Dim_Product_Category_Translation

Maps Portuguese product categories to English category names.

Used to improve dashboard readability.

---

# 5. Conceptual Schema

```
                    Dim_Customers
                           |
                           |
                      Dim_Orders
                           |
                           |
Dim_Products ---- Fact_Order_Items ---- Dim_Sellers
                           |
                           |
                  Dim_Order_Payments
                           |
                           |
                   Dim_Order_Reviews
                           |
                           |
                    Dim_Geolocation
                           |
                           |
          Dim_Product_Category_Translation
```

---

# 6. Why Fact_Order_Items Instead of Orders?

The Orders table stores one record per order, whereas Order Items stores one record for each product purchased.

Since most business metrics are calculated at the product level, using Fact_Order_Items enables analysis such as:

* Product sales
* Revenue
* Freight costs
* Seller performance
* Category performance

without losing transaction-level detail.

---

# 7. How This Model Supports Analysis

This analytical model enables business questions such as:

* What are the best-selling product categories?
* Which sellers generate the highest revenue?
* Which states contribute the most sales?
* How long do deliveries take?
* Which payment methods are most commonly used?
* Does delivery performance influence customer ratings?

The same model also serves as the foundation for the Power BI dashboard.

---

# 8. Design Decision

The star schema was created **after completing data validation**.

This ensured that:

* Business keys were verified.
* Duplicate records were identified.
* Missing values were understood.
* Relationships between tables were validated before designing the analytical model.

Designing the schema after validation provides a more reliable analytical foundation than creating it before examining the quality of the data.

---

# 9. Conclusion

The star schema provides a clean analytical structure for the Olist dataset while preserving the original transactional tables.

It serves as the foundation for the SQL analysis and Power BI dashboards developed in the later stages of this project.
