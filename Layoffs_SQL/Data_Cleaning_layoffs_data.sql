-- data cleaning

use world_layoffs;
select* from layoffs;


-- using staging to keep the raw data saved 
drop table if exists layoffs_staging;
CREATE TABLE layoffs_staging
like layoffs;
select* from layoffs_staging;

insert layoffs_staging
select *
from layoffs;


-- 1.identifying duplicates
-- numbering the rows hence if there is a duplicate it will have >1 , to filter that we can use a subquery or cte
select* ,
row_number() over( partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, funds_raised) as row_num
from layoffs_staging;


with duplicate_cte as
(
select* ,
row_number() over( partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, funds_raised) as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num > 1;

-- checking for a particular company

select *
from layoffs_staging
where company = 'Amazon';

-- to delete duplicate rows, creating a new table with all duplicates

drop table if exists layoffs_staging2;
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` text,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised` double DEFAULT NULL,
  row_num int 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


insert into layoffs_staging2
select* ,
row_number() over( partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, funds_raised) as row_num
from layoffs_staging;

delete
from layoffs_staging2 
where row_num >1;

-- checking again
select *
from layoffs_staging2
where company = 'Amazon';

-- 2.standardizing data

select company, trim(company)
from layoffs_staging2;

update layoffs_staging2
set company = trim(company);


select distinct industry
from layoffs_staging2
order by 1;

-- just to use % operator
insert into layoffs_staging2(industry) values ( 'Crypto currency');

select*
from layoffs_staging2
where industry like 'Crypto%';

update layoffs_staging2
set industry = ' Crypto'
where industry like 'Crypto%';

select distinct location
from layoffs_staging2
order by 1;

UPDATE layoffs_staging2
SET location = TRIM(BOTH ']' FROM TRIM(BOTH '[' FROM location))
WHERE location LIKE '%[%]%';

UPDATE layoffs_staging2
SET location = REPLACE(REPLACE(replace(location, '''', ''), 'Non-U.S.', ''), ',','');

select distinct location, trim(location)
from layoffs_staging2
order by 1;
update layoffs_staging2
set location = trim(location);

-- now
select distinct country
from layoffs_staging2
order by 1;

select `date`
from layoffs_staging2;

-- changing the format ot the columns text to date
select `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

-- the above didn't work there is time also
SELECT `date`,
       DATE(STR_TO_DATE(`date`, '%Y-%m-%dT%H:%i:%s.%fZ')) 
FROM layoffs_staging2;

update layoffs_staging2
set `date` = DATE(STR_TO_DATE(`date`, '%Y-%m-%dT%H:%i:%s.%fZ')) ;

select *
from layoffs_staging2;


-- changing the data type
alter table layoffs_staging2
modify column `date` date;

-- removing null or repopulating blanks
select *
from layoffs_staging2
where industry = '';

select *
from layoffs_staging2
where company = 'Appsmith';

select t1.industry, t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2 
	on t1.company = t2.company
where(t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoffs_staging2
set industry = null
where industry = '';

update layoffs_staging2 t1
join layoffs_staging2 t2 
	on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null
and t2.industry is not null;


-- for removing null
insert into layoffs_staging2(company, location, industry, total_laid_off,percentage_laid_off, `date`, stage, country, funds_raised) 
values ( 'Appsmith','Sf Bay Area','Travel', '50','0.2', '2022-03-06' ,'Series B','United States', 90);

-- deleting rows that can be useless 

select *
from layoffs_staging2
where (total_laid_off is null or total_laid_off = '')
and (percentage_laid_off is null or percentage_laid_off = '');

delete
from layoffs_staging2
where (total_laid_off is null or total_laid_off = '')
and (percentage_laid_off is null or percentage_laid_off = '');

-- deleting row_num
alter table layoffs_staging2
drop column row_num;

-- leftover data cleaning

UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE total_laid_off = '';

-- checking if any values in the column can't be converted to int 
SELECT total_laid_off
FROM layoffs_staging2
WHERE total_laid_off NOT REGEXP '^[0-9]+$';


UPDATE layoffs_staging2
SET total_laid_off = CAST(ROUND(CAST(total_laid_off AS DECIMAL(10, 2))) AS UNSIGNED)
WHERE total_laid_off IS NOT NULL;

alter table layoffs_staging2
modify column total_laid_off int;