-- 1.  REMOVING NULL VALUES

--products table
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

--order_reviews table
UPDATE olist_order_reviews_dataset$
SET review_comment_message = 'N/A'
WHERE review_comment_message IS NULL;

UPDATE olist_order_reviews_dataset$
SET review_comment_title = 'N/A'
WHERE review_comment_title IS NULL;



--  2.Checking / Deleting duplicate values from order_reviews table
--order_reviews table
SELECT review_id, count(*)
from olist_order_reviews_dataset$
group by review_id
having count(*) >1
---

WITH CTE AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY review_id 
ORDER BY (SELECT 0)) AS RN
FROM olist_order_reviews_dataset$
)

DELETE FROM CTE 
WHERE RN>1



--order_item table
ALTER TABLE order_items ALTER COLUMN shipping_limit_date DATE;

ALTER TABLE order_items ALTER COLUMN price MONEY;

ALTER TABLE order_items ALTER COLUMN freight_value MONEY;


--order_payment table
ALTER TABLE order_payments ALTER COLUMN payment_installments INT;

ALTER TABLE order_payments ALTER COLUMN payment_sequential INT;

ALTER TABLE order_payments ALTER COLUMN payment_value MONEY;


--change the data type for the orders table
ALTER TABLE orders ALTER COLUMN order_purchase_timestamp DATE;
ALTER TABLE orders ALTER COLUMN order_approved_at DATE;
ALTER TABLE orders ALTER COLUMN order_delivered_carrier_date DATE;
ALTER TABLE orders ALTER COLUMN order_delivered_customer_date DATE;
ALTER TABLE orders ALTER COLUMN order_estimated_delivery_date DATE;


--order_reviews table
ALTER TABLE olist_order_reviews_dataset$ ALTER COLUMN review_answer_timestamp DATE;
ALTER TABLE olist_order_reviews_dataset$ ALTER COLUMN review_score INT;


-- Inserting records into the category_name_translatn table

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

--changing first lettter of geolocation_city to upper case
UPDATE olist_geolocation_dataset$
SET geolocation_city=
upper(substring(geolocation_city,1,1))+ lower(substring(geolocation_city,2,len(geolocation_city)))

--rplacing special charcters in geolocation_city column
UPDATE olist_geolocation_dataset$
SET geolocation_city=
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(geolocation_city,'ê','e'), 
'ç', 'c'), 'ó', 'o'), 'â','a'),'ã','a'),'á','a'), 'é', 'e'), 'ô','o'),'ú','u'),'í','i'),
'õ','o'),'d''avila','davila'),'Sant''ana','Santana'),'d''alianca', 'dalianca')