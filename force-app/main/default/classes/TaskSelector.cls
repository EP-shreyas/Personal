public without sharing class TaskSelector {
    public static List<Document__c> documentList(Set<Id> documentChecklistIdSet){
        List<Document__c> documentList = new List<Document__c>();
        documentList = [Select Id, Document_Checklist__c,Name from Document__c where Document_Checklist__c IN :documentChecklistIdSet];
        return documentList;
    }
    public static List<Task> subTaskList(Set<Id> taskIdSet){
        List<Task> subTaskList = new List<Task>();
        subTaskList = [Select Id, Parent_Activity__c, Subject, Status from Task where Parent_Activity__c IN : taskIdSet];
        return subTaskList;
    }
/********************************************************************************************************
* @author          Rahul Jog
* @description     Returns custom metadata type records
* @return          List<Update_Task_Parent_Specifier__mdt>
* @date            29/05/2023
********************************************************************************************************/
    public static List<Update_Task_Parent_Specifier__mdt> getTaskParentFields(Set<String> taskSubjectSet){
        List<Update_Task_Parent_Specifier__mdt> updateTaskParentList = new List<Update_Task_Parent_Specifier__mdt>();
        updateTaskParentList = [Select Id, Parent_Field__c,Field_Value__c, Parent_Object__c, Parent_RecordType__c, Task_Status__c,Task_Subject__c
                             from Update_Task_Parent_Specifier__mdt 
                            where Task_Subject__c IN : taskSubjectSet];
        return updateTaskParentList;
    }
/********************************************************************************************************
* @author          Rahul Jog
* @description     Returns task list with it's Parent's RecordType
* @return          List<Task>
* @date            29/05/2023
********************************************************************************************************/
    public static List<Task> fetchParentRecordTypeList(Set<Id> taskIdSet){
        List<Task> taskParentRecordTypeList = new List<Task>();
        taskParentRecordTypeList = [Select Id, What.RecordType.DeveloperName from Task where Id IN : taskIdSet];
        return taskParentRecordTypeList;
    }
}