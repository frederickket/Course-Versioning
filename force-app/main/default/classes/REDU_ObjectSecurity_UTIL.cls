/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Utility
 * @description SObject object and field level security validator
 * @changehistory
 * 
 */
@NamespaceAccessible
public inherited sharing class REDU_ObjectSecurity_UTIL {
    
    @NamespaceAccessible
    public class SecurityException extends Exception {}
    
    /**
     * @description get Access check messages
     * @param objectName Object Api Name
     * @param fieldList List of field Api Name
     * @param accessType Object AccessType to be validated (e.g, READABLE, CREATABLE, UPDATABLE, UPSERTABLE)
     * @param isSilent return error message to be handled gracefully or throw security exception error
     * @return String  - 1. empty: success 2. not empty - denied access message
     */
    @NamespaceAccessible
    public static String validateAccess(String objectName, List<String> fieldList, AccessType accessType, boolean isSilent){

        if (String.isNotBlank(objectName)) {
            Schema.DescribeSObjectResult sobjectResult = REDU_Metadata_UTIL.describeSObject(objectName);
            
            String accessDeniedMsg = '';
            
            if(isObjectPermitted(sobjectResult, accessType)){
                
                Map<String, Schema.SObjectField> fieldsMap = sobjectResult.fields.getMap();
                Set<String> setAccessDeniedField = new Set<String>();
                
                for(String fieldName : fieldList){
                    fieldName = fieldName.trim();
                    if (fieldName.endsWith('__r') || fieldName.contains('.'))
                        continue;  
                    
                    Schema.SObjectField fld = fieldsMap.get(fieldName);
                    
                    if(fld!=null){
                        Schema.DescribeFieldResult dfr = fieldsMap.get(fieldName).getDescribe();
                        
                        if (!isFieldPermitted(dfr, accessType)) {
                            setAccessDeniedField.add(dfr.getLabel());
                        }
                    } else {
                        throw new REDU_ObjectSecurity_UTIL.SecurityException(String.format(Label.Invalid_Object_Field_Error, new List<String>{fieldName, objectName} ));
                    }
                }
                
                if (!setAccessDeniedField.isEmpty()){
                    String objectError = objectName + ': ' + String.join(new List<String>(setAccessDeniedField), ', ') + '.';
                    accessDeniedMsg = String.format(Label.Insufficient_Object_Field_Access, new List<String>{accessType.name(), objectError});
                }
                
            } else{
                String objectError = objectName + '.';
                accessDeniedMsg = String.format(Label.Insufficient_Object_Field_Access, new List<String>{accessType.name(), objectError});
            }
            
            if(isSilent){
                return accessDeniedMsg;
            } else {
                if(String.isBlank(accessDeniedMsg)){
                    return '';
                } else {
                    throw new REDU_ObjectSecurity_UTIL.SecurityException(accessDeniedMsg);
                }
            }
        }

        return '';
    }

    /**
     * @description Object permission check.
     * @param sobjectResult Schema.DescribeSObjectResult
     * @param accessType Object AccessType to be validated (e.g, READABLE, CREATABLE, UPDATABLE, UPSERTABLE)
     * @return Boolean
     */
    @NamespaceAccessible
    public static boolean isObjectPermitted(Schema.DescribeSObjectResult sobjectResult, AccessType accessType){

        switch on accessType {
            when READABLE {
                if(!sobjectResult.isAccessible()){
                    return false;
                }
            }
            when CREATABLE {
                if(!sobjectResult.isCreateable()){
                    return false;
                }
            }
            when UPDATABLE {
                if(!sobjectResult.isUpdateable()){
                    return false;
                }
            }
            when UPSERTABLE {
                if(!sobjectResult.isCreateable() || !sobjectResult.isUpdateable()){
                    return false;
                }
            }
            when else {
                return false;
            }
        }
        
        return true;
    }

    /**
     * @description Field permission check.
     * @param fieldResult Schema.DescribeFieldResult
     * @param accessType Object AccessType to be validated (e.g, READABLE, CREATABLE, UPDATABLE, UPSERTABLE)
     * @return Boolean
     */
    @NamespaceAccessible
    public static boolean isFieldPermitted(Schema.DescribeFieldResult fieldResult, AccessType accessType){

        switch on accessType {
            when READABLE {
                if(!fieldResult.isAccessible()){
                    return false;
                }
            }
            when CREATABLE {
                if(!fieldResult.isCreateable()){
                    return false;
                }
            }
            when UPDATABLE {
                if(!fieldResult.isUpdateable()){
                    return false;
                }
            }
            when UPSERTABLE {
                if(!fieldResult.isCreateable() || !fieldResult.isUpdateable()){
                    return false;
                }
            }
            when else {
                return false;
            }
        }
        
        return true;
    }

    /**
     * @description Validate object and field access based on list of records for Delete
     * @param recordsList
     * @param isSilent
     * @return String
     */
    @NamespaceAccessible
    public static String validateDeleteAccess(List<SObject> recordsList, Boolean isSilent){
        Schema.DescribeSObjectResult sobjectResult = REDU_Metadata_UTIL.describeSObject(String.valueOf(recordsList.getSObjectType()));

        if (!sobjectResult.isDeletable()) {

            String errorMsg = String.format(Label.Insufficient_Object_Field_Access, new List<String>{Label.Delete, sobjectResult.getName()});

            if (isSilent){
                return errorMsg;
            } else {
                throw new REDU_ApplicationException(errorMsg);
            }
        }

        return '';
    }

    /**
     * @description Handle query exception for object and field access error
     * @param qex
     * @param isSilent
     * @return String
     */
    @NamespaceAccessible
    public static String handleQueryException(QueryException qex, Boolean isSilent) {

        if (qex.getInaccessibleFields() != null && !qex.getInaccessibleFields().isEmpty()) {

            Map<String, Set<String>> flsErrorFields = qex.getInaccessibleFields();
            
            List<String> objectErrors = new List<String>();
            for (String objectKey : flsErrorFields.keySet()){
                objectErrors.add(objectKey + ': ' + String.join(new List<String>(flsErrorFields.get(objectKey)), ', ') + '.');
            }

            String errorMsg = String.format(Label.Insufficient_Object_Field_Access, new List<String>{AccessType.READABLE.name(), String.join(objectErrors, ' ')});

            if (isSilent){
                return errorMsg;
            } else {
                throw new REDU_ApplicationException(errorMsg);
            }

        } else {
            throw qex;
        }
    }

    /**
     * @description Handle DML exception for object and field access error
     * @param objectName SObject API name
     * @param dex DmlException
     * @param isSilient Fail silently and return the error message instead of throwing exception
     * @return String
     */
    @NamespaceAccessible
    public static String handleDmlException(String objectName, DmlException dex, String accessType, Boolean isSilent) {
        
        if (dex.getDmlMessage(0).contains(Label.DmlException_Error) && dex.getDmlFieldNames(0) != null && !dex.getDmlFieldNames(0).isEmpty()) {
            String objError = (String.isNotBlank(objectName) ? objectName : '') + ': ' + String.join(dex.getDmlFieldNames(0), ', ');
            
            String errorMsg = String.format(Label.Insufficient_Object_Field_Access, new List<String>{accessType, objError});

            if (isSilent){
                return errorMsg;
            } else {
                throw new REDU_ApplicationException(errorMsg);
            }

        } else {
            throw new REDU_ApplicationException(REDU_Database_UTIL.cleanseErrorMessage(dex.getMessage()));
        }
    }
	
}