# Hospital360 Architecture Summary

Hospital360 is a layered analytics platform built entirely with synthetic healthcare and hospital enterprise data.

## Data Flow

```text
Synthea healthcare sources + generated enterprise sources
→ RAW source-preserving tables
→ STAGING typing, normalization, and DQ flags
→ ANALYTICS star schemas
→ read-only SQL and Python analysis
→ Power BI semantic model and report
```

## Healthcare Layer

The healthcare pipeline loads patients, encounters, claims, claim transactions, conditions, and procedures. It preserves source grain through RAW, applies typed validation in STAGING, and publishes conformed patient, provider, organization, payer, condition, procedure, and date dimensions with five analytical facts.

See [source-to-target mapping](synthea_v1_source_to_target_mapping.md) and [healthcare analytics star schema](analytics_star_schema.md).

## Enterprise Extension

The deterministic 36-month extension adds Finance, Budget, Workforce, Operations, IT Incident, and IT System Daily facts. It reuses Date and Organization and adds governed Department and domain dimensions. Existing clinical activity is used only as an aggregated synthetic driver.

See [enterprise implementation](enterprise_implementation.md), [enterprise star schema](enterprise_star_schema.md), and [generation rules](enterprise_generation_rules.md).

## Modeling Principles

- Source-preserving RAW landing.
- Typed, validated, and traceable STAGING transformations.
- Surrogate keys and explicit Unknown-member handling.
- Dimension-to-fact, predominantly single-direction filtering.
- No direct fact-to-fact relationships.
- Reconciliation at each pipeline boundary.
- SQL and Power BI measures evaluated at compatible grains.

## Power BI Semantic Layer

The PBIP/PBIR project version-controls the semantic model, DAX measures, relationships, pages, and navigation. The final report contains 13 pages and 12 Home tiles across healthcare and enterprise performance domains.

See [final report inventory](powerbi_final_report_inventory.md) and [enterprise Power BI inventory](enterprise_powerbi_inventory.md).
