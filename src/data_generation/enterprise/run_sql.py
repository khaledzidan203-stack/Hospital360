"""Execute approved Hospital360 SQL files with credentials kept in the ignored .env."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import subprocess

from src.analytics.db import PROJECT_ROOT, connection_settings, find_psql


def run_sql_files(paths: list[str]) -> None:
    settings = connection_settings()
    environment = os.environ.copy()
    environment["PGPASSWORD"] = settings["POSTGRES_PASSWORD"]
    for value in paths:
        path = (PROJECT_ROOT / value).resolve()
        if PROJECT_ROOT not in path.parents or not path.is_file():
            raise FileNotFoundError(value)
        command = [
            str(find_psql()), "-X", "-w", "-v", "ON_ERROR_STOP=1",
            "-h", settings["POSTGRES_HOST"], "-p", settings["POSTGRES_PORT"],
            "-U", settings["POSTGRES_USER"], "-d", settings["POSTGRES_DB"],
            "-f", str(path),
        ]
        result = subprocess.run(command, cwd=PROJECT_ROOT, env=environment, text=True, capture_output=True, check=False)
        if result.returncode:
            raise RuntimeError(f"SQL execution failed for {path.name}: {result.stderr.strip()}")
        print(f"PASS {path.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+")
    args = parser.parse_args()
    run_sql_files(args.paths)
