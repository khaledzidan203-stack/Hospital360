"""Distribution and concentration calculations used by the EDA notebook."""

from __future__ import annotations

import numpy as np
import pandas as pd


def robust_summary(values: pd.Series) -> pd.Series:
    numeric = pd.to_numeric(values, errors="coerce").dropna()
    quantiles = numeric.quantile([0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99])
    return pd.Series(
        {
            "count": int(numeric.size),
            "mean": numeric.mean(),
            "std": numeric.std(),
            "min": numeric.min(),
            "p01": quantiles.loc[0.01],
            "p05": quantiles.loc[0.05],
            "p25": quantiles.loc[0.25],
            "median": quantiles.loc[0.5],
            "p75": quantiles.loc[0.75],
            "p95": quantiles.loc[0.95],
            "p99": quantiles.loc[0.99],
            "max": numeric.max(),
            "iqr": quantiles.loc[0.75] - quantiles.loc[0.25],
            "skewness": numeric.skew(),
        }
    )


def concentration_shares(values: pd.Series, top_n: tuple[int, ...] = (1, 10, 100)) -> pd.Series:
    numeric = pd.to_numeric(values, errors="coerce").fillna(0).clip(lower=0).sort_values(ascending=False)
    total = numeric.sum()
    return pd.Series({f"top_{n}_share": numeric.head(n).sum() / total if total else np.nan for n in top_n})


def lorenz_curve(values: pd.Series) -> pd.DataFrame:
    numeric = np.sort(pd.to_numeric(values, errors="coerce").fillna(0).clip(lower=0).to_numpy())
    cumulative = np.insert(np.cumsum(numeric), 0, 0.0)
    if cumulative[-1] > 0:
        cumulative /= cumulative[-1]
    population = np.linspace(0, 1, cumulative.size)
    return pd.DataFrame({"population_share": population, "value_share": cumulative})
