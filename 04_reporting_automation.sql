/* =====================================================================
   04_reporting_automation.sql
   Workstream 1 – how much reporting time did automation release?
   Annual hours = average hours per run × runs per year, measured
   separately for the baseline Aug 2024 – Jan 2025 (manual) and the
   project period Feb – Jul 2025 (automated).
   ===================================================================== */

/* ---------------------------------------------------------------------
   Q1. Effort per report, before vs after
   --------------------------------------------------------------------- */
-- name: ws1_hours_by_report
WITH avg_run AS (
    SELECT report,
           AVG(CASE WHEN phase = 'Before' THEN hours END) AS avg_before,
           AVG(CASE WHEN phase = 'After'  THEN hours END) AS avg_after
    FROM time_log
    GROUP BY report
)
SELECT
    c.report,
    c.runs_per_year,
    ROUND(a.avg_before, 2)                                                    AS avg_hours_before,
    ROUND(a.avg_after, 2)                                                     AS avg_hours_after,
    ROUND(a.avg_before * c.runs_per_year, 1)                                  AS annual_hours_before,
    ROUND(a.avg_after  * c.runs_per_year, 1)                                  AS annual_hours_after,
    ROUND((a.avg_before - a.avg_after) * c.runs_per_year, 1)                  AS hours_saved,
    ROUND(1 - a.avg_after / a.avg_before, 4)                                  AS reduction,
    c.what_was_automated
FROM stg_report_catalogue c
JOIN avg_run a ON a.report = c.report
ORDER BY hours_saved DESC;

/* ---------------------------------------------------------------------
   Q2. Headline: total hours, reduction, value and FTE released
   --------------------------------------------------------------------- */
-- name: ws1_summary
WITH avg_run AS (
    SELECT report,
           AVG(CASE WHEN phase = 'Before' THEN hours END) AS avg_before,
           AVG(CASE WHEN phase = 'After'  THEN hours END) AS avg_after
    FROM time_log
    GROUP BY report
),
tot AS (
    SELECT SUM(a.avg_before * c.runs_per_year) AS hours_before,
           SUM(a.avg_after  * c.runs_per_year) AS hours_after
    FROM stg_report_catalogue c
    JOIN avg_run a ON a.report = c.report
)
SELECT
    ROUND(hours_before, 1)                                                    AS annual_hours_before,
    ROUND(hours_after, 1)                                                     AS annual_hours_after,
    ROUND(hours_before - hours_after, 1)                                      AS hours_saved,
    ROUND(1 - hours_after / hours_before, 4)                                  AS reduction,
    /* hours are logged in quarter-hours: round to 2 dp first so averaging noise
       cannot flip the final rounding (938.5 h × €55 = €51,617.50 → €51,618) */
    ROUND(ROUND(hours_before - hours_after, 2)
          * (SELECT param_value FROM assumptions WHERE param_name = 'hourly_cost_eur'), 0)          AS value_eur,
    ROUND(ROUND(hours_before - hours_after, 2)
          / (SELECT param_value FROM assumptions WHERE param_name = 'productive_hours_per_fte'), 2)  AS fte_released
FROM tot;

/* ---------------------------------------------------------------------
   Q3. Reporting hours per month (the trend on the dashboard)
   --------------------------------------------------------------------- */
-- name: ws1_hours_by_month
SELECT month, phase, ROUND(SUM(hours), 2) AS hours, COUNT(*) AS runs
FROM time_log
GROUP BY month, phase
ORDER BY month;
