#!/bin/bash

# Run all Apex test classes in the main package (force-app/main/default/classes)
# Usage: ./scripts/deploy/run-main-tests.sh [org-alias] [--exclude Class1,Class2]
#
# Examples:
#   ./scripts/deploy/run-main-tests.sh OnboardV2
#   ./scripts/deploy/run-main-tests.sh OnboardV2 --exclude FollowUpExecutionServiceTest

set -e

ORG_ALIAS=${1:-myorg}
EXCLUDE_CLASSES=""

# Check for exclude flag
if [ "$2" == "--exclude" ] && [ -n "$3" ]; then
    EXCLUDE_CLASSES="$3"
fi

# Get all test class names from main package (just the class name, not the path)
CLASS_NAMES=$(find force-app/main/default/classes -name "*Test.cls" -type f | \
    xargs -I {} basename {} .cls | \
    sort)

# Filter out excluded classes if specified
if [ -n "$EXCLUDE_CLASSES" ]; then
    echo "Excluding classes: $EXCLUDE_CLASSES"
    IFS=',' read -ra EXCLUDE_ARRAY <<< "$EXCLUDE_CLASSES"
    for exclude in "${EXCLUDE_ARRAY[@]}"; do
        CLASS_NAMES=$(echo "$CLASS_NAMES" | grep -v "^${exclude}$")
    done
fi

TEST_COUNT=$(echo "$CLASS_NAMES" | wc -l | tr -d ' ')
echo "=========================================="
echo "Found $TEST_COUNT test classes in main package:"
echo "=========================================="
echo "$CLASS_NAMES" | nl
echo ""
echo "Running tests..."
echo ""
echo "Note: Classes that aren't deployed or have compilation errors will be skipped."
echo ""

# Build command with multiple --class-names flags (new array format required by CLI)
# Convert class names to array and build command with repeated --class-names flags
CMD_ARGS=()
while IFS= read -r class; do
    [ -n "$class" ] && CMD_ARGS+=("--class-names" "$class")
done <<< "$CLASS_NAMES"

# Execute the command with proper array handling
# Continue even if some classes fail (they'll be skipped by Salesforce)
sf apex run test \
    "${CMD_ARGS[@]}" \
    --target-org "$ORG_ALIAS" \
    --result-format human \
    --code-coverage \
    --wait 10 || {
    echo ""
    echo "Some test classes may have failed or been skipped."
    echo "Check the output above for details."
    exit 1
}

