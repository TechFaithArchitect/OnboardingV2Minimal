# EmailComm Removal Notes

## Summary
- EmailComm send/log stack removed (actions, DTOs, helpers, log object)
- Follow-up emails now send directly in `FollowUpExecutionService` via `Messaging.sendEmail`
- Flows use standard `emailSimple` actions instead of EmailComm invocable actions

## Remaining EmailComm-Named Classes
These are unrelated to the email log and only handle territory role sync:

- `force-app/main/default/classes/helpers/EmailCommTerritoryRoleHelper.cls`
- `force-app/main/default/classes/jobs/EmailCommTerritoryRoleSyncJob.cls`
- `force-app/main/default/triggers/TerritoryAssignmentsTrigger.trigger`
- Tests: `EmailCommTerritoryRoleHelperTest`, `EmailCommTerritoryRoleSyncJobTest`

## If Removing Territory Role Sync
1. Update `force-app/main/default/triggers/TerritoryAssignmentsTrigger.trigger` to remove the helper call (or replace with a new helper).
2. Delete the helper/job classes and their tests + meta files.
3. Unschedule the job in the org (Setup → Scheduled Jobs or delete `CronTrigger`).
4. Remove class access entries from profiles/permsets for the deleted classes.
5. Re-verify `Territory_Role_Assignment__c` behavior (this sync currently populates roles).

## If Renaming But Keeping Functionality
- Create new classes (e.g., `TerritoryRoleHelper`, `TerritoryRoleSyncJob`) with the same logic.
- Update `TerritoryAssignmentsTrigger` and any schedules to reference the new names.
- Remove old EmailComm-prefixed classes, tests, and profile access entries.
