/**
 * @description       : 
 * @author            : Tushar Chopade
 * @last modified on  : 03-01-2023
 * @last modified by  : Tushar Chopade
**/
public class ContentDocumentDomain {
    public static void processDocumentDeletion(Map<Id,ContentDocument> oldRecMap) {

        Set<Id> linkedEntityIdSet = new Set<Id>();
        Set<String> documentSet = new Set<String>();
        List<Document__c> docToCleanList = new List<Document__c>();
        List<Document__c> documentList = new List<Document__c>();
        List<ContentDocumentLink> docList = new List<ContentDocumentLink>();
        
        if (oldRecMap.size()>0) {
            documentSet = getDocNames(oldRecMap.values());
            docList = ContentDocumentSelector.getContentDocumentLinkList(oldRecMap.keySet());
            if (docList.size()>0) {
                linkedEntityIdSet = getlinkedEntity(docList);
                if (linkedEntityIdSet.size()>0) {
                    documentList = ContentDocumentSelector.getDocumentDetails(linkedEntityIdSet);
                }
            }
        }
        Set<String> documentApprovalSent = new Set<String>();
        for (Document__c docRecord : documentList) {
            if (documentSet.contains(docRecord.Name)) {
                 if(Approval.isLocked(docRecord.Id)){//Added by Priti Chande-(23/03/2023)-To validation Error if document is already sent for approval
                     if(docRecord.Content_Document_Id__c != null)
                     documentApprovalSent.add(docRecord.Content_Document_Id__c);
					//ended here(23/03/2023)
                 }else{
                    docToCleanList.add(docRecord);
                 }
            }
        }
        if(documentApprovalSent.size() > 0){//Added by Priti Chande-(23/03/2023)-To validation Error if document is already sent for approval
            for(ContentDocument con : oldRecMap.values()){
                    if(documentApprovalSent.contains(con.Id)){
                    con.addError(Constants.FILE_DELETE_ERROR_MSG);
                    }
                }
        }//ended here(23/03/2023)
        if (docToCleanList.size()>0) {
           /* //Added by Rahul(Thinqloud) 23-03-2023 - Start
            for(Document__c docRecord : docToCleanList){
                if(Approval.isLocked(docRecord.Id)){
                    docRecord.addError('This document is submitted for approval');
                }
            }//Added by Rahul(Thinqloud) 23-03-2023 - End*/
            deleteDocument(docToCleanList);
        }
    }

    public static Set<Id> getlinkedEntity(List<ContentDocumentLink> contentDocLinkList){
        Set<Id> linkedEntitySet = new Set<Id>();
        for(ContentDocumentLink contDocLink:contentDocLinkList){
            String conID = contDocLink.LinkedEntityId;
            if (!conID.startsWith('005') && !conID.startsWith('00G')) {
                linkedEntitySet.add(contDocLink.LinkedEntityId);
            }
        }
        return linkedEntitySet;
    }

    public static Set<String> getDocNames(List<ContentDocument> ContentDocumentList){
        Set<String> DocNameSet = new Set<String>();
        for(ContentDocument contDoc:ContentDocumentList){
            if (contDoc.Title != null) {
                DocNameSet.add(contDoc.Title);
            }
        }
        return DocNameSet;
    }

    public static void deleteDocument(List<Document__c> docList){
        Database.DeleteResult[] drList = Database.delete(docList, false);
        for(Database.DeleteResult dr : drList) {
            if (!dr.isSuccess()) {
                System.debug('error has occurred.');
            }else {
                System.debug('Document deleted successfully.');
            }
        }
    }
    //Added by Rahul Jog(Thinqloud) - 17-04-2023 - Start
    @future
    public static void createDocumentLinkString(List<Id> contentDocumentIdList){
        Set<Id> caseIdSet = new Set<Id>();
        List<ContentDocumentLink> cdLink = new List<ContentDocumentLink>();
        List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
        List<Case> caseList = new List<Case>();
        //Added by Rahul Jog(Thinqloud) 19-04-2023 - Start
        Set<Id> emailMessageIdSet = new Set<Id>();
        List<EmailMessage> emailMessageList = new List<EmailMessage>();
        List<EmailMessage> uploadedEmailList = new List<EmailMessage>();
        //Added by Rahul Jog(Thinqloud) 19-04-2023 - End
        //1. After Insert of ContentDocument, query on ContentDocumentLink to get LinkedEntityId, ContentDocumentId, ContentDocument.Title where ContentDocumentId is our ContentDocument inserted.
        //2. If LinkedEntityId is related to case :
        //Get all ContentDocumentLink records related to this LinkedEntityId and query ContentDocumentId. Add ContentDocumentId in the set
        //3. Using set retrieve the ContentDistribution where it's ContentDocumentId is In set of ContentDocumentId. Query Id, Name, DistributionPublicUrl from ContentDistribution
        //4. Add all the DistributionPublicUrl using a href html tag in the rich text field in the Case object.
        if(!contentDocumentIdList.isEmpty() && contentDocumentIdList.size() > 0){
            cdLink =[SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink where ContentDocumentId IN : contentDocumentIdList];
        }
        if(!cdLink.isEmpty() && cdLink.size() > 0){
            for(ContentDocumentLink contentDocLink : cdLink){
                if(ContentDocumentLinkDomain.prepareObjectName(contentDocLink.LinkedEntityId) == 'Case'){
                    caseIdSet.add(contentDocLink.LinkedEntityId);
                }
                //Added by Rahul Jog(Thinqloud) 19-04-2023 - Start
                else if(ContentDocumentLinkDomain.prepareObjectName(contentDocLink.LinkedEntityId) == 'EmailMessage'){
                    emailMessageIdSet.add(contentDocLink.LinkedEntityId);
                }
                //Added by Rahul Jog(Thinqloud) 19-04-2023 - End
            }
        }
        //Added by Rahul Jog(Thinqloud) 27-04-2023 Start
        if(!caseIdSet.isEmpty() && caseIdSet.size() > 0){
            uploadedEmailList = [Select Id,ParentId,RelatedToId from EmailMessage where ParentId IN : caseIdSet];// Rework
        }
        if(!uploadedEmailList.isEmpty() && uploadedEmailList.size() > 0){
            for(EmailMessage email : uploadedEmailList){
                emailMessageIdSet.add(email.Id);
            }
        }
        //Added by Rahul Jog(Thinqloud) 27-04-2023 End
        //Added by Rahul Jog(Thinqloud) 19-04-2023 - Start
        if((!emailMessageIdSet.isEmpty() && emailMessageIdSet.size() > 0) || (!caseIdSet.isEmpty() && caseIdSet.size() > 0)){
            emailMessageList = [Select Id,ParentId from EmailMessage where Id IN : emailMessageIdSet OR ParentId IN : caseIdSet];//Extra condition Added by Rahul Jog(Thinqloud) 27-04-2023
        }
        for(EmailMessage emailRecord : emailMessageList){
            if(emailRecord.ParentId != null){
                caseIdSet.add(emailRecord.ParentId);
            }
        }
        //Added by Rahul Jog(Thinqloud) 19-04-2023 - End
        if((!caseIdSet.isEmpty() && caseIdSet.size() > 0) || (!emailMessageIdSet.isEmpty() && emailMessageIdSet.size() > 0)){ 
            caseList = [Select Id, Document_Links__c, RecordTypeId from Case where Id IN : caseIdSet];
            cdLinkList = [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink where LinkedEntityId IN : caseIdSet OR LinkedEntityId IN : emailMessageIdSet]; //Modified by Rahul Jog(Thinqloud) -19-04-2023 added emailMessageIdSet filter
        }
        if(!cdLinkList.isEmpty() && cdLinkList.size() >0 && caseList.size() > 0 && !caseList.isEmpty()){
            documentLinkGeneration(cdLinkList, caseList, emailMessageList);
        }
    }
    //Added by Rahul Jog(Thinqloud) - 17-04-2023 - End
    //Added by Rahul Jog(Thinqloud) - 18-04-2023 - Start
    public static void processCaseDocumentDeletion(Map<Id, ContentDocument> contentDocumentMap){
        List<ContentDocument> contentDocumentList = new List<ContentDocument>();
        List<Id> contentDocumentIdList = new List<Id>();
        Set<Id> caseIdSet = new Set<Id>();
        List<ContentDocumentLink> cdLink = new List<ContentDocumentLink>();
        List<ContentDocumentLink> cdLinkList = new List<ContentDocumentLink>();
        List<Case> caseList = new List<Case>();
        List<Case> updateCaseList = new List<Case>();
        //Added by Rahul Jog(Thinqloud) 19-04-2023 - Start
        Set<Id> emailMessageIdSet = new Set<Id>();
        List<EmailMessage> emailMessageList = new List<EmailMessage>();
        List<EmailMessage> uploadedEmailList = new List<EmailMessage>();
        //Added by Rahul Jog(Thinqloud) 19-04-2023 - End
        //1. Before Delete of ContentDocument, query on ContentDocumentLink to get LinkedEntityId, ContentDocumentId, ContentDocument.Title where ContentDocumentId is our ContentDocument inserted.
        //2. If LinkedEntityId is related to case :
        //Get all ContentDocumentLink records related to this LinkedEntityId and query ContentDocumentId. Add ContentDocumentId in the set
        //3. Using set retrieve the ContentDistribution where it's ContentDocumentId is In set of ContentDocumentId. Query Id, Name, DistributionPublicUrl from ContentDistribution
        //4. Add all the DistributionPublicUrl using a href html tag in the rich text field in the Case object.
        contentDocumentList = contentDocumentMap.values();
        if(!contentDocumentList.isEmpty() && contentDocumentList.size() > 0){
            for(ContentDocument contentDocRecord : contentDocumentList){
                contentDocumentIdList.add(contentDocRecord.Id);
            }
        }
        if(!contentDocumentIdList.isEmpty() && contentDocumentIdList.size() > 0){
            cdLink =[SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink where ContentDocumentId IN : contentDocumentIdList];
        }
        if(!cdLink.isEmpty() && cdLink.size() > 0){
            for(ContentDocumentLink contentDocLink : cdLink){
                if(ContentDocumentLinkDomain.prepareObjectName(contentDocLink.LinkedEntityId) == 'Case'){
                    caseIdSet.add(contentDocLink.LinkedEntityId);
                }
                //Added by Rahul Jog(Thinqloud) 19-04-2023 - Start
                else if(ContentDocumentLinkDomain.prepareObjectName(contentDocLink.LinkedEntityId) == 'EmailMessage'){
                    emailMessageIdSet.add(contentDocLink.LinkedEntityId);
                }
                //Added by Rahul Jog(Thinqloud) 19-04-2023 - End
            }
        }
        //Added by Rahul Jog(Thinqloud) 27-04-2023 Start
        if(!caseIdSet.isEmpty() && caseIdSet.size() > 0){
            uploadedEmailList = [Select Id,ParentId,RelatedToId from EmailMessage where ParentId IN : caseIdSet];
        }
        if(!uploadedEmailList.isEmpty() && uploadedEmailList.size() > 0){
            for(EmailMessage email : uploadedEmailList){
                emailMessageIdSet.add(email.Id);
            }
        }
        //Added by Rahul Jog(Thinqloud) 27-04-2023 End
        //Added by Rahul Jog(Thinqloud) 19-04-2023 - Start
        if((!emailMessageIdSet.isEmpty() && emailMessageIdSet.size() > 0) || (!caseIdSet.isEmpty() && caseIdSet.size() > 0)){
            emailMessageList = [Select Id,ParentId from EmailMessage where Id IN : emailMessageIdSet OR ParentId IN : caseIdSet];//Extra condition Added by Rahul Jog(Thinqloud) 27-04-2023
        }
        if(!emailMessageList.isEmpty() && emailMessageList.size() > 0){
            for(EmailMessage emailRecord : emailMessageList){
                if(emailRecord.ParentId != null){
                    caseIdSet.add(emailRecord.ParentId);
                }
            }
        }
        //Added by Rahul Jog(Thinqloud) 19-04-2023 - End
        if((!caseIdSet.isEmpty() && caseIdSet.size() > 0) || (!emailMessageIdSet.isEmpty() && emailMessageIdSet.size() > 0)){ 
            caseList = [Select Id, Document_Links__c, RecordTypeId from Case where Id IN : caseIdSet];
            cdLinkList = [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink 
                            where (LinkedEntityId IN : caseIdSet OR LinkedEntityId IN : emailMessageIdSet)
                             AND ContentDocumentId NOT IN : contentDocumentIdList];//Modified by Rahul Jog(Thinqloud) -19-04-2023 added emailMessageIdSet filter
        }
        if(!cdLinkList.isEmpty() && cdLinkList.size() > 0 && caseList.size() > 0 && !caseList.isEmpty()){
            documentLinkGeneration(cdLinkList, caseList, emailMessageList);
        }
        else if(caseList.size() > 0 && !caseList.isEmpty() && cdLinkList.size() == 0){
            for(Case caseRecord : caseList){
                caseRecord.Document_Links__c = ' ';
                Case updateCase = new Case(Id = caseRecord.Id, Document_Links__c = caseRecord.Document_Links__c);
                updateCaseList.add(updateCase);
            }
            if(!updateCaseList.isEmpty() && updateCaseList.size() > 0){
                update updateCaseList;
            }
        }
    }
    public static void documentLinkGeneration(List<ContentDocumentLink> cdLinkList,List<Case> caseList,List<EmailMessage> emailMessageList){
        Set<Id> caseDocumentIdSet = new Set<Id>();
        List<Case> updateCaseList = new List<Case>();
        List<ContentDistribution> contentDistributionList = new List<ContentDistribution>();
        Map<Id,List<Id>> caseContentDocumentMap = new Map<Id,List<Id>>();// Map of LinkedEntityId vs list of ContentDocumentId Map<Id,List<Id>>
        Map<Id,String> documentUrlMap = new Map<Id,String>();// a map of ContentDocumentId vs DistributionPublicUrl Map<Id,String>
        Map<Id,String> documentNameMap = new Map<Id,String>(); // a map of ContentDocumentId vs FileName Map<Id,String>
        //Added by Rahul Jog(Thinqloud) 19-04-2023 - Start
        Map<Id,Id> emailCaseIdMap = new Map<Id,Id>();
        if(!emailMessageList.isEmpty() && emailMessageList.size() > 0){
            for(EmailMessage emailRecord : emailMessageList){
                if(emailRecord.ParentId != null){
                    emailCaseIdMap.put(emailRecord.Id, emailRecord.ParentId);
                }
            }
        }
        //Added by Rahul Jog(Thinqloud) 19-04-2023 - End
        if(!cdLinkList.isEmpty() && cdLinkList.size() > 0){
            for(ContentDocumentLink contentDocLink : cdLinkList){
                if(contentDocLink.ContentDocumentId != null){
                    caseDocumentIdSet.add(contentDocLink.ContentDocumentId);
                }
                //Create Map of LinkedEntityId vs list of ContentDocumentId : Map<Id,List<Id>>
                if(ContentDocumentLinkDomain.prepareObjectName(contentDocLink.LinkedEntityId) == 'Case'){
                    if(caseContentDocumentMap.containsKey(contentDocLink.LinkedEntityId)){
                        if(caseContentDocumentMap.get(contentDocLink.LinkedEntityId) != null){
                            List<Id> contentDocIdList = new List<Id>();
                            contentDocIdList = caseContentDocumentMap.get(contentDocLink.LinkedEntityId);
                            contentDocIdList.add(contentDocLink.ContentDocumentId);
                            caseContentDocumentMap.put(contentDocLink.LinkedEntityId,contentDocIdList);
                        }else{
                            caseContentDocumentMap.put(contentDocLink.LinkedEntityId,new List<Id>{contentDocLink.ContentDocumentId});
                        }
                    }
                    else{
                        caseContentDocumentMap.put(contentDocLink.LinkedEntityId,new List<Id>{contentDocLink.ContentDocumentId});
                    }
                }
                //Added by Rahul Jog(Thinqloud) 19-04-2023 - Start
                else if(ContentDocumentLinkDomain.prepareObjectName(contentDocLink.LinkedEntityId) == 'EmailMessage'){
                    // Create a Map of EmailMessaged.ParentId vs ContentDocumentId
                    if(caseContentDocumentMap.containsKey(emailCaseIdMap.get(contentDocLink.LinkedEntityId))){
                        if(caseContentDocumentMap.get(emailCaseIdMap.get(contentDocLink.LinkedEntityId)) != null){
                            List<Id> contentDocIdList = new List<Id>();
                            contentDocIdList = caseContentDocumentMap.get(emailCaseIdMap.get(contentDocLink.LinkedEntityId));
                            contentDocIdList.add(contentDocLink.ContentDocumentId);
                            caseContentDocumentMap.put(emailCaseIdMap.get(contentDocLink.LinkedEntityId),contentDocIdList);
                        }
                        else{
                            caseContentDocumentMap.put(emailCaseIdMap.get(contentDocLink.LinkedEntityId),new List<Id>{contentDocLink.ContentDocumentId});
                        }
                    }
                    else{
                        caseContentDocumentMap.put(emailCaseIdMap.get(contentDocLink.LinkedEntityId),new List<Id>{contentDocLink.ContentDocumentId});
                    }
                }
                //Added by Rahul Jog(Thinqloud) 19-04-2023 - End
            }
        }
        if(!caseDocumentIdSet.isEmpty() && caseDocumentIdSet.size() > 0){
            contentDistributionList = [SELECT Id, Name, ContentDocumentId, DistributionPublicUrl FROM ContentDistribution where ContentDocumentId IN : caseDocumentIdSet];
        }
        if(!contentDistributionList.isEmpty() && contentDistributionList.size() > 0){
            for(ContentDistribution cdDistribution : contentDistributionList){
                // Create a map of ContentDocumentId vs DistributionPublicUrl Map<Id,String>
                documentUrlMap.put(cdDistribution.ContentDocumentId, cdDistribution.DistributionPublicUrl);
                documentNameMap.put(cdDistribution.ContentDocumentId, cdDistribution.Name);
            }
        }
        if(!caseList.isEmpty() && caseList.size() > 0){
            for(Case caseRecord : caseList){
                String documentLink = ' ';
                Integer i =1;
                if(caseContentDocumentMap.containsKey(caseRecord.Id) && caseContentDocumentMap.get(caseRecord.Id) != null){
                    for(Id linkedId : caseContentDocumentMap.get(caseRecord.Id)){
                        if(i < caseContentDocumentMap.get(caseRecord.Id).size()){
                            documentLink += '<a href = '+documentUrlMap.get(linkedId)+'>'+documentNameMap.get(linkedId)+'</a>, <br>';
                        }
                        else{
                            documentLink += '<a href = '+documentUrlMap.get(linkedId)+'>'+documentNameMap.get(linkedId)+'</a>';
                        }
                        i++;
                    }
                }
                if(documentLink != null){
                    caseRecord.Document_Links__c = documentLink;
                }
                Case updateCase = new Case(Id = caseRecord.Id, Document_Links__c = caseRecord.Document_Links__c);
                updateCaseList.add(updateCase);
            }
        }
        if(!updateCaseList.isEmpty() && updateCaseList.size() > 0){
            update updateCaseList;
        }
    }
    //Added by Rahul Jog(Thinqloud) - 18-04-2023 - End
}