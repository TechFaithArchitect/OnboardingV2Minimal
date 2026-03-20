#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG="${SCRIPT_DIR}/scenarios/org-happy-path.json"
TEMPLATE_PATH="${SCRIPT_DIR}/templates/run-org-happy-path.apex.tmpl"

CONFIG_PATH="${DEFAULT_CONFIG}"
ORG_ALIAS=""

vendor_program_id=""
requirement_id=""
requirement_type=""
onboarding_id=""
opportunity_id=""
account_id=""

usage() {
  cat <<'EOF'
Usage:
  run-configurable-org-happy-path.sh [--org <alias>] [--config <path>]

Options:
  --org      Salesforce org alias. Defaults to .targetOrg in config, then OnboardV2.
  --config   Scenario JSON path. Defaults to scripts/simulation/scenarios/org-happy-path.json.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org)
      ORG_ALIAS="${2:-}"
      shift 2
      ;;
    --config)
      CONFIG_PATH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "Config file not found: $CONFIG_PATH" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE_PATH" ]]; then
  echo "Template file not found: $TEMPLATE_PATH" >&2
  exit 1
fi

if ! command -v sf >/dev/null 2>&1; then
  echo "Error: Salesforce CLI (sf) is not installed or not on PATH." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required." >&2
  exit 1
fi

scenario_name="$(jq -r '.scenarioName // "org-happy-path"' "$CONFIG_PATH")"
if [[ -z "$ORG_ALIAS" ]]; then
  ORG_ALIAS="$(jq -r '.targetOrg // "OnboardV2"' "$CONFIG_PATH")"
fi

run_soql_json() {
  local soql="$1"
  sf data query --target-org "$ORG_ALIAS" --query "$soql" --json
}

replace_tokens() {
  local text="$1"
  text="${text//'{{vendorProgramId}}'/${vendor_program_id}}"
  text="${text//'{{requirementId}}'/${requirement_id}}"
  text="${text//'{{requirementType}}'/${requirement_type}}"
  text="${text//'{{onboardingId}}'/${onboarding_id}}"
  text="${text//'{{opportunityId}}'/${opportunity_id}}"
  text="${text//'{{accountId}}'/${account_id}}"
  printf '%s' "$text"
}

compare_values() {
  local operator="$1"
  local actual="$2"
  local expected="$3"

  case "$operator" in
    eq) [[ "$actual" == "$expected" ]] ;;
    ne) [[ "$actual" != "$expected" ]] ;;
    contains) [[ "$actual" == *"$expected"* ]] ;;
    not_contains) [[ "$actual" != *"$expected"* ]] ;;
    gt|gte|lt|lte)
      awk -v op="$operator" -v a="$actual" -v b="$expected" '
        BEGIN {
          av = a + 0;
          bv = b + 0;
          if (op == "gt")  exit !(av >  bv);
          if (op == "gte") exit !(av >= bv);
          if (op == "lt")  exit !(av <  bv);
          if (op == "lte") exit !(av <= bv);
          exit 1;
        }'
      ;;
    *)
      echo "Unsupported operator: $operator" >&2
      return 2
      ;;
  esac
}

echo "Scenario: ${scenario_name}"
echo "Target org: ${ORG_ALIAS}"
echo "Config: ${CONFIG_PATH}"
echo

# Resolve vendor program from org data if not explicitly provided.
vendor_program_id="$(jq -r '.inputs.vendorProgramId // empty' "$CONFIG_PATH")"
if [[ -z "$vendor_program_id" ]]; then
  vendor_program_soql="$(jq -r '.selection.vendorProgramSoql // "SELECT Id, Vendor__c FROM Vendor_Customization__c WHERE Active__c = true AND Vendor__c != null ORDER BY LastModifiedDate DESC LIMIT 1"' "$CONFIG_PATH")"
  vendor_program_soql="$(replace_tokens "$vendor_program_soql")"
  vendor_program_response="$(run_soql_json "$vendor_program_soql")"
  vendor_program_id="$(jq -r '.result.records[0].Id // empty' <<<"$vendor_program_response")"
else
  vendor_program_response="$(run_soql_json "SELECT Id, Vendor__c FROM Vendor_Customization__c WHERE Id = '${vendor_program_id}' LIMIT 1")"
fi

if [[ -z "$vendor_program_id" ]]; then
  echo "Failed: could not resolve vendor program from org data." >&2
  exit 1
fi

# Resolve requirement from org data if not explicitly provided.
requirement_id="$(jq -r '.inputs.requirementId // empty' "$CONFIG_PATH")"
requirement_type="$(jq -r '.inputs.requirementType // empty' "$CONFIG_PATH")"
if [[ -z "$requirement_id" ]]; then
  requirement_soql="$(jq -r '.selection.requirementSoql // "SELECT Id, Requirement_Type__c FROM Vendor_Program_Requirement__c WHERE Vendor_Program__c = '\''{{vendorProgramId}}'\'' AND Active__c = true ORDER BY Sequence__c ASC LIMIT 1"' "$CONFIG_PATH")"
  requirement_soql="$(replace_tokens "$requirement_soql")"
  requirement_response="$(run_soql_json "$requirement_soql")"
else
  requirement_response="$(run_soql_json "SELECT Id, Requirement_Type__c FROM Vendor_Program_Requirement__c WHERE Id = '${requirement_id}' LIMIT 1")"
fi

requirement_id="$(jq -r '.result.records[0].Id // empty' <<<"$requirement_response")"
if [[ -z "$requirement_id" ]]; then
  echo "Failed: could not resolve requirement from org data." >&2
  exit 1
fi

if [[ -z "$requirement_type" ]]; then
  requirement_type="$(jq -r '.result.records[0].Requirement_Type__c // empty' <<<"$requirement_response")"
fi

account_id="$(jq -r '.inputs.accountId // empty' "$CONFIG_PATH")"
if [[ -n "$account_id" ]]; then
  run_soql_json "SELECT Id FROM Account WHERE Id = '${account_id}' LIMIT 1" >/dev/null
fi

opportunity_stage_name="$(jq -r '.inputs.opportunityStageName // "Prospecting"' "$CONFIG_PATH")"
close_date_offset_days="$(jq -r '.inputs.closeDateOffsetDays // 14' "$CONFIG_PATH")"
program_base_selection="$(jq -r '.inputs.programBaseSelection // empty' "$CONFIG_PATH")"
program_type="$(jq -r '.inputs.programType // empty' "$CONFIG_PATH")"

expect_creation_completed="$(jq -r '.expectations.creationCompleted // true' "$CONFIG_PATH")"
min_requirement_count="$(jq -r '.expectations.minRequirementCount // 1' "$CONFIG_PATH")"
min_subject_count="$(jq -r '.expectations.minSubjectCount // 0' "$CONFIG_PATH")"
require_seeded_requirement="$(jq -r '.expectations.requireSeededRequirement // true' "$CONFIG_PATH")"

payload_json="$(jq -n \
  --arg scenarioName "$scenario_name" \
  --arg accountId "$account_id" \
  --arg vendorProgramId "$vendor_program_id" \
  --arg requirementId "$requirement_id" \
  --arg requirementType "$requirement_type" \
  --arg opportunityStageName "$opportunity_stage_name" \
  --arg programBaseSelection "$program_base_selection" \
  --arg programType "$program_type" \
  --argjson closeDateOffsetDays "$close_date_offset_days" \
  --argjson expectCreationCompleted "$expect_creation_completed" \
  --argjson minRequirementCount "$min_requirement_count" \
  --argjson minSubjectCount "$min_subject_count" \
  --argjson requireSeededRequirement "$require_seeded_requirement" \
  '{
    scenarioName: $scenarioName,
    accountId: $accountId,
    vendorProgramId: $vendorProgramId,
    requirementId: $requirementId,
    requirementType: $requirementType,
    opportunityStageName: $opportunityStageName,
    closeDateOffsetDays: $closeDateOffsetDays,
    programBaseSelection: $programBaseSelection,
    programType: $programType,
    expectCreationCompleted: $expectCreationCompleted,
    minRequirementCount: $minRequirementCount,
    minSubjectCount: $minSubjectCount,
    requireSeededRequirement: $requireSeededRequirement
  }')"

payload_base64="$(printf '%s' "$payload_json" | base64 | tr -d '\n')"
tmp_apex="$(mktemp "${TMPDIR:-/tmp}/org-happy-path-XXXXXX.apex")"
trap 'rm -f "$tmp_apex"' EXIT

sed "s#__PAYLOAD_BASE64__#${payload_base64}#g" "$TEMPLATE_PATH" > "$tmp_apex"

echo "Executing simulation interview chain..."
if ! apex_response="$(sf apex run --target-org "$ORG_ALIAS" --file "$tmp_apex" --json)"; then
  echo "Failed: apex execution command returned non-zero status." >&2
  exit 1
fi

compiled="$(jq -r '.result.compiled // false' <<<"$apex_response")"
success="$(jq -r '.result.success // false' <<<"$apex_response")"
if [[ "$compiled" != "true" || "$success" != "true" ]]; then
  echo "Simulation Apex failed to compile/execute." >&2
  echo "Compile problem: $(jq -r '.result.compileProblem // empty' <<<"$apex_response")" >&2
  echo "Exception: $(jq -r '.result.exceptionMessage // empty' <<<"$apex_response")" >&2
  exit 1
fi

logs="$(jq -r '.result.logs // ""' <<<"$apex_response")"
simulation_line="$(printf '%s\n' "$logs" | grep 'SIMULATION_RESULT_JSON=' | tail -n 1 || true)"
if [[ -z "$simulation_line" ]]; then
  echo "Failed: SIMULATION_RESULT_JSON not found in Apex logs." >&2
  exit 1
fi

simulation_result_json="${simulation_line#*SIMULATION_RESULT_JSON=}"
if ! jq -e . >/dev/null 2>&1 <<<"$simulation_result_json"; then
  echo "Failed: simulation result JSON is not valid." >&2
  echo "$simulation_result_json" >&2
  exit 1
fi

onboarding_id="$(jq -r '.onboardingId // empty' <<<"$simulation_result_json")"
opportunity_id="$(jq -r '.opportunityId // empty' <<<"$simulation_result_json")"
account_id="$(jq -r '.accountId // empty' <<<"$simulation_result_json")"
vendor_program_id="$(jq -r '.vendorProgramId // empty' <<<"$simulation_result_json")"
requirement_id="$(jq -r '.requirementId // empty' <<<"$simulation_result_json")"
requirement_type="$(jq -r '.requirementType // empty' <<<"$simulation_result_json")"

assertion_count="$(jq '.assertions // [] | length' "$CONFIG_PATH")"
failures=0

if [[ "$assertion_count" -gt 0 ]]; then
  echo
  echo "Running ${assertion_count} post-run assertion(s)..."
fi

for ((i = 0; i < assertion_count; i++)); do
  assertion_name="$(jq -r ".assertions[$i].name // \"assertion-$((i + 1))\"" "$CONFIG_PATH")"
  assertion_soql_template="$(jq -r ".assertions[$i].soql // empty" "$CONFIG_PATH")"
  assertion_operator="$(jq -r ".assertions[$i].operator // \"eq\"" "$CONFIG_PATH")"
  assertion_expected_raw="$(jq -r ".assertions[$i].expected // empty" "$CONFIG_PATH")"
  assertion_actual_field="$(jq -r ".assertions[$i].actualField // empty" "$CONFIG_PATH")"

  if [[ -z "$assertion_soql_template" ]]; then
    echo "FAIL: ${assertion_name} (missing SOQL)" >&2
    failures=$((failures + 1))
    continue
  fi

  assertion_soql="$(replace_tokens "$assertion_soql_template")"
  assertion_expected="$(replace_tokens "$assertion_expected_raw")"
  assertion_response="$(run_soql_json "$assertion_soql")"

  if [[ "$assertion_actual_field" == "__totalSize__" ]]; then
    assertion_actual="$(jq -r '.result.totalSize // 0' <<<"$assertion_response")"
  elif [[ -n "$assertion_actual_field" ]]; then
    assertion_actual="$(jq -r --arg f "$assertion_actual_field" '.result.records[0][$f] // empty' <<<"$assertion_response")"
  else
    assertion_actual="$(jq -r '.result.records[0] | to_entries | map(select(.key != "attributes")) | .[0].value // empty' <<<"$assertion_response")"
  fi

  if compare_values "$assertion_operator" "$assertion_actual" "$assertion_expected"; then
    echo "PASS: ${assertion_name} (actual=${assertion_actual}, expected ${assertion_operator} ${assertion_expected})"
  else
    echo "FAIL: ${assertion_name} (actual=${assertion_actual}, expected ${assertion_operator} ${assertion_expected})" >&2
    failures=$((failures + 1))
  fi
done

echo
echo "Simulation result:"
jq . <<<"$simulation_result_json"

if [[ "$failures" -gt 0 ]]; then
  echo
  echo "Scenario failed with ${failures} failed assertion(s)." >&2
  exit 1
fi

echo
echo "Scenario passed."
