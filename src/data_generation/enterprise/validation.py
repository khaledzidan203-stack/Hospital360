"""Generation quality gates for all enterprise profiles."""

from __future__ import annotations

from dataclasses import asdict, dataclass

import numpy as np
import pandas as pd


@dataclass
class ValidationResult:
    status: str
    fact_rows: int
    errors: list[str]
    warnings: list[str]
    metrics: dict[str, float | int | str]

    def to_dict(self) -> dict[str, object]:
        return asdict(self)


def _duplicate_count(frame: pd.DataFrame, columns: list[str]) -> int:
    return int(frame.duplicated(columns, keep=False).sum())


def validate_generation(frames: dict[str, pd.DataFrame], profile_name: str) -> ValidationResult:
    errors: list[str] = []
    warnings: list[str] = []
    finance = frames["finance_monthly"]; budget = frames["budget_monthly"]; workforce = frames["workforce_monthly"]
    operations = frames["operations_daily"]; incidents = frames["it_incident"]; it_daily = frames["it_system_daily"]
    dimensions = frames["dimensions"]
    grain_checks = {
        "finance": (finance, ["month_start_date_key", "organization_key", "department_key", "cost_category_key"]),
        "budget": (budget, ["month_start_date_key", "organization_key", "department_key", "budget_scenario_key"]),
        "workforce": (workforce, ["month_start_date_key", "organization_key", "department_key", "employee_role_key"]),
        "operations": (operations, ["date_key", "organization_key", "department_key"]),
        "incidents": (incidents, ["incident_id"]),
        "it_daily": (it_daily, ["date_key", "organization_key", "it_system_key"]),
    }
    for name, (frame, columns) in grain_checks.items():
        duplicates = _duplicate_count(frame, columns)
        if duplicates:
            errors.append(f"{name}: duplicate grain rows={duplicates}")
    key_sets = {
        "organization_key": set(int(value) for value in dimensions["organizations"].organization_key),
        "department_key": set(int(value) for value in dimensions["departments"].department_key),
        "cost_category_key": set(int(value) for value in dimensions["cost_categories"].cost_category_key),
        "budget_scenario_key": set(int(value) for value in dimensions["budget_scenarios"].budget_scenario_key),
        "employee_role_key": set(int(value) for value in dimensions["employee_roles"].employee_role_key),
        "it_system_key": set(int(value) for value in dimensions["it_systems"].it_system_key),
        "incident_category_key": set(int(value) for value in dimensions["incident_categories"].incident_category_key),
    }
    for frame_name, frame in [(name, item[0]) for name, item in grain_checks.items()]:
        for column, valid in key_sets.items():
            if column in frame.columns:
                invalid = set(int(value) for value in frame[column].dropna().unique()) - valid
                if invalid:
                    errors.append(f"{frame_name}: invalid {column} values={sorted(invalid)}")
    if (finance[["operating_revenue", "operating_cost"]] < 0).any().any(): errors.append("finance: negative revenue/cost")
    finance_recon = (finance.fixed_cost_amount + finance.variable_cost_amount + finance.allocated_shared_cost_amount - finance.operating_cost).abs()
    if float(finance_recon.max()) > 0.03: errors.append("finance: cost components do not reconcile")
    if (budget[["budget_revenue", "budget_operating_cost", "budget_payroll_cost", "budget_fte"]] < 0).any().any(): errors.append("budget: negative values")
    if (workforce[["headcount", "fte", "overtime_hours", "absence_hours", "payroll_cost"]] < 0).any().any(): errors.append("workforce: negative values")
    if (workforce.fte > workforce.headcount + 0.01).any(): errors.append("workforce: FTE exceeds headcount")
    departments = dimensions["departments"].set_index("department_key")
    operations_check = operations.join(departments[["bed_applicable_flag"]], on="department_key")
    non_bed = operations_check[~operations_check.bed_applicable_flag]
    if non_bed[["available_beds", "occupied_beds", "admissions", "discharges", "average_length_of_stay"]].notna().any().any(): errors.append("operations: non-bed departments contain bed metrics")
    bed = operations_check[operations_check.bed_applicable_flag]
    if (bed.occupied_beds > bed.available_beds * 1.05).any(): errors.append("operations: occupied beds exceed controlled overflow limit")
    if ((operations.capacity_utilization.dropna() < 0) | (operations.capacity_utilization.dropna() > 1.05)).any(): errors.append("operations: invalid utilization")
    if not incidents.empty:
        opened = pd.to_datetime(incidents.opened_at, utc=True); resolved = pd.to_datetime(incidents.resolved_at, utc=True)
        if (resolved.dropna() < opened[resolved.notna()]).any(): errors.append("incidents: resolved before opened")
    if ((it_daily.uptime_pct < 0) | (it_daily.uptime_pct > 1)).any(): errors.append("it daily: uptime outside 0-1")
    if not (it_daily.availability_minutes + it_daily.downtime_minutes == it_daily.scheduled_minutes).all(): errors.append("it daily: availability arithmetic failure")
    monthly_ops = operations.assign(month=pd.to_datetime(operations.date).dt.to_period("M").dt.to_timestamp()).groupby(["month", "department_key"], as_index=False).agg(encounters=("encounter_count", "sum"), utilization=("capacity_utilization", "mean"))
    monthly_workforce = workforce.assign(month=pd.to_datetime(workforce.month_start_date)).groupby(["month", "department_key"], as_index=False).fte.sum()
    monthly_finance = finance.assign(month=pd.to_datetime(finance.month_start_date)).groupby(["month", "department_key"], as_index=False).agg(variable_cost=("variable_cost_amount", "sum"))
    coherence = monthly_ops.merge(monthly_workforce, on=["month", "department_key"]).merge(monthly_finance, on=["month", "department_key"])
    corr_fte = float(coherence.encounters.corr(coherence.fte)) if len(coherence) > 2 else 0.0
    corr_cost = float(coherence.encounters.corr(coherence.variable_cost)) if len(coherence) > 2 else 0.0
    if not np.isfinite(corr_fte) or corr_fte <= 0.10 or corr_fte >= 0.9999: errors.append(f"coherence: encounters/FTE correlation={corr_fte:.4f}")
    if not np.isfinite(corr_cost) or corr_cost <= 0.10 or corr_cost >= 0.9999: errors.append(f"coherence: encounters/variable cost correlation={corr_cost:.4f}")
    actual_budget = finance.groupby(["month_start_date_key", "department_key"], as_index=False).agg(actual=("operating_cost", "sum")).merge(
        budget[budget.budget_scenario_key == 1][["month_start_date_key", "department_key", "budget_operating_cost"]], on=["month_start_date_key", "department_key"]
    )
    variance_unique = int((actual_budget.actual - actual_budget.budget_operating_cost).round(2).nunique())
    if variance_unique < max(4, len(actual_budget) // 20): errors.append("budget: insufficient actual/budget variation")
    fact_rows = sum(len(frame) for frame in [finance, budget, workforce, operations, incidents, it_daily])
    if profile_name == "FINAL_36M" and not 25000 <= fact_rows <= 27000: errors.append(f"final fact rows outside 25K-27K: {fact_rows}")
    warning_count = int((workforce.overtime_hours / workforce.worked_hours.replace(0, np.nan) > 0.15).sum())
    warning_count += int((workforce.absence_hours / workforce.scheduled_hours.replace(0, np.nan) > 0.10).sum())
    warning_count += int((operations.capacity_utilization.fillna(0) > 0.95).sum())
    warning_count += int((incidents.resolution_minutes.fillna(0) > incidents.sla_target_minutes * 2).sum()) if not incidents.empty else 0
    return ValidationResult(
        status="PASS" if not errors else "FAIL", fact_rows=fact_rows, errors=errors, warnings=warnings,
        metrics={"warning_candidates": warning_count, "encounter_fte_correlation": round(corr_fte, 4), "encounter_variable_cost_correlation": round(corr_cost, 4), "budget_variance_unique_values": variance_unique},
    )
