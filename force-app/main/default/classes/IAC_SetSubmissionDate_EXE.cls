/**
 * @author      WDCi (XW)
 * @date        Nov 2025
 * @group       
 * @description 
 * @changehistory
 * ISS-002633 14-11-2025 XW - create new class
 */

public inherited sharing class IAC_SetSubmissionDate_EXE extends REDU_TriggerExecutable {
    
    private static List<String> SUBMITTED_STATUSES = IAC_Helper.getSubmittedVerificationStatuses();
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

            List<reduivy__Individual_Achievement__c> workingList = new List<reduivy__Individual_Achievement__c>();
            for (reduivy__Individual_Achievement__c objNew : (List<reduivy__Individual_Achievement__c>) newList) {
                if(
                    String.isNotBlank(objNew.reduivy__Verification_Status__c) && 
                    SUBMITTED_STATUSES.contains(objNew.reduivy__Verification_Status__c)
                ) {    
                    workingList.add(objNew);
                }
            }

            setSubmissionDate(workingList);
        }
    }

    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Achievement__c> workingList = new List<reduivy__Individual_Achievement__c>();
            for (reduivy__Individual_Achievement__c objNew : (List<reduivy__Individual_Achievement__c>) newList) {
                reduivy__Individual_Achievement__c objOld = (reduivy__Individual_Achievement__c) oldMap.get(objNew.Id);

                if(
                    String.isNotBlank(objNew.reduivy__Verification_Status__c) && 
                    objOld.reduivy__Verification_Status__c != objNew.reduivy__Verification_Status__c &&
                    SUBMITTED_STATUSES.contains(objNew.reduivy__Verification_Status__c) &&
                    !SUBMITTED_STATUSES.contains(objOld.reduivy__Verification_Status__c) 
                ) {    
                    workingList.add(objNew);
                }
            }

            setSubmissionDate(workingList);
        }
    }

    /**
     * @description set the submission date of iac to today
     * @param
     * @return voids
     */
    private void setSubmissionDate(List<reduivy__Individual_Achievement__c> iacList) {
        for(reduivy__Individual_Achievement__c iac : iacList) {
            iac.reduivy__Submission_Date__c = System.today();
        }
    }
}