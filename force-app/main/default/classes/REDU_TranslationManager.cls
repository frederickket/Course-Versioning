/**
 * @author      WDCi (XW)
 * @date        Sep 2025
 * @group       Translation
 * @description UTIL class for the translation feature
 * @changehistory
 * ISS-002495 17-09-2025 XW - new class, and moved getTranslationFieldForNameByObjPrefix to here
 * ISS-002746 28-11-2025 Lean - Ignore CurrencyIsoCode from translation
 * ISS-002797 13-02-2026 Lean - Standardize language code format to POSIX
 */

global with sharing class REDU_TranslationManager {

    private static Map<String, Schema.DescribeFieldResult> fieldToDescribeFieldMap = new Map<String, Schema.DescribeFieldResult>();

    public static final List<FormulaEval.FormulaGlobal> FORMULA_GLOBAL_VARIABLES = new List<FormulaEval.FormulaGlobal>{
        FormulaEval.FormulaGlobal.USER,
        FormulaEval.FormulaGlobal.USER_ROLE,
        FormulaEval.FormulaGlobal.PROFILE
    };

    //=========================================================Translation Method : Mixed=============================================

    /**
     * @description map of SObject name => translationinfo
     * @return   return description
     */
    private static Map<String, Map<String, Object>> translationInfoForSObjectMap = new Map<String, Map<String, Object>>();

    /**
     * @description get translation info based on the given sobject result
     * @param sobjResult Schema.DescribeSObjectResult for target object
     * @return Map<String, Object> Translation info 
     */
    global static Map<String, Object> getTranslationInfoForSObject(Schema.DescribeSObjectResult sobjResult) {
        if(translationInfoForSObjectMap.containsKey(sobjResult.getName())) {
            return translationInfoForSObjectMap.get(sobjResult.getName());
        }

        Map<String, Object> translationInfo = new Map<String, Object>();

        //track the formula api name that translate the record name
        String objectNameTranslationFormulaField = '';

        //track the api name for the translation map lookup field on the sobject
        String translationMapFieldNameInObject = '';
        //track the api relationship name for the translation map lookup field on the sobject
        String translationMapFieldRelationshipInObject = '';

        //track the translation field vs relationship api name in reduivy__Translation_Map__c object e.g., reduivy__Translation_1__c=reduivy__Translation_1__r
        //this is used to query the source records's translation if it is cloned
        Map<String, String> tlnFieldsNameAndRelationshipInTlm = new Map<String, String>();

        //track the formula field vs field to be translated in core object e.g., reduivy__Translated_Name__c=Name
        Map<String, String> translationFormulaFieldToSourceField = new Map<String, String>();

        //track the translation field relationship api name vs field to be translated e.g., reduivy__Translation_1__r=Name
        //this is used to identify the source records's translation if it is cloned
        Map<String, String> translationFieldRelationshipToSourceField = new Map<String, String>();

        //track the translation field vs field to be translated e.g., reduivy__Translation_1__c=Name
        Map<String, String> translationFieldToSourceField = new Map<String, String>();  

        //Stores the formula field that display the translation display field in Sobject
        List<TranslationMapping> objectTranslationFormulaFields = new List<TranslationMapping>();
        
        //stores the source field/object and the tranlastion fields in translation map for the source field.
        List<TranslationMapping> objectTranslationMappingConfigFields = new List<TranslationMapping>();
        
        Map<String, Schema.SObjectField> sobjFieldMap = sobjResult.fields.getMap();

        //get the translation value of the formula field
        for(String fieldName : sobjFieldMap.keySet()) {
            Schema.DescribeFieldResult sobjFieldDescribe = sobjFieldMap.get(fieldName).getDescribe();
            if (sobjFieldDescribe.isCalculated() && sobjFieldDescribe.getType() == Schema.DisplayType.STRING &&
                String.isNotBlank(sobjFieldDescribe.getCalculatedFormula())) {

                //if the field is a formula field, we need to check if it is a translation
                String formulaDefinition = sobjFieldDescribe.getCalculatedFormula();
                REDU_Logging_UTIL.debug('formulaDefinition', formulaDefinition);
                
                //extract the actual formula and comments from the formula
                List<String> commentList = extractCommentsFromFormula(formulaDefinition);
                String actualFormula = commentList.remove(0);
                REDU_Logging_UTIL.debug('actualFormula', actualFormula);
                REDU_Logging_UTIL.debug('commentList', commentList);
                
                //we will skip formula which does not have the format of xxx.xxx.xxx 
                Boolean match3Segment = Pattern.matches(REGEX_3_SEGMENT, actualFormula);
                if(!match3Segment){
                    continue;
                }

                //if the formula format is xxx.xxx.xxx, we check if it is a translation map formula field
                List<Schema.DescribeFieldResult> fieldPathResult = REDU_Metadata_UTIL.getDescribePathFields(sobjResult.getName(), actualFormula);
                REDU_Logging_UTIL.debugJsonString('fieldPathResult', fieldPathResult);
                
                //get the first level field (should be tlm)
                Schema.DescribeFieldResult tlmDescribeField = fieldPathResult.get(0);
                //get the second level field (should be tln)
                Schema.DescribeFieldResult tlnDescribeField = fieldPathResult.get(1);
                
                //if it is a translation map formula field, we will check for the field in the comments
                if(tlmDescribeField.getReferenceTo()[0].getDescribe(SObjectDescribeOptions.DEFERRED).getName() == TLM_Helper.getApiName() &&
                    tlnDescribeField.getReferenceTo()[0].getDescribe(SObjectDescribeOptions.DEFERRED).getName() == TLN_Helper.getApiName()) {

                    if(!commentList.isEmpty()) {
                
                        //if comments are found in the formula, we extract fields from comments
                        List<String> targetFieldList = REDU_StringMerge_UTIL.extractFieldNames(PATTERN_MERGESTRING, String.join(commentList, ' ')).values();
                        REDU_Logging_UTIL.debugJsonString('targetFieldList', targetFieldList);
                
                        if(targetFieldList.size() > 1) {
                            String error = String.format(Label.More_Than_1_Field_Is_Found_In_Comments, new List<String> {sobjFieldDescribe.getLabel()});
                            throw new REDU_ApplicationException(error);
                        }
                        else if(targetFieldList.size() == 0) {
                            String error = String.format(Label.No_Field_Is_Found_In_Comments, new List<String> {sobjFieldDescribe.getLabel()});
                            throw new REDU_ApplicationException(error);
                        }
                        else if(targetFieldList.size() == 1) {
                            //store the api name of the field to be translated 
                            String targetFieldName = targetFieldList.get(0).trim();
                            if(!sobjFieldMap.containsKey(targetFieldName)) {
                                //invalid target field
                                String error = String.format(Label.Invalid_Object_Field_Error, new List<String> {targetFieldName, sobjResult.getLabel()});
                                throw new REDU_ApplicationException(error);
                            }
                            
                            translationMapFieldNameInObject = tlmDescribeField.getName();
                            translationMapFieldRelationshipInObject = tlmDescribeField.getRelationshipName();

                            String translationFieldName = tlnDescribeField.getName();
                            String translationRelName = tlnDescribeField.getRelationshipName();

                            tlnFieldsNameAndRelationshipInTlm.put(translationFieldName, translationRelName);

                            translationFormulaFieldToSourceField.put(sobjFieldDescribe.getName(), targetFieldName);
                            translationFieldRelationshipToSourceField.put(translationRelName, targetFieldName);

                            translationFieldToSourceField.put(translationFieldName, targetFieldName);

                            if (targetFieldName.endsWithIgnoreCase('Name')) {
                                objectNameTranslationFormulaField = sobjFieldDescribe.getName();
                            }

                            //rebuild the translation field to mimic the same as the one in metadata config
                            //reduivy__Translation_Map__r.reduivy__Translation_1__c
                            String translationField = translationMapFieldRelationshipInObject + '.' + translationFieldName;
                            //reduivy__Translation_Map__r.reduivy__Translation_1__r
                            String translationFieldRelName = translationMapFieldRelationshipInObject + '.' + translationRelName + '.';

                            //get the last part of the formulat to mimic the same as the one in metadata config
                            //reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Display__c > reduivy__Display__c
                            String formulaString = actualFormula.removeStart(translationFieldRelName).removeStart('.');

                            objectTranslationFormulaFields.add(new TranslationMapping(sobjResult.getName(), targetFieldName, translationField, formulaString));

                            REDU_Logging_UTIL.debug('tlnDescribeField', translationFieldName);
                        }
                    } else {
                        String error = String.format(Label.No_Field_Is_Found_In_Comments, new List<String> {sobjFieldDescribe.getLabel()});
                        throw new REDU_ApplicationException(error);
                    }
                }
            }

        }

        //the translations for long text starts here
        Map<String, Object> translationInfoFromConfig = getTranslationInfoFromConfigForSObject(sobjResult);

        //applying the properties that are defined in the custom mdt
        if(String.isBlank(translationMapFieldNameInObject)) {
            translationMapFieldNameInObject = String.valueOf(translationInfoFromConfig.get(TRANSLATION_MAP_FIELD_NAME));
        }
        if(String.isBlank(translationMapFieldRelationshipInObject)) {
            translationMapFieldRelationshipInObject = String.valueOf(translationInfoFromConfig.get(TRANSLATION_MAP_RELATIONSHIP_NAME));
        }

        Map<String, String> tlnFieldsNameAndRelationshipInTlmFromConfig = (Map<String, String>) translationInfoFromConfig.get(TRANSLATION_FIELD_AND_RELATIONSHIP_IN_TLM);
        for(String tlnLookupField : tlnFieldsNameAndRelationshipInTlmFromConfig.keySet())  {
            tlnFieldsNameAndRelationshipInTlm.put(tlnLookupField, tlnFieldsNameAndRelationshipInTlmFromConfig.get(tlnLookupField));
        }

        Map<String, String> tlnFieldRelationship_targetFieldToTranslateFromConfig = (Map<String, String>) translationInfoFromConfig.get(TRANSLATION_FIELD_RELATIONSHIP_TO_SOURCE_FIELD);
        for(String tlnFieldRelationshipFromConfig : tlnFieldRelationship_targetFieldToTranslateFromConfig.keySet())  {
            translationFieldRelationshipToSourceField.put(tlnFieldRelationshipFromConfig, tlnFieldRelationship_targetFieldToTranslateFromConfig.get(tlnFieldRelationshipFromConfig));
        }

        Map<String, String> tlnFieldsName_targetFieldToTranslateFromConfig = (Map<String, String>) translationInfoFromConfig.get(TRANSLATION_FIELD_TO_SOURCE_FIELD);
        for(String tlnFieldName : tlnFieldsName_targetFieldToTranslateFromConfig.keySet()) {
            translationFieldToSourceField.put(tlnFieldName, tlnFieldsName_targetFieldToTranslateFromConfig.get(tlnFieldName));
        }

        if(String.isBlank(objectNameTranslationFormulaField)) {
            objectNameTranslationFormulaField = String.valueOf(translationInfoFromConfig.get(OBJ_NAME_TRANSLATION_FORMULA_FIELD));
        }

        objectTranslationMappingConfigFields = (List<TranslationMapping>) translationInfoFromConfig.get(OBJ_TRANSLATION_MAPPING_CONFIG_FIELDS);
        

        translationInfo.put(TRANSLATION_MAP_FIELD_NAME, translationMapFieldNameInObject);
        translationInfo.put(TRANSLATION_MAP_RELATIONSHIP_NAME, translationMapFieldRelationshipInObject);
        translationInfo.put(TRANSLATION_FIELD_AND_RELATIONSHIP_IN_TLM, tlnFieldsNameAndRelationshipInTlm);
        translationInfo.put(TRANSLATION_FORMULA_FIELD_TO_SOURCE_FIELD, translationFormulaFieldToSourceField);
        translationInfo.put(TRANSLATION_FIELD_RELATIONSHIP_TO_SOURCE_FIELD, translationFieldRelationshipToSourceField);
        translationInfo.put(TRANSLATION_FIELD_TO_SOURCE_FIELD, translationFieldToSourceField);
        translationInfo.put(OBJ_NAME_TRANSLATION_FORMULA_FIELD, objectNameTranslationFormulaField);
        translationInfo.put(OBJ_TRANSLATION_FORMULA_FIELDS, objectTranslationFormulaFields);
        translationInfo.put(OBJ_TRANSLATION_MAPPING_CONFIG_FIELDS, objectTranslationMappingConfigFields);

        translationInfoForSObjectMap.put(sobjResult.getName(), translationInfo);
        
        return translationInfo;
    }
    
    /**
     * @description getSObjectTranslationFieldNameForName description
     * @param  sobjResult sobjResult description
     * @return            return description
     */
    public static String getSObjectTranslationFieldNameForName(Schema.DescribeSObjectResult sobjResult) {
        if (REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()) {
            Map<String, Object> translationInfo = getTranslationInfoForSObject(sobjResult);

            return (String) translationInfo.get(OBJ_NAME_TRANSLATION_FORMULA_FIELD);
            
        }

        return null;
    }


    /**
     * @description extract formula to actual formula (without comments) and comments in the formula
     * @param  formula formula description
     * @return         return list of separated string, first element is the actual formula, second onwards is the comments
     */
    public static List<String> extractCommentsFromFormula(String formula) {
        List<String> result = new List<String>();
        Matcher matcher = PATTERN_MULTILINE_COMMMENT.matcher(formula);
        String actualFormula = formula.replaceAll(REGEX_MULTILINE_COMMENT, '').trim();
        result.add(actualFormula);

        while(matcher.find()){
            String comment = matcher.group(1).trim();
            result.add(comment);
        }

        return result;
    }

    /**
     * @description Return true if reduivy__Translated_Name__c is available in object for testing
     * @return Boolean
     */
    public static Boolean canRunTranslationTest() {

        Map<String, Schema.SObjectField> sunFields = SObjectType.reduivy__Study_Unit__c.fields.getMap();

        //patch org doesn't allow us to add fields to the object, hence we will only proceed the test if the field exist e.g., major release test
        return sunFields.containsKey('reduivy__Translated_Name__c') || sunFields.containsKey('Translated_Name__c');
    }

    //=========================================================Translation Method : Formula=============================================
    
    /**
     * @description Translation info map keys - translationMapFieldNameInObject
     */
    public static final String TRANSLATION_MAP_FIELD_NAME = 'translationMapFieldNameInObject';

    /**
     * @description Translation info map keys - translationMapFieldRelationshipInObject
     */
    public static final String TRANSLATION_MAP_RELATIONSHIP_NAME = 'translationMapFieldRelationshipInObject';

    /**
     * @description Translation info map keys - translationFieldAndRelationshipInTranslationMapObject
     */
    public static final String TRANSLATION_FIELD_AND_RELATIONSHIP_IN_TLM = 'translationFieldAndRelationshipInTranslationMapObject';

    /**
     * @description Translation info map keys - translationFormulaFieldToSourceField
     */
    public static final String TRANSLATION_FORMULA_FIELD_TO_SOURCE_FIELD = 'translationFormulaFieldToSourceField';

    /**
     * @description Translation info map keys - translationFieldRelationshipToSourceField
     */
    public static final String TRANSLATION_FIELD_RELATIONSHIP_TO_SOURCE_FIELD = 'translationFieldRelationshipToSourceField';

    /**
     * @description Translation info map keys - translationFieldToSourceField
     */
    public static final String TRANSLATION_FIELD_TO_SOURCE_FIELD = 'translationFieldToSourceField';

    /**
     * @description Translation info map keys - objectNameTranslationFormulaField
     */
    public static final String OBJ_NAME_TRANSLATION_FORMULA_FIELD = 'objectNameTranslationFormulaField';

    /**
     * @description Translation info map keys - objectNameTranslationMappingConfigField
     */
    public static final String OBJ_NAME_TRANSLATION_MAPPING_CONFIG_FIELD = 'objectNameTranslationMappingConfigField';

    /**
     * @description Translation info map keys - objectTranslationFormulaFields
     */
    public static final String OBJ_TRANSLATION_FORMULA_FIELDS = 'objectTranslationFormulaFields';

    /**
     * @description Translation info map keys - objectTranslationMappingConfigFields
     */
    public static final String OBJ_TRANSLATION_MAPPING_CONFIG_FIELDS = 'objectTranslationMappingConfigFields';

    /**
     * @description regex to extract translation field from the formula field
     */
    /**
     * @description regex that matches the string format xxxx.xxxx.xxxx
     */
    public static final String REGEX_3_SEGMENT = '^\\w+\\.\\w+\\.\\w+$';
    public static final String REGEX_MULTILINE_COMMENT = '/\\*([\\s\\S]*?)\\*+/';
    public static final Pattern PATTERN_MULTILINE_COMMMENT = Pattern.compile(REGEX_MULTILINE_COMMENT);
    public static final Pattern PATTERN_MERGESTRING = Pattern.compile(REDU_StringMerge_UTIL.MERGEFIELD_SYNTAX_REGEX);

    /**
     * @description To search and return the translation field for name of an object based on the object prefix provided e.g., SUN = reduivy__Study_Unit__c
     * @param objectPrefixes List of object prefix
     * @return REDU_LightningResponse
     */
    @NamespaceAccessible
    public static Map<String, Object> getTranslationFieldForNameByObjPrefix(List<String> objectPrefixes){

        Map<String, Object> responseData = new Map<String, Object>();

        if (objectPrefixes != null && !objectPrefixes.isEmpty()) {
            for (String objPrefix : objectPrefixes) {
                String trimmedPrefix = objPrefix.trim();
                String objectHelperClass;

                if (trimmedPrefix.length() == 3) {
                    objectHelperClass = trimmedPrefix.toUpperCase() + '_Helper';
                } else {
                    objectHelperClass = trimmedPrefix;
                }

                Type classType = Type.forName(objectHelperClass);
                SObject_Helper sobjHelper;
                
                if (classType != null) {
                    sobjHelper = (SObject_Helper) classType.newInstance();
                }

                if (sobjHelper != null) {
                    String translatedNameField = sobjHelper.getTranslationFieldNameForName();

                    responseData.put(objPrefix, translatedNameField);
                }
            }
        }

        REDU_Logging_UTIL.debugJsonString('getTranslationFieldForNameByObjPrefix', responseData);
        return responseData;
    }
    
    /**
     * @description getTranslationFieldName description
     * @param  field           field. Can be more than one level. eg: reduivy__Contact__r.Name
     * @param  rootSObjectType root sobject type. eg: reduivy__IPE__c
     * @return                 field name. if the field consist of more than 1 level, the path is added automatically. eg:  reduivy__Contact__r.Translated_Name__c
     */
    @NamespaceAccessible
    public static String getTranslationFieldName(String field, Schema.SObjectType rootSObjectType) {
        Schema.SObjectType stmSObjectType = REDU_Metadata_UTIL.getSObjectType(STM_Helper.getApiName());
        Schema.DescribeFieldResult describeFieldResult = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);
        Schema.SObjectType sobjectType = describeFieldResult.getSObjectType();
        if(
            describeFieldResult.getName() == 'Name' || 
            (
                describeFieldResult.getSObjectType() == stmSObjectType && 
                describeFieldResult.getName() == 'reduivy__Display_Name__c'
            )
        ) {

            String translationFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(sobjectType.getDescribe(Schema.SObjectDescribeOptions.DEFERRED));
            if(String.isBlank(translationFieldName)) {
                translationFieldName = describeFieldResult.getName();
            }
            
            //it is possible that the search field is from parent object, so we need to construct the path to the parent field.
            if(describeFieldResult.getType() !== Schema.DisplayType.REFERENCE && field.contains('.')) {
                String relationPath = field.substringBeforeLast('.');
                if(String.isNotBlank(relationPath)) {
                    translationFieldName = relationPath + '.' + translationFieldName;
                }
            }

            return translationFieldName;
        }

        return null;
    }

    
    public static Map<String, String> getTranslationFieldNames(List<String> fields, String rootObjectName){
        try {
            Map<String, String> responseData = new Map<String, String>();
            Schema.SObjectType rootSObjectType = REDU_Metadata_UTIL.getSObjectType(rootObjectName);

            for(String field : new Set<String> (fields)) {
                String translationFieldName = REDU_TranslationManager.getTranslationFieldName(field, rootSObjectType);
                if(String.isNotBlank(translationFieldName)) {
                    responseData.put(field, translationFieldName);
                }
            }

            return responseData;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //==========================================================Translation Method : Custom Metadata===========================================================

    private static Map<String, FormulaEval.FormulaInstance> formulaInstanceMap = new Map<String, FormulaEval.FormulaInstance>();
    private static Map<String, Set<String>> referencedFieldsMap = new Map<String, Set<String>>();
    private static Map<String, String> referencedLanguageFieldMap = new Map<String, String>();
    private static String USER_LANGUAGE_KEY = '{USERLANGUAGE}';

    //translationInfo
    public static String DATATABLE_TRANSLATION_INFO_PARAM = 'translationInfo';

    //translationInfo.records
    public static String RECORDS_PARAM = 'records';

    //translationInfo.translations
    public static String TRANSLATIONS_PARAM = 'translations';

    //translationInfo.translations[0].languageCode
    public static String TRANSLATIONS_LANGUAGECODE_PARAM = 'languageCode';

    //translationInfo.translations[0].configs
    public static String TRANSLATIONS_CONFIGS_PARAM = 'configs';

    //translationInfo.translations[0].configs[0].fields.fieldName
    public static String TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM = 'fieldName';

    //translationInfo.translations[0].configs[0].fields.fieldLabel
    public static String TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM = 'fieldLabel';

    //translationInfo.translations[0].data
    public static String TRANSLATIONS_DATA_PARAM = 'data';

    /**
     * @description Get translation info with record ids
     * @param objectName SObject API name
     * @param recordIds Set of record ids
     * @param fields Set of fields
     * @param language language code
     * @return Map<String, Object>
     */
    global static Map<String, Object> getTranslationInfo(String objectName, Set<Id> recordIds, Set<String> fields, String language) {
        return getTranslationInfo(objectName, new List<Id>( recordIds ), new List<String>(fields), language);
    }
    
    /**
     * @description Get translation info with record list
     * @param objectName SObject API name
     * @param recordList List of records
     * @param fields Set of fields
     * @param language language code
     * @return Map<String, Object>
     */
    global static Map<String, Object> getTranslationInfo(String objectName, List<SObject> recordList, Set<String> fields, String language) {
        return getTranslationInfo(objectName, (new Map<Id, SObject>(recordList)).keySet(), new List<String>(fields), language);
    }

    public static Map<String, Object> getTranslationInfo(String objectName, Set<Id> recordIds, List<String> fields, String language) {
        return getTranslationInfo(objectName, new List<Id>( recordIds ), fields, language);
    }
    
    public static Map<String, Object> getTranslationInfo(String objectName, List<SObject> recordList, List<String> fields, String language) {
        return getTranslationInfo(objectName, (new Map<Id, SObject>(recordList)).keySet(), fields, language);
    }

    /**
     * @description get the translation details of the given fields
     * @param  objectName the root object name
     * @param  recordIds  list of record id
     * @param  fields     list of fields from the root object
     * @param  language   the language to be translated
     * @return Map<String, Object> Records with translated value
     */
    public static Map<String, Object> getTranslationInfo(String objectName, List<String> recordIds, List<String> fields, String language) {
        Map<String, Object> responseData = new Map<String, Object>();

        if(
            String.isNotBlank(objectName) &&
            recordIds != null && !recordIds.isEmpty() &&
            fields != null && !fields.isEmpty() &&
            String.isNotBlank(language) &&
            REDU_AppSetting_UTIL.isRecordValueTranslationEnabled()
        ) {

            // ISS-002797 we convert the hyphen to underscore to match salesforce Apex/formula format.
            language = language.replace('-', '_');

            List<SObject> recordsRaw = new List<SObject>();
            List<Object> translations = new List<Object>();
            Map<String, Map<String, String>> translationsData = new Map<String, Map<String, String>>();
            
            //make sure that the name of the referenced field is always retrieved
            Set<String> fieldsWithRefName = new Set<String>();
            Schema.SObjectType rootSobjType = REDU_Metadata_UTIL.getSObjectType(objectName);
            for(String field : fields) {
                fieldsWithRefName.add(field);
                //might contains tolabel(field__c), and we simply ignore them
                if(field.contains(REDU_Metadata_UTIL.PICKLIST_LABEL)) {
                    continue;
                }
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSobjType);
                fieldToDescribeFieldMap.put(field, fieldDescribe);

                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    String refFieldName = REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true);
                    fieldsWithRefName.add(refFieldName);
                    Schema.DescribeFieldResult refFieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(refFieldName, rootSobjType);
                    fieldToDescribeFieldMap.put(refFieldName, refFieldDescribe);
                }
            }
            
            //ISS-002746 remove the CurrencyIsoCode as we don't think anyone will translate this
            fieldsWithRefName.remove(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);

            //construct the config list in translation object
            List<TranslationConfig> translationConfigList = getFieldConfigs(objectName, fieldsWithRefName);

            //get the translation mapping mdt. all of the mdt with different source object are retrieved for children fields.
            List<TranslationMapping> translationWrapperList = getTranslationMappingConfig();
            Set<String> fieldsToQuery = getTranslationFieldsToQuery(objectName, fieldsWithRefName, translationWrapperList);

            String sobjQuery = 'SELECT ' + String.join(fieldsToQuery, ', ')
                            + ' FROM ' + objectName
                            + ' WHERE Id IN :recordIds';
            Map<String, Object> sobjBindMap = new Map<String, Object>{
                'recordIds' => recordIds
            };

            Map<String, Map<String, Object>> translationInfoMap = new Map<String, Map<String, Object>>();

            for(SObject sobj : Database.queryWithBinds(sobjQuery, sobjBindMap, AccessLevel.USER_MODE)) {
                recordsRaw.add(sobj);
                translationInfoMap = getSObjectTranslationValue(sobj.getPopulatedFieldsAsMap(), fieldsWithRefName, translationWrapperList, translationInfoMap, language);
            }

            translations.add(new Map<String, Object>{
                TRANSLATIONS_LANGUAGECODE_PARAM => language,
                TRANSLATIONS_CONFIGS_PARAM => translationConfigList,
                TRANSLATIONS_DATA_PARAM => translationInfoMap
            });

            responseData.put(RECORDS_PARAM, recordsRaw);
            responseData.put(TRANSLATIONS_PARAM, translations);
        }
        REDU_Logging_UTIL.debugJsonString('translationInfo :: ', responseData);
        return responseData;
    }

    /**
     * @description get the translation fields to be queried. All of the translation field and value defined in the translation mapping mdt should be queried.
     * @param  objectName             the root object name 
     * @param  fields                 all of the fields used
     * @param  translationWrapperList list of translation mapping wrapper. 
     * @return                        return Set<String>
     */
    private static Set<String> getTranslationFieldsToQuery(String objectName, Set<String> fields, List<TranslationMapping> translationWrapperList) {
        Map<String, Map<String, Schema.SObjectField>> sobjectFieldsBySobj = new Map<String, Map<String, Schema.SObjectField>>();
        sobjectFieldsBySobj.put(objectName, REDU_Metadata_UTIL.describeSObject(objectName).fields.getMap());

        Set<String> fieldsToQuery = new Set<String>();
        for(String field : fields) {
            String curRemaining = field;
            Schema.DescribeSObjectResult curParentObject = REDU_Metadata_UTIL.describeSObject(objectName);
            String curPath = '';

            while(String.isNotBlank(curRemaining)) { //go to next field if the current field has reach the end
                
                //this is to get the current child field of the record
                String curChildField = curRemaining.substringBefore('.');
                if(String.isNotBlank(curRemaining.substringAfter('.'))) {
                    if(curChildField.endsWith('__r')) {
                        curChildField = curChildField.removeEnd('__r') + '__c';
                    } else if(!curChildField.endsWith('__c') && !curChildField.endsWith('Id')) {
                        curChildField = curChildField + 'Id';
                    } 
                }

                // loop through all of the translation mapping wrapper
                for(TranslationMapping wrapper : translationWrapperList) {
                    //continue to next translation mapping mdt if the mdt and the field doesnt match
                    if(wrapper.sourceObject != curParentObject.getName() || wrapper.sourceField != curChildField || String.isBlank(wrapper.translationField)) {
                        continue;
                    }
                    //throw error if translation map field not found
                    if(!sobjectFieldsBySobj.get(curParentObject.getName()).containsKey(wrapper.translationField.substringBefore('.').removeEnd('__r') + '__c')) {
                        String errMsg = String.format(Label.Translation_Map_Not_Found, new List<String>{TLM_Helper.getObjectLabel(), curParentObject.getLabel()});
                        throw new REDU_ApplicationException(errMsg);
                    }

                    // construct set of fields to be queried, which are the translation fields referenced in the formula config 
                    for(String translationValueField : wrapper.getReferencedFields()) {
                        String fieldToQuery = curPath + (String.isNotBlank(curPath) ? '.' : '')
                                            + wrapper.translationField.removeEnd('__c') + '__r' + '.'
                                            + translationValueField;
                        fieldsToQuery.add(fieldToQuery);
                    }
                }
                

                curPath = (curPath + (String.isNotBlank(curPath) ? '.' : '') + curRemaining.substringBefore('.'));
                curRemaining = curRemaining.substringAfter('.');
                if(String.isNotBlank(curRemaining)) {
                    
                    //get the parent object name of the current field
                    Schema.DescribeFieldResult curDescribe = sobjectFieldsBySobj.get(curParentObject.getName()).get(curChildField).getDescribe();
                    curParentObject = curDescribe.getReferenceTo()[0].getDescribe(Schema.SObjectDescribeOptions.DEFERRED);

                    if(!sobjectFieldsBySobj.containsKey(curParentObject.getName())) {
                        Map<String, Schema.SObjectField> curParentFieldMap = curParentObject.fields.getMap();
                        sobjectFieldsBySobj.put(curParentObject.getName(), curParentFieldMap);
                    }
                }
            }
        }

        for (String field : fields) {
            if(field.contains(REDU_Metadata_UTIL.PICKLIST_LABEL)) {
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = fieldToDescribeFieldMap.get(field);

            if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                fieldsToQuery.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
            }
        }
        fieldsToQuery.addAll(fields);



        return fieldsToQuery;
    }

    /**
     * @description generate the configs attribute of the translation info
     * @param  objectName the root object name
     * @param  fields     list of field from root object
     * @return            List<TranslationConfig>
     */
    private static List<TranslationConfig> getFieldConfigs(String objectName, Set<String> fields) {
        List<TranslationConfig> wrapperList = new List<TranslationConfig>();
        
        Map<String, Set<String>> fieldsByPath = new Map<String, Set<String>>();

        for (String field : fields) {
            Integer lastDot = field.lastIndexOf('.');
            String path;
            String fieldName;

            if (lastDot == -1) {
                // No relationship path, so key is empty string
                path = '';
                fieldName = field;
            } else {
                // Split into relationship path and field name
                path = field.substring(0, lastDot);
                fieldName = field.substring(lastDot + 1);
            }

            if (!fieldsByPath.containsKey(path)) {
                fieldsByPath.put(path, new Set<String>());
            }
            if(!fieldName.contains(REDU_Metadata_UTIL.PICKLIST_LABEL)) {
                fieldsByPath.get(path).add(fieldName);
            }
        }
        
        Schema.SObjectType sobjectType = REDU_Metadata_UTIL.describeSObject(objectName).getSObjectType();

        for(String path : fieldsByPath.keySet()) {
            String pathEndedWithId = String.isBlank(path) ? 'Id' : path + '.Id';

            //find the sobject of the path
            String sobjectOfPath = REDU_Datatable_UTIL.getFieldDescribe(pathEndedWithId, sObjectType).getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName();
            Map<String, Schema.DescribeFieldResult> describeFieldsMap = REDU_Metadata_UTIL.describeSObjectFields(sobjectOfPath, fieldsByPath.get(path));

            List<Map<String, String>> fieldsInWrapper = new List<Map<String, String>>();
            for(String field : describeFieldsMap.keySet()) {
                Map<String, String> fieldInfo = new Map<String, String>();
                fieldInfo.put(TRANSLATIONS_CONFIGS_FIELDS_FIELDNAME_PARAM, field);
                fieldInfo.put(TRANSLATIONS_CONFIGS_FIELDS_FIELDLABEL_PARAM, describeFieldsMap.get(field).getLabel()); //we can only get label based on user language
                fieldsInWrapper.add(fieldInfo);
            }

            TranslationConfig wrapper = new TranslationConfig(sobjectOfPath, path, fieldsInWrapper);
            wrapperList.add(wrapper);
        }

        return wrapperList;
    }

    /**
     * @description get the translation value of the sobject based on translation mapping wrapper. return map: sobject id => field name => translation value
     * @param  sobjInMap              the sobject in map format
     * @param  fieldPaths             list of field paths to be translated
     * @param  translationWrapperList translation mapping wrapper list
     * @param  translationInfoMap     translation data that have been retrieved
     * @return                        translation data
     */
    private static Map<String, Map<String, Object>> getSObjectTranslationValue(
        Map<String, Object> sobjInMap,
        Set<String> fieldPaths,
        List<TranslationMapping> translationWrapperList,
        Map<String, Map<String, Object>> translationInfoMap,
        String language
    ) {
        
        if (sobjInMap == null || !sobjInMap.containsKey('Id')) {
            return translationInfoMap;
        }

        for (String fieldPath : fieldPaths) {
            List<String> parts = fieldPath.split('\\.');
            // start at top-level map
            Map<String, Object> curSobjInMap = sobjInMap;
            Boolean broken = false;
            
            String curSobjId = String.valueOf(curSobjInMap.get('Id'));
            String curSobjName = Id.valueOf(curSobjId).getSobjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName();
            String finalField = parts[parts.size() - 1];

            //if the translation value for this field has been retrieved, we skip it
            if (translationInfoMap.containsKey(curSobjId) && translationInfoMap.get(curSobjId).containsKey(finalField)) {
                continue;
            }
            
            Object originalValue = curSobjInMap.containsKey(finalField) ? curSobjInMap.get(finalField) : null;
            Object chosenValue = originalValue;

            // Find mapping for this final field
            for (TranslationMapping mapping : translationWrapperList) {
                if (mapping.sourceField == finalField && mapping.sourceObject == curSobjName) {
                    
                    // try to read the constructed translation path from the current map
                    Object transVal = getFieldValueByPath(curSobjInMap, mapping, language);
                    if (transVal != null) {
                        chosenValue = transVal;
                    }

                    // Determine which record Id we should put this translation under:
                    // prefer the Id of the current map (the object that contains finalField), fallback to top-level Id
                    String targetId = null;
                    if (curSobjInMap.containsKey('Id')) {
                        targetId = curSobjId;
                    } else {
                        targetId = (String) sobjInMap.get('Id');
                    }
                    if (String.isBlank(targetId)) {
                        continue;
                    }

                    if (!translationInfoMap.containsKey(targetId)) {
                        translationInfoMap.put(targetId, new Map<String, Object>());
                    }
                    translationInfoMap.get(targetId).put(finalField, chosenValue);
                    
                    break; // we used the mapping for this finalField; stop checking other mappings
                }
            }

            //find children
            for(String fieldInCurSobj : curSobjInMap.keySet()) {
                Object valueOfFieldInCurSobj = curSobjInMap.get(fieldInCurSobj);
                Boolean isInstanceOfSObject = valueOfFieldInCurSobj instanceOf SObject && !(valueOfFieldInCurSobj instanceOf reduivy__Translation_Map__c);
                if(isInstanceOfSObject) {
                    translationInfoMap = getSObjectTranslationValue(
                        ((SObject)valueOfFieldInCurSobj).getPopulatedFieldsAsMap(),
                        new Set<String> {fieldPath},
                        translationWrapperList,
                        translationInfoMap,
                        language
                    );
                }
            }
        }

        return translationInfoMap;
    }

    /**
     * Resolves nested field paths inside a single record map
     */
    private static Object getFieldValueByPath(Map<String, Object> recordMap, TranslationMapping mapping, String language) {
        if (recordMap == null || mapping == null) return null;

        List<String> parts = mapping.translationField.split('\\.');
        reduivy__Translation_Map__c tlm = (reduivy__Translation_Map__c) recordMap.get(parts[0]);
        if(tlm == null) {
            return null;
        }
        Map<String,Object> tlmMap = tlm.getPopulatedFieldsAsMap();
        String tlnRecordName = parts[1].removeEnd('__c') + '__r';
        if(!tlmMap.containsKey(tlnRecordName)) {
            return null;
        }
        reduivy__Translation__c tln = (reduivy__Translation__c) tlmMap.get(tlnRecordName);
        if(tln == null) {
            return null;
        }
        String translatedValue = mapping.getTranslationValue(tln, language);
        
        return translatedValue;
    }

    /**
     * @description the translation info config wrapper class
     * @param sobjectType the sobject name of the root and its parents
     * @param path the path to reach the parent records
     * @param fields fields of the root record and parent records used
     */
    public class TranslationConfig {
        public String sobjectType {get; set;}
        public String path {get; set;}
        public List<Map<String, String>> fields {get; set;}

        public TranslationConfig(String sobjectType, String path, List<Map<String, String>> fields) {
            this.sobjectType = sobjectType;
            this.path = path;
            this.fields = fields;
        }

    }

    /**
     * @description get the translation info of sobject from the translation mapping config
     * @param  sobjResult sobjResult description
     * @return            return description
     */
    public static Map<String, Object> getTranslationInfoFromConfigForSObject(Schema.DescribeSObjectResult sobjResult) {
        
        Map<String, Schema.SObjectField> sobjFieldMap = sobjResult.fields.getMap();

        Map<String, Object> configInfo = new Map<String, Object>();
        
        //track the formula api name that translate the record name
        String objectNameTranslationMappingConfigField = '';

        //track the api name for the translation map lookup field on the sobject
        String translationMapFieldNameInObject = '';
        //track the api relationship name for the translation map lookup field on the sobject
        String translationMapFieldRelationshipInObject = '';

        //track the translation field vs relationship api name in reduivy__Translation_Map__c object e.g., reduivy__Translation_1__c=reduivy__Translation_1__r
        //this is used to query the source records's translation if it is cloned
        Map<String, String> tlnFieldsNameAndRelationshipInTlm = new Map<String, String>();

        //track the translation field relationship api name vs field to be translated e.g., reduivy__Translation_1__r=Name
        //this is used to identify the source records's translation if it is cloned
        Map<String, String> translationFieldRelationshipToSourceField = new Map<String, String>();

        //track the translation field vs field to be translated e.g., reduivy__Translation_1__c=Name
        Map<String, String> translationFieldToSourceField = new Map<String, String>();  
        
        //stores the source field/object and the tranlastion fields in translation map for the source field.
        List<TranslationMapping> objectTranslationMappingConfigFields = new List<TranslationMapping>();

        //the translations for long text starts here
        Map<String, TranslationMapping> translationMapping = getTranslationMappingConfigByObject(sobjResult.getName());

        Map<String, Schema.SObjectField> tlmFieldsMap = Schema.SObjectType.reduivy__Translation_Map__c.fields.getMap();
        for(String translationSourceField : translationMapping.keySet()) {
            TranslationMapping mapping = translationMapping.get(translationSourceField);
            List<String> translationFieldSplitted = mapping.translationField.split('\\.');
            String tlnLookupFieldInTlm = translationFieldSplitted[1];
            if(!tlmFieldsMap.containsKey(tlnLookupFieldInTlm)) {
                String errMsg = String.format(Label.Translation_Not_Found, new List<String> {
                    TLN_Helper.getObjectLabel(), tlnLookupFieldInTlm, TLM_Helper.getObjectLabel()
                });
                throw new REDU_ApplicationException(errMsg);
            }
            Schema.DescribeFieldResult tlnLookupFieldInTlmDfr = tlmFieldsMap.get(tlnLookupFieldInTlm).getDescribe();

            if(mapping.sourceField.endsWithIgnoreCase('Name')) {
                objectNameTranslationMappingConfigField = translationSourceField;
            }

            if(String.isBlank(translationMapFieldNameInObject)) {
                translationMapFieldNameInObject = translationFieldSplitted[0].removeEnd('__r') + '__c';
                if(!sobjFieldMap.containsKey(translationMapFieldNameInObject)) {
                    continue; //skip if no translation map found
                }

                translationMapFieldRelationshipInObject = sobjFieldMap.get(translationMapFieldNameInObject).getDescribe().getRelationshipName();
            }

            tlnFieldsNameAndRelationshipInTlm.put(tlnLookupFieldInTlmDfr.getName(), tlnLookupFieldInTlmDfr.getRelationshipName());
            translationFieldRelationshipToSourceField.put(tlnLookupFieldInTlmDfr.getRelationshipName(), translationSourceField);
            translationFieldToSourceField.put(tlnLookupFieldInTlmDfr.getName(), translationSourceField);

            objectTranslationMappingConfigFields.add(mapping);
        }

        configInfo.put(TRANSLATION_MAP_FIELD_NAME, translationMapFieldNameInObject);
        configInfo.put(TRANSLATION_MAP_RELATIONSHIP_NAME, translationMapFieldRelationshipInObject);
        configInfo.put(TRANSLATION_FIELD_AND_RELATIONSHIP_IN_TLM, tlnFieldsNameAndRelationshipInTlm);
        configInfo.put(TRANSLATION_FIELD_RELATIONSHIP_TO_SOURCE_FIELD, translationFieldRelationshipToSourceField);
        configInfo.put(TRANSLATION_FIELD_TO_SOURCE_FIELD, translationFieldToSourceField);
        configInfo.put(OBJ_NAME_TRANSLATION_MAPPING_CONFIG_FIELD, objectNameTranslationMappingConfigField);
        configInfo.put(OBJ_TRANSLATION_MAPPING_CONFIG_FIELDS, objectTranslationMappingConfigFields);

        return configInfo;
    }

    
    /**
     * @description List of TranslationMapping
     */
    private static List<TranslationMapping> translationMappingConfigs;

    /**
     * @description get a list of Translation mapping wrapper defined in the custom metadata
     * @return   return description
     */
    public static List<TranslationMapping> getTranslationMappingConfig() {
        if(translationMappingConfigs == null) {
            translationMappingConfigs = new List<TranslationMapping>();
            List<reduivy__Translation_Mapping__mdt> configs = reduivy__Translation_Mapping__mdt.getAll().values();

            for(reduivy__Translation_Mapping__mdt config : configs) {
                if(
                    config.reduivy__Active__c && 
                    String.isNotBlank(config.reduivy__Source_Object__c) && 
                    String.isNotBlank(config.reduivy__Source_Field__c) && 
                    String.isNotBlank(config.reduivy__Translation_Field__c) &&
                    String.isNotBlank(config.reduivy__Formula_Config__c)
                ) {
                    translationMappingConfigs.add(new TranslationMapping(config));
                }
            }
        }

        return translationMappingConfigs;
    }

    /**
     * @description Map of source object Name => source field => translation Mapping wrapper
     * @param  objectName objectName description
     * @return            return description
     */
    private static Map<String, Map<String, TranslationMapping>> translationMappingConfigsByObject;

    /**
     * @description get the translation mapping config where the source object is the given object
     * @param  objectName the object name
     * @return            return description
     */
    public static Map<String, TranslationMapping> getTranslationMappingConfigByObject(String objectName) {
        if(translationMappingConfigsByObject == null) {
            translationMappingConfigsByObject = new Map<String, Map<String, TranslationMapping>>();
            getTranslationMappingConfig();

            for(TranslationMapping wrapper : translationMappingConfigs) {

                if(!translationMappingConfigsByObject.containsKey(wrapper.sourceObject)) {
                    translationMappingConfigsByObject.put(wrapper.sourceObject, new Map<String, TranslationMapping>());
                }
                translationMappingConfigsByObject.get(wrapper.sourceObject).put(wrapper.sourceField, wrapper);
                
            }
        }
        if(!translationMappingConfigsByObject.containsKey(objectName)) {
            translationMappingConfigsByObject.put(objectName, new Map<String, TranslationMapping>());
        }

        return translationMappingConfigsByObject.get(objectName);
    }

    private static Map<String, TranslationMapping> translationMappingConfigByField;

    /**
     * @description get the translation mapping config in map. key = {sourceObject}.{sourceField}
     * @return   return description
     */
    public static Map<String, TranslationMapping> getTranslationMappingConfigMap() {
        if(translationMappingConfigByField == null) {

            translationMappingConfigByField = new Map<String, TranslationMapping>();
            
            List<TranslationMapping> translationWrapperList = getTranslationMappingConfig();
            if(translationWrapperList != null && !translationWrapperList.isEmpty()) {
                for(TranslationMapping translationWrapper : translationWrapperList) {
                    String translationWrapperMapKey = translationWrapper.sourceObject + '.' + translationWrapper.sourceField;
                    translationMappingConfigByField.put(translationWrapperMapKey, translationWrapper);
                }
            }
        }

        return translationMappingConfigByField;
    }

    /**
     * @description Map of formula Config id => formula Config
     * @return   Map<Id, String>
     */
    private static Map<Id, String> formulaConfigs;

    /**
     * @description get the map of the formula config id => the formula of the formula config 
     * @return   Map<Id, String>
     */
    public static Map<Id, String> getFormulaConfigMap() {
        if(formulaConfigs == null) {
            List<reduivy__Formula_Config__mdt> configs = reduivy__Formula_Config__mdt.getAll().values();

            formulaConfigs = new Map<Id, String>();
            
            for(reduivy__Formula_Config__mdt config : configs) {
                if(config.reduivy__Active__c && String.isNotBlank(config.reduivy__Formula__c)) {
                    formulaConfigs.put(config.Id, config.reduivy__Formula__c);
                }
            }
        }
            
        return formulaConfigs;
    }

    /**
     * @description get formula in string formula from its formula config id
     * @param  formulaConfigId the formula config metadata id
     * @return                 formula in string
     */
    public static String getFormulaFromConfigId(Id formulaConfigId) {
        return getFormulaConfigMap().get(formulaConfigId);
    }

    /**
     * @description Wrapper to represent the reduivy__Translation_Mapping__mdt record
     * @param sourceObject the object name of the field to be translated
     * @param sourceField the field name of the field to be translated
     * @param translationField the translation field to be used with the tlm.tln format. eg: reduivy__Translation_Map__r.reduivy__Translation_2__c
     * @param formulaString The formula to determine which language field in translation to use. May contains the identifier '{USERLANGUAGE}'
     * @param sourceFieldDescribe field describe of the source field
     */
    @NamespaceAccessible
    public class TranslationMapping {
        public String sourceObject {get; set;}
        public String sourceField {get; set;}
        public String translationField {get; set;}
        public String formulaString {get; set;}
        public Schema.DescribeFieldResult sourceFieldDescribe {get; private set;}
        public Boolean isFormula {get; set;}
        
        /**
         * @description Init translation mapping from custom metadata
         * @param translationMap
         */
        @NamespaceAccessible
        public TranslationMapping(reduivy__Translation_Mapping__mdt translationMap) {
            this.sourceObject = translationMap.reduivy__Source_Object__c;
            this.sourceField = translationMap.reduivy__Source_Field__c;
            this.translationField = translationMap.reduivy__Translation_Field__c;
            this.formulaString = getFormulaFromConfigId(translationMap.reduivy__Formula_Config__c);
            this.sourceFieldDescribe = REDU_Metadata_UTIL.describeSObjectField(this.sourceObject, this.sourceField);
            this.isFormula = false;
        }

        /**
         * @description Init translation mapping from formula field
         */
        @NamespaceAccessible
        public TranslationMapping(String sourceObject, String sourceField, String translationField, String formulaString) {
            this.sourceObject = sourceObject;
            this.sourceField = sourceField;
            this.translationField = translationField;
            this.formulaString = formulaString;
            this.sourceFieldDescribe = REDU_Metadata_UTIL.describeSObjectField(this.sourceObject, this.sourceField);
            this.isFormula = true;
        }

        /**
         * @description get the translated value in translation record based on the language
         * @param  tln      the translation record
         * @param  language the user language from js
         * @return          the translated value
         */
        public String getTranslationValue(reduivy__Translation__c tln, String language){
            if(tln == null || String.isBlank(language)) {
                return null;
            }

            String calculatedValue;
            if (this.isFormula) {
                // if it is already a formula field, return the field value directly to avoid FormulaEval to evaluate the formula of the formula field
                calculatedValue = String.valueOf(tln.get(this.formulaString)) ?? null;
            } else {
                // evaluate the formula config and return the value
                String replacedFormulaString = this.formulaString.replace('{USERLANGUAGE}', language);
                if(!formulaInstanceMap.containsKey(replacedFormulaString)) {
                    FormulaEval.FormulaInstance formulaIns = Formula.builder().withReturnType(FormulaEval.FormulaReturnType.STRING)
                        .withType(reduivy__Translation__c.getSObjectType())
                        .withFormula(replacedFormulaString)
                        .withGlobalVariables(FORMULA_GLOBAL_VARIABLES)
                        .build();

                    formulaInstanceMap.put(replacedFormulaString, formulaIns);
                }

                calculatedValue = String.valueOf(formulaInstanceMap.get(replacedFormulaString).evaluate(tln));
            }

            return calculatedValue;
        }

        /**
         * @description get the referenced fields in the formulaString
         * @return   Set<String>
         */
        public Set<String> getReferencedFields() {
            if(!referencedFieldsMap.containsKey(this.formulaString)) {
                
                FormulaEval.FormulaInstance formulaIns = Formula.builder().withReturnType(FormulaEval.FormulaReturnType.STRING)
                                                        .withType(reduivy__Translation__c.getSObjectType())
                                                        .withFormula(formulaString)
                                                        .build();
                referencedFieldsMap.put(this.formulaString, formulaIns.getReferencedFields());

            }
            return referencedFieldsMap.get(formulaString);
        }

    
        /**
         * @description return the language field of the 
         * @return   return description
         */
        public String getReferencedLanguageField(String language) {
            if(!referencedLanguageFieldMap.containsKey(this.formulaString)) {
                String formulaToFindField = this.formulaString.replace(USER_LANGUAGE_KEY, language);
                for(String referencedField : this.getReferencedFields()) {
                    formulaToFindField = formulaToFindField.replaceAll(referencedField, '"' + referencedField + '"');
                }
                    
                FormulaEval.FormulaInstance formulaIns = Formula.builder().withReturnType(FormulaEval.FormulaReturnType.STRING)
                                                    .withType(reduivy__Translation__c.getSObjectType())
                                                    .withFormula(formulaToFindField)
                                                    .build();
                String languageField = (String) formulaIns.evaluate(new reduivy__Translation__c());
                referencedLanguageFieldMap.put(this.formulaString, languageField); 
                return languageField;
            }
            return referencedLanguageFieldMap.get(this.formulaString);
        }

    }

}
