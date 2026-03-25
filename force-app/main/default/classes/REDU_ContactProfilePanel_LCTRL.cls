/**
 * @Author 		WDCi (Jordan)
 * @Date 		Dec 2024
 * @group 		Contact
 * @Description Contact profile picture wizard
 * @changehistory
 * ISS-002196 04-12-2024 Jordan - new component
 */
public with sharing class REDU_ContactProfilePanel_LCTRL {
    
    /**
     * @description Get the current profile picture
     * @param recordId Contact record id
     * @param fileCategory Profile picture file category
     * @return REDU_LightningResponse
     */
	@AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getProfilePicture(String recordId, String fileCategory){
        
        Map<String, Object> responseJSON = new Map<String, Object>();
        try {

            Map<String, Object> cdlBindParams = new Map<String, Object>{
                'recordId' => recordId
            };

            String cdlQuery = 'SELECT ContentDocumentId, LinkedEntityId ' +
            ' FROM ContentDocumentLink ' +
            ' WHERE LinkedEntityId =: recordId ';

            Set<Id> cdlDocumentIdSet = new Set<Id>();
            
            for(ContentDocumentLink cdl : (List<ContentDocumentLink>) Database.queryWithBinds(cdlQuery, cdlBindParams, AccessLevel.USER_MODE)){
                cdlDocumentIdSet.add(cdl.ContentDocumentId);
            }

            if (!cdlDocumentIdSet.isEmpty()) {
                Map<String, Object> cvBindParams = new Map<String, Object>{
                    'cdlDocumentIdSet' => cdlDocumentIdSet,
                    'fileCategory' => fileCategory
                };
    
                String cvQuery = 'SELECT Id, Title, ContentDocumentId ' +
                ' FROM ContentVersion ' +
                ' WHERE ContentDocumentId IN: cdlDocumentIdSet ' +
                ' AND reduivy__File_Category__c =: fileCategory ' +
                ' ORDER BY CreatedDate DESC ' +
                ' LIMIT 1 ';
    
                String avatarResourceUrl = REDU_AppSetting_UTIL.getFileRenditionUrl();
    
                for (ContentVersion cv : (List<ContentVersion>) Database.queryWithBinds(cvQuery, cvBindParams, AccessLevel.USER_MODE)) {
                    responseJSON.put('contentVersion', cv);
                    responseJSON.put('imageUrl', String.format(avatarResourceUrl, new List<String>{cv.Id, cv.ContentDocumentId}));
                }
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));
            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
    
    /**
     * @description Get the updated profile picture after it is changed
     * @param documentId Document id of profile picture file
     * @param fileCategory Profile picture file category
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=false)
    public static REDU_LightningResponse updateProfilePicture(String documentId, String fileCategory){
        
        Map<String, Object> responseJSON = new Map<String, Object>();

        try {

            Map<String, Object> cvBindParams = new Map<String, Object>{
                'documentId' => documentId
            };

            String cvQuery = 'SELECT Id, reduivy__File_Category__c ' +
            ' FROM ContentVersion ' +
            ' WHERE ContentDocumentId =: documentId ' +
            ' ORDER BY CreatedDate DESC ' +
            ' LIMIT 1 ';

            List<ContentVersion> cvUpdateList = new List<ContentVersion>();
            for (ContentVersion cv : (List<ContentVersion>) Database.queryWithBinds(cvQuery, cvBindParams, AccessLevel.USER_MODE)) {
                cvUpdateList.add(cv);
            }

            if (!cvUpdateList.isEmpty() && String.isNotBlank(fileCategory)){
                for (ContentVersion cv : cvUpdateList) {
                    cv.reduivy__File_Category__c = fileCategory;
                }

                if (!cvUpdateList.isEmpty()) {
                    REDU_Database_UTIL.doUpdate(cvUpdateList);
                }
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Delete the current profile picture
     * @param recordId Contact record id
     * @param fileCategory Profile picture file category
     * @return REDU_LightningResponse
     */
	@AuraEnabled(cacheable=false)
    public static REDU_LightningResponse deleteProfilePicture(String recordId, String fileCategory){
        
        try {

            Map<String, Object> cdlBindParams = new Map<String, Object>{
                'recordId' => recordId
            };

            String cdlQuery = 'SELECT ContentDocumentId, LinkedEntityId ' +
            ' FROM ContentDocumentLink ' +
            ' WHERE LinkedEntityId =: recordId ';

            Set<Id> cdlDocumentIdSet = new Set<Id>();

            for(ContentDocumentLink cdl : (List<ContentDocumentLink>) Database.queryWithBinds(cdlQuery, cdlBindParams, AccessLevel.USER_MODE)){
                cdlDocumentIdSet.add(cdl.ContentDocumentId);
            }

            if (!cdlDocumentIdSet.isEmpty()) {
                Map<String, Object> cvBindParams = new Map<String, Object>{
                    'cdlDocumentIdSet' => cdlDocumentIdSet,
                    'fileCategory' => fileCategory
                };
    
                String cvQuery = 'SELECT Id, Title, ContentDocumentId ' +
                ' FROM ContentVersion ' +
                ' WHERE ContentDocumentId IN: cdlDocumentIdSet ' +
                ' AND reduivy__File_Category__c =: fileCategory ' +
                ' ORDER BY CreatedDate DESC ' +
                ' LIMIT 1 ';
    
                List<ContentDocument> cdList = new List<ContentDocument>();
    
                for (ContentVersion cv : (List<ContentVersion>) Database.queryWithBinds(cvQuery, cvBindParams, AccessLevel.USER_MODE)) {
                    ContentDocument cd = new ContentDocument(Id = cv.ContentDocumentId);
                    cdList.add(cd);
                }

                if (!cdList.isEmpty()) {
                    REDU_Database_UTIL.doDelete(cdList);
                }
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}