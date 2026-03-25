/**
 * @author      WDCi (Jordan)
 * @date        Feb 2024
 * @group       Custom Rollup Engine
 * @description Custom rollup utility
 * @changehistory
 * ISS-001847 07-02-2024 Jordan - new class
 */
public inherited sharing class REDU_CustomRollup_UTIL {

    /**
     * @description Map of reduivy__Trigger_Controller__mdt
     */
    public static Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>> rollupConfigsByChildAndParentObject;

    /**
     * @description Sets the list of reduivy__Custom_Rollup_Config__mdt grouped by object
     * @return Map<String, List<reduivy__Custom_Rollup_Config__mdt>>
    */
    public static Map<String, List<reduivy__Custom_Rollup_Config__mdt>> getRollupConfigsByParentObject(String childObjType) {

        if (rollupConfigsByChildAndParentObject == null) {
            rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();

            //Get all child objects
            Set<String> childObjects = new Set<String>();

            //Get all configs
            List<reduivy__Custom_Rollup_Config__mdt> rollupConfigs = reduivy__Custom_Rollup_Config__mdt.getAll().values();

            List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
                new REDU_SObjectComparator.SortCriterion(reduivy__Custom_Rollup_Config__mdt.reduivy__Sequence2__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
            };
            
            rollupConfigs.sort(new REDU_SObjectComparator(criteria));

            for (reduivy__Custom_Rollup_Config__mdt rc : rollupConfigs) {
                childObjects.add(rc.reduivy__Child_Object_Name__c);
            }

            for (String childObject : childObjects) {
                Map<String, List<reduivy__Custom_Rollup_Config__mdt>> rcByParentObjects = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();

                for (reduivy__Custom_Rollup_Config__mdt rc : rollupConfigs) {
                    if (rc.reduivy__Active__c && rc.reduivy__Child_Object_Name__c == childObject) {
                        if (!rcByParentObjects.containsKey(rc.reduivy__Master_Object_Name__c)) {
                            rcByParentObjects.put(rc.reduivy__Master_Object_Name__c, new List<reduivy__Custom_Rollup_Config__mdt>{rc});
                        } else {
                            rcByParentObjects.get(rc.reduivy__Master_Object_Name__c).add(rc);
                        }
                    }
                }

                rollupConfigsByChildAndParentObject.put(childObject, rcByParentObjects);
            }
        }

        return rollupConfigsByChildAndParentObject.get(childObjType);
    }

}