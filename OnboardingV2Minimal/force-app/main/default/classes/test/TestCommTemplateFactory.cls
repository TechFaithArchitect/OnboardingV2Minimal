@isTest
public class TestCommTemplateFactory {

    public static Communication_Template__c createTemplate(Boolean doInsert) {
        Communication_Template__c template = new Communication_Template__c(
            Name = 'Test Template ' + DateTime.now().getTime(),
            Active__c = true
        );
        if (doInsert) insert template;
        return template;
    }
}