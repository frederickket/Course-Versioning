/**
 * @author      WDCi (Lean)
 * @date        Jul 2024
 * @group       Custom Rollup Engine
 * @description Custom Rollup Controller
 * @changehistory
 * ISS-001993 02-07-2024 Lean - controller to support disablement of rollup
 */
global inherited sharing class REDU_CustomRollupController {
    
    /**
     * @description Set<String> to hold the config name, child object, and child>>master object for the muted rollups
     */
    private static Set<String> rollupsToMute;

    /**
     * @description Boolean flag to mute all rollups
     */
    private static Boolean muteAll = false;

    /**
     * @description Mute rollups by config name, child object, or child>>master object (e.g., reduivy__Transaction_Line_Item__c>>reduivy__Transaction_Order__c)
     * @param rollups Set<String> of rollup config name, child object, or child>>master object
     */
    global static void muteRollups(Set<String> rollups) {
        if (rollupsToMute == null) {
            rollupsToMute = rollups;
        } else {
            rollupsToMute.addAll(rollups);
        }
        
    }

    /**
     * @description Unmute rollups by config name, child object, or child>>master object (e.g., reduivy__Transaction_Line_Item__c>>reduivy__Transaction_Order__c)
     * @param triggers Set<String> of rollup config name, child object, or child>>master object
     */
    global static void unmuteRollups(Set<String> rollups) {
        if (rollupsToMute != null) {
            rollupsToMute.removeAll(rollups);
        }
    }

    /**
     * @description Mute all rollups
     */
    global static void muteAllRollups() {
        muteAll = true;
    }

    /**
     * @description Unmute all rollups
     */
    global static void unmuteAllRollups() {
        muteAll = false;
        rollupsToMute = new Set<String>();
    }

    /**
     * @description Main method to initiate rollup
     * @param operationType TriggerOperation enum
     * @param rawNewList Trigger.new
     * @param rawOldList Trigger.old
     * @param sobjResult Schema.SobjectType
     */
    public static void execute(System.TriggerOperation operationType, List<SObject> rawNewList, List<SObject> rawOldList, Schema.DescribeSObjectResult sobjResult) {

        try {
            //get sobject type
            String objType = rawNewList != null && !rawNewList.isEmpty() ? String.valueOf(rawNewList.getSObjectType()) : String.valueOf(rawOldList.getSObjectType());

            //will skip all rollups if muteAll is enabled or object type is unknown
            if (muteAll || String.isBlank(objType)) {
                return;
            }
            
            List<SObject> objectList = new List<SObject>();
            List<SObject> oldObjectList = new List<SObject>();

            if(operationType == TriggerOperation.AFTER_INSERT || operationType == TriggerOperation.AFTER_UPDATE || operationType == TriggerOperation.AFTER_UNDELETE){
                objectList = rawNewList;

                if (operationType == TriggerOperation.AFTER_UPDATE) {
                    oldObjectList = rawOldList;
                }
            } else if (operationType == TriggerOperation.AFTER_DELETE) {
                objectList = rawOldList;
            } else {
                return;
            }
            
            Map<String, List<reduivy__Custom_Rollup_Config__mdt>> rollupConfigsByParentObject = REDU_CustomRollup_UTIL.getRollupConfigsByParentObject(objType);
            Map<String, List<reduivy__Custom_Rollup_Config__mdt>> eligibleRollupConfigsByParentObject = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();

            for (String parentObjType : rollupConfigsByParentObject.keySet()) {
                for (reduivy__Custom_Rollup_Config__mdt crc : rollupConfigsByParentObject.get(parentObjType)) {
                    if (isEligble(crc)) {
                        if (eligibleRollupConfigsByParentObject.containsKey(parentObjType)) {
                            eligibleRollupConfigsByParentObject.get(parentObjType).add(crc);
                        } else {
                            eligibleRollupConfigsByParentObject.put(parentObjType, new List<reduivy__Custom_Rollup_Config__mdt>{crc});
                        }
                    }
                }
            }

            if (!eligibleRollupConfigsByParentObject.isEmpty()) {
                REDU_CustomRollup_OBJ rollupInsert = new REDU_CustomRollup_OBJ(objectList, oldObjectList, eligibleRollupConfigsByParentObject);
                rollupInsert.doRollup();
            }

        } catch (QueryException qex) {
            REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
        }
    }

    /**
     * @description Check if a custom rollup is eligible to run e.g., not muted
     * @param tc reduivy__Custom_Rollup_Config__mdt
     * @return Boolean
     */
    private static Boolean isEligble(reduivy__Custom_Rollup_Config__mdt crc) {
        if (rollupsToMute != null && (rollupsToMute.contains(crc.reduivy__Child_Object_Name__c) || rollupsToMute.contains(crc.DeveloperName) || rollupsToMute.contains(crc.reduivy__Child_Object_Name__c + '>>' + crc.reduivy__Master_Object_Name__c))) {
            return false;
        }

        return true;

    }
}