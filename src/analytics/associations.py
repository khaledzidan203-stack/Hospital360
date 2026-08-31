"""Association diagnostics; association is not evidence of causation."""

from __future__ import annotations

import pandas as pd


def correlation_table(frame: pd.DataFrame, pairs: list[tuple[str, str]]) -> pd.DataFrame:
    rows = []
    for left, right in pairs:
        pair = frame[[left, right]].apply(pd.to_numeric, errors="coerce").dropna()
        rows.append(
            {
                "left": left,
                "right": right,
                "n": len(pair),
                "pearson": pair[left].corr(pair[right], method="pearson"),
                "spearman": pair[left].corr(pair[right], method="spearman"),
            }
        )
    return pd.DataFrame(rows)
