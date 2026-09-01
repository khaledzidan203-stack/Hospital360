# Hospital360 Enterprise KPI Dictionary

**Implementation status:** Validated Enterprise V1

## Semantic Model Governance

The implementation adds 45 enterprise measures to `_Measures`, organized under Enterprise Finance, Enterprise Workforce, Enterprise Operations, and Enterprise IT. It does not alter the 46 validated healthcare measures. Enterprise finance KPIs use only the new Finance and Budget facts; Synthea claims and transactions are never used to calculate revenue, operating margin, or budget variance.

**Status: Candidate KPIs — To Be Validated Before Implementation**

## Governance Rules

- All KPIs use synthetic data and demonstrate analytical methodology only.
- Rates and averages use additive numerators and denominators; row-level percentages are not averaged.
- Monthly snapshot measures such as FTE, headcount, staffed beds, and active users are not summed across time.
- Cross-domain KPIs are evaluated through conformed Date, Organization, and Department dimensions, never a fact-to-fact relationship.
- Existing claim and transaction measures are not hospital revenue, profit, EBITDA, margin, ROI, or cash flow.

## Finance KPIs

| KPI Name | Business Definition | Formula | Source Fact | Grain | Filters | Unit | Directionality | Expected Range | Cautions / Limitations |
|---|---|---|---|---|---|---|---|---|---|
| Actual Operating Cost | Synthetic operating expense incurred | `SUM(actual_operating_cost)` | Finance Monthly | Cost category / department / month | Date, Organization, Department, Cost Category | Amount | Lower is not automatically better | Department-dependent | Not audited cost accounting or P&L. |
| Budget | Approved synthetic operating-cost plan | `SUM(budget_operating_cost)` for selected scenario | Budget Monthly | Scenario / department / month | Date, Organization, Department, Budget Scenario | Amount | Contextual | Positive planned value | Scenario selection is mandatory. |
| Budget Variance | Difference between actual cost and budget | `Actual Operating Cost - Budget` | Finance Monthly + Budget Monthly | Shared department/month context | Date, Organization, Department, Scenario | Amount | Lower / negative favorable for cost | Commonly ±15% of budget | Facts remain independent; compare only at shared grain. |
| Budget Variance % | Variance relative to budget | `Budget Variance / Budget` | Finance Monthly + Budget Monthly | Shared department/month context | Same as above | % | Lower is favorable for cost | Usually -15% to +15% | Blank when budget is zero or absent. |
| Budget Achievement % | Actual cost relative to budget | `Actual Operating Cost / Budget` | Finance Monthly + Budget Monthly | Shared department/month context | Same as above | % | Near 100% is on plan | Usually 85%–115% | Above 100% is unfavorable for a cost budget; label clearly. |
| Cost per Encounter | Operating cost per allocated encounter | `Actual Operating Cost / SUM(Operations[encounter_count])` | Finance Monthly + Operations Daily | Department/month after date alignment | Date, Organization, Department | Amount per encounter | Lower may be favorable only with quality/context | Department-dependent | Not patient-level costing; exclude zero-encounter denominators. |
| Payroll Cost % | Share of operating cost in payroll category | `Payroll-category Actual Operating Cost / Actual Operating Cost` | Finance Monthly | Department/month | Date, Organization, Department | % | Contextual | Approximately 35%–75% | Category definition must remain governed. |
| Department Cost Share | Department share of selected operating cost | `Department Actual Operating Cost / Cost with Department filter removed` | Finance Monthly | Department within filter context | Date, Organization, Cost Category | % | Concentration indicator | 0%–100% | Not efficiency or value contribution. |

## HR / Workforce KPIs

| KPI Name | Business Definition | Formula | Source Fact | Grain | Filters | Unit | Directionality | Expected Range | Cautions / Limitations |
|---|---|---|---|---|---|---|---|---|---|
| Headcount | End-of-period synthetic workforce headcount | `SUM(headcount_end)` for latest month in context | Workforce Monthly | Department/role/month snapshot | Date, Organization, Department, Role | People | Contextual | Non-negative | Semi-additive; do not sum monthly snapshots. |
| FTE | End-of-period full-time-equivalent workforce | `SUM(fte_end)` for latest month in context | Workforce Monthly | Department/role/month snapshot | Same | FTE | Contextual | `0 ≤ FTE ≤ Headcount` normally | Semi-additive across time. |
| Average FTE | Time-weighted workforce denominator | `SUM(average_fte)` for selected period grain | Workforce Monthly | Department/role/month | Same | FTE | Contextual | Positive for active departments | Across multiple months, use average or time-weighted logic, not sum. |
| Overtime Hours | Hours worked above scheduled regular capacity | `SUM(overtime_hours)` | Workforce Monthly | Department/role/month | Date, Organization, Department, Role | Hours | Lower generally favorable | Non-negative | Some overtime is operationally necessary. |
| Overtime Rate | Overtime share of worked hours | `SUM(overtime_hours) / SUM(worked_hours)` | Workforce Monthly | Shared filter context | Same | % | Lower generally favorable | Typically 0%–12%; review >15% | Not a direct quality measure. |
| Absence Rate | Absence hours relative to scheduled hours | `SUM(absence_hours) / SUM(scheduled_hours)` | Workforce Monthly | Shared filter context | Same | % | Lower generally favorable | Typically 1%–8%; review >10% | Synthetic attendance, not employee records. |
| Turnover Rate | Separations relative to average headcount | `SUM(separations) / AVERAGE_OR_TIME_WEIGHTED(average_headcount)` | Workforce Monthly | Department/role/period | Date, Organization, Department, Role | % | Lower generally favorable | Monthly usually 0%–3% | Annualize only with explicit methodology. |
| Payroll Cost | Synthetic workforce payroll expense | `SUM(payroll_cost)` | Workforce Monthly | Department/role/month | Same | Amount | Contextual | Positive | Must reconcile to Finance payroll category within approved tolerance; not personal payroll data. |
| Encounters per FTE | Allocated encounter activity per average FTE | `SUM(Operations[encounter_count]) / Average FTE` | Operations Daily + Workforce Monthly | Department/month | Date, Organization, Department | Encounters per FTE | Contextual | Department-dependent | Not productivity without case mix, service hours, quality, and capacity context. |

## Operations / Capacity KPIs

| KPI Name | Business Definition | Formula | Source Fact | Grain | Filters | Unit | Directionality | Expected Range | Cautions / Limitations |
|---|---|---|---|---|---|---|---|---|---|
| Staffed Beds | Beds staffed and available for service | Latest/average `staffed_beds` in context | Operations Daily | Department/day snapshot | Date, Organization, Department | Beds | Contextual | 0 to licensed beds | Semi-additive; ambulatory departments may be zero. |
| Occupancy Rate | Used bed-days relative to available bed-days | `SUM(occupied_bed_days) / SUM(available_bed_days)` | Operations Daily | Department/period | Date, Organization, Department | % | Target band, not simply higher/lower | Usually 55%–95%; flagged overflow may reach 105% | Use only bed-capacity departments; >100% requires overflow flag. |
| Admissions | Synthetic admitted cases | `SUM(admissions)` | Operations Daily | Department/day | Date, Organization, Department | Count | Contextual | Non-negative | Not equal to all encounters. |
| Discharges | Synthetic completed inpatient stays | `SUM(discharges)` | Operations Daily | Department/day | Same | Count | Contextual | Non-negative | Daily admissions and discharges need not match. |
| Average Length of Stay | Discharge-weighted average stay | `SUM(length_of_stay_days_total) / SUM(discharged_with_los_count)` | Operations Daily | Department/period | Same | Days | Lower may be favorable only with outcome/context | Often 1.5–8 days | Not computed for ambulatory departments; no quality inference. |
| Bed Turnover | Discharges per staffed bed over period | `SUM(discharges) / AVERAGE(staffed_beds)` | Operations Daily | Department/period | Same | Discharges per bed | Contextual | Service-dependent | Requires a clearly labeled period and snapshot denominator. |
| Average Waiting Time | Weighted mean waiting time | `SUM(wait_minutes_total) / SUM(waited_encounter_count)` | Operations Daily | Department/period | Same | Minutes | Lower favorable | Usually 5–120 minutes | Compare like services; not patient-level wait records. |
| Appointment Utilization | Completed appointments relative to available slots | `SUM(appointments_completed) / SUM(appointment_slots)` | Operations Daily | Department/period | Same | % | Higher generally favorable within capacity | Typically 65%–95% | Exclude zero-slot bed-only departments. |

## IT / Technology KPIs

| KPI Name | Business Definition | Formula | Source Fact | Grain | Filters | Unit | Directionality | Expected Range | Cautions / Limitations |
|---|---|---|---|---|---|---|---|---|---|
| Uptime % | Available scheduled service time | `SUM(available_minutes) / SUM(scheduled_minutes)` | IT System Daily | System/department/period | Date, Organization, Department, IT System | % | Higher favorable | Usually 98.5%–99.99% | Weight by scheduled minutes; do not average daily percentages. |
| Downtime Minutes | Planned and unplanned unavailable time | `SUM(downtime_minutes)` | IT System Daily | System/department/day | Same | Minutes | Lower favorable | Non-negative; ≤ scheduled minutes | Separate planned and unplanned views where relevant. |
| Unplanned Downtime Minutes | Unscheduled unavailable time | `SUM(unplanned_downtime_minutes)` | IT System Daily | System/department/day | Same | Minutes | Lower favorable | Usually low with deliberate outage spikes | Incident downtime may not reconcile one-to-one because incidents overlap. |
| Incident Count | Number of synthetic incidents opened | `COUNTROWS(Fact_IT_Incident)` | IT Incident | Incident/open date | Date, Organization, Department, System, Category, Severity | Count | Lower generally favorable | Approximately 2,000–3,000 total | Higher volume may reflect exposure or reporting behavior. |
| SLA Compliance % | Resolved incidents completed within SLA | `Resolved-within-SLA incidents / Resolved incidents` | IT Incident | Incident/opened or resolved period, explicitly labeled | Same | % | Higher favorable | Commonly 80%–98% | Exclude unresolved incidents; date role must be explicit. |
| Mean Resolution Time | Average resolution duration for resolved incidents | `SUM(resolution_minutes) / Resolved incident count` | IT Incident | Incident | Same | Minutes | Lower favorable | Severity-dependent | Report by severity/category; skewed distribution makes median useful in Python. |
| Critical Incident Rate | P1/P2 share of incidents | `P1 or P2 Incident Count / Incident Count` | IT Incident | Incident | Same | % | Lower favorable | Approximately 9%–17% under proposed mix | Synthetic severity distribution; not real risk. |
| System Usage Transactions | Synthetic system interactions | `SUM(transaction_count)` | IT System Daily | System/department/day | Date, Organization, Department, IT System | Count | Contextual | System-dependent | Not Synthea claim transactions and not financial transactions. |
| Tickets per 100 FTE | Incident volume normalized by average workforce | `Incident Count / Average FTE × 100` | IT Incident + Workforce Monthly | Department/month | Date, Organization, Department | Tickets per 100 FTE | Lower generally favorable | Department-dependent | Requires month alignment; exposure measure, not staff performance. |

## KPI Validation Requirements

Before implementation approval:

1. Confirm every formula at its native grain.
2. Confirm all denominators exclude invalid/zero contexts safely.
3. Confirm scenario filtering for budget KPIs.
4. Confirm snapshot handling for headcount, FTE, beds, and users.
5. Confirm active and role-playing date behavior.
6. Reconcile payroll across Workforce and Finance within the approved tolerance.
7. Confirm no claim activity is labeled revenue or profit.
8. Validate KPI ranges on 1-, 3-, and 12-month samples before final generation.
