/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Individual plan structure (unit) requirement met processing
 * @changehistory
 * ISS-001762 20-10-2023 dblack - new class
 * ISS-001979 15-07-2024 Sueanne - remove pre-req enrolled/completed option
 */
public inherited sharing class IPS_RequirementMet_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual plan structure unit record type Id
     */
    static final Id IPSU_RECORDTYPE_ID = IPS_Helper.getUnitRecordTypeId();

    /**
     * @description Individual plan structure (unit) completed statuses
     */
    static final List<String> IPSU_STATUS_COMPLETED = IPS_Helper.getUnitCompletedStatuses();

    /**
     * @description Individual plan unit requirement types
     */
    static final String IUR_REQTYPE_PREREQ = IUR_Helper.REQTYPE_PREREQ;
    static final String IUR_REQTYPE_COREQ = IUR_Helper.REQTYPE_COREQ;
    
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

            for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>) newList) {

                if (ips.RecordTypeId == IPSU_RECORDTYPE_ID) {
                    ips.reduivy__Requirement_Met__c = true;
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

        if ((operationType == TriggerOperation.BEFORE_UPDATE) && 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            Map<Id, reduivy__Individual_Plan_Structure__c> ipsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();

            for (reduivy__Individual_Plan_Structure__c ipsNew : (List<reduivy__Individual_Plan_Structure__c>) newList) {                
                reduivy__Individual_Plan_Structure__c ipsOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsNew.Id);

                if ((ipsNew.reduivy__Requirement_Met__c != ipsOld.reduivy__Requirement_Met__c) && 
                    (ipsNew.RecordTypeId == IPSU_RECORDTYPE_ID)
                ) {

                    ipsMap.put(ipsNew.Id, ipsNew);
                }
            }

            if (!ipsMap.isEmpty()) {

                // Get the individual plan unit requirement records
                List<reduivy__Individual_Plan_Structure__c> ipsList = [
                    SELECT  Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Met__c,
                            (SELECT Id, reduivy__Requirement_Type__c, reduivy__Requirement_ID__c, reduivy__Requirement_Met__c,
                             reduivy__Individual_Plan_Unit__r.reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c
                             FROM reduivy__Individual_Plan_Unit_Requirements__r)
                    FROM reduivy__Individual_Plan_Structure__c
                    WHERE Id IN :ipsMap.keySet()
                    WITH USER_MODE
                ];

                // Evaluate the requirement met (Y) according to the requirements logic specified on the IPS
                // record [i.e. Y = f(A, B, C, D, etc)] with respect to each of the related IUR records (i.e. A, B, C, D, etc)
                for (reduivy__Individual_Plan_Structure__c ips : ipsList) {

                    ipsMap.get(ips.Id).reduivy__Requirement_Met__c = true;
                    
                    if ((String.isNotBlank(ips.reduivy__Requirement_Logic__c)) && 
                        (!ips.reduivy__Individual_Plan_Unit_Requirements__r.isEmpty())
                    ) {

                        REDU_ConditionLogic_OBJ clo = new REDU_ConditionLogic_OBJ(ips.reduivy__Requirement_Logic__c);
                        List<REDU_ConditionLogic_OBJ.Requirement> reqList = new List<REDU_ConditionLogic_OBJ.Requirement>();

                        for (reduivy__Individual_Plan_Unit_Requirement__c iur : ips.reduivy__Individual_Plan_Unit_Requirements__r) {

                            REDU_ConditionLogic_OBJ.Requirement req = new REDU_ConditionLogic_OBJ.Requirement(
                                iur.reduivy__Requirement_ID__c,
                                iur.reduivy__Requirement_Met__c
                            );

                            reqList.add(req);
                        }

                        if (!reqList.isEmpty()) {

                            ipsMap.get(ips.Id).reduivy__Requirement_Met__c = clo.valueOf(reqList);
                        }
                    }
                }
            }
        }
    }
}