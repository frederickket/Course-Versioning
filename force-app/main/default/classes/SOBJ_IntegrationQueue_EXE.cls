/**
 * @author      WDCi (Xirouh)
 * @date        June 2024
 * @group       
 * @description trigger to add the integration queue record
 * @changehistory
 * ISS-001978 24-06-2024 Xirouh - new class
 */
public inherited sharing class SOBJ_IntegrationQueue_EXE extends REDU_TriggerExecutable {
    
	/**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert (System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_AppSetting_UTIL.isExternalPortalSyncEnabled()) {
            if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER) ||
                REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)
            ) {
                List<reduivy__Integration_Queue__c> iqList = new List <reduivy__Integration_Queue__c>();
                Map<Id, SObject> sourceMap = new Map<Id, SObject>();

                for (SObject s : newList) {
                    iqList.add(INQ_Helper.addIntegrationQueue(INQ_Helper.ACTION_TYPE_INSERT, sobjResult, s, INQ_Helper.STATUS_TYPE_READY_TO_SYNC, INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL));
                    sourceMap.put(s.Id, s);
                }

                if (!iqList.isEmpty()) {
                    REDU_Database_UTIL.doInsert(iqList, sourceMap, 'reduivy__Object_Id__c', false);
                }
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
        
        if (REDU_AppSetting_UTIL.isExternalPortalSyncEnabled()) {
            if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER) ||
                REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)
            ) {
                List<reduivy__Integration_Queue__c> iqList = new List <reduivy__Integration_Queue__c>();
                Map<Id, SObject> sourceMap = new Map<Id, SObject>();

                for (SObject s : newList) {
                    iqList.add(INQ_Helper.addIntegrationQueue(INQ_Helper.ACTION_TYPE_UPDATE, sobjResult, s, INQ_Helper.STATUS_TYPE_READY_TO_SYNC, INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL));
                    sourceMap.put(s.Id, s);
                }

                if (!iqList.isEmpty()) {
                    REDU_Database_UTIL.doInsert(iqList, sourceMap, 'reduivy__Object_Id__c', false);
                }
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
        
        if (REDU_AppSetting_UTIL.isExternalPortalSyncEnabled()) {
            if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER) ||
                REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)
            ) {
                List<reduivy__Integration_Queue__c> iqList = new List <reduivy__Integration_Queue__c>();
                Map<Id, SObject> sourceMap = new Map<Id, SObject>();

                for (SObject s : oldList) {
                    iqList.add(INQ_Helper.addIntegrationQueue(INQ_Helper.ACTION_TYPE_DELETE, sobjResult, s, INQ_Helper.STATUS_TYPE_READY_TO_SYNC, INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL));
                    sourceMap.put(s.Id, s);
                }

                if (!iqList.isEmpty()) {
                    REDU_Database_UTIL.doInsert(iqList, sourceMap, 'reduivy__Object_Id__c', false);
                }
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
        
        if (REDU_AppSetting_UTIL.isExternalPortalSyncEnabled()) {
            if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER) ||
                REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)
            ) {
                List<reduivy__Integration_Queue__c> iqList = new List <reduivy__Integration_Queue__c>();
                Map<Id, SObject> sourceMap = new Map<Id, SObject>();

                for (SObject s : newList) {
                    iqList.add(INQ_Helper.addIntegrationQueue(INQ_Helper.ACTION_TYPE_UNDELETE, sobjResult, s, INQ_Helper.STATUS_TYPE_READY_TO_SYNC, INQ_Helper.TARGET_SYSTEM_TYPE_EXT_PORTAL));
                    sourceMap.put(s.Id, s);
                }

                if (!iqList.isEmpty()) {
                    REDU_Database_UTIL.doInsert(iqList, sourceMap, 'reduivy__Object_Id__c', false);
                }
            }
        }
    }
}