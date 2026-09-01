"""Stable enterprise dimensions and valid combination catalogs."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

import pandas as pd


DEPARTMENT_BLUEPRINTS = [
    (1, "EMERGENCY", "Emergency", "Emergency", True, True, True),
    (2, "OUTPATIENT", "Outpatient", "Ambulatory", True, True, False),
    (3, "INPATIENT", "Inpatient / Medical", "Inpatient", True, True, True),
    (4, "SURGERY", "Surgery", "Surgical", True, True, True),
    (5, "ICU", "Intensive Care Unit", "Inpatient", True, True, True),
    (6, "RADIOLOGY", "Radiology", "Diagnostic", True, True, False),
    (7, "LABORATORY", "Laboratory", "Diagnostic", True, True, False),
    (8, "PHARMACY", "Pharmacy", "Clinical Support", True, True, False),
    (9, "ADMIN", "Administration", "Administrative", False, False, False),
    (10, "FINANCE", "Finance", "Administrative", False, False, False),
    (11, "HR", "Human Resources", "Administrative", False, False, False),
    (12, "IT", "Information Technology", "Technology", False, False, False),
]

COST_CATEGORIES = [
    (1, "REVENUE", "Operating Revenue", "Revenue", False),
    (2, "PAYROLL", "Payroll", "Mixed", True),
    (3, "SUPPLIES", "Clinical Supplies", "Variable", False),
    (4, "MEDICATION", "Medications", "Variable", False),
    (5, "FACILITY", "Facilities", "Fixed", False),
    (6, "TECH_OTHER", "Technology & Other", "Mixed", False),
]

BUDGET_SCENARIOS = [
    (1, "ORIGINAL", "Original Budget", "Approved"),
    (2, "FORECAST", "Rolling Forecast", "Rolling Forecast"),
    (3, "STRETCH", "Stretch Target", "Target"),
]

EMPLOYEE_ROLES = [
    (1, "PHYSICIAN", "Physician", "Clinical", True, 168.0),
    (2, "NURSING", "Nursing", "Clinical", True, 168.0),
    (3, "ALLIED", "Allied Health", "Clinical", True, 168.0),
    (4, "ADMIN_ROLE", "Administrative", "Administrative", False, 168.0),
    (5, "OPS_SUPPORT", "Operations Support", "Support", False, 168.0),
    (6, "TECHNOLOGY", "Technology", "Technology", False, 168.0),
    (7, "MANAGEMENT", "Management", "Leadership", False, 168.0),
]

IT_SYSTEMS = [
    (1, "EHR", "Electronic Health Record", "Clinical", "Tier 1", 99.90, 120),
    (2, "PACS", "Imaging and PACS", "Clinical", "Tier 1", 99.80, 180),
    (3, "LIS", "Laboratory Information System", "Clinical", "Tier 1", 99.80, 180),
    (4, "PHARM", "Pharmacy System", "Clinical", "Tier 1", 99.80, 180),
    (5, "ERP", "Enterprise Resource Planning", "Administrative", "Tier 2", 99.50, 240),
    (6, "DATA", "Analytics and Data Platform", "Analytics", "Tier 2", 99.50, 240),
]

INCIDENT_CATEGORIES = [
    (1, "APPLICATION", "Application", "Software", "P3"),
    (2, "INFRA", "Infrastructure", "Platform", "P3"),
    (3, "NETWORK", "Network", "Connectivity", "P2"),
    (4, "ACCESS", "Access and Identity", "Security", "P3"),
    (5, "INTEGRATION", "Integration", "Interface", "P3"),
    (6, "DATA_REPORT", "Data and Reporting", "Analytics", "P4"),
]

ROLE_CODES_BY_DEPARTMENT = {
    "EMERGENCY": ["PHYSICIAN", "NURSING", "ALLIED", "OPS_SUPPORT", "MANAGEMENT"],
    "OUTPATIENT": ["PHYSICIAN", "NURSING", "ALLIED", "ADMIN_ROLE", "MANAGEMENT"],
    "INPATIENT": ["PHYSICIAN", "NURSING", "ALLIED", "OPS_SUPPORT", "MANAGEMENT"],
    "SURGERY": ["PHYSICIAN", "NURSING", "ALLIED", "OPS_SUPPORT", "MANAGEMENT"],
    "ICU": ["PHYSICIAN", "NURSING", "ALLIED", "OPS_SUPPORT", "MANAGEMENT"],
    "RADIOLOGY": ["PHYSICIAN", "ALLIED", "ADMIN_ROLE", "OPS_SUPPORT", "MANAGEMENT"],
    "LABORATORY": ["ALLIED", "ADMIN_ROLE", "OPS_SUPPORT", "TECHNOLOGY", "MANAGEMENT"],
    "PHARMACY": ["ALLIED", "ADMIN_ROLE", "OPS_SUPPORT", "TECHNOLOGY", "MANAGEMENT"],
    "ADMIN": ["ADMIN_ROLE", "OPS_SUPPORT", "TECHNOLOGY", "MANAGEMENT", "ALLIED"],
    "FINANCE": ["ADMIN_ROLE", "OPS_SUPPORT", "TECHNOLOGY", "MANAGEMENT", "ALLIED"],
    "HR": ["ADMIN_ROLE", "OPS_SUPPORT", "TECHNOLOGY", "MANAGEMENT", "ALLIED"],
    "IT": ["TECHNOLOGY", "ADMIN_ROLE", "OPS_SUPPORT", "MANAGEMENT", "ALLIED"],
}


def build_dimensions(organizations: pd.DataFrame) -> dict[str, pd.DataFrame]:
    """Create stable dimension rows using the three selected organizations."""
    if len(organizations) != 3:
        raise ValueError("Exactly three organizations are required")
    orgs = organizations.sort_values("organization_key").reset_index(drop=True)
    rows = []
    for index, blueprint in enumerate(DEPARTMENT_BLUEPRINTS):
        key, code, name, dtype, clinical, capacity, beds = blueprint
        org = orgs.iloc[index % 3]
        rows.append(
            {
                "department_key": key,
                "department_code": code,
                "department_name": name,
                "department_type": dtype,
                "clinical_flag": clinical,
                "capacity_managed_flag": capacity,
                "bed_applicable_flag": beds,
                "organization_key": int(org.organization_key),
                "organization_id": str(org.organization_id),
                "effective_start_date": "2023-08-01",
                "effective_end_date": None,
                "is_active": True,
                "source_system": "Hospital360 Enterprise Synthetic",
            }
        )
    departments = pd.DataFrame(rows)
    cost = pd.DataFrame(
        COST_CATEGORIES,
        columns=["cost_category_key", "cost_category_code", "cost_category_name", "cost_behavior", "payroll_flag"],
    ).assign(display_order=lambda frame: frame.cost_category_key, is_active=True)
    budget = pd.DataFrame(
        BUDGET_SCENARIOS,
        columns=["budget_scenario_key", "budget_scenario_code", "budget_scenario_name", "scenario_type"],
    ).assign(display_order=lambda frame: frame.budget_scenario_key, is_active=True)
    roles = pd.DataFrame(
        EMPLOYEE_ROLES,
        columns=["employee_role_key", "employee_role_code", "employee_role_name", "role_family", "clinical_flag", "standard_hours_per_fte_month"],
    ).assign(is_active=True)
    systems = pd.DataFrame(
        IT_SYSTEMS,
        columns=["it_system_key", "it_system_code", "it_system_name", "system_domain", "criticality_tier", "target_uptime_pct", "default_sla_minutes"],
    ).assign(is_active=True)
    categories = pd.DataFrame(
        INCIDENT_CATEGORIES,
        columns=["incident_category_key", "incident_category_code", "incident_category_name", "category_group", "default_priority"],
    ).assign(is_active=True)
    return {
        "departments": departments,
        "cost_categories": cost,
        "budget_scenarios": budget,
        "employee_roles": roles,
        "it_systems": systems,
        "incident_categories": categories,
    }


def valid_department_roles(dimensions: dict[str, pd.DataFrame]) -> pd.DataFrame:
    roles = dimensions["employee_roles"].set_index("employee_role_code")
    rows = []
    for department in dimensions["departments"].itertuples(index=False):
        for code in ROLE_CODES_BY_DEPARTMENT[department.department_code]:
            rows.append({"department_key": department.department_key, "employee_role_key": int(roles.loc[code, "employee_role_key"])})
    return pd.DataFrame(rows)
