# Makefile for OnboardingV2Minimal automation scripts
# Run `make audit` to execute all automation audits, or individual targets below.

ORG_ALIAS ?= OnboardV2
ANALYSIS_DIR ?= .analysis/automation-audit
BEST_PRACTICES_SOURCE ?= docs/implementation-notes/best-practices-review-2026-03-12/full-original.md
BEST_PRACTICES_DIR ?= docs/implementation-notes/best-practices-review-2026-03-12

.PHONY: audit check-vpr-drift check-cmdt-alias-drift canonicalize-onboarding-cmdt-aliases validate-focal-flow-error-paths build-legacy-queue build-flow-deps check-apex-refs profile-flows build-redundancy-audit audit-fault-connectors audit-flow-loop-shape audit-flow-loop-connectors audit-onboarding-status-owner audit-subflow-error-contracts audit-screen-flow-fault-user-messaging audit-fault-message-context-contract fix-deploy deploy-default-vendor-program refresh-best-practices-docs simulate-onboarding-opportunity simulate-org-happy-path

# Fix UnsafeFilepathError from cached temp path in source tracking (e.g. ../../tmp/onboardv2-training-sync-review/...)
# Run this when deploys fail with "contains unsafe character sequences"
fix-deploy:
	@echo "Removing corrupted source-tracking cache..."
	@rm -rf .sf/orgs/*/localSourceTracking 2>/dev/null || true
	@echo "Disabling source tracking for target org..."
	@sf org disable tracking --target-org $(ORG_ALIAS) 2>/dev/null || sf org disable tracking 2>/dev/null || true
	@echo "Done. Try your deploy again."

# Deploy Default Vendor Program components (bypasses VS Code extension - use when UI deploy fails)
deploy-default-vendor-program:
	@echo "Deploying Onboarding Default Vendor Program (Apex, CMDT field, CMDT record)..."
	@sf project deploy start --manifest manifest/deploy-default-vendor-program.xml --target-org $(ORG_ALIAS)

# Run all automation scripts (default target for `make audit`)
audit: check-vpr-drift check-cmdt-alias-drift validate-focal-flow-error-paths build-legacy-queue build-flow-deps check-apex-refs profile-flows build-redundancy-audit audit-fault-connectors audit-flow-loop-shape audit-flow-loop-connectors audit-onboarding-status-owner audit-subflow-error-contracts audit-screen-flow-fault-user-messaging audit-fault-message-context-contract
	@echo "All automation audits complete."

# CMDT alias drift check (Onboarding-focused)
check-cmdt-alias-drift:
	@echo "Checking onboarding CMDT alias drift..."
	scripts/automation/check-cmdt-alias-drift.sh force-app/main/default/customMetadata

# Canonicalize onboarding CMDT aliases to __mdt naming
canonicalize-onboarding-cmdt-aliases:
	@echo "Canonicalizing onboarding CMDT aliases..."
	scripts/automation/canonicalize-onboarding-cmdt-aliases.sh force-app/main/default/customMetadata

# Validate focal flow error propagation and fault-path assertions
validate-focal-flow-error-paths:
	@echo "Validating focal flow error paths..."
	scripts/automation/validate-focal-flow-error-paths.sh force-app/main/default/flows

# Flow fault connector audit
audit-fault-connectors:
	@echo "Auditing flow fault connectors..."
	@mkdir -p "$(ANALYSIS_DIR)"
	scripts/automation/audit-flow-fault-connectors.sh force-app/main/default/flows "$(ANALYSIS_DIR)/flow_fault_connector_audit.tsv" || true

# Flow loop-shape audit (in-loop lookup/DML reference detection)
audit-flow-loop-shape:
	@echo "Auditing flow loop shape..."
	@mkdir -p "$(ANALYSIS_DIR)"
	scripts/automation/audit-flow-loop-shape.sh force-app/main/default/flows "$(ANALYSIS_DIR)" || true

# Flow loop connector-target audit
audit-flow-loop-connectors:
	@echo "Auditing flow loop connector targets..."
	@mkdir -p "$(ANALYSIS_DIR)"
	scripts/automation/audit-flow-loop-connectors.sh force-app/main/default/flows "$(ANALYSIS_DIR)/flow_loop_connector_audit.tsv" || true

# Onboarding status single-owner audit (direct write detection)
audit-onboarding-status-owner:
	@echo "Auditing onboarding status owner-write enforcement..."
	@mkdir -p "$(ANALYSIS_DIR)"
	scripts/automation/audit-onboarding-status-owner-writes.sh force-app/main/default/flows force-app/main/default/classes "$(ANALYSIS_DIR)/onboarding_status_owner_audit.tsv" || true

# Subflow error-contract audit (called flow exposes errorMessage output but parent does not map it)
audit-subflow-error-contracts:
	@echo "Auditing subflow error-message output contracts..."
	@mkdir -p "$(ANALYSIS_DIR)"
	scripts/automation/audit-subflow-error-contracts.sh force-app/main/default/flows "$(ANALYSIS_DIR)/subflow_error_contract_audit.tsv" || true

# Screen-flow fault UX contract audit (user-safe message + context inputs)
audit-screen-flow-fault-user-messaging:
	@echo "Auditing screen-flow fault user-messaging contract..."
	@mkdir -p "$(ANALYSIS_DIR)"
	scripts/automation/audit-screen-flow-fault-user-messaging.sh force-app/main/default/flows "$(ANALYSIS_DIR)/screen_flow_fault_user_messaging_audit.tsv" || true

# Global fault-message subflow context contract audit (all flow types, deferred flow excluded)
audit-fault-message-context-contract:
	@echo "Auditing global fault-message context contract..."
	@mkdir -p "$(ANALYSIS_DIR)"
	scripts/automation/audit-fault-message-context-contract.sh force-app/main/default/flows "$(ANALYSIS_DIR)/fault_message_context_contract_audit.tsv" || true

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

# Refresh split best-practices docs from the source plan
refresh-best-practices-docs:
	@echo "Refreshing best-practices split docs..."
	scripts/automation/refresh-best-practices-review-docs.sh "$(BEST_PRACTICES_SOURCE)" "$(BEST_PRACTICES_DIR)"

# Run end-to-end onboarding simulation (account -> opportunity -> onboarding -> requirements)
simulate-onboarding-opportunity:
	@echo "Running onboarding opportunity simulation..."
	bash scripts/simulation/run-account-onboarding-through-opportunity.sh "$(ORG_ALIAS)"

# Run configurable org-data happy-path simulation + post-run assertions
simulate-org-happy-path:
	@echo "Running configurable org-data happy-path simulation..."
	bash scripts/simulation/run-configurable-org-happy-path.sh --org "$(ORG_ALIAS)"
