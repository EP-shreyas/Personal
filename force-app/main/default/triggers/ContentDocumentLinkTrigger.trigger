/**
 * @description       : 
 * @author            : Tushar Chopade
 * @last modified on  : 03-01-2023
 * @last modified by  : Tushar Chopade
**/
trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert,before update,before delete,after insert,after update,after delete,after undelete) {

    TriggerDispatcher.Run(new ContentDocumentLinkTriggerHandler(), Trigger.operationType);

}