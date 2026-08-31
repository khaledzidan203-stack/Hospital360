# Hospital360 Power BI Relationship Design

## Status and Scope

Proposed Power BI V1 semantic relationships for the validated 5,000-patient synthetic portfolio dataset. Power BI must import only the seven dimensions and five facts in PostgreSQL schema `analytics`. RAW and STAGING are outside the Power BI model.

## Design Rules

- Every relationship is dimension `1` to fact `*`.
- Cross-filter direction is **Single** from dimension to fact.
- There are no fact-to-fact relationships, bridge tables, or bidirectional filters in V1.
- Source lineage columns such as `encounter_id` and `claim_id` do not create relationships between facts.
- One role is active where a fact contains multiple keys to the same dimension. Alternate roles remain inactive and are invoked only by explicit `USERELATIONSHIP` measures.
- Surrogate key `0` is the governed Unknown member. Non-date dimensions retain it directly. The imported `dim_date` query excludes only key `0` so Power BI can mark it as a valid date table; fact date key `0` therefore appears through Power BI's blank/Unknown relationship member and remains measurable through explicit DQ measures.

## Relationship Inventory

| # | From table | From column | To table | To column | Cardinality | Filter | Status | Business purpose |
|---:|---|---|---|---|---|---|---|---|
| 1 | `dim_patient` | `patient_key` | `fact_encounter` | `patient_key` | 1:* | Single | Active | Patient slicing of encounter activity |
| 2 | `dim_provider` | `provider_key` | `fact_encounter` | `provider_key` | 1:* | Single | Active | Encounter provider analysis |
| 3 | `dim_organization` | `organization_key` | `fact_encounter` | `organization_key` | 1:* | Single | Active | Encounter organization analysis |
| 4 | `dim_payer` | `payer_key` | `fact_encounter` | `payer_key` | 1:* | Single | Active | Encounter payer analysis |
| 5 | `dim_date` | `date_key` | `fact_encounter` | `start_date_key` | 1:* | Single | Active | Default encounter activity date |
| 6 | `dim_date` | `date_key` | `fact_encounter` | `stop_date_key` | 1:* | Single | Inactive | Role-playing encounter stop date |
| 7 | `dim_patient` | `patient_key` | `fact_claim` | `patient_key` | 1:* | Single | Active | Patient slicing of claim headers |
| 8 | `dim_provider` | `provider_key` | `fact_claim` | `provider_key` | 1:* | Single | Active | Default claim provider role |
| 9 | `dim_provider` | `provider_key` | `fact_claim` | `supervising_provider_key` | 1:* | Single | Inactive | Role-playing supervising provider |
| 10 | `dim_provider` | `provider_key` | `fact_claim` | `referring_provider_key` | 1:* | Single | Inactive | Role-playing referring provider |
| 11 | `dim_organization` | `organization_key` | `fact_claim` | `organization_key` | 1:* | Single | Active | Claim organization context |
| 12 | `dim_payer` | `payer_key` | `fact_claim` | `primary_payer_key` | 1:* | Single | Active | Default primary claim payer |
| 13 | `dim_payer` | `payer_key` | `fact_claim` | `secondary_payer_key` | 1:* | Single | Inactive | Role-playing secondary claim payer |
| 14 | `dim_date` | `date_key` | `fact_claim` | `service_date_key` | 1:* | Single | Active | Default claim service date |
| 15 | `dim_date` | `date_key` | `fact_claim` | `current_illness_date_key` | 1:* | Single | Inactive | Role-playing current-illness date |
| 16 | `dim_date` | `date_key` | `fact_claim` | `last_billed_date_key_1` | 1:* | Single | Inactive | Role-playing first payer billing date |
| 17 | `dim_date` | `date_key` | `fact_claim` | `last_billed_date_key_2` | 1:* | Single | Inactive | Role-playing second payer billing date |
| 18 | `dim_date` | `date_key` | `fact_claim` | `last_billed_date_key_primary` | 1:* | Single | Inactive | Role-playing primary billing date |
| 19 | `dim_patient` | `patient_key` | `fact_claim_transaction` | `patient_key` | 1:* | Single | Active | Patient slicing of financial transactions |
| 20 | `dim_provider` | `provider_key` | `fact_claim_transaction` | `provider_key` | 1:* | Single | Active | Default transaction provider |
| 21 | `dim_provider` | `provider_key` | `fact_claim_transaction` | `supervising_provider_key` | 1:* | Single | Inactive | Role-playing transaction supervisor |
| 22 | `dim_organization` | `organization_key` | `fact_claim_transaction` | `organization_key` | 1:* | Single | Active | Transaction place-of-service organization |
| 23 | `dim_payer` | `payer_key` | `fact_claim_transaction` | `claim_primary_payer_key` | 1:* | Single | Active | Parent claim primary-payer context |
| 24 | `dim_date` | `date_key` | `fact_claim_transaction` | `from_date_key` | 1:* | Single | Active | Default transaction activity date |
| 25 | `dim_date` | `date_key` | `fact_claim_transaction` | `to_date_key` | 1:* | Single | Inactive | Role-playing transaction stop date; sentinel maps to Unknown |
| 26 | `dim_patient` | `patient_key` | `fact_condition_occurrence` | `patient_key` | 1:* | Single | Active | Patient slicing of condition occurrences |
| 27 | `dim_condition` | `condition_key` | `fact_condition_occurrence` | `condition_key` | 1:* | Single | Active | Condition concept analysis |
| 28 | `dim_provider` | `provider_key` | `fact_condition_occurrence` | `encounter_provider_key` | 1:* | Single | Active | Encounter-context provider |
| 29 | `dim_organization` | `organization_key` | `fact_condition_occurrence` | `encounter_organization_key` | 1:* | Single | Active | Encounter-context organization |
| 30 | `dim_payer` | `payer_key` | `fact_condition_occurrence` | `encounter_payer_key` | 1:* | Single | Active | Encounter-context payer |
| 31 | `dim_date` | `date_key` | `fact_condition_occurrence` | `start_date_key` | 1:* | Single | Active | Default condition start date |
| 32 | `dim_date` | `date_key` | `fact_condition_occurrence` | `stop_date_key` | 1:* | Single | Inactive | Role-playing condition stop date |
| 33 | `dim_patient` | `patient_key` | `fact_procedure` | `patient_key` | 1:* | Single | Active | Patient slicing of performed procedures |
| 34 | `dim_procedure` | `procedure_key` | `fact_procedure` | `procedure_key` | 1:* | Single | Active | Procedure concept analysis |
| 35 | `dim_provider` | `provider_key` | `fact_procedure` | `encounter_provider_key` | 1:* | Single | Active | Encounter-context procedure provider |
| 36 | `dim_organization` | `organization_key` | `fact_procedure` | `encounter_organization_key` | 1:* | Single | Active | Encounter-context procedure organization |
| 37 | `dim_payer` | `payer_key` | `fact_procedure` | `encounter_payer_key` | 1:* | Single | Active | Encounter-context procedure payer |
| 38 | `dim_date` | `date_key` | `fact_procedure` | `start_date_key` | 1:* | Single | Active | Default procedure start date |
| 39 | `dim_date` | `date_key` | `fact_procedure` | `stop_date_key` | 1:* | Single | Inactive | Role-playing procedure stop date |

Relationship count: **39** total — **27 active** and **12 inactive**.

## Role-Playing Date Strategy

The shared `dim_date` table is the conformed reporting date. Active roles are encounter start, claim service, transaction from, condition start, and procedure start. Measures that require stop, billing, illness, or other dates must explicitly use the relevant inactive relationship:

```DAX
Encounters by Stop Date :=
CALCULATE (
    [Total Encounters],
    USERELATIONSHIP ( 'dim_date'[date_key], 'fact_encounter'[stop_date_key] )
)
```

Do not activate multiple relationships between the same dimension and fact. If report requirements later need simultaneous independent date slicers, create named role-playing copies in the Power BI semantic model only after governance review; do not change PostgreSQL V1 for that convenience.

## Validation Gates

1. Each dimension key is unique on the `1` side.
2. Every relationship shows `1:*`, Single direction.
3. The 27 listed relationships are active and the 12 alternate roles are inactive.
4. No relationship connects two facts or uses `encounter_id`, `claim_id`, or transaction identifiers.
5. Filtering a dimension changes only measures from facts related to that dimension and does not multiply native fact totals.
