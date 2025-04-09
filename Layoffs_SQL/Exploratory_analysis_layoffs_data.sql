
-- exploratory data analysis

select *
from layoffs_staging2;

select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;

select *
from layoffs_staging2
where percentage_laid_off = 1
order by total_laid_off desc;

select *
from layoffs_staging2
order by total_laid_off desc;

-- total people laidoff by each company or industry or country or year
select	company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

select	industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

select	country, sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc;

select	year(`date`), sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 2 desc;

select	stage, sum(total_laid_off)
from layoffs_staging2
group by stage
order by 2 desc;

-- timeline of data
select	min(`date`), max(`date`)
from layoffs_staging2;

-- the latest company in the list
SELECT *
FROM layoffs_staging2 
WHERE `date` = (SELECT MAX(`date`) FROM layoffs_staging2);

-- total of layoffs according to months

select	substring(`date`,6,2) as `month`, sum(total_laid_off)
from layoffs_staging2
group by `month`
;

select	substring(`date`,1,7) as `month`, sum(total_laid_off)
from layoffs_staging2
group by `month`
order by 1 asc;

-- using a cte for a rolling total(compounding)

with rolling_total as (
select	substring(`date`,1,7) as `month`, sum(total_laid_off) as total_off
from layoffs_staging2
group by `month`
order by 1 asc
)
select `month`, total_off,
sum(total_off) over(order by `month`) as rolling_total
from rolling_total;

-- seeing company wise layoff per year
select company,	year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
order by 3 desc;

select country,	year(`date`), sum(total_laid_off)
from layoffs_staging2
group by country, year(`date`)
order by 3 desc;

-- to rank companies according to year 

with company_year(company, years,total_laidoff)  as(
select company,	year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
)
select *, dense_rank() over(partition by years order by total_laidoff desc) as ranking
from company_year
where years is not null
;

-- above gave rankings each year wise, I want it together for each year, just ordering by ranking
with company_year(company, years,total_laidoff)  as(
select company,	year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
)
select *, dense_rank() over(partition by years order by total_laidoff desc) as ranking
from company_year
where years is not null
order by ranking asc;

-- maybe ranking year wise was okay but just top five would be good
with company_year(company, years,total_laidoff)  as(
select company,	year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
), 
company_year_rank as
(
select *, dense_rank() over(partition by years order by total_laidoff desc) as ranking
from company_year
where years is not null
)
select *
from company_year_rank
where ranking <=5;

-- indexing
 
create index idx_company_laidoff
on layoffs_staging2(company(50), total_laid_off);

select* from layoffs_staging2 where total_laid_off> 100;

-- company layoffs every year, pivoting with case
SELECT 
    company,
    SUM(CASE WHEN YEAR(`date`) = 2022 THEN total_laid_off ELSE 0 END) AS `2022`,
    SUM(CASE WHEN YEAR(`date`) = 2023 THEN total_laid_off ELSE 0 END) AS `2023`,
    SUM(CASE WHEN YEAR(`date`) = 2024 THEN total_laid_off ELSE 0 END) AS `2024`,
    SUM(CASE WHEN YEAR(`date`) = 2025 THEN total_laid_off ELSE 0 END) AS `2025`
FROM 
    layoffs_staging2
GROUP BY 
    company
    order by sum(total_laid_off) desc;
    
-- transations esure that a sequence of operations are executed completely or not at all. use start transaction; then commit;to execute or roleback to cancel;

-- correlation

SELECT CORR(total_laid_off, YEAR(`date`)) AS correlation
FROM layoffs_staging2;
 
SELECT 
    (COUNT(*) * SUM(total_laid_off * YEAR(`date`)) - SUM(total_laid_off) * SUM(YEAR(`date`))) /
    (SQRT((COUNT(*) * SUM(total_laid_off * total_laid_off) - SUM(total_laid_off) * SUM(total_laid_off))) * 
          (COUNT(*) * SUM(YEAR(`date`) * YEAR(`date`)) - SUM(YEAR(`date`)) * SUM(YEAR(`date`))))
AS correlation
FROM layoffs_staging2; 


-- percentile

SELECT 
    total_laid_off AS percentile_50
FROM (
    SELECT 
        total_laid_off,
        PERCENT_RANK() OVER (ORDER BY total_laid_off) AS percentile_rank
    FROM 
        layoffs_staging2
) AS ranked_layoffs
WHERE 
    percentile_rank >= 0.90
ORDER BY 
    percentile_rank
LIMIT 1;

select*from layoffs_staging2;
