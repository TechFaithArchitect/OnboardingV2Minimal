#!/usr/bin/env bash
set -euo pipefail

CUSTOM_METADATA_DIR="${1:-force-app/main/default/customMetadata}"

if [[ ! -d "$CUSTOM_METADATA_DIR" ]]; then
  echo "Custom metadata directory not found: $CUSTOM_METADATA_DIR" >&2
  exit 2
fi

TARGET_TYPES=(
  "Onboarding_Default_Vendor_Program"
  "Onboarding_Fulfillment_Policy"
  "Onboarding_Status_Normalization"
)

removed_aliases=0
migrated_records=0

shopt -s nullglob
for type_name in "${TARGET_TYPES[@]}"; do
  for src in "$CUSTOM_METADATA_DIR"/"${type_name}".*.md-meta.xml; do
    b="$(basename "$src")"
    record_name="${b#${type_name}.}"
    record_name="${record_name%.md-meta.xml}"
    canonical="$CUSTOM_METADATA_DIR/${type_name}__mdt.${record_name}.md-meta.xml"

    if [[ -f "$canonical" ]]; then
      if ! cmp -s "$src" "$canonical"; then
        echo "Info: differing alias pair detected for ${type_name}.${record_name}; keeping canonical __mdt file."
      fi
      rm -f "$src"
      removed_aliases=$((removed_aliases + 1))
    else
      mv "$src" "$canonical"
      migrated_records=$((migrated_records + 1))
    fi
  done
done

echo "Canonicalization complete."
echo "Removed duplicate alias files: ${removed_aliases}"
echo "Migrated base-only records to __mdt: ${migrated_records}"

scripts/automation/check-cmdt-alias-drift.sh "$CUSTOM_METADATA_DIR" "${TARGET_TYPES[@]}"
