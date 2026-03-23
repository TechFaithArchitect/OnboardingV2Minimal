VendorProgramSeedService.Options opts = new VendorProgramSeedService.Options();
opts.dryRun = false;
opts.seedTrainingSystems = false;
opts.seedTrainingRequirements = false;
opts.seedVendorProgramRequirements = false;
opts.cleanupDuplicates = false; // Set true to repoint/delete duplicate credential rows and dependencies.
opts.vendorNames = new Set<String>{
    // Add Vendor filter (optional). Leave empty to process all seeded rows.
    // 'Verizon',
    // 'WOW'
};

VendorProgramSeedService.Result result = VendorProgramSeedService.seedCredentialData(opts);
System.debug(LoggingLevel.INFO, 'VendorProgramSeedService.seedCredentialData summary: ' + result.summary());
for (String warningMessage : result.warnings) {
    System.debug(LoggingLevel.WARN, warningMessage);
}
