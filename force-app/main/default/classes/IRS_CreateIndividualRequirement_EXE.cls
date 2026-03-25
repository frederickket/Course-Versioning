/**
 * @author      WDCi (XW)
 * @date        June 2024
 * @group       Requirement
 * @description Generate Individual Requirement when Individual Requirement Set is generated
 * @changehistory
 * ISS-002128 04-06-2025 XW - create new class
 */

public inherited sharing class IRS_CreateIndividualRequirement_EXE extends REDU_TriggerExecutable {

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

            Map<Id, reduivy__Individual_Requirement_Set__c> workingMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
            Map<Id, List<reduivy__Individual_Requirement_Set__c>> srsIdToIrsMap = new Map<Id, List<reduivy__Individual_Requirement_Set__c>>();
            for (reduivy__Individual_Requirement_Set__c irsNew : (List<reduivy__Individual_Requirement_Set__c>) newList) {
                if(
                    String.isNotBlank(irsNew.reduivy__Study_Requirement_Set__c) && 
                    irsNew.reduivy__Status__c == IRS_Helper.STATUS_ACTIVE &&
                    irsNew.reduivy__Requirement_Generation_Mode__c == IRS_Helper.REQUIREMENT_GENERATION_MODE_AUTO
                ) {
                    workingMap.put(irsNew.Id, irsNew);
                    if(srsIdToIrsMap.containsKey(irsNew.reduivy__Study_Requirement_Set__c)) {
                       srsIdToIrsMap.get(irsNew.reduivy__Study_Requirement_Set__c).add(irsNew);
                    } else {
                       srsIdToIrsMap.put(irsNew.reduivy__Study_Requirement_Set__c, new List<reduivy__Individual_Requirement_Set__c> {irsNew}) ;
                    }
                }
            }

            if(!workingMap.isEmpty()) {
                createIrq(workingMap, srsIdToIrsMap);
            }
        }
    }

    /**
     * @description create a list of children individual requirement of the individual requirement
     * @param  irsMap        the irs Map
     * @param  srsIdToIrsMap Map of study requirment set Id to the list of related individual requirement set
     */
    private void createIrq(Map<Id, reduivy__Individual_Requirement_Set__c> irsMap, Map<Id, List<reduivy__Individual_Requirement_Set__c>> srsIdToIrsMap) {
        //query srs and its related srq to clone
        Map<Id, reduivy__Study_Requirement_Set__c> srsMap = new Map<Id, reduivy__Study_Requirement_Set__c>();
        List<reduivy__Individual_Requirement__c> irqToInsert = new List<reduivy__Individual_Requirement__c>();
        Set<String> usedRequirementCode = new Set<String>();

        Set<String> srsFields = new Set<String> {
            'Id',
            'reduivy__Object__c'
        };

        Set<String> srqFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Due_Days__c'
        };
        srqFields.addAll(IRQ_Helper.getSrqIrqCommonFields());
        String srqQuery = 'SELECT ' + String.join(srqFields, ', ') +
                         ' FROM reduivy__Study_Requirements__r' +
                         ' WHERE reduivy__Status__c = :srqActive';

        String srsQuery = 'SELECT ' + String.join(srsFields, ', ') + ', (' + srqQuery + ')' +
                         ' FROM ' + SRS_Helper.getApiName() +
                         ' WHERE Id in :srsId' +
                         ' AND reduivy__Status__c = :srsActive';

        Map<String, Object> bindMap = new Map<String, Object> {
            'srqActive' => SRQ_Helper.STATUS_ACTIVE,
            'srsActive' => SRS_Helper.STATUS_ACTIVE,
            'srsId' => srsIdToIrsMap.keySet()
        };

        for(reduivy__Study_Requirement_Set__c srs : (List<reduivy__Study_Requirement_Set__c>) Database.queryWithBinds(srsQuery, bindMap, AccessLevel.USER_MODE)) {
            srsMap.put(srs.Id, srs);
            if(srsIdToIrsMap.containsKey(srs.Id)){
                Boolean hasMasterDetailRelationship = REDU_Metadata_UTIL.hasMasterDetailRelationship(srs.reduivy__Object__c);

                for(reduivy__Individual_Requirement_Set__c irs : srsIdToIrsMap.get(srs.Id)){
                    for(reduivy__Study_Requirement__c srq : srs.reduivy__Study_Requirements__r) {

                        Id ownerId = IRQ_Helper.getIrqOwnerId(srs.reduivy__Object__c, srq, irs);
                        
                        reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srq, irs.Id, ownerId);
                        irqToInsert.add(irq);
                    }
                }
            }
        }

        if(!irqToInsert.isEmpty()) {
            REDU_Database_UTIL.doInsert(irqToInsert, irsMap, 'reduivy__Individual_Requirement_Set__c', false);
        }
        
    }
}