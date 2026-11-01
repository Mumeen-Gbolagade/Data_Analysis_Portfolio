# Revenue Leakage Recovery & Reporting Automation

**Cutting reporting time, recovering revenue and predicting churn for an IoT subscription business**

![SQL](https://img.shields.io/badge/SQL-SQLite%20%7C%20PostgreSQL-1E3D71) ![Python](https://img.shields.io/badge/Python-numpy%20%7C%20pandas-1E3D71) ![Excel](https://img.shields.io/badge/Excel-Dashboards-1E3D71) ![Model](https://img.shields.io/badge/Churn%20model-AUC%200.815-22BFD6) ![Validation](https://img.shields.io/badge/Validation-19%20of%2019%20passed-2E7D5B)

> [!NOTE]
> **Case study.** The data is modelled on the business of an IoT hardware and RMS cloud-subscription company, Teltonika IoT Group (Vilnius, Lithuania), to demonstrate the methods used. * This Data modelled based on case study Project only. 

![Executive dashboard](images/executive_dashboard.png)

---

## Results at a glance

| Workstream | Headline result | Target | Status |
|---|---|---|---|
| **1 · Reporting automation** | Reporting effort cut **60%**: 1,552 → 613 hours a year (939 hours, ≈ €51.6K of analyst time) | ≥ 50% | ✅ On target |
| | Month-end pack published in **2.3 days** instead of 7.3 | ≤ 4 days | ✅ On target |
| **2 · Revenue leakage** | Audit of **600 accounts** found **€125,485** of leakage in 132 cases on 123 accounts | ≥ €100K | ✅ On target |
| | **€120,625** recovered through billing corrections and dunning, a **96%** recovery rate | €100K · 60% | ✅ On target |
| | Billing accuracy **96.7%** (from 90.8%) | 97% | 🟠 Close |
| **3 · Churn prediction** | Hold-out **AUC 0.815**; top 20% of risk scores catch **53%** of churners | AUC ≥ 0.75 | ✅ On target |
| | Top risk decile churns at **56%** vs 16% average; retention prize **€177K/yr** (scenario) | – | 📌 Test before claiming |

---

## Contents
1. [Business problem](#1-business-problem)
2. [Objectives and key questions](#2-objectives-and-key-questions)
3. [Data](#3-data)
4. [KPI framework](#4-kpi-framework)
5. [Method, step by step](#5-method-step-by-step)
6. [Workstream 1: Reporting automation](#6-workstream-1-reporting-automation)
7. [Workstream 2: Revenue leakage recovery](#7-workstream-2-revenue-leakage-recovery)
8. [Workstream 3: Predictive churn model](#8-workstream-3-predictive-churn-model)
9. [Recommendations](#9-recommendations)
10. [Adapting to business strategy](#10-adapting-to-business-strategy)
11. [Validation](#11-validation)
12. [Repository structure and how to run](#12-repository-structure-and-how-to-run)
13. [Limitations](#13-limitations)

---

## 1. Business problem

The business sells IoT hardware (routers, gateways and trackers) in 150+ markets, plus **RMS (Remote Management System) cloud subscriptions** sold through distributors. Hardware sales were strong, but **recurring RMS revenue growth had slowed**, and leadership had three blind spots:

| | Problem | Business impact |
|---|---|---|
| **Reporting** | Analysts spent ~1,550 hours a year rebuilding eight recurring reports by hand; month-end packs arrived ~7 working days after close | Decisions made on stale numbers; skilled time spent on copy-paste |
| **Billing** | Contracts, partner discounts and connected-device counts lived in different systems (CRM, ERP billing, RMS platform). Expired promotions stayed on invoices, renewal uplifts were missed and devices above the licence went unbilled | Money earned but never collected |
| **Retention** | Churn was discovered only after customers had left; there was no early-warning signal and no single KPI view | Lost recurring revenue that might have been saved |

## 2. Objectives and key questions

| Workstream | SMART objective | Key questions |
|---|---|---|
| 1 · Reporting automation | Cut recurring reporting effort by **≥ 50% within six months**, without losing report content | Which reports take the most effort? What can be automated? How much capacity is released? |
| 2 · Revenue leakage | Audit **100% of RMS accounts** over a six-month window and **recover ≥ €100K within five months** | Where does revenue leak, how much, in which plans and markets? How much can realistically be recovered? |
| 3 · Churn & KPIs | Build a churn model with **hold-out AUC ≥ 0.75** and a monthly KPI tracker for leadership | Which signals predict churn? How concentrated is risk? What is it worth to act? |

**Scope:** Aug 2024 – Jul 2025 · EUR · Europe, Americas, APAC & MEA · baseline Aug 2024 – Jan 2025 (manual) vs project period Feb – Jul 2025 (automated reporting, leakage recovery and churn model).

## 3. Data

Five case-study datasets ([data dictionary](docs/data_dictionary.md)):

| File | Rows | What it holds |
|---|---|---|
| [`report_time_log.csv`](data/raw/report_time_log.csv) | 208 | One row per report run: date, report, phase (manual / automated), hours, analyst |
| [`report_catalogue.csv`](data/raw/report_catalogue.csv) | 8 | Each recurring report, runs per year and what was automated |
| [`rms_accounts.csv`](data/raw/rms_accounts.csv) | 600 | Contract fee, discounts, renewal uplift, devices included vs connected, what was billed, failed payments |
| [`recovery_log.csv`](data/raw/recovery_log.csv) | 132 | One case per leakage item: type, amount, action, status, month recovered |
| [`customers.csv`](data/raw/customers.csv) | 2,000 | Model features, churn outcome and a 70/30 Train/Test split |
| [`kpi_monthly_measures.csv`](data/raw/kpi_monthly_measures.csv) | 12 | Monthly billing accuracy, days to publish month-end, churn rate |

## 4. KPI framework

Ten KPIs, each with a definition, baseline, target, owner and review cycle (workbook tab `02_KPI_Framework`).

| KPI | Definition | Baseline | Result | Target | Owner |
|---|---|---|---|---|---|
| Reporting effort | Σ avg hours per run × runs per year | 1,552 h | **613 h** | ≤ 650 h | BI / Analytics |
| Reporting time reduction | 1 − hours after ÷ hours before | – | **60.5%** | ≥ 50% | BI / Analytics |
| Days to publish month-end | Working days from close to pack issued | 7.3 | **2.3** | ≤ 4 | Finance |
| Leakage identified | Σ rule-based gaps, 6-month audit | €0 | **€125,485** | ≥ €100K | Revenue Ops |
| Revenue recovered | Recovery log, status = Recovered | €0 | **€120,625** | ≥ €100K | Revenue Ops / Finance |
| Recovery rate | Recovered ÷ identified | – | **96.1%** | ≥ 60% | Revenue Ops |
| Billing accuracy | Invoices with no correction ÷ all invoices | 90.8% | **96.7%** | 97% | Billing |
| Churn model AUC (hold-out) | P(churner scores above a non-churner) | 0.50 | **0.815** | ≥ 0.75 | Analytics |
| Churners caught in top 20% | Recall in the top two risk deciles | 20% | **53.2%** | ≥ 40% | Customer Success |
| Monthly churn rate | Customers lost ÷ customers at start of month | 2.47% | **2.06%** | ≤ 2.0% | Customer Success |

*A baseline of 0, 0.5 or 20% means no process existed (no audit, a random model, random targeting).*

![KPI trends](images/exec_kpi_trends.png)

## 5. Method, step by step

| Step | What was done | Where |
|---|---|---|
| **1. Define** | Business context, problems and SMART objectives per workstream | Excel `01_Problem_Objectives` |
| **2. Set KPIs** | 10 KPIs with baseline, target, owner and review cycle | Excel `02_KPI_Framework` |
| **3. Load and clean** | Staging tables; phase labels standardised; text-stored numbers typed; leakage rules applied per account; customers scored | [`sql/01`](sql/01_create_tables.sql), [`sql/02`](sql/02_clean_transform.sql) |
| **4. Check data quality** | 8 checks: counts, duplicate keys, catalogue coverage, referential integrity, rules-vs-log reconciliation, status completeness, value ranges, Train/Test balance | [`sql/03`](sql/03_data_quality_checks.sql) · [log](docs/data_quality_log.md) |
| **5. Analyse** | Time study · contract-vs-billing audit and recovery tracking · logistic-regression churn model with lift and scenario | [`sql/04`](sql/04_reporting_automation.sql)–[`07`](sql/07_kpi_tracker.sql) · [`python/01`](python/01_train_churn_model.py) |
| **6. Visualise** | Executive dashboard and revenue leakage dashboard, all linked to live formulas | [`excel/`](excel/) |
| **7. Recommend and adapt** | Six actions tied to evidence, KPI and owner; re-prioritised by business strategy | Excel `09`, `10` |
| **8. Validate** | 19 pipeline figures checked against the workbook; SQL run on SQLite and PostgreSQL | [`python/03`](python/03_validate.py) · [results](docs/validation_results.md) |

## 6. Workstream 1: Reporting automation

**Method:** every run of the eight recurring reports was logged for 12 months. Annual effort = average hours per run × runs per year, measured separately for the baseline (Aug 2024 – Jan 2025, manual) and the project period (Feb – Jul 2025, automated).

| Report | Runs/yr | Hours before | Hours after | Saved | Reduction | What was automated |
|---|---:|---:|---:|---:|---:|---|
| Weekly distributor sales | 52 | 297.0 | 80.5 | 216.5 | 73% | SQL view + scheduled refresh |
| RMS billing exceptions | 52 | 203.5 | 53.0 | 150.5 | 74% | Rule-based exception query |
| Monthly revenue close pack | 12 | 263.0 | 113.0 | 150.0 | 57% | Automated reconciliations + template |
| Executive KPI pack | 12 | 205.5 | 85.0 | 120.5 | 59% | Single KPI dashboard replaces slides |
| Partner & distributor funnel | 52 | 180.0 | 82.0 | 98.0 | 54% | Direct CRM connector |
| RMS churn & retention | 12 | 144.5 | 49.0 | 95.5 | 66% | Model scores refreshed weekly |
| Quarterly board pack | 4 | 153.5 | 97.0 | 56.5 | 37% | Pre-built visuals, manual narrative kept |
| Market performance review | 12 | 104.5 | 53.5 | 51.0 | 49% | Parameterised dashboard page |
| **Total** | | **1,551.5** | **613.0** | **938.5** | **60.5%** | ≈ 0.57 FTE · €51,618 at €55/h |

> Released hours are **capacity**, not cash savings, unless headcount or contractor spend changes.

## 7. Workstream 2: Revenue leakage recovery

**Four rules** compare what the contract and the RMS device count say should be billed with what ERP billing actually invoiced, over the six months of billing from 1 Aug 2024:

| # | Rule | Logic |
|---|---|---|
| 1 | Expired partner discount still applied | Expected fee drops the discount once it has expired; leak = (expected − billed) × months |
| 2 | Missed renewal price uplift | Expected fee = contract fee × (1 + uplift); leak = (expected − billed) × months |
| 3 | Unbilled device overage | Expected overage = max(devices connected − included, 0) × rate; leak = (expected − billed overage) × months |
| 4 | Failed payment not retried | Failed invoices that were never retried |

![Revenue leakage dashboard](images/leakage_dashboard.png)

**Findings**
- **€125,485 leaking** across 132 cases on **123 of 600 accounts (21%)**, equal to **2.2%** of the €5.76m invoiced in the window. The rules total reconciles exactly with the recovery log.
- **€120,625 recovered (96%)** between March and July 2025 through back-billing, true-up invoices and dunning; €2,523 is still being chased and €2,337 was written off as uneconomic.
- **Unbilled device overage is the largest leak** (€39,570, 32%) and, after missed uplifts, has the lowest recovery rate (95%). Expired discounts are almost fully recovered (99%).
- **Europe** carries 57% of all leakage as the largest market; **RMS Pro** has the highest share of leaking accounts (26%).
- July was the strongest month (€53,867) as the final back-billing true-ups were paid; the **top 10 accounts hold 37%** of all leakage, a short call list for Revenue Ops.

| Leak type | Cases | Identified | Recovered | Recovery rate |
|---|---:|---:|---:|---:|
| Unbilled device overage | 50 | €39,570 | €37,530 | 95% |
| Failed payment not retried | 21 | €36,070 | €35,230 | 98% |
| Expired partner discount | 23 | €35,892 | €35,364 | 99% |
| Missed renewal uplift | 38 | €13,953 | €12,501 | 90% |
| **Total** | **132** | **€125,485** | **€120,625** | **96%** |

## 8. Workstream 3: Predictive churn model

**Method:** logistic regression fitted by Newton-Raphson on 70% of customers (1,397) and evaluated only on the 30% hold-out (603) the model never saw ([`python/01`](python/01_train_churn_model.py), [`sql/06`](sql/06_churn_model_evaluation.sql)).

| Driver | Coefficient | z | Reading |
|---|---:|---:|---|
| RMS login change (%) | −2.566 | −7.35 | Falling platform usage → much higher risk |
| Annual contract | −1.082 | −6.07 | Annual contracts churn far less |
| Late payments (12m) | +0.349 | 3.31 | Payment problems → higher risk |
| Support tickets (90d) | +0.298 | 5.40 | More tickets → higher risk |
| Tenure (months) | −0.044 | −8.21 | Longer-standing customers are safer |

**Hold-out performance:** AUC **0.815** · accuracy 82.9% · at a 0.30 threshold, precision 44.6% and recall 39.4% · the top two risk deciles capture **53%** of churners.

| Risk decile | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Churn rate | **56%** | 27% | 25% | 18% | 10% | 7% | 8% | 5% | 0% | 0% |
| Lift vs 15.6% base | **3.6×** | 1.7× | 1.6× | 1.2× | 0.6× | 0.4× | 0.5× | 0.3× | 0 | 0 |

**Retention scenario (an input, not a result):** churners in deciles 1–2 carry €885K of annual revenue. If a campaign saved 20% of them, that is **€177K a year**. This must be proven with a control group before it is claimed.

![Three workstreams](images/exec_workstreams.png)

## 9. Recommendations

| # | Finding | Recommendation | KPI and target | Owner | Priority |
|---|---|---|---|---|---|
| 1 | Automation cut effort 60% (939 h/yr); month-end in 2 days vs 7 | Redeploy released time to pricing and retention analysis; retire duplicate spreadsheets; keep the run log | Reporting hours ≤ 650/yr; pack ≤ 4 days | Head of BI | High |
| 2 | Expired discounts and missed uplifts: €49,845 | ERP controls: auto-expire partner discounts; apply uplifts from the contract record; monthly exception report | 0 new pricing-leak cases per quarter | Revenue Ops + Billing | High |
| 3 | Device overage is the largest leak: €39,570, 95% recovered | Bill overage monthly from RMS device counts; alert account managers at > 10% over licence to start an upgrade conversation | Unbilled overage €0; upgrade conversations logged | Revenue Ops + Account Mgmt | High |
| 4 | Failed payments never retried: €36,070 (€840 still open) | Automated dunning (retry + reminder + card-update link) and a weekly ageing review | ≥ 75% recovered within 30 days | Finance (AR) | Medium |
| 5 | AUC 0.82; top decile churns at 56% vs 16% | Weekly risk list to Customer Success; target deciles 1–2 first as a **controlled test** | Monthly churn ≤ 2.0%; save rate vs control | Customer Success + Analytics | High |
| 6 | Falling logins and tickets drive churn; annual contracts protect | In-app nudges when logins drop; incentivise annual contracts for high-risk monthly customers | Share on annual contracts; 30-day login trend | Product + Sales | Medium |

![Key insights and actions](images/exec_actions.png)

**From root cause to control:** each leak type is closed with a standing control so new leakage trends to €0.

![Root cause to control](images/leak_controls.png)

## 10. Adapting to business strategy

The same toolkit, re-prioritised for whichever strategy leadership chooses:

| If the strategy is… | Lead KPI | Prioritise | Watch-out |
|---|---|---|---|
| **Growth** | Net revenue retention; expansion revenue | Usage-based overage billing and upgrade alerts (Rec 3) | Don't let recovery work damage growing accounts or distributors |
| **Profitability** | Revenue recovered; billing accuracy | Leakage controls (Rec 2–4); analyst hours to pricing | Back-billing can trigger disputes; agree the tone with Sales |
| **Cost efficiency** | Reporting hours; FTE released | Automate the remaining reports (Rec 1) | Released capacity isn't cash unless spend changes |
| **Retention** | Monthly churn; churners in top 20% | Risk list and controlled test (Rec 5–6) | Model drift: retrain quarterly, monitor AUC |
| **Cash flow** | Failed-payment recovery; days to collect | Dunning automation (Rec 4) | Customer experience of reminders |
| **Risk & compliance** | Billing accuracy; audit coverage | Monthly audit as a standing control | Document rules so results are auditable |

## 11. Validation

- **19 of 19** headline figures from the SQL/Python pipeline match the Excel workbook exactly ([results](docs/validation_results.md)). The workbook's own 13 internal checks also pass.
- The churn model was **refitted independently in Python**: coefficients match the workbook to 15 decimal places and the hold-out AUC is identical (0.815136).
- All SQL runs unchanged on **SQLite 3.53 and PostgreSQL 16** with identical results. Testing caught three issues along the way (integer division returning a 0% recovery rate, `ROUND` on double precision in PostgreSQL, and a half-cent rounding difference between databases), all fixed and commented in the code.

## 12. Repository structure and how to run

```
revenue-leakage-recovery-analytics/
├── README.md
├── LICENSE
├── requirements.txt
├── data/
│   ├── raw/                      # 6 case-study source files
│   └── processed/                # model coefficients + every query output
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_clean_transform.sql    # leakage rules, churn scoring
│   ├── 03_data_quality_checks.sql
│   ├── 04_reporting_automation.sql
│   ├── 05_revenue_leakage.sql
│   ├── 06_churn_model_evaluation.sql
│   └── 07_kpi_tracker.sql
├── python/
│   ├── 01_train_churn_model.py   # logistic regression (Newton-Raphson)
│   ├── 02_build_database.py      # load + run all SQL, save outputs
│   └── 03_validate.py            # 19 checks against the workbook
├── excel/
│   └── Revenue_Leakage_Recovery_2025.xlsx   # 15 tabs incl. both dashboards
├── docs/
│   ├── methodology.md
│   ├── data_dictionary.md
│   ├── data_quality_log.md
│   └── validation_results.md
└── images/                       # dashboard screenshots
```

```bash
pip install -r requirements.txt
python python/01_train_churn_model.py   # fits the model, writes coefficients
python python/02_build_database.py      # builds data/revenue_analytics.db and all outputs
python python/03_validate.py            # checks results against the workbook
```
**PostgreSQL:** run `sql/01_create_tables.sql`, load the CSVs with the `\copy` commands at the end of that file, then run scripts 02 to 07.

**Workbook tabs:** `00_Read_Me` · `01_Problem_Objectives` · `02_KPI_Framework` · `03_Dashboard` · `03B_Leakage_Dashboard` · `04_Reporting_Time` · `05_Revenue_Leakage` · `06_Recovery_Log` · `07_Churn_Model` · `08_KPI_Tracker` · `09_Recommendations` · `10_Strategy_Playbook` · `11_Validation` · `12_Data_Dictionary` · `99_Chart_Data`

## 13. Limitations

- **Case-study data.** The results show the method, not a real company's outcomes.
- **Before/after is not proof of cause.** Other changes happened during the project period; billing accuracy and churn need controlled comparisons before results are attributed.
- **The retention scenario is an assumption** (20% save rate) and must be tested against a control group.
- The churn model is a simple, explainable baseline; it should be retrained quarterly and monitored for drift.

---

**Author:** Mumeen Gbolagade, Data Analyst, London · [GitHub profile](https://github.com/mumeen-gbola) · [LinkedIn](https://www.linkedin.com/in/gbolagade-mumeen-7261641b6/)
