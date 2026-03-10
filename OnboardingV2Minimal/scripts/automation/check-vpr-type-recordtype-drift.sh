#!/usr/bin/env bash

set -euo pipefail

ORG_ALIAS_RAW="${1:-OnboardV2}"
OUT_DIR="${2:-.analysis/automation-audit/nightly-vpr-type-drift-$(date +%F)}"
FAIL_ON_DRIFT="${3:-true}" # true|false

# Normalize user-provided org argument to avoid hidden newline/CR issues.
ORG_ALIAS="$(printf '%s' "$ORG_ALIAS_RAW" | tr -d '\r' | xargs)"

mkdir -p "$OUT_DIR"

ERROR_LOG="$OUT_DIR/errors.log"
VPR_JSON="$OUT_DIR/vendor_program_requirement_types.json"
RT_JSON="$OUT_DIR/onboarding_requirement_recordtypes.json"
TYPE_LIST="$OUT_DIR/vendor_program_requirement_type_values.txt"
RT_LIST="$OUT_DIR/onboarding_requirement_recordtype_names_active.txt"
MISSING_TYPES="$OUT_DIR/vpr_types_missing_onboarding_recordtype.txt"
UNUSED_RECORDTYPES="$OUT_DIR/onboarding_recordtypes_without_vpr_usage.txt"
SUMMARY_TSV="$OUT_DIR/vpr_type_recordtype_drift_summary.tsv"
RUN_METADATA="$OUT_DIR/run_metadata.txt"

: > "$ERROR_LOG"

TARGET_ORG="$ORG_ALIAS"

query_vpr_types() {
  local field_name="$1"
  sf data query -o "$TARGET_ORG" \
    --query "SELECT ${field_name}, COUNT(Id) FROM Vendor_Program_Requirement__c WHERE ${field_name} != null GROUP BY ${field_name} ORDER BY ${field_name}" \
    --json > "$VPR_JSON" 2>> "$ERROR_LOG"
}

FIELD_USED="Requirement_Type__c"
if ! query_vpr_types "$FIELD_USED"; then
  FIELD_USED="Type__c"
  if ! query_vpr_types "$FIELD_USED"; then
    echo "Unable to query Vendor_Program_Requirement__c by Requirement_Type__c or Type__c." >&2
    echo "See: $ERROR_LOG" >&2
    exit 1
  fi
fi

if ! sf data query -o "$TARGET_ORG" --use-tooling-api \
  --query "SELECT Id, Name, SobjectType, IsActive FROM RecordType WHERE SobjectType = 'Onboarding_Requirement__c'" \
  --json > "$RT_JSON" 2>> "$ERROR_LOG"; then
  echo "Unable to query Onboarding_Requirement__c record types." >&2
  echo "See: $ERROR_LOG" >&2
  exit 1
fi

jq -r --arg f "$FIELD_USED" '.result.records[] | .[$f]' "$VPR_JSON" \
  | sed '/^null$/d;/^$/d' \
  | sort -u > "$TYPE_LIST"

jq -r '.result.records[] | select(.IsActive == true) | .Name' "$RT_JSON" \
  | sed '/^null$/d;/^$/d' \
  | sort -u > "$RT_LIST"

comm -23 "$TYPE_LIST" "$RT_LIST" > "$MISSING_TYPES"
comm -13 "$TYPE_LIST" "$RT_LIST" > "$UNUSED_RECORDTYPES"

echo -e "RequirementType\tVPRCount\tHasActiveOnboardingRequirementRecordType\tMatchingRecordTypeName" > "$SUMMARY_TSV"

while IFS= read -r requirement_type; do
  [ -z "$requirement_type" ] && continue

  type_count="$(
    jq -r --arg f "$FIELD_USED" --arg t "$requirement_type" \
      '.result.records[] | select(.[$f] == $t) | .expr0' "$VPR_JSON" \
      | head -n 1
  )"

  if grep -Fxq "$requirement_type" "$RT_LIST"; then
    has_match="Y"
  else
    has_match="N"
  fi

  printf "%s\t%s\t%s\t%s\n" \
    "$requirement_type" \
    "${type_count:-0}" \
    "$has_match" \
    "$requirement_type" >> "$SUMMARY_TSV"
done < "$TYPE_LIST"

missing_count="$(wc -l < "$MISSING_TYPES" | tr -d ' ')"
unused_count="$(wc -l < "$UNUSED_RECORDTYPES" | tr -d ' ')"

{
  echo "org_alias=$ORG_ALIAS"
  echo "target_org_used=$TARGET_ORG"
  echo "field_used=$FIELD_USED"
  echo "generated_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "missing_type_count=$missing_count"
  echo "unused_active_recordtype_count=$unused_count"
  echo "summary_tsv=$SUMMARY_TSV"
  echo "missing_types_file=$MISSING_TYPES"
  echo "unused_recordtypes_file=$UNUSED_RECORDTYPES"
  echo "error_log=$ERROR_LOG"
} > "$RUN_METADATA"

echo "Drift check complete."
echo "Org alias: $ORG_ALIAS"
echo "Target org used: $TARGET_ORG"
echo "Field used: $FIELD_USED"
echo "Missing type-to-recordtype mappings: $missing_count"
echo "Unused active Onboarding Requirement record types: $unused_count"
echo "Output directory: $OUT_DIR"

if [ "$missing_count" -gt 0 ] && [ "$FAIL_ON_DRIFT" = "true" ]; then
  echo "Drift detected. Failing with exit code 2."
  exit 2
fi

exit 0
