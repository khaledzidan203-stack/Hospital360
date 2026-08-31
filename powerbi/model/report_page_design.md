# Hospital360 Power BI V1 Report Page Design

## Report-Wide Principles

- Dataset: 5,000 synthetic Synthea patients; never present it as a real hospital population.
- Structure every page as **What happened? → Why/where is it concentrated?**
- Use measures from `core_measures.dax`; disable implicit sums in visuals.
- Keep encounter, claim-transaction, and procedure financial grains visually separate.
- Synchronize only slicers whose dimensions validly filter the facts used on each page.
- Use consistent colors: activity, financial activity, Unknown/DQ, and comparison series.
- Keep descriptions concise and place limitations in an always-visible information panel or tooltip.
- Avoid decorative visuals, excessive gauges, 3D charts, and unsupported red/green performance judgments.

## Page 1 — Executive Overview

**Business question:** What is the scale, mix, and financial activity of the validated synthetic portfolio, and where should the viewer investigate next?

### What

- KPI cards: Total Patients, Total Encounters, Total Claims, Total Claim Transactions, Total Procedures, Total Condition Occurrences.
- Separate financial cards: Encounter Claim Cost, Encounter Payer Coverage, Transaction Amount, Transaction Payments, Procedure Base Cost.
- Monthly combo chart: Total Encounters and Transaction Amount by `year_month`, using separate axes and explicit grain labels.
- Encounter-class share: sorted horizontal bar chart.

### Why / where

- Top payer transaction-amount share card.
- Top provider and top organization share cards.
- Unknown primary payer and sentinel date cards.
- Navigation buttons to payer, provider/organization, clinical, time, and DQ pages.

**Slicers:** Date range, encounter class, patient gender, patient state. Keep payer/provider slicers off this overview unless all affected visuals are clearly scoped.

**Drill-through:** Patient & Encounter Activity; Claims & Financial Activity; Payer Analysis.

**Tooltips:** Full unrounded value, native fact grain, current filter context, synthetic-data statement.

**Interaction behavior:** Date and demographic slicers cross-filter all compatible visuals. Selecting encounter class must not filter transaction-only visuals through a fact-to-fact path; use edit interactions to prevent misleading cross-highlighting.

**Do not show:** A single “total financial value” combining facts, profit/margin cards, gauges against invented targets, clinical outcomes, or real-hospital branding.

## Page 2 — Patient & Encounter Activity

**Business question:** How is encounter activity distributed across synthetic patients, classes, dates, providers, and organizations?

### What

- KPI cards: Total Patients, Total Encounters, Encounters per Patient.
- Encounter class and encounter description bars.
- Monthly encounter trend with Encounters Previous Month and Encounters YoY Change % in tooltips.
- Patient demographic distributions using `dim_patient` gender, race, ethnicity, and state where useful.

### Why / where

- Provider and organization encounter rankings.
- Encounter reason or description drill-down.
- Optional binned distribution of encounters per patient only if created from a governed aggregation; otherwise link to Python EDA for full distribution analysis.

**Slicers:** Start-date range, encounter class, gender, race/ethnicity, state, provider identifier, organization identifier.

**Drill-through:** Technical patient detail using synthetic patient identifier, and provider/organization page. Keep detail technical and synthetic.

**Tooltips:** Encounter count, patient count, encounters per patient, share of selected encounters.

**Interaction behavior:** Dimension slicers filter encounter visuals. Provider selection may cross-highlight organization volume but must not imply provider performance.

**Do not show:** Productivity, wait-time, quality, capacity, or length-of-stay conclusions from elapsed timestamps alone.

## Page 3 — Claims & Financial Activity

**Business question:** What are the separate encounter- and transaction-grain financial activity patterns, and where is value concentrated?

### What

- Claim activity cards: Total Claims, Claims per Encounter, Total Claim Transactions.
- Encounter-grain cards grouped together: Encounter Base Cost, Encounter Claim Cost, Encounter Payer Coverage, Payer Coverage Ratio.
- Transaction-grain cards grouped separately: Transaction Amount, Transaction Payments, Transaction Transfers, Payment Ratio.
- Monthly transaction amount/payment/transfer lines using transaction from-date.
- Transaction type and method bars.

### Why / where

- Transaction-derived claim value ranking by `fact_claim_transaction[claim_id]` on a controlled drill-through visual.
- Claim status distribution from `fact_claim` without adding transaction amounts to claim rows.
- Payer and organization contribution bars using transaction measures only.

**Slicers:** Transaction from-date, transaction type, method, primary payer, organization. Use a separate claim-service-date slicer only on claim-header visuals and label it clearly.

**Drill-through:** Claim lineage page with transaction rows; payer page.

**Tooltips:** Measure grain, full value, ratio numerator and denominator, Unknown payer flag.

**Interaction behavior:** Prevent claim-header visuals from cross-filtering transaction values through lineage identifiers. Shared dimensions may filter both facts independently.

**Do not show:** Sum of encounter claim cost plus transaction amount, profitability, collections, revenue, denials, reimbursement performance, or a fact-to-fact relationship.

## Page 4 — Payer Analysis

**Business question:** How are synthetic claim and transaction activities distributed across payer identifiers, including Unknown?

### What

- Cards: Total Claims, Transaction Amount, Transaction Payments, Top Payer Share, Unknown Payer %, Unknown Transaction Payer %.
- Claims by primary payer bar chart.
- Transaction amount and payments by claim-primary payer clustered bars.
- Payer share of selected transaction amount as a 100% stacked bar or sorted share bar.

### Why / where

- Payment Ratio by payer with transaction amount as tooltip context.
- Primary versus secondary payer claim counts shown in separate visuals; use explicit inactive-role measures if secondary-payer reporting is implemented.
- Unknown contribution panel explaining missing source payer context.

**Slicers:** Transaction from-date, primary payer, transaction type, organization.

**Drill-through:** Payer detail with claim counts, transaction measures, monthly trend, and Unknown explanation.

**Tooltips:** Claim share, value share, payment ratio, full transaction amount, inferred-reference limitation.

**Interaction behavior:** A payer selection filters claim-primary and transaction-primary roles only by default. It must not silently activate secondary payer relationships.

**Do not show:** Payer names not present in the dimension, contract rates, denial rates, reimbursement quality, or payer profitability.

## Page 5 — Provider & Organization Activity

**Business question:** Where is synthetic activity concentrated across inferred provider and organization identifiers?

### What

- Cards: Total Encounters, Encounter Claim Cost, Top Provider Share, Top Organization Share.
- Provider encounter-volume ranking.
- Organization encounter-volume ranking.
- Encounter claim cost by provider and by organization in separate visuals.

### Why / where

- Scatterplot: encounter volume versus encounter claim cost by provider, with organization or encounter-class tooltips where valid.
- Monthly encounter trend for selected provider/organization.
- Source-role flags to distinguish inferred provider usage when technically helpful.

**Slicers:** Start-date, provider ID, organization ID, encounter class.

**Drill-through:** Provider detail and organization detail pages or bookmarks.

**Tooltips:** Encounter volume, patient count, encounter claim cost, share of selected total, inferred-reference notice.

**Interaction behavior:** Provider and organization selections filter compatible fact measures through active relationships. Do not use bidirectional filters to infer membership between providers and organizations.

**Do not show:** Performance league tables, productivity ratings, quality rankings, capacity utilization, staffing conclusions, or fabricated names/specialties.

## Page 6 — Clinical Utilization

**Business question:** Which synthetic procedure and condition concepts account for the most recorded activity and source base cost?

### What

- Cards: Total Procedures, Total Condition Occurrences, Procedure Base Cost, Procedures per Encounter.
- Top procedures by occurrence count.
- Top procedures by Procedure Base Cost.
- Top conditions by occurrence count.
- Procedure and condition long-tail share using Top N parameter or cumulative share where practical.

### Why / where

- Procedure frequency versus base cost scatterplot.
- Monthly procedure and condition trends on their active start-date roles.
- Patient demographic breakdown only as descriptive synthetic segmentation.

**Slicers:** Start-date, procedure description, condition description, patient demographics, encounter-context payer/provider/organization.

**Drill-through:** Procedure concept detail and condition concept detail with trend and encounter-context distributions.

**Tooltips:** Concept code/system, occurrence count, patient count where separately defined, source base cost, synthetic/clinical limitation.

**Interaction behavior:** Procedure selection affects procedure visuals; condition selection affects condition visuals. Avoid pretending one clinical fact filters the other.

**Do not show:** Prevalence, incidence, efficacy, outcomes, clinical quality, appropriateness, or causal claims.

## Page 7 — Time Trends

**Business question:** How do synthetic activity and financial measures change over comparable calendar periods?

### What

- Cards: Encounters MTD/YTD, Transaction Amount MTD/YTD.
- Monthly encounter trend with prior month and prior year comparison.
- Monthly transaction amount trend with previous month/year.
- Claim Amount trend labeled **transaction-derived / transaction from-date**.
- Optional 3-month moving average measure added only if governed and documented.

### Why / where

- MoM and YoY change bars with blanks retained where comparison periods do not exist.
- Small multiples by encounter class or payer for sufficiently populated periods.
- Annotation of partial first/last years.

**Slicers:** Full-date range, year, quarter, encounter class, payer. Use one date role per visual and label alternate roles.

**Drill-through:** Month detail to encounter, transaction, payer, or organization page through conformed dimensions.

**Tooltips:** Current, prior period, absolute difference, percentage difference, role-playing date name.

**Interaction behavior:** Selecting a month filters active date roles across facts. Disable interaction where a visual intentionally uses an inactive stop-date measure to avoid role confusion.

**Do not show:** Synthetic peaks as seasonality, growth, shocks, forecasts, or real operational trends. Do not show YoY where periods are not comparable.

## Page 8 — Data Quality / Analytical Limitations

**Business question:** What must a reviewer understand before interpreting this model or trusting a report total?

### What

- Validation cards for five fact counts and seven financial totals.
- Unknown primary payer and Unknown transaction payer measures.
- Sentinel To-Date Transactions and Sentinel To-Date %.
- Static note: 547 non-sentinel date-order warnings remain **To Be Validated**.
- Relationship summary: 39 dimension-to-fact relationships, zero fact-to-fact, Single direction.

### Why / where

- Reconciliation matrix comparing expected and Power BI totals with difference.
- Unknown-member usage by role where measures are approved.
- Limitations panel: synthetic data, inferred masters, no P&L, no clinical conclusions, incompatible financial grains.

**Slicers:** Minimal. A date or payer slicer may be provided only to demonstrate filter behavior; validation baseline cards should include a clear “Clear filters” button.

**Drill-through:** Technical lineage page for controlled validation; no raw/staging connection.

**Tooltips:** Expected baseline, observed measure, difference, validation status, source fact grain.

**Interaction behavior:** Validation cards must be checked with all filters cleared. Filtered validation views must be explicitly labeled as filtered, not failed.

**Do not show:** Raw/staging data, credentials, real patient implications, fabricated errors, or corrected/reclassified date warnings.

## Accessibility and Presentation Checks

- Use a color-blind-safe palette and never rely on color alone for status.
- Provide descriptive visual titles and alt text.
- Keep font sizes readable at 16:9 presentation resolution.
- Limit each page to the visuals needed to answer its stated question.
- Put native grain in financial visual subtitles.
- Use a persistent footer: `Synthetic Synthea portfolio — analytical demonstration, not real hospital data`.

Report pages designed: **8**.
