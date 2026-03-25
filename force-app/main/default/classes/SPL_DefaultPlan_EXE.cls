/**
 * @author      WDCi (Lean)
 * @date        Nov 2023
 * @group       Study Plan
 * @description This is to unset the Default checkbox for other study plan when a study plan is promoted as default
 * @changehistory
 * ISS-001798 06-11-2023 Lean - New class
 */
public inherited sharing class SPL_DefaultPlan_EXE extends REDU_TriggerExecutable {
    
	/**
     * @description This is to ensure that the current trigger list doesn't contain duplicate default study plan
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Set<Id> spgWithDefaultSpl = new Set<Id>();
            for (reduivy__Study_Plan__c spl : (List<reduivy__Study_Plan__c>) newList) {
                if (String.isNotBlank(spl.reduivy__Study_Program__c) && spl.reduivy__Default__c) {
                    if (spgWithDefaultSpl.contains(spl.reduivy__Study_Program__c)) {
                        spl.reduivy__Default__c = false;
                    } else {
                        spgWithDefaultSpl.add(spl.reduivy__Study_Program__c);
                    }
                }
            }

        }

    }

    /**
     * @description This is to ensure that the current trigger list doesn't contain duplicate default study plan
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Set<Id> spgWithDefaultSpl = new Set<Id>();
            for (reduivy__Study_Plan__c spl : (List<reduivy__Study_Plan__c>) newList) {
                reduivy__Study_Plan__c oldSpl = (reduivy__Study_Plan__c) oldMap.get(spl.Id);

                if (String.isNotBlank(spl.reduivy__Study_Program__c) && spl.reduivy__Default__c && spl.reduivy__Default__c != oldSpl.reduivy__Default__c ) {
                    if (spgWithDefaultSpl.contains(spl.reduivy__Study_Program__c)) {
                        spl.reduivy__Default__c = false;
                    } else {
                        spgWithDefaultSpl.add(spl.reduivy__Study_Program__c);
                    }
                }
            }

        }

    }

    /**
     * @description This is to make other study plan as non default if the current trigger list has one.
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<reduivy__Study_Plan__c> workingSplList = new List<reduivy__Study_Plan__c>();

            for (reduivy__Study_Plan__c spl : (List<reduivy__Study_Plan__c>) newList) {
                if (isNewlyDefaultOrDefaultAndStudyProgramChanged(null, spl)) {
                    workingSplList.add(spl);
                }
            }

            if (!workingSplList.isEmpty()) {
                unsetOtherDefaultPlan(workingSplList);
            }
        }

    }

    /**
     * @description This is to make other study plan as non default if the current trigger list has one promoted or the study program for an existing study plan is changed.
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<reduivy__Study_Plan__c> workingSplList = new List<reduivy__Study_Plan__c>();

            for (reduivy__Study_Plan__c spl : (List<reduivy__Study_Plan__c>) newList) {
                reduivy__Study_Plan__c oldSpl = (reduivy__Study_Plan__c) oldMap.get(spl.Id);

                if (isNewlyDefaultOrDefaultAndStudyProgramChanged(oldSpl, spl)) {
                    workingSplList.add(spl);
                }
            }

            if (!workingSplList.isEmpty()) {
                unsetOtherDefaultPlan(workingSplList);
            }
        }

    }

    /**
     * @description This is to unset other default study pathway
     * @param newDefaultPathways List of new default pathway
     * @return void
     */
    private void unsetOtherDefaultPlan(List<reduivy__Study_Plan__c> newDefaultPlans) {

        if (!newDefaultPlans.isEmpty()) {
            Set<Id> splIds = new Set<Id>();

            Map<Id, List<reduivy__Study_Plan__c>> spgStudyPlans = new Map<Id, List<reduivy__Study_Plan__c>>();
            for (reduivy__Study_Plan__c spl : newDefaultPlans) {
                
                if (String.isNotBlank(spl.reduivy__Study_Program__c)) {
                    splIds.add(spl.Id);

                    if (spgStudyPlans.containsKey(spl.reduivy__Study_Program__c)) {
                        spgStudyPlans.get(spl.reduivy__Study_Program__c).add(spl);
                    } else {
                        spgStudyPlans.put(spl.reduivy__Study_Program__c, new List<reduivy__Study_Plan__c>{spl});
                    }
                }
            }

            List<reduivy__Study_Plan__c> splUpdateList = new List<reduivy__Study_Plan__c>();
            for (reduivy__Study_Plan__c otherSpl : [SELECT Id, reduivy__Default__c, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c
                WHERE reduivy__Study_Program__c IN: spgStudyPlans.keySet()
                AND Id NOT IN: splIds
                WITH USER_MODE
            ]) {
                otherSpl.reduivy__Default__c = false;
                splUpdateList.add(otherSpl);
            }

            REDU_Database_UTIL.doUpdate(splUpdateList, spgStudyPlans, 'reduivy__Study_Program__c', false);
        }
    }

    /**
     * @description This is to validate if the new study plan is default or the existing study plan is changed to default or the study program has changed
     * @param oldSpl Old study pathway record
     * @param newSpw New study pathway record
     * @return Boolean
     */
    private Boolean isNewlyDefaultOrDefaultAndStudyProgramChanged(reduivy__Study_Plan__c oldSpl, reduivy__Study_Plan__c newSpl) {
        Boolean wasDefault = ((oldSpl != null) && (oldSpl.reduivy__Default__c));
        Boolean isDefault = ((newSpl != null) && (newSpl.reduivy__Default__c));
        Id oldSpgId = (oldSpl != null) ? oldSpl.reduivy__Study_Program__c : null;
        Id newSpgId = (newSpl != null) ? newSpl.reduivy__Study_Program__c : null;

        Boolean programChange = ((oldSpl != null) && (oldSpgId != newSpgId));

        return (isDefault) && ((!wasDefault) || (programChange));
    }
	
}