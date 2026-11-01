"""
03_validate.py
--------------
Checks every headline figure produced by the SQL/Python pipeline against
the value shown in the Excel workbook (excel/Revenue_Leakage_Recovery_2025.xlsx).

    python 03_validate.py

Writes validation_results.md and exits with an error if any check fails.
"""
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent
P = ROOT / "outputs"

# Values as shown in the workbook (tabs 04, 06, 07, 08, 11)
EXPECTED = {
    "Annual reporting hours before": 1551.5,
    "Annual reporting hours after": 613.0,
    "Reporting time reduction": 0.6049,
    "Value of hours released (EUR)": 51618,
    "Leakage identified (EUR)": 125485,
    "Revenue recovered (EUR)": 120625,
    "Still in progress (EUR)": 2523,
    "Written off (EUR)": 2337,
    "Recovery rate": 0.9613,
    "Accounts leaking": 123,
    "Leakage vs invoiced": 0.0218,
    "Unbilled device overage (EUR)": 39570,
    "Recovered by month, July cumulative (EUR)": 120625,
    "Churn model AUC (hold-out)": 0.815136,
    "Test customers": 603,
    "Churners caught in top 20%": 0.5319,
    "Top-decile churn rate": 0.5574,
    "Retention scenario (EUR / year)": 177000,
    "Month-end pack, days after automation": 2.33,
}


def actual():
    s1 = pd.read_csv(P / "ws1_summary.csv").iloc[0]
    h = pd.read_csv(P / "ws2_headline.csv").iloc[0]
    t = pd.read_csv(P / "ws2_by_type.csv").set_index("leakage_type")
    m = pd.read_csv(P / "ws2_recovery_by_month.csv")
    e = pd.read_csv(P / "ws3_evaluation.csv").iloc[0]
    d = pd.read_csv(P / "ws3_deciles.csv").set_index("risk_decile")
    r = pd.read_csv(P / "ws3_retention_scenario.csv").iloc[0]
    k = pd.read_csv(P / "kpi_before_after.csv").iloc[1]
    return {
        "Annual reporting hours before": s1.annual_hours_before,
        "Annual reporting hours after": s1.annual_hours_after,
        "Reporting time reduction": s1.reduction,
        "Value of hours released (EUR)": s1.value_eur,
        "Leakage identified (EUR)": h.leakage_identified,
        "Revenue recovered (EUR)": h.recovered,
        "Still in progress (EUR)": h.in_progress,
        "Written off (EUR)": h.written_off,
        "Recovery rate": h.recovery_rate,
        "Accounts leaking": h.accounts_leaking,
        "Leakage vs invoiced": h.leakage_vs_invoiced,
        "Unbilled device overage (EUR)": t.loc["Unbilled device overage", "identified"],
        "Recovered by month, July cumulative (EUR)": m.cumulative.iloc[-1],
        "Churn model AUC (hold-out)": e.auc,
        "Test customers": e.n_test,
        "Churners caught in top 20%": e.churners_caught_top20,
        "Top-decile churn rate": d.loc[1, "churn_rate"],
        "Retention scenario (EUR / year)": r.revenue_retained_scenario,
        "Month-end pack, days after automation": k.avg_days_to_publish,
    }


def main():
    got = actual()
    rows, failed = [], 0
    for name, exp in EXPECTED.items():
        val = float(got[name])
        ok = abs(val - exp) <= max(1e-4, abs(exp) * 1e-6)
        failed += not ok
        rows.append(f"| {name} | {exp:,.6g} | {val:,.6g} | {'✅ PASS' if ok else '❌ FAIL'} |")
    md = ["# Validation results", "",
          "Pipeline output (SQL + Python) compared with the figures shown in the Excel workbook.", "",
          "| Check | Workbook | Pipeline | Result |", "|---|---|---|---|", *rows, "",
          f"**{len(EXPECTED) - failed} of {len(EXPECTED)} checks passed.**", ""]
    (ROOT / "validation_results.md").write_text("\n".join(md), encoding="utf-8")
    print("\n".join(rows))
    print(f"\n{len(EXPECTED) - failed} of {len(EXPECTED)} checks passed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
