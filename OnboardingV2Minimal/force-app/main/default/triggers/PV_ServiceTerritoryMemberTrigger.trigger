/**
 * @description       : PV_ServiceTerritoryMemberTrigger
 * @author            : Muhammed Shanid
 * @last modified on  : 05-12-2023
 * Modifications Log
 * Ver   Date         Author             Modification
 * 1.0   05-12-2023   Muhammed Shanid   Initial Version
 **/
trigger PV_ServiceTerritoryMemberTrigger  on ServiceTerritoryMember (after insert,after update, after delete) {
    
    
    If(trigger.isAfter && trigger.isInsert){
        PV_ServiceTerritoryMemberTriggerHandler.createParentrStm(trigger.newMap.keySet());
    }
    If(trigger.isAfter && (trigger.isUpdate || trigger.isDelete)){
        PV_ServiceTerritoryMemberTriggerHandler.updatePrimaryStm(trigger.old,trigger.newMap);
    }
    
}