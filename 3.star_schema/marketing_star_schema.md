# Marketing Funnel Data Model

## Olist Marketing Analytics Project

## 1. Overview

The marketing dataset was analyzed separately from the e-commerce dataset because it represents a customer acquisition process rather than transactional sales.

Unlike the e-commerce data, which is well suited for a star schema, the marketing dataset follows a funnel structure where leads progress through different stages before becoming sellers.

The analytical model was designed after completing data validation to ensure that business keys and table relationships were verified before analysis.

---

# 2. Why Not a Star Schema?

A traditional star schema was not used for the marketing dataset because:

* The dataset contains only two related business tables.
* There is no central transactional fact table.
* The data represents a sequential business process rather than repeated sales transactions.
* Most analyses are based on conversion rates and funnel progression.

For these reasons, a simple relational model is more appropriate than creating unnecessary dimensions.

---

# 3. Data Model

The analytical model consists of two tables.

## Olist Marketing Qualified Leads

This table represents the top of the marketing funnel.

Each row represents one Marketing Qualified Lead (MQL).

Key information includes:

* MQL ID
* First Contact Date
* Landing Page
* Lead Origin

---

## Olist Closed Deals

This table represents successful lead conversions.

Each row represents one seller acquired through the marketing process.

Key information includes:

* MQL ID
* Seller ID
* Business Segment
* Business Type
* Lead Type
* Monthly Revenue
* Product Catalog Size
* Deal Won Date

---

# 4. Relationship

The two tables are connected through the **mql_id** field.

```text
Olist_Marketing_Qualified_Leads
              │
              │ mql_id
              ▼
      Olist_Closed_Deals
```

Relationship:

**One Marketing Qualified Lead → Zero or One Closed Deal**

During validation:

* Every Closed Deal successfully matched an existing Marketing Qualified Lead.
* No orphan records were found.

---

# 5. Analytical Grain

### Marketing Qualified Leads

**Grain**

> One row = One Marketing Qualified Lead

---

### Closed Deals

**Grain**

> One row = One Converted Seller

---

# 6. Why This Model?

This structure allows analysis of the complete acquisition funnel without introducing unnecessary complexity.

It supports questions such as:

* How many qualified leads were generated?
* What is the overall conversion rate?
* Which acquisition channels perform best?
* Which lead sources generate high-quality sellers?
* Which business segments generate the highest revenue?
* How does seller profile relate to conversion?

---

# 7. Design Decisions

The model was finalized after completing data validation.

Validation confirmed that:

* mql_id is unique in both tables.
* No duplicate business keys exist.
* All Closed Deals reference a valid Marketing Qualified Lead.
* No negative revenue values exist.
* Missing values are limited to optional business attributes.

This validation ensured that the relationship between both tables is reliable for analysis.

---

# 8. How This Model Supports Analysis

The marketing data model forms the foundation for:

* Funnel conversion analysis
* Lead source performance
* Business segment analysis
* Revenue analysis
* Seller acquisition reporting

The same model will also support the Power BI marketing dashboard.

---

# 9. Conclusion

The marketing dataset is best represented as a simple relational funnel model rather than a traditional star schema.

This approach preserves the business process, keeps the model easy to understand, and provides a reliable foundation for marketing analytics and reporting.
