/* =====================================================================
   01_create_tables.sql
   Revenue Leakage Recovery & Reporting Automation – staging tables
   ---------------------------------------------------------------------
   Purpose : Hold the six source files exactly as exported, plus the
             model coefficients produced by python/01_train_churn_model.py
             and the business assumptions used in the analysis.
   Data    : Case-study data modelled on an IoT subscription business (see README – not company data).
   Dialect : ANSI SQL. Tested on SQLite 3.53 and PostgreSQL 16.
   Run     : python python/02_build_database.py
   ===================================================================== */

DROP TABLE IF EXISTS stg_report_time_log;
DROP TABLE IF EXISTS stg_report_catalogue;
DROP TABLE IF EXISTS stg_rms_accounts;
DROP TABLE IF EXISTS stg_recovery_log;
DROP TABLE IF EXISTS stg_customers;
DROP TABLE IF EXISTS stg_kpi_monthly_measures;
DROP TABLE IF EXISTS model_coefficients;
DROP TABLE IF EXISTS assumptions;

/* Workstream 1 – one row per recurring report run (Aug 2024 – Jul 2025) */
CREATE TABLE stg_report_time_log (
    run_date        VARCHAR(10)  NOT NULL,   -- 'YYYY-MM-DD'
    report          VARCHAR(80)  NOT NULL,
    phase           VARCHAR(30)  NOT NULL,   -- 'Before (manual)' / 'After (automated)'
    hours           DECIMAL(6,2) NOT NULL,
    analyst         VARCHAR(20)
);

CREATE TABLE stg_report_catalogue (
    report              VARCHAR(80) NOT NULL,
    runs_per_year       INTEGER     NOT NULL,
    what_was_automated  VARCHAR(80)
);

/* Workstream 2 – 600 RMS subscription accounts, 6-month audit window */
CREATE TABLE stg_rms_accounts (
    account_id                   VARCHAR(10) NOT NULL,
    plan                         VARCHAR(20),     -- RMS Starter / Pro / Enterprise
    region                       VARCHAR(20),     -- Europe / Americas / APAC & MEA
    contract_monthly_fee         DECIMAL(10,2),
    promo_discount_pct           DECIMAL(5,3),
    discount_end_date            VARCHAR(10),     -- blank = no promotion
    renewal_uplift_pct           DECIMAL(5,3),
    devices_included             INTEGER,
    avg_devices_connected        INTEGER,
    overage_rate_per_device      DECIMAL(8,2),
    billed_base_fee              DECIMAL(10,2),   -- what ERP billing invoiced per month
    billed_overage               DECIMAL(10,2),
    audit_months                 INTEGER,
    failed_payments_unrecovered  DECIMAL(10,2)
);

CREATE TABLE stg_recovery_log (
    case_id            VARCHAR(10) NOT NULL,
    account_id         VARCHAR(10) NOT NULL,
    leakage_type       VARCHAR(60) NOT NULL,
    amount_identified  DECIMAL(10,2) NOT NULL,
    action             VARCHAR(120),
    status             VARCHAR(20) NOT NULL,   -- Recovered / In progress / Written off
    recovery_month     VARCHAR(10)             -- 'YYYY-MM-01' when recovered
);

/* Workstream 3 – 2,000 RMS customers with a 70/30 Train/Test split */
CREATE TABLE stg_customers (
    customer_id            VARCHAR(10) NOT NULL,
    set_name               VARCHAR(5)  NOT NULL,   -- 'Train' / 'Test'
    tenure_months          INTEGER,
    monthly_fee            DECIMAL(10,2),
    support_tickets_90d    INTEGER,
    rms_login_change_pct   DECIMAL(6,3),
    late_payments_12m      INTEGER,
    annual_contract        INTEGER,                -- 1 = annual, 0 = monthly
    churned                INTEGER                 -- 1 = left
);

/* Monthly KPI measurements that are not derived from the logs */
CREATE TABLE stg_kpi_monthly_measures (
    month                      VARCHAR(10) NOT NULL,
    billing_accuracy           DECIMAL(6,4),
    days_to_publish_month_end  DECIMAL(4,1),
    monthly_churn_rate         DECIMAL(6,4)
);

/* Written by python/01_train_churn_model.py */
CREATE TABLE model_coefficients (
    term         VARCHAR(30) NOT NULL,
    coefficient  DOUBLE PRECISION NOT NULL,
    std_error    DOUBLE PRECISION,
    z_value      DOUBLE PRECISION,
    reading      VARCHAR(80)
);

CREATE TABLE assumptions (
    param_name   VARCHAR(40) PRIMARY KEY,
    param_value  DECIMAL(12,4) NOT NULL,
    note         VARCHAR(200)
);

INSERT INTO assumptions (param_name, param_value, note) VALUES
  ('audit_start_yyyymmdd',  20240801, 'Start of the 6-month leakage audit window (Aug 2024 – Jan 2025 billing)'),
  ('hourly_cost_eur',             55, 'Cost of one analyst hour, used to value released time'),
  ('productive_hours_per_fte',  1650, 'Annual productive hours of one FTE'),
  ('risk_threshold',            0.30, 'Churn probability at or above which a customer is flagged high risk'),
  ('assumed_save_rate',         0.20, 'Share of targeted high-risk churners a retention campaign might save (scenario input)');

/* PostgreSQL load (repository root, in psql):
   \copy stg_report_time_log      FROM 'report_time_log.csv'      CSV HEADER
   \copy stg_report_catalogue     FROM 'report_catalogue.csv'     CSV HEADER
   \copy stg_rms_accounts         FROM 'rms_accounts.csv'         CSV HEADER NULL ''
   \copy stg_recovery_log         FROM 'recovery_log.csv'         CSV HEADER NULL ''
   \copy stg_customers            FROM 'customers.csv'            CSV HEADER
   \copy stg_kpi_monthly_measures FROM 'kpi_monthly_measures.csv' CSV HEADER
   \copy model_coefficients       FROM 'outputs/model_coefficients.csv' CSV HEADER
*/
