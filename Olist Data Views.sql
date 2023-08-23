-- OLIST DATA VIEWS

-- KPI VIEWS
CREATE VIEW Total_Revenue AS
SELECT SUM(payment_value) AS total_revenue
FROM orders orders
JOIN order_payments payments
ON orders.order_id  = payments.order_id
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable' 

CREATE VIEW Total_Orders AS
SELECT COUNT(order_id) AS No_of_orders
FROM orders

CREATE VIEW Total_Sellers AS
SELECT COUNT(DISTINCT sellers.seller_id) AS No_of_Sellers
FROM orders o
INNER JOIN order_items oi
ON o.order_id = oi.order_id
INNER JOIN olist_sellers_dataset$ sellers
ON oi.seller_id = sellers.seller_id

CREATE VIEW Avg_Order_Value AS
SELECT  ROUND(AVG(payment_value),2) AS Average_order_value
FROM order_payments op
JOIN orders od on op.order_id = od.order_id
WHERE order_status != 'canceled' AND order_status != 'unavailable'

CREATE VIEW Cancellation_Rate AS
SELECT
 COUNT(o.order_id) AS Total_orders,
 COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) AS Cancelled_orders,
 CAST(COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) AS FLOAT) / (COUNT(o.order_id)) * 100 AS Average_cancellation_rate
FROM orders o


-- NORMAL VISUALS
CREATE VIEW Revenue_Total_In_Years AS
SELECT DATEPART(Year, order_approved_at) AS YEAR, SUM(payment_value) AS REVENUE, LAG(SUM(payment_value)) OVER (ORDER BY DATEPART(Year, order_approved_at)) AS previous_year, SUM(payment_value) - LAG(SUM(payment_value)) OVER (ORDER BY DATEPART(Year, order_approved_at)) AS differenceinyears
FROM order_payments payments
JOIN orders orders
ON payments.order_id = orders.order_id
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable' 
GROUP BY DATEPART(Year, order_approved_at)

CREATE VIEW Revenue_Total_In_Months AS
SELECT DATEPART(Year, order_approved_at) AS YEAR, DATEPART(Month, order_approved_at) AS MONTH, SUM(payment_value) AS REVENUE
FROM order_payments payments
JOIN orders orders
ON payments.order_id = orders.order_id
WHERE order_status <> 'cancelled' AND order_approved_at IS NOT NULL AND order_status <> 'unavailable' 
GROUP BY DATEPART(Year, order_approved_at), DATEPART(Month, order_approved_at)
--ORDER BY 1, 2


CREATE VIEW Total_Orders_In_Years AS
SELECT DATEPART(Year, order_purchase_timestamp) AS YEAR, COUNT(order_id) AS Yearly_Orders
FROM orders
WHERE DATEPART(Year, order_purchase_timestamp) in (2016, 2017, 2018)
GROUP BY DATEPART(Year, order_purchase_timestamp)
--ORDER BY 1,2

CREATE VIEW Total_Orders_In_Months AS
SELECT DATEPART(Year, order_purchase_timestamp) AS YEAR, DATEPART(Month, order_purchase_timestamp) AS MONTH, COUNT(order_id) AS Monthly_Orders
FROM orders
WHERE DATEPART(Year, order_purchase_timestamp) in (2016, 2017, 2018)
GROUP BY DATEPART(Year, order_purchase_timestamp), DATEPART(Month, order_purchase_timestamp)
--ORDER BY 1,2

CREATE VIEW AOV_VS_ProductCategory AS
SELECT category.product_category_name_english, SUM(payment_value)/COUNT(o.order_id) AS Average_Order_Value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN order_payments pa ON o.order_id = pa.order_id
JOIN product_category_name_translation category ON p.product_category_name = category.product_category_name
GROUP BY category.product_category_name_english
--ORDER BY 2 DESC

CREATE VIEW AOV_VS_PaymentType AS
SELECT payment_type, SUM(payment_value)/COUNT(o.order_id) AS Average_Order_Value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN order_payments pa ON o.order_id = pa.order_id
JOIN product_category_name_translation category ON p.product_category_name = category.product_category_name
GROUP BY payment_type
--ORDER BY 2 DESC

CREATE VIEW Top_Selling_Products AS
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
--ORDER BY 3 DESC

CREATE VIEW Payment_Methods AS
SELECT payment_type, COUNT(op.order_id) AS num_of_orders
FROM order_payments op
JOIN orders o
ON op.order_id = o.order_id
GROUP BY op.payment_type
--ORDER BY 2 DESC

CREATE VIEW CustomerRating_VS_SalesPerformance AS
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
--ORDER BY 1 DESC

CREATE VIEW CustomerRating_VS_Product AS
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
--ORDER BY 1 DESC

CREATE VIEW ProductCategory_VS_GrossProfitMargin AS
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
--ORDER BY gross_profit_margin DESC

CREATE VIEW Geolocation_VS_CustomerDensity AS
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
   --ORDER BY 3 DESC
