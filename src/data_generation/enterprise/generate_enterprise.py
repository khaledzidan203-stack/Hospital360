"""Generate and validate one Hospital360 enterprise profile."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import time

import pandas as pd

from .activity_drivers import allocate_activity, load_activity
from .budget import generate_budget
from .config import PROFILES, profile_dates
from .departments import build_dimensions
from .finance import generate_finance
from .it_incidents import generate_it_incidents
from .it_system_daily import generate_it_system_daily
from .operations import generate_operations
from .validation import validate_generation
from .workforce import generate_workforce


def _prepare_output(profile_name: str, output_root: Path) -> None:
    if profile_name != "FINAL_36M":
        if output_root.exists():
            shutil.rmtree(output_root)
        output_root.mkdir(parents=True)
        return
    targets = [output_root / name for name in ("finance", "hr", "operations", "it")]
    for target in targets:
        target.mkdir(parents=True, exist_ok=True)
        for path in target.glob("enterprise_*.csv"):
            path.unlink()
        for path in target.glob("enterprise_*.json"):
            path.unlink()


def _write_frames(profile_name: str, output_root: Path, frames: dict[str, object], manifest: dict[str, object]) -> None:
    if profile_name == "FINAL_36M":
        mapping = {
            "finance": {
                "enterprise_departments.csv": frames["dimensions"]["departments"],
                "enterprise_cost_categories.csv": frames["dimensions"]["cost_categories"],
                "enterprise_budget_scenarios.csv": frames["dimensions"]["budget_scenarios"],
                "enterprise_finance_monthly.csv": frames["finance_monthly"],
                "enterprise_budget_monthly.csv": frames["budget_monthly"],
            },
            "hr": {
                "enterprise_employee_roles.csv": frames["dimensions"]["employee_roles"],
                "enterprise_workforce_monthly.csv": frames["workforce_monthly"],
            },
            "operations": {"enterprise_operations_daily.csv": frames["operations_daily"]},
            "it": {
                "enterprise_it_systems.csv": frames["dimensions"]["it_systems"],
                "enterprise_incident_categories.csv": frames["dimensions"]["incident_categories"],
                "enterprise_it_incident.csv": frames["it_incident"],
                "enterprise_it_system_daily.csv": frames["it_system_daily"],
            },
        }
        for folder, files in mapping.items():
            for name, frame in files.items():
                frame.to_csv(output_root / folder / name, index=False)
        (output_root / "finance" / "enterprise_generation_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    else:
        for name in ["finance_monthly", "budget_monthly", "workforce_monthly", "operations_daily", "it_incident", "it_system_daily"]:
            frames[name].to_csv(output_root / f"{name}.csv", index=False)
        (output_root / "validation.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def generate(profile_name: str) -> dict[str, object]:
    profile = PROFILES[profile_name]
    start_date, end_date = profile_dates(profile)
    started = time.perf_counter()
    organizations, source_activity = load_activity(start_date, end_date)
    dimensions = build_dimensions(organizations)
    dimensions["organizations"] = organizations[["organization_key", "organization_id"]].copy()
    allocated = allocate_activity(start_date, end_date, organizations, source_activity, dimensions["departments"])
    operations = generate_operations(allocated, dimensions["departments"])
    workforce = generate_workforce(start_date, profile.months, operations, dimensions["departments"], dimensions)
    finance = generate_finance(start_date, profile.months, operations, workforce, dimensions)
    budget = generate_budget(finance, workforce, dimensions)
    it_daily = generate_it_system_daily(start_date, end_date, source_activity, dimensions)
    incidents, it_daily = generate_it_incidents(it_daily, dimensions)
    frames: dict[str, object] = {
        "dimensions": dimensions, "finance_monthly": finance, "budget_monthly": budget,
        "workforce_monthly": workforce, "operations_daily": operations,
        "it_incident": incidents, "it_system_daily": it_daily,
    }
    result = validate_generation(frames, profile_name)
    elapsed = time.perf_counter() - started
    manifest = {
        "profile": profile_name, "start_date": start_date, "end_date": end_date,
        "status": result.status, "fact_rows": result.fact_rows,
        "row_counts": {name: len(frames[name]) for name in ["finance_monthly", "budget_monthly", "workforce_monthly", "operations_daily", "it_incident", "it_system_daily"]},
        "validation": result.to_dict(), "runtime_seconds": round(elapsed, 3),
        "selected_organizations": organizations.to_dict(orient="records"),
    }
    if result.status != "PASS":
        raise RuntimeError(json.dumps(manifest, indent=2))
    _prepare_output(profile_name, profile.output_dir)
    _write_frames(profile_name, profile.output_dir, frames, manifest)
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", choices=PROFILES, required=True)
    arguments = parser.parse_args()
    print(json.dumps(generate(arguments.profile), indent=2))
