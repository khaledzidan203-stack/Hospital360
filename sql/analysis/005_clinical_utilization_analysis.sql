-- Hospital360 V1: Clinical service utilization.
-- Read-only. Condition and procedure occurrences remain separate fact grains.
\set ON_ERROR_STOP on
\pset pager off
BEGIN TRANSACTION READ ONLY;

-- Analysis CU01: procedure occurrence and cost baseline.
SELECT
    count(*) AS procedure_count,
    count(DISTINCT patient_key) AS patients_with_procedures,
    count(DISTINCT encounter_id) AS encounters_with_procedures,
    sum(base_cost) AS procedure_base_cost
FROM analytics.fact_procedure;

-- Analysis CU02: procedures by concept/type with frequency and cost rankings.
SELECT
    d.code_system,
    d.procedure_code,
    d.procedure_description,
    count(*) AS procedure_count,
    count(DISTINCT f.patient_key) AS patient_count,
    sum(f.base_cost) AS procedure_base_cost,
    dense_rank() OVER (ORDER BY count(*) DESC) AS frequency_rank,
    dense_rank() OVER (ORDER BY sum(f.base_cost) DESC NULLS LAST) AS cost_rank,
    round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS procedure_contribution_pct
FROM analytics.fact_procedure f
JOIN analytics.dim_procedure d ON d.procedure_key = f.procedure_key
GROUP BY d.code_system, d.procedure_code, d.procedure_description
ORDER BY frequency_rank, cost_rank, d.procedure_code;

-- Analysis CU03: top 20 procedures by frequency.
SELECT
    d.procedure_code,
    d.procedure_description,
    count(*) AS procedure_count,
    sum(f.base_cost) AS procedure_base_cost
FROM analytics.fact_procedure f
JOIN analytics.dim_procedure d ON d.procedure_key = f.procedure_key
GROUP BY d.procedure_code, d.procedure_description
ORDER BY procedure_count DESC, d.procedure_code
FETCH FIRST 20 ROWS WITH TIES;

-- Analysis CU04: top 20 procedures by source base cost.
SELECT
    d.procedure_code,
    d.procedure_description,
    count(*) AS procedure_count,
    sum(f.base_cost) AS procedure_base_cost
FROM analytics.fact_procedure f
JOIN analytics.dim_procedure d ON d.procedure_key = f.procedure_key
GROUP BY d.procedure_code, d.procedure_description
ORDER BY procedure_base_cost DESC NULLS LAST, d.procedure_code
FETCH FIRST 20 ROWS WITH TIES;

-- Validation CU01-CU04: concept grouping retains procedure rows and base cost.
WITH by_concept AS (
    SELECT procedure_key, count(*) n, sum(base_cost) base_cost
    FROM analytics.fact_procedure
    GROUP BY procedure_key
)
SELECT
    sum(n) AS grouped_procedures,
    (SELECT count(*) FROM analytics.fact_procedure) AS fact_procedures,
    sum(base_cost) AS grouped_base_cost,
    (SELECT sum(base_cost) FROM analytics.fact_procedure) AS fact_base_cost,
    sum(base_cost) - (SELECT sum(base_cost) FROM analytics.fact_procedure) AS cost_difference
FROM by_concept;

-- Analysis CU05: condition occurrence baseline.
SELECT
    count(*) AS condition_occurrence_count,
    count(DISTINCT patient_key) AS patients_with_conditions,
    count(DISTINCT encounter_id) AS encounters_with_conditions
FROM analytics.fact_condition_occurrence;

-- Analysis CU06: top conditions by recorded occurrence frequency.
SELECT
    d.code_system,
    d.condition_code,
    d.condition_description,
    count(*) AS occurrence_count,
    count(DISTINCT f.patient_key) AS patient_count,
    count(DISTINCT f.encounter_id) AS encounter_count,
    dense_rank() OVER (ORDER BY count(*) DESC) AS frequency_rank,
    round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS occurrence_contribution_pct
FROM analytics.fact_condition_occurrence f
JOIN analytics.dim_condition d ON d.condition_key = f.condition_key
GROUP BY d.code_system, d.condition_code, d.condition_description
ORDER BY frequency_rank, d.condition_code
FETCH FIRST 20 ROWS WITH TIES;

-- Analysis CU07: condition occurrences per patient.
SELECT
    p.patient_id,
    count(f.condition_occurrence_fact_key) AS condition_occurrence_count,
    count(DISTINCT f.condition_key) AS distinct_condition_concepts,
    count(DISTINCT f.encounter_id) AS encounters_with_conditions,
    dense_rank() OVER (ORDER BY count(f.condition_occurrence_fact_key) DESC) AS occurrence_rank
FROM analytics.dim_patient p
LEFT JOIN analytics.fact_condition_occurrence f ON f.patient_key = p.patient_key
WHERE p.patient_key <> 0
GROUP BY p.patient_id
ORDER BY occurrence_rank, p.patient_id;

-- Analysis CU08: condition occurrences per encounter lineage ID.
SELECT
    coalesce(encounter_id, '__UNKNOWN__') AS encounter_id,
    count(*) AS condition_occurrence_count,
    count(DISTINCT condition_key) AS distinct_condition_concepts
FROM analytics.fact_condition_occurrence
GROUP BY encounter_id
ORDER BY condition_occurrence_count DESC, encounter_id;

-- Validation CU05-CU08: patient, encounter, and concept groupings retain fact rows.
WITH by_patient AS (
    SELECT patient_key, count(*) n FROM analytics.fact_condition_occurrence GROUP BY patient_key
), by_encounter AS (
    SELECT encounter_id, count(*) n FROM analytics.fact_condition_occurrence GROUP BY encounter_id
), by_concept AS (
    SELECT condition_key, count(*) n FROM analytics.fact_condition_occurrence GROUP BY condition_key
)
SELECT
    (SELECT sum(n) FROM by_patient) AS patient_grouped_occurrences,
    (SELECT sum(n) FROM by_encounter) AS encounter_grouped_occurrences,
    (SELECT sum(n) FROM by_concept) AS concept_grouped_occurrences,
    (SELECT count(*) FROM analytics.fact_condition_occurrence) AS fact_occurrences;

ROLLBACK;
