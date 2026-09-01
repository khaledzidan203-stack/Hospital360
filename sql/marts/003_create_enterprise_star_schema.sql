-- Hospital360 Enterprise V1 analytics dimensions and facts.
\set ON_ERROR_STOP on

BEGIN;

CREATE TABLE IF NOT EXISTS analytics.dim_department (
    department_key integer PRIMARY KEY, department_code text NOT NULL,
    department_name text NOT NULL, department_type text NOT NULL,
    clinical_flag boolean NOT NULL, capacity_managed_flag boolean NOT NULL,
    bed_applicable_flag boolean NOT NULL, organization_key integer NOT NULL,
    organization_id text NOT NULL, effective_start_date date,
    effective_end_date date, is_active boolean NOT NULL, source_system text NOT NULL,
    UNIQUE (organization_id, department_code)
);
CREATE TABLE IF NOT EXISTS analytics.dim_cost_category (
    cost_category_key integer PRIMARY KEY, cost_category_code text NOT NULL UNIQUE,
    cost_category_name text NOT NULL, cost_behavior text NOT NULL,
    payroll_flag boolean NOT NULL, display_order smallint NOT NULL, is_active boolean NOT NULL
);
CREATE TABLE IF NOT EXISTS analytics.dim_budget_scenario (
    budget_scenario_key integer PRIMARY KEY, budget_scenario_code text NOT NULL UNIQUE,
    budget_scenario_name text NOT NULL, scenario_type text NOT NULL,
    display_order smallint NOT NULL, is_active boolean NOT NULL
);
CREATE TABLE IF NOT EXISTS analytics.dim_employee_role (
    employee_role_key integer PRIMARY KEY, employee_role_code text NOT NULL UNIQUE,
    employee_role_name text NOT NULL, role_family text NOT NULL,
    clinical_flag boolean NOT NULL, standard_hours_per_fte_month numeric(10,2) NOT NULL,
    is_active boolean NOT NULL
);
CREATE TABLE IF NOT EXISTS analytics.dim_it_system (
    it_system_key integer PRIMARY KEY, it_system_code text NOT NULL UNIQUE,
    it_system_name text NOT NULL, system_domain text NOT NULL, criticality_tier text NOT NULL,
    target_uptime_pct numeric(9,6) NOT NULL, default_sla_minutes integer NOT NULL, is_active boolean NOT NULL
);
CREATE TABLE IF NOT EXISTS analytics.dim_incident_category (
    incident_category_key integer PRIMARY KEY, incident_category_code text NOT NULL UNIQUE,
    incident_category_name text NOT NULL, category_group text NOT NULL,
    default_priority text NOT NULL, is_active boolean NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.fact_finance_monthly (
    finance_monthly_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    month_start_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    organization_key integer NOT NULL REFERENCES analytics.dim_organization(organization_key),
    department_key integer NOT NULL REFERENCES analytics.dim_department(department_key),
    cost_category_key integer NOT NULL REFERENCES analytics.dim_cost_category(cost_category_key),
    operating_revenue numeric(18,2) NOT NULL, operating_cost numeric(18,2) NOT NULL,
    fixed_cost_amount numeric(18,2) NOT NULL, variable_cost_amount numeric(18,2) NOT NULL,
    allocated_shared_cost_amount numeric(18,2) NOT NULL, payroll_cost numeric(18,2) NOT NULL,
    supplies_cost numeric(18,2) NOT NULL, medication_cost numeric(18,2) NOT NULL,
    facility_cost numeric(18,2) NOT NULL, technology_other_cost numeric(18,2) NOT NULL,
    driver_encounter_count integer NOT NULL, driver_procedure_count integer NOT NULL,
    dq_warning boolean NOT NULL, business_anomaly boolean NOT NULL, dq_notes text,
    UNIQUE(month_start_date_key,organization_key,department_key,cost_category_key)
);
CREATE TABLE IF NOT EXISTS analytics.fact_budget_monthly (
    budget_monthly_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    month_start_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    organization_key integer NOT NULL REFERENCES analytics.dim_organization(organization_key),
    department_key integer NOT NULL REFERENCES analytics.dim_department(department_key),
    budget_scenario_key integer NOT NULL REFERENCES analytics.dim_budget_scenario(budget_scenario_key),
    budget_revenue numeric(18,2) NOT NULL, budget_operating_cost numeric(18,2) NOT NULL,
    budget_payroll_cost numeric(18,2) NOT NULL, budget_capital_amount numeric(18,2) NOT NULL,
    budget_fte numeric(12,2) NOT NULL, assumption_version text NOT NULL,
    dq_warning boolean NOT NULL, business_anomaly boolean NOT NULL, dq_notes text,
    UNIQUE(month_start_date_key,organization_key,department_key,budget_scenario_key)
);
CREATE TABLE IF NOT EXISTS analytics.fact_workforce_monthly (
    workforce_monthly_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    month_start_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    organization_key integer NOT NULL REFERENCES analytics.dim_organization(organization_key),
    department_key integer NOT NULL REFERENCES analytics.dim_department(department_key),
    employee_role_key integer NOT NULL REFERENCES analytics.dim_employee_role(employee_role_key),
    headcount_start integer NOT NULL, headcount integer NOT NULL, headcount_end integer NOT NULL,
    average_headcount numeric(12,2) NOT NULL, fte_start numeric(12,2) NOT NULL,
    fte numeric(12,2) NOT NULL, fte_end numeric(12,2) NOT NULL, average_fte numeric(12,2) NOT NULL,
    new_hires integer NOT NULL, turnover_count integer NOT NULL, vacancy_count integer NOT NULL,
    scheduled_hours numeric(16,2) NOT NULL, worked_hours numeric(16,2) NOT NULL,
    overtime_hours numeric(16,2) NOT NULL, absence_hours numeric(16,2) NOT NULL,
    payroll_cost numeric(18,2) NOT NULL, dq_warning boolean NOT NULL,
    business_anomaly boolean NOT NULL, dq_notes text,
    UNIQUE(month_start_date_key,organization_key,department_key,employee_role_key)
);
CREATE TABLE IF NOT EXISTS analytics.fact_operations_daily (
    operations_daily_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    organization_key integer NOT NULL REFERENCES analytics.dim_organization(organization_key),
    department_key integer NOT NULL REFERENCES analytics.dim_department(department_key),
    licensed_beds integer, available_beds integer, occupied_beds integer,
    available_bed_days numeric(14,2), occupied_bed_days numeric(14,2),
    admissions integer, discharges integer, encounter_count integer NOT NULL,
    procedure_count integer NOT NULL, appointments_scheduled integer,
    appointments_completed integer, wait_minutes_total numeric(18,2) NOT NULL,
    waited_encounter_count integer NOT NULL, average_waiting_time_minutes numeric(12,2) NOT NULL,
    length_of_stay_days_total numeric(18,2) NOT NULL, discharged_with_los_count integer NOT NULL,
    average_length_of_stay numeric(12,2), capacity_utilization numeric(12,8),
    throughput integer NOT NULL, overflow_capacity_flag boolean NOT NULL,
    dq_warning boolean NOT NULL, business_anomaly boolean NOT NULL, dq_notes text,
    UNIQUE(date_key,organization_key,department_key)
);
CREATE TABLE IF NOT EXISTS analytics.fact_it_incident (
    it_incident_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    incident_id text NOT NULL UNIQUE,
    opened_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    resolved_date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    organization_key integer NOT NULL REFERENCES analytics.dim_organization(organization_key),
    department_key integer NOT NULL REFERENCES analytics.dim_department(department_key),
    it_system_key integer NOT NULL REFERENCES analytics.dim_it_system(it_system_key),
    incident_category_key integer NOT NULL REFERENCES analytics.dim_incident_category(incident_category_key),
    opened_at timestamptz NOT NULL, resolved_at timestamptz, severity text NOT NULL,
    status text NOT NULL, channel text NOT NULL, sla_class text NOT NULL,
    sla_target_minutes integer NOT NULL, resolution_minutes integer, sla_met_flag boolean,
    downtime_minutes integer NOT NULL, affected_users integer NOT NULL,
    business_impact_score numeric(10,2) NOT NULL, dq_warning boolean NOT NULL,
    business_anomaly boolean NOT NULL, dq_notes text
);
CREATE TABLE IF NOT EXISTS analytics.fact_it_system_daily (
    it_system_daily_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key integer NOT NULL REFERENCES analytics.dim_date(date_key),
    organization_key integer NOT NULL REFERENCES analytics.dim_organization(organization_key),
    it_system_key integer NOT NULL REFERENCES analytics.dim_it_system(it_system_key),
    scheduled_minutes integer NOT NULL, availability_minutes integer NOT NULL,
    available_minutes integer NOT NULL, downtime_minutes integer NOT NULL,
    planned_downtime_minutes integer NOT NULL, unplanned_downtime_minutes integer NOT NULL,
    uptime_pct numeric(12,8) NOT NULL, transaction_count bigint NOT NULL,
    active_users integer NOT NULL, peak_concurrent_users integer NOT NULL,
    response_time_ms numeric(14,2) NOT NULL, error_count integer NOT NULL,
    incident_count integer NOT NULL, dq_warning boolean NOT NULL,
    business_anomaly boolean NOT NULL, dq_notes text,
    UNIQUE(date_key,organization_key,it_system_key)
);

CREATE INDEX IF NOT EXISTS ix_ent_finance_date ON analytics.fact_finance_monthly(month_start_date_key);
CREATE INDEX IF NOT EXISTS ix_ent_budget_date ON analytics.fact_budget_monthly(month_start_date_key);
CREATE INDEX IF NOT EXISTS ix_ent_workforce_date ON analytics.fact_workforce_monthly(month_start_date_key);
CREATE INDEX IF NOT EXISTS ix_ent_operations_date ON analytics.fact_operations_daily(date_key);
CREATE INDEX IF NOT EXISTS ix_ent_incident_opened ON analytics.fact_it_incident(opened_date_key);
CREATE INDEX IF NOT EXISTS ix_ent_it_daily_date ON analytics.fact_it_system_daily(date_key);

COMMIT;
