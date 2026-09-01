# Hospital360 Enterprise Extension Design

**Status: Implemented and Validated — Enterprise V1**

## Purpose and Scope

This extension adds small-scale synthetic Finance, HR / Workforce, Operations / Capacity, and IT / Technology analytics to the validated Hospital360 foundation. It is designed for SQL, Python, and Power BI while preserving the current clinical model and keeping the complete new fact dataset below 40,000 rows.

The extension uses synthetic operational records only. It does not represent a real hospital, employee population, financial ledger, or technology environment.

## Design Decisions

- Analysis window: **2023-08-01 through 2026-07-31**, 36 complete months and 1,096 calendar days.
- Enterprise scope: 12 controlled departments mapped to three selected existing synthetic organizations.
- Existing conformed dimensions reused: `analytics.dim_date` and `analytics.dim_organization`.
- `analytics.dim_provider` is not used by the first enterprise facts because workforce is role-level, not employee/provider-level. It may be used later only after provider-to-department assignment is governed.
- New facts relate only to dimensions. There are no fact-to-fact relationships.
- Cross-domain KPIs combine independently aggregated measures through Date, Organization, and Department filter context.
- Existing claim and transaction activity is not treated as hospital revenue.

## Business Questions

### Finance

- How does actual operating cost compare with approved budget by month, organization, and department?
- Which departments and cost categories account for the largest share of operating cost?
- How much of operating cost is attributable to payroll?
- How does operating cost per encounter change over time?
- Where are material unfavorable budget variances concentrated?
- Are cost movements consistent with changes in clinical activity and workforce demand?

### HR / Workforce

- What are month-end headcount and FTE by organization, department, and role?
- How do staffing levels compare with encounter activity and capacity demand?
- Where are overtime and absence rates elevated?
- Which departments have the highest separations and turnover?
- How does payroll cost change with workforce mix and overtime?
- How many encounters are supported per average FTE?

### Operations / Capacity

- What are staffed capacity and occupancy by department and day?
- How do admissions, discharges, and bed turnover change over time?
- What is average length of stay using discharge-weighted totals?
- Where do waiting time and appointment utilization indicate pressure?
- Which departments operate near capacity most frequently?
- How does observed activity align with staffing and operating cost?

### IT / Technology

- What uptime and downtime are recorded by system and supported department?
- Which systems and departments generate the most incidents?
- What percentage of resolved incidents meet their SLA target?
- How long do incidents take to resolve by severity and category?
- Where are critical incidents concentrated?
- How do system usage and ticket volume change with workforce and operational activity?

## Conformed Dimensions

### Existing Dimensions

| Dimension | Enterprise use | Rule |
|---|---|---|
| `analytics.dim_date` | All monthly and daily date roles | Use existing `date_key`; no second calendar dimension. |
| `analytics.dim_organization` | Direct filter on every enterprise fact | Select three existing synthetic organization business members with sufficient activity in the design window. Do not invent replacement organization IDs. |
| `analytics.dim_provider` | Deferred | No provider FK in Enterprise V1 because role-level workforce aggregates cannot support a valid individual-provider relationship. |

### New Dimensions

| Dimension | Grain | Surrogate key | Natural key | Purpose |
|---|---|---|---|---|
| `analytics.dim_department` | One governed department within one organization | `department_key` | `organization_id + department_code` | Shared department filtering across all six facts. |
| `analytics.dim_cost_category` | One operating-cost category | `cost_category_key` | `cost_category_code` | Classifies actual operating cost without implying revenue. |
| `analytics.dim_employee_role` | One governed workforce role group | `employee_role_key` | `employee_role_code` | Supports role-level workforce analysis without employee-level records. |
| `analytics.dim_budget_scenario` | One budget scenario/version | `budget_scenario_key` | `budget_scenario_code` | Separates Original, Forecast, and Stretch scenarios. |
| `analytics.dim_it_system` | One synthetic technology system/service | `it_system_key` | `it_system_code` | Conforms incident and daily availability facts. |
| `analytics.dim_incident_category` | One governed IT incident category | `incident_category_key` | `incident_category_code` | Supports stable incident classification. |

### Dim_Department Definition

**Grain:** one department within one selected existing organization.

**Key strategy:** integer `department_key`, with key `0` reserved for Unknown. The natural key is the composite `organization_id + department_code`; department codes are unique within an organization, not assumed globally unique.

**Required attributes:**

- `department_key`
- `department_code`
- `department_name`
- `department_type` such as Emergency, Inpatient, Ambulatory, Diagnostic, Administrative, Technology, or Support
- `clinical_flag`
- `capacity_managed_flag`
- `organization_key` and `organization_id` mapping
- `effective_start_date`
- `effective_end_date`, nullable
- `is_active`
- `source_system`

The initial 12-department catalog contains eight clinical/capacity departments and four shared non-clinical departments. Each department maps to exactly one selected organization. Facts also carry `organization_key` directly, and ingestion must validate that it agrees with the department mapping. Power BI should not create both a direct and indirect organization filtering path.

## Fact Design

### Fact_Finance_Monthly

- **Grain:** one organization + department + month + cost category.
- **Natural grain key:** `month_start_date_key + organization_key + department_key + cost_category_key`.
- **Foreign keys:** month-start Date, Organization, Department, Cost Category.
- **Measures:** `actual_operating_cost`, `fixed_cost_amount`, `variable_cost_amount`, `allocated_shared_cost_amount`.
- **Generation:** cost baselines depend on department type, average workforce, encounter/procedure activity, capacity, inflation, seasonality, and controlled noise. Payroll-category actuals reconcile to workforce payroll within an explicit tolerance.
- **Expected rows:** 2,160 (12 departments × 36 months × 5 categories).
- **Aggregation:** currency measures are additive across categories, departments, and months. Ratios and cost per encounter are calculated, not stored.
- **Existing integration:** clinical activity is first aggregated by organization/month and allocated to departments using governed mappings; no patient or encounter FK is added.
- **Uses:** cost trend, cost mix, department cost share, payroll share, cost per encounter.

### Fact_Budget_Monthly

- **Grain:** one organization + department + month + budget scenario.
- **Natural grain key:** `month_start_date_key + organization_key + department_key + budget_scenario_key`.
- **Foreign keys:** month-start Date, Organization, Department, Budget Scenario.
- **Measures:** `budget_operating_cost`, `budget_payroll_cost`, `budget_capital_amount`, `budget_fte`.
- **Generation:** Original budget uses prior run rate, expected activity, staffing plan, inflation, and approved efficiency assumptions. Forecast incorporates information available to the simulated forecast month. Stretch is a deliberately tighter scenario.
- **Expected rows:** 1,296 (12 × 36 × 3 scenarios).
- **Aggregation:** budget amounts are additive. `budget_fte` is a month-end/average plan and semi-additive over time.
- **Existing integration:** activity forecasts are derived from lagged aggregated clinical activity, never from claim transaction amounts presented as revenue.
- **Uses:** actual vs budget, budget variance, achievement, staffing-plan comparison.

### Fact_Workforce_Monthly

- **Grain:** one organization + department + employee role + month.
- **Natural grain key:** `month_start_date_key + organization_key + department_key + employee_role_key`.
- **Foreign keys:** month-start Date, Organization, Department, Employee Role.
- **Measures:** `headcount_start`, `headcount_end`, `average_headcount`, `fte_start`, `fte_end`, `average_fte`, `hires`, `separations`, `scheduled_hours`, `worked_hours`, `overtime_hours`, `absence_hours`, `payroll_cost`.
- **Generation:** staffing demand follows smoothed activity, department minimum coverage, operating hours, role mix, and capacity. Hiring and separation effects occur with lag and bounded month-to-month movement.
- **Expected rows:** approximately 2,160 based on 60 valid department-role assignments across 36 months.
- **Aggregation:** hours, hires, separations, and payroll are additive. Headcount and FTE snapshots are semi-additive and must not be summed over months.
- **Existing integration:** provider is deliberately absent; existing provider IDs do not represent the full workforce.
- **Uses:** staffing, overtime, absence, turnover, payroll, encounters per FTE.

### Fact_Operations_Daily

- **Grain:** one organization + capacity-managed clinical department + calendar date.
- **Natural grain key:** `date_key + organization_key + department_key`.
- **Foreign keys:** Date, Organization, Department.
- **Measures:** `licensed_beds`, `staffed_beds`, `available_bed_days`, `occupied_bed_days`, `admissions`, `discharges`, `encounter_count`, `appointment_slots`, `appointments_completed`, `wait_minutes_total`, `waited_encounter_count`, `length_of_stay_days_total`, `discharged_with_los_count`.
- **Generation:** existing encounter activity provides an aggregated demand anchor. Capacity, day-of-week, seasonality, staffing, cancellations, and random variation influence operational values.
- **Expected rows:** 8,768 (8 capacity-managed departments × 1,096 days).
- **Aggregation:** event counts, totals, and bed-days are additive. Licensed/staffed beds are snapshots and semi-additive. Occupancy, ALOS, waiting time, utilization, and turnover are calculated ratios.
- **Existing integration:** uses aggregated encounter and procedure activity by date/organization; allocation to department is governed and noisy, not patient-level.
- **Uses:** occupancy, throughput, ALOS, waiting time, appointment utilization, capacity pressure.

### Fact_IT_Incident

- **Grain:** one synthetic IT incident/ticket.
- **Natural grain key:** `incident_id`.
- **Foreign keys:** opened Date, resolved Date role, Organization, affected Department, IT System, Incident Category.
- **Degenerate attributes:** severity (`P1`–`P4`), status, channel, SLA class.
- **Measures:** `resolution_minutes`, `downtime_minutes`, `sla_target_minutes`, `affected_users`, `business_impact_score`, `resolved_within_sla_flag`.
- **Generation:** incident arrival rates depend on system criticality, usage, change windows, department activity, and recent reliability, with stochastic variation and controlled anomaly events.
- **Expected rows:** 2,000–3,000.
- **Aggregation:** incident count, downtime, affected users, and resolution minutes are additive at incident grain; SLA compliance and mean resolution time are calculated.
- **Existing integration:** department activity and workforce affect usage exposure, but incidents are not mechanically proportional to clinical events.
- **Uses:** incident volume, SLA, severity, resolution time, critical incident rate.

### Fact_IT_System_Daily

- **Grain:** one governed IT system + supported department + calendar date.
- **Natural grain key:** `date_key + organization_key + department_key + it_system_key`.
- **Foreign keys:** Date, Organization, Department, IT System.
- **Measures:** `scheduled_minutes`, `available_minutes`, `downtime_minutes`, `planned_downtime_minutes`, `unplanned_downtime_minutes`, `transaction_count`, `active_user_count`, `peak_concurrent_users`.
- **Generation:** eight governed system-department coverage pairs are generated daily. Usage follows operating schedules, workforce, appointments, and encounter demand. Availability follows system reliability and maintenance with incident-consistent downtime.
- **Expected rows:** 8,768 (8 coverage pairs × 1,096 days).
- **Aggregation:** time and transaction totals are additive across days/pairs when each pair is distinct. Active and peak users are non-additive across systems and time. Uptime is calculated from available/scheduled minutes.
- **Existing integration:** activity and workforce are aggregated drivers; no relationship to patient, encounter, or transaction facts is created.
- **Uses:** uptime, downtime, usage, availability, capacity, tickets per exposure unit.

## Existing Data Integration

```text
Existing encounter/procedure activity by Date + Organization
        ↓ governed department allocation with controlled noise
Operations demand and utilization
        ↓ lagged staffing response
Workforce capacity and payroll
        ↓ category-specific fixed/variable cost logic
Finance actuals and budgets

Operations + Workforce exposure
        ↓ system-specific usage model
IT daily usage and availability
        ↓ reliability and stochastic incident model
IT incidents
```

Integration rules:

1. Select three existing synthetic organizations with stable activity during the 36-month window.
2. Map the 12 enterprise departments to those organizations through `dim_department`.
3. Aggregate existing facts before using them as generation drivers.
4. Allocate activity by stable department rules and seeded weights; do not attach finance or workforce rows to patients or encounters.
5. Load the resulting enterprise facts with Date, Organization, and Department keys.
6. Compare facts only through conformed dimensions and independent measures.

## Data Quality Classification

- **ERROR:** breaks grain, keys, required references, type rules, or physical possibility. The row must fail or quarantine.
- **WARNING:** plausible but incomplete, extreme, or semantically unresolved. Preserve the row and flag it.
- **BUSINESS ANOMALY:** valid record intentionally outside normal operating tolerance. Preserve and surface it for analysis.

### Fact-Level Rules

| Fact | ERROR | WARNING | BUSINESS ANOMALY |
|---|---|---|---|
| Finance Monthly | Duplicate grain; missing FK; negative operating cost; fixed + variable + allocated does not reconcile to actual within rounding tolerance | Missing category budget comparison; payroll reconciliation outside tolerance | Unfavorable variance above 15%; monthly cost spike above robust threshold |
| Budget Monthly | Duplicate grain; missing scenario/date/department; negative budget amounts; invalid scenario | Missing Original scenario; budget FTE inconsistent with workforce plan | Forecast revision above 10%; capital-plan spike |
| Workforce Monthly | Duplicate grain; missing FK; negative headcount/FTE/hours/payroll; `fte_end > headcount_end`; worked-hour arithmetic failure | FTE ≤ 0 for active clinical department; overtime or absence beyond review threshold; large unexplained staffing swing | Overtime >15% of worked hours; absence >10%; turnover spike |
| Operations Daily | Duplicate grain; missing FK; negative counts; `staffed_beds > licensed_beds`; completed appointments > slots; invalid ratio denominator | Occupancy >100% only if explicitly tagged overflow; admissions/discharges imbalance; missing waiting-time denominator | Occupancy ≥95%; wait time above target; appointment utilization below 65% |
| IT Incident | Duplicate incident ID; missing FK/opened date; resolved before opened; negative duration; resolved flag without resolved date | Open incident beyond SLA; affected users missing; SLA flag inconsistent with duration | P1/P2 incident; unplanned downtime >120 minutes; repeated-system cluster |
| IT System Daily | Duplicate grain; missing FK; minutes outside 0–1,440; availability arithmetic failure; uptime outside 0–100%; negative usage | Zero usage on normally active day; incident downtime mismatch outside tolerance | Uptime <99%; major usage surge; peak concurrency above planned threshold |

## Implementation Order

1. Approve the design, grains, mappings, and KPI definitions.
2. Implement and validate `Dim_Department` and the other small reference dimensions.
3. Generate a one-month sample.
4. Validate keys, arithmetic, DQ flags, correlations, runtime, and reconciliation.
5. Generate and validate a three-month sample.
6. Generate and validate a 12-month sample.
7. Generate the final 36-month snapshot only after all gates pass.
8. Implement RAW ingestion.
9. Implement STAGING typing and source-preserving transformations.
10. Execute DQ and quarantine/warning rules.
11. Implement ANALYTICS dimensions and facts.
12. Reconcile SQL row counts and measures at native grains.
13. Perform Python EDA and correlation validation.
14. Extend Power BI using the existing Hospital360 design system.
15. Finalize documentation.
16. Create a Git milestone.

## Progressive Scaling Rule

**Do not jump directly to the final dataset.** Required progression:

`1 month → 3 months → 12 months → 36 months final`

At every scale validate runtime, row counts, key uniqueness, DQ classifications, business relationships, financial/operational arithmetic, and source-to-target reconciliation. A failed gate blocks the next scale.

## Future Power BI Page Plan

### Financial Performance

- **Purpose:** Actual cost, budget variance, cost mix, and cost per encounter.
- **KPIs:** Actual Operating Cost, Budget, Budget Variance, Budget Achievement %, Payroll Cost %, Cost per Encounter.
- **Charts:** monthly actual vs budget; variance by department; cost-category mix; department cost share.
- **Slicers:** Date, Organization, Department, Cost Category, Budget Scenario.
- **Drill path:** Organization → Department → Cost Category → Month.
- **Home integration:** Add a tile using the existing Home navigation and visual standard.

### Workforce Performance

- **Purpose:** Workforce capacity, cost, attendance, turnover, and activity-normalized staffing.
- **KPIs:** Headcount, FTE, Overtime Hours, Absence Rate, Turnover Rate, Payroll Cost, Encounters per FTE.
- **Charts:** staffing trend; role mix; overtime/absence by department; payroll trend; productivity scatter.
- **Slicers:** Date, Organization, Department, Employee Role.
- **Drill path:** Organization → Department → Role → Month.
- **Home integration:** Add a tile only after page validation.

### Operations & Capacity

- **Purpose:** Capacity, occupancy, throughput, waiting, and appointment utilization.
- **KPIs:** Staffed Beds, Occupancy Rate, Admissions, Discharges, ALOS, Bed Turnover, Average Waiting Time, Appointment Utilization.
- **Charts:** occupancy trend; admissions/discharges; waiting time by department; utilization heatmap.
- **Slicers:** Date, Organization, Department, Department Type.
- **Drill path:** Organization → Department → Month → Day.
- **Home integration:** Reuse the existing page-navigation tile pattern.

### Technology Performance

- **Purpose:** Availability, usage, incidents, and SLA performance.
- **KPIs:** Uptime %, Downtime Minutes, Incident Count, SLA Compliance %, Mean Resolution Time, Critical Incident Rate.
- **Charts:** uptime trend; incident volume by severity/category; SLA trend; system-department matrix; downtime Pareto.
- **Slicers:** Date, Organization, Department, IT System, Incident Category, Severity.
- **Drill path:** System → Department → Incident Category → Incident.
- **Home integration:** Add one validated tile consistent with the current design system.

## Approval Gate

No data generation, database implementation, DDL, Python generator, or Power BI page build should begin until the fact grains, department catalog, selected organization mappings, time window, budget scenarios, and KPI definitions are approved.
