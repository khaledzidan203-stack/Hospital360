-- Deterministic Enterprise V1 analytics reload. Existing healthcare objects are untouched.
\set ON_ERROR_STOP on

BEGIN;
TRUNCATE TABLE
    analytics.fact_finance_monthly, analytics.fact_budget_monthly,
    analytics.fact_workforce_monthly, analytics.fact_operations_daily,
    analytics.fact_it_incident, analytics.fact_it_system_daily,
    analytics.dim_department, analytics.dim_cost_category,
    analytics.dim_budget_scenario, analytics.dim_employee_role,
    analytics.dim_it_system, analytics.dim_incident_category
RESTART IDENTITY;

INSERT INTO analytics.dim_department VALUES
(0,'__UNKNOWN__','Unknown / Unmapped','Unknown',false,false,false,0,'__UNKNOWN__',NULL,NULL,false,'HOSPITAL360');
INSERT INTO analytics.dim_cost_category VALUES
(0,'__UNKNOWN__','Unknown / Unmapped','Unknown',false,0,false);
INSERT INTO analytics.dim_budget_scenario VALUES
(0,'__UNKNOWN__','Unknown / Unmapped','Unknown',0,false);
INSERT INTO analytics.dim_employee_role VALUES
(0,'__UNKNOWN__','Unknown / Unmapped','Unknown',false,0,false);
INSERT INTO analytics.dim_it_system VALUES
(0,'__UNKNOWN__','Unknown / Unmapped','Unknown','Unknown',0,0,false);
INSERT INTO analytics.dim_incident_category VALUES
(0,'__UNKNOWN__','Unknown / Unmapped','Unknown','Unknown',false);

INSERT INTO analytics.dim_department
SELECT department_key,department_code,department_name,department_type,clinical_flag,
       capacity_managed_flag,bed_applicable_flag,organization_key,organization_id,
       effective_start_date,effective_end_date,is_active,source_system
FROM staging.stg_enterprise_departments WHERE NOT dq_error ORDER BY department_key;
INSERT INTO analytics.dim_cost_category
SELECT cost_category_key,cost_category_code,cost_category_name,cost_behavior,payroll_flag,display_order,is_active
FROM staging.stg_enterprise_cost_categories WHERE NOT dq_error ORDER BY cost_category_key;
INSERT INTO analytics.dim_budget_scenario
SELECT budget_scenario_key,budget_scenario_code,budget_scenario_name,scenario_type,display_order,is_active
FROM staging.stg_enterprise_budget_scenarios WHERE NOT dq_error ORDER BY budget_scenario_key;
INSERT INTO analytics.dim_employee_role
SELECT employee_role_key,employee_role_code,employee_role_name,role_family,clinical_flag,standard_hours_per_fte_month,is_active
FROM staging.stg_enterprise_employee_roles WHERE NOT dq_error ORDER BY employee_role_key;
INSERT INTO analytics.dim_it_system
SELECT it_system_key,it_system_code,it_system_name,system_domain,criticality_tier,target_uptime_pct,default_sla_minutes,is_active
FROM staging.stg_enterprise_it_systems WHERE NOT dq_error ORDER BY it_system_key;
INSERT INTO analytics.dim_incident_category
SELECT incident_category_key,incident_category_code,incident_category_name,category_group,default_priority,is_active
FROM staging.stg_enterprise_incident_categories WHERE NOT dq_error ORDER BY incident_category_key;

INSERT INTO analytics.fact_finance_monthly (
 month_start_date_key,organization_key,department_key,cost_category_key,operating_revenue,operating_cost,
 fixed_cost_amount,variable_cost_amount,allocated_shared_cost_amount,payroll_cost,supplies_cost,
 medication_cost,facility_cost,technology_other_cost,driver_encounter_count,driver_procedure_count,
 dq_warning,business_anomaly,dq_notes)
SELECT month_start_date_key,organization_key,department_key,cost_category_key,operating_revenue,operating_cost,
 fixed_cost_amount,variable_cost_amount,allocated_shared_cost_amount,payroll_cost,supplies_cost,
 medication_cost,facility_cost,technology_other_cost,driver_encounter_count,driver_procedure_count,
 dq_warning,business_anomaly,dq_notes
FROM staging.stg_enterprise_finance_monthly WHERE NOT dq_error;

INSERT INTO analytics.fact_budget_monthly (
 month_start_date_key,organization_key,department_key,budget_scenario_key,budget_revenue,budget_operating_cost,
 budget_payroll_cost,budget_capital_amount,budget_fte,assumption_version,dq_warning,business_anomaly,dq_notes)
SELECT month_start_date_key,organization_key,department_key,budget_scenario_key,budget_revenue,budget_operating_cost,
 budget_payroll_cost,budget_capital_amount,budget_fte,assumption_version,dq_warning,business_anomaly,dq_notes
FROM staging.stg_enterprise_budget_monthly WHERE NOT dq_error;

INSERT INTO analytics.fact_workforce_monthly (
 month_start_date_key,organization_key,department_key,employee_role_key,headcount_start,headcount,headcount_end,
 average_headcount,fte_start,fte,fte_end,average_fte,new_hires,turnover_count,vacancy_count,scheduled_hours,
 worked_hours,overtime_hours,absence_hours,payroll_cost,dq_warning,business_anomaly,dq_notes)
SELECT month_start_date_key,organization_key,department_key,employee_role_key,headcount_start,headcount,headcount_end,
 average_headcount,fte_start,fte,fte_end,average_fte,new_hires,turnover_count,vacancy_count,scheduled_hours,
 worked_hours,overtime_hours,absence_hours,payroll_cost,dq_warning,business_anomaly,dq_notes
FROM staging.stg_enterprise_workforce_monthly WHERE NOT dq_error;

INSERT INTO analytics.fact_operations_daily (
 date_key,organization_key,department_key,licensed_beds,available_beds,occupied_beds,available_bed_days,
 occupied_bed_days,admissions,discharges,encounter_count,procedure_count,appointments_scheduled,
 appointments_completed,wait_minutes_total,waited_encounter_count,average_waiting_time_minutes,
 length_of_stay_days_total,discharged_with_los_count,average_length_of_stay,capacity_utilization,
 throughput,overflow_capacity_flag,dq_warning,business_anomaly,dq_notes)
SELECT date_key,organization_key,department_key,licensed_beds,available_beds,occupied_beds,available_bed_days,
 occupied_bed_days,admissions,discharges,encounter_count,procedure_count,appointments_scheduled,
 appointments_completed,wait_minutes_total,waited_encounter_count,average_waiting_time_minutes,
 length_of_stay_days_total,discharged_with_los_count,average_length_of_stay,capacity_utilization,
 throughput,overflow_capacity_flag,dq_warning,business_anomaly,dq_notes
FROM staging.stg_enterprise_operations_daily WHERE NOT dq_error;

INSERT INTO analytics.fact_it_incident (
 incident_id,opened_date_key,resolved_date_key,organization_key,department_key,it_system_key,
 incident_category_key,opened_at,resolved_at,severity,status,channel,sla_class,sla_target_minutes,
 resolution_minutes,sla_met_flag,downtime_minutes,affected_users,business_impact_score,
 dq_warning,business_anomaly,dq_notes)
SELECT incident_id,opened_date_key,resolved_date_key,organization_key,department_key,it_system_key,
 incident_category_key,opened_at,resolved_at,severity,status,channel,sla_class,sla_target_minutes,
 resolution_minutes,sla_met_flag,downtime_minutes,affected_users,business_impact_score,
 dq_warning,business_anomaly,dq_notes
FROM staging.stg_enterprise_it_incident WHERE NOT dq_error;

INSERT INTO analytics.fact_it_system_daily (
 date_key,organization_key,it_system_key,scheduled_minutes,availability_minutes,available_minutes,
 downtime_minutes,planned_downtime_minutes,unplanned_downtime_minutes,uptime_pct,transaction_count,
 active_users,peak_concurrent_users,response_time_ms,error_count,incident_count,dq_warning,business_anomaly,dq_notes)
SELECT date_key,organization_key,it_system_key,scheduled_minutes,availability_minutes,available_minutes,
 downtime_minutes,planned_downtime_minutes,unplanned_downtime_minutes,uptime_pct,transaction_count,
 active_users,peak_concurrent_users,response_time_ms,error_count,incident_count,dq_warning,business_anomaly,dq_notes
FROM staging.stg_enterprise_it_system_daily WHERE NOT dq_error;

COMMIT;
