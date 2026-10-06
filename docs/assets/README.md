# Presentation Assets

This directory contains presentation-only visual assets for Hospital360.

## Current overview

`Hospital360 Healthcare Analytics Infographic.png`

The main repository README uses this image as a concise visual summary of the implemented architecture and validated release boundary.

It summarizes repository-supported claims only:

- synthetic healthcare and enterprise data only;
- Synthea healthcare sources plus the deterministic enterprise generator;
- RAW → STAGING / Data Quality → governed analytics star schemas;
- PostgreSQL, SQL, Python analytics, and Power BI;
- validated 5,000-patient working dataset;
- approximately 5.52M healthcare RAW rows;
- 5 healthcare facts and 6 enterprise facts;
- 36 enterprise months;
- 13 Power BI report pages and 12 Home navigation tiles;
- a documented 20,000-patient scale-test boundary rather than a claimed completed 20K pipeline.

## Evidence boundary

This image is a presentation summary. It is not analytical source data, database evidence, a Power BI screenshot, or a substitute for governed validation records.

Authoritative project claims are mapped in [`../PROJECT_EVIDENCE_MAP.md`](../PROJECT_EVIDENCE_MAP.md) and remain grounded in repository source code, SQL, PBIP/PBIR/TMDL, architecture records, and validation evidence.
