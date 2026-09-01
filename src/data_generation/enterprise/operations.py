"""Daily synthetic operations and capacity generation."""

from __future__ import annotations

import numpy as np
import pandas as pd

from .activity_drivers import stable_rng


BED_CAPACITY = {"EMERGENCY": 28, "INPATIENT": 72, "SURGERY": 24, "ICU": 18}
BASE_WAIT = {"EMERGENCY": 48, "OUTPATIENT": 24, "INPATIENT": 18, "SURGERY": 30, "ICU": 12, "RADIOLOGY": 35, "LABORATORY": 22, "PHARMACY": 16}


def generate_operations(allocated: pd.DataFrame, departments: pd.DataFrame) -> pd.DataFrame:
    metadata = departments.set_index("department_key")
    medians = allocated.groupby("department_key").encounters.median().clip(lower=1)
    rows = []
    for source in allocated.itertuples(index=False):
        department = metadata.loc[source.department_key]
        code = department.department_code
        rng = stable_rng(source.full_date.date(), source.department_key, domain="operations")
        baseline = float(medians.loc[source.department_key])
        pressure = float(np.clip(0.55 + 0.35 * source.encounters / max(baseline * 1.4, 1) + rng.normal(0, 0.045), 0.25, 1.05))
        bed_applicable = bool(department.bed_applicable_flag)
        if bed_applicable:
            licensed = BED_CAPACITY[code]
            staffed = max(1, int(round(licensed * np.clip(0.86 + rng.normal(0, 0.035), 0.72, 1.0))))
            overflow = bool(pressure > 1.0)
            occupied = min(int(np.floor(staffed * 1.05)), int(round(staffed * pressure)))
            admissions = int(rng.binomial(max(source.encounters, 0), {"EMERGENCY": 0.14, "INPATIENT": 0.44, "SURGERY": 0.35, "ICU": 0.20}[code]))
            discharges = max(0, int(round(admissions + rng.normal(0, max(1.0, admissions * 0.14)))))
            average_los = float(np.clip({"EMERGENCY": 0.7, "INPATIENT": 4.3, "SURGERY": 2.7, "ICU": 5.2}[code] * rng.lognormal(0, 0.08), 0.2, 12.0))
            los_count = discharges
            los_total = average_los * los_count
            slots = None
            completed = None
            available_bed_days = float(staffed)
            occupied_bed_days = float(occupied)
            utilization = occupied / staffed if staffed else None
            throughput = discharges
        else:
            licensed = staffed = occupied = admissions = discharges = None
            overflow = False
            average_los = None
            los_count = 0
            los_total = 0.0
            slots = max(source.encounters, int(round(baseline * (1.15 + rng.normal(0, 0.08)))))
            completion_rate = float(np.clip(0.82 + rng.normal(0, 0.055), 0.60, 0.98))
            completed = min(slots, int(round(slots * completion_rate)))
            available_bed_days = occupied_bed_days = None
            utilization = completed / slots if slots else None
            throughput = completed
        waited = int(source.encounters)
        nonlinear = max(0.0, pressure - 0.85) ** 2 * 520
        average_wait = float(np.clip(BASE_WAIT[code] * (0.80 + 0.45 * pressure) + nonlinear + rng.normal(0, 5.0), 2.0, 240.0))
        rows.append(
            {
                "date": source.full_date.date().isoformat(),
                "date_key": source.date_key,
                "organization_key": source.organization_key,
                "department_key": source.department_key,
                "licensed_beds": licensed,
                "available_beds": staffed,
                "occupied_beds": occupied,
                "available_bed_days": available_bed_days,
                "occupied_bed_days": occupied_bed_days,
                "admissions": admissions,
                "discharges": discharges,
                "encounter_count": int(source.encounters),
                "procedure_count": int(source.procedures),
                "appointments_scheduled": slots,
                "appointments_completed": completed,
                "wait_minutes_total": round(average_wait * waited, 2),
                "waited_encounter_count": waited,
                "average_waiting_time_minutes": round(average_wait, 2),
                "length_of_stay_days_total": round(los_total, 2),
                "discharged_with_los_count": los_count,
                "average_length_of_stay": round(average_los, 2) if average_los is not None else None,
                "capacity_utilization": round(utilization, 6) if utilization is not None else None,
                "throughput": throughput,
                "overflow_capacity_flag": overflow,
            }
        )
    return pd.DataFrame(rows)
