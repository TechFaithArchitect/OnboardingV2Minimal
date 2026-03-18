# Makefile for OnboardingV2Minimal automation scripts
# Run `make audit` to execute all automation audits, or individual targets below.

ORG_ALIAS ?= OnboardV2
ANALYSIS_DIR ?= .analysis/automation-audit

.PHONY: audit check-vpr-drift build-legacy-queue build-flow-deps check-apex-refs profile-flows build-redundancy-audit audit-fault-connectors fix-deploy

# Fix UnsafeFilepathError from cached temp path in source tracking (e.g. ../../tmp/onboardv2-training-sync-review/...)
# Run this when deploys fail with "contains unsafe character sequences"
fix-deploy:
	@echo "Removing corrupted source-tracking cache..."
	@rm -rf .sf/orgs/*/localSourceTracking 2>/dev/null || true
	@echo "Disabling source tracking for target org..."
	@sf org disable tracking --target-org $(ORG_ALIAS) 2>/dev/null || sf org disable tracking 2>/dev/null || true
	@echo "Done. Try your deploy again."

# Run all automation scripts (default target for `make audit`)
audit: check-vpr-drift build-legacy-queue build-flow-deps check-apex-refs profile-flows build-redundancy-audit audit-fault-connectors
	@echo "All automation audits complete."

# Flow fault connector audit
audit-fault-connectors:
	@echo "Auditing flow fault connectors..."
	@mkdir -p "$(ANALYSIS_DIR)"
	scripts/automation/audit-flow-fault-connectors.sh force-app/main/default/flows "$(ANALYSIS_DIR)/flow_fault_connector_audit.tsv" || true

# VPR type vs record type drift check
check-vpr-drift:
	@echo "Running VPR type / record type drift check..."
	@mkdir -p "$(ANALYSIS_DIR)"
	@$(MAKE) -s _run-check-vpr-drift 2>/dev/null || \
		scripts/automation/check-vpr-type-recordtype-drift.sh "$(ORG_ALIAS)" "$(ANALYSIS_DIR)/vpr-type-drift-$$(date +%F)" false

_run-check-vpr-drift:
	scripts/automation/check-vpr-type-recordtype-drift.sh "$(ORG_ALIAS)" "$(ANALYSIS_DIR)/vpr-type-drift-$$(date +%F)" false

# Build legacy domain queue (requires wave10 IN_DIR with active_domain_flowdefinitions.csv and active_inbound_refs_fullscope.tsv)
build-legacy-queue:
	@echo "Building legacy domain queue..."
	@mkdir -p "$(ANALYSIS_DIR)"
	@IN_DIR="$(ANALYSIS_DIR)/wave10-execution-2026-02-23"; \
	if [ -f "$$IN_DIR/active_domain_flowdefinitions.csv" ] && [ -f "$$IN_DIR/active_inbound_refs_fullscope.tsv" ]; then \
		scripts/automation/build-legacy-domain-queue.sh "$$IN_DIR" "$$IN_DIR/legacy_active_domain_queue.tsv" || true; \
	else \
		echo "Skipping build-legacy-queue: missing $$IN_DIR/active_domain_flowdefinitions.csv or active_inbound_refs_fullscope.tsv. Run build-flow-deps first."; \
	fi

# Build full-scope flow dependency map
build-flow-deps:
	@echo "Building flow dependency map..."
	@mkdir -p "$(ANALYSIS_DIR)"
	scripts/automation/build-fullscope-flow-dependency-map.sh "$(ORG_ALIAS)" "$(ANALYSIS_DIR)/fullscope-active-scan" || true

# Check Apex flow name references (requires wave12 TSV from build-legacy-queue or similar)
check-apex-refs:
	@echo "Checking Apex flow name references..."
	@mkdir -p "$(ANALYSIS_DIR)"
	@INPUT="$(ANALYSIS_DIR)/wave12-execution-2026-02-23/wave12_legacy_active_domain_queue.tsv"; \
	if [ -f "$$INPUT" ]; then \
		scripts/automation/check-apex-flow-name-references.sh "$(ORG_ALIAS)" "$$INPUT" "$(ANALYSIS_DIR)/apex_flow_name_refs.tsv" "$(ANALYSIS_DIR)/apex_flow_name_refs_errors.log" || true; \
	else \
		echo "Skipping check-apex-refs: $$INPUT not found. Run build-legacy-queue first or provide input."; \
	fi

# Profile legacy domain flows (requires wave11 TSV from build-legacy-queue)
profile-flows:
	@echo "Profiling legacy domain flows..."
	@mkdir -p "$(ANALYSIS_DIR)"
	@INPUT="$(ANALYSIS_DIR)/wave11-execution-2026-02-23/wave11_legacy_active_domain_queue.tsv"; \
	if [ -f "$$INPUT" ]; then \
		scripts/automation/profile-legacy-domain-flows.sh "$(ORG_ALIAS)" "$$INPUT" "$(ANALYSIS_DIR)/wave12_legacy_profile.tsv" "$(ANALYSIS_DIR)/wave12_legacy_profile_errors.log" || true; \
	else \
		echo "Skipping profile-flows: $$INPUT not found."; \
	fi

# Build automation redundancy audit
build-redundancy-audit:
	@echo "Building automation redundancy audit..."
	@mkdir -p "$(ANALYSIS_DIR)"
	scripts/automation/build-automation-redundancy-audit.sh "$(ORG_ALIAS)" "$(ANALYSIS_DIR)" || true
