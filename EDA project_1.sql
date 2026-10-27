/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouseAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called gold
	
WARNING:
    Running this script will drop the entire 'DataWarehouseAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'C:\Users\karti\OneDrive\Documents\dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'C:\Users\karti\OneDrive\Documents\dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'C:\Users\karti\OneDrive\Documents\fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO
SELECT *
FROM INFORMATION_SCHEMA.TABLES

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers'

--Explore all countries our customers come form 
SELECT DISTINCT country FROM gold.dim_customers

--Explore all categories "The major Divisions"
SELECT DISTINCT category,subcategory,product_name FROM gold.dim_products ORDER BY 1,2,3

--Find the date of the first and last order
--How many year of sales are available 
SELECT 
MIN(order_date) AS first_order_date,
MAX(order_date) AS last_order_date,
DATEDIFF(year,MIN(order_date),MAX(order_date)) AS order_range_months
FROM gold.fact_sales

--Find the youngest and the oldest customer
SELECT
MIN(birthdate) AS oldest_birthdate,
DATEDIFF(year,MIN(birthdate) , GETDATE()) AS oldest_age,
MAX(birthdate) AS youngest_birthdate,
DATEDIFF(year,MAX(birthdate) , GETDATE()) AS youngest_age
FROM gold.dim_customers

--Find the total sales
SELECT SUM(sales_amount)AS total_sales FROM gold.fact_sales

--Find how many items are sold 
SELECT SUM(quantity) AS total_quantity FROM gold.fact_sales

--Find the average selling price 
SELECT AVG(price) AS avg_price FROM gold.fact_sales

--Find the total number of orders 
SELECT COUNT(order_number) AS total_order FROM gold.fact_sales
SELECT COUNT(DISTINCT order_number) AS total_order FROM gold.fact_sales

--Find the total number of products 
SELECT COUNT(product_key) AS total_products FROM gold.dim_products

--Find the total number of customers 
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers

--Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.fact_sales

--Generate a report that shows all key metrics of the business
SELECT 'Total Sales' AS measure_name,SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity',SUM(quantity)FROM gold.fact_sales
UNION ALL
SELECT 'Average Price',AVG(price) FROM gold.fact_sales  
UNION ALL
SELECT 'Total Nr. Orders',COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr. Products',COUNT(product_key) FROM gold.dim_products
UNION ALL
SELECT 'Total Nr. Customers',COUNT(customer_key) FROM gold.dim_customers;

--Find total customers by countries
SELECT
country,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC

--Find the total customers by gender
SELECT 
gender,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC

--Find the total products by category
SELECT 
category,
COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC

--What is the average cost in each category
SELECT 
category,
AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC

--What is the total revenue generated for each category
SELECT 
category,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS d
ON d.product_key = f.product_key
GROUP BY category
ORDER BY total_revenue DESC

--What is the total revenue generated by each customer
SELECT 
d.customer_key,
d.first_name,
d.last_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS d
ON f.customer_key = d.customer_key
GROUP BY 
d.customer_key,
d.first_name,
d.last_name
ORDER BY total_revenue DESC

--What is the distribution of sold items across countries
SELECT
d.country,
SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS d
ON f.customer_key = d.customer_key
GROUP BY d.country
ORDER BY total_sold_items DESC

--Which 5 products generate the highest revenue
SELECT TOP 5
d.product_name,
SUM(f.sales_amount) AS total_revenue 
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS d
ON f.product_key = d.product_key
GROUP BY d.product_name
ORDER BY total_revenue DESC

--With window fuction 
SELECT *
FROM (
	SELECT 
	d.product_name,
	SUM(f.sales_amount) AS total_revenue,
	ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_products AS d
	ON f.product_key = d.product_key
	GROUP BY d.product_name) t
	WHERE rank_products <= 5

--What are the 5 worst-performing products in terms of sales 
SELECT TOP 5
d.product_name,
SUM(f.sales_amount) AS total_revenue 
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS d
ON f.product_key = d.product_key
GROUP BY d.product_name
ORDER BY total_revenue ASC

--Find the top 10 customers who have generated the highest revenue
SELECT TOP 10
d.customer_key,
d.first_name,
d.last_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS d
ON f.customer_key = d.customer_key
GROUP BY 
d.customer_key,
d.first_name,
d.last_name
ORDER BY total_revenue DESC

--The 3 customers with the fewest orders placed
SELECT TOP 3
d.customer_key,
d.first_name,
d.last_name,
COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS d
ON f.customer_key = d.customer_key
GROUP BY 
d.customer_key,
d.first_name,
d.last_name
ORDER BY total_orders

