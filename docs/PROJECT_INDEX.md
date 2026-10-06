# Hospital360 Project Index

Hospital360 is a synthetic healthcare and hospital-enterprise analytics platform built around governed data grains, PostgreSQL analytical layers, SQL/Python validation, and a source-controlled Power BI PBIP/PBIR/TMDL report.

> **Data boundary:** all patient, claim, financial, workforce, operations, and IT data in this project is synthetic. No real hospital or patient data is included.

## Start here

| Need | Document |
|---|---|
| Project overview | [Repository README](../README.md) |
| Case study | [CASE_STUDY.md](CASE_STUDY.md) |
| 60–90 second technical walkthrough | [TECHNICAL_WALKTHROUGH.md](TECHNICAL_WALKTHROUGH.md) |
| Evidence behind project claims | [PROJECT_EVIDENCE_MAP.md](PROJECT_EVIDENCE_MAP.md) |
| Final release validation | [FINAL_RELEASE_VALIDATION.md](FINAL_RELEASE_VALIDATION.md) |
| Setup / reproduction | [SETUP.md](SETUP.md) |
| Architecture | [architecture/README.md](architecture/README.md) |
| KPI definitions | [kpi_dictionary/](kpi_dictionary/) |
| Dashboard captures | [screenshots/README.md](screenshots/README.md) |
| Power BI time-intelligence audit | [architecture/POWER_BI_TIME_INTELLIGENCE_AUDIT.md](architecture/POWER_BI_TIME_INTELLIGENCE_AUDIT.md) |
| Environment baseline | [ENVIRONMENT_BASELINE.md](ENVIRONMENT_BASELINE.md) |
| Repository structure notes | [REPOSITORY_STRUCTURE_NOTES.md](REPOSITORY_STRUCTURE_NOTES.md) |

## Current integrated release

- Validated working healthcare population: **5,000 synthetic patients**.
- Healthcare RAW rows: **5,515,928** across the six approved core sources.
- Healthcare analytics facts: **5** — Encounter, Claim, Claim Transaction, Condition Occurrence, Procedure.
- Enterprise extension: **36 months**, **25,716 fact rows**, **6 enterprise facts**.
- Database architecture: PostgreSQL `RAW → STAGING → ANALYTICS`.
- SQL regression at the accepted 5K scale: **47/47 queries successful**, **0 validation failures**.
- Enterprise DQ: **0 fatal errors**, **633 warnings**, **1,257 retained business anomalies**.
- Current Power BI report: **13 pages**, **12 Home navigation tiles**.
- Power BI source is version controlled as PBIP/PBIR/TMDL; the redundant PBIX binary is excluded.

## Two governed analytical domains

### Healthcare activity and claims

Synthea supplies synthetic patient, encounter, claim, transaction, condition, and procedure activity. Claims and claim transactions remain analytical healthcare activity and are **not** treated as a hospital profit-and-loss statement.

### Enterprise performance

A deterministic generator creates synthetic Finance, Budget, Workforce, Operations, IT Incident, and IT System Daily facts. Aggregated healthcare activity can act as a synthetic operating driver, but enterprise facts do not contain Patient, Encounter, or Claim foreign keys and are not joined fact-to-fact.

## Scale-testing boundary

A clean **20,000-patient** Synthea dataset was successfully generated and RAW-loaded. The full 20K pipeline was **not completed**: STAGING claims processing exposed a multi-hour I/O bottleneck. The accepted analytical working dataset therefore remains 5,000 patients. This is documented as a scalability finding, not presented as a completed 20K production run.

## Power BI documentation chronology

`architecture/powerbi_final_report_inventory.md` documents the **historical nine-page healthcare baseline**. The later enterprise implementation retained those nine pages and added four enterprise pages, producing the **current 13-page integrated release** documented in `architecture/enterprise_powerbi_inventory.md` and the saved PBIR source.

## Current model-hygiene note

The saved Power BI model has an explicit governed `analytics dim_date`, but Power BI Auto Date/Time is also still enabled and generated LocalDateTable objects remain in TMDL. No destructive model rewrite is performed in repository hardening without Power BI Desktop runtime regression. See the dedicated audit for the remediation boundary.
