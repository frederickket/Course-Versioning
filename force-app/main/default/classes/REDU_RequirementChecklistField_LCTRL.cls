/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Requirement Checklist
 * @description Requirement Checklist field update
 * @changehistory
 * ISS-002128 30-06-2025 XW - new class
 */

public with sharing class REDU_RequirementChecklistField_LCTRL {

    static String RESPONSE_RECORD_ID = 'RESPONSE_RECORD_ID';
    static String RESPONSE_OBJECT_API_NAME = 'RESPONSE_OBJECT_API_NAME';

    /**
     * @description get the object namd and the record id of the related record
     * @param irqId the irq id
     * @param objectRelationField the relation field of the target parent record
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getObjectNameAndRecord(String irqId, String objectRelationField){

        try {

            Map<String, Object> responseData = new Map<String, Object>();

            if(String.isNotBlank(objectRelationField) && String.isNotBlank(irqId)) {
                
                String query = 'SELECT reduivy__Individual_Requirement_Set__r.' + objectRelationField + ' FROM ' + IRQ_Helper.getApiName() + ' WHERE Id = :irqId LIMIT 1';
                Map<String, Object> bindMap = new Map<String, Object>{
                    'irqId' => irqId
                };
                
                Object responseRecordId;
                
                for(reduivy__Individual_Requirement__c irq : (List<reduivy__Individual_Requirement__c>) Database.queryWithBinds(query, bindMap, AccessLevel.USER_MODE)){
                    responseRecordId = REDU_SObject_UTIL.extractFieldValue(irq.reduivy__Individual_Requirement_Set__r, objectRelationField);
                }
                
                Schema.DescribeFieldResult objectToUpdate = REDU_Datatable_UTIL.getFieldDescribe(objectRelationField, Schema.reduivy__Individual_Requirement_Set__c.getSObjectType());
                responseData.put(RESPONSE_RECORD_ID, responseRecordId);
                responseData.put(RESPONSE_OBJECT_API_NAME, objectToUpdate.getReferenceTo()[0].getDescribe(SObjectDescribeOptions.DEFERRED).getName());

            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}