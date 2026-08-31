# Hospital360 Power BI Validation Plan

## Objective

Prove that the manually built Power BI model reproduces the validated PostgreSQL Analytics V1 baseline, preserves native fact grains, and applies filters without multiplication. Validation uses the 5,000-patient synthetic Synthea portfolio; it does not validate a real hospital or clinical system.

## Preconditions

- Import only the twelve approved `analytics` tables.
- Apply the documented date key-0 semantic-model exception; do not change PostgreSQL.
- Create exactly the relationships in `relationship_design.md`.
- Create measures from `core_measures.dax` without changing definitions.
- Clear all report filters and slicers before baseline reconciliation.
- Record the refresh timestamp and the latest database milestone/commit used for comparison.

## 1. Fact Row Reconciliation

Create temporary validation cards or a matrix using the core count measures.

| Measure | Expected Power BI result | Difference required |
|---|---:|---:|
| Total Encounters | 253,563 | 0 |
| Total Claims | 435,751 | 0 |
| Total Claim Transactions | 3,966,064 | 0 |
| Total Condition Occurrences | 159,348 | 0 |
| Total Procedures | 696,202 | 0 |

Also confirm `[Total Patients] = 5,000` with all filters cleared.

Failure action: stop page construction, confirm table refresh and filters, then check relationships. Do not compensate with `DISTINCT`, bidirectional filters, or altered measures.

## 2. Financial Reconciliation

Each total must be tested from its native fact without adding or joining financial measures from another fact.

| Measure | Expected Power BI result | Difference required |
|---|---:|---:|
| Encounter Base Cost | 28,981,362.04 | 0.00 |
| Encounter Claim Cost | 731,937,228.14 | 0.00 |
| Encounter Payer Coverage | 526,304,744.54 | 0.00 |
| Transaction Amount | 837,678,683.76 | 0.00 |
| Transaction Payments | 697,790,613.67 | 0.00 |
| Transaction Transfers | 279,776,140.18 | 0.00 |
| Procedure Base Cost | 716,784,016.74 | 0.00 |

Additional semantic checks:

- `[Claim Amount]` must equal `[Transaction Amount]` in total because it is an explicit transaction-derived alias.
- `[Payment Ratio]` must equal Transaction Payments ÷ Transaction Amount using unrounded values.
- `[Payer Coverage Ratio]` must use only the two encounter-grain measures.
- Never define or validate a total made by adding encounter, transaction, and procedure financial fields.

## 3. Relationship Integrity

In Model view verify:

- 39 relationships total: 27 active, 12 inactive.
- Every relationship is dimension `1` to fact `*`.
- Every cross-filter direction is Single.
- No fact-to-fact relationship exists.
- No relationship uses `encounter_id`, `claim_id`, `transaction_id`, or fact identity keys.
- Only the documented default date/provider/payer roles are active.

Take a model-view screenshot only after these tests pass. Do not fabricate or pre-create a screenshot.

## 4. Filter Propagation Tests

Perform each test with before/after values recorded:

1. Select one `dim_patient[gender]`: encounter, claim, transaction, condition, and procedure counts should filter through their patient relationships.
2. Select one encounter start year: encounter measures should change; transaction measures change only through their own active from-date relationship for the same selected calendar dates, not through encounters.
3. Select one payer: claim measures use primary payer; transaction measures use parent claim-primary payer; encounter measures use encounter payer. Values may differ because the roles are source-specific.
4. Select one provider: each fact uses its documented active provider role. Supervising/referring roles must not activate silently.
5. Select one condition: condition fact measures change; unrelated encounter/claim/transaction facts must not be filtered through a fact path.
6. Select one procedure: procedure measures change; unrelated facts remain governed by shared dimension filters only.

Failure indicators: unrelated facts disappear, totals increase after filtering, or a selection propagates from one fact to another. Correct the relationship—not the measure total.

## 5. Amount-Multiplication Tests

For each dimension below, place its member on matrix rows and `[Transaction Amount]` in values. The matrix grand total must remain 837,678,683.76 with filters cleared:

- Payer
- Provider
- Organization
- Patient
- Transaction from month

Repeat native-grain regrouping tests:

- Encounter Claim Cost by encounter class totals 731,937,228.14.
- Procedure Base Cost by procedure concept totals 716,784,016.74.
- Total Claims by primary payer totals 435,751.
- Total Encounters by provider and organization each total 253,563.

Required multiplication differences: **0.00** for amounts and **0** for counts.

## 6. Unknown-Member Validation

Validate that Unknown remains visible and does not drop fact rows:

- Claim primary payer Unknown: 35,972 claims, approximately 8.26%.
- Transaction claim-primary payer Unknown: 171,235 transaction rows, approximately 4.32%.
- Unknown transaction payer amount: 47,175,305.28, approximately 5.63% of Transaction Amount.
- Key-0 non-date dimension members display as `__UNKNOWN__`/Unknown rather than an empty category.
- Date key `0`, excluded from the marked semantic date table, appears through Power BI's blank/Unknown date relationship member and is monitored through the sentinel flag.

Expected Unknown usage is not a relationship failure. A failed test is row loss, an unexplained new Unknown population, or replacement of Unknown with a fabricated member.

## 7. Date and Time-Intelligence Validation

- Confirm `dim_date` is marked using `full_date` after filtering date key 0 in the imported query.
- Confirm `month_name` sorts by `month_number`.
- Confirm `year_month` sorts by `year_month_sort` and displays chronologically.
- Confirm active roles: encounter start, claim service, transaction from, condition start, procedure start.
- Test Encounters MTD/YTD and Transaction Amount MTD/YTD for a fully populated month/year.
- Verify prior-month and prior-year measures return blank when no comparable period exists rather than infinity or fabricated zero.
- Compare one stop-date measure against the corresponding active start-date measure and confirm its `USERELATIONSHIP` role is correctly labeled.
- Confirm sentinel stop timestamps never appear as genuine January 1970 activity.

## 8. Data-Quality Validation

- `[Sentinel To-Date Transactions]` must equal 317,271.
- `[Sentinel To-Date %]` must use Total Claim Transactions as denominator.
- The 547 non-sentinel date-order warnings remain **To Be Validated**. They are not exposed as a fact column in Analytics V1, so show the validated number as a documented static limitation—not a fabricated DAX result.
- Do not classify the sentinel population as a transformation error.
- Do not correct, swap, delete, or hide warning rows in Power Query.

## 9. Visual and Drill-Through Validation

For every page:

1. Compare each card with the same measure in a simple validation matrix.
2. Confirm visual totals equal measure totals under identical filters.
3. Use **Show as a table** to verify chart categories sum to the displayed total.
4. Drill through from at least three different source categories and confirm the detail page retains intended filters.
5. Clear filters and confirm the baseline returns exactly.
6. Confirm tooltips show full values and grain labels.
7. Confirm edit-interaction settings prevent a fact visual from misleadingly filtering another fact visual.

## 10. Acceptance Record

Record the following after manual validation:

| Gate | Required result | Actual | Status |
|---|---|---|---|
| Fact counts | All five differences 0 |  |  |
| Financial totals | All seven differences 0.00 |  |  |
| Patient count | 5,000 |  |  |
| Relationships | 39 total; 27 active; 12 inactive |  |  |
| Fact-to-fact relationships | 0 |  |  |
| Bidirectional relationships | 0 |  |  |
| Amount multiplication | 0 |  |  |
| Unknown behavior | Preserved and explained |  |  |
| Sentinel transactions | 317,271 |  |  |
| Non-sentinel warnings | 547, To Be Validated |  |  |
| Date sorting/time intelligence | Passed |  |  |
| Drill-through/visual totals | Passed |  |  |

Power BI is ready for screenshots and portfolio presentation only after every gate is recorded as Passed.
