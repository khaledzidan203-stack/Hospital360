# Hospital360 Python EDA Findings

## Status

Validated Python EDA foundation for the final 5,000-patient analytical portfolio dataset.

This analysis uses synthetic Synthea healthcare data, not real hospital or patient data. It demonstrates analytical methodology and pipeline behavior; it does not provide clinical conclusions. Financial fields describe synthetic healthcare and claim activity, not hospital profit and loss, cash flow, margin, or profitability.

## Methodology

- PostgreSQL `analytics` is the analytical source of truth.
- Python database access is read-only and obtains credentials from environment variables or the ignored `.env` file.
- The validated 5K fact counts and seven financial totals are checked before EDA proceeds.
- The 253,563-row encounter fact is a bounded encounter-grain extract.
- The 3,966,064-row transaction fact is not loaded wholesale into pandas. It is aggregated in PostgreSQL to claim, payer, or month grain, or summarized with SQL-side percentiles.
- Procedure rows are aggregated to encounter grain before comparison with encounter measures, preventing fact multiplication.
- Distribution analysis uses medians, IQR, percentiles, skewness, and concentration shares.
- Outliers are flagged, not removed. IQR flags are statistical review indicators rather than automatic data-quality failures.
- Pearson is reported for linear association and Spearman for monotonic association. Association does not imply causation.
- A deterministic 20,000-row encounter sample is used only for one scatterplot; every reported correlation uses all 253,563 eligible encounter-grain rows.

## Dataset Scope and Baseline

| Fact | Validated rows |
|---|---:|
| Encounter | 253,563 |
| Claim | 435,751 |
| Claim transaction | 3,966,064 |
| Condition occurrence | 159,348 |
| Procedure | 696,202 |

All baseline financial measures reconciled exactly to the SQL milestone:

| Measure | Validated total |
|---|---:|
| Encounter base cost | 28,981,362.04 |
| Encounter total claim cost | 731,937,228.14 |
| Encounter payer coverage | 526,304,744.54 |
| Transaction amount | 837,678,683.76 |
| Transaction payments | 697,790,613.67 |
| Transaction transfers | 279,776,140.18 |
| Procedure base cost | 716,784,016.74 |

## Findings

### Finding 1 — Patient encounter frequency is right-skewed

**Observation:** The median patient has 34 encounters, the 95th percentile is 106, and the maximum is 790. The mean is 50.71 and skewness is 5.89.

**Interpretation:** A comparatively small upper tail raises the average above the median, so the median and percentile bands are more useful than the mean alone for synthetic utilization segmentation.

**Limitation:** These are synthetic longitudinal histories without enrollment-time or risk adjustment; they are not real utilization rates.

### Finding 2 — Encounter duration has an extreme upper tail

**Observation:** Median duration is 41.9 minutes, while p99 is 6,471 minutes and the maximum is 299,535 minutes. The IQR rule flags 10,247 encounters (4.04%) as high-duration observations.

**Outlier classification:** Durations above the IQR threshold but within the broader class-specific context may be expected long-running synthetic activity. The extreme maximum is a **possible synthetic anomaly / requires investigation**; it is retained unchanged.

**Limitation:** Elapsed encounter time is not clinician effort, waiting time, bed occupancy, or operational efficiency.

### Finding 3 — Encounter claim cost is strongly right-skewed

**Observation:** Median encounter total claim cost is 919.90, p99 is 37,200.25, and the maximum is 322,799.96. Skewness is 10.17, and 25,555 rows (10.08%) exceed the standard upper IQR boundary.

**Outlier classification:** Most IQR flags represent **expected high-value synthetic activity** within a skewed cost distribution. Values above p99 remain **requires investigation**, not errors and not deletion candidates.

**Limitation:** Source claim cost is not an adjudicated allowed amount, hospital revenue, cost accounting measure, or margin.

### Finding 4 — Multiple claims per encounter create a long but sparse tail

**Observation:** Claims per encounter have a median of 1, p95 of 4, p99 of 7, and a maximum of 78. Claim count and transaction amount have Pearson correlation 0.343 but Spearman correlation only 0.113.

**Interpretation:** A few high-count or high-value encounters influence the linear relationship; simply having more claim headers is only weakly associated with a consistently higher transaction amount across the rank order.

**Limitation:** Multiple claim headers do not establish rebilling, denial, duplication, or billing problems.

### Finding 5 — Claim value is highly concentrated in its upper one percent

**Observation:** Transaction-derived claim value has a median of 259.88, p99 of 24,031.25, and a maximum of 335,532.66. The highest 1% of claims contributes 26.51% of total claim value. The IQR rule flags 63,169 claims (14.50%).

**Interpretation:** Percentile and concentration views add material context beyond the aggregate total. The large IQR-flag share reflects strong skew and is not evidence that 14.50% of claims are invalid.

**Limitation:** Claim value is the sum of transaction `amount` at claim grain, not final adjudication or profitability.

### Finding 6 — Non-null transaction amounts also have a substantial upper tail

**Observation:** Among 1,845,597 transactions with a non-null amount, the median is 136.00, p99 is 7,425.44, and the maximum is 267,860.97. There are 113,950 high-IQR observations and 18,456 above p99.

**Outlier classification:** High-IQR amounts are retained as **expected high-value activity** unless corroborating evidence identifies a source anomaly. The p99 tail remains **requires investigation** for contextual review.

**Limitation:** Rows with null `amount` can still carry other transaction measures; the non-null amount distribution is not the distribution of all financial fields.

### Finding 7 — Payer mix varies in both volume and value

**Observation:** The leading identified primary payer represents 30.91% of claims and 26.51% of transaction-derived claim value. Across material payer groups, observed payment-to-value ratios vary, while Unknown represents 8.26% of claims and 5.63% of value.

**Interpretation:** Payer-level medians and value shares reveal variation hidden by portfolio totals, while the Unknown member keeps unattributed activity visible.

**Limitation:** Synthetic payer identifiers lack contract, product, adjudication, and reimbursement context. Ratios are not collection or contract-performance KPIs.

### Finding 8 — Provider and organization volumes are heterogeneous

**Observation:** Both provider and organization encounter distributions have a median of 59, p95 of 1,330.8, a maximum of 5,598, and a coefficient of variation of 2.25.

**Interpretation:** Activity is broadly distributed but still has a pronounced upper tail, making percentile-based peer bands preferable to a single average.

**Limitation:** Missing specialty, staffing, capacity, service-line, and case-mix denominators prevent productivity or performance labels.

### Finding 9 — Procedure frequency follows a long-tail concept distribution

**Observation:** Across 392 populated procedure concepts, median occurrence count is 98 and p99 is 27,779.59. The top 10 concepts account for 45.93% of all procedure occurrences.

**Interpretation:** Python distribution analysis quantifies the long tail and identifies where category-level drill-downs can add the most explanatory value.

**Limitation:** Procedure frequency and Synthea base cost do not establish clinical efficacy, workload, reimbursement, or quality.

### Finding 10 — Condition occurrences are more concentrated than procedures

**Observation:** Across 295 populated condition concepts, median occurrence count is 67, p99 is 11,036.12, and the top 10 concepts contribute 57.94% of all occurrences.

**Interpretation:** A relatively small concept set drives much of recorded synthetic condition activity.

**Limitation:** Recorded occurrence is not prevalence, incidence, severity, outcome, quality, or causation.

### Finding 11 — Monthly series remain volatile despite the larger dataset

**Observation:** Coefficients of variation are 2.12 for monthly encounters, 2.12 for claims, and 2.38 for transaction amount. Encounter volume peaks in April 2021; transaction amount peaks in May 2026.

**Interpretation:** Three-month rolling averages improve readability, but the long synthetic history still contains large changes and sparse early periods.

**Limitation:** These patterns are generator histories, not real growth, seasonality, demand shocks, or operational performance.

### Finding 12 — Procedure activity and cost fields show the strongest measured associations

**Observation:** At encounter grain, procedure count versus encounter total claim cost has Spearman 0.635; procedure base cost versus encounter total claim cost has Spearman 0.831. Duration versus claim cost is more modest at 0.333. Total claim cost and payer coverage show Pearson 0.941 but Spearman 0.616.

**Interpretation:** Encounters with greater procedure activity generally rank higher on synthetic claim cost, while the Pearson/Spearman gap indicates skew and influential high values. The strong cost associations likely reflect shared source-generation mechanics as well as activity intensity.

**Limitation:** Association is not causation. These coefficients do not show that procedures cause cost, that coverage causes claims, or that any activity is clinically appropriate.

## Known Data-Quality Finding

The 547 non-sentinel claim-transaction date-order warnings remain **To Be Validated**. Python EDA does not correct, remove, or silently reclassify them. The known Synthea sentinel timestamp behavior remains separately preserved.

## What Python Added Beyond SQL

- Robust percentiles, IQRs, skewness, and outlier counts at several grains.
- Concentration curves and top-percentile contribution measures.
- Full-population Pearson/Spearman comparisons with explicit grain controls.
- Monthly volatility and three-month rolling views.
- Reusable plotting and profiling modules plus an executable presentation notebook.
- Explicit outlier retention and investigation categories rather than deletion.

## Current Limitations

- The population is synthetic and is not representative of a real hospital.
- No staffing, capacity, budget, operating expense, contract, adjudication, cash, outcome, or technology-operations data is present.
- Descriptive provider, organization, and payer master attributes remain limited.
- Financial measures from different grains retain different semantics and must not be equated.
- No clinical, quality, causal, profitability, or performance conclusion is supported.

## Recommendation

The Python EDA foundation is ready for technical review. Power BI work should begin only after the notebook, findings, and reusable module interfaces are accepted.
