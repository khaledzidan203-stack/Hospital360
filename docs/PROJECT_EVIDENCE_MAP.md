# Hospital360 Project Evidence Map

This map links high-level project claims to the repository artifacts that support them. Presentation assets and README summaries are not treated as primary evidence.

| Claim | Primary evidence |
|---|---|
| Data is synthetic only | `README.md`, `SECURITY.md`, architecture documentation |
| Accepted healthcare baseline is 5,000 patients | `docs/architecture/portfolio_scale_validation.md` |
| Core healthcare RAW total is 5,515,928 rows | `docs/architecture/portfolio_scale_validation.md` |
| Healthcare model contains five analytical facts | `docs/architecture/analytics_star_schema.md` |
| RAW → STAGING parity is exact at 5K scale | `docs/architecture/portfolio_scale_validation.md` |
| STAGING → fact differences are zero | `docs/architecture/portfolio_scale_validation.md` |
| SQL regression completed 47/47 queries with zero failures | `docs/architecture/portfolio_scale_validation.md` |
| 20K source generation and RAW load succeeded but full pipeline did not complete | `docs/architecture/portfolio_scale_validation.md` |
| Enterprise period is 36 months | `docs/architecture/enterprise_implementation.md` |
| Enterprise final fact rows total 25,716 | `docs/architecture/enterprise_implementation.md` |
| Enterprise layer contains six facts | `docs/architecture/enterprise_implementation.md`, `docs/architecture/enterprise_star_schema.md` |
| Enterprise DQ has 0 fatal errors, 633 warnings, 1,257 retained anomalies | `docs/architecture/enterprise_implementation.md` |
| Healthcare claims are not treated as hospital P&L | `README.md`, `docs/architecture/enterprise_implementation.md` |
| Current report contains 13 pages | `powerbi/Hospital360.Report/definition/pages/pages.json`, `docs/architecture/enterprise_powerbi_inventory.md` |
| Current Home navigation contains 12 tiles | `docs/architecture/enterprise_powerbi_inventory.md` and saved PBIR source |
| PBIP/PBIR/TMDL is version controlled | `powerbi/Hospital360.pbip`, `powerbi/Hospital360.Report/`, `powerbi/Hospital360.SemanticModel/` |
| Seven repository screenshots are representative captures, not the full page inventory | `docs/screenshots/README.md`, `docs/screenshots/` |
| Auto Date/Time remains enabled while explicit `analytics dim_date` also exists | `powerbi/Hospital360.SemanticModel/definition/model.tmdl`, `powerbi/Hospital360.SemanticModel/definition/relationships.tmdl` |
| Local RAW files and credentials are excluded from Git | `.gitignore`, `.env.example`, `docs/SETUP.md` |

## Evidence hierarchy

When presentation wording conflicts with a technical artifact, use this order:

1. saved database / Power BI source and executable code;
2. validated architecture and reconciliation records;
3. setup and governance documentation;
4. screenshots;
5. README and visual presentation summaries.

Historical artifacts are preserved for development traceability, but current implementation evidence takes precedence when page counts or release state changed later.
