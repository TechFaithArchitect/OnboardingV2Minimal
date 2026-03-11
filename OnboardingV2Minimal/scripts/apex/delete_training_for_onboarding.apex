/*
  Reusable Execute Anonymous script (UAT + OnboardV2)

  Purpose:
  - Delete Training_Assignment_Onboarding__c links for one Onboarding__c
  - Delete related Training_Assignment__c records based on selected mode

  How to use:
  1) Set onboardingIdInput to the target Onboarding__c Id (15/18 chars)
  2) Start with dryRun = true and review logs
  3) Set dryRun = false to execute

  Delete modes:
  - deleteSharedAssignments = false (recommended):
      Deletes the target onboarding's junction links.
      Deletes assignments only when they are NOT linked to any other onboarding.
  - deleteSharedAssignments = true:
      Deletes all candidate assignments even if shared.
      Also deletes their other onboarding junction links first.
*/

String onboardingIdInput = 'PUT_ONBOARDING_ID_HERE';
Boolean dryRun = true;
Boolean deleteSharedAssignments = false;

String normalizedOnboardingIdInput = onboardingIdInput == null ? null : onboardingIdInput.trim();

if (String.isBlank(normalizedOnboardingIdInput)) {
    System.debug(LoggingLevel.ERROR, 'Set onboardingIdInput before running.');
} else if (!Pattern.matches('^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$', normalizedOnboardingIdInput)) {
    System.debug(LoggingLevel.ERROR, 'onboardingIdInput must be a 15 or 18 character Salesforce Id: ' + onboardingIdInput);
} else {
    Id onboardingId;
    try {
        onboardingId = (Id) normalizedOnboardingIdInput;
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, 'Invalid onboardingIdInput: ' + onboardingIdInput);
    }

    if (onboardingId != null) {
        List<Onboarding__c> onboardingRows = [
            SELECT Id
            FROM Onboarding__c
            WHERE Id = :onboardingId
            LIMIT 1
        ];

        if (onboardingRows.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Onboarding not found: ' + onboardingId);
        } else {
            List<Training_Assignment_Onboarding__c> targetLinks = [
                SELECT Id, Training_Assignment__c
                FROM Training_Assignment_Onboarding__c
                WHERE Onboarding__c = :onboardingId
            ];

            List<Training_Assignment__c> directAssignments = [
                SELECT Id
                FROM Training_Assignment__c
                WHERE Onboarding__c = :onboardingId
            ];

            Set<Id> targetLinkIds = new Set<Id>();
            Set<Id> candidateAssignmentIds = new Set<Id>();

            for (Training_Assignment_Onboarding__c linkRow : targetLinks) {
                targetLinkIds.add(linkRow.Id);
                if (linkRow.Training_Assignment__c != null) {
                    candidateAssignmentIds.add(linkRow.Training_Assignment__c);
                }
            }
            for (Training_Assignment__c taRow : directAssignments) {
                candidateAssignmentIds.add(taRow.Id);
            }

            Set<Id> candidateWithOtherOnboardingLinks = new Set<Id>();
            if (!candidateAssignmentIds.isEmpty()) {
                for (Training_Assignment_Onboarding__c otherLink : [
                    SELECT Training_Assignment__c
                    FROM Training_Assignment_Onboarding__c
                    WHERE Training_Assignment__c IN :candidateAssignmentIds
                    AND Onboarding__c != :onboardingId
                ]) {
                    candidateWithOtherOnboardingLinks.add(otherLink.Training_Assignment__c);
                }
            }

            Set<Id> assignmentIdsToDelete = new Set<Id>();
            Set<Id> sharedAssignmentIdsSkipped = new Set<Id>();

            for (Id taId : candidateAssignmentIds) {
                Boolean sharedElsewhere = candidateWithOtherOnboardingLinks.contains(taId);
                if (deleteSharedAssignments || !sharedElsewhere) {
                    assignmentIdsToDelete.add(taId);
                } else {
                    sharedAssignmentIdsSkipped.add(taId);
                }
            }

            Set<Id> allLinkIdsToDelete = new Set<Id>();
            allLinkIdsToDelete.addAll(targetLinkIds);

            if (deleteSharedAssignments && !assignmentIdsToDelete.isEmpty()) {
                for (Training_Assignment_Onboarding__c extraLink : [
                    SELECT Id
                    FROM Training_Assignment_Onboarding__c
                    WHERE Training_Assignment__c IN :assignmentIdsToDelete
                    AND Id NOT IN :targetLinkIds
                ]) {
                    allLinkIdsToDelete.add(extraLink.Id);
                }
            }

            List<Training_Assignment_Onboarding__c> linkRowsToDelete = new List<Training_Assignment_Onboarding__c>();
            for (Id linkId : allLinkIdsToDelete) {
                linkRowsToDelete.add(new Training_Assignment_Onboarding__c(Id = linkId));
            }

            List<Training_Assignment__c> assignmentRowsToDelete = new List<Training_Assignment__c>();
            for (Id taId : assignmentIdsToDelete) {
                assignmentRowsToDelete.add(new Training_Assignment__c(Id = taId));
            }

            System.debug('=== Delete Training By Onboarding Summary ===');
            System.debug('Onboarding Id: ' + onboardingId);
            System.debug('dryRun: ' + dryRun);
            System.debug('deleteSharedAssignments: ' + deleteSharedAssignments);
            System.debug('Target onboarding link rows found: ' + targetLinks.size());
            System.debug('Legacy direct assignment rows found: ' + directAssignments.size());
            System.debug('Candidate assignment rows: ' + candidateAssignmentIds.size());
            System.debug('Shared assignments skipped (safe mode): ' + sharedAssignmentIdsSkipped.size());
            System.debug('Training_Assignment_Onboarding__c rows to delete: ' + linkRowsToDelete.size());
            System.debug('Training_Assignment__c rows to delete: ' + assignmentRowsToDelete.size());

            if (dryRun) {
                System.debug('DRY RUN ONLY. No records were deleted.');
            } else {
                Integer linkDeleteSuccess = 0;
                Integer linkDeleteFailure = 0;
                Integer assignmentDeleteSuccess = 0;
                Integer assignmentDeleteFailure = 0;

                if (!linkRowsToDelete.isEmpty()) {
                    Database.DeleteResult[] linkResults = Database.delete(linkRowsToDelete, false);
                    for (Integer i = 0; i < linkResults.size(); i++) {
                        if (linkResults[i].isSuccess()) {
                            linkDeleteSuccess++;
                        } else {
                            linkDeleteFailure++;
                            for (Database.Error err : linkResults[i].getErrors()) {
                                System.debug(LoggingLevel.ERROR,
                                    'Link delete failed: Id=' + linkRowsToDelete[i].Id +
                                    ', Status=' + err.getStatusCode() +
                                    ', Message=' + err.getMessage()
                                );
                            }
                        }
                    }
                }

                if (!assignmentRowsToDelete.isEmpty()) {
                    Database.DeleteResult[] assignmentResults = Database.delete(assignmentRowsToDelete, false);
                    for (Integer i = 0; i < assignmentResults.size(); i++) {
                        if (assignmentResults[i].isSuccess()) {
                            assignmentDeleteSuccess++;
                        } else {
                            assignmentDeleteFailure++;
                            for (Database.Error err : assignmentResults[i].getErrors()) {
                                System.debug(LoggingLevel.ERROR,
                                    'Assignment delete failed: Id=' + assignmentRowsToDelete[i].Id +
                                    ', Status=' + err.getStatusCode() +
                                    ', Message=' + err.getMessage()
                                );
                            }
                        }
                    }
                }

                System.debug('=== Delete Execution Results ===');
                System.debug('Training_Assignment_Onboarding__c deleted: ' + linkDeleteSuccess + ', failed: ' + linkDeleteFailure);
                System.debug('Training_Assignment__c deleted: ' + assignmentDeleteSuccess + ', failed: ' + assignmentDeleteFailure);
            }
        }
    }
}
