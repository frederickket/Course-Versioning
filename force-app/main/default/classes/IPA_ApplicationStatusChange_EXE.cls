/**
 * @author      WDCi (XiRouh)
 * @date        July 2025
 * @group       
 * @description To prevent the application status from changing from 'Create IPE' to a non-'Create IPE' status when IPE(s) already exists for the IPA
 * @changehistory
 * ISS-002487 22-07-2025 XiRouh - new class
 */
public inherited sharing class IPA_ApplicationStatusChange_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description Individual Program Application Create IPE Statuses with IPE Status
     */
    private static final Map<String, String> IPA_CREATE_IPE_STATUSES_WITH_IPE_STATUS = IPA_Helper.getCreateIpeStatusWithIpeEnrollmentStatus();

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

        if (operationType == TriggerOperation.BEFORE_UPDATE) {
            Set<String> applicableIpaStatuses = IPA_CREATE_IPE_STATUSES_WITH_IPE_STATUS.keySet();
            Set<Id> ipaIds = new Set<Id>();

            Map<Id, reduivy__Individual_Program_Application__c> ipaOldMap = 
                new Map<Id, reduivy__Individual_Program_Application__c>((List<reduivy__Individual_Program_Application__c>) oldList);

            Map<Id, reduivy__Individual_Program_Application__c> ipaNewMap = 
                new Map<Id, reduivy__Individual_Program_Application__c>((List<reduivy__Individual_Program_Application__c>) newList);

            for (reduivy__Individual_Program_Application__c ipaNew : ipaNewMap.values()) {
                reduivy__Individual_Program_Application__c ipaOld = ipaOldMap.get(ipaNew.Id);
                
                if ((ipaNew.reduivy__Application_Status__c != ipaOld.reduivy__Application_Status__c) && 
                    (
                        (!applicableIpaStatuses.contains(ipaNew.reduivy__Application_Status__c) && applicableIpaStatuses.contains(ipaOld.reduivy__Application_Status__c))
                    )
                ) {
                    ipaIds.add(ipaNew.Id);
                }
            }

            if(!ipaIds.isEmpty()){
                List<reduivy__Individual_Program_Enrollment__c> relatedIpes = new List<reduivy__Individual_Program_Enrollment__c>();

                for(reduivy__Individual_Program_Enrollment__c ipe : [
                    SELECT Id, reduivy__Individual_Program_Application__c 
                    FROM reduivy__Individual_Program_Enrollment__c 
                    WHERE reduivy__Individual_Program_Application__c IN :ipaIds 
                    WITH USER_MODE
                ]) {
                    reduivy__Individual_Program_Application__c ipa = ipaNewMap.get(ipe.reduivy__Individual_Program_Application__c);

                    String errorMsg = String.format(Label.IPA_ApplicationStatusChange_EXE_StatusChangeDisallowed, 
                                    new List<String>{IPE_Helper.getObjectPluralLabel(), IPA_Helper.getObjectLabel()});

                    ipa.addError(errorMsg);
                }
            }
        }
    }
}