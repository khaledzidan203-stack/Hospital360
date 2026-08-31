"""Read-only PostgreSQL access for Hospital360 EDA.

The local PostgreSQL ``psql`` client is used deliberately so the EDA can run
without embedding credentials or requiring a Python database driver. Queries
are exported as CSV and parsed into pandas DataFrames. PostgreSQL's
``default_transaction_read_only`` setting provides the database-side safety
gate in addition to the local SELECT/WITH-only validation.
"""

from __future__ import annotations

from io import StringIO
import os
from pathlib import Path
import shutil
import subprocess
from typing import Mapping

import pandas as pd
from dotenv import dotenv_values


PROJECT_ROOT = Path(__file__).resolve().parents[2]


def connection_settings(env_file: Path | None = None) -> dict[str, str]:
    """Return connection settings from process variables and an ignored .env."""
    env_path = env_file or PROJECT_ROOT / ".env"
    file_values = {key: value for key, value in dotenv_values(env_path).items() if value}
    keys = (
        "POSTGRES_HOST",
        "POSTGRES_PORT",
        "POSTGRES_DB",
        "POSTGRES_USER",
        "POSTGRES_PASSWORD",
    )
    defaults = {
        "POSTGRES_HOST": "localhost",
        "POSTGRES_PORT": "5432",
        "POSTGRES_DB": "hospital360",
    }
    settings = {
        key: os.environ.get(key) or file_values.get(key) or defaults.get(key, "")
        for key in keys
    }
    missing = [key for key in keys if not settings[key]]
    if missing:
        raise RuntimeError(f"Missing database environment variables: {', '.join(missing)}")
    return settings


def find_psql() -> Path:
    """Locate psql without relying on a user-specific absolute path."""
    configured = os.environ.get("PSQL_PATH")
    if configured and Path(configured).is_file():
        return Path(configured)
    discovered = shutil.which("psql")
    if discovered:
        return Path(discovered)
    candidates: list[Path] = []
    for base in (Path("D:/PostgreSQL"), Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "PostgreSQL"):
        if base.exists():
            candidates.extend(base.glob("*/bin/psql.exe"))
    if not candidates:
        raise FileNotFoundError("psql was not found; set PSQL_PATH or add psql to PATH")
    return sorted(candidates, reverse=True)[0]


def _validate_read_only_sql(sql: str) -> str:
    statement = sql.strip().rstrip(";").strip()
    if not statement.lower().startswith(("select", "with")):
        raise ValueError("EDA database access accepts SELECT or WITH queries only")
    if ";" in statement:
        raise ValueError("Multiple SQL statements are not allowed")
    return statement


def query_dataframe(
    sql: str,
    *,
    settings: Mapping[str, str] | None = None,
    timeout_seconds: int = 900,
    **read_csv_options: object,
) -> pd.DataFrame:
    """Execute one read-only query and return its result as a DataFrame."""
    statement = _validate_read_only_sql(sql)
    cfg = dict(settings or connection_settings())
    command = [
        str(find_psql()),
        "-X",
        "-q",
        "-w",
        "-h",
        cfg["POSTGRES_HOST"],
        "-p",
        cfg["POSTGRES_PORT"],
        "-U",
        cfg["POSTGRES_USER"],
        "-d",
        cfg["POSTGRES_DB"],
        "-v",
        "ON_ERROR_STOP=1",
        "-c",
        f"COPY ({statement}) TO STDOUT WITH (FORMAT CSV, HEADER TRUE)",
    ]
    child_env = os.environ.copy()
    child_env["PGPASSWORD"] = cfg["POSTGRES_PASSWORD"]
    child_env["PGOPTIONS"] = "-c default_transaction_read_only=on"
    result = subprocess.run(
        command,
        cwd=PROJECT_ROOT,
        env=child_env,
        text=True,
        capture_output=True,
        check=False,
        timeout=timeout_seconds,
    )
    if result.returncode:
        raise RuntimeError(f"Read-only PostgreSQL query failed: {result.stderr.strip()}")
    return pd.read_csv(StringIO(result.stdout), **read_csv_options)
