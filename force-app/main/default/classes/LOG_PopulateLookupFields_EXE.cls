/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Misc
 * @description Trigger to link the log to a parent record based on the record id
 * @changehistory
 * 
 */
public without sharing class LOG_PopulateLookupFields_EXE extends REDU_TriggerExecutable {
    
	/**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     * @return void
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        List<reduivy__Log__c> qualifiedLogs = new List<reduivy__Log__c>();
        for (reduivy__Log__c newLog : (List<reduivy__Log__c>) newList) {
            if (String.isNotBlank(newLog.reduivy__Record_Id__c)) {
                qualifiedLogs.add(newLog);
            }
        }

        linkParentRecords(qualifiedLogs);
    }

    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     * @return void
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        List<reduivy__Log__c> qualifiedLogs = new List<reduivy__Log__c>();

        for (reduivy__Log__c newLog : (List<reduivy__Log__c>) newList) {
            reduivy__Log__c oldLog = (reduivy__Log__c) oldMap.get(newLog.Id);
            if (String.isNotBlank(newLog.reduivy__Record_Id__c) && newLog.reduivy__Record_Id__c != oldLog.reduivy__Record_Id__c) {
                qualifiedLogs.add(newLog);
            }
        }

        linkParentRecords(qualifiedLogs);
    }

    /**
     * @description Link the log to parent records
     * @param logsToLink List of reduivy__Log__c
     * @return void
     */
    private void linkParentRecords(List<reduivy__Log__c> logsToLink) {

        if (logsToLink != null && !logsToLink.isEmpty()) {
            //Create map of object type to fieldname string
            Map<Schema.SObjectType, String> sobjTypeToFieldName = new Map<Schema.SObjectType, String>();
            Map<String, Schema.SObjectField> fieldMap = SObjectType.reduivy__Log__c.fields.getMap();

            for (String key : fieldMap.keySet()){
                Schema.DescribeFieldResult fieldResult = fieldMap.get(key).getDescribe();
                if (fieldResult.getType() == Schema.DisplayType.REFERENCE){
                    //Clone Source is a reference field with no reference to, need to avoid exception
                    if (!fieldResult.getReferenceTo().isEmpty()){
                        sobjTypeToFieldName.put(fieldResult.getReferenceTo()[0], fieldResult.getName());
                    }
                }
            }

            for (reduivy__Log__c log : logsToLink){
                //Need to wrap in a try because the id could be an invalid id
                try {
                    //For each record Id, find object type
                    Id targetRecordId = (Id) log.reduivy__Record_Id__c;

                    Schema.SObjectType targetObjectType = targetRecordId.getSobjectType();
                    if (sobjTypeToFieldName.containsKey(targetObjectType)){
                        //Populate lookup
                        log.put(sobjTypeToFieldName.get(targetObjectType), targetRecordId);
                    }
                    
                } catch (Exception ex){
                    //Won't touch error record
                    REDU_Logging_UTIL.debug(ex);
                }
            }
        }
    }
	
}