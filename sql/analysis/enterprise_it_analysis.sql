-- Read-only Enterprise V1 technology analysis.
\set ON_ERROR_STOP on

SELECT SUM(availability_minutes)::numeric/NULLIF(SUM(scheduled_minutes),0) uptime_pct,
       SUM(downtime_minutes) downtime_minutes,SUM(transaction_count) system_transaction_volume,
       SUM(error_count)::numeric/NULLIF(SUM(transaction_count),0) error_rate
FROM analytics.fact_it_system_daily;

SELECT s.it_system_name,SUM(d.availability_minutes)::numeric/NULLIF(SUM(d.scheduled_minutes),0) uptime_pct,
       SUM(d.downtime_minutes) downtime_minutes,SUM(d.transaction_count) transaction_count
FROM analytics.fact_it_system_daily d JOIN analytics.dim_it_system s ON s.it_system_key=d.it_system_key
GROUP BY s.it_system_name ORDER BY uptime_pct;

SELECT COUNT(*) incident_count,COUNT(*) FILTER(WHERE severity IN('P1','P2')) critical_incidents,
       COUNT(*) FILTER(WHERE sla_met_flag)::numeric/NULLIF(COUNT(*) FILTER(WHERE resolved_at IS NOT NULL),0) sla_compliance_pct,
       AVG(resolution_minutes) FILTER(WHERE resolved_at IS NOT NULL) mean_resolution_minutes
FROM analytics.fact_it_incident;

SELECT severity,COUNT(*) incident_count,AVG(resolution_minutes) mean_resolution_minutes,
       COUNT(*) FILTER(WHERE sla_met_flag)::numeric/NULLIF(COUNT(*) FILTER(WHERE resolved_at IS NOT NULL),0) sla_compliance_pct
FROM analytics.fact_it_incident GROUP BY severity ORDER BY severity;

SELECT d.year_month,COUNT(i.it_incident_key) incident_count,
       AVG(i.resolution_minutes) FILTER(WHERE i.resolved_at IS NOT NULL) mean_resolution_minutes
FROM analytics.fact_it_incident i JOIN analytics.dim_date d ON d.date_key=i.opened_date_key
GROUP BY d.year_month ORDER BY d.year_month;

SELECT s.it_system_name,COUNT(i.it_incident_key) incident_count,SUM(i.downtime_minutes) downtime_minutes
FROM analytics.fact_it_incident i JOIN analytics.dim_it_system s ON s.it_system_key=i.it_system_key
GROUP BY s.it_system_name ORDER BY incident_count DESC;
