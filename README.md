# Retail Credit Risk PD Model

## Business Objective

Retail lending portfolios are exposed to significant default risk.  
This project develops a **Probability of Default (PD)** model to:

- Rank borrower risk systematically  
- Compare alternative model specifications  
- Simulate underwriting policy decisions  
- Quantify economic impact using Expected Loss  

---

## Interactive Dashboard Preview

### Portfolio Overview
Highlights validation default rate and risk distribution across Grade and FICO segments.

![Portfolio Overview](reports/portfolio.png)

### Model Discrimination
Decile analysis showing risk concentration and cumulative bad capture for both models.

![Model Lift Analysis](reports/lift.png)

### Policy Simulation
Expected loss impact under 30% risk rejection strategy.

![Policy Simulation](reports/policy_simulation.png)

---

## Dataset

**Source:** [LendingClub public dataset (Kaggle)] (https://www.kaggle.com/datasets/ethon0426/lending-club-20072020q1)

- Data restricted to 2016–2018 originations  
- Dataset not included due to size constraints  

### Temporal Split Strategy

2019 originations were excluded due to right-censoring:

- Many 2019 loans remained "Current"
- Only early defaults were resolved
- Including 2019 would bias PD upward

To avoid survivorship bias:

- **Training Set:** 2016–2017  
- **Validation Set:** 2018  

This ensures a clean out-of-time evaluation framework.    

---

## Modeling Approach

Two logistic regression models were developed:

### Model A — Borrower Risk Only
- WOE transformation  
- Excludes pricing variables  

### Model B — Borrower + Pricing
- Includes interest rate  
- Higher discrimination power, but introduces potential pricing circularity  

**Feature Engineering:**
- WOE encoding  
- IV-based variable selection  
- Logistic Regression (scikit-learn)  

---

## Model Performance (Validation Set)

| Metric | Model A | Model B |
|--------|---------|---------|
| AUC | 0.63 | 0.68 |
| KS | 0.19 | 0.26 |
| Top Decile Capture | 16.2% | 18.4% |
| 30% Reject Capture | 42.5% | 46.3% |

Model B demonstrates stronger risk concentration and separation.

---

## Policy Simulation

Underwriting strategy simulated:

> Reject top 30% highest predicted risk loans.

Expected Loss (EL) computed as:

EL = PD × LGD × Loan Amount 

LGD estimated from historical recoveries at 59.3%.

### Economic Impact

| Model | Baseline EL | Policy EL | EL Reduction |
|-------|-------------|-----------|--------------|
| Model A | 322M | 186M | 42% |
| Model B | 369M | 178M | 52% |

Model-driven rejection materially reduces portfolio expected loss.

---

## SQL Analysis

Four query modules validate model outputs and simulate business decisions directly in PostgreSQL.

| File | Purpose |
|------|---------|
| `portfolio_analysis.sql` | Baseline risk profiling — default rates segmented by Grade, FICO band, and loan term across the validation set |
| `decile_analysis.sql` | Ranks borrowers into 10 risk buckets for both models; computes bad rate and cumulative bad capture per decile |
| `model_performance_metrics.sql` | Calculates top-decile capture rate and 30% rejection capture for Model A vs Model B |
| `policy_simulation.sql` | Simulates a 30% risk-rejection underwriting policy; computes baseline vs post-policy Expected Loss using PD × LGD × Loan Amount |

---

## Key Insights

- FICO and Grade show strong default gradients — Grade G borrowers default at 
  nearly 4x the rate of Grade A, confirming these as primary risk drivers for 
  scorecard design
- Model B's interest rate inclusion improves discrimination (AUC 0.68 vs 0.63) 
  but introduces pricing circularity — high-risk borrowers receive higher rates, 
  which the model then uses to predict risk; unsuitable for production without 
  further isolation
- Top decile concentrates 18% of all defaults in just 10% of the portfolio — 
  meaningful risk separation for threshold-based underwriting
- A 30% risk-based rejection policy reduces expected loss by 52% while declining 
  less than a third of applications — a favorable risk-volume tradeoff for 
  most retail lending contexts

---

## Limitations & Future Work

- **Right-censoring:** 2019 originations excluded due to unresolved loan outcomes; 
  survival modeling (e.g. Cox regression) would handle this more rigorously
- **Reject inference:** Model trained only on approved loans — performance on 
  declined population is unknown, a known bias in all application scorecards
- **Single model class:** Logistic regression chosen for interpretability; 
  XGBoost would likely improve AUC but reduce regulatory explainability
- **LGD assumption:** Fixed at 59.3% from historical averages; a segmented 
  LGD model by collateral type or loan term would improve EL precision  

---

## Tech Stack

- **Python** (pandas, scikit-learn)  
- **PostgreSQL** (decile analysis & policy simulation)  
- **Power BI** (interactive dashboard reporting)  

---

## Repository Structure
- sql/ -> Analytics & policy simulation queries
- notebooks/ -> Modeling pipeline
- reports/ -> Power BI dashboard
- data/ -> Dataset placeholder


---

This project demonstrates end-to-end credit risk analytics:

**Data Preparation → PD Modeling → SQL Validation → Economic Simulation → Business Reporting**
