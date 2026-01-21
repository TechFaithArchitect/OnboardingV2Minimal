public with sharing class OnboardingRulesService {
    
    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rule__c> getRulesEngineRecords(Id engineId) {
        return OnboardingRulesRepository.fetchRulesEngineRecords(engineId);
    }

    @AuraEnabled
    public static Onboarding_Status_Rule__c createOrUpdateRule(Onboarding_Status_Rule__c statusRuleRecord) {
        return OnboardingRulesRepository.upsertRule(statusRuleRecord);
    }

    @AuraEnabled
    public static void deleteRule(Id ruleId) {
        OnboardingRulesRepository.deleteRule(ruleId);
    }

    public class OnboardingEvaluationContext {
        public Map<Id, Onboarding_Requirement__c> requirementsByVPR;
        public Id vendorProgramId;
        public List<Id> groupIds;
    }

    public static OnboardingEvaluationContext getEvaluationContext(Id onboardingId) {
        Onboarding__c onboarding = OnboardingRulesRepository.fetchOnboardingWithRequirements(onboardingId);
        
        if (onboarding == null) return null;
        
        OnboardingEvaluationContext context = new OnboardingEvaluationContext();
        context.vendorProgramId = onboarding.Vendor_Customization__c;
        
        context.requirementsByVPR = new Map<Id, Onboarding_Requirement__c>();
        for (Onboarding_Requirement__c onboardingRequirement : onboarding.Onboarding_Requirements__r) {
            context.requirementsByVPR.put(onboardingRequirement.Vendor_Program_Requirement__c, onboardingRequirement);
        }
        
        context.groupIds = getVendorProgramGroupIds(context.vendorProgramId);
        
        return context;
    }

    public static List<Onboarding_Status_Rules_Engine__c> getRulesForGroups(List<Id> groupIds) {
        return OnboardingRulesRepository.fetchRulesForGroups(groupIds);
    }

    public static Map<Id, Map<Id, Onboarding_Requirement__c>> getRequirementsByVPRBulk(Set<Id> onboardingIds) {
        Map<Id, Map<Id, Onboarding_Requirement__c>> requirementsByOnboardingByVPR = new Map<Id, Map<Id, Onboarding_Requirement__c>>();
        
        List<Onboarding_Requirement__c> requirements = OnboardingRulesRepository.fetchRequirementsByOnboardingIds(onboardingIds);
        
        for (Onboarding_Requirement__c onboardingRequirement : requirements) {
            if (!requirementsByOnboardingByVPR.containsKey(onboardingRequirement.Onboarding__c)) {
                requirementsByOnboardingByVPR.put(onboardingRequirement.Onboarding__c, new Map<Id, Onboarding_Requirement__c>());
            }
            if (onboardingRequirement.Vendor_Program_Requirement__c != null) {
                requirementsByOnboardingByVPR.get(onboardingRequirement.Onboarding__c).put(onboardingRequirement.Vendor_Program_Requirement__c, onboardingRequirement);
            }
        }
        
        return requirementsByOnboardingByVPR;
    }

    public static Map<Id, Id> getVendorProgramIdsBulk(Set<Id> onboardingIds) {
        Map<Id, Id> vendorProgramIdByOnboardingId = new Map<Id, Id>();
        
        List<Onboarding__c> onboardings = OnboardingRulesRepository.fetchOnboardingsByIds(onboardingIds);
        
        for (Onboarding__c onboardingRecord : onboardings) {
            vendorProgramIdByOnboardingId.put(onboardingRecord.Id, onboardingRecord.Vendor_Customization__c);
        }
        
        return vendorProgramIdByOnboardingId;
    }

    public static Map<Id, List<Id>> getVendorProgramGroupIdsBulk(Set<Id> vendorProgramIds) {
        Map<Id, List<Id>> groupIdsByVendorProgramId = new Map<Id, List<Id>>();
        
        List<Vendor_Program_Group_Member__c> members = OnboardingRulesRepository.fetchGroupMembersByVendorProgramIds(vendorProgramIds);
        
        for (Vendor_Program_Group_Member__c groupMember : members) {
            if (!groupIdsByVendorProgramId.containsKey(groupMember.Required_Program__c)) {
                groupIdsByVendorProgramId.put(groupMember.Required_Program__c, new List<Id>());
            }
            groupIdsByVendorProgramId.get(groupMember.Required_Program__c).add(groupMember.Vendor_Program_Group__c);
        }
        
        return groupIdsByVendorProgramId;
    }
    
    public static List<Id> getVendorProgramGroupIds(Id vendorProgramId) {
        List<Id> groupIds = new List<Id>();
        
        List<Vendor_Program_Group_Member__c> members = OnboardingRulesRepository.fetchGroupMembersByVendorProgramId(vendorProgramId);
        
        for (Vendor_Program_Group_Member__c groupMember : members) {
            groupIds.add(groupMember.Vendor_Program_Group__c);
        }
        
        return groupIds;
    }

    /**
     * Gets rules engines by vendor program group and requirement group
     * @param vendorProgramGroupId Vendor Program Group ID
     * @param requirementGroupId Requirement Group ID
     * @return List of rules engines
     */
    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rules_Engine__c> getRulesEngines(Id vendorProgramGroupId, Id requirementGroupId) {
        return OnboardingRulesRepository.fetchRulesEnginesByGroups(vendorProgramGroupId, requirementGroupId);
    }

    /**
     * Gets rules engines by vendor program group only
     * @param vendorProgramGroupId Vendor Program Group ID
     * @return List of rules engines
     */
    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rules_Engine__c> getRulesEnginesByVendorProgramGroup(Id vendorProgramGroupId) {
        return OnboardingRulesRepository.fetchRulesEnginesByVendorProgramGroup(vendorProgramGroupId);
    }

    /**
     * Gets a single rules engine by ID
     * @param ruleId Rules engine ID
     * @return Rules engine or null if not found
     */
    @AuraEnabled(cacheable=true)
    public static Onboarding_Status_Rules_Engine__c getRulesEngine(Id ruleId) {
        return OnboardingRulesRepository.fetchRulesEngineById(ruleId);
    }

    /**
     * Gets conditions (rules) for a rules engine
     * @param ruleId Rules engine ID
     * @return List of status rules
     */
    @AuraEnabled(cacheable=true)
    public static List<Onboarding_Status_Rule__c> getConditions(Id ruleId) {
        return OnboardingRulesRepository.fetchConditionsByRuleId(ruleId);
    }

    /**
     * Saves (updates) rules engines in bulk
     * @param rulesEngines List of rules engines to update
     */
    @AuraEnabled
    public static void saveRulesEngines(List<Onboarding_Status_Rules_Engine__c> rulesEngines) {
        if (rulesEngines == null || rulesEngines.isEmpty()) {
            return;
        }
        OnboardingRulesRepository.updateRulesEngines(rulesEngines);
    }

    /**
     * Saves (upserts) a single rules engine
     * @param rulesEngine Rules engine to upsert
     * @return Upserted rules engine
     */
    @AuraEnabled
    public static Onboarding_Status_Rules_Engine__c saveRulesEngine(Onboarding_Status_Rules_Engine__c rulesEngine) {
        ValidationHelper.requireRecord(rulesEngine, 'Rules engine');
        return OnboardingRulesRepository.upsertRulesEngine(rulesEngine);
    }

    /**
     * Saves (upserts) conditions in bulk
     * @param conditions List of status rules to upsert
     */
    @AuraEnabled
    public static void saveConditions(List<Onboarding_Status_Rule__c> conditions) {
        if (conditions == null || conditions.isEmpty()) {
            return;
        }
        OnboardingRulesRepository.upsertConditions(conditions);
    }
}