/**
* @description       : 
* @author            : Ishwari Gaikwad(Thinqloud)
* @group             : 
* @last modified on  : 05-15-2023
* @last modified by  : Ishwari Gaikwad(Thinqloud)
**/
public class DocumentTrackerDomain {
     
    public static void updateSobjectFields(List<Document__c> newDocumentList , Set<Id> recordIdSet, String objectName){
        List<Document__c> updatedDocumentList = [SELECT Id, Approval_Status__c, Approved_Rejected_Date__c ,Approved_Rejected_By__c , 
                                                 Approver_Comments__c, Opportunity__c
                                                 from Document__c WHERE ID IN:newDocumentList];
        Map<String, Map<String, Map<String, String>>> recordTypeVsStatusVsFieldsMap = getObjectWiseApprovalFields(objectName);
        Map<String, String> objectNameVsFieldMap = getObjectWiseDocumentRelationField(objectName);
        Map<Id, SObject> sobjectMap = new Map<Id, sObject>();        
        Map<Id, SObject> idVsSobjectMap = new Map<Id, sObject>((List<sObject>)Database.query('Select Id, (Select Id, Approval_Status__c From Document__r where Approval_Status__c != null) From '+objectName+' Where Id IN: recordIdSet'));
        if(!recordTypeVsStatusVsFieldsMap.isEmpty() && recordTypeVsStatusVsFieldsMap.size() > 0){            
            for(Document__c document : updatedDocumentList){
                Map<String, String> fieldsList = recordTypeVsStatusVsFieldsMap.get(document.Document_Type__c).get(document.File_Type__c);
                Id recordId = String.valueOf(document.get(objectNameVsFieldMap.get(objectName)));
                SObject record = recordId.getSObjectType().newSObject(recordId);
                if(fieldsList <> null && !fieldsList.isEmpty()  && fieldsList.size() > 0){
                    for(String docFieldName : fieldsList.keySet()){
                        if(document.get(docFieldName) <> null){
                            if(document.get(docFieldName) == 'Pending'){
                                record.put(fieldsList.get(docFieldName),'Submitted for Approval');
                            }else if(document.get(docFieldName) == 'Approved' || document.get(docFieldName) == 'Rejected'){
                                if(idVsSobjectMap.get(recordId).getSObjects('Document__r') <> null){
                                    List<Document__c> documentList = idVsSobjectMap.get(recordId).getSObjects('Document__r');
                                    boolean isAllApproved = false;
                                    boolean isPending = false;
                                    for(Document__c documentRecord : documentList){
                                        if(documentRecord.Approval_Status__c == 'Approved'){
                                            isAllApproved = true;
                                        }else if(documentRecord.Approval_Status__c == 'Rejected'){
                                            isAllApproved = false;
                                            break;
                                        }else if(documentRecord.Approval_Status__c == 'Pending'){
                                            isPending = true;
                                            break;
                                        }
                                    }
                                    if(isAllApproved && !isPending){
                                        record.put(fieldsList.get(docFieldName),'Approved');
                                    }else if(!isAllApproved && !isPending){
                                        //Added by Rahul Jog(Thinqloud) : 01/06/2023 : Null check was added
                                        if(fieldsList.get(docFieldName) != null){
                                            record.put(fieldsList.get(docFieldName),'Rejected');
                                        }
                                    }
                                }
                            }else{
                                  //Added by Rahul Jog(Thinqloud) : 01/06/2023 : Null check was added
                                if(fieldsList.get(docFieldName) != null && document.get(docFieldName) != null){
                                	record.put(fieldsList.get(docFieldName),document.get(docFieldName));
                                }
                            }
                            
                        }
                        
                    }
                    sobjectMap.put(recordId, record);
                }
            }
            if(!sobjectMap.isEmpty() && sobjectMap.size() > 0){
                update sobjectMap.values();
            }
        }
    }
    
    public static void updateDocumentFields(List<Document__c> newDocList, Map<ID, Document__c> newMap){
        List<ProcessInstanceStep> processInstanceStepList = new List<ProcessInstanceStep>();
        //id docObjId;
        //Set<id> processInstanceIdSet = new Set<id>();
        Map<Id, Id> processInstanceIdVSTargetObjectIdMap = new Map<Id, Id>();
        List<ProcessInstance> processInstanceList =[select id,TargetObjectId from ProcessInstance where TargetObjectId IN :newDocList];
        for(ProcessInstance pi :processInstanceList){
            if(pi.TargetObjectId != null){
                processInstanceIdVSTargetObjectIdMap.put(pi.id, pi.TargetObjectId);
                //docObjId = pi.TargetObjectId;
                //processInstanceIdSet.add(pi.id); 
            }            
        }
        if(processInstanceList != null && processInstanceList.size() > 0){
            processInstanceStepList =[select id, Comments, CreatedDate, ActorId, ProcessInstanceId from ProcessInstanceStep where ProcessInstanceId IN :processInstanceIdVSTargetObjectIdMap.keySet() ORDER BY CreatedDate desc Limit 1];
        }
        list<Document__c> updateDocList = new list<Document__c>();
        if(processInstanceStepList != null && processInstanceStepList.size()>0){
            for(processInstanceStep psObj : processInstanceStepList){
                Document__c docObj = new Document__c();
                docObj.Approved_Rejected_By__c = psObj.ActorId;
                docObj.Approved_Rejected_Date__c = Date.valueof(psObj.CreatedDate);
                docObj.Approver_Comments__c = psObj.Comments;
                docObj.Id = processInstanceIdVSTargetObjectIdMap.get(psObj.ProcessInstanceId);//docObjId;
                updateDocList.add(docObj);
            }
          
            if(!updateDocList.isEmpty() && updateDocList.size() > 0){
                update updateDocList;
                List<Document__c> docForOppProcessList = new List<Document__c>();
                List<Document__c> docForCpProcessList = new List<Document__c>();
                 List<Document__c> docForProductProcessList = new List<Document__c>(); // added by Vipin
                
                Set<Id> oppIdSet = new Set<Id>();
                Set<Id> cpcsIdSet = new Set<Id>();
                Set<Id> productIdSet = new Set<Id>();  // added by vipin
                
                for(Document__c document : updateDocList){
                    if(newMap.get(document.Id).Opportunity__c <> null){
                        docForOppProcessList.add(document);
                        oppIdSet.add(newMap.get(document.Id).Opportunity__c);
                    }
                    // if(newMap.get(document.Id).CP_Tracker__c <> null ){
                    //     docForCpProcessList.add(document);
                    //     cpcsIdSet.add(newMap.get(document.Id).CP_Tracker__c);
                    // }
                    //added by vipin
                    // if(newMap.get(document.Id).Product__c <> null && newMap.get(document.Id).Parent_Record_Type__c == 'AIF_Fund'){
                    //     docForProductProcessList.add(document);
                    //     productIdSet.add(newMap.get(document.Id).Product__c);
                    // }
                    
                    //end
                }
                if(!docForOppProcessList.isEmpty() && docForOppProcessList.size() > 0){
                    updateSobjectFields(docForOppProcessList, oppIdSet,'Opportunity');
                }
                // if(!docForCpProcessList.isEmpty() && docForCpProcessList.size() > 0){
                //    updateSobjectFields(docForCpProcessList, cpcsIdSet,'CPCSTracker__c');
                // }
                // //added by vipin 
                // if(!docForProductProcessList.isEmpty() && docForProductProcessList.size() > 0){
                //     updateSobjectFields(docForProductProcessList, productIdSet,'Product2');
                // }
                
            }
            
        }
    }
    
    
    public static Map<String, Map<String, Map<String, String>>> getObjectWiseApprovalFields(String objectName){
        List<Object_Specific_Approval_Fields__mdt> approvalFieldsList = [Select Id, Approval_Status__c, Approved_Rejected_By__c, Approved_Rejected_Date__c,
                                                                         Approver_Comments__c, Object_Name__c, Status_Value__c 
                                                                         From Object_Specific_Approval_Fields__mdt Where Object_Name__c =:objectName];
        
        Map<String, Map<String, Map<String, String>>> recordTypeVsStatusVsFieldsMap = new Map<String, Map<String, Map<String,String>>>();
        
        for(Object_Specific_Approval_Fields__mdt approvalFields : approvalFieldsList){
            
            if(recordTypeVsStatusVsFieldsMap.containsKey(approvalFields.Record_Type_Name__c)){
                Map<String ,Map<String,String>> statusVsFieldsMap = recordTypeVsStatusVsFieldsMap.get(approvalFields.Record_Type_Name__c);
                statusVsFieldsMap.put(approvalFields.Status_Value__c, new Map<String,String>{'Approval_Status__c' => approvalFields.Approval_Status__c, 'Approved_Rejected_By__c' => approvalFields.Approved_Rejected_By__c, 
                    'Approved_Rejected_Date__c' => approvalFields.Approved_Rejected_Date__c, 'Approver_Comments__c' => approvalFields.Approver_Comments__c});
                recordTypeVsStatusVsFieldsMap.put(approvalFields.Record_Type_Name__c, statusVsFieldsMap);
            }else{
                recordTypeVsStatusVsFieldsMap.put(approvalFields.Record_Type_Name__c, 
                                                  new Map<String ,Map<String,String>>{approvalFields.Status_Value__c => 
                                                      new Map<String, String>{'Approval_Status__c' => approvalFields.Approval_Status__c, 'Approved_Rejected_By__c' => approvalFields.Approved_Rejected_By__c, 
                                                          'Approved_Rejected_Date__c' => approvalFields.Approved_Rejected_Date__c,'Approver_Comments__c' =>  approvalFields.Approver_Comments__c}});
            }
            
        }
        return recordTypeVsStatusVsFieldsMap;
    }
    
        public static  Map<String, String> getObjectWiseDocumentRelationField(String objectName){
        List<Object_Specific_Approval_Fields__mdt> approvalFieldsList = [Select Id, Approval_Status__c, Approved_Rejected_By__c, Approved_Rejected_Date__c,Lookup_Field_Name_on_Document__c,
                                                                         Approver_Comments__c, Object_Name__c, Record_Type_Name__c, Status_Value__c 
                                                                         From Object_Specific_Approval_Fields__mdt Where Object_Name__c =:objectName];
        Map<String, String> objectVsFieldNameMap = new  Map<String,String>();
        
        for(Object_Specific_Approval_Fields__mdt approvalFields : approvalFieldsList){
            
            objectVsFieldNameMap.put(objectName, approvalFields.Lookup_Field_Name_on_Document__c);
            
        }
        return objectVsFieldNameMap;
    }
}
    
