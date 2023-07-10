public class EventAndActionUtility {
	/*public static Map<String, Map<String, String>> getObjectSpecifierMap(String objectName){
        List<Object_Event_Specifier__mdt> objectSpecifierList = [SELECT Id, MasterLabel,Object_Name__c, Field_Value__c, Field_Name__c from Object_Event_Specifier__mdt where Object_Name__c =: objectName];
        map<String, map<String, String>> fieldNameVSFieldValueVSEventMap = new map<String, map<String, String>>();
        for(Object_Event_Specifier__mdt objectSpecifier : objectSpecifierList){
                if(fieldNameVSFieldValueVSEventMap.containsKey(objectSpecifier.Field_Name__c)){
                    Map<String, String> fieldValueVsEventName = fieldNameVSFieldValueVSEventMap.get(objectSpecifier.Field_Name__c);
                    fieldValueVsEventName.put(objectSpecifier.Field_Value__c, objectSpecifier.MasterLabel) ;
                    fieldNameVSFieldValueVSEventMap.put(objectSpecifier.Field_Name__c, fieldValueVsEventName);
                }else{
                    fieldNameVSFieldValueVSEventMap.put(objectSpecifier.Field_Name__c , new map<String, String>
                                                        {objectSpecifier.Field_Value__c => objectSpecifier.MasterLabel});
                }
        }
        return fieldNameVSFieldValueVSEventMap;
    }*/
    
    public static Map<String, Map<String, Map<String, String>>> getObjectSpecifierMap(String objectName){
        List<Object_Event_Specifier__mdt> objectSpecifierList = [SELECT Id, MasterLabel,Object_Name__c, Field_Value__c, Field_Name__c, RecordTypeName__c from Object_Event_Specifier__mdt where Object_Name__c =: objectName];
        Map<String,Map<String,Map<String,String>>> objectVsFieldVsValueMap = new Map<String,Map<String,Map<String,String>>>();
        for(Object_Event_Specifier__mdt objectSpecifier : objectSpecifierList){
            if(objectVsFieldVsValueMap.containsKey(objectSpecifier.RecordTypeName__c)){
                map<String, map<String, String>> fieldNameVSFieldValueVSEventMap = objectVsFieldVsValueMap.get(objectSpecifier.RecordTypeName__c);
                if(fieldNameVSFieldValueVSEventMap.containsKey(objectSpecifier.Field_Name__c)){
                    Map<String, String> fieldValueVsEventName = fieldNameVSFieldValueVSEventMap.get(objectSpecifier.Field_Name__c);
                    fieldValueVsEventName.put(objectSpecifier.Field_Value__c, objectSpecifier.MasterLabel) ;
                    fieldNameVSFieldValueVSEventMap.put(objectSpecifier.Field_Name__c, fieldValueVsEventName);
                }else{
                    fieldNameVSFieldValueVSEventMap.put(objectSpecifier.Field_Name__c , new map<String, String>
                                                        {objectSpecifier.Field_Value__c => objectSpecifier.MasterLabel});
                }
                objectVsFieldVsValueMap.put(objectSpecifier.RecordTypeName__c, fieldNameVSFieldValueVSEventMap);
            }else{
                objectVsFieldVsValueMap.put(objectSpecifier.RecordTypeName__c , 
                                        new map<String, map<String, String>>{objectSpecifier.Field_Name__c => new map<String, String>
                                                                            {objectSpecifier.Field_Value__c => objectSpecifier.MasterLabel}});
            }
        }
        return objectVsFieldVsValueMap;
    }


    public static Action_Task_Generator_Event__e getPlatformEvent(String eventName, String dateTimeString, String userName, String recordId, 
                                                    String customData, String objectName){
       EventAndActionHandler.JSONWrapper  jsonWrapper = new EventAndActionHandler.JSONWrapper(eventName, dateTimeString, userName, recordId,'',objectName); 
        Action_Task_Generator_Event__e actionEvent = new Action_Task_Generator_Event__e();
        actionEvent.Payload__c = JSON.serialize(jsonWrapper);
        return actionEvent;
    }
    
        public static Action_Task_Tracker_Event__e getPlatformEventForTaskTracker(String eventName, String dateTimeString, String userName, String recordId, 
                                                    String customData, String objectName,String actionTrackerId){
       EventAndActionHandler.JSONWrapper  jsonWrapper = new EventAndActionHandler.JSONWrapper(eventName, dateTimeString, userName, recordId,'',objectName,actionTrackerId); 
        Action_Task_Tracker_Event__e actionEvent = new Action_Task_Tracker_Event__e();
        actionEvent.Payload__c = JSON.serialize(jsonWrapper);
        return actionEvent;
    }


   /* public static Event_Audit__c getEventAudit(){
        Event_Audit__c eventAudit = new Event_Audit__c();
        return eventAudit;
    }*/
}