\set ON_ERROR_STOP on

-- Hospital360 STAGING V1/V2 parity validation.
--
-- This script is deliberately read-only with respect to persistent project
-- tables. The test harness must populate same-session temporary tables named
-- v1_<table> and v2_<table>, each created LIKE its corresponding staging
-- table. EXCEPT ALL preserves duplicate multiplicity and therefore compares
-- every typed value, metadata value, source hash, and DQ flag without using
-- DISTINCT or masking duplicate behavior.

WITH parity AS (
    SELECT 'patients' AS table_name,
           (SELECT count(*) FROM pg_temp.v1_patients) AS v1_rows,
           (SELECT count(*) FROM pg_temp.v2_patients) AS v2_rows,
           (SELECT count(*) FROM (
                (SELECT * FROM pg_temp.v1_patients)
                EXCEPT ALL
                (SELECT * FROM pg_temp.v2_patients)
            ) d) AS v1_minus_v2,
           (SELECT count(*) FROM (
                (SELECT * FROM pg_temp.v2_patients)
                EXCEPT ALL
                (SELECT * FROM pg_temp.v1_patients)
            ) d) AS v2_minus_v1
    UNION ALL
    SELECT 'encounters',
           (SELECT count(*) FROM pg_temp.v1_encounters),
           (SELECT count(*) FROM pg_temp.v2_encounters),
           (SELECT count(*) FROM ((SELECT * FROM pg_temp.v1_encounters) EXCEPT ALL (SELECT * FROM pg_temp.v2_encounters)) d),
           (SELECT count(*) FROM ((SELECT * FROM pg_temp.v2_encounters) EXCEPT ALL (SELECT * FROM pg_temp.v1_encounters)) d)
    UNION ALL
    SELECT 'claims',
           (SELECT count(*) FROM pg_temp.v1_claims),
           (SELECT count(*) FROM pg_temp.v2_claims),
           (SELECT count(*) FROM ((SELECT * FROM pg_temp.v1_claims) EXCEPT ALL (SELECT * FROM pg_temp.v2_claims)) d),
           (SELECT count(*) FROM ((SELECT * FROM pg_temp.v2_claims) EXCEPT ALL (SELECT * FROM pg_temp.v1_claims)) d)
    UNION ALL
    SELECT 'claim_transactions',
           (SELECT count(*) FROM pg_temp.v1_claim_transactions),
           (SELECT count(*) FROM pg_temp.v2_claim_transactions),
           (SELECT count(*) FROM ((SELECT * FROM pg_temp.v1_claim_transactions) EXCEPT ALL (SELECT * FROM pg_temp.v2_claim_transactions)) d),
           (SELECT count(*) FROM ((SELECT * FROM pg_temp.v2_claim_transactions) EXCEPT ALL (SELECT * FROM pg_temp.v1_claim_transactions)) d)
    UNION ALL
    SELECT 'condition_occurrences',
           (SELECT count(*) FROM pg_temp.v1_condition_occurrences),
           (SELECT count(*) FROM pg_temp.v2_condition_occurrences),
           (SELECT count(*) FROM ((SELECT * FROM pg_temp.v1_condition_occurrences) EXCEPT ALL (SELECT * FROM pg_temp.v2_condition_occurrences)) d),
           (SELECT count(*) FROM ((SELECT * FROM pg_temp.v2_condition_occurrences) EXCEPT ALL (SELECT * FROM pg_temp.v1_condition_occurrences)) d)
    UNION ALL
    SELECT 'procedures',
           (SELECT count(*) FROM pg_temp.v1_procedures),
           (SELECT count(*) FROM pg_temp.v2_procedures),
           (SELECT count(*) FROM ((SELECT * FROM pg_temp.v1_procedures) EXCEPT ALL (SELECT * FROM pg_temp.v2_procedures)) d),
           (SELECT count(*) FROM ((SELECT * FROM pg_temp.v2_procedures) EXCEPT ALL (SELECT * FROM pg_temp.v1_procedures)) d)
)
SELECT table_name, v1_rows, v2_rows,
       v2_rows - v1_rows AS row_count_difference,
       v1_minus_v2, v2_minus_v1,
       CASE
           WHEN v1_rows = v2_rows AND v1_minus_v2 = 0 AND v2_minus_v1 = 0
           THEN 'PASS' ELSE 'FAIL'
       END AS parity_result
FROM parity
ORDER BY table_name;
