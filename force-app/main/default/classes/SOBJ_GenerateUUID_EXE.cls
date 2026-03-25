/**
 * @author      WDCi (XiRouh)
 * @date        July 2024
 * @group       
 * @description trigger to populate the uuid field
 * @changehistory
 * ISS-002046 31-07-2024 XiRouh - new class
 */
public inherited sharing class SOBJ_GenerateUUID_EXE extends REDU_TriggerExecutable {
    
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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER) || REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)) {

            if(sobjResult.fields.getMap().containsKey('reduivy__UUID__c')){
                for (SObject objNew : newList) {
                    String uuid = (String)objNew.get('reduivy__UUID__c');

                    if (String.isBlank(uuid)) {

                        String generatedUUID = System.UUID.randomUUID().toString();

                        objNew.put('reduivy__UUID__c', generatedUUID);
                    }

                }
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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER) || REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)) {

            if(sobjResult.fields.getMap().containsKey('reduivy__UUID__c')){
                for (SObject objNew : newList) {
                    String uuid = (String)objNew.get('reduivy__UUID__c');

                    if (String.isBlank(uuid)) {

                        String generatedUUID = System.UUID.randomUUID().toString();

                        objNew.put('reduivy__UUID__c', generatedUUID);
                    }

                }
            }    
        }
    }
}