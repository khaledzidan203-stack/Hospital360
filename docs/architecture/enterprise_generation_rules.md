# Hospital360 Enterprise Synthetic Generation Rules

**Status: Implemented and Validated — Master Seed 20260831**

## Objective

Generate a compact, reproducible enterprise dataset whose domains are related through plausible drivers rather than independent random numbers. Relationships must be visible but imperfect, with controlled seasonality, lags, heterogeneity, and noise.

## Reproducibility

- Use one documented master seed and deterministic child seeds by domain.
- Keep configuration values outside generated records and version them.
- Generate dimensions and valid combination catalogs before facts.
- Re-running the same version, seed, time window, and input clinical snapshot must reproduce identical output.
- Record generator version, seed, run ID, accepted time window, and source aggregate counts.

## Enterprise Scope Setup

1. Select three existing synthetic organizations with sufficient activity in the 36-month period.
2. Create 12 departments mapped to those organizations: eight clinical/capacity-managed and four non-clinical/shared-service departments.
3. Approve valid department-role combinations and eight IT system-department coverage pairs.
4. Aggregate existing encounters and procedures by Date and Organization.
5. Allocate aggregates to departments using encounter class, procedure mix, stable weights, and seeded multinomial variation.
6. Preserve aggregate totals where allocation is intended to reconcile; keep the allocation mapping as generation audit metadata.

## Shared Driver Framework

For department `d` and period `t`, define standardized drivers:

- `activity_index`: smoothed allocated encounters and procedures
- `capacity_pressure`: occupied capacity / available capacity
- `workforce_index`: average FTE relative to baseline
- `complexity_index`: governed department-type and procedure-mix factor
- `season_index`: month, day-of-week, and holiday effects where relevant
- `technology_exposure`: activity × workforce × system coverage

Final values use a bounded combination of baseline, driver effects, autoregressive continuity, and random noise. No output measure should equal a simple fixed multiple of another domain measure across all periods.

## Finance Rules

### Baselines

- Base monthly cost differs by department type and organization size.
- Payroll, Clinical Supplies, Pharmaceuticals, Facilities, and Technology & Other use distinct cost behavior.
- Fixed cost changes slowly; variable cost responds to activity; allocated shared cost follows a governed allocation basis.

### Variability and Seasonality

- Monthly inflation drift: approximately 2%–5% annualized in the synthetic scenario.
- Variable categories respond to a three-month smoothed activity index with elasticity below 1.0.
- Facilities include mild seasonal effects; technology includes scheduled renewal months.
- Noise is autocorrelated and category-specific, normally about ±2%–8% after bounds.

### Cross-Domain Logic

- Payroll-category actual cost reconciles to aggregated workforce payroll by department/month within ±0.5% rounding/allocation tolerance.
- Clinical supplies and pharmaceutical costs have positive, imperfect relationships with encounters/procedures.
- Facilities and technology costs are less activity-sensitive.
- Cost per encounter must be derived analytically, not generated directly.

### Deliberate Anomalies

- One controlled supply-cost spike.
- One technology renewal month.
- Two department-months with unfavorable operating-cost variance above 15%.
- One cost reduction period following a prior pressure period.

### Prohibited Relationships

- Do not equate claim amount, transaction amount, or payer coverage with revenue.
- Do not force every higher-activity month to have higher total cost.
- Do not generate cost as a patient-level or encounter-level record.

## Budget Rules

### Original Scenario

- Uses prior six-month smoothed cost and activity, approved staffing plan, inflation, and small efficiency assumptions.
- Is fixed for each budget month once generated.

### Forecast Scenario

- Uses information available through the simulated forecast cutoff.
- Moves partway toward current run rate; it must not equal actual cost.
- Includes bounded forecast error with realistic persistence.

### Stretch Scenario

- Applies a 2%–6% controlled reduction to controllable operating assumptions while preserving minimum staffing/capacity constraints.

### Deliberate Anomalies

- One forecast revision caused by a capacity-pressure period.
- One capital-plan month with a planned technology increase.
- One department with persistent but plausible unfavorable variance.

## Workforce Rules

### Baselines

- Minimum role coverage is defined by department type and operating schedule.
- FTE demand uses a three-month smoothed activity index, capacity, role productivity factors, and minimum coverage.
- Headcount is at least ceiling(FTE) for most role groups, allowing part-time mix.

### Dynamics

- Month-to-month FTE change is normally capped at ±5%; exceptional hiring programs may reach ±10%.
- Hires and separations update headcount with consistent arithmetic.
- Staffing response lags demand by one to three months.
- Payroll uses FTE, role pay bands, overtime premiums, and bounded wage drift.

### Realistic Ranges

- FTE per active department-role: normally 0.5–80 depending on scope.
- Overtime: typically 0%–12% of worked hours; deliberate peaks up to 20%.
- Absence: typically 1%–8% of scheduled hours; deliberate peaks up to 12%.
- Monthly separations: usually 0%–3% of average headcount.

### Deliberate Anomalies

- One overtime spike following high capacity pressure.
- One short absence cluster.
- One delayed hiring response producing temporary productivity pressure.
- One turnover cluster in a non-critical synthetic role group.

### Prohibited Relationships

- Do not create individual employees or map all workforce roles to providers.
- Do not force perfect negative correlation between staffing and waiting time.
- Do not delete high overtime or absence observations; classify them as Business Anomalies.

## Operations Rules

### Baselines

- Licensed and staffed capacity vary by department type and organization.
- Daily encounters start from existing aggregate clinical activity allocated to departments.
- Admissions/discharges apply only to appropriate department types.
- Appointment slots apply to ambulatory/diagnostic areas; bed measures may be zero there.

### Variability and Seasonality

- Day-of-week patterns differ for emergency, inpatient, ambulatory, and diagnostic departments.
- Monthly seasonality is mild and consistent with the synthetic encounter anchor.
- Occupied bed-days depend on admissions, prior census, discharges, and average stay dynamics.
- Waiting time rises nonlinearly when capacity pressure exceeds approximately 85%, but noise and staffing response prevent a deterministic curve.

### Realistic Ranges

- Normal occupancy: 55%–95%; controlled overflow may reach 105% only with `overflow_capacity_flag = true`.
- Average length of stay: generally 1.5–8 days for applicable inpatient departments.
- Appointment utilization: commonly 65%–95%.
- Average wait: typically 5–120 minutes by service; deliberate pressure events may be higher.

### Deliberate Anomalies

- A short occupancy-pressure event.
- An appointment-cancellation period.
- A waiting-time spike with partial staffing recovery.
- One valid overflow-capacity episode explicitly flagged.

### Prohibited Relationships

- Do not force admissions to equal encounters.
- Do not force daily discharges to equal admissions.
- Do not compute ALOS as an average of daily averages; retain numerator and denominator.

## IT System Daily Rules

### Baselines

- Six systems have distinct criticality, target uptime, operating schedules, usage baselines, and reliability.
- Only eight approved system-department pairs are generated.
- Usage depends on department activity, workforce, appointments, weekday, and system function.

### Availability

- `available_minutes = scheduled_minutes - downtime_minutes`.
- `downtime_minutes = planned_downtime_minutes + unplanned_downtime_minutes`.
- Tier 1 systems normally achieve 99.5%–99.99% monthly uptime; lower tiers may range 98.5%–99.9%.
- Planned maintenance is concentrated in approved windows.

### Usage

- Transaction count is a synthetic system-usage count and must not be confused with claim transactions.
- Active users and peak concurrent users are bounded by workforce/department scale but include variability.
- Usage may increase without reducing uptime; no forced causal relation is assumed.

### Deliberate Anomalies

- One major unplanned outage.
- Two smaller performance-degradation periods.
- One usage surge during a capacity-pressure event.
- One planned maintenance event that remains within SLA.

## IT Incident Rules

### Arrival and Classification

- Incident arrival uses a seeded count process with rate driven by system exposure, criticality, change windows, and recent reliability.
- Severity mix target: P1 1%–2%, P2 8%–15%, P3 45%–60%, P4 remainder.
- Category depends probabilistically on system domain; it is not assigned independently.

### Resolution and SLA

- Resolution time follows severity- and category-specific skewed distributions.
- Open incidents have null resolved timestamp and SLA flag.
- Resolved timestamp must be on/after opened timestamp.
- Incident downtime contributes to, but need not equal, system-daily unplanned downtime because incidents may overlap or not affect full availability.

### Deliberate Anomalies

- One P1 outage incident aligned with the major daily outage.
- A short cluster of related integration incidents.
- Several valid SLA breaches across severity levels.
- One long-running open P3 incident at final cutoff.

### Prohibited Relationships

- Do not force every downtime period to create exactly one incident.
- Do not force every incident to cause downtime.
- Do not make incident count a fixed proportion of usage.

## Correlation Expectations

| Pair | Expected direction | Target strength | Caution |
|---|---|---|---|
| Activity ↔ variable operating cost | Positive | Moderate | Fixed cost and noise prevent a perfect relationship. |
| Activity ↔ workforce demand | Positive with lag | Moderate | Minimum staffing and hiring delay weaken contemporaneous correlation. |
| Capacity pressure ↔ waiting time | Positive, nonlinear | Moderate | Department type and staffing also matter. |
| FTE ↔ payroll cost | Positive | Strong but not perfect | Role mix and overtime affect payroll. |
| IT exposure ↔ usage | Positive | Moderate to strong | System function and schedule differ. |
| Usage ↔ incidents | Weak positive | Weak | Reliability and change events dominate some periods. |
| Incidents ↔ downtime | Positive | Moderate | Not all incidents cause outages; outages may overlap. |
| Budget ↔ actual cost | Positive | Strong but imperfect | Forecast error and anomalies must remain. |

## Validation by Scale

### One Month

- Confirm every valid dimension/combination appears as intended.
- Verify formulas, arithmetic, keys, and no Cartesian expansion.
- Review distributions and all deliberate anomalies manually.

### Three Months

- Confirm continuity, headcount roll-forward, lag behavior, and incident/date logic.
- Validate monthly aggregation and reload determinism.

### Twelve Months

- Validate seasonality, annual totals, budget comparisons, rate denominators, and correlation ranges.
- Benchmark generation, ingestion, and transformations.

### Final 36 Months

- Generate only after prior gates pass.
- Reconcile row counts and native-grain measures through RAW, STAGING, and ANALYTICS.
- Run SQL regression, Python EDA, and Power BI validation before the Git milestone.
