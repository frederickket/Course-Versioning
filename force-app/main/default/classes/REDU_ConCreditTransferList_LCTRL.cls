/**
 * @author      WDCi (VTan)
 * @date        Jan 2024
 * @group       Lightning Web Component
 * @description ISS-001659 08-01-2024 VTan - New Component
 * @changehistory
 * ISS-002104 04-12-2024 XW - update generateTableColMetadata param
 * ISS-002230 23-01-2025 XW - get picklist value label if field type is picklist
 * ISS-002218 04-03-2025 XW - get for community from ORG_Helper
 * ISS-002495 23-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 */
public with sharing class REDU_ConCreditTransferList_LCTRL {

    /**
     * @description Get the details of current Credit Transfer Application
     * @param objectApiName API Name of the current object
     * @param recordId Current record Id
     * @param contactFieldApiName Related contact field for object other than Contact
     * @param ctAppListFields String of Credit Transfer Application fields separated by semicolon (;)
     * @param enableClickableRefField
     * @param hrefTargetType
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getCreditTransferList(String objectApiName, Id recordId, String contactFieldApiName, String ctAppListFields, Boolean enableClickableRefField, String hrefTargetType, String language) {
        
        Map<String, Object> responseJSON = new Map<String, Object>();
        try {

            Id contactId;
            String contactApiName = CON_Helper.getApiName();
            if(String.isBlank(language)) {
                language = UserInfo.getLanguage();
            }

            if(objectApiName == contactApiName){

                //Assign Contact Id if current object is a Contact
                contactId = recordId;

            }else{

                //Query Contact Id if current object is NOT a contact
                String conIdQuery = 'SELECT ' + contactFieldApiName +
                                    ' FROM ' + objectApiName + 
                                    ' WHERE Id =: recordId';

                Map<String, Object> conBindParams = new Map<String, Object>{
                    'recordId' => recordId
                };

                for(sObject sobj : Database.queryWithBinds(conIdQuery, conBindParams, AccessLevel.USER_MODE)){

                    contactId = (Id)sobj.get(contactFieldApiName);
                }
            }

            if(!String.isBlank(contactId)){
                Set<String> ctaFields = new Set<String>{'Id', 'Name'};
                SObjectType rootSObjectType = reduivy__Credit_Transfer_Application__c.sObjectType;

                //Generate column metadata for datatable
                List<REDU_Datatable_UTIL.TableActionWrapper> tableActionList = new List<REDU_Datatable_UTIL.TableActionWrapper>();

                JSONGenerator tableColumnMetadata = JSON.createGenerator(true);
                REDU_Datatable_UTIL.generateTableColMetadata(tableColumnMetadata, rootSObjectType, ctAppListFields, false, tableActionList, enableClickableRefField, hrefTargetType, false, false); //ISS-002104

                //Store list of fields that have ref to parent
                JSONGenerator tableFieldRefMetadata = JSON.createGenerator(true);
                REDU_Datatable_UTIL.generateRefLinksMetadata(tableFieldRefMetadata, rootSObjectType, ctAppListFields);

                if (String.isNotBlank(ctAppListFields)) {
                    ctaFields.addAll(ctAppListFields.split(';'));
                }

                Set<String> ctaAdditionalFields = new Set<String>();
                for (String field : ctaFields) {
                    Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);

                    if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                        String refField = REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true);
                        ctaAdditionalFields.add(refField);
                    } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        ctaAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                    }
                }

                ctaFields.addAll(ctaAdditionalFields);

                Map<String, Object> ctAppBindParams = new Map<String, Object>{
                    'contactId' => contactId
                };

                //Query Credit Transfer Applications with related fields to be displayed in the datatable
                String queryString = 'SELECT ' + String.join(ctaFields, ',');
                queryString += ' FROM reduivy__Credit_Transfer_Application__c ';
                queryString += ' WHERE reduivy__Contact__c = : contactId';

                List<reduivy__Credit_Transfer_Application__c> ctApplicationList =  new List<reduivy__Credit_Transfer_Application__c>();
                for(reduivy__Credit_Transfer_Application__c cta : (List<reduivy__Credit_Transfer_Application__c>) Database.queryWithBinds(queryString, ctAppBindParams, AccessLevel.USER_MODE)){
                    ctApplicationList.add(cta);
                }

                Map<String, Object> communityInfo = ORG_Helper.getCommunityInfo();

                responseJSON.put('contactId', contactId);
                //Row action's buttons are depending on the statuses of data
                responseJSON.put('approvedStatuses', CTA_Helper.getApprovedStatuses());
                responseJSON.put('rejectedStatuses', CTA_Helper.getRejectedStatuses());
                responseJSON.put('submittedStatuses', CTA_Helper.getSubmittedStatuses());
                responseJSON.put('draftStatuses', CTA_Helper.getDraftStatuses());
                responseJSON.put(REDU_Datatable_UTIL.RECORDS_PARAM, ctApplicationList);
                responseJSON.put(REDU_Datatable_UTIL.COLUMNS_PARAM, JSON.deserializeUntyped(tableColumnMetadata.getAsString()));
                responseJSON.put(REDU_Datatable_UTIL.REFLINKS_PARAM, JSON.deserializeUntyped(tableFieldRefMetadata.getAsString()));
                responseJSON.put(REDU_Datatable_UTIL.SITE_PATH_PREFIX_PARAM, communityInfo.get(ORG_Helper.SITE_PATH_PREFIX_PARAM));
                responseJSON.put(ORG_Helper.IS_COMMUNITY_PARAM, communityInfo.get(ORG_Helper.IS_COMMUNITY_PARAM));
                responseJSON.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, REDU_TranslationManager.getTranslationInfo(CTA_Helper.getApiName(), ctApplicationList, ctaFields, language));

            }

            REDU_Logging_UTIL.debugJsonString('responseJSON', responseJSON);

            return new REDU_LightningResponse(true, 'success', JSON.serialize(responseJSON));
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Approve credit transfer application
     * @param ctApplicationRecord Credit Transfer Application record
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse rejectCTApplication (String ctApplicationRecord){

        try {
            reduivy__Credit_Transfer_Application__c ctApplication = (reduivy__Credit_Transfer_Application__c) JSON.deserialize(ctApplicationRecord, reduivy__Credit_Transfer_Application__c.class);

            if (ctApplication == null || ctApplication.Id == null) {
                throw new REDU_ApplicationException(Label.Error_Contact_Admin);
            }else{

                //Get rejected statuses
                List<String> rejectedStatuses = CTA_Helper.getRejectedStatuses();
                reduivy__Credit_Transfer_Application__c updateCtApplication = [SELECT Id, reduivy__Status__c FROM reduivy__Credit_Transfer_Application__c WHERE Id = :ctApplication.Id WITH USER_MODE];
                if(!rejectedStatuses.contains(updateCtApplication.reduivy__Status__c)){

                    updateCtApplication.reduivy__Status__c = rejectedStatuses[0];

                    REDU_Database_UTIL.doUpdate(new List<reduivy__Credit_Transfer_Application__c>{updateCtApplication});
                }
            }

            return new REDU_LightningResponse(true, 'success', JSON.serialize(new Set<Id>{ctApplication.Id}));

        } catch (QueryException qex) {

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {

            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description Approve credit transfer application
     * @param ctApplicationRecord Credit Transfer Application record
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse submitCTApplication (String ctApplicationRecord){

        try {
            reduivy__Credit_Transfer_Application__c ctApplication = (reduivy__Credit_Transfer_Application__c) JSON.deserialize(ctApplicationRecord, reduivy__Credit_Transfer_Application__c.class);

            if (ctApplication == null || ctApplication.Id == null) {
                throw new REDU_ApplicationException(Label.Error_Contact_Admin);
            }else{

                //Get submitted statuses
                List<String> submittedStatuses = CTA_Helper.getSubmittedStatuses();
                reduivy__Credit_Transfer_Application__c updateCtApplication = [SELECT Id, reduivy__Request_Date__c, reduivy__Status__c FROM reduivy__Credit_Transfer_Application__c WHERE Id = :ctApplication.Id WITH USER_MODE];
                if(!submittedStatuses.contains(updateCtApplication.reduivy__Status__c)){

                    updateCtApplication.reduivy__Status__c = submittedStatuses[0];
                    if(updateCtApplication.reduivy__Request_Date__c == null){
                        updateCtApplication.reduivy__Request_Date__c = System.today();
                    }

                    REDU_Database_UTIL.doUpdate(new List<reduivy__Credit_Transfer_Application__c>{updateCtApplication});
                }
            }

            return new REDU_LightningResponse(true, 'success', JSON.serialize(new Set<Id>{ctApplication.Id}));

        } catch (QueryException qex) {

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {

            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}