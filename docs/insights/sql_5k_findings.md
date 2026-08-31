# Hospital360 SQL Analytical Findings

## Portfolio Dataset — 5,000 Synthetic Patients

**Status:** Validated portfolio-scale SQL analytical baseline

This report uses synthetic Synthea healthcare data, not real hospital data. It demonstrates analytical methodology, dimensional modeling, reconciliation, and controlled interpretation. The findings are not clinical conclusions. Financial fields describe synthetic healthcare activity and claim-related source measures; they are not hospital profit-and-loss, margin, cash, or profitability measures.

## Regression and Dataset Scope

All six existing SQL analysis scripts ran unchanged in read-only transactions. All 35 analytical queries and 12 validation queries completed successfully: 47 of 47 queries passed, with no SQL failures, direct fact-to-fact joins, amount multiplication, fact-count changes, or database modifications.

| Measure | Validated result |
|---|---:|
| Synthetic patients | 5,000 |
| Encounters | 253,563 |
| Claims | 435,751 |
| Claim transactions | 3,966,064 |
| Condition occurrences | 159,348 |
| Procedures | 696,202 |
| Encounter base cost | 28,981,362.04 |
| Encounter total claim cost | 731,937,228.14 |
| Encounter payer coverage | 526,304,744.54 |
| Transaction amount | 837,678,683.76 |
| Transaction payments | 697,790,613.67 |
| Transaction transfers | 279,776,140.18 |
| Procedure base cost | 716,784,016.74 |

The full captured-output regression took 242.456 seconds. Per-script orchestration times were 30.191 seconds for patient/encounter, 91.273 seconds for claims/financial, 30.429 seconds for payer, 30.140 seconds for provider/organization, 30.190 seconds for clinical utilization, and 30.139 seconds for time trends. Short-script elapsed times include up to one 30-second monitoring interval and should be treated as operational wall-clock measurements rather than query-engine microbenchmarks.

## Patient & Encounter Activity

### Finding 1 — Encounter activity is broadly distributed across the portfolio

**Business observation:** The dataset contains 253,563 encounters across 5,000 patients, averaging 50.71 encounters per patient. Counts range from 1 to 790, while the three highest-volume patients contribute only 2,248 encounters, or 0.89%.

**Interpretation:** Patient-level utilization analysis is substantially less dominated by a few records than in the smoke test, making rankings and segmentation more useful for portfolio demonstrations.

**Important limitation:** These are synthetic longitudinal histories, not utilization rates for a real population. No observation window, enrollment adjustment, or risk adjustment has been applied.

### Finding 2 — Ambulatory, wellness, and outpatient activity dominate encounter volume

**Business observation:** Ambulatory encounters contribute 136,632 rows (53.88%), wellness 59,091 (23.30%), and outpatient 33,466 (13.20%). Together they represent 90.38% of encounters.

**Interpretation:** The generated portfolio is primarily oriented toward routine ambulatory and preventive activity, with inpatient encounters representing only 1.47%.

**Important limitation:** Synthea encounter classes reflect generator behavior. They do not establish real service demand, capacity requirements, or care-setting performance.

### Finding 3 — Encounter duration has a pronounced long tail

**Business observation:** All 253,563 encounters have chronologically eligible timestamps. Median elapsed duration is 41.90 minutes, while the mean is 321.14 minutes.

**Interpretation:** A relatively small number of long-duration events materially raise the overall average. Duration should be segmented by encounter class before operational use.

**Important limitation:** Source elapsed duration is not clinician effort, waiting time, staffed bed time, or an efficiency measure.

## Claims & Financial Activity

### Finding 4 — Multiple claim headers per encounter remain a material grain risk

**Business observation:** The 435,751 claim headers map to 253,563 encounter lineage IDs, averaging 1.72 claims per encounter. There are 100,766 encounters (39.74%) with more than one claim, and the maximum is 78.

**Interpretation:** Encounter measures must not be joined directly to claim or transaction rows before aggregation. The larger dataset confirms that this is an architectural requirement rather than a smoke-test artifact.

**Important limitation:** Multiple claim headers do not by themselves imply duplication, denial, rebilling, or poor billing quality.

### Finding 5 — Financial activity reconciles, but the measures remain semantically distinct

**Business observation:** Encounter total claim cost is 731,937,228.14 and payer coverage is 526,304,744.54. At transaction grain, amount is 837,678,683.76, payments are 697,790,613.67, and transfers are 279,776,140.18. The guarded payment-to-transaction ratio is 0.833005, or 83.30%.

**Interpretation:** The model supports internally consistent analysis of source-level healthcare financial movement at each native grain.

**Important limitation:** The ratio is not a collection rate, reimbursement rate, margin, or profitability KPI. No operating expenses, budget, adjudication, or cash-posting data are present.

### Finding 6 — Claim-value concentration is low at portfolio scale

**Business observation:** The largest transaction-derived claim value is 335,532.66, only 0.04% of total transaction amount. The top 10 claims total 2,884,057.26, or 0.34%.

**Interpretation:** Aggregate financial activity is distributed across many claims; the extreme concentration seen in the 10-patient smoke test does not persist.

**Important limitation:** “Claim value” means transaction `amount` summed by claim ID. It is not an adjudicated allowed amount or final paid-claim value.

## Payer Analysis

### Finding 7 — The leading payer is material but does not dominate the portfolio

**Business observation:** The leading identified primary payer accounts for 134,687 claims (30.91%). At transaction grain, it contributes 222,089,417.95, or 26.51% of transaction amount.

**Interpretation:** Payer activity is concentrated enough to support mix analysis but remains distributed across multiple payer identifiers.

**Important limitation:** Payer dimensions contain inferred synthetic identifiers without names, product types, contracts, or reimbursement terms.

### Finding 8 — Unknown payer attribution is lower than in the smoke test but remains reportable

**Business observation:** Unknown primary payer affects 35,972 claims (8.26%). At transaction grain, Unknown affects 171,235 rows (4.32%) and 47,175,305.28 of amount (5.63%).

**Interpretation:** The Unknown-member strategy retains financial activity without breaking dimensional relationships, while making attribution gaps measurable.

**Important limitation:** Unknown reflects missing source insurance identifiers, not a broken non-null lookup or evidence of uninsured status.

## Provider / Organization Activity

### Finding 9 — Encounter volume is dispersed across provider and organization identifiers

**Business observation:** The leading provider and organization each account for 5,598 encounters (2.21%). Their respective top three identifiers account for 15,251 encounters (6.01%).

**Interpretation:** No single inferred identifier dominates encounter activity, supporting broader ranking and drill-down than the smoke-test sample.

**Important limitation:** Provider and organization dimensions lack names, specialties, staffing, capacity, ownership, and service-line hierarchies. Volume does not demonstrate productivity or efficiency.

## Clinical Utilization

### Finding 10 — Procedure activity is concentrated in a limited concept set

**Business observation:** There are 696,202 procedure occurrences with 716,784,016.74 of source base cost. Depression screening is the leading concept with 67,867 occurrences (9.75%) and 29,277,823.80 of base cost. The top 10 procedure concepts contribute 45.93% of occurrences and 21.10% of base cost.

**Interpretation:** Frequency and cost rankings identify a reusable shortlist for service-category drill-through, while showing that frequency and cost concentration are not identical.

**Important limitation:** Synthea base cost is not actual hospital cost, reimbursement, workload, clinical value, or margin.

### Finding 11 — Condition recording is concentrated, but occurrence is not prevalence

**Business observation:** There are 159,348 condition occurrences. “Medication review due” leads with 30,928 occurrences (19.41%) and appears across all 5,000 patients. The top 10 concepts account for 57.94% of occurrences.

**Interpretation:** A limited set of clinical and situational concepts drives much of the recorded condition activity.

**Important limitation:** Recorded occurrences are not prevalence, incidence, severity, outcome, care quality, or causation. Some concepts are findings or situations rather than diseases.

## Time Trends

### Finding 12 — Portfolio-scale monthly trends are more usable, but remain synthetic histories

**Business observation:** Peak monthly activity is 2,762 encounters in April 2021 and 4,126 claims in March 2021. Peak transaction amount is 7,194,615.82 in May 2026.

**Interpretation:** Larger monthly counts make absolute trends and rolling measures substantially more stable and readable than in the 10-patient smoke test.

**Important limitation:** The time series combines synthetic patient histories over a long date range. Peaks must not be interpreted as real hospital growth, seasonality, shocks, or operational performance.

## Data Quality and Interpretation Notes

- Five independent transaction-amount regroupings—claim, month, provider, organization, and payer—each reconciled to the native fact with a 0.00 difference.
- Fact counts and all seven financial baselines were unchanged after regression.
- The analytics model retains 317,271 source sentinel transaction stop timestamps. There are 547 additional non-sentinel date-order warnings, still classified **To Be Validated**.
- Association must not be described as causation, and synthetic clinical activity must not be presented as real hospital evidence.

## Smoke Test → 5K Comparison

The 10-patient run was a pipeline and query-logic smoke test, not a benchmark. The same 35 analytical and 12 validation queries remained stable at 5K scale, with zero failures and zero multiplication differences.

| Metric | 10-patient smoke test | 5K portfolio |
|---|---:|---:|
| Top-three patient share of encounters | 48.76% | 0.89% |
| Largest transaction-derived claim share | 15.23% | 0.04% |
| Top-10 claim-value share | 33.02% | 0.34% |
| Unknown primary-payer claim share | 26.72% | 8.26% |
| Unknown transaction row share | 13.99% | 4.32% |
| Unknown transaction amount share | 18.90% | 5.63% |
| Leading provider/organization encounter share | 9.54% | 2.21% |
| Top-three provider/organization encounter share | 26.86% | 6.01% |
| Top-10 procedure frequency share | 55.13% | 45.93% |
| Top-10 condition occurrence share | 62.30% | 57.94% |

The prior emphasis on a few high-value claims and a few high-volume patients should therefore not carry forward. Larger monthly absolute counts improve trend usability, although percentage changes and causal interpretations still require guardrails.

## Current Limitations and Next Step

No real hospital, staffing, capacity, budget, operating-expense, adjudication, quality, outcome, or technology-operations data is included. Descriptive master attributes remain limited. The validated SQL baseline is suitable for Python exploratory analysis, provided Python preserves fact grains, reconciled totals, Unknown-member handling, and synthetic-data disclaimers.
