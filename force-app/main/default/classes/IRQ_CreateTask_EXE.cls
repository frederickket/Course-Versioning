/**
 * @author      WDCi (XW)
 * @date        June 2024
 * @group       Requirement
 * @description Create Salesforce Task when an Individual Requirement with Create Salesforce Task = true is inserted or is updated to true
 * @changehistory
 * ISS-002128 11-06-2025 XW - new class
 */

public inherited sharing class IRQ_CreateTask_EXE extends REDU_TriggerExecutable {
    
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Requirement__c> workingList = new List<reduivy__Individual_Requirement__c>();
            for (reduivy__Individual_Requirement__c objNew : (List<reduivy__Individual_Requirement__c>) newList) {
                if(objNew.reduivy__Create_Salesforce_Task__c && objNew.reduivy__Status__c == IRQ_Helper.STATUS_ACTIVE) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                createTask(workingList);
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Requirement__c> workingList = new List<reduivy__Individual_Requirement__c>();
            for (reduivy__Individual_Requirement__c objNew : (List<reduivy__Individual_Requirement__c>) newList) {
                reduivy__Individual_Requirement__c objOld = (reduivy__Individual_Requirement__c) oldMap.get(objNew.Id);
                if (
                    objNew.reduivy__Create_Salesforce_Task__c &&
                    objNew.reduivy__Create_Salesforce_Task__c != objOld.reduivy__Create_Salesforce_Task__c &&
                    objNew.reduivy__Status__c == IRQ_Helper.STATUS_ACTIVE
                ) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                createTask(workingList);
            }
        }
    }
    
    /**
     * @description create salesforce task
     * @param  irqList the qualified individual requirement list 
     */
    private void createTask(List<reduivy__Individual_Requirement__c> irqList) {


        Set<String> irqFields = new Set<String> {
            'Id', 
            'reduivy__Individual_Requirement_Set__c',
            'reduivy__Individual_Requirement_Set__r.reduivy__Study_Requirement_Set__r.reduivy__Object__c'
        };

        Set<String> irsFields = REDU_Metadata_UTIL.getLookupFieldsFromObject(IRS_Helper.getApiName());
        for(String irsField : irsFields) {
            irqFields.add('reduivy__Individual_Requirement_Set__r.' + irsField);
        }

        String irqQuery = 'SELECT ' + String.join(irqFields, ', ') + 
                        ' FROM reduivy__Individual_Requirement__c' + 
                        ' WHERE Id IN :irqList';
        Map<String, Object> bindMap = new Map<String, Object> {
            'irqList' => irqList
        };

        //we need to get the related data id of the irq, so we need to query its srs's object lookup field
        Map<Id, reduivy__Individual_Requirement__c> irqWithParentRecordsMap = new Map<Id, reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement__c irs : (List<reduivy__Individual_Requirement__c>) Database.queryWithBinds(irqQuery, bindMap, AccessLevel.USER_MODE)) {
            irqWithParentRecordsMap.put(irs.Id, irs);
        }
        
        //create task based on the irq
        List<Task> tasksToBeInserted = new List<Task>();
        String relatedFieldName = '';
        for(reduivy__Individual_Requirement__c irq : irqList) {
            Task newTask = new Task();
            newTask.OwnerId = irq.OwnerId;
            newTask.Description = irq.reduivy__Requirement_Details__c;
            newTask.ActivityDate = irq.reduivy__Due_Date__c;
            newTask.Subject = irq.Name;

            if(String.isNotBlank(irq.reduivy__Priority__c)){
                newTask.Priority = irq.reduivy__Priority__c;
            }

            //get the related data id
            reduivy__Individual_Requirement__c irqWithParentRecord = irqWithParentRecordsMap.get(irq.Id);
            String objectApiName = irqWithParentRecord.reduivy__Individual_Requirement_Set__r?.reduivy__Study_Requirement_Set__r?.reduivy__Object__c;
            if(String.isBlank(objectApiName)) {
                return;
            }
            String objectRelationField = REDU_Metadata_UTIL.getObjectLookupField(IRS_Helper.getApiName(), objectApiName);
            if(irqWithParentRecord.reduivy__Individual_Requirement_Set__r.get(objectRelationField) != null) {
                Id relatedDataId = (Id) irqWithParentRecord.reduivy__Individual_Requirement_Set__r.get(objectRelationField);
                if(
                    relatedDataId.getSObjectType() == Lead.getSObjectType() ||
                    relatedDataId.getSObjectType() == Contact.getSObjectType()
                ) {
                    newTask.WhoId = relatedDataId;
                    relatedFieldName = 'WhoId';
                } else {
                    newTask.WhatId = relatedDataId;
                    relatedFieldName = 'WhatId';
                }
                if(String.isBlank(newTask.WhoId) && irqWithParentRecord.reduivy__Individual_Requirement_Set__r.reduivy__Contact__c != null) {
                    newTask.WhoId = irqWithParentRecord.reduivy__Individual_Requirement_Set__r.reduivy__Contact__c;
                }
            }

            tasksToBeInserted.add(newTask);
            
        }

        if(!tasksToBeInserted.isEmpty()) {
            Map<Id, reduivy__Individual_Requirement__c> irqMap = new Map<Id, reduivy__Individual_Requirement__c>(irqList);
            REDU_Database_UTIL.doInsert(tasksToBeInserted, irqMap, relatedFieldName, false);
        }
    }
}