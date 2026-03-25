/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Requirement Checklist
 * @description Requirement Checklist File Uploader Controller class
 * @changehistory
 * ISS-002128 12-06-2025 XW - new class
 */

public with sharing class REDU_RequirementChecklistFile_LCTRL {
    
    /**
     * @description get the uploaded files of the individual requirement
     * @param irqId irq id
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getExistingUploadedFiles(String recordId){

        try {
            List<ContentDocument> uploadedDocs = new List<ContentDocument>();   

            if(String.isNotBlank(recordId)) {
                
                Set<Id> latestPublishedVersionId = new Set<Id>();
                for (ContentDocumentLink cdLink : [
                SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersionId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId =: recordId
                    WITH USER_MODE
                ]) {
                    if (String.isNotBlank(cdLink.ContentDocumentId)) {
                        uploadedDocs.add(cdLink.ContentDocument);
                    }
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(uploadedDocs));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description update the file category to the defined in individual requirement
     * @param  fileCategory       file category defined in individual requirement
     * @param  contentDocumentIds list of content document id
     * @return                    REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse updateUploadedFiles(String fileCategory, List<String> contentDocumentIds){

        Savepoint sp = Database.setSavePoint();

        try {
            List<ContentVersion> filesToUpdate = new List<ContentVersion>();
            if(String.isNotBlank(fileCategory) && contentDocumentIds != null && !contentDocumentIds.isEmpty()){

                for(ContentVersion cvs : [
                    SELECT Id, 
                    reduivy__File_Category__c 
                    FROM ContentVersion 
                    WHERE ContentDocumentId IN: contentDocumentIds
                    WITH USER_MODE
                ]) {
                    cvs.reduivy__File_Category__c = fileCategory;
                    filesToUpdate.add(cvs);
                }

                if(!filesToUpdate.isEmpty()) {
                    REDU_Database_UTIL.doUpdate(filesToUpdate);
                }
            }
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(filesToUpdate));
        } catch (QueryException qex) {
            Database.rollback(sp);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            Database.rollback(sp);

            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }


    /**
     * @description update the share type and the visibility of the content document link of the document 
     * @param  requirementId      irq id
     * @param  fileShareType      share type defined in individual requirement
     * @param  fileVisibility     visibility defined in individual requirement
     * @param  contentDocumentIds contentDocumentIds 
     * @return                    REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse shareUploadedFiles(String requirementId, String fileShareType, String fileVisibility, List<String> contentDocumentIds){
        Savepoint sp = Database.setSavepoint();
        try {
            List<ContentDocumentLink> existingDocumentLinks = new List<ContentDocumentLink>();
            
            //Skip the visibility update if linked entity is a user or a chatter group
            Schema.SObjectType userSObjectType = Schema.User.getSObjectType();
            Schema.SObjectType collaborationGroupSObjectType = Schema.CollaborationGroup.getSObjectType();

            if (String.isNotBlank(requirementId) && contentDocumentIds != null && !contentDocumentIds.isEmpty()) {
                for (ContentDocumentLink cdl : [SELECT Id, Visibility, ShareType, LinkedEntityId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId =: requirementId
                    AND ContentDocumentId IN: contentDocumentIds
                    WITH USER_MODE
                ]) {

                    //Skip the visibility update if linked entity is a user or a chatter group
                    Schema.SObjectType linkedEntityType = cdl.LinkedEntityId.getSObjectType();
                    
                    if (linkedEntityType == userSObjectType || linkedEntityType == collaborationGroupSObjectType) {
                        continue;
                    }

                    ContentDocumentLink newcdl = new ContentDocumentLink(Id = cdl.Id);

                    if (String.isNotBlank(fileShareType)) {
                        newcdl.ShareType = fileShareType;
                    }

                    if (String.isNotBlank(fileVisibility)) {
                        newcdl.Visibility = fileVisibility;
                    }

                    existingDocumentLinks.add(newcdl);
                }

                if(!existingDocumentLinks.isEmpty()){
                    REDU_Database_UTIL.doUpdate(existingDocumentLinks);
                }
            } 

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(existingDocumentLinks));
            return response;

        } catch (QueryException qex) {
            Database.rollback(sp);
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
            
        }  catch (Exception exp) {
            Database.rollback(sp);
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
    
    /**
     * @description link the document to the target parent
     * @param  parentId           the record id to be linked
     * @param  fileShareType      share type defined in individual requirement
     * @param  fileVisibility     visibility defined in individual requirement
     * @param  contentDocumentIds contentDocumentIds 
     * @return                    REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse linkUploadedFiles(String parentId, String fileShareType, String fileVisibility, List<String> contentDocumentIds){
        Savepoint sp = Database.setSavepoint();
        
        try {
            List<ContentDocumentLink> newDocumentLinks = new List<ContentDocumentLink>();
            if (String.isNotBlank(parentId) && contentDocumentIds != null && !contentDocumentIds.isEmpty()) {


                for (String cdId : contentDocumentIds) {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cdId;
                    cdl.LinkedEntityId = parentId;

                    if (String.isNotBlank(fileShareType)) {
                        cdl.ShareType = fileShareType;
                    }

                    if (String.isNotBlank(fileVisibility)) {
                        cdl.Visibility = fileVisibility;
                    }

                    newDocumentLinks.add(cdl);
                }
                if(!newDocumentLinks.isEmpty()) {
                    REDU_Database_UTIL.doInsert(newDocumentLinks);
                }

            } 
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(newDocumentLinks));

            return response;
        } catch (QueryException qex) {
            Database.rollback(sp);
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp) {
            Database.rollback(sp);
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}
