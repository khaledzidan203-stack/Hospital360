# Hospital360 Analytics Columns

## Scope

Live, read-only export of PostgreSQL `information_schema.columns` for schema `analytics`. Generated on 2026-08-31 for exact Power BI and DAX field-name reference. No database objects or data were modified.

- Tables: 12
- Columns: 200
- Nullability values are PostgreSQL metadata values: `YES` or `NO`.

## `analytics.dim_date`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `date_key` | `integer` | NO |
| 2 | `full_date` | `date` | YES |
| 3 | `year` | `smallint` | YES |
| 4 | `quarter` | `smallint` | YES |
| 5 | `month_number` | `smallint` | YES |
| 6 | `month_name` | `text` | YES |
| 7 | `year_month` | `text` | YES |
| 8 | `day_of_month` | `smallint` | YES |
| 9 | `day_name` | `text` | YES |
| 10 | `day_of_week` | `smallint` | YES |
| 11 | `week_of_year` | `smallint` | YES |

## `analytics.dim_patient`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `patient_key` | `integer` | NO |
| 2 | `patient_id` | `text` | NO |
| 3 | `birth_date` | `date` | YES |
| 4 | `death_date` | `date` | YES |
| 5 | `marital_status` | `text` | YES |
| 6 | `race` | `text` | YES |
| 7 | `ethnicity` | `text` | YES |
| 8 | `gender` | `text` | YES |
| 9 | `birthplace` | `text` | YES |
| 10 | `city` | `text` | YES |
| 11 | `state` | `text` | YES |
| 12 | `county` | `text` | YES |
| 13 | `fips` | `text` | YES |
| 14 | `zip` | `text` | YES |
| 15 | `latitude` | `numeric` | YES |
| 16 | `longitude` | `numeric` | YES |
| 17 | `source_system` | `text` | NO |
| 18 | `source_table` | `text` | NO |
| 19 | `source_row_hash` | `text` | YES |

## `analytics.dim_provider`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `provider_key` | `integer` | NO |
| 2 | `provider_id` | `text` | NO |
| 3 | `observed_as_encounter_provider` | `boolean` | NO |
| 4 | `observed_as_claim_provider` | `boolean` | NO |
| 5 | `observed_as_claim_supervisor` | `boolean` | NO |
| 6 | `observed_as_claim_referrer` | `boolean` | NO |
| 7 | `observed_as_transaction_provider` | `boolean` | NO |
| 8 | `observed_as_transaction_supervisor` | `boolean` | NO |
| 9 | `is_inferred_reference` | `boolean` | NO |
| 10 | `source_system` | `text` | NO |
| 11 | `source_scope` | `text` | NO |

## `analytics.dim_organization`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `organization_key` | `integer` | NO |
| 2 | `organization_id` | `text` | NO |
| 3 | `observed_as_encounter_organization` | `boolean` | NO |
| 4 | `observed_as_place_of_service` | `boolean` | NO |
| 5 | `is_inferred_reference` | `boolean` | NO |
| 6 | `source_system` | `text` | NO |
| 7 | `source_scope` | `text` | NO |

## `analytics.dim_payer`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `payer_key` | `integer` | NO |
| 2 | `payer_id` | `text` | NO |
| 3 | `observed_as_encounter_payer` | `boolean` | NO |
| 4 | `observed_as_primary_claim_payer` | `boolean` | NO |
| 5 | `observed_as_secondary_claim_payer` | `boolean` | NO |
| 6 | `is_inferred_reference` | `boolean` | NO |
| 7 | `source_system` | `text` | NO |
| 8 | `source_scope` | `text` | NO |

## `analytics.dim_condition`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `condition_key` | `integer` | NO |
| 2 | `code_system` | `text` | NO |
| 3 | `condition_code` | `text` | NO |
| 4 | `condition_description` | `text` | YES |
| 5 | `source_system` | `text` | NO |
| 6 | `source_table` | `text` | NO |

## `analytics.dim_procedure`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `procedure_key` | `integer` | NO |
| 2 | `code_system` | `text` | NO |
| 3 | `procedure_code` | `text` | NO |
| 4 | `procedure_description` | `text` | YES |
| 5 | `source_system` | `text` | NO |
| 6 | `source_table` | `text` | NO |

## `analytics.fact_encounter`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `encounter_fact_key` | `bigint` | NO |
| 2 | `encounter_id` | `text` | NO |
| 3 | `patient_key` | `integer` | NO |
| 4 | `provider_key` | `integer` | NO |
| 5 | `organization_key` | `integer` | NO |
| 6 | `payer_key` | `integer` | NO |
| 7 | `start_date_key` | `integer` | NO |
| 8 | `stop_date_key` | `integer` | NO |
| 9 | `start_at` | `timestamp with time zone` | YES |
| 10 | `stop_at` | `timestamp with time zone` | YES |
| 11 | `encounter_class` | `text` | YES |
| 12 | `encounter_code` | `text` | YES |
| 13 | `encounter_description` | `text` | YES |
| 14 | `reason_code` | `text` | YES |
| 15 | `reason_description` | `text` | YES |
| 16 | `base_encounter_cost` | `numeric` | YES |
| 17 | `total_claim_cost` | `numeric` | YES |
| 18 | `payer_coverage` | `numeric` | YES |
| 19 | `source_system` | `text` | NO |
| 20 | `source_table` | `text` | NO |
| 21 | `source_row_hash` | `text` | YES |

## `analytics.fact_claim`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `claim_fact_key` | `bigint` | NO |
| 2 | `claim_id` | `text` | NO |
| 3 | `encounter_id` | `text` | YES |
| 4 | `patient_key` | `integer` | NO |
| 5 | `provider_key` | `integer` | NO |
| 6 | `supervising_provider_key` | `integer` | NO |
| 7 | `referring_provider_key` | `integer` | NO |
| 8 | `organization_key` | `integer` | NO |
| 9 | `primary_payer_key` | `integer` | NO |
| 10 | `secondary_payer_key` | `integer` | NO |
| 11 | `current_illness_date_key` | `integer` | NO |
| 12 | `service_date_key` | `integer` | NO |
| 13 | `last_billed_date_key_1` | `integer` | NO |
| 14 | `last_billed_date_key_2` | `integer` | NO |
| 15 | `last_billed_date_key_primary` | `integer` | NO |
| 16 | `current_illness_at` | `timestamp with time zone` | YES |
| 17 | `service_at` | `timestamp with time zone` | YES |
| 18 | `last_billed_at_1` | `timestamp with time zone` | YES |
| 19 | `last_billed_at_2` | `timestamp with time zone` | YES |
| 20 | `last_billed_at_primary` | `timestamp with time zone` | YES |
| 21 | `department_id` | `integer` | YES |
| 22 | `patient_department_id` | `integer` | YES |
| 23 | `status_1` | `text` | YES |
| 24 | `status_2` | `text` | YES |
| 25 | `status_primary` | `text` | YES |
| 26 | `healthcare_claim_type_id_1` | `integer` | YES |
| 27 | `healthcare_claim_type_id_2` | `integer` | YES |
| 28 | `diagnosis_1` | `text` | YES |
| 29 | `diagnosis_2` | `text` | YES |
| 30 | `diagnosis_3` | `text` | YES |
| 31 | `diagnosis_4` | `text` | YES |
| 32 | `diagnosis_5` | `text` | YES |
| 33 | `diagnosis_6` | `text` | YES |
| 34 | `diagnosis_7` | `text` | YES |
| 35 | `diagnosis_8` | `text` | YES |
| 36 | `outstanding_1` | `numeric` | YES |
| 37 | `outstanding_2` | `numeric` | YES |
| 38 | `outstanding_primary` | `numeric` | YES |
| 39 | `source_system` | `text` | NO |
| 40 | `source_table` | `text` | NO |
| 41 | `source_row_hash` | `text` | YES |

## `analytics.fact_claim_transaction`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `claim_transaction_fact_key` | `bigint` | NO |
| 2 | `transaction_id` | `text` | NO |
| 3 | `claim_id` | `text` | YES |
| 4 | `encounter_id` | `text` | YES |
| 5 | `charge_id` | `text` | YES |
| 6 | `patient_key` | `integer` | NO |
| 7 | `provider_key` | `integer` | NO |
| 8 | `supervising_provider_key` | `integer` | NO |
| 9 | `organization_key` | `integer` | NO |
| 10 | `claim_primary_payer_key` | `integer` | NO |
| 11 | `from_date_key` | `integer` | NO |
| 12 | `to_date_key` | `integer` | NO |
| 13 | `from_at` | `timestamp with time zone` | YES |
| 14 | `to_at` | `timestamp with time zone` | YES |
| 15 | `transaction_type` | `text` | YES |
| 16 | `method` | `text` | YES |
| 17 | `procedure_code` | `text` | YES |
| 18 | `modifier_1` | `text` | YES |
| 19 | `modifier_2` | `text` | YES |
| 20 | `diagnosis_ref_1` | `integer` | YES |
| 21 | `diagnosis_ref_2` | `integer` | YES |
| 22 | `diagnosis_ref_3` | `integer` | YES |
| 23 | `diagnosis_ref_4` | `integer` | YES |
| 24 | `department_id` | `integer` | YES |
| 25 | `transfer_out_id` | `text` | YES |
| 26 | `transfer_type` | `text` | YES |
| 27 | `patient_insurance_id` | `text` | YES |
| 28 | `fee_schedule_id` | `text` | YES |
| 29 | `units` | `numeric` | YES |
| 30 | `amount` | `numeric` | YES |
| 31 | `unit_amount` | `numeric` | YES |
| 32 | `payments` | `numeric` | YES |
| 33 | `adjustments` | `numeric` | YES |
| 34 | `transfers` | `numeric` | YES |
| 35 | `outstanding` | `numeric` | YES |
| 36 | `source_unset_to_timestamp_warning` | `boolean` | NO |
| 37 | `source_system` | `text` | NO |
| 38 | `source_table` | `text` | NO |
| 39 | `source_row_hash` | `text` | YES |

## `analytics.fact_condition_occurrence`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `condition_occurrence_fact_key` | `bigint` | NO |
| 2 | `encounter_id` | `text` | YES |
| 3 | `patient_key` | `integer` | NO |
| 4 | `condition_key` | `integer` | NO |
| 5 | `encounter_provider_key` | `integer` | NO |
| 6 | `encounter_organization_key` | `integer` | NO |
| 7 | `encounter_payer_key` | `integer` | NO |
| 8 | `start_date_key` | `integer` | NO |
| 9 | `stop_date_key` | `integer` | NO |
| 10 | `start_date` | `date` | YES |
| 11 | `stop_date` | `date` | YES |
| 12 | `source_system` | `text` | NO |
| 13 | `source_table` | `text` | NO |
| 14 | `source_row_hash` | `text` | YES |

## `analytics.fact_procedure`

| Ordinal position | Exact column name | PostgreSQL data type | Is nullable |
|---:|---|---|:---:|
| 1 | `procedure_fact_key` | `bigint` | NO |
| 2 | `encounter_id` | `text` | YES |
| 3 | `patient_key` | `integer` | NO |
| 4 | `procedure_key` | `integer` | NO |
| 5 | `encounter_provider_key` | `integer` | NO |
| 6 | `encounter_organization_key` | `integer` | NO |
| 7 | `encounter_payer_key` | `integer` | NO |
| 8 | `start_date_key` | `integer` | NO |
| 9 | `stop_date_key` | `integer` | NO |
| 10 | `start_at` | `timestamp with time zone` | YES |
| 11 | `stop_at` | `timestamp with time zone` | YES |
| 12 | `reason_code` | `text` | YES |
| 13 | `reason_description` | `text` | YES |
| 14 | `base_cost` | `numeric` | YES |
| 15 | `source_system` | `text` | NO |
| 16 | `source_table` | `text` | NO |
| 17 | `source_row_hash` | `text` | YES |

## Usage Note

Use these exact lowercase identifiers in Power BI model relationships and DAX table/column references. Do not infer aliases from business-facing measure names. Technical keys may be hidden in Report view but must not be renamed inconsistently with the governed model documentation.

