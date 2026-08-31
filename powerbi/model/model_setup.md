# Hospital360 Power BI Model Setup

## Scope

Build the Power BI model manually from PostgreSQL schema `analytics` using the validated 5,000-patient synthetic portfolio dataset. Do not select `raw`, `staging`, PostgreSQL catalog objects, or Synthea CSV files.

## 1. Connect

1. Open Power BI Desktop.
2. Select **Home → Get data → More → Database → PostgreSQL database**.
3. Enter:
   - Server: `localhost`
   - Database: `hospital360`
4. Select **Import** mode.
5. Use the PostgreSQL credentials supplied locally by the project owner. Do not embed credentials in PBIX parameters, documentation, screenshots, or source control.
6. If prompted about encryption for this local development server, follow the local PostgreSQL configuration; do not weaken a production connection based on this development setup.

### Why Import mode

Import mode is appropriate for this fixed local analytical snapshot: it provides responsive cross-filtering and DAX time intelligence, while the largest fact contains about 3.97 million rows. DirectQuery adds latency and source-load complexity without a current freshness requirement. Reassess incremental refresh or DirectQuery only when data volume, refresh frequency, or deployment architecture changes.

## 2. Select and Load Tables

In Navigator, select exactly these `analytics` tables:

- `dim_date`
- `dim_patient`
- `dim_provider`
- `dim_organization`
- `dim_payer`
- `dim_condition`
- `dim_procedure`
- `fact_encounter`
- `fact_claim`
- `fact_claim_transaction`
- `fact_condition_occurrence`
- `fact_procedure`

Choose **Transform Data** before loading and verify:

- Key columns are Whole Number; bigint fact keys may appear as 64-bit Whole Number.
- `full_date`, `birth_date`, `death_date`, condition dates are Date.
- Timestamp fields are Date/Time/Timezone as supported; reporting should use date keys.
- Numeric amounts are Fixed Decimal Number where feasible, not text.
- Boolean source-role and sentinel fields are True/False.
- No deduplication, value replacement, or business transformation is added in Power Query. The sole approved row filter is the date-table key-0 handling described below.

Then select **Close & Apply**.

## 3. Keep Source Names Stable

Keep the twelve source table names unchanged in V1 so the supplied DAX can be pasted directly. Friendly display folders and measure names provide business usability without disconnecting documentation from PostgreSQL lineage.

## 4. Configure Relationships

1. Disable **Autodetect new relationships after data is loaded** for this model.
2. Remove any automatically created relationship that is not in `relationship_design.md`.
3. Create all 39 documented relationships.
4. Confirm all are `1:*`, dimension-to-fact, Single direction.
5. Keep 27 default roles active and 12 role-playing relationships inactive.
6. Confirm there are no relationships on `encounter_id`, `claim_id`, `transaction_id`, or fact identity keys.

## 5. Configure the Date Dimension

1. In Power Query, filter the imported `dim_date` query to `date_key <> 0`. This is the only approved row filter: Power BI requires the marked date column to contain unique, nonblank dates. It does not modify PostgreSQL. Facts with date key `0` resolve to Power BI's blank/Unknown relationship member; monitor the transaction sentinel with the supplied DQ measures rather than presenting it as a real date.
2. Select `dim_date` and choose **Table tools → Mark as date table**.
3. Select `full_date` as the date column.
4. Select `month_name` and set **Sort by column → month_number**.
5. Create this calculated column for numeric year-month sorting:

```DAX
year_month_sort = 'dim_date'[year] * 100 + 'dim_date'[month_number]
```

6. Select `year_month` and set **Sort by column → year_month_sort**.
7. Hide `year_month_sort` after configuring the sort.
8. Use `full_date` from the marked date table for all standard time-intelligence measures.

## 6. Hide Technical Columns

Hide from Report view, but do not delete:

- All dimension surrogate keys and fact foreign keys.
- Fact identity keys.
- Source-system, source-table, and source-row-hash columns.
- Raw synthetic UUID identifiers unless a technical drill-through page explicitly requires them.
- Date integer keys.
- Lineage identifiers such as `claim_id` and `encounter_id` from normal report pages; keep them available only for controlled drill-through or validation.
- Low-level diagnosis reference numbers and other implementation attributes not used in V1 visuals.

Keep business descriptors visible: demographics, encounter class/description, transaction type/method, procedure and condition descriptions, calendar fields, and governed Unknown labels.

## 7. Measures and Display Folders

Create a dedicated empty measures table named `_Measures` using **Enter data** with one placeholder column, then hide the placeholder. Assign every measure in `core_measures.dax` to `_Measures` and organize display folders:

- `Activity`
- `Financial`
- `Time Intelligence\Encounters`
- `Time Intelligence\Claims`
- `Time Intelligence\Transactions`
- `Concentration`
- `Data Quality`

## 8. Formatting

- Counts: whole number with thousands separator; display units `None` for validation cards and `Auto` for overview visuals.
- Per-encounter/patient ratios: decimal with two places.
- Currency/activity amounts: fixed decimal/currency with two places; display units `Millions` on executive charts and full units in tooltips and validation pages.
- Ratios and shares: percentage with two decimal places.
- Dates: locale-appropriate date; `year_month` displayed as `YYYY-MM`.
- Avoid currency symbols unless a confirmed reporting currency is approved. The source provides amounts but no governed currency context.

## 9. Model Quality Checks

- Mark technical keys as **Do not summarize**.
- Disable default summarization for identifiers and codes.
- Ensure measures, not implicit column sums, drive report visuals.
- Confirm the Unknown member is visible as `__UNKNOWN__`/Unknown rather than blank where available.
- Validate every baseline in `powerbi_validation_plan.md` before building pages.
- Save the PBIX locally only after validation; do not fabricate a PBIX or commit one until the manual build is complete and reviewed.
