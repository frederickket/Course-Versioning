/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Trigger executable
 * @description Assign the default owner for records created by community users
 * @changehistory
 * ISS-001813 07-12-2023 dblack - new class
 */
public inherited sharing class SOBJ_AssignOwnership_EXE extends REDU_TriggerExecutable {

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

        if ((operationType == TriggerOperation.BEFORE_INSERT) && 
            (USR_Helper.getNonSharingUserTypes().contains(UserInfo.getUserType())) && 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {
            // we don't handle guest user here because digital experience already has a default user
            Id defaultOwnerId = REDU_AppSetting_UTIL.getDefaultOwnerId();

            if (String.isNotBlank(defaultOwnerId)) {
                for (SObject sobj : newList) {
                    sobj.put('OwnerId', defaultOwnerId);
                }
            }
        }
    }
}