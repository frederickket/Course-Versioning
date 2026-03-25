/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Trigger executable
 * @description Reset the individual plan structure (unit) status when the individual enrollment is unlinked
 * @changehistory
 * ISS-001831 19-12-2023 dblack - new class
 */
public inherited sharing class IPS_ResetStatus_EXE extends REDU_TriggerExecutable {

    /**
     * @description Record type Id for individual plan structure (unit)
     */
    static final Id UNIT_RECORD_TYPE_ID = IPS_Helper.getUnitRecordTypeId();

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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            String ipsUnitNotStartedStatus = IPS_Helper.getUnitNotStartedStatuses().get(0);

            for (reduivy__Individual_Plan_Structure__c ipsNew : (List<reduivy__Individual_Plan_Structure__c>) newList) {
                reduivy__Individual_Plan_Structure__c ipsOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsNew.Id);

                if ((ipsNew.RecordTypeId == UNIT_RECORD_TYPE_ID) && 
                    ((String.isBlank(ipsNew.reduivy__Individual_Enrollment__c)) && 
                    (String.isNotBlank(ipsOld.reduivy__Individual_Enrollment__c)))
                ) {

                    ipsNew.reduivy__Status__c = ipsUnitNotStartedStatus;
                }
            }
        }
    }
}