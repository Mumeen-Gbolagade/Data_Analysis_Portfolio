/* =====================================================================
   06_churn_model_evaluation.sql
   Workstream 3 – how well does the churn model rank risk on customers
   it has never seen (the 30% Test set), and what is acting on it worth?
   Scores come from customer_scores (02_clean_transform.sql).
   ===================================================================== */

/* ---------------------------------------------------------------------
   Q1. Model coefficients (fitted in python/01_train_churn_model.py)
   --------------------------------------------------------------------- */
-- name: ws3_coefficients
-- CAST to NUMERIC: PostgreSQL's ROUND(x, n) needs NUMERIC, not DOUBLE PRECISION
SELECT term,
       ROUND(CAST(coefficient AS NUMERIC), 4) AS coefficient,
       ROUND(CAST(std_error   AS NUMERIC), 4) AS std_error,
       ROUND(CAST(z_value     AS NUMERIC), 2) AS z_value,
       reading
FROM model_coefficients;

/* ---------------------------------------------------------------------
   Q2. Hold-out evaluation: AUC (rank method), confusion matrix at the
       risk threshold, precision, recall, accuracy, top-20% capture
   AUC = (sum of churners' ranks − n1(n1+1)/2) / (n1 × n0)
   --------------------------------------------------------------------- */
-- name: ws3_evaluation
WITH t AS (SELECT * FROM customer_scores WHERE set_name = 'Test'),
s AS (
    SELECT
        COUNT(*)                                                       AS n_test,
        SUM(churned)                                                   AS n1,
        COUNT(*) - SUM(churned)                                        AS n0,
        SUM(CASE WHEN churned = 1 THEN test_rank ELSE 0 END)           AS rank_sum,
        SUM(CASE WHEN high_risk = 1 AND churned = 1 THEN 1 ELSE 0 END) AS tp,
        SUM(CASE WHEN high_risk = 1 AND churned = 0 THEN 1 ELSE 0 END) AS fp,
        SUM(CASE WHEN high_risk = 0 AND churned = 1 THEN 1 ELSE 0 END) AS fn,
        SUM(CASE WHEN high_risk = 0 AND churned = 0 THEN 1 ELSE 0 END) AS tn,
        SUM(CASE WHEN risk_decile <= 2 AND churned = 1 THEN 1 ELSE 0 END) AS caught_top20
    FROM t
)
SELECT
    n_test,
    n1                                                         AS churners,
    ROUND(1.0 * n1 / n_test, 4)                                AS base_churn_rate,
    ROUND((rank_sum - n1 * (n1 + 1) / 2.0) / (1.0 * n1 * n0), 6) AS auc,
    tp, fp, fn, tn,
    ROUND(1.0 * tp / (tp + fp), 4)                             AS precision_rate,
    ROUND(1.0 * tp / (tp + fn), 4)                             AS recall,
    ROUND(1.0 * (tp + tn) / n_test, 4)                         AS accuracy,
    ROUND(1.0 * caught_top20 / n1, 4)                          AS churners_caught_top20
FROM s;

/* ---------------------------------------------------------------------
   Q3. Lift: churn rate by risk decile (1 = highest risk)
   --------------------------------------------------------------------- */
-- name: ws3_deciles
WITH base AS (
    SELECT 1.0 * SUM(churned) / COUNT(*) AS rate FROM customer_scores WHERE set_name = 'Test'
)
SELECT
    risk_decile,
    COUNT(*)                                        AS customers,
    SUM(churned)                                    AS churners,
    ROUND(1.0 * SUM(churned) / COUNT(*), 4)         AS churn_rate,
    ROUND(1.0 * SUM(churned) / COUNT(*) / MAX(base.rate), 2) AS lift_vs_base
FROM customer_scores
CROSS JOIN base
WHERE set_name = 'Test'
GROUP BY risk_decile
ORDER BY risk_decile;

/* ---------------------------------------------------------------------
   Q4. Retention scenario (inputs, NOT results): revenue retained if a
       campaign saves the assumed share of churners in deciles 1–2
   --------------------------------------------------------------------- */
-- name: ws3_retention_scenario
SELECT
    SUM(monthly_fee) * 12                                                       AS annual_revenue_top2_churners,
    (SELECT param_value FROM assumptions WHERE param_name = 'assumed_save_rate') AS assumed_save_rate,
    ROUND(SUM(monthly_fee) * 12
          * (SELECT param_value FROM assumptions WHERE param_name = 'assumed_save_rate'), 0) AS revenue_retained_scenario
FROM customer_scores
WHERE set_name = 'Test' AND risk_decile <= 2 AND churned = 1;
