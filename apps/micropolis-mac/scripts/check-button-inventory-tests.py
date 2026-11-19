#!/usr/bin/env python3
"""Check that the optional target has exactly one named method per table row."""
from collections import Counter
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
table = (root / "BUTTON-INVENTORY.md").read_text()
rows = [line for line in table.splitlines() if re.match(r"^\| \d{3} \|", line)]
expected = []
for row in rows:
    names = re.findall(r"`(test_B\d{3}_\w+)`", row)
    if len(names) != 1:
        raise SystemExit("Expected one test name in inventory row: " + row)
    expected += names
if len(rows) != 139 or len(set(expected)) != 139:
    raise SystemExit("Expected 139 distinct inventory rows/tests; review changes to the inventory.")

found = []
for source in (root / "Tests/MicropolisButtonInventoryUITests").glob("*.swift"):
    found += re.findall(r"func\s+(test_B\d{3}_\w+)\s*\(", source.read_text())
duplicates = [name for name, count in Counter(found).items() if count != 1]
missing = sorted(set(expected) - set(found))
extra = sorted(set(found) - set(expected))
if duplicates or missing or extra:
    raise SystemExit(f"Duplicate tests: {duplicates}\nMissing tests: {missing}\nUnexpected tests: {extra}")
print(f"Inventory mapping verified: {len(expected)} rows, {len(found)} distinct test methods.")
