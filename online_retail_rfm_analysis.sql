-- ================================================================
-- ONLINE RETAIL CUSTOMER SEGMENTATION ANALYSIS (RFM)
-- Business Question: Which customers should we retain, reward, or let go?
-- Dataset: Online Retail Dataset (UK) - Kaggle - 541,909 transactions
-- Tools: MySQL
-- Author: Awan Mansuri
-- ================================================================


-- ================================================================
-- SECTION 1: DATA CLEANING
-- Goal: Identify and quantify bad data before trusting any analysis
-- ================================================================

-- Q1: How many transactions have no customer attached?
SELECT COUNT(*) AS missing_customer_id
FROM retail_data
WHERE CustomerID = '';

-- Q2: How many returns/cancellations exist in the data?
SELECT COUNT(*) AS negative_quantity_rows
FROM retail_data
WHERE Quantity < 0;

-- Q3: How many rows have invalid (zero or negative) pricing?
SELECT COUNT(*) AS invalid_price_rows
FROM retail_data
WHERE UnitPrice <= 0;

-- Q4: How many invoices were cancelled?
SELECT COUNT(DISTINCT InvoiceNo) AS cancelled_invoices
FROM retail_data
WHERE InvoiceNo LIKE 'C%';


-- ================================================================
-- SECTION 2: SALES OVERVIEW
-- Goal: Understand overall business performance
-- Note: All queries from here on exclude bad data using the
-- standard cleaning filter: Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
-- ================================================================

-- Q1: What is total revenue from valid transactions?
SELECT SUM(Quantity * UnitPrice) AS Total_Revenue
FROM retail_data
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != '';

-- Q2: How many actual orders were placed?
SELECT COUNT(DISTINCT InvoiceNo) AS Total_Orders
FROM retail_data
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != '';

-- Q3: How many distinct customers do we have?
SELECT COUNT(DISTINCT CustomerID) AS Total_Customers
FROM retail_data
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != '';

-- Q4: Which countries generate the most revenue? (Top 5)
SELECT Country, SUM(Quantity * UnitPrice) AS Total_Revenue
FROM retail_data
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
GROUP BY Country
ORDER BY Total_Revenue DESC
LIMIT 5;

-- Q5: How does revenue change month by month?
SELECT MONTH(InvoiceDate) AS MonthNum, MONTHNAME(InvoiceDate) AS Month,
       SUM(Quantity * UnitPrice) AS Revenue
FROM retail_data
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
GROUP BY MONTH(InvoiceDate), MONTHNAME(InvoiceDate)
ORDER BY MonthNum;


-- ================================================================
-- SECTION 3: CUSTOMER ANALYSIS
-- Goal: Understand who our customers are before RFM scoring
-- ================================================================

-- Q1: Who are our highest value customers? (Top 10)
SELECT CustomerId, SUM(Quantity * UnitPrice) AS total_revenue
FROM retail_data
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
GROUP BY CustomerId
ORDER BY total_revenue DESC
LIMIT 10;

-- Q2: Which customers order most frequently? (Top 10)
SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS total_orders
FROM retail_data
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
GROUP BY CustomerId
ORDER BY total_orders DESC
LIMIT 10;

-- Q3: What is the average amount spent per order?
SELECT AVG(invoice_total) AS total_avg
FROM (
    SELECT InvoiceNo, SUM(UnitPrice * Quantity) AS invoice_total
    FROM retail_data
    WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
    GROUP BY InvoiceNo
) AS total_Invoice;

-- Q4: Which countries have the most customers? (Top 10)
SELECT Country, COUNT(DISTINCT CustomerID) AS customer_count
FROM retail_data
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
GROUP BY Country
ORDER BY customer_count DESC
LIMIT 10;

-- Q5: How long has each top customer been with us? (Top 10 by spend)
SELECT CustomerId,
       MIN(InvoiceDate) AS first_purchase,
       MAX(InvoiceDate) AS last_purchase,
       SUM(Quantity * UnitPrice) AS total_spend
FROM retail_data
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
GROUP BY CustomerID
ORDER BY total_spend DESC
LIMIT 10;


-- ================================================================
-- SECTION 4: RFM CALCULATION
-- Goal: Score every customer on Recency, Frequency, Monetary value
-- Reference date used: 2011-12-10 (one day after last transaction)
-- ================================================================

-- Q1: For every customer — how recently did they buy, how often, and how much?
SELECT CustomerID,
       DATEDIFF('2011-12-10', MAX(InvoiceDate)) AS Recency,
       COUNT(DISTINCT InvoiceNo) AS Frequency,
       SUM(Quantity * UnitPrice) AS Monetary
FROM retail_data
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
GROUP BY CustomerID;

-- Q2: Score each customer 1-5 on Recency, Frequency, Monetary
-- Higher score = better customer across all three metrics
SELECT CustomerID, Recency, Frequency, Monetary,
       NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
       NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
       NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
FROM (
    SELECT CustomerID,
           DATEDIFF('2011-12-10', MAX(InvoiceDate)) AS Recency,
           COUNT(DISTINCT InvoiceNo) AS Frequency,
           SUM(Quantity * UnitPrice) AS Monetary
    FROM retail_data
    WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
    GROUP BY CustomerID
) AS rfm_base;

-- Q3: Combine R, F, M scores into one overall RFM_Total (range: 3-15)
SELECT CustomerID, Recency, Frequency, Monetary,
       R_Score, F_Score, M_Score,
       (R_Score + F_Score + M_Score) AS RFM_Total
FROM (
    SELECT CustomerID, Recency, Frequency, Monetary,
           NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
           NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
           NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM (
        SELECT CustomerID,
               DATEDIFF('2011-12-10', MAX(InvoiceDate)) AS Recency,
               COUNT(DISTINCT InvoiceNo) AS Frequency,
               SUM(Quantity * UnitPrice) AS Monetary
        FROM retail_data
        WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
        GROUP BY CustomerID
    ) AS rfm_base
) AS rfm_scored
ORDER BY RFM_Total DESC;

-- Q4: Save RFM results as a permanent table for reuse
CREATE TABLE customer_rfm AS
SELECT CustomerID, Recency, Frequency, Monetary,
       R_Score, F_Score, M_Score,
       (R_Score + F_Score + M_Score) AS RFM_Total
FROM (
    SELECT CustomerID, Recency, Frequency, Monetary,
           NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
           NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
           NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM (
        SELECT CustomerID,
               DATEDIFF('2011-12-10', MAX(InvoiceDate)) AS Recency,
               COUNT(DISTINCT InvoiceNo) AS Frequency,
               SUM(Quantity * UnitPrice) AS Monetary
        FROM retail_data
        WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID != ''
        GROUP BY CustomerID
    ) AS rfm_base
) AS rfm_scored;


-- ================================================================
-- SECTION 5: SEGMENTATION & RECOMMENDATIONS
-- Goal: Turn RFM scores into actionable customer segments
-- ================================================================

-- Q1: Which customers are Champions, Loyal, At Risk, or Lost?
SELECT CustomerID, Recency, Frequency, Monetary, RFM_Total,
CASE
    WHEN RFM_Total >= 12 THEN 'Champions'
    WHEN RFM_Total >= 9  THEN 'Loyal'
    WHEN RFM_Total >= 6  THEN 'At Risk'
    ELSE 'Lost'
END AS Customer_Segment
FROM customer_rfm;

-- Q2: How many customers fall into each segment?
SELECT Customer_Segment, COUNT(*) AS total_customers
FROM (
    SELECT CustomerID, RFM_Total,
    CASE
        WHEN RFM_Total >= 12 THEN 'Champions'
        WHEN RFM_Total >= 9  THEN 'Loyal'
        WHEN RFM_Total >= 6  THEN 'At Risk'
        ELSE 'Lost'
    END AS Customer_Segment
    FROM customer_rfm
) AS segmented
GROUP BY Customer_Segment
ORDER BY total_customers DESC;

-- Q3: How much revenue does each segment represent? Where should marketing focus?
SELECT Customer_Segment, SUM(Monetary) AS total_revenue
FROM (
    SELECT CustomerID, Monetary, RFM_Total,
    CASE
        WHEN RFM_Total >= 12 THEN 'Champions'
        WHEN RFM_Total >= 9  THEN 'Loyal'
        WHEN RFM_Total >= 6  THEN 'At Risk'
        ELSE 'Lost'
    END AS Customer_Segment
    FROM customer_rfm
) AS segmented
GROUP BY Customer_Segment
ORDER BY total_revenue DESC;


-- ================================================================
-- KEY FINDINGS
-- ================================================================
-- Total Revenue:      £8,911,407.90
-- Total Customers:    4,338
-- Top Market:         United Kingdom
--
-- Segment      | Customers | Revenue      | % of Revenue
-- Champions    | 1,292     | £6,883,371   | 77.2%
-- Loyal        | 1,017     | £1,163,113   | 13.1%
-- At Risk      | 1,117     | £635,239     | 7.1%
-- Lost         | 912       | £229,685     | 2.6%
--
-- Just 29.8% of customers (Champions) generate 77.2% of total
-- revenue -- a clear Pareto (80/20) pattern.
-- ================================================================
