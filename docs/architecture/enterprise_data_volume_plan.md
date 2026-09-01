# Hospital360 Enterprise Data Volume Plan

**Status: Implemented and Validated — Final 36-Month Snapshot**

## Recommended Time Window

Use **2023-08-01 through 2026-07-31**:

- 36 complete calendar months
- 1,096 calendar days
- recent enough for meaningful monthly, annual, and rolling comparisons
- fully compatible with the existing continuous `analytics.dim_date`
- avoids extending enterprise records across the century-scale synthetic patient history
- avoids an incomplete August 2026 reporting month

## Scope Assumptions

- Three selected existing synthetic organizations
- 12 governed departments: eight clinical/capacity-managed and four non-clinical/shared-service departments
- Five operating-cost categories
- Three budget scenarios
- Approximately 60 valid department-role combinations
- Six IT systems with eight governed system-department coverage pairs
- Six incident categories

## Final Row Plan

| Dataset | Calculation | Expected rows |
|---|---|---:|
| Finance Monthly | 12 departments × 36 months × 5 cost categories | 2,160 |
| Budget Monthly | 12 departments × 36 months × 3 scenarios | 1,296 |
| Workforce Monthly | ~60 valid department-role combinations × 36 months | ~2,160 |
| Operations Daily | 8 managed departments × 1,096 days | 8,768 |
| IT Incidents | Stochastic incident events across 36 months | 2,000–3,000 |
| IT System Daily | 8 system-department coverage pairs × 1,096 days | 8,768 |
| **Total new fact rows** |  | **25,152–26,152** |

Dimension and small configuration rows are expected to remain below 100 and do not materially affect the total.

## Progressive Scale Volumes

| Gate | Approximate fact rows | Purpose |
|---|---:|---|
| 1 month | 690–730 | Validate schema, keys, arithmetic, and driver relationships quickly |
| 3 months | 2,070–2,190 | Validate continuity, lags, seasonality setup, and reload behavior |
| 12 months | 8,380–8,720 | Validate annual trends, performance, outliers, and reconciliation |
| 36 months final | 25,152–26,152 | Portfolio analytical dataset |

Incident counts remain stochastic within controlled bounds, so totals are ranges rather than fixed promises until the seed and acceptance gate are approved.

## Volume Controls

- Do not generate employee-level payroll, shift-level staffing, patient-level costing, bed-level occupancy, minute-level system telemetry, or log-event data.
- Generate monthly summaries for Finance, Budget, and Workforce.
- Generate daily summaries only where daily operational or availability patterns are analytically necessary.
- Limit IT System Daily to governed system-department coverage pairs rather than a full system × department cross join.
- Generate IT incidents as events, not expanded status-history snapshots.
- Reject accidental Cartesian products during every scale gate.

## Acceptance Gates

At each scale:

1. Actual row counts reconcile to the valid combination catalog and time window.
2. Every fact grain is unique.
3. Required Date, Organization, Department, and domain-dimension references resolve.
4. DQ Error count is zero before promotion.
5. Warning and Business Anomaly counts are explained.
6. Payroll, capacity, availability, and budget arithmetic reconcile.
7. Runtime and storage remain suitable for local development.
8. Correlations are directionally plausible without becoming deterministic.

## Hard Limit

The Enterprise V1 generation must remain below **40,000 fact rows**. Any design change projected to exceed that ceiling requires a documented review before generation.
