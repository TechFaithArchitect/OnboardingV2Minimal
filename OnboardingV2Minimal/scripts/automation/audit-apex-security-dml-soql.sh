#!/usr/bin/env bash

set -euo pipefail

OUT_TSV="${1:-.analysis/automation-audit/apex_security_inventory.tsv}"
mkdir -p "$(dirname "$OUT_TSV")"

python3 - "$OUT_TSV" <<'PY'
from pathlib import Path
import csv
import re
import sys

out_path = Path(sys.argv[1])
root = Path("force-app/main/default/classes")

db_dml_pattern = re.compile(r"Database\.(insert|update|upsert|delete)\(", re.IGNORECASE)
explicit_dml_pattern = re.compile(r"\b(insert|update|upsert|delete)\s+as\s+(user|system)\b", re.IGNORECASE)

rows = []

for path in sorted(root.glob("*.cls")):
    name = path.name
    if name.endswith("Test.cls") or name.startswith("Test"):
        continue

    lines = path.read_text(encoding="utf-8").splitlines()
    line_count = len(lines)

    for idx, line in enumerate(lines, start=1):
        if "Database.query(" in line:
            start = max(0, idx - 15)
            end = min(line_count, idx + 15)
            window = "\n".join(lines[start:end]).upper()
            has_secure_mode = (
                "WITH SECURITY_ENFORCED" in window or
                "WITH USER_MODE" in window
            )
            rows.append([
                str(path),
                str(idx),
                "Database.query",
                "ok" if has_secure_mode else "review",
                "contains WITH SECURITY_ENFORCED/USER_MODE near call" if has_secure_mode else "missing obvious security mode near call",
            ])

        dml_match = db_dml_pattern.search(line)
        if dml_match:
            has_access_level = "AccessLevel." in line
            rows.append([
                str(path),
                str(idx),
                f"Database.{dml_match.group(1).lower()}",
                "ok" if has_access_level else "review",
                "explicit AccessLevel on Database.* call" if has_access_level else "missing explicit AccessLevel on Database.* call",
            ])

        explicit_match = explicit_dml_pattern.search(line)
        if explicit_match:
            rows.append([
                str(path),
                str(idx),
                f"{explicit_match.group(1).lower()} as {explicit_match.group(2).lower()}",
                "ok",
                "explicit Apex DML mode",
            ])

with out_path.open("w", encoding="utf-8", newline="") as fh:
    writer = csv.writer(fh, delimiter="\t")
    writer.writerow(["file", "line", "callsite", "status", "note"])
    writer.writerows(rows)

ok_count = sum(1 for row in rows if row[3] == "ok")
review_count = sum(1 for row in rows if row[3] == "review")
print(f"Apex security inventory complete. Callsites: {len(rows)}")
print(f"OK: {ok_count}")
print(f"REVIEW: {review_count}")
print(f"Report: {out_path}")
PY
