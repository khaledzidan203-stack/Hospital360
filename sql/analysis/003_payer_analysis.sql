-- Hospital360 V1: Payer analysis.
-- Read-only. Payer roles are analyzed separately at their native fact grains.
\set ON_ERROR_STOP on
\pset pager off
BEGIN TRANSACTION READ ONLY;

-- Analysis PA01: claim headers by primary payer with contribution percentage.
SELECT
    CASE WHEN p.payer_key = 0 THEN 'Unknown / Unmapped' ELSE p.payer_id END AS primary_payer,
    count(*) AS claim_count,
    round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS claim_contribution_pct
FROM analytics.fact_claim c
JOIN analytics.dim_payer p ON p.payer_key = c.primary_payer_key
GROUP BY p.payer_key, p.payer_id
ORDER BY claim_count DESC, primary_payer;

-- Validation PA01: payer groups retain every claim and contribute approximately 100%.
WITH payer_claims AS (
    SELECT primary_payer_key, count(*) AS claim_count
    FROM analytics.fact_claim
    GROUP BY primary_payer_key
), validated AS (
    SELECT claim_count,
           100.0 * claim_count / sum(claim_count) OVER () AS contribution_pct
    FROM payer_claims
)
SELECT
    sum(claim_count) AS grouped_claims,
    (SELECT count(*) FROM analytics.fact_claim) AS fact_claims,
    sum(claim_count) - (SELECT count(*) FROM analytics.fact_claim) AS difference,
    round(sum(contribution_pct), 2) AS contribution_pct
FROM validated;

-- Analysis PA02: transaction amount by the parent claim's primary payer role.
-- The payer key was resolved during analytics loading; no Fact_Claim join is used.
SELECT
    CASE WHEN p.payer_key = 0 THEN 'Unknown / Unmapped' ELSE p.payer_id END AS claim_primary_payer,
    count(*) AS transaction_count,
    sum(t.amount) AS transaction_amount,
    sum(t.payments) AS payments,
    sum(t.transfers) AS transfers,
    round(100.0 * sum(t.amount) / nullif(sum(sum(t.amount)) OVER (), 0), 2) AS amount_contribution_pct
FROM analytics.fact_claim_transaction t
JOIN analytics.dim_payer p ON p.payer_key = t.claim_primary_payer_key
GROUP BY p.payer_key, p.payer_id
ORDER BY transaction_amount DESC, claim_primary_payer;

-- Analysis PA03: encounter claim cost and coverage by encounter payer role.
SELECT
    CASE WHEN p.payer_key = 0 THEN 'Unknown / Unmapped' ELSE p.payer_id END AS encounter_payer,
    count(*) AS encounter_count,
    sum(e.total_claim_cost) AS encounter_claim_cost,
    sum(e.payer_coverage) AS payer_coverage,
    round(100.0 * sum(e.payer_coverage) / nullif(sum(sum(e.payer_coverage)) OVER (), 0), 2) AS coverage_contribution_pct
FROM analytics.fact_encounter e
JOIN analytics.dim_payer p ON p.payer_key = e.payer_key
GROUP BY p.payer_key, p.payer_id
ORDER BY payer_coverage DESC, encounter_payer;

-- Analysis PA04: explicit Unknown-member usage by supported payer role.
SELECT 'claim_primary_payer' AS payer_role, count(*) FILTER (WHERE primary_payer_key = 0) AS unknown_rows, count(*) AS total_rows
FROM analytics.fact_claim
UNION ALL
SELECT 'claim_secondary_payer', count(*) FILTER (WHERE secondary_payer_key = 0), count(*)
FROM analytics.fact_claim
UNION ALL
SELECT 'transaction_claim_primary_payer', count(*) FILTER (WHERE claim_primary_payer_key = 0), count(*)
FROM analytics.fact_claim_transaction
UNION ALL
SELECT 'encounter_payer', count(*) FILTER (WHERE payer_key = 0), count(*)
FROM analytics.fact_encounter;

-- Analysis PA05: primary-payer claim mix over service month.
SELECT
    date_trunc('month', d.full_date)::date AS service_month,
    CASE WHEN p.payer_key = 0 THEN 'Unknown / Unmapped' ELSE p.payer_id END AS primary_payer,
    count(*) AS claim_count,
    round(100.0 * count(*) / sum(count(*)) OVER (
        PARTITION BY date_trunc('month', d.full_date)
    ), 2) AS monthly_payer_mix_pct
FROM analytics.fact_claim c
JOIN analytics.dim_date d ON d.date_key = c.service_date_key
JOIN analytics.dim_payer p ON p.payer_key = c.primary_payer_key
WHERE d.date_key <> 0
GROUP BY date_trunc('month', d.full_date), p.payer_key, p.payer_id
ORDER BY service_month, claim_count DESC, primary_payer;

-- Validation PA02/PA03/PA05: payer groupings retain their native fact totals.
WITH tx AS (
    SELECT claim_primary_payer_key, sum(amount) amount FROM analytics.fact_claim_transaction GROUP BY claim_primary_payer_key
), enc AS (
    SELECT payer_key, sum(total_claim_cost) claim_cost, sum(payer_coverage) coverage FROM analytics.fact_encounter GROUP BY payer_key
), claim_month_payer AS (
    SELECT service_date_key, primary_payer_key, count(*) n FROM analytics.fact_claim GROUP BY service_date_key, primary_payer_key
)
SELECT
    (SELECT sum(amount) FROM tx) AS payer_grouped_transaction_amount,
    (SELECT sum(amount) FROM analytics.fact_claim_transaction) AS fact_transaction_amount,
    (SELECT sum(claim_cost) FROM enc) AS payer_grouped_encounter_claim_cost,
    (SELECT sum(total_claim_cost) FROM analytics.fact_encounter) AS fact_encounter_claim_cost,
    (SELECT sum(coverage) FROM enc) AS payer_grouped_coverage,
    (SELECT sum(payer_coverage) FROM analytics.fact_encounter) AS fact_coverage,
    (SELECT sum(n) FROM claim_month_payer) AS payer_month_claims,
    (SELECT count(*) FROM analytics.fact_claim) AS fact_claims;

ROLLBACK;
