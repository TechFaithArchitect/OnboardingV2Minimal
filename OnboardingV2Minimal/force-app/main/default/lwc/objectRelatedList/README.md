# Object Related List Component

A reusable Lightning Web Component for displaying related records in a datatable format. This component provides all the common functionality needed for related lists, making it easy to create object-specific implementations.

## Purpose

This component eliminates the need to duplicate related list code for each object. It handles:
- Dynamic SOQL queries via Object Related List Controller
- Data table rendering with Lightning datatable
- Row actions (view, edit, delete)
- Inline editing
- Modal integration for record creation
- Error handling
- Loading states

## Usage

### Direct Usage (Lightning App Builder)

1. Add component to your Lightning page
2. Configure all required properties (see Properties section)
3. Component will automatically query and display records

### Usage in Object-Specific Wrappers

Create a thin wrapper component that provides object-specific configuration:

```javascript
import { LightningElement, api } from 'lwc';

const COLUMNS = [ /* your columns */ ];
const FIELD_API_NAMES = [ /* your fields */ ];

export default class MyObjectRelatedList extends LightningElement {
    @api recordId;
    
    get objectApiName() { return 'My_Object__c'; }
    get parentFieldApiName() { return 'Parent__c'; }
    get fieldApiNames() { return FIELD_API_NAMES; }
    get columns() { return COLUMNS; }
    get childComponent() { return 'myObjectScreenAction'; }
}
```

```html
<template>
    <c-object-related-list
        record-id={recordId}
        object-api-name={objectApiName}
        parent-field-api-name={parentFieldApiName}
        field-api-names={fieldApiNames}
        columns={columns}
        child-component={childComponent}>
    </c-object-related-list>
</template>
```

## Properties

### Required

- `recordId` (String): Parent record ID
- `objectApiName` (String): Child object API name (e.g., 'Program_Dates__c')
- `parentFieldApiName` (String): Lookup field API name (e.g., 'Account__c')
- `fieldApiNames` (Array): Array of field API names to query
- `columns` (Array): Lightning datatable column definitions
- `childComponent` (String): Name of form component for modal

### Optional

- `relationshipFieldApiNames` (Array): Relationship fields (e.g., ['Parent__r.Name'])
- `orderByField` (String): Field to order by (default: none)
- `orderDirection` (String): 'ASC' or 'DESC' (default: 'DESC')
- `modalTitle` (String): Override modal title
- `objectLabel` (String): Override object label
- `headerTitleOverride` (String): Custom header title (use {count} placeholder)
- `itemCountLabelOverride` (String): Custom item count label
- `relationshipApiName` (String): Relationship name for "View All" navigation

## Events

### Dispatched Events

- `rowtransform`: Fired when rows are being transformed. Listen to this event in parent components to customize row data.
  - Detail: `{ rows: Array }` - Modify `detail.rows` to transform data
  - Use `preventDefault()` to use custom rows, or modify `detail.rows` in place

### Listened Events

- None (all communication via properties)

## Custom Row Transformations

To add custom fields or transformations to rows, listen to the `rowtransform` event:

```javascript
// In wrapper component
handleRowTransform(event) {
    const rows = event.detail.rows;
    rows.forEach(row => {
        // Add custom computed fields
        row.customField = computeValue(row);
        row.displayLabel = row.Related__r?.Name || row.Name;
    });
}
```

```html
<c-object-related-list
    onrowtransform={handleRowTransform}
    ...other properties>
</c-object-related-list>
```

## Column Definitions

Columns should follow Lightning datatable column format:

```javascript
const COLUMNS = [
    {
        label: 'Field Label',
        fieldName: 'Field_API_Name__c',
        type: 'text', // text, number, date, boolean, url, email, etc.
        editable: true,
        initialWidth: 200,
        wrapText: true
    },
    // URL column with custom label
    {
        label: 'Record',
        fieldName: 'recordLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'CustomLabelField' },
            target: '_self'
        }
    }
];
```

## Integration with Form Components

This component integrates with the `relatedObjectActionModal` component. When user clicks "New":

1. Modal opens with specified `childComponent`
2. Form component should implement:
   - `@api triggerSave()` method
   - `@api triggerSaveAndNew()` method
   - Fire `success`, `error`, and `validitychange` events
3. On success, list automatically refreshes

## Examples

### Simple Implementation

```html
<c-object-related-list
    record-id={recordId}
    object-api-name="My_Object__c"
    parent-field-api-name="Account__c"
    field-api-names={fieldNames}
    columns={columns}
    child-component="myObjectScreenAction">
</c-object-related-list>
```

### With Custom Transformations

```javascript
handleRowTransform(event) {
    event.detail.rows.forEach(row => {
        row.fullName = `${row.FirstName__c} ${row.LastName__c}`;
        row.recordLink = `/${row.Id}`;
    });
}
```

## Security

- Uses `WITH SECURITY_ENFORCED` in SOQL queries
- Respects Field-Level Security (FLS)
- Respects object and record sharing rules
- All data access goes through Apex controller with sharing enforcement

## Performance

- Queries are cached via `@wire(cacheable=true)`
- Only queries specified fields
- Uses efficient SOQL queries
- Supports large datasets via pagination (datatable handles this)

## Limitations

- Requires parent-child relationship via lookup/master-detail field
- Form components must follow the standard interface
- Column definitions must be provided (not auto-generated)
- Inline editing requires editable columns

## See Also

- `MULTI_OBJECT_GUIDE.md` - Complete guide for adding new objects
- `relatedObjectActionModal` - Reusable modal wrapper
- `ObjectRelatedListController` - Reusable Apex controller

