# Methodology

All data in this project is **case-study data**: it models an IoT hardware and RMS-subscription business and was generated with a fixed random seed. The methods below are what the project demonstrates.

## Workstream 1 – Reporting automation (time study)
- **Data:** every run of eight recurring reports over 12 months, with hours logged by the analyst (`report_time_log.csv`). Aug 2024 – Jan 2025 = manual baseline; Feb – Jul 2025 = automated.
- **Annual effort** per report = average hours per run in the phase × runs per year (`report_catalogue.csv`). Averaging dilutes one-off long runs.
- **Reduction** = 1 − annual hours after ÷ annual hours before → **60.5%** (1,551.5 h → 613 h).
- **Value of time** = hours saved × €55 per hour = **€51,618**. **FTE** = hours saved ÷ 1,650 productive hours = **0.57**.
- Released hours are capacity, not cash savings, unless spending actually changes.
- SQL: [`04_reporting_automation.sql`](04_reporting_automation.sql)

## Workstream 2 – Revenue leakage (contract vs billing vs device count)
- **Audit window:** six months of billing from 1 August 2024 (Aug 2024 – Jan 2025), 600 RMS accounts; cases were worked and recovered Mar – Jul 2025.
- **Expected base fee** = contract fee × (1 + renewal uplift) × (1 − discount, *only if the promotion was still valid at the audit start*).
- **Pricing leak** = max(expected − billed base fee, 0) × months. It is labelled *expired partner discount* if a promotion existed, otherwise *missed renewal uplift*.
- **Overage leak** = max(max(devices connected − included, 0) × overage rate − billed overage, 0) × months.
- **Failed-payment leak** = failed invoices never retried.
- **Total leakage** = pricing + overage + failed payments = **€125,485**, which reconciles exactly with the 132 cases in the recovery log.
- **Recovery:** each case has a status (Recovered / In progress / Written off) and a recovery month. Recovered through billing corrections and dunning = **€120,625 (96%)**; €2,523 still in progress; €2,337 written off.
- SQL: [`02_clean_transform.sql`](02_clean_transform.sql) (rules) and [`05_revenue_leakage.sql`](05_revenue_leakage.sql) (analysis)

## Workstream 3 – Churn model
- **Features** (measured before the outcome period): tenure, support tickets in 90 days, % change in RMS logins, late payments in 12 months, annual contract flag. Monthly fee is used only to value the retention scenario.
- **Split:** 70% Train (1,397) / 30% Test (603), fixed in the data.
- **Model:** logistic regression, maximum likelihood by Newton-Raphson ([`01_train_churn_model.py`](01_train_churn_model.py)). Standard errors come from the inverse Hessian.
- **Scoring:** p = 1 / (1 + e^−z) in SQL, using the saved coefficients.
- **AUC (rank method):** (Σ ranks of churners − n₁(n₁+1)/2) ÷ (n₁ × n₀), on the Test set only → **0.815**.
- **Deciles:** decile = min(10, ⌊(customers scoring higher ÷ n) × 10⌋ + 1), so decile 1 is the riskiest 10%.
- **Threshold:** p ≥ 0.30 flags high risk (precision 44.6%, recall 39.4%).
- **Retention scenario:** annual fee of churners in deciles 1–2 (€885K) × assumed save rate (20%) = €177K. This is an input-driven scenario, not a result.
- SQL: [`06_churn_model_evaluation.sql`](06_churn_model_evaluation.sql)

## KPI tracker
Reporting hours and revenue recovered come from the logs; billing accuracy, days to publish and monthly churn are monthly measurements. Baseline vs project-period averages show association, not proof of cause: other changes happened in the same period, and the retention pilot began in April 2025.

## Assumptions (table `assumptions`)
| Parameter | Value |
|---|---|
| Audit start | 1 Aug 2024 |
| Hourly cost of analyst time | €55 |
| Productive hours per FTE | 1,650 |
| Churn risk threshold | 0.30 |
| Assumed retention save rate (scenario) | 20% |
