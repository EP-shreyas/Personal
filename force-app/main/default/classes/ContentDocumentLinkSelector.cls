/**
 * @description       : 
 * @author            : Tushar Chopade
 * @last modified on  : 03-01-2023
 * @last modified by  : Tushar Chopade
**/
public class ContentDocumentLinkSelector {
    public static List<ContentVersion> getContentVersionList(Set<Id> conDocIdSet){
        List<ContentVersion> conVerList = [SELECT ID,Title FROM ContentVersion WHERE ContentDocumentId IN : conDocIdSet];
        return conVerList;
    }

    public static List<ContentDistribution> getContentDistributionList(List<ContentDistribution> conDocDistList){
        Set<Id> idSet = new Set<Id>();
        for(ContentDistribution contDistVar : conDocDistList){
            idSet.add(contDistVar.id);
        }
        List<ContentDistribution> distributionList = [SELECT ID,Name,ContentDocumentId,
                                                     /*Added by Priti Chande(06/03/2023)-To fetch File Type*/ ContentVersion.FileExtension,DistributionPublicUrl
                                                     FROM ContentDistribution WHERE Id IN : idSet];
        return distributionList;
    }
}