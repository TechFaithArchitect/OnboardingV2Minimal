# Program Dates Related List Wrapper (Parent Component)

Parent wrapper component that provides proper spacing context for the Program Dates related list to match standard Salesforce "Related List - Single" components.

## Purpose

Standard Salesforce related lists use a parent-child component structure:
- **Parent (this component)**: Provides the wrapper container and proper spacing context
- **Child (`programDatesRelatedList`)**: Renders the actual related list table

This structure ensures the component spacing and layout exactly matches the standard related list appearance.

## Usage

### In Lightning App Builder:
1. Deploy both components (`programDatesRelatedListWrapper` and `programDatesRelatedList`)
2. Remove the standard Program Dates related list from the Account record page
3. Drag `Program Dates Related List (Wrapper)` onto the page
4. Save and activate

The wrapper automatically passes the `recordId` to the child component.

## Files
- `programDatesRelatedListWrapper.html` - Simple template that wraps the child component
- `programDatesRelatedListWrapper.js` - Passes `recordId` from parent to child
- `programDatesRelatedListWrapper.js-meta.xml` - Exposes wrapper on record pages
- `programDatesRelatedListWrapper.css` - Minimal wrapper styles

## Architecture

```
programDatesRelatedListWrapper (Parent - Use this in App Builder)
  └── programDatesRelatedList (Child - Renders the table)
       └── programDatesScreenAction (Modal for creating records)
```

This parent-child pattern matches how standard Salesforce related list components are structured.

