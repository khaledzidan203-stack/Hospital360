-- Hospital360 V1: Claims and financial activity.
-- Read-only. Encounter, claim-header, and transaction measures are never mixed by direct fact joins.
\set ON_ERROR_STOP on
\pset pager off
BEGIN TRANSACTION READ ONLY;

-- Analysis CF01: claim-header baseline.
SELECT count(*) AS total_claims, count(DISTINCT claim_id) AS distinct_claim_ids
FROM analytics.fact_claim;

-- Analysis CF02: claims by service month. Date role: Fact_Claim.service_date_key.
SELECT
    date_trunc('month', d.full_date)::date AS service_month,
    count(*) AS claim_count,
    count(DISTINCT c.patient_key) AS patient_count
FROM analytics.fact_claim c
JOIN analytics.dim_date d ON d.date_key = c.service_date_key
WHERE d.date_key <> 0
GROUP BY date_trunc('month', d.full_date)
ORDER BY service_month;

-- Analysis CF03: claim headers per encounter lineage ID.
-- This counts claim headers only and does not join encounter measures.
SELECT
    coalesce(encounter_id, '__UNKNOWN__') AS encounter_id,
    count(*) AS claim_count,
    dense_rank() OVER (ORDER BY count(*) DESC) AS claims_per_encounter_rank
FROM analytics.fact_claim
GROUP BY encounter_id
ORDER BY claim_count DESC, encounter_id;

-- Validation CF01-CF03: grouped claim totals reconcile to the claim fact.
WITH by_month AS (
    SELECT service_date_key, count(*) n FROM analytics.fact_claim GROUP BY service_date_key
), by_encounter AS (
    SELECT encounter_id, count(*) n FROM analytics.fact_claim GROUP BY encounter_id
)
SELECT
    (SELECT sum(n) FROM by_month) AS claims_by_month,
    (SELECT sum(n) FROM by_encounter) AS claims_by_encounter,
    (SELECT count(*) FROM analytics.fact_claim) AS fact_claims;

-- Analysis CF04: encounter-grain financial baseline from Fact_Encounter only.
SELECT
    count(*) AS encounter_count,
    sum(total_claim_cost) AS total_encounter_claim_cost,
    sum(payer_coverage) AS total_payer_coverage,
    sum(total_claim_cost) - sum(payer_coverage) AS source_patient_responsibility_difference
FROM analytics.fact_encounter;

-- Analysis CF05: transaction-grain financial baseline from Fact_ClaimTransaction only.
-- The payment ratio is a source-measure ratio, not a final reimbursement KPI.
SELECT
    count(*) AS claim_transaction_count,
    sum(amount) AS total_transaction_amount,
    sum(payments) AS total_payments,
    sum(transfers) AS total_transfers,
    round(sum(payments) / nullif(sum(amount), 0), 6) AS payment_to_transaction_ratio
FROM analytics.fact_claim_transaction;

-- Analysis CF06: distribution of transaction-derived claim value.
-- Grain after the CTE: one claim ID; no Fact_Claim join is needed.
WITH claim_values AS (
    SELECT claim_id, sum(amount) AS transaction_derived_claim_value
    FROM analytics.fact_claim_transaction
    GROUP BY claim_id
), bucketed AS (
    SELECT claim_id, transaction_derived_claim_value,
           ntile(4) OVER (ORDER BY transaction_derived_claim_value) AS value_quartile
    FROM claim_values
)
SELECT
    value_quartile,
    count(*) AS claim_count,
    min(transaction_derived_claim_value) AS minimum_claim_value,
    round(avg(transaction_derived_claim_value), 2) AS average_claim_value,
    max(transaction_derived_claim_value) AS maximum_claim_value
FROM bucketed
GROUP BY value_quartile
ORDER BY value_quartile;

-- Analysis CF07: top claims by transaction-derived value.
WITH claim_values AS (
    SELECT claim_id, sum(amount) AS transaction_derived_claim_value,
           sum(payments) AS payments, sum(transfers) AS transfers,
           count(*) AS transaction_count
    FROM analytics.fact_claim_transaction
    GROUP BY claim_id
)
SELECT
    claim_id, transaction_count, transaction_derived_claim_value,
    payments, transfers,
    dense_rank() OVER (ORDER BY transaction_derived_claim_value DESC) AS value_rank
FROM claim_values
ORDER BY value_rank, claim_id
FETCH FIRST 20 ROWS WITH TIES;

-- Analysis CF08: monthly transaction financial trend. Date role: from_date_key.
SELECT
    date_trunc('month', d.full_date)::date AS transaction_month,
    count(*) AS transaction_count,
    sum(t.amount) AS transaction_amount,
    sum(t.payments) AS payments,
    sum(t.transfers) AS transfers
FROM analytics.fact_claim_transaction t
JOIN analytics.dim_date d ON d.date_key = t.from_date_key
WHERE d.date_key <> 0
GROUP BY date_trunc('month', d.full_date)
ORDER BY transaction_month;

-- Validation CF04-CF08: same-grain financial totals; every difference must be zero.
WITH claim_values AS (
    SELECT claim_id, sum(amount) amount, sum(payments) payments, sum(transfers) transfers
    FROM analytics.fact_claim_transaction GROUP BY claim_id
), monthly AS (
    SELECT from_date_key, sum(amount) amount, sum(payments) payments, sum(transfers) transfers
    FROM analytics.fact_claim_transaction GROUP BY from_date_key
)
SELECT
    (SELECT sum(total_claim_cost) FROM analytics.fact_encounter) AS encounter_claim_cost,
    (SELECT sum(payer_coverage) FROM analytics.fact_encounter) AS encounter_payer_coverage,
    (SELECT sum(amount) FROM analytics.fact_claim_transaction) AS transaction_amount,
    (SELECT sum(amount) FROM claim_values) AS claim_grouped_amount,
    (SELECT sum(amount) FROM monthly) AS monthly_grouped_amount,
    (SELECT sum(amount) FROM claim_values) - (SELECT sum(amount) FROM analytics.fact_claim_transaction) AS claim_group_difference,
    (SELECT sum(amount) FROM monthly) - (SELECT sum(amount) FROM analytics.fact_claim_transaction) AS month_group_difference;

ROLLBACK;
