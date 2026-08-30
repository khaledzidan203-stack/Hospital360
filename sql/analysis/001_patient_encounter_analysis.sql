-- Hospital360 V1: Patient and encounter activity.
-- Read-only. Fact grain: one row per encounter event unless stated otherwise.
\set ON_ERROR_STOP on
\pset pager off
BEGIN TRANSACTION READ ONLY;

-- Analysis PE01: total current-state patients and encounter events.
SELECT
    (SELECT count(*) FROM analytics.dim_patient WHERE patient_key <> 0) AS total_patients,
    (SELECT count(*) FROM analytics.fact_encounter) AS total_encounters;

-- Validation PE01: patient natural keys and encounter business keys remain unique.
SELECT
    count(*) FILTER (WHERE patient_key <> 0) AS patient_rows,
    count(DISTINCT patient_id) FILTER (WHERE patient_key <> 0) AS distinct_patient_ids,
    (SELECT count(*) FROM analytics.fact_encounter) AS encounter_rows,
    (SELECT count(DISTINCT encounter_id) FROM analytics.fact_encounter) AS distinct_encounter_ids
FROM analytics.dim_patient;

-- Analysis PE02: encounters per patient, including patients with zero encounters.
-- Dimension grain: one row per patient. Measure comes only from Fact_Encounter.
SELECT
    p.patient_id,
    count(e.encounter_fact_key) AS encounter_count,
    round(avg(count(e.encounter_fact_key)) OVER (), 2) AS average_encounters_across_patients,
    dense_rank() OVER (ORDER BY count(e.encounter_fact_key) DESC) AS encounter_volume_rank
FROM analytics.dim_patient p
LEFT JOIN analytics.fact_encounter e ON e.patient_key = p.patient_key
WHERE p.patient_key <> 0
GROUP BY p.patient_id
ORDER BY encounter_count DESC, p.patient_id;

-- Validation PE02: summing patient-level encounter counts must equal the fact total.
WITH by_patient AS (
    SELECT patient_key, count(*) AS encounter_count
    FROM analytics.fact_encounter
    GROUP BY patient_key
)
SELECT
    sum(encounter_count) AS grouped_encounters,
    (SELECT count(*) FROM analytics.fact_encounter) AS fact_encounters,
    sum(encounter_count) - (SELECT count(*) FROM analytics.fact_encounter) AS difference
FROM by_patient;

-- Analysis PE03: monthly encounter trend using the encounter start-date role.
SELECT
    date_trunc('month', d.full_date)::date AS encounter_month,
    count(*) AS encounter_count,
    count(DISTINCT e.patient_key) AS active_patient_count
FROM analytics.fact_encounter e
JOIN analytics.dim_date d ON d.date_key = e.start_date_key
WHERE d.date_key <> 0
GROUP BY date_trunc('month', d.full_date)
ORDER BY encounter_month;

-- Analysis PE04: encounter distribution by source class and type/code.
SELECT
    coalesce(encounter_class, 'Unknown') AS encounter_class,
    coalesce(encounter_code, 'Unknown') AS encounter_code,
    coalesce(encounter_description, 'Unknown') AS encounter_description,
    count(*) AS encounter_count,
    round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS encounter_contribution_pct
FROM analytics.fact_encounter
GROUP BY encounter_class, encounter_code, encounter_description
ORDER BY encounter_count DESC, encounter_class, encounter_code;

-- Validation PE04: grouped counts and percentage contribution reconcile.
WITH grouped AS (
    SELECT encounter_class, encounter_code, count(*) AS encounter_count
    FROM analytics.fact_encounter
    GROUP BY encounter_class, encounter_code
), validated AS (
    SELECT encounter_count,
           100.0 * encounter_count / sum(encounter_count) OVER () AS contribution_pct
    FROM grouped
)
SELECT
    sum(encounter_count) AS grouped_encounters,
    (SELECT count(*) FROM analytics.fact_encounter) AS fact_encounters,
    sum(encounter_count) - (SELECT count(*) FROM analytics.fact_encounter) AS difference,
    round(sum(contribution_pct), 2) AS contribution_pct
FROM validated;

-- Analysis PE05: encounter duration in minutes for chronologically valid events.
SELECT
    count(*) FILTER (WHERE start_at IS NOT NULL AND stop_at IS NOT NULL AND stop_at >= start_at) AS eligible_encounters,
    round((avg(extract(epoch FROM (stop_at - start_at)) / 60.0)
          FILTER (WHERE start_at IS NOT NULL AND stop_at IS NOT NULL AND stop_at >= start_at))::numeric, 2) AS average_duration_minutes,
    round((percentile_cont(0.5) WITHIN GROUP (ORDER BY extract(epoch FROM (stop_at - start_at)) / 60.0)
          FILTER (WHERE start_at IS NOT NULL AND stop_at IS NOT NULL AND stop_at >= start_at))::numeric, 2) AS median_duration_minutes
FROM analytics.fact_encounter;

-- Analysis PE06: encounter volume by organization.
SELECT
    o.organization_id,
    count(*) AS encounter_count,
    count(DISTINCT e.patient_key) AS patient_count,
    dense_rank() OVER (ORDER BY count(*) DESC) AS organization_volume_rank
FROM analytics.fact_encounter e
JOIN analytics.dim_organization o ON o.organization_key = e.organization_key
GROUP BY o.organization_id
ORDER BY encounter_count DESC, o.organization_id;

-- Analysis PE07: encounter volume by provider.
SELECT
    p.provider_id,
    count(*) AS encounter_count,
    count(DISTINCT e.patient_key) AS patient_count,
    dense_rank() OVER (ORDER BY count(*) DESC) AS provider_volume_rank
FROM analytics.fact_encounter e
JOIN analytics.dim_provider p ON p.provider_key = e.provider_key
GROUP BY p.provider_id
ORDER BY encounter_count DESC, p.provider_id;

-- Validation PE06/PE07: each one-to-many dimension grouping retains the fact total.
WITH organization_totals AS (
    SELECT organization_key, count(*) AS n FROM analytics.fact_encounter GROUP BY organization_key
), provider_totals AS (
    SELECT provider_key, count(*) AS n FROM analytics.fact_encounter GROUP BY provider_key
)
SELECT
    (SELECT sum(n) FROM organization_totals) AS encounters_by_organization,
    (SELECT sum(n) FROM provider_totals) AS encounters_by_provider,
    (SELECT count(*) FROM analytics.fact_encounter) AS fact_encounters;

ROLLBACK;
