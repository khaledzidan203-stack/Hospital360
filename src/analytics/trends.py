"""Time-series transformations for monthly analytical extracts."""

from __future__ import annotations

import pandas as pd


def add_monthly_diagnostics(frame: pd.DataFrame, value_columns: list[str]) -> pd.DataFrame:
    result = frame.copy()
    result["month"] = pd.to_datetime(result["month"])
    result = result.sort_values("month").reset_index(drop=True)
    for column in value_columns:
        result[f"{column}_rolling_3m"] = result[column].rolling(3, min_periods=3).mean()
        result[f"{column}_mom_pct"] = result[column].pct_change(fill_method=None) * 100
    return result


def volatility_summary(frame: pd.DataFrame, value_columns: list[str]) -> pd.DataFrame:
    rows = []
    for column in value_columns:
        mean = frame[column].mean()
        std = frame[column].std()
        rows.append(
            {
                "metric": column,
                "mean": mean,
                "std": std,
                "coefficient_of_variation": std / mean if mean else float("nan"),
            }
        )
    return pd.DataFrame(rows)
