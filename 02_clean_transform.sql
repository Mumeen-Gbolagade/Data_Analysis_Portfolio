/* =====================================================================
   02_clean_transform.sql
   Typed, analysis-ready tables.
     time_log        – adds month and a short Before/After phase
     account_leakage – applies the four contract-vs-billing leakage rules
     recovery_cases  – normalises status and month
     customer_scores – churn probability, risk flag, rank and decile
   ===================================================================== */

DROP TABLE IF EXISTS time_log;
DROP TABLE IF EXISTS account_leakage;
DROP TABLE IF EXISTS recovery_cases;
DROP TABLE IF EXISTS customer_scores;

/* ---- Workstream 1: report run log --------------------------------- */
CREATE TABLE time_log AS
SELECT
    run_date,
    substr(run_date, 1, 7)                                        AS month,
    report,
    CASE WHEN phase LIKE 'Before%' THEN 'Before' ELSE 'After' END AS phase,
    hours,
    analyst
FROM stg_report_time_log;

/* ---- Workstream 2: leakage rules per account -----------------------
   Rule 1+2  Expected base fee = contract fee × (1 + renewal uplift)
                                 × (1 − discount, only if the promotion was
                                   still valid at the audit start)
             Pricing leak      = max(expected − billed base, 0) × months
             → 'Expired partner discount still applied' if a promotion
               existed, otherwise 'Missed renewal price uplift'
   Rule 3    Overage leak      = max(max(connected − included, 0) × rate
                                     − billed overage, 0) × months
   Rule 4    Failed payments never retried
   Total     = pricing + overage + failed payments
   ------------------------------------------------------------------- */
CREATE TABLE account_leakage AS
WITH a AS (
    SELECT
        s.*,
        s.contract_monthly_fee * (1 + s.renewal_uplift_pct)
          * (1 - CASE
                   WHEN s.promo_discount_pct > 0
                    AND CAST(replace(s.discount_end_date, '-', '') AS INTEGER) >
                        (SELECT param_value FROM assumptions WHERE param_name = 'audit_start_yyyymmdd')
                   THEN s.promo_discount_pct ELSE 0
                 END)                                                         AS expected_base_fee,
        CASE WHEN s.avg_devices_connected > s.devices_included
             THEN (s.avg_devices_connected - s.devices_included) * s.overage_rate_per_device
             ELSE 0 END                                                       AS expected_overage
    FROM stg_rms_accounts s
),
b AS (
    SELECT
        a.*,
        CASE WHEN expected_base_fee > billed_base_fee
             THEN (expected_base_fee - billed_base_fee) * audit_months
             ELSE 0 END                                                       AS pricing_leak,
        CASE WHEN expected_overage > billed_overage
             THEN (expected_overage - billed_overage) * audit_months
             ELSE 0 END                                                       AS overage_leak
    FROM a
)
SELECT
    account_id, plan, region,
    contract_monthly_fee, billed_base_fee, audit_months,
    expected_base_fee, expected_overage,
    pricing_leak,
    CASE WHEN pricing_leak > 0.5
         THEN CASE WHEN promo_discount_pct > 0
                   THEN 'Expired partner discount still applied'
                   ELSE 'Missed renewal price uplift' END
    END                                                                       AS pricing_leak_type,
    overage_leak,
    failed_payments_unrecovered                                               AS failed_payment_leak,
    pricing_leak + overage_leak + failed_payments_unrecovered                 AS total_leakage,
    (billed_base_fee + billed_overage) * audit_months                         AS invoiced_in_window
FROM b;

/* ---- Workstream 2: recovery cases ---------------------------------- */
CREATE TABLE recovery_cases AS
SELECT
    case_id, account_id, leakage_type, amount_identified, action, status,
    CASE WHEN status = 'Recovered' THEN substr(recovery_month, 1, 7) END   AS recovery_month,
    CASE WHEN status = 'Recovered'   THEN amount_identified ELSE 0 END     AS recovered,
    CASE WHEN status = 'In progress' THEN amount_identified ELSE 0 END     AS in_progress,
    CASE WHEN status = 'Written off' THEN amount_identified ELSE 0 END     AS written_off
FROM stg_recovery_log;

/* ---- Workstream 3: score every customer ---------------------------- */
CREATE TABLE customer_scores AS
WITH c AS (
    SELECT
        MAX(CASE WHEN term = 'Intercept'            THEN coefficient END) AS b0,
        MAX(CASE WHEN term = 'Tenure_Months'        THEN coefficient END) AS b_ten,
        MAX(CASE WHEN term = 'Support_Tickets_90d'  THEN coefficient END) AS b_tix,
        MAX(CASE WHEN term = 'RMS_Login_Change_Pct' THEN coefficient END) AS b_log,
        MAX(CASE WHEN term = 'Late_Payments_12m'    THEN coefficient END) AS b_late,
        MAX(CASE WHEN term = 'Annual_Contract'      THEN coefficient END) AS b_ann
    FROM model_coefficients
),
p AS (
    SELECT
        s.*,
        1.0 / (1 + EXP(-(c.b0 + c.b_ten * s.tenure_months + c.b_tix * s.support_tickets_90d
                         + c.b_log * s.rms_login_change_pct + c.b_late * s.late_payments_12m
                         + c.b_ann * s.annual_contract)))                AS churn_probability
    FROM stg_customers s
    CROSS JOIN c
),
t AS (
    /* rank within the Test set: count of Test customers scoring <= this one */
    SELECT customer_id,
           COUNT(*) OVER (ORDER BY churn_probability
                          RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS test_rank,
           COUNT(*) OVER ()                                                  AS n_test
    FROM p
    WHERE set_name = 'Test'
)
SELECT
    p.customer_id, p.set_name, p.tenure_months, p.monthly_fee, p.support_tickets_90d,
    p.rms_login_change_pct, p.late_payments_12m, p.annual_contract, p.churned,
    p.churn_probability,
    CASE WHEN p.churn_probability >=
              (SELECT param_value FROM assumptions WHERE param_name = 'risk_threshold')
         THEN 1 ELSE 0 END                                                AS high_risk,
    t.test_rank,
    /* decile 1 = highest risk; same rule as the workbook */
    CASE WHEN t.customer_id IS NOT NULL THEN
        CASE WHEN CAST((t.n_test - t.test_rank) * 10 / t.n_test AS INTEGER) + 1 > 10 THEN 10
             ELSE CAST((t.n_test - t.test_rank) * 10 / t.n_test AS INTEGER) + 1 END
    END                                                                   AS risk_decile
FROM p
LEFT JOIN t ON t.customer_id = p.customer_id;
