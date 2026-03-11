# Program Dates Related List (Child Component)

Child component that renders the Program Dates related list for Account records. **Use `programDatesRelatedListWrapper` in Lightning App Builder** - this component is meant to be used within the wrapper for proper spacing.

Custom related list for Program_Dates__c on Account to replace the standard "Related List – Single" when you need a custom New action.

## What it does
- Renders Program_Dates__c rows (for the current Account) in a `lightning-datatable` with key fields: Name, Partner Category, Inception Date, Program ID, Program Active Flag, Program Date, Program Deactivated Flag/Date/Reason, Program Reactivated Date.
- Row actions: View, Edit, Delete (uses `NavigationMixin` and `deleteRecord`).
- Header shows the object tab icon (in color) with count in parentheses format `Program Dates (0)` to match standard related list style.
- "New" button opens the existing `c-program-dates-screen-action` modal; on success it toasts and refreshes the list.
- Uses **SLDS standards** throughout for proper spacing, layout, and styling.

## Files
- `programDatesRelatedList.js` — wires data from `ProgramDatesRelatedListController`, handles actions, and fetches object icon via `getObjectInfo`.
- `programDatesRelatedList.html` — Standard SLDS card markup using `slds-card__header`, `slds-media`, `slds-icon_container`, proper grid layout, and SLDS spacing utilities.
- `programDatesRelatedList.css` — Light custom CSS to match standard related list gray header background.
- `ProgramDatesRelatedListController.cls` — Apex (with sharing, WITH SECURITY_ENFORCED) querying Program_Dates__c by `Account__c`.
- `programDatesScreenAction` — reused for creation; emits `recordcreated` and `cancel` so the modal can close/refresh.

## How to use
**Important**: This is the child component. Use `programDatesRelatedListWrapper` in Lightning App Builder.

1) Deploy both components (`programDatesRelatedListWrapper` and this component).
2) In Lightning App Builder, remove the standard Program Dates related list.
3) Drop `Program Dates Related List (Wrapper)` onto the Account record page.
4) Save/activate. The "New" button will use the existing Program Dates screen action inside a modal.

The parent-child structure ensures proper spacing that matches standard related lists.

## Notes
- Apex query ordering: `WITH SECURITY_ENFORCED` before `ORDER BY` to satisfy compilation.
- **Object tab icon**: Searches for and extracts the object's tab icon from `getObjectInfo.themeInfo.iconUrl`, supporting both standard and custom icons via `lightning-icon` wrapped in `slds-icon_container`.
- **SLDS-compliant**: Uses standard SLDS classes (`slds-card__header`, `slds-card__body_inner`, `slds-media`, `slds-grid`, `slds-icon_container`, etc.) for consistent appearance.
- **Gray header background**: Matches the standard "Related List - Single" component's light gray header via custom CSS.
- **Empty state**: Follows standard behavior by showing nothing when there are no records (no "No records found" message).
- If you later want a refresh button, add it in the header `slds-no-flex` section and call `refreshApex`.
