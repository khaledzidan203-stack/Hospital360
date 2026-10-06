# Hospital360 Case Study

## Problem

Hospital analytics rarely live at one grain. Patient activity, claims, workforce, budgets, capacity, and IT reliability describe different business processes and can produce misleading totals when flattened or joined directly.

Hospital360 was built to demonstrate how those domains can coexist inside one analytical platform without pretending that they have one financial or operational meaning.

## Data strategy

The project deliberately separates two synthetic source families:

1. **Healthcare activity** from Synthea — patients, encounters, claims, claim transactions, conditions, and procedures.
2. **Enterprise performance** from a deterministic generator — Finance, Budget, Workforce, Operations, IT Incident, and IT System Daily data.

All data is synthetic. The project contains no real hospital, patient, employee, or financial records.

## Engineering architecture

```text
Synthea healthcare sources ─┐
                           ├→ RAW → STAGING + DQ → ANALYTICS star schemas
Enterprise generator ──────┘                       ↓
                                    PostgreSQL + SQL validation
                                                ↓
                                      Python analytical layer
                                                ↓
                                  Power BI semantic model + DAX
                                                ↓
                                   13-page management report
```

RAW preserves source meaning. STAGING applies typing, normalization, and DQ flags. ANALYTICS publishes dimensional models with surrogate keys and controlled Unknown members. Facts remain at native grains and do not have direct fact-to-fact relationships.

## Healthcare implementation

The accepted working dataset contains exactly **5,000 synthetic patients** and **5,515,928 RAW rows** across the six approved core sources. The five healthcare analytical facts contain:

- 253,563 encounters;
- 435,751 claims;
- 3,966,064 claim transactions;
- 159,348 condition occurrences;
- 696,202 procedures.

RAW-to-STAGING and STAGING-to-fact reconciliation differences are zero for the validated 5K baseline. The SQL framework executed **47/47 queries successfully** with zero validation failures.

## Enterprise extension

The enterprise extension covers **36 complete months** from 2023-08-01 through 2026-07-31. Its six facts contain **25,716 rows** across Finance, Budget, Workforce, Operations, IT Incident, and IT System Daily activity.

Generation was progressive — 1, 3, 12, then 36 months — before the final snapshot entered PostgreSQL. The accepted extension records **0 fatal DQ errors**, while retaining **633 warnings** and **1,257 business anomalies** for analysis rather than silently deleting them.

## Critical modeling boundary

Synthea claim and transaction values are not treated as hospital revenue, margin, or an audited P&L. Enterprise finance is generated separately. Healthcare activity can be used as an aggregated synthetic operating driver, but enterprise facts have no Patient, Encounter, Claim, or fact-to-fact foreign keys.

This separation is one of the central governance controls of the project.

## Scalability finding

A clean **20,000-patient** Synthea dataset was successfully generated with overflow disabled, accepted, and loaded to RAW. The 20K STAGING claims transformation then remained active for multiple hours with PostgreSQL `DataFileRead` I/O waits and no blocking backend.

The 20K pipeline was therefore **not described as completed**. The working analytical scale was deliberately reduced to 5,000 patients so the complete pipeline could be validated locally. The finding is retained as an engineering scalability boundary rather than hidden as a failed experiment.

## Power BI delivery

The saved PBIP/PBIR project contains the current **13-page** integrated report and **12 Home navigation tiles**. The original healthcare release contributed nine pages; four enterprise pages were added for Financial Performance, Workforce Performance, Operations & Capacity, and Technology Performance.

PBIP/PBIR/TMDL source is version controlled. The large redundant PBIX binary and local Power BI caches are excluded from Git.

## Validation philosophy

Validation is performed at different boundaries rather than reduced to one generic PASS flag:

- source-to-RAW row parity;
- RAW-to-STAGING reconciliation;
- STAGING-to-ANALYTICS reconciliation;
- surrogate-key and fact-grain checks;
- broken-reference checks;
- financial reconciliation;
- read-only SQL regression;
- deterministic enterprise-generation tests;
- PBIR/TMDL structure and navigation evidence;
- explicit analytical limitations in the report and documentation.

## Outcome

Hospital360 demonstrates a governed end-to-end analytical system rather than a collection of unrelated dashboards: synthetic source generation, layered data engineering, dimensional modeling, data quality, SQL/Python analysis, Power BI semantic engineering, reproducibility, validation, and documented scale limits are all treated as parts of the same system.
