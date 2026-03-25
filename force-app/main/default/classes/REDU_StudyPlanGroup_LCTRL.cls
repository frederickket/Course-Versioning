/**
 * @Author 		WDCi (Lean)
 * @Date 		Nov 2023
 * @group 		Study Plan
 * @Description Study plan hierarchy wizard
 * @changehistory
 * ISS-001617 10-11-2023 Lean - new component
 * ISS-002152 06-11-2024 Jordan - Study Plan Wizard to support modification
 */
public with sharing class REDU_StudyPlanGroup_LCTRL {
    
    /**
     * @description Get child study plan structures
     * @param spsId Parent study plan structure id 
     * @return REDU_LightningResponse
     */
	@AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getChildRecords(Id spsId){
        
        try {
            List<reduivy__Study_Plan_Structure__c> childRecords = new List<reduivy__Study_Plan_Structure__c>();

            Map<String, Object> spsBindParams = new Map<String, Object>{
                'spsId' => spsId
            };

            String spsQuery = 'SELECT Id, Name, RecordType.DeveloperName ' +
            ' FROM reduivy__Study_Plan_Structure__c ' +
            ' WHERE reduivy__Parent_Study_Plan_Structure__c =: spsId ' +
            ' ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC';

            for (reduivy__Study_Plan_Structure__c sps : (List<reduivy__Study_Plan_Structure__c>) Database.queryWithBinds(spsQuery, spsBindParams, AccessLevel.USER_MODE)) {
                childRecords.add(sps);
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(childRecords));
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