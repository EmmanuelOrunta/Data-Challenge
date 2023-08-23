-- DATA CLEANING PROCESS
-- 1.  REPLACING NULL VALUES

-- products table
UPDATE products
SET product_category_name = 'N/A'
WHERE product_category_name IS NULL;

UPDATE products
SET product_name_lenght = '0'
WHERE product_name_lenght IS NULL;

UPDATE products
SET product_description_lenght = '0'
WHERE product_description_lenght IS NULL;

UPDATE products
SET product_photos_qty = '0'
WHERE product_photos_qty IS NULL;

-- order_reviews table
UPDATE olist_order_reviews_dataset$
SET review_comment_message = 'N/A'
WHERE review_comment_message IS NULL;

UPDATE olist_order_reviews_dataset$
SET review_comment_title = 'N/A'
WHERE review_comment_title IS NULL;



--  2. Checking / Deleting duplicate values from order_reviews table
-- order_reviews table
SELECT review_id, COUNT(*)
FROM olist_order_reviews_dataset$
GROUP BY review_id
HAVING COUNT(*) >1
---

WITH CTE AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY review_id 
ORDER BY (SELECT 0)) AS RN
FROM olist_order_reviews_dataset$
)

DELETE FROM CTE 
WHERE RN>1


-- 3. Changing Data Types
-- order_item table
ALTER TABLE order_items ALTER COLUMN shipping_limit_date DATE;
ALTER TABLE order_items ALTER COLUMN price MONEY;
ALTER TABLE order_items ALTER COLUMN freight_value MONEY;

-- order_payment table
ALTER TABLE order_payments ALTER COLUMN payment_installments INT;
ALTER TABLE order_payments ALTER COLUMN payment_sequential INT;
ALTER TABLE order_payments ALTER COLUMN payment_value MONEY;

-- orders table
ALTER TABLE orders ALTER COLUMN order_purchase_timestamp DATE;
ALTER TABLE orders ALTER COLUMN order_approved_at DATE;
ALTER TABLE orders ALTER COLUMN order_delivered_carrier_date DATE;
ALTER TABLE orders ALTER COLUMN order_delivered_customer_date DATE;
ALTER TABLE orders ALTER COLUMN order_estimated_delivery_date DATE;

-- order_reviews table
ALTER TABLE olist_order_reviews_dataset$ ALTER COLUMN review_answer_timestamp DATE;
ALTER TABLE olist_order_reviews_dataset$ ALTER COLUMN review_score INT;

 
-- 4. Inserting records into the category_name_translatn table and updating the products table

INSERT INTO product_category_name_translation (product_category_name, product_category_name_english)
VALUES ('pc_gamer', 'gaming_pc');
INSERT INTO product_category_name_translation (product_category_name, product_category_name_english)
VALUES ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparators');
INSERT INTO product_category_name_translation (product_category_name, product_category_name_english)
VALUES ('N/A', 'N/A');

-- Updating Products Table
UPDATE products
SET product_category_name = c.product_category_name_english
FROM product_category_name_translation c
WHERE products.product_category_name = c.product_category_name_english

-- 5. Changing first lettter of geolocation_city to upper case
UPDATE olist_geolocation_dataset$
SET geolocation_city=
UPPER(SUBSTRING(geolocation_city,1,1))+ LOWER(SUBSTRING(geolocation_city,2,LEN(geolocation_city)))

-- 6. Replacing special charcters in geolocation_city column
UPDATE olist_geolocation_dataset$
SET geolocation_city=
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(geolocation_city,'ê','e'), 
'ç', 'c'), 'ó', 'o'), 'â','a'),'ã','a'),'á','a'), 'é', 'e'), 'ô','o'),'ú','u'),'í','i'),
'õ','o'),'d''avila','davila'),'Sant''ana','Santana'),'d''alianca', 'dalianca')


-- DATA EXPLORATION AND ANALYSIS

-- Loading the different Datasets
SELECT *
FROM olist_customers_dataset$
SELECT *
FROM olist_geolocation_dataset$ 
SELECT *
FROM olist_order_reviews_dataset$
SELECT *
FROM olist_sellers_dataset$
SELECT *
FROM orders
SELECT *
FROM order_payments
SELECT *
FROM order_items
SELECT *
FROM products
SELECT *
FROM product_category_name_translation

-- 1. What is the total revenue made by olist and how has it changed over time?

SELECT SUM(payment_value) AS total_revenue
FROM orders orders
JOIN order_payments payments
ON orders.order_id  = payments.order_id
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable' 


-- Finding the total revenue by month in each year and comparison between previous month totals

SELECT DATEPART(Year, order_approved_at) AS YEAR, DATEPART(Month, order_approved_at) AS MONTH, SUM(payment_value) AS REVENUE, LAG(SUM(payment_value)) OVER (ORDER BY DATEPART(Year, order_approved_at), Month(order_approved_at))
FROM order_payments payments
JOIN orders orders
ON payments.order_id = orders.order_id
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable' 
GROUP BY DATEPART(Year, order_approved_at), DATEPART(Month, order_approved_at)

-- The difference between previous month totals i.e difference between january 2017 and december 2016

SELECT DATEPART(Year, order_approved_at) AS YEAR, DATEPART(Month, order_approved_at) AS MONTH, SUM(payment_value) - LAG(SUM(payment_value)) OVER (ORDER BY DATEPART(Year, order_approved_at), DATEPART(Month, order_approved_at))
FROM order_payments payments
JOIN orders orders
ON payments.order_id = orders.order_id
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable' 
GROUP BY DATEPART(Year, order_approved_at), DATEPART(Month, order_approved_at)

-- The revenue for each month and comparison between the same months in different years

SELECT DATEPART(Year, order_approved_at) AS YEAR, DATEPART(Month, order_approved_at) AS MONTH, SUM(payment_value) AS REVENUE, LAG(SUM(payment_value), 12) OVER (ORDER BY DATEPART(Year, order_approved_at), DATEPART(Month, order_approved_at))
FROM order_payments payments
JOIN orders orders
ON payments.order_id = orders.order_id
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable' 
GROUP BY DATEPART(Year, order_approved_at), DATEPART(Month, order_approved_at)

-- Revenue totals in the years and comparison between each years

SELECT DATEPART(Year, order_approved_at) AS YEAR, SUM(payment_value) AS REVENUE, LAG(SUM(payment_value)) OVER (ORDER BY DATEPART(Year, order_approved_at)) AS previous_year, SUM(payment_value) - LAG(SUM(payment_value)) OVER (ORDER BY DATEPART(Year, order_approved_at)) AS differenceinyears
FROM order_payments payments
JOIN orders orders
ON payments.order_id = orders.order_id
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable' 
GROUP BY DATEPART(Year, order_approved_at)

-- Revenue Totals in months of years, quarters of the years and years total

SELECT 
CASE WHEN Month(order_approved_at) IS NULL AND
DATEPART(QUARTER, order_approved_at) IS NULL
THEN 'Yearly'
WHEN Month(order_approved_at) IS NULL
THEN 'Quarterly'
WHEN 
Year(order_approved_at) IS NULL
THEN 'Grand_Total'
ELSE 'Monthly'
END AS Totals,
Year(order_approved_at) AS YEAR,
DATEPART(QUARTER, order_approved_at) AS QuarterName,
Month(order_approved_at) AS MONTH, 
SUM(payment_value) AS REVENUE
FROM order_payments payments
JOIN orders orders
ON payments.order_id = orders.order_id
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable' 
GROUP BY GROUPING SETS ((Year(order_approved_at)),
(Year(order_approved_at), DATEPART(QUARTER, order_approved_at)),
(Year(order_approved_at), Month(order_approved_at)), ())


-- 2. How many orders were placed on Olist, and how does this vary by month or season?

-- Total orders made
SELECT COUNT(order_id) AS No_of_orders
FROM orders
 
-- No of orders in a specific months in a particular year
SELECT DATEPART(Year, order_purchase_timestamp) AS YEAR, DATEPART(Month, order_purchase_timestamp) AS MONTH, COUNT(order_id) AS NoOfOrdersPerMonth
FROM orders
WHERE DATEPART(Year, order_purchase_timestamp) in (2016, 2017, 2018)
GROUP BY DATEPART(Year, order_purchase_timestamp), DATEPART(Month, order_purchase_timestamp)
ORDER BY 1,2

-- No of orders in those years individually 
SELECT DATEPART(Year, order_purchase_timestamp) AS YEAR, COUNT(order_id) AS Yearly_Orders
FROM orders
WHERE DATEPART(Year, order_purchase_timestamp) in (2016, 2017, 2018)
GROUP BY DATEPART(Year, order_purchase_timestamp)
ORDER BY 1,2

-- No of orders made in a particular month throughout the years (i.e Month of January in 2016-2018)
SELECT DATEPART(Month, order_purchase_timestamp) AS MONTH, COUNT(order_id) as NoOfOrdersPerMonth
FROM orders
GROUP BY DATEPART(Month, order_purchase_timestamp)
ORDER BY 1,2

SELECT DATEPART(Year, order_purchase_timestamp) as YEAR, DATEPART(Month, order_purchase_timestamp) AS MONTH, COUNT(order_id) AS NoOfOrdersPerMonth, LAG(COUNT(order_id)) OVER (ORDER BY DATEPART(Year, order_purchase_timestamp), DATEPART(Month, order_purchase_timestamp)),
COUNT(order_id) - LAG(COUNT(order_id)) OVER (ORDER BY DATEPART(Year, order_purchase_timestamp), DATEPART(Month, order_purchase_timestamp)) AS ChangeInNoOfOrdersPerMonth
FROM orders
WHERE Year(order_purchase_timestamp) in (2016, 2017, 2018)
GROUP BY DATEPART(Year, order_purchase_timestamp), DATEPART(Month, order_purchase_timestamp)
ORDER BY 1,2


-- 3. What are the most popular product categories on Olist, and how do their sales volumes compare to each other?

-- Total orders from the categories

SELECT category.product_category_name_english, COUNT(oi.order_id) AS NoOfOrders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN order_payments pa ON o.order_id = pa.order_id
JOIN product_category_name_translation category ON p.product_category_name = category.product_category_name
GROUP BY category.product_category_name_english
ORDER BY 2 DESC
 
 -- Revenue made by the categories
SELECT category.product_category_name_english, COUNT(oi.order_id) AS NoOfOrders, SUM(payment_value) AS TotalRevenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN order_payments pa ON o.order_id = pa.order_id
JOIN product_category_name_translation category ON p.product_category_name = category.product_category_name
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable' 
GROUP BY category.product_category_name_english
ORDER BY 3 DESC

-- 4.  What is the average order value (AOV) on Olist, and how does this vary by product category or payment method?

SELECT  ROUND(AVG(payment_value),2) AS Average_order_value
FROM order_payments op
JOIN orders od on op.order_id = od.order_id
WHERE order_status != 'canceled' AND order_status != 'unavailable'


-- By Category
SELECT category.product_category_name_english, SUM(payment_value)/COUNT(o.order_id) AS Average_Order_Value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN order_payments pa ON o.order_id = pa.order_id
JOIN product_category_name_translation category ON p.product_category_name = category.product_category_name
GROUP BY category.product_category_name_english
ORDER BY 2 DESC

-- By Payment Type
SELECT payment_type, SUM(payment_value)/COUNT(o.order_id) AS Average_Order_Value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN order_payments pa ON o.order_id = pa.order_id
JOIN product_category_name_translation category ON p.product_category_name = category.product_category_name
GROUP BY payment_type
ORDER BY 2 DESC


-- 5. How many sellers are active on Olist, and how does this number change over time?
SELECT COUNT(DISTINCT sellers.seller_id) AS No_of_Sellers
FROM orders o
INNER JOIN order_items oi
ON o.order_id = oi.order_id
INNER JOIN olist_sellers_dataset$ sellers
ON oi.seller_id = sellers.seller_id


SELECT DATEPART(Year, o.order_purchase_timestamp), COUNT(DISTINCT s.seller_id) AS NoOfSellers,  COUNT(DISTINCT o.order_id) as Nooforders, MIN(order_purchase_timestamp) AS firstorder, 
MAX(order_purchase_timestamp) AS lastorder, COUNT(DISTINCT p.product_id) as num_products_listed
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN olist_sellers_dataset$ s ON oi.seller_id = s.seller_id
JOIN products p ON oi.product_id = p.product_id
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY DATEPART(Year, o.order_purchase_timestamp)
HAVING DATEDIFF(MONTH, MIN(order_purchase_timestamp), MAX(order_purchase_timestamp)) >2
ORDER BY 3




-- 6.  What is the distribution of seller ratings on Olist, and how does this impact sales performance?

SELECT review_score, 
COUNT(DISTINCT o.order_id) AS num_of_orders, 
SUM(payment_value) AS total_revenue, 
SUM(payment_value)/COUNT(DISTINCT o.order_id) AS avg_order_val
FROM olist_order_reviews_dataset$ oor
INNER JOIN orders o ON oor.order_id = o.order_id
INNER JOIN order_payments p ON oor.order_id = p.order_id
INNER JOIN order_items oi ON oor.order_id = oi.order_id
INNER JOIN products pr ON pr.product_id = oi.product_id 
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable'
GROUP BY review_score
ORDER BY 1 DESC



-- 7. : How many customers have made repeat purchases on Olist, and what percentage of total sales do they account for?

-- Customers who made multiple orders
SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS No_Of_Orders, SUM(payment_value) AS total_revenue 
FROM orders o 
INNER JOIN olist_customers_dataset$ c ON o.customer_id = c.customer_id
INNER JOIN order_payments p ON o.order_id = p.order_id
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY 2 desc

-- Total Number of customers with multiple orders 
SELECT COUNT(*) AS no_of_repeated_customers
FROM(
SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS No_Of_Orders, SUM(payment_value) AS total_revenue
FROM orders o 
INNER JOIN olist_customers_dataset$ c ON o.customer_id = c.customer_id
INNER JOIN order_payments p ON o.order_id = p.order_id
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1)sub;


-- Sales percentage of repeated customers 

WITH rc as (
SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS No_Of_Orders, SUM(payment_value) AS total_spent
FROM orders o 
INNER JOIN olist_customers_dataset$ c ON o.customer_id = c.customer_id
INNER JOIN order_payments p ON o.order_id = p.order_id
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1
)
SELECT COUNT(DISTINCT customer_unique_id) AS repeated_customers, 
SUM(rc.total_spent)/ (SELECT SUM(payment_value) 
FROM order_payments p
JOIN orders o
ON o.order_id = p.order_id
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable') * 100 as  salespercentage
FROM rc

-- 8: What is the average customer rating for products sold on Olist, and how does this impact sales performance?


SELECT ct.product_category_name_english AS Product_name, AVG(review_score) AS Average_cutomer_rating, COUNT(DISTINCT o.order_id) AS No_Of_Orders, SUM(payment_value) AS total_revenue, SUM(payment_value)/COUNT(DISTINCT o.order_id) as avg_revenue
FROM dbo.olist_order_reviews_dataset$ oor
JOIN orders o ON oor.order_id = o.order_id
JOIN order_payments op ON oor.order_id = op.order_id
JOIN order_items oi ON oor.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN dbo.product_category_name_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY ct.product_category_name_english, review_score
ORDER BY 2 DESC, 4 DESC

WITH tr as (
SELECT ct.product_category_name_english AS Product_name, AVG(review_score) AS Average_cutomer_rating, COUNT(DISTINCT o.order_id) AS No_Of_Orders, SUM(payment_value) AS total_revenue, SUM(payment_value)/COUNT(DISTINCT o.order_id) as avg_revenue
FROM dbo.olist_order_reviews_dataset$ oor
JOIN orders o ON oor.order_id = o.order_id
JOIN order_payments op ON oor.order_id = op.order_id
JOIN order_items oi ON oor.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN dbo.product_category_name_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY ct.product_category_name_english, review_score
)
SELECT Average_cutomer_rating, SUM(total_revenue) as total_revenue
FROM tr
GROUP BY Average_cutomer_rating
ORDER BY 2 DESC


-- 9: What is the average order cancellation rate on Olist, and how does this impact seller performance?.


SELECT
 COUNT(o.order_id) AS Total_orders,
 COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) AS Cancelled_orders,
 CAST(COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) AS FLOAT) / (COUNT(o.order_id)) * 100 AS Average_cancellation_rate
FROM orders o

-- Cancellation Rate for a Seller
SELECT
 seller_id,
 COUNT(distinct oi.order_id) AS Total_orders,
 COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) AS Cancelled_orders,
 ROUND(SUM(op.payment_value), 2) AS total_sales_volume,
 AVG(review_score) AS customer_satisfaction,
 CAST(COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) AS FLOAT) / (COUNT(DISTINCT oi.order_id)) * 100 AS Average_cancellation_rate
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN order_payments op ON o.order_id = op.order_id
JOIN olist_order_reviews_dataset$ r ON o.order_id = r.order_id
GROUP BY seller_id
ORDER BY 6 DESC


-- 10: What are the top-selling products on Olist, and how have their sales trends changed over time?


SELECT t.product_category_name_english AS Product_name, SUM(payment_value) AS total_revenue, COUNT(o.order_id) as no_products_sold
FROM dbo.product_category_name_translation t
JOIN products p
ON p.product_category_name = t.product_category_name
JOIN order_items oi
ON oi.product_id = p.product_id
JOIN order_payments op
ON op.order_id = oi.order_id
JOIN orders o
ON o.order_id = op.order_id
WHERE order_status <> 'cancelled' AND order_approved_at is NOT NULL AND order_status <> 'unavailable'
GROUP BY t.product_category_name_english
ORDER BY 3 DESC


-- This is to find the the number of sales made by each product in each quarter of a year
SELECT
p.product_category_name,
DATEPART(QUARTER, o.order_purchase_timestamp) AS order_quarter,
DATEPART(YEAR, o.order_purchase_timestamp) AS order_year,
SUM(op.payment_value) AS total_sales,
COUNT(o.order_id) as no_products_sold,
RANK() OVER (PARTITION BY p.product_category_name ORDER BY DATEPART(YEAR, o.order_purchase_timestamp), DATEPART(QUARTER, o.order_purchase_timestamp) ) AS product_rank
FROM
order_items oi
INNER JOIN order_payments op ON oi.order_id = op.order_id
INNER JOIN products p ON oi.product_id = p.product_id
INNER JOIN orders o ON o.order_id = oi.order_id
WHERE order_status <> 'cancelled'AND order_approved_at is NOT NULL AND order_status <> 'unavailable'
GROUP BY
p.product_category_name,
DATEPART(QUARTER, o.order_purchase_timestamp),
DATEPART(YEAR, o.order_purchase_timestamp)		 
     

SELECT DATEPART(YEAR, o.order_purchase_timestamp) as YEAR, t.product_category_name_english AS Product_name, SUM(payment_value) AS total_revenue, COUNT(o.order_id) as no_products_sold
FROM dbo.product_category_name_translation t
JOIN products p
ON p.product_category_name = t.product_category_name
JOIN order_items oi
ON oi.product_id = p.product_id
JOIN order_payments op
ON op.order_id = oi.order_id
JOIN orders o
ON o.order_id = op.order_id
WHERE order_status <> 'cancelled'AND order_approved_at is NOT NULL AND order_status <> 'unavailable'
GROUP BY DATEPART(YEAR, o.order_purchase_timestamp), t.product_category_name_english
ORDER BY 1, 4 DESC


-- 11: Which payment methods are most commonly used by Olist customers, and how does this vary by product category or geographic region?
SELECT payment_type, COUNT(op.order_id) AS num_of_orders
FROM order_payments op
JOIN orders o
ON op.order_id = o.order_id
GROUP BY op.payment_type
ORDER BY 2 DESC

-- bY category
SELECT t.product_category_name_english AS Product_name, op.payment_type AS Payment_type, COUNT(op.payment_type) AS Count_payment_type
FROM order_payments op
JOIN order_items oi
ON oi.order_id = op.order_id
JOIN products p
ON p.product_id = oi.product_id
JOIN dbo.product_category_name_translation t
ON t.product_category_name = p.product_category_name
GROUP BY t.product_category_name_english, op.payment_type
ORDER BY 1, 3 DESC

-- by city
SELECT og.geolocation_city AS City_Name, op.payment_type AS Payment_type, COUNT(op.payment_type) AS Count_payment_type
FROM order_payments op
JOIN orders o
ON o.order_id = op.order_id
JOIN  olist_customers_dataset$ oc
ON o.customer_id = oc.customer_id
JOIN dbo.olist_geolocation_dataset$ og
ON oc.customer_zip_code_prefix = og.geolocation_zip_code_prefix 
GROUP BY og.geolocation_city, op.payment_type
ORDER BY 3 DESC



-- 12: How do customer reviews and ratings affect sales and product performance on Olist?

-- sales performance
SELECT review_score, 
COUNT(DISTINCT o.order_id) AS num_of_orders, 
SUM(payment_value) as total_revenue, 
SUM(payment_value)/COUNT(DISTINCT o.order_id) AS avg_order_val
FROM olist_order_reviews_dataset$ oor
INNER JOIN orders o ON oor.order_id = o.order_id
INNER JOIN order_payments p ON oor.order_id = p.order_id
INNER JOIN order_items oi ON oor.order_id = oi.order_id
INNER JOIN products pr ON pr.product_id = oi.product_id 
WHERE order_status <> 'cancelled'AND order_approved_at is NOT NULL AND order_status <> 'unavailable'
GROUP BY review_score
ORDER BY 1 DESC


-- product and sales performance
SELECT review_score, 
COUNT(DISTINCT oi.product_id) AS num_of_products, 
SUM(payment_value) AS total_revenue, 
SUM(payment_value)/COUNT(DISTINCT oor.order_id) AS avg_order_val
FROM olist_order_reviews_dataset$ oor
INNER JOIN orders o ON oor.order_id = o.order_id
INNER JOIN order_payments p ON oor.order_id = p.order_id
INNER JOIN order_items oi ON oor.order_id = oi.order_id
INNER JOIN products op ON oi.product_id = op.product_id
WHERE order_status <> 'cancelled'AND order_approved_at is NOT NULL
GROUP BY review_score
ORDER BY 1 DESC

-- 13: Which product categories have the highest profit margins on Olist, and how can the company increase profitability across different categories?
SELECT t.product_category_name_english,
  SUM((op.payment_value) -(oi.price + oi.freight_value)) / SUM(op.payment_value) * 100 AS gross_profit_margin
FROM order_payments op
JOIN order_items oi
ON oi.order_id = op.order_id
JOIN products p
ON oi.product_id = p.product_id
JOIN dbo.product_category_name_translation t
ON t.product_category_name = p.product_category_name
GROUP BY t.product_category_name_english
ORDER BY gross_profit_margin DESC


-- 14: Geolocation having high customer density. Calculate customer retention rate according to geolocations.

-- High Customer Density i.e Geolocations with more than 10 customers
WITH customer_density AS (
  SELECT g.geolocation_state,
  COUNT(DISTINCT customer_unique_id) AS customer_count,
  COUNT(order_id) AS order_count
  FROM olist_customers_dataset$ c
  JOIN olist_geolocation_dataset$ g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
  JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY g.geolocation_state
  HAVING COUNT(DISTINCT customer_unique_id) > 9
  ),
-- Number of customers that made more than 1 order 
 repeat_customers AS (
   SELECT c.customer_state, COUNT(DISTINCT c.customer_unique_id) AS rc
   FROM order_payments op
   JOIN orders o ON op.order_id = o.order_id
   JOIN olist_customers_dataset$ c ON o.customer_id = c.customer_id
   WHERE c.customer_unique_id IN (
   SELECT customer_unique_id
   FROM (
   SELECT customer_unique_id, COUNT(order_id) AS order_count
   FROM orders O
   JOIN olist_customers_dataset$ c ON o.customer_id = c.customer_id
   GROUP BY customer_unique_id
   HAVING COUNT(order_id) > 1)sub)

   GROUP BY c.customer_state
   ),
   tot_customers AS (
   SELECT  customer_state, COUNT(DISTINCT customer_id) AS tot_customer
   FROM olist_customers_dataset$
   GROUP BY customer_state
   )
   SELECT cd.geolocation_state, ROUND((CAST(rc.rc AS FLOAT) / CAST(tc.tot_customer AS FLOAT)) * 100, 2) AS percentage_repeated_sales
   FROM customer_density cd
   JOIN tot_customers tc ON cd.geolocation_state = tc.customer_state
   JOIN repeat_customers rc ON cd.geolocation_state = rc.customer_state
   ORDER BY 2 DESC


   -- OR

  WITH repeat_customers AS (
   SELECT c.customer_state, COUNT(DISTINCT c.customer_unique_id) AS rc
   FROM order_payments op
   JOIN orders o ON op.order_id = o.order_id
   JOIN olist_customers_dataset$ c ON o.customer_id = c.customer_id
   WHERE c.customer_unique_id IN (
   SELECT customer_unique_id
   FROM (
   SELECT customer_unique_id, COUNT(order_id) AS order_count
   FROM orders O
   JOIN olist_customers_dataset$ c ON o.customer_id = c.customer_id
   GROUP BY customer_unique_id
   HAVING COUNT(order_id) > 1)sub)

   GROUP BY c.customer_state
   ),
   tot_customers AS (
   SELECT  customer_state, COUNT(DISTINCT customer_id) AS tot_customer
   FROM olist_customers_dataset$
   GROUP BY customer_state
   )
   SELECT rc.customer_state, CASE
                  WHEN rc.customer_state = 'AC' THEN 'Acre'
				  WHEN rc.customer_state = 'AL' THEN 'Alagoas'
				  WHEN rc.customer_state = 'AP' THEN 'Amapa'
				  WHEN rc.customer_state = 'AM' THEN 'Amazonas'
				  WHEN rc.customer_state = 'BA' THEN 'Bahia'
				  WHEN rc.customer_state = 'CE' THEN 'Ceara'
				  WHEN rc.customer_state = 'DF' THEN 'Distrito Federal'
				  WHEN rc.customer_state = 'ES' THEN 'Espirito Santo'
				  WHEN rc.customer_state = 'GO' THEN 'Goias'
				  WHEN rc.customer_state = 'MA' THEN 'Maranhao'
				  WHEN rc.customer_state = 'MT' THEN 'Mato Grosso'
				  WHEN rc.customer_state = 'MS' THEN 'Mato Grosso do Sul'
				  WHEN rc.customer_state = 'MG' THEN 'Minas Gerais'
				  WHEN rc.customer_state = 'PA' THEN 'Para'
				  WHEN rc.customer_state = 'PB' THEN 'Paraiba'
				  WHEN rc.customer_state = 'PR' THEN 'Parana'
				  WHEN rc.customer_state = 'PE' THEN 'Pernambuco'
				  WHEN rc.customer_state = 'PI' THEN 'Piaui'
				  WHEN rc.customer_state = 'RJ' THEN 'Rio de Janeiro'
				  WHEN rc.customer_state = 'RN' THEN 'Rio Grande do Norte'
				  WHEN rc.customer_state = 'RS' THEN 'Rio Grande do Sul'
				  WHEN rc.customer_state = 'RO' THEN 'Rondonia'
				  WHEN rc.customer_state = 'RR' THEN 'Roraima'
				  WHEN rc.customer_state = 'SC' THEN 'Santa Catarina'
				  WHEN rc.customer_state = 'SP' THEN 'Sao Paulo'
				  WHEN rc.customer_state = 'SE' THEN 'Sergipe'
				  WHEN rc.customer_state = 'TO' THEN 'Tocantins'
				  ELSE rc.customer_state
				  END AS state_full_name,
   ROUND((CAST(rc.rc AS FLOAT) / CAST(tc.tot_customer AS FLOAT)) * 100, 2) AS percentage_repeated_sales
   FROM repeat_customers rc
   JOIN tot_customers tc ON rc.customer_state = tc.customer_state
   ORDER BY 3 DESC


  
