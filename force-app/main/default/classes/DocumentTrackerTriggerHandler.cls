/**
* @description  Example trigger handler for the Document__c object.
*               In this example, we are checking on both before insert and before update to ensure that the 
*               name of the account does not include the string 'test'.
*               Note that we have to implement the other events (BeforeDelete, AfterInsert) etc even though 
*               we are not using them (yet).
* @author Chris Aldridge, http://chrisaldridge.com/triggers/lightweight-apex-trigger-framework/
* @date Dec 31, 2015
* @author Mark H. Morrison, https://github.com/MarkHMorrison/Lightweight-Trigger-Framework
* @date Sat Dec 29, 2018
*/
public class DocumentTrackerTriggerHandler implements ITriggerHandler {
    /* 
Allows unit tests (or other code) to disable this trigger for the transaction
To stop this trigger from firing while in a unit test, I could just add the following code to the test:
Document__cTriggerHandler.TriggerDisabled = true;
*/
    public static Boolean TriggerDisabled = false;
    public static Boolean isFirstTime = true;
    /*
Checks to see if the trigger has been disabled. For example, you could check a custom setting here.
In this example, a static property is used to disable the trigger.
In a unit test, you could use Document__cTriggerHandler.TriggerDisabled = true to completely disable the trigger.
*/
    public Boolean IsDisabled() {
        /*
Use the option below if you set up Custom Settings to controll Triggers
*/
        // if(TriggerSettings__c.Document__cTriggerDisabled__c = true) {
        //   return true;
        // } else {
        //   return TriggerDisabled;
        // }
        return TriggerDisabled;
    }
    
    public void BeforeInsert(List<SObject> newItems) {
        List<Document__c> newList = (List<Document__c>)newItems;

    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
        Map<Id, Document__c> newMap = (Map<Id, Document__c>)newItems;
        Map<Id, Document__c> oldMap = (Map<Id, Document__c>)oldItems;

       
    }
    public void BeforeDelete(Map<Id, SObject> oldItems) {
        Map<Id, Document__c> oldMap = (Map<Id, Document__c>)oldItems;
    }
    
    public void AfterInsert(Map<Id, SObject> newItems) {
        Map<Id, Document__c> newMap = (Map<Id, Document__c>)newItems;
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, Document__c> newMap = (Map<Id, Document__c>)newItems;
        Map<Id, Document__c> oldMap = (Map<Id, Document__c>)oldItems;
		List<Document__c> documentListCP = new List<Document__c>();
        List<Document__c> documentListProduct = new List<Document__c>();
        List<Document__c> documentList = new List<Document__c>(); 
        List<Document__c> docList = new List<Document__c>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> cpcsIdSet = new Set<Id>();
         Set<Id> productIdSet = new Set<Id>();
        for(Document__c document: newMap.values()){
            if(document.Approval_Status__c != oldMap.get(document.Id).Approval_Status__c && document.Opportunity__c <> null &&
               document.Approval_Status__c == 'Pending'){
                documentList.add(document);
                oppIdSet.add(document.Opportunity__c);
            }
            if(document.Approval_Status__c != oldMap.get(document.Id).Approval_Status__c && document.Approval_Status__c == 'Pending'){
                documentListCP.add(document);
            }
            //added by vipin
             if(document.Approval_Status__c != oldMap.get(document.Id).Approval_Status__c && document.Approval_Status__c == 'Pending' ){
                documentListProduct.add(document);
                   
                   //end
            }
            if(document.Approval_Status__c != oldMap.get(document.Id).Approval_Status__c && 
               (document.Approval_Status__c == 'Approved' || document.Approval_Status__c == 'Rejected') && document.Parent_Document__c == null){
                docList.add(document);
            }
        }
        
        if(!documentList.isEmpty() && documentList.size() > 0){
           DocumentTrackerDomain.updateSobjectFields(documentList,oppIdSet,'Opportunity');
        }
        if(!docList.isEmpty() && docList.size() > 0){
            DocumentTrackerDomain.updateDocumentFields(docList, newMap);
        }
        if(!documentListCP.isEmpty() && documentListCP.size() > 0){
          //DocumentTrackerDomain.updateCPTrackerFields(documentListCP);
            DocumentTrackerDomain.updateSobjectFields(documentListCP,cpcsIdSet,'CPCSTracker__c');
        }
        //added by vipin
        if(!documentListProduct.isEmpty() && documentListProduct.size() > 0){
            DocumentTrackerDomain.updateSobjectFields(documentListProduct,productIdSet,'Product2');
        }
        // end
    }
    
    
    
    public void AfterDelete(Map<Id, SObject> oldItems) {}
    
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    
    
}