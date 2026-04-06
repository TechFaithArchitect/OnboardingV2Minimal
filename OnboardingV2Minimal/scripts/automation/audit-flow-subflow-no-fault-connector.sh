#!/usr/bin/env bash
# Subflow metadata does not support faultConnector (API rejects deploy). Fail if any
# <subflows> block contains <faultConnector>.

set -euo pipefail

FLOWS_DIR="${1:-force-app/main/default/flows}"

python3 - "$FLOWS_DIR" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
pat = re.compile(r"<subflows>([\s\S]*?)</subflows>")
failures = []

for path in sorted(root.glob("*.flow-meta.xml")) + sorted(root.glob("*.flow")):
    if not path.is_file():
        continue
    text = path.read_text(encoding="utf-8")
    for block in pat.findall(text):
        if "<faultConnector>" not in block:
            continue
        m = re.search(r"<name>([^<]+)</name>", block)
        name = m.group(1) if m else "(unnamed)"
        failures.append(f"{path.name} subflow={name}")

if failures:
    print("audit-flow-subflow-no-fault-connector: violations:")
    for line in failures:
        print(f"  {line}")
    print(
        "Remove fault paths from subflow elements; use child errorMessage output and decisions instead."
    )
    sys.exit(1)

print("audit-flow-subflow-no-fault-connector: OK (no faultConnector inside subflows).")
PY
