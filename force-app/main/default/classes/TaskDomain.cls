public without sharing class TaskDomain {
    public static void createSubTask(Map<Id, Task> newMap){
        String recordTypeId =Schema.SObjectType.Task.getRecordTypeInfosByName().get(label.Task_Activity_Record_Type_Name).getRecordTypeId();//Added by Priti Chande(24/02/2023) - to get activity record type id
        Set<Id> documentChecklistIdSet = new Set<Id>();
        Map<Id,List<Document__c>> documentMap = new Map<Id,List<Document__c>>();// Id vs List of document
        List<Task> subTaskList = new List<Task>();
        for(Task tsk : newMap.values()){
            if(tsk.Document_Checklist__c != null){
                documentChecklistIdSet.add(tsk.Document_Checklist__c);
            }
        }
        List<Document__c> documentList = new List<Document__c>();
        if(!documentChecklistIdSet.isEmpty() && documentChecklistIdSet.size() > 0){
            documentList = TaskSelector.documentList(documentChecklistIdSet);
            //[Select Id, Document_Checklist__c,Name from Document__c where Document_Checklist__c IN :documentChecklistIdSet];
        }
        if(!documentList.isEmpty() && documentList.size() >0){
            for(Document__c document : documentList){
                if(documentMap.containsKey(document.Document_Checklist__c)){
                    if(!documentMap.get(document.Document_Checklist__c).isEmpty() && documentMap.get(document.Document_Checklist__c).size() > 0){
                        //Get List of record to which current document is to be appended
                        List<Document__c> docList = documentMap.get(document.Document_Checklist__c);
                        docList.add(document);
                        documentMap.put(document.Document_Checklist__c, docList);
                    }
                }
                else{
                    documentMap.put(document.Document_Checklist__c,new List<Document__c>{document});
                }
            }
        }
        if(!newMap.isEmpty() && newMap.size() > 0){
            for(Task task : newMap.values()){
                if(task.Document_Checklist__c != null){
                    if (!documentMap.isEmpty() && documentMap.size() > 0) {
                        if(documentMap.containsKey(task.Document_Checklist__c)){
                            if(!documentMap.get(task.Document_Checklist__c).isEmpty() && documentMap.get(task.Document_Checklist__c).size() > 0 ){
                                // Iterate over list of document
                                for(Document__c document : documentMap.get(task.Document_Checklist__c)){
                                    Task subTask = new Task();
                                    subTask.Parent_Activity__c = task.Id; //task.Subject;
                                    subTask.Subject = task.Subject + ' - ' +document.Name ;
                                    subTask.Document_Checklist__c = task.Document_Checklist__c;
                                    subTask.Sub_Task__c = true;
                                    subTask.ActivityDate = task.ActivityDate; //Added by Priti chande(10/02/23)-To update acitivity Date
                                    subTask.Action_Template_Activity_Tracker__c = task.Action_Template_Activity_Tracker__c;
                                    subTask.OwnerId = task.OwnerId;
                                    subTask.RecordTypeId = recordTypeId;//Added by Priti Chande(24/02/2023) - to get activity record type id
                                    if(task.WhatId != null){
                                        subTask.WhatId = task.WhatId;
                                    }
                                    if(task.WhoId != null){
                                        subTask.WhoId = task.WhoId;
                                    }
                                    subTaskList.add(subTask);
                                }
                            }
                        }
                    }
                }
            }
        }
        if(!subTaskList.isEmpty() && subTaskList.size() > 0){  
            TaskTriggerHandler.TriggerDisabled = true;
            insert subTaskList;
        }
    }
    public static void taskCompletionVerification(Map<Id, Task> newMap, Map<Id, Task> oldMap){
        Set<Id> taskIdSet = new Set<Id>();
        Map<Id,List<Task>> subTaskMap = new Map<Id,List<Task>>();
        List<Task> subTaskList = new List<Task>();
        for(Task task : newMap.values()){
            if(newMap.get(task.Id).Status == TaskConstants.TASK_STATUS_COMPLETED && oldMap.get(task.Id).Status != newMap.get(task.Id).Status){
                taskIdSet.add(task.Id);
            }
        }
        subTaskList = TaskSelector.subTaskList(taskIdSet);
        //[Select Id, Parent_Activity__c, Subject, Status from Task where Parent_Activity__c IN : taskIdSet];
        if(!subTaskList.isEmpty() && subTaskList.size() > 0){
            for(Task task : subTaskList){
                if(subTaskMap.get(task.Parent_Activity__c) != null){
                    List<Task> subTaskTempList = subTaskMap.get(task.Parent_Activity__c);
                    subTaskTempList.add(task);
                    subTaskMap.put(task.Parent_Activity__c, subTaskTempList);
                }
                else{
                    subTaskMap.put(task.Parent_Activity__c, new List<Task>{task});
                }
            }
        }
        for(Task task : newMap.values()){
            if(newMap.get(task.Id).Status == TaskConstants.TASK_STATUS_COMPLETED && oldMap.get(task.Id).Status != newMap.get(task.Id).Status){
                if(!subTaskMap.isEmpty() && subTaskMap.size() > 0){
                    if(subTaskMap.containsKey(task.Id)){
                        if(!subTaskMap.get(task.Id).isEmpty() && subTaskMap.get(task.Id).size() > 0){
                            for(Task subTask : subTaskMap.get(task.Id)){
                                if(subTask.Status != TaskConstants.TASK_STATUS_COMPLETED){
                                    task.addError(TaskConstants.INCOMPLETE_SUBTASK_ERROR);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    /* public static void assignOwnertoDependantTask(Map<Id, Task> newMap, Map<Id, Task> oldMap){
Set<String> dependentActivityList = new Set<String>();
Set<Id> actionTemplateTrackerIdSet = new Set<Id>();
List<Task> dependantTaskList = new List<Task>();
Map<String, List<Task>> dependantTaskMap = new Map<String, List<Task>>();

//1. Create Subject set for tasks that are completed and do not have a dependant task name
//2. Create IdSet for Id of related action template activity tracker

for(Task task : newMap.values()){
if((newMap.get(task.Id).Dependent_Activity_Name__c == '' || newMap.get(task.Id).Dependent_Activity_Name__c == null) && newMap.get(task.Id).Status == 'Completed' 
&& newMap.get(task.Id).Status != oldMap.get(task.Id).Status){
dependentActivityList.add(newMap.get(task.Id).Subject);
actionTemplateTrackerIdSet.add(newMap.get(task.Id).Action_Template_Activity_Tracker__c);
}
}
dependantTaskList = [Select Id, Status, Subject, Action_Template_Activity_Tracker__c,Dependent_Activity_Name__c from Task where Dependent_Activity_Name__c IN : dependentActivityList AND Action_Template_Activity_Tracker__c IN : actionTemplateTrackerIdSet];
for(Task task : newMap.values()){
if((newMap.get(task.Id).Dependent_Activity_Name__c == '' || newMap.get(task.Id).Dependent_Activity_Name__c == null) && newMap.get(task.Id).Status == 'Completed' 
&& newMap.get(task.Id).Status != oldMap.get(task.Id).Status){

if(!dependantTaskList.isEmpty() && dependantTaskList.size() > 0){
for(Task dependantTask : dependantTaskList){
if(dependantTask.Dependent_Activity_Name__c == task.Subject && dependantTask.Action_Template_Activity_Tracker__c == task.Action_Template_Activity_Tracker__c){
if(dependantTaskMap.containsKey(task.Dependent_Activity_Name__c)){
if(dependantTaskMap.get(task.Dependent_Activity_Name__c) != null){
List<Task> taskList = new List<Task>();
taskList = dependantTaskMap.get(task.Dependent_Activity_Name__c);
dependantTaskMap.put(dependantTask.Dependent_Activity_Name__c, taskList);
}
}
else{
dependantTaskMap.put(dependantTask.Dependent_Activity_Name__c, new List<Task>{dependantTask});
}
}
}
}
}
}
for(Task task : newMap.values()){
if((newMap.get(task.Id).Dependent_Activity_Name__c == '' || newMap.get(task.Id).Dependent_Activity_Name__c == null) && newMap.get(task.Id).Status == 'Completed' 
&& newMap.get(task.Id).Status != oldMap.get(task.Id).Status){
if(!dependantTaskMap.isEmpty() && dependantTaskMap.size() > 0){
if(dependantTaskMap.containsKey(task.Subject)  && !dependantTaskMap.get(task.Subject).isEmpty() &&  dependantTaskMap.get(task.Subject).size() > 0){
for(Task dependantTask : dependantTaskMap.get(task.Subject)){
if(dependantTask.Dependent_Activity_Name__c == task.Subject && dependantTask.Action_Template_Activity_Tracker__c == task.Action_Template_Activity_Tracker__c){
dependantTask.OwnerId = task.OwnerId;
}
}
}   
}
}
}
} */
    
/********************************************************************************************************
* @author          Priti Chande
* @description     This Method is used for publish tracker event after task status is completed         
* @return          List<Task> taskList List of Task
* @date            06/02/2023
********************************************************************************************************/
public static void publishActivityTrackerEvent(List<Task> taskList){
        List<Action_Task_Tracker_Event__e> platformEventList = new List<Action_Task_Tracker_Event__e>();
        for(Task taskRecord : taskList){
            platformEventList.add(EventAndActionUtility.getPlatformEventForTaskTracker('Action Task Completion Tracker', String.valueOf(System.now()), UserInfo.getUserId(), taskRecord.Id,'','Task',taskRecord.Action_Template_Activity_Tracker__c));
        }
        if(!platformEventList.isEmpty() && platformEventList.size() > 0 ){
            Integer i = 0;
            List<Database.SaveResult> results = EventBus.publish(platformEventList);
            
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        //commentted by Priti Chande(09/02/2023)-code review is pending
                    /*    Event_Audit__c eventAuditRecord = new Event_Audit__c();
                        eventAuditRecord.Type__c = 'Error';
                        eventAuditRecord.Error_Message__c = 'Error returned: ' + err.getStatusCode() + ' - ' +  err.getMessage();
                        eventAuditRecord.Salesforce_RecordId__c = taskList[i].Id ; //Add Tracker ID here
                        System.debug('Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                        eventAuditList.add(eventAuditRecord);
                        i++;*/
                    }
                }       
            }
           // insert eventAuditList;
        }
    }
/********************************************************************************************************
* @author          Rahul Jog
* @description     Trigger on task to assign Parent account ID
* @return          void
* @date            15/03/2023
********************************************************************************************************/
    public static void assignParentAccountId(List<Task> taskList){
        String relatedrecordObject;
        //Get Account object type
        Schema.sObjectType parentType = Account.sObjectType;
        Schema.SObjectType relatedrecordObjectType;
        List<Schema.SObjectField> fieldList = new List<Schema.SObjectField>();
        String parentQuery;
        String childQuery = ' ';
        Map<String, String> accountReferenceFieldMap = new  Map<String, String>();
        List<Task> fetchTaskList = new List<Task>();
        List<Task> updateTaskList = new List<Task>();
        Set<Id> taskIdSet = new Set<Id>();
        //Get relations of task record and their related field reference to Account Object
        for(Task taskRecord : taskList){
            if(taskRecord.WhatId != null){
                relatedrecordObject = taskRecord.WhatId.getSobjectType().getDescribe().getName();
            }
            if(relatedrecordObject != null && relatedrecordObject != ''){
                relatedrecordObjectType = ((SObject) Type.forName(relatedrecordObject).newInstance()).getSObjectType();
            }
            if(relatedrecordObjectType != null){
                fieldList = relatedrecordObjectType.getDescribe().fields.getMap().values();
            }
            String accountFieldName;
            if(!fieldList.isEmpty() && fieldList.size() > 0){
                for (Schema.SObjectField field : fieldList) {
                    Schema.DescribeFieldResult fieldDesc = field.getDescribe();
                    if (Schema.DisplayType.REFERENCE == fieldDesc.getType() &&
                        new Set<Schema.sObjectType>(fieldDesc.getReferenceTo()).contains(parentType)) {
                        accountFieldName = String.valueOf(field);
                        break;
                    }
                }
            }
            if(relatedrecordObject != null && relatedrecordObject != '' && accountFieldName != null && accountFieldName != ''){
                accountReferenceFieldMap.put(relatedrecordObject,accountFieldName);
            }
            taskIdSet.add(taskRecord.Id);
        }
        //Query Task record and their related to reference object
        if(accountReferenceFieldMap.size() > 0 && !accountReferenceFieldMap.isEmpty()){
            parentQuery = 'SELECT Id, WhatId, Account__c, TypeOf What ';
            for(String objName : accountReferenceFieldMap.keySet()){
                childQuery += ' WHEN '+objName + ' THEN ' + accountReferenceFieldMap.get(objName);
            }
            parentQuery += childQuery + ' END  FROM Task where WhatId != null and Account__c = null and AccountId = null and Id IN : taskIdSet';
        } 
        if(taskIdSet.size() > 0 && !taskIdSet.isEmpty() && parentQuery != null && parentQuery != ''){
            fetchTaskList = Database.query(parentQuery);
        }
        //Update task account reference field 
        if(!fetchTaskList.isEmpty() && fetchTaskList.size() > 0){
            for(Task taskRecord : fetchTaskList){
                if(accountReferenceFieldMap.size() > 0 && !accountReferenceFieldMap.isEmpty()){
                    if(accountReferenceFieldMap.containsKey(taskRecord.WhatId.getSobjectType().getDescribe().getName())){
                        SObject whatRecord = taskRecord.What;
                        String parentAccountField = (String) whatRecord.get(accountReferenceFieldMap.get(taskRecord.WhatId.getSobjectType().getDescribe().getName()));
                        if(parentAccountField != null){
                            taskRecord.Account__c = Id.valueOf(parentAccountField);
                        }
                    }   
                }
                Task updateTask = new Task(Id = taskRecord.Id, Account__c = taskRecord.Account__c);
                updateTaskList.add(updateTask);
            }
        }
        if(!updateTaskList.isEmpty() && updateTaskList.size() > 0){
            update updateTaskList;
        }
    }
/********************************************************************************************************
* @author          Rahul Jog
* @description     Trigger to Update Parent Status fields
* @return          void
* @date            29/05/2023
********************************************************************************************************/
    public static void assignParentStatus(List<Task> taskList){
        Set<String> taskSubjectSet = new Set<String>();
        Map<Id,SObject> updateParentObjectMap = new Map<Id,SObject>();
        Set<Id> taskIdSet = new Set<Id>();
        List<Task> taskParentRecordTypeList = new List<Task>();
        Map<Id,String> taskParentRecordTypeMap = new Map<Id,String>();
        List<Update_Task_Parent_Specifier__mdt> updateTaskParentList = new List<Update_Task_Parent_Specifier__mdt>();
        for(Task task : taskList){
            if(task.Subject != null){
                taskSubjectSet.add(task.Subject);
                taskIdSet.add(task.Id);
            }
        }
        if(!taskIdSet.isEmpty() && taskIdSet.size() > 0){
            taskParentRecordTypeList = TaskSelector.fetchParentRecordTypeList(taskIdSet);
        }
        if(!taskParentRecordTypeList.isEmpty() && taskParentRecordTypeList.size() > 0){
            for(Task taskRecord : taskParentRecordTypeList){
                if(taskRecord.What.RecordType.DeveloperName != null){
                    taskParentRecordTypeMap.put(taskRecord.Id, taskRecord.What.RecordType.DeveloperName);
                }
            }
        }
        updateTaskParentList = TaskSelector.getTaskParentFields(taskSubjectSet);
        for(Task task : taskList){
            if(!updateTaskParentList.isEmpty() && updateTaskParentList.size() > 0){
                for(Update_Task_Parent_Specifier__mdt updateTaskParent : updateTaskParentList){
                    if(updateTaskParent.Task_Status__c == task.Status && updateTaskParent.Task_Subject__c == task.Subject && updateTaskParent.Parent_Object__c == task.WhatId.getSObjectType().getDescribe().getName()
                    && taskParentRecordTypeMap.get(task.Id) != null && updateTaskParent.Parent_RecordType__c == taskParentRecordTypeMap.get(task.Id)){
                        //Dynamic design such that it updates all kinds of Parent SObjects
                        SObject sobj = (SObject)Type.forName(task.WhatId.getSObjectType().getDescribe().getName()).newInstance();
                        sobj.put('Id', task.WhatId);
                        if(updateParentObjectMap.get((Id)sobj.get('Id')) != null){
                            SObject updateSobj = updateParentObjectMap.get((Id)sobj.get('Id')) ;
                            if(updateTaskParent.Parent_Field__c != null && updateTaskParent.Field_Value__c != null){
                                updateSobj.put(updateTaskParent.Parent_Field__c, updateTaskParent.Field_Value__c);
                            }
                            updateParentObjectMap.put((Id)sobj.get('Id'), updateSobj);
                        }
                        else{
                            if(updateTaskParent.Parent_Field__c != null && updateTaskParent.Field_Value__c != null){
                                sobj.put(updateTaskParent.Parent_Field__c, updateTaskParent.Field_Value__c);
                            }
                            updateParentObjectMap.put((Id)sobj.get('Id'), sobj);
                        }
                    }
                }
            }
        }
        if(!updateParentObjectMap.values().isEmpty() && updateParentObjectMap.values().size() > 0){
            update updateParentObjectMap.values();
        }
    }
}