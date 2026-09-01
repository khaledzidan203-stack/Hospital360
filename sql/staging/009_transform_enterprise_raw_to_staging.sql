-- Deterministic Enterprise V1 RAW-to-STAGING transformation and DQ classification.
\set ON_ERROR_STOP on

BEGIN;
TRUNCATE TABLE
    staging.stg_enterprise_finance_monthly, staging.stg_enterprise_budget_monthly,
    staging.stg_enterprise_workforce_monthly, staging.stg_enterprise_operations_daily,
    staging.stg_enterprise_it_incident, staging.stg_enterprise_it_system_daily,
    staging.stg_enterprise_departments, staging.stg_enterprise_cost_categories,
    staging.stg_enterprise_budget_scenarios, staging.stg_enterprise_employee_roles,
    staging.stg_enterprise_it_systems, staging.stg_enterprise_incident_categories;

INSERT INTO staging.stg_enterprise_departments
SELECT department_key::integer, department_code, department_name, department_type,
       clinical_flag::boolean, capacity_managed_flag::boolean, bed_applicable_flag::boolean,
       organization_key::integer, organization_id, effective_start_date::date,
       effective_end_date::date, is_active::boolean, source_system,
       department_key IS NULL OR department_code IS NULL OR organization_key IS NULL
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_organization o WHERE o.organization_key=r.organization_key::integer),
       false, false,
       CASE WHEN NOT EXISTS (SELECT 1 FROM analytics.dim_organization o WHERE o.organization_key=r.organization_key::integer) THEN 'ERROR: organization reference' END
FROM raw.enterprise_departments r;

INSERT INTO staging.stg_enterprise_cost_categories
SELECT cost_category_key::integer, cost_category_code, cost_category_name, cost_behavior,
       payroll_flag::boolean, display_order::smallint, is_active::boolean,
       cost_category_key IS NULL OR cost_category_code IS NULL, NULL
FROM raw.enterprise_cost_categories;
INSERT INTO staging.stg_enterprise_budget_scenarios
SELECT budget_scenario_key::integer, budget_scenario_code, budget_scenario_name,
       scenario_type, display_order::smallint, is_active::boolean,
       budget_scenario_key IS NULL OR budget_scenario_code IS NULL, NULL
FROM raw.enterprise_budget_scenarios;
INSERT INTO staging.stg_enterprise_employee_roles
SELECT employee_role_key::integer, employee_role_code, employee_role_name, role_family,
       clinical_flag::boolean, standard_hours_per_fte_month::numeric, is_active::boolean,
       employee_role_key IS NULL OR employee_role_code IS NULL OR standard_hours_per_fte_month::numeric <= 0, NULL
FROM raw.enterprise_employee_roles;
INSERT INTO staging.stg_enterprise_it_systems
SELECT it_system_key::integer, it_system_code, it_system_name, system_domain, criticality_tier,
       target_uptime_pct::numeric / 100.0, default_sla_minutes::integer, is_active::boolean,
       it_system_key IS NULL OR it_system_code IS NULL OR target_uptime_pct::numeric NOT BETWEEN 0 AND 100, NULL
FROM raw.enterprise_it_systems;
INSERT INTO staging.stg_enterprise_incident_categories
SELECT incident_category_key::integer, incident_category_code, incident_category_name,
       category_group, default_priority, is_active::boolean,
       incident_category_key IS NULL OR incident_category_code IS NULL, NULL
FROM raw.enterprise_incident_categories;

WITH typed AS (
    SELECT r.*, month_start_date::date AS d, month_start_date_key::integer AS dk,
           organization_key::integer AS ok, department_key::integer AS depk,
           cost_category_key::integer AS ck, operating_revenue::numeric AS revenue,
           operating_cost::numeric AS cost, fixed_cost_amount::numeric AS fixed,
           variable_cost_amount::numeric AS variable, allocated_shared_cost_amount::numeric AS allocated,
           payroll_cost::numeric AS payroll, supplies_cost::numeric AS supplies,
           medication_cost::numeric AS medication, facility_cost::numeric AS facility,
           technology_other_cost::numeric AS technology, driver_encounter_count::integer AS encounters,
           driver_procedure_count::integer AS procedures
    FROM raw.enterprise_finance_monthly r
), duplicates AS (
    SELECT dk,ok,depk,ck FROM typed GROUP BY dk,ok,depk,ck HAVING count(*)>1
)
INSERT INTO staging.stg_enterprise_finance_monthly
SELECT d,dk,ok,depk,ck,revenue,cost,fixed,variable,allocated,payroll,supplies,medication,facility,technology,encounters,procedures,
       dup.dk IS NOT NULL OR d < DATE '2023-08-01' OR d > DATE '2026-07-31' OR extract(day FROM d)<>1
         OR revenue<0 OR cost<0 OR abs((fixed+variable+allocated)-cost)>0.03
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_date x WHERE x.date_key=dk)
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_organization x WHERE x.organization_key=ok)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_departments x WHERE x.department_key=depk AND x.organization_key=ok)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_cost_categories x WHERE x.cost_category_key=ck),
       encounters=0 AND revenue>0,
       cost>1000000,
       concat_ws('; ', CASE WHEN dup.dk IS NOT NULL THEN 'ERROR: duplicate grain' END,
         CASE WHEN abs((fixed+variable+allocated)-cost)>0.03 THEN 'ERROR: cost reconciliation' END,
         CASE WHEN cost>1000000 THEN 'BUSINESS_ANOMALY: high monthly cost' END)
FROM typed t LEFT JOIN duplicates dup USING(dk,ok,depk,ck);

WITH typed AS (
    SELECT r.*, month_start_date::date AS d, month_start_date_key::integer AS dk,
           organization_key::integer AS ok, department_key::integer AS depk,
           budget_scenario_key::integer AS sk, budget_revenue::numeric AS revenue,
           budget_operating_cost::numeric AS cost, budget_payroll_cost::numeric AS payroll,
           budget_capital_amount::numeric AS capital, budget_fte::numeric AS fte
    FROM raw.enterprise_budget_monthly r
), duplicates AS (
    SELECT dk,ok,depk,sk FROM typed GROUP BY dk,ok,depk,sk HAVING count(*)>1
)
INSERT INTO staging.stg_enterprise_budget_monthly
SELECT d,dk,ok,depk,sk,revenue,cost,payroll,capital,fte,assumption_version,
       dup.dk IS NOT NULL OR d<DATE '2023-08-01' OR d>DATE '2026-07-31' OR extract(day FROM d)<>1
         OR revenue<0 OR cost<0 OR payroll<0 OR capital<0 OR fte<0
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_date x WHERE x.date_key=dk)
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_organization x WHERE x.organization_key=ok)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_departments x WHERE x.department_key=depk AND x.organization_key=ok)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_budget_scenarios x WHERE x.budget_scenario_key=sk),
       fte=0, capital>50000,
       concat_ws('; ',CASE WHEN dup.dk IS NOT NULL THEN 'ERROR: duplicate grain' END,
         CASE WHEN fte=0 THEN 'WARNING: zero planned FTE' END,
         CASE WHEN capital>50000 THEN 'BUSINESS_ANOMALY: capital plan spike' END)
FROM typed t LEFT JOIN duplicates dup USING(dk,ok,depk,sk);

WITH typed AS (
    SELECT r.*, month_start_date::date AS d, month_start_date_key::integer AS dk,
           organization_key::integer AS ok, department_key::integer AS depk,
           employee_role_key::integer AS rk, headcount_start::integer AS hc_start,
           headcount::integer AS hc, headcount_end::integer AS hc_end,
           average_headcount::numeric AS avg_hc, fte_start::numeric AS fte_s,
           fte::numeric AS fte_v, fte_end::numeric AS fte_e, average_fte::numeric AS avg_fte,
           new_hires::integer AS hires, turnover_count::integer AS turnover,
           vacancy_count::integer AS vacancies, scheduled_hours::numeric AS scheduled,
           worked_hours::numeric AS worked, overtime_hours::numeric AS overtime,
           absence_hours::numeric AS absence, payroll_cost::numeric AS payroll
    FROM raw.enterprise_workforce_monthly r
), duplicates AS (
    SELECT dk,ok,depk,rk FROM typed GROUP BY dk,ok,depk,rk HAVING count(*)>1
)
INSERT INTO staging.stg_enterprise_workforce_monthly
SELECT d,dk,ok,depk,rk,hc_start,hc,hc_end,avg_hc,fte_s,fte_v,fte_e,avg_fte,hires,turnover,vacancies,scheduled,worked,overtime,absence,payroll,
       dup.dk IS NOT NULL OR d<DATE '2023-08-01' OR d>DATE '2026-07-31'
         OR least(hc_start,hc,hc_end,hires,turnover,vacancies,scheduled,worked,overtime,absence,payroll)<0
         OR greatest(fte_s,fte_v,fte_e)>greatest(hc_start,hc,hc_end)+0.01 OR absence>scheduled
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_date x WHERE x.date_key=dk)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_departments x WHERE x.department_key=depk AND x.organization_key=ok)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_employee_roles x WHERE x.employee_role_key=rk),
       fte_v<=0 OR overtime/nullif(worked,0)>0.15 OR absence/nullif(scheduled,0)>0.10,
       overtime/nullif(worked,0)>0.15 OR absence/nullif(scheduled,0)>0.10 OR turnover/nullif(avg_hc,0)>0.05,
       concat_ws('; ',CASE WHEN dup.dk IS NOT NULL THEN 'ERROR: duplicate grain' END,
         CASE WHEN overtime/nullif(worked,0)>0.15 THEN 'BUSINESS_ANOMALY: high overtime' END,
         CASE WHEN absence/nullif(scheduled,0)>0.10 THEN 'BUSINESS_ANOMALY: high absence' END)
FROM typed t LEFT JOIN duplicates dup USING(dk,ok,depk,rk);

WITH typed AS (
    SELECT r.*, date::date AS d, date_key::integer AS dk, organization_key::integer AS ok,
           department_key::integer AS depk, licensed_beds::numeric::integer AS licensed,
           available_beds::numeric::integer AS available, occupied_beds::numeric::integer AS occupied,
           available_bed_days::numeric AS available_days, occupied_bed_days::numeric AS occupied_days,
           admissions::numeric::integer AS admits, discharges::numeric::integer AS disch,
           encounter_count::integer AS encounters, procedure_count::integer AS procedures,
           appointments_scheduled::numeric::integer AS slots, appointments_completed::numeric::integer AS completed,
           wait_minutes_total::numeric AS wait_total, waited_encounter_count::integer AS wait_count,
           average_waiting_time_minutes::numeric AS avg_wait, length_of_stay_days_total::numeric AS los_total,
           discharged_with_los_count::numeric::integer AS los_count, average_length_of_stay::numeric AS avg_los,
           capacity_utilization::numeric AS utilization, throughput::integer AS throughput_v,
           overflow_capacity_flag::boolean AS overflow
    FROM raw.enterprise_operations_daily r
), duplicates AS (
    SELECT dk,ok,depk FROM typed GROUP BY dk,ok,depk HAVING count(*)>1
)
INSERT INTO staging.stg_enterprise_operations_daily
SELECT d,dk,ok,depk,licensed,available,occupied,available_days,occupied_days,admits,disch,encounters,procedures,slots,completed,wait_total,wait_count,avg_wait,los_total,los_count,avg_los,utilization,throughput_v,overflow,
       dup.dk IS NOT NULL OR d<DATE '2023-08-01' OR d>DATE '2026-07-31'
         OR least(encounters,procedures,wait_count,throughput_v)<0 OR coalesce(completed,0)>coalesce(slots,0)
         OR coalesce(utilization<0,false) OR coalesce(utilization>1.05,false)
         OR coalesce(occupied>available AND NOT overflow,false)
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_date x WHERE x.date_key=dk)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_departments x WHERE x.department_key=depk AND x.organization_key=ok),
       overflow OR avg_wait>120,
       (coalesce(utilization,0)>0.95 AND EXISTS (
            SELECT 1 FROM staging.stg_enterprise_departments x
            WHERE x.department_key=depk AND x.bed_applicable_flag
        )) OR avg_wait>120 OR (slots IS NOT NULL AND completed/nullif(slots,0)<0.65),
       concat_ws('; ',CASE WHEN dup.dk IS NOT NULL THEN 'ERROR: duplicate grain' END,
         CASE WHEN overflow THEN 'WARNING: controlled overflow capacity' END,
         CASE WHEN coalesce(utilization,0)>0.95 AND EXISTS (
              SELECT 1 FROM staging.stg_enterprise_departments x
              WHERE x.department_key=depk AND x.bed_applicable_flag
         ) THEN 'BUSINESS_ANOMALY: high bed utilization' END,
         CASE WHEN avg_wait>120 THEN 'BUSINESS_ANOMALY: high waiting time' END)
FROM typed t LEFT JOIN duplicates dup USING(dk,ok,depk);

WITH typed AS (
    SELECT r.*, opened_date_key::integer AS odk, resolved_date_key::integer AS rdk,
           organization_key::integer AS ok, department_key::integer AS depk,
           it_system_key::integer AS sk, incident_category_key::integer AS ck,
           opened_at::timestamptz AS opened, resolved_at::timestamptz AS resolved,
           sla_target_minutes::numeric::integer AS sla_target, resolution_minutes::numeric::integer AS resolution,
           sla_met_flag::boolean AS sla_met, downtime_minutes::integer AS downtime,
           affected_users::integer AS users, business_impact_score::numeric AS impact
    FROM raw.enterprise_it_incident r
), duplicates AS (SELECT incident_id FROM typed GROUP BY incident_id HAVING count(*)>1)
INSERT INTO staging.stg_enterprise_it_incident
SELECT incident_id,odk,rdk,ok,depk,sk,ck,opened,resolved,severity,status,channel,sla_class,sla_target,resolution,sla_met,downtime,users,impact,
       dup.incident_id IS NOT NULL OR incident_id IS NULL OR coalesce(resolved<opened,false)
         OR least(sla_target,coalesce(resolution,0),downtime,users,impact)<0
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_date x WHERE x.date_key=odk)
         OR (rdk<>0 AND NOT EXISTS (SELECT 1 FROM analytics.dim_date x WHERE x.date_key=rdk))
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_organization x WHERE x.organization_key=ok)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_departments x WHERE x.department_key=depk)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_it_systems x WHERE x.it_system_key=sk)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_incident_categories x WHERE x.incident_category_key=ck),
       (resolved IS NULL AND status<>'Open') OR coalesce(resolution,0)>sla_target*2,
       severity IN ('P1','P2') OR downtime>120 OR coalesce(resolution,0)>sla_target*2,
       concat_ws('; ',CASE WHEN dup.incident_id IS NOT NULL THEN 'ERROR: duplicate incident' END,
         CASE WHEN resolved<opened THEN 'ERROR: resolved before opened' END,
         CASE WHEN severity IN ('P1','P2') THEN 'BUSINESS_ANOMALY: critical incident' END,
         CASE WHEN coalesce(resolution,0)>sla_target*2 THEN 'BUSINESS_ANOMALY: long resolution' END)
FROM typed t LEFT JOIN duplicates dup USING(incident_id);

WITH typed AS (
    SELECT r.*, date::date AS d, date_key::integer AS dk, organization_key::integer AS ok,
           it_system_key::integer AS sk, scheduled_minutes::integer AS scheduled,
           availability_minutes::integer AS availability, available_minutes::integer AS available,
           downtime_minutes::integer AS downtime, planned_downtime_minutes::integer AS planned,
           unplanned_downtime_minutes::integer AS unplanned, uptime_pct::numeric AS uptime,
           transaction_count::bigint AS transactions, active_users::integer AS users,
           peak_concurrent_users::integer AS peak_users, response_time_ms::numeric AS response,
           error_count::integer AS errors, incident_count::integer AS incidents
    FROM raw.enterprise_it_system_daily r
), duplicates AS (SELECT dk,ok,sk FROM typed GROUP BY dk,ok,sk HAVING count(*)>1)
INSERT INTO staging.stg_enterprise_it_system_daily
SELECT d,dk,ok,sk,scheduled,availability,available,downtime,planned,unplanned,uptime,transactions,users,peak_users,response,errors,incidents,
       dup.dk IS NOT NULL OR d<DATE '2023-08-01' OR d>DATE '2026-07-31'
         OR least(scheduled,availability,available,downtime,planned,unplanned,transactions,users,peak_users,response,errors,incidents)<0
         OR availability+downtime<>scheduled OR available<>availability OR planned+unplanned<>downtime OR uptime NOT BETWEEN 0 AND 1
         OR abs(uptime-(availability::numeric/nullif(scheduled,0)))>0.000001
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_date x WHERE x.date_key=dk)
         OR NOT EXISTS (SELECT 1 FROM analytics.dim_organization x WHERE x.organization_key=ok)
         OR NOT EXISTS (SELECT 1 FROM staging.stg_enterprise_it_systems x WHERE x.it_system_key=sk),
       uptime<0.99 OR response>1000,
       uptime<0.99 OR downtime>120 OR response>1000,
       concat_ws('; ',CASE WHEN dup.dk IS NOT NULL THEN 'ERROR: duplicate grain' END,
         CASE WHEN uptime<0.99 THEN 'BUSINESS_ANOMALY: low uptime' END,
         CASE WHEN downtime>120 THEN 'BUSINESS_ANOMALY: major downtime' END)
FROM typed t LEFT JOIN duplicates dup USING(dk,ok,sk);

COMMIT;
