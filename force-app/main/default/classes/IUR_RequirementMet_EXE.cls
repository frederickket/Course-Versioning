/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Individual Plan Unit Requirement: Requirement met processing
 * @changehistory
 * ISS-001762 23-10-2023 dblack - new class
 * ISS-002155 26-12-2024 XW - added logic to support custom reqtype requirement
 */
public inherited sharing class IUR_RequirementMet_EXE extends REDU_TriggerExecutable {
    
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

        if ((operationType == TriggerOperation.BEFORE_INSERT) && 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = (List<reduivy__Individual_Plan_Unit_Requirement__c>) newList;
            IUR_Helper.isRequirementMet(iurList);
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

        if ((operationType == TriggerOperation.BEFORE_UPDATE) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
            for (reduivy__Individual_Plan_Unit_Requirement__c iurNew : (List<reduivy__Individual_Plan_Unit_Requirement__c>) newList) {
                reduivy__Individual_Plan_Unit_Requirement__c iurOld = (reduivy__Individual_Plan_Unit_Requirement__c) oldMap.get(iurNew.Id);
                
                if ((iurNew.reduivy__Requirement_Type__c != iurOld.reduivy__Requirement_Type__c) || 
                    (iurNew.reduivy__Credits__c != iurOld.reduivy__Credits__c) || 
                    (iurNew.reduivy__Other__c != iurOld.reduivy__Other__c) || 
                    (iurNew.reduivy__Requirement_Met__c != iurOld.reduivy__Requirement_Met__c) || 
                    (iurNew.reduivy__Required_Study_Unit__c != iurOld.reduivy__Required_Study_Unit__c) ||
                    (iurNew.reduivy__Field_Name__c != iurOld.reduivy__Field_Name__c) ||                         //ISS-002155
                    (iurNew.reduivy__Field_Matching_Value__c != iurOld.reduivy__Field_Matching_Value__c) ||     //ISS-002155
                    (iurNew.reduivy__Field_Matching_Operator__c != iurOld.reduivy__Field_Matching_Operator__c)  //ISS-002155
                ) {
                    iurList.add(iurNew);
                }
            }

            if (!iurList.isEmpty()) {

                IUR_Helper.isRequirementMet(iurList);
            }
        }
    }

    /**
     * @description Trigger the requirement met evaluation on IPS unit when an IUR requirement is created and the requirement met checkbox is not the same
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if ((operationType == TriggerOperation.AFTER_INSERT) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            Map<Id, List<SObject>> iurMapByIps = REDU_Map_UTIL.generateParentChilMap(newList, 'reduivy__Individual_Plan_Unit__c');

            if (!iurMapByIps.isEmpty()) {

                List<reduivy__Individual_Plan_Structure__c> ipsList = [
                    SELECT Id, reduivy__Requirement_Met__c
                    FROM reduivy__Individual_Plan_Structure__c
                    WHERE Id IN :iurMapByIps.keySet() 
                    WITH USER_MODE
                ];

                // Toggle to invoke re-evaluation of the individual plan unit requirement logic
                for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                    ips.reduivy__Requirement_Met__c = !ips.reduivy__Requirement_Met__c;
                }

                REDU_Database_UTIL.doUpdate(ipsList, iurMapByIps, 'Id', false);
            }
        }
    }

    /**
     * @description Retrigger the requirement met evaluation on IPS unit when an IUR requirement met is changed
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if ((operationType == TriggerOperation.AFTER_UPDATE) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            List<reduivy__Individual_Plan_Unit_Requirement__c> qualifiedList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();

            //we should only update the parent if the requirement met checkbox is changed
            for (reduivy__Individual_Plan_Unit_Requirement__c iurNew : (List<reduivy__Individual_Plan_Unit_Requirement__c>) newList) {
                reduivy__Individual_Plan_Unit_Requirement__c iurOld = (reduivy__Individual_Plan_Unit_Requirement__c) oldMap.get(iurNew.Id);

                if (iurNew.reduivy__Requirement_Met__c != iurOld.reduivy__Requirement_Met__c) {
                    qualifiedList.add(iurNew);
                }
            }

            Map<Id, List<SObject>> iurMapByIps = REDU_Map_UTIL.generateParentChilMap(qualifiedList, 'reduivy__Individual_Plan_Unit__c');

            if (!iurMapByIps.isEmpty()) {

                List<reduivy__Individual_Plan_Structure__c> ipsList = [
                    SELECT Id, reduivy__Requirement_Met__c
                    FROM reduivy__Individual_Plan_Structure__c
                    WHERE Id IN :iurMapByIps.keySet() 
                    WITH USER_MODE
                ];

                // Toggle to invoke re-evaluation of the individual plan unit requirement logic
                for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                    ips.reduivy__Requirement_Met__c = !ips.reduivy__Requirement_Met__c;
                }

                REDU_Database_UTIL.doUpdate(ipsList, iurMapByIps, 'Id', false);
            }
        }
    }

    /**
     * @description Retrigger the requirement met evaluation on IPS unit when a requirement is deleted
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if ((operationType == TriggerOperation.AFTER_DELETE) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            Map<Id, List<SObject>> iurMapByIps = REDU_Map_UTIL.generateParentChilMap(oldList, 'reduivy__Individual_Plan_Unit__c');

            if (!iurMapByIps.isEmpty()) {

                List<reduivy__Individual_Plan_Structure__c> ipsList = [
                    SELECT Id, reduivy__Requirement_Met__c
                    FROM reduivy__Individual_Plan_Structure__c
                    WHERE Id IN :iurMapByIps.keySet() 
                    WITH USER_MODE
                ];

                // Toggle to invoke re-evaluation of the individual plan unit requirement logic
                for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                    ips.reduivy__Requirement_Met__c = !ips.reduivy__Requirement_Met__c;
                }

                REDU_Database_UTIL.doUpdate(ipsList, iurMapByIps, 'Id', false);
            }
        }
    }	
}