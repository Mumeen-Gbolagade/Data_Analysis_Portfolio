/* =====================================================================
   07_kpi_tracker.sql
   Monthly KPI tracker, Aug 2024 – Jul 2025, and the baseline (manual,
   Aug 2024 – Jan 2025) vs project (automated, Feb – Jul 2025) comparison. Reporting hours and revenue recovered come from the logs;
   billing accuracy, days to publish and churn rate are monthly
   measurements (stg_kpi_monthly_measures).
   ===================================================================== */

/* ---------------------------------------------------------------------
   Q1. Monthly tracker
   --------------------------------------------------------------------- */
-- name: kpi_monthly_tracker
WITH hrs AS (
    SELECT month, SUM(hours) AS reporting_hours FROM time_log GROUP BY month
),
rec AS (
    SELECT recovery_month AS month, SUM(recovered) AS revenue_recovered
    FROM recovery_cases WHERE status = 'Recovered' GROUP BY recovery_month
)
SELECT
    substr(m.month, 1, 7)                                         AS month,
    CASE WHEN m.month < '2025-02' THEN 'Before' ELSE 'After' END AS phase,
    COALESCE(h.reporting_hours, 0)                                AS reporting_hours,
    COALESCE(r.revenue_recovered, 0)                              AS revenue_recovered,
    m.billing_accuracy,
    m.days_to_publish_month_end,
    m.monthly_churn_rate
FROM stg_kpi_monthly_measures m
LEFT JOIN hrs h ON h.month = substr(m.month, 1, 7)
LEFT JOIN rec r ON r.month = substr(m.month, 1, 7)
ORDER BY m.month;

/* ---------------------------------------------------------------------
   Q2. Before (Aug 2024 – Jan 2025) vs after (Feb – Jul 2025) averages
   --------------------------------------------------------------------- */
-- name: kpi_before_after
WITH hrs AS (SELECT month, SUM(hours) AS h FROM time_log GROUP BY month),
m AS (
    SELECT
        CASE WHEN k.month < '2025-02' THEN '1. Before (Aug-Jan)' ELSE '2. After (Feb-Jul)' END AS period,
        h.h AS reporting_hours, k.billing_accuracy, k.days_to_publish_month_end, k.monthly_churn_rate
    FROM stg_kpi_monthly_measures k
    LEFT JOIN hrs h ON h.month = substr(k.month, 1, 7)
)
SELECT
    period,
    ROUND(AVG(reporting_hours), 2)            AS avg_reporting_hours,
    ROUND(AVG(billing_accuracy), 4)           AS avg_billing_accuracy,
    ROUND(AVG(days_to_publish_month_end), 2)  AS avg_days_to_publish,
    ROUND(AVG(monthly_churn_rate), 4)         AS avg_monthly_churn
FROM m
GROUP BY period
ORDER BY period;
