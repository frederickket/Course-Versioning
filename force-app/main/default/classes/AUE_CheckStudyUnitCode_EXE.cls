/**
 * @author      WDCi (dblack)
 * @date        Nov 2023
 * @group       Trigger executable
 * @description Agreement Unit Equivalent: check the study unit code for the existence of the study unit record
 * @changehistory
 * ISS-001659 09-11-2023 dblack - new class
 */
public inherited sharing class AUE_CheckStudyUnitCode_EXE extends REDU_TriggerExecutable {

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

        if ((operationType == TriggerOperation.AFTER_INSERT) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN))) {

            Map<Id, reduivy__Agreement_Unit_Equivalent__c> aueMap = 
                new Map<Id, reduivy__Agreement_Unit_Equivalent__c>((List<reduivy__Agreement_Unit_Equivalent__c>) newList);
            checkStudyUnitCode(aueMap);
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

        if ((operationType == TriggerOperation.AFTER_UPDATE) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN))) {

            Map<Id, reduivy__Agreement_Unit_Equivalent__c> aueMap = new Map<Id, reduivy__Agreement_Unit_Equivalent__c>();
            for (reduivy__Agreement_Unit_Equivalent__c aueNew : (List<reduivy__Agreement_Unit_Equivalent__c>) newList) {
                reduivy__Agreement_Unit_Equivalent__c aueOld = (reduivy__Agreement_Unit_Equivalent__c) oldMap.get(aueNew.Id); 

                if (aueNew.reduivy__Target_Unit_Codes__c != aueOld.reduivy__Target_Unit_Codes__c) {
                    aueMap.put(aueNew.Id, aueNew);
                }
            }
            
            if (!aueMap.isEmpty()) {
                checkStudyUnitCode(aueMap);
            }
        }
    }

    /**
     * @description Check study unit codes and if the study unit records don't exist throw an error
     * @param aueMap Map<Id, reduivy__Agreement_Unit_Equivalent__c>
     */
    private static void checkStudyUnitCode(Map<Id, reduivy__Agreement_Unit_Equivalent__c> aueMap) {

        Set<String> sunCodesToCheck = new Set<String>();

        // Check if there are study unit codes
        for (reduivy__Agreement_Unit_Equivalent__c aue : aueMap.values()) {

            if (String.isNotBlank(aue.reduivy__Target_Unit_Codes__c)) {
                for (String sunCode : aue.reduivy__Target_Unit_Codes__c.split(';')) {
                    if (String.isNotBlank(sunCode)) {
                        sunCodesToCheck.add(sunCode);
                    }
                }
            }
        }
        
        if (!sunCodesToCheck.isEmpty()) {
            
            // Look for study unit records with the specified study unit codes
            Set<String> validSunCodeSet = new Set<String>();
            for (reduivy__Study_Unit__c sun : [
                SELECT reduivy__Unit_Code__c
                FROM reduivy__Study_Unit__c
                WHERE reduivy__Unit_Code__c IN :sunCodesToCheck
                WITH USER_MODE
            ]) {
                validSunCodeSet.add(sun.reduivy__Unit_Code__c);
            }

            String sunObjLabel = SUN_Helper.getObjectLabel();
            // Check if the study unit codes are valid
            for (reduivy__Agreement_Unit_Equivalent__c aue : aueMap.values()) {

                if (String.isNotBlank(aue.reduivy__Target_Unit_Codes__c)) {
                    List<String> invalidSuns = new List<String>();

                    for (String sunCode : aue.reduivy__Target_Unit_Codes__c.split(';')) {
                        if (!validSunCodeSet.contains(sunCode)) {
                            invalidSuns.add(sunCode);
                        }
                    }

                    if (!invalidSuns.isEmpty()) {
                        List<String> paramList = new List<String>{sunObjLabel, String.join(invalidSuns, ', ')};
                        String errorMsg = String.format(Label.Invalid_Study_Unit_Codes, paramList);

                        aue.addError(errorMsg);
                    }
                }
            }
        }
    }
}