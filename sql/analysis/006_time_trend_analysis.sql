-- Hospital360 V1: Calendar-month trends.
-- Read-only. Each query uses one fact and a continuous Dim_Date month spine.
\set ON_ERROR_STOP on
\pset pager off
BEGIN TRANSACTION READ ONLY;

-- Analysis TT01: monthly encounters with MoM, YoY, rolling average, and running total.
-- Date role: encounter start date.
WITH bounds AS (
    SELECT min(d.full_date) AS min_date, max(d.full_date) AS max_date
    FROM analytics.fact_encounter f JOIN analytics.dim_date d ON d.date_key = f.start_date_key
    WHERE d.date_key <> 0
), months AS (
    SELECT DISTINCT date_trunc('month', d.full_date)::date AS month_start
    FROM analytics.dim_date d CROSS JOIN bounds b
    WHERE d.full_date BETWEEN date_trunc('month', b.min_date)::date AND b.max_date
), monthly AS (
    SELECT date_trunc('month', d.full_date)::date AS month_start, count(*) AS encounter_count
    FROM analytics.fact_encounter f JOIN analytics.dim_date d ON d.date_key = f.start_date_key
    WHERE d.date_key <> 0 GROUP BY date_trunc('month', d.full_date)
), series AS (
    SELECT m.month_start, coalesce(a.encounter_count, 0) AS encounter_count FROM months m LEFT JOIN monthly a USING (month_start)
), metrics AS (
    SELECT month_start, encounter_count,
           lag(encounter_count) OVER (ORDER BY month_start) AS prior_month_count,
           lag(encounter_count, 12) OVER (ORDER BY month_start) AS prior_year_count,
           avg(encounter_count) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_month_average,
           sum(encounter_count) OVER (ORDER BY month_start) AS running_encounter_total
    FROM series
)
SELECT month_start, encounter_count, prior_month_count,
       round(100.0 * (encounter_count - prior_month_count) / nullif(prior_month_count, 0), 2) AS mom_change_pct,
       prior_year_count,
       round(100.0 * (encounter_count - prior_year_count) / nullif(prior_year_count, 0), 2) AS yoy_change_pct,
       round(rolling_3_month_average, 2) AS rolling_3_month_average,
       running_encounter_total
FROM metrics ORDER BY month_start;

-- Analysis TT02: monthly claim headers with MoM, YoY, rolling average, and running total.
-- Date role: claim service date.
WITH bounds AS (
    SELECT min(d.full_date) min_date, max(d.full_date) max_date
    FROM analytics.fact_claim f JOIN analytics.dim_date d ON d.date_key = f.service_date_key WHERE d.date_key <> 0
), months AS (
    SELECT DISTINCT date_trunc('month', d.full_date)::date month_start
    FROM analytics.dim_date d CROSS JOIN bounds b
    WHERE d.full_date BETWEEN date_trunc('month', b.min_date)::date AND b.max_date
), monthly AS (
    SELECT date_trunc('month', d.full_date)::date month_start, count(*) claim_count
    FROM analytics.fact_claim f JOIN analytics.dim_date d ON d.date_key = f.service_date_key
    WHERE d.date_key <> 0 GROUP BY date_trunc('month', d.full_date)
), series AS (
    SELECT m.month_start, coalesce(a.claim_count, 0) claim_count FROM months m LEFT JOIN monthly a USING (month_start)
), metrics AS (
    SELECT month_start, claim_count,
           lag(claim_count) OVER (ORDER BY month_start) prior_month_count,
           lag(claim_count, 12) OVER (ORDER BY month_start) prior_year_count,
           avg(claim_count) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) rolling_3_month_average,
           sum(claim_count) OVER (ORDER BY month_start) running_claim_total
    FROM series
)
SELECT month_start, claim_count, prior_month_count,
       round(100.0 * (claim_count - prior_month_count) / nullif(prior_month_count, 0), 2) mom_change_pct,
       prior_year_count,
       round(100.0 * (claim_count - prior_year_count) / nullif(prior_year_count, 0), 2) yoy_change_pct,
       round(rolling_3_month_average, 2) rolling_3_month_average,
       running_claim_total
FROM metrics ORDER BY month_start;

-- Analysis TT03: monthly claim transactions and financial movement.
-- Date role: transaction from date. All measures remain at transaction grain.
WITH bounds AS (
    SELECT min(d.full_date) min_date, max(d.full_date) max_date
    FROM analytics.fact_claim_transaction f JOIN analytics.dim_date d ON d.date_key = f.from_date_key WHERE d.date_key <> 0
), months AS (
    SELECT DISTINCT date_trunc('month', d.full_date)::date month_start
    FROM analytics.dim_date d CROSS JOIN bounds b
    WHERE d.full_date BETWEEN date_trunc('month', b.min_date)::date AND b.max_date
), monthly AS (
    SELECT date_trunc('month', d.full_date)::date month_start,
           count(*) transaction_count, sum(f.amount) amount,
           sum(f.payments) payments, sum(f.transfers) transfers
    FROM analytics.fact_claim_transaction f JOIN analytics.dim_date d ON d.date_key = f.from_date_key
    WHERE d.date_key <> 0 GROUP BY date_trunc('month', d.full_date)
), series AS (
    SELECT m.month_start, coalesce(a.transaction_count, 0) transaction_count,
           coalesce(a.amount, 0) amount, coalesce(a.payments, 0) payments,
           coalesce(a.transfers, 0) transfers
    FROM months m LEFT JOIN monthly a USING (month_start)
), metrics AS (
    SELECT month_start, transaction_count, amount, payments, transfers,
           lag(amount) OVER (ORDER BY month_start) prior_month_amount,
           lag(amount, 12) OVER (ORDER BY month_start) prior_year_amount,
           avg(amount) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) rolling_3_month_amount,
           sum(amount) OVER (ORDER BY month_start) running_amount,
           sum(payments) OVER (ORDER BY month_start) running_payments,
           sum(transfers) OVER (ORDER BY month_start) running_transfers
    FROM series
)
SELECT month_start, transaction_count, amount, payments, transfers,
       round(100.0 * (amount - prior_month_amount) / nullif(prior_month_amount, 0), 2) amount_mom_change_pct,
       round(100.0 * (amount - prior_year_amount) / nullif(prior_year_amount, 0), 2) amount_yoy_change_pct,
       round(rolling_3_month_amount, 2) rolling_3_month_amount,
       running_amount, running_payments, running_transfers
FROM metrics ORDER BY month_start;

-- Validation TT01-TT03: calendar-spine totals equal the native facts.
WITH encounter_months AS (
    SELECT date_trunc('month', d.full_date), count(*) n
    FROM analytics.fact_encounter f JOIN analytics.dim_date d ON d.date_key=f.start_date_key
    WHERE d.date_key<>0 GROUP BY 1
), claim_months AS (
    SELECT date_trunc('month', d.full_date), count(*) n
    FROM analytics.fact_claim f JOIN analytics.dim_date d ON d.date_key=f.service_date_key
    WHERE d.date_key<>0 GROUP BY 1
), transaction_months AS (
    SELECT date_trunc('month', d.full_date), count(*) n, sum(f.amount) amount,
           sum(f.payments) payments, sum(f.transfers) transfers
    FROM analytics.fact_claim_transaction f JOIN analytics.dim_date d ON d.date_key=f.from_date_key
    WHERE d.date_key<>0 GROUP BY 1
)
SELECT
    (SELECT sum(n) FROM encounter_months) AS monthly_encounters,
    (SELECT count(*) FROM analytics.fact_encounter) AS fact_encounters,
    (SELECT sum(n) FROM claim_months) AS monthly_claims,
    (SELECT count(*) FROM analytics.fact_claim) AS fact_claims,
    (SELECT sum(n) FROM transaction_months) AS monthly_transactions,
    (SELECT count(*) FROM analytics.fact_claim_transaction) AS fact_transactions,
    (SELECT sum(amount) FROM transaction_months) AS monthly_amount,
    (SELECT sum(amount) FROM analytics.fact_claim_transaction) AS fact_amount,
    (SELECT sum(payments) FROM transaction_months) AS monthly_payments,
    (SELECT sum(payments) FROM analytics.fact_claim_transaction) AS fact_payments,
    (SELECT sum(transfers) FROM transaction_months) AS monthly_transfers,
    (SELECT sum(transfers) FROM analytics.fact_claim_transaction) AS fact_transfers;

ROLLBACK;
