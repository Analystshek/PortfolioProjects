-- INIT database
CREATE TABLE customers (
  customerID INT ,
  name VARCHAR(50),
  city VARCHAR(50)
);

INSERT INTO customers(customerID, name, city) VALUES (1,'alfred', 'chicago');
INSERT INTO customers(customerID, name, city) VALUES (2,'william', 'new jersey');
INSERT INTO customers(customerID, name, city) VALUES (3,'avi', 'delhi');

-- QUERY database
SELECT * FROM customers WHERE customerID = 1;

-- updating
UPDATE customers
SET name='v'
WHERE customerID=3;

SELECT * FROM customers;

SELECT*FROM customers
WHERE name='v' AND customerID>1;

-- SELECT * FROM customers
-- INTO OUTFILE 'C:\Users\ASUS\OneDrive\Documents\sql.xlsx';

INSERT INTO customers(customerID, name, city) VALUES (4,'avi', 'delhi');
INSERT INTO customers(customerID, name, city) VALUES (5,'avi', 'mumbai');

ALTER TABLE customers
add income int;

-- to insert values in a new column 
UPDATE customers 
SET income= 10000
WHERE name='alfred' OR customerID>4;
UPDATE customers 
SET income= 5000
WHERE name='v';


-- DROP COLUMN income;

SELECT * FROM customers;

SELECT * FROM customers
WHERE name='avi' OR 'alfred';

SELECT * FROM customers
WHERE name LIKE 'a%' ;

SELECT * FROM customers
WHERE name LIKE '_v_' AND customerID>4;

SELECT*FROM customers
WHERE income IS NULL;

UPDATE customers 
SET income= 6000
WHERE customerID=4;
UPDATE customers 
SET income= 8000
WHERE name='william';

INSERT INTO customers(customerID,name, city, income)VALUES (6,'greg', 'chicago', 2000);
SELECT*FROM customers;

-- grouping- aggregating data across rows that share common value in one or more columns.
-- to get the count of customers and avg income for each city

SELECT city, COUNT(customerID) AS num_customers,
AVG(income) AS avg_income
FROM customers
GROUP BY city;

-- filtering with having
SELECT city, COUNT(customerID) AS num_customers,
AVG(income) AS avg_income
FROM customers
GROUP BY city
HAVING avg_income>7000;

-- combining multiple aggregate functions
SELECT city, 
COUNT(customerID) AS num_customers,
AVG(income) AS avg_income,
MIN(income) AS min_income,
MAX(income) AS max_income
FROM customers
GROUP BY city;

-- new table

CREATE TABLE spends (
  customerID INT ,
  spend INT ,
  age INT
);
INSERT INTO spends(customerID, Spend, age) VALUES(1,7000,21);
INSERT INTO spends(customerID, Spend, age) VALUES(2,3000,37);
INSERT INTO spends(customerID, Spend, age) VALUES(3,6000,25);
INSERT INTO spends(customerID, Spend, age) VALUES(4,6000,27);
INSERT INTO spends(customerID, Spend, age) VALUES(6,4000,19);
INSERT INTO spends(customerID, Spend, age) VALUES(7,20000,56);


SELECT*FROM spends;

-- nowjoin these
-- inner join returnsrecord when there is a matching column
SELECT customers.name, customers.city, customers.income, spends.spend, spends.age
FROM customers
INNER JOIN spends ON customers.customerID = spends.customerID;

-- left join keeping all left table data even if it is not a match fills it with null

SELECT customers.name, customers.city, customers.income, spends.spend, spends.age
FROM customers
LEFT JOIN spends ON customers.customerID = spends.customerID;

-- Right keeping all righttable data even if it is not a match fills it with null
SELECT customers.name, customers.city, customers.income, spends.spend, spends.age
FROM customers
Right JOIN spends ON customers.customerID = spends.customerID;

-- cross join cartisian product of the values, SELECT customers.name spends.spend FROM customers CROSS JOIN spends; 
-- full outer join(not in mysql) used keeps all data even if it is not a match fills it with null
-- so to get full data together we can use left and right with union

CREATE TABLE info(
SELECT customers.name, customers.city, customers.income, spends.spend, spends.age
FROM customers
LEFT JOIN spends ON customers.customerID = spends.customerID
UNION
SELECT customers.name, customers.city, customers.income, spends.spend, spends.age
FROM customers
RIGHT JOIN spends ON customers.customerID = spends.customerID);
SELECT*FROM info;

-- advance filtering:
-- case conditional logic, new colums(temporary) base on conditions like an if-then-else statement
SELECT info.name, info.city,
CASE 
WHEN city IN ('chicago','new jersey') THEN 'north america'
WHEN city IN ('delhi','mumbai') THEN ' south asia'
ELSE 'other'
END AS region
FROM info;

-- subqueries: nesting queries iinside queriesALTER
SELECT name, city 
FROM customers 
WHERE customerID IN (SELECT customerID FROM spends WHERE spend>4000);
--

CREATE TABLE orders (
  customerID INT ,
  total_o INT ,
  order_date date);
  
INSERT INTO orders(customerID, total_o, order_date) VALUES(1,7,'2024-01-26');
INSERT INTO orders(customerID, total_o, order_date) VALUES(2,3,'2024-01-30');
INSERT INTO orders(customerID, total_o, order_date) VALUES(1,6,'2024-02-25');
INSERT INTO orders(customerID, total_o, order_date) VALUES(1,6,'2024-02-27');
INSERT INTO orders(customerID, total_o, order_date) VALUES(6,4,'2024-03-19');
INSERT INTO orders(customerID, total_o, order_date) VALUES(2,2,'2024-03-5');

-- row number is assigning a unique rank to each row, here ranking through order dates 
-- 1st second 3rd order of a customer, finding the first order placed by a customer 
SELECT customerID, order_date,
ROW_NUMBER() OVER (PARTITION BY customerID ORDER BY order_date DESC) AS order_rank
FROM orders;

-- ranking customers by total spending, rank() skips number when tie dense_rank() does not
SELECT 
customerID, spend,
rank()over (ORDER BY spend DESC) AS spend_rank,
dense_rank() over (ORDER BY spend DESC) AS dense_spend_rank
FROM spends;

-- LAG: Retrieves the total_o from the previous row within the same customerID partition.
-- LEAD: Retrieves the total_o from the next row within the same customerID partition.
-- PARTITION BY: Groups the data by customerID.
-- ORDER BY: Orders the rows by order_date within each partition.
-- IFNUL: replacing null values with 0 
SELECT
customerID, order_date, total_o AS order_qty,
IFNULL(LAG(total_o) over (Partition BY customerID ORDER BY order_date),0) AS prev_order_qty,
IFNULL(LEAD(total_o) over (Partition BY customerID ORDER BY order_date),0) AS next_order_qty
FROM orders;

-- common table expressions, a temporary result set makes queries more 
-- redable and breaks down complex queries

WITH cusOrders AS (
  SELECT customerID, COUNT(total_o) AS diff_orders
  from orders
  GROUP BY customerID
  )
  SELECT customerID, diff_orders
  FROM cusOrders
  WHERE diff_orders > 1;
  
  
 WITH TOrders AS (
  SELECT customerID, sum(total_o) AS total_orders
  from orders
  GROUP BY customerID
  )
  SELECT customerID, total_orders
  FROM TOrders
  ORDER BY total_orders DESC; 
 -- recursive CTEs, used for hierarchical data(eg employee hierarchy,category tree)
 
 CREATE TABLE employee (
  employeeID INT,
  managerID INT,
  empName VARCHAR(50),
  birthDate date,
  gender varchar(50)
 );

INSERT INTO employee(employeeID, managerID, empName, birthDate, gender) VALUES
(1, NULL, 'gill', '2000-01-26', 'female'), 
(2, 1, 'jil', '2001-01-30','female'),
(3, 2, 'billy', '1990-05-26','male'),
(4, 2, 'till', '2000-09-20','male'),
(5, 3, 'mill', '1999-08-02','female');

SELECT * FROM employee;

WITH RECURSIVE recursiveEmp AS ( 
   -- base case: get employee without a manager (CEO)
   SELECT employeeID, managerID, empName, 1 AS level
   FROM employee
   WHERE managerID IS NULL 
   UNION ALL 
   -- recursive case: find employees reporting to the previous
   SELECT e.employeeID, e.managerID, e.empName, re.level + 1
   FROM employee e
   JOIN recursiveEmp re ON e.managerID = re.employeeID 
)
SELECT * FROM recursiveEmp;
 
 -- to revise joins
 
 CREATE TABLE departments (
  employeeID INT,
  department VARCHAR(50) 
);

INSERT INTO departments(employeeID, department) VALUES
(1,  null),
(2, 'Pharmacy'),
(3, 'Clothing'),
(4, 'Furniture'),
(5, 'Grocery'),
(6, 'Grocery');

SELECT * FROM departments;

SELECT e.employeeID, e.empName, de.department
FROM employee e
LEFT JOIN  departments de ON e.employeeID = de.employeeID;


SELECT e.employeeID, e.empName, de.department
FROM employee e
RIGHT JOIN  departments de ON e.employeeID = de.employeeID;

-- string functions

SELECT empName, length(empName)AS len
FROM employee
-- ORDER BY len ASC; or
ORDER BY 2;

SELECT empName, UPPER(empName) AS UCASE
FROM employee;
-- OR LOWER

SELECT TRIM('      SKY     ');
SELECT RTRIM('      SKY     ');

SELECT empName, 
LEFT(empName, 3),
RIGHT(empName, 3),
SUBSTRING(empName,3,2),
-- substring(empName,the position to start from,total caracters to present)
-- say we want to find the mothn of birth
birthDate,
SUBSTRING(birthDate,6,2) AS birthMonth
FROM employee;


SELECT empName, 
REPLACE(empName, 'i','e')AS otherName,
LOCATE ('bi', empName),
CONCAT(empName,' ',REPLACE(empName, 'i','e') ) AS newName
FROM employee;

 
 -- window functions, similar to group by but they don't rool up data likeit
 CREATE TABLE empSalary(
  employeeID INT,
  Salary INT 
 );

INSERT INTO empSalary(employeeID, salary) VALUES
(1, 10000),
(2, 15000),
(3, 16000),
(4, 15000),
(5, 10000 ); 
 
-- group by   
SELECT gender, AVG(sal.salary) AS avgSal
   FROM employee e
   JOIN empSalary sal
       ON e.employeeID = sal.employeeID
   GROUP BY gender;
   
-- window function, here we can add other things like name without affecting the result.

SELECT empName, gender, AVG(salary) OVER(PARTITION BY gender) 
   FROM employee e
   JOIN empSalary sal
       ON e.employeeID = sal.employeeID;

SELECT empName, gender, sal.salary, 
sum(salary) OVER(PARTITION BY gender ORDER BY e.employeeID) AS rolling_table 
   FROM employee e
   JOIN empSalary sal
       ON e.employeeID = sal.employeeID;
       
 SELECT e.employeeID, empName, gender, sal.salary, 
ROW_NUMBER() OVER(PARTITION BY gender ORDER BY e.employeeID) AS row_num,
rank() OVER(PARTITION BY gender ORDER BY sal.salary desc) AS row_rank
   FROM employee e
   JOIN empSalary sal
       ON e.employeeID = sal.employeeID;
       
       
 create temporary TABLE	salaryOver5000
select *
from empSalary
where salary >= 15000;

select*from salaryOver5000;
       
-- stored procedure, way to save code to reuse that can be called
CREATE procedure bigSalary()
select *
from empSalary
where salary >= 10000;

call bigSalary();

 -- to continously use the whole script use drop table if exists tablename;
 describe empSalary;
    -- triggers and events
      insert into empSalary (employeeID, Salary) values(6, 30000);
      SELECT * FROM empSalary;
    
    delimiter $$
    create	trigger employeeInsert
      after insert on empSalary
      for each row 
      begin
		insert into employee (employeeID, Salary)
		values (new.employeeID, new.Salary);
      end $$
      DELIMITER ;
      
      insert into empSalary (employeeID, Salary) values(6, 30000);
      SELECT * FROM empSalary;