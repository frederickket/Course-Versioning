/**
 * @author      WDCi (XW)
 * @date        Oct 2025
 * @group       Individual Score
 * @description Delete the children individual score details if parent scores are deleted
 * @changehistory
 * ISS-002636 07-10-2025 XW - new class
 */

public without sharing class ISC_DeleteScoreDetails_EXE extends REDU_TriggerExecutable {

    /**
     * @description BeforeDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            if(!oldList.isEmpty()) {
                deleteIsd((List<reduivy__Individual_Score__c>) oldList);
            }
        }
    }

    /**
     * @description delete related individual score detail
     * @param iscList
     * @return void
     */
    private void deleteIsd(List<reduivy__Individual_Score__c> iscList) {

        Set<String> isdFields = new Set<String> {
            'Id', 'reduivy__Individual_Score__c'
        };

        String isdQuery = 'SELECT ' + String.join(isdFields, ', ') 
                       + ' FROM ' + ISD_Helper.getApiName()
                       + ' WHERE reduivy__Individual_Score__c IN :iscList';
                       

        Map<String, Object> bindMap = new Map<String, Object>{
            'iscList' => iscList
        };
        
        Map<String, Set<String>> fls = new Map<String, Set<String>>{
            ISD_Helper.getApiName() => isdFields
        };

        List<reduivy__Individual_Score_Detail__c> isdList = new List<reduivy__Individual_Score_Detail__c>();
        for(reduivy__Individual_Score_Detail__c isd : (List<reduivy__Individual_Score_Detail__c>) REDU_SystemMode_UTIL.doQuery(isdQuery, bindMap, fls)) {
            isdList.add(isd);
        }

        if(!isdList.isEmpty()) {
            REDU_SystemMode_UTIL.doDelete(isdList, new Map<Id, reduivy__Individual_Score__c>(iscList), 'reduivy__Individual_Score__c', false);
        }
        
    }
}