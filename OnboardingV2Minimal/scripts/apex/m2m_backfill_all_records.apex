/*
  Production-safe m2m data backfill (re-runnable, idempotent).

  What this script does:
  1) Backfill Vendor_Program_Training_Requirement__c from legacy Training_Requirement__c.Vendor_Customization__c
  2) Backfill Training_Assignment_Onboarding__c from legacy Training_Assignment__c.Onboarding__c
  3) Backfill Unique_Assignment_Key__c for canonical Training_Assignment__c records

  Safety:
  - dryRun = true by default
  - uses upsert by unique key fields
  - no deletes in this script

  How to run:
  - Execute Anonymous in Production (or CLI sf apex run --target-org <alias> --file ...)
  - Run with dryRun=true first, then set dryRun=false
  - Re-run until "remaining" counts are 0
*/

Boolean dryRun = false;

Boolean runVendorProgramRequirementBackfill = false;
Boolean runAssignmentOnboardingBackfill = true;
Boolean runCanonicalAssignmentKeyBackfill = false;

Integer vendorProgramRequirementBatchSize = 338;
Integer assignmentOnboardingBatchSize = 338;
Integer canonicalKeyBatchSize = 338;

Boolean enforceSinglePhasePerRun = true;
Boolean includeRemainingCounts = true;
Boolean verboseRowErrors = false;

System.debug('=== M2M Backfill Start ===');
System.debug('dryRun=' + dryRun);
System.debug('runVendorProgramRequirementBackfill=' + runVendorProgramRequirementBackfill);
System.debug('runAssignmentOnboardingBackfill=' + runAssignmentOnboardingBackfill);
System.debug('runCanonicalAssignmentKeyBackfill=' + runCanonicalAssignmentKeyBackfill);
System.debug('enforceSinglePhasePerRun=' + enforceSinglePhasePerRun);
System.debug('includeRemainingCounts=' + includeRemainingCounts);
System.debug('verboseRowErrors=' + verboseRowErrors);
System.debug('vendorProgramRequirementBatchSize=' + vendorProgramRequirementBatchSize);
System.debug('assignmentOnboardingBatchSize=' + assignmentOnboardingBatchSize);
System.debug('canonicalKeyBatchSize=' + canonicalKeyBatchSize);

Integer selectedPhaseCount = 0;
selectedPhaseCount += runVendorProgramRequirementBackfill ? 1 : 0;
selectedPhaseCount += runAssignmentOnboardingBackfill ? 1 : 0;
selectedPhaseCount += runCanonicalAssignmentKeyBackfill ? 1 : 0;

if (selectedPhaseCount == 0) {
    System.debug(LoggingLevel.WARN, 'No phase selected. Nothing to do.');
} else if (enforceSinglePhasePerRun && selectedPhaseCount > 1) {
    System.debug(LoggingLevel.ERROR,
        'CPU-safe guard: select only one phase per run, or set enforceSinglePhasePerRun=false.');
} else {

if (runVendorProgramRequirementBackfill) {
    List<Training_Requirement__c> trainingRequirementsToBackfill = [
        SELECT Id, Vendor_Customization__c
        FROM Training_Requirement__c
        WHERE Vendor_Customization__c != null
        AND Id NOT IN (
            SELECT Training_Requirement__c
            FROM Vendor_Program_Training_Requirement__c
            WHERE Training_Requirement__c != null
        )
        ORDER BY Id
        LIMIT :vendorProgramRequirementBatchSize
    ];

    List<Vendor_Program_Training_Requirement__c> vendorProgramLinksToUpsert =
        new List<Vendor_Program_Training_Requirement__c>();

    for (Training_Requirement__c trainingRequirementRow : trainingRequirementsToBackfill) {
        String uniqueKey = String.valueOf(trainingRequirementRow.Vendor_Customization__c)
            + '|'
            + String.valueOf(trainingRequirementRow.Id);

        vendorProgramLinksToUpsert.add(new Vendor_Program_Training_Requirement__c(
            Vendor_Program__c = trainingRequirementRow.Vendor_Customization__c,
            Training_Requirement__c = trainingRequirementRow.Id,
            Unique_Key__c = uniqueKey
        ));
    }

    Integer vendorProgramSuccess = 0;
    Integer vendorProgramFailure = 0;

    if (!dryRun && !vendorProgramLinksToUpsert.isEmpty()) {
        Database.UpsertResult[] vendorProgramResults =
            Database.upsert(
                vendorProgramLinksToUpsert,
                Vendor_Program_Training_Requirement__c.Fields.Unique_Key__c,
                false
            );

        for (Integer i = 0; i < vendorProgramResults.size(); i++) {
            if (vendorProgramResults[i].isSuccess()) {
                vendorProgramSuccess++;
            } else {
                vendorProgramFailure++;
                for (Database.Error err : vendorProgramResults[i].getErrors()) {
                    if (verboseRowErrors) {
                        System.debug(
                            LoggingLevel.ERROR,
                            'Vendor_Program_Training_Requirement__c upsert failed. key='
                            + vendorProgramLinksToUpsert[i].Unique_Key__c
                            + ', status=' + err.getStatusCode()
                            + ', message=' + err.getMessage()
                        );
                    }
                }
            }
        }
    }

    Integer vendorProgramRemaining = -1;
    if (includeRemainingCounts) {
        vendorProgramRemaining = [
            SELECT COUNT()
            FROM Training_Requirement__c
            WHERE Vendor_Customization__c != null
            AND Id NOT IN (
                SELECT Training_Requirement__c
                FROM Vendor_Program_Training_Requirement__c
                WHERE Training_Requirement__c != null
            )
        ];
    }

    System.debug('--- Phase 1: Vendor Program <-> Training Requirement ---');
    System.debug('Candidates in this run: ' + trainingRequirementsToBackfill.size());
    System.debug('Rows prepared to upsert: ' + vendorProgramLinksToUpsert.size());
    if (dryRun) {
        System.debug('Dry run: no rows upserted.');
    } else {
        System.debug('Upsert success: ' + vendorProgramSuccess + ', failed: ' + vendorProgramFailure);
    }
    if (includeRemainingCounts) {
        System.debug('Remaining after this run: ' + vendorProgramRemaining);
    } else {
        System.debug('Remaining after this run: (skipped; set includeRemainingCounts=true to compute)');
    }
}

if (runAssignmentOnboardingBackfill) {
    List<Training_Assignment__c> assignmentsMissingAnyLink = [
        SELECT Id, Onboarding__c
        FROM Training_Assignment__c
        WHERE Onboarding__c != null
        AND Id NOT IN (
            SELECT Training_Assignment__c
            FROM Training_Assignment_Onboarding__c
            WHERE Training_Assignment__c != null
        )
        ORDER BY Id
        LIMIT :assignmentOnboardingBatchSize
    ];

    List<Training_Assignment_Onboarding__c> assignmentOnboardingLinksToUpsert =
        new List<Training_Assignment_Onboarding__c>();

    for (Training_Assignment__c assignmentRow : assignmentsMissingAnyLink) {
        String uniqueKey = String.valueOf(assignmentRow.Id)
            + '|'
            + String.valueOf(assignmentRow.Onboarding__c);

        assignmentOnboardingLinksToUpsert.add(new Training_Assignment_Onboarding__c(
            Training_Assignment__c = assignmentRow.Id,
            Onboarding__c = assignmentRow.Onboarding__c,
            Unique_Key__c = uniqueKey
        ));
    }

    Integer assignmentLinkSuccess = 0;
    Integer assignmentLinkFailure = 0;

    if (!dryRun && !assignmentOnboardingLinksToUpsert.isEmpty()) {
        Database.UpsertResult[] assignmentLinkResults =
            Database.upsert(
                assignmentOnboardingLinksToUpsert,
                Training_Assignment_Onboarding__c.Fields.Unique_Key__c,
                false
            );

        for (Integer i = 0; i < assignmentLinkResults.size(); i++) {
            if (assignmentLinkResults[i].isSuccess()) {
                assignmentLinkSuccess++;
            } else {
                assignmentLinkFailure++;
                for (Database.Error err : assignmentLinkResults[i].getErrors()) {
                    if (verboseRowErrors) {
                        System.debug(
                            LoggingLevel.ERROR,
                            'Training_Assignment_Onboarding__c upsert failed. key='
                            + assignmentOnboardingLinksToUpsert[i].Unique_Key__c
                            + ', status=' + err.getStatusCode()
                            + ', message=' + err.getMessage()
                        );
                    }
                }
            }
        }
    }

    Integer assignmentLinksRemaining = -1;
    if (includeRemainingCounts) {
        assignmentLinksRemaining = [
            SELECT COUNT()
            FROM Training_Assignment__c
            WHERE Onboarding__c != null
            AND Id NOT IN (
                SELECT Training_Assignment__c
                FROM Training_Assignment_Onboarding__c
                WHERE Training_Assignment__c != null
            )
        ];
    }

    System.debug('--- Phase 2: Training Assignment <-> Onboarding ---');
    System.debug('Candidates in this run: ' + assignmentsMissingAnyLink.size());
    System.debug('Rows prepared to upsert: ' + assignmentOnboardingLinksToUpsert.size());
    if (dryRun) {
        System.debug('Dry run: no rows upserted.');
    } else {
        System.debug('Upsert success: ' + assignmentLinkSuccess + ', failed: ' + assignmentLinkFailure);
    }
    if (includeRemainingCounts) {
        System.debug('Remaining after this run: ' + assignmentLinksRemaining);
    } else {
        System.debug('Remaining after this run: (skipped; set includeRemainingCounts=true to compute)');
    }
}

if (runCanonicalAssignmentKeyBackfill) {
    List<Training_Assignment__c> canonicalAssignmentsMissingKeys = [
        SELECT Id, Contact__c, Vendor_Training_Requirement__c, Unique_Assignment_Key__c
        FROM Training_Assignment__c
        WHERE Is_Canonical__c = true
        AND Unique_Assignment_Key__c = null
        AND Contact__c != null
        AND Vendor_Training_Requirement__c != null
        ORDER BY Id
        LIMIT :canonicalKeyBatchSize
    ];

    List<Training_Assignment__c> canonicalAssignmentsToUpdate = new List<Training_Assignment__c>();
    for (Training_Assignment__c canonicalAssignmentRow : canonicalAssignmentsMissingKeys) {
        String canonicalKey = String.valueOf(canonicalAssignmentRow.Contact__c)
            + '|'
            + String.valueOf(canonicalAssignmentRow.Vendor_Training_Requirement__c);

        canonicalAssignmentsToUpdate.add(new Training_Assignment__c(
            Id = canonicalAssignmentRow.Id,
            Unique_Assignment_Key__c = canonicalKey
        ));
    }

    Integer canonicalKeySuccess = 0;
    Integer canonicalKeyFailure = 0;

    if (!dryRun && !canonicalAssignmentsToUpdate.isEmpty()) {
        Database.SaveResult[] canonicalKeyResults = Database.update(canonicalAssignmentsToUpdate, false);
        for (Integer i = 0; i < canonicalKeyResults.size(); i++) {
            if (canonicalKeyResults[i].isSuccess()) {
                canonicalKeySuccess++;
            } else {
                canonicalKeyFailure++;
                for (Database.Error err : canonicalKeyResults[i].getErrors()) {
                    if (verboseRowErrors) {
                        System.debug(
                            LoggingLevel.ERROR,
                            'Training_Assignment__c key update failed. assignmentId='
                            + canonicalAssignmentsToUpdate[i].Id
                            + ', key=' + canonicalAssignmentsToUpdate[i].Unique_Assignment_Key__c
                            + ', status=' + err.getStatusCode()
                            + ', message=' + err.getMessage()
                        );
                    }
                }
            }
        }
    }

    Integer canonicalKeysRemaining = -1;
    if (includeRemainingCounts) {
        canonicalKeysRemaining = [
            SELECT COUNT()
            FROM Training_Assignment__c
            WHERE Is_Canonical__c = true
            AND Unique_Assignment_Key__c = null
            AND Contact__c != null
            AND Vendor_Training_Requirement__c != null
        ];
    }

    System.debug('--- Phase 3: Canonical Assignment Keys ---');
    System.debug('Candidates in this run: ' + canonicalAssignmentsMissingKeys.size());
    System.debug('Rows prepared to update: ' + canonicalAssignmentsToUpdate.size());
    if (dryRun) {
        System.debug('Dry run: no rows updated.');
    } else {
        System.debug('Update success: ' + canonicalKeySuccess + ', failed: ' + canonicalKeyFailure);
    }
    if (includeRemainingCounts) {
        System.debug('Remaining after this run: ' + canonicalKeysRemaining);
    } else {
        System.debug('Remaining after this run: (skipped; set includeRemainingCounts=true to compute)');
    }
}
}

System.debug('=== M2M Backfill Complete ===');
