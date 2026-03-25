/**
 * @author      WDCi (XW)
 * @date        Jan 2025
 * @group       Object Helper
 * @description Translation object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002230 03-02-2025 XW - new class
 * ISS-002312 05-03-2025 XW - accept cloned translation if sobj is a cloned record
 * ISS-002529 08-07-2025 XW - update the for field and for field api name value to the source field, instead of the target field (formula field)
 * ISS-002495 18-09-2025 XW - support translation for long text field
 */
global inherited sharing class TLN_Helper implements SObject_Helper {

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Translation__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Translation__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Translation__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Translation__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
    /**
     * @description Generate list of translation record with default name applied
     * @param  objList                                  The object list to be translated
     * @param  fieldDescribeTobeTranslatedList          The field describe of the field to be translated (eg. Study Unit Name, Study Plan Name)
     * @param  formulaField_targetFieldToTranslate   Map to get the field to be translated. Key = formula field name, value = target field name to be translated
     * @return    List<reduivy__Translation__c>            
     */
    global static List<reduivy__Translation__c> generateTranslationRecords(List<SObject> objList, List<Schema.DescribeFieldResult> displayFieldList, Map<String, String> formulaField_targetFieldToTranslate){

        throw new UnsupportedOperationException('The operation is obsolete.');
    }
    
    /**
     * @description Generate translation records with default name applied
     * @param  objList                             The object list to be translated
     * @param  sobjTranslationFormulaFields        list of formula fields that are used to display the translated value
     * @param  formulaField_targetFieldToTranslate map of formula fields to the source field to be translated
     * @param  sourceRecordsTranslations           list of the source fields to be translated
     * @param  translationMappingWrapperList       list of translation mapping config
     * @return                                     return description
     */
    @NamespaceAccessible
    public static List<Map<String, reduivy__Translation__c>> generateTranslationRecords(List<SObject> objList, List<REDU_TranslationManager.TranslationMapping> sobjTranslationFormulaFields, Map<String, String> formulaField_targetFieldToTranslate, Map<String, reduivy__Translation__c> sourceRecordsTranslations, List<REDU_TranslationManager.TranslationMapping> translationMappingWrapperList){
        List<Map<String, reduivy__Translation__c>> translationsBySobj = new List<Map<String, reduivy__Translation__c>>();

        for(SObject sobj : objList) {
            Map<String, reduivy__Translation__c> sobjTranslations = new Map<String, reduivy__Translation__c>();

            for(REDU_TranslationManager.TranslationMapping formulaMapping : sobjTranslationFormulaFields) {
                //create new translation record, name = '{object record name} {Field label of the formula}'
                reduivy__Translation__c newTln;
                String defaultTlmReference = String.format(Label.Translation_Map_Default_Name, new List<String>{String.valueOf(sobj.get('Name')), formulaMapping.sourceFieldDescribe.getLabel()});

                //if sobject is cloned, we will see if we can clone the existing translation record
                String sourceRecordTranslationKey = sobj.getCloneSourceId() + '_' + formulaMapping.sourceField;
                if(sourceRecordsTranslations != null && sobj.isClone() && sourceRecordsTranslations.containsKey(sourceRecordTranslationKey)){
                    
                    reduivy__Translation__c tln = sourceRecordsTranslations.get(sourceRecordTranslationKey);

                    newTln = tln.clone(false, true, false, false);
                    newTln.reduivy__Clone_From_Id__c = tln.Id;

                } else {
                    newTln = new reduivy__Translation__c();
                }

                newTln.reduivy__Reference__c = defaultTlmReference;
                newTln.reduivy__For_Field__c = formulaMapping.sourceFieldDescribe.getLabel();
                newTln.reduivy__For_Field_API_Name__c = sobj.getSObjectType() + '.' + formulaMapping.sourceField;

                if(String.isNotBlank(formulaMapping.sourceField)) {
                    newTln.reduivy__Default__c = String.valueOf(sobj.get(formulaMapping.sourceField));
                }

                sobjTranslations.put(formulaMapping.sourceField, newTln);
            }

            //generate translation records if translation mapping mdt is defined
            if(translationMappingWrapperList != null && !translationMappingWrapperList.isEmpty()) {
                for(REDU_TranslationManager.TranslationMapping configMapping : translationMappingWrapperList) {
                    reduivy__Translation__c newTln;
                    String defaultTlmReference = String.format(Label.Translation_Map_Default_Name, new List<String>{String.valueOf(sobj.get('Name')), configMapping.sourceFieldDescribe.getLabel()});
                    
                    //if sobject is cloned, we will see if we can clone the existing translation record
                    String sourceRecordTranslationKey = sobj.getCloneSourceId() + '_' + configMapping.sourceField;
                    if(sourceRecordsTranslations != null && sobj.isClone() && sourceRecordsTranslations.containsKey(sourceRecordTranslationKey)){
                        
                        reduivy__Translation__c tln = sourceRecordsTranslations.get(sourceRecordTranslationKey);

                        newTln = tln.clone(false, true, false, false);
                        newTln.reduivy__Clone_From_Id__c = tln.Id;

                    } else {
                        newTln = new reduivy__Translation__c();
                    }
                    
                    newTln.reduivy__Reference__c = defaultTlmReference;
                    newTln.reduivy__For_Field__c = configMapping.sourceFieldDescribe.getLabel();
                    newTln.reduivy__For_Field_API_Name__c = sobj.getSObjectType() + '.' + configMapping.sourceField;

                    sobjTranslations.put(configMapping.sourceField, newTln);
                }
            }

            translationsBySobj.add(sobjTranslations);
        }

        return translationsBySobj;
    }


}