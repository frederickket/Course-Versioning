/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Content version object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class CVS_Helper implements SObject_Helper {
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.ContentVersion.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.ContentVersion.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.ContentVersion.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.ContentVersion);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Get object image url for the entities
     * @param linkedEntityIds Set of record id
     * @param fileName
     * @return Map<Id, String>
     */
    public static Map<Id, String> getObjectImageUrl(Set<Id> linkedEntityIds, String fileName) {

        Map<Id, String> objectImageUrlMap = new Map<Id,String>();

        if (!linkedEntityIds.isEmpty()) {

            if (String.isBlank(fileName)) {
                fileName = 'Profile';
            }

            fileName = '%' + fileName + '%';

            //Find all files related object
            Map<Id, ContentDocumentLink> cdlMap = new Map<Id,ContentDocumentLink>();

            for (ContentDocumentLink cdl : [SELECT 
                ContentDocumentId, 
                LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId in : linkedEntityIds
                WITH USER_MODE
            ]) {
                cdlMap.put(cdl.ContentDocumentId, cdl);
            }

            //Find latest profile picture
            Map<Id, ContentVersion> cvByLinkedEntityId = new Map<Id, ContentVersion>();
            for(ContentVersion cv : [SELECT Title, Description, ContentDocumentId 
                FROM ContentVersion 
                WHERE ContentDocumentId IN: cdlMap.keySet() 
                AND Title LIKE: fileName 
                AND IsLatest = TRUE
                WITH USER_MODE
            ]){
                if (cdlMap.containsKey(cv.ContentDocumentId)) {
                    cvByLinkedEntityId.put(cdlMap.get(cv.ContentDocumentId).LinkedEntityId, cv);
                }
            }
            
            String renditionUrl = REDU_AppSetting_UTIL.getFileRenditionUrl();

            for (Id entityId : linkedEntityIds) {
                if (cvByLinkedEntityId.containsKey(entityId)) {
                    ContentVersion cv = cvByLinkedEntityId.get(entityId);

                    String imageUrl = String.format(renditionUrl, new List<String>{cv.Id, cv.ContentDocumentId});

                    objectImageUrlMap.put(entityId, imageUrl);
                }
            }
        }

        return objectImageUrlMap;
    }

    /**
     * @description List of reduivy__File_Sharing_Config__mdt
     */
    private static List<reduivy__File_Sharing_Config__mdt> fileSharingConfigs;

    /**
     * @description File sharing configs metadata
     * @return List<reduivy__File_Sharing_Config__mdt>
     */
    public static List<reduivy__File_Sharing_Config__mdt> getFileCategorySharingConfig() {

        if (fileSharingConfigs == null) {
            fileSharingConfigs = new List<reduivy__File_Sharing_Config__mdt>();
            
            List<reduivy__File_Sharing_Config__mdt> configs = reduivy__File_Sharing_Config__mdt.getAll().values();

            for (reduivy__File_Sharing_Config__mdt fsc : configs) {
                if (fsc.reduivy__Active__c) {
                    fileSharingConfigs.add(fsc);
                }
            }
        }

        return fileSharingConfigs;
    }

    /**
     * @description File sharing config xref map
     */
    private static Map<String, reduivy__File_Sharing_Config__mdt> fileSharingXref;

    /**
     * @description File sharing config map by file category
     * @return Map<String, reduivy__File_Sharing_Config__mdt>
     */
    public static Map<String, reduivy__File_Sharing_Config__mdt> getFileSharingXref() {

        if (fileSharingXref == null) {
            fileSharingXref = new Map<String, reduivy__File_Sharing_Config__mdt>();

            for (reduivy__File_Sharing_Config__mdt fsc : getFileCategorySharingConfig()) {
                if (String.isNotBlank(fsc.reduivy__Content_Version_File_Category__c) && String.isNotBlank(fsc.reduivy__Visibility__c)) {
                    fileSharingXref.put(fsc.reduivy__Content_Version_File_Category__c, fsc);
                }
            }
        }

        return fileSharingXref;
    }
}