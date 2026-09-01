"""Event-level IT incident generation aligned with daily system exposure."""

from __future__ import annotations

from datetime import timedelta

import numpy as np
import pandas as pd

from .activity_drivers import stable_rng


def _department_for_system(organization_key: int, system_code: str, departments: pd.DataFrame) -> int:
    org_departments = departments[departments.organization_key == organization_key]
    preferred = {"PACS": "RADIOLOGY", "LIS": "LABORATORY", "PHARM": "PHARMACY", "ERP": "FINANCE", "DATA": "IT"}.get(system_code)
    if preferred and not org_departments[org_departments.department_code == preferred].empty:
        return int(org_departments[org_departments.department_code == preferred].iloc[0].department_key)
    clinical = org_departments[org_departments.clinical_flag]
    return int((clinical if not clinical.empty else org_departments).iloc[0].department_key)


def generate_it_incidents(it_daily: pd.DataFrame, dimensions: dict[str, pd.DataFrame]) -> tuple[pd.DataFrame, pd.DataFrame]:
    systems = dimensions["it_systems"].set_index("it_system_key")
    categories = dimensions["incident_categories"]
    departments = dimensions["departments"]
    rows = []
    serial = 1
    for daily in it_daily.itertuples(index=False):
        system = systems.loc[daily.it_system_key]
        rng = stable_rng(daily.date, daily.organization_key, daily.it_system_key, domain="it_incident")
        rate = 0.23 + min(daily.transaction_count / 250000, 0.10) + min(daily.error_count / 100, 0.08) + (0.7 if daily.unplanned_downtime_minutes >= 120 else 0)
        count = int(rng.poisson(rate))
        for incident_number in range(count):
            incident_rng = stable_rng(daily.date, daily.organization_key, daily.it_system_key, incident_number, domain="it_incident")
            severity = incident_rng.choice(["P1", "P2", "P3", "P4"], p=[0.015, 0.105, 0.52, 0.36])
            category = categories.iloc[int(incident_rng.integers(0, len(categories)))]
            target = {"P1": 60, "P2": 240, "P3": 720, "P4": 1440}[severity]
            opened = pd.Timestamp(daily.date) + pd.Timedelta(minutes=int(incident_rng.integers(0, 1440)))
            multiplier = {"P1": 0.75, "P2": 0.85, "P3": 0.95, "P4": 1.05}[severity]
            resolution = max(5, int(round(target * incident_rng.lognormal(np.log(multiplier), 0.48))))
            is_final_open = daily.date >= it_daily.date.max() and incident_number == 0 and severity in {"P3", "P4"}
            resolved = None if is_final_open else opened + pd.Timedelta(minutes=resolution)
            downtime = 0
            if severity in {"P1", "P2"}:
                downtime = min(resolution, max(0, int(daily.unplanned_downtime_minutes + incident_rng.normal(8, 12))))
            rows.append(
                {
                    "incident_id": f"ENT-INC-{serial:07d}",
                    "opened_date_key": int(opened.strftime("%Y%m%d")),
                    "resolved_date_key": int(resolved.strftime("%Y%m%d")) if resolved is not None else 0,
                    "organization_key": int(daily.organization_key),
                    "department_key": _department_for_system(int(daily.organization_key), system.it_system_code, departments),
                    "it_system_key": int(daily.it_system_key),
                    "incident_category_key": int(category.incident_category_key),
                    "opened_at": opened.isoformat(), "resolved_at": resolved.isoformat() if resolved is not None else None,
                    "severity": severity, "status": "Open" if resolved is None else "Resolved",
                    "channel": incident_rng.choice(["Portal", "Phone", "Monitoring", "Email"], p=[0.38, 0.18, 0.32, 0.12]),
                    "sla_class": severity, "sla_target_minutes": target,
                    "resolution_minutes": None if resolved is None else resolution,
                    "sla_met_flag": None if resolved is None else bool(resolution <= target),
                    "downtime_minutes": downtime, "affected_users": max(1, int(round(daily.active_users * incident_rng.uniform(0.03, 0.70)))),
                    "business_impact_score": round({"P1": 95, "P2": 70, "P3": 38, "P4": 15}[severity] * incident_rng.uniform(0.8, 1.2), 2),
                }
            )
            serial += 1
    incidents = pd.DataFrame(rows)
    if not incidents.empty:
        counts = incidents.assign(date=pd.to_datetime(incidents.opened_at).dt.date.astype(str)).groupby(["date", "organization_key", "it_system_key"]).size().rename("actual_incidents")
        daily_index = it_daily.set_index(["date", "organization_key", "it_system_key"])
        daily_index["incident_count"] = counts.reindex(daily_index.index, fill_value=0).astype(int)
        it_daily = daily_index.reset_index()
    return incidents, it_daily
