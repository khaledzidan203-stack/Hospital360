# Hospital360 SQL Analysis Framework

## Objective

Provide a validated, read-only SQL query framework over the implemented Hospital360 Analytics V1 star schema. The framework answers supported patient, encounter, claims, financial, payer, provider, organization, clinical-utilization, and time-trend questions while preserving fact grain and preventing measure multiplication.

This deliverable defines analytical methods and reusable queries. It does not create KPI views, final business insights, Power BI artifacts, Python analysis, or database objects.

## Analytical Scope

The framework uses only the seven implemented dimensions and five implemented facts in the `analytics` schema. It contains 47 total queries: 35 business/analytical questions implemented as analytical queries and 12 explicit reconciliation/validation queries across six SQL files. Each file executes within `BEGIN TRANSACTION READ ONLY` and ends with `ROLLBACK`.

Supported domains are:

- Patient and encounter activity
- Claim-header and transaction-grain financial activity
- Payer-role analysis
- Provider and organization activity
- Procedure and condition utilization
- Calendar-month trends

Unsupported V2 subjects—including budgets, operating expenses, bed occupancy, staffing, overtime, appointments/no-shows, IT availability, tickets, and device downtime—are excluded.

## Business Questions

### A. Patient & Encounter Activity

| ID | Business Question | Analytical Question | Measure | Dimension(s) | Grain | Date role | Fact | Required dimensions | Validation method | Known limitation |
|---|---|---|---|---|---|---|---|---|---|---|
| PE01 | How much patient and encounter activity exists? | Count current-state patient members and encounter events. | Patients; encounters | Patient | Patient and encounter baselines reported separately | None | `fact_encounter`; patient baseline from dimension | `dim_patient` | Natural-key and encounter-ID distinct counts equal row counts | Patient dimension is current-state; patients need not have encounters in future extracts |
| PE02 | How frequently does each patient use services? | Count encounters per patient, including zero-encounter patients, and rank volume. | Encounter count; average encounters | Patient | One output row per patient | None | `fact_encounter` | `dim_patient` | Sum patient encounter counts equals encounter fact count | Small synthetic population; ranking is descriptive only |
| PE03 | How does encounter activity change monthly? | Count encounters and active patients by encounter start month. | Encounters; distinct active patients | Start month | One row per active encounter month | Encounter start | `fact_encounter` | `dim_date` | Monthly encounter counts reconcile to fact total | Sparse months may occur in the smoke-test data |
| PE04 | What is the encounter-class/type mix? | Group encounter events by class, code, and description. | Encounters; contribution % | Encounter class/type | One row per class/code/description combination | None | `fact_encounter` | None | Grouped count equals fact count; contribution is approximately 100% | Source classification has no conformed encounter-type dimension in V1 |
| PE05 | How long do encounters last? | Calculate mean and median minutes for valid start/stop pairs. | Eligible encounters; average/median duration | None | All chronologically valid encounter events | Encounter start/stop timestamps | `fact_encounter` | None | Eligible-row count is reported; invalid/missing pairs excluded | Duration is elapsed timestamp time, not clinical effort or bed occupancy |
| PE06 | Which organizations have the most encounters? | Count encounters and patients by encounter organization and rank volume. | Encounters; distinct patients | Organization | One row per organization | None | `fact_encounter` | `dim_organization` | Sum organization counts equals fact count | Organization dimension contains inferred IDs, not master names |
| PE07 | Which providers have the most encounters? | Count encounters and patients by encounter provider and rank volume. | Encounters; distinct patients | Provider | One row per provider | None | `fact_encounter` | `dim_provider` | Sum provider counts equals fact count | Provider dimension contains inferred IDs, not names or specialties |

### B. Claims & Financial Activity

| ID | Business Question | Analytical Question | Measure | Dimension(s) | Grain | Date role | Fact | Required dimensions | Validation method | Known limitation |
|---|---|---|---|---|---|---|---|---|---|---|
| CF01 | How many claim headers exist? | Count claim rows and distinct source claim IDs. | Claims | None | Claim header | None | `fact_claim` | None | Claim row count equals distinct claim ID count | A claim header is not a transaction amount |
| CF02 | How does claim volume change monthly? | Count claims and patients by service month. | Claims; distinct patients | Service month | One row per active service month | Claim service date | `fact_claim` | `dim_date` | Monthly counts sum to claim fact count | Service date is one claim date role; billing dates answer different questions |
| CF03 | How many claims are associated with each encounter? | Count claim headers by degenerate encounter ID and rank. | Claims per encounter | Encounter lineage ID | One row per encounter ID | None | `fact_claim` | None | Grouped counts equal claim fact count | Encounter ID is lineage, not a fact-to-fact relationship |
| CF04 | What are the source encounter financial totals? | Sum encounter claim cost and payer coverage at encounter grain. | Total claim cost; payer coverage; source difference | None | Entire encounter fact | None | `fact_encounter` | None | Totals match validated analytics baselines | Encounter valuation must not be mixed with transaction valuation |
| CF05 | What are transaction-grain financial totals? | Sum amount, payments, and transfers and calculate a guarded payment/amount ratio. | Transaction amount; payments; transfers; ratio | None | Entire transaction fact | None | `fact_claim_transaction` | None | Totals match validated baselines | Ratio is a source-measure diagnostic, not an approved reimbursement KPI |
| CF06 | How are transaction-derived claim values distributed? | Aggregate transaction amounts by claim ID and divide claims into quartiles. | Claim-level transaction amount | Value quartile | One row per value quartile after one-row-per-claim CTE | None | `fact_claim_transaction` | None | Claim-grouped amount equals transaction fact amount | This is transaction-derived value, not a claim-header amount |
| CF07 | Which claims have the highest transaction-derived value? | Aggregate transactions per claim and rank the top values. | Amount; payments; transfers; transaction count | Claim ID | One row per claim ID | None | `fact_claim_transaction` | None | Grouped amount reconciles to transaction fact amount | Ranking does not establish profitability or final adjudication |
| CF08 | How do financial movements change monthly? | Sum transaction amount, payments, and transfers by from month. | Transactions; amount; payments; transfers | Transaction month | One row per active from month | Transaction from date | `fact_claim_transaction` | `dim_date` | Monthly totals reconcile to transaction fact totals | The from date is the chosen event role; unset to-date sentinel is not used |

### C. Payer Analysis

| ID | Business Question | Analytical Question | Measure | Dimension(s) | Grain | Date role | Fact | Required dimensions | Validation method | Known limitation |
|---|---|---|---|---|---|---|---|---|---|---|
| PA01 | What is the primary-payer claim mix? | Count claim headers and contribution by primary payer role. | Claims; contribution % | Primary payer | One row per primary payer | None | `fact_claim` | `dim_payer` | Counts equal claim total; percentage approximately 100% | Unknown key represents missing source insurance IDs |
| PA02 | How much transaction activity is associated with each claim-primary payer? | Group transaction amounts and movements by resolved claim-primary payer key. | Transactions; amount; payments; transfers; contribution % | Claim-primary payer | One row per payer | None | `fact_claim_transaction` | `dim_payer` | Grouped amount equals transaction fact amount | Payer key was resolved during load; no claim fact join is performed |
| PA03 | What encounter costs and coverage are attributed to encounter payers? | Sum encounter claim cost and payer coverage by encounter payer role. | Encounters; claim cost; coverage; contribution % | Encounter payer | One row per payer | None | `fact_encounter` | `dim_payer` | Grouped costs/coverage equal encounter fact totals | Encounter payer role may differ from claim insurance roles |
| PA04 | Where are payer values unknown? | Count key-0 usage for each supported payer role. | Unknown rows; total rows | Payer role | One row per payer role | None | `fact_claim`, `fact_claim_transaction`, `fact_encounter` separately | None | Counts are produced independently per fact; no mixed-grain sum | Unknown usage can mean absent source data, not lookup failure |
| PA05 | How does primary-payer claim mix vary by month? | Count claims and monthly contribution by primary payer and service month. | Claims; monthly payer mix % | Service month; primary payer | One row per month/payer | Claim service date | `fact_claim` | `dim_date`, `dim_payer` | Month/payer counts sum to claim fact count | Sparse synthetic months can create volatile percentages |

### D. Provider & Organization Performance

| ID | Business Question | Analytical Question | Measure | Dimension(s) | Grain | Date role | Fact | Required dimensions | Validation method | Known limitation |
|---|---|---|---|---|---|---|---|---|---|---|
| PO01 | Which encounter providers have the highest volume and average duration? | Group encounters by provider and rank volume. | Encounters; patients; average duration | Encounter provider | One row per provider | Encounter timestamps for duration | `fact_encounter` | `dim_provider` | Provider counts equal encounter total | IDs are inferred; duration is not provider productivity |
| PO02 | Which encounter organizations have the highest volume and source costs? | Group encounter volume, duration, claim cost, and coverage by organization. | Encounters; patients; duration; claim cost; coverage | Encounter organization | One row per organization | Encounter timestamps for duration | `fact_encounter` | `dim_organization` | Counts and monetary totals equal encounter fact | No organization name, capacity, or expense denominator exists |
| PO03 | Which transaction providers have the most transaction value? | Group transaction counts, amounts, and payments by transaction provider role. | Transactions; amount; payments | Transaction provider | One row per provider | None | `fact_claim_transaction` | `dim_provider` | Counts/amounts equal transaction fact totals | Transaction provider role is not necessarily encounter provider role |
| PO04 | Which places of service have the most transaction value? | Group transaction activity by organization/place-of-service role. | Transactions; amount; payments | Place-of-service organization | One row per organization | None | `fact_claim_transaction` | `dim_organization` | Counts/amounts equal transaction fact totals | Organization master attributes are unavailable in V1 |

### E. Clinical Service Utilization

| ID | Business Question | Analytical Question | Measure | Dimension(s) | Grain | Date role | Fact | Required dimensions | Validation method | Known limitation |
|---|---|---|---|---|---|---|---|---|---|---|
| CU01 | What is total procedure utilization and source cost? | Count procedure occurrences, patients, encounters, and base cost. | Procedures; patients; encounters; base cost | None | Entire procedure fact | None | `fact_procedure` | None | Totals match validated procedure baseline | Base cost is a source measure, not actual cost accounting |
| CU02 | Which procedure concepts are most frequent and costly? | Group procedures by concept and calculate frequency/cost ranks and contribution. | Procedures; patients; base cost; ranks | Procedure concept | One row per procedure concept | None | `fact_procedure` | `dim_procedure` | Counts/cost reconcile to procedure fact | Concept labels are Synthea source descriptions |
| CU03 | What are the top procedures by frequency? | Rank procedure concepts by occurrence count. | Procedures; base cost | Procedure concept | One row per procedure concept | None | `fact_procedure` | `dim_procedure` | Grouped counts equal procedure total | Top 20 may include ties |
| CU04 | What are the top procedures by source base cost? | Rank procedure concepts by summed base cost. | Procedures; base cost | Procedure concept | One row per procedure concept | None | `fact_procedure` | `dim_procedure` | Grouped cost equals procedure fact cost | Cost is not margin or reimbursement |
| CU05 | What is total recorded condition activity? | Count occurrences, patients, and encounters. | Condition occurrences; patients; encounters | None | Entire condition-occurrence fact | None | `fact_condition_occurrence` | None | Totals match validated condition baseline | Occurrence is not prevalence without a defined population/time window |
| CU06 | Which condition concepts occur most frequently? | Group and rank recorded occurrences by condition concept. | Occurrences; patients; encounters; contribution % | Condition concept | One row per condition concept | None | `fact_condition_occurrence` | `dim_condition` | Concept counts sum to occurrence total | Source occurrence does not establish clinical severity |
| CU07 | How many conditions are recorded per patient? | Count occurrences, concepts, and encounters per patient, including zero rows. | Occurrences; distinct concepts; encounters | Patient | One row per patient | None | `fact_condition_occurrence` | `dim_patient` | Sum patient occurrence counts equals fact total | Current 10-patient synthetic sample is not epidemiological evidence |
| CU08 | How many conditions are recorded per encounter? | Count occurrences and distinct concepts by encounter lineage ID. | Occurrences; concepts | Encounter lineage ID | One row per encounter ID with a condition | None | `fact_condition_occurrence` | None | Grouped counts equal occurrence fact count | No encounter fact join is used; ID is lineage only |

### F. Time Trends

| ID | Business Question | Analytical Question | Measure | Dimension(s) | Grain | Date role | Fact | Required dimensions | Validation method | Known limitation |
|---|---|---|---|---|---|---|---|---|---|---|
| TT01 | How does encounter volume evolve over time? | Build a continuous month series with MoM, YoY, rolling-three-month average, and running total. | Encounters; changes; rolling average; running total | Calendar month | One row per calendar month in encounter range | Encounter start date | `fact_encounter` | `dim_date` | Month total and final running total reconcile to fact count | Zero prior period yields null percentage rather than division error |
| TT02 | How does claim volume evolve over time? | Build a continuous service-month series with MoM, YoY, rolling average, and running total. | Claims; changes; rolling average; running total | Calendar month | One row per calendar month in claim range | Claim service date | `fact_claim` | `dim_date` | Month total and final running total reconcile to fact count | Sparse synthetic history can make growth rates unstable |
| TT03 | How do transaction amounts evolve over time? | Build a continuous from-month series with count, amount, payments, transfers, MoM/YoY, rolling amount, and running totals. | Transactions; amount; payments; transfers; changes | Calendar month | One row per calendar month in transaction range | Transaction from date | `fact_claim_transaction` | `dim_date` | Counts and every financial total reconcile to transaction fact | Transaction measures are not interchangeable with encounter or claim-header valuation |

## Measures and Dimensions

Additive measures are summed only within their native facts:

- `fact_encounter`: `base_encounter_cost`, `total_claim_cost`, `payer_coverage`
- `fact_claim`: `outstanding_1`, `outstanding_2`, `outstanding_primary`
- `fact_claim_transaction`: `amount`, `unit_amount`, `payments`, `adjustments`, `transfers`, `outstanding`, `units`
- `fact_procedure`: `base_cost`
- `fact_condition_occurrence`: occurrence count only in V1

Counts use source fact rows or distinct dimension/business identifiers as stated. Percentages use guarded denominators with `NULLIF`. Duration uses valid encounter timestamp pairs only.

Dimensions are joined through their implemented surrogate keys. Provider, organization, and payer outputs display their inferred natural IDs because V1 lacks staged master attributes.

## Grain Rules

- Encounter measures remain at one row per encounter event.
- Claim-header measures remain at one row per claim header.
- Claim transaction measures remain at one row per transaction/event line.
- Condition counts remain at one row per recorded condition occurrence.
- Procedure counts and costs remain at one row per performed procedure occurrence.
- Aggregation to patient, provider, payer, organization, concept, claim ID, encounter ID, or month occurs from one fact at a time.
- Rankings and windows operate only after the required native-grain aggregation.

## Date Roles

- Encounter trends use `fact_encounter.start_date_key`; stop dates are reserved for duration/end-date questions.
- Claim trends use `fact_claim.service_date_key`; current-illness and billing date roles are not substituted silently.
- Transaction trends use `fact_claim_transaction.from_date_key`.
- Condition and procedure start/stop roles are available but are not required by the current minimum trend set.
- Time queries use a continuous `dim_date` calendar-month spine so missing-activity months remain visible and `lag(..., 12)` represents the same calendar month in the prior year.
- The 796 unset transaction stop timestamps use Unknown `to_date_key = 0` and are excluded from real-date trend roles.

## SQL Analysis Files

| File | Domain | Analytical queries | Validation queries |
|---|---|---:|---:|
| `sql/analysis/001_patient_encounter_analysis.sql` | Patient and encounter activity | 7 | 4 |
| `sql/analysis/002_claims_financial_analysis.sql` | Claims and financial activity | 8 | 2 |
| `sql/analysis/003_payer_analysis.sql` | Payer analysis | 5 | 2 |
| `sql/analysis/004_provider_organization_analysis.sql` | Provider and organization performance | 4 | 1 |
| `sql/analysis/005_clinical_utilization_analysis.sql` | Clinical service utilization | 8 | 2 |
| `sql/analysis/006_time_trend_analysis.sql` | Time trends | 3 | 1 |
| **Total** |  | **35** | **12** |

## Validation Strategy

All six files were executed successfully against the local `hospital360` database. Validation uses:

- Fact row counts and distinct source keys for grain checks.
- Sum-of-groups compared with native fact totals.
- Contribution percentages checked to approximately 100%, allowing display rounding.
- Financial values regrouped within the same fact and compared with validated baselines.
- Rankings applied after aggregation so ranking cannot change totals.
- Continuous month-spine totals compared with native fact counts and financial totals.
- PostgreSQL read-only transactions to prevent accidental writes during execution.

| Validation result | Result |
|---|---|
| Validation Failures | 0 |
| Amount Multiplication Detected | No |
| Direct Fact-to-Fact Joins | 0 |

Validated baselines:

| Measure | Value |
|---|---:|
| Patients | 10 |
| Encounters | 283 |
| Claims | 464 |
| Claim transactions | 5,403 |
| Procedures | 1,003 |
| Condition occurrences | 252 |
| Encounter total claim cost | 518,472.87 |
| Payer coverage | 145,968.31 |
| Transaction amount | 722,860.68 |
| Payments | 537,616.96 |
| Transfers | 370,487.44 |
| Procedure base cost | 504,449.26 |

All reconciliation differences were zero. No query execution or validation failure remained after correction of a validation-only aggregate expression.

## Fact-to-Fact Safety Rules

- Never directly join `fact_encounter`, `fact_claim`, and `fact_claim_transaction` to sum measures.
- Never repeat encounter amounts across multiple claim headers.
- Never repeat claim-header amounts across multiple transaction lines.
- Aggregate a fact independently to the comparison grain before comparing results through conformed dimensions.
- Treat `encounter_id` and `claim_id` on facts as degenerate lineage identifiers, not analytical relationships.
- The claim-value distribution and top-claim queries aggregate `fact_claim_transaction` by `claim_id`; they do not join `fact_claim`.
- Payer analysis uses the payer role already resolved on each fact and does not bridge facts at query time.

## Current V1 Limitations

- Results describe a 10-patient synthetic smoke-test dataset, not real hospital performance.
- Provider, organization, and payer dimensions contain inferred IDs and role flags rather than full master descriptions.
- No budget, expense, capacity, staffing, appointment, or technology operations sources exist in V1.
- Encounter cost, claim outstanding, and transaction financial measures have different source semantics and valuation grains.
- The payment-to-transaction ratio is a guarded diagnostic calculation, not an approved KPI.
- Claim “value” in this framework means transaction amount aggregated by claim ID; it is not a claim-header total.
- Sparse historical activity can produce volatile MoM/YoY percentages; a zero prior value returns null.
- No final business interpretation, benchmark, target, or causal conclusion is defined here.

## Next Step

Review and approve the analytical questions, date roles, financial semantics, and output grain before deriving governed KPI definitions or building Power BI measures. Commit this framework separately only after review and validation acceptance.
