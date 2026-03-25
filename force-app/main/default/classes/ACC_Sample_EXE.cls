/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Trigger controller
 * @description Sample trigger controller for account 
 * @changehistory
 * ISS-001591 30-03-2023 Lean - new class
 */
public inherited sharing class ACC_Sample_EXE extends REDU_TriggerExecutable {
    
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

        if (operationType == TriggerOperation.BEFORE_INSERT) {
            List<Log__c> newLogs = new List<Log__c>();
            for (Account acc : (List<Account>) newList) {
                newLogs.add(new Log__c(Name = acc.Name, Reference__c = 'BeforeInsert'));
            }

            REDU_Database_UTIL.doInsert(newLogs);

            if (!newMap.isEmpty() || !oldList.isEmpty() || !oldMap.isEmpty()) {
                throw new REDU_ApplicationException('Invalid trigger context data:: newList = ' + newList.isEmpty() + ', newMap = ' + newMap.isEmpty() + ', oldList = ' + oldList.isEmpty() + ', oldMap = ' + oldMap.isEmpty());
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

        if (operationType == TriggerOperation.BEFORE_UPDATE) {
            List<Log__c> newLogs = new List<Log__c>();
            for (Account acc : (List<Account>) newList) {
                newLogs.add(new Log__c(Name = acc.Name, Reference__c = 'BeforeUpdate'));
            }

            REDU_Database_UTIL.doInsert(newLogs);

            if ((newList.size() != newMap.keySet().size()) || newList.size() != oldList.size() || newList.size() != oldMap.keySet().size()) {
                throw new REDU_ApplicationException('Invalid trigger context data:: newList = ' + newList.isEmpty() + ', newMap = ' + newMap.isEmpty() + ', oldList = ' + oldList.isEmpty() + ', oldMap = ' + oldMap.isEmpty());
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

        if (operationType == TriggerOperation.BEFORE_DELETE) {
            List<Log__c> newLogs = new List<Log__c>();
            for (Account acc : (List<Account>) oldList) {
                newLogs.add(new Log__c(Name = acc.Name, Reference__c = 'BeforeDelete'));
            }

            REDU_Database_UTIL.doInsert(newLogs);

            if (!newList.isEmpty() || !newMap.isEmpty() || oldList.size() != oldMap.keySet().size()) {
                throw new REDU_ApplicationException('Invalid trigger context data:: newList = ' + newList.isEmpty() + ', newMap = ' + newMap.isEmpty() + ', oldList = ' + oldList.isEmpty() + ', oldMap = ' + oldMap.isEmpty());
            }
        }
    }

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

        if (operationType == TriggerOperation.AFTER_INSERT) {
            List<Log__c> newLogs = new List<Log__c>();
            for (Account acc : (List<Account>) newList) {
                newLogs.add(new Log__c(Name = acc.Name, Reference__c = 'AfterInsert'));
            }

            REDU_Database_UTIL.doInsert(newLogs);

            if ((newList.size() != newMap.keySet().size()) || !oldList.isEmpty() || !oldMap.isEmpty()) {
                throw new REDU_ApplicationException('Invalid trigger context data:: newList = ' + newList.isEmpty() + ', newMap = ' + newMap.isEmpty() + ', oldList = ' + oldList.isEmpty() + ', oldMap = ' + oldMap.isEmpty());
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

        if (operationType == TriggerOperation.AFTER_UPDATE) {
            List<Log__c> newLogs = new List<Log__c>();
            for (Account acc : (List<Account>) newList) {
                newLogs.add(new Log__c(Name = acc.Name, Reference__c = 'AfterUpdate'));
            }

            REDU_Database_UTIL.doInsert(newLogs);

            if ((newList.size() != newMap.keySet().size()) || newList.size() != oldList.size() || newList.size() != oldMap.keySet().size()) {
                throw new REDU_ApplicationException('Invalid trigger context data:: newList = ' + newList.isEmpty() + ', newMap = ' + newMap.isEmpty() + ', oldList = ' + oldList.isEmpty() + ', oldMap = ' + oldMap.isEmpty());
            }
        }
    }

    /**
     * @description AfterDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (operationType == TriggerOperation.AFTER_DELETE) {
            List<Log__c> newLogs = new List<Log__c>();
            for (Account acc : (List<Account>) oldList) {
                newLogs.add(new Log__c(Name = acc.Name, Reference__c = 'AfterDelete'));
            }

            REDU_Database_UTIL.doInsert(newLogs);

            if (!newList.isEmpty() || !newMap.isEmpty() || oldList.size() != oldMap.keySet().size()) {
                throw new REDU_ApplicationException('Invalid trigger context data:: newList = ' + newList.isEmpty() + ', newMap = ' + newMap.isEmpty() + ', oldList = ' + oldList.isEmpty() + ', oldMap = ' + oldMap.isEmpty());
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

        if (operationType == TriggerOperation.AFTER_UNDELETE) {
            List<Log__c> newLogs = new List<Log__c>();
            for (Account acc : (List<Account>) newList) {
                newLogs.add(new Log__c(Name = acc.Name, Reference__c = 'AfterUndelete'));
            }

            REDU_Database_UTIL.doInsert(newLogs);

            if ((newList.size() != newMap.keySet().size()) || !oldList.isEmpty() || !oldMap.isEmpty()) {
                throw new REDU_ApplicationException('Invalid trigger context data:: newList = ' + newList.isEmpty() + ', newMap = ' + newMap.isEmpty() + ', oldList = ' + oldList.isEmpty() + ', oldMap = ' + oldMap.isEmpty());
            }
        }
    }
}