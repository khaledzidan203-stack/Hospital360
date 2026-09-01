-- Read-only Enterprise V1 finance analysis. All facts remain at native grain.
\set ON_ERROR_STOP on

SELECT SUM(operating_revenue) AS revenue, SUM(operating_cost) AS operating_cost,
       SUM(operating_revenue)-SUM(operating_cost) AS operating_margin,
       (SUM(operating_revenue)-SUM(operating_cost))/NULLIF(SUM(operating_revenue),0) AS operating_margin_pct
FROM analytics.fact_finance_monthly;

SELECT d.year_month, SUM(f.operating_revenue) AS revenue, SUM(f.operating_cost) AS operating_cost
FROM analytics.fact_finance_monthly f JOIN analytics.dim_date d ON d.date_key=f.month_start_date_key
GROUP BY d.year_month ORDER BY d.year_month;

SELECT dep.department_name, SUM(f.operating_revenue) AS revenue, SUM(f.operating_cost) AS operating_cost,
       SUM(f.operating_revenue)-SUM(f.operating_cost) AS operating_margin
FROM analytics.fact_finance_monthly f JOIN analytics.dim_department dep ON dep.department_key=f.department_key
GROUP BY dep.department_name ORDER BY operating_cost DESC;

SELECT c.cost_category_name, SUM(f.operating_cost) AS operating_cost
FROM analytics.fact_finance_monthly f JOIN analytics.dim_cost_category c ON c.cost_category_key=f.cost_category_key
WHERE c.cost_category_code<>'REVENUE' GROUP BY c.cost_category_name ORDER BY operating_cost DESC;

WITH actual AS (
 SELECT month_start_date_key,organization_key,department_key,SUM(operating_revenue) revenue,SUM(operating_cost) cost
 FROM analytics.fact_finance_monthly GROUP BY 1,2,3
), budget AS (
 SELECT month_start_date_key,organization_key,department_key,SUM(budget_revenue) budget_revenue,SUM(budget_operating_cost) budget_cost
 FROM analytics.fact_budget_monthly WHERE budget_scenario_key=1 GROUP BY 1,2,3
)
SELECT d.year_month,SUM(a.revenue) revenue,SUM(b.budget_revenue) budget_revenue,
       SUM(a.cost) cost,SUM(b.budget_cost) budget_cost,
       SUM(a.revenue)-SUM(b.budget_revenue) revenue_variance,
       SUM(a.cost)-SUM(b.budget_cost) cost_variance
FROM actual a JOIN budget b USING(month_start_date_key,organization_key,department_key)
JOIN analytics.dim_date d ON d.date_key=a.month_start_date_key
GROUP BY d.year_month ORDER BY d.year_month;

SELECT dep.department_name,SUM(f.payroll_cost) payroll_cost,
       SUM(f.payroll_cost)/NULLIF(SUM(f.operating_cost),0) payroll_cost_pct
FROM analytics.fact_finance_monthly f JOIN analytics.dim_department dep ON dep.department_key=f.department_key
GROUP BY dep.department_name ORDER BY payroll_cost DESC;
