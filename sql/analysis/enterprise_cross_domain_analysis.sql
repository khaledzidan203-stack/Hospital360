-- Read-only cross-domain associations using pre-aggregated conformed grains.
\set ON_ERROR_STOP on

WITH ops AS (
 SELECT to_char(d.full_date,'YYYYMM')::integer month_key,o.organization_key,o.department_key,
        SUM(o.encounter_count) encounters,AVG(o.capacity_utilization) utilization
 FROM analytics.fact_operations_daily o JOIN analytics.dim_date d ON d.date_key=o.date_key GROUP BY 1,2,3
), workforce AS (
 SELECT to_char(d.full_date,'YYYYMM')::integer month_key,w.organization_key,w.department_key,
        SUM(w.average_fte) average_fte,SUM(w.overtime_hours) overtime_hours
 FROM analytics.fact_workforce_monthly w JOIN analytics.dim_date d ON d.date_key=w.month_start_date_key GROUP BY 1,2,3
), finance AS (
 SELECT to_char(d.full_date,'YYYYMM')::integer month_key,f.organization_key,f.department_key,
        SUM(f.operating_revenue) revenue,SUM(f.operating_cost) operating_cost
 FROM analytics.fact_finance_monthly f JOIN analytics.dim_date d ON d.date_key=f.month_start_date_key GROUP BY 1,2,3
)
SELECT dep.department_name,o.month_key,o.encounters,w.average_fte,w.overtime_hours,f.revenue,f.operating_cost,o.utilization,
       o.encounters/NULLIF(w.average_fte,0) encounters_per_fte,
       f.operating_cost/NULLIF(o.encounters,0) cost_per_encounter,
       f.revenue/NULLIF(o.encounters,0) revenue_per_encounter
FROM ops o JOIN workforce w USING(month_key,organization_key,department_key)
JOIN finance f USING(month_key,organization_key,department_key)
JOIN analytics.dim_department dep ON dep.department_key=o.department_key
ORDER BY o.month_key,dep.department_name;

WITH hospital_activity AS (
 SELECT date_key,organization_key,SUM(encounter_count) encounters
 FROM analytics.fact_operations_daily GROUP BY date_key,organization_key
), usage AS (
 SELECT date_key,organization_key,SUM(transaction_count) system_transactions,SUM(error_count) errors
 FROM analytics.fact_it_system_daily GROUP BY date_key,organization_key
)
SELECT d.year_month,SUM(a.encounters) encounters,SUM(u.system_transactions) system_transactions,SUM(u.errors) errors
FROM hospital_activity a JOIN usage u USING(date_key,organization_key)
JOIN analytics.dim_date d ON d.date_key=a.date_key
GROUP BY d.year_month ORDER BY d.year_month;
