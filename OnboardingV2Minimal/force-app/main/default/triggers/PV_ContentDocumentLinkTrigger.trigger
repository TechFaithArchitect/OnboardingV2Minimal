trigger PV_ContentDocumentLinkTrigger on ContentDocumentLink (before insert, after insert) {
   
    If(trigger.isAfter && trigger.isInsert){
        PV_ContentDocumentLinkTriggerHandler.handleAfterInsert(Trigger.New);
    }
    If(trigger.isBefore && trigger.isInsert){
        PV_ContentDocumentLinkTriggerHandler.handleBeforeInsert(Trigger.New);
    }
}