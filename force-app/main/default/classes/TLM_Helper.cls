/**
 * @author      WDCi (XW)
 * @date        Feb 2025
 * @group       Object Helper
 * @description Translation Map object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002230 03-02-2025 XW - new class
 * ISS-002312 07-03-2025 XW - accept cloned translation map
 */
global inherited sharing class TLM_Helper implements SObject_Helper {
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Translation_Map__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Translation_Map__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Translation_Map__c.getName();
    }

    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Translation_Map__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Generate a list of Translation Map records with translation linked
     * @param  objList                  list of record to be translated
     * @param  translationList          Inserted translation records
     * @param  usedTlnFieldsName        The used translation field Api name in translation map
     * @return                          List<reduivy__Translation_Map__c>
     */
    global static List<reduivy__Translation_Map__c> generateTranslationMapRecords(List<SObject> objList, List<reduivy__Translation__c> translationList, Set<String> usedTlnFieldsName){
        throw new UnsupportedOperationException('The operation is obsolete.');
    }

    /**
     * @description Generate a list of Translation Map records with translation linked
     * @param  objList                  list of record to be translated
     * @param  translationList          Inserted translation records
     * @param  tlnFieldsNameAndRelationshipInTlm  The translation field Api name in translation map
     * @param  clonedTranslationMaps    The cloned translation map
     * @return List<reduivy__Translation_Map__c>
     */
    @NamespaceAccessible
    public static List<reduivy__Translation_Map__c> generateTranslationMapRecords(List<SObject> objList, List<Map<String, reduivy__Translation__c>> translationsBySobj, Map<String, String> tlnFieldsName_targetFieldToTranslate, Map<Id, reduivy__Translation_Map__c> sourceRecordsTranslationMaps){
        List<reduivy__Translation_Map__c> translationMapList = new List<reduivy__Translation_Map__c>();

        Integer counter = 0;
        String objectLabel = getObjectLabel();
        for(SObject obj : objList) {
            Map<String, reduivy__Translation__c> translations = translationsBySobj.get(counter);
            
            //generate reference for translation map
            String defaultTlmReference = String.format(Label.Translation_Map_Default_Name, new List<String>{String.valueOf(obj.get('Name')), objectLabel});
            
            //get cloned translation map if sobject is cloned
            reduivy__Translation_Map__c newTlm;
            String sourceRecordTranslationMapKey = obj.getCloneSourceId();

            if(sourceRecordsTranslationMaps != null && obj.isClone() && sourceRecordsTranslationMaps.containsKey(sourceRecordTranslationMapKey)) {

                reduivy__Translation_Map__c tlm = sourceRecordsTranslationMaps.get(sourceRecordTranslationMapKey);

                newTlm = new reduivy__Translation_Map__c();
                newTlm.reduivy__Clone_From_Id__c = tlm.Id;

            } else {
                newTlm = new reduivy__Translation_Map__c();
            }

            newTlm.reduivy__Reference__c = defaultTlmReference;
            
            for(String fieldName : tlnFieldsName_targetFieldToTranslate.keySet()) {
                String targetField = tlnFieldsName_targetFieldToTranslate.get(fieldName);


                if (translations.containsKey(targetField)) {
                    newTlm.put(fieldName, translations.get(targetField).Id);
                }                
            }

            translationMapList.add(newTlm);

            counter ++;
        }

        REDU_Logging_UTIL.debugJsonString('translationMapList', translationMapList);
        return translationMapList;
    }
}