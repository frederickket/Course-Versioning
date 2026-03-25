/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Fundings
 * @description This is to set the default values on individual funding allocation when a new record is created.
 * @changehistory
 * ISS-002168 10-01-2025 Lean - new class
 */
public inherited sharing class IFA_DefaultValues_EXE extends REDU_TriggerExecutable {
    
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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Funding_Allocation__c> workingList = new List<reduivy__Individual_Funding_Allocation__c>();
            for (reduivy__Individual_Funding_Allocation__c newIfa : (List<reduivy__Individual_Funding_Allocation__c>) newList) {
                
                if (String.isNotBlank(newIfa.reduivy__Study_Funding__c) && 
                    newIfa.reduivy__Max_Per_Term__c == null
                ) {
                    workingList.add(newIfa);
                }
            }

            if (!workingList.isEmpty()) {
                setDefaultValues(workingList);
            }
        }
    }
	
    /**
     * @description Set default values on individual funding allocations
     * @param ifaList
     * @return void
     */
    private void setDefaultValues(List<reduivy__Individual_Funding_Allocation__c> ifaList) {
        
        Set<Id> sfdIds = new Set<Id>();
        for (reduivy__Individual_Funding_Allocation__c ifa : ifaList) {
            if (String.isNotBlank(ifa.reduivy__Study_Funding__c)) {
                sfdIds.add(ifa.reduivy__Study_Funding__c);
            }
        }

        if (!sfdIds.isEmpty()) {
            Map<Id, reduivy__Study_Funding__c> studyFundings = new Map<Id, reduivy__Study_Funding__c>([SELECT Id,
                reduivy__Max_Per_Term__c
                FROM reduivy__Study_Funding__c
                WHERE Id IN: sfdIds
                WITH USER_MODE
            ]);

            for (reduivy__Individual_Funding_Allocation__c ifa : ifaList) {
                if (studyFundings.containsKey(ifa.reduivy__Study_Funding__c)) {
                    ifa.reduivy__Max_Per_Term__c = studyFundings.get(ifa.reduivy__Study_Funding__c).reduivy__Max_Per_Term__c;
                }
            }
        }
    }
}