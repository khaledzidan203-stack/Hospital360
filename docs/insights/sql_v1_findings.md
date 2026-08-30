# Hospital360 SQL V1 Findings

**Status: Development / Smoke-Test Analytical Baseline**

This report validates analytical logic and pipeline behavior. It is not the final portfolio-scale business analysis.

## Executive Summary

The validated SQL framework was executed against the Hospital360 Analytics V1 model. All 35 analytical queries completed successfully in PostgreSQL read-only transactions. Selected results were reconciled to their native facts; no row or amount multiplication was detected.

The 10-patient synthetic extract contains 283 encounters, 464 claim headers, 5,403 claim transaction rows, 1,003 procedure occurrences, and 252 condition occurrences. The strongest patterns are concentration in routine encounter classes, several high-value claims, payer attribution gaps, concentrated clinical concepts, and volatile monthly results caused partly by small and sparse synthetic counts.

These findings demonstrate the analytical model and SQL methods. They do not describe a real hospital population, profitability, care quality, operational efficiency, or causal relationships.

## Dataset Scope

| Measure | Validated result |
|---|---:|
| Patients | 10 |
| Encounters | 283 |
| Average encounters per patient | 28.30 |
| Claims | 464 |
| Average claims per encounter with claims | 1.64 |
| Claim transactions | 5,403 |
| Procedures | 1,003 |
| Procedure base cost | 504,449.26 |
| Condition occurrences | 252 |
| Encounter total claim cost | 518,472.87 |
| Payer coverage | 145,968.31 |
| Transaction amount | 722,860.68 |
| Payments | 537,616.96 |
| Transfers | 370,487.44 |

All event fact date ranges run from 1935-01-03 through 2026-08-24. The broad range reflects longitudinal synthetic patient histories, not 91 years of one hospital's operating history.

## Patient & Encounter Findings

### Finding 1 — Encounter activity is concentrated among a small synthetic patient set

**Observation:** The dataset contains 283 encounters across 10 patients, averaging 28.30 encounters per patient. Patient encounter counts range from 11 to 54, and the three highest-volume patients account for 48.76% of encounters.

**Evidence:** `dim_patient` has 10 non-Unknown members; `fact_encounter` has 283 rows. Patient-grouped encounter counts reconcile exactly to 283. The top-three concentration is 138 of 283 encounters.

**Interpretation:** The extract is suitable for testing patient-level utilization segmentation and concentration queries. Within this synthetic sample, activity is not evenly distributed across patients.

**Limitation:** Ten synthetic patients are far too few for population inference, risk adjustment, utilization benchmarking, or causal interpretation.

### Finding 2 — Routine encounter classes dominate, while average duration mixes unlike encounter types

**Observation:** Wellness encounters represent 125 of 283 events (44.17%), ambulatory encounters 100 (35.34%), and outpatient encounters 37 (13.07%). Wellness plus ambulatory therefore account for 79.51% of encounters. The three most frequent encounter codes—general examination, check-up, and well-child visit—represent 64.66% of encounters. Average valid encounter duration is 388.27 minutes.

**Evidence:** Encounter-class counts sum to 283 and their contributions sum to approximately 100%. The three leading codes have 69, 58, and 56 encounters. Duration was calculated only where start and stop timestamps were present and chronological.

**Interpretation:** Routine and preventive encounter categories are the main source of volume in this generated extract. Duration should be segmented by class before it is used operationally because the overall mean combines outpatient, emergency, inpatient, skilled-nursing, and other event types.

**Limitation:** The duration is elapsed source time, not clinician effort, wait time, length-of-stay methodology, resource utilization, or an efficiency measure.

## Claims & Financial Findings

### Finding 3 — Multiple claim headers per encounter are common enough to create material join risk

**Observation:** The 464 claims map to 283 encounter identifiers, averaging 1.64 claims per encounter. Every represented encounter has at least one claim, 117 encounters (41.34%) have multiple claims, and the maximum is six.

**Evidence:** Claim counts grouped by the degenerate `encounter_id` reconcile to all 464 claim rows. The calculation uses `fact_claim` only and does not join encounter measures.

**Interpretation:** Encounter and claim analyses must remain at separate grains. The frequency of multiple claims per encounter makes pre-aggregation essential when comparing encounter and claim results.

**Limitation:** Claim count per encounter does not indicate billing quality, denials, complexity, reimbursement, or duplicate claims without adjudication semantics.

### Finding 4 — Source financial measures reconcile, but they represent different valuation bases

**Observation:** Encounter total claim cost is 518,472.87 and encounter payer coverage is 145,968.31. At transaction grain, amount totals 722,860.68, payments total 537,616.96, and transfers total 370,487.44. The guarded payment-to-transaction ratio is 0.743735, or 74.37%.

**Evidence:** Each value was summed independently from its native fact. The totals match the validated analytics baseline with zero differences. No encounter, claim, or transaction fact was joined to another fact for summation.

**Interpretation:** The transaction dataset records substantial payment and transfer movement relative to transaction amount and can support source-level financial-flow analysis.

**Limitation:** The ratio is a descriptive source-measure ratio, not a collection rate, reimbursement rate, margin, or profitability KPI. Encounter claim cost, payer coverage, transaction amount, payments, and transfers have different source semantics and must not be netted without an approved rule.

### Finding 5 — Transaction-derived claim value is concentrated in a small number of claims

**Observation:** The largest transaction-derived claim value is 110,073.60, representing 15.23% of total transaction amount. The top 10 claims total 238,718.84, or 33.02% of 722,860.68.

**Evidence:** Transaction rows were aggregated to one row per `claim_id` inside `fact_claim_transaction`; no claim-header fact join was used. The top claim contains five transaction rows. Top-10 values reconcile within the full transaction total.

**Interpretation:** A small set of claim IDs drives a sizable share of source transaction value. These claims are appropriate candidates for transaction-level drill-through and semantic review.

**Limitation:** “Claim value” here means summed transaction `amount`; it is not an adjudicated allowed amount, paid claim total, cost of care, or profitability measure. The data is synthetic.

## Payer Findings

### Finding 6 — Payer attribution is fragmented, with a material Unknown share

**Observation:** Unknown/Unmapped is the largest primary-payer claim category: 124 of 464 claims (26.72%). The largest identified primary payer has 77 claims (16.59%). At transaction grain, the leading identified payer accounts for 174,179.86 (24.10%) of amount, while Unknown accounts for 756 of 5,403 transactions (13.99%) and 136,596.32 (18.90%) of amount.

**Evidence:** Claim percentages use all claim headers as the denominator. Transaction amount percentages use all 722,860.68 of transaction amount. Payer grouping occurs independently in each fact and reconciles to its native count and amount totals.

**Interpretation:** Unknown payer attribution is large enough to affect payer-mix reporting, especially claim counts. Identified payer concentration is present but no single identified payer dominates a majority of either claims or transaction amount.

**Limitation:** V1 payer members are inferred identifiers without payer names or plan attributes. Unknown reflects absent source insurance IDs, not a failed non-null dimension lookup. Encounter payer and claim-primary payer are different roles.

## Provider & Organization Findings

### Finding 7 — Encounter volume is distributed across many inferred providers and organizations

**Observation:** The leading organization and leading provider each account for 27 encounters (9.54%). The top three organizations and top three providers each account for 76 of 283 encounters (26.86%).

**Evidence:** Organization and provider counts were grouped separately from `fact_encounter`; each grouping reconciles to all 283 encounters. The leading organization ID is `497f39dd-280e-3d58-af5b-c5e3a3a09b10`; the leading provider ID is `4a95a55e-2675-3e3a-99ba-a529113a702e`.

**Interpretation:** Encounter volume is moderately concentrated rather than dominated by one identifier in this extract. The queries demonstrate ranking and concentration analysis across conformed dimensions.

**Limitation:** Provider and organization dimensions contain inferred IDs rather than names, specialties, capacity, staffing, ownership, or service-line attributes. Volume and duration cannot establish performance or efficiency.

## Clinical Utilization Findings

### Finding 8 — A small procedure set accounts for much of procedure activity

**Observation:** There are 1,003 procedure occurrences with total source base cost of 504,449.26. Depression screening is the most frequent and highest-cost concept, with 116 occurrences (11.57%) and 50,042.40 (9.92% of procedure base cost). The 10 most frequent concepts account for 55.13% of procedures; the 10 highest-cost concepts account for 47.50% of base cost.

**Evidence:** Procedure counts and costs were grouped by `procedure_key` from `fact_procedure` and reconcile to 1,003 rows and 504,449.26. Frequency and cost rankings were calculated independently.

**Interpretation:** Procedure utilization in the extract is concentrated in preventive, assessment, medication-reconciliation, and dental-care concepts. This supports focused service-category drill-down.

**Limitation:** Synthea procedure base cost is not actual hospital cost, reimbursement, margin, workload, or clinical value. Concept frequency is driven by the synthetic generation model.

### Finding 9 — Condition occurrences are even more concentrated in the leading concepts

**Observation:** There are 252 recorded condition occurrences. “Medication review due” is the leading concept with 57 occurrences (22.62%) and appears across all 10 patients. The top 10 condition concepts account for 157 occurrences (62.30%).

**Evidence:** Condition counts grouped by `condition_key` reconcile to all 252 `fact_condition_occurrence` rows. The next most frequent concept, gingivitis, has 22 occurrences across seven patients.

**Interpretation:** A limited set of clinical and social-context concepts drives most recorded condition activity in this extract.

**Limitation:** Recorded occurrence frequency is not prevalence, incidence, disease burden, severity, outcome, or quality of care. Several leading concepts are findings or situations rather than diseases.

## Time Trend Findings

### Finding 10 — Monthly trends show sharp peaks and percentage volatility from small bases

**Observation:** Peak monthly volume is eight encounters in September 2021 and 14 claims in June 2023. Peak monthly transaction amount is 135,518.51 in June 2026. The strongest comparable encounter MoM increase is from one to eight encounters (+700%) in September 2021; a comparable claim increase is from one to seven (+600%) in June 2022 and September 2019. The largest transaction-amount MoM percentage is +2,128.63% in December 2025, rising from 164.16 to 3,658.52; June 2026 rises 1,485.81% from 8,545.70 to the value peak.

**Evidence:** Comparisons use a continuous monthly spine and include only cases where both current and immediately prior calendar months are positive. The peak rolling-three-month averages are 5.00 encounters ending November 2021, 10.67 claims ending June 2023, and 49,693.85 transaction amount ending July 2026. Comparable encounter YoY increases include September 2019 rising from one to five (+400%).

**Interpretation:** Activity and financial movements are episodic in this small synthetic longitudinal sample. Absolute values and rolling averages are more stable evidence than percentage changes alone.

**Limitation:** Large MoM and YoY percentages frequently arise from denominators of one event or very small amounts. The 1935–2026 event range represents synthetic patient histories, not a continuous hospital reporting series; these changes must not be interpreted as real growth, decline, seasonality, or operational performance.

## Data Quality / Interpretation Notes

- All 35 analytical queries executed successfully in read-only transactions.
- Validation failures: 0. No row or amount multiplication was detected.
- Reported fact totals reconcile to the validated Analytics V1 baseline. No measure was summed after a direct fact-to-fact join.
- The 796 claim transaction rows with `source_unset_to_timestamp_warning = true` represent 14.7326% of transaction rows. Synthea serialized an unset stop timestamp as `1970-01-01T00:00:00Z`; Analytics V1 preserves the source timestamp, retains the warning, and assigns Unknown `to_date_key = 0`.
- Unknown primary payer affects 26.72% of claims. Unknown claim-primary payer affects 13.99% of transaction rows and 18.90% of transaction amount. These rows remain in all totals.
- Percentages use their stated native-fact denominator. Displayed percentages can differ from 100% by rounding.
- Event IDs are synthetic. UUIDs are retained only for evidence and drill-through, not as descriptive business labels.

## Current Limitations

- Only 10 synthetic patients are included; no result is representative of a real population or hospital.
- Provider, organization, and payer master descriptions are not staged in V1.
- Financial measures have source-specific meanings and no operating expense, budget, cash posting, denial, or adjudication context.
- No staffing, capacity, bed, appointment, quality, outcome, IT, or device operational data is present.
- No risk adjustment, benchmark, target, confidence interval, or statistical inference has been defined.
- Patient and reference dimensions are current-state, not historized.
- Time-series percentages are sensitive to sparse months and small denominators.

## Questions for V2

1. Which authoritative definitions should govern billed amount, allowed amount, paid amount, transfers, outstanding balance, patient responsibility, and payer coverage?
2. Should provider, organization, and payer master sources be staged to add names, specialties, plan types, ownership, and hierarchies?
3. Which encounter classes require separate duration and utilization definitions?
4. What minimum volume and prior-period thresholds should suppress unstable MoM and YoY percentages?
5. Should high-value claim review use transaction type, charge line, payment, transfer, and adjustment sequences?
6. Which clinical concepts should be grouped into governed service lines or condition categories?
7. What production audit, incremental-load, and as-of-date rules are required before operational reporting?
8. Which approved business KPIs should be formalized before Power BI implementation?
