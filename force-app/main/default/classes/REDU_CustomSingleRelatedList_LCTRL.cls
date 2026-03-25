/**
 * @author      WDCi (XW)
 * @date        Nov 2024
 * @group       Custom Single Related List
 * @description Custom Single Related List Controller
 * @changehistory
 * ISS-002104 05-11-2024 XW - create new class
 * ISS-002230 22-01-2025 XW - get picklist value label if field type is picklist
 * ISS-002351 26-03-2025 XW - support parent record querying
 * ISS-002410 14-04-2025 XiRouh - Replaced isSet with != null
 * ISS-002603 12-09-2025 Lean - Support current user system var
 * ISS-002495 23-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 * ISS-002746 27-11-2025 Lean - Standardize the CurrencyIsoCode detection
 */
public with sharing class REDU_CustomSingleRelatedList_LCTRL {
    
    //default
    private static final Integer DEFAULT_ROWS_TO_LOAD = 10;
    private static final Integer DEFAULT_OFFSET = 0;
    private static final String DEFAULT_ANONYMIZED_STRING = '********';

    //for request
    public static final String RECORD_ID_PARAM = 'recordId';
    public static final String TARGET_RECORD_ID_PARAM = 'targetRecordIdField';
    public static final String PARENT_OBJECT_REF_FIELD_PARAM = 'parentObjectRefField';
    public static final String CHILD_OBJECT_API_NAME_PARAM = 'childObjectApiName';
    public static final String CHILD_OBJECT_FIELDS_PARAM = 'childObjectFields';
    public static final String CHILD_OBJECT_FILTER_CRITERIA_PARAM = 'childObjectFilterCriteria';
    public static final String ENABLE_VIEW_PARAM = 'enableRowViewButton';
    public static final String ENABLE_EDIT_PARAM = 'enableRowEditButton';
    public static final String ENABLE_DELETE_PARAM = 'enableRowDeleteButton';
    public static final String ENABLE_DOWNLOAD_PARAM = 'enableRowDownloadButton';
    public static final String REFERENCE_TARGET = 'refTarget';

    public static final String ROWS_TO_LOAD_PARAM = 'rowsToLoad';
    public static final String CURRENT_OFFSET_PARAM = 'currentOffset';

    public static final String ENABLE_CLICKABLE_REFFIELD_PARAM = 'enableClickableRefField';

    public static final String ENABLE_INLINE_EDIT_PARAM = 'enableInlineEditing';
    public static final String USE_SOURCE_COLLECTION_RECORDS = 'useSourceCollectionRecords';
    public static final String LANGUAGE_PARAM = 'language';

    public static final String WRAPTEXT_PARAM = 'wrapText';

    //for response
    public static final String COLUMNS_PARAM = 'columns';
    public static final String RECORDS_PARAM = 'records';
    public static final String TRANSLATION_INFO_PARAM = REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM;
    public static final String OBJECT_ICON_PARAM = 'objectIcon';
    public static final String REFLINKS_PARAM = 'refLinks';
    public static final String IS_COMMUNITY_PARAM = 'isCommunity';
    public static final String SITE_PATH_PARAM = 'sitePath';
    public static final String BASE_URL_PARAM = 'baseURL';

    /**
     * @description User id variable = {USERID}
     */
    public static final String USERID_VAR = '{USERID}';

    /**
     * @description User contact id variable = {USERCONTACTID}
     */
    public static final String USERCONTACTID_VAR = '{USERCONTACTID}';

    //get the data needed (records, columns, icon etc)
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse initDatatable(String datatableConfig){
        try {
            REDU_Logging_UTIL.debug('datatableConfig', datatableConfig);
            Map<String, Object> requestJSON = (Map<String, Object>)JSON.deserializeUntyped(datatableConfig);  
            Map<String, Object> responseJSON = new Map<String, Object>();

            String recordId = String.valueOf(requestJSON.get(RECORD_ID_PARAM));
            String targetRecordIdField = String.valueOf(requestJSON.get(TARGET_RECORD_ID_PARAM));
            String parentObjRefField = String.valueOf(requestJSON.get(PARENT_OBJECT_REF_FIELD_PARAM));
            String childObjName = String.valueOf(requestJSON.get(CHILD_OBJECT_API_NAME_PARAM));
            String childObjFields = String.valueOf(requestJSON.get(CHILD_OBJECT_FIELDS_PARAM));
            String childObjFilter = String.valueOf(requestJSON.get(CHILD_OBJECT_FILTER_CRITERIA_PARAM));
            Integer rowsToLoad = Integer.valueOf(requestJSON.get(ROWS_TO_LOAD_PARAM));
            Integer currentOffSet = Integer.valueOf(requestJSON.get(CURRENT_OFFSET_PARAM));
            
            Boolean enableView = Boolean.valueOf(requestJSON.get(ENABLE_VIEW_PARAM));
            Boolean enableEdit = Boolean.valueOf(requestJSON.get(ENABLE_EDIT_PARAM));
            Boolean enableDelete = Boolean.valueOf(requestJSON.get(ENABLE_DELETE_PARAM));
            Boolean enableDownload = Boolean.valueOf(requestJSON.get(ENABLE_DOWNLOAD_PARAM));
            Boolean enableWrapText = Boolean.valueOf(requestJSON.get(WRAPTEXT_PARAM));
            
            Boolean enableClickableRefField = Boolean.valueOf(requestJSON.get(ENABLE_CLICKABLE_REFFIELD_PARAM));
            
            Boolean enableInlineEditing = Boolean.valueOf(requestJSON.get(ENABLE_INLINE_EDIT_PARAM));
            
            String refTarget = String.valueOf(requestJSON.get(REFERENCE_TARGET));
            
            Boolean useSourceCollectionRecords = Boolean.valueOf(requestJSON.get(USE_SOURCE_COLLECTION_RECORDS));
            String language = requestJSON.containsKey(LANGUAGE_PARAM) ? String.valueOf(requestJSON.get(LANGUAGE_PARAM)) : UserInfo.getLanguage();
            
            //ISS-002603 support system vars
            if (String.isNotBlank(recordId)) {
                if (recordId == USERID_VAR) {
                    recordId = UserInfo.getUserId();
                } else if (recordId == USERCONTACTID_VAR) {
                    recordId = USR_Helper.getCurrentUserInfo(UserInfo.getUserId())?.ContactId;
                }
            }

            if(String.isNotBlank(recordId) || useSourceCollectionRecords) {
                
                List<SObject> data;
                //if the records are retrieved from flow, we can skip the query
                if(!useSourceCollectionRecords){
                    //get parent Id
                    String parentId = getTargetParentId(recordId,targetRecordIdField);

                    //get child record
                    data = getChildRecords(parentId, parentObjRefField, childObjName, childObjFields, childObjFilter, rowsToLoad, currentOffSet);
                    
                    REDU_Logging_UTIL.debugJsonString('data', data);
                }

                //generate columns
                JSONGenerator jsonGenColumns = generateTableColMetadata(childObjName, childObjFields, enableView, enableEdit, enableDelete, enableDownload, enableClickableRefField, refTarget, enableInlineEditing, enableWrapText);
                REDU_Logging_UTIL.debug('columns', jsonGenColumns.getAsString());
                
                //reference link (to display name if the field is REFERENCE)
                JSONGenerator jsonGenRefLinks = JSON.createGenerator(true);
                Schema.DescribeSObjectResult childObjectDescribe = REDU_Metadata_UTIL.describeSObject(childObjName);
                REDU_Datatable_UTIL.generateRefLinksMetadata(jsonGenRefLinks, childObjectDescribe.getSObjectType(), childObjFields);
                String refLinks = jsonGenRefLinks.getAsString();
                REDU_Logging_UTIL.debug('refLinks', refLinks);
                
                //get child object icon
                String childObjectIcon = REDU_Metadata_UTIL.getObjectIcon(childObjName);
                REDU_Logging_UTIL.debug('childObjectIcon', childObjectIcon);

                Map<String, Object> communityInfo = ORG_Helper.getCommunityInfo();

                if(!useSourceCollectionRecords){
                    responseJSON.put(RECORDS_PARAM, JSON.serialize(data));
                    responseJSON.put(CURRENT_OFFSET_PARAM, currentOffSet + data.size());
                    responseJSON.put(TRANSLATION_INFO_PARAM, REDU_TranslationManager.getTranslationInfo(childObjName, data, childObjFields.split(REDU_List_UTIL.DELIMITER), language));
                }
                responseJSON.put(COLUMNS_PARAM, JSON.deserializeUntyped(jsonGenColumns.getAsString()));
                responseJSON.put(OBJECT_ICON_PARAM, childObjectIcon);
                responseJSON.put(REFLINKS_PARAM, JSON.deserializeUntyped(refLinks));
                responseJSON.put(IS_COMMUNITY_PARAM, ORG_Helper.isCommunity());
                responseJSON.put(SITE_PATH_PARAM, ORG_Helper.getCurrentCommunitySitePath());
                responseJSON.put(ORG_Helper.SITE_PATH_PREFIX_PARAM, communityInfo.get(ORG_Helper.SITE_PATH_PREFIX_PARAM));

                if (ORG_Helper.isCommunity()) {
                    responseJSON.put(BASE_URL_PARAM, communityInfo.get(ORG_Helper.SITE_BASE_URL_PARAM));
                } else {
                    responseJSON.put(BASE_URL_PARAM, URL.getOrgDomainUrl().toExternalForm());
                }
            }

            return new REDU_LightningResponse(true, 'success', JSON.serialize(responseJSON));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    //generate columns used in datatable
    private static JSONGenerator generateTableColMetadata(String childObjName, String childObjFields, Boolean enableView, Boolean enableEdit, Boolean enableDelete, Boolean enableDownload, Boolean enableClickableRefField, String refTarget, Boolean enableInlineEdit, Boolean enableWrapText){
        JSONGenerator jsonGenColumns = JSON.createGenerator(true);
        SObjectType childSObjectType = REDU_Metadata_UTIL.getSObjectType(childObjName);

        //generate columns metadata used in the custom type datatable
        List<REDU_Datatable_UTIL.TableActionWrapper> tableActionWrapper = new List<REDU_Datatable_UTIL.TableActionWrapper>();

        if(enableView){
            tableActionWrapper.add(new REDU_Datatable_UTIL.TableActionWrapper(Label.View,'view'));
        } 
        if(enableEdit){
            tableActionWrapper.add(new REDU_Datatable_UTIL.TableActionWrapper(Label.Edit,'edit'));
        } 
        if(enableDelete){
            tableActionWrapper.add(new REDU_Datatable_UTIL.TableActionWrapper(Label.Delete,'delete'));
        } 
        if(enableDownload && childObjName == 'ContentVersion'){
            tableActionWrapper.add(new REDU_Datatable_UTIL.TableActionWrapper(Label.Download,'download'));
        } 
        REDU_Datatable_UTIL.generateTableColMetadata(jsonGenColumns, childSObjectType, childObjFields, false, tableActionWrapper, enableClickableRefField, refTarget, enableInlineEdit, enableWrapText);

        return jsonGenColumns;
    }
    
    //get the records of the child objects, either refresh or add more data
    private static List<SObject> getChildRecords(String parentId, String parentObjRefField, String childObjName, String childObjFields, String childObjFilter, integer rowsToLoad, integer currentOffSet) {
        List<String> objsToDescribe = new List<String>{childObjName};
        Set<String> fieldsToQuery = new Set<String>{};
        List<String> childObjFieldsList = childObjFields.split(';');
        //List<REDU_DynamicFieldValue_OBJ> fields = REDU_Metadata_UTIL.getFieldSetMembers(childObjName, childObjFieldsetName);
        //Map<String, Schema.DescribeFieldResult> fields = REDU_Metadata_UTIL.describeSObjectFields(childObjName, childObjFieldsList);
        Map<String, Schema.DisplayType> fieldToFieldTypeMap = new Map<String, Schema.DisplayType>();
        Schema.SObjectType childType = REDU_Metadata_UTIL.describeSObject(childObjName).getSObjectType();

        rowsToLoad = (rowsToLoad != null ? rowsToLoad : DEFAULT_ROWS_TO_LOAD);
        currentOffSet = (currentOffSet != null ? currentOffSet : DEFAULT_OFFSET);

        for(String fieldName : childObjFieldsList){
            Schema.DescribeFieldResult field = REDU_Datatable_UTIL.getFieldDescribe(fieldName, childType);
            if(field.getName() != 'Id'){
                        
                if(field.getType() == Schema.DisplayType.REFERENCE){
                    //we also query the name for relationship field
                    fieldsToQuery.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field.getName(), true));
                }

                fieldsToQuery.add(fieldName);

                //we also avoiding percent formula field as it can't be set in sobject
                if (field.getType() == Schema.DisplayType.ENCRYPTEDSTRING ||
                    field.getType() == Schema.DisplayType.TIME || 
                    (
                        field.getType() == Schema.DisplayType.PERCENT && !field.isCalculated()
                    )){
                    fieldToFieldTypeMap.put(field.getName(), field.getType());
                }

                else if (field.getType() == Schema.DisplayType.PICKLIST || field.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    fieldsToQuery.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field.getName()));
                }
            }
        }

        //ContentVersion logic
        if(childObjName == 'ContentVersion' && !fieldsToQuery.contains('ContentDocumentId')){
            fieldsToQuery.add('ContentDocumentId');
        }

        //Add CurrencyIsoCode to query so that we can display the correct symbol
        if (REDU_SObject_UTIL.hasCurrencyIsoCode(childType)) {
            fieldsToQuery.add(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);
        }

        //Declaring map of string vs object which is used in forming dynamic soql query.
        Map<String, Object> varBindMap = new Map<String, Object>();
        
        String soqlStr = 'SELECT ' + String.join(fieldsToQuery,', ') + ' FROM ' + childObjName + ' WHERE ';
        
        //ContentVersion logic
        Set<String> cdIds = new Set<String>();
        if(childObjName == 'ContentVersion'){
            for(ContentDocumentLink cdl : [SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId =: parentId
                WITH USER_MODE
            ]){
                cdIds.add(cdl.ContentDocumentId);
            }

            soqlStr += ' ContentDocumentId IN: cdIds ';
            varBindMap.put('cdIds', cdIds);
        } else {
            soqlStr += parentObjRefField + ' =: parentId';
            varBindMap.put('parentId', parentId);
        }

        //we only perform query if there parent id and offset is less than 2000
        if(String.isNotBlank(parentId) && currentOffSet <= 2000){
            if(String.isNotBlank(childObjFilter)){
                soqlStr += ' AND (' + childObjFilter + ')';
            }

            soqlStr += (' LIMIT ' + rowsToLoad + ' OFFSET ' + currentOffSet);

            REDU_Logging_UTIL.debug('soql :: ', soqlStr);

            List<SObject> results = Database.queryWithBinds(soqlStr, varBindMap, AccessLevel.USER_MODE);

            results = parseSpecificFieldTypes(results, fieldToFieldTypeMap);

            return results;
        } else {
            return new List<SObject>();
        }
    }

    //get the parent id
    private static String getTargetParentId(String recordId, String targetRecordIdField){

        String parentId = '';

        if(targetRecordIdField.equalsIgnoreCase('id')){
            parentId = recordId;
        } else {
            Id idObj = Id.valueOf(recordId);
            String idObjType = idObj.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName();

            String query = 'SELECT Id, ' + targetRecordIdField +
                            ' FROM ' + idObjType +
                            ' WHERE Id = :recordId';

            REDU_Logging_UTIL.debug('query', query);
            Map<String, Object> bindMap = new Map<String, Object>();
            bindMap.put('recordId', recordId);
            SObject currentRecord = Database.queryWithBinds(query, bindMap, AccessLevel.USER_MODE);

            if(currentRecord.get(targetRecordIdField) != null){
                parentId = String.valueOf(currentRecord.get(targetRecordIdField));
            }
    
        }

        return parentId;
    }


    //This method will edit the sobject data to be displayable
    private static List<SObject> parseSpecificFieldTypes(List<Sobject> soList, Map<String, Schema.DisplayType> fieldToFieldTypeMap){

        List<SObject> parsedSoList = new List<SObject>();

        if (!fieldToFieldTypeMap.isEmpty()){

            Boolean canViewEncryptedData = hasViewEncryptedDataPermission();

            for (SObject so : soList){
                //Update the fields that need to be updated
                for (String fieldName : fieldToFieldTypeMap.keySet()){
                    /*Encrypted field - Encrypted fields are actually PLAIN TEXT here, so we need to handle them differently
                    *                 - We can't read encryption mask type, so we're just gonna hide the text and call it a day
                    */
                    if (fieldToFieldTypeMap.get(fieldName) == Schema.DisplayType.ENCRYPTEDSTRING && !canViewEncryptedData){
                        Boolean blankField = String.isBlank((String)so.get(fieldName));
                        if (!blankField){
                            so.put(fieldName, DEFAULT_ANONYMIZED_STRING);
                        }
                    /*Percent field - Salesforce UI multiplies the value by 100 to save as a nice looking number. Okay.
                    *               - Data table multiplies the value by 100 to display as a nice looking number. Wait, what?
                    *               - We need to divide this value by 100, so the data table doesn't screw up the real value
                    */
                    } else if (fieldToFieldTypeMap.get(fieldName) == Schema.DisplayType.PERCENT){
                        Boolean blankField = so.get(fieldName) == null;
                        if (!blankField){
                            Decimal convertedPercentage = (Decimal)so.get(fieldName) / 100;
                            so.put(fieldName, convertedPercentage);
                        }
                    }
                }

                parsedSoList.add(so);
            }

        } else {
            parsedSoList = soList;
        }

        return parsedSoList;
    }

    //used to determine if user can view encrypted data
    private static Boolean hasViewEncryptedDataPermission(){
        //Check if user profile has permission to see encrypted data
        List<Profile> pList = [SELECT Id 
                                FROM Profile
                                WHERE PermissionsViewEncryptedData = true 
                                AND Id = :UserInfo.getProfileId()
                                WITH USER_MODE];
        if (!pList.isEmpty()){
            return true;
        } else {
            //Check if user has permission set to see encrypted data
            List<PermissionSetAssignment> psaList = [SELECT Id 
                                                    FROM PermissionSetAssignment 
                                                    WHERE AssigneeId = :UserInfo.getUserId()
                                                    AND PermissionSet.PermissionsViewEncryptedData = true
                                                    WITH USER_MODE];
            if (!psaList.isEmpty()){
                return true;
            }
        }

        return false;
    }
    
}
