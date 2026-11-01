/* =====================================================================
   03_data_quality_checks.sql
   Run after 02. Each check returns a small result; the expected result
   is written above it. Results are recorded in docs/data_quality_log.md.
   ===================================================================== */

/* DQ1 – Row counts: expect 208 runs, 8 reports, 600 accounts,
         184 cases, 2,000 customers, 12 months */
SELECT 'report runs' AS dataset, COUNT(*) AS n_rows FROM time_log
UNION ALL SELECT 'reports',         COUNT(*) FROM stg_report_catalogue
UNION ALL SELECT 'accounts',        COUNT(*) FROM account_leakage
UNION ALL SELECT 'recovery cases',  COUNT(*) FROM recovery_cases
UNION ALL SELECT 'customers',       COUNT(*) FROM customer_scores
UNION ALL SELECT 'KPI months',      COUNT(*) FROM stg_kpi_monthly_measures;

/* DQ2 – Duplicate keys: expect no rows */
SELECT 'account' AS key_type, account_id AS key_value, COUNT(*) AS n FROM stg_rms_accounts GROUP BY account_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'case', case_id, COUNT(*) FROM stg_recovery_log GROUP BY case_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'customer', customer_id, COUNT(*) FROM stg_customers GROUP BY customer_id HAVING COUNT(*) > 1;

/* DQ3 – Every report in the run log exists in the catalogue, and every
         report has runs in both phases: expect no rows */
SELECT t.report, 'missing from catalogue' AS issue
FROM (SELECT DISTINCT report FROM time_log) t
LEFT JOIN stg_report_catalogue c ON c.report = t.report
WHERE c.report IS NULL
UNION ALL
SELECT report, 'runs in only one phase'
FROM time_log GROUP BY report HAVING COUNT(DISTINCT phase) < 2;

/* DQ4 – Referential integrity: every recovery case points to an account
         that the rules flagged as leaking: expect no rows */
SELECT r.case_id, r.account_id
FROM recovery_cases r
LEFT JOIN account_leakage a ON a.account_id = r.account_id
WHERE a.account_id IS NULL OR a.total_leakage <= 0.5;

/* DQ5 – Reconciliation: leakage found by the rules = amount logged in the
         recovery log (expect difference 0) */
SELECT
    (SELECT SUM(total_leakage)     FROM account_leakage)                              AS rules_total,
    (SELECT SUM(amount_identified) FROM recovery_cases)                               AS log_total,
    (SELECT SUM(total_leakage) FROM account_leakage)
      - (SELECT SUM(amount_identified) FROM recovery_cases)                           AS difference;

/* DQ6 – Status completeness: recovered + in progress + written off =
         identified, and every recovered case has a month: expect 0 / 0 */
SELECT
    SUM(amount_identified) - SUM(recovered + in_progress + written_off)               AS unbalanced_amount,
    SUM(CASE WHEN status = 'Recovered' AND recovery_month IS NULL THEN 1 ELSE 0 END)  AS recovered_without_month
FROM recovery_cases;

/* DQ7 – Value ranges: fees and hours positive, probabilities 0–1,
         binary flags 0/1: expect no rows */
SELECT 'negative or zero hours' AS issue, COUNT(*) AS n FROM time_log WHERE hours <= 0 HAVING COUNT(*) > 0
UNION ALL SELECT 'non-positive contract fee', COUNT(*) FROM stg_rms_accounts WHERE contract_monthly_fee <= 0 HAVING COUNT(*) > 0
UNION ALL SELECT 'discount outside 0-1', COUNT(*) FROM stg_rms_accounts WHERE promo_discount_pct NOT BETWEEN 0 AND 1 HAVING COUNT(*) > 0
UNION ALL SELECT 'probability outside 0-1', COUNT(*) FROM customer_scores WHERE churn_probability NOT BETWEEN 0 AND 1 HAVING COUNT(*) > 0
UNION ALL SELECT 'non-binary churn flag', COUNT(*) FROM stg_customers WHERE churned NOT IN (0, 1) OR annual_contract NOT IN (0, 1) HAVING COUNT(*) > 0;

/* DQ8 – Train/Test split: expect about 70/30 and a similar churn rate in both */
SELECT set_name, COUNT(*) AS customers, SUM(churned) AS churners,
       ROUND(1.0 * SUM(churned) / COUNT(*), 4) AS churn_rate
FROM customer_scores
GROUP BY set_name
ORDER BY set_name DESC;
