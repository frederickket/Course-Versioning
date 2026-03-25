/**
 * @author      WDCi (VTan)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description This is to create individual enrollment or individual plan structure (unit) upon credit transfer application approval.
 * @changehistory
 * ISS-001659 VTan 30-01-2024 - New class
 * ISS-002136 16-10-2024 Lean - Fixed the credits contribution for IPS unit created via credit transfer application (type = manual)
 * ISS-002513 10-02-2026 XiRouh - Added assignment to the Credit Transfer Type field for the new IEN
 */
public inherited sharing class CTA_ApprovalManager_EXE extends REDU_TriggerExecutable {
    
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

        if (operationType == TriggerOperation.AFTER_INSERT && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<String> approvedStatuses = CTA_Helper.getApprovedStatuses();
            Map<Id, reduivy__Credit_Transfer_Application__c> createIpsUnitMap = new Map<Id, reduivy__Credit_Transfer_Application__c>();
            Map<Id, reduivy__Credit_Transfer_Application__c> createIenMap = new Map<Id, reduivy__Credit_Transfer_Application__c>();

            for (reduivy__Credit_Transfer_Application__c ctaNew : (List<reduivy__Credit_Transfer_Application__c>) newList) {

                if(approvedStatuses.contains(ctaNew.reduivy__Status__c) && ctaNew.reduivy__Individual_Plan_Structure__c != null) {
                    createIpsUnitMap.put(ctaNew.Id, ctaNew);
                }else if(approvedStatuses.contains(ctaNew.reduivy__Status__c) && String.isNotBlank(ctaNew.reduivy__Approved_Unit_Codes__c)){
                    createIenMap.put(ctaNew.Id, ctaNew);
                }
            }

            // Process creation of individual plan structure (unit)
            if(!createIpsUnitMap.isEmpty()){
                createIpsUnit(createIpsUnitMap);
            }

            // Process creation of individual enrollment
            if(!createIenMap.isEmpty()){
                createIen(createIenMap);
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
        
        if(operationType == TriggerOperation.AFTER_UPDATE && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<String> approvedStatuses = CTA_Helper.getApprovedStatuses();
            Map<Id, reduivy__Credit_Transfer_Application__c> createIpsUnitMap = new Map<Id, reduivy__Credit_Transfer_Application__c>();
            Map<Id, reduivy__Credit_Transfer_Application__c> createIenMap = new Map<Id, reduivy__Credit_Transfer_Application__c>();

            for (reduivy__Credit_Transfer_Application__c ctaNew : (List<reduivy__Credit_Transfer_Application__c>) newList) {

                reduivy__Credit_Transfer_Application__c ctaOld = (reduivy__Credit_Transfer_Application__c) oldMap.get(ctaNew.Id);

                if(approvedStatuses.contains(ctaNew.reduivy__Status__c) && !approvedStatuses.contains(ctaOld.reduivy__Status__c) && ctaNew.reduivy__Individual_Plan_Structure__c != null) {
                    createIpsUnitMap.put(ctaNew.Id, ctaNew);
                }else if(approvedStatuses.contains(ctaNew.reduivy__Status__c) && !approvedStatuses.contains(ctaOld.reduivy__Status__c) && String.isNotBlank(ctaNew.reduivy__Approved_Unit_Codes__c)){
                    createIenMap.put(ctaNew.Id, ctaNew);
                }
            }

            // Process creation of individual plan structure (unit)
            if(!createIpsUnitMap.isEmpty()){
                createIpsUnit(createIpsUnitMap);
            }

            // Process creation of individual enrollment
            if(!createIenMap.isEmpty()){
                createIen(createIenMap);
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

        if(operationType == TriggerOperation.BEFORE_UPDATE && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<String> approvedStatuses = CTA_Helper.getApprovedStatuses();
            Map<Id, reduivy__Credit_Transfer_Application__c> deleteIpsUnitIenMap = new Map<Id, reduivy__Credit_Transfer_Application__c>();

            for (reduivy__Credit_Transfer_Application__c ctaNew : (List<reduivy__Credit_Transfer_Application__c>) newList) {

                reduivy__Credit_Transfer_Application__c ctaOld = (reduivy__Credit_Transfer_Application__c) oldMap.get(ctaNew.Id);

                if(!approvedStatuses.contains(ctaNew.reduivy__Status__c) && approvedStatuses.contains(ctaOld.reduivy__Status__c)){
                    deleteIpsUnitIenMap.put(ctaNew.Id, ctaNew);
                }
            }

            if(!deleteIpsUnitIenMap.isEmpty()){
                ctaDisapproval(deleteIpsUnitIenMap);
            }
        }
    }

    /**
     * @description BeforeDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if(operationType == TriggerOperation.BEFORE_DELETE && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<String> approvedStatuses = CTA_Helper.getApprovedStatuses();
            Map<Id, reduivy__Credit_Transfer_Application__c> deleteIpsUnitIenMap = new Map<Id, reduivy__Credit_Transfer_Application__c>();

            for (reduivy__Credit_Transfer_Application__c ctaOld : (List<reduivy__Credit_Transfer_Application__c>) oldList) {

                if(approvedStatuses.contains(ctaOld.reduivy__Status__c)){
                    deleteIpsUnitIenMap.put(ctaOld.Id, ctaOld);
                }
            }

            if(!deleteIpsUnitIenMap.isEmpty()){
                ctaDisapproval(deleteIpsUnitIenMap);
            }
        }
    }

    /**
     * @description AfterUndelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUndelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (operationType == TriggerOperation.AFTER_UNDELETE && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {
            
            List<String> approvedStatuses = CTA_Helper.getApprovedStatuses();
            Map<Id, reduivy__Credit_Transfer_Application__c> createIpsUnitMap = new Map<Id, reduivy__Credit_Transfer_Application__c>();
            Map<Id, reduivy__Credit_Transfer_Application__c> createIenMap = new Map<Id, reduivy__Credit_Transfer_Application__c>();

            for (reduivy__Credit_Transfer_Application__c ctaNew : (List<reduivy__Credit_Transfer_Application__c>) newList) {

                if(approvedStatuses.contains(ctaNew.reduivy__Status__c) && ctaNew.reduivy__Individual_Plan_Structure__c != null) {
                    createIpsUnitMap.put(ctaNew.Id, ctaNew);
                }else if(approvedStatuses.contains(ctaNew.reduivy__Status__c) && String.isNotBlank(ctaNew.reduivy__Approved_Unit_Codes__c)){
                    createIenMap.put(ctaNew.Id, ctaNew);
                }
            }

            // Process creation of individual plan structure (unit)
            if(!createIpsUnitMap.isEmpty()){
                createIpsUnit(createIpsUnitMap);
            }

            // Process creation of individual enrollment
            if(!createIenMap.isEmpty()){
                createIen(createIenMap);
            }
        }
    }

    /**
     * @description create related individual plan structure (unit) when the credit transfer application is approved
     * @param ctaMap Map of credit transfer application
     * @return void
     */
    private void createIpsUnit(Map<Id, reduivy__Credit_Transfer_Application__c> ctaMap) {

        Id ipsUnitRecordTypeId = IPS_Helper.getUnitRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> newIpsUnitList = new List<reduivy__Individual_Plan_Structure__c>();

        String ipsGroupCompletedStatus = IPS_Helper.getGroupCompletedStatuses().get(0);

        for (reduivy__Credit_Transfer_Application__c cta : ctaMap.values()) {

            reduivy__Individual_Plan_Structure__c ipsUnit = new reduivy__Individual_Plan_Structure__c();
            ipsUnit.RecordTypeId = ipsUnitRecordTypeId;
            ipsUnit.reduivy__Individual_Program_Enrollment__c = cta.reduivy__Individual_Program_Enrollment__c;
            ipsUnit.reduivy__Credit_Transfer_Application__c = cta.Id;
            ipsUnit.reduivy__Credits__c = cta.reduivy__Credits_Attempted__c;
            ipsUnit.reduivy__Credits_Earned__c = cta.reduivy__Credits_Earned__c;
            ipsUnit.reduivy__Parent_Plan_Structure__c = cta.reduivy__Individual_Plan_Structure__c;
            ipsUnit.reduivy__Status__c = ipsGroupCompletedStatus;

            //This is required to ensure that the manual assignment IPS unit always contribute to the group
            ipsUnit.reduivy__Primary__c = true;
            ipsUnit.reduivy__Credits_Contribution__c = IPS_Helper.CREDITS_CONTRIBUTION_YES;

            newIpsUnitList.add(ipsUnit);
        }

        if (!newIpsUnitList.isEmpty()) {
            REDU_Database_UTIL.doInsert(newIpsUnitList, ctaMap, 'reduivy__Credit_Transfer_Application__c', false);
        }
    }

    /**
     * @description create related individual enrollment when the credit transfer application is approved
     * @param ctaMap Map of credit transfer application
     * @return void
     */
    private void createIen(Map<Id, reduivy__Credit_Transfer_Application__c> ctaMap) {

        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
        Set<String> studyUnitCodes = new Set<String>();
        Id IEN_STUDENT_RECORDTYPE_ID = IEN_Helper.getStudentRecordTypeId();
        String ienReleased = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

        // Preparation to get the related study unit records based on approved unit codes
        for (reduivy__Credit_Transfer_Application__c cta : ctaMap.values()) {
            studyUnitCodes.addAll(cta.reduivy__Approved_Unit_Codes__c.split(';'));
        }

        if (!studyUnitCodes.isEmpty()) {
            
            Map<String, reduivy__Study_Unit__c> studyUnitMap = new Map<String, reduivy__Study_Unit__c>();
            for (reduivy__Study_Unit__c su : [SELECT  Id, Name, reduivy__Unit_Code__c
                FROM reduivy__Study_Unit__c
                WHERE reduivy__Unit_Code__c IN :studyUnitCodes
                WITH USER_MODE]
            ){    
                studyUnitMap.put(su.reduivy__Unit_Code__c, su);
            }
            
            for (reduivy__Credit_Transfer_Application__c cta : ctaMap.values()) {
                for(String unitCode : cta.reduivy__Approved_Unit_Codes__c.split(';')){
                    if(studyUnitMap.containsKey(unitCode)){
                        
                        reduivy__Individual_Enrollment__c ien = new reduivy__Individual_Enrollment__c();
                        ien.RecordTypeId = IEN_STUDENT_RECORDTYPE_ID;
                        ien.reduivy__Contact__c = cta.reduivy__Contact__c;
                        ien.reduivy__Credit_Transfer_Application__c = cta.Id;
                        ien.reduivy__Credits_Offered__c = cta.reduivy__Credits_Attempted__c;
                        ien.reduivy__Letter_Grade__c = cta.reduivy__Approved_Letter_Grade__c;
                        ien.reduivy__Study_Unit__c = studyUnitMap.get(unitCode).Id;
                        ien.reduivy__Credit_Transfer_Received__c = true;
                        ien.reduivy__Grade_Release_Status__c = ienReleased;
                        ien.reduivy__Credit_Transfer_Type__c = IEN_Helper.CREDIT_TRANSFER_TYPE_CREDIT_TRANSFER_APPLICATION;
                        
                        newIenList.add(ien);
                    }
                }
            }
            
            if (!newIenList.isEmpty()) {
                REDU_Database_UTIL.doInsert(newIenList, ctaMap, 'reduivy__Credit_Transfer_Application__c', false);
            }
        }
    }

    /**
     * @description Delete related individual enrollment and individual plan structure when the credit transfer application is disapproved
     * @param ctaMap Map of credit transfer application
     * @return void
     */
    private void ctaDisapproval(Map<Id, reduivy__Credit_Transfer_Application__c> ctaMap) {

        List<reduivy__Individual_Plan_Structure__c> deleteIpsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
        for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Credit_Transfer_Application__c IN :ctaMap.keySet() 
            WITH USER_MODE
        ]){
                                                    
            deleteIpsUnitList.add(ipsUnit);
        }

        List<reduivy__Individual_Enrollment__c> deleteIenList = new List<reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c ien : [SELECT Id 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Credit_Transfer_Application__c IN :ctaMap.keySet()
            WITH USER_MODE
        ]){
                                                    
            deleteIenList.add(ien);
        }

        if(!deleteIpsUnitList.isEmpty()){
            //Delete records regardless of ownership using system mode
            REDU_SystemMode_UTIL.doDelete(deleteIpsUnitList, ctaMap, 'reduivy__Credit_Transfer_Application__c', false);
        }

        if(!deleteIenList.isEmpty()){
            //Delete records regardless of ownership using system mode
            REDU_SystemMode_UTIL.doDelete(deleteIenList, ctaMap, 'reduivy__Credit_Transfer_Application__c', false);
        }
    }
}