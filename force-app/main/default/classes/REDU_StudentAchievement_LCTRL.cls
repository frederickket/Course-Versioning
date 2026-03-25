/**
 * @author      WDCi (XW)
 * @date        Nov 2025
 * @group       Student Achievement
 * @description 
 * @changehistory
 * ISS-002633 17-11-2025 XW - new class
 */

public with sharing class REDU_StudentAchievement_LCTRL {

    /**
     * @description get list of individual achievements for achievement wizard to display
     * @param  recordId                               any recordid. the object should have a contact lookup field
     * @param  contactField                           the contact field name from the record. "Id" if the record id is contact
     * @param  additionalFields                       the additional fields to be queried.
     * @param  language                               language used by the user
     * @return                                        return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualAchievements(String recordId, String contactField, List<String> additionalFields, String language) {

        try {

            Map<String, Object> responseData = new Map<String, Object>();
            if(String.isBlank(recordId)) {
                recordId = CON_Helper.getCurrentLoggedInUserContact()?.Id;
            }

            if(String.isBlank(language)) {
                language = UserInfo.getLanguage();
            }

            if(String.isNotBlank(recordId) && String.isNotBlank(contactField)) {

                Id targetContactId;
                String givenObjectName = Id.valueOf(recordId).getSobjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName() ;
                if(givenObjectName == CON_Helper.getApiName()) {
                    targetContactId = recordId;
                } else {
                    String conQuery = 'SELECT Id, ' + contactField + 
                                     ' FROM ' + givenObjectName +
                                     ' WHERE Id =: givenRecordId' +
                                     ' LIMIT 1'; 

                    Map<String, Object> conBindMap = new Map<String, Object>{
                        'givenRecordId' => recordId
                    };
                    
                    for(SObject sobj : Database.queryWithBinds(conQuery, conBindMap, AccessLevel.USER_MODE)) {
                        targetContactId = (Id) sobj.get(contactField);
                    }
                }

                if(String.isNotBlank(targetContactId)) {
                    Set<String> individualAchievementQueryFields = new Set<String>();
                    Set<String> individualAchievementFields = new Set<String> { 
                        'Id',
                        'reduivy__Details__c',
                        'reduivy__Verification_Status__c',
                        'reduivy__Agreement__r.reduivy__Educational_Institution__r.Name',
                        'reduivy__Agreement__r.reduivy__External_Educational_Institution__r.Name',
                        'reduivy__Department__r.Name',
                        'reduivy__Agreement_Recognition__r.reduivy__Agreement__r.Name',
                        'reduivy__Agreement_Recognition__r.Name'
                    };

                    if(REDU_Metadata_UTIL.describeSObject(IAC_Helper.getApiName()).getRecordTypeInfos().size() > 1) {
                        individualAchievementFields.add('RecordTypeId');
                    }

                    individualAchievementFields.addAll(IAC_Helper.getIacReferencedFields());
                    if(additionalFields != null && !additionalFields.isEmpty()) {
                        individualAchievementFields.addAll(additionalFields);
                    }

                    Schema.SObjectType rootSObjectType = REDU_Metadata_UTIL.getSObjectType(IAC_Helper.getApiName());
                    for (String field : individualAchievementFields) {
                        Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);
                        individualAchievementQueryFields.add(field);

                        if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                            String refField = REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true);
                            individualAchievementQueryFields.add(refField);
                        } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                            individualAchievementQueryFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                        }
                    }

                    String individualAchievementQuery = 'SELECT ' + String.join(individualAchievementQueryFields, ', ')
                                   + ' FROM ' + IAC_Helper.getApiName()
                                   + ' WHERE reduivy__Contact__c = :contactId';
                    
                    Map<String, Object> individualAchievementBindMap = new Map<String, Object>{
                        'contactId' => targetContactId
                    };

                    List<reduivy__Individual_Achievement__c> individualAchievementList = new List<reduivy__Individual_Achievement__c>();

                    REDU_Logging_UTIL.debug('individualAchievementQuery', individualAchievementQuery);
                    for(reduivy__Individual_Achievement__c individualAchievement : (List<reduivy__Individual_Achievement__c>) Database.queryWithBinds(individualAchievementQuery, individualAchievementBindMap, AccessLevel.USER_MODE)) {
                        individualAchievementList.add(individualAchievement);
                    }

                    Map<String, String> fieldToDisplayTypeMap = new Map<String, String>();
                    
                    Schema.SObjectType individualAchievementSobjType = REDU_Metadata_UTIL.getSObjectType(IAC_Helper.getApiName());
                    for(String field : individualAchievementFields) {
                        Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, individualAchievementSobjType);
                        fieldToDisplayTypeMap.put(field, dfr.getType().name());
                    }

                    responseData.put('individualAchievementList', individualAchievementList);
                    responseData.put('fieldToDisplayTypeMap', fieldToDisplayTypeMap);
                    responseData.put('targetContactId', targetContactId);
                    responseData.put(
                        REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, 
                        REDU_TranslationManager.getTranslationInfo(IAC_Helper.getApiName(), individualAchievementList, individualAchievementFields, language) 
                    );

                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
    
    /**
     * @description get list of field set member
     * @param fieldSetName the field set name
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getFieldSet(String fieldSetName, String objectApiName){

        try {
            List<reduivy.REDU_DynamicFieldValue_OBJ> result;
            if(String.isNotBlank(fieldSetName) && String.isNotBlank(objectApiName)) {
                result = REDU_Metadata_UTIL.getFieldSetMembers(objectApiName, fieldsetName);
            } else {
                result = new List<reduivy.REDU_DynamicFieldValue_OBJ>();
            } 
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(result));

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get the individual achievement wizard metadata based on the wizard config id
     * @param parentWizardConfigName the wizard config id 
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIdvAcWizardMetadata(String parentWizardConfigName){

        try {
            Map<String,List<IAC_Helper.IdvAcWizardFormWrapper>> idvAcWizardFormGroupByWizardConfig = IAC_Helper.getIdvAcWizardFormGroupByWizardConfigName();
            List<IAC_Helper.IdvAcWizardFormWrapper> idvAcWizardFormGroupList = new List<IAC_Helper.IdvAcWizardFormWrapper>();
            if(idvAcWizardFormGroupByWizardConfig.containsKey(parentWizardConfigName)) {
                idvAcWizardFormGroupList = idvAcWizardFormGroupByWizardConfig.get(parentWizardConfigName);
            }

            Map<String, String> labels = new Map<String, String>();
            for(IAC_Helper.IdvAcWizardFormWrapper config : idvAcWizardFormGroupList) {
                labels.putAll(config.extractAllLabelsValue());
            }

            Map<String, Object> responseData = new Map<String, Object>{
                'idvAcWizardFormGroupList' => idvAcWizardFormGroupList,
                'labels' => labels
            };
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualAchievementVerificationStatusesInfo(){
        try{
            Map<String, Object> responseData = new Map<String, Object> {
                'lockingMode' => new Map<String, Object> {
                    IAC_Helper.VERIFICATION_STATUS_LOCKING_MODE_LOCKED => IAC_Helper.getLockedVerificationStatuses(),
                    IAC_Helper.VERIFICATION_STATUS_LOCKING_MODE_UNLOCKED => IAC_Helper.getUnlockedVerificationStatuses()
                },
                'verificationStatusType' => new Map<String, Object> {
                    IAC_Helper.VERIFICATION_STATUS_TYPE_OPEN => IAC_Helper.getOpenVerificationStatuses(),
                    IAC_Helper.VERIFICATION_STATUS_TYPE_SUBMITTED => IAC_Helper.getSubmittedVerificationStatuses(),
                    IAC_Helper.VERIFICATION_STATUS_TYPE_REVIEW => IAC_Helper.getReviewVerificationStatuses(),
                    IAC_Helper.VERIFICATION_STATUS_TYPE_VERIFIED => IAC_Helper.getVerifiedVerificationStatuses(),
                    IAC_Helper.VERIFICATION_STATUS_TYPE_REJECTED => IAC_Helper.getRejectedVerificationStatuses(),
                    IAC_Helper.VERIFICATION_STATUS_TYPE_CANCELLED => IAC_Helper.getCancelledVerificationStatuses()
                },
                'verificationStatusBadgeType' => IAC_Helper.getVerificationStatusesBadgeType()
            };
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
        
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }


    }


}