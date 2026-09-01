"""Monthly synthetic hospital finance generation, separate from Synthea claims."""

from __future__ import annotations

import numpy as np
import pandas as pd

from .activity_drivers import stable_rng


REVENUE_PER_ENCOUNTER = {
    "EMERGENCY": 920.0, "OUTPATIENT": 310.0, "INPATIENT": 1850.0, "SURGERY": 3350.0,
    "ICU": 4100.0, "RADIOLOGY": 380.0, "LABORATORY": 95.0, "PHARMACY": 165.0,
}


def generate_finance(
    start_date: str,
    months: int,
    operations: pd.DataFrame,
    workforce: pd.DataFrame,
    dimensions: dict[str, pd.DataFrame],
) -> pd.DataFrame:
    periods = pd.date_range(start_date, periods=months, freq="MS")
    departments = dimensions["departments"].set_index("department_key")
    categories = dimensions["cost_categories"]
    ops = operations.copy(); ops["month"] = pd.to_datetime(ops.date).dt.to_period("M").dt.to_timestamp()
    monthly_ops = ops.groupby(["month", "department_key"], as_index=False).agg(encounters=("encounter_count", "sum"), procedures=("procedure_count", "sum"))
    payroll = workforce.groupby(["month_start_date_key", "department_key"], as_index=False).payroll_cost.sum().set_index(["month_start_date_key", "department_key"])
    rows = []
    for month in periods:
        month_key = int(month.strftime("%Y%m%d"))
        inflation = (1.035) ** ((month.year - 2023) + (month.month - 8) / 12)
        for department_key, department in departments.iterrows():
            current = monthly_ops[(monthly_ops.month == month) & (monthly_ops.department_key == department_key)]
            encounters = int(current.encounters.iloc[0]) if not current.empty else 0
            procedures = int(current.procedures.iloc[0]) if not current.empty else 0
            payroll_cost = float(payroll.loc[(month_key, department_key), "payroll_cost"])
            for category in categories.itertuples(index=False):
                rng = stable_rng(month.date(), department_key, category.cost_category_key, domain="finance")
                revenue = 0.0; operating_cost = fixed = variable = allocated = 0.0
                payroll_amount = supplies = medication = facility = technology_other = 0.0
                if category.cost_category_code == "REVENUE":
                    rate = REVENUE_PER_ENCOUNTER.get(department.department_code, 0.0)
                    revenue = encounters * rate * inflation * (1 + rng.normal(0, 0.055)) + procedures * rate * 0.08
                    revenue = max(0.0, revenue)
                elif category.cost_category_code == "PAYROLL":
                    payroll_amount = payroll_cost
                    operating_cost = payroll_amount; fixed = payroll_amount * 0.82; variable = payroll_amount * 0.18
                elif category.cost_category_code == "SUPPLIES":
                    supplies = (encounters * 19 + procedures * 42 + 9000) * inflation * (1 + rng.normal(0, 0.07))
                    operating_cost = max(0.0, supplies); fixed = min(operating_cost, 9000 * inflation); variable = operating_cost - fixed
                elif category.cost_category_code == "MEDICATION":
                    medication = (encounters * (28 if department.clinical_flag else 0) + 4500) * inflation * (1 + rng.normal(0, 0.08))
                    operating_cost = max(0.0, medication); fixed = min(operating_cost, 4500 * inflation); variable = operating_cost - fixed
                elif category.cost_category_code == "FACILITY":
                    facility = (38000 + 4500 * int(department.capacity_managed_flag)) * inflation * (1 + rng.normal(0, 0.035))
                    operating_cost = max(0.0, facility); fixed = operating_cost * 0.94; variable = operating_cost * 0.06
                elif category.cost_category_code == "TECH_OTHER":
                    technology_other = (24000 + encounters * 3.5) * inflation * (1 + rng.normal(0, 0.06))
                    operating_cost = max(0.0, technology_other); fixed = operating_cost * 0.72; variable = operating_cost * 0.18; allocated = operating_cost * 0.10
                rows.append(
                    {
                        "month_start_date": month.date().isoformat(), "month_start_date_key": month_key,
                        "organization_key": int(department.organization_key), "department_key": int(department_key),
                        "cost_category_key": int(category.cost_category_key),
                        "operating_revenue": round(revenue, 2), "operating_cost": round(operating_cost, 2),
                        "fixed_cost_amount": round(fixed, 2), "variable_cost_amount": round(variable, 2),
                        "allocated_shared_cost_amount": round(allocated, 2), "payroll_cost": round(payroll_amount, 2),
                        "supplies_cost": round(supplies, 2), "medication_cost": round(medication, 2),
                        "facility_cost": round(facility, 2), "technology_other_cost": round(technology_other, 2),
                        "driver_encounter_count": encounters, "driver_procedure_count": procedures,
                    }
                )
    return pd.DataFrame(rows)
