/**
 * @description       : 
 * @author            : Tushar Chopade
 * @last modified on  : 06-05-2023
 * @last modified by  : Rahul Jog
**/
public class ContentDocumentLinkDomain {
  public static void prepareDocument(Map<Id, ContentDocumentLink> newDocMap){
    //Declarations
    List<Document__c> docToInsertList = new List<Document__c>();
    Map<Id,ContentDocumentLink> contLinkMap = new Map<Id,ContentDocumentLink>();
    Map<Id,ContentDistribution> contDistMap = new Map<Id,ContentDistribution>();
    List<ContentDocumentLink> docLinkList = newDocMap.values();
    List<ContentDistribution> docDistList = new List<ContentDistribution>();
    List<ContentVersion> contentVersionList = new List<ContentVersion>();
    system.debug('DD - Engagement Letter:'+docLinkList);
    if(docLinkList.size()>0){
        contLinkMap = getContentDocumentLink(docLinkList);
    }
    system.debug('DD - Engagement Letter:'+contLinkMap);

    if(contLinkMap.keySet().size()>0){
      contentVersionList = ContentDocumentLinkSelector.getContentVersionList(contLinkMap.keySet());
    }

    if(contentVersionList.size()>0){
      docDistList = createConteDistribution(contentVersionList);
    }
            
    if(docDistList.size()>0){
      List<ContentDistribution> docDistributionList = ContentDocumentLinkSelector.getContentDistributionList(docDistList);
      if(docDistributionList.size()>0){
        contDistMap = getContentDistribution(docDistributionList);
      }
    }
    
    //Create document record
    for(ID docId : contLinkMap.keySet()){
      String linkValue,docName,/*Added by Priti Chande(06/03/2023)-To fetch File Type*/docType;
      ID objTypeId;
      if(contDistMap.containsKey(docId)){
        linkValue = contDistMap.get(docId).DistributionPublicUrl;
        docName = contDistMap.get(docId).Name;
        docType = contDistMap.get(docId).ContentVersion.FileExtension;//Added by Priti Chande(06/03/2023)-To fetch File Type

      }

      if(contLinkMap.containsKey(docId)){
        objTypeId = contLinkMap.get(docId).LinkedEntityId;
      }

      Document__c docObjRecord = new Document__c();
        if(docName != 'Error File'){
      docObjRecord.Name = docName;
      docObjRecord.Document_view_link__c = linkValue;
      docObjRecord.Content_Document_Id__c = contLinkMap.get(docId).ContentDocumentId;//Added by Priti Chande(23/03/2023)-To stored Content Document Id.
      docObjRecord.File_Type__c = docType;//Added by Priti Chande(06/03/2023)-To fetch File Type
      if(prepareObjectName(objTypeId) == 'Opportunity')
      {
        docObjRecord.Opportunity__c = objTypeId;
      }
      else if(prepareObjectName(objTypeId) == 'Account')
      {
        docObjRecord.Account__c = objTypeId;
      }
      else if(prepareObjectName(objTypeId) == 'Contact'){
        docObjRecord.Contact__c = objTypeId;
      }
      //Added by Rahul Jog(Thinqloud) - 06-05-2023 - End
      //Added by Rahul Jog(Thinqloud) - 30-05-2023 - Start
      else if(prepareObjectName(objTypeId) == 'Case'){
        docObjRecord.Case__c = objTypeId;
      }
      //Added by Rahul Jog(Thinqloud) - 30-05-2023 - End
      docToInsertList.add(docObjRecord);
    }
    }
    if(docToInsertList.size()>0){
      insert docToInsertList;
    }
  }

  public static Map<Id,ContentDocumentLink> getContentDocumentLink(List<ContentDocumentLink> contentDocLinkList){
      Map<Id,ContentDocumentLink> contentDocLinkMap = new Map<Id,ContentDocumentLink>();
      for(ContentDocumentLink contDocLink:contentDocLinkList){
          String conID = contDocLink.LinkedEntityId;
          if (!conID.startsWith('005') && !conID.startsWith('00G')) {
              contentDocLinkMap.put(contDocLink.ContentDocumentId,contDocLink);
          }
      }
      return contentDocLinkMap;
  }

  public static Map<Id,ContentDistribution> getContentDistribution(List<ContentDistribution> documentDistributionList){
      Map<Id,ContentDistribution> documentDistributionMap = new Map<Id,ContentDistribution>();
      for(ContentDistribution conDist : documentDistributionList){
          if(String.isNotBlank(conDist.DistributionPublicUrl)){
              documentDistributionMap.put(conDist.ContentDocumentId,conDist);
          }
      }
      return documentDistributionMap;
  }

  public static String prepareObjectName(ID recordId){
    String SObjectName;
      if(recordId != null){
        SObjectName = recordId.getSObjectType().getDescribe().getName();
      }
      system.debug('SObjectName:'+SObjectName);
      return SObjectName;
  }

  public static List<ContentDistribution> createConteDistribution(List<ContentVersion> conVersionList){
    List<ContentDistribution> contentDistributionList = new List<ContentDistribution>();
    for(ContentVersion conVerRec : conVersionList){
        ContentDistribution cd = new ContentDistribution();
        cd.Name = conVerRec.Title;
        cd.ContentVersionId = conVerRec.id;
        cd.PreferencesAllowViewInBrowser= true;
        cd.PreferencesLinkLatestVersion=true;
        cd.PreferencesNotifyOnVisit=false;
        cd.PreferencesPasswordRequired=false;
        cd.PreferencesAllowOriginalDownload= true;
        contentDistributionList.add(cd);
    }
    if (contentDistributionList.size()>0) {
        insert contentDistributionList;
    }
    return contentDistributionList;
  }
}