/**
 * @author      WDCi (VTan)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description This is to update credit transfer application transfer status date when the application is approved/rejected.
 * @changehistory
 * ISS-002045 VTan 22-08-2024 - New class
 */
public inherited sharing class CTA_SetTransferStatusDate_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
    */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)){

            List<String> ctaApprovedStatuses = CTA_Helper.getApprovedStatuses();
            List<String> ctaRejectedStatuses = CTA_Helper.getRejectedStatuses();

            for (reduivy__Credit_Transfer_Application__c ctaNew : (List<reduivy__Credit_Transfer_Application__c>) newList) {
                if (ctaNew.reduivy__Transfer_Status_Date__c == null && 
                    String.isNotBlank(ctaNew.reduivy__Status__c) && 
                    (ctaApprovedStatuses.contains(ctaNew.reduivy__Status__c) || ctaRejectedStatuses.contains(ctaNew.reduivy__Status__c))
                ) {

                    setTransferStatusDate(ctaNew);
                }
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

        if(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)){

            List<String> ctaApprovedStatuses = CTA_Helper.getApprovedStatuses();
            List<String> ctaRejectedStatuses = CTA_Helper.getRejectedStatuses();
            
            for (reduivy__Credit_Transfer_Application__c ctaNew : (List<reduivy__Credit_Transfer_Application__c>) newList) {
                reduivy__Credit_Transfer_Application__c ctaOld = (reduivy__Credit_Transfer_Application__c) oldMap.get(ctaNew.Id);

                if (String.isNotBlank(ctaNew.reduivy__Status__c) && 
                    ctaNew.reduivy__Status__c != ctaOld.reduivy__Status__c && 
                    (ctaApprovedStatuses.contains(ctaNew.reduivy__Status__c) || ctaRejectedStatuses.contains(ctaNew.reduivy__Status__c))
                ) {
                    
                    setTransferStatusDate(ctaNew);
                }
            }
        }
    }

    /**
     * @description Sets the transfer status date in Credit transfer Application
     * @param cta reduivy__Credit_Transfer_Application__c
     */
    private void setTransferStatusDate(reduivy__Credit_Transfer_Application__c cta) {

        cta.reduivy__Transfer_Status_Date__c = System.today();
    }
}