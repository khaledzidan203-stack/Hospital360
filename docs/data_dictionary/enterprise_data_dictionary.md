# Hospital360 Enterprise Data Dictionary

**Status: Implemented and Validated — Enterprise V1**

## Conventions

## Implemented Physical Scope

The physical definitions are governed by the versioned RAW, STAGING, and ANALYTICS SQL scripts. Implemented fact grains are:

- Finance Monthly: month × organization × department × cost category.
- Budget Monthly: month × organization × department × budget scenario.
- Workforce Monthly: month × organization × department × employee role.
- Operations Daily: date × organization × department.
- IT Incident: one row per incident ID.
- IT System Daily: date × organization × IT system.

The implementation uses six cost categories, including the revenue classification that keeps synthetic operating revenue separate from costs. Bed-related Operations fields remain nullable for departments where beds are not applicable.

- Names are proposed logical/physical names and do not create database objects.
- Surrogate keys are integers; fact row keys may use bigint identities.
- Date foreign keys reuse `analytics.dim_date.date_key`.
- Organization foreign keys reuse `analytics.dim_organization.organization_key`.
- New dimensions reserve key `0` for Unknown / Unmapped.
- Required grain columns are non-null after staging validation.
- Audit columns such as `source_system`, `generation_run_id`, and `source_row_hash` may be added consistently to every table during implementation.

## Dimensions

### `analytics.dim_department`

**Grain:** one governed department within one organization.

| Column | Proposed type | Nullable | Description |
|---|---|:---:|---|
| `department_key` | integer | No | Surrogate primary key; `0` is Unknown. |
| `department_code` | text | No | Stable code unique within organization. |
| `department_name` | text | No | Portfolio display name. |
| `department_type` | text | No | Emergency, Inpatient, Ambulatory, Diagnostic, Administrative, Technology, or Support. |
| `clinical_flag` | boolean | No | Indicates a clinical service department. |
| `capacity_managed_flag` | boolean | No | Indicates inclusion in daily operations generation. |
| `organization_key` | integer | No | Governed mapping to existing Organization. |
| `organization_id` | text | No | Existing organization natural key retained for validation. |
| `effective_start_date` | date | No | Start of valid department mapping. |
| `effective_end_date` | date | Yes | End of mapping, if retired. |
| `is_active` | boolean | No | Current activity status. |
| `source_system` | text | No | `Hospital360 Enterprise Synthetic`. |

**Candidate uniqueness:** `organization_id + department_code` — To Be Validated.

### `analytics.dim_cost_category`

**Grain:** one governed operating-cost category.

| Column | Proposed type | Nullable | Description |
|---|---|:---:|---|
| `cost_category_key` | integer | No | Surrogate primary key. |
| `cost_category_code` | text | No | Natural key. |
| `cost_category_name` | text | No | Payroll, Clinical Supplies, Pharmaceuticals, Facilities, or Technology & Other. |
| `cost_behavior` | text | No | Fixed, Variable, or Mixed. |
| `payroll_flag` | boolean | No | Identifies category reconciled to workforce payroll. |
| `display_order` | smallint | No | Stable report order. |
| `is_active` | boolean | No | Current status. |

### `analytics.dim_budget_scenario`

**Grain:** one budget scenario/version.

| Column | Proposed type | Nullable | Description |
|---|---|:---:|---|
| `budget_scenario_key` | integer | No | Surrogate primary key. |
| `budget_scenario_code` | text | No | Natural key: ORIGINAL, FORECAST, or STRETCH. |
| `budget_scenario_name` | text | No | Display name. |
| `scenario_type` | text | No | Approved, Rolling Forecast, or Target. |
| `display_order` | smallint | No | Stable report order. |
| `is_active` | boolean | No | Current status. |

### `analytics.dim_employee_role`

**Grain:** one governed workforce role group.

| Column | Proposed type | Nullable | Description |
|---|---|:---:|---|
| `employee_role_key` | integer | No | Surrogate primary key. |
| `employee_role_code` | text | No | Natural key. |
| `employee_role_name` | text | No | Display role group such as Physician, Nursing, Allied Health, Administrative, Operations Support, Technology, or Management. |
| `role_family` | text | No | Clinical, Administrative, Support, Technology, or Leadership. |
| `clinical_flag` | boolean | No | Indicates clinical workforce role. |
| `standard_hours_per_fte_month` | numeric(8,2) | No | Planning basis, not an employee contract. |
| `is_active` | boolean | No | Current status. |

### `analytics.dim_it_system`

**Grain:** one synthetic technology system or service.

| Column | Proposed type | Nullable | Description |
|---|---|:---:|---|
| `it_system_key` | integer | No | Surrogate primary key. |
| `it_system_code` | text | No | Natural key. |
| `it_system_name` | text | No | Display name. |
| `system_domain` | text | No | Clinical, Administrative, Infrastructure, Integration, or Analytics. |
| `criticality_tier` | text | No | Tier 1, Tier 2, or Tier 3. |
| `target_uptime_pct` | numeric(7,4) | No | Governed availability target. |
| `default_sla_minutes` | integer | No | Default resolution target for standard incidents. |
| `is_active` | boolean | No | Current status. |

### `analytics.dim_incident_category`

**Grain:** one governed IT incident category.

| Column | Proposed type | Nullable | Description |
|---|---|:---:|---|
| `incident_category_key` | integer | No | Surrogate primary key. |
| `incident_category_code` | text | No | Natural key. |
| `incident_category_name` | text | No | Application, Infrastructure, Network, Access, Integration, or Data/Reporting. |
| `category_group` | text | No | Technical grouping. |
| `default_priority` | text | No | Typical P1–P4 priority, not a forced incident severity. |
| `is_active` | boolean | No | Current status. |

## Facts

### `analytics.fact_finance_monthly`

**Grain:** one cost-category actual for one department, organization, and month.

| Column | Proposed type | Nullable | Description / aggregation |
|---|---|:---:|---|
| `finance_monthly_key` | bigint | No | Surrogate row key. |
| `month_start_date_key` | integer | No | Active Date FK; first day of month. |
| `organization_key` | integer | No | Existing Organization FK. |
| `department_key` | integer | No | Department FK. |
| `cost_category_key` | integer | No | Cost Category FK. |
| `actual_operating_cost` | numeric(18,2) | No | Additive operating cost; non-negative. |
| `fixed_cost_amount` | numeric(18,2) | No | Additive fixed component. |
| `variable_cost_amount` | numeric(18,2) | No | Additive activity-sensitive component. |
| `allocated_shared_cost_amount` | numeric(18,2) | No | Additive governed allocation. |
| `driver_encounter_count` | integer | Yes | Generation audit only; not a relationship to Encounter fact. |
| `driver_procedure_count` | integer | Yes | Generation audit only; not a relationship to Procedure fact. |
| `dq_status` | text | No | PASS, WARNING, or ERROR. |

**Candidate uniqueness:** month + organization + department + cost category — To Be Validated.

### `analytics.fact_budget_monthly`

**Grain:** one budget scenario for one department, organization, and month.

| Column | Proposed type | Nullable | Description / aggregation |
|---|---|:---:|---|
| `budget_monthly_key` | bigint | No | Surrogate row key. |
| `month_start_date_key` | integer | No | Active Date FK. |
| `organization_key` | integer | No | Existing Organization FK. |
| `department_key` | integer | No | Department FK. |
| `budget_scenario_key` | integer | No | Budget Scenario FK. |
| `budget_operating_cost` | numeric(18,2) | No | Additive planned operating cost. |
| `budget_payroll_cost` | numeric(18,2) | No | Additive planned payroll component. |
| `budget_capital_amount` | numeric(18,2) | No | Additive planned capital amount; kept separate from operating cost. |
| `budget_fte` | numeric(10,2) | No | Semi-additive planned FTE snapshot/average. |
| `assumption_version` | text | No | Traceable synthetic assumption set. |
| `dq_status` | text | No | PASS, WARNING, or ERROR. |

**Candidate uniqueness:** month + organization + department + scenario — To Be Validated.

### `analytics.fact_workforce_monthly`

**Grain:** one workforce role summary for one department, organization, and month.

| Column | Proposed type | Nullable | Description / aggregation |
|---|---|:---:|---|
| `workforce_monthly_key` | bigint | No | Surrogate row key. |
| `month_start_date_key` | integer | No | Active Date FK. |
| `organization_key` | integer | No | Existing Organization FK. |
| `department_key` | integer | No | Department FK. |
| `employee_role_key` | integer | No | Employee Role FK. |
| `headcount_start` | integer | No | Semi-additive start snapshot. |
| `headcount_end` | integer | No | Semi-additive end snapshot. |
| `average_headcount` | numeric(10,2) | No | Semi-additive monthly average. |
| `fte_start` | numeric(10,2) | No | Semi-additive start snapshot. |
| `fte_end` | numeric(10,2) | No | Semi-additive end snapshot. |
| `average_fte` | numeric(10,2) | No | Denominator for period productivity. |
| `hires` | integer | No | Additive monthly count. |
| `separations` | integer | No | Additive monthly count. |
| `scheduled_hours` | numeric(14,2) | No | Additive. |
| `worked_hours` | numeric(14,2) | No | Additive. |
| `overtime_hours` | numeric(14,2) | No | Additive subset of worked hours. |
| `absence_hours` | numeric(14,2) | No | Additive. |
| `payroll_cost` | numeric(18,2) | No | Additive synthetic payroll cost. |
| `dq_status` | text | No | PASS, WARNING, or ERROR. |

**Candidate uniqueness:** month + organization + department + employee role — To Be Validated.

### `analytics.fact_operations_daily`

**Grain:** one daily summary for one capacity-managed department and organization.

| Column | Proposed type | Nullable | Description / aggregation |
|---|---|:---:|---|
| `operations_daily_key` | bigint | No | Surrogate row key. |
| `date_key` | integer | No | Active Date FK. |
| `organization_key` | integer | No | Existing Organization FK. |
| `department_key` | integer | No | Department FK. |
| `licensed_beds` | integer | No | Semi-additive capacity snapshot. Zero for non-bed ambulatory areas. |
| `staffed_beds` | integer | No | Semi-additive available staffed capacity. |
| `available_bed_days` | numeric(12,2) | No | Additive capacity denominator. |
| `occupied_bed_days` | numeric(12,2) | No | Additive occupancy numerator. |
| `admissions` | integer | No | Additive daily count. |
| `discharges` | integer | No | Additive daily count. |
| `encounter_count` | integer | No | Additive allocated encounter activity. |
| `appointment_slots` | integer | No | Additive scheduled capacity. |
| `appointments_completed` | integer | No | Additive completed appointments. |
| `wait_minutes_total` | numeric(16,2) | No | Additive numerator for weighted average waiting time. |
| `waited_encounter_count` | integer | No | Additive waiting-time denominator. |
| `length_of_stay_days_total` | numeric(16,2) | No | Additive numerator for ALOS. |
| `discharged_with_los_count` | integer | No | Additive ALOS denominator. |
| `overflow_capacity_flag` | boolean | No | Explains deliberately valid occupancy above nominal capacity. |
| `dq_status` | text | No | PASS, WARNING, or ERROR. |

**Candidate uniqueness:** date + organization + department — To Be Validated.

### `analytics.fact_it_incident`

**Grain:** one synthetic IT incident.

| Column | Proposed type | Nullable | Description / aggregation |
|---|---|:---:|---|
| `it_incident_key` | bigint | No | Surrogate row key. |
| `incident_id` | text | No | Natural business key. |
| `opened_date_key` | integer | No | Active opened-date FK. |
| `resolved_date_key` | integer | No | Role-playing resolved-date FK; key `0` for unresolved. |
| `organization_key` | integer | No | Existing Organization FK. |
| `department_key` | integer | No | Affected Department FK. |
| `it_system_key` | integer | No | IT System FK. |
| `incident_category_key` | integer | No | Incident Category FK. |
| `opened_at` | timestamptz | No | Incident open timestamp. |
| `resolved_at` | timestamptz | Yes | Resolution timestamp. |
| `severity` | text | No | P1, P2, P3, or P4. |
| `status` | text | No | Open, Resolved, or Closed. |
| `channel` | text | No | Portal, Phone, Monitoring, or Email. |
| `sla_class` | text | No | Governed SLA tier. |
| `resolution_minutes` | integer | Yes | Additive duration for resolved incidents; use weighted mean. |
| `downtime_minutes` | integer | No | Additive downtime attributable to incident. |
| `sla_target_minutes` | integer | No | Target for the incident. |
| `affected_users` | integer | No | Additive only where incidents do not overlap; otherwise exposure indicator. |
| `business_impact_score` | numeric(8,2) | No | Synthetic severity/exposure score. |
| `resolved_within_sla_flag` | boolean | Yes | Null for unresolved incidents. |
| `dq_status` | text | No | PASS, WARNING, or ERROR. |

**Candidate uniqueness:** incident ID — To Be Validated.

### `analytics.fact_it_system_daily`

**Grain:** one daily system summary for one supported department and organization.

| Column | Proposed type | Nullable | Description / aggregation |
|---|---|:---:|---|
| `it_system_daily_key` | bigint | No | Surrogate row key. |
| `date_key` | integer | No | Active Date FK. |
| `organization_key` | integer | No | Existing Organization FK. |
| `department_key` | integer | No | Supported Department FK. |
| `it_system_key` | integer | No | IT System FK. |
| `scheduled_minutes` | integer | No | Additive availability denominator. |
| `available_minutes` | integer | No | Additive uptime numerator. |
| `downtime_minutes` | integer | No | Additive total downtime. |
| `planned_downtime_minutes` | integer | No | Additive planned component. |
| `unplanned_downtime_minutes` | integer | No | Additive unplanned component. |
| `transaction_count` | bigint | No | Additive system-usage count. Not a claim transaction. |
| `active_user_count` | integer | No | Non-additive daily distinct-user estimate. |
| `peak_concurrent_users` | integer | No | Non-additive daily peak. |
| `dq_status` | text | No | PASS, WARNING, or ERROR. |

**Candidate uniqueness:** date + organization + department + IT system — To Be Validated.

## Relationship and Usage Notes

- `organization_key` and `department_key` must be mutually consistent on every row.
- `driver_encounter_count` and `driver_procedure_count` are generation lineage values, not foreign keys or substitutes for existing facts.
- Ratios must use stored numerators and denominators rather than averaging row-level percentages.
- Headcount, FTE, beds, active users, and peak users are snapshots/non-additive across time.
- Financial cost facts contain synthetic operating cost only. Existing Synthea claim activity remains separate and is not relabeled as revenue.
