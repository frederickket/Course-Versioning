/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Enrollment Deletion: deletes individual program enrollment record and its child records
 * @changehistory
 * ISS-001770 17-10-2023 dblack - new class
 * ISS-002487 22-07-2025 XiRouh - Updated to also delete the associated child IPE and their IPS if the deleted IPE is a master IPE
 */
public without sharing class IPE_DeleteEnrollment_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual Program Enrollment Child Record Type Id
     */
    private static final Id IPE_CHILD_RECORD_TYPE_ID = IPE_Helper.getChildEnrollmentRecordTypeId();

    /**
     * @description Individual Program Enrollment Master Record Type Id
     */
    private static final Id IPE_MASTER_RECORD_TYPE_ID = IPE_Helper.getMasterEnrollmentRecordTypeId();

    /**
     * @description BeforeDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult
    ) {
        if (operationType == TriggerOperation.BEFORE_DELETE) {
            Set<Id> masterIpeToBeDeleted = new Set<Id>();
            List<reduivy__Individual_Program_Enrollment__c> childIpeToBeDeleted = new List<reduivy__Individual_Program_Enrollment__c>();

            Map<Id, reduivy__Individual_Program_Enrollment__c> ipeOldMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>((List<reduivy__Individual_Program_Enrollment__c>) oldList);

            Set<Id> ipeIds = new Set<Id>();

            //ISS-002487
            for(reduivy__Individual_Program_Enrollment__c ipe : ipeOldMap.values()) {
                if(ipe.RecordTypeId == IPE_MASTER_RECORD_TYPE_ID) {
                    masterIpeToBeDeleted.add(ipe.Id);
                } 

                ipeIds.add(ipe.Id);
            }

            if(!masterIpeToBeDeleted.isEmpty()) {
                for(reduivy__Individual_Program_Enrollment__c ipe : 
                    [SELECT Id, reduivy__Master_Enrollment__c
                    FROM reduivy__Individual_Program_Enrollment__c 
                    WHERE reduivy__Master_Enrollment__c IN :masterIpeToBeDeleted
                    WITH USER_MODE]
                ) {
                    if(!ipeIds.contains(ipe.Id)) {
                        childIpeToBeDeleted.add(ipe);
                        ipeIds.add(ipe.Id);
                    }
                }    
            }

            List<reduivy__Individual_Plan_Structure__c> ipsToBeDeleted = new List<reduivy__Individual_Plan_Structure__c>();

            if(!ipeIds.isEmpty()) {
                Set<String> ipsFields = new Set<String>{
                    'Id',
                    'reduivy__Individual_Program_Enrollment__c'
                };

                String ipsSoql = 'SELECT ' + String.join(ipsFields, ', ') + 
                    ' FROM reduivy__Individual_Plan_Structure__c ' +
                    ' WHERE reduivy__Individual_Program_Enrollment__c IN: ipeIds ';
                
                Map<String, Object> ipsBindParams = new Map<String, Object>();
                ipsBindParams.put('ipeIds', ipeIds);

                Map<String, Set<String>> ipsObjectFieldsFls = new Map<String, Set<String>>();
                ipsObjectFieldsFls.put(IPS_Helper.getApiName(), ipsFields);

                for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>) REDU_SystemMode_UTIL.doQuery(ipsSoql, ipsBindParams, ipsObjectFieldsFls)) {
                    ipsToBeDeleted.add(ips);
                }
            }

            if (!ipsToBeDeleted.isEmpty()) {
                //Delete records regardless of ownership using system mode
                REDU_SystemMode_UTIL.doDelete(ipsToBeDeleted, ipeOldMap, 'reduivy__Individual_Program_Enrollment__c', false);
            }

            //ISS-002487
            if (!childIpeToBeDeleted.isEmpty()) {
                //Delete records regardless of ownership using system mode
                REDU_TriggerController.muteTriggers(new Set<String>{'IPE_DeleteEnrollment_EXE'});
                REDU_SystemMode_UTIL.doDelete(childIpeToBeDeleted, ipeOldMap, 'reduivy__Master_Enrollment__c', false);
                REDU_TriggerController.unmuteTriggers(new Set<String>{'IPE_DeleteEnrollment_EXE'});
            }
        }
    }	
}