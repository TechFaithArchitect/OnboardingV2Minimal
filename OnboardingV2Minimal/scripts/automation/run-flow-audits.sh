#!/usr/bin/env bash

set -euo pipefail

if [[ -f "docs/implementation-notes/best-practices-review-2026-03-12/full-original.md" ]]; then
  bash scripts/automation/refresh-best-practices-review-docs.sh
else
  echo "Skipping refresh-best-practices-review-docs.sh (legacy source file not found)."
fi

bash scripts/automation/audit-screen-flow-fault-user-messaging.sh
bash scripts/automation/audit-subflow-error-contracts.sh
bash scripts/automation/audit-flow-subflow-no-fault-connector.sh
