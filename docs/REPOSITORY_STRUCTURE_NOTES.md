# Repository Structure Notes

Hospital360 contains both active implementation paths and a small number of reserved placeholders created during the original project scaffold.

## Active implementation paths

- `sql/` — PostgreSQL DDL, staging, marts, validation, and analysis.
- `src/data_generation/` — deterministic enterprise generation and SQL execution helpers.
- `src/analytics/` — read-only Python analytical utilities and notebook support.
- `notebooks/` — reproducible healthcare and enterprise EDA.
- `powerbi/` — current PBIP/PBIR/TMDL report and semantic-model source.
- `docs/` — architecture, dictionaries, insights, governance, validation, and screenshots.
- `data/sample/enterprise/` — small synthetic examples safe for public version control.

## Reserved / inactive scaffold paths

The following paths are currently placeholders rather than separate runtime implementations:

- `app/`
- `src/ingestion/`
- `src/data_quality/`
- `src/transformation/`

The active ingestion, transformation, and data-quality logic is implemented primarily in the governed SQL RAW/STAGING/ANALYTICS pipeline and enterprise-generation modules. The placeholder directories are retained as historical scaffold boundaries and should not be interpreted as missing required pipeline components.

## Generated local data

`data/raw/` and `data/processed/` are intentionally ignored except for directory placeholders. Full synthetic datasets are generated locally and are not committed because of size and reproducibility/security hygiene.
