/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Util
 * @description Trigger controller
 * @changehistory
 * ISS-001591 30-03-2023 Lean - new class
 */
global inherited sharing abstract class REDU_TriggerExecutable {
    
    /**
     * @description BeforeInsert Method to be implemented by the classes that extend this abstract class.
     * @param operationType TriggerOperation enum
     * @param newList The filtered newList
     * @param newMap The filtered newMap
     * @param oldList The filtered oldList
     * @param oldMap The filtered oldMap
     * @param sobjResult DescribeSObjectResult of Schema.SObjectType
     */
    global virtual void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

    }

    /**
     * @description BeforeUpdate Method to be implemented by the classes that extend this abstract class.
     * @param operationType TriggerOperation enum
     * @param newList The filtered newList
     * @param newMap The filtered newMap
     * @param oldList The filtered oldList
     * @param oldMap The filtered oldMap
     * @param sobjResult DescribeSObjectResult of Schema.SObjectType
     */
    global virtual void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

    }

    /**
     * @description BeforeDelete Method to be implemented by the classes that extend this abstract class.
     * @param operationType TriggerOperation enum
     * @param newList The filtered newList
     * @param newMap The filtered newMap
     * @param oldList The filtered oldList
     * @param oldMap The filtered oldMap
     * @param sobjResult DescribeSObjectResult of Schema.SObjectType
     */
    global virtual void executeBeforeDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

    }

    /**
     * @description AfterInsert Method to be implemented by the classes that extend this abstract class.
     * @param operationType TriggerOperation enum
     * @param newList The filtered newList
     * @param newMap The filtered newMap
     * @param oldList The filtered oldList
     * @param oldMap The filtered oldMap
     * @param sobjResult DescribeSObjectResult of Schema.SObjectType
     */
    global virtual void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

    }

    /**
     * @description AfterUpdate Method to be implemented by the classes that extend this abstract class.
     * @param operationType TriggerOperation enum
     * @param newList The filtered newList
     * @param newMap The filtered newMap
     * @param oldList The filtered oldList
     * @param oldMap The filtered oldMap
     * @param sobjResult DescribeSObjectResult of Schema.SObjectType
     */
    global virtual void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

    }

    /**
     * @description AfterDelete Method to be implemented by the classes that extend this abstract class.
     * @param operationType TriggerOperation enum
     * @param newList The filtered newList
     * @param newMap The filtered newMap
     * @param oldList The filtered oldList
     * @param oldMap The filtered oldMap
     * @param sobjResult DescribeSObjectResult of Schema.SObjectType
     */
    global virtual void executeAfterDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

    }

    /**
     * @description AfterUndelete Method to be implemented by the classes that extend this abstract class.
     * @param operationType TriggerOperation enum
     * @param newList The filtered newList
     * @param newMap The filtered newMap
     * @param oldList The filtered oldList
     * @param oldMap The filtered oldMap
     * @param sobjResult DescribeSObjectResult of Schema.SObjectType
     */
    global virtual void executeAfterUndelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

    }
}