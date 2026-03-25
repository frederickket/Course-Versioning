/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description To calculate the GPA on individual academic profile
 * @changehistory
 * ISS-001836 03-01-2024 Lean - new class
 */
public inherited sharing class IPF_CalculateGPA_EXE extends REDU_TriggerExecutable {
    
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
                calculateGpa((List<reduivy__Individual_Academic_Profile__c>) newList);
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
            
            List<reduivy__Individual_Academic_Profile__c> workingList = new List<reduivy__Individual_Academic_Profile__c>();

            for (reduivy__Individual_Academic_Profile__c newIpf : (List<reduivy__Individual_Academic_Profile__c>) newList) {
                reduivy__Individual_Academic_Profile__c oldIpf = (reduivy__Individual_Academic_Profile__c) oldMap.get(newIpf.Id);

                if (
                    newIpf.reduivy__Cumulative_Credits_Attempted__c != oldIpf.reduivy__Cumulative_Credits_Attempted__c ||
                    newIpf.reduivy__Cumulative_Quality_Points__c != oldIpf.reduivy__Cumulative_Quality_Points__c
                ) {
                    workingList.add(newIpf);
                }
            }

            if (!workingList.isEmpty()) {
                calculateGpa(workingList);
            }
        }
    }

    /**
     * @description Calculate the GPA
     * @param ipfList List of reduivy__Individual_Academic_Profile__c
     * @return void
     */
    private void calculateGpa(List<reduivy__Individual_Academic_Profile__c> ipfList) {

        for (reduivy__Individual_Academic_Profile__c ipf : ipfList) {
            if (ipf.reduivy__Cumulative_Credits_Attempted__c != null &&
                ipf.reduivy__Cumulative_Credits_Attempted__c != 0 && 
                ipf.reduivy__Cumulative_Quality_Points__c != null 
            ) {
                ipf.reduivy__Cumulative_GPA__c = ipf.reduivy__Cumulative_Quality_Points__c.divide(ipf.reduivy__Cumulative_Credits_Attempted__c, 4, System.RoundingMode.HALF_UP);
            } else {
                ipf.reduivy__Cumulative_GPA__c = 0;
            }
        }
    }
}