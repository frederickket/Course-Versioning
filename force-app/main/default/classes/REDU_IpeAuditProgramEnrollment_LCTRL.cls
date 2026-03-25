/**
 * @author      WDCi (VTan)
 * @date        Oct 2023
 * @group       Lightning Web Component
 * @description ISS-001753 Controller for ipeAudit lightning web component.
 * @changehistory
 * ISS-001753 23-10-2023 VTan - New class
 */
public with sharing class REDU_IpeAuditProgramEnrollment_LCTRL {

    /**
     * @description Get the first level of Individual Plan Structure Group related to the PE
     * @param individualPEId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIdvPlanStructureParentGroups (Id individualPEId){

        try {
            List<reduivy__Individual_Plan_Structure__c> idvPlanStructureGroups = new List<reduivy__Individual_Plan_Structure__c>();
            for(reduivy__Individual_Plan_Structure__c ipsGroup : [SELECT Id, 
                reduivy__Individual_Program_Enrollment__c,
                reduivy__Category__c,
                reduivy__Sequence__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Study_Plan_Structure__r.Name
                FROM reduivy__Individual_Plan_Structure__c
                WHERE reduivy__Individual_Program_Enrollment__c =: individualPEId 
                AND RecordTypeId =: IPS_Helper.getGroupRecordTypeId() 
                AND reduivy__Parent_Plan_Structure__c = null WITH USER_MODE
                ORDER BY reduivy__Category__c DESC, 
                reduivy__Sequence_Key__c ASC NULLS LAST
            ]){

                idvPlanStructureGroups.add(ipsGroup);
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(idvPlanStructureGroups));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}