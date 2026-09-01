-- Read-only Enterprise V1 workforce analysis.
\set ON_ERROR_STOP on

SELECT SUM(headcount_end) headcount,SUM(fte_end) fte,SUM(payroll_cost) payroll_cost,
       SUM(overtime_hours) overtime_hours,SUM(absence_hours)/NULLIF(SUM(scheduled_hours),0) absence_rate,
       SUM(turnover_count)/NULLIF(SUM(average_headcount),0) turnover_rate,SUM(vacancy_count) vacancies
FROM analytics.fact_workforce_monthly WHERE month_start_date_key=20260701;

SELECT dep.department_name,SUM(w.fte_end) fte,SUM(w.payroll_cost) payroll_cost,
       SUM(w.overtime_hours)/NULLIF(SUM(w.worked_hours),0) overtime_rate,
       SUM(w.absence_hours)/NULLIF(SUM(w.scheduled_hours),0) absence_rate
FROM analytics.fact_workforce_monthly w JOIN analytics.dim_department dep ON dep.department_key=w.department_key
WHERE w.month_start_date_key=20260701 GROUP BY dep.department_name ORDER BY fte DESC;

SELECT r.employee_role_name,SUM(w.average_fte) average_fte,SUM(w.payroll_cost) payroll_cost
FROM analytics.fact_workforce_monthly w JOIN analytics.dim_employee_role r ON r.employee_role_key=w.employee_role_key
GROUP BY r.employee_role_name ORDER BY average_fte DESC;

SELECT d.year_month,SUM(w.fte_end) fte,SUM(w.overtime_hours) overtime_hours,
       SUM(w.absence_hours)/NULLIF(SUM(w.scheduled_hours),0) absence_rate
FROM analytics.fact_workforce_monthly w JOIN analytics.dim_date d ON d.date_key=w.month_start_date_key
GROUP BY d.year_month ORDER BY d.year_month;

SELECT dep.department_name,SUM(w.turnover_count) turnover_count,
       SUM(w.turnover_count)/NULLIF(SUM(w.average_headcount),0) turnover_rate
FROM analytics.fact_workforce_monthly w JOIN analytics.dim_department dep ON dep.department_key=w.department_key
GROUP BY dep.department_name ORDER BY turnover_rate DESC;
