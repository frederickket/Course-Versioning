/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Util
 * @description System mode utility
 * @changehistory
 * ISS-001978 24-06-2024  Xirouh - added doQuery for INQ
 * ISS-002410 14-04-2025 XiRouh - Replaced isSet with != null
 */
public without sharing class REDU_SystemMode_UTIL {
    /**
     * =========================================================================================
     * DO NOT CHANGE THE CLASS AND METHODS TO 'global' as this is meant for internal use only
     * =========================================================================================
     */


    /**
     * @description Insert DML method
     * @param objectList List of SObjects to insert
     * @return void
     */
    public static void doInsert(List<SObject> objectList) {

        String sObjName = String.valueOf(objectList.getSObjectType());
        //this will throw exception if the user doesn't have valid access
        REDU_ObjectSecurity_UTIL.validateAccess(sObjName, new List<String>(), AccessType.CREATABLE, false);

        try {
            Database.insert(objectList, AccessLevel.SYSTEM_MODE);

        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.CREATABLE.name(), false);
        }
    }

    /**
     * @description Insert DML method
     * @param objectList List of SObjects to insert
     * @param sourceObjMap Map of source objects (e.g., Trigger.newMap) to be error if exception found during the insert
     * @param parentFieldName The parent field API name from the object to be inserted that can be used to match the record in sourceObjMap
     * @param allOrNone Disallow partial success
     * @return void
     */
    public static void doInsert(List<SObject> objectList, Map<Id, SObject> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());
        //this will throw exception if the user doesn't have valid access
        REDU_ObjectSecurity_UTIL.validateAccess(sObjName, new List<String>(), AccessType.CREATABLE, false);

        try{
            integer counter = 0;

            List<Database.SaveResult> saveResults = Database.insert(objectList, allOrNone, AccessLevel.SYSTEM_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    
                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        SObject targetParentToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        targetParentToError.addError(REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                    } else {
                        List<String> paramList = new List<String>{Label.Insert, String.valueOf(errorRecord.getSObjectType()), sr.getErrors()[0].getMessage()};
                        String exMsg = String.format(Label.DML_Error, paramList);
                        throw new REDU_ApplicationException(exMsg);
                    }
                }
                counter++;
            }
        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.CREATABLE.name(), false);
        }
        
    }

    /**
     * @description Insert DML method
     * @param objectList List of SObjects to insert
     * @param sourceObjMap Map of source objects grouped by parent id to be error if exception found during the insert
     * @param parentFieldName The parent field API name from the object to be inserted that can be used to match the record in sourceObjMap
     * @param allOrNone Disallow partial success
     * @return void
     */
    public static void doInsert(List<SObject> objectList, Map<Id, List<SObject>> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());
        //this will throw exception if the user doesn't have valid access
        REDU_ObjectSecurity_UTIL.validateAccess(sObjName, new List<String>(), AccessType.CREATABLE, false);

        try {
            integer counter = 0;

            List<Database.SaveResult> saveResults = Database.insert(objectList, allOrNone, AccessLevel.SYSTEM_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    
                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        List<SObject> targetChildrenToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        for (SObject child : targetChildrenToError){
                            child.addError(REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Insert, String.valueOf(errorRecord.getSObjectType()), sr.getErrors()[0].getMessage()};
                        String exMsg = String.format(Label.DML_Error, paramList);
                        throw new REDU_ApplicationException(exMsg);
                    }
                }
                counter++;
            }
        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.CREATABLE.name(), false);
        }
        
    }
    
    /**
     * @description Update DML method
     * @param objectList List of SObjects to insert
     * @return void
     */
    public static void doUpdate(List<SObject> objectList) {

        String sObjName = String.valueOf(objectList.getSObjectType());
        REDU_ObjectSecurity_UTIL.validateAccess(sObjName, new List<String>(), AccessType.UPDATABLE, false);

        try {
            Database.update(objectList, AccessLevel.SYSTEM_MODE);

        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.UPDATABLE.name(), false);
        }
    }

    /**
     * @description Update DML method
     * @param objectList List of SObjects to update
     * @param sourceObjMap Map of source objects (e.g., Trigger.newMap) to be error if exception found during the update
     * @param parentFieldName The parent field API name from the object to be updated that can be used to match the record in sourceObjMap
     * @param allOrNone Disallow partial success
     * @return void
     */
    public static void doUpdate(List<SObject> objectList, Map<Id, SObject> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());
        //this will throw exception if the user doesn't have valid access
        REDU_ObjectSecurity_UTIL.validateAccess(sObjName, new List<String>(), AccessType.UPDATABLE, false);

        try {
            integer counter = 0;

            List<Database.SaveResult> saveResults = Database.update(objectList, allOrNone, AccessLevel.SYSTEM_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    
                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        SObject targetParentToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        targetParentToError.addError(REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                    } else {
                        List<String> paramList = new List<String>{Label.Update, String.valueOf(errorRecord.getSObjectType()), sr.getErrors()[0].getMessage()};
                        String exMsg = String.format(Label.DML_Error, paramList);
                        throw new REDU_ApplicationException(exMsg);
                    }
                }
                counter++;
            }
        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.UPDATABLE.name(), false);
        }
        
    }

    /**
     * @description Update DML method
     * @param objectList List of SObjects to update
     * @param sourceObjMap Map of source objects grouped by parent id to be error if exception found during the update
     * @param parentFieldName The parent field API name from the object to be updated that can be used to match the record in sourceObjMap
     * @param allOrNone Disallow partial success
     * @return void
     */
    public static void doUpdate(List<SObject> objectList, Map<Id, List<SObject>> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());
        //this will throw exception if the user doesn't have valid access
        REDU_ObjectSecurity_UTIL.validateAccess(sObjName, new List<String>(), AccessType.UPDATABLE, false);

        try {
            integer counter = 0;
            
            List<Database.SaveResult> saveResults = Database.update(objectList, allOrNone, AccessLevel.SYSTEM_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    
                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        List<SObject> targetChildrenToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        for (SObject child : targetChildrenToError){
                            child.addError(REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Update, String.valueOf(errorRecord.getSObjectType()), sr.getErrors()[0].getMessage()};
                        String exMsg = String.format(Label.DML_Error, paramList);
                        throw new REDU_ApplicationException(exMsg);
                    }
                }
                counter++;
            }
        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.UPDATABLE.name(), false);
        }
        
    }

    /**
     * @description Upsert DML method
     * @param objectList List of SObjects to insert
     * @return void
     */
    public static void doUpsert(List<SObject> objectList) {

        String sObjName = String.valueOf(objectList.getSObjectType());
        //this will throw exception if the user doesn't have valid access
        REDU_ObjectSecurity_UTIL.validateAccess(sObjName, new List<String>(), AccessType.UPSERTABLE, false);

        try {
            Database.upsert(objectList, AccessLevel.SYSTEM_MODE);

        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.UPSERTABLE.name(), false);
        }
    }

    /**
     * @description Upsert DML method
     * @param objectList List of SObjects to upsert
     * @param sourceObjMap Map of source objects (e.g., Trigger.newMap) to be error if exception found during the upsert
     * @param parentFieldName The parent field API name from the object to be upserted that can be used to match the record in sourceObjMap
     * @param allOrNone Disallow partial success
     * @return void
     */
    public static void doUpsert(List<SObject> objectList, Map<Id, SObject> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());
        //this will throw exception if the user doesn't have valid access
        REDU_ObjectSecurity_UTIL.validateAccess(sObjName, new List<String>(), AccessType.UPSERTABLE, false);

        try {
            //Upsert
            integer counter = 0;
            
            List<Database.UpsertResult> saveResults = Database.upsert(objectList, allOrNone, AccessLevel.SYSTEM_MODE);
            for(Database.UpsertResult ur : saveResults){
                //Record errors against given record
                if(!ur.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    
                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        SObject targetParentToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        targetParentToError.addError(REDU_Database_UTIL.cleanseErrorMessage(ur.getErrors()[0].getMessage()));
                    } else {
                        List<String> paramList = new List<String>{Label.Upsert, String.valueOf(errorRecord.getSObjectType()), ur.getErrors()[0].getMessage()};
                        String exMsg = String.format(Label.DML_Error, paramList);
                        throw new REDU_ApplicationException(exMsg);
                    }
                }
                counter++;
            }
        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.UPSERTABLE.name(), false);
        }
        
    }

    /**
     * @description Upsert DML method
     * @param objectList List of SObjects to upsert
     * @param sourceObjMap Map of source objects grouped by parent id to be error if exception found during the upsert
     * @param parentFieldName The parent field API name from the object to be upserted that can be used to match the record in sourceObjMap
     * @param allOrNone Disallow partial success
     * @return void
     */
    public static void doUpsert(List<SObject> objectList, Map<Id, List<SObject>> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());
        //this will throw exception if the user doesn't have valid access
        REDU_ObjectSecurity_UTIL.validateAccess(sObjName, new List<String>(), AccessType.UPSERTABLE, false);

        try {
            //Upsert
            integer counter = 0;
            
            List<Database.UpsertResult> saveResults = Database.upsert(objectList, allOrNone, AccessLevel.SYSTEM_MODE);
            for(Database.UpsertResult ur : saveResults){
                //Record errors against all given records
                if(!ur.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    
                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        List<SObject> targetChildrenToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        for (SObject child : targetChildrenToError){
                            child.addError(REDU_Database_UTIL.cleanseErrorMessage(ur.getErrors()[0].getMessage()));
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Upsert, String.valueOf(errorRecord.getSObjectType()), ur.getErrors()[0].getMessage()};
                        String exMsg = String.format(Label.DML_Error, paramList);
                        throw new REDU_ApplicationException(exMsg);
                    }
                }
                counter++;
            }
        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.UPSERTABLE.name(), false);
        }
        
    }    
    
    /**
     * @description Delete DML method, this still respect object permission but bypass the record ownership but link to the contact
     * @param objectList List of SObjects to insert
     * @return void
     */
    public static void doDelete(List<SObject> objectList) {

        //this will throw exception if the user doesn't have valid access
        REDU_ObjectSecurity_UTIL.validateDeleteAccess(objectList, false);

        String sObjName = String.valueOf(objectList.getSObjectType());

        try {
            Database.delete(objectList, AccessLevel.SYSTEM_MODE);

        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, Label.Delete, false);
        }
    }

    /**
     * @description Delete DML method, this still respect object permission but bypass the record ownership but link to the contact
     * @param objectList List of SObjects to delete
     * @param sourceObjMap Map of source objects (e.g., Trigger.oldMap) to be error if exception found during the delete
     * @param parentFieldName The parent field API name from the object to be deleted that can be used to match the record in sourceObjMap
     * @param allOrNone Disallow partial success
     * @return void
     */
    public static void doDelete(List<SObject> objectList, Map<Id, SObject> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        //this will throw exception if the user doesn't have valid access
        REDU_ObjectSecurity_UTIL.validateDeleteAccess(objectList, false);

        integer counter = 0;
        
        List<Database.DeleteResult> saveResults = Database.delete(objectList, allOrNone, AccessLevel.SYSTEM_MODE);
        for(Database.DeleteResult sr : saveResults){
            if(!sr.isSuccess()){
                SObject errorRecord = objectList.get(counter);
                
                if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                    SObject targetParentToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                    targetParentToError.addError(REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                } else {
                    List<String> paramList = new List<String>{Label.Delete, String.valueOf(errorRecord.getSObjectType()), sr.getErrors()[0].getMessage()};
                    String exMsg = String.format(Label.DML_Error, paramList);
                    throw new REDU_ApplicationException(exMsg);
                }
            }
            counter++;
        }
        
    }

    /**
     * @description Query record using "without sharing" but we still need to respect the object and field permission. This should be limited to query data for rollup, child records deletion and system protected objects.
     * @param soqlQuery The query to be executed
     * @param bindParams The query bind params
     * @param objectFieldsForFls Map of object and fields for object and FLS check
     * @return List<SObject>
     */
    public static List<SObject> doQuery(String soqlQuery, Map<String, Object> bindParams, Map<String, Set<String>> objectFieldsForFls){
        List<SObject> result = new List<SObject>();

        //ensure that we have the object and fields to be validated.
        if (objectFieldsForFls.isEmpty()) {
            throw new REDU_ApplicationException(Label.Missing_Object_And_Field_For_FLS);
        }

        //perform the object and FLS check manually as required by security team when using query with system_mode
        for (String objectName : objectFieldsForFls.keySet()) {
            //this will throw exception if the user doesn't have valid access
            REDU_ObjectSecurity_UTIL.validateAccess(objectName, new List<String>(objectFieldsForFls.get(objectName)), AccessType.READABLE, false);
        }

        //need to query using system mode so that we can get all data regardless of the sharing, this should be limited to query data for rollup, child records deletion and system protected objects.
        for (SObject records : (List<SObject>) Database.queryWithBinds(soqlQuery, bindParams, AccessLevel.SYSTEM_MODE)) {
            result.add(records);
        }

        return result;
    }
}