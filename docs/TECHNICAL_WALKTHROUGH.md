# Hospital360 Technical Walkthrough

## 60–90 second version

**0–10 seconds — Scope**

Hospital360 is an end-to-end synthetic hospital analytics platform. It combines healthcare activity and claims with separately generated Finance, Workforce, Operations, and IT performance data. No real patient or hospital data is used.

**10–25 seconds — Data engineering**

Synthea and the deterministic enterprise generator feed a PostgreSQL architecture with source-preserving RAW, typed STAGING with data-quality flags, and governed ANALYTICS star schemas. Facts stay at their native grains and are not joined fact-to-fact.

**25–40 seconds — Healthcare baseline**

The accepted analytical baseline is 5,000 synthetic patients and 5.52 million RAW rows. RAW-to-STAGING and STAGING-to-fact reconciliations are exact at the validated scale, and the SQL regression framework completed 47 of 47 queries successfully.

**40–55 seconds — Enterprise extension**

The enterprise layer adds 36 months and 25,716 fact rows across Finance, Budget, Workforce, Operations, IT incidents, and IT system activity. Claims are never presented as hospital revenue; enterprise finance remains a separate governed model.

**55–70 seconds — BI delivery**

Power BI is stored as PBIP/PBIR/TMDL source. The current integrated report has 13 pages and 12 Home navigation tiles across healthcare and enterprise performance.

**70–90 seconds — Validation and engineering boundary**

A clean 20,000-patient source was generated and RAW-loaded, but STAGING exposed an I/O scalability bottleneck, so the full 20K pipeline is not claimed as completed. The project preserves that limitation and uses the fully validated 5K pipeline as the working release.

## Suggested review order

1. Main `README.md`
2. `docs/CASE_STUDY.md`
3. `docs/PROJECT_EVIDENCE_MAP.md`
4. `docs/architecture/README.md`
5. `docs/architecture/portfolio_scale_validation.md`
6. `docs/screenshots/README.md`
7. `docs/SETUP.md`

## Guardrails

- All data is synthetic.
- Synthea claims are not hospital revenue or profit.
- Enterprise finance is generated separately.
- 20K is a documented scale test boundary, not a completed end-to-end release.
- Historical nine-page Power BI documentation is a healthcare baseline; the current integrated report contains 13 pages.
- Auto Date/Time remains enabled in the saved model and is documented as a model-hygiene item pending Power BI Desktop regression before any destructive cleanup.
