-- Typed, validated Enterprise V1 staging tables.
\set ON_ERROR_STOP on

BEGIN;

CREATE TABLE IF NOT EXISTS staging.stg_enterprise_departments (
    department_key integer, department_code text, department_name text, department_type text,
    clinical_flag boolean, capacity_managed_flag boolean, bed_applicable_flag boolean,
    organization_key integer, organization_id text, effective_start_date date,
    effective_end_date date, is_active boolean, source_system text,
    dq_error boolean NOT NULL DEFAULT false, dq_warning boolean NOT NULL DEFAULT false,
    business_anomaly boolean NOT NULL DEFAULT false, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_cost_categories (
    cost_category_key integer, cost_category_code text, cost_category_name text,
    cost_behavior text, payroll_flag boolean, display_order smallint, is_active boolean,
    dq_error boolean NOT NULL DEFAULT false, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_budget_scenarios (
    budget_scenario_key integer, budget_scenario_code text, budget_scenario_name text,
    scenario_type text, display_order smallint, is_active boolean,
    dq_error boolean NOT NULL DEFAULT false, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_employee_roles (
    employee_role_key integer, employee_role_code text, employee_role_name text,
    role_family text, clinical_flag boolean, standard_hours_per_fte_month numeric(10,2), is_active boolean,
    dq_error boolean NOT NULL DEFAULT false, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_it_systems (
    it_system_key integer, it_system_code text, it_system_name text, system_domain text,
    criticality_tier text, target_uptime_pct numeric(9,6), default_sla_minutes integer, is_active boolean,
    dq_error boolean NOT NULL DEFAULT false, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_incident_categories (
    incident_category_key integer, incident_category_code text, incident_category_name text,
    category_group text, default_priority text, is_active boolean,
    dq_error boolean NOT NULL DEFAULT false, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_finance_monthly (
    month_start_date date, month_start_date_key integer, organization_key integer,
    department_key integer, cost_category_key integer, operating_revenue numeric(18,2),
    operating_cost numeric(18,2), fixed_cost_amount numeric(18,2), variable_cost_amount numeric(18,2),
    allocated_shared_cost_amount numeric(18,2), payroll_cost numeric(18,2), supplies_cost numeric(18,2),
    medication_cost numeric(18,2), facility_cost numeric(18,2), technology_other_cost numeric(18,2),
    driver_encounter_count integer, driver_procedure_count integer,
    dq_error boolean NOT NULL, dq_warning boolean NOT NULL, business_anomaly boolean NOT NULL, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_budget_monthly (
    month_start_date date, month_start_date_key integer, organization_key integer,
    department_key integer, budget_scenario_key integer, budget_revenue numeric(18,2),
    budget_operating_cost numeric(18,2), budget_payroll_cost numeric(18,2),
    budget_capital_amount numeric(18,2), budget_fte numeric(12,2), assumption_version text,
    dq_error boolean NOT NULL, dq_warning boolean NOT NULL, business_anomaly boolean NOT NULL, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_workforce_monthly (
    month_start_date date, month_start_date_key integer, organization_key integer,
    department_key integer, employee_role_key integer, headcount_start integer,
    headcount integer, headcount_end integer, average_headcount numeric(12,2),
    fte_start numeric(12,2), fte numeric(12,2), fte_end numeric(12,2), average_fte numeric(12,2),
    new_hires integer, turnover_count integer, vacancy_count integer,
    scheduled_hours numeric(16,2), worked_hours numeric(16,2), overtime_hours numeric(16,2),
    absence_hours numeric(16,2), payroll_cost numeric(18,2),
    dq_error boolean NOT NULL, dq_warning boolean NOT NULL, business_anomaly boolean NOT NULL, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_operations_daily (
    operation_date date, date_key integer, organization_key integer, department_key integer,
    licensed_beds integer, available_beds integer, occupied_beds integer,
    available_bed_days numeric(14,2), occupied_bed_days numeric(14,2), admissions integer,
    discharges integer, encounter_count integer, procedure_count integer,
    appointments_scheduled integer, appointments_completed integer, wait_minutes_total numeric(18,2),
    waited_encounter_count integer, average_waiting_time_minutes numeric(12,2),
    length_of_stay_days_total numeric(18,2), discharged_with_los_count integer,
    average_length_of_stay numeric(12,2), capacity_utilization numeric(12,8), throughput integer,
    overflow_capacity_flag boolean, dq_error boolean NOT NULL, dq_warning boolean NOT NULL,
    business_anomaly boolean NOT NULL, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_it_incident (
    incident_id text, opened_date_key integer, resolved_date_key integer, organization_key integer,
    department_key integer, it_system_key integer, incident_category_key integer,
    opened_at timestamptz, resolved_at timestamptz, severity text, status text, channel text,
    sla_class text, sla_target_minutes integer, resolution_minutes integer, sla_met_flag boolean,
    downtime_minutes integer, affected_users integer, business_impact_score numeric(10,2),
    dq_error boolean NOT NULL, dq_warning boolean NOT NULL, business_anomaly boolean NOT NULL, dq_notes text
);
CREATE TABLE IF NOT EXISTS staging.stg_enterprise_it_system_daily (
    metric_date date, date_key integer, organization_key integer, it_system_key integer,
    scheduled_minutes integer, availability_minutes integer, available_minutes integer,
    downtime_minutes integer, planned_downtime_minutes integer, unplanned_downtime_minutes integer,
    uptime_pct numeric(12,8), transaction_count bigint, active_users integer,
    peak_concurrent_users integer, response_time_ms numeric(14,2), error_count integer, incident_count integer,
    dq_error boolean NOT NULL, dq_warning boolean NOT NULL, business_anomaly boolean NOT NULL, dq_notes text
);

CREATE INDEX IF NOT EXISTS ix_stg_ent_finance_grain ON staging.stg_enterprise_finance_monthly(month_start_date_key,organization_key,department_key,cost_category_key);
CREATE INDEX IF NOT EXISTS ix_stg_ent_budget_grain ON staging.stg_enterprise_budget_monthly(month_start_date_key,organization_key,department_key,budget_scenario_key);
CREATE INDEX IF NOT EXISTS ix_stg_ent_workforce_grain ON staging.stg_enterprise_workforce_monthly(month_start_date_key,organization_key,department_key,employee_role_key);
CREATE INDEX IF NOT EXISTS ix_stg_ent_operations_grain ON staging.stg_enterprise_operations_daily(date_key,organization_key,department_key);
CREATE INDEX IF NOT EXISTS ix_stg_ent_it_daily_grain ON staging.stg_enterprise_it_system_daily(date_key,organization_key,it_system_key);

COMMIT;
