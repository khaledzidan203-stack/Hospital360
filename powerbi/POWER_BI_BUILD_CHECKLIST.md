# Hospital360 Power BI Build Checklist

Execute in this exact order. Dataset scope: 5,000 synthetic Synthea patients. Do not connect to RAW/STAGING, modify PostgreSQL, fabricate a PBIX, or create screenshots before the relevant build exists.

## 1. Connect

- [ ] Open Power BI Desktop.
- [ ] Choose PostgreSQL connector.
- [ ] Enter server `localhost` and database `hospital360`.
- [ ] Select Import mode.
- [ ] Authenticate locally without recording credentials in project files or screenshots.
- [ ] Confirm connection targets schema `analytics` only.

## 2. Load

- [ ] Select the seven approved dimensions.
- [ ] Select the five approved facts.
- [ ] Confirm RAW and STAGING objects are not selected.
- [ ] Verify data types in Power Query.
- [ ] Apply only the approved `dim_date[date_key] <> 0` semantic filter.
- [ ] Confirm no cleaning, deduplication, replacement, or business transformation exists.
- [ ] Close & Apply and record refresh duration.

## 3. Model

- [ ] Disable automatic relationship discovery.
- [ ] Remove any undocumented auto-created relationship.
- [ ] Create the 39 documented relationships.
- [ ] Confirm 27 active and 12 inactive relationships.
- [ ] Confirm every relationship is dimension `1` to fact `*`, Single direction.
- [ ] Confirm zero fact-to-fact and zero bidirectional relationships.
- [ ] Mark `dim_date` as the date table using `full_date`.
- [ ] Create and apply `year_month_sort`.
- [ ] Sort month name by month number.

## 4. Format

- [ ] Create `_Measures` table and display folders.
- [ ] Hide surrogate keys, fact identity keys, foreign keys, hashes, and technical lineage fields from normal Report view.
- [ ] Set identifiers and codes to Do not summarize.
- [ ] Format counts as whole numbers.
- [ ] Format ratios/shares as percentages with two decimals.
- [ ] Format per-unit ratios with two decimals.
- [ ] Format financial activity with two decimals and no unapproved currency symbol.
- [ ] Configure chart display units while retaining full values in tooltips.
- [ ] Add persistent synthetic-data disclosure/footer.

## 5. DAX

- [ ] Add all 46 measures from `core_measures.dax` without changing logic.
- [ ] Assign Activity measures to their folder.
- [ ] Assign Financial measures to their folder.
- [ ] Assign Encounter, Claim, and Transaction time measures to separate folders.
- [ ] Assign Concentration and Data Quality measures to their folders.
- [ ] Confirm Claim Amount is documented as a transaction-derived alias.
- [ ] Confirm no profit, margin, EBITDA, ROI, budget, or operating-expense measure exists.

## 6. Validate

- [ ] Reconcile all five fact counts.
- [ ] Reconcile all seven financial totals.
- [ ] Confirm Total Patients equals 5,000.
- [ ] Confirm each difference is exactly zero/0.00.
- [ ] Validate Unknown payer and date behavior.
- [ ] Confirm sentinel count is 317,271.
- [ ] Retain 547 non-sentinel warnings as To Be Validated.
- [ ] Test dimension filter propagation.
- [ ] Test inactive role-playing relationships.
- [ ] Complete amount-multiplication regrouping checks.
- [ ] Record results in the validation acceptance table.

## 7. Build Pages

- [ ] Executive Overview.
- [ ] Patient & Encounter Activity.
- [ ] Claims & Financial Activity.
- [ ] Payer Analysis.
- [ ] Provider & Organization Activity.
- [ ] Clinical Utilization.
- [ ] Time Trends.
- [ ] Data Quality / Analytical Limitations.
- [ ] Apply What → Why structure and page-specific limitations.
- [ ] Add navigation and consistent page titles.

## 8. Test Interactions

- [ ] Test each slicer against every visual on its page.
- [ ] Disable misleading cross-fact visual interactions.
- [ ] Test drill-through entry, retained filters, and back navigation.
- [ ] Test custom tooltips and full-value display.
- [ ] Test Clear filters/reset bookmarks.
- [ ] Validate MTD/YTD and comparable MoM/YoY periods.
- [ ] Verify accessibility, alt text, keyboard order, and color contrast.
- [ ] Reconfirm page totals after interaction testing.

## 9. Capture Screenshots

- [ ] Capture screenshots only from the completed, validated Power BI Desktop report.
- [ ] Include model view showing relationship direction/cardinality.
- [ ] Capture each report page at consistent 16:9 size.
- [ ] Clear accidental selections and sensitive local UI before capture.
- [ ] Ensure screenshots contain synthetic-data disclosure.
- [ ] Save approved images under `powerbi/screenshots/` with descriptive names.
- [ ] Do not fabricate, mock, or pre-populate screenshots.

## 10. Document Final Model

- [ ] Record Power BI Desktop version and PostgreSQL refresh date.
- [ ] Record Import mode and the twelve source tables.
- [ ] Record relationship counts and any reviewed exceptions.
- [ ] Record measure count and KPI dictionary version.
- [ ] Complete the validation acceptance table.
- [ ] Document any visual or DAX deviation with rationale and reviewer approval.
- [ ] Record remaining limitations and the 547 To-Be-Validated warnings.
- [ ] Save the final PBIX locally using the approved filename.
- [ ] Review PBIX and screenshot source-control policy before committing binary artifacts.
