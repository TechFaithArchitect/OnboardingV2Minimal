#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_FILE="${1:-$ROOT_DIR/docs/implementation-notes/best-practices-review-2026-03-12/full-original.md}"
OUT_DIR="${2:-$ROOT_DIR/docs/implementation-notes/best-practices-review-2026-03-12}"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Source file not found: $SOURCE_FILE" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

CHECKLIST_FILE="$OUT_DIR/checklist.md"
EXECUTION_LOG_FILE="$OUT_DIR/execution-log.md"
IN_PROGRESS_FILE="$OUT_DIR/in-progress.md"

cat > "$CHECKLIST_FILE" <<'EOT'
# Best-Practices Review Checklist (2026-03-12)

Checkbox status list extracted from the source plan.
EOT

awk '
/^## / { heading = $0 }
$0 ~ /^- \[[ x]\]/ {
  if (heading != last_heading) {
    print ""
    print heading
    last_heading = heading
  }
  print $0
}
' "$SOURCE_FILE" >> "$CHECKLIST_FILE"

cat > "$EXECUTION_LOG_FILE" <<'EOT'
# Best-Practices Review Execution Log (2026-03-12)

Chronological implementation and validation log.
EOT

awk '
/^## Execution Log/ { in_section = 1 }
/^## A\. Apex/ { in_section = 0 }
in_section { print }
' "$SOURCE_FILE" >> "$EXECUTION_LOG_FILE"

cat > "$IN_PROGRESS_FILE" <<'EOT'
# Best-Practices Review In-Progress Tracker (2026-03-12)

Active work items extracted from the source plan.
EOT

awk '
/^## / { heading = $0 }
index($0, "In progress:") > 0 {
  if (heading != last_heading) {
    print ""
    print heading
    last_heading = heading
  }
  line = $0
  sub(/^[[:space:]]*/, "", line)
  if (line !~ /^- /) {
    line = "- " line
  }
  print line
}
' "$SOURCE_FILE" >> "$IN_PROGRESS_FILE"

echo "Refreshed docs from source: $SOURCE_FILE"
echo "- $CHECKLIST_FILE"
echo "- $EXECUTION_LOG_FILE"
echo "- $IN_PROGRESS_FILE"
