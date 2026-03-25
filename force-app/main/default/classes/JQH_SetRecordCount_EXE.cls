/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Job Queue Framework
 * @description This is to set or update the number of record fields based on the record ids fields
 * @changehistory
 * ISS-002219 22-01-2025 Lean - new class
 */
public inherited sharing class JQH_SetRecordCount_EXE extends REDU_TriggerExecutable {
    
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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Job_Queue__c> workingList = new List<reduivy__Job_Queue__c>();
            for (reduivy__Job_Queue__c jqhNew : (List<reduivy__Job_Queue__c>) newList) {

                if (String.isNotBlank(jqhNew.reduivy__Job_Handler_Record_Ids__c) ||
                    String.isNotBlank(jqhNew.reduivy__Job_Handler_Error_Record_Ids__c) ||
                    String.isNotBlank(jqhNew.reduivy__Job_Handler_Warning_Record_Ids__c) ||
                    String.isNotBlank(jqhNew.reduivy__Job_Handler_Success_Record_Ids__c) 
                ) {
                    workingList.add(jqhNew);
                }
            }

            setRecordCountFields(workingList);
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

        //TODO change the permission
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            //TODO change the SObject
            List<reduivy__Job_Queue__c> workingList = new List<reduivy__Job_Queue__c>();
            for (reduivy__Job_Queue__c jqhNew : (List<reduivy__Job_Queue__c>) newList) {
                reduivy__Job_Queue__c jqhOld = (reduivy__Job_Queue__c) oldMap.get(jqhNew.Id);

                if (jqhNew.reduivy__Job_Handler_Record_Ids__c != jqhOld.reduivy__Job_Handler_Record_Ids__c ||
                    jqhNew.reduivy__Job_Handler_Error_Record_Ids__c != jqhOld.reduivy__Job_Handler_Error_Record_Ids__c ||
                    jqhNew.reduivy__Job_Handler_Warning_Record_Ids__c != jqhOld.reduivy__Job_Handler_Warning_Record_Ids__c || 
                    jqhNew.reduivy__Job_Handler_Success_Record_Ids__c != jqhOld.reduivy__Job_Handler_Success_Record_Ids__c
                ) {
                    workingList.add(jqhNew);
                }
            }

            setRecordCountFields(workingList);
        }
    }

    /**
     * @description Set the record count fields
     * @param jobQueueList
     * @return void
     */
    private void setRecordCountFields(List<reduivy__Job_Queue__c> jobQueueList) {
        
        for (reduivy__Job_Queue__c jqh : jobQueueList) {

            try {
                List<Id> recordIds = JQH_Helper.deserializeRecordIds(jqh.reduivy__Job_Handler_Record_Ids__c);
                List<Id> successRecordIds = JQH_Helper.deserializeRecordIds(jqh.reduivy__Job_Handler_Success_Record_Ids__c);
                List<Id> warningRecordIds = JQH_Helper.deserializeRecordIds(jqh.reduivy__Job_Handler_Warning_Record_Ids__c);
                List<Id> errorRecordIds = JQH_Helper.deserializeRecordIds(jqh.reduivy__Job_Handler_Error_Record_Ids__c);

                jqh.reduivy__Number_of_Records__c = recordIds.size();
                jqh.reduivy__Number_of_Success_Records__c = successRecordIds.size();
                jqh.reduivy__Number_of_Warning_Records__c = warningRecordIds.size();
                jqh.reduivy__Number_of_Error_Records__c = errorRecordIds.size();

            } catch (Exception exp) {
                jqh.addError(exp.getMessage());
            }
        }
    }
}