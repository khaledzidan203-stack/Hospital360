# Hospital360 Power BI KPI Dictionary

## Governance Rule

**One KPI = One Definition = One Calculation Logic.** These definitions apply to the validated 5,000-patient synthetic portfolio model. They are not real hospital, clinical, operational-performance, or profitability KPIs.

Financial measures remain at their native source grain. Encounter, transaction, and procedure amounts must not be added together or treated as interchangeable.

## Activity KPIs

| KPI name | Business definition | Numerator | Denominator | Grain | Source fact | DAX measure | Interpretation | Limitation |
|---|---|---|---|---|---|---|---|---|
| Total Patients | Distinct non-Unknown patients represented in encounter activity under the current filters | Distinct encounter `patient_key` excluding 0 | N/A | Patient represented in encounters | `fact_encounter` | `[Total Patients]` | Synthetic patients with encounter activity | Not an enrolled or real hospital population |
| Total Encounters | Number of encounter events under current filters | Encounter rows | N/A | Encounter event | `fact_encounter` | `[Total Encounters]` | Encounter activity volume | Not demand, throughput, or efficiency by itself |
| Total Claims | Number of claim-header rows under current filters | Claim rows | N/A | Claim header | `fact_claim` | `[Total Claims]` | Claim-header volume | Multiple claims may exist per encounter |
| Total Claim Transactions | Number of claim-transaction event rows | Transaction rows | N/A | Claim transaction | `fact_claim_transaction` | `[Total Claim Transactions]` | Financial event-line volume | Not claim count or payment count |
| Total Procedures | Number of performed procedure occurrences | Procedure rows | N/A | Procedure occurrence | `fact_procedure` | `[Total Procedures]` | Procedure activity volume | Not clinical value, quality, or workload |
| Total Condition Occurrences | Number of recorded condition occurrences | Condition occurrence rows | N/A | Condition occurrence | `fact_condition_occurrence` | `[Total Condition Occurrences]` | Recorded synthetic condition activity | Occurrence is not prevalence or incidence |
| Encounters per Patient | Average encounter rows per represented patient | Total Encounters | Total Patients | Portfolio/filter context | `fact_encounter` | `[Encounters per Patient]` | Relative encounter frequency | Requires observation-time and risk context for operational use |
| Claims per Encounter | Average claim headers per distinct encounter lineage represented in the claim fact | Total Claims | Distinct nonblank claim `encounter_id` | Claim-header/encounter-lineage context | `fact_claim` | `[Claims per Encounter]` | Claim-header multiplicity within the native claim fact | Encounter ID is lineage, not a Power BI fact relationship; does not imply duplicate claims |
| Procedures per Encounter | Ratio of procedure occurrences to encounters | Total Procedures | Total Encounters | Portfolio/filter context | `fact_procedure`, `fact_encounter` as independent measures | `[Procedures per Encounter]` | Procedure activity relative to encounters | Does not measure appropriateness or intensity adjustment |

## Financial Activity KPIs

| KPI name | Business definition | Numerator | Denominator | Grain | Source fact | DAX measure | Interpretation | Limitation |
|---|---|---|---|---|---|---|---|---|
| Encounter Base Cost | Sum of source base encounter cost | `base_encounter_cost` | N/A | Encounter | `fact_encounter` | `[Encounter Base Cost]` | Synthetic base cost attached to encounters | Not actual hospital cost accounting |
| Encounter Claim Cost | Sum of source total claim cost carried on encounters | `total_claim_cost` | N/A | Encounter | `fact_encounter` | `[Encounter Claim Cost]` | Encounter-grain claim-cost activity | Must not be reconciled directly to transaction amount |
| Encounter Payer Coverage | Sum of payer coverage carried on encounters | `payer_coverage` | N/A | Encounter | `fact_encounter` | `[Encounter Payer Coverage]` | Encounter-grain source coverage | Not cash received or adjudicated reimbursement |
| Transaction Amount | Sum of transaction `amount` | `amount` | N/A | Claim transaction | `fact_claim_transaction` | `[Transaction Amount]` | Native transaction-grain financial activity | Null amount rows may carry other transaction fields |
| Transaction Payments | Sum of transaction payments | `payments` | N/A | Claim transaction | `fact_claim_transaction` | `[Transaction Payments]` | Payment field activity | Not confirmed cash collection |
| Transaction Transfers | Sum of transaction transfers | `transfers` | N/A | Claim transaction | `fact_claim_transaction` | `[Transaction Transfers]` | Transfer field activity | Transfer semantics are source-specific |
| Procedure Base Cost | Sum of source procedure base cost | `base_cost` | N/A | Procedure occurrence | `fact_procedure` | `[Procedure Base Cost]` | Synthetic procedure cost activity | Not reimbursement, margin, or actual resource cost |
| Claim Amount | Transaction amount presented at transaction-derived claim context | Transaction Amount | N/A | Claim lineage over transaction rows | `fact_claim_transaction` | `[Claim Amount]` | Allows transaction value to be grouped by transaction `claim_id` | Semantic alias, not a claim-header amount; equals Transaction Amount in total |
| Payment Ratio | Transaction payments divided by transaction amount | Transaction Payments | Transaction Amount | Transaction portfolio/filter context | `fact_claim_transaction` | `[Payment Ratio]` | Relative payment field share of transaction amount | Not collection, reimbursement, or profitability rate |
| Payer Coverage Ratio | Encounter payer coverage divided by encounter claim cost | Encounter Payer Coverage | Encounter Claim Cost | Encounter portfolio/filter context | `fact_encounter` | `[Payer Coverage Ratio]` | Relative source coverage at encounter grain | Not payer contract performance or cash realization |

## Encounter Time KPIs

The active relationship is `dim_date[date_key] → fact_encounter[start_date_key]`.

| KPI name | Business definition | Numerator | Denominator | Grain | Source fact | DAX measure | Interpretation | Limitation |
|---|---|---|---|---|---|---|---|---|
| Encounters MTD | Encounter count from month start through current date context | Total Encounters in DATESMTD | N/A | Encounter/start month | `fact_encounter` | `[Encounters MTD]` | Current month-to-date activity | Requires valid date context; synthetic history |
| Encounters YTD | Encounter count from year start through current date context | Total Encounters in DATESYTD | N/A | Encounter/start year | `fact_encounter` | `[Encounters YTD]` | Current year-to-date activity | Partial years must be labeled |
| Encounters Previous Month | Encounter count in the comparable preceding month context | Prior-month Total Encounters | N/A | Encounter/start month | `fact_encounter` | `[Encounters Previous Month]` | Month comparison baseline | Blank when no comparable prior month |
| Encounters MoM Change % | Change from previous month divided by previous month | Current encounters minus previous-month encounters | Previous-month encounters | Encounter/start month | `fact_encounter` | `[Encounters MoM Change %]` | Direction and size of month change | Sparse synthetic periods can create unstable percentages |
| Encounters Previous Year | Encounter count in comparable prior-year date context | Prior-year Total Encounters | N/A | Encounter/start date period | `fact_encounter` | `[Encounters Previous Year]` | Prior-year comparison baseline | Use only for comparable periods |
| Encounters YoY Change % | Change from prior year divided by prior-year encounters | Current encounters minus prior-year encounters | Prior-year encounters | Encounter/start date period | `fact_encounter` | `[Encounters YoY Change %]` | Direction and size of comparable annual change | Synthetic history is not real growth or seasonality |

## Transaction-Derived Claim Time KPIs

These measures use the active transaction **from-date**, not claim service date. V1 intentionally has no fact-to-fact relationship that could propagate claim service date to transaction value.

| KPI name | Business definition | Numerator | Denominator | Grain | Source fact | DAX measure | Interpretation | Limitation |
|---|---|---|---|---|---|---|---|---|
| Claim Amount MTD | Transaction-derived claim amount from month start through current transaction-date context | Claim Amount in DATESMTD | N/A | Transaction from month / claim lineage | `fact_claim_transaction` | `[Claim Amount MTD]` | MTD transaction value grouped conceptually by claim | Same total as Transaction Amount MTD; not claim service-date value |
| Claim Amount YTD | Transaction-derived claim amount from year start through current transaction-date context | Claim Amount in DATESYTD | N/A | Transaction from year / claim lineage | `fact_claim_transaction` | `[Claim Amount YTD]` | YTD transaction-derived claim value | Partial years and synthetic history require caution |
| Claim Amount Previous Month | Transaction-derived claim amount in prior transaction month | Prior-month Claim Amount | N/A | Transaction from month | `fact_claim_transaction` | `[Claim Amount Previous Month]` | Prior-month claim-lineage value baseline | Not a claim-header service-month measure |
| Claim Amount MoM Change % | Change from prior transaction month divided by prior month | Current Claim Amount minus prior month | Prior-month Claim Amount | Transaction from month | `fact_claim_transaction` | `[Claim Amount MoM Change %]` | Monthly transaction-derived value change | Sparse periods can make percentage unstable |
| Claim Amount Previous Year | Transaction-derived claim amount in comparable prior-year transaction context | Prior-year Claim Amount | N/A | Transaction from period | `fact_claim_transaction` | `[Claim Amount Previous Year]` | Prior-year comparison baseline | Only valid for comparable transaction periods |
| Claim Amount YoY Change % | Change from prior-year transaction-derived claim amount | Current Claim Amount minus prior year | Prior-year Claim Amount | Transaction from period | `fact_claim_transaction` | `[Claim Amount YoY Change %]` | Comparable annual change | Not revenue growth or profitability |

## Transaction Time KPIs

The active relationship is `dim_date[date_key] → fact_claim_transaction[from_date_key]`.

| KPI name | Business definition | Numerator | Denominator | Grain | Source fact | DAX measure | Interpretation | Limitation |
|---|---|---|---|---|---|---|---|---|
| Transaction Amount MTD | Transaction amount from month start through current date context | Transaction Amount in DATESMTD | N/A | Transaction/from month | `fact_claim_transaction` | `[Transaction Amount MTD]` | Current MTD transaction activity | Not revenue or cash flow |
| Transaction Amount YTD | Transaction amount from year start through current date context | Transaction Amount in DATESYTD | N/A | Transaction/from year | `fact_claim_transaction` | `[Transaction Amount YTD]` | Current YTD transaction activity | Partial years must be labeled |
| Transaction Amount Previous Month | Transaction amount in prior month context | Prior-month Transaction Amount | N/A | Transaction/from month | `fact_claim_transaction` | `[Transaction Amount Previous Month]` | Prior-month baseline | Blank when no comparable month |
| Transaction Amount MoM Change % | Change from previous month divided by previous month | Current amount minus previous month | Previous-month amount | Transaction/from month | `fact_claim_transaction` | `[Transaction Amount MoM Change %]` | Direction and size of monthly change | Sparse synthetic periods can cause volatility |
| Transaction Amount Previous Year | Transaction amount in comparable prior-year context | Prior-year Transaction Amount | N/A | Transaction/from period | `fact_claim_transaction` | `[Transaction Amount Previous Year]` | Prior-year comparison baseline | Use only for comparable periods |
| Transaction Amount YoY Change % | Change from prior year divided by prior year | Current amount minus prior year | Prior-year amount | Transaction/from period | `fact_claim_transaction` | `[Transaction Amount YoY Change %]` | Comparable annual transaction change | Not real financial growth or seasonality |

## Concentration, Unknown, and Date-Role KPIs

| KPI name | Business definition | Numerator | Denominator | Grain | Source fact | DAX measure | Interpretation | Limitation |
|---|---|---|---|---|---|---|---|---|
| Top Payer Share | Largest identified payer transaction amount divided by selected payer transaction amount | Maximum identified payer Transaction Amount | Selected Transaction Amount | Payer within current context | `fact_claim_transaction` | `[Top Payer Share]` | Concentration in the largest identified payer | Payer attributes are inferred synthetic identifiers; Unknown excluded from numerator |
| Unknown Payer % | Claims with Unknown primary payer divided by all claims under non-payer filters | Claims where payer key = 0 | Total Claims with payer filter removed | Claim header | `fact_claim` | `[Unknown Payer %]` | Primary payer attribution gap | Unknown does not necessarily mean uninsured |
| Top Provider Share | Largest identified provider encounter count divided by selected encounters | Maximum identified provider encounters | Selected Total Encounters | Provider/encounter | `fact_encounter` | `[Top Provider Share]` | Encounter-volume concentration | Not provider performance or productivity |
| Top Organization Share | Largest identified organization encounter count divided by selected encounters | Maximum identified organization encounters | Selected Total Encounters | Organization/encounter | `fact_encounter` | `[Top Organization Share]` | Encounter-volume concentration | Not organization efficiency or capacity utilization |
| Unknown Transaction Payer % | Transactions with Unknown claim-primary payer divided by all transactions | Transactions where payer key = 0 | Total transactions with payer filter removed | Claim transaction | `fact_claim_transaction` | `[Unknown Transaction Payer %]` | Transaction payer-attribution gap | Unknown reflects absent source payer context, not failed model integrity |
| Sentinel To-Date Transactions | Transactions carrying the Synthea unset-stop warning | Rows where sentinel warning is true | N/A | Claim transaction | `fact_claim_transaction` | `[Sentinel To-Date Transactions]` | Preserved source sentinel volume | Valid source behavior, not automatic error or real 1970 activity |
| Sentinel To-Date % | Sentinel-warning transactions divided by all transactions | Sentinel To-Date Transactions | Total Claim Transactions | Claim transaction | `fact_claim_transaction` | `[Sentinel To-Date %]` | Relative scale of unset stop timestamps | Does not include 547 non-sentinel warnings, which remain To Be Validated |
| Encounters by Stop Date | Encounter count evaluated through inactive stop-date role | Total Encounters using stop-date relationship | N/A | Encounter/stop date | `fact_encounter` | `[Encounters by Stop Date]` | Encounter completion-date activity | Do not compare to start-date counts without labeling roles |
| Procedures by Stop Date | Procedure count evaluated through inactive stop-date role | Total Procedures using stop-date relationship | N/A | Procedure/stop date | `fact_procedure` | `[Procedures by Stop Date]` | Procedure completion-date activity | Do not mix start and stop date contexts silently |

## Formatting Standards

- Counts: whole number.
- Per-unit ratios: decimal, two places.
- Financial activity: fixed decimal, two places; no currency symbol until currency is governed.
- Shares and change measures: percentage, two places.
- Time measures: display only where a valid `dim_date` context exists.

Total governed measures/KPIs: **46**.
