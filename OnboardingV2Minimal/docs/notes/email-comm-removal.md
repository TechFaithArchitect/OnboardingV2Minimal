# EmailComm Removal Notes

## Summary
- EmailComm send/log stack removed (actions, DTOs, helpers, log object)
- Follow-up emails are handled by Flow send email actions (no Apex email sending)
- Flows use native Send Email actions instead of EmailComm invocable actions

## Remaining EmailComm-Named Classes
These are unrelated to the email log and only handle territory role sync:

- `force-app/main/default/classes/EmailCommTerritoryRoleHelper.cls`
- `force-app/main/default/triggers/TerritoryAssignmentsTrigger.trigger`
- Tests: `EmailCommTerritoryRoleHelperTest`

## If Removing Territory Role Sync
1. Update `force-app/main/default/triggers/TerritoryAssignmentsTrigger.trigger` to remove the helper call (or replace with a new helper).
2. Delete the helper class and its test + meta files.
3. Remove class access entries from profiles/permsets for the deleted classes.
4. Re-verify `Territory_Role_Assignment__c` behavior (this sync currently populates roles).

## If Renaming But Keeping Functionality
- Create new class (e.g., `TerritoryRoleHelper`) with the same logic.
- Update `TerritoryAssignmentsTrigger` to reference the new name.
- Remove old EmailComm-prefixed class, test, and profile access entries.
