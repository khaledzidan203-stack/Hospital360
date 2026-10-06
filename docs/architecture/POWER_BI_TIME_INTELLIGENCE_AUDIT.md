# Power BI Time-Intelligence Audit

## Status

**Current saved state retained; model-hygiene remediation deferred until Power BI Desktop runtime regression is available.**

This is a documentation and governance decision, not an assertion that Auto Date/Time is the preferred final design.

## Observed current state

The source-controlled semantic model contains an explicit governed `analytics dim_date` table and date-key relationships from healthcare and enterprise facts. At the same time:

- `model.tmdl` records `__PBI_TimeIntelligenceEnabled = 1`;
- multiple `LocalDateTable_*` objects are present in TMDL;
- `relationships.tmdl` contains automatic date relationships from raw date/date-time columns to those LocalDateTable objects;
- the governed `analytics dim_date` is also used by explicit fact date-key relationships.

The model therefore has both a governed Date dimension and Power BI Auto Date/Time artifacts.

## Why the repository hardening does not delete them

Removing Auto Date/Time safely is more than changing one annotation. A complete cleanup may require removal or regeneration of LocalDateTable objects and relationships, and saved visuals or implicit date hierarchies may depend on them.

A destructive TMDL/PBIR rewrite is therefore outside a documentation-only hardening pass unless all of the following can be executed:

1. open the PBIP project in Power BI Desktop;
2. disable Auto Date/Time;
3. confirm visuals do not depend on implicit date hierarchies;
4. confirm explicit `analytics dim_date` relationships and time measures behave as intended;
5. refresh the model;
6. run DAX and navigation regression;
7. capture updated evidence and screenshots;
8. commit the resulting PBIP/PBIR/TMDL source together.

## Current governance rule

For governed analytical interpretation, use `analytics dim_date` and explicit KPI definitions. LocalDateTable artifacts should not be presented as the designed enterprise date model.

## Recommended future remediation

When a Power BI Desktop regression session is available, remove Auto Date/Time and its unused generated tables only after dependency verification. Until then, preserving the validated saved model is safer than editing TMDL text in isolation.
