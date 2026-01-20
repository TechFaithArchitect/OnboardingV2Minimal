public with sharing class OnboardingApplicationRepository {

    public static List<Onboarding_Application_Stage__c> fetchStagesForProcess(Id processId) {
        if (processId == null) {
            return new List<Onboarding_Application_Stage__c>();
        }
        return [
            SELECT 
                Id, 
                Name, 
                Display_Order__c,
                Label__c,
                Next_Stage__c,
                Required__c,
                Onboarding_Component_Library__r.Component_API_Name__c, 
                Onboarding_Component_Library__c
            FROM Onboarding_Application_Stage__c
            WHERE Onboarding_Application_Process__c = :processId
            ORDER BY Display_Order__c ASC
        ];
    }

    public static Onboarding_Application_Process__c fetchProcessDetails(Id processId) {
        if (processId == null) {
            return null;
        }
        List<Onboarding_Application_Process__c> processes = [
            SELECT Id, Name, Description__c
            FROM Onboarding_Application_Process__c
            WHERE Id = :processId
            LIMIT 1
        ];
        return processes.isEmpty() ? null : processes[0];
    }

    public static Onboarding_Application_Progress__c fetchProgress(Id vendorProgramId, Id processId) {
        if (vendorProgramId == null || processId == null) {
            return null;
        }
        List<Onboarding_Application_Progress__c> progressList = [
            SELECT Id, Current_Stage__c
            FROM Onboarding_Application_Progress__c
            WHERE Vendor_Program__c = :vendorProgramId 
              AND Onboarding_Application_Process__c = :processId
            LIMIT 1
        ];
        return progressList.isEmpty() ? null : progressList[0];
    }

    public static Onboarding_Application_Progress__c fetchProgressByVendorProgram(Id vendorProgramId) {
        if (vendorProgramId == null) {
            return null;
        }
        List<Onboarding_Application_Progress__c> progressList = [
            SELECT Id, Onboarding_Application_Process__c
            FROM Onboarding_Application_Progress__c
            WHERE Vendor_Program__c = :vendorProgramId
            LIMIT 1
        ];
        return progressList.isEmpty() ? null : progressList[0];
    }

    public static Id upsertProgress(Onboarding_Application_Progress__c progress) {
        upsert progress;
        return progress.Id;
    }

    public static void insertStageCompletion(Onboarding_Application_Stage_Completion__c completion) {
        insert completion;
    }

    public static void insertStageCompletions(List<Onboarding_Application_Stage_Completion__c> completions) {
        if (completions != null && !completions.isEmpty()) {
            insert completions;
        }
    }

    public static List<Onboarding_Application_Process__c> fetchActiveProcessesByName(String name) {
        if (String.isBlank(name)) {
            return new List<Onboarding_Application_Process__c>();
        }
        return [
            SELECT Id, Name
            FROM Onboarding_Application_Process__c
            WHERE Active__c = true
              AND Name = :name
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    public static List<Onboarding_Application_Process__c> fetchActiveProcesses() {
        return [
            SELECT Id, Name
            FROM Onboarding_Application_Process__c
            WHERE Active__c = true
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    public static Id insertProcess(Onboarding_Application_Process__c process) {
        insert process;
        return process.Id;
    }

    public static void insertStages(List<Onboarding_Application_Stage__c> stages) {
        if (stages != null && !stages.isEmpty()) {
            insert stages;
        }
    }

    public static void updateStages(List<Onboarding_Application_Stage__c> stages) {
        if (stages != null && !stages.isEmpty()) {
            update stages;
        }
    }
    
    /**
     * Fetches stage completion records for a vendor program and process.
     * @param vendorProgramId The vendor program ID
     * @param processId The process ID
     * @return List of stage completion records
     */
    public static List<Onboarding_Application_Stage_Completion__c> fetchStageCompletions(Id vendorProgramId, Id processId) {
        if (vendorProgramId == null || processId == null) {
            return new List<Onboarding_Application_Stage_Completion__c>();
        }
        return [
            SELECT Onboarding_Application_Stage__c
            FROM Onboarding_Application_Stage_Completion__c
            WHERE Vendor_Program__c = :vendorProgramId
              AND Onboarding_Application_Process__c = :processId
        ];
    }
}