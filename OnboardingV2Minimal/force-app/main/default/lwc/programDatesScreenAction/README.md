# programDatesScreenAction Component

## Overview

Child form component for creating Program Dates records. This component provides the form fields and business logic, while the parent `relatedObjectActionModal` handles the modal structure.

## Purpose

- Renders form fields for Program Dates creation
- Handles Vendor Program selection (custom combobox)
- Manages form validation
- Creates records via Lightning Data Service
- Communicates with parent modal via events

## Architecture

This is a **child component** that:
1. Receives `recordId` from parent
2. Renders form fields in two sections
3. Validates required fields (Account, Vendor Program)
4. Exposes public methods for parent to trigger saves
5. Fires events to notify parent of success/error

## Component Structure

```
programDatesScreenAction
├── Lightning Messages (error display)
├── Form Container
│   ├── Required Information Legend
│   ├── Information Section
│   │   ├── Partner Category
│   │   ├── Vendor Program (combobox)
│   │   ├── Program ID
│   │   └── Account (lookup, required)
│   └── Program Active/Inactive Info Section
│       ├── Program Activated Subsection
│       │   ├── Program Active Flag
│       │   └── Program Date
│       ├── Program Deactivated Subsection
│       │   ├── Program Deactivated Flag
│       │   ├── Program Deactivated Date
│       │   └── Program Deactivated Reason
│       └── Program Reactivated Subsection
│           ├── Program Reactivated Flag
│           └── Program Reactivated Date
```

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `recordId` | String | Account ID (passed from parent) |

## Public Methods

These methods are called by the parent component:

### `triggerSave()`
Triggers a standard save operation.
- Sets `saveAndNew = false`
- Calls `submitForm()`

### `triggerSaveAndNew()`
Triggers save and reset form for new entry.
- Sets `saveAndNew = true`
- Calls `submitForm()`
- Resets form after successful save

## Internal Methods

### Form Handling
- `handleChange(event)` - Handles input field changes
- `handleVendorChange(event)` - Handles Vendor Program selection
- `handleAccountChange(event)` - Handles Account lookup change
- `submitForm()` - Creates record via Lightning Data Service
- `resetForm()` - Clears all form fields

### Validation
- `notifyValidity()` - Fires `validitychange` event to parent
- Validates: Account and Vendor Program are required

### Utilities
- `getFieldValue(name)` - Gets value from programFields array
- `get getProgramFieldValue` - Returns object map of all program field values
- `reduceErrors(errors)` - Flattens error objects into message array
- `showToast(title, message, variant)` - Displays toast notification

## Events

### Dispatched Events

- `success` - Record created successfully
  - Detail: `{ id, recordId, saveAndNew }`
- `error` - Error occurred during save
  - Detail: Error object
- `validitychange` - Form validation state changed
  - Detail: `{ isValid: boolean }`
- `ShowToastEvent` - For displaying notifications

## Form Fields

### Information Section

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Partner Category | Text | No | Standard text input |
| Vendor Program | Combobox | **Yes** | Custom dropdown, loads from Apex |
| Program ID | Text | No | Standard text input |
| Account | Lookup | **Yes** | Pre-filled from `recordId` |

### Program Active/Inactive Info Section

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Program Active Flag | Checkbox | No | Boolean |
| Program Date | Date | No | Date picker |
| Program Deactivated Flag | Checkbox | No | Boolean |
| Program Deactivated Date | Date | No | Date picker |
| Program Deactivated Reason | Textarea | No | Multi-line text |
| Program Reactivated Flag | Checkbox | No | Boolean |
| Program Reactivated Date | Date | No | Date picker |

## Data Flow

### Initialization
1. Component receives `recordId` from parent
2. Sets `accountId = recordId`
3. Loads Vendor Programs via `@wire(getVendorPrograms)`
4. Fires initial validity check

### User Interaction
1. User fills form fields
2. `handleChange()` updates component state
3. Required field changes trigger `notifyValidity()`
4. Parent receives validity updates

### Save Process
1. Parent calls `triggerSave()` or `triggerSaveAndNew()`
2. Component calls `submitForm()`
3. Creates record via `createRecord()` from `lightning/uiRecordApi`
4. On success: fires `success` event, optionally resets form
5. On error: fires `error` event, shows toast

## Apex Dependencies

### VendorProgramService.getVendorProgramsForSelection

**Purpose:** Returns list of Vendor Programs for dropdown

**Expected Return:** List of objects with:
- `Id` - Record ID
- `Label__c` - Display label

**Usage:**
```javascript
@wire(getVendorPrograms)
wiredVendors({ data, error }) {
    if (data) {
        this.vendorOptions = data.map(v => ({
            label: v.Label__c || 'Unlabeled',
            value: v.Id
        }));
    }
}
```

## Styling

### Layout
- Two-column grid layout using SLDS grid system
- Sections with gray headers (`rgb(243, 243, 243)`)
- White content areas
- Consistent padding and spacing

### Key CSS Classes
- `.record-body-container` - Main form wrapper
- `.required-legend` - Right-aligned legend
- `.slds-section` - Section containers
- `.slds-section__title` - Gray section headers
- `.slds-grid` - Two-column layout

## Validation Rules

### Required Fields
1. **Account** - Must have a value
2. **Vendor Program** - Must be selected from dropdown

### Validation Logic
```javascript
const isValid = !!this.accountId && !!this.selectedVendorProgramId;
```

When validation state changes, component fires:
```javascript
this.dispatchEvent(new CustomEvent('validitychange', {
    detail: { isValid },
    bubbles: true,
    composed: true
}));
```

## Error Handling

### Error Reduction
The `reduceErrors()` method handles various error formats:
- Array of errors → flattened
- Body with pageErrors → extracted messages
- Body with message → single message
- String message → returned as-is
- Unknown format → "Unknown error"

### Error Display
- Errors shown via `ShowToastEvent`
- Error event fired to parent
- Form remains open for user to correct

## Save & New Flow

1. User clicks "Save & New"
2. Parent calls `triggerSaveAndNew()`
3. Component sets `saveAndNew = true`
4. Record is created
5. On success:
   - `success` event fired with `saveAndNew: true`
   - Form is reset via `resetForm()`
   - `saveAndNew` flag reset to `false`
6. Parent keeps modal open (doesn't close)

## Testing

### Test Scenarios

1. **Form Renders**
   - All fields visible
   - Vendor Program dropdown populated
   - Account pre-filled

2. **Validation**
   - Save disabled when Account missing
   - Save disabled when Vendor Program missing
   - Save enabled when both present

3. **Save Operation**
   - Record created with correct field values
   - Success event fired
   - Modal closes (unless Save & New)

4. **Save & New**
   - Record created
   - Form resets
   - Modal stays open

5. **Error Handling**
   - Errors displayed in toast
   - Error event fired to parent
   - Form remains open

## Known Issues

None currently.

## Future Enhancements

- Edit mode support
- Field-level validation messages
- Dependent field logic
- Bulk field updates

