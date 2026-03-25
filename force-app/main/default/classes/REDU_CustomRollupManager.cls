/**
 * @author      WDCi (Lean)
 * @date        Jul 2024
 * @group       Custom Rollup Engine
 * @description Custom Rollup Manager
 * @changehistory
 * ISS-001993 02-07-2024 Lean - controller to support disablement of rollup
 */
global inherited sharing class REDU_CustomRollupManager {
    
    /**
     * @description A global method to initiate the execution for rollup
     * @param operationType TriggerOperation enum
     * @param newList Trigger.new
     * @param oldList Trigger.old
     * @param sobjResult DescribeSObjectResult of Schema.SObjectType
     */
    global static void execute(System.TriggerOperation operationType, List<SObject> newList, List<SObject> oldList, Schema.DescribeSObjectResult sobjResult) {
        REDU_CustomRollupController.execute(operationType, newList, oldList, sobjResult);
    }

}