/*******************************************************************************************************************************
* @author          Prakash Dighe
* @date            27/01/2023
* @Description     To create Document record when attachment insertted in Parent Record(Account/Contact/opprtunity/Lead/Product)
********************************************************************************************************************************/
public class DocumentRecordCreate {
/********************************************************************************************************************************
* @author          Prakash Dighe
* @description     This method to get list of attached document.  .
* @param           ContDocList(String)
* @date            27/01/2023
*********************************************************************************************************************************/
    public static void DocUpload(List<ContentDocumentLink> ContDocList){
    String Title;
	Id pId;
	for(ContentDocumentLink att: ContDocList){        
        pId=att.LinkedEntityId;
	}
    List<ContentDocumentLink> CDList = [select Id,ContentDocument.Title, LinkedEntityId,ContentDocumentId from ContentDocumentLink where LinkedEntityId =:pId];

       // ContentDistribution contentdist = new ContentDistribution();
       // contentdist.Name = CDList[0].ContentDocumentId;
       // insert contentdist;
        // ContentDistribution contentdist=[select Id,ContentDocumentId,ContentDownloadUrl from ContentDistribution
         //                          where ContentDocumentId = : CDList[0].ContentDocumentId]; 
        ContentVersion cv = [select id from contentversion where ContentDocumentId = : CDList[0].ContentDocumentId];
         ContentDistribution cd = new ContentDistribution();
            cd.Name = CDList[0].ContentDocument.Title;
            //cd.DistributionPublicUrl=URL.getSalesforceBaseUrl().toExternalForm() +'/' + contentdist.Id;
            cd.ContentVersionId =cv.id;
            cd.PreferencesAllowViewInBrowser= true;
            cd.PreferencesLinkLatestVersion=true;
            cd.PreferencesNotifyOnVisit=false;
            cd.PreferencesPasswordRequired=false;
            cd.PreferencesAllowOriginalDownload= true;
           insert cd;   
        system.debug('cd:'+cd.Id);
        
    Integer waitTime = 60;
    Integer waitTimeInMs = waitTime * 1000;
    Integer startTime =integer.valueOf(Datetime.now().getTime());
    while (Datetime.now().getTime() - startTime < waitTimeInMs) {
            
        }
    list<Document__c> DocList= new list<Document__c>();
    Document__c DocInfo=new Document__c();
    DocInfo.Name= CDList[0].ContentDocument.Title; 
   DocInfo.Document_view_link__c=cd.DistributionPublicUrl;
    
    //list<Document__c> DocList= new list<Document__c>();
    //Document__c DocInfo=new Document__c();
    //DocInfo.Name= CDList[0].ContentDocument.Title; 
  // DocInfo.Document_view_link__c=cd.DistributionPublicUrl;
 // URL.getSalesforceBaseUrl().toExternalForm() +'/' + view1.Id;
       // ContentDistribution contentdist=[select ContentDocumentId,ContentDownloadUrl from ContentDistribution where];
        //DocInfo.Document_view_link__c=contentdist.ContentDownloadUrl;
        
        // To check wheather attached doucument is null or not as well as also chek type of record based  on first three record digit number.
        // ContentVersion cv = [select id from contentversion where ContentDocumentId = :CDList[0].contentdocument.id];
        
        // ContentDistribution cd = new ContentDistribution();
            //cd.Name = CDList[0].ContentDocument.Title;
            //cd.DistributionPublicUrl=URL.getSalesforceBaseUrl().toExternalForm() +'/' + contentdist.Id;
            //cd.ContentVersionId = cv.id;
            //cd.PreferencesAllowViewInBrowser= true;
            //cd.PreferencesLinkLatestVersion=true;
            //cd.PreferencesNotifyOnVisit=false;
            //cd.PreferencesPasswordRequired=false;
            ///cd.PreferencesAllowOriginalDownload= true;
            //insert cd;
        //system.debug('content distrubuted record '+cd);
    if(CDList[0].LinkedEntityId !=null && String.valueOf(CDList[0].LinkedEntityId).startsWithIgnoreCase('001')){        
        DocInfo.Account__c = CDList[0].LinkedEntityId;
    }
    else if(CDList[0].LinkedEntityId!=null && String.valueOf(CDList[0].LinkedEntityId).startsWithIgnoreCase('003')){
        DocInfo.Contact__c = CDList[0].LinkedEntityId;
    }
    else if(CDList[0].LinkedEntityId!=null && String.valueOf(CDList[0].LinkedEntityId).startsWithIgnoreCase('006')){
        DocInfo.Opportunity__c = CDList[0].LinkedEntityId;
    }
      //      DocList.add(DocInfo);
       // }
    Insert DocInfo;
        
    }
}