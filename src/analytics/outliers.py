"""Robust outlier identification without deleting or rewriting observations."""

from __future__ import annotations

import numpy as np
import pandas as pd


def iqr_bounds(values: pd.Series, multiplier: float = 1.5) -> tuple[float, float]:
    numeric = pd.to_numeric(values, errors="coerce").dropna()
    q1, q3 = numeric.quantile([0.25, 0.75])
    spread = q3 - q1
    return float(q1 - multiplier * spread), float(q3 + multiplier * spread)


def robust_z_score(values: pd.Series) -> pd.Series:
    numeric = pd.to_numeric(values, errors="coerce")
    median = numeric.median()
    mad = (numeric - median).abs().median()
    if mad == 0 or np.isnan(mad):
        return pd.Series(np.nan, index=numeric.index)
    return 0.6745 * (numeric - median) / mad


def outlier_profile(values: pd.Series, multiplier: float = 1.5) -> pd.Series:
    numeric = pd.to_numeric(values, errors="coerce").dropna()
    lower, upper = iqr_bounds(numeric, multiplier)
    high = numeric > upper
    low = numeric < lower
    return pd.Series(
        {
            "iqr_lower_bound": lower,
            "iqr_upper_bound": upper,
            "low_outliers": int(low.sum()),
            "high_outliers": int(high.sum()),
            "outlier_share": float((low | high).mean()),
            "p99_threshold": float(numeric.quantile(0.99)),
            "above_p99": int((numeric > numeric.quantile(0.99)).sum()),
        }
    )
