/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Application Scoring
 * @description Rollup total score from Individual Score Detail to Parent Individual Score Detail
 * @changehistory
 * ISS-002506 12-08-2025 XW - new class
 */

public without sharing class ISD_ScoreDetailRollup_EXE extends REDU_TriggerExecutable {
    
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
                if(objNew.reduivy__Weighted_Score__c != null && String.isNotBlank(objNew.reduivy__Parent_Score_Detail__c)) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                rollupToParentIsd(workingList);
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
                    objNew.reduivy__Parent_Score_Detail__c != objOld.reduivy__Parent_Score_Detail__c
                ) {

                    if(String.isNotBlank(objNew.reduivy__Parent_Score_Detail__c)) {
                        workingList.add(objNew);
                    } 
                    if(objNew.reduivy__Parent_Score_Detail__c != objOld.reduivy__Parent_Score_Detail__c && String.isNotBlank(objOld.reduivy__Parent_Score_Detail__c)) {
                        workingList.add(objOld);
                    }
                }
            }

            if(!workingList.isEmpty()) {
                rollupToParentIsd(workingList);
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

                if(objOld.reduivy__Weighted_Score__c != null && String.isNotBlank(objOld.reduivy__Parent_Score_Detail__c)) {
                    workingList.add(objOld);
                }
            }

            if(!workingList.isEmpty()) {
                rollupToParentIsd(workingList);
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

                if(objNew.reduivy__Weighted_Score__c != null && String.isNotBlank(objNew.reduivy__Parent_Score_Detail__c)) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                rollupToParentIsd(workingList);
            }
        }
    }
	
    /**
     * @description rollup individual score detail total weighted score to parent individual score detail
     * @param
     * @return void
     */
    private void rollupToParentIsd(List<reduivy__Individual_Score_Detail__c> isdList) {
        //get parent isdid => children isd map
        Map<Id, List<reduivy__Individual_Score_Detail__c>> parentIsdIdToIsdMap = new Map<Id, List<reduivy__Individual_Score_Detail__c>>();

        for(reduivy__Individual_Score_Detail__c isd : isdList) {
            if(!parentIsdIdToIsdMap.containsKey(isd.reduivy__Parent_Score_Detail__c)) {
                parentIsdIdToIsdMap.put(isd.reduivy__Parent_Score_Detail__c, new List<reduivy__Individual_Score_Detail__c>());
            }
            parentIsdIdToIsdMap.get(isd.reduivy__Parent_Score_Detail__c).add(isd);
        }

        //query all the parent isd to be rolled up
        List<reduivy__Individual_Score_Detail__c> parentIsdToUpdate = new List<reduivy__Individual_Score_Detail__c>();
        Set<String> isdFields = new Set<String> {
            'Id', 'reduivy__Weighted_Score__c', 'reduivy__Max_Score__c'
        };

        String isdQuery = 'SELECT ' + String.join(isdFields, ',') +
                    ', (' +
                    ' SELECT ' + String.join(isdFields, ',') + 
                    ' FROM reduivy__Individual_Score_Details__r' +
                    ' WHERE reduivy__Status__c = :isdActive' +
                    ' AND reduivy__Weighted_Score__c != null' +
                    ' )' +
                    ' FROM ' + ISD_Helper.getApiName() +
                    ' WHERE Id IN :parentIsdIdSet' +
                    ' AND reduivy__Status__c = :isdActive';

        Map<String, Object> isdBindMap = new Map<String, Object>{
            'isdActive' => ISD_Helper.STATUS_ACTIVE,
            'parentIsdIdSet' => parentIsdIdToIsdMap.keySet()
        };

        //query all of the children isd from the parent isd
        for(reduivy__Individual_Score_Detail__c parentIsd : (List<reduivy__Individual_Score_Detail__c>) REDU_SystemMode_UTIL.doQuery(isdQuery, isdBindMap, new Map<String, Set<String>> {ISD_Helper.getApiName() => isdFields})) {
            Decimal totalWeightedScore = 0;

            for(reduivy__Individual_Score_Detail__c childIsd : parentIsd.reduivy__Individual_Score_Details__r) {
                totalWeightedScore += childIsd.reduivy__Weighted_Score__c ?? 0;
            }

            //capped by max score
            if(parentIsd.reduivy__Max_Score__c != null) {
                totalWeightedScore = Math.min(parentIsd.reduivy__Max_Score__c, totalWeightedScore);
            }

            if(totalWeightedScore != parentIsd.reduivy__Weighted_Score__c) {
                parentIsdToUpdate.add(
                    new reduivy__Individual_Score_Detail__c(
                        Id = parentIsd.Id,
                        reduivy__Weighted_Score__c = totalWeightedScore
                    )
                );
            }
        }

        if(!parentIsdToUpdate.isEmpty()) {
            REDU_SystemMode_UTIL.doUpdate(parentIsdToUpdate, parentIsdIdToIsdMap, 'Id', false);
        }

    }
}