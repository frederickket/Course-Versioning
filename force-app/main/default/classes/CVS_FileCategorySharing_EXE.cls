/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Trigger Executable
 * @description Share the file based on the file category.
 * @changehistory
 * ISS-002103 Jordan 07-11-2024 - New class
 * ISS-002321 Jordan 06-03-2025 - Exclude user and chatter group
 */
public inherited sharing class CVS_FileCategorySharing_EXE extends REDU_TriggerExecutable {

    /**
     * @description File sharing config xref map
     */
    private static final Map<String, reduivy__File_Sharing_Config__mdt> fileSharingXref = CVS_Helper.getFileSharingXref();

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

        Map<Id, ContentVersion> cvsMap = new Map<Id, ContentVersion>();

        if (!fileSharingXref.isEmpty()) {
            for (ContentVersion cvsNew : (List<ContentVersion>) newList) {
                if (String.isNotBlank(cvsNew.reduivy__File_Category__c) && 
                    fileSharingXref.containsKey(cvsNew.reduivy__File_Category__c)
                ){
                    cvsMap.put(cvsNew.Id, cvsNew);
                }
            }
        }

        // Share files
        if(!cvsMap.isEmpty()){
            shareFiles(cvsMap);
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

        Map<Id, ContentVersion> cvsMap = new Map<Id, ContentVersion>();
        Map<Id, ContentVersion> cvsOldMap = new Map<Id, ContentVersion>((List<ContentVersion>) oldList);

        if (!fileSharingXref.isEmpty()) {
            for (ContentVersion cvsNew : (List<ContentVersion>) newList) {
                if (cvsNew.reduivy__File_Category__c != cvsOldMap.get(cvsNew.Id).reduivy__File_Category__c && 
                    String.isNotBlank(cvsNew.reduivy__File_Category__c) && 
                    fileSharingXref.containsKey(cvsNew.reduivy__File_Category__c)
                ){
                    cvsMap.put(cvsNew.Id, cvsNew);
                }
            }
        }

        // Share files
        if(!cvsMap.isEmpty()){
            shareFiles(cvsMap);
        }
    }

    /**
     * @description Share the files based on the file sharing configurations for the file category
     * @param cvsMap Map of Content Version
     * @return void
     */
    private void shareFiles(Map<Id, ContentVersion> cvsMap) {

        Map<Id, String> cdFileCategoryMap = new Map<Id, String>();

        for (ContentVersion cvs : cvsMap.values()) {
            cdFileCategoryMap.put(cvs.ContentDocumentId, cvs.reduivy__File_Category__c);
        }

        Map<String, Object> cdlBindParams = new Map<String, Object>{
            'cdIds' => cdFileCategoryMap.keySet()
        };

        String cdlQuery = 'SELECT Id, ContentDocumentId, Visibility, LinkedEntityId ' +
        ' FROM ContentDocumentLink ' +
        ' WHERE ContentDocumentId IN :cdIds ';

        //Update the visibility according to the file sharing configs
        List<ContentDocumentLink> cdlUpdateList = new List<ContentDocumentLink>();

        //ISS-002321 Skip the visibility update if linked entity is a user or a chatter group
        Schema.SObjectType userSObjectType = Schema.User.getSObjectType();
        Schema.SObjectType collaborationGroupSObjectType = Schema.CollaborationGroup.getSObjectType();
        
        for (ContentDocumentLink cdl : (List<ContentDocumentLink>) Database.queryWithBinds(cdlQuery, cdlBindParams, AccessLevel.USER_MODE)) {

            String fileCategory = cdFileCategoryMap.get(cdl.ContentDocumentId);
            reduivy__File_Sharing_Config__mdt fileSharingConfig = fileSharingXref.get(fileCategory);

            //ISS-002321 Skip the visibility update if linked entity is a user or a chatter group
            Schema.SObjectType linkedEntityType = cdl.LinkedEntityId.getSObjectType();

            if (linkedEntityType == userSObjectType || linkedEntityType == collaborationGroupSObjectType) {
                continue;
            }
            
            if (fileSharingConfig != null && cdl.Visibility != fileSharingConfig.reduivy__Visibility__c) {
                cdlUpdateList.add(new ContentDocumentLink(Id = cdl.Id, Visibility = fileSharingConfig.reduivy__Visibility__c));
            }
        }

        if (!cdlUpdateList.isEmpty()){
            //Update
            REDU_Database_UTIL.doUpdate(cdlUpdateList);
        }
    }
}