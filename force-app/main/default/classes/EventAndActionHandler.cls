/**
* @description       : 
* @author            : Ishwari Gaikwad(Thinqloud)
* @group             : 
* @last modified on  : 01-30-2023
* @last modified by  : Ishwari Gaikwad(Thinqloud)
**/
public without sharing class EventAndActionHandler {
    
    public Static void identifyAndPublishEvent(List<Sobject> changeEventList,String ObjectName){ 
        List<Action_Task_Generator_Event__e> platformEventList = new List<Action_Task_Generator_Event__e>();
        Schema.SObjectType sObjectType = changeEventList.getSObjectType();
        if (sObjectType != null)
        {
            String listType = 'List<' + sObjectType + '>';
            List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
            castRecords.addAll(changeEventList);
            Map<String, Map<String, Map<String, String>>> recordTypevVsfieldVsValueVsEventNameMap = EventAndActionUtility.getObjectSpecifierMap(ObjectName);
            Set<String> recordIdSet = new Set<String>();
            for (SObject event : castRecords) {
                Map<String,Object> apiNameObjectMap = event.getPopulatedFieldsAsMap();
                // Get some event header fields
                EventBus.ChangeEventHeader header = (EventBus.ChangeEventHeader) apiNameObjectMap.get('ChangeEventHeader');
                // For update operations, we can get a list of changed fields
                if (header.changetype == 'UPDATE' || header.changetype == 'CREATE') {
                    for(String recordId : header.recordids){
                        recordIdSet.add(recordId);
                    }
                }
            }
            //check sObject has record Type exist or not... Akshay Salunke
            List<RecordType> recordTypeList = [select Id from RecordType where SObjectType = :ObjectName];
            Map<String, String> idVSRecordTypeName = new Map<String, String>();
            List<SObject> recordList = new List<SObject> ();
            if(recordTypeList.size() > 0){
                recordList = Database.query('SELECT Id, RecordTypeId, RecordType.DeveloperName FROM '+ObjectName+' WHERE Id IN: recordIdSet');
                for(SObject record : recordList){
                    String recordTypeName = (String)record.getSobject('RecordType').get('DeveloperName');
                    idVSRecordTypeName.put((Id)record.get('Id'), recordTypeName);
                }
            }else{
                recordList = Database.query('SELECT Id FROM '+ObjectName+' WHERE Id IN: recordIdSet');        
                for(SObject record : recordList){
                    idVSRecordTypeName.put((Id)record.get('Id'), null); 
                }
            }   
            for (SObject event : castRecords) {
                Map<String,Object> apiNameObjectMap = event.getPopulatedFieldsAsMap();
                // Get some event header fields
                EventBus.ChangeEventHeader header = (EventBus.ChangeEventHeader) apiNameObjectMap.get('ChangeEventHeader');
                // For update operations, we can get a list of changed fields
                if (header.changetype == 'UPDATE' || header.changetype == 'CREATE') {
                    for(String recordId : header.recordids){
                        system.debug('recordId:'+recordId);
                        //Changes Added by Akshay... To fetch custom metata values based on recordTypeName...
                        Map<String, Map<String,String>> fieldVsValueVsEventNameMap = new Map<String, Map<String,String>>();
                        Map<String, Map<String,String>> fieldVsValueVsEventNameMapForNull = new Map<String, Map<String,String>>();//Added by Priti chande(Date-20/03/2023)-To check if recordType Is null

                        if(idVSRecordTypeName.containsKey(recordId) && idVSRecordTypeName.get(recordId) <> null){
                           
                            if(recordTypevVsfieldVsValueVsEventNameMap.containsKey(idVSRecordTypeName.get(recordId))){
                                fieldVsValueVsEventNameMap = recordTypevVsfieldVsValueVsEventNameMap.get(idVSRecordTypeName.get(recordId)); 
                            }else{
                              //  fieldVsValueVsEventNameMap = recordTypevVsfieldVsValueVsEventNameMap.get(null); 
                            }
                        }else{
                            fieldVsValueVsEventNameMap = recordTypevVsfieldVsValueVsEventNameMap.get(idVSRecordTypeName.get(recordId));
                        }
                        if(fieldVsValueVsEventNameMap != null  && !fieldVsValueVsEventNameMap.containsKey(null))//Added by Priti chande(Date-20/03/2023)-To check if recordType Is null
                        fieldVsValueVsEventNameMapForNull = recordTypevVsfieldVsValueVsEventNameMap.get(null); 
                              system.debug('field:'+header);

                            for (String field : header.changedFields) {
                            if (event.get(field) <> null) {
                                Map<String,String> fieldValueVsEventNameMap = new Map<String,String>();
                                Map<String,String> fieldValueVsEventNameMapForNull = new Map<String,String>();//Added by Priti chande(Date-20/03/2023)-To check if recordType Is null

                                if(fieldVsValueVsEventNameMap != null){
                                    if(fieldVsValueVsEventNameMap.containsKey(field) && fieldVsValueVsEventNameMap.get(field) != null){
                                        fieldValueVsEventNameMap = fieldVsValueVsEventNameMap.get(field); 
                                    }
                                }

                               if(fieldVsValueVsEventNameMapForNull != null){//Added by Priti chande(Date-20/03/2023)-To check if recordType Is null
                                  if(fieldVsValueVsEventNameMapForNull.containsKey(field) && fieldVsValueVsEventNameMapForNull.get(field) != null){
                                            fieldValueVsEventNameMapForNull = fieldVsValueVsEventNameMapForNull.get(field); 
                                        }
                                    }//Ended here(20/03/2023)

                                String eventName;
                                if(fieldValueVsEventNameMap <> null){
                                    eventName = fieldValueVsEventNameMap.get(String.valueOf(event.get(field)));
                                    if(String.isBlank(eventName)){//Added by Priti chande(Date-21/03/2023)-To check if recordType Is null
                                      if(fieldValueVsEventNameMapForNull <> null){
                                       eventName = fieldValueVsEventNameMapForNull.get(String.valueOf(event.get(field)));
                                      }
                                    }//Ended here(21/03/2023)
                                    if(String.isNotBlank(eventName))//Added by Priti chande(Date-21/02/2023)-to avoid blank eventName 
                                        platformEventList.add(EventAndActionUtility.getPlatformEvent(eventName, String.valueOf(System.now()),String.valueOf(header.commituser), recordId,'',header.entityname));
                                }
                            }
                        }
                    }
                }
            }
        }
        if(!platformEventList.isEmpty() && platformEventList.size() > 0 ){
            List<Database.SaveResult> results = EventBus.publish(platformEventList);
            
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                    }
                }       
            }
        }
    }
    
    public class JSONWrapper{
        public String eventName;
        public String dateTimeString;
        public String userId;
        public String recordId;
        public String customData;
        public String objectName;
        public String actionTrackerId;
        
        public JSONWrapper( String eventName, String dateTimeString, 
                           String userId, String recordId, 
                           String customData, String objectName ){
                               this.eventName = eventName;
                               this.dateTimeString = dateTimeString;
                               this.userId = userId;
                               this.recordId = recordId;
                               this.customData = customData;
                               this.objectName = objectName;
                           }
        public JSONWrapper( String eventName, String dateTimeString, 
                           String userId, String recordId, 
                           String customData, String objectName,String actionTrackerId ){
                               this.eventName = eventName;
                               this.dateTimeString = dateTimeString;
                               this.userId = userId;
                               this.recordId = recordId;
                               this.customData = customData;
                               this.objectName = objectName;
                               this.actionTrackerId = actionTrackerId;
                               
                           }
        
    }
}