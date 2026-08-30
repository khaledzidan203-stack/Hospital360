-- Deterministic development reload for Hospital360 Analytics V1.
-- Reads staging only and writes analytics only.
\set ON_ERROR_STOP on

BEGIN;

TRUNCATE TABLE
    analytics.fact_claim_transaction,
    analytics.fact_condition_occurrence,
    analytics.fact_procedure,
    analytics.fact_claim,
    analytics.fact_encounter,
    analytics.dim_patient,
    analytics.dim_provider,
    analytics.dim_organization,
    analytics.dim_payer,
    analytics.dim_condition,
    analytics.dim_procedure,
    analytics.dim_date
RESTART IDENTITY;

-- Surrogate key 0 is the explicit Unknown/Unmapped member in every dimension.
INSERT INTO analytics.dim_date (date_key, full_date, year, quarter, month_number, month_name, year_month, day_of_month, day_name, day_of_week, week_of_year)
VALUES (0, NULL, NULL, NULL, NULL, 'Unknown', 'Unknown', NULL, 'Unknown', NULL, NULL);

INSERT INTO analytics.dim_patient (patient_key, patient_id, source_system, source_table)
VALUES (0, '__UNKNOWN__', 'HOSPITAL360', 'SYSTEM');
INSERT INTO analytics.dim_provider (provider_key, provider_id, is_inferred_reference, source_system, source_scope)
VALUES (0, '__UNKNOWN__', false, 'HOSPITAL360', 'SYSTEM');
INSERT INTO analytics.dim_organization (organization_key, organization_id, is_inferred_reference, source_system, source_scope)
VALUES (0, '__UNKNOWN__', false, 'HOSPITAL360', 'SYSTEM');
INSERT INTO analytics.dim_payer (payer_key, payer_id, is_inferred_reference, source_system, source_scope)
VALUES (0, '__UNKNOWN__', false, 'HOSPITAL360', 'SYSTEM');
INSERT INTO analytics.dim_condition (condition_key, code_system, condition_code, condition_description, source_system, source_table)
VALUES (0, '__UNKNOWN__', '__UNKNOWN__', 'Unknown / Unmapped', 'HOSPITAL360', 'SYSTEM');
INSERT INTO analytics.dim_procedure (procedure_key, code_system, procedure_code, procedure_description, source_system, source_table)
VALUES (0, '__UNKNOWN__', '__UNKNOWN__', 'Unknown / Unmapped', 'HOSPITAL360', 'SYSTEM');

-- Generate every calendar day in the relevant staged range, not only event days.
WITH source_dates(full_date) AS (
    SELECT birth_date FROM staging.stg_patients
    UNION ALL SELECT death_date FROM staging.stg_patients
    UNION ALL SELECT start_at::date FROM staging.stg_encounters
    UNION ALL SELECT stop_at::date FROM staging.stg_encounters
    UNION ALL SELECT current_illness_at::date FROM staging.stg_claims
    UNION ALL SELECT service_at::date FROM staging.stg_claims
    UNION ALL SELECT last_billed_at_1::date FROM staging.stg_claims
    UNION ALL SELECT last_billed_at_2::date FROM staging.stg_claims
    UNION ALL SELECT last_billed_at_primary::date FROM staging.stg_claims
    UNION ALL SELECT from_at::date FROM staging.stg_claim_transactions
    UNION ALL SELECT to_at::date FROM staging.stg_claim_transactions WHERE NOT dq_to_before_from
    UNION ALL SELECT start_date FROM staging.stg_condition_occurrences
    UNION ALL SELECT stop_date FROM staging.stg_condition_occurrences
    UNION ALL SELECT start_at::date FROM staging.stg_procedures
    UNION ALL SELECT stop_at::date FROM staging.stg_procedures
), bounds AS (
    SELECT min(full_date) AS min_date, max(full_date) AS max_date
    FROM source_dates
    WHERE full_date IS NOT NULL
), calendar AS (
    SELECT generate_series(min_date, max_date, interval '1 day')::date AS full_date
    FROM bounds
)
INSERT INTO analytics.dim_date (
    date_key, full_date, year, quarter, month_number, month_name, year_month,
    day_of_month, day_name, day_of_week, week_of_year
)
SELECT
    to_char(full_date, 'YYYYMMDD')::integer,
    full_date,
    extract(year FROM full_date)::smallint,
    extract(quarter FROM full_date)::smallint,
    extract(month FROM full_date)::smallint,
    trim(to_char(full_date, 'Month')),
    to_char(full_date, 'YYYY-MM'),
    extract(day FROM full_date)::smallint,
    trim(to_char(full_date, 'Day')),
    extract(isodow FROM full_date)::smallint,
    extract(week FROM full_date)::smallint
FROM calendar
ORDER BY full_date;

INSERT INTO analytics.dim_patient (
    patient_id, birth_date, death_date, marital_status, race, ethnicity, gender,
    birthplace, city, state, county, fips, zip, latitude, longitude,
    source_system, source_table, source_row_hash
)
SELECT patient_id, birth_date, death_date, marital_status, race, ethnicity, gender,
       birthplace, city, state, county, fips, zip, latitude, longitude,
       source_system, source_table, source_row_hash
FROM staging.stg_patients
ORDER BY patient_id;

WITH provider_roles AS (
    SELECT provider_id, 'encounter_provider' AS role FROM staging.stg_encounters
    UNION ALL SELECT provider_id, 'claim_provider' FROM staging.stg_claims
    UNION ALL SELECT supervising_provider_id, 'claim_supervisor' FROM staging.stg_claims
    UNION ALL SELECT referring_provider_id, 'claim_referrer' FROM staging.stg_claims
    UNION ALL SELECT provider_id, 'transaction_provider' FROM staging.stg_claim_transactions
    UNION ALL SELECT supervising_provider_id, 'transaction_supervisor' FROM staging.stg_claim_transactions
)
INSERT INTO analytics.dim_provider (
    provider_id, observed_as_encounter_provider, observed_as_claim_provider,
    observed_as_claim_supervisor, observed_as_claim_referrer,
    observed_as_transaction_provider, observed_as_transaction_supervisor,
    source_system, source_scope
)
SELECT provider_id,
       bool_or(role = 'encounter_provider'), bool_or(role = 'claim_provider'),
       bool_or(role = 'claim_supervisor'), bool_or(role = 'claim_referrer'),
       bool_or(role = 'transaction_provider'), bool_or(role = 'transaction_supervisor'),
       'SYNTHEA', 'Distinct references in approved staging tables'
FROM provider_roles
WHERE provider_id IS NOT NULL
GROUP BY provider_id
ORDER BY provider_id;

WITH organization_roles AS (
    SELECT organization_id, 'encounter_organization' AS role FROM staging.stg_encounters
    UNION ALL SELECT place_of_service_id, 'place_of_service' FROM staging.stg_claim_transactions
)
INSERT INTO analytics.dim_organization (
    organization_id, observed_as_encounter_organization,
    observed_as_place_of_service, source_system, source_scope
)
SELECT organization_id, bool_or(role = 'encounter_organization'),
       bool_or(role = 'place_of_service'), 'SYNTHEA',
       'Distinct references in approved staging tables'
FROM organization_roles
WHERE organization_id IS NOT NULL
GROUP BY organization_id
ORDER BY organization_id;

WITH payer_roles AS (
    SELECT payer_id, 'encounter_payer' AS role FROM staging.stg_encounters
    UNION ALL SELECT primary_patient_insurance_id, 'primary_claim_payer' FROM staging.stg_claims
    UNION ALL SELECT secondary_patient_insurance_id, 'secondary_claim_payer' FROM staging.stg_claims
)
INSERT INTO analytics.dim_payer (
    payer_id, observed_as_encounter_payer, observed_as_primary_claim_payer,
    observed_as_secondary_claim_payer, source_system, source_scope
)
SELECT payer_id, bool_or(role = 'encounter_payer'),
       bool_or(role = 'primary_claim_payer'), bool_or(role = 'secondary_claim_payer'),
       'SYNTHEA', 'Distinct references in approved staging tables'
FROM payer_roles
WHERE payer_id IS NOT NULL
GROUP BY payer_id
ORDER BY payer_id;

INSERT INTO analytics.dim_condition (
    code_system, condition_code, condition_description, source_system, source_table
)
SELECT code_system, condition_code, min(condition_description), 'SYNTHEA',
       'staging.stg_condition_occurrences'
FROM staging.stg_condition_occurrences
WHERE code_system IS NOT NULL AND condition_code IS NOT NULL
GROUP BY code_system, condition_code
ORDER BY code_system, condition_code;

INSERT INTO analytics.dim_procedure (
    code_system, procedure_code, procedure_description, source_system, source_table
)
SELECT code_system, procedure_code, min(procedure_description), 'SYNTHEA',
       'staging.stg_procedures'
FROM staging.stg_procedures
WHERE code_system IS NOT NULL AND procedure_code IS NOT NULL
GROUP BY code_system, procedure_code
ORDER BY code_system, procedure_code;

INSERT INTO analytics.fact_encounter (
    encounter_id, patient_key, provider_key, organization_key, payer_key,
    start_date_key, stop_date_key, start_at, stop_at, encounter_class,
    encounter_code, encounter_description, reason_code, reason_description,
    base_encounter_cost, total_claim_cost, payer_coverage,
    source_system, source_table, source_row_hash
)
SELECT s.encounter_id, COALESCE(p.patient_key,0), COALESCE(v.provider_key,0),
       COALESCE(o.organization_key,0), COALESCE(y.payer_key,0),
       COALESCE(ds.date_key,0), COALESCE(de.date_key,0), s.start_at, s.stop_at,
       s.encounter_class, s.encounter_code, s.encounter_description,
       s.reason_code, s.reason_description, s.base_encounter_cost,
       s.total_claim_cost, s.payer_coverage, s.source_system, s.source_table,
       s.source_row_hash
FROM staging.stg_encounters s
LEFT JOIN analytics.dim_patient p ON p.patient_id=s.patient_id
LEFT JOIN analytics.dim_provider v ON v.provider_id=s.provider_id
LEFT JOIN analytics.dim_organization o ON o.organization_id=s.organization_id
LEFT JOIN analytics.dim_payer y ON y.payer_id=s.payer_id
LEFT JOIN analytics.dim_date ds ON ds.full_date=s.start_at::date
LEFT JOIN analytics.dim_date de ON de.full_date=s.stop_at::date
ORDER BY s.encounter_id;

INSERT INTO analytics.fact_claim (
    claim_id, encounter_id, patient_key, provider_key, supervising_provider_key,
    referring_provider_key, organization_key, primary_payer_key,
    secondary_payer_key, current_illness_date_key, service_date_key,
    last_billed_date_key_1, last_billed_date_key_2,
    last_billed_date_key_primary, current_illness_at, service_at,
    last_billed_at_1, last_billed_at_2, last_billed_at_primary,
    department_id, patient_department_id, status_1, status_2, status_primary,
    healthcare_claim_type_id_1, healthcare_claim_type_id_2,
    diagnosis_1, diagnosis_2, diagnosis_3, diagnosis_4, diagnosis_5,
    diagnosis_6, diagnosis_7, diagnosis_8, outstanding_1, outstanding_2,
    outstanding_primary, source_system, source_table, source_row_hash
)
SELECT s.claim_id, s.appointment_id, COALESCE(p.patient_key,0),
       COALESCE(v.provider_key,0), COALESCE(sv.provider_key,0),
       COALESCE(rv.provider_key,0), COALESCE(o.organization_key,0),
       COALESCE(py.payer_key,0), COALESCE(sy.payer_key,0),
       COALESCE(di.date_key,0), COALESCE(ds.date_key,0),
       COALESCE(db1.date_key,0), COALESCE(db2.date_key,0),
       COALESCE(dbp.date_key,0), s.current_illness_at, s.service_at,
       s.last_billed_at_1, s.last_billed_at_2, s.last_billed_at_primary,
       s.department_id, s.patient_department_id, s.status_1, s.status_2,
       s.status_primary, s.healthcare_claim_type_id_1,
       s.healthcare_claim_type_id_2, s.diagnosis_1, s.diagnosis_2,
       s.diagnosis_3, s.diagnosis_4, s.diagnosis_5, s.diagnosis_6,
       s.diagnosis_7, s.diagnosis_8, s.outstanding_1, s.outstanding_2,
       s.outstanding_primary, s.source_system, s.source_table, s.source_row_hash
FROM staging.stg_claims s
LEFT JOIN staging.stg_encounters e ON e.encounter_id=s.appointment_id
LEFT JOIN analytics.dim_patient p ON p.patient_id=s.patient_id
LEFT JOIN analytics.dim_provider v ON v.provider_id=s.provider_id
LEFT JOIN analytics.dim_provider sv ON sv.provider_id=s.supervising_provider_id
LEFT JOIN analytics.dim_provider rv ON rv.provider_id=s.referring_provider_id
LEFT JOIN analytics.dim_organization o ON o.organization_id=e.organization_id
LEFT JOIN analytics.dim_payer py ON py.payer_id=s.primary_patient_insurance_id
LEFT JOIN analytics.dim_payer sy ON sy.payer_id=s.secondary_patient_insurance_id
LEFT JOIN analytics.dim_date di ON di.full_date=s.current_illness_at::date
LEFT JOIN analytics.dim_date ds ON ds.full_date=s.service_at::date
LEFT JOIN analytics.dim_date db1 ON db1.full_date=s.last_billed_at_1::date
LEFT JOIN analytics.dim_date db2 ON db2.full_date=s.last_billed_at_2::date
LEFT JOIN analytics.dim_date dbp ON dbp.full_date=s.last_billed_at_primary::date
ORDER BY s.claim_id;

INSERT INTO analytics.fact_claim_transaction (
    transaction_id, claim_id, encounter_id, charge_id, patient_key,
    provider_key, supervising_provider_key, organization_key,
    claim_primary_payer_key, from_date_key, to_date_key, from_at, to_at,
    transaction_type, method, procedure_code, modifier_1, modifier_2,
    diagnosis_ref_1, diagnosis_ref_2, diagnosis_ref_3, diagnosis_ref_4,
    department_id, transfer_out_id, transfer_type, patient_insurance_id,
    fee_schedule_id, units, amount, unit_amount, payments, adjustments,
    transfers, outstanding, source_unset_to_timestamp_warning,
    source_system, source_table, source_row_hash
)
SELECT s.transaction_id, s.claim_id, s.appointment_id, s.charge_id,
       COALESCE(p.patient_key,0), COALESCE(v.provider_key,0),
       COALESCE(sv.provider_key,0), COALESCE(o.organization_key,0),
       COALESCE(py.payer_key,0), COALESCE(df.date_key,0),
       CASE WHEN s.dq_to_before_from THEN 0 ELSE COALESCE(dt.date_key,0) END,
       s.from_at, s.to_at, s.transaction_type, s.method, s.procedure_code,
       s.modifier_1, s.modifier_2, s.diagnosis_ref_1, s.diagnosis_ref_2,
       s.diagnosis_ref_3, s.diagnosis_ref_4, s.department_id,
       s.transfer_out_id, s.transfer_type, s.patient_insurance_id,
       s.fee_schedule_id, s.units, s.amount, s.unit_amount, s.payments,
       s.adjustments, s.transfers, s.outstanding, s.dq_to_before_from,
       s.source_system, s.source_table, s.source_row_hash
FROM staging.stg_claim_transactions s
LEFT JOIN staging.stg_claims c ON c.claim_id=s.claim_id
LEFT JOIN analytics.dim_patient p ON p.patient_id=s.patient_id
LEFT JOIN analytics.dim_provider v ON v.provider_id=s.provider_id
LEFT JOIN analytics.dim_provider sv ON sv.provider_id=s.supervising_provider_id
LEFT JOIN analytics.dim_organization o ON o.organization_id=s.place_of_service_id
LEFT JOIN analytics.dim_payer py ON py.payer_id=c.primary_patient_insurance_id
LEFT JOIN analytics.dim_date df ON df.full_date=s.from_at::date
LEFT JOIN analytics.dim_date dt ON dt.full_date=s.to_at::date AND NOT s.dq_to_before_from
ORDER BY s.transaction_id;

INSERT INTO analytics.fact_condition_occurrence (
    encounter_id, patient_key, condition_key, encounter_provider_key,
    encounter_organization_key, encounter_payer_key, start_date_key,
    stop_date_key, start_date, stop_date, source_system, source_table,
    source_row_hash
)
SELECT s.encounter_id, COALESCE(p.patient_key,0), COALESCE(c.condition_key,0),
       COALESCE(v.provider_key,0), COALESCE(o.organization_key,0),
       COALESCE(y.payer_key,0), COALESCE(ds.date_key,0),
       COALESCE(de.date_key,0), s.start_date, s.stop_date,
       s.source_system, s.source_table, s.source_row_hash
FROM staging.stg_condition_occurrences s
LEFT JOIN staging.stg_encounters e ON e.encounter_id=s.encounter_id
LEFT JOIN analytics.dim_patient p ON p.patient_id=s.patient_id
LEFT JOIN analytics.dim_condition c ON c.code_system=s.code_system AND c.condition_code=s.condition_code
LEFT JOIN analytics.dim_provider v ON v.provider_id=e.provider_id
LEFT JOIN analytics.dim_organization o ON o.organization_id=e.organization_id
LEFT JOIN analytics.dim_payer y ON y.payer_id=e.payer_id
LEFT JOIN analytics.dim_date ds ON ds.full_date=s.start_date
LEFT JOIN analytics.dim_date de ON de.full_date=s.stop_date
ORDER BY s.patient_id, s.encounter_id, s.start_date, s.condition_code, s.source_row_hash;

INSERT INTO analytics.fact_procedure (
    encounter_id, patient_key, procedure_key, encounter_provider_key,
    encounter_organization_key, encounter_payer_key, start_date_key,
    stop_date_key, start_at, stop_at, reason_code, reason_description,
    base_cost, source_system, source_table, source_row_hash
)
SELECT s.encounter_id, COALESCE(p.patient_key,0), COALESCE(c.procedure_key,0),
       COALESCE(v.provider_key,0), COALESCE(o.organization_key,0),
       COALESCE(y.payer_key,0), COALESCE(ds.date_key,0),
       COALESCE(de.date_key,0), s.start_at, s.stop_at, s.reason_code,
       s.reason_description, s.base_cost, s.source_system, s.source_table,
       s.source_row_hash
FROM staging.stg_procedures s
LEFT JOIN staging.stg_encounters e ON e.encounter_id=s.encounter_id
LEFT JOIN analytics.dim_patient p ON p.patient_id=s.patient_id
LEFT JOIN analytics.dim_procedure c ON c.code_system=s.code_system AND c.procedure_code=s.procedure_code
LEFT JOIN analytics.dim_provider v ON v.provider_id=e.provider_id
LEFT JOIN analytics.dim_organization o ON o.organization_id=e.organization_id
LEFT JOIN analytics.dim_payer y ON y.payer_id=e.payer_id
LEFT JOIN analytics.dim_date ds ON ds.full_date=s.start_at::date
LEFT JOIN analytics.dim_date de ON de.full_date=s.stop_at::date
ORDER BY s.patient_id, s.encounter_id, s.start_at, s.procedure_code, s.source_row_hash;

COMMIT;
