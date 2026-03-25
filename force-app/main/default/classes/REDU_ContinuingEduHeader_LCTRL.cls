/**
 * @author      WDCi (Jordan)
 * @date        Feb 2024
 * @group       Continuing Education
 * @description Controller for continuingEduDetail
 * @changehistory
 * ISS-001846 22-02-2024 Jordan - new class
 */
public with sharing class REDU_ContinuingEduHeader_LCTRL {
    
    /**
     * @description Return community info
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getCommunityInfo(){
        try {
            
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(ORG_Helper.getCommunityInfo()));

            return response;

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
    
    /**
     * @description This method is used to get the title and image url of the particular record clicked by user on the lightning card.
     * @param sObjectName
     * @param recordId
     * @param titleFieldApiName
     * @param imageFieldApiName
     * @param allowGuestRegistrationFieldApiName
     * @param registerButtonConditionFieldApiName
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getRecordInfo(String sObjectName, Id recordId, String titleFieldApiName, String imageFieldApiName, String allowGuestRegistrationFieldApiName, String registerButtonConditionFieldApiName) {
        try {
            
            if (recordId != null && String.isBlank(sObjectName)) {
                sObjectName = recordId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName();
            }

            Set<String> fieldApiNames = new Set<String>();
            
            if (String.isNotBlank(titleFieldApiName)) {
                fieldApiNames.add(titleFieldApiName);
            }

            if (String.isNotBlank(imageFieldApiName)) {
                fieldApiNames.add(imageFieldApiName);
            }

            if (String.isNotBlank(allowGuestRegistrationFieldApiName)) {
                fieldApiNames.add(allowGuestRegistrationFieldApiName);
            }

            if(String.isNotBlank(registerButtonConditionFieldApiName)) {
                Schema.DescribeSObjectResult targetObjDescribe = REDU_Metadata_UTIL.describeSObject(sObjectName);

                Map<String, Schema.SObjectField> targetObjFieldsMap = targetObjDescribe.fields.getMap();
                if(targetObjFieldsMap.containsKey(registerButtonConditionFieldApiName.toLowerCase())) {
                    Schema.DisplayType fieldType = targetObjFieldsMap.get(registerButtonConditionFieldApiName.toLowerCase()).getDescribe().getType();

                    if(String.valueOf(fieldType) == 'BOOLEAN') {
                        if(!fieldApiNames.contains(registerButtonConditionFieldApiName)) {
                            fieldApiNames.add(registerButtonConditionFieldApiName);
                        }
                    } else {
                        REDU_ApplicationException invalidFieldExp = new REDU_ApplicationException(Label.Invalid_Boolean_Field_For_Register_Button);
                        throw invalidFieldExp;
                    }
                }
            }

            Map<String, Object> recordBindParams = new Map<String, Object>();
            recordBindParams.put('recordId', recordId);

            if (!fieldApiNames.isEmpty()) {
                String queryString = 'SELECT ' + String.join(fieldApiNames, ',') + 
                    ' FROM ' + sObjectName + 
                    ' WHERE Id =: recordId ';
                
                List<sObject> targetObjRecords = new List<sObject>();
                for(sObject targetObjRecord : Database.queryWithBinds(queryString, recordBindParams, AccessLevel.USER_MODE)) {
                    targetObjRecords.add(targetObjRecord);
                }
                
                if(!targetObjRecords.isEmpty()) {
                    Map<String, Object> response = new Map<String, Object>();
                    response.put('records', targetObjRecords);
                    response.put('objectName', sObjectName);

                    return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(response));
                } else {
                    return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
                }
            } else {
                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
            }
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}