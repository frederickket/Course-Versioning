/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Requirement Checklist
 * @description Set the Individual Requirement Submission Status if the review status is updated
 * @changehistory
 * ISS-002128 25-06-2025 XW - new class
 */

public inherited sharing class IRQ_SetSubmissionStatus_EXE extends REDU_TriggerExecutable {
    
    static Map<String, String> reviewStatusToSubmissionStatusMap = IRQ_Helper.getSubmissionStatusMap();

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
            for (reduivy__Individual_Requirement__c irqNew : (List<reduivy__Individual_Requirement__c>) newList) {
                if(String.isNotBlank(irqNew.reduivy__Review_Status__c) && reviewStatusToSubmissionStatusMap.containsKey(irqNew.reduivy__Review_Status__c)) {
                    workingList.add(irqNew);
                }
            }

            if(!workingList.isEmpty()) {
                setSubmissionStatus(workingList);
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
            for (reduivy__Individual_Requirement__c irqNew : (List<reduivy__Individual_Requirement__c>) newList) {
                reduivy__Individual_Requirement__c irqOld = (reduivy__Individual_Requirement__c) oldMap.get(irqNew.Id);

                if (
                    irqNew.reduivy__Review_Status__c != irqOld.reduivy__Review_Status__c &&
                    reviewStatusToSubmissionStatusMap.containsKey(irqNew.reduivy__Review_Status__c) &&
                    reviewStatusToSubmissionStatusMap.get(irqNew.reduivy__Review_Status__c) != irqNew.reduivy__Submission_Status__c
                ) {
                    
                    workingList.add(irqNew);
                }
            }

            if(!workingList.isEmpty()) {
                setSubmissionStatus(workingList);
            }
        }
    }

    /**
     * @description set the submission status based on the review status and the configuration in custom metadata
     * @param list of individual requirement
     */
    private void setSubmissionStatus(List<reduivy__Individual_Requirement__c> irqList) {
        for(reduivy__Individual_Requirement__c irq : irqList){
            irq.reduivy__Submission_Status__c = reviewStatusToSubmissionStatusMap.get(irq.reduivy__Review_Status__c);
        }
    }
}