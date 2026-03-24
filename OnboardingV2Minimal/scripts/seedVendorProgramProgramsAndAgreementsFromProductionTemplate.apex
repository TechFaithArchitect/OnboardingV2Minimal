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
opts.cleanupDuplicates = false; // Set true to repoint/delete duplicate agreement, program-requirement, credential, training-system, and training-requirement rows.
opts.vendorNames = new Set<String>{
    // Add Vendor filter (optional). Leave empty to process all seeded rows.
    // 'Frontier',
    // 'PerfectVision'
};

// Also seed credential + training data to keep ECC model complete in one run.
VendorProgramSeedService.Result result = VendorProgramSeedService.seedProgramsAndAgreements(opts);
result.mergeFrom(VendorProgramSeedService.seedVendorProgramRequirements(opts));
result.mergeFrom(VendorProgramSeedService.seedCredentialData(opts));
result.mergeFrom(VendorProgramSeedService.seedTrainingSystems(opts));
result.mergeFrom(VendorProgramSeedService.seedTrainingRequirements(opts));
System.debug(LoggingLevel.INFO, 'VendorProgramSeedService.seedProgramsAndAgreements(+program-requirements+credentials+training+training-requirements) summary: ' + result.summary());
for (String warningMessage : result.warnings) {
    System.debug(LoggingLevel.WARN, warningMessage);
}
