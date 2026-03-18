# Installation Guide

## Prerequisites

- Salesforce org with appropriate API version (64.0+)
- Salesforce DX CLI installed
- Appropriate permissions to deploy metadata

## Deployment Steps

### Option 1: Automated Deployment (Recommended)

Use the provided deployment scripts for a streamlined experience:

#### 1. Clone Repository

```bash
git clone [repository-url]
cd OnboardingV2
```

#### 2. Authenticate with Salesforce

```bash
sf org login web --alias myorg
```

#### 3. Validate Metadata (Optional but Recommended)

```bash
./scripts/deploy/validate.sh myorg
```

This performs a dry-run validation to catch issues before deployment.

#### 4. Deploy Metadata

```bash
./scripts/deploy/deploy.sh myorg
```

This script:
- Deploys main/default metadata
- Provides clear success/failure feedback

#### 5. Run Tests

```bash
./scripts/deploy/run-tests.sh myorg
```

Or run specific test classes:
```bash
./scripts/deploy/run-tests.sh myorg VendorOnboardingServiceTest,OnboardingDefaultVendorProgramInvocTest
```

#### 6. Post-Deployment Configuration

```bash
./scripts/deploy/post-deploy.sh myorg
```

This verifies deployment and provides configuration reminders.

### Option 2: Manual Deployment

If you prefer manual deployment:

#### 1. Clone Repository

```bash
git clone [repository-url]
cd OnboardingV2
```

#### 2. Authenticate with Salesforce

```bash
sf org login web --alias myorg
```

#### 3. Deploy Metadata

**Deploy main/default:**
```bash
sf project deploy start --source-dir force-app/main/default --target-org myorg
```

#### 4. Run Tests

```bash
sf apex run test --class-names VendorOnboardingServiceTest,OnboardingDefaultVendorProgramInvocTest --target-org myorg
```

#### 5. Assign Permission Sets

Assign the following permission sets to users:
- `Onboarding_Account_Services`
- `Onboarding_Compliance_Team`
- `Onboarding_Program_Sales_Team`
- `Onboarding_Program_Specialists`
- `Onboarding_Customer_Service`
- `Onboarding_Finance_Team`
- (Add others as needed)

## Post-Deployment Configuration

### 1. Configure Custom Metadata

Create required custom metadata records:
- Global Value Sets
- Custom Labels

### 2. Configure Status Rules

1. Create `Vendor_Program_Group__c` records
2. Ensure `Onboarding_Status_Normalization__mdt` has the required per-requirement mappings (e.g., Agreement+signed, Contract+Complete → Setup Complete)

### 3. Set Up Record Pages

Add components to Lightning record pages:
- **Account Page**: Add `accountProgramOnboardingModal`
- **Onboarding Page**: Add `onboardingHomeDashboard` and `onboardingRequirementsPanel`

## Verification

### Verify Deployment

1. Check for deployment errors
2. Verify all components are available
3. Check permission sets are assigned

### Test Onboarding Flow

1. Open an Account
2. Launch `accountProgramOnboardingModal`
3. Create an onboarding for a Vendor Program
4. Verify requirements and status update logic

### Test Status Evaluation

1. Create an Onboarding record
2. Create requirements
3. Update requirement statuses
4. Verify onboarding status updates automatically

## Rollback Procedures

If deployment fails or you need to rollback:

### Rollback Specific Components

```bash
# Rollback specific metadata type
sf project deploy cancel --job-id [job-id] --target-org myorg
```

### Full Rollback

1. Identify the deployment job ID from the failed deployment
2. Cancel the deployment if still in progress
3. Redeploy previous version from source control
4. Verify all components are restored

### Component-Level Rollback

```bash
# Delete specific component
sf project delete source --metadata ApexClass:ClassName --target-org myorg
```

## Environment-Specific Configuration

### Sandbox Deployment

```bash
# Use sandbox-specific org alias
./scripts/deploy/deploy.sh sandbox-org
```

### Production Deployment

1. **Always validate first**:
   ```bash
   ./scripts/deploy/validate.sh production-org
   ```

2. **Run full test suite**:
   ```bash
   ./scripts/deploy/run-tests.sh production-org
   ```

3. **Deploy with test execution**:
   ```bash
   sf project deploy start --source-dir force-app/main/default --target-org production-org --test-level RunLocalTests
   ```

4. **Monitor deployment**:
   - Check deployment status
   - Review test results
   - Verify post-deployment configuration

## Troubleshooting

### Common Issues

**Deployment Errors:**
- Check API version compatibility
- Verify all dependencies are deployed
- Check for missing fields or objects
- Review validation script output

**Component Not Appearing:**
- Verify component is deployed
- Check Lightning page configuration
- Verify user has appropriate permissions
- Clear browser cache

**Status Not Updating:**
- Check rules engine configuration
- Verify requirements are linked correctly
- Check flow is active and not bypassed
- Review flow debug logs

**Script Execution Errors:**
- Ensure scripts are executable: `chmod +x scripts/deploy/*.sh`
- Verify Salesforce CLI is installed and updated
- Check org authentication status
- Review script output for specific errors

**Test Failures:**
- Review test class code
- Check for data dependencies
- Verify test data setup
- Review Apex debug logs

## Related Documentation

- [Configuration Guide](./configuration.md)
- [Sample Data Setup](./sample-data.md)
- [Architecture Overview](../architecture/overview.md)
- [Troubleshooting Guide](../user-guides/troubleshooting.md)
