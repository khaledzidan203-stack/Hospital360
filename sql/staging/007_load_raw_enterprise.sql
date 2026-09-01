-- Deterministic client-side load of the accepted Enterprise V1 final snapshot.
-- Reads local CSV files and truncates/reloads only enterprise RAW tables.
\set ON_ERROR_STOP on

BEGIN;
TRUNCATE TABLE
    raw.enterprise_departments, raw.enterprise_cost_categories,
    raw.enterprise_budget_scenarios, raw.enterprise_employee_roles,
    raw.enterprise_it_systems, raw.enterprise_incident_categories,
    raw.enterprise_finance_monthly, raw.enterprise_budget_monthly,
    raw.enterprise_workforce_monthly, raw.enterprise_operations_daily,
    raw.enterprise_it_incident, raw.enterprise_it_system_daily;

\copy raw.enterprise_departments FROM 'D:/Hospital360/data/raw/finance/enterprise_departments.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_cost_categories FROM 'D:/Hospital360/data/raw/finance/enterprise_cost_categories.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_budget_scenarios FROM 'D:/Hospital360/data/raw/finance/enterprise_budget_scenarios.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_employee_roles FROM 'D:/Hospital360/data/raw/hr/enterprise_employee_roles.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_it_systems FROM 'D:/Hospital360/data/raw/it/enterprise_it_systems.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_incident_categories FROM 'D:/Hospital360/data/raw/it/enterprise_incident_categories.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_finance_monthly FROM 'D:/Hospital360/data/raw/finance/enterprise_finance_monthly.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_budget_monthly FROM 'D:/Hospital360/data/raw/finance/enterprise_budget_monthly.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_workforce_monthly FROM 'D:/Hospital360/data/raw/hr/enterprise_workforce_monthly.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_operations_daily FROM 'D:/Hospital360/data/raw/operations/enterprise_operations_daily.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_it_incident FROM 'D:/Hospital360/data/raw/it/enterprise_it_incident.csv' WITH (FORMAT csv, HEADER true, NULL '')
\copy raw.enterprise_it_system_daily FROM 'D:/Hospital360/data/raw/it/enterprise_it_system_daily.csv' WITH (FORMAT csv, HEADER true, NULL '')
COMMIT;
