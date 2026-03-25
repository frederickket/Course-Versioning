/**
 * @author      WDCi (Lean)
 * @date        Nov 2023
 * @group       Study Pathway
 * @description This is to unset the Default checkbox for other study pathway when a study pathway is promoted as default
 * @changehistory
 * ISS-001797 06-11-2023 Lean - New class
 */
public inherited sharing class SPW_DefaultPathway_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description This is to ensure that the current trigger list doesn't contain duplicate default study pathway
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Set<Id> splWithDefaultSpw = new Set<Id>();
            for (reduivy__Study_Pathway__c spw : (List<reduivy__Study_Pathway__c>) newList) {
                if (String.isNotBlank(spw.reduivy__Study_Plan__c) && spw.reduivy__Default__c) {
                    if (splWithDefaultSpw.contains(spw.reduivy__Study_Plan__c)) {
                        spw.reduivy__Default__c = false;
                    } else {
                        splWithDefaultSpw.add(spw.reduivy__Study_Plan__c);
                    }
                }
            }

        }
    }

    /**
     * @description This is to ensure that the current trigger list doesn't contain duplicate default study pathway
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Set<Id> splWithDefaultSpw = new Set<Id>();
            for (reduivy__Study_Pathway__c spw : (List<reduivy__Study_Pathway__c>) newList) {
                reduivy__Study_Pathway__c oldSpw = (reduivy__Study_Pathway__c) oldMap.get(spw.Id);

                if (String.isNotBlank(spw.reduivy__Study_Plan__c) && spw.reduivy__Default__c && spw.reduivy__Default__c != oldSpw.reduivy__Default__c ) {
                    if (splWithDefaultSpw.contains(spw.reduivy__Study_Plan__c)) {
                        spw.reduivy__Default__c = false;
                    } else {
                        splWithDefaultSpw.add(spw.reduivy__Study_Plan__c);
                    }
                }
            }

        }
    }

	/**
     * @description This is to make other study pathway as non default if the current trigger list has one.
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<reduivy__Study_Pathway__c> workingSpwList = new List<reduivy__Study_Pathway__c>();

            for (reduivy__Study_Pathway__c spw : (List<reduivy__Study_Pathway__c>) newList) {
                if (isNewlyDefaultOrDefaultAndStudyPlanChanged(null, spw)) {
                    workingSpwList.add(spw);
                }
            }

            if (!workingSpwList.isEmpty()) {
                unsetOtherDefaultPathway(workingSpwList);
            }
        }
    }

    /**
     * @description This is to make other study pathway as non default if the current trigger list has one promoted or the study plan for an existing study pathway is changed.
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<reduivy__Study_Pathway__c> workingSpwList = new List<reduivy__Study_Pathway__c>();

            for (reduivy__Study_Pathway__c spw : (List<reduivy__Study_Pathway__c>) newList) {
                reduivy__Study_Pathway__c oldSpw = (reduivy__Study_Pathway__c) oldMap.get(spw.Id);

                if (isNewlyDefaultOrDefaultAndStudyPlanChanged(oldSpw, spw)) {
                    workingSpwList.add(spw);
                }
            }

            if (!workingSpwList.isEmpty()) {
                unsetOtherDefaultPathway(workingSpwList);
            }
        }

    }

    /**
     * @description This is to unset other default study pathway
     * @param newDefaultPathways List of new default pathway
     * @return void
     */
    private void unsetOtherDefaultPathway(List<reduivy__Study_Pathway__c> newDefaultPathways) {

        if (!newDefaultPathways.isEmpty()) {
            Set<Id> spwIds = new Set<Id>();

            Map<Id, List<reduivy__Study_Pathway__c>> splStudyPathways = new Map<Id, List<reduivy__Study_Pathway__c>>();
            for (reduivy__Study_Pathway__c spw : newDefaultPathways) {
                
                if (String.isNotBlank(spw.reduivy__Study_Plan__c)) {
                    spwIds.add(spw.Id);

                    if (splStudyPathways.containsKey(spw.reduivy__Study_Plan__c)) {
                        splStudyPathways.get(spw.reduivy__Study_Plan__c).add(spw);
                    } else {
                        splStudyPathways.put(spw.reduivy__Study_Plan__c, new List<reduivy__Study_Pathway__c>{spw});
                    }
                }
            }

            List<reduivy__Study_Pathway__c> spwUpdateList = new List<reduivy__Study_Pathway__c>();
            for (reduivy__Study_Pathway__c otherSpw : [SELECT Id, reduivy__Default__c, reduivy__Study_Plan__c
                FROM reduivy__Study_Pathway__c
                WHERE reduivy__Study_Plan__c IN: splStudyPathways.keySet()
                AND Id NOT IN: spwIds
                WITH USER_MODE
            ]) {
                otherSpw.reduivy__Default__c = false;
                spwUpdateList.add(otherSpw);
            }

            REDU_Database_UTIL.doUpdate(spwUpdateList, splStudyPathways, 'reduivy__Study_Plan__c', false);
        }
    }

    /**
     * @description This is to validate if the new study pathway is default or the existing study pathway is changed to default or the study plan has changed
     * @param oldSpw Old study pathway record
     * @param newSpw New study pathway record
     * @return Boolean
     */
    private Boolean isNewlyDefaultOrDefaultAndStudyPlanChanged(reduivy__Study_Pathway__c oldSpw, reduivy__Study_Pathway__c newSpw) {
        Boolean wasDefault = ((oldSpw != null) && (oldSpw.reduivy__Default__c));
        Boolean isDefault = ((newSpw != null) && (newSpw.reduivy__Default__c));
        Id oldSplId = (oldSpw != null) ? oldSpw.reduivy__Study_Plan__c : null;
        Id newSplId = (newSpw != null) ? newSpw.reduivy__Study_Plan__c : null;

        Boolean planChange = ((oldSpw != null) && (oldSplId != newSplId));

        return (isDefault) && ((!wasDefault) || (planChange));
    }
	
}