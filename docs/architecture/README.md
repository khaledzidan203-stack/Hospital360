# Hospital360 Architecture Summary

Hospital360 is a layered analytics platform built entirely with synthetic healthcare and hospital-enterprise data.

## End-to-end flow

```text
Synthea healthcare sources + deterministic enterprise sources
→ RAW source-preserving tables
→ STAGING typing, normalization, and DQ flags
→ ANALYTICS star schemas
→ read-only SQL and Python analysis
→ Power BI semantic model and report
→ reconciliation and release checks
```

## Healthcare layer

The healthcare pipeline loads patients, encounters, claims, claim transactions, conditions, and procedures. It preserves source grain through RAW, applies typed validation in STAGING, and publishes conformed patient, provider, organization, payer, condition, procedure, and date dimensions with five analytical facts.

The accepted working baseline contains 5,000 synthetic patients. See [source-to-target mapping](synthea_v1_source_to_target_mapping.md), [healthcare analytics star schema](analytics_star_schema.md), and [scale validation](portfolio_scale_validation.md).

## Enterprise extension

The deterministic 36-month extension adds Finance, Budget, Workforce, Operations, IT Incident, and IT System Daily facts. It reuses Date and Organization, adds governed Department and domain dimensions, and preserves the healthcare pipeline.

Healthcare activity is used only as an aggregated synthetic driver where required. Synthea claims are not treated as enterprise revenue or profitability, and enterprise facts do not contain Patient, Encounter, or Claim foreign keys.

See [enterprise implementation](enterprise_implementation.md), [enterprise star schema](enterprise_star_schema.md), and [generation rules](enterprise_generation_rules.md).

## Modeling principles

- Source-preserving RAW landing.
- Typed, validated, and traceable STAGING transformations.
- Surrogate keys and explicit Unknown-member handling.
- Dimension-to-fact, predominantly single-direction filtering.
- No direct fact-to-fact relationships.
- Reconciliation at each pipeline boundary.
- SQL, Python, and Power BI metrics evaluated at compatible grains.
- Claims activity and enterprise finance retain separate business meanings.

## Power BI semantic layer

The PBIP/PBIR project version-controls the semantic model, DAX measures, relationships, pages, and navigation.

The **current integrated release contains 13 pages and 12 Home tiles** across healthcare and enterprise performance. `powerbi_final_report_inventory.md` is intentionally retained as the historical **nine-page healthcare baseline**; the four enterprise pages and current integrated state are documented in [enterprise Power BI inventory](enterprise_powerbi_inventory.md).

The saved model also contains an explicit `analytics dim_date` alongside Power BI Auto Date/Time artifacts. That model-hygiene issue is documented in [Power BI Time-Intelligence Audit](POWER_BI_TIME_INTELLIGENCE_AUDIT.md); no destructive TMDL cleanup is performed without Power BI Desktop runtime regression.
