/**
 * @author      WDCi (XW)
 * @date        Dec 2025
 * @group       
 * @description Set individual achievement’s verification status to Open when the related individual achievement units are set to open.
 * @changehistory
 * ISS-002633 11-12-2025 XW - new class
 */

public inherited sharing class IAU_SetIacVerficationStatus_EXE extends REDU_TriggerExecutable {
    
    private List<String> IAC_VERIFIED_VERIFICATION_STATUSES = IAC_Helper.getVerifiedVerificationStatuses();
    private List<String> IAU_VERIFIED_VERIFICATION_STATUSES = IAU_Helper.getVerifiedVerificationStatuses();
    private List<String> IAC_OPEN_VERIFICATION_STATUSES = IAC_Helper.getOpenVerificationStatuses();
    private List<String> IAU_OPEN_VERIFICATION_STATUSES = IAU_Helper.getOpenVerificationStatuses();

    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Achievement_Unit__c> iauList = new List<reduivy__Individual_Achievement_Unit__c>();
            for (reduivy__Individual_Achievement_Unit__c objNew : (List<reduivy__Individual_Achievement_Unit__c>) newList) {

                if(
                    String.isNotBlank(objNew.reduivy__Individual_Achievement__c) &&
                    String.isNotBlank(objNew.reduivy__Verification_Status__c) &&
                    IAU_OPEN_VERIFICATION_STATUSES.contains(objNew.reduivy__Verification_Status__c)
                ) {
                    iauList.add(objNew);
                }
            }

            if(!iauList.isEmpty()) {
                setIacVerificationStatus(iauList);
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
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Achievement_Unit__c> iauList = new List<reduivy__Individual_Achievement_Unit__c>();
            for (reduivy__Individual_Achievement_Unit__c objNew : (List<reduivy__Individual_Achievement_Unit__c>) newList) {
                reduivy__Individual_Achievement_Unit__c objOld = (reduivy__Individual_Achievement_Unit__c) oldMap.get(objNew.Id);

                if(
                    String.isNotBlank(objNew.reduivy__Individual_Achievement__c) &&
                    String.isNotBlank(objNew.reduivy__Verification_Status__c) &&
                    objNew.reduivy__Verification_Status__c != objOld.reduivy__Verification_Status__c &&
                    IAU_OPEN_VERIFICATION_STATUSES.contains(objNew.reduivy__Verification_Status__c) &&
                    !IAU_OPEN_VERIFICATION_STATUSES.contains(objOld.reduivy__Verification_Status__c)
                ) {
                    iauList.add(objNew);
                }
            }

            if(!iauList.isEmpty()) {
                setIacVerificationStatus(iauList);
            }
        }
    }
	
    /**
     * @description set individual achievements verification status to open
     * @param
     * @return void
     */
    private void setIacVerificationStatus(List<reduivy__Individual_Achievement_Unit__c> iauList) {
        Map<Id, List<reduivy__Individual_Achievement_Unit__c>> iauSourceObjMap = new Map<Id, List<reduivy__Individual_Achievement_Unit__c>>();
        for(reduivy__Individual_Achievement_Unit__c iau : iauList) {
            if(!iauSourceObjMap.containsKey(iau.reduivy__Individual_Achievement__c)) {
                iauSourceObjMap.put(iau.reduivy__Individual_Achievement__c, new List<reduivy__Individual_Achievement_Unit__c>());
            }
            iauSourceObjMap.get(iau.reduivy__Individual_Achievement__c).add(iau);
        }

        List<reduivy__Individual_Achievement__c> updateIacList = new List<reduivy__Individual_Achievement__c>();
        for(reduivy__Individual_Achievement_Unit__c iau : iauList) {
            reduivy__Individual_Achievement__c updateIac = new reduivy__Individual_Achievement__c(
                Id = iau.reduivy__Individual_Achievement__c,
                reduivy__Verification_Status__c = IAC_OPEN_VERIFICATION_STATUSES[0]
            );
            updateIacList.add(updateIac);
        }
       
        if(!updateIacList.isEmpty()) {
            REDU_Database_UTIL.doUpdate(updateIacList, iauSourceObjMap, 'Id', true);
        }
    }
}