/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Application Scoring
 * @description Rollup total score from Individual Score Detail to Individual Score
 * @changehistory
 * ISS-002506 11-08-2025 XW - new class
 */

public without sharing class ISD_ScoreRollup_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Score_Detail__c> workingList = new List<reduivy__Individual_Score_Detail__c>();
            for (reduivy__Individual_Score_Detail__c objNew : (List<reduivy__Individual_Score_Detail__c>) newList) {
                if(objNew.reduivy__Weighted_Score__c != null && String.isBlank(objNew.reduivy__Parent_Score_Detail__c) && String.isNotBlank(objNew.reduivy__Individual_Score__c)) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                rollupToIndividualScore(workingList);
            }
        }
    }

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Score_Detail__c> workingList = new List<reduivy__Individual_Score_Detail__c>();
            for (reduivy__Individual_Score_Detail__c objNew : (List<reduivy__Individual_Score_Detail__c>) newList) {
                reduivy__Individual_Score_Detail__c objOld = (reduivy__Individual_Score_Detail__c) oldMap.get(objNew.Id);

                if (
                    objNew.reduivy__Weighted_Score__c != objOld.reduivy__Weighted_Score__c ||
                    objNew.reduivy__Individual_Score__c != objOld.reduivy__Individual_Score__c ||
                    objNew.reduivy__Parent_Score_Detail__c != objOld.reduivy__Parent_Score_Detail__c
                ) {

                    if(String.isBlank(objNew.reduivy__Parent_Score_Detail__c) && String.isNotBlank(objNew.reduivy__Individual_Score__c)) {
                        workingList.add(objNew);
                    } 
                    if(String.isBlank(objOld.reduivy__Parent_Score_Detail__c) && objNew.reduivy__Individual_Score__c != objOld.reduivy__Individual_Score__c && String.isNotBlank(objOld.reduivy__Individual_Score__c)) {
                        workingList.add(objOld);
                    }
                }
            }

            if(!workingList.isEmpty()) {
                rollupToIndividualScore(workingList);
            }
        }
    }

    /**
     * @description AfterDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Score_Detail__c> workingList = new List<reduivy__Individual_Score_Detail__c>();
            for (reduivy__Individual_Score_Detail__c objOld : (List<reduivy__Individual_Score_Detail__c>) oldList) {

                if(objOld.reduivy__Weighted_Score__c != null && String.isBlank(objOld.reduivy__Parent_Score_Detail__c) && String.isNotBlank(objOld.reduivy__Individual_Score__c)) {
                    workingList.add(objOld);
                }
            }

            if(!workingList.isEmpty()) {
                rollupToIndividualScore(workingList);
            }
        }
    }

    /**
     * @description AfterUndelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUndelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Score_Detail__c> workingList = new List<reduivy__Individual_Score_Detail__c>();
            for (reduivy__Individual_Score_Detail__c objNew : (List<reduivy__Individual_Score_Detail__c>) newList) {
                if(objNew.reduivy__Weighted_Score__c != null && String.isBlank(objNew.reduivy__Parent_Score_Detail__c) && String.isNotBlank(objNew.reduivy__Individual_Score__c)) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                rollupToIndividualScore(workingList);
            }
        }
    }
	
    /**
     * @description roll up total weighted score from first level isd to parent individual score
     * @param
     * @return void
     */
    private void rollupToIndividualScore(List<reduivy__Individual_Score_Detail__c> isdList) {
        Map<Id, List<reduivy__Individual_Score_Detail__c>> iscIdToIsd = new Map<Id, List<reduivy__Individual_Score_Detail__c>>();
        for(reduivy__Individual_Score_Detail__c isd : isdList) {
            if(!iscIdToIsd.containsKey(isd.reduivy__Individual_Score__c)) {
                iscIdToIsd.put(isd.reduivy__Individual_Score__c, new List<reduivy__Individual_Score_Detail__c>());
            }

            iscIdToIsd.get(isd.reduivy__Individual_Score__c).add(isd);
        }

        List<reduivy__Individual_Score__c> iscListToUpdate = new List<reduivy__Individual_Score__c>();
        Set<String> isdFields = new Set<String> {
            'Id', 'reduivy__Weighted_Score__c'
        };

        String isdQuery = 'SELECT ' + String.join(isdFields, ', ') + 
                         ' FROM reduivy__Individual_Score_Details__r' +
                         ' WHERE reduivy__Status__c = :isdActive' +
                         ' AND reduivy__Parent_Score_Detail__c = null' +
                         ' AND reduivy__Weighted_Score__c != null';

        Set<String> iscFields = new Set<String> {
            'Id', 'Name'
        };

        String iscQuery = 'SELECT ' + String.join(iscFields, ', ') +
                         ' , ( ' + isdQuery + ')' +
                         ' FROM ' + ISC_Helper.getApiName() +
                         ' WHERE Id IN :iscIdSet' +
                         ' AND reduivy__Status__c = :iscActive';

        Map<String, Object> bindMap = new Map<String, Object>{
            'isdActive' => ISD_Helper.STATUS_ACTIVE,
            'iscIdSet' => iscIdToIsd.keySet(),
            'iscActive' => ISC_Helper.STATUS_ACTIVE
        };

        Map<String, Set<String>> flsMap = new Map<String, Set<String>>{
            ISD_Helper.getApiName() => isdFields,
            ISC_Helper.getApiName() => iscFields
        };
        
        for(reduivy__Individual_Score__c isc : (List<reduivy__Individual_Score__c>) REDU_SystemMode_UTIL.doQuery(iscQuery, bindMap, flsMap)) {
            Decimal totalWeightedScore = 0;

            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                totalWeightedScore += isd.reduivy__Weighted_Score__c ?? 0;
            }
            iscListToUpdate.add(
                new reduivy__Individual_Score__c(
                    Id = isc.Id,
                    reduivy__Total_Score__c = totalWeightedScore,
                    reduivy__Last_Calculated_Date__c = System.now()
                )
            );

        }

        if(!iscListToUpdate.isEmpty()) {
            REDU_SystemMode_UTIL.doUpdate(iscListToUpdate, iscIdToIsd, 'Id', false);
        }
    }
}