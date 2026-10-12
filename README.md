# PathWise — Navigation Product Analytics

**End-to-End Product Analytics Portfolio Case Study**  
**PostgreSQL | SQL | Python | Statistics | A/B Testing | Power BI**

**Created by:** Jatindra Kumar Soni  
**Education:** B.Tech in Computer Science and Business Systems (CSBS), Shri Shankaracharya Technical Campus  
**Focus:** Data Analytics, Product Analytics, and Data Engineering  
**GitHub:** [jatins2002](https://github.com/jatins2002)

> **Disclaimer:** PathWise is a fictional navigation application. This project uses synthetic data for portfolio practice. Observed results are not real-world business outcomes.

![PathWise Dashboard](images/pathwise-dashboard-overview.png)

## Project Overview

PathWise recommends routes using ETA, traffic, tolls, and user preferences. Users can accept the top recommendation or choose an alternative. This project investigates **why users reject recommended routes**, how navigation experiences relate to completion and retention, and whether displaying ETA confidence ranges improves outcomes.

**Business question:** How can PathWise increase trust in its route recommendations without compromising navigation reliability?

## Objectives

- Measure route acceptance and navigation funnel conversion.
- Investigate traffic uncertainty, tolls, route complexity, ETA accuracy, and preference alignment.
- Analyze completion, abandonment, rerouting, engagement, and retention.
- Evaluate an ETA-confidence-range A/B experiment, including experiment validity.
- Present findings and actionable recommendations in Power BI.

## Technology Stack

| Stage | Tools |
|---|---|
| Data storage | PostgreSQL (`pathwise` schema) |
| Data cleaning and analysis | SQL, CTEs, joins, window functions |
| EDA and statistical testing | Python, pandas, NumPy, SciPy, logistic regression |
| Experiment analysis | Two-proportion z-test, SRM checks, exposure audits |
| Visualization | Power BI, DAX, KPI cards, funnels, cohort heatmaps |
| Portfolio | Git, GitHub |

## Data

Six related synthetic datasets were analyzed:

| Table | Rows | Grain |
|---|---:|---|
| `users` | 20,000 | User |
| `navigation_sessions` | 300,000 | Navigation session |
| `route_options` | 900,000 | Route option |
| `user_events` | 2,225,247 | Event |
| `experiments` | 50,000 | Experiment exposure |
| `retention_daily` | 2,210,068 | User/activity date |

## Analytical Process

1. **Business understanding:** Define the navigation funnel and product KPIs.
2. **Data quality:** Check keys, nulls, event inconsistencies, and experiment assignments.
3. **Data cleaning:** Handle missing values with documented rules; preserve structural nulls.
4. **Funnel analysis:** Measure destination search → route recommendation → selection → start → completion → arrival.
5. **Route analytics:** Compare route acceptance across tolls, traffic, uncertainty, route type, and preferences.
6. **Statistics:** Test associations with Welch's t-test, chi-square, and logistic regression.
7. **Retention:** Analyze DAU/WAU/MAU, signup cohorts, and exact day-7 follow-up.
8. **A/B testing:** Quantify observed differences and audit validity.
9. **Dashboard:** Build a multi-section Power BI report for product stakeholders.

## Key Findings

| Metric | Result |
|---|---:|
| Navigation sessions | 300,000 |
| Recommended-route acceptance | **59.12%** |
| Completion among started navigations | **72.52%** |
| Average reroutes per started navigation | **0.97** |
| Mean signed ETA error | **+3.02 minutes** |

The largest funnel drop-off occurs between **Navigation Started** and **Navigation Completed**.

### Route Recommendation Insights

- **Toll sensitivity:** 64.60% acceptance when the recommendation is toll-free versus 47.86% when it includes a toll (**+16.74 percentage points**).
- **Traffic uncertainty:** acceptance is 67.13% at low uncertainty versus 45.77% at high uncertainty.
- **Preference match:** 73.42% acceptance for preference-matched recommendations versus 54.42% for mismatches (**+19.00 pp**).
- **Route type:** Fastest has the highest observed acceptance among recommended route types (**60.10%**).
- **ETA bias:** actual trips average **3.02 minutes longer** than the recommended ETA among included records. This is *signed* error, not mean absolute error.

These patterns are **associations, not proven causal effects**.

### Retention Insight

Exact day-7 follow-up was **22.59%** after accepted sessions versus **23.03%** after rejected sessions (p ≈ 0.063). The difference was **not statistically significant** at the 5% level.

**Caution:** Dashboard signup-cohort D7/D14/D30 calculations require additional date-coverage and eligibility validation before being treated as final retention benchmarks.

## A/B Experiment: ETA Confidence Range

**Control:** Single-number ETA.  
**Treatment:** ETA range with uncertainty messaging.

| Metric | Control | Treatment | Observed difference |
|---|---:|---:|---:|
| Route acceptance | 44.63% | 52.19% | **+7.56 pp** |
| Navigation completion | 68.36% | 75.13% | **+6.77 pp** |
| Experiment 7-day retention flag | 53.73% | 60.05% | **+6.32 pp** |

A naive exposure-level two-proportion test gives **p < 0.001** for acceptance. However, this is **not a trustworthy causal experiment**:

- **7,832 users** appeared in both experiment groups.
- **10,212 users** had multiple exposures.
- Exposure records span approximately **724 days**, compared with a planned **4–6 weeks**.

### Product Decision: RE-RUN CLEAN EXPERIMENT

**Do not ship based on this test alone.** Re-run with stable user-level assignment, no cross-group contamination, a predefined duration, and appropriate guardrail monitoring. Treat the observed lifts as promising but **not causally validated**.

## Power BI Dashboard

The report covers four analytics sections, with the experiment funnels and decision presented on a continuation page:

1. **Executive Product Overview:** users, sessions, acceptance, completion, retention, city breakdown, trends.
2. **Route Recommendation Analytics:** tolls, traffic, ETA errors, uncertainty, route types, city heatmap.
3. **User Behavior & Retention:** DAU/WAU/MAU, user segments, signup-cohort matrix.
4. **Experiment & Product Insights:** group comparison, absolute/relative lift, cumulative acceptance, funnels, experiment decision.

**Dashboard preview:** `images/pathwise-dashboard-overview.png`  
**Power BI file:** `powerbi/PathWise_Navigation_Product_Analytics.pbix` *(add your local file)*

> The combined dashboard image is for presentation. Refer to original Power BI pages for exact metrics and labels.

## Recommendations

1. Explore user-specific toll preferences and preference-aware ranking.
2. Test transparent ETA uncertainty messaging in a properly controlled experiment.
3. Investigate the Navigation Started → Completed drop-off.
4. Improve data instrumentation and experiment-assignment checks.
5. Validate cohort eligibility before drawing strong retention conclusions.

## Suggested Repository Structure

```text
PathWise-Product-Analytics/
├── README.md
├── data/
│   └── data_dictionary.xlsx
├── sql/
│   ├── data_quality/
│   ├── cleaning/
│   └── analytics/
├── python/
│   ├── eda/
│   └── statistics/
├── powerbi/
│   └── PathWise_Navigation_Product_Analytics.pbix
├── images/
│   └── pathwise-dashboard-overview.png
└── reports/
    └── PathWise_Dashboard.pdf
```

*This is a suggested structure; add only files that actually exist in your repository.*

## How to Explore

1. Read the business case and data dictionary.
2. Load the six CSVs into PostgreSQL under the `pathwise` schema.
3. Execute SQL cleaning and KPI analysis.
4. Run the Python statistical analysis.
5. Open the Power BI `.pbix` and update database credentials if necessary.
6. Review experiment limitations before interpreting the lift.

## Limitations

- Synthetic data, not a production product dataset.
- Observational findings cannot establish causation.
- Experiment contamination invalidates a straightforward rollout conclusion.
- Cohort retention requires further eligibility and coverage checks.
- No real-world revenue or efficiency improvement is claimed.

## About the Author

**Jatindra Kumar Soni** is a B.Tech graduate in Computer Science and Business Systems (CSBS) from Shri Shankaracharya Technical Campus, building practical experience across data analytics and data engineering. His toolkit includes **Python, SQL, PostgreSQL, PySpark, Databricks, Excel, and Power BI**. This project demonstrates an end-to-end product analytics workflow: defining business questions, validating and transforming data, applying statistical tests, designing an interactive dashboard, and making evidence-based recommendations.

- **GitHub:** https://github.com/jatins2002
- **Interests:** Product Analytics · Data Analytics · Data Engineering

---

**Project:** PathWise Navigation Product Analytics · **Category:** Product Analyst / Product Data Analyst Portfolio
