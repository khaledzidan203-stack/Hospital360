# Hospital360 Tests

Hospital360 separates tests that can run from a clean Git clone from acceptance checks that require locally generated RAW data.

## Clone-safe checks

`test_enterprise_generation.py` always validates the deterministic master seed and the 36-month final profile contract.

The enterprise RAW acceptance-manifest assertion is also defined in that test file, but it is automatically skipped when the ignored local manifest is not present. This allows GitHub Actions and fresh clones to execute the repository-safe test suite without fabricating RAW evidence.

Run:

```powershell
python -m unittest discover -s tests -p "test_*.py" -v
```

## Local full-data acceptance

After generating the accepted enterprise RAW snapshot, the file below exists locally:

`data/raw/finance/enterprise_generation_manifest.json`

The manifest test then runs automatically and verifies:

- status = `PASS`;
- profile = `FINAL_36M`;
- fact rows = `25,716`;
- validation status = `PASS`;
- validation error list is empty.

Full PostgreSQL reconciliation and Power BI runtime validation are separate environment-dependent checks documented in `docs/SETUP.md` and the architecture evidence.
