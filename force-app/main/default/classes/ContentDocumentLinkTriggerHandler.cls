/**
 * @description       : 
 * @author            : Tushar Chopade
 * @last modified on  : 02-28-2023
 * @last modified by  : Tushar Chopade
**/
public class ContentDocumentLinkTriggerHandler implements ITriggerHandler{

  /*****Implements interfaces methods*****/
  public static Boolean TriggerDisabled = false;  
  public void BeforeInsert(List<SObject> newItems) {}
  public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
  public void BeforeDelete(Map<Id, SObject> oldItems) {}
  public void AfterDelete(Map<Id, SObject> oldItems) {}
  public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
  public void AfterUndelete(Map<Id, SObject> oldItems) {}
  public Boolean IsDisabled() {
    return TriggerDisabled;
  }

  /*****Process on document insert*****/
  public void AfterInsert(Map<Id, SObject> newItems) {
    Map<Id, ContentDocumentLink> newMap = (Map<Id, ContentDocumentLink>)newItems;
    ContentDocumentLinkDomain.prepareDocument(newMap);
  }
  
}