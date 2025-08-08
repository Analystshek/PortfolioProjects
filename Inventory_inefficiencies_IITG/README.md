# SOLVING INVENTORY INEFFICIENCIES AND OPTIMIZING Using SQL & Tableau

This project was built as part of a national competition hosted by the IIT Guwahati Consulting & Analyst Society. The goal was to solve real-world inventory management challenges faced by a fast-growing retail chain using SQL-driven analytics and business intelligence tools.

## PROBLEM STATEMENT

Urban Retail Co. is struggling with:
- Frequent stockouts of fast-moving SKUs
- Overstocking of slow-moving items
- Poor visibility into inventory performance across stores
- Lack of data-driven reorder and forecasting decisions

The company has access to sales, inventory, and warehouse data — but it's underutilized.

---

## OBJECTIVE

Design and implement a scalable, SQL-powered inventory monitoring system that:
- Detects stock inefficiencies
- Recommends reorder points based on demand
- Calculates key KPIs like inventory turnover and stockout rates
- Surfaces insights via a clean Tableau dashboard and business report

---

##  MY CONTRIBUTIONS

 **SQL ANALYTICS:**
  Wrote modular queries using joins, CTEs, CASE logic, and window functions to:
  - Identify stockouts and low inventory
  - Estimate reorder points using 7-day demand forecasting
  - Calculate inventory turnover at SKU and category levels

 **DATA MODELLING:** 
 Normalized raw inventory data into a clean relational schema:
  - Built an ERD with `Products`, `Stores`, `Inventory_Fact`, and `CompetitorPricing` tables

 **VISUALIZATION:** 
 Designed an interactive Tableau dashboard showing:
  - Stock health by store and category
  - Forecast vs actual demand
  - Sales performance by promotion, seasonality, and region

-  **BUSINESS REPORTING:** Compiled a concise executive summary report with actionable recommendations.

---

##  PROJECT STRUCTURE

```bash
├── README.md
├── /sql_scripts
│   └── inventory_queries.sql
├── /data
│   └── inventory_data_cleaned.xlsx
├── /visuals
│   ├── inventory_dashboard.twb (or PDF)
│   └── erd_diagram.png
├── executive_summary.pdf

