"""Daily IT availability and usage generation."""

from __future__ import annotations

import numpy as np
import pandas as pd

from .activity_drivers import stable_rng


def coverage_pairs(dimensions: dict[str, pd.DataFrame]) -> list[tuple[int, int]]:
    departments = dimensions["departments"]
    systems = dimensions["it_systems"].set_index("it_system_code")
    organizations = sorted(int(value) for value in departments.organization_key.unique())
    pair_codes = [(org, "EHR") for org in organizations]
    for code, department_code in [("PACS", "RADIOLOGY"), ("LIS", "LABORATORY"), ("PHARM", "PHARMACY"), ("ERP", "FINANCE"), ("DATA", "IT")]:
        department = departments[departments.department_code == department_code].iloc[0]
        pair_codes.append((int(department.organization_key), code))
    return [(org, int(systems.loc[code, "it_system_key"])) for org, code in pair_codes]


def generate_it_system_daily(
    start_date: str,
    end_date: str,
    activity: pd.DataFrame,
    dimensions: dict[str, pd.DataFrame],
) -> pd.DataFrame:
    dates = pd.date_range(start_date, end_date, freq="D")
    systems = dimensions["it_systems"].set_index("it_system_key")
    activity_lookup = activity.set_index(["full_date", "organization_key"])
    rows = []
    for organization_key, system_key in coverage_pairs(dimensions):
        system = systems.loc[system_key]
        for date in dates:
            key = (date, organization_key)
            if key in activity_lookup.index:
                current = activity_lookup.loc[key]
                encounters, procedures = int(current.encounters), int(current.procedures)
            else:
                encounters = procedures = 0
            rng = stable_rng(date.date(), organization_key, system_key, domain="it_daily")
            scheduled = 1440 if system.criticality_tier == "Tier 1" else 1200
            planned = 30 if date.day == 15 and system_key in {5, 6} else 0
            unplanned = int(max(0, round(rng.gamma(0.32, 3.2) - 1.1)))
            if date == pd.Timestamp("2025-02-12") and system.it_system_code == "EHR":
                unplanned += 185
            downtime = min(scheduled, planned + unplanned)
            available = scheduled - downtime
            usage_factor = {"EHR": 14, "PACS": 5, "LIS": 11, "PHARM": 8, "ERP": 2, "DATA": 3}[system.it_system_code]
            transaction_count = max(0, int(round((encounters + procedures * 0.7 + 25) * usage_factor * (1 + rng.normal(0, 0.09)))))
            active_users = max(1, int(round((encounters * 0.08 + procedures * 0.025 + 12) * (1 + rng.normal(0, 0.08)))))
            peak_users = max(1, int(round(active_users * np.clip(0.28 + rng.normal(0, 0.035), 0.16, 0.42))))
            response = float(np.clip(180 + 0.012 * transaction_count + downtime * 0.8 + rng.normal(0, 28), 80, 1600))
            errors = int(rng.poisson(max(0.2, transaction_count * 0.0007 + unplanned * 0.08)))
            rows.append(
                {
                    "date": date.date().isoformat(), "date_key": int(date.strftime("%Y%m%d")),
                    "organization_key": organization_key, "it_system_key": system_key,
                    "scheduled_minutes": scheduled, "availability_minutes": available,
                    "available_minutes": available, "downtime_minutes": downtime,
                    "planned_downtime_minutes": planned, "unplanned_downtime_minutes": unplanned,
                    "uptime_pct": round(available / scheduled, 8), "transaction_count": transaction_count,
                    "active_users": active_users, "peak_concurrent_users": peak_users,
                    "response_time_ms": round(response, 2), "error_count": errors, "incident_count": 0,
                }
            )
    return pd.DataFrame(rows)
