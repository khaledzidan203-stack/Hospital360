# Hospital360 Enterprise Python Findings

**Status:** Validated reproducible EDA

**Notebook:** `notebooks/02_enterprise_performance_eda.ipynb`

## Scope and Disclosure

The notebook analyzes synthetic Finance, Budget, Workforce, Operations, and IT aggregates. It contains no real hospital patient or employee data, makes no clinical claims, and does not describe association as causation. Financial values are synthetic operating-activity measures, not audited statements.

## Execution Validation

- Code cells executed: 10/10.
- Execution errors: 0.
- Runtime: 17.716 seconds.
- Database access: read-only SELECT/WITH queries through the guarded connector.
- Database writes: 0.
- Outliers removed: 0.
- Embedded credentials or personal absolute paths: 0.

## Findings

- Monthly revenue and operating cost have non-identical seasonality and controlled noise.
- Payroll is the dominant workforce-linked cost; overtime and absence remain visible rather than being removed as outliers.
- Department profiles show distinct cost, activity, capacity, and waiting-time patterns.
- IT systems differ in usage and downtime while maintaining high generated uptime.
- Monthly correlations show intended positive, imperfect associations among activity, FTE, occupancy, overtime, and cost.

## Limitations

Correlations partly reflect generator assumptions and cannot validate causal mechanisms. Results demonstrate pipeline, modeling, visualization, and analytical methodology only.
