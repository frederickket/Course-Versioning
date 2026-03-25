/**
 * @author      WDCi (XW)
 * @date        Jan 2024
 * @group       Study Intake Group
 * @description Set the existing default Study Intake Group to false
 * @changehistory
 * ISS-002526 08-07-2025 XW - new class
 */

public inherited sharing class SIG_DefaultGroup_EXE extends REDU_TriggerExecutable {
    
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
        
        if (REDU_AppSetting_UTIL.isUsingStudyIntakeGroup() && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            List<reduivy__Study_Intake_Group__c> newDefaults = new List<reduivy__Study_Intake_Group__c>();

            Set<Id> sitWithDefaultSig = new Set<Id>();
            for (reduivy__Study_Intake_Group__c newSig : (List<reduivy__Study_Intake_Group__c>) newList) {
                
                //to make sure that only 1 default child study intake group for each study intake if more than 1 sig with same sit have inserted with default to true
                if (String.isNotBlank(newSig.reduivy__Study_Intake__c) && newSig.reduivy__Default__c) {
                    if(sitWithDefaultSig.contains(newSig.reduivy__Study_Intake__c)) {
                        newSig.reduivy__Default__c = false;
                    } else {
                        sitWithDefaultSig.add(newSig.reduivy__Study_Intake__c);
                    }       
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

        if (REDU_AppSetting_UTIL.isUsingStudyIntakeGroup() && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Set<Id> sitWithDefaultSig = new Set<Id>();
            for (reduivy__Study_Intake_Group__c newSig : (List<reduivy__Study_Intake_Group__c>) newList) {
                reduivy__Study_Intake_Group__c oldSig = (reduivy__Study_Intake_Group__c) oldMap.get(newSig.Id);

                //to make sure that only 1 default child study intake group for each study intake if more than 1 sig with same sit have updated default to true
                if (String.isNotBlank(newSig.reduivy__Study_Intake__c) && newSig.reduivy__Default__c && newSig.reduivy__Default__c != oldSig.reduivy__Default__c ) {
                    if (sitWithDefaultSig.contains(newSig.reduivy__Study_Intake__c)) {
                        newSig.reduivy__Default__c = false;
                    } else {
                        sitWithDefaultSig.add(newSig.reduivy__Study_Intake__c);
                    }
                }
            }
        }
    }

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

        if (REDU_AppSetting_UTIL.isUsingStudyIntakeGroup() && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            List<reduivy__Study_Intake_Group__c> newDefaults = new List<reduivy__Study_Intake_Group__c>();

            for (reduivy__Study_Intake_Group__c newSig : (List<reduivy__Study_Intake_Group__c>) newList) {
                if (isNewlyDefaultOrDefaultAndStudyIntakeChanged(null, newSig)) {
                    newDefaults.add(newSig);
                }
            }

            if (!newDefaults.isEmpty()) {
                unsetOtherDefaults(newDefaults);
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

        if (REDU_AppSetting_UTIL.isUsingStudyIntakeGroup() && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Study_Intake_Group__c> newDefaults = new List<reduivy__Study_Intake_Group__c>();

            for (reduivy__Study_Intake_Group__c newSig : (List<reduivy__Study_Intake_Group__c>) newList) {
                reduivy__Study_Intake_Group__c oldSig = (reduivy__Study_Intake_Group__c) oldMap.get(newSig.Id);
                if (isNewlyDefaultOrDefaultAndStudyIntakeChanged(oldSig, newSig)) {
                    newDefaults.add(newSig);
                }
            }

            if (!newDefaults.isEmpty()) {
                unsetOtherDefaults(newDefaults);
            }
        }
    }

    private Boolean isNewlyDefaultOrDefaultAndStudyIntakeChanged(reduivy__Study_Intake_Group__c oldSig, reduivy__Study_Intake_Group__c newSig) {
        
        Boolean wasDefault = ((oldSig != null) && (oldSig.reduivy__Default__c));
        Boolean isDefault = ((newSig != null) && (newSig.reduivy__Default__c));
        Id oldSitId = (oldSig != null) ? oldSig.reduivy__Study_Intake__c : null;
        Id newSitId = (newSig != null) ? newSig.reduivy__Study_Intake__c : null;

        Boolean sitChanged = ((oldSig != null) && (oldSitId != newSitId));

        return (isDefault) && ((!wasDefault) || (sitChanged));
    }
	
    /**
     * @description unset other default study intake group 
     * @param  newDefaultsSigList list of new set default study intake group
     */
    private void unsetOtherDefaults(List<reduivy__Study_Intake_Group__c> newDefaultsSigList) {
        Map<Id, Id> newDefaultByIntake = new Map<Id, Id>();

        for (reduivy__Study_Intake_Group__c sig : newDefaultsSigList) {
            newDefaultByIntake.put(sig.reduivy__Study_Intake__c, sig.Id);
        }

        List<reduivy__Study_Intake_Group__c> sigListToUnsetList = new List<reduivy__Study_Intake_Group__c>();
        for(reduivy__Study_Intake_Group__c sig : [
            SELECT Id, reduivy__Study_Intake__c
            FROM reduivy__Study_Intake_Group__c
            WHERE reduivy__Study_Intake__c IN :newDefaultByIntake.keySet()
            AND reduivy__Default__c = true
            AND Id NOT IN :newDefaultByIntake.values()
            WITH USER_MODE
        ]) {
            sig.reduivy__Default__c = false;
            sigListToUnsetList.add(sig);
        }

        if (!sigListToUnsetList.isEmpty()) {
            REDU_Database_UTIL.doUpdate(sigListToUnsetList);
        }
    }

}