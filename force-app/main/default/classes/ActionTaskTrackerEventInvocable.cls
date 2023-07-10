/**
 * @description       : 
 * @author            : Ishwari Gaikwad(Thinqloud)
 * @group             : 
 * @last modified on  : 16-05-2023
 * @last modified by  : Rahul Jog(Thinqloud)
**/
public without sharing class ActionTaskTrackerEventInvocable {
    @InvocableMethod
    public static void actionTaskTracker(List<Action_Task_Tracker_Event__e> taskEventList) {
        
        Action_Task_Tracker_Event__e taskEvent = taskEventList[0];
        Map<String,String> deserialisedPayload = new Map<String,String>();
        deserialisedPayload = (Map<String,String>)JSON.deserialize(taskEvent.Payload__c,Map<String,String>.class);
        List<Task> dependantTaskToUpdate = new List<Task>();
        List<Task> dependantSubTaskToUpdate = new List<Task>();//Added by Priti Chande(13/02/23)
        Map<String,Task> dependantTaskIdWithTaskRecord = new Map<String,Task>();//Added by Priti Chande(13/02/23)
        List<Task> parentTaskToUpdate = new List<Task>();
       /* Action_Template_Activity_Tracker__c actionTemplateTracker = [SELECT Id, Action_Status__c,
                                                                    (SELECT Id, subject, Status, Parent_Activity__c, Sub_Task__c,
                                                                    Action_Template_Activity_List__r.Action_By__c,OwnerId,
                                                                    Action_Template_Activity_List__r.Action_By_Entity__c
                                                                    FROM Activities__r) 
                                                                    FROM Action_Template_Activity_Tracker__c 
                                                                    WHERE ID=: deserialisedPayload.get('ActionTrackerId') limit 1];
        */
        List<Task> taskList = [SELECT Id, subject, Status, Parent_Activity__c, Sub_Task__c,
        Action_Template_Activity_List__r.OwnerId,OwnerId,
        Action_Template_Activity_List__r.Action_By_Entity__c,Action_Template_Activity_Tracker__c,
        Action_Template_Activity_Tracker__r.Action_Status__c,Action_Template_Activity_List__r.Target_TAT__c
         FROM Task Where Action_Template_Activity_Tracker__c =: deserialisedPayload.get('actionTrackerId')];
        Integer i = 0;
        Map<String, List<Task>> subjectVsSubtaskListMap = new Map<String, List<Task>>();
        Map<String, List<Task>> subjectVsDependantTaskListMap = new Map<String, List<Task>>();
        Map<String, Task> subjectVsTaskMap = new Map<String, Task>();
        for(Task taskRecord : taskList){
            if(taskRecord.Parent_Activity__c <> null || taskRecord.Parent_Activity__c <> ''){
                if(taskRecord.Sub_Task__c){
                    if(subjectVsSubtaskListMap.containsKey(taskRecord.Parent_Activity__c)){
                        List<Task> tempTaskList = subjectVsSubtaskListMap.get(taskRecord.Parent_Activity__c);
                        tempTaskList.add(taskRecord);
                        subjectVsSubtaskListMap.put(taskRecord.Parent_Activity__c,tempTaskList);
                    }else{
                        subjectVsSubtaskListMap.put(taskRecord.Parent_Activity__c, new List<Task>{taskRecord});
                    }
                }else{
                    if(subjectVsDependantTaskListMap.containsKey(taskRecord.Parent_Activity__c)){
                        List<Task> tempTaskList = subjectVsDependantTaskListMap.get(taskRecord.Parent_Activity__c);
                        tempTaskList.add(taskRecord);
                        subjectVsDependantTaskListMap.put(taskRecord.Parent_Activity__c,tempTaskList);
                    }else{
                        subjectVsDependantTaskListMap.put(taskRecord.Parent_Activity__c, new List<Task>{taskRecord});
                    }
                }
            }
            subjectVsTaskMap.put(taskRecord.Subject, taskRecord);
        }

        for(Task taskRecord : taskList){
            if(taskRecord.Id == deserialisedPayload.get('recordId')){
                if(taskRecord.Status == 'Completed' && subjectVsSubtaskListMap.containsKey(taskRecord.Parent_Activity__c)){
                    Integer count = 0;
                    for(Task subTask : subjectVsSubtaskListMap.get(taskRecord.Parent_Activity__c)){
                        if(subTask.Status == 'Completed'){
                            count++;
                        }
                    }
                    if(subjectVsSubtaskListMap.get(taskRecord.Parent_Activity__c).size() == count){
                        if(subjectVsTaskMap.get(taskRecord.Parent_Activity__c) != null){
                        Task parentTask = subjectVsTaskMap.get(taskRecord.Parent_Activity__c);
                        parentTask.Status = 'Completed';
                        parentTaskToUpdate.add(parentTask);
                        }
                    }
                }

                if(taskRecord.Status == 'Completed' && subjectVsDependantTaskListMap.containsKey(taskRecord.Subject)){
                    //assign dependant tasks to the desired assignee

                    for(Task dependantTask : subjectVsDependantTaskListMap.get(taskRecord.Subject)){
                        if(dependantTask.Action_Template_Activity_List__r.Action_By_Entity__c == 'User'){
                            dependantTask.OwnerId = dependantTask.Action_Template_Activity_List__r.OwnerId;
                        }else if(dependantTask.Action_Template_Activity_List__r.Action_By_Entity__c == 'Queue'){
                         dependantTask.OwnerId = dependantTask.Action_Template_Activity_List__r.OwnerId;// get queue id here
                        }
                        //Added Priti Chande(11/02/2023) - To update due date when user/queuw assign to dependant task.
                        dependantTask.ActivityDate = Date.today() + Integer.valueOf(dependantTask.Action_Template_Activity_List__r.Target_TAT__c != null ?
                                                                                   dependantTask.Action_Template_Activity_List__r.Target_TAT__c : 0);//Ended here(Priti chande(11/02/2023))
                        dependantTaskToUpdate.add(dependantTask);
                        dependantTaskIdWithTaskRecord.put(dependantTask.Id,dependantTask);//Added by Priti Chande(13/02/2023)-To update sub task of dependend Task    

                    }
                    
                    
                    
                }
            }
            if(taskRecord.Status == 'Completed' || taskRecord.Status == 'Not Required'){//Added by Rahul Jog(Thinqloud) 16/05/2023 : Added condition for 'Not Required' status
                i++;
            }
             //Added by Priti Chande(13/02/2023)-To update sub task of dependend Task
              if(taskRecord.Sub_Task__c && dependantTaskIdWithTaskRecord.containsKey(taskRecord.Parent_Activity__c)){
                         taskRecord.ActivityDate = dependantTaskIdWithTaskRecord.get(taskRecord.Parent_Activity__c).ActivityDate;
                         taskRecord.OwnerId = dependantTaskIdWithTaskRecord.get(taskRecord.Parent_Activity__c).OwnerId;
                         dependantTaskToUpdate.add(taskRecord);
                    }//Ended Here(PC)

        }
        
        Action_Template_Activity_Tracker__c actionTemplateTracker = new Action_Template_Activity_Tracker__c();

        if(taskList.size() == i){

            actionTemplateTracker.Id = deserialisedPayload.get('actionTrackerId');
            actionTemplateTracker.Action_Status__c = 'Completed';
            actionTemplateTracker.Activity_Tracker_Payload__c = taskEvent.Payload__c;//Added by Priti Chande (10/02/23)-To get payload string
            actionTemplateTracker.UserId__c =  deserialisedPayload.get('userId');//added by Priti chande(24/02/23) - to get change event user
            update actionTemplateTracker;
        }else{//Added by Priti Chande (10/02/23)-To update Tracker status if task is in Progress
            actionTemplateTracker.Id = deserialisedPayload.get('actionTrackerId');
            actionTemplateTracker.Action_Status__c = 'In Progress';
            actionTemplateTracker.Activity_Tracker_Payload__c = taskEvent.Payload__c;
            actionTemplateTracker.UserId__c =  deserialisedPayload.get('userId');//added by Priti chande(24/02/23) - to get change event user
            update actionTemplateTracker;

        }//Ended here
        if(!dependantTaskToUpdate.isEmpty() && dependantTaskToUpdate.size() > 0){
            update dependantTaskToUpdate;
        }
        if(!parentTaskToUpdate.isEmpty() && parentTaskToUpdate.size() > 0){
            update parentTaskToUpdate;
        }
    }
}