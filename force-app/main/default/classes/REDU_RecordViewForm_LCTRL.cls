/**
 * @author      WDCi (XW)
 * @date        Sep 2025
 * @group       Record View Form
 * @description Custom record view form to display translation value, and the parent fields
 * @changehistory
 * ISS-002495 23-09-2025 XW - new class
 * ISS-002746 27-11-2025 Lean - The CurrencyIsoCode detection
 */

public with sharing class REDU_RecordViewForm_LCTRL {

    /**
     * @description the records returned to the record view form
     */
    public static final String RECORDS_PARAM = 'records';

    /**
     * @description details of fields
     */
    public static final String FIELDS_OBJECT_PARAM = 'fieldsObject';
    /**
     * @description get the data for custom record view form (translation info, records, fields object)
     * @param recordId The record id of the root record
     * @param objectApiName the object name of the root object
     * @param fields fields to display
     * @param language language used in js
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getRecordFieldValue(String recordId, String objectApiName, List<String> fields, String language){

        try {
            Map<String, Object> responseData = new Map<String, Object>();

            if(String.isBlank(recordId) || String.isBlank(objectApiName) || fields == null || fields.isEmpty()) {
                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
            }
            
            if(String.isBlank(language)) {
                language = UserInfo.getLanguage();
            }

            Schema.SObjectType sobjectType = REDU_Metadata_UTIL.getSObjectType(objectApiName);
            
            Map<String, Object> translationInfo;
            List<SObject> sobjList;

            //Add CurrencyIsoCode to query so that we can display the correct symbol in the form
            Set<String> fieldsToQuery = new Set<String>(fields);
            if (REDU_SObject_UTIL.hasCurrencyIsoCode(sobjectType)) {
                fieldsToQuery.add(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);
            }

            if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
                //if the record value translation is enabled, we can get the records from translation info
                translationInfo = REDU_TranslationManager.getTranslationInfo(objectApiName, new List<String> {recordId}, new List<String>(fieldsToQuery), language);
                sobjList = (List<SObject>) translationInfo.get(REDU_TranslationManager.RECORDS_PARAM);
            } else {
                //if the record value translation is not enabled, we need to get record by querying it
                translationInfo = new Map<String, Object>();
                sobjList = new List<SObject>();

                for (String field : fields) {
                    Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, sobjectType);

                    if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                        fieldsToQuery.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true));
                    } else if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        fieldsToQuery.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                    }
                }
                
                String sobjQuery = 'SELECT ' + String.join(fieldsToQuery, ', ')
                                + ' FROM ' + objectApiName
                                + ' WHERE Id = :recordId';

                Map<String, Object> bindMap = new Map<String, Object>{
                    'recordId' => recordId
                };

                for(SObject sobj : Database.queryWithBinds(sobjQuery, bindMap, AccessLevel.USER_MODE)) {
                    sobjList.add(sobj);
                }
            }


            Map<String, REDU_DynamicFieldValue_OBJ> fieldsObjectMap = new Map<String, REDU_DynamicFieldValue_OBJ>(); //map to store the details of each field
            for(String field : fields) {
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, sobjectType);
                String objectNameOfField = fieldDescribe.getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName();
                for(SObject sobj : sobjList) {

                    String value = String.valueOf(REDU_SObject_UTIL.extractFieldValue(sobj, field));
                    REDU_DynamicFieldValue_OBJ obj = new REDU_DynamicFieldValue_OBJ(
                        fieldDescribe, value, value, false
                    );

                    fieldsObjectMap.put(field, obj);
                }
            }
            
            responseData.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, translationInfo);
            responseData.put(RECORDS_PARAM, sobjList);
            responseData.put(FIELDS_OBJECT_PARAM, fieldsObjectMap);

            String serializedResponseData = JSON.serialize(responseData);
            REDU_Logging_UTIL.debug('CustomRecordFieldValue', serializedResponseData);

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, serializedResponseData);

        } catch (QueryException qex) {
            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}