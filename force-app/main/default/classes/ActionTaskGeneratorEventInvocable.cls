public without sharing class ActionTaskGeneratorEventInvocable {
    @InvocableMethod
    public static void getpayload(List<String> payload){

        String recordTypeId =Schema.SObjectType.Task.getRecordTypeInfosByName().get(System.label.Task_Activity_Record_Type_Name).getRecordTypeId();//Added by Priti Chande(24/02/2023) - to get activity record type id
        List<Task> taskList = new List<Task>();
        Map<String,String> parsePayload = new Map<String,String>();
        parsePayload = (Map<String,String>)JSON.deserialize(payload[0],Map<String,String>.class);
        List<Event_Activity_Template_Mapper__c> eventActivityMap = new List<Event_Activity_Template_Mapper__c>();
        if(parsePayload.size() > 0 && parsePayload.get('eventName') != null){
            eventActivityMap = [Select Id, Action_Template__c, Action_Template__r.Status__c, Action_Template__r.Template_Type__c,
                                Apex_Class_to_Call__c,Event_Type__c, Flow_to_Call__c, Name 
                                from Event_Activity_Template_Mapper__c 
                                where Name = :parsePayload.get('eventName') AND 
                                Action_Template__r.Status__c = 'Active'
                                limit 1];
        }
        if(eventActivityMap.size() > 0 && eventActivityMap[0].Action_Template__r.Template_Type__c == 'Activity'){// Added by Ishwari (13/02/2023)
            Action_Template_Activity_Tracker__c activityTemplateTracker = new Action_Template_Activity_Tracker__c();
            activityTemplateTracker.Name = parsePayload.get('eventName');
            activityTemplateTracker.Action_Start_Datetime__c = System.now();
            activityTemplateTracker.Action_Status__c = 'Initiated';
            activityTemplateTracker.Data_Payload_Passed__c = payload[0];
            activityTemplateTracker.Object_Name__c = parsePayload.get('objectName');
            activityTemplateTracker.Record_Id__c = parsePayload.get('recordId');
            activityTemplateTracker.UserId__c = parsePayload.get('userId');//added by Priti chande(24/02/23) - to get change event user
            //Added By Akshay
            activityTemplateTracker.Action_Template_Name__c= eventActivityMap[0].Action_Template__c; 
            insert activityTemplateTracker;
            List<Action_Template_Activity_List__c> actionActivityTempList = new List<Action_Template_Activity_List__c>();
            //Added by Akshay Action_By__c field in Query
            actionActivityTempList = [Select Id, Name,Action_Template__c,OwnerId, Parent_Activity_Name__c, Activity_Type__c, 
                                      Is_Mandatory__c, Document_Checklist_Name__c, Target_TAT__c, Use_Document_Checklist__c,
                                      Task_Description__c,Action_By_Entity__c 
                                      from Action_Template_Activity_List__c 
                                      where Action_Template__c =: eventActivityMap[0].Action_Template__c];
            
            // List<User> userList = [Select Id From user where name =: System.label.User_Name_For_Task_Assignment And IsActive = True];//Added by Priti Chande(21/02/2023)
            
            List<User> userList = [Select Id From user where name=: System.label.User_Name_For_Task_Assignment and IsActive=True];
            if(!actionActivityTempList.isEmpty() && actionActivityTempList.size() >0){
                for(Action_Template_Activity_List__c actionTemplate : actionActivityTempList){
                    Task tsk = new Task();
                    if(parsePayload.get('objectName') == 'Lead' || parsePayload.get('objectName') == 'Contact'){
                        tsk.WhoId = parsePayload.get('recordId');
                    }
                    else{
                        tsk.WhatId = parsePayload.get('recordId');
                    }
                    tsk.RecordTypeId = recordTypeId;//Added by Priti Chande(24/02/2023) - to set activity record type id
                    tsk.Status = 'Open';
                    tsk.Subject = actionTemplate.Name;
                    tsk.Action_Template_Activity_Tracker__c = activityTemplateTracker.Id;
                    if(actionTemplate.Parent_Activity_Name__c != null){
                        tsk.Parent_Activity__c = actionTemplate.Parent_Activity_Name__c;
                        tsk.OwnerId = userList.size() > 0 ? userList[0].Id : '';//Added by Priti Chande(21/02/2023)
                    }
                    else{
                        //tsk.OwnerId = UserInfo.getUserId();
                        if(actionTemplate.Action_By_Entity__c == 'User' || actionTemplate.Action_By_Entity__c == 'Queue')//Added by Priti Chande(11/02/23)-if blank then Owner will not assigned
                            tsk.OwnerId = actionTemplate.OwnerId;
                        
                    }
                    if(actionTemplate.Use_Document_Checklist__c == true){
                        tsk.Document_Checklist__c = actionTemplate.Document_Checklist_Name__c;
                    }
                    tsk.Action_Template_Activity_List__c = actionTemplate.Id;
                    if(actionTemplate.Target_TAT__c != null && actionTemplate.Parent_Activity_Name__c == null){//Added by Priti Chande(10/02/2023) -To avoid Null Error
                        tsk.ActivityDate = Date.today() + Integer.valueOf(actionTemplate.Target_TAT__c);}
                    tsk.Remarks__c = actionTemplate.Task_Description__c;//Added by Priti Chande(10/02/2023)-to update task Description
                    // Added by Ishwari : Start(13/02/2023)
                    if(actionTemplate.Activity_Type__c <> null && actionTemplate.Activity_Type__c <> ''){
                        tsk.Task_Type__c = actionTemplate.Activity_Type__c;//Added by Priti Chande(13/02/2023)
                        if(actionTemplate.Activity_Type__c == 'Call'){
                            tsk.TaskSubtype =  actionTemplate.Activity_Type__c;
                        }else if(actionTemplate.Activity_Type__c == 'Email'){
                            tsk.TaskSubtype =  actionTemplate.Activity_Type__c;
                        }
                    } // Added by Ishwari : END(13/02/2023)
                    taskList.add(tsk);
                }
            }
            if(!taskList.isEmpty() && taskList.size() > 0){
                insert taskList;
            }
        }    
    }
}