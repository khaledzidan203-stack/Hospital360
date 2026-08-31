"""Validated baselines and compact profiling helpers."""

from __future__ import annotations

from dataclasses import dataclass
from math import isclose

import pandas as pd

from .db import query_dataframe


EXPECTED_FACT_COUNTS = {
    "fact_encounter": 253_563,
    "fact_claim": 435_751,
    "fact_claim_transaction": 3_966_064,
    "fact_condition_occurrence": 159_348,
    "fact_procedure": 696_202,
}

EXPECTED_FINANCIAL_TOTALS = {
    "encounter_base_cost": 28_981_362.04,
    "encounter_total_claim_cost": 731_937_228.14,
    "encounter_payer_coverage": 526_304_744.54,
    "transaction_amount": 837_678_683.76,
    "transaction_payments": 697_790_613.67,
    "transaction_transfers": 279_776_140.18,
    "procedure_base_cost": 716_784_016.74,
}


@dataclass(frozen=True)
class BaselineResult:
    counts: dict[str, int]
    financials: dict[str, float]
    passed: bool


def validate_baseline() -> BaselineResult:
    """Reconcile the Python connection to the committed 5K SQL milestone."""
    frame = query_dataframe(
        """
        SELECT
          (SELECT count(*) FROM analytics.fact_encounter) AS fact_encounter,
          (SELECT count(*) FROM analytics.fact_claim) AS fact_claim,
          (SELECT count(*) FROM analytics.fact_claim_transaction) AS fact_claim_transaction,
          (SELECT count(*) FROM analytics.fact_condition_occurrence) AS fact_condition_occurrence,
          (SELECT count(*) FROM analytics.fact_procedure) AS fact_procedure,
          (SELECT coalesce(sum(base_encounter_cost), 0) FROM analytics.fact_encounter) AS encounter_base_cost,
          (SELECT coalesce(sum(total_claim_cost), 0) FROM analytics.fact_encounter) AS encounter_total_claim_cost,
          (SELECT coalesce(sum(payer_coverage), 0) FROM analytics.fact_encounter) AS encounter_payer_coverage,
          (SELECT coalesce(sum(amount), 0) FROM analytics.fact_claim_transaction) AS transaction_amount,
          (SELECT coalesce(sum(payments), 0) FROM analytics.fact_claim_transaction) AS transaction_payments,
          (SELECT coalesce(sum(transfers), 0) FROM analytics.fact_claim_transaction) AS transaction_transfers,
          (SELECT coalesce(sum(base_cost), 0) FROM analytics.fact_procedure) AS procedure_base_cost
        """
    )
    row = frame.iloc[0]
    counts = {name: int(row[name]) for name in EXPECTED_FACT_COUNTS}
    financials = {name: float(row[name]) for name in EXPECTED_FINANCIAL_TOTALS}
    counts_pass = counts == EXPECTED_FACT_COUNTS
    financials_pass = all(
        isclose(financials[name], expected, rel_tol=0, abs_tol=0.005)
        for name, expected in EXPECTED_FINANCIAL_TOTALS.items()
    )
    result = BaselineResult(counts, financials, counts_pass and financials_pass)
    if not result.passed:
        raise RuntimeError(f"Validated 5K baseline mismatch: {result}")
    return result


def profile_table(frame: pd.DataFrame, value_column: str) -> pd.Series:
    """Return a consistent percentile profile for one numeric field."""
    values = pd.to_numeric(frame[value_column], errors="coerce").dropna()
    return values.describe(percentiles=[0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99])
