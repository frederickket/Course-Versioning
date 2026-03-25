/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Requirement 
 * @description Set the review date and the submit date of individual requirements
 * @changehistory
 * ISS-002128 16-06-2025 XW - new class
 * ISS-002665 11-11-2025 XiRouh - Added SUBMITTED_STATUSES
 */

public with sharing class IRQ_SetDates_EXE extends REDU_TriggerExecutable {
    
    static List<String> REVIEWED_STATUSES = IRQ_Helper.getReviewedStatuses();
    static List<String> SUBMITTED_STATUSES = IRQ_Helper.getSubmissionSubmittedStatuses();

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

            List<reduivy__Individual_Requirement__c> workingList = new List<reduivy__Individual_Requirement__c>();
            for (reduivy__Individual_Requirement__c objNew : (List<reduivy__Individual_Requirement__c>) newList) {
                if(objNew.reduivy__Status__c == IRQ_Helper.STATUS_ACTIVE && (SUBMITTED_STATUSES.contains(objNew.reduivy__Submission_Status__c) || REVIEWED_STATUSES.contains(objNew.reduivy__Review_Status__c))) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                setDates(workingList);
            }
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

            List<reduivy__Individual_Requirement__c> workingList = new List<reduivy__Individual_Requirement__c>();
            for (reduivy__Individual_Requirement__c objNew : (List<reduivy__Individual_Requirement__c>) newList) {
                reduivy__Individual_Requirement__c objOld = (reduivy__Individual_Requirement__c) oldMap.get(objNew.Id);

                if (objNew.reduivy__Status__c == IRQ_Helper.STATUS_ACTIVE &&
                    ((
                        objNew.reduivy__Submission_Status__c != objOld.reduivy__Submission_Status__c &&
                        SUBMITTED_STATUSES.contains(objNew.reduivy__Submission_Status__c) 
                    ) ||
                    (
                        objOld.reduivy__Review_Status__c != objNew.reduivy__Review_Status__c &&
                        REVIEWED_STATUSES.contains(objNew.reduivy__Review_Status__c) 
                    ))
                ) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                setDates(workingList);
            }
        }
    }

    /**
     * @description set the date time of the review and submit date
     * @param irqList list of individual requirement to be populated
     * @return void
     */
    private void setDates(List<reduivy__Individual_Requirement__c> irqList) {
        for(reduivy__Individual_Requirement__c irq : irqList) {
            if(REVIEWED_STATUSES.contains(irq.reduivy__Review_Status__c)) {
                irq.reduivy__Review_Date__c = System.now();
            }
            if(SUBMITTED_STATUSES.contains(irq.reduivy__Submission_Status__c)) {
                irq.reduivy__Submission_Date__c = System.now();
            }
        }
    }
}