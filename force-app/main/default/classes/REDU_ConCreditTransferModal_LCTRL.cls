/**
 * @author      WDCi (VTan)
 * @date        Jan 2024
 * @group       Lightning Web Component
 * @description ISS-001659 08-01-2024 VTan - New Component
 * @changehistory
 * ISS-002045 30-07-2024 Sueanne - update to get another field set for approve modal (approveModalFieldMember)
 * ISS-002330 21-03-2025 XW - query study unit translation name if found
 */
 public with sharing class REDU_ConCreditTransferModal_LCTRL {
    
    /**
     * @description Get the details of current Credit Transfer Application
     * @param fieldSetName Name of the field set
     * @param objectName API name of the object
     * @param recordId API name of the object
     * @return List<Schema.FieldSetMember>
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getFields(String fieldSetName, String approveModalFieldSetName, String objectName, String recordId) {
        
        Map<String, Object> responseJSON = new Map<String, Object>();
        try {

            if(recordId != null && String.isNotBlank(recordId)){

                //Query credit transfer application if the credit transfer application Id is not empty
                String ctaQuery = 'SELECT reduivy__Agreement_Unit_Equivalent__c, ' +
                    ' reduivy__Agreement_Unit_Equivalent__r.reduivy__Type__c, ' +
                    ' reduivy__Agreement_Unit_Equivalent__r.reduivy__Target_Unit_Codes__c, ' +
                    ' reduivy__Agreement_Unit_Equivalent__r.reduivy__Agreement__c, ' +
                    ' reduivy__Individual_Program_Enrollment__c, ' +
                    ' reduivy__Individual_Plan_Structure__c, ' +
                    ' reduivy__Individual_Plan_Structure__r.reduivy__Study_Plan_Structure__r.Name' +
                    ' FROM reduivy__Credit_Transfer_Application__c' + 
                    ' WHERE Id =: recordId';

                Map<String, Object> ctaBindParams = new Map<String, Object>{
                    'recordId' => recordId
                };
                
                reduivy__Credit_Transfer_Application__c ctaInfo = new reduivy__Credit_Transfer_Application__c();

                for(sObject cta : Database.queryWithBinds(ctaQuery, ctaBindParams, AccessLevel.USER_MODE)){

                    ctaInfo = (reduivy__Credit_Transfer_Application__c) cta;
                }

                if(String.isNotBlank(ctaInfo.reduivy__Agreement_Unit_Equivalent__r.reduivy__Target_Unit_Codes__c)){

                    Set<String> approvableUnitCode = new Set<String>();
                    approvableUnitCode.addAll(ctaInfo.reduivy__Agreement_Unit_Equivalent__r.reduivy__Target_Unit_Codes__c.split(';'));

                    Set<String> suFieldsToQuery = new Set<String>{
                        'Name',
                        'reduivy__Unit_Code__c',
                        SUN_Helper.getTranslationFieldNameForName()
                    };

                    String suQuery = 'SELECT ' + String.join(suFieldsToQuery, ', ') + 
                        ' FROM reduivy__Study_Unit__c ' + 
                        ' WHERE reduivy__Unit_Code__c IN: approvableUnitCode';

                    Map<String, Object> suBindParams = new Map<String, Object>{
                        'approvableUnitCode' => approvableUnitCode
                    };

                    List<reduivy__Study_Unit__c> approvableUnits = new List<reduivy__Study_Unit__c>();
                    for(reduivy__Study_Unit__c studyUnit : (List<reduivy__Study_Unit__c>) Database.queryWithBinds(suQuery, suBindParams, AccessLevel.USER_MODE)){
                        approvableUnits.add(studyUnit);
                    }

                    if(!approvableUnits.isEmpty()){

                        responseJSON.put('approvableUnits', approvableUnits);
                        REDU_Logging_UTIL.debug('approvableUnits :: ', approvableUnits);
                    }
                }

                responseJSON.put('lookupFields', ctaInfo);
                REDU_Logging_UTIL.debug('lookupFields :: ', ctaInfo);

            }

            responseJSON.put('fieldMember', REDU_Metadata_UTIL.getFieldSetMembers(objectName, fieldSetName));
            responseJSON.put('approveModalFieldMember', REDU_Metadata_UTIL.getFieldSetMembers(objectName, approveModalFieldSetName));
            responseJSON.put('approvalStatus', CTA_Helper.getApprovedStatuses().get(0));

            REDU_Logging_UTIL.debug('responseJSON', responseJSON);

            return new REDU_LightningResponse(true, 'success', JSON.serialize(responseJSON));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}