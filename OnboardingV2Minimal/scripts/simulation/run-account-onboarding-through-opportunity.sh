#!/usr/bin/env bash

set -euo pipefail

ORG_ALIAS="${1:-OnboardV2}"
SCRIPT_PATH="scripts/simulation/account-onboarding-through-opportunity.apex"

if ! command -v sf >/dev/null 2>&1; then
  echo "Error: Salesforce CLI (sf) is not installed or not on PATH." >&2
  exit 1
fi

echo "Running end-to-end onboarding simulation against org alias: ${ORG_ALIAS}"
echo "Apex script: ${SCRIPT_PATH}"
echo

sf apex run --target-org "${ORG_ALIAS}" --file "${SCRIPT_PATH}"

echo
echo "Simulation finished. Search the Apex output for SIMULATION_RESULT_JSON and SIMULATION_COMPLETE."
