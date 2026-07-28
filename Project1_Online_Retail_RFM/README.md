# Online Retail Customer Segmentation Analysis (RFM)

## 📌 Business Problem
An online retailer needed to understand which customers to retain, reward, or let go — to focus limited marketing budget where it matters most.

**Central Question:** *Which customers should we retain, reward, or let go?*

## 📂 Dataset
[Online Retail Dataset](https://www.kaggle.com/datasets/vijayuv/onlineretail) — UK-based online retailer, 541,909 transactions, December 2010 to December 2011.

**Columns:** InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country

## 🧹 Data Cleaning
Before analysis, the raw data was audited for quality issues:
- Removed transactions with missing CustomerID (guest/unidentified checkouts)
- Removed rows with negative Quantity (returns/cancellations)
- Removed rows with zero or negative UnitPrice (invalid entries)
- Excluded cancelled invoices (InvoiceNo starting with 'C')

## 🔍 Methodology
Applied **RFM Analysis** (Recency, Frequency, Monetary) — a technique used by companies like Amazon and Netflix to prioritize customer retention efforts:

1. Calculated Recency (days since last purchase), Frequency (order count), and Monetary (total spend) per customer
2. Scored each metric 1–5 using the `NTILE()` window function
3. Combined scores into an RFM_Total (range: 3–15)
4. Segmented customers into **Champions, Loyal, At Risk, and Lost**

## 📊 Key Findings

| Metric | Value |
|---|---|
| Total Revenue | £8,911,407.90 |
| Total Customers Analyzed | 4,338 |
| Top Market | United Kingdom |

| Segment | Customers | % of Customers | Revenue | % of Revenue |
|---|---|---|---|---|
| Champions | 1,292 | 29.8% | £6,883,371 | 77.2% |
| Loyal | 1,017 | 23.4% | £1,163,113 | 13.1% |
| At Risk | 1,117 | 25.7% | £635,239 | 7.1% |
| Lost | 912 | 21.0% | £229,685 | 2.6% |

### 🎯 Headline Insight
**Just 29.8% of customers (Champions) generate 77.2% of total revenue** — a clear Pareto (80/20) pattern. This concentration means customer retention efforts should be highly targeted rather than spread evenly.

## 💡 Business Recommendations

1. **Protect Champions aggressively** — These 1,292 customers drive £6.88M in revenue. Losing even 10% of this segment would cost approximately £688K. Recommend a VIP loyalty program with early access to sales and dedicated support.

2. **Win back At Risk customers urgently** — 1,117 customers represent £635K in revenue that is actively slipping away. Recommend a targeted win-back email campaign with personalized discounts before they fully churn.

3. **Minimize spend on the Lost segment** — This segment contributes only 2.6% of total revenue. Recommend low-cost automated re-engagement only, reserving marketing budget for higher-value segments.

## 🛠️ Tools & Skills Used
- **MySQL** — Data cleaning, aggregation, subqueries (3 levels deep), window functions (`NTILE`), `CASE` statements, `CREATE TABLE AS SELECT`
- **Techniques** — RFM Analysis, Customer Segmentation, Pareto Analysis

## 📁 Repository Contents
- `online_retail_rfm_analysis.sql` — All 21 queries used in this analysis, organized by section
- `README.md` — This file

## 👤 Author
**Awan Mansuri** | BSc Information Technology | Aspiring Data Analyst
[LinkedIn](https://www.linkedin.com/in/awan-mansuri) | [GitHub](https://github.com/awan-mansuri)
