"""Monthly role-level workforce generation with lagged activity response."""

from __future__ import annotations

import math

import numpy as np
import pandas as pd

from .activity_drivers import stable_rng
from .departments import valid_department_roles


BASE_FTE = {
    "PHYSICIAN": 7.0,
    "NURSING": 13.0,
    "ALLIED": 6.0,
    "ADMIN_ROLE": 4.0,
    "OPS_SUPPORT": 5.0,
    "TECHNOLOGY": 4.0,
    "MANAGEMENT": 2.0,
}
HOURLY_RATE = {
    "PHYSICIAN": 115.0,
    "NURSING": 48.0,
    "ALLIED": 39.0,
    "ADMIN_ROLE": 27.0,
    "OPS_SUPPORT": 24.0,
    "TECHNOLOGY": 52.0,
    "MANAGEMENT": 68.0,
}


def generate_workforce(
    start_date: str,
    months: int,
    operations: pd.DataFrame,
    departments: pd.DataFrame,
    dimensions: dict[str, pd.DataFrame],
) -> pd.DataFrame:
    periods = pd.date_range(start_date, periods=months, freq="MS")
    ops = operations.copy()
    ops["month"] = pd.to_datetime(ops.date).dt.to_period("M").dt.to_timestamp()
    activity = ops.groupby(["month", "organization_key", "department_key"], as_index=False).agg(encounters=("encounter_count", "sum"), procedures=("procedure_count", "sum"))
    org_activity = activity.groupby(["month", "organization_key"], as_index=False).agg(encounters=("encounters", "sum"), procedures=("procedures", "sum"))
    catalog = valid_department_roles(dimensions)
    roles = dimensions["employee_roles"].set_index("employee_role_key")
    department_meta = departments.set_index("department_key")
    state: dict[tuple[int, int], tuple[float, int]] = {}
    rows = []
    for month in periods:
        for combo in catalog.itertuples(index=False):
            department = department_meta.loc[combo.department_key]
            role = roles.loc[combo.employee_role_key]
            current = activity[(activity.month == month) & (activity.department_key == combo.department_key)]
            if current.empty:
                shared = org_activity[(org_activity.month == month) & (org_activity.organization_key == department.organization_key)]
                encounters = float(shared.encounters.iloc[0] * 0.10) if not shared.empty else 0.0
            else:
                encounters = float(current.encounters.iloc[0])
            department_factor = 1.35 if department.department_code in {"EMERGENCY", "INPATIENT", "ICU", "SURGERY"} else 1.0
            activity_factor = 0.82 + min(encounters / 1800.0, 1.5) * 0.24
            target = BASE_FTE[role.employee_role_code] * department_factor * activity_factor
            rng = stable_rng(month.date(), combo.department_key, combo.employee_role_key, domain="workforce")
            previous_fte, previous_headcount = state.get((combo.department_key, combo.employee_role_key), (target, math.ceil(target / 0.86)))
            desired = target * (1 + rng.normal(0, 0.035))
            fte = float(np.clip(previous_fte + np.clip(desired - previous_fte, -previous_fte * 0.05, previous_fte * 0.05), 0.5, 90.0))
            headcount = max(math.ceil(fte), int(round(fte / np.clip(0.82 + rng.normal(0, 0.035), 0.72, 0.98))))
            hires = max(0, headcount - previous_headcount) + int(rng.binomial(max(headcount, 1), 0.006))
            separations = max(0, previous_headcount + hires - headcount)
            scheduled = fte * float(role.standard_hours_per_fte_month)
            gap_pressure = max(0.0, desired - fte) / max(fte, 1.0)
            overtime_rate = float(np.clip(0.025 + 0.10 * gap_pressure + rng.normal(0, 0.012), 0.0, 0.20))
            absence_rate = float(np.clip(0.035 + rng.normal(0, 0.012), 0.005, 0.12))
            overtime = scheduled * overtime_rate
            absence = scheduled * absence_rate
            worked = scheduled - absence + overtime
            payroll = worked * HOURLY_RATE[role.employee_role_code] * (1 + 0.012 * ((month.year - 2023) + (month.month - 8) / 12)) + overtime * HOURLY_RATE[role.employee_role_code] * 0.5
            vacancies = max(0, int(round(max(desired - fte, 0) / 0.9)))
            rows.append(
                {
                    "month_start_date": month.date().isoformat(),
                    "month_start_date_key": int(month.strftime("%Y%m%d")),
                    "organization_key": int(department.organization_key),
                    "department_key": combo.department_key,
                    "employee_role_key": combo.employee_role_key,
                    "headcount_start": previous_headcount,
                    "headcount": headcount,
                    "headcount_end": headcount,
                    "average_headcount": round((previous_headcount + headcount) / 2, 2),
                    "fte_start": round(previous_fte, 2),
                    "fte": round(fte, 2),
                    "fte_end": round(fte, 2),
                    "average_fte": round((previous_fte + fte) / 2, 2),
                    "new_hires": hires,
                    "turnover_count": separations,
                    "vacancy_count": vacancies,
                    "scheduled_hours": round(scheduled, 2),
                    "worked_hours": round(worked, 2),
                    "overtime_hours": round(overtime, 2),
                    "absence_hours": round(absence, 2),
                    "payroll_cost": round(payroll, 2),
                }
            )
            state[(combo.department_key, combo.employee_role_key)] = (fte, headcount)
    return pd.DataFrame(rows)
