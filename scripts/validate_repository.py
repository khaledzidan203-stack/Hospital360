"""Static, clone-safe validation for the public Hospital360 repository."""

from __future__ import annotations

import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]


def require(path: str) -> Path:
    target = ROOT / path
    if not target.exists():
        raise AssertionError(f"Required path is missing: {path}")
    return target


def main() -> int:
    required = [
        "README.md",
        "docs/PROJECT_INDEX.md",
        "docs/CASE_STUDY.md",
        "docs/TECHNICAL_WALKTHROUGH.md",
        "docs/PROJECT_EVIDENCE_MAP.md",
        "docs/architecture/POWER_BI_TIME_INTELLIGENCE_AUDIT.md",
        "docs/assets/Hospital360 Healthcare Analytics Infographic.png",
        "powerbi/Hospital360.pbip",
        "powerbi/Hospital360.Report/definition/pages/pages.json",
        "powerbi/Hospital360.SemanticModel/definition/model.tmdl",
        "tests/test_enterprise_generation.py",
    ]
    for path in required:
        require(path)

    readme = require("README.md").read_text(encoding="utf-8")
    hero = "docs/assets/Hospital360%20Healthcare%20Analytics%20Infographic.png"
    assert hero in readme, "README must use the approved Hospital360 overview image"
    assert "## Featured Portfolio" not in readme, "README must remain project-focused"
    assert "13 pages" in readme, "README must state the current 13-page report"
    assert "synthetic" in readme.lower(), "README must disclose the synthetic-data boundary"

    pages = json.loads(
        require("powerbi/Hospital360.Report/definition/pages/pages.json").read_text(
            encoding="utf-8"
        )
    )
    assert len(pages.get("pageOrder", [])) == 13, "PBIR page order must contain 13 pages"

    screenshot_dir = require("docs/screenshots")
    screenshots = sorted(p.name for p in screenshot_dir.glob("*.png"))
    assert len(screenshots) == 7, f"Expected 7 representative screenshots, found {len(screenshots)}"

    model = require("powerbi/Hospital360.SemanticModel/definition/model.tmdl").read_text(
        encoding="utf-8"
    )
    assert "'analytics dim_date'" in model, "Governed analytics dim_date is missing"
    if "__PBI_TimeIntelligenceEnabled = 1" in model:
        require("docs/architecture/POWER_BI_TIME_INTELLIGENCE_AUDIT.md")
        print("NOTICE: Auto Date/Time remains enabled; remediation boundary is documented.")

    tests = require("tests/test_enterprise_generation.py").read_text(encoding="utf-8")
    assert "skipUnless" in tests, "Local RAW acceptance test must be clone-safe"

    print("Hospital360 static repository validation: PASS")
    print(f"PBIR pages: {len(pages['pageOrder'])}")
    print(f"Representative screenshots: {len(screenshots)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"VALIDATION FAILED: {exc}", file=sys.stderr)
        raise SystemExit(1)
