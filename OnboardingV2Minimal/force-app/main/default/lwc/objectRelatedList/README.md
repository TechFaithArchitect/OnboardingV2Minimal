# Object Related List Component

Reusable related list LWC that can be configured per object in Lightning App Builder.

## What It Solves

- One LWC for multiple related objects (Program Dates, Onboarding Requirements, etc.)
- Minimal Apex footprint (uses `ObjectRelatedListController.getRelatedRecords`)
- Configurable from Record Page properties
- Supports two New-record patterns:
  - Custom modal child component
  - Standard Salesforce New page with default parent lookup

## App Builder Configuration

Use these key properties on `Object Related List`:

- `Record Object API Name (System)`: auto-populated by Salesforce; ignore this for child list setup
- `Child Object API Name`: child object to query (example: `Program_Dates__c`)
- `Parent Lookup Field API Name`: lookup/master-detail field on child (example: `Account__c`)
- `Relationship API Name`: relationship name for header/View All navigation (example: `Program_Dates__r`)
- `Fields (CSV)`: fields queried by Apex
- `Auto Column Fields (CSV)`: optional field list for auto-generated datatable columns
- `Column JSON Override`: optional advanced datatable config (overrides auto columns)
- `Link Field API Name`: optional field to display as clickable record link in auto columns
- `New Button Behavior`: `auto`, `standard`, `modal`, `hidden`
- `Modal Child Component Name`: used only when modal behavior is selected
- `Read Only Fields (CSV)`: optional comma-separated fields to force read-only while other fields remain editable
- `Read Only & Treat As Text (CSV)`: optional comma-separated fields to render as plain read-only text (useful for picklists you do not want as dropdowns)

## Example: Program Dates on Account

Property values:

- `Child Object API Name`: `Program_Dates__c`
- `Parent Lookup Field API Name`: `Account__c`
- `Relationship API Name`: `Program_Dates__r`
- `Fields (CSV)`: `Vendor_Program__c,Partner_Category__c,Inception_Date__c,Program_ID__c,Program_Active_Flag__c,Program_Date__c,Program_Deactivated_Flag__c,Program_Deactivated_Date__c,Program_Deactivated_Reason__c,Program_Reactivated_Date__c,Program_Reactivated_Flag__c`
- `Relationship Fields (CSV)`: `Vendor_Program__r.Label__c`
- `Auto Column Fields (CSV)`: `Vendor_Program__r.Label__c,Partner_Category__c,Inception_Date__c,Program_ID__c,Program_Active_Flag__c,Program_Date__c,Program_Deactivated_Flag__c,Program_Deactivated_Date__c,Program_Deactivated_Reason__c,Program_Reactivated_Date__c,Program_Reactivated_Flag__c`
- `Order By Field API Name`: `Program_Date__c`
- `Order Direction`: `DESC`
- `New Button Behavior`: `modal`
- `Modal Child Component Name`: `programDatesScreenAction`
- `Header Title Override`: `Program Dates ({count})`

## Example: Onboarding Requirements on Onboarding

This configuration does not require a new custom form component.

Property values:

- `Child Object API Name`: `Onboarding_Requirement__c`
- `Parent Lookup Field API Name`: `Onboarding__c`
- `Relationship API Name`: `Onboarding_Requirements__r`
- `Fields (CSV)`: `Requirement_Type__c,Status__c,Completed__c,Is_Overridden__c,Is_Inherited__c,Sequence__c,Display_Label__c`
- `Auto Column Fields (CSV)`: `Sequence__c,Requirement_Type__c,Status__c,Completed__c,Is_Overridden__c,Is_Inherited__c`
- `Order By Field API Name`: `Sequence__c`
- `Order Direction`: `ASC`
- `New Button Behavior`: `standard`
- `Header Title Override`: `Onboarding Requirements ({count})`
- `Item Count Label Override`: `Sorted by Sequence`
- `Read Only Fields (CSV)`: `Completed__c`
- `Read Only & Treat As Text (CSV)`: `Requirement_Type__c`

## Column JSON Override (Advanced)

If you need explicit datatable control, provide `Column JSON Override`, for example:

```json
[
  { "label": "Requirement Type", "fieldName": "Requirement_Type__c", "type": "text", "editable": true },
  { "label": "Status", "fieldName": "Status__c", "type": "text", "editable": true },
  { "label": "Completed", "fieldName": "Completed__c", "type": "boolean", "editable": true }
]
```

## Notes

- `objectApiName` is a reserved record-page context value in LWC. Always configure child records with `Child Object API Name`.
- `Fields (CSV)` drives the SOQL query; include every field needed by your columns.
- Relationship columns work by including them in `Relationship Fields (CSV)` (example: `Parent__r.Name`).
- In `standard` New mode, parent lookup is prefilled automatically using `Parent Lookup Field API Name` + current `recordId`.
- Auto-generated picklist columns render as inline dropdowns and save immediately per-row.
- Use `Read Only & Treat As Text (CSV)` for picklists that should display as plain text and never enter edit mode.
