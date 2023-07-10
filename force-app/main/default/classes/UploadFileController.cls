/**
* @description       : 
* @author            : Priti Chande
* @last modified on  : 03-04-2023
* @last modified by  : Priti Chande
**/
public class UploadFileController {
    @AuraEnabled
    public static void clearData(Id recordId){
        List<String> filesToBeDeleted = new List<String>();
        String sObjectAPIName = recordId.getSObjectType().getDescribe().getName();
        List<Relationship_Names_on_Document_Trackers__mdt> relationShipName = [Select Parent_RelationShip_Name__c From Relationship_Names_on_Document_Trackers__mdt where
                                                                               label =: sObjectAPIName];
        String query = 'Select Id,Document_Type__c,Content_Document_Id__c'+ 
            ' from Document__c where Document_Type__c = Null And CreatedDate = today And '
            + relationShipName[0].Parent_RelationShip_Name__c +' =: recordId';
        for(Document__c doc : Database.query(query)){
            filesToBeDeleted.add(doc.Content_Document_Id__c);
        }
        if(filesToBeDeleted.size() > 0){
            getDocumentTypeList('',filesToBeDeleted,false); 
        }
    }
    /* Added By Priti Chande(16/05/2023)- to get Task realted recordId */
    @AuraEnabled(cacheable=true)
    public static Id getRecordIdOnTaskObject(Id recordId){
        Id recordIdValue =recordId;
        Task taskRecord = new Task();
        String sObjectAPIName = recordId.getSObjectType().getDescribe().getName();
        if(sObjectAPIName =='Task'){
            taskRecord = [Select Id, WhoId, WhatId from Task where Id =: recordId];
            if(taskRecord.WhatId != null){
                recordIdValue = taskRecord.WhatId;
            }else if(taskRecord.WhoId != null){
                recordIdValue = taskRecord.WhoId;
            }
            
        }
        return recordIdValue;
    }//Ended here(Priti Chande -16/05/23)
    @AuraEnabled(cacheable=true)
    public static List<String> getDocumentTypeOnRecordTypeList(Id recordId,String objectApiName){
        List<String> documentTypeList = new List<String>();
        String objectNameWithSameRecordType = label.Object_Names_With_Same_Record_Type_Names;
        List<String> objectNameWithSameRecordTypeList = objectNameWithSameRecordType.split(',');
        string query;
        String recordTypeName;
        Sobject sObj;
        List<Sobject> listOfSobj;
        String sObjectAPIName = recordId.getSObjectType().getDescribe().getName();
        String queryForRecordTypes = 'select Id from RecordType where SObjectType = : sObjectAPIName';
        listOfSobj = Database.query(queryForRecordTypes);
        if(listOfSobj.size() <= 0){
       // if(sObjectAPIName == 'CPCSTracker__c'){
       /* query = 'SELECT Name  FROM ' + sObjectAPIName + ' where Id = :recordId';
        sObj = Database.query(query);*/
        }else{
        query = 'SELECT RecordType.DeveloperName FROM ' + sObjectAPIName + ' where Id = :recordId';
        sObj = Database.query(query);
        recordTypeName = (string)sObj.getSObject('RecordType').get('DeveloperName');
        }
        if(objectNameWithSameRecordTypeList.contains(objectApiName)){
            objectApiName = '';
        }
        for(Document_Type_Record_Type_Mapping__mdt record : [Select label,Upload_Button_On_Object_Name__c From Document_Type_Record_Type_Mapping__mdt where
                                                             Record_Type_Name__c =: recordTypeName AND Upload_Button_On_Object_Name__c =:objectApiName]){
                                                                 documentTypeList.add(record.label);                                         
                                                             }
        System.debug(documentTypeList);
        return documentTypeList;
        
    }
    @AuraEnabled
    public static void getDocumentTypeList(string jsonString,List<String> filesToBeDeleted,boolean onSave){
        Set<String> documentList = new Set<String>();
        Map<String,String> documentIdVsTypeMap = new Map<String,String>();
        if(String.isNotBlank(jsonString)){
            jsonString = jsonString.removeStart('[');
            jsonString = jsonString.removeEnd(']');
            if(jsonString.startsWith('{')){
                jsonString = '[' + jsonString + ']';
            }
            List<documentWrp> documentWrpList = (List<documentWrp>)JSON.deserialize(jsonString, List<documentWrp>.class);
            for(documentWrp docWrp : documentWrpList){
                if(String.isNotBlank(docWrp.documentId) && onSave){
                    documentIdVsTypeMap.put(docWrp.documentId,docWrp.documentType);
                }else{
                    filesToBeDeleted.add(docWrp.documentId);
                }
            }
        }
        List<Document__c> docuToBeUpdated = new List<Document__c>(); 
        if(documentIdVsTypeMap.size() >0){
            for(Document__c doc :[Select Id,Document_Type__c,Content_Document_Id__c from Document__c where Content_Document_Id__c In:documentIdVsTypeMap.keySet()]){
                if(documentIdVsTypeMap.containsKey(doc.Content_Document_Id__c) && documentIdVsTypeMap.get(doc.Content_Document_Id__c) != null){
                    doc.Document_Type__c =documentIdVsTypeMap.get(doc.Content_Document_Id__c);
                    docuToBeUpdated.add(doc);
                }
            }
            if(docuToBeUpdated.size() > 0){
                try{
                    update docuToBeUpdated;
                }
                catch(exception e){
                    throw new AuraHandledException(e.getMessage());
                }
            }
        }
        
        List<ContentDocument> ListOfContDocumentToBeDeleted = new List<ContentDocument>();
        Set<String> filesToBeDeletedForContentDoc = new Set<String>();
        if(filesToBeDeleted.size() > 0){
            filesToBeDeletedForContentDoc.addAll(filesToBeDeleted);
        }
        if(filesToBeDeletedForContentDoc.size() > 0){
            for(ContentDocument contDoc : [Select Id From ContentDocument where Id In:filesToBeDeletedForContentDoc]){
                ListOfContDocumentToBeDeleted.add(contDoc);
            }
            if(ListOfContDocumentToBeDeleted.size() > 0){
                delete ListOfContDocumentToBeDeleted;
            }           
        }
    }
    
    public class documentWrp{
        @AuraEnabled
        public String documentType{get;set;}
        @AuraEnabled
        public String documentId{get;set;}
        @AuraEnabled
        public String id{get;set;}
        @AuraEnabled
        public String documentName{get;set;}
    }
}