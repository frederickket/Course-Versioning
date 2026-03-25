/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Trigger executable
 * @description To do rollup for study funding's allocated amount and disbursed amount when update, insert, delete or undelete the individual funding allocation
 * @changehistory
 * ISS-001995 29-08-2024 Sueanne - new class
 */
public without sharing class IFA_StudyFundingAmountRollup_EXE extends REDU_TriggerExecutable {
    
    private final static String IFA_STATUS_ACTIVE = IFA_Helper.STATUS_ACTIVE;
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
        
            List<reduivy__Individual_Funding_Allocation__c> ifaList = new List<reduivy__Individual_Funding_Allocation__c>();

            for(reduivy__Individual_Funding_Allocation__c ifa : (List<reduivy__Individual_Funding_Allocation__c>) newList){
                if(
                    (ifa.reduivy__Amount__c != null || ifa.reduivy__Disbursed_Amount__c != null)
                    && String.isNotBlank(ifa.reduivy__Study_Funding__c)
                    && ifa.reduivy__Status__c == IFA_STATUS_ACTIVE
                ){
                    ifaList.add(ifa);
                }
            }

            if(!ifaList.isEmpty()){
                doRollup(ifaList);
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

            Map<Id, reduivy__Individual_Funding_Allocation__c> oldIfaMap = new Map<Id, reduivy__Individual_Funding_Allocation__c>((List<reduivy__Individual_Funding_Allocation__c>) oldList);
            List<reduivy__Individual_Funding_Allocation__c> ifaList = new List<reduivy__Individual_Funding_Allocation__c>();

            for(reduivy__Individual_Funding_Allocation__c ifa : (List<reduivy__Individual_Funding_Allocation__c>) newList){

                reduivy__Individual_Funding_Allocation__c oldIfa = oldIfaMap.get(ifa.Id);

                if(
                    ifa.reduivy__Amount__c != oldIfa.reduivy__Amount__c 
                    || ifa.reduivy__Disbursed_Amount__c != oldIfa.reduivy__Disbursed_Amount__c
                    || ifa.reduivy__Study_Funding__c != oldIfa.reduivy__Study_Funding__c 
                    || ifa.reduivy__Status__c != oldIfa.reduivy__Status__c
                ){
                    if(String.isNotBlank(ifa.reduivy__Study_Funding__c)){
                        ifaList.add(ifa);
                    }

                    if(
                        String.isNotBlank(oldIfa.reduivy__Study_Funding__c) 
                        && ifa.reduivy__Study_Funding__c != oldIfa.reduivy__Study_Funding__c
                    ){
                        ifaList.add(oldIfa);
                    }
                }
            }

            if(!ifaList.isEmpty()){
                doRollup(ifaList);
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

            List<reduivy__Individual_Funding_Allocation__c> ifaList = new List<reduivy__Individual_Funding_Allocation__c>();

            for(reduivy__Individual_Funding_Allocation__c ifa : (List<reduivy__Individual_Funding_Allocation__c>) oldList){

                if(
                    (ifa.reduivy__Amount__c != null || ifa.reduivy__Disbursed_Amount__c != null)
                    && String.isNotBlank(ifa.reduivy__Study_Funding__c)
                    && ifa.reduivy__Status__c == IFA_STATUS_ACTIVE
                ){
                    ifaList.add(ifa);
                }
            }

            if(!ifaList.isEmpty()){
                doRollup(ifaList);
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

            List<reduivy__Individual_Funding_Allocation__c> ifaList = new List<reduivy__Individual_Funding_Allocation__c>();

            for(reduivy__Individual_Funding_Allocation__c ifa : (List<reduivy__Individual_Funding_Allocation__c>) newList){

                if(
                    (ifa.reduivy__Amount__c != null || ifa.reduivy__Disbursed_Amount__c != null)
                    && String.isNotBlank(ifa.reduivy__Study_Funding__c)
                    && ifa.reduivy__Status__c == IFA_STATUS_ACTIVE
                ){
                    ifaList.add(ifa);
                }
            }

            if(!ifaList.isEmpty()){
                doRollup(ifaList);
            }
        }
    }

    /**
     * @description This is the method that performs the roll up calculation.
     * @param ifaList individual funding allocation list to rollup
     */
    private static void doRollup(List<reduivy__Individual_Funding_Allocation__c> ifaList){

        List<reduivy__Study_Funding__c> sfdToUpdate = new List<reduivy__Study_Funding__c>();
        Map<Id, List<reduivy__Individual_Funding_Allocation__c>> parentChildsMap = new Map<Id, List<reduivy__Individual_Funding_Allocation__c>>();

        for(reduivy__Individual_Funding_Allocation__c ifa : ifaList){
            
            if(!parentChildsMap.containsKey(ifa.reduivy__Study_Funding__c)){
                parentChildsMap.put(ifa.reduivy__Study_Funding__c, new List<reduivy__Individual_Funding_Allocation__c>());
            }
            parentChildsMap.get(ifa.reduivy__Study_Funding__c).add(ifa);
        }

        for (reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_STATUS_ACTIVE
                AND (reduivy__Amount__c != NULL OR reduivy__Disbursed_Amount__c != NULL))
            FROM reduivy__Study_Funding__c
            WHERE Id IN: parentChildsMap.keySet()
            WITH SYSTEM_MODE
            FOR UPDATE
        ]){
            Decimal allocated = 0;
            Decimal disbursed = 0;

            for (reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r) {

                if(ifa.reduivy__Amount__c != null){
                    allocated += ifa.reduivy__Amount__c;
                } 
                
                if(ifa.reduivy__Disbursed_Amount__c != null){
                    disbursed += ifa.reduivy__Disbursed_Amount__c;
                }
            }
            
            if (sfd.reduivy__Allocated_Amount__c != allocated || sfd.reduivy__Disbursed_Amount__c != disbursed) {

                reduivy__Study_Funding__c sfdUpdate = new reduivy__Study_Funding__c();
                sfdUpdate.Id = sfd.Id;
                sfdUpdate.reduivy__Allocated_Amount__c = allocated;
                sfdUpdate.reduivy__Disbursed_Amount__c = disbursed;

                sfdToUpdate.add(sfdUpdate);
            }
        }
        
        //update sfd
        if(!sfdToUpdate.isEmpty()){
            //Rollup using system mode as the fields are non editable by normal user
            REDU_SystemMode_UTIL.doUpdate(sfdToUpdate, parentChildsMap, 'Id', false);
        }
    }
}