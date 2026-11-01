"""
01_train_churn_model.py
-----------------------
Fits the churn model (logistic regression, Newton-Raphson / IRLS) on the 70%
Train set and saves the coefficients that the SQL layer uses to score customers.

    python 01_train_churn_model.py

Output: outputs/model_coefficients.csv
Only numpy and pandas are used, so every step of the fit is visible.
"""
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "customers.csv"
OUT = ROOT / "outputs"

FEATURES = ["Tenure_Months", "Support_Tickets_90d", "RMS_Login_Change_Pct",
            "Late_Payments_12m", "Annual_Contract"]
READING = {
    "Intercept": "Baseline log-odds",
    "Tenure_Months": "Longer customers are less likely to churn",
    "Support_Tickets_90d": "More support tickets -> higher risk",
    "RMS_Login_Change_Pct": "Falling RMS usage -> much higher risk",
    "Late_Payments_12m": "Payment problems -> higher risk",
    "Annual_Contract": "Annual contracts churn less",
}


def fit_logistic(X, y, tol=1e-12, max_iter=50):
    """Maximum-likelihood logistic regression by Newton-Raphson."""
    beta = np.zeros(X.shape[1])
    for _ in range(max_iter):
        p = 1 / (1 + np.exp(-X @ beta))
        W = p * (1 - p)
        H = X.T @ (X * W[:, None])          # Hessian of the log-likelihood (negated)
        step = np.linalg.solve(H, X.T @ (y - p))
        beta += step
        if np.max(np.abs(step)) < tol:
            break
    p = 1 / (1 + np.exp(-X @ beta))
    cov = np.linalg.inv(X.T @ (X * (p * (1 - p))[:, None]))
    return beta, np.sqrt(np.diag(cov))


def auc_rank(p, y):
    """AUC = probability that a churner scores above a non-churner (rank method)."""
    order = pd.Series(p).rank(method="max").to_numpy()   # same tie rule as the workbook
    n1, n0 = y.sum(), len(y) - y.sum()
    return (order[y == 1].sum() - n1 * (n1 + 1) / 2) / (n1 * n0)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    df = pd.read_csv(RAW)
    train, test = df[df.Set == "Train"], df[df.Set == "Test"]

    X = np.column_stack([np.ones(len(train)), train[FEATURES].to_numpy(float)])
    beta, se = fit_logistic(X, train.Churned.to_numpy(float))

    terms = ["Intercept"] + FEATURES
    coef = pd.DataFrame({"term": terms, "coefficient": beta, "std_error": se,
                         "z_value": beta / se, "reading": [READING[t] for t in terms]})
    coef.to_csv(OUT / "model_coefficients.csv", index=False)

    Xt = np.column_stack([np.ones(len(test)), test[FEATURES].to_numpy(float)])
    p_test = 1 / (1 + np.exp(-Xt @ beta))
    auc = auc_rank(p_test, test.Churned.to_numpy())

    print(coef.round(4).to_string(index=False))
    print(f"\nTrain {len(train)} · Test {len(test)} · hold-out AUC = {auc:.6f}")


if __name__ == "__main__":
    main()
