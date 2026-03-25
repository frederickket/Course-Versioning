/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Individual Plan Structure: Create requirement records
 * @changehistory
 * ISS-001762 19-10-2023 dblack - new class
 * ISS-001255 30-12-2024 XW - consider fields for custom reqtype
 */
public inherited sharing class IPS_CreateRequirement_EXE extends REDU_TriggerExecutable {

	/**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult
    ) {

        if ((operationType == TriggerOperation.AFTER_INSERT) && 			 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            Id ipsUnitRecordTypeId = IPS_Helper.getUnitRecordTypeId();
            Map<Id, reduivy__Individual_Plan_Structure__c> ipsuMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
            Set<Id> spsIdSet = new Set<Id>(); // Study plan structure Ids
            Set<Id> sunIdSet = new Set<Id>(); // Study unit Ids

            for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>) newList) {

                // Get only the relevant individual plan structure (unit) records
                if ((String.isNotBlank(ips.reduivy__Individual_Program_Enrollment__c)) && 
                    (String.isNotBlank(ips.reduivy__Study_Plan_Structure__c)) && 
                    (ips.RecordTypeId == ipsUnitRecordTypeId)
                ) {
                    ipsuMap.put(ips.Id, ips);
                    spsIdSet.add(ips.reduivy__Study_Plan_Structure__c);
                    sunIdSet.add(ips.reduivy__Target_Unit_Id__c);
                }
            }
            if (!ipsuMap.isEmpty()) {

                // Study plan unit requirement map
                Map<Id, reduivy__Study_Plan_Structure__c> unitSpsMap = new Map<Id, reduivy__Study_Plan_Structure__c>();
                if (!spsIdSet.isEmpty()) {
                    for (reduivy__Study_Plan_Structure__c sps : [SELECT Id,
                        reduivy__Requirement_Logic__c,
                        (
                            SELECT  Id, 
                            Name, reduivy__Other__c, reduivy__Requirement_ID__c, reduivy__Requirement_Type__c,
                            reduivy__Required_Study_Unit__c, reduivy__Credits__c, reduivy__Study_Plan_Unit__c,
                            reduivy__Field_Name__c, reduivy__Field_Matching_Value__c, reduivy__Field_Matching_Operator__c //ISS-002155
                            FROM reduivy__Study_Plan_Unit_Requirements__r
                        )
                        FROM reduivy__Study_Plan_Structure__c
                        WHERE Id IN :spsIdSet
                        WITH USER_MODE
                    ]) {                    
                        for (reduivy__Study_Plan_Unit_Requirement__c spr : sps.reduivy__Study_Plan_Unit_Requirements__r) {
                            //loop through to get all records query returned
                        }

                        unitSpsMap.put(sps.Id, sps);
                    }
                }

                // Study unit requirement map
                Map<Id, List<reduivy__Study_Unit_Requirement__c>> surMap = new Map<Id, List<reduivy__Study_Unit_Requirement__c>>();
                if (!sunIdSet.isEmpty()) {
                    for (reduivy__Study_Unit_Requirement__c sur : [
                        SELECT  Id, Name, reduivy__Other__c, reduivy__Requirement_ID__c, reduivy__Requirement_Type__c,
                                reduivy__Required_Study_Unit__c, reduivy__Credits__c, reduivy__Study_Unit__c,
                                reduivy__Field_Name__c, reduivy__Field_Matching_Value__c, reduivy__Field_Matching_Operator__c //ISS-002155
                        FROM reduivy__Study_Unit_Requirement__c
                        WHERE reduivy__Study_Unit__c IN :sunIdSet
                        WITH USER_MODE
                    ]) {                    
                        if (!surMap.containsKey(sur.reduivy__Study_Unit__c)) {
                            surMap.put(sur.reduivy__Study_Unit__c, new List<reduivy__Study_Unit_Requirement__c>());
                        }
                        surMap.get(sur.reduivy__Study_Unit__c).add(sur);
                    }
                }

                // Create individual plan unit requirement records
				List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsuMap.values()) {
                    reduivy__Study_Plan_Structure__c sps = unitSpsMap.get(ipsu.reduivy__Study_Plan_Structure__c);

                    if (String.isNotBlank(sps.reduivy__Requirement_Logic__c)) {
                        //if the sps has requirment logic define, we will take the spur without considering sur
                        //this is the same in REDU_StudyUnitRequirement_UTIL
                        for (reduivy__Study_Plan_Unit_Requirement__c spr : sps.reduivy__Study_Plan_Unit_Requirements__r) {
                            reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c();
                            iur.Name = spr.Name;
                            iur.reduivy__Individual_Plan_Unit__c = ipsu.Id;						
                            iur.reduivy__Required_Study_Unit__c = spr.reduivy__Required_Study_Unit__c;							
                            iur.reduivy__Credits__c = spr.reduivy__Credits__c;
                            iur.reduivy__Other__c = spr.reduivy__Other__c;
                            iur.reduivy__Field_Name__c = spr.reduivy__Field_Name__c;                            //ISS-002155
                            iur.reduivy__Field_Matching_Value__c = spr.reduivy__Field_Matching_Value__c;        //ISS-002155
                            iur.reduivy__Field_Matching_Operator__c = spr.reduivy__Field_Matching_Operator__c;  //ISS-002155
                            iur.reduivy__Requirement_ID__c = spr.reduivy__Requirement_ID__c;
                            iur.reduivy__Requirement_Type__c = spr.reduivy__Requirement_Type__c;

                            iurList.add(iur);
                        }

                    } else if (surMap.containsKey(ipsu.reduivy__Target_Unit_Id__c)) {

                        for (reduivy__Study_Unit_Requirement__c sur : surMap.get(ipsu.reduivy__Target_Unit_Id__c)) {
                            reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c();
                            iur.Name = sur.Name;
                            iur.reduivy__Individual_Plan_Unit__c = ipsu.Id;						
                            iur.reduivy__Required_Study_Unit__c = sur.reduivy__Required_Study_Unit__c;							
                            iur.reduivy__Credits__c = sur.reduivy__Credits__c;
                            iur.reduivy__Other__c = sur.reduivy__Other__c;
                            iur.reduivy__Field_Name__c = sur.reduivy__Field_Name__c;                            //ISS-002155
                            iur.reduivy__Field_Matching_Value__c = sur.reduivy__Field_Matching_Value__c;        //ISS-002155
                            iur.reduivy__Field_Matching_Operator__c = sur.reduivy__Field_Matching_Operator__c;  //ISS-002155
                            iur.reduivy__Requirement_ID__c = sur.reduivy__Requirement_ID__c;
                            iur.reduivy__Requirement_Type__c = sur.reduivy__Requirement_Type__c;

                            iurList.add(iur);
                        }
                    }
                }

				if (!iurList.isEmpty()) {
                    REDU_Database_UTIL.doInsert(iurList, ipsuMap, 'reduivy__Individual_Plan_Unit__c', false);
				}
            }
		}
	}
}