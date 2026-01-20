/**
 * Data Transfer Object for status evaluation trace information
 * Used by preview evaluation feature to show which rules were evaluated and their results
 */
public class StatusEvaluationTraceDTO {
    @AuraEnabled public Id engineId;
    @AuraEnabled public String engineName;
    @AuraEnabled public Id groupId;
    @AuraEnabled public String groupName;
    @AuraEnabled public Integer ruleNumber;
    @AuraEnabled public String ruleName;
    @AuraEnabled public String requirementName;
    @AuraEnabled public String expectedStatus;
    @AuraEnabled public Boolean passed;
    @AuraEnabled public String shortCircuitReason;
    @AuraEnabled public String resultingStatus;
    @AuraEnabled public String evaluationLogic;
    @AuraEnabled public Integer ruleOrder;

    public StatusEvaluationTraceDTO() {
        this.passed = false;
        this.ruleOrder = 0;
    }
}
