/**
 * @description       : 
 * @author            : Tushar Chopade
 * @last modified on  : 03-01-2023
 * @last modified by  : Tushar Chopade
**/
public class ContentDocumentSelector {

    public static List<ContentDocumentLink> getContentDocumentLinkList(Set<Id> conDocIdSet){
        List<ContentDocumentLink> conDocList = [SELECT ID,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink 
                                                WHERE ContentDocumentId IN : conDocIdSet];
        return conDocList;
    }

    public static List<Document__c> getDocumentDetails(Set<Id> linkedEntityIdSet){
        List<Document__c> documentList = [SELECT ID,Name,Opportunity__c,Account__c,Contact__c, 
                                          /*Added by Priti Chande*/ Content_Document_Id__c /*Ended Here*/
                                         FROM Document__c 
                                         WHERE 
                                         Opportunity__c IN : linkedEntityIdSet 
                                         OR Account__c IN : linkedEntityIdSet 
                                         OR Contact__c IN : linkedEntityIdSet 
                                        //  OR CP_Tracker__c IN : linkedEntityIdSet //Added by Rahul(Thinqloud) 19-05-2023
                                        //  OR Term_Sheet__c IN : linkedEntityIdSet//Added by Rahul(Thinqloud) 20-03-2023 : Termsheet lookup field for record deletion added in query
                                         OR Case__c IN : linkedEntityIdSet //Added by Rahul(Thinqloud) 30-05-2023 
                                         ];
        return documentList;
    }
}