# Hospital360 Enterprise SQL Findings

**Status:** Validated synthetic enterprise baseline

**Scope:** 2023-08-01 through 2026-07-31

These findings demonstrate analytical methodology on generated portfolio data. They do not describe a real hospital, workforce, financial ledger, or technology environment. Associations do not establish causation.

## Reconciled Baseline

- Operating revenue: **$5,341,901.89**.
- Operating cost: **$130,140,655.86**.
- Operating margin: **-$124,798,753.97**.
- Original budget revenue: **$5,632,376.94**; budget operating cost: **$133,119,595.11**.
- Workforce payroll: **$93,895,820.95**; overtime: **46,098.49 hours**; absence: **62,321.85 hours**.
- Latest-month headcount: **360**; FTE: **296.46**.
- Operational encounters: **3,891**; admissions: **648**; discharges: **2,159**.
- Appointment completion: **99.0739%**; weighted mean wait: **41.24 minutes**.
- IT transactions: **2,184,072**; downtime: **7,576 minutes**; weighted uptime: **99.9374%**.
- IT incidents: **2,132**, including **38 P1 incidents**; resolved SLA compliance: **53.5899%**.

## Major Findings

1. Payroll is the dominant generated cost component, consistent with the workforce-driven design.
2. Inpatient / Medical has the largest department cost at $16.24M and the largest allocated encounter volume at 1,085.
3. ICU, Emergency, and Surgery each carry approximately $16.23M of operating cost, showing deliberate clinical cost concentration.
4. P1 events are rare at 38 of 2,132 incidents (1.78%); P3 is largest with 1,151 incidents.
5. Electronic Health Record usage dominates system volume at 1,293,716 transactions.
6. Enterprise Resource Planning has the lowest weighted uptime at 99.8752%, within the generated reliability range.
7. Original budget exceeds actual revenue and cost in aggregate; department/month results include favorable and unfavorable variance.
8. Accepted generation correlations are positive but imperfect: 0.1929 for activity/FTE and 0.2739 for activity/variable cost.

## Data Quality and Interpretation

Fatal DQ errors are zero. The pipeline preserves 633 warnings and 1,257 business anomalies. The negative aggregate margin is a property of this synthetic scenario, not a conclusion about a real institution, and the amounts are not audited financial statements. Cross-domain comparisons aggregate each fact independently to conformed Date, Organization, and Department context.
