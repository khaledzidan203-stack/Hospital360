"""Central configuration for progressive enterprise generation profiles."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[3]
MASTER_SEED = 20260831
FINAL_START = "2023-08-01"


@dataclass(frozen=True)
class EnterpriseProfile:
    name: str
    months: int
    final: bool = False

    @property
    def output_dir(self) -> Path:
        if self.final:
            return PROJECT_ROOT / "data" / "raw"
        return PROJECT_ROOT / "data" / "processed" / "enterprise_pilots" / self.name.lower()


PROFILES = {
    "PILOT_1M": EnterpriseProfile("PILOT_1M", 1),
    "PILOT_3M": EnterpriseProfile("PILOT_3M", 3),
    "PILOT_12M": EnterpriseProfile("PILOT_12M", 12),
    "FINAL_36M": EnterpriseProfile("FINAL_36M", 36, final=True),
}


DOMAIN_SEEDS = {
    "allocation": MASTER_SEED + 101,
    "operations": MASTER_SEED + 211,
    "workforce": MASTER_SEED + 307,
    "finance": MASTER_SEED + 401,
    "budget": MASTER_SEED + 503,
    "it_daily": MASTER_SEED + 601,
    "it_incident": MASTER_SEED + 701,
}


def profile_dates(profile: EnterpriseProfile) -> tuple[str, str]:
    """Return inclusive start/end dates; all profiles start at the same date."""
    import pandas as pd

    start = pd.Timestamp(FINAL_START)
    end = start + pd.DateOffset(months=profile.months) - pd.Timedelta(days=1)
    return start.date().isoformat(), end.date().isoformat()
