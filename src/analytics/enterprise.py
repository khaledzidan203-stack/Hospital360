"""Read-only analytical extracts for the Hospital360 enterprise extension."""

from __future__ import annotations

import pandas as pd

from .db import query_dataframe


def executive_baseline() -> pd.DataFrame:
    """Return one reconciled enterprise KPI row without changing database state."""
    return query_dataframe(
        """
        SELECT
          (SELECT sum(operating_revenue) FROM analytics.fact_finance_monthly) AS revenue,
          (SELECT sum(operating_cost) FROM analytics.fact_finance_monthly) AS operating_cost,
          (SELECT sum(payroll_cost) FROM analytics.fact_workforce_monthly) AS payroll_cost,
          (SELECT sum(encounter_count) FROM analytics.fact_operations_daily) AS encounter_volume,
          (SELECT sum(transaction_count) FROM analytics.fact_it_system_daily) AS it_transactions,
          (SELECT count(*) FROM analytics.fact_it_incident) AS incidents
        """
    )


def finance_by_month() -> pd.DataFrame:
    return query_dataframe(
        """
        SELECT d.full_date AS month_start,
               sum(f.operating_revenue) AS revenue,
               sum(f.operating_cost) AS operating_cost,
               sum(f.operating_revenue-f.operating_cost) AS operating_margin
        FROM analytics.fact_finance_monthly f
        JOIN analytics.dim_date d ON d.date_key=f.month_start_date_key
        GROUP BY d.full_date ORDER BY d.full_date
        """,
        parse_dates=["month_start"],
    )


def department_performance() -> pd.DataFrame:
    return query_dataframe(
        """
        WITH finance AS (
          SELECT department_key, sum(operating_revenue) revenue,
                 sum(operating_cost) operating_cost
          FROM analytics.fact_finance_monthly GROUP BY department_key
        ), operations AS (
          SELECT department_key, sum(encounter_count) encounters,
                 avg(capacity_utilization) FILTER (WHERE capacity_utilization IS NOT NULL) occupancy_rate,
                 sum(wait_minutes_total)/nullif(sum(waited_encounter_count),0) average_wait_minutes
          FROM analytics.fact_operations_daily GROUP BY department_key
        )
        SELECT d.department_name, f.revenue, f.operating_cost,
               f.revenue-f.operating_cost operating_margin,
               o.encounters, o.occupancy_rate, o.average_wait_minutes
        FROM analytics.dim_department d
        LEFT JOIN finance f USING(department_key)
        LEFT JOIN operations o USING(department_key)
        WHERE d.department_key<>0 ORDER BY f.operating_cost DESC
        """
    )


def workforce_by_month() -> pd.DataFrame:
    return query_dataframe(
        """
        SELECT d.full_date month_start, sum(f.headcount) headcount, sum(f.fte) fte,
               sum(f.vacancy_count) vacancies, sum(f.overtime_hours) overtime_hours,
               sum(f.absence_hours) absence_hours, sum(f.payroll_cost) payroll_cost
        FROM analytics.fact_workforce_monthly f
        JOIN analytics.dim_date d ON d.date_key=f.month_start_date_key
        GROUP BY d.full_date ORDER BY d.full_date
        """,
        parse_dates=["month_start"],
    )


def it_system_profile() -> pd.DataFrame:
    return query_dataframe(
        """
        SELECT s.it_system_name,
               sum(f.available_minutes)::numeric/nullif(sum(f.scheduled_minutes),0) uptime_rate,
               sum(f.downtime_minutes) downtime_minutes,
               sum(f.transaction_count) transaction_count,
               sum(f.error_count)::numeric/nullif(sum(f.transaction_count),0) error_rate,
               sum(f.incident_count) incident_count
        FROM analytics.fact_it_system_daily f
        JOIN analytics.dim_it_system s USING(it_system_key)
        WHERE s.it_system_key<>0 GROUP BY s.it_system_name
        ORDER BY uptime_rate
        """
    )


def correlation_matrix() -> pd.DataFrame:
    """Return descriptive associations; correlations do not imply causation."""
    data = query_dataframe(
        """
        WITH monthly_ops AS (
          SELECT date_trunc('month',d.full_date)::date month_start,
                 sum(encounter_count) encounters,
                 avg(capacity_utilization) FILTER (WHERE capacity_utilization IS NOT NULL) occupancy
          FROM analytics.fact_operations_daily f JOIN analytics.dim_date d USING(date_key)
          GROUP BY 1
        ), monthly_workforce AS (
          SELECT d.full_date month_start,sum(fte) fte,sum(overtime_hours) overtime
          FROM analytics.fact_workforce_monthly f
          JOIN analytics.dim_date d ON d.date_key=f.month_start_date_key GROUP BY 1
        ), monthly_finance AS (
          SELECT d.full_date month_start,sum(operating_cost) operating_cost
          FROM analytics.fact_finance_monthly f
          JOIN analytics.dim_date d ON d.date_key=f.month_start_date_key GROUP BY 1
        )
        SELECT o.month_start,o.encounters,o.occupancy,w.fte,w.overtime,n.operating_cost
        FROM monthly_ops o JOIN monthly_workforce w USING(month_start)
        JOIN monthly_finance n USING(month_start) ORDER BY o.month_start
        """,
        parse_dates=["month_start"],
    )
    return data.drop(columns="month_start").corr(numeric_only=True)
