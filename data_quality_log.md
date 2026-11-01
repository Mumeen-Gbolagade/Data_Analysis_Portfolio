# Data-quality log

Checks are in [`03_data_quality_checks.sql`](03_data_quality_checks.sql). They were run on SQLite 3.53 and PostgreSQL 16, with identical results.

| # | Check | Result | Status |
|---|---|---|---|
| DQ1 | Row counts | 208 runs · 8 reports · 600 accounts · 132 cases · 2,000 customers · 12 months | ✅ |
| DQ2 | Duplicate keys (account, case, customer) | 0 | ✅ |
| DQ3 | Every logged report is in the catalogue and has runs in both phases | Yes | ✅ |
| DQ4 | Every recovery case points to an account the rules flagged | Yes (132 of 132) | ✅ |
| DQ5 | Leakage found by the rules = amount in the recovery log | €125,485 = €125,485 | ✅ |
| DQ6 | Recovered + in progress + written off = identified; recovered cases have a month | Difference €0; 0 missing months | ✅ |
| DQ7 | Value ranges (hours > 0, fees > 0, discounts 0–1, probabilities 0–1, binary flags) | No violations | ✅ |
| DQ8 | Train/Test balance | 1,397 / 603 (70/30); churn 15.0% vs 15.6% | ✅ |

## Issues found in the source workbook and how they were handled

| Issue | Handling |
|---|---|
| Four numeric columns (`Devices_Included`, `Avg_Devices_Connected`, `Overage_Rate_per_Device`, `Audit_Months`) were stored as **text** in the workbook | Typed as INTEGER/DECIMAL in the staging tables |
| Phase labels mix descriptions (`Before (manual)`, `After (automated)`) | Standardised to `Before` / `After` in `time_log` |
| The leakage dashboard header showed a broken text fragment instead of the validation badge | Replaced with the same live formula used on the executive dashboard |
| The validation badge was navy text on a near-black band, so it was unreadable | Recoloured to the dashboard's light accent |
| Waterfall value labels were clipped by narrow bars | Bar gap width reduced so labels fit |
| Wording slips ("Seat overage", "$0" in a euro workbook) | Corrected to "Device overage" and "0 new cases per quarter" |

Outliers were not removed: every value lies within plausible business ranges, and the time study deliberately averages runs so that one-off long runs are diluted.
