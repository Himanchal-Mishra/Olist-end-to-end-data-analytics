# Key Validation Insights

The data validation phase was performed after importing all datasets into SQL Server to verify data completeness, consistency, and relationships before analytical modeling.

## E-commerce Dataset

* Successfully validated **9 e-commerce tables** containing customers, orders, products, sellers, payments, reviews, and supporting lookup data.
* All core business entities (`customer_id`, `order_id`, `product_id`, `seller_id`) were verified as unique business keys.
* Composite business keys such as (`order_id`, `order_item_id`) and (`order_id`, `payment_sequential`) were validated successfully.
* No duplicate records were found in the Customers, Orders, Products, Sellers, Order Items, and Payments tables.
* The Reviews dataset contains duplicate `review_id` and `order_id` values, indicating that these fields cannot be treated as primary keys in the raw dataset.
* Referential integrity checks confirmed that all reviews reference valid orders.
* Product data contains missing metadata for a small number of products, while transactional tables remain largely complete.
* Order timestamp validation identified a small number of inconsistent records, along with **7,827 late deliveries**, providing a useful business insight for later analysis.
* Payment validation confirmed that all payment values are non-negative and identified **2,961 orders with multiple payment transactions**, representing valid customer payment behavior.
* Geolocation data contains repeated coordinate records, which is expected because multiple observations may exist for the same ZIP code.

## Marketing Dataset

* Successfully validated both marketing tables representing the seller acquisition funnel.
* All `mql_id` values are unique in both datasets.
* No duplicate records were found.
* Every closed deal maps to a valid Marketing Qualified Lead, confirming complete referential integrity.
* Missing values are primarily limited to optional business attributes such as catalog size and behaviour profile, while critical identifiers remain complete.
* No negative revenue or invalid catalog size values were identified.

## Overall Outcome

The validation process confirmed that the datasets are suitable for analytical modeling and dashboard development. Minor inconsistencies were documented rather than modified to preserve the integrity of the original data. The validated datasets provide a reliable foundation for the star schema, analytical SQL queries, and Power BI dashboards developed in the subsequent phases of this project.
