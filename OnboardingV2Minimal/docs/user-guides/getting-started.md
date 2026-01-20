# Getting Started with Onboarding V2

Welcome to Onboarding V2! This guide will help you get started with the onboarding system.

## What is Onboarding V2?

Onboarding V2 is a comprehensive, metadata-driven system for managing vendor program onboarding processes in Salesforce. It provides a flexible, configurable framework for guiding users through structured onboarding flows with full auditability and progress tracking.

## Terminology (Quick Reference)

- Dealer = Account.
- Program Specialist (Sales): starts onboarding for Dealers and links them to Vendor Programs.
- Program Manager: configures Vendor Programs, requirements, and rules.
- Onboarding Manager (Account Services): drives requirement completion with Dealers.

See [Terminology](../README.md#terminology) for full definitions.

See [User Journey Summary](./user-journey-summary.md) for the end-to-end flow.

## Key Features

- **Metadata-Driven Workflows**: Configure onboarding processes without code changes
- **Progress Tracking**: Monitor onboarding progress in real-time
- **Status Rules Engine**: Automatically evaluate and update onboarding status based on requirements
- **Audit Trail**: Complete history of all onboarding activities
- **Flexible Configuration**: Customize onboarding flows for different vendor programs

## Accessing the Onboarding System

### From the Home Dashboard (Recommended)

1. Navigate to your **Home** page
2. The **Vendor Onboarding Dashboard** provides a comprehensive overview:
   - **Summary Cards**: View total counts of onboarding records by status
   - **My Active Onboarding**: See all active onboarding records you created
   - **Eligible Accounts**: Find accounts that can start new onboarding
   - **Recent Activity**: View your recent onboarding activity
3. Click **Start New Onboarding** to begin a new process
4. Use row actions to view, resume, or start onboarding for specific records

### From a Vendor Program Record

1. Navigate to a **Vendor Program** record
2. The onboarding flow component appears automatically on the record page
3. If you don't see it, contact your administrator to add the `vendorProgramOnboardingFlow` component to the page

### From an Onboarding Record

1. Navigate to an **Onboarding** record
2. Use the **Requirements Panel** to view and update requirement statuses
3. The system automatically evaluates status based on your requirement updates

## Basic Workflow

1. **Start Onboarding**: 
   - From the Home Dashboard, click **Start New Onboarding** and select a Dealer (Account)
   - Or navigate directly to a Vendor Program record
2. **Complete Stages**: Follow the guided flow through each stage
3. **Update Requirements**: Mark requirements as complete as you progress
4. **Monitor Status**: 
   - Watch the onboarding status update automatically
   - Use the Home Dashboard to track all your active onboarding records
5. **Complete**: Finish all stages and requirements

## Common Tasks

### Starting a New Onboarding

**Option 1: From Home Dashboard (Recommended)**
1. Go to your **Home** page with the Vendor Onboarding Dashboard
2. Click **Start New Onboarding** button
3. Select a Dealer (Account) from the modal
4. Navigate to the Dealer (Account) record and use the Quick Action to select vendor programs

**Option 2: From Vendor Program Record**
1. Navigate directly to a Vendor Program record
2. The onboarding flow will appear if a process is assigned
3. Click through each stage to complete the onboarding

### Updating Requirement Status

1. Navigate to the Onboarding record
2. Find the Requirements Panel
3. Select a new status from the dropdown for each requirement
4. Click **Submit** to save changes
5. The system will automatically re-evaluate the onboarding status

### Viewing Onboarding Progress

- Progress is shown in the onboarding flow component
- Each completed stage is marked
- Current stage is highlighted

## Next Steps

- [Onboarding Workflow Guide](./onboarding-workflow.md) - Detailed step-by-step process
- [Managing Requirements](./managing-requirements.md) - How to work with requirements
- [Configuring Rules](./configuring-rules.md) - Setting up status rules
- [Troubleshooting](./troubleshooting.md) - Common issues and solutions

## Need Help?

If you encounter issues or have questions:

1. Check the [Troubleshooting Guide](./troubleshooting.md)
2. Contact your system administrator
3. Review the [Configuration Guide](../setup/configuration.md) for advanced setup

## Related Documentation

- [Architecture Overview](../architecture/overview.md)
- [Onboarding Process](../processes/onboarding-process.md)
- [Status Evaluation](../processes/status-evaluation.md)

