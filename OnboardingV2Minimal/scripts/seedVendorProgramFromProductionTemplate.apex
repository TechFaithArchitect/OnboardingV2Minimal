// PerfectVision DOM programs use refs PV_PROGRAM_BASE_CHUZO, PV_PROGRAM_BASE_CHUZO_NO_PG, PV_PROGRAM_BASE_NO_CHUZO
// (replaces legacy PV_DOM). Vendor_Program_Requirement__c rows match OnboardV2 via getVendorProgramRequirementRowsByProgramRef().
VendorProgramSeedService.Options opts = new VendorProgramSeedService.Options();
opts.dryRun = false;
opts.updateExistingVendorActiveFlag = true;
opts.strictPicklists = false;
opts.skipRowsWithMissingContractType = false;
opts.seedContractRecordTypeReferences = true;
opts.seedAgreementTypeAndTemplateRecords = true;
opts.seedTrainingSystems = true;
opts.seedTrainingRequirements = true;
opts.seedVendorProgramRequirements = true;
opts.cleanupDuplicates = false; // Set true to repoint/delete duplicate seeded agreement, program-requirement, credential, training-system, and training-requirement records.
opts.vendorNames = new Set<String>{
    // Add Vendor filter (optional). Leave empty to process all seeded rows.
    // 'Verizon',
    // 'C Spire'
};

VendorProgramSeedService.Result result = VendorProgramSeedService.runAll(opts);
System.debug(LoggingLevel.INFO, 'VendorProgramSeedService.runAll summary: ' + result.summary());
for (String warningMessage : result.warnings) {
    System.debug(LoggingLevel.WARN, warningMessage);
}
