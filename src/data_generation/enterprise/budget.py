"""Scenario-based monthly budget generation with imperfect forecast behavior."""

from __future__ import annotations

import numpy as np
import pandas as pd

from .activity_drivers import stable_rng


def generate_budget(finance: pd.DataFrame, workforce: pd.DataFrame, dimensions: dict[str, pd.DataFrame]) -> pd.DataFrame:
    actual = finance.groupby(["month_start_date", "month_start_date_key", "organization_key", "department_key"], as_index=False).agg(
        actual_revenue=("operating_revenue", "sum"), actual_cost=("operating_cost", "sum"), actual_payroll=("payroll_cost", "sum")
    )
    actual["month"] = pd.to_datetime(actual.month_start_date)
    fte = workforce.groupby(["month_start_date_key", "department_key"], as_index=False).average_fte.sum().set_index(["month_start_date_key", "department_key"])
    scenario_map = dimensions["budget_scenarios"].set_index("budget_scenario_code")
    rows = []
    for department_key, group in actual.groupby("department_key", sort=True):
        group = group.sort_values("month").reset_index(drop=True)
        for index, current in group.iterrows():
            history = group.iloc[max(0, index - 6):index]
            revenue_base = float(history.actual_revenue.mean()) if not history.empty else float(current.actual_revenue * 0.96 + 15000)
            cost_base = float(history.actual_cost.mean()) if not history.empty else float(current.actual_cost * 1.03 + 8000)
            payroll_base = float(history.actual_payroll.mean()) if not history.empty else float(current.actual_payroll)
            budget_fte = float(fte.loc[(current.month_start_date_key, department_key), "average_fte"])
            for code, scenario in scenario_map.iterrows():
                rng = stable_rng(current.month.date(), department_key, code, domain="budget")
                if code == "ORIGINAL":
                    revenue_factor, cost_factor = 1.02 + rng.normal(0, 0.035), 1.025 + rng.normal(0, 0.03)
                elif code == "FORECAST":
                    revenue_base = 0.55 * revenue_base + 0.45 * current.actual_revenue
                    cost_base = 0.55 * cost_base + 0.45 * current.actual_cost
                    payroll_base = 0.60 * payroll_base + 0.40 * current.actual_payroll
                    revenue_factor, cost_factor = 1 + rng.normal(0, 0.025), 1 + rng.normal(0, 0.022)
                else:
                    revenue_factor, cost_factor = 1.04 + rng.normal(0, 0.025), 0.96 + rng.normal(0, 0.018)
                rows.append(
                    {
                        "month_start_date": current.month_start_date,
                        "month_start_date_key": int(current.month_start_date_key),
                        "organization_key": int(current.organization_key),
                        "department_key": int(department_key),
                        "budget_scenario_key": int(scenario.budget_scenario_key),
                        "budget_revenue": round(max(0.0, revenue_base * revenue_factor), 2),
                        "budget_operating_cost": round(max(0.0, cost_base * cost_factor), 2),
                        "budget_payroll_cost": round(max(0.0, payroll_base * cost_factor), 2),
                        "budget_capital_amount": round(max(0.0, (15000 if current.month.month in {1, 7} else 3000) * (1 + rng.normal(0, 0.25))), 2),
                        "budget_fte": round(max(0.0, budget_fte * (1 + rng.normal(0, 0.025))), 2),
                        "assumption_version": "ENTERPRISE_V1",
                    }
                )
    return pd.DataFrame(rows)
