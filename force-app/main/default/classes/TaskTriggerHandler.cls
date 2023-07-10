public without sharing class TaskTriggerHandler implements ITriggerHandler{
      /* 
    Allows unit tests (or other code) to disable this trigger for the transaction
    To stop this trigger from firing while in a unit test, I could just add the following code to the test:
    LeadTriggerHandler.TriggerDisabled = true;
  */
  public static Boolean TriggerDisabled = false;
  /*
    Checks to see if the trigger has been disabled. For example, you could check a custom setting here.
    In this example, a static property is used to disable the trigger.
    In a unit test, you could use LeadTriggerHandler.TriggerDisabled = true to completely disable the trigger.
  */
  public Boolean IsDisabled() {
    /*
      Use the option below if you set up Custom Settings to controll Triggers
    */
    // if(TriggerSettings__c.LeadTriggerDisabled__c = true) {
    //   return true;
    // } else {
    //   return TriggerDisabled;
    // }
    return TriggerDisabled;
  }

  public void BeforeInsert(List<SObject> newItems) {
      /*Added by Priti Chande(14/04/23)-To removew rich text format if record type is Interaction*/
      List<Task> newList = (List<Task>)newItems;
      Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(TaskConstants.INTERACTION_RECORD_TYPE).getRecordTypeId();
      for(Task task : newList){
          if(task.RecordTypeId == recordTypeId && String.isNotBlank(task.Description)){
              task.Description = task.Description.stripHtmlTags();
          }
      }//Ended here -Priti Chande(14/04/23)
  }

  public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    Map<Id, Task> newMap = (Map<Id, Task>)newItems;
    Map<Id, Task> oldMap = (Map<Id, Task>)oldItems;
    TaskDomain.taskCompletionVerification( newMap,  oldMap);
  }
  public void BeforeDelete(Map<Id, SObject> oldItems) {
    Map<Id, Task> oldMap = (Map<Id, Task>)oldItems;
  }
  public void AfterInsert(Map<Id, SObject> newItems) {
    Map<Id, Task> newMap = (Map<Id, Task>)newItems;
    List<Task> taskList = new List<Task>();
    if(!newMap.isEmpty() && newMap.size () > 0 && !TriggerDisabled){
      TaskDomain.createSubTask(newMap);
    }
    if(newMap.size() > 0){
      taskList = newMap.values();
    }
    if(taskList.size() > 0){
      TaskDomain.assignParentAccountId(taskList); // Assign parent account Id of related object
      TaskDomain.assignParentStatus(taskList);//Added by Rahul Jog(Thinqloud) 29/05/2023 : To update task parent status
    }
  }
  public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    List<Task> taskList = new List<Task>();
    Map<Id, Task> newMap = (Map<Id, Task>)newItems;
    Map<Id, Task> oldMap = (Map<Id, Task>)oldItems;
    List<Task> updateTaskParentList = new List<Task>();//Added by Rahul Jog(Thinqloud) 29/05/2023 

    for(Task taskRecord : newMap.values()){//Added by Rahul Jog(Thinqloud) 16/05/2023 : Added condition for 'Not Required' status
      if(taskRecord.Status != oldMap.get(taskRecord.Id).Status && (taskRecord.Status == TaskConstants.TASK_STATUS_COMPLETED || taskRecord.Status == TaskConstants.TASK_STATUS_NOT_REQUIRED)){
        taskList.add(taskRecord);
      }
      //START : Added by Rahul Jog(Thinqloud) 29/05/2023 : To update task parent status
      if(taskRecord.Status != oldMap.get(taskRecord.Id).Status && taskRecord.Status == TaskConstants.TASK_STATUS_COMPLETED){
        updateTaskParentList.add(taskRecord);
      }
      //END : Added by Rahul Jog(Thinqloud) 29/05/2023 : To update task parent status
    }
      if(taskList.size() > 0){
          TaskDomain.publishActivityTrackerEvent(taskList);
      }
      //START : Added by Rahul Jog(Thinqloud) 29/05/2023 : To update task parent status
      if(!updateTaskParentList.isEmpty() && updateTaskParentList.size() > 0){
        TaskDomain.assignParentStatus(updateTaskParentList);
      }
      //END : Added by Rahul Jog(Thinqloud) 29/05/2023 : To update task parent status
  }
  public void AfterDelete(Map<Id, SObject> oldItems) {}

  public void AfterUndelete(Map<Id, SObject> oldItems) {}

  
}