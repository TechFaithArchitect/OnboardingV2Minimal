# relatedObjectActionModal Component

## Overview

Generic, reusable modal wrapper component that provides a standardized modal structure for creating related records. This component handles the modal chrome (header, footer, close button) while delegating form content to child components.

## Purpose

- Provides consistent modal UI across all related object actions
- Handles modal structure (header, footer, backdrop)
- Manages save/cancel actions
- Coordinates with child form components
- Dispatches events for record creation

## Architecture

This is a **parent component** that:
1. Renders the modal structure (SLDS-compliant)
2. Contains child form components
3. Handles user actions (Save, Save & New, Cancel)
4. Communicates with child via public methods
5. Listens to child events (success, error, validitychange)

## Component Structure

```
relatedObjectActionModal
├── Modal Section (slds-modal)
│   ├── Modal Container
│   │   ├── Header
│   │   │   ├── Close Button (X)
│   │   │   └── Title
│   │   ├── Content Area
│   │   │   └── Child Form Component
│   │   └── Footer
│   │       └── Action Buttons (Cancel, Save & New, Save)
│   └── Backdrop
└── Loading Spinner (conditional)
```

## Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `recordId` | String | Parent record ID (e.g., Account Id) | - |
| `objectApiName` | String | Object API name for title generation | - |
| `childComponent` | String | Which child component to render | `'programDatesScreenAction'` |
| `modalTitle` | String | Modal title text | `'New Record'` |

## Methods

### Public Methods
None - this component is invoked as a Screen Action.

### Internal Methods

- `handleCancel()` - Closes modal and dispatches close event
- `handleSave()` - Triggers save in child component
- `handleSaveAndNew()` - Triggers save and new in child component
- `handleSuccess(event)` - Handles successful record creation
- `handleError()` - Handles errors from child component
- `handleValidityChange(event)` - Updates form validation state
- `getObjectLabel(objectApiName)` - Maps object API names to labels

## Events

### Dispatched Events

- `CloseActionScreenEvent` - Closes the Screen Action modal
- `close` - Custom close event (bubbles, composed)
- `recordcreated` - Fired when record is successfully created
  - Detail: `{ recordId, objectApiName }`

### Listened Events

- `success` - From child component when save succeeds
- `error` - From child component when save fails
- `validitychange` - From child component when validation state changes

## Child Component Communication

### Calling Child Methods

```javascript
const childComponent = this.template.querySelector('c-program-dates-screen-action');
if (childComponent && typeof childComponent.triggerSave === 'function') {
    childComponent.triggerSave();
}
```

### Listening to Child Events

```html
<c-program-dates-screen-action
    onsuccess={handleSuccess}
    onerror={handleError}
    onvaliditychange={handleValidityChange}>
</c-program-dates-screen-action>
```

## Styling

### Key CSS Classes

- `.slds-modal` - Main modal container
- `.slds-modal__container` - Modal content wrapper (responsive width)
- `.slds-modal__header` - Header with title and close button
- `.slds-modal__close` - Close button styling
- `.slds-modal__content` - Content area for child components
- `.slds-modal__footer` - Footer with action buttons

### Responsive Width

```css
.slds-modal__container {
    width: clamp(44rem, 60vw, 60rem);
    min-width: 44rem;
    max-width: 60rem;
}
```

### Close Button Positioning

The close button is positioned absolutely at the top-right of the header:
- Uses `lightning-primitive-icon` with `variant="bare"`
- Standard SLDS button classes
- White background with proper sizing

## Usage Example

### As Screen Action

1. Deploy component
2. Configure as Screen Action on Account object
3. When invoked, automatically:
   - Opens modal with title "New Program Dates"
   - Renders `programDatesScreenAction` child component
   - Handles all user interactions

### Adding New Child Component

1. Create new child form component
2. Add getter in parent:
   ```javascript
   get isNewObject() {
       return this.childComponent === 'newObjectForm';
   }
   ```
3. Add component in template:
   ```html
   <c-new-object-form
       if:true={isNewObject}
       record-id={recordId}
       onsuccess={handleSuccess}
       onerror={handleError}>
   </c-new-object-form>
   ```

## Dependencies

- Child form components (e.g., `programDatesScreenAction`)
- Salesforce Lightning Design System (SLDS)
- Lightning Web Components framework

## Testing

### Test Scenarios

1. **Modal Opens Correctly**
   - Verify header, title, close button render
   - Check backdrop appears
   - Confirm child component loads

2. **Close Button Works**
   - Click X button → modal closes
   - Click Cancel → modal closes

3. **Save Actions**
   - Click Save → child component saves
   - Click Save & New → saves and resets form
   - Verify validation prevents save when invalid

4. **Events Fire Correctly**
   - Success event → modal closes (unless Save & New)
   - Error event → modal stays open, shows error
   - Validity change → buttons enable/disable

## Known Issues

None currently.

## Future Enhancements

- Support for edit mode (not just create)
- Configurable footer buttons
- Custom header actions
- Multiple child components in tabs

