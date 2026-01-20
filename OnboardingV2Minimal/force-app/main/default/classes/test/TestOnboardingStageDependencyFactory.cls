@isTest
public class TestOnboardingStageDependencyFactory {

    public static Onboarding_Application_Process__c createProcessWithStages(Integer numStages, Boolean doInsert) {
        Integer stageCount = (numStages != null && numStages > 0) ? numStages : 0;
        Onboarding_Application_Process__c process = new Onboarding_Application_Process__c(
            Name = 'Test Process ' + DateTime.now().getTime(),
            Active__c = true
        );
        TestDataFactoryUtil.maybeInsert(process, doInsert);

        List<Onboarding_Application_Stage__c> stages = new List<Onboarding_Application_Stage__c>();
        for (Integer i = 1; i <= stageCount; i++) {
            stages.add(new Onboarding_Application_Stage__c(
                Name = 'Stage ' + i,
                Label__c = 'Stage ' + i,
                Display_Order__c = i,
                Onboarding_Application_Process__c = process.Id,
                Required__c = true
            ));
        }
        TestDataFactoryUtil.maybeInsert(stages, doInsert);

        return process;
    }

    public static Onboarding_Application_Stage_Dependency__c createStageDependency(
        Boolean doInsert,
        Id targetStageId,
        Id requiredStageId,
        Boolean required
    ) {
        return createStageDependency(doInsert, targetStageId, requiredStageId, null, required);
    }

    public static Onboarding_Application_Stage_Dependency__c createStageDependency(
        Boolean doInsert,
        Id targetStageId,
        Id requiredStageId,
        String logicType,
        Boolean required
    ) {
        List<Id> requiredStageIds = new List<Id>();
        if (requiredStageId != null) {
            requiredStageIds.add(requiredStageId);
        }
        return createStageDependency(doInsert, targetStageId, requiredStageIds, logicType, required, required);
    }

    public static Onboarding_Application_Stage_Dependency__c createStageDependency(
        Boolean doInsert,
        Id targetStageId,
        List<Id> requiredStageIds,
        String logicType,
        Boolean required
    ) {
        return createStageDependency(doInsert, targetStageId, requiredStageIds, logicType, required, required);
    }

    public static Onboarding_Application_Stage_Dependency__c createStageDependency(
        Boolean doInsert,
        Id targetStageId,
        List<Id> requiredStageIds,
        String logicType,
        Boolean required,
        Boolean memberRequired
    ) {
        String resolvedLogicType = resolveLogicType(logicType);
        Id resolvedRequiredStageId = targetStageId;
        if (requiredStageIds != null && !requiredStageIds.isEmpty()) {
            resolvedRequiredStageId = requiredStageIds[0];
        }

        Onboarding_Application_Stage_Dependency__c dependency = new Onboarding_Application_Stage_Dependency__c(
            Name = 'Dependency ' + DateTime.now().getTime(),
            Target_Stage__c = targetStageId,
            Required_Stage__c = resolvedRequiredStageId,
            Required__c = required != null ? required : true,
            Logic_Type__c = resolvedLogicType
        );
        TestDataFactoryUtil.maybeInsert(dependency, doInsert);

        if (doInsert && requiredStageIds != null && !requiredStageIds.isEmpty()) {
            List<Onboarding_App_Stage_Dependency_Member__c> members = new List<Onboarding_App_Stage_Dependency_Member__c>();
            for (Id requiredId : requiredStageIds) {
                members.add(new Onboarding_App_Stage_Dependency_Member__c(
                    Stage_Dependency__c = dependency.Id,
                    Required_Stage__c = requiredId,
                    Required__c = memberRequired != null ? memberRequired : true
                ));
            }
            TestDataFactoryUtil.maybeInsert(members, doInsert);
        }

        return dependency;
    }

    public static Onboarding_Application_Stage_Completion__c createStageCompletion(
        Boolean doInsert,
        Id vendorProgramId,
        Id processId,
        Id stageId
    ) {
        Onboarding_Application_Stage_Completion__c completion = new Onboarding_Application_Stage_Completion__c(
            Vendor_Program__c = vendorProgramId,
            Onboarding_Application_Process__c = processId,
            Onboarding_Application_Stage__c = stageId
        );
        TestDataFactoryUtil.maybeInsert(completion, doInsert);
        return completion;
    }

    private static String resolveLogicType(String logicType) {
        List<String> validLogics = TestDataFactoryUtil.getPicklistValues(
            Onboarding_Application_Stage_Dependency__c.SObjectType,
            'Logic_Type__c'
        );
        if (String.isNotBlank(logicType) && validLogics.contains(logicType)) {
            return logicType;
        }
        return validLogics.isEmpty() ? null : validLogics[0];
    }
}