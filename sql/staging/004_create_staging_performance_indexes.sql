-- Hospital360 STAGING Performance V2 supporting indexes.
-- V1 remains the correctness baseline. These non-unique indexes support
-- post-load duplicate and reference-integrity validation without enforcing
-- candidate keys or changing source-row grain.

CREATE INDEX IF NOT EXISTS ix_stg_patients_patient_id
    ON staging.stg_patients (patient_id);

CREATE INDEX IF NOT EXISTS ix_stg_encounters_encounter_id
    ON staging.stg_encounters (encounter_id);
CREATE INDEX IF NOT EXISTS ix_stg_encounters_patient_id
    ON staging.stg_encounters (patient_id);

CREATE INDEX IF NOT EXISTS ix_stg_claims_claim_id
    ON staging.stg_claims (claim_id);
CREATE INDEX IF NOT EXISTS ix_stg_claims_patient_id
    ON staging.stg_claims (patient_id);
CREATE INDEX IF NOT EXISTS ix_stg_claims_encounter_id
    ON staging.stg_claims (appointment_id);

CREATE INDEX IF NOT EXISTS ix_stg_claim_transactions_transaction_id
    ON staging.stg_claim_transactions (transaction_id);
CREATE INDEX IF NOT EXISTS ix_stg_claim_transactions_claim_id
    ON staging.stg_claim_transactions (claim_id);
CREATE INDEX IF NOT EXISTS ix_stg_claim_transactions_patient_id
    ON staging.stg_claim_transactions (patient_id);
CREATE INDEX IF NOT EXISTS ix_stg_claim_transactions_encounter_id
    ON staging.stg_claim_transactions (appointment_id);

-- Equivalent indexes are justified by the existing condition/procedure DQ
-- candidate-key and reference checks. Composite order matches those checks.
CREATE INDEX IF NOT EXISTS ix_stg_condition_occurrences_candidate_key
    ON staging.stg_condition_occurrences
        (patient_id, encounter_id, start_date, condition_code);
CREATE INDEX IF NOT EXISTS ix_stg_condition_occurrences_encounter_id
    ON staging.stg_condition_occurrences (encounter_id);

CREATE INDEX IF NOT EXISTS ix_stg_procedures_candidate_key
    ON staging.stg_procedures
        (patient_id, encounter_id, start_at, procedure_code);
CREATE INDEX IF NOT EXISTS ix_stg_procedures_encounter_id
    ON staging.stg_procedures (encounter_id);
