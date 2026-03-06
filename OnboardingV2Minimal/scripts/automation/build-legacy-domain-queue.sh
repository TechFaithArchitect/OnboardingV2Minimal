#!/usr/bin/env bash

set -euo pipefail

IN_DIR="${1:-.analysis/automation-audit/wave10-execution-2026-02-23}"
OUT_TSV="${2:-$IN_DIR/legacy_active_domain_queue.tsv}"

IN_CSV="$IN_DIR/active_domain_flowdefinitions.csv"
REFS_TSV="$IN_DIR/active_inbound_refs_fullscope.tsv"

if [ ! -f "$IN_CSV" ]; then
  echo "Missing input: $IN_CSV" >&2
  exit 1
fi

if [ ! -f "$REFS_TSV" ]; then
  echo "Missing input: $REFS_TSV" >&2
  exit 1
fi

CALLEE_COUNTS="$IN_DIR/.callee_counts.tsv"
ACTIVE_TARGET_NAMES="$IN_DIR/.active_target_names.txt"
RAW_ROWS="$IN_DIR/.legacy_domain_rows.tsv"

awk -F'\t' '
  NR>1 {
    if (callers[$2] == "") {
      callers[$2] = $1
    } else {
      callers[$2] = callers[$2] ";" $1
    }
    count[$2]++
  }
  END {
    for (k in count) {
      print k "\t" count[k] "\t" callers[k]
    }
  }
' "$REFS_TSV" | sort > "$CALLEE_COUNTS"

if [ -f "$IN_DIR/active_scope_names.csv" ]; then
  awk -F, 'NR>1 {print $1}' "$IN_DIR/active_scope_names.csv" | sort -u > "$ACTIVE_TARGET_NAMES"
else
  awk -F, 'NR>1 {print $1}' "$IN_CSV" | sort -u > "$ACTIVE_TARGET_NAMES"
fi

awk -F, '
  function to_target_name(legacy_name,    target) {
    # Explicit override: onboarding training status logic was consolidated into create-or-update onboarding flow.
    if (legacy_name == "DOMAIN_Onboarding_SFL_Update_Onboarding_Record_s_Training_Status") {
      return "DOMAIN_OmniSObject_SFL_CREATE_or_UPDATE_Onboarding_Record"
    }

    # Explicit override: training reminder should move to BLL scheduled flow convention.
    if (legacy_name == "DOMAIN_Training_Assignment_SFL_Training_Reminder_Emails") {
      return "BLL_Training_Assignment_SCD_Training_Reminder_Emails"
    }

    target = legacy_name
    if (target ~ /^DOMAIN_.*_SFL_/) {
      sub(/^DOMAIN_.*_SFL_/, "DOMAIN_OmniSObject_SFL_", target)
      return target
    }
    if (target ~ /^DOMAIN_.*_RCD_/) {
      sub(/^DOMAIN_/, "BLL_", target)
      return target
    }
    if (target ~ /^DOMAIN_.*_SCR_/) {
      sub(/^DOMAIN_.*_SCR_/, "DOMAIN_OmniSObject_SCR_", target)
      return target
    }
    if (target ~ /^DOMAIN_.*_ACTION_/) {
      sub(/^DOMAIN_.*_ACTION_/, "DOMAIN_OmniSObject_ACTION_", target)
      return target
    }
    # Fallback keeps the legacy tail unchanged.
    sub(/^DOMAIN_/, "DOMAIN_OmniSObject_", target)
    return target
  }

  NR>1 && $1 !~ /^DOMAIN_OmniSObject/ {
    legacy = $1
    lm = $4
    by = $5
    target = to_target_name(legacy)
    print legacy "\t" lm "\t" by "\t" target
  }
' "$IN_CSV" > "$RAW_ROWS"

echo -e "LegacyFlow\tLastModifiedDate\tLastModifiedBy\tInboundCallerCount\tInboundCallers\tSuggestedTargetFlow\tSuggestedTargetActive" > "$OUT_TSV"

while IFS=$'\t' read -r legacy lm by target; do
  hit="$(awk -F'\t' -v key="$legacy" '$1==key {print $2 "\t" $3}' "$CALLEE_COUNTS")"
  if [ -n "$hit" ]; then
    cnt="${hit%%$'\t'*}"
    callers="${hit#*$'\t'}"
  else
    cnt="0"
    callers=""
  fi

  if grep -Fxq "$target" "$ACTIVE_TARGET_NAMES"; then
    active="Y"
  else
    active="N"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$legacy" "$lm" "$by" "$cnt" "$callers" "$target" "$active"
done < "$RAW_ROWS" | sort -t $'\t' -k4,4nr -k1,1 >> "$OUT_TSV"
