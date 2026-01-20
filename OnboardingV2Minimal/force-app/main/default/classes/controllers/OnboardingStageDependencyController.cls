/**
 * Controller for Stage Dependency Viewer component
 */
public with sharing class OnboardingStageDependencyController {

    /**
     * Gets stages with dependency information for visualization
     * @param processId The onboarding process ID
     * @param vendorProgramId The vendor program ID (optional, for completion status)
     * @return List of StageWithDependencyDTO objects
     */
    @AuraEnabled(cacheable=true)
    public static List<StageWithDependencyDTO> getStagesWithDependencies(Id processId, Id vendorProgramId) {
        ValidationHelper.requireId(processId, 'Process ID');
        
        List<StageWithDependencyDTO> stageWithDependencyDTOList = new List<StageWithDependencyDTO>();
        
        // Get all stages for the process
        // Note: Repository returns Display_Order__c, not Sequence__c
        List<Onboarding_Application_Stage__c> stages = OnboardingApplicationRepository.fetchStagesForProcess(processId);
        
        // Get completed stages if vendor program is provided
        Set<Id> completedStageIds = new Set<Id>();
        if (vendorProgramId != null) {
            completedStageIds = OnboardingStageDependencyRepository.getCompletedStageIds(vendorProgramId, processId);
        }
        
        // Get all dependencies for all stages (bulk query)
        Set<Id> stageIds = new Set<Id>();
        for (Onboarding_Application_Stage__c onboardingStage : stages) {
            stageIds.add(onboardingStage.Id);
        }
        List<Onboarding_Application_Stage_Dependency__c> allDependencies = 
            OnboardingStageDependencyRepository.getDependenciesForTargetStages(stageIds);
        
        // Build map of dependencies by target stage
        Map<Id, List<Onboarding_Application_Stage_Dependency__c>> dependenciesByStage = 
            new Map<Id, List<Onboarding_Application_Stage_Dependency__c>>();
        for (Onboarding_Application_Stage_Dependency__c stageDependency : allDependencies) {
            if (!dependenciesByStage.containsKey(stageDependency.Target_Stage__c)) {
                dependenciesByStage.put(stageDependency.Target_Stage__c, new List<Onboarding_Application_Stage_Dependency__c>());
            }
            dependenciesByStage.get(stageDependency.Target_Stage__c).add(stageDependency);
        }
        
        // Build DTOs
        for (Onboarding_Application_Stage__c onboardingStage : stages) {
            StageWithDependencyDTO stageDTO = new StageWithDependencyDTO();
            stageDTO.stageId = onboardingStage.Id;
            stageDTO.stageName = onboardingStage.Name;
            // Use Display_Order__c as sequence (repository doesn't query Sequence__c)
            stageDTO.sequence = onboardingStage.Display_Order__c != null ? Integer.valueOf(onboardingStage.Display_Order__c) : 0;
            stageDTO.isCompleted = completedStageIds.contains(onboardingStage.Id);
            stageDTO.isBlocked = false;
            stageDTO.requiredStageIds = new List<Id>();
            
            // Get dependencies for this stage
            List<Onboarding_Application_Stage_Dependency__c> stageDependencies = dependenciesByStage.get(onboardingStage.Id);
            if (stageDependencies != null && !stageDependencies.isEmpty()) {
                for (Onboarding_Application_Stage_Dependency__c stageDependency : stageDependencies) {
                    if (stageDependency.Required__c == true) {
                        for (Onboarding_App_Stage_Dependency_Member__c dependencyMember : stageDependency.Onboarding_App_Stage_Dependency_Members__r) {
                            if (dependencyMember.Required_Stage__c != null && dependencyMember.Required__c != false) {
                                stageDTO.requiredStageIds.add(dependencyMember.Required_Stage__c);
                                
                                // Check if blocked (dependency not met)
                                if (!completedStageIds.contains(dependencyMember.Required_Stage__c)) {
                                    stageDTO.isBlocked = true;
                                }
                            }
                        }
                    }
                }
            }
            
            stageWithDependencyDTOList.add(stageDTO);
        }
        
        // Sort by sequence
        stageWithDependencyDTOList.sort(new StageSequenceComparator());
        
        return stageWithDependencyDTOList;
    }

    /**
     * DTO for stage with dependency information
     */
    public class StageWithDependencyDTO {
        @AuraEnabled public Id stageId;
        @AuraEnabled public String stageName;
        @AuraEnabled public Integer sequence;
        @AuraEnabled public Boolean isCompleted;
        @AuraEnabled public Boolean isBlocked;
        @AuraEnabled public List<Id> requiredStageIds;
    }

    /**
     * Comparator for sorting stages by sequence
     */
    private class StageSequenceComparator implements Comparator<StageWithDependencyDTO> {
        public Integer compare(StageWithDependencyDTO a, StageWithDependencyDTO b) {
            if (a.sequence < b.sequence) return -1;
            if (a.sequence > b.sequence) return 1;
            return 0;
        }
    }
}