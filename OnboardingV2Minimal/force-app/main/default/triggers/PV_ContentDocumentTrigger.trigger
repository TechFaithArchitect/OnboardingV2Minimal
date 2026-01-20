trigger PV_ContentDocumentTrigger on ContentDocument (before delete) {
 if(Trigger.isdelete){
         PV_ContentDocumentLinkTriggerHandler.handleBeforeDelete(Trigger.old);
         
     }
}