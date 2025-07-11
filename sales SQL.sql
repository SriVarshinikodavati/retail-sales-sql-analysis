DROP DATABASE IF EXISTS Sales;
CREATE DATABASE Sales;
USE Sales;
CREATE TABLE retail_sales (
  transactions_id INT PRIMARY KEY NOT NULL,
  sale_date DATE, 
  sale_time TIME,
  customer_id INT, 
  gender VARCHAR(10),
  age INT,
  category VARCHAR(35),
  quantity INT,
  price_per_unit FLOAT, 
  cogs FLOAT,
  total_sale FLOAT
);

SHOW VARIABLES LIKE 'local_infile';

SELECT *
FROM retail_sales
LIMIT 10; -- Gets the first 10 rows

-- Data Cleaning --

SELECT COUNT(*) FROM retail_sales;
SELECT COUNT(DISTINCT customer_id) FROM retail_sales;
SELECT DISTINCT category FROM retail_sales;

SELECT * FROM retail_sales
WHERE 
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR 
    gender IS NULL OR age IS NULL OR category IS NULL OR 
    quantity IS NULL OR price_per_unit IS NULL OR cogs IS NULL;
SET SQL_SAFE_UPDATES = 0;

DELETE FROM retail_sales
WHERE sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR  
      gender IS NULL OR age IS NULL OR category IS NULL OR  
      quantity IS NULL OR price_per_unit IS NULL OR cogs IS NULL;

SET SQL_SAFE_UPDATES = 1;

-- Data Exploration --
-- ✅ How many sales do we have?
SELECT COUNT(*) AS total_sales 
FROM retail_sales;

SELECT DISTINCT sale_time
FROM retail_sales;

-- ✅ How many unique customers do we have?
SELECT COUNT(DISTINCT customer_id) AS total_customers 
FROM retail_sales;
-- There are 155 No Of total customers.

-- ✅ How many product categories do we have?
SELECT COUNT(DISTINCT category) AS total_categories 
FROM retail_sales;

SELECT DISTINCT category 
FROM retail_sales;

-- ✅ How many unique quantity values are there?
SELECT COUNT(DISTINCT quantity) AS distinct_quantity_count 
FROM retail_sales;

SELECT DISTINCT quantity 
FROM retail_sales;

-- ✅ How many genders are recorded?
SELECT COUNT(DISTINCT gender) AS gender_count 
FROM retail_sales;

SELECT DISTINCT gender 
FROM retail_sales;

-- ✅ How many unique price-per-unit values are there?
SELECT COUNT(DISTINCT price_per_unit) AS distinct_price_per_unit_count 
FROM retail_sales;


-- ✅ In which month sales are more?
SELECT  
    MONTHNAME(sale_date) AS sale_month,
    MONTH(sale_date) AS month_number
FROM retail_sales
GROUP BY sale_month, month_number;

-- ✅ In which Hours sales are more ?
SELECT  
    HOUR(sale_time) AS sale_hour,
    COUNT(*) AS total_sales
FROM retail_sales
GROUP BY sale_hour
ORDER BY total_sales DESC;


-- Clothing is the most popular product with more sales.
SELECT
    category AS product_sale,
    COUNT(*) AS total_sales
FROM retail_sales
GROUP BY category
ORDER BY total_sales DESC;


-- ✅  Age Groups – Which age range purchased more?
SELECT 
    CASE 
        WHEN CAST(age AS UNSIGNED) BETWEEN 18 AND 25 THEN '18-25'
        WHEN CAST(age AS UNSIGNED) BETWEEN 26 AND 35 THEN '26-35'
        WHEN CAST(age AS UNSIGNED) BETWEEN 36 AND 45 THEN '36-45'
        WHEN CAST(age AS UNSIGNED) BETWEEN 46 AND 55 THEN '46-55'
        WHEN CAST(age AS UNSIGNED) > 55 THEN '56+'
        ELSE 'Unknown'
    END AS age_group,
    COUNT(*) AS total_purchases
FROM retail_sales
WHERE age IS NOT NULL AND age <> ''
GROUP BY age_group
ORDER BY total_purchases DESC;

-- Age_group of 46-55 purchased more of 455
-- Age_group of 18-25 purchased less of 337

-- ✅ what is highest price per unit?

SELECT *
FROM retail_sales
WHERE CAST(price_per_unit AS DECIMAL(10,2)) = (
    SELECT MAX(CAST(price_per_unit AS DECIMAL(10,2)))
    FROM retail_sales
    WHERE price_per_unit IS NOT NULL AND price_per_unit <> ''
);
-- 500 is the most ordered cost per unit.
SELECT * FROM retail_sales
WHERE sale_date = '2022-11-05' ;

SELECT
    gender,
    CASE 
        WHEN CAST(age AS UNSIGNED) BETWEEN 18 AND 25 THEN '18-25'
        WHEN CAST(age AS UNSIGNED) BETWEEN 26 AND 35 THEN '26-35'
        WHEN CAST(age AS UNSIGNED) BETWEEN 36 AND 45 THEN '36-45'
        WHEN CAST(age AS UNSIGNED) BETWEEN 46 AND 55 THEN '46-55'
        WHEN CAST(age AS UNSIGNED) > 55 THEN '56+'
        ELSE 'Unknown'
    END AS age_group,
    COUNT(*) AS total_purchases
FROM retail_sales
WHERE age IS NOT NULL AND age <> ''
  AND gender IS NOT NULL AND gender <> ''
GROUP BY gender, age_group
ORDER BY gender, age_group;
-- Female of age 46-55 has purchased more than any other.


-- Q. Write a SQL query to retrieve all transactions where the each category and the quantity sold for 2,3,4 as per gender in the month of Nov-2022
SELECT gender , category, quantity, COUNT(*) AS total_sales
FROM retail_sales
WHERE 
    DATE_FORMAT(sale_date, '%Y-%m') = '2022-11'
    AND quantity IN (2, 3, 4)
GROUP BY gender, category, quantity
ORDER BY gender, category, quantity;
-- ✅ Both genders follow a similar purchasing pattern:
-- . High-Performing Segments
-- Female + Electronics + Quantity 4 → 8 sales → 🔥 Top female segment
-- Male + Electronics + Quantity 2 → 9 sales → 🔥 Top male segment
-- Female + Clothing + Quantity 4 → 10 sales → 🥇 Highest overall count

---- Write a SQL query to find all transactions where the total_sale is greater than or equal to 1000.

SELECT * FROM retail_sales
WHERE total_sale >= 1000

-- Q.4 Write a SQL query to find the average age of customers who purchased items from the 'Beauty' category.

SELECT 
    ROUND(AVG(age), 2) as avg_age
FROM retail_sales
WHERE category = 'Beauty'

SELECT 
    DATE_FORMAT(sale_date, '%Y-%m') AS sale_month,
    CASE
        WHEN CAST(price_per_unit AS DECIMAL) >= 100 THEN 'High'
        ELSE 'Regular'
    END AS price_tier,
    COUNT(*) AS total_sales
FROM retail_sales
WHERE price_per_unit IS NOT NULL AND price_per_unit <> ''
GROUP BY sale_month, price_tier
ORDER BY sale_month, price_tier;

-- Q Write a SQL query to calculate the average sale for each month. Find out best selling month in each year

SELECT 
    year,
    month,
    avg_sale
FROM (
    SELECT 
        YEAR(sale_date) AS year,
        MONTH(sale_date) AS month,
        AVG(total_sale) AS avg_sale,
        RANK() OVER (PARTITION BY YEAR(sale_date) ORDER BY AVG(total_sale) DESC) AS rnk
    FROM retail_sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
) AS ranked_sales
WHERE rnk = 1;    
-- ORDER BY 1, 3 DESC


-- Q.10 Write a SQL query to create each shift and number of orders (Example Morning <12, Afternoon Between 12 & 17, Evening >17)
WITH hourly_sale
AS
(
SELECT *,
    CASE
        WHEN EXTRACT(HOUR FROM sale_time) < 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END as shift
FROM retail_sales
)
SELECT 
    shift,
    COUNT(*) as total_orders    
FROM hourly_sale
GROUP BY shift
-- Evening dominates sales: Over 50% of the sales occur in the evening.
-- Morning has moderate activity, accounting for about 25%.
-- Afternoon sees the lowest sales, under 20%.

SELECT
  CASE
    WHEN price_per_unit >= 100 THEN 'High-Priced'
    ELSE 'Regular'
  END AS price_tier,
  COUNT(*) AS total_sales
FROM retail_sales
WHERE sale_date BETWEEN '2022-07-01' AND '2022-07-31'
  AND price_per_unit IS NOT NULL
GROUP BY price_tier;
-- High-priced items made up nearly 49% of the sales (20 out of 41 total).
-- High-priced items were almost as popular as regular ones during July 2022.alter


-- Q.7 Write a SQL query to calculate the average sale for each month. Find out best selling month in each year

SELECT
    year,
    month,
    avg_sale
FROM (
    SELECT
        YEAR(sale_date) AS year,
        MONTH(sale_date) AS month,
        AVG(total_sale) AS avg_sale,
        RANK() OVER (PARTITION BY YEAR(sale_date) ORDER BY AVG(total_sale) DESC) AS rk
    FROM retail_sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
) AS sub
WHERE rk = 1;

-- Yes, seasonality appears to have an impact on high average sales, with July 2022 standing out as the peak.

-- Q "How were the sales in July 2022 distributed across category, gender, and price tier ?"
SELECT FLOOR(COUNT(*) * 0.75) AS offset_value
FROM retail_sales
WHERE price_per_unit IS NOT NULL  
  AND sale_date BETWEEN '2022-07-01' AND '2022-07-31';
SELECT price_per_unit
FROM retail_sales
WHERE price_per_unit IS NOT NULL  
  AND sale_date BETWEEN '2022-07-01' AND '2022-07-31'
ORDER BY price_per_unit
LIMIT 1 OFFSET 45;
SELECT 
    gender,
    category,
    CASE 
        WHEN price_per_unit >= 120 THEN 'High-Priced'
        ELSE 'Regular'
    END AS price_tier,
    COUNT(*) AS total_sales
FROM retail_sales
WHERE sale_date BETWEEN '2022-07-01' AND '2022-07-31'
  AND price_per_unit IS NOT NULL
GROUP BY gender, category, price_tier
ORDER BY gender, category, price_tier;

-- Suggests electronics tend to sell better even at higher prices.
--  Indicates that beauty and clothing are more price-sensitive, especially for females.
-- Females made more high-priced purchases (11) than males (9) Especially strong in Electronics and Beauty.

-- Q What categories sell most during different times of the day?
SELECT 
  CASE
    WHEN HOUR(sale_date) BETWEEN 6 AND 11 THEN 'Morning'
    WHEN HOUR(sale_date) BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN HOUR(sale_date) BETWEEN 18 AND 23 THEN 'Evening'
    ELSE 'Night'
  END AS time_of_day,
  category,
  COUNT(*) AS total_sales
FROM retail_sales
GROUP BY time_of_day, category
ORDER BY time_of_day, total_sales DESC;

-- Night sales peaks at very category.



