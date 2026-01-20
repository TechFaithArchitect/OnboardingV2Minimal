# Component Library Setup Guide

## Overview

The Component Library (`Onboarding_Component_Library__c`) is the central registry that maps Lightning Web Component API names to metadata records. This enables the onboarding flow engine to dynamically determine which components are available for rendering in wizard stages.

## Why Component Library?

LWC does not support dynamic component loading. To work around this limitation, the system uses:

1. **Component Library** - Metadata records that define available components
2. **Static Conditional Rendering** - `onboardingStageRenderer` has all components statically defined but only renders one based on `componentName` prop
3. **Process & Stages** - Define which component from the library to render at each stage

This architecture allows you to:

- Configure onboarding flows without code changes
- Add new components by syncing the library
- Create multiple processes with different stage sequences
- Track which components are available and active

## Initial Setup: Populating the Component Library

### Method 1: Via Apex (Anonymous Apex or Developer Console)

```apex
// Execute in Anonymous Apex
VendorOnboardingWizardController.syncRendererComponents();
```

This will:

1. Read the list of 14 predefined component API names
2. For each component, create or update an `Onboarding_Component_Library__c` record
3. Set `Component_API_Name__c` to the component name
4. Auto-generate `Name` from the API name (converts camelCase to readable format)
5. Set `Component_Type__c` to "LWC"
6. Set `Active__c` to true

### Method 2: Via Flow/Process Builder

The `VendorOnboardingWizardController.syncRendererComponents()` method is marked as `@InvocableMethod`, making it available in Flow Builder. This method handles the component library synchronization.

**Steps:**

1. Create a new Flow
2. Add an Action element
3. Search for "Sync Onboarding Components"
4. Add the action (requires a dummy List<Id> input, but it's ignored)
5. Save and activate the Flow

**Or create a Process Builder:**

1. Object: Any (or trigger on deployment)
2. Action: Invocable Action
3. Action: "Sync Onboarding Components"

### Method 3: Via Salesforce CLI (Workbench or VS Code)

You can also execute it via CLI:

```bash
sfdx force:apex:execute -f sync-component-library.txt
```

Where `sync-component-library.txt` contains:

```apex
VendorOnboardingWizardController.syncRendererComponents();
```

## What Gets Created

After running `syncComponentLibrary()`, you should see 14 records in `Onboarding_Component_Library__c`:

| Component API Name                                   | Display Name                                               |
| ---------------------------------------------------- | ---------------------------------------------------------- |
| vendorProgramOnboardingVendor                        | Vendor Program Onboarding Vendor                           |
| vendorProgramOnboardingVendorProgramSearchOrCreate   | Vendor Program Onboarding Vendor Program Search Or Create  |
| vendorProgramOnboardingVendorProgramCreate           | Vendor Program Onboarding Vendor Program Create            |
| vendorProgramOnboardingVendorProgramGroup            | Vendor Program Onboarding Vendor Program Group             |
| vendorProgramOnboardingVendorProgramRequirementGroup | Vendor Program Onboarding Vendor Program Requirement Group |
| vendorProgramOnboardingVendorProgramRecipientGroup   | Vendor Program Onboarding Vendor Program Recipient Group   |
| vendorProgramOnboardingRecipientGroup                | Vendor Program Onboarding Recipient Group                  |
| vendorProgramOnboardingRecipientGroupMembers         | Vendor Program Onboarding Recipient Group Members          |
| vendorProgramOnboardingTrainingRequirements          | Vendor Program Onboarding Training Requirements            |
| vendorProgramOnboardingRequiredCredentials           | Vendor Program Onboarding Required Credentials             |
| vendorProgramOnboardingVendorProgramRequirements     | Vendor Program Onboarding Vendor Program Requirements      |
| vendorProgramOnboardingStatusRulesEngine             | Vendor Program Onboarding Status Rules Engine              |
| vendorProgramOnboardingStatusRuleBuilder             | Vendor Program Onboarding Status Rule Builder              |
| vendorProgramOnboardingCommunicationTemplate         | Vendor Program Onboarding Communication Template           |

## Verifying Setup

After running the sync, verify the records were created:

```sql
SELECT Id, Name, Component_API_Name__c, Component_Type__c, Active__c
FROM Onboarding_Component_Library__c
ORDER BY Component_API_Name__c
```

You should see 14 records, all with `Active__c = true`.

## Adding New Components

When you create a new wizard component:

1. **Create the LWC component** (e.g., `vendorProgramOnboardingNewStep`)

2. **Add it to the sync list** in `VendorOnboardingWizardController.syncRendererComponents()`:

   ```apex
   List<String> components = new List<String>{
       // ... existing components
       'vendorProgramOnboardingNewStep'  // Add new component
   };
   ```

3. **Add it to onboardingStageRenderer**:
   - Add getter in `onboardingStageRenderer.js`:
     ```javascript
     get showVendorProgramOnboardingNewStep() {
       return this.componentName === 'vendorProgramOnboardingNewStep';
     }
     ```
   - Add template block in `onboardingStageRenderer.html`:
     ```html
     <template if:true="{showVendorProgramOnboardingNewStep}">
       <c-vendor-program-onboarding-new-step
         vendor-program-id="{vendorProgramId}"
         onnext="{handleNext}"
         onback="{handleBack}"
       >
       </c-vendor-program-onboarding-new-step>
     </template>
     ```

4. **Run sync again** to create the library record

5. **Use it in a stage** - Create an `Onboarding_Application_Stage__c` record that references the new component library entry

## Troubleshooting

### Issue: Components not appearing in flow

**Cause:** Component Library not populated or component not in library

**Solution:**

1. Verify Component Library has records: `SELECT COUNT() FROM Onboarding_Component_Library__c`
2. Check if component API name matches exactly (case-sensitive)
3. Run sync again: `VendorOnboardingWizardController.syncRendererComponents()`

### Issue: "Unknown component" error in flow

**Cause:** Component name in stage doesn't match Component Library entry

**Solution:**

1. Check `Onboarding_Application_Stage__c.Onboarding_Component_Library__r.Component_API_Name__c`
2. Ensure it matches exactly the LWC component API name
3. Verify component exists in `onboardingStageRenderer` with proper getter

### Issue: Component not rendering

**Cause:** Component not added to `onboardingStageRenderer` static rendering

**Solution:**

1. Add getter to `onboardingStageRenderer.js`
2. Add template block to `onboardingStageRenderer.html`
3. Ensure component is imported (static import, not dynamic)

## Best Practices

1. **Sync After Component Changes**
   - Run sync whenever you add/remove components
   - Keep the component list in sync with actual LWC components

2. **Component Naming Convention**
   - Use descriptive names: `vendorProgramOnboarding[Purpose]`
   - Keep naming consistent
   - Document new components

3. **Active Flag Management**
   - Set `Active__c = false` to disable a component without deleting
   - Useful for deprecating old components gradually

4. **Version Control**
   - Track changes to `syncComponentLibrary()` method
   - Document when components are added/removed

## Related Documentation

- [Vendor Program Onboarding Flow](../processes/vendor-program-onboarding-flow.md)
- [Onboarding Process](../processes/onboarding-process.md)
- [LWC Components](../components/lwc-components.md)
