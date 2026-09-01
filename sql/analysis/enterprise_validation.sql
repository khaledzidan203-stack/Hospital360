-- Read-only consolidated Enterprise V1 validation and reconciliation.
\set ON_ERROR_STOP on

WITH counts AS (
 SELECT 'finance' fact,(SELECT count(*) FROM staging.stg_enterprise_finance_monthly) staging_rows,(SELECT count(*) FROM analytics.fact_finance_monthly) analytics_rows
 UNION ALL SELECT 'budget',(SELECT count(*) FROM staging.stg_enterprise_budget_monthly),(SELECT count(*) FROM analytics.fact_budget_monthly)
 UNION ALL SELECT 'workforce',(SELECT count(*) FROM staging.stg_enterprise_workforce_monthly),(SELECT count(*) FROM analytics.fact_workforce_monthly)
 UNION ALL SELECT 'operations',(SELECT count(*) FROM staging.stg_enterprise_operations_daily),(SELECT count(*) FROM analytics.fact_operations_daily)
 UNION ALL SELECT 'it_incident',(SELECT count(*) FROM staging.stg_enterprise_it_incident),(SELECT count(*) FROM analytics.fact_it_incident)
 UNION ALL SELECT 'it_daily',(SELECT count(*) FROM staging.stg_enterprise_it_system_daily),(SELECT count(*) FROM analytics.fact_it_system_daily)
)
SELECT fact,staging_rows,analytics_rows,analytics_rows-staging_rows difference FROM counts ORDER BY fact;

WITH duplicate_counts AS (
 SELECT (SELECT count(*) FROM (SELECT month_start_date_key,organization_key,department_key,cost_category_key FROM analytics.fact_finance_monthly GROUP BY 1,2,3,4 HAVING count(*)>1)x) finance,
        (SELECT count(*) FROM (SELECT month_start_date_key,organization_key,department_key,budget_scenario_key FROM analytics.fact_budget_monthly GROUP BY 1,2,3,4 HAVING count(*)>1)x) budget,
        (SELECT count(*) FROM (SELECT month_start_date_key,organization_key,department_key,employee_role_key FROM analytics.fact_workforce_monthly GROUP BY 1,2,3,4 HAVING count(*)>1)x) workforce,
        (SELECT count(*) FROM (SELECT date_key,organization_key,department_key FROM analytics.fact_operations_daily GROUP BY 1,2,3 HAVING count(*)>1)x) operations,
        (SELECT count(*) FROM (SELECT incident_id FROM analytics.fact_it_incident GROUP BY 1 HAVING count(*)>1)x) incidents,
        (SELECT count(*) FROM (SELECT date_key,organization_key,it_system_key FROM analytics.fact_it_system_daily GROUP BY 1,2,3 HAVING count(*)>1)x) it_daily
)
SELECT * FROM duplicate_counts;

SELECT
 (SELECT sum(operating_revenue) FROM staging.stg_enterprise_finance_monthly)-(SELECT sum(operating_revenue) FROM analytics.fact_finance_monthly) revenue_difference,
 (SELECT sum(operating_cost) FROM staging.stg_enterprise_finance_monthly)-(SELECT sum(operating_cost) FROM analytics.fact_finance_monthly) cost_difference,
 (SELECT sum(payroll_cost) FROM staging.stg_enterprise_workforce_monthly)-(SELECT sum(payroll_cost) FROM analytics.fact_workforce_monthly) payroll_difference,
 (SELECT sum(encounter_count) FROM staging.stg_enterprise_operations_daily)-(SELECT sum(encounter_count) FROM analytics.fact_operations_daily) encounter_difference,
 (SELECT sum(transaction_count) FROM staging.stg_enterprise_it_system_daily)-(SELECT sum(transaction_count) FROM analytics.fact_it_system_daily) it_transaction_difference;

SELECT count(*) AS fact_to_fact_foreign_keys
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name=tc.constraint_name AND ccu.constraint_schema=tc.constraint_schema
WHERE tc.constraint_schema='analytics' AND tc.constraint_type='FOREIGN KEY'
  AND tc.table_name LIKE 'fact_%' AND ccu.table_name LIKE 'fact_%';

SELECT count(*) FILTER(WHERE dq_error) fatal_errors,
       count(*) FILTER(WHERE dq_warning) warnings,
       count(*) FILTER(WHERE business_anomaly) business_anomalies
FROM (
 SELECT dq_error,dq_warning,business_anomaly FROM staging.stg_enterprise_finance_monthly
 UNION ALL SELECT dq_error,dq_warning,business_anomaly FROM staging.stg_enterprise_budget_monthly
 UNION ALL SELECT dq_error,dq_warning,business_anomaly FROM staging.stg_enterprise_workforce_monthly
 UNION ALL SELECT dq_error,dq_warning,business_anomaly FROM staging.stg_enterprise_operations_daily
 UNION ALL SELECT dq_error,dq_warning,business_anomaly FROM staging.stg_enterprise_it_incident
 UNION ALL SELECT dq_error,dq_warning,business_anomaly FROM staging.stg_enterprise_it_system_daily
) dq;
