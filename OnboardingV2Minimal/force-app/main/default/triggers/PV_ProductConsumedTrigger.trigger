trigger PV_ProductConsumedTrigger on ProductConsumed (after insert) {
    if(trigger.isAfter && trigger.isInsert){
        PV_ProductConsumedTriggerHandler.createAsset(Trigger.NewMap);
    }
}