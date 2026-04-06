#!/usr/bin/env bash

set -euo pipefail

python3 - <<'PY'
from pathlib import Path
import re
import sys

root = Path("force-app/main/default/classes")
entry_annotation = re.compile(r"@(?:InvocableMethod|AuraEnabled)\b")
class_line = re.compile(r"\b(public|global)\b[^\n]*\bclass\b")
explicit_sharing = re.compile(r"\b(with|without|inherited)\s+sharing\b")

# First top-level class or interface declaration (production only).
first_type_decl = re.compile(
    r"^\s*(?:global|public)\s+(?:(?:abstract|virtual)\s+)*(?:(?:with|without|inherited)\s+sharing\s+)?(class|interface)\s+\w+",
    re.MULTILINE,
)

entry_violations = []
for path in sorted(root.glob("*.cls")):
    text = path.read_text(encoding="utf-8")
    if not entry_annotation.search(text):
        continue
    match = class_line.search(text)
    if not match:
        entry_violations.append((path, "No public/global class declaration found"))
        continue
    if not explicit_sharing.search(match.group(0)):
        entry_violations.append((path, "Missing explicit sharing on entry-point class"))

if entry_violations:
    print("Apex entry-point sharing audit failed:")
    for path, reason in entry_violations:
        print(f" - {path}: {reason}")
    sys.exit(1)

print("Apex entry-point sharing audit passed: all entry-point classes use explicit sharing.")

# All production classes (not tests): first declaration must be interface XOR explicit-sharing class.
class_violations = []
for path in sorted(root.glob("*.cls")):
    if path.name.endswith("Test.cls") or path.name.startswith("Test"):
        continue
    text = path.read_text(encoding="utf-8")
    m = first_type_decl.search(text)
    if not m:
        continue
    kind = m.group(1)
    if kind == "interface":
        continue
    line = m.group(0)
    if not explicit_sharing.search(line):
        class_violations.append(path)

if class_violations:
    print("Apex production-class sharing audit failed (add with/without/inherited sharing):")
    for path in class_violations:
        print(f" - {path}")
    sys.exit(1)

print("Apex production-class sharing audit passed: all classes declare explicit sharing.")
PY
