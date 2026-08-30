-- Hospital360 V1: Provider and organization performance.
-- Read-only. V1 reference dimensions contain inferred IDs and role flags, not master names.
\set ON_ERROR_STOP on
\pset pager off
BEGIN TRANSACTION READ ONLY;

-- Analysis PO01: provider encounter volume and duration ranking.
SELECT
    p.provider_id,
    count(*) AS encounter_count,
    count(DISTINCT e.patient_key) AS patient_count,
    round((avg(extract(epoch FROM (e.stop_at - e.start_at)) / 60.0)
        FILTER (WHERE e.start_at IS NOT NULL AND e.stop_at IS NOT NULL AND e.stop_at >= e.start_at))::numeric, 2) AS average_duration_minutes,
    dense_rank() OVER (ORDER BY count(*) DESC) AS encounter_volume_rank
FROM analytics.fact_encounter e
JOIN analytics.dim_provider p ON p.provider_key = e.provider_key
GROUP BY p.provider_id
ORDER BY encounter_volume_rank, p.provider_id;

-- Analysis PO02: organization encounter volume, duration, and same-grain financial totals.
SELECT
    o.organization_id,
    count(*) AS encounter_count,
    count(DISTINCT e.patient_key) AS patient_count,
    round((avg(extract(epoch FROM (e.stop_at - e.start_at)) / 60.0)
        FILTER (WHERE e.start_at IS NOT NULL AND e.stop_at IS NOT NULL AND e.stop_at >= e.start_at))::numeric, 2) AS average_duration_minutes,
    sum(e.total_claim_cost) AS encounter_claim_cost,
    sum(e.payer_coverage) AS payer_coverage,
    dense_rank() OVER (ORDER BY count(*) DESC) AS encounter_volume_rank
FROM analytics.fact_encounter e
JOIN analytics.dim_organization o ON o.organization_key = e.organization_key
GROUP BY o.organization_id
ORDER BY encounter_volume_rank, o.organization_id;

-- Analysis PO03: transaction activity by transaction provider role.
SELECT
    p.provider_id,
    count(*) AS transaction_count,
    sum(t.amount) AS transaction_amount,
    sum(t.payments) AS payments,
    dense_rank() OVER (ORDER BY sum(t.amount) DESC) AS transaction_amount_rank
FROM analytics.fact_claim_transaction t
JOIN analytics.dim_provider p ON p.provider_key = t.provider_key
GROUP BY p.provider_id
ORDER BY transaction_amount_rank, p.provider_id;

-- Analysis PO04: place-of-service transaction activity by organization.
SELECT
    o.organization_id,
    count(*) AS transaction_count,
    sum(t.amount) AS transaction_amount,
    sum(t.payments) AS payments,
    dense_rank() OVER (ORDER BY sum(t.amount) DESC) AS transaction_amount_rank
FROM analytics.fact_claim_transaction t
JOIN analytics.dim_organization o ON o.organization_key = t.organization_key
GROUP BY o.organization_id
ORDER BY transaction_amount_rank, o.organization_id;

-- Validation PO01-PO04: one-to-many dimension joins do not multiply facts or amounts.
WITH encounter_provider AS (
    SELECT provider_key, count(*) n FROM analytics.fact_encounter GROUP BY provider_key
), encounter_organization AS (
    SELECT organization_key, count(*) n, sum(total_claim_cost) cost, sum(payer_coverage) coverage
    FROM analytics.fact_encounter GROUP BY organization_key
), transaction_provider AS (
    SELECT provider_key, count(*) n, sum(amount) amount FROM analytics.fact_claim_transaction GROUP BY provider_key
), transaction_organization AS (
    SELECT organization_key, count(*) n, sum(amount) amount FROM analytics.fact_claim_transaction GROUP BY organization_key
)
SELECT
    (SELECT sum(n) FROM encounter_provider) AS provider_grouped_encounters,
    (SELECT sum(n) FROM encounter_organization) AS organization_grouped_encounters,
    (SELECT count(*) FROM analytics.fact_encounter) AS fact_encounters,
    (SELECT sum(cost) FROM encounter_organization) AS organization_grouped_claim_cost,
    (SELECT sum(total_claim_cost) FROM analytics.fact_encounter) AS fact_claim_cost,
    (SELECT sum(n) FROM transaction_provider) AS provider_grouped_transactions,
    (SELECT sum(n) FROM transaction_organization) AS organization_grouped_transactions,
    (SELECT count(*) FROM analytics.fact_claim_transaction) AS fact_transactions,
    (SELECT sum(amount) FROM transaction_provider) AS provider_grouped_amount,
    (SELECT sum(amount) FROM transaction_organization) AS organization_grouped_amount,
    (SELECT sum(amount) FROM analytics.fact_claim_transaction) AS fact_transaction_amount;

ROLLBACK;
