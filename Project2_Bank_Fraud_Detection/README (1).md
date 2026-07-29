# Bank Fraud Detection Analysis (SQL Layer)

## 📌 Business Problem
A financial institution needed to understand fraud patterns in transaction data — which transaction characteristics correlate with fraud, and how could simple, explainable rules help flag suspicious activity before more advanced ML models are introduced.

**Central Question:** *Which transactions show fraud patterns, and how would we flag them for review?*

## 📂 Dataset
[Credit Card Fraud Detection](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud) — 284,807 anonymized European credit card transactions over 2 days.

**Columns:** `Time` (seconds since first transaction), `V1`-`V28` (anonymized/PCA-transformed features), `Amount`, `Class` (0 = Normal, 1 = Fraud)

**Note:** Features V1-V28 are anonymized for privacy and cannot be individually interpreted. This analysis focuses on `Amount`, `Time`, and `Class` — the three interpretable dimensions available.

## 🔍 Methodology
1. **Fraud Overview** — quantified the scale and rarity of fraud in the dataset
2. **Amount Analysis** — compared transaction values across fraud vs normal, and across amount buckets
3. **Time Pattern Analysis** — converted raw seconds into hour-of-day to detect time-based fraud patterns
4. **Risk Flagging** — built and validated a simple rule-based flagging system combining Amount and Time signals

## 📊 Key Findings

| Metric | Value |
|---|---|
| Total Transactions | 284,807 |
| Fraud Transactions | 492 |
| Fraud Rate | 0.173% |
| Avg Amount — Normal | £88.29 |
| Avg Amount — Fraud | £122.21 |

### Fraud Rate by Transaction Amount

| Amount Bucket | Fraud Rate |
|---|---|
| Very Large (1000+) | 0.306% |
| Large (200-1000) | 0.293% |
| Small (<50) | 0.161% |
| Medium (50-200) | 0.154% |

### Risk Flag Validation

| Risk Flag | Transactions | Fraud Count | Fraud Rate |
|---|---|---|---|
| **Medium Risk (Night + Medium Amount)** | 1,664 | 13 | **0.781%** |
| High Risk (Large Amount only) | 2,940 | 9 | 0.306% |
| Low Risk | 280,203 | 470 | 0.168% |

### 🎯 Headline Insight
**Combining transaction time with amount is a far stronger fraud signal than amount alone.** Transactions flagged as "Night + Medium Amount" showed a fraud rate of 0.781% — **4.5x higher** than the baseline rate (0.173%), and more than double the rate caught by flagging large amounts alone (0.306%).

This means fraud detection rules based purely on transaction size miss a significant pattern: fraud is disproportionately more likely for medium-value transactions occurring during low-monitoring night hours (12AM–6AM).

## 💡 Business Recommendations

1. **Prioritize time-aware fraud rules over amount-only rules** — a Night + Medium Amount rule catches fraud at a rate 2.5x higher than a Large Amount-only rule, despite flagging fewer transactions overall (1,664 vs 2,940). This means better precision with less manual review workload.

2. **Add step-up verification for medium-value transactions during night hours** — e.g., OTP or biometric confirmation for transactions between £50-200 occurring 12AM-6AM, where the fraud rate is highest relative to volume.

3. **Treat large transactions as a secondary signal, not the primary one** — while large transactions do carry elevated fraud risk (0.306%), the data shows time-of-day is a more discriminating factor and should be weighted accordingly in any scoring model.

## 🛠️ Tools & Skills Used
- **MySQL** — Data import via `LOAD DATA INFILE`, `CASE` statements for bucketing and rule-based flagging, conditional aggregation (`SUM(CASE WHEN...)`), `FLOOR()` and modulo for time transformation, `CREATE TABLE AS SELECT`
- **Techniques** — Fraud rate analysis, rule-based risk flagging, rule validation against ground truth

## 📁 Repository Contents
- `bank_fraud_detection_analysis.sql` — All 12 queries used in this analysis, organized by section

## 👤 Author
**Awan Mansuri** | BSc Information Technology | Aspiring Data Analyst
[LinkedIn](https://www.linkedin.com/in/awan-mansuri) | [GitHub](https://github.com/awan-mansuri)
