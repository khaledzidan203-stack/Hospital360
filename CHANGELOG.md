# Changelog

Hospital360 follows a concise Keep a Changelog-style record of major implementation and release milestones.

## [Unreleased]

### Added — 2026-10-06

- Project-focused README with the current Hospital360 architecture, validated release boundary, and approved overview infographic.
- Current project index, case study, technical walkthrough, and evidence map.
- Power BI Auto Date/Time audit documenting the safe remediation boundary without changing the validated PBIP/PBIR/TMDL core.
- Environment baseline and repository-structure notes.
- Clone-safe repository validator and GitHub Actions quality gate.
- Explicit distinction between repository-safe tests and local RAW-data acceptance checks.

### Changed — 2026-10-06

- Enterprise acceptance test now skips only its local RAW-manifest assertion when generated RAW evidence is absent, allowing clean-clone CI execution.
- Documentation now distinguishes the historical nine-page healthcare Power BI baseline from the current 13-page integrated release.
- Screenshot documentation now identifies the seven committed images as representative captures of the 13-page report.
- Presentation-asset documentation now points to the current Hospital360 infographic and its evidence boundary.

### Preserved

- PostgreSQL analytical logic, SQL transformation/analysis logic, Python analytical logic, PBIP/PBIR/TMDL model/report source, DAX, validated screenshots, and validated analytical results were not modified by this repository hardening pass.

## [1.0.0] - 2026-09-01

### Added

- Initial professional project structure and local Git foundation.
- Synthetic Synthea healthcare pipeline at the accepted 5,000-patient scale.
- PostgreSQL RAW, optimized STAGING V2, data-quality, and ANALYTICS layers.
- Validated SQL analysis and reconciliation framework.
- Reproducible healthcare and enterprise Python EDA notebooks.
- Thirteen-page Power BI healthcare and enterprise performance report.
- Synthetic Finance, Workforce, Operations, and IT enterprise extension.
- Final manual Power BI visual polish and navigation validation.
- Public README, documentation indexes, setup, security, and contribution guidance.
