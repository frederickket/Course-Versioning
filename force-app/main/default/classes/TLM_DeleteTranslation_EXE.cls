/**
 * @author      WDCi (XW)
 * @date        Mar 2025
 * @group       Translation
 * @description Delete parent translation records if the translation map records are deleted
 * @changehistory
 * ISS-002340 19-03-2025 XW - new class
 * ISS-002410 14-04-2025 XiRouh - Replaced isSet with != null
 */

public without sharing class TLM_DeleteTranslation_EXE extends REDU_TriggerExecutable {

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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Map<Id, reduivy__Translation_Map__c> workingMap = new Map<Id, reduivy__Translation_Map__c>();
            for (reduivy__Translation_Map__c objOld : (List<reduivy__Translation_Map__c>) oldList) {
                workingMap.put(objOld.Id, objOld);
            }

            if(!workingMap.isEmpty()){
                deleteTranslation(workingMap);
            }
        }
    }
	
    /**
     * @description delete translation records of the translation maps
     * @param  tlmMap the target translation map
     */
    private void deleteTranslation(Map<Id, reduivy__Translation_Map__c> tlmMap) {
        Set<String> tlnFieldsName = getTlnFieldsNameInTlm();
        List<reduivy__Translation__c> translationsToDelete = new List<reduivy__Translation__c>();
        Map<Id, reduivy__Translation_Map__c> tlmOriginMap = new Map<Id, reduivy__Translation_Map__c>();

        for(reduivy__Translation_Map__c tlm : tlmMap.values()) {
            for(String tlnfield : tlnFieldsName) {
                if(tlm.get(tlnfield) != null){
                    Id tlnId = (Id)tlm.get(tlnfield);
                    
                    reduivy__Translation__c tlnToDelete = new reduivy__Translation__c(Id = tlnId);
                    translationsToDelete.add(tlnToDelete);
                    tlmOriginMap.put(tlnId, tlm);
                }
            }
        }

        if(!translationsToDelete.isEmpty()) {
            REDU_Database_UTIL.doDelete(translationsToDelete, tlmOriginMap, 'Id', false);
        }
    }

    /**
    * @description get the field api name of the translation lookup field in translation map
    * @return   Set of Translation Lookup field api name
    */
    private Set<String> getTlnFieldsNameInTlm(){
        Set<String> tlnFields = new Set<String>();
        Map<String, Schema.SObjectField> tlmFieldMap = SObjectType.reduivy__Translation_Map__c.fields.getMap();
        for(String fieldName : tlmFieldMap.keySet()) {
            Schema.DescribeFieldResult tlmFieldDescribe = tlmFieldMap.get(fieldName).getDescribe();
            if(tlmFieldDescribe.getType() == Schema.DisplayType.REFERENCE && 
                tlmFieldDescribe.getReferenceTo()[0].getDescribe(SObjectDescribeOptions.DEFERRED).getName() == TLN_Helper.getApiName()
            ) {
                tlnFields.add(tlmFieldDescribe.getName());
            }
        }

        return tlnFields;
    }
}