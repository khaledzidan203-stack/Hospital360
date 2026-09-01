"""Determinism and acceptance tests for synthetic enterprise generation."""

from __future__ import annotations

import json
from pathlib import Path
import unittest

from src.data_generation.enterprise.config import MASTER_SEED, PROFILES


ROOT = Path(__file__).resolve().parents[1]


class EnterpriseGenerationTests(unittest.TestCase):
    def test_seed_is_fixed(self) -> None:
        self.assertEqual(MASTER_SEED, 20260831)

    def test_final_profile_is_exactly_36_months(self) -> None:
        self.assertEqual(PROFILES["FINAL_36M"].months, 36)

    def test_accepted_manifest(self) -> None:
        manifest_path = ROOT / "data/raw/finance/enterprise_generation_manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        self.assertEqual(manifest["status"], "PASS")
        self.assertEqual(manifest["profile"], "FINAL_36M")
        self.assertEqual(manifest["fact_rows"], 25_716)
        self.assertEqual(manifest["validation"]["status"], "PASS")
        self.assertEqual(manifest["validation"]["errors"], [])


if __name__ == "__main__":
    unittest.main()
