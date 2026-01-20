# Stage Dependency Management

## Overview

The Stage Dependency Management system allows you to define dependencies between onboarding stages, ensuring that certain stages must be completed before others can be started. This system uses a Campaign/Campaign Member pattern to provide long-term reference stability even when stage orders change.

## Architecture

### Objects

#### Onboarding_Application_Stage_Dependency\_\_c

The "Campaign" object - defines a dependency rule.

**Key Fields:**

- `Name` - Descriptive name for the dependency rule
- `Logic_Type__c` - Evaluation logic: ALL, ANY, or CUSTOM
- `Required__c` - Whether this dependency is required
- `Target_Stage__c` - The stage that requires dependencies to be met

#### Onboarding_App_Stage_Dependency_Member\_\_c

The "Campaign Member" object - individual required stages within a dependency rule.

**Key Fields:**

- `Dependency__c` - Master-Detail to Onboarding_Application_Stage_Dependency\_\_c
- `Required_Stage__c` - The stage that must be completed
- `Required__c` - Whether this specific member is required

### Pattern Benefits

The Campaign/Campaign Member pattern provides:

1. **Long-term stability**: Dependencies reference stages by ID, not by order, so they persist even if stage orders change
2. **Flexibility**: Multiple members can be added to a single dependency rule
3. **Scalability**: Easy to add or remove required stages without changing the dependency rule structure

## Logic Types

### ALL

All required stages must be completed before the target stage can be started.

**Example**: "Vendor Selection" and "Vendor Program Creation" must both be completed before "Requirement Set Selection" can start.

### ANY

At least one required stage must be completed before the target stage can be started.

**Example**: Either "Vendor Selection" OR "Vendor Program Search" must be completed before proceeding.

### CUSTOM

Custom evaluation logic (not yet fully implemented - defaults to ALL for safety).

## Visualization

The `onboardingStageDependencyViewer` component provides a visual representation of stage dependencies:

- **Visual Layout**: Stages displayed in SVG-based layout showing dependency relationships
- **Status Indicators**: Color-coded completion status for each stage
- **Dependency Lines**: Visual connections showing which stages depend on others
- **Blocked Indicators**: Highlights stages that cannot be started due to unmet dependencies

### Usage

Add the component to a Lightning page with:

- `vendorProgramId` - Vendor program ID
- `processId` - Onboarding process ID

The component automatically:

- Loads stages with dependency information
- Calculates stage positions based on dependencies
- Displays completion status for each stage
- Shows blocked stages with visual indicators

See [Onboarding Stage Dependency Viewer](../components/lwc-components.md#onboardingstagedependencyviewer) for component documentation.

## Implementation

### Apex Classes

#### OnboardingStageDependencyRepository

Repository layer for dependency queries.

**Key Methods:**

- `getDependenciesForTargetStage(Id targetStageId)` - Gets all dependencies for a target stage
- `getCompletedStageIds(Id vendorProgramId, Id processId)` - Gets completed stage IDs for a vendor program

#### OnboardingStageDependencyService

Service layer for dependency validation.

**Key Methods:**

- `canStartStage(Id targetStageId, Id vendorProgramId, Id processId)` - Validates if a stage can be started
- `getDependencyInfo(Id targetStageId, Id vendorProgramId, Id processId)` - Gets dependency information for display

#### OnboardingApplicationService

Updated to include dependency validation.

**Key Methods:**

- `saveProgress()` - Now validates dependencies before saving progress
- `canStartStage()` - Exposes dependency validation to LWC
- `getStageDependencies()` - Gets dependency information for display

### Flow Engine Integration

The `onboardingFlowEngine` LWC component checks dependencies before allowing navigation:

1. When user clicks "Next", the component calls `canStartStage()` to validate
2. If dependencies are not met, navigation is blocked and an error message is shown
3. The error message lists all blocking dependencies with their logic types

### Validation Flow

```
User clicks "Next"
    ↓
Flow Engine checks dependencies (canStartStage)
    ↓
Dependencies met?
    ├─ Yes → Save progress and navigate
    └─ No → Show error message and block navigation
```

## Usage

### Creating a Dependency Rule

1. Create an `Onboarding_Application_Stage_Dependency__c` record:
   - Set `Name` to a descriptive name (e.g., "Vendor Selection Required")
   - Set `Logic_Type__c` to ALL, ANY, or CUSTOM
   - Set `Target_Stage__c` to the stage that requires dependencies
   - Set `Required__c` to true

2. Create `Onboarding_App_Stage_Dependency_Member__c` records:
   - Set `Dependency__c` to the dependency rule created above
   - Set `Required_Stage__c` to each stage that must be completed
   - Set `Required__c` to true for each member

### Example: Vendor Selection Required Before Program Setup

1. **Dependency Rule:**
   - Name: "Vendor Selection Required Before Program Setup"
   - Logic Type: ALL
   - Target Stage: "Vendor Program Creation" stage
   - Required: true

2. **Dependency Members:**
   - Member 1: Required Stage = "Vendor Selection" stage
   - Member 2: Required Stage = "Vendor Program Search" stage (if applicable)

### Example: Any Vendor Stage Before Requirements

1. **Dependency Rule:**
   - Name: "Any Vendor Stage Before Requirements"
   - Logic Type: ANY
   - Target Stage: "Requirement Set Selection" stage
   - Required: true

2. **Dependency Members:**
   - Member 1: Required Stage = "Vendor Selection" stage
   - Member 2: Required Stage = "Vendor Program Search" stage

## Error Messages

When dependencies are not met, users see error messages like:

```
Cannot proceed to this stage. The following dependencies must be completed first:

• Vendor Selection Required Before Program Setup (All required stages must be completed)
• Any Vendor Stage Before Requirements (At least one required stage must be completed)
```

## Best Practices

1. **Use descriptive names** for dependency rules to make them easy to understand
2. **Set Required\_\_c = true** for dependencies that should block navigation
3. **Use ALL logic** when all dependencies must be met (most common)
4. **Use ANY logic** when at least one dependency is sufficient
5. **Test dependencies** after creating them to ensure they work as expected
6. **Document complex dependencies** in the dependency rule's description or name

## Related Documentation

- [Custom Objects - Stage Dependencies](../objects/custom-objects.md#onboarding_application_stage_dependency__c)
- [Application Flow Engine](./application-flow-engine.md)
- [Onboarding Process](./onboarding-process.md)
