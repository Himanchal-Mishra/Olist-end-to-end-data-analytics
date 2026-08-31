# Olist E-Commerce & Marketing Analytics Dashboard

> End-to-end SQL Server and Power BI analytics project on the Brazilian Olist marketplace dataset, combining e-commerce transactions with marketing funnel analysis to generate actionable business insights.

## Project Overview

This project analyzes the **Olist Brazilian E-Commerce Dataset (2016–2018)** containing over **1.4 million records** across transactional, customer, seller, logistics, review, payment, and marketing datasets.

The objective was to build a complete analytics solution—from **SQL-based business analysis** to **Power BI dashboards**—that answers key business questions across sales performance, customer behavior, seller productivity, delivery operations, and marketing effectiveness.

---

## Business Objectives

- Analyze marketplace revenue and order trends.
- Identify high-performing product categories and sellers.
- Evaluate customer purchasing behavior and satisfaction.
- Measure delivery performance and its impact on customer reviews.
- Assess marketing channel effectiveness from lead generation to seller conversion.
- Build an interactive executive dashboard for business decision-making.

---

## Dashboard Overview

The Power BI dashboard consists of **5 interactive pages**, each answering a different business question.

| Dashboard Page | Focus |
|---------------|-------|
| Executive Overview | Overall business performance and KPIs |
| Customer & Sales Analysis | Customer behavior and regional sales |
| Seller Performance | Seller productivity and marketplace structure |
| Delivery & Customer Experience | Logistics performance and customer satisfaction |
| Marketing Funnel | Lead acquisition and seller conversion |

> Dashboard file: `dashboard/olist_analytics_dashboard.pbix`

---

## Key Business Insights

- **R$13.59M** total marketplace revenue generated from **99K orders**.
- **96K** unique customers purchased from **3K** sellers.
- **97%** of orders were successfully delivered.
- **91.89%** of deliveries arrived before the estimated delivery date.
- Late deliveries reduced customer ratings from approximately **4.3** to **2.3**, highlighting delivery reliability as a major driver of customer satisfaction.
- **Organic Search** generated the highest declared seller revenue (**R$51.4M**).
- **Paid Search** achieved the highest meaningful lead-to-seller conversion rate (**12.30%**).
- The **Top 10 sellers contributed approximately 13%** of marketplace revenue, indicating a diversified seller ecosystem.

---

## Technology Stack

- **SQL Server** (T-SQL)
- **Power BI**
- **DAX**
- **Star/Snowflake Data Modeling**
- **Markdown Documentation**
- **Git & GitHub**

---

## Dataset Overview

The project combines two business domains.

### E-Commerce Dataset

- Orders
- Order Items
- Customers
- Sellers
- Products
- Product Category Translation
- Payments
- Reviews

### Marketing Dataset

- Marketing Qualified Leads (MQL)
- Closed Deals

---

## Data Model

The project uses a **hybrid Star/Snowflake schema** optimized for Power BI.

### Core Relationships

```text
Customers → Orders → Fact_Order_Items
Payments → Orders
Reviews → Orders
Products → Fact_Order_Items
Sellers → Fact_Order_Items
Category Translation → Products
Marketing Qualified Leads ↔ Closed Deals (1:1 via mql_id)
```

- **Fact_Order_Items** serves as the central transaction table for sales analysis.
- Marketing analysis is modeled separately through a **1:1 relationship** between Marketing Qualified Leads and Closed Deals.

---

## SQL Analysis

Over **50 business-focused SQL queries** were written using:

- Joins
- Common Table Expressions (CTEs)
- Window Functions
- Aggregate Functions
- CASE Statements
- Ranking Functions

### Analysis Areas

- Revenue trends
- Customer behavior
- Product performance
- Seller productivity
- Delivery performance
- Payment analysis
- Marketing funnel conversion

SQL scripts are available in:

```text
analytical_insights/
├── ecommerce_analytical_insights.sql
└── marketing_analytical_insight.sql
```

---

## Power BI Dashboard Features

### Executive Overview

- Revenue KPIs
- Monthly Revenue Trend
- Revenue by State
- Payment Method Distribution
- Top Product Categories

### Customer & Sales

- Customer KPIs
- Monthly Orders Trend
- Top Cities by Revenue
- Revenue by State

### Seller Performance

- Seller KPIs
- Top Seller Cities
- Seller Distribution by State
- Top Sellers by Revenue

### Delivery & Customer Experience

- Delivery Success Rate
- Early vs Late Deliveries
- Customer Ratings by Delivery Status
- Delivery Days by Product Category
- Late Deliveries by State

### Marketing Funnel

- Marketing Funnel
- MQL by Lead Source
- Conversion Rate by Channel
- Revenue by Lead Source
- Business Segment Performance

---

## Key DAX Measures

Some important measures used in the dashboard include:

- Total Revenue
- Total Orders
- Average Order Value
- Delivery Success Rate
- Early Delivery Rate
- Late Delivery Rate
- Average Review Score
- Average Revenue per Seller
- Top 10 Seller Revenue Share
- Marketing Conversion Rate

---

## Repository Structure

```text
Olist-Analytics/
│
├── analytical_insights/
│   ├── ecommerce_analytical_insights.sql
│   └── marketing_analytical_insight.sql
│
├── dashboard/
│   └── olist_analytics_dashboard.pbix
│
├── data_source/
│   └── data_sources.md
│
├── project_profile/
│   ├── project_context.md
│   └── project_profiling.ipynb
│
├── star_schema/
│   ├── ecommerce_star_schema.md
│   └── marketing_star_schema.md
│
├── LICENSE
└── README.md
```

---

## Skills Demonstrated

- SQL Server
- T-SQL
- Power BI
- DAX
- Data Modeling
- Business Intelligence
- Dashboard Design
- KPI Development
- Marketing Analytics
- E-Commerce Analytics
- Data Storytelling

---

## Business Impact

This project demonstrates an end-to-end analytics workflow by:

- Designing a scalable dimensional data model.
- Performing SQL-based business analysis.
- Creating interactive Power BI dashboards with DAX.
- Translating raw data into executive-level business insights.
- Presenting actionable recommendations across sales, logistics, sellers, and marketing.

---

## Future Enhancements

- Seller drill-through pages
- Customer cohort analysis
- Sales forecasting
- Automated Power BI refresh pipeline
- Advanced geographic visualizations

---

## Author

**Himanchal**

Engineering Student | Aspiring Data Analyst

**Tech Stack:** SQL Server • Power BI • DAX • Data Modeling • Business Intelligence
