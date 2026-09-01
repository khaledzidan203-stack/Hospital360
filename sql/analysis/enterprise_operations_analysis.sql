-- Read-only Enterprise V1 operations and capacity analysis.
\set ON_ERROR_STOP on

SELECT SUM(admissions) admissions,SUM(discharges) discharges,
       SUM(occupied_bed_days)/NULLIF(SUM(available_bed_days),0) occupancy_rate,
       SUM(length_of_stay_days_total)/NULLIF(SUM(discharged_with_los_count),0) average_length_of_stay,
       SUM(wait_minutes_total)/NULLIF(SUM(waited_encounter_count),0) average_waiting_time,
       SUM(appointments_completed)::numeric/NULLIF(SUM(appointments_scheduled),0) appointment_completion_pct
FROM analytics.fact_operations_daily;

SELECT dep.department_name,SUM(o.occupied_bed_days)/NULLIF(SUM(o.available_bed_days),0) occupancy_rate,
       SUM(o.admissions) admissions,SUM(o.discharges) discharges
FROM analytics.fact_operations_daily o JOIN analytics.dim_department dep ON dep.department_key=o.department_key
WHERE dep.bed_applicable_flag GROUP BY dep.department_name ORDER BY occupancy_rate DESC;

SELECT d.year_month,SUM(o.occupied_bed_days)/NULLIF(SUM(o.available_bed_days),0) occupancy_rate,
       SUM(o.admissions) admissions,SUM(o.discharges) discharges
FROM analytics.fact_operations_daily o JOIN analytics.dim_date d ON d.date_key=o.date_key
GROUP BY d.year_month ORDER BY d.year_month;

SELECT dep.department_name,SUM(o.wait_minutes_total)/NULLIF(SUM(o.waited_encounter_count),0) average_waiting_time
FROM analytics.fact_operations_daily o JOIN analytics.dim_department dep ON dep.department_key=o.department_key
GROUP BY dep.department_name ORDER BY average_waiting_time DESC;

SELECT dep.department_name,SUM(o.appointments_completed)::numeric/NULLIF(SUM(o.appointments_scheduled),0) appointment_completion_pct
FROM analytics.fact_operations_daily o JOIN analytics.dim_department dep ON dep.department_key=o.department_key
WHERE o.appointments_scheduled IS NOT NULL GROUP BY dep.department_name ORDER BY appointment_completion_pct;
