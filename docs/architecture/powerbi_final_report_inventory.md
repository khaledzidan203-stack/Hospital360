# Hospital360 Power BI Final Report Inventory

## Milestone Status

The Hospital360 Power BI report is a validated nine-page analytical portfolio built from synthetic Synthea healthcare data. Power BI uses the curated `analytics` schema through the validated semantic model. The report is not based on real hospital or patient data.

## Navigation Standard

The Home page provides eight active page-navigation tiles. Every analytical page includes a top-left Home button using Page navigation to return to Home. Power BI Desktop navigation uses Ctrl + Click; published or reading mode uses a single click.

## Page Architecture

### 1. Home

- **Purpose:** Report index and entry point for all eight analytical pages.
- **Slicers:** None.
- **KPI measures:** None.
- **Major visuals:** Eight navigation tiles and concise report context.
- **Navigation:** Each tile opens its named analytical page.
- **Limitations:** Navigation and orientation only; no analytical conclusions are presented.

### 2. Executive Overview

- **Purpose:** Executive summary of activity, claim-related financial measures, concentration, and payer data quality.
- **Slicers:** Date, Payer, Provider, Organization.
- **KPI measures:** Total Patients, Total Encounters, Total Claims, Transaction Amount, Encounter Claim Cost, Encounter Payer Coverage, Top Payer Share, Top Provider Share, Top Organization Share, Unknown Payer %.
- **Major visuals:** Monthly Encounter Trend and Monthly Transaction Amount Trend.
- **Navigation:** Home button returns to Home.
- **Limitations:** Financial values describe claim and transaction activity, not hospital profitability or a profit-and-loss statement.

### 3. Patient & Encounter Activity

- **Purpose:** Patient volume, encounter utilization, concentration, and recent encounter movement.
- **Slicers:** Date, Encounter Class, Provider, Organization, Payer.
- **KPI measures:** Total Patients, Total Encounters, Encounters per Patient, Claims per Encounter, Procedures per Encounter, Encounters YTD, Encounters Previous Month, Encounters MoM Change %, Top Provider Share, Top Organization Share.
- **Major visuals:** Monthly Encounter Trend, Encounters by Class, Top Providers by Encounters, Top Organizations by Encounters.
- **Navigation:** Home button returns to Home.
- **Limitations:** Encounter duration analysis is deferred because no validated duration measure is available.

### 4. Claims & Financial Activity

- **Purpose:** Claim and transaction activity across validated financial grains.
- **Slicers:** Date, Payer, Provider, Organization.
- **KPI measures:** Total Claims, Total Claim Transactions, Claims per Encounter, Encounter Base Cost, Encounter Claim Cost, Encounter Payer Coverage, Transaction Amount, Transaction Payments, Transaction Transfers, Payment Ratio, Payer Coverage Ratio, Procedure Base Cost, Unknown Transaction Payer %.
- **Major visuals:** Monthly Transaction Amount, Monthly Payments, Payments vs Transfers, Transaction Amount by Payer.
- **Navigation:** Home button returns to Home.
- **Limitations:** Measures from encounter, claim-transaction, and procedure grains are displayed separately and must not be summed as though they share one financial meaning.

### 5. Payer Analysis

- **Purpose:** Payer concentration, coverage, transaction activity, and Unknown-member exposure.
- **Slicers:** Date, Payer, Provider, Organization.
- **KPI measures:** Total Claims, Transaction Amount, Encounter Payer Coverage, Top Payer Share, Unknown Payer %, Unknown Transaction Payer %.
- **Major visuals:** Claims by Payer, Transaction Amount by Payer, Payer Coverage Comparison, Payer Claim Activity Trend, Payer Transaction Trend.
- **Navigation:** Home button returns to Home.
- **Limitations:** Payer activity does not establish reimbursement adequacy, margin, or profitability.

### 6. Provider & Organization Activity

- **Purpose:** Provider and organization activity volume, concentration, and trends.
- **Slicers:** Date, Provider, Organization, Encounter Class, Payer.
- **KPI measures:** Total Encounters, Total Claims, Total Procedures, Transaction Amount, Top Provider Share, Top Organization Share.
- **Major visuals:** Top Providers by Encounters, Top Organizations by Encounters, Provider Encounter Trend, Organization Encounter Trend, Transaction Amount by Organization, Procedures by Provider.
- **Navigation:** Home button returns to Home.
- **Limitations:** Activity concentration is not a measure of provider quality, productivity, or operational efficiency.

### 7. Clinical Utilization

- **Purpose:** Descriptive condition and procedure utilization within the synthetic population.
- **Slicers:** Date, Condition, Procedure, Provider, Organization.
- **KPI measures:** Total Patients, Total Encounters, Total Procedures, Total Condition Occurrences, Procedures per Encounter, Procedure Base Cost.
- **Major visuals:** Top Conditions, Top Procedures, Monthly Procedure Activity, Monthly Condition Activity, Procedure Base Cost by Procedure.
- **Navigation:** Home button returns to Home.
- **Limitations:** Clinical occurrences do not establish prevalence, care quality, outcomes, or causation.

### 8. Time Trends

- **Purpose:** Monthly activity trends and validated period-comparison measures.
- **Slicers:** Date, Payer, Provider, Organization.
- **KPI measures:** Total Encounters, Transaction Amount, Claim Amount, Encounters MTD, Encounters YTD, Encounters Previous Month, Encounters MoM Change %, Encounters YoY Change %, Transaction Amount MTD, Transaction Amount YTD, Transaction Amount Previous Month, Transaction Amount MoM Change %, Transaction Amount YoY Change %.
- **Major visuals:** Monthly Encounter Trend, Monthly Transaction Amount Trend, Monthly Claim Amount Trend.
- **Navigation:** Home button returns to Home.
- **Limitations:** Sparse or non-comparable periods can make MoM and YoY percentages volatile; an optional annual view is deferred.

### 9. Data Quality & Analytical Limitations

- **Purpose:** Make key data-quality signals and interpretation boundaries visible to report consumers.
- **Slicers:** Date, Payer.
- **KPI measures:** Total Claim Transactions, Total Claims, Sentinel To-Date Transactions, Sentinel To-Date %, Unknown Payer %, Unknown Transaction Payer %.
- **Major visuals:** Unknown Payer Exposure and explanatory limitation panels.
- **Navigation:** Home button returns to Home.
- **Limitations:** Sentinel timestamps represent documented source behavior. The 547 non-sentinel date-order warnings remain **To Be Validated** and are not silently reclassified.

## Portfolio Interpretation Note

Hospital360 demonstrates analytical engineering and reporting methodology using a 5,000-patient synthetic development dataset. It must not be interpreted as real hospital performance, patient behavior, clinical evidence, or audited financial reporting.
