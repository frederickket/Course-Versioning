/**
 * @author      WDCi (Jordan)
 * @date        Mar 2024
 * @group       Trigger Executable
 * @description Automatically generate a publicly accessible url for a File, and set it on the public url field
 * @changehistory
 * ISS-001844 Jordan 07-03-2024 - New class
 */
public inherited sharing class CVS_GeneratePublicUrl_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (operationType == TriggerOperation.AFTER_INSERT) {
            Map<Id, ContentVersion> cvsMap = new Map<Id, ContentVersion>();

            for (ContentVersion cvsNew : (List<ContentVersion>) newList) {
                if (cvsNew.reduivy__Generate_Public_URL__c){
                    cvsMap.put(cvsNew.Id, cvsNew);
                }
            }

            // Generate public URL
            if(!cvsMap.isEmpty()){
                generatePublicURL(cvsMap);
            }
        }
    }

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if(operationType == TriggerOperation.AFTER_UPDATE) {
            Map<Id, ContentVersion> cvsMap = new Map<Id, ContentVersion>();

            for (ContentVersion cvsNew : (List<ContentVersion>) newList) {
                ContentVersion cvsOld = (ContentVersion) oldMap.get(cvsNew.Id);

                if (cvsNew.reduivy__Generate_Public_URL__c && !cvsOld.reduivy__Generate_Public_URL__c){
                    cvsMap.put(cvsNew.Id, cvsNew);
                }
            }

            // Generate public URL
            if(!cvsMap.isEmpty()){
                generatePublicURL(cvsMap);
            }
        }
    }
    
    /**
     * @description Generate and set the publicly accessible url for a File
     * @param cvsMap Map of Content Version
     * @return void
     */
    private void generatePublicURL(Map<Id, ContentVersion> cvsMap) {

        //Get Files, find which ones already have a public link
        Map<Id, String> fileToUrlMap = new Map<Id, String>();
        for (ContentDistribution url : [
            SELECT Id, ContentVersionId, ContentDownloadUrl
            FROM ContentDistribution
            WHERE ContentVersionId IN :cvsMap.keySet()
            WITH USER_MODE
        ]){
            fileToUrlMap.put(url.ContentVersionId, url.ContentDownloadUrl);
        }

        List<ContentVersion> filesNeedingUrl = new List<ContentVersion>();
        for (ContentVersion cvs : cvsMap.values()){
            if (!fileToUrlMap.containsKey(cvs.Id)){
                filesNeedingUrl.add(cvs);
            }
        }

        //Create a public link for any that haven't already been created
        if (!filesNeedingUrl.isEmpty()){
            List<ContentDistribution> urlInsertList = new List<ContentDistribution>();
            for (ContentVersion cvs : filesNeedingUrl){
                // Create a new ContentDistribution
                ContentDistribution cd = new ContentDistribution();
                cd.Name = cvs.Title;
                cd.ContentVersionId = cvs.Id;
                cd.PreferencesAllowViewInBrowser = true;
                cd.PreferencesLinkLatestVersion = true;
                cd.PreferencesNotifyOnVisit = false;
                cd.PreferencesPasswordRequired = false;
                cd.PreferencesAllowOriginalDownload = true;
                urlInsertList.add(cd);
            }
            //Insert
            REDU_Database_UTIL.doInsert(urlInsertList, cvsMap, 'ContentVersionId', false);
            
            //Need to requery to get urls
            for (ContentDistribution url : [SELECT Id, 
                ContentDownloadUrl, 
                ContentVersionId 
                FROM ContentDistribution 
                WHERE ContentVersionId IN :filesNeedingUrl 
                WITH USER_MODE
            ]){
                fileToUrlMap.put(url.ContentVersionId, url.ContentDownloadUrl);
            }
        }

        //Set Urls
        List<ContentVersion> filesToUpdateList = new List<ContentVersion>();
        for (ContentVersion cvs : cvsMap.values()){
            if (cvs.reduivy__Public_URL__c != fileToUrlMap.get(cvs.Id)){
                ContentVersion updateCvs = new ContentVersion();
                updateCvs.Id = cvs.Id;
                updateCvs.reduivy__Public_URL__c = fileToUrlMap.get(cvs.Id);
                filesToUpdateList.add(updateCvs);
            }
        }
        if (!filesToUpdateList.isEmpty()){
            //Update
            REDU_Database_UTIL.doUpdate(filesToUpdateList, cvsMap, 'Id', false);
        }
    }
}