/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Trigger executable
 * @description Copy the credits from study unit for newly created "Unit" study plan structure if the field is left blank
 * @changehistory
 * ISS-002176 27-11-2024 Jordan - new class
 */
public inherited sharing class SPS_DefaultValues_EXE extends REDU_TriggerExecutable {

    private static final Id SPS_RTID_UNIT = SPS_Helper.getUnitRecordTypeId();

    /**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<reduivy__Study_Plan_Structure__c> qualifiedSpsList = new List<reduivy__Study_Plan_Structure__c>();

            for (reduivy__Study_Plan_Structure__c spsNew : (List<reduivy__Study_Plan_Structure__c>) newList) {
                
                if (spsNew.RecordTypeId == SPS_RTID_UNIT && spsNew.reduivy__Credits__c == null && String.isNotBlank(spsNew.reduivy__Study_Unit__c)) {
                    qualifiedSpsList.add(spsNew);
                }
            }

            if(!qualifiedSpsList.isEmpty()){
                copyCredits(qualifiedSpsList);
            }
        }
    }

    /**
     * @description This is to copy the credits from study unit
     * @param qualifiedSpsList List of qualified study plan structure records
     * @return void
     */
    private void copyCredits(List<reduivy__Study_Plan_Structure__c> qualifiedSpsList) {

        //Get study units
        Set<Id> studyUnitIds = new Set<Id>();

        for (reduivy__Study_Plan_Structure__c sps : qualifiedSpsList) {
            if (String.isNotBlank(sps.reduivy__Study_Unit__c)) {
                studyUnitIds.add(sps.reduivy__Study_Unit__c);
            }
        }

        String studyUnitQuery = 'SELECT Id, reduivy__Credits__c ' +
            ' FROM reduivy__Study_Unit__c ' + 
            ' WHERE Id IN: studyUnitIds';

        Map<String, Object> studyUnitBindParams = new Map<String, Object>{
            'studyUnitIds' => studyUnitIds
        };

        Map<Id, reduivy__Study_Unit__c> studyUnitsMap = new Map<Id, reduivy__Study_Unit__c>();

        for(reduivy__Study_Unit__c studyUnit : (List<reduivy__Study_Unit__c>) Database.queryWithBinds(studyUnitQuery, studyUnitBindParams, AccessLevel.USER_MODE)){
            if (studyUnit.reduivy__Credits__c != null) {
                studyUnitsMap.put(studyUnit.Id, studyUnit);
            }
        }

        //Copy credits from study units
        for (reduivy__Study_Plan_Structure__c sps : qualifiedSpsList) {
            if (studyUnitsMap.containsKey(sps.reduivy__Study_Unit__c)) {
                sps.reduivy__Credits__c = studyUnitsMap.get(sps.reduivy__Study_Unit__c).reduivy__Credits__c;
            }
        }
    }
}