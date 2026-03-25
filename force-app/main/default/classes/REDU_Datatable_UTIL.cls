/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Util
 * @description Data table metadata util
 * @changehistory
 * ISS-002104 08-11-2024 XW - added inline edit 
 * ISS-002230 23-01-2025 XW - display picklist value label if field type is picklist
 * ISS-002351 25-03-2025 XW - consider clickable link if field is translation name
 * ISS-002495 02-10-2025 XW - support translation for long text
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 * ISS-002746 27-11-2025 Lean - Standardize the CurrencyIsoCode detection
 */
@NamespaceAccessible
public inherited sharing class REDU_Datatable_UTIL {

    /**
     * @description Parameter name for response
     */
    public static final String RECORDS_PARAM = 'records';
    public static final String COLUMNS_PARAM = 'columns';
    public static final String REFLINKS_PARAM = 'refLinks';
    public static final String SITE_PATH_PREFIX_PARAM = ORG_Helper.SITE_PATH_PREFIX_PARAM;

    /**
     * @description For columns metadata, to be displayed in the datatable
     */
    public static final String LABEL_PARAM = 'label';
    public static final String FIELDNAME_PARAM = 'fieldName';
    public static final String TYPE_PARAM = 'type';
    public static final String TYPEATTRIBUTES_PARAM = 'typeAttributes';
    public static final String TOOLTIP_PARAM = 'tooltip';
    public static final String TARGET_PARAM = 'target';
    public static final String SORTABLE_PARAM = 'sortable';
    public static final String INITIALWIDTH_PARAM = 'initialWidth';
    public static final String HIDEDEFAULTACTIONS_PARAM = 'hideDefaultActions';
    public static final String HIDELABEL_PARAM = 'hideLabel';
    public static final String EDITABLE_PARAM = 'editable';
    public static final String WRAPTEXT_PARAM = 'wrapText';

    /**
     * @description For reflink metadata, to be used for the datatable
     */
    public static final String LINKFIELDNAME_PARAM = 'linkFieldName'; // the name used as the fieldName in the columns
    public static final String LINKFIELDVALUE_PARAM = 'linkFieldValue'; // url : the lookup field name of the record to navigate to / value : the value to be displayed
    public static final String LINKFIELDLABEL_PARAM = 'linkFieldLabel'; //The display value of the record in the column
    public static final String LINKFIELDTYPE_PARAM = 'linkFieldType'; //type of the column (url / value)
    public static final String LINKFIELDREFERENCEID_PARAM = 'linkFieldReferenceId'; // the lookup field name of the record to navigate to
    public static final String URL_VAL = 'url';
    public static final String VALUE_VAL = 'value';

    /**
     * @description To be used for table column metadata generation by field string
     */
    private static Map<SObjectType, Map<String, SObjectField>> SOBJ_FIELDS = new Map<SObjectType, Map<String, SObjectField>>();
    private static Map<sObjectType, String> translationNameFields = new Map<sObjectType, String>();
    private static Map<String, REDU_TranslationManager.TranslationMapping> translationWrapperMap = REDU_TranslationManager.getTranslationMappingConfigMap();

    /**
     * @description Generate column metadata (to be used in datatable) json string
     * @param tableColJsonGen JSON generator
     * @param sObjectType SObject type of the fields provided in tableFields
     * @param tableFields String of fields separated by semicolon (;)
     * @param showHelpTextCol Show help text col
     * @param tableActionList Show edit menu
     * @param enableClickableRefField Make reference field clickable to open target record
     * @param hrefTargetType Make url and clickable refererence to open on the same window or new window
     * @param  enableInlineEditing user selection to enable the inline editing
     * @return void
     */
    @NamespaceAccessible
    public static void generateTableColMetadata(JSONGenerator tableColJsonGen, SObjectType sObjectType, String tableFields, boolean showHelpTextCol, List<TableActionWrapper> tableActionList, boolean enableClickableRefField, String hrefTargetType, Boolean enableInlineEditing, Boolean enableWrapText) {
        
        if (String.isBlank(hrefTargetType)) {
            hrefTargetType = '_self';
        }

        //check if CurrencyIsoCode is available
        Boolean hasCurrencyIsoCode = REDU_SObject_UTIL.hasCurrencyIsoCode(sObjectType);
        
        tableColJsonGen.writeStartArray();

        if (showHelpTextCol) {

            //curently we only support adding help text col as the first col in the table
            tableColJsonGen.writeStartObject();
            tableColJsonGen.writeStringField(LABEL_PARAM, '');
            tableColJsonGen.writeNumberField(INITIALWIDTH_PARAM, 20);
            tableColJsonGen.writeStringField(HIDEDEFAULTACTIONS_PARAM, 'true');
            tableColJsonGen.writeStringField(HIDELABEL_PARAM, 'true');
            tableColJsonGen.writeStringField(TYPE_PARAM, 'customHelpTextCol');
            tableColJsonGen.writeFieldName(TYPEATTRIBUTES_PARAM);
                tableColJsonGen.writeStartObject();
                    tableColJsonGen.writeFieldName('content');
                    tableColJsonGen.writeStartObject();
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, 'helpTextColContent');
                    tableColJsonGen.writeEndObject();

                    tableColJsonGen.writeFieldName('iconName');
                    tableColJsonGen.writeStartObject();
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, 'helpTextColIconName');
                    tableColJsonGen.writeEndObject();

                    tableColJsonGen.writeFieldName('iconVariant');
                    tableColJsonGen.writeStartObject();
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, 'helpTextColIconVariant');
                    tableColJsonGen.writeEndObject();

                    tableColJsonGen.writeFieldName('visible');
                    tableColJsonGen.writeStartObject();
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, 'helpTextColIconVisible');
                    tableColJsonGen.writeEndObject();

                tableColJsonGen.writeEndObject();

            tableColJsonGen.writeEndObject();
        }

        for(String field : tableFields.split(';')){
            
            if(field != 'Id'){
                
                Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(field, sObjectType);
                Schema.SObjectType parentSobjType = fieldDescribe.getSObjectType(); 
                if(!translationNameFields.containsKey(parentSobjType)) {
                    translationNameFields.put(parentSobjType, getTranslationName(parentSobjType));
                }
                String translationName = translationNameFields.get(parentSobjType);

                String translationWrapperKey = fieldDescribe.getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName() + '.' + fieldDescribe.getName();

                //this is the field that stores the translation value of the source field in the datatable. if no translation is found, the original field is used.

                Boolean isTranslation;
                
                if((translationWrapperMap != null && translationWrapperMap.containsKey(translationWrapperKey))) {
                    isTranslation = true;
                } else {
                    isTranslation = false;
                }

                Boolean canInlineEdit = canInlineEdit(enableInlineEditing, fieldDescribe.isCalculated(), isTranslation);
                
                tableColJsonGen.writeStartObject();

                //Need to consider clickable link if this is an reference or name (either 'Name' or translation name) field
                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE || fieldDescribe.getName() == translationName || fieldDescribe.getName() == 'Name'){

                    String refLinkField;

                    if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE){

                        refLinkField = REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true);

                    }else{

                        refLinkField = field;
                    }
                    
                    if(enableClickableRefField){
                        
                        tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                        tableColJsonGen.writeStringField(FIELDNAME_PARAM, 'link' + field);
                        tableColJsonGen.writeStringField(TYPE_PARAM , 'url');
                        tableColJsonGen.writeFieldName(TYPEATTRIBUTES_PARAM);
                            tableColJsonGen.writeStartObject();
                                tableColJsonGen.writeFieldName(TOOLTIP_PARAM);
                                    tableColJsonGen.writeStartObject();
                                        tableColJsonGen.writeStringField(FIELDNAME_PARAM, refLinkField);
                                    tableColJsonGen.writeEndObject();
                                tableColJsonGen.writeFieldName(LABEL_PARAM); 
                                    tableColJsonGen.writeStartObject();
                                        tableColJsonGen.writeStringField(FIELDNAME_PARAM, refLinkField);
                                    tableColJsonGen.writeEndObject();
                                tableColJsonGen.writeStringField(TARGET_PARAM, hrefTargetType);
                            tableColJsonGen.writeEndObject();
                        tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                        tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                        tableColJsonGen.writeEndObject();
                        
                    } else {
                        
                        tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                        tableColJsonGen.writeStringField(FIELDNAME_PARAM, refLinkField);
                        tableColJsonGen.writeStringField(TYPE_PARAM , 'text');
                        tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                        tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                        tableColJsonGen.writeEndObject();
                    }

                }else if (fieldDescribe.getType() == Schema.DisplayType.INTEGER || fieldDescribe.getType() == Schema.DisplayType.DOUBLE || fieldDescribe.getType() == Schema.DisplayType.LONG) {
                    
                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'number');
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeFieldName('cellAttributes');
                        tableColJsonGen.writeStartObject();
                            tableColJsonGen.writeStringField('alignment', 'left');
                        tableColJsonGen.writeEndObject();
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                    tableColJsonGen.writeEndObject();     

                } else if (fieldDescribe.getType() == Schema.DisplayType.CURRENCY) {
                    
                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'currency');
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeFieldName('cellAttributes');
                        tableColJsonGen.writeStartObject();
                            tableColJsonGen.writeStringField('alignment', 'left');
                        tableColJsonGen.writeEndObject();
                    tableColJsonGen.writeFieldName(TYPEATTRIBUTES_PARAM);
                        tableColJsonGen.writeStartObject();

                            //add the CurrencyIsoCode if the field is available
                            if (hasCurrencyIsoCode) {
                                tableColJsonGen.writeFieldName('currencyCode');
                                tableColJsonGen.writeStartObject();
                                    //we will take the default CurrencyIsoCode from the record, it is not available, sf will fallback to the user or org currency
                                    tableColJsonGen.writeStringField('fieldName', REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);
                                tableColJsonGen.writeEndObject();
                            }

                        tableColJsonGen.writeEndObject();
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                    tableColJsonGen.writeEndObject();

                } else if (fieldDescribe.getType() == Schema.DisplayType.BOOLEAN) {

                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'boolean');
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeEndObject();

                } else if (fieldDescribe.getType() == Schema.DisplayType.EMAIL) {
                    
                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'email');
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                    tableColJsonGen.writeEndObject();

                } else if (fieldDescribe.getType() == Schema.DisplayType.PHONE) {

                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'phone');
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                    tableColJsonGen.writeEndObject();

                } else if (fieldDescribe.getType() == Schema.DisplayType.URL) {
                    
                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'url');
                    tableColJsonGen.writeFieldName(TYPEATTRIBUTES_PARAM);
                        tableColJsonGen.writeStartObject();
                            tableColJsonGen.writeStringField(TARGET_PARAM, hrefTargetType);
                        tableColJsonGen.writeEndObject();
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                    tableColJsonGen.writeEndObject();

                } else if (fieldDescribe.getType() == Schema.DisplayType.PERCENT) {

                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'percent');
                    tableColJsonGen.writeFieldName(TYPEATTRIBUTES_PARAM);
                        tableColJsonGen.writeStartObject();
                            tableColJsonGen.writeStringField('maximumFractionDigits', '4');
                        tableColJsonGen.writeEndObject();
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeFieldName('cellAttributes');
                        tableColJsonGen.writeStartObject();
                            tableColJsonGen.writeStringField('alignment', 'left');
                        tableColJsonGen.writeEndObject();
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                    tableColJsonGen.writeEndObject();

                } else if (fieldDescribe.getType() == Schema.DisplayType.DATE) {
                    
                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'date');
                    tableColJsonGen.writeFieldName(TYPEATTRIBUTES_PARAM);
                        tableColJsonGen.writeStartObject();
                            tableColJsonGen.writeStringField('day', 'numeric');
                            tableColJsonGen.writeStringField('month', 'numeric');
                            tableColJsonGen.writeStringField('year', 'numeric');
                            tableColJsonGen.writeStringField('timeZone', 'UTC');
                        tableColJsonGen.writeEndObject();
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeEndObject();

                } else if (fieldDescribe.getType() == Schema.DisplayType.DATETIME) {
                    
                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'date');
                    tableColJsonGen.writeFieldName(TYPEATTRIBUTES_PARAM);
                        tableColJsonGen.writeStartObject();
                            tableColJsonGen.writeStringField('day', 'numeric');
                            tableColJsonGen.writeStringField('month', 'numeric');
                            tableColJsonGen.writeStringField('year', 'numeric');
                            tableColJsonGen.writeStringField('hour', 'numeric');
                            tableColJsonGen.writeStringField('minute', '2-digit');
                            tableColJsonGen.writeStringField('timeZone', UserInfo.getTimeZone().getID());
                        tableColJsonGen.writeEndObject();
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeEndObject();
                    
                } else if (fieldDescribe.isHtmlFormatted() || fieldDescribe.getType() == Schema.DisplayType.TEXTAREA) {
                    
                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'customRichTextCol');
                    tableColJsonGen.writeFieldName(TYPEATTRIBUTES_PARAM);
                        tableColJsonGen.writeStartObject();
                            tableColJsonGen.writeFieldName('value');
                                tableColJsonGen.writeStartObject();
                                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                                tableColJsonGen.writeEndObject();
                        tableColJsonGen.writeEndObject();
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                    tableColJsonGen.writeEndObject();
                
                } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {

                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, REDU_Metadata_UTIL.getPicklistLabelFieldName(field));
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'text');
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                    tableColJsonGen.writeEndObject();

                }
                else {
                    
                    tableColJsonGen.writeStringField(LABEL_PARAM, fieldDescribe.getLabel());
                    tableColJsonGen.writeStringField(FIELDNAME_PARAM, field);
                    tableColJsonGen.writeStringField(TYPE_PARAM , 'text');
                    tableColJsonGen.writeBooleanField(SORTABLE_PARAM, true);
                    tableColJsonGen.writeBooleanField(EDITABLE_PARAM, canInlineEdit);
                    tableColJsonGen.writeBooleanField(WRAPTEXT_PARAM, enableWrapText);
                    tableColJsonGen.writeEndObject();
                }
            }
        }

        if (tableActionList != null && !tableActionList.isEmpty()) {

            tableColJsonGen.writeStartObject();
            tableColJsonGen.writeStringField(TYPE_PARAM, 'action');
            tableColJsonGen.writeFieldName(TYPEATTRIBUTES_PARAM);
                tableColJsonGen.writeStartObject();
                    tableColJsonGen.writeFieldName('rowActions');
                    tableColJsonGen.writeStartArray();

                        for(TableActionWrapper tableAction : tableActionList){

                            tableColJsonGen.writeStartObject();
                            tableColJsonGen.writeStringField(LABEL_PARAM, tableAction.actionLabel);
                            tableColJsonGen.writeStringField('name', tableAction.actionName);
                            tableColJsonGen.writeEndObject();
                        }
                    tableColJsonGen.writeEndArray();
                tableColJsonGen.writeEndObject();

            tableColJsonGen.writeEndObject();
        }

        tableColJsonGen.writeEndArray();

    }

    /**
     * @description Get DescribeFieldResult based on the field API
     * @param fieldPath API Name of the field
     * @param sObjectType SObject type of the fields provided in tableFields
     * @return Schema.DescribeFieldResult
     */
    @NamespaceAccessible
    public static Schema.DescribeFieldResult getFieldDescribe(String fieldPath, SObjectType sObjectType){

        if (sObjectType == null || String.isBlank(fieldPath)){
            return null;
        } 

        if (!SOBJ_FIELDS.containsKey(sObjectType)){
            SOBJ_FIELDS.put(sObjectType, sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap());
        }

        if(!fieldPath.contains('.')){
            return SOBJ_FIELDS.get(sObjectType).get(fieldPath).getDescribe();
        } 

        //If the fieldPath is refering to parent with "__r", process again to reach the last field
        SObjectField field = SOBJ_FIELDS.get(sObjectType).get(getParentFieldPath(fieldPath.substringBefore('.')));
        if (field == null){
            return null;
        } 

        SObjectType parentType = field.getDescribe().getReferenceTo()[0];
        return getFieldDescribe(fieldPath.substringAfter('.'), parentType);

    }

    /**
     * @description Replace reference field (__r) to (__c)
     * @param fieldName
     * @return String
     */
    @NamespaceAccessible
    public static String getParentFieldPath(String fieldName) {
        if (String.isBlank(fieldName)){
            return null;
        }else{
            return fieldName.endsWith('__r') ? fieldName.removeEnd('__r') + '__c' : fieldName + 'Id';
        }
    }

    /**
     * @description Generate ref links metadata for datatable
     * @param refLinkJsonGen JSON generator
     * @param rootSObjectType SObjectType
     * @param tableFields String of fields separated by semicolon (;)
     * @return void
     */
    @NamespaceAccessible
    public static void generateRefLinksMetadata(JSONGenerator refLinkJsonGen, SObjectType rootSObjectType, String tableFields) {

        refLinkJsonGen.writeStartArray();

        for(String field : tableFields.split(';')){
            
            if(field != 'Id'){
                
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);
                Schema.SObjectType childSObjType = fieldDescribe.getSObjectType(); 
                String translationName = getTranslationName(childSObjType);

                String translationWrapperKey = fieldDescribe.getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName() + '.' + fieldDescribe.getName();

                
                String referenceRecordId;
                String fieldPath = field.substringBeforeLast('.');
                if(fieldPath.endsWith('__r')) {
                    referenceRecordId = fieldPath.removeEnd('__r') + '__c';
                } else if(fieldPath.endsWith('__c') || fieldPath.endsWith('Id')) {
                    referenceRecordId = fieldPath;
                } else { 
                    referenceRecordId = fieldPath + 'Id';
                }

                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE || fieldDescribe.getName() == 'Name' || fieldDescribe.getName() == translationName){

                    String fieldValue;
                    if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                        fieldValue = field;
                    } else if(field.contains('.')) {
                        fieldValue = referenceRecordId;
                    } else {
                        fieldValue = 'Id';
                    }
                    refLinkJsonGen.writeStartObject();
                    refLinkJsonGen.writeStringField(LINKFIELDNAME_PARAM, 'link' + field);
                    refLinkJsonGen.writeStringField(LINKFIELDVALUE_PARAM, fieldValue);
                    refLinkJsonGen.writeStringField(LINKFIELDLABEL_PARAM, (fieldDescribe.getName() == translationName || fieldDescribe.getName() == 'Name' ? field : REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true)));
                    refLinkJsonGen.writeStringField(LINKFIELDTYPE_PARAM, URL_VAL);
                    refLinkJsonGen.writeStringField(LINKFIELDREFERENCEID_PARAM, fieldValue);
                    refLinkJsonGen.writeEndObject();

                } else if(field.contains('.')){

                    refLinkJsonGen.writeStartObject();
                    refLinkJsonGen.writeStringField(LINKFIELDNAME_PARAM, field);
                    refLinkJsonGen.writeStringField(LINKFIELDVALUE_PARAM, field);
                    refLinkJsonGen.writeStringField(LINKFIELDLABEL_PARAM, field);
                    refLinkJsonGen.writeStringField(LINKFIELDTYPE_PARAM, VALUE_VAL);
                    refLinkJsonGen.writeStringField(LINKFIELDREFERENCEID_PARAM, referenceRecordId);
                    refLinkJsonGen.writeEndObject();

                    //if it is a picklist/multipicklist, we add another ref link here so that we can extract the picklist label in js
                    if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        String formattedFieldName = REDU_Metadata_UTIL.getPicklistLabelFieldName(field);
                        refLinkJsonGen.writeStartObject();
                        refLinkJsonGen.writeStringField(LINKFIELDNAME_PARAM, formattedFieldName);
                        refLinkJsonGen.writeStringField(LINKFIELDVALUE_PARAM, formattedFieldName);
                        refLinkJsonGen.writeStringField(LINKFIELDLABEL_PARAM, formattedFieldName);
                        refLinkJsonGen.writeStringField(LINKFIELDTYPE_PARAM, VALUE_VAL);
                        refLinkJsonGen.writeStringField(LINKFIELDREFERENCEID_PARAM, referenceRecordId);
                        refLinkJsonGen.writeEndObject();
                    }
                    
                } else if (translationWrapperMap.containsKey(translationWrapperKey)) {
                    refLinkJsonGen.writeStartObject();
                    refLinkJsonGen.writeStringField(LINKFIELDNAME_PARAM, field);
                    refLinkJsonGen.writeStringField(LINKFIELDVALUE_PARAM, field);
                    refLinkJsonGen.writeStringField(LINKFIELDLABEL_PARAM, field);
                    refLinkJsonGen.writeStringField(LINKFIELDTYPE_PARAM, VALUE_VAL);
                    refLinkJsonGen.writeStringField(LINKFIELDREFERENCEID_PARAM, 'Id');
                    refLinkJsonGen.writeEndObject();
                }
            }
        }

        refLinkJsonGen.writeEndArray();
    }

    /**
    * @description get the field api name of the sobject type translation name
    * @param  childSObjType the child sobject type
    * @return               return translation name field api name
    */
    private static String getTranslationName(Schema.SObjectType childSObjType) {

        if(!translationNameFields.containsKey(childSObjType)) {
            String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(childSObjType.getDescribe(SObjectDescribeOptions.DEFERRED));
            if(String.isBlank(formulaFieldName)){
                formulaFieldName = 'Name';
            }
            translationNameFields.put(childSObjType, formulaFieldName);
            return formulaFieldName;
        }
        return translationNameFields.get(childSObjType);

    }

    /**
     * @description return true if the column is inline editable based on conditions
     * @param  enableInlineEdit The user selection
     * @param  isFormula        True if the field is formula field
     * @param  isTranslation    True if the field has translation value
     * @return                  Boolean
     */
    private static Boolean canInlineEdit(Boolean enableInlineEdit, Boolean isFormula, Boolean isTranslation) {
        return enableInlineEdit && !isFormula && !isTranslation;
    }

    // This is wrapper for the action in data table.
    @NamespaceAccessible
    public class TableActionWrapper{

        public String actionLabel {get;set;}
        public String actionName {get;set;}

        @NamespaceAccessible
        public TableActionWrapper(String actionLabel, String actionName){

            this.actionLabel = actionLabel;
            this.actionName = actionName;
        }

    }
}