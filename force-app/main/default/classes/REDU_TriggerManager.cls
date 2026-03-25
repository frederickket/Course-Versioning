/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Util
 * @description Trigger manager that invokes Trigger Controller
 * @changehistory
 * ISS-001591 30-03-2023 Lean - new class
 */
global inherited sharing class REDU_TriggerManager {
    
    /**
     * @description A global method to initiate the execution for Trigger Controller
     * @param operationType TriggerOperation enum
     * @param newList Trigger.new
     * @param oldList Trigger.old
     * @param sobjResult DescribeSObjectResult of Schema.SObjectType
     */
    global static void execute(System.TriggerOperation operationType, List<SObject> newList, List<SObject> oldList, Schema.DescribeSObjectResult sobjResult) {
        REDU_TriggerController.execute(operationType, newList, oldList, sobjResult);
    }

}