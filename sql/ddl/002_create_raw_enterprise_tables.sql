-- Hospital360 Enterprise V1 RAW landing tables.
-- Source-preserving text columns; no business transformations or analytical FKs.
\set ON_ERROR_STOP on

BEGIN;

CREATE TABLE IF NOT EXISTS raw.enterprise_departments (
    department_key text, department_code text, department_name text, department_type text,
    clinical_flag text, capacity_managed_flag text, bed_applicable_flag text,
    organization_key text, organization_id text, effective_start_date text,
    effective_end_date text, is_active text, source_system text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_cost_categories (
    cost_category_key text, cost_category_code text, cost_category_name text,
    cost_behavior text, payroll_flag text, display_order text, is_active text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_budget_scenarios (
    budget_scenario_key text, budget_scenario_code text, budget_scenario_name text,
    scenario_type text, display_order text, is_active text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_employee_roles (
    employee_role_key text, employee_role_code text, employee_role_name text,
    role_family text, clinical_flag text, standard_hours_per_fte_month text, is_active text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_it_systems (
    it_system_key text, it_system_code text, it_system_name text, system_domain text,
    criticality_tier text, target_uptime_pct text, default_sla_minutes text, is_active text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_incident_categories (
    incident_category_key text, incident_category_code text, incident_category_name text,
    category_group text, default_priority text, is_active text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_finance_monthly (
    month_start_date text, month_start_date_key text, organization_key text, department_key text,
    cost_category_key text, operating_revenue text, operating_cost text, fixed_cost_amount text,
    variable_cost_amount text, allocated_shared_cost_amount text, payroll_cost text,
    supplies_cost text, medication_cost text, facility_cost text, technology_other_cost text,
    driver_encounter_count text, driver_procedure_count text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_budget_monthly (
    month_start_date text, month_start_date_key text, organization_key text, department_key text,
    budget_scenario_key text, budget_revenue text, budget_operating_cost text,
    budget_payroll_cost text, budget_capital_amount text, budget_fte text, assumption_version text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_workforce_monthly (
    month_start_date text, month_start_date_key text, organization_key text, department_key text,
    employee_role_key text, headcount_start text, headcount text, headcount_end text,
    average_headcount text, fte_start text, fte text, fte_end text, average_fte text,
    new_hires text, turnover_count text, vacancy_count text, scheduled_hours text,
    worked_hours text, overtime_hours text, absence_hours text, payroll_cost text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_operations_daily (
    date text, date_key text, organization_key text, department_key text, licensed_beds text,
    available_beds text, occupied_beds text, available_bed_days text, occupied_bed_days text,
    admissions text, discharges text, encounter_count text, procedure_count text,
    appointments_scheduled text, appointments_completed text, wait_minutes_total text,
    waited_encounter_count text, average_waiting_time_minutes text,
    length_of_stay_days_total text, discharged_with_los_count text,
    average_length_of_stay text, capacity_utilization text, throughput text,
    overflow_capacity_flag text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_it_incident (
    incident_id text, opened_date_key text, resolved_date_key text, organization_key text,
    department_key text, it_system_key text, incident_category_key text, opened_at text,
    resolved_at text, severity text, status text, channel text, sla_class text,
    sla_target_minutes text, resolution_minutes text, sla_met_flag text,
    downtime_minutes text, affected_users text, business_impact_score text
);
CREATE TABLE IF NOT EXISTS raw.enterprise_it_system_daily (
    date text, organization_key text, it_system_key text, date_key text,
    scheduled_minutes text, availability_minutes text, available_minutes text,
    downtime_minutes text, planned_downtime_minutes text, unplanned_downtime_minutes text,
    uptime_pct text, transaction_count text, active_users text, peak_concurrent_users text,
    response_time_ms text, error_count text, incident_count text
);

COMMENT ON TABLE raw.enterprise_finance_monthly IS 'Source-preserving landing for final synthetic enterprise finance monthly CSV.';
COMMENT ON TABLE raw.enterprise_budget_monthly IS 'Source-preserving landing for final synthetic enterprise budget monthly CSV.';
COMMENT ON TABLE raw.enterprise_workforce_monthly IS 'Source-preserving landing for final synthetic enterprise workforce monthly CSV.';
COMMENT ON TABLE raw.enterprise_operations_daily IS 'Source-preserving landing for final synthetic enterprise operations daily CSV.';
COMMENT ON TABLE raw.enterprise_it_incident IS 'Source-preserving landing for final synthetic enterprise IT incident CSV.';
COMMENT ON TABLE raw.enterprise_it_system_daily IS 'Source-preserving landing for final synthetic enterprise IT system daily CSV.';

COMMIT;
