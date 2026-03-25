/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description To calculate the GPA on individual academic progress
 * @changehistory
 * ISS-001836 03-01-2024 Lean - new class
 */
public inherited sharing class IPR_CalculateGPA_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description Calculate the GPA
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            if (!newList.isEmpty()) {
                calculateGpa((List<reduivy__Individual_Academic_Progress__c>) newList);
            }
        }
    }

    /**
     * @description Calculate the GPA
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Academic_Progress__c> workingList = new List<reduivy__Individual_Academic_Progress__c>();

            for (reduivy__Individual_Academic_Progress__c newIpr : (List<reduivy__Individual_Academic_Progress__c>) newList) {
                reduivy__Individual_Academic_Progress__c oldIpr = (reduivy__Individual_Academic_Progress__c) oldMap.get(newIpr.Id);

                if (
                    newIpr.reduivy__Credits_Attempted__c != oldIpr.reduivy__Credits_Attempted__c ||
                    newIpr.reduivy__Credits_Earned__c != oldIpr.reduivy__Credits_Earned__c ||
                    newIpr.reduivy__Quality_Points__c != oldIpr.reduivy__Quality_Points__c
                ) {
                    workingList.add(newIpr);
                }
            }

            if (!workingList.isEmpty()) {
                calculateGpa(workingList);
            }
        }
    }

    /**
     * @description Calculate the GPA
     * @param iprList List of reduivy__Individual_Academic_Progress__c
     * @return void
     */
    private void calculateGpa(List<reduivy__Individual_Academic_Progress__c> iprList) {

        for (reduivy__Individual_Academic_Progress__c ipr : iprList) {
            if (ipr.reduivy__Credits_Attempted__c != null &&
                ipr.reduivy__Credits_Attempted__c != 0 && 
                ipr.reduivy__Quality_Points__c != null 
            ) {
                ipr.reduivy__GPA__c = ipr.reduivy__Quality_Points__c.divide(ipr.reduivy__Credits_Attempted__c, 4, System.RoundingMode.HALF_UP);
            } else {
                ipr.reduivy__GPA__c = 0;
            }
        }
    }
}