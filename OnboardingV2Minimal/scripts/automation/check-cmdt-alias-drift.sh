#!/usr/bin/env bash
set -euo pipefail

CUSTOM_METADATA_DIR="${1:-force-app/main/default/customMetadata}"
shift || true

if [[ ! -d "$CUSTOM_METADATA_DIR" ]]; then
  echo "Custom metadata directory not found: $CUSTOM_METADATA_DIR" >&2
  exit 2
fi

if [[ $# -gt 0 ]]; then
  TARGET_TYPES=("$@")
else
  TARGET_TYPES=(
    "Onboarding_Default_Vendor_Program"
    "Onboarding_Fulfillment_Policy"
    "Onboarding_Status_Normalization"
  )
fi

duplicate_count=0

for type_name in "${TARGET_TYPES[@]}"; do
  base_file="$(mktemp)"
  mdt_file="$(mktemp)"
  overlap_file="$(mktemp)"

  shopt -s nullglob
  for f in "$CUSTOM_METADATA_DIR"/"${type_name}".*.md-meta.xml; do
    b="$(basename "$f")"
    rec="${b#${type_name}.}"
    rec="${rec%.md-meta.xml}"
    echo "$rec" >> "$base_file"
  done

  for f in "$CUSTOM_METADATA_DIR"/"${type_name}"__mdt.*.md-meta.xml; do
    b="$(basename "$f")"
    rec="${b#${type_name}__mdt.}"
    rec="${rec%.md-meta.xml}"
    echo "$rec" >> "$mdt_file"
  done

  sort -u -o "$base_file" "$base_file"
  sort -u -o "$mdt_file" "$mdt_file"
  comm -12 "$base_file" "$mdt_file" > "$overlap_file"

  while IFS= read -r record_name; do
    [[ -n "$record_name" ]] || continue
    duplicate_count=$((duplicate_count + 1))
    echo "DUPLICATE_ALIAS	${type_name}	${record_name}	${type_name}.${record_name}.md-meta.xml	${type_name}__mdt.${record_name}.md-meta.xml"
  done < "$overlap_file"

  rm -f "$base_file" "$mdt_file" "$overlap_file"
done

if [[ "$duplicate_count" -gt 0 ]]; then
  echo "Detected ${duplicate_count} duplicate CMDT alias record(s)." >&2
  exit 1
fi

echo "No duplicate CMDT aliases detected for target types."
