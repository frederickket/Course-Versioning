/**
 * @author      WDCi (XW)
 * @date        Mar 2025
 * @group       Trigger
 * @description Delete the translation map records and translation records when sobject records are deleted
 * @changehistory
 * ISS-002340 17-03-2025 XW - new class
 * ISS-002410 14-04-2025 XiRouh - Replaced isSet with != null
 */

public without sharing class SOBJ_DeleteTranslationMap_EXE extends REDU_TriggerExecutable {

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

        Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfoForSObject(sobjResult);

        //track the api name for the translation map lookup field on the sobject
        String tlmFieldNameInSObject = (String) translationInfo.get(REDU_TranslationManager.TRANSLATION_MAP_FIELD_NAME);

        //if there is no Translation Map Field in Sobject, we will skip everything
        if(String.isBlank(tlmFieldNameInSObject)) {
            return;
        }

        REDU_Logging_UTIL.debugJsonString('translationMapFieldNameInObject', tlmFieldNameInSObject);

        Map<Id, SObject> workingMap = new Map<Id, SObject>();
        for (SObject objOld : (List<SObject>) oldList) {
            if(objOld.get(tlmFieldNameInSObject) != null) {
                workingMap.put(objOld.Id, objOld);
            } 
        }

        if(!workingMap.isEmpty()) {
            deleteTranslationMaps(workingMap, tlmFieldNameInSObject, sobjResult.getName());
        }
    }

    /**
     * @description delete translation map of the records
     * @param  sobjRecords           the sobject records
     * @param  tlmFieldNameInSObject tlm field api name in sobject
     * @param  sobjApiName           sobject api name
     */
    private static void deleteTranslationMaps(Map<Id, SObject> sobjRecords, String tlmFieldNameInSObject, String sobjApiName){
        
        //get all the translation map id and delete them
        List<reduivy__Translation_Map__c> tlmListToDelete = new List<reduivy__Translation_Map__c>();
        Map<Id, SObject> sobjectOriginMap = new Map<Id, SObject>();
        for(SObject sobj : sobjRecords.values()) {
            Id tlmId = (Id) sobj.get(tlmFieldNameInSObject);
            if(String.isNotBlank(tlmId)){
                tlmListToDelete.add(new reduivy__Translation_Map__c(Id = tlmId));
                sobjectOriginMap.put(tlmId, sobj);
            }
        }

        if(!tlmListToDelete.isEmpty()) {
            REDU_Database_UTIL.doDelete(tlmListToDelete, sobjectOriginMap, 'Id', false);
        }
        
    }

    

}