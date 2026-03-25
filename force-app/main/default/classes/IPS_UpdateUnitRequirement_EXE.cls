/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description This is to update Individual Unit Requirement when an Individual plan structure (unit) status is changed
 * @changehistory
 * ISS-001762 20-10-2023 dblack - new class
 * ISS-001927 29-03-2024 VTan - Enhance logic to consider requirement met for child IPE
 * ISS-001979 15-07-2024 Sueanne - remove pre-req enrolled/completed option
 * ISS-001255 30-12-2024 XW - consider fields for custom reqtype
 * ISS-002366 10-04-2025 XiRouh - Updated to consider for the change in status category
 * ISS-002379 05-05-2025 XiRouh - Updated the way to constructing the object map and source object map used to update the IUR
 */
public inherited sharing class IPS_UpdateUnitRequirement_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description Individual plan structure unit record type Id
     */
    static final Id IPSU_RECORDTYPE_ID = IPS_Helper.getUnitRecordTypeId();

    /**
     * @description Individual plan structure (unit) completed statuses
     */
    static final List<String> IPSU_STATUS_COMPLETED = IPS_Helper.getUnitCompletedStatuses();

    /**
     * @description Individual plan structure (unit) in progress statuses
     */
    static final List<String> IPSU_STATUS_INPROGRESS = IPS_Helper.getUnitInProgressStatuses();
    
    /**
     * @description Individual plan unit requirement types
     */
    static final String IUR_REQTYPE_PREREQ = IUR_Helper.REQTYPE_PREREQ;
    static final String IUR_REQTYPE_COREQ = IUR_Helper.REQTYPE_COREQ;

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

        if ((operationType == TriggerOperation.AFTER_INSERT) && 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {
            Map<Id, reduivy__Individual_Plan_Structure__c> qualifiedIpsu = new Map<Id, reduivy__Individual_Plan_Structure__c>();

            for (reduivy__Individual_Plan_Structure__c ipsNew : (List<reduivy__Individual_Plan_Structure__c>) newList) {

                if (ipsNew.RecordTypeId == IPSU_RECORDTYPE_ID &&
                    String.isNotBlank(ipsNew.reduivy__Status__c) && 
                    (IPSU_STATUS_INPROGRESS.contains(ipsNew.reduivy__Status__c) || IPSU_STATUS_COMPLETED.contains(ipsNew.reduivy__Status__c))
                ) {
                    qualifiedIpsu.put(ipsNew.Id, ipsNew);
                }
            }

            if(!qualifiedIpsu.isEmpty()) {
                updateRelatedUnitRequirements(qualifiedIpsu);
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

        if ((operationType == TriggerOperation.AFTER_UPDATE) && 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            Map<Id, reduivy__Individual_Plan_Structure__c> qualifiedIpsu = new Map<Id, reduivy__Individual_Plan_Structure__c>();

            for (reduivy__Individual_Plan_Structure__c ipsNew : (List<reduivy__Individual_Plan_Structure__c>) newList) {
                reduivy__Individual_Plan_Structure__c ipsOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsNew.Id);

                if ((ipsNew.reduivy__Status__c != ipsOld.reduivy__Status__c) && 
                    (ipsNew.RecordTypeId == IPSU_RECORDTYPE_ID) && 
                    (((IPSU_STATUS_INPROGRESS.contains(ipsNew.reduivy__Status__c) && !IPSU_STATUS_INPROGRESS.contains(ipsOld.reduivy__Status__c))) 
                        || (IPSU_STATUS_INPROGRESS.contains(ipsOld.reduivy__Status__c) && !IPSU_STATUS_INPROGRESS.contains(ipsNew.reduivy__Status__c)) ||
                    ((IPSU_STATUS_COMPLETED.contains(ipsNew.reduivy__Status__c)) && !IPSU_STATUS_COMPLETED.contains(ipsOld.reduivy__Status__c)) 
                        || (IPSU_STATUS_COMPLETED.contains(ipsOld.reduivy__Status__c) && !IPSU_STATUS_COMPLETED.contains(ipsNew.reduivy__Status__c)))
                ) {
                    qualifiedIpsu.put(ipsNew.Id, ipsNew);
                }
            }

            if(!qualifiedIpsu.isEmpty()) {
                updateRelatedUnitRequirements(qualifiedIpsu);
            }            
        }
    }

    /**
     * @description Find the related individual plan unit requirement and reevaluate the "requirement met" when the status of individual plan structure is changed
     * @param ipsuMap Map of individual plan structure
     * @return void
     */
    private void updateRelatedUnitRequirements(Map<Id, reduivy__Individual_Plan_Structure__c> ipsuMap) {

        if (!ipsuMap.isEmpty()) {

            Set<Id> ipeIds = new Set<Id>();
            Set<Id> sunIds = new Set<Id>();

            Map<String, List<reduivy__Individual_Plan_Structure__c>> sourceObjMap = new Map<String, List<reduivy__Individual_Plan_Structure__c>>();

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsuMap.values()) {
                if (String.isNotBlank(ipsu.reduivy__Individual_Program_Enrollment__c) && String.isNotBlank(ipsu.reduivy__Target_Unit_Id__c)) {
                    ipeIds.add(ipsu.reduivy__Master_Individual_Program_Enrollment_Id__c);
                    sunIds.add(ipsu.reduivy__Target_Unit_Id__c);

                    if (sourceObjMap.containsKey(ipsu.reduivy__Master_Individual_Program_Enrollment_Id__c + '_' + ipsu.reduivy__Target_Unit_Id__c)) {
                        sourceObjMap.get(ipsu.reduivy__Master_Individual_Program_Enrollment_Id__c + '_' + ipsu.reduivy__Target_Unit_Id__c).add(ipsu);
                    } else {
                        sourceObjMap.put(ipsu.reduivy__Master_Individual_Program_Enrollment_Id__c + '_' + ipsu.reduivy__Target_Unit_Id__c, new List<reduivy__Individual_Plan_Structure__c>{ipsu});
                    }
                }
            }
            
            List<reduivy__Individual_Plan_Unit_Requirement__c> iurList = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
            for (reduivy__Individual_Plan_Unit_Requirement__c iur : [
                SELECT Id, 
                reduivy__Individual_Plan_Unit__c, 
                reduivy__Requirement_Type__c, 
                reduivy__Requirement_Met__c,
                reduivy__Required_Study_Unit__c,
                reduivy__Credits__c,
                reduivy__Other__c,
                reduivy__Master_Individual_Program_Enrollment_Id__c,
                reduivy__Field_Name__c,             //ISS-002155
                reduivy__Field_Matching_Value__c,   //ISS-002155
                reduivy__Field_Matching_Operator__c //ISS-002155
                FROM reduivy__Individual_Plan_Unit_Requirement__c
                WHERE reduivy__Master_Individual_Program_Enrollment_Id__c IN :ipeIds
                AND reduivy__Required_Study_Unit__c IN: sunIds
                WITH USER_MODE
            ]) {
                iurList.add(iur);
            }

            if (!iurList.isEmpty()) {

                Map<Id, reduivy__Individual_Plan_Unit_Requirement__c> oriIurMap = new Map<Id, reduivy__Individual_Plan_Unit_Requirement__c>(iurList.deepClone(true, true, true));
                Map<String, List<reduivy__Individual_Plan_Unit_Requirement__c>> objectMap = new Map<String, List<reduivy__Individual_Plan_Unit_Requirement__c>>();

                // evaluate the iur list
                IUR_Helper.isRequirementMet(iurList);

                // look for the iur that has requirement met changed that we need to update, to reduce unnecessary dml
                for (reduivy__Individual_Plan_Unit_Requirement__c evaluatedIur : iurList) {
                    if (oriIurMap.get(evaluatedIur.Id).reduivy__Requirement_Met__c != evaluatedIur.reduivy__Requirement_Met__c) {
                        
                        reduivy__Individual_Plan_Unit_Requirement__c iur = new reduivy__Individual_Plan_Unit_Requirement__c(
                            Id = evaluatedIur.Id,
                            reduivy__Requirement_Met__c = evaluatedIur.reduivy__Requirement_Met__c,
                            reduivy__Required_Study_Unit__c = evaluatedIur.reduivy__Required_Study_Unit__c,
                            reduivy__Credits__c = evaluatedIur.reduivy__Credits__c,
                            reduivy__Other__c = evaluatedIur.reduivy__Other__c,
                            reduivy__Field_Name__c = evaluatedIur.reduivy__Field_Name__c,                            //ISS-002155
                            reduivy__Field_Matching_Value__c = evaluatedIur.reduivy__Field_Matching_Value__c,        //ISS-002155
                            reduivy__Field_Matching_Operator__c = evaluatedIur.reduivy__Field_Matching_Operator__c   //ISS-002155
                        );

                        if (objectMap.containsKey(evaluatedIur.reduivy__Master_Individual_Program_Enrollment_Id__c + '_' + evaluatedIur.reduivy__Required_Study_Unit__c)) {
                            objectMap.get(evaluatedIur.reduivy__Master_Individual_Program_Enrollment_Id__c + '_' + evaluatedIur.reduivy__Required_Study_Unit__c).add(iur);
                        } else {
                            objectMap.put(evaluatedIur.reduivy__Master_Individual_Program_Enrollment_Id__c + '_' + evaluatedIur.reduivy__Required_Study_Unit__c, new List<reduivy__Individual_Plan_Unit_Requirement__c>{iur});
                        }
                    }
                }

                REDU_Database_UTIL.doUpdate(objectMap, sourceObjMap, false);
            }
        }
    }
}