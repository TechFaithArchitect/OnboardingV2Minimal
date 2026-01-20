/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_echosign_dev1_SIGN_AgreementTrigger on echosign_dev1__SIGN_Agreement__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(echosign_dev1__SIGN_Agreement__c.SObjectType);
}