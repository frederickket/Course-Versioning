/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Util
 * @description Metadata utility
 * @changehistory
 * ISS-001591 31-03-2023 Lean - new class
 * ISS-002153 15-11-2024 Jordan - getObjectFieldsForCloning()
 * ISS-002230 22-01-2025 XW - added new method to get picklist value label
 * ISS-002261 08-03-2025 Jordan - added isCreateable and isUpdateable to getFieldSetMembers()
 * ISS-002675 14-01-2026 XiRouh - Added getObjectLookupField() to receive a set objectNamesLookup
 */
@NamespaceAccessible
public inherited sharing class REDU_Metadata_UTIL {
    
    public static final String PICKLIST_LABEL = '_PicklistLabel';

    /**
    * @description Helper method to describe sobject type.
    * @param objectName object name
    * @return Schema.SObjectType
    */
    @NamespaceAccessible
    public static Schema.SObjectType getSObjectType(String objectName){
        
        return describeSObject(objectName).getSObjectType();
        
    }

    /**
    * @description Helper method to describe sobject.
    * @param objectName object name
    * @return Schema.DescribeSObjectResult
    */
    @NamespaceAccessible
    public static Schema.DescribeSObjectResult describeSObject(String objectName){
        
        List<Schema.DescribeSObjectResult> sObjects = Schema.describeSObjects(new List<String>{objectName}, SObjectDescribeOptions.DEFERRED);

        return sObjects.get(0);
        
    }

    /**
     * @description Helper method to describe sobject field.
     * @param objectName object api name
     * @param fieldName field api name
     * @return Schema.DescribeSObjectResult
     */
    @NamespaceAccessible
    public static Schema.DescribeFieldResult describeSObjectField(String objectName, String fieldName){
        
        List<Schema.DescribeSObjectResult> sObjects = Schema.describeSObjects(new List<String>{objectName}, SObjectDescribeOptions.DEFERRED);

        if (!sObjects.isEmpty()) {
            Map<String, Schema.SObjectField> fieldMap = sObjects.get(0).fields.getMap();
            if (fieldMap.containsKey(fieldName)) {
                return fieldMap.get(fieldName).getDescribe();
            }
        }

        throw new REDU_ApplicationException(String.format(Label.Invalid_Object_Field_Error, new List<String>{fieldName, objectName}));
    }

    /**
     * @description Helper method to describe a list of sobject fields.
     * @param objectName object name
     * @param fields Set of fields
     * @return Schema.DescribeSObjectResult
     */
    @NamespaceAccessible
    public static Map<String, Schema.DescribeFieldResult> describeSObjectFields(String objectName, Set<String> fields){
        
        return describeSObjectFields(objectName, new List<String>(fields));
    }
    
    /**
     * @description Helper method to describe a list of sobject fields.
     * @param objectName object name
     * @param fields List of fields
     * @return Schema.DescribeSObjectResult
     */
    @NamespaceAccessible
    public static Map<String, Schema.DescribeFieldResult> describeSObjectFields(String objectName, List<String> fields){
        
        List<Schema.DescribeSObjectResult> sObjects = Schema.describeSObjects(new List<String>{objectName}, SObjectDescribeOptions.DEFERRED);
        Map<String, Schema.DescribeFieldResult> fieldsDescribeMap = new Map<String, Schema.DescribeFieldResult>();

        if (!sObjects.isEmpty() && !fields.isEmpty()) {
            Map<String, Schema.SObjectField> fieldMap = sObjects.get(0).fields.getMap();

            for (String fName : fields) {
                String loweredFieldName = fName.toLowerCase();

                if (fieldMap.containsKey(loweredFieldName)) {
                    fieldsDescribeMap.put(fName, fieldMap.get(loweredFieldName).getDescribe());
                } else {
                    throw new REDU_ApplicationException(String.format(Label.Invalid_Object_Field_Error, new List<String>{fName, objectName}));
                }
            }
        }

        return fieldsDescribeMap;
    }

    /**
     * @description Provide a field set member info
     * @param objectName object Name
     * @param fieldsetName field set Name
     * @return List<List<REDU_DynamicFieldValue_OBJ>>
     */
    @NamespaceAccessible
    public static List<REDU_DynamicFieldValue_OBJ> getFieldSetMembers(String objectName, String fieldsetName){
        REDU_Logging_UTIL.debug('getFieldSetMembers', objectName + ' - ' + fieldsetName);
        
        List<REDU_DynamicFieldValue_OBJ> fields = new List<REDU_DynamicFieldValue_OBJ>();
        
        for(Schema.FieldSetMember fsmObj : getFieldSetSchema(objectName, fieldsetName)){
            DescribeFieldResult dfr = fsmObj.getSObjectField().getDescribe();

            fields.add( new REDU_DynamicFieldValue_OBJ(objectName, fsmObj.getFieldPath(), fsmObj.getLabel(), null, dfr.getType().name(), dfr.getSoapType().name(), null, dfr.getInlineHelpText(), dfr.getScale(), dfr.isCreateable(), dfr.isUpdateable(), fsmObj.getRequired()) );
        }
            
        return fields;
    }

    /**
     * @description Provide a field set member info
     * @param objectName object Name
     * @param fieldsetName field set Name
     * @param columnNo column number per row
     * @return List<List<REDU_DynamicFieldValue_OBJ>>
     */
    @NamespaceAccessible
    public static List<List<REDU_DynamicFieldValue_OBJ>> getFieldSetMembers(String objectName, String fieldsetName, Integer columnNo){
        REDU_Logging_UTIL.debug('getFieldSetMembers', objectName + ' - ' + fieldsetName + ' - ' + columnNo);
        
        List<List<REDU_DynamicFieldValue_OBJ>> fields = new List<List<REDU_DynamicFieldValue_OBJ>>();
        List<REDU_DynamicFieldValue_OBJ> rowFields;
        
        integer counter = 0;
        integer columns = columnNo == null ? 1 : columnNo;
        for(Schema.FieldSetMember fsmObj : getFieldSetSchema(objectName, fieldsetName)){
            
            if(Math.mod(counter, columns) == 0){
                rowFields = new List<REDU_DynamicFieldValue_OBJ>();
                fields.add(rowFields);
            }
            
            DescribeFieldResult dfr = fsmObj.getSObjectField().getDescribe();
            rowFields.add( new REDU_DynamicFieldValue_OBJ(objectName, fsmObj.getFieldPath(), fsmObj.getLabel(), null, dfr.getType().name(), dfr.getSoapType().name(), null, dfr.getInlineHelpText(), dfr.getScale(), dfr.isCreateable(), dfr.isUpdateable(), fsmObj.getRequired()) );
            
            counter ++;
        }
            
        return fields;
    }

    /**
     * @description Provide a field set info
     * @param objectName object Name
     * @param fieldsetName field set Name
     * @param columnNo column number per row
     * @return List<List<String>>
     */
    @NamespaceAccessible
    public static List<List<String>> getFields(String objectName, String fieldsetName, Integer columnNo){
        REDU_Logging_UTIL.debug('getFields', objectName + ' - ' + fieldsetName + ' - ' + columnNo);
        
        List<List<String>> fields = new List<List<String>>();
        List<String> rowFields;
        
        integer counter = 0;
        integer columns = columnNo == null ? 1 : columnNo;
        for(Schema.FieldSetMember fieldSetMemberObj : getFieldSetSchema(objectName, fieldsetName)){
            
            if(Math.mod(counter, columns) == 0){
                rowFields = new List<String>();
                fields.add(rowFields);
            }
            
            rowFields.add(fieldSetMemberObj.getFieldPath());
            
            counter ++;
        }
            
        return fields;
    }

    /**
     * @description Provide a field set info
     * @param objectName object Name
     * @param fieldsetName field set Name
     * @param useNameForRefField return name instead of id for reference field e.g., Account.Name instead of AccountId
     * @return List<List<String>>
     */
    @NamespaceAccessible
    public static List<String> getFields(String objectName, String fieldsetName, Boolean useNameForRefField){
        REDU_Logging_UTIL.debug('getFields', objectName + ' - ' + fieldsetName + ' - ' + useNameForRefField);
        
        List<String> fields = new List<String>();
        
        for(Schema.FieldSetMember fsm : getFieldSetSchema(objectName, fieldsetName)){
            fields.add(getFieldPath(fsm, useNameForRefField ));
        }
        
        return fields;
    }

    /**
     * @description Get the field path
     * @param fsm Field set member
     * @param useNameForRefField return name instead of Id field
     * @return String
     */
    @NamespaceAccessible
    public static String getFieldPath(Schema.FieldSetMember fsm, boolean useNameForRefField){

        if(fsm.getType() == Schema.DisplayType.REFERENCE){
            return getReferenceFieldForQuery(fsm.getFieldPath(), useNameForRefField);
        } else {
            return fsm.getFieldPath();
        }
        
    }

    /**
     * @description Get the parent field relationship name
     * @param fieldName Field name
     * @param useNameForRefField return name instead of Id field
     * @return String
     */
    @NamespaceAccessible
    public static String getReferenceFieldForQuery(String fieldName, boolean useNameForRefField){

        if(useNameForRefField){
            if(fieldName.endsWithIgnoreCase('__c')){
                fieldName = fieldName.removeEnd('__c') + '__r';
            } else if(fieldName.endsWithIgnoreCase('id')){
                fieldName = fieldName.removeEndIgnoreCase('id');
            }

            fieldName += '.Name';
        }

        return fieldName;
    }

    /**
    * @description Get the fieldSet schema.
    * @param ObjectName String record type
    * @param fieldSetName String record type
    * @return List<Schema.FieldSetMember>
    */
    @NamespaceAccessible
    public static List<Schema.FieldSetMember> getFieldSetSchema(String objectName, String fieldsetName){
        List<Schema.FieldSetMember> listFieldSetMember = new List<Schema.FieldSetMember>();
        try{
            Schema.FieldSet fieldSetObj = describeSObject(objectName).FieldSets.getMap().get(fieldSetName);
            listFieldSetMember = fieldSetObj.getFields();
        } catch(Exception ex){
            throw new REDU_ApplicationException(String.format(Label.Invalid_Object_Field_Set_Error, new List<String>{fieldsetName, objectName}));
        }
        
        return listFieldSetMember;
    }
    /**
     * @description ISS-002153 Get object fields for cloning
     * @param objectName Object name
     * @param createableOnly To include only createable fields
     * @return Set<String>
     */
    @NamespaceAccessible
    public static Set<String> getObjectFieldsForCloning(String objectName, AccessType accessType) {
        
        Set<String> fieldData = new Set<String>();
        Type t = Type.forName(objectName);
        SObject sobj = (SObject)t.newInstance();
        Map<String, Schema.SobjectField> fieldMap = sobj.getSObjectType().getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        for (Schema.SobjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();

            if (!REDU_ObjectSecurity_UTIL.isFieldPermitted(dfr, accessType)) {
                continue;
            }

            String fieldName = dfr.getName();

            //exclude rio system fields
            if (
                !dfr.isExternalId() && //reduivy__External_Id__c & reduivy__UUID__c and any external id fields
                fieldName != 'OwnerId' &&
                fieldName != 'reduivy__Clone_From_Id__c' &&
                fieldName != 'reduivy__Sample_Record_Code__c'
            ) {
                fieldData.add(fieldName);
            }
        }
        return fieldData;
    }



    /**
     * @description Get the query string to get picklist value label with alias e.g., toLabel(field__c) field__c_PicklistLabel
     * @param fieldName Field name
     * @return String
     */
    @NamespaceAccessible
    public static String getPicklistFieldLabelQuery(String fieldName) {
        List<String> fieldListSplitList = fieldName.split('\\.');
        return 'toLabel(' + fieldName  + ') ' + fieldListSplitList.get(fieldListSplitList.size() - 1) + PICKLIST_LABEL;
    }

    /**
     * @description Get the query string for picklist field (used in datatable columns only) e.g., Status__c_PicklistLabel or Parent__r.Status__c_PicklistLabel
     * @param fieldName Field name
     * @return String
     */
    @NamespaceAccessible
    public static String getPicklistLabelFieldName(String fieldName) {
        return fieldName + PICKLIST_LABEL;
    }

    /**
     * @description get all the DescribeFieldResult of the field 
     * @param  baseObjectApiName the object api name of this field coming from
     * @param  fieldPath         The string representing the field path (e.g., 'reduivy__IPE__r.reduivy_SPL__r.Name').
     * @return                   the DescribeFieldResult of all the field
     */
    @NamespaceAccessible
    public static List<Schema.DescribeFieldResult> getDescribePathFields(String baseObjectApiName, String fieldPath) {
        List<String> fieldSegments = fieldPath.split('\\.'); // Split the path
        Schema.SObjectType currentSObjectType;
        List<Schema.DescribeFieldResult> describeFieldResults = new List<Schema.DescribeFieldResult>();

        for (Integer i = 0; i < fieldSegments.size(); i++) {
            String fieldName = fieldSegments[i];
           
            // Get the SObjectType or DescribeFieldResult
            if (i == 0) {
                currentSObjectType = describeSObject(baseObjectApiName).getSObjectType();
            }


            if (i < fieldSegments.size() - 1) {
                // Navigate to the next related object
                fieldName = fieldName.endsWith('__r') ? fieldName.removeEnd('__r') + '__c' : fieldName + 'Id';
                REDU_Logging_UTIL.debug('fieldName', fieldName);
                Schema.DescribeFieldResult fieldDescribe = currentSObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().get(fieldName).getDescribe();
                describeFieldResults.add(fieldDescribe);
                List<Schema.SObjectType> referenceTo = fieldDescribe.getReferenceTo();
                if (!referenceTo.isEmpty()) {
                    currentSObjectType = referenceTo[0]; // Assuming only one reference
                } else {
                    break;
                }
            } else {
                // Last field in the path
                Schema.DescribeFieldResult fieldDescribe = currentSObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().get(fieldName).getDescribe();
                describeFieldResults.add(fieldDescribe);
            }
        }


        return describeFieldResults;
    }

    /**
     * @description masterDetailRelationshipMap stores if sobject has master detail relationship with other.
     */
    private static Map<String, Boolean> masterDetailRelationshipMap;

    /**
     * @description Checking if the sObject has master detail relationship with other.
     * @param  sObjectName sObjectName description
     * @return             return description
     */
    @NamespaceAccessible
    public static Boolean hasMasterDetailRelationship(String sObjectName) {
        if(masterDetailRelationshipMap == null) {
            masterDetailRelationshipMap = new Map<String, Boolean>();
        }

        if(masterDetailRelationshipMap.containsKey(sObjectName)) {
            return masterDetailRelationshipMap.get(sObjectName);
        }

        Map<String, Schema.SObjectField> fieldMap = REDU_Metadata_UTIL.describeSObject(sObjectName).fields.getMap();
        for(String fieldName: fieldMap.keySet()) {
            Integer fieldLabel = fieldMap.get(fieldName).getDescribe().getRelationshipOrder();
            if(fieldLabel != null) {
                masterDetailRelationshipMap.put(sObjectName, true);
                return true;
            }
        }

        masterDetailRelationshipMap.put(sObjectName, false);
        return false;
    }

    /**
     * @description get lookup fields of the object
     * @param objectName the sobject name
     */
    @NamespaceAccessible
    public static Set<String> getLookupFieldsFromObject(String objectName) {

        Set<String> lookupFields = new Set<String>();

        Schema.DescribeSObjectResult descSobjResult = describeSObject(objectName);
        Map<String, Schema.SobjectField> fieldMap = descSobjResult.fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            Schema.SobjectField sobjField = fieldMap.get(fieldName);
            Schema.DescribeFieldResult dfr = sobjField.getDescribe();

            if (Schema.DisplayType.Reference == dfr.getType()) {
                lookupFields.add(dfr.getName());
            }
        }

        return lookupFields;
    }

    /**
     * @description The child object name to the parent object name to lookup to its object lookup field name, 
     * @return   Map<String, String>
     */
    private static Map<String, Map<String, String>> objectLookupFieldsMap = new Map<String, Map<String, String>>();


    /**
     * @description get the field name of the object lookup field from a object
     * @param  objectNameFrom   objectNameFrom the object name of the lookup field from 
     * @param  objectNameLookup objectNameLookup the object name that is referred by the lookup field
     * @return                  object lookup field name
     */
    @NamespaceAccessible
    public static String getObjectLookupField(String objectNameFrom, String objectNameLookup) {
        if(objectLookupFieldsMap.containsKey(objectNameFrom)) {
            if(objectLookupFieldsMap.get(objectNameFrom).containsKey(objectNameLookup)){
                return objectLookupFieldsMap.get(objectNameFrom).get(objectNameLookup);
            }
        } else {
            objectLookupFieldsMap.put(objectNameFrom, new Map<String, String>());
        }
        Map<String, Schema.SObjectField> fieldsMap = describeSObject(objectNameFrom).fields.getMap();
        for(Schema.SObjectField field : fieldsMap.values()) {
            Schema.DescribeFieldResult describeField = field.getDescribe();
            List<Schema.SObjectType> referenceToList = describeField.getReferenceTo();
            if(referenceToList != null && !referenceToList.isEmpty() && referenceToList[0].getDescribe(SObjectDescribeOptions.DEFERRED).getName() == objectNameLookup) {
                objectLookupFieldsMap.get(objectNameFrom).put(objectNameLookup, describeField.getName());
                return describeField.getName();
            }
        }

        objectLookupFieldsMap.get(objectNameFrom).put(objectNameLookup, objectNameLookup);
        return objectNameLookup;
    }

    /**
     * @description get the object icon of the given object
     * @param  objName the object api name
     * @return         
     */
    @NamespaceAccessible
    public static String getObjectIcon(String objName){
        String objIcon = '';

        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.DescribeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { 
            tabDesc.addAll(tsr.getTabs()); 
        }

        for(Schema.DescribeTabResult tr : tabDesc) {
            if( objName == tr.getSobjectName() ) {
                if( tr.isCustom() ) {
                    iconDesc.addAll(tr.getIcons());
                } else {
                    objIcon = 'standard:' + objName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                objIcon = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
        return objIcon;
    }

    /**
     * @description get the field names of the object lookup fields from an object
     * @param  objectNameFrom   objectNameFrom the object name of the lookup field from 
     * @param  objectNamesLookup objectNamesLookup the list of object names that are referred by lookup fields
     * @return                  Map of object name to lookup field name
     */
    @NamespaceAccessible
    public static Map<String, String> getObjectLookupField(String objectNameFrom, Set<String> objectNamesLookup) {
        Map<String, String> resultMap = new Map<String, String>();
        Set<String> lookupsToFind = new Set<String>();
        
        if(objectLookupFieldsMap.containsKey(objectNameFrom)) {
            for(String objectNameLookup : objectNamesLookup) {
                if(objectLookupFieldsMap.get(objectNameFrom).containsKey(objectNameLookup)){
                    resultMap.put(objectNameLookup, objectLookupFieldsMap.get(objectNameFrom).get(objectNameLookup));
                } else {
                    lookupsToFind.add(objectNameLookup);
                }
            }
        } else {
            objectLookupFieldsMap.put(objectNameFrom, new Map<String, String>());
            lookupsToFind.addAll(objectNamesLookup);
        }
        
        if(lookupsToFind.isEmpty()) {
            return resultMap;
        }
        
        Map<String, Schema.SObjectField> fieldsMap = describeSObject(objectNameFrom).fields.getMap();
        for(Schema.SObjectField field : fieldsMap.values()) {
            Schema.DescribeFieldResult describeField = field.getDescribe();
            List<Schema.SObjectType> referenceToList = describeField.getReferenceTo();
            if(referenceToList != null && !referenceToList.isEmpty()) {
                String referencedObjectName = referenceToList[0].getDescribe(SObjectDescribeOptions.DEFERRED).getName();
                if(lookupsToFind.contains(referencedObjectName)) {
                    objectLookupFieldsMap.get(objectNameFrom).put(referencedObjectName, describeField.getName());
                    resultMap.put(referencedObjectName, describeField.getName());
                    lookupsToFind.remove(referencedObjectName);
                }
            }
        }

        for(String objectNameLookup : lookupsToFind) {
            objectLookupFieldsMap.get(objectNameFrom).put(objectNameLookup, objectNameLookup);
            resultMap.put(objectNameLookup, objectNameLookup);
        }
        
        return resultMap;
    }
}