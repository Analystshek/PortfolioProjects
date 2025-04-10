# 🧾 Layoff Analysis Project

This project explores global layoff trends using SQL for data analysis and Tableau for data visualization. 
The dataset contains company-wise layoffs information including industry, country, year, and total laid-off employees.

---

## 📂 Tools Used

- **SQL (MySQL):** Data cleaning, exploration, and insights generation
- **Tableau:** Interactive dashboards for visual insights

---

## 🔍 Key Objectives

- Identify industries and companies with the highest layoffs
- Analyze trends over time and across regions
- Uncover patterns in layoff severity and startup layoffs

---

## 📊 Insights Extracted

- Top countries and companies with most layoffs
- Year-wise layoff distribution
- Layoffs as a percentage of company size
- Startup vs non-startup impact comparison
- Correlation between year and layoff
- percentile for total laid of
---

## 📁 Files Included

| File | Description |
|------|-------------|
| `layoff_analysis.sql` | All SQL queries and views |
| `dashboard/` | Tableau pdf and links |
| `README.md` | Project overview and documentation |

---

## 📌 Tableau Dashboard
- view interactive dashboard
[(https://public.tableau.com/views/layoffs_sql/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)](https://public.tableau.com/views/layoffs_sql/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

## 📈 Sample SQL Snippet

```sql
-- Companies with most layoffs
SELECT company, SUM(total_laid_off) AS total
FROM layoffs
GROUP BY company
ORDER BY total DESC
LIMIT 10;

## kaggle dataset link
[link] https://www.kaggle.com/datasets/swaptr/layoffs-2022
