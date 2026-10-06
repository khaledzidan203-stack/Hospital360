# Hospital360 Environment Baseline

Hospital360 is designed for a local Windows analytical development environment. The repository publishes a dependency contract rather than claiming a byte-for-byte locked runtime for the multi-gigabyte generated RAW dataset.

## Required platform components

- Python 3
- PostgreSQL 16 with `psql`
- Power BI Desktop with PBIP/PBIR/TMDL support
- Git
- Java 21 only when regenerating Synthea data

## Python dependency contract

`requirements.txt` defines supported minimum package versions for the analytical notebooks and generators. These lower bounds intentionally allow compatible patch/minor updates; they are not presented as an exact historical lock file.

For a controlled local reproduction, create a dedicated virtual environment and retain the resolved environment alongside local run evidence:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m pip freeze > environment-resolved.txt
```

`environment-resolved.txt` is local run evidence and does not need to replace the repository's portable dependency contract.

## Data reproducibility boundary

The full Synthea RAW snapshot is multi-gigabyte and excluded from Git. Reproducing the healthcare pipeline therefore requires regenerating the synthetic source with the documented configuration before running the SQL pipeline.

The accepted 5K baseline and the 20K scale-test boundary are documented in `architecture/portfolio_scale_validation.md`.

The enterprise generator is deterministic through the documented master seed and 36-month profile. Public sample enterprise files are available under `data/sample/enterprise/`.

## CI boundary

Repository CI can validate committed structure, clone-safe tests, Python syntax, Power BI source structure, and documentation contracts. Full PostgreSQL reconciliation and Power BI Desktop runtime validation remain local/full-environment checks because their required generated datasets and desktop engine are intentionally not committed.
