trigger PV_ServiceTerritoryTrigger on ServiceTerritory (after update) {
    If(trigger.isAfter && trigger.isUpdate){
        PV_ServiceTerritoryTriggerHandler.handleAfterUpdate(Trigger.New);
    }
}