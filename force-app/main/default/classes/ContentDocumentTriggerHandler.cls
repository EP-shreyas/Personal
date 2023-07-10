/**
 * @description       : 
 * @author            : Tushar Chopade
 * @last modified on  : 03-01-2023
 * @last modified by  : Tushar Chopade
**/
public class ContentDocumentTriggerHandler implements ITriggerHandler {

    /*****Implements interfaces methods*****/
  public static Boolean TriggerDisabled = false;  
  public void BeforeInsert(List<SObject> newItems) {}
  public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
  public void AfterDelete(Map<Id, SObject> oldItems) {}
  public void AfterInsert(Map<Id, SObject> newItems) {
    //Added by Rahul Jog(Thinqloud) - 17-04-2023 - Start
    Map<Id, ContentDocument> newMap = (Map<Id, ContentDocument>)newItems;
    List<Id> idList = new List<Id>();
    for(ContentDocument contDocument : newMap.values()){
      idList.add(contDocument.Id);
    }
    if(!idList.isEmpty() && idList.size() > 0){
      ContentDocumentDomain.createDocumentLinkString(idList);
    }
    //Added by Rahul Jog(Thinqloud) - 17-04-2023 - End
  }
  public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
  public void AfterUndelete(Map<Id, SObject> oldItems) {}
  public Boolean IsDisabled() {
    return TriggerDisabled;
  }

  public void BeforeDelete(Map<Id, SObject> oldItems) {
    Map<Id, ContentDocument> oldMap = (Map<Id, ContentDocument>)oldItems;
    ContentDocumentDomain.processDocumentDeletion(oldMap);
    ContentDocumentDomain.processCaseDocumentDeletion(oldMap);//Added by Rahul Jog(Thinqloud) - 18-04-2023
  }
  
}