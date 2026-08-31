# Hospital360 Analytics Relationships Reference

## Scope

Live, read-only export of PostgreSQL `pg_catalog` constraints for schema `analytics`, combined with the implemented Analytics V1 and Power BI semantic-role design. Generated on 2026-08-31. PostgreSQL data and objects were not modified.

- Primary-key constraints: 12
- Unique/business-key constraints: 10
- Foreign-key relationships: 39

## Primary Keys

| Table | Constraint | Exact primary-key column(s) |
|---|---|---|
| `analytics.dim_date` | `dim_date_pkey` | `date_key` |
| `analytics.dim_patient` | `dim_patient_pkey` | `patient_key` |
| `analytics.dim_provider` | `dim_provider_pkey` | `provider_key` |
| `analytics.dim_organization` | `dim_organization_pkey` | `organization_key` |
| `analytics.dim_payer` | `dim_payer_pkey` | `payer_key` |
| `analytics.dim_condition` | `dim_condition_pkey` | `condition_key` |
| `analytics.dim_procedure` | `dim_procedure_pkey` | `procedure_key` |
| `analytics.fact_encounter` | `fact_encounter_pkey` | `encounter_fact_key` |
| `analytics.fact_claim` | `fact_claim_pkey` | `claim_fact_key` |
| `analytics.fact_claim_transaction` | `fact_claim_transaction_pkey` | `claim_transaction_fact_key` |
| `analytics.fact_condition_occurrence` | `fact_condition_occurrence_pkey` | `condition_occurrence_fact_key` |
| `analytics.fact_procedure` | `fact_procedure_pkey` | `procedure_fact_key` |

## Unique / Business Keys

| Table | Constraint | Exact unique column(s) |
|---|---|---|
| `analytics.dim_date` | `dim_date_full_date_key` | `full_date` |
| `analytics.dim_patient` | `dim_patient_patient_id_key` | `patient_id` |
| `analytics.dim_provider` | `dim_provider_provider_id_key` | `provider_id` |
| `analytics.dim_organization` | `dim_organization_organization_id_key` | `organization_id` |
| `analytics.dim_payer` | `dim_payer_payer_id_key` | `payer_id` |
| `analytics.dim_condition` | `uq_dim_condition_business_key` | `code_system` + `condition_code` |
| `analytics.dim_procedure` | `uq_dim_procedure_business_key` | `code_system` + `procedure_code` |
| `analytics.fact_encounter` | `fact_encounter_encounter_id_key` | `encounter_id` |
| `analytics.fact_claim` | `fact_claim_claim_id_key` | `claim_id` |
| `analytics.fact_claim_transaction` | `fact_claim_transaction_transaction_id_key` | `transaction_id` |

## PostgreSQL Foreign Keys

| # | Constraint | From table | Exact FK column | Referenced table | Referenced column |
|---:|---|---|---|---|---|
| 1 | `fact_encounter_organization_key_fkey` | `analytics.fact_encounter` | `organization_key` | `analytics.dim_organization` | `organization_key` |
| 2 | `fact_encounter_patient_key_fkey` | `analytics.fact_encounter` | `patient_key` | `analytics.dim_patient` | `patient_key` |
| 3 | `fact_encounter_payer_key_fkey` | `analytics.fact_encounter` | `payer_key` | `analytics.dim_payer` | `payer_key` |
| 4 | `fact_encounter_provider_key_fkey` | `analytics.fact_encounter` | `provider_key` | `analytics.dim_provider` | `provider_key` |
| 5 | `fact_encounter_start_date_key_fkey` | `analytics.fact_encounter` | `start_date_key` | `analytics.dim_date` | `date_key` |
| 6 | `fact_encounter_stop_date_key_fkey` | `analytics.fact_encounter` | `stop_date_key` | `analytics.dim_date` | `date_key` |
| 7 | `fact_claim_current_illness_date_key_fkey` | `analytics.fact_claim` | `current_illness_date_key` | `analytics.dim_date` | `date_key` |
| 8 | `fact_claim_last_billed_date_key_1_fkey` | `analytics.fact_claim` | `last_billed_date_key_1` | `analytics.dim_date` | `date_key` |
| 9 | `fact_claim_last_billed_date_key_2_fkey` | `analytics.fact_claim` | `last_billed_date_key_2` | `analytics.dim_date` | `date_key` |
| 10 | `fact_claim_last_billed_date_key_primary_fkey` | `analytics.fact_claim` | `last_billed_date_key_primary` | `analytics.dim_date` | `date_key` |
| 11 | `fact_claim_organization_key_fkey` | `analytics.fact_claim` | `organization_key` | `analytics.dim_organization` | `organization_key` |
| 12 | `fact_claim_patient_key_fkey` | `analytics.fact_claim` | `patient_key` | `analytics.dim_patient` | `patient_key` |
| 13 | `fact_claim_primary_payer_key_fkey` | `analytics.fact_claim` | `primary_payer_key` | `analytics.dim_payer` | `payer_key` |
| 14 | `fact_claim_provider_key_fkey` | `analytics.fact_claim` | `provider_key` | `analytics.dim_provider` | `provider_key` |
| 15 | `fact_claim_referring_provider_key_fkey` | `analytics.fact_claim` | `referring_provider_key` | `analytics.dim_provider` | `provider_key` |
| 16 | `fact_claim_secondary_payer_key_fkey` | `analytics.fact_claim` | `secondary_payer_key` | `analytics.dim_payer` | `payer_key` |
| 17 | `fact_claim_service_date_key_fkey` | `analytics.fact_claim` | `service_date_key` | `analytics.dim_date` | `date_key` |
| 18 | `fact_claim_supervising_provider_key_fkey` | `analytics.fact_claim` | `supervising_provider_key` | `analytics.dim_provider` | `provider_key` |
| 19 | `fact_claim_transaction_claim_primary_payer_key_fkey` | `analytics.fact_claim_transaction` | `claim_primary_payer_key` | `analytics.dim_payer` | `payer_key` |
| 20 | `fact_claim_transaction_from_date_key_fkey` | `analytics.fact_claim_transaction` | `from_date_key` | `analytics.dim_date` | `date_key` |
| 21 | `fact_claim_transaction_organization_key_fkey` | `analytics.fact_claim_transaction` | `organization_key` | `analytics.dim_organization` | `organization_key` |
| 22 | `fact_claim_transaction_patient_key_fkey` | `analytics.fact_claim_transaction` | `patient_key` | `analytics.dim_patient` | `patient_key` |
| 23 | `fact_claim_transaction_provider_key_fkey` | `analytics.fact_claim_transaction` | `provider_key` | `analytics.dim_provider` | `provider_key` |
| 24 | `fact_claim_transaction_supervising_provider_key_fkey` | `analytics.fact_claim_transaction` | `supervising_provider_key` | `analytics.dim_provider` | `provider_key` |
| 25 | `fact_claim_transaction_to_date_key_fkey` | `analytics.fact_claim_transaction` | `to_date_key` | `analytics.dim_date` | `date_key` |
| 26 | `fact_condition_occurrence_condition_key_fkey` | `analytics.fact_condition_occurrence` | `condition_key` | `analytics.dim_condition` | `condition_key` |
| 27 | `fact_condition_occurrence_encounter_organization_key_fkey` | `analytics.fact_condition_occurrence` | `encounter_organization_key` | `analytics.dim_organization` | `organization_key` |
| 28 | `fact_condition_occurrence_encounter_payer_key_fkey` | `analytics.fact_condition_occurrence` | `encounter_payer_key` | `analytics.dim_payer` | `payer_key` |
| 29 | `fact_condition_occurrence_encounter_provider_key_fkey` | `analytics.fact_condition_occurrence` | `encounter_provider_key` | `analytics.dim_provider` | `provider_key` |
| 30 | `fact_condition_occurrence_patient_key_fkey` | `analytics.fact_condition_occurrence` | `patient_key` | `analytics.dim_patient` | `patient_key` |
| 31 | `fact_condition_occurrence_start_date_key_fkey` | `analytics.fact_condition_occurrence` | `start_date_key` | `analytics.dim_date` | `date_key` |
| 32 | `fact_condition_occurrence_stop_date_key_fkey` | `analytics.fact_condition_occurrence` | `stop_date_key` | `analytics.dim_date` | `date_key` |
| 33 | `fact_procedure_encounter_organization_key_fkey` | `analytics.fact_procedure` | `encounter_organization_key` | `analytics.dim_organization` | `organization_key` |
| 34 | `fact_procedure_encounter_payer_key_fkey` | `analytics.fact_procedure` | `encounter_payer_key` | `analytics.dim_payer` | `payer_key` |
| 35 | `fact_procedure_encounter_provider_key_fkey` | `analytics.fact_procedure` | `encounter_provider_key` | `analytics.dim_provider` | `provider_key` |
| 36 | `fact_procedure_patient_key_fkey` | `analytics.fact_procedure` | `patient_key` | `analytics.dim_patient` | `patient_key` |
| 37 | `fact_procedure_procedure_key_fkey` | `analytics.fact_procedure` | `procedure_key` | `analytics.dim_procedure` | `procedure_key` |
| 38 | `fact_procedure_start_date_key_fkey` | `analytics.fact_procedure` | `start_date_key` | `analytics.dim_date` | `date_key` |
| 39 | `fact_procedure_stop_date_key_fkey` | `analytics.fact_procedure` | `stop_date_key` | `analytics.dim_date` | `date_key` |

## Power BI Relationship Interpretation

The live database contains 39 dimension foreign keys and no fact-to-fact foreign keys. PostgreSQL does not store Power BI active/inactive or filter-direction metadata. The governed Power BI design applies dimension `1` → fact `*`, Single direction, with 27 active relationships and 12 inactive role-playing relationships as documented in `powerbi/model/relationship_design.md`.

Identifiers such as `fact_claim[encounter_id]`, `fact_claim_transaction[claim_id]`, and clinical-fact `encounter_id` columns are lineage/degenerate identifiers. They are not PostgreSQL foreign keys and must not be used to create Power BI fact-to-fact relationships.

## Financial Column Map

| Measure | Table | Exact Column |
|---|---|---|
| Encounter Base Cost | `analytics.fact_encounter` | `base_encounter_cost` |
| Encounter Total Claim Cost | `analytics.fact_encounter` | `total_claim_cost` |
| Encounter Payer Coverage | `analytics.fact_encounter` | `payer_coverage` |
| Transaction Amount | `analytics.fact_claim_transaction` | `amount` |
| Transaction Payments | `analytics.fact_claim_transaction` | `payments` |
| Transaction Transfers | `analytics.fact_claim_transaction` | `transfers` |
| Procedure Base Cost | `analytics.fact_procedure` | `base_cost` |

These are separate native-grain measures. Do not add encounter, transaction, and procedure financial fields together or treat their totals as interchangeable.

## Activity Column Map

| Activity / entity | Table | Exact row key or count column | Exact business/lineage identifier | Dimension relationship key(s) |
|---|---|---|---|---|
| Patient | `analytics.dim_patient` | `patient_key` | `patient_id` | Facts use `patient_key` |
| Encounter | `analytics.fact_encounter` | `encounter_fact_key` | `encounter_id` | `patient_key`, `provider_key`, `organization_key`, `payer_key`, `start_date_key`, `stop_date_key` |
| Claim | `analytics.fact_claim` | `claim_fact_key` | `claim_id`; `encounter_id` is lineage | `patient_key`, provider-role keys, `organization_key`, payer-role keys, claim date keys |
| Claim transaction | `analytics.fact_claim_transaction` | `claim_transaction_fact_key` | `transaction_id`; `claim_id` and `encounter_id` are lineage | `patient_key`, provider-role keys, `organization_key`, `claim_primary_payer_key`, `from_date_key`, `to_date_key` |
| Procedure occurrence | `analytics.fact_procedure` | `procedure_fact_key` | `encounter_id` is lineage | `patient_key`, `procedure_key`, encounter-context keys, `start_date_key`, `stop_date_key` |
| Condition occurrence | `analytics.fact_condition_occurrence` | `condition_occurrence_fact_key` | `encounter_id` is lineage | `patient_key`, `condition_key`, encounter-context keys, `start_date_key`, `stop_date_key` |
| Primary payer | `analytics.dim_payer` | `payer_key` | `payer_id` | Encounter: `payer_key`; claim: `primary_payer_key`; transaction: `claim_primary_payer_key`; clinical facts: `encounter_payer_key` |
| Provider | `analytics.dim_provider` | `provider_key` | `provider_id` | Encounter: `provider_key`; claim: `provider_key`, `supervising_provider_key`, `referring_provider_key`; transaction: `provider_key`, `supervising_provider_key`; clinical facts: `encounter_provider_key` |
| Organization | `analytics.dim_organization` | `organization_key` | `organization_id` | Encounter/claim/transaction: `organization_key`; clinical facts: `encounter_organization_key` |

### Exact Activity Count References

| Power BI activity measure | Exact source reference |
|---|---|
| Total Patients | Distinct nonzero `analytics.fact_encounter[patient_key]` |
| Total Encounters | Rows of `analytics.fact_encounter` or count of `encounter_fact_key` |
| Total Claims | Rows of `analytics.fact_claim` or count of `claim_fact_key` |
| Total Claim Transactions | Rows of `analytics.fact_claim_transaction` or count of `claim_transaction_fact_key` |
| Total Procedures | Rows of `analytics.fact_procedure` or count of `procedure_fact_key` |
| Total Condition Occurrences | Rows of `analytics.fact_condition_occurrence` or count of `condition_occurrence_fact_key` |

## Active Power BI Date Keys

“Active” is a Power BI semantic-model choice, not a PostgreSQL constraint property. The implemented design uses these exact active roles:

| Date dimension | Fact table | Exact active fact date key | Source timestamp/date |
|---|---|---|---|
| `analytics.dim_date[date_key]` | `analytics.fact_encounter` | `start_date_key` | `start_at` |
| `analytics.dim_date[date_key]` | `analytics.fact_claim` | `service_date_key` | `service_at` |
| `analytics.dim_date[date_key]` | `analytics.fact_claim_transaction` | `from_date_key` | `from_at` |
| `analytics.dim_date[date_key]` | `analytics.fact_condition_occurrence` | `start_date_key` | `start_date` |
| `analytics.dim_date[date_key]` | `analytics.fact_procedure` | `start_date_key` | `start_at` |

Inactive role-playing date keys are `fact_encounter[stop_date_key]`; `fact_claim[current_illness_date_key]`, `last_billed_date_key_1`, `last_billed_date_key_2`, and `last_billed_date_key_primary`; `fact_claim_transaction[to_date_key]`; `fact_condition_occurrence[stop_date_key]`; and `fact_procedure[stop_date_key]`.

## Power BI / DAX Naming Rule

Power BI may hide technical keys, but DAX must use these exact imported model table and column names unless a deliberate, documented model rename is applied consistently. Business measure labels must never be used to guess a physical column name.

