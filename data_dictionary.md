# Data dictionary

All datasets are **case-study data** (fixed random seed), with labels adapted to an IoT/RMS subscription context.

## `report_time_log.csv` – one row per report run
| Field | Meaning |
|---|---|
| Run_Date | Date of the run (YYYY-MM-DD) |
| Report | Recurring report name |
| Phase | `Before (manual)` (Aug 2024 – Jan 2025) or `After (automated)` (Feb – Jul 2025) |
| Hours | Hours logged for the run (quarter-hour precision) |
| Analyst | Analyst who ran it |

## `report_catalogue.csv`
| Field | Meaning |
|---|---|
| Report | Report name (matches the run log) |
| Runs_Per_Year | 52 weekly, 12 monthly, 4 quarterly |
| What_Was_Automated | The automation applied |

## `rms_accounts.csv` – 600 RMS subscription accounts
| Field | Meaning |
|---|---|
| Account_ID | Account key (AC-3000 …) |
| Plan | RMS Starter / RMS Pro / RMS Enterprise |
| Region | Europe / Americas / APAC & MEA |
| Contract_Monthly_Fee | Agreed monthly fee (EUR) |
| Promo_Discount_Pct, Discount_End_Date | Partner or promotional discount and the date it should stop (blank = none) |
| Renewal_Uplift_Pct | Contractual price increase due at renewal |
| Devices_Included, Avg_Devices_Connected, Overage_Rate_per_Device | Licence allowance, devices actually connected, price per extra device |
| Billed_Base_Fee, Billed_Overage | What ERP billing invoiced per month |
| Audit_Months | Months in the audit window (6) |
| Failed_Payments_Unrecovered | Value of failed invoices never retried (EUR) |

## `recovery_log.csv` – 132 leakage cases
| Field | Meaning |
|---|---|
| Case_ID, Account_ID | Case key and the account it belongs to |
| Leakage_Type | One of the four rule types |
| Amount_Identified | Leakage found (EUR) |
| Action | What was done (back-bill, true-up, dunning …) |
| Status | Recovered / In progress / Written off |
| Recovery_Month | First day of the month cash was recovered |

## `customers.csv` – 2,000 customers
| Field | Meaning |
|---|---|
| Customer_ID | Customer key |
| Set | Train (70%) / Test (30%) |
| Tenure_Months, Monthly_Fee | Months as a customer; monthly fee (EUR) |
| Support_Tickets_90d | Support tickets in the last 90 days |
| RMS_Login_Change_Pct | Change in RMS platform logins (−0.40 = 40% fewer) |
| Late_Payments_12m | Late payments in the last 12 months |
| Annual_Contract | 1 = annual, 0 = monthly |
| Churned | 1 = customer left |

## `kpi_monthly_measures.csv`
| Field | Meaning |
|---|---|
| Month | First day of month |
| Billing_Accuracy | Invoices with no correction ÷ all invoices |
| Days_To_Publish_Month_End | Working days from close to pack issued |
| Monthly_Churn_Rate | Customers lost ÷ customers at start of month |

## Derived tables (SQL)
| Table | Built in | Key columns |
|---|---|---|
| `time_log` | `02` | month, phase (Before/After) |
| `account_leakage` | `02` | expected_base_fee, pricing_leak, pricing_leak_type, overage_leak, failed_payment_leak, total_leakage |
| `recovery_cases` | `02` | recovered, in_progress, written_off, recovery_month |
| `customer_scores` | `02` | churn_probability, high_risk, test_rank, risk_decile |
