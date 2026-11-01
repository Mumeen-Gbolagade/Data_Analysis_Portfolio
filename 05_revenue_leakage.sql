/* =====================================================================
   05_revenue_leakage.sql
   Workstream 2 – where did revenue leak, how much was recovered, and
   where should Revenue Ops act first?
   ===================================================================== */

/* ---------------------------------------------------------------------
   Q1. Leakage at a glance (the six KPI cards)
   --------------------------------------------------------------------- */
-- name: ws2_headline
SELECT
    (SELECT SUM(total_leakage) FROM account_leakage)                                   AS leakage_identified,
    (SELECT COUNT(*) FROM recovery_cases)                                              AS cases,
    (SELECT COUNT(*) FROM account_leakage WHERE total_leakage > 0.5)                   AS accounts_leaking,
    (SELECT COUNT(*) FROM account_leakage)                                             AS accounts_audited,
    ROUND(1.0 * (SELECT SUM(total_leakage) FROM account_leakage)
          / (SELECT SUM(invoiced_in_window) FROM account_leakage), 4)                  AS leakage_vs_invoiced,
    (SELECT SUM(invoiced_in_window) FROM account_leakage)                              AS invoiced_in_window,
    (SELECT SUM(recovered)   FROM recovery_cases)                                      AS recovered,
    (SELECT SUM(in_progress) FROM recovery_cases)                                      AS in_progress,
    (SELECT SUM(written_off) FROM recovery_cases)                                      AS written_off,
    ROUND(1.0 * (SELECT SUM(recovered) FROM recovery_cases)
          / (SELECT SUM(amount_identified) FROM recovery_cases), 4)                    AS recovery_rate;

/* ---------------------------------------------------------------------
   Q2. What caused it? Leakage and recovery by type
   --------------------------------------------------------------------- */
-- name: ws2_by_type
SELECT
    leakage_type,
    COUNT(*)                                                    AS cases,
    SUM(amount_identified)                                      AS identified,
    SUM(recovered)                                              AS recovered,
    SUM(in_progress)                                            AS in_progress,
    SUM(written_off)                                            AS written_off,
    ROUND(1.0 * SUM(recovered) / SUM(amount_identified), 4)     AS recovery_rate,
    ROUND(1.0 * SUM(amount_identified)
          / (SELECT SUM(amount_identified) FROM recovery_cases), 4) AS share_of_leakage
FROM recovery_cases
GROUP BY leakage_type
ORDER BY identified DESC;

/* ---------------------------------------------------------------------
   Q3. Where in the market? Leakage by region, split by driver
   --------------------------------------------------------------------- */
-- name: ws2_by_region
SELECT
    region,
    COUNT(*)                                                         AS accounts,
    SUM(CASE WHEN total_leakage > 0.5 THEN 1 ELSE 0 END)             AS leaking,
    ROUND(1.0 * SUM(CASE WHEN total_leakage > 0.5 THEN 1 ELSE 0 END) / COUNT(*), 4) AS pct_leaking,
    SUM(pricing_leak)                                                AS pricing_leak,
    SUM(overage_leak)                                                AS overage_leak,
    SUM(failed_payment_leak)                                         AS failed_payment_leak,
    SUM(total_leakage)                                               AS total_leakage
FROM account_leakage
GROUP BY region
ORDER BY total_leakage DESC;

/* ---------------------------------------------------------------------
   Q4. Which RMS plans? Leakage by plan, split by driver
   --------------------------------------------------------------------- */
-- name: ws2_by_plan
SELECT
    plan,
    COUNT(*)                                                         AS accounts,
    SUM(CASE WHEN total_leakage > 0.5 THEN 1 ELSE 0 END)             AS leaking,
    ROUND(1.0 * SUM(CASE WHEN total_leakage > 0.5 THEN 1 ELSE 0 END) / COUNT(*), 4) AS pct_leaking,
    SUM(pricing_leak)                                                AS pricing_leak,
    SUM(overage_leak)                                                AS overage_leak,
    SUM(failed_payment_leak)                                         AS failed_payment_leak,
    SUM(total_leakage)                                               AS total_leakage
FROM account_leakage
GROUP BY plan
ORDER BY CASE plan WHEN 'RMS Starter' THEN 1 WHEN 'RMS Pro' THEN 2 ELSE 3 END;

/* ---------------------------------------------------------------------
   Q5. How fast did cash come back? Recovered per month and cumulative
   --------------------------------------------------------------------- */
-- name: ws2_recovery_by_month
SELECT
    recovery_month,
    SUM(recovered)                                                         AS recovered,
    SUM(SUM(recovered)) OVER (ORDER BY recovery_month
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative
FROM recovery_cases
WHERE status = 'Recovered'
GROUP BY recovery_month
ORDER BY recovery_month;

/* ---------------------------------------------------------------------
   Q6. Top 10 leaking accounts and their main driver
   --------------------------------------------------------------------- */
-- name: ws2_top10_accounts
SELECT
    account_id,
    plan,
    region,
    CASE
        WHEN failed_payment_leak >= pricing_leak AND failed_payment_leak >= overage_leak THEN 'Failed payment'
        WHEN pricing_leak >= overage_leak                                               THEN 'Pricing (discount/uplift)'
        ELSE 'Device overage'
    END                                    AS main_driver,
    total_leakage
FROM account_leakage
WHERE total_leakage > 0.5
ORDER BY total_leakage DESC, account_id
LIMIT 10;

/* ---------------------------------------------------------------------
   Q7. Concentration: share of leakage in the top 10 accounts
   --------------------------------------------------------------------- */
-- name: ws2_concentration
WITH ranked AS (
    SELECT total_leakage,
           ROW_NUMBER() OVER (ORDER BY total_leakage DESC, account_id) AS rn
    FROM account_leakage
)
SELECT
    ROUND(1.0 * SUM(CASE WHEN rn <= 10 THEN total_leakage ELSE 0 END) / SUM(total_leakage), 4) AS top10_share,
    ROUND(SUM(CASE WHEN rn <= 10 THEN total_leakage ELSE 0 END), 0)                    AS top10_leakage
FROM ranked;
