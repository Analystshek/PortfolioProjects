
use inventory_inefficiency;
select* from inventory_forecasting;
-- creating table 
CREATE TABLE inventory_dataset
like inventory_forecasting;
select* from inventory_dataset;

insert inventory_dataset
select *
from inventory_forecasting;

-- stock level calculations across stores and warehouses
-- stock levels by store and products
select store_id, product_id,
    SUM(inventory_level) as total_stock
from Inventory_Dataset
group by store_id, product_id
order by store_id, 
total_stock asc;
    
-- stock levels by region and product category
select region, category,
    SUM(inventory_level) as total_stock
from Inventory_Dataset
group by region, category
order by region, total_stock desc;
    
-- merging : stock levels by store, product, category and region
select store_id, product_id, category, region,                          
    SUM(inventory_level) as total_stock  
from Inventory_Dataset
group by store_id, product_id, category, region
order by store_id, total_stock asc;      

-- low inventory detection based on reorder points
-- finding products where the inventory level is below the reorder threshold/minimum quantity (30 units)
select store_id, product_id, category, region, inventory_level, demand_forecast, units_sold                       
from Inventory_Dataset
where inventory_level < 30       
order by store_id, inventory_level asc;  

-- Low Inventory Detection with Category-Based Reorder Thresholds
select store_id, product_id, category, region, inventory_level, units_sold, demand_forecast                   
from Inventory_Dataset
where 
-- Comparing inventory level to category specific reorder thresholds
    inventory_level < 
case
when category = 'Groceries' then 35
when category = 'Electronics' then 15
when category = 'Personal Care' then 20
when category = 'Home Essentials' then 15
when category = 'Seasonal' then 5
else 20  -- Default threshold if category is unknown
end
order by store_id, inventory_level asc;
    
-- Create a threshold table to store reorder points per category
create table Category_Reorder_Threshold (
    category VARCHAR(50) PRIMARY KEY,
    reorder_threshold INT);

-- Insert reorder levels for each product category
insert into Category_Reorder_Threshold (category, reorder_threshold) values
('Groceries', 35),
('Electronics', 10),
('Personal Care', 20),
('Home Essentials', 15),
('Seasonal', 5);

-- Low Inventory Detection with stock status
-- Uses JOIN to match reorder thresholds from separate table

select inv.store_id, inv.product_id, inv.category, inv.region, inv.inventory_level, inv.units_sold, inv.demand_forecast, crt.reorder_threshold,

-- Stock Status column
case
when inv.inventory_level < crt.reorder_threshold then 'Low Stock'
else 'Sufficient'
end as stock_status
from Inventory_Dataset as inv
join Category_Reorder_Threshold as crt on inv.category = crt.category
order by stock_status desc, inv.inventory_level asc;

-- This subquery calculates average demand per category
select category, round(avg(demand_forecast), 0) as reorder_threshold
from Inventory_Dataset
group by category;
   
-- Detect low stock based on avg demand per category
select inv.store_id, inv.product_id, inv.category, inv.region, inv.inventory_level, inv.units_sold, inv.demand_forecast,
    round(avg_df.reorder_threshold) as reorder_threshold,
case 
when inv.inventory_level < avg_df.reorder_threshold then 'Low Stock'
else 'Sufficient'
end as stock_status
from Inventory_Dataset as inv
join (select category, avg(demand_forecast) as reorder_threshold
from Inventory_Dataset
group by category)
as avg_df
on inv.category = avg_df.category
order by stock_status desc, inv.inventory_level asc;
    
-- Dynamic threshold with special treatment for 'Home Essentials' category
select inv.store_id, inv.product_id, inv.category, inv.region, inv.inventory_level, inv.units_sold, inv.demand_forecast,

-- Set reorder threshold conditionally
case
when inv.category = 'Home Essentials' then round(he.avg_forecast * 1.5)
else round(cat.avg_forecast)
end as reorder_threshold,

-- Stock status based on custom threshold logic
case 
when inv.category = 'Home Essentials' and inv.inventory_level < (he.avg_forecast * 1.5) then 'Low Stock'
when inv.category <> 'Home Essentials' and inv.inventory_level < cat.avg_forecast then 'Low Stock'
else 'Sufficient'
end as stock_status
from Inventory_Dataset as inv

-- JOIN for general category-wise average demand
join (select category, avg(demand_forecast) as avg_forecast
from Inventory_Dataset
where category <> 'Home Essentials'
group by category) as cat on inv.category = cat.category and inv.category <> 'Home Essentials'

-- JOIN for Home Essentials separately
left join(select category, avg(demand_forecast) as avg_forecast from Inventory_Dataset where category = 'Home Essentials' group by category)
    as he on inv.category = he.category
order by stock_status desc, inventory_level asc;
    
-- Reorder Point Estimation by Product
-- Estimating reorder point using avg forecast × 7-day lead time
select inv.product_id, inv.category, inv.store_id, inv.region,
-- Average forecast for this product
    round(avg(inv.demand_forecast), 2) as avg_forecast_per_day,
-- Reorder point = avg forecast × lead time (7 days)
    round(avg(inv.demand_forecast) * 7, 0) as reorder_point,
-- Latest inventory level (can be avg or MAX as well depending on structure)
    max(inv.inventory_level) as current_inventory,
-- Flag to suggest reorder
case
when max(inv.inventory_level) < avg(inv.demand_forecast) * 7 then 'Yes'
else 'No' 
end as reorder_needed
from Inventory_Dataset as inv
group by
    inv.product_id, inv.category, inv.store_id, inv.region
order by reorder_needed desc, current_inventory asc;
-- checking for reorder points with average demand forecast
select product_id,
round(avg(demand_forecast), 2) as avg_forecast,
round(avg(demand_forecast) * 7) as reorder_point,
    max(inventory_level) as current_inventory
from Inventory_Dataset
group by product_id;

-- Inventory Turnover Analysis
-- Measuring how efficiently each product's inventory is moving
select product_id, category, region,
-- Total units sold over time
    sum(units_sold) as total_units_sold,
-- Average inventory held over time
    round(avg(inventory_level), 2) as avg_inventory_level,
-- Inventory turnover calculation
    round(sum(units_sold) / nullif(avg(inventory_level), 0), 2) as inventory_turnover,
-- Interpretation for business decision
    case
when sum(units_sold) / nullif(avg(inventory_level), 0) >= 2 then 'High'
when sum(units_sold) / nullif(avg(inventory_level), 0) between 1 and 2 then 'Moderate'
else 'Low'
end as turnover_status
from Inventory_Dataset
group by product_id, category, region
order by inventory_turnover desc;

-- Inventory Turnover with Data-Driven Thresholds (dynamic version)

with turnover_base as (select product_id, category, region, sum(units_sold) as total_units_sold, avg(inventory_level) as avg_inventory_level,
round(sum(units_sold) / nullif(avg(inventory_level), 0), 2) as inventory_turnover
from Inventory_Dataset
group by product_id, category, region),
ranked as (select *,
-- Rank turnover using percentiles
ntile(4) over (order by inventory_turnover) as turnover_quartile from turnover_base)
select product_id, category, region, total_units_sold,
round(avg_inventory_level, 2) as avg_inventory_level, inventory_turnover,
-- Interpret turnover quartile
case 
when turnover_quartile = 4 then 'High'
when turnover_quartile = 3 then 'Moderate'
else 'Low'
end as turnover_status
from ranked
order by inventory_turnover desc;

-- Inventory KPI Summary Report 
-- Calculating base turnover KPIs
with base_kpis as (select product_id, category, region,
sum(units_sold) as total_units_sold,
avg(inventory_level) as avg_inventory_level,
round(sum(units_sold) / nullif(avg(inventory_level), 0), 2) as inventory_turnover
from Inventory_Dataset
group by product_id, category, region),

-- Rank inventory into quartiles to flag stockout-prone records
ranked_inventory AS (select product_id, category, region, inventory_level,
ntile(4) over (partition by product_id order by inventory_level)
as inventory_quartile 
from Inventory_Dataset),

-- Count stockout occurrences for each product (quartile = 1)
stockout_rate_calc AS (select product_id, category, region,
count(*) as total_days,
sum(case when inventory_quartile = 1 then 1 else 0 end) as stockout_days
from ranked_inventory
group by product_id, category, region)
-- Final summary joining base KPIs with stockout rate
select b.product_id, b.category, b.region, b.total_units_sold,
round(b.avg_inventory_level, 2) as avg_inventory_level, b.inventory_turnover,
-- Dynamic stockout rate based on bottom 25% inventory levels
round((s.stockout_days * 100.0) / s.total_days, 2) as stockout_rate_percent
from base_kpis b
join stockout_rate_calc s
on b.product_id = s.product_id
and b.category = s.category
and b.region = s.region
order by stockout_rate_percent desc, inventory_turnover desc;

-- designing a normaliz schema 
create table Products (product_id VARCHAR(10) PRIMARY KEY, category VARCHAR(40), price DECIMAL(10,2), seasonality VARCHAR(25));

-- details of each store
create table Stores (store_id VARCHAR(10) PRIMARY KEY, region VARCHAR(25));

-- The core fact table (daily inventory, sales, etc.)
create table Inventory_Fact (record_date DATE, store_id VARCHAR(10), product_id VARCHAR(10), 
	inventory_level INT, units_sold INT, units_ordered INT, demand_forecast FLOAT,
    discount INT, holiday_promotion BOOLEAN, weather_condition VARCHAR(25),
primary key (record_date, store_id, product_id),
foreign key (store_id) references Stores(store_id),
foreign key (product_id) references Products(product_id));

-- Separate pricing info
create table CompetitorPricing (record_date DATE, product_id VARCHAR(10), competitor_pricing DECIMAL(15,2),
primary key (record_date, product_id),
foreign key (product_id) references Products(product_id));

-- Populating Stores
insert ignore into Stores (store_id, region)
select store_id, MIN(region)
from Inventory_Dataset
group by store_id;

--  Populating Products
insert ignore into Products (product_id, category, price, seasonality)
select product_id, min(category), min(price), min(seasonality)
from Inventory_Dataset
group by product_id;

-- Populating Inventory_Fact
insert ignore into Inventory_Fact (
    record_date, store_id, product_id, inventory_level, units_sold,
    units_ordered, demand_forecast, discount, holiday_promotion, weather_condition)
select 
    record_date, store_id, product_id, inventory_level, units_sold,
    units_ordered, demand_forecast, discount, holiday_promotion, weather_condition
from Inventory_Dataset;

--  Populating CompetitorPricing
insert ignore into CompetitorPricing (record_date, product_id, competitor_pricing)
select record_date, product_id, max(competitor_pricing)
from Inventory_Dataset
group by record_date, product_id;

-- Adding Indexes
create index idx_inv_product on Inventory_Fact(product_id);
create index idx_inv_store on Inventory_Fact(store_id);
create index idx_inv_date on Inventory_Fact(record_date);

-- REFACTORED QUERIES BASED ON NORMALIZED SCHEMA
-- 1. STOCK LEVEL CALCULATIONS
-- Stock by store and product
select store_id, product_id, sum(inventory_level) as total_stock
from Inventory_Fact
group by store_id, product_id
order by store_id, total_stock asc;

-- Stock by region and category
select s.region, p.category, sum(f.inventory_level) as total_stock
from Inventory_Fact f
join Stores s on f.store_id = s.store_id
join Products p on f.product_id = p.product_id
group by s.region, p.category
order by s.region, total_stock desc;

-- Merging view: store, product, category, region
select f.store_id, f.product_id, p.category, s.region, SUM(f.inventory_level) AS total_stock
from Inventory_Fact f
join Stores s on f.store_id = s.store_id
join Products p on f.product_id = p.product_id
group by f.store_id, f.product_id, p.category, s.region
order by f.store_id, total_stock asc;

-- LOW INVENTORY DETECTION
-- Using fixed threshold (e.g. < 30)
select f.store_id, f.product_id, p.category, s.region, f.inventory_level, f.demand_forecast, f.units_sold
from Inventory_Fact f
join Products p on f.product_id = p.product_id
join Stores s on f.store_id = s.store_id
where f.inventory_level < 30
order by f.store_id, f.inventory_level asc;

-- Dynamic threshold based on category average forecast
select f.store_id, f.product_id, p.category, s.region, f.inventory_level, f.units_sold, f.demand_forecast,
       round(thresholds.reorder_threshold) as reorder_threshold,
       case when f.inventory_level < thresholds.reorder_threshold then 'Low Stock' else 'Sufficient' end as stock_status
from Inventory_Fact f
join Products p on f.product_id = p.product_id
join Stores s on f.store_id = s.store_id
join (select category, avg(demand_forecast) as reorder_threshold
    from Inventory_Fact f
    join Products p on f.product_id = p.product_id
    group by category) as thresholds on p.category = thresholds.category
order by stock_status desc, f.inventory_level asc;

-- Special logic for Home Essentials
select f.store_id, f.product_id, p.category, s.region, f.inventory_level, f.units_sold, f.demand_forecast,
case
when p.category = 'Home Essentials' then round(he.avg_forecast * 1.5)
else round(cat.avg_forecast)
end as reorder_threshold,
  case 
when p.category = 'Home Essentials' and f.inventory_level < he.avg_forecast * 1.5 then 'Low Stock'
when p.category <> 'Home Essentials' and f.inventory_level < cat.avg_forecast then 'Low Stock'
else 'Sufficient'
end as stock_status
from Inventory_Fact f
join Products p on f.product_id = p.product_id
join Stores s on f.store_id = s.store_id
left join (select category, avg(demand_forecast) as avg_forecast
from Inventory_Fact f
join Products p on f.product_id = p.product_id
where category = 'Home Essentials'
group by category) as he on p.category = he.category
join (select category, avg(demand_forecast) as avg_forecast
    from Inventory_Fact f
    join Products p on f.product_id = p.product_id
    where category <> 'Home Essentials'
    group by category) as cat on p.category = cat.category and p.category <> 'Home Essentials'
order by stock_status desc, f.inventory_level asc;

-- REORDER POINT ESTIMATION (7-day lead time)
select f.product_id, p.category, f.store_id, s.region,
       round(avg(f.demand_forecast), 2) as avg_forecast_per_day,
       round(avg(f.demand_forecast) * 7, 0) as reorder_point,
       max(f.inventory_level) as current_inventory,
       case when max(f.inventory_level) < avg(f.demand_forecast) * 7 then 'Yes' else 'No' end as reorder_needed
from Inventory_Fact f
join Products p on f.product_id = p.product_id
join Stores s on f.store_id = s.store_id
group by f.product_id, p.category, f.store_id, s.region
order by reorder_needed desc, current_inventory asc;

-- INVENTORY TURNOVER ANALYSIS (Dynamic)
with turnover_base as (
    select f.product_id, p.category, s.region,
           sum(f.units_sold) as total_units_sold,
           avg(f.inventory_level) as avg_inventory_level,
           round(sum(f.units_sold) / nullif(avg(f.inventory_level), 0), 2) as inventory_turnover
    from Inventory_Fact f
    join Products p on f.product_id = p.product_id
    join Stores s on f.store_id = s.store_id
    group by f.product_id, p.category, s.region),
   ranked as (select *, ntile(4) over (order by inventory_turnover) as turnover_quartile
    from turnover_base)
select product_id, category, region, total_units_sold,
       round(avg_inventory_level, 2) as avg_inventory_level,
       inventory_turnover,
case
           when turnover_quartile = 4 then 'High'
           when turnover_quartile = 3 then 'Moderate'
           else 'Low'
       end as turnover_status
from ranked
order by inventory_turnover desc;

-- KPI REPORT (Turnover + Stockout Rate)
with base_kpis as (select f.product_id, p.category, s.region,
           sum(f.units_sold) as total_units_sold,
           avg(f.inventory_level) as avg_inventory_level,
           round(sum(f.units_sold) / nullif(avg(f.inventory_level), 0), 2) as inventory_turnover
    from Inventory_Fact f
    join Products p on f.product_id = p.product_id
    join Stores s on f.store_id = s.store_id
    group by f.product_id, p.category, s.region),
ranked_inventory as (select f.product_id, p.category, s.region, f.inventory_level,
           ntile(4) over (partition by f.product_id order  by f.inventory_level) as inventory_quartile
    from Inventory_Fact f
    join Products p on f.product_id = p.product_id
    join Stores s on f.store_id = s.store_id),
stockout_rate_calc as (
    select product_id, category, region,
           count(*) as total_days,
           sum(case when inventory_quartile = 1 then 1 else 0 end) as stockout_days
    from ranked_inventory
    group by product_id, category, region)
select b.product_id, b.category, b.region, b.total_units_sold,
       round(b.avg_inventory_level, 2) as avg_inventory_level,
       b.inventory_turnover,
       round((s.stockout_days * 100.0) / s.total_days, 2) as stockout_rate_percent
from base_kpis b
join stockout_rate_calc s
on b.product_id = s.product_id and b.category = s.category and b.region = s.region
order by stockout_rate_percent desc, inventory_turnover desc;




