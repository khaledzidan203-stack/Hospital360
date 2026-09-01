"""Read-only extraction and deterministic allocation of healthcare activity."""

from __future__ import annotations

import hashlib

import numpy as np
import pandas as pd

from src.analytics.db import query_dataframe

from .config import DOMAIN_SEEDS


def stable_rng(*parts: object, domain: str) -> np.random.Generator:
    payload = "|".join([str(DOMAIN_SEEDS[domain]), *(str(part) for part in parts)])
    seed = int.from_bytes(hashlib.sha256(payload.encode("utf-8")).digest()[:8], "big")
    return np.random.default_rng(seed)


def load_activity(start_date: str, end_date: str) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Return top-three organizations and independent daily activity aggregates."""
    organizations = query_dataframe(
        f"""
        SELECT o.organization_key, o.organization_id, COUNT(*) AS encounter_count
        FROM analytics.fact_encounter e
        JOIN analytics.dim_organization o ON o.organization_key = e.organization_key
        JOIN analytics.dim_date d ON d.date_key = e.start_date_key
        WHERE e.organization_key <> 0
          AND d.full_date BETWEEN DATE '{start_date}' AND DATE '{end_date}'
        GROUP BY o.organization_key, o.organization_id
        ORDER BY encounter_count DESC, o.organization_key
        LIMIT 3
        """
    )
    keys = ",".join(str(int(value)) for value in organizations.organization_key)
    activity = query_dataframe(
        f"""
        WITH encounters AS (
            SELECT d.full_date, e.organization_key, COUNT(*) AS encounters
            FROM analytics.fact_encounter e
            JOIN analytics.dim_date d ON d.date_key=e.start_date_key
            WHERE e.organization_key IN ({keys})
              AND d.full_date BETWEEN DATE '{start_date}' AND DATE '{end_date}'
            GROUP BY d.full_date, e.organization_key
        ), procedures AS (
            SELECT d.full_date, p.encounter_organization_key AS organization_key,
                   COUNT(*) AS procedures
            FROM analytics.fact_procedure p
            JOIN analytics.dim_date d ON d.date_key=p.start_date_key
            WHERE p.encounter_organization_key IN ({keys})
              AND d.full_date BETWEEN DATE '{start_date}' AND DATE '{end_date}'
            GROUP BY d.full_date, p.encounter_organization_key
        )
        SELECT COALESCE(e.full_date,p.full_date) AS full_date,
               COALESCE(e.organization_key,p.organization_key) AS organization_key,
               COALESCE(e.encounters,0) AS encounters,
               COALESCE(p.procedures,0) AS procedures
        FROM encounters e
        FULL JOIN procedures p USING (full_date,organization_key)
        ORDER BY full_date, organization_key
        """
    )
    activity["full_date"] = pd.to_datetime(activity["full_date"])
    return organizations, activity


ALLOCATION_WEIGHTS = {
    "EMERGENCY": (0.36, 0.16),
    "OUTPATIENT": (0.42, 0.22),
    "INPATIENT": (0.24, 0.20),
    "SURGERY": (0.12, 0.30),
    "ICU": (0.08, 0.08),
    "RADIOLOGY": (0.12, 0.32),
    "LABORATORY": (0.18, 0.38),
    "PHARMACY": (0.22, 0.18),
}


def allocate_activity(
    start_date: str,
    end_date: str,
    organizations: pd.DataFrame,
    activity: pd.DataFrame,
    departments: pd.DataFrame,
) -> pd.DataFrame:
    """Allocate organization activity to its clinical departments reproducibly."""
    dates = pd.date_range(start_date, end_date, freq="D")
    lookup = activity.set_index(["full_date", "organization_key"])
    rows = []
    for org in organizations.itertuples(index=False):
        org_departments = departments[(departments.organization_key == int(org.organization_key)) & departments.clinical_flag]
        for date in dates:
            key = (date, int(org.organization_key))
            if key in lookup.index:
                source = lookup.loc[key]
                encounters = int(source.encounters)
                procedures = int(source.procedures)
            else:
                encounters = 0
                procedures = 0
            encounter_weights = np.array([ALLOCATION_WEIGHTS[row.department_code][0] for row in org_departments.itertuples(index=False)], dtype=float)
            procedure_weights = np.array([ALLOCATION_WEIGHTS[row.department_code][1] for row in org_departments.itertuples(index=False)], dtype=float)
            encounter_weights /= encounter_weights.sum()
            procedure_weights /= procedure_weights.sum()
            rng = stable_rng(date.date(), org.organization_key, domain="allocation")
            encounter_alloc = rng.multinomial(encounters, encounter_weights) if encounters else np.zeros(len(org_departments), dtype=int)
            procedure_alloc = rng.multinomial(procedures, procedure_weights) if procedures else np.zeros(len(org_departments), dtype=int)
            for department, allocated_encounters, allocated_procedures in zip(org_departments.itertuples(index=False), encounter_alloc, procedure_alloc):
                rows.append(
                    {
                        "full_date": date,
                        "date_key": int(date.strftime("%Y%m%d")),
                        "organization_key": int(org.organization_key),
                        "department_key": int(department.department_key),
                        "encounters": int(allocated_encounters),
                        "procedures": int(allocated_procedures),
                    }
                )
    return pd.DataFrame(rows)
