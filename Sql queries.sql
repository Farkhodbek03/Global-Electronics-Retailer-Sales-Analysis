-- Retrieve all data from key tables to explore the dataset
SELECT * FROM customers;
SELECT * FROM exchange_rates;
SELECT * FROM products; 
SELECT * FROM sales; 
SELECT * FROM stores;

-- Data Cleaning: Remove '$' symbol from price columns in the products table
UPDATE products
SET `Unit Price USD` = REPLACE(`Unit Price USD`, '$', '');

UPDATE products
SET `Unit Cost USD` = REPLACE(`Unit Cost USD`, '$', '');

-- Convert 'Order Date' to proper DATE format
UPDATE sales 
SET `Order Date` = STR_TO_DATE(`Order Date`, '%m/%d/%Y');
ALTER TABLE sales MODIFY `Order Date` DATE;

-- Convert 'Delivery Date' to proper DATE format while handling empty values
UPDATE sales
SET `Delivery Date` = DATE_FORMAT(STR_TO_DATE(`Delivery Date`, '%m/%d/%Y'), '%Y-%m-%d')
WHERE `Delivery Date` != '' AND `Delivery Date` IS NOT NULL;

-- Handle empty strings by replacing them with NULL values
UPDATE sales SET `Delivery Date` = NULL WHERE `Delivery Date` = '';
ALTER TABLE sales MODIFY `Delivery Date` DATE;

-- 1. Identify top-selling products by revenue and quantity sold
SELECT 
    p.Category,
    SUM(s.Quantity) AS Total_Quantity_Sold,
    SUM(s.Quantity * p.`Unit Price USD`) AS Total_Revenue
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY p.Category
ORDER BY Total_Revenue DESC, Total_Quantity_Sold DESC;

-- 2. Monthly Sales Trends Over Time
SELECT
    YEAR(`Order Date`) AS `Year`,
    MONTH(`Order Date`) AS `Month`,
    ROUND(SUM(Quantity * `Unit Price USD`),1) AS TotalSales
FROM sales
JOIN products ON sales.ProductKey = products.ProductKey
GROUP BY `Year`, `Month`
ORDER BY `Year`, `Month`;

-- Aggregate monthly sales across all years
SELECT
    MONTH(`Order Date`) AS `Month`,
    ROUND(SUM(Quantity * `Unit Price USD`),1) AS TotalSales
FROM sales
JOIN products ON sales.ProductKey = products.ProductKey
GROUP BY `Month`
ORDER BY `Month`;

-- 3. Identify highest revenue-generating stores
SELECT
    sl.StoreKey AS StoreKey,
    st.Country,
    ROUND(SUM(sl.Quantity * p.`Unit Price USD`),1) AS Total_Revenue
FROM sales sl 
JOIN stores st ON sl.StoreKey = st.StoreKey
JOIN products p ON p.ProductKey = sl.ProductKey
GROUP BY sl.StoreKey, st.Country
ORDER BY Total_Revenue DESC
LIMIT 10;

-- 4. Analyze sales performance by product category
SELECT 
    p.Category AS Category,
    AVG(s.Quantity) AS Avg_Quantity,
    COUNT(s.ProductKey) AS Total_Orders,
    ROUND(AVG(s.Quantity * p.`Unit Price USD`),1) AS Avg_Total_Sales,
    ROUND(SUM(s.Quantity * p.`Unit Price USD`),1) AS Total_Sales
FROM sales s 
JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY p.Category
ORDER BY Total_Sales DESC;

-- 5. Calculate Average Order Value (AOV) across different stores
SELECT 
    s.StoreKey,
    st.Country, 
    COUNT(DISTINCT s.`Order Number`) AS Total_Orders,
    ROUND(SUM(s.Quantity * p.`Unit Price USD`),1) AS Total_Revenue,
    ROUND(SUM(s.Quantity * p.`Unit Price USD`) / COUNT(DISTINCT s.`Order Number`), 2) AS Average_Order_Value
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey
JOIN stores st ON s.StoreKey = st.StoreKey
GROUP BY s.StoreKey, st.Country
ORDER BY Average_Order_Value DESC;

-- 6. Calculate Average Delivery Time & Trend Over Time
SELECT 
    DATE_FORMAT(s.`Order Date`, '%Y-%m') AS Order_Month,
    AVG(DATEDIFF(s.`Delivery Date`, s.`Order Date`)) AS Avg_Delivery_Time_Days
FROM sales s
WHERE s.`Delivery Date` IS NOT NULL
GROUP BY Order_Month
ORDER BY Order_Month;

-- 7. Compare AOV for Online vs. In-Store Sales
SELECT 
    st.`StoreKey` AS Store_Name,
    COUNT(DISTINCT s.`Order Number`) AS Total_Orders,
    ROUND(SUM(s.Quantity * p.`Unit Price USD`),1) AS Total_Revenue,
    ROUND(SUM(s.Quantity * p.`Unit Price USD`) / COUNT(DISTINCT s.`Order Number`), 2) AS Average_Order_Value
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey
JOIN stores st ON s.StoreKey = st.StoreKey
GROUP BY st.`StoreKey`
ORDER BY Total_Revenue DESC
LIMIT 3;
