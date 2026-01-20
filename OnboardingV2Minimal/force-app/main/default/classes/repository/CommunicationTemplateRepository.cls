public with sharing class CommunicationTemplateRepository {
    
    // MOCK DATA OVERRIDE
    @TestVisible private static Map<String, Communication_Template__c> testMockTemplates;

    public static void setMockTemplates(Map<String, Communication_Template__c> templates) {
        testMockTemplates = templates;
    }

    // FETCH ALL COMM TEMPLATES FROM DB
    public static Map<String, Communication_Template__c> getAllTemplates() {
        if (Test.isRunningTest() && testMockTemplates != null) {
            return testMockTemplates;
        }

        Map<String, Communication_Template__c> templateMap = new Map<String, Communication_Template__c>();

        for (Communication_Template__c communicationTemplate : [
            SELECT Id, Name, DeveloperName__c, Email_Subject__c, Folder_Name__c,
                   Communication_Type__c, Active__c,
                   Email_Template_Id__c, Messaging_Template_Id__c, Messaging_Channel_Id__c, Message_Body__c
            FROM Communication_Template__c
        ]) {
            if (String.isNotBlank(communicationTemplate.DeveloperName__c)) {
                templateMap.put(communicationTemplate.DeveloperName__c, communicationTemplate);
            }
        }

        return templateMap;
    }

    // UPSERT LOGIC
    public static void upsertTemplates(List<Communication_Template__c> incomingRecords) {
        if (incomingRecords == null || incomingRecords.isEmpty()) return;

        Map<String, Communication_Template__c> existing = getAllTemplates();

        List<Communication_Template__c> toInsert = new List<Communication_Template__c>();
        List<Communication_Template__c> toUpdate = new List<Communication_Template__c>();

        for (Communication_Template__c incomingTemplate : incomingRecords) {
            String developerNameKey = incomingTemplate.DeveloperName__c;

            if (String.isBlank(developerNameKey)) continue;

            if (existing.containsKey(developerNameKey)) {
                Communication_Template__c existingTemplate = existing.get(developerNameKey);

                Boolean isUnchanged =
                    existingTemplate.Folder_Name__c == incomingTemplate.Folder_Name__c &&
                    existingTemplate.Email_Subject__c == incomingTemplate.Email_Subject__c &&
                    existingTemplate.Communication_Type__c == incomingTemplate.Communication_Type__c &&
                    existingTemplate.Active__c == incomingTemplate.Active__c;

                if (isUnchanged) {
                    System.debug('Skipped unchanged: ' + developerNameKey);
                    continue;
                }

                existingTemplate.Folder_Name__c = incomingTemplate.Folder_Name__c;
                existingTemplate.Email_Subject__c = incomingTemplate.Email_Subject__c;
                existingTemplate.Communication_Type__c = incomingTemplate.Communication_Type__c;
                existingTemplate.Active__c = incomingTemplate.Active__c;

                toUpdate.add(existingTemplate);
            } else {
                toInsert.add(incomingTemplate);
            }
        }

        if (!toInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(toInsert, false);
            System.debug('Inserted: ' + insertResults.size());
        }

        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(toUpdate, false);
            System.debug('Updated: ' + updateResults.size());
        }

        if (toInsert.isEmpty() && toUpdate.isEmpty()) {
            System.debug('No changes to upsert.');
        }
    }

    /**
     * Safely inserts or updates Communication_Template__c records in batches with retry logic.
     * This method provides robust error handling and retry capability for bulk operations.
     * 
     * @param records - List of Communication_Template__c to process
     * @param isInsert - true for insert, false for update
     */
    public static void saveWithRetry(List<Communication_Template__c> communicationTemplateRecords, Boolean isInsert) {
        if (communicationTemplateRecords == null || communicationTemplateRecords.isEmpty()) {
            System.debug('[DML] ⚪ No records to process.');
            return;
        }

        final Integer MAX_RETRIES = 2;
        final Integer BATCH_SIZE = 200;

        Integer total = communicationTemplateRecords.size();
        System.debug('[DML] ' + (isInsert ? '🟢 Inserting ' : '🟠 Updating ') + total + ' Communication Templates...');

        for (Integer batchStartIndex = 0; batchStartIndex < total; batchStartIndex += BATCH_SIZE) {
            Integer endIndex = Math.min(batchStartIndex + BATCH_SIZE, total);

            // ⚙️ Build batch manually to avoid subList() issues with SObjects
            List<Communication_Template__c> batch = new List<Communication_Template__c>();
            for (Integer recordIndex = batchStartIndex; recordIndex < endIndex; recordIndex++) {
                batch.add(communicationTemplateRecords[recordIndex]);
            }

            Integer attempt = 0;
            Boolean success = false;

            while (!success && attempt < MAX_RETRIES) {
                attempt++;
                try {
                    List<Database.SaveResult> saveResults = isInsert
                        ? Database.insert(batch, false)
                        : Database.update(batch, false);

                    List<Communication_Template__c> failed = new List<Communication_Template__c>();

                    for (Integer resultIndex = 0; resultIndex < saveResults.size(); resultIndex++) {
                        if (!saveResults[resultIndex].isSuccess()) {
                            failed.add(batch[resultIndex]);
                            Database.Error dmlError = saveResults[resultIndex].getErrors()[0];
                            System.debug('❌ [DML] ' + (isInsert ? 'Insert' : 'Update') + 
                                ' failed for ' + batch[resultIndex].DeveloperName__c + 
                                ' — ' + dmlError.getStatusCode() + ': ' + dmlError.getMessage());
                        }
                    }

                    if (failed.isEmpty()) {
                        success = true;
                        System.debug('✅ [DML] Batch succeeded on attempt ' + attempt + ' (' + batch.size() + ' records)');
                    } else if (attempt < MAX_RETRIES) {
                        batch = failed;
                        System.debug('🔁 [DML] Retrying ' + failed.size() + ' failed records...');
                    } else {
                        success = true;
                        System.debug('🚨 [DML] Permanent failures after ' + MAX_RETRIES + ' attempts.');
                    }

                } catch (Exception dmlException) {
                    System.debug('💥 [DML Exception] Attempt ' + attempt + ': ' + dmlException.getMessage());
                    if (attempt >= MAX_RETRIES) throw dmlException;
                }
            }
        }

        System.debug('[DML] ✅ Completed processing ' + total + ' records.');
    }
}