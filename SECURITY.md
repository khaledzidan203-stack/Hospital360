# Security and Privacy

- Keep credentials in the ignored local `.env`; never commit passwords, tokens, keys, or connection secrets.
- Report an exposed secret immediately through the repository's private security-reporting channel, then rotate it.
- Do not add real patient, employee, customer, or confidential organization data.
- Public examples and test fixtures must remain synthetic.
- Keep large generated RAW datasets, local PostgreSQL data, PBIX files, caches, logs, and temporary artifacts outside Git.
- Review staged files for secrets and sensitive identifiers before every public release.
