-- ================================================================
-- BANK FRAUD DETECTION ANALYSIS (SQL LAYER)
-- Business Question: Which transactions show fraud patterns, and
--                     how would we flag them for review?
-- Dataset: Credit Card Fraud Detection - Kaggle - 284,807 transactions
-- Tools: MySQL
-- Author: Awan Mansuri
-- Note: Features V1-V28 are anonymized (PCA-transformed) for privacy
--       and cannot be individually interpreted. Analysis focuses on
--       Amount, Time, and Class (0 = Normal, 1 = Fraud).
-- ================================================================


-- ================================================================
-- SECTION 1: FRAUD OVERVIEW
-- Goal: Understand the scale of the fraud problem
-- ================================================================

-- Q1: What is the total transaction count, fraud count, and fraud rate?
SELECT 
    COUNT(*) AS Total_Transactions,
    SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS Fraud_Transactions,
    ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 3) AS Fraud_Percentage
FROM fraud_data;

-- Q2: How does average transaction amount compare between Fraud and Normal?
SELECT Class, 
    COUNT(*) AS total_transactions,
    AVG(Amount) AS avg_amount,
    MIN(Amount) AS min_amount,
    MAX(Amount) AS max_amount
FROM fraud_data
GROUP BY Class;

-- Q3: What is the total monetary value of fraud vs normal transactions?
SELECT Class, SUM(Amount) AS total_amount
FROM fraud_data
GROUP BY Class;


-- ================================================================
-- SECTION 2: AMOUNT ANALYSIS
-- Goal: Understand what fraud transactions look like by value
-- ================================================================

-- Q1: What do the top 10 highest fraud transactions look like?
SELECT Class, Amount, Time
FROM fraud_data
WHERE Class = 1
ORDER BY Amount DESC
LIMIT 10;

-- Q2: What amount ranges do most fraud transactions fall into?
SELECT 
CASE
    WHEN Amount < 50 THEN 'Small (<50)'
    WHEN Amount BETWEEN 50 AND 200 THEN 'Medium (50-200)'
    WHEN Amount BETWEEN 200 AND 1000 THEN 'Large (200-1000)'
    ELSE 'Very Large (1000+)'
END AS Amount_Bucket,
COUNT(*) AS fraud_count
FROM fraud_data
WHERE Class = 1
GROUP BY Amount_Bucket
ORDER BY fraud_count DESC;

-- Q3: Is fraud RATE (%) higher in small or large transactions?
SELECT 
CASE
    WHEN Amount < 50 THEN 'Small (<50)'
    WHEN Amount BETWEEN 50 AND 200 THEN 'Medium (50-200)'
    WHEN Amount BETWEEN 200 AND 1000 THEN 'Large (200-1000)'
    ELSE 'Very Large (1000+)'
END AS Amount_Bucket,
COUNT(*) AS total_transactions,
SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS fraud_count,
ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 3) AS fraud_rate_percent
FROM fraud_data
GROUP BY Amount_Bucket
ORDER BY fraud_rate_percent DESC;


-- ================================================================
-- SECTION 3: TIME PATTERN ANALYSIS
-- Goal: Identify when fraud is most likely to occur
-- Note: Time = seconds elapsed since first transaction in dataset,
--       converted to hour-of-day using FLOOR(Time/3600) % 24
-- ================================================================

-- Q1: Which hour of the day has the most fraud cases?
SELECT 
FLOOR(Time / 3600) % 24 AS Hour_of_Day,
COUNT(*) AS fraud_count
FROM fraud_data
WHERE Class = 1
GROUP BY Hour_of_Day
ORDER BY fraud_count DESC;

-- Q2: Is fraud rate higher at Night (12AM-6AM) vs Day (7AM-11PM)?
SELECT 
CASE 
    WHEN (FLOOR(Time/3600) % 24) BETWEEN 0 AND 6 THEN 'Night (12AM-6AM)'
    ELSE 'Day (7AM-11PM)'
END AS Time_Period,
COUNT(*) AS total_transactions,
SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS fraud_count,
ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 3) AS fraud_rate_percent
FROM fraud_data
GROUP BY Time_Period;

-- Q3: Do fraudsters target higher amounts at specific hours?
SELECT 
FLOOR(Time/3600) % 24 AS Hour_of_Day,
COUNT(*) AS fraud_count,
ROUND(AVG(Amount), 2) AS avg_fraud_amount
FROM fraud_data
WHERE Class = 1
GROUP BY Hour_of_Day
ORDER BY fraud_count DESC
LIMIT 5;


-- ================================================================
-- SECTION 4: RISK FLAGGING
-- Goal: Build a simple SQL-based rule to flag suspicious transactions
-- ================================================================

-- Q1: Flag transactions into risk levels based on amount and time
SELECT 
COUNT(*) AS total_flagged,
CASE
    WHEN Amount > 1000 THEN 'High Risk - Large Amount'
    WHEN Amount > 200 AND (FLOOR(Time/3600) % 24) BETWEEN 0 AND 6 THEN 'Medium Risk - Night + Medium Amount'
    ELSE 'Low Risk'
END AS Risk_Flag
FROM fraud_data
GROUP BY Risk_Flag;

-- Q2: Validate the risk flag - how well does it catch real fraud?
SELECT 
CASE
    WHEN Amount > 1000 THEN 'High Risk - Large Amount'
    WHEN Amount > 200 AND (FLOOR(Time/3600) % 24) BETWEEN 0 AND 6 THEN 'Medium Risk - Night + Medium Amount'
    ELSE 'Low Risk'
END AS Risk_Flag,
COUNT(*) AS total_transactions,
SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS actual_fraud_count,
ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 3) AS actual_fraud_rate
FROM fraud_data
GROUP BY Risk_Flag
ORDER BY actual_fraud_rate DESC;

-- Q3: Save the risk-flagged dataset as a permanent table for reuse
CREATE TABLE fraud_risk_flagged AS
SELECT *,
CASE
    WHEN Amount > 1000 THEN 'High Risk - Large Amount'
    WHEN Amount > 200 AND (FLOOR(Time/3600) % 24) BETWEEN 0 AND 6 THEN 'Medium Risk - Night + Medium Amount'
    ELSE 'Low Risk'
END AS Risk_Flag
FROM fraud_data;

-- Verify the table was created correctly
SELECT COUNT(*) FROM fraud_risk_flagged;


-- ================================================================
-- KEY FINDINGS
-- ================================================================
-- Total Transactions:     284,807
-- Fraud Transactions:     492
-- Fraud Rate:             0.173%
--
-- Avg Amount (Normal):    £88.29
-- Avg Amount (Fraud):     £122.21
--
-- Fraud Rate by Amount Bucket:
--   Very Large (1000+):   0.306%  (highest by amount alone)
--   Large (200-1000):     0.293%
--   Small (<50):          0.161%
--   Medium (50-200):      0.154%
--
-- Risk Flag Validation (combining Amount + Time signals):
--   Medium Risk (Night + Medium Amount):  0.781% fraud rate  <-- 4.5x baseline
--   High Risk (Large Amount only):        0.306% fraud rate
--   Low Risk:                             0.168% fraud rate
--
-- KEY INSIGHT: Combining transaction time (night hours) with amount
-- is a far stronger fraud signal (0.781%) than amount alone (0.306%).
-- This suggests fraud detection rules should weight time-of-day
-- patterns, not just transaction size.
-- ================================================================
