/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Util
 * @description Database DML utility
 * @changehistory
 * ISS-002410 14-04-2025 XiRouh - Replaced isSet with != null
 * ISS-002379 05-05-2025 XiRouh - updated to cleanse the error message even when the source record could not be found
 * ISS-002504 04-06-2025 XW - added getMultiPicklistBindMap and getMultiPicklistPlaceholders for multipicklist query
 * ISS-002542 14-07-2025 XiRouh - Added a new doInsert method that accepts objectMap: a map containing multiple sObjects per key and sourceObjMap: a map with a single key and a single sObject
 * ISS-002513 09-02-2026 XiRouh - Added doUpsert(Map<String, List<SObject>> objectMap, Map<String, SObject> sourceObjMap, boolean allOrNone)
 */
global inherited sharing class REDU_Database_UTIL {
	
    /**
     * @description Salesforce common exception/error messages prefix to be cleansed from a long error message
     */
    global static final String SFVALIDATIONMSG = Label.Salesforce_Standard_Error_Messages;
    
    global static final String SFERRORNOISE = Label.Salesforce_Standard_Error_Noise;
    
    /**
     * @description Insert DML method
     * @param objectList List of SObjects to insert
     * @return void
     */
    global static void doInsert(List<SObject> objectList) {

        String sObjName = String.valueOf(objectList.getSObjectType());

        try {
            Database.insert(objectList, AccessLevel.USER_MODE);

        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.CREATABLE.name(), false);
        }
    }

    /**
     * @description Insert DML method
     * @param objectList List of SObjects to insert
     * @param sourceObjList List of source SObjects related to the DML
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doInsert(List<SObject> objectList, List<SObject> sourceObjList, boolean allOrNone) {

        String sObjName = String.valueOf(objectList.getSObjectType());

        try {
            integer counter = 0;

            List<Database.SaveResult> saveResults = Database.insert(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                    if(sourceObjList.size() < counter){
                        SObject targetParentToError = sourceObjList.get(counter);
                        targetParentToError.addError(errorMsg);
                    } else {
                        List<String> paramList = new List<String>{Label.Insert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
     * @param sourceObjMap Map of source objects (e.g., Trigger.newMap) to be error if exception found during the insert
     * @param parentFieldName The parent field API name from the object to be inserted that can be used to match the record in sourceObjMap
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doInsert(List<SObject> objectList, Map<Id, SObject> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());

        try{
            integer counter = 0;

            List<Database.SaveResult> saveResults = Database.insert(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        SObject targetParentToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        targetParentToError.addError(errorMsg);
                    } else {
                        List<String> paramList = new List<String>{Label.Insert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
    global static void doInsert(List<SObject> objectList, Map<Id, List<SObject>> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());
        
        try {
            integer counter = 0;

            List<Database.SaveResult> saveResults = Database.insert(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        List<SObject> targetChildrenToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        for (SObject child : targetChildrenToError){
                            child.addError(errorMsg);
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Insert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
     * @param objectMap Map of SObjects to insert with key as the identifier
     * @param sourceObjMap Map of source objects grouped by the identifier to be error if exception found during the insert
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doInsert(Map<String, SObject> objectMap, Map<String, List<SObject>> sourceObjMap, boolean allOrNone){
        
        String sObjName = String.valueOf(objectMap.getSObjectType());

        List<SObject> objectList = new List<SObject>();
        List<String> objectKeyList = new List<String>();

        for (String objKey : objectMap.keySet()) {
            objectKeyList.add(objKey);
            objectList.add(objectMap.get(objKey));
        }

        try {
            integer counter = 0;

            List<Database.SaveResult> saveResults = Database.insert(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String objKey = objectKeyList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                    if(sourceObjMap.containsKey(objKey)){
                        List<SObject> targetChildrenToError = sourceObjMap.get(objKey);
                        for (SObject child : targetChildrenToError){
                            child.addError(errorMsg);
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Insert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
     * @param objectMap Map of SObject Lists to insert with key as the identifier
     * @param sourceObjMap Map of source objects grouped by the identifier to be error if exception found during the insert
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doInsert(Map<String, List<SObject>> objectMap, Map<String, SObject> sourceObjMap, boolean allOrNone) {
        
        String sObjName;

        List<SObject> objectList = new List<SObject>();
        List<String> objectKeyList = new List<String>();

        for (String objKey : objectMap.keySet()) {
            for (SObject sobj : objectMap.get(objKey)) {
                objectKeyList.add(objKey);
                objectList.add(sobj);

                if (String.isBlank(sObjName)) {
                    sObjName = String.valueOf(sobj.getSObjectType());
                }
            }
        }

        try {
            Integer counter = 0;
            List<Database.SaveResult> saveResults = Database.insert(objectList, allOrNone, AccessLevel.USER_MODE);

            for (Database.SaveResult sr : saveResults) {
                if (!sr.isSuccess()) {
                    SObject errorRecord = objectList.get(counter);
                    String objKey = objectKeyList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                    if (sourceObjMap.containsKey(objKey)) {
                        SObject sourceObj = sourceObjMap.get(objKey);
                        sourceObj.addError(errorMsg);
                    } else {
                        List<String> paramList = new List<String>{Label.Insert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
     * @param objectMap Map of SObject Lists to insert with key as the identifier
     * @param sourceObjMap Map of source object Lists grouped by the identifier to be marked with error if exception found during the insert
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doInsert(Map<String, List<SObject>> objectMap, Map<String, List<SObject>> sourceObjMap, boolean allOrNone) {
        
        String sObjName;
        List<SObject> objectList = new List<SObject>();
        List<String> objectKeyList = new List<String>();

        for (String objKey : objectMap.keySet()) {
            for (SObject sobj : objectMap.get(objKey)) {
                objectKeyList.add(objKey);
                objectList.add(sobj);

                if (String.isBlank(sObjName)) {
                    sObjName = String.valueOf(sobj.getSObjectType());
                }
            }
        }

        try {
            Integer counter = 0;

            List<Database.SaveResult> saveResults = Database.insert(objectList, allOrNone, AccessLevel.USER_MODE);
            for (Database.SaveResult sr : saveResults) {
                if (!sr.isSuccess()) {
                    SObject errorRecord = objectList.get(counter);
                    String objKey = objectKeyList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                    if (sourceObjMap.containsKey(objKey)) {
                        List<SObject> targetChildrenToError = sourceObjMap.get(objKey);
                        for (SObject sourceObj : targetChildrenToError) {
                            sourceObj.addError(errorMsg);
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Insert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
    global static void doUpdate(List<SObject> objectList) {

        String sObjName = String.valueOf(objectList.getSObjectType());

        try {
            Database.update(objectList, AccessLevel.USER_MODE);

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
    global static void doUpdate(List<SObject> objectList, Map<Id, SObject> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());
        
        try {
            integer counter = 0;

            List<Database.SaveResult> saveResults = Database.update(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        SObject targetParentToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        targetParentToError.addError(errorMsg);
                    } else {
                        List<String> paramList = new List<String>{Label.Update, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
    global static void doUpdate(List<SObject> objectList, Map<Id, List<SObject>> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());
        
        try {
            integer counter = 0;
            
            List<Database.SaveResult> saveResults = Database.update(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        List<SObject> targetChildrenToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        for (SObject child : targetChildrenToError){
                            child.addError(errorMsg);
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Update, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
     * @param objectMap Map of SObjects to update with key as the identifier
     * @param sourceObjMap Map of source objects grouped by the identifier to be error if exception found during the insert
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doUpdate(Map<String, SObject> objectMap, Map<String, List<SObject>> sourceObjMap, boolean allOrNone){
        
        String sObjName = String.valueOf(objectMap.getSObjectType());

        List<SObject> objectList = new List<SObject>();
        List<String> objectKeyList = new List<String>();

        for (String objKey : objectMap.keySet()) {
            objectKeyList.add(objKey);
            objectList.add(objectMap.get(objKey));
        }

        try {
            integer counter = 0;

            List<Database.SaveResult> saveResults = Database.update(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String objKey = objectKeyList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                    if(sourceObjMap.containsKey(objKey)){
                        List<SObject> targetChildrenToError = sourceObjMap.get(objKey);
                        for (SObject child : targetChildrenToError){
                            child.addError(errorMsg);
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Update, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
     * @param objectMap Map of SObjects to update with key as the identifier
     * @param sourceObjMap Map of source objects grouped by the identifier to be error if exception found during the insert
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doUpdate(Map<String, List<SObject>> objectMap, Map<String, List<SObject>> sourceObjMap, boolean allOrNone){
        
        String sObjName;

        List<SObject> objectList = new List<SObject>();
        List<String> objectKeyList = new List<String>();

        for (String objKey : objectMap.keySet()) {
            for (SObject sobj : objectMap.get(objKey)) {
                objectKeyList.add(objKey);
                objectList.add(sobj);

                if (String.isBlank(sObjName)) {
                    sObjName = String.valueOf(sobj.getSObjectType());
                }
            }
        }

        try {
            integer counter = 0;

            List<Database.SaveResult> saveResults = Database.update(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.SaveResult sr : saveResults){
                if(!sr.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String objKey = objectKeyList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                    if(sourceObjMap.containsKey(objKey)){
                        List<SObject> targetChildrenToError = sourceObjMap.get(objKey);
                        for (SObject child : targetChildrenToError){
                            child.addError(errorMsg);
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Update, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
    global static void doUpsert(List<SObject> objectList) {

        String sObjName = String.valueOf(objectList.getSObjectType());

        try {
            Database.upsert(objectList, AccessLevel.USER_MODE);

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
    global static void doUpsert(List<SObject> objectList, Map<Id, SObject> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());
        
        try {
            //Upsert
            integer counter = 0;

            List<Database.UpsertResult> saveResults = Database.upsert(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.UpsertResult ur : saveResults){
                //Record errors against given record
                if(!ur.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(ur.getErrors()[0].getMessage());

                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        SObject targetParentToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        targetParentToError.addError(errorMsg);
                    } else {
                        List<String> paramList = new List<String>{Label.Upsert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
    global static void doUpsert(List<SObject> objectList, Map<Id, List<SObject>> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        String sObjName = String.valueOf(objectList.getSObjectType());

        try {
            //Upsert
            integer counter = 0;
            
            List<Database.UpsertResult> saveResults = Database.upsert(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.UpsertResult ur : saveResults){
                //Record errors against all given records
                if(!ur.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(ur.getErrors()[0].getMessage());

                    if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                        List<SObject> targetChildrenToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                        for (SObject child : targetChildrenToError){
                            child.addError(errorMsg);
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Upsert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
     * @param objectMap Map of SObjects to upsert with key as the identifier
     * @param sourceObjMap Map of source objects grouped by the identifier to be error if exception found during the insert
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doUpsert(Map<String, SObject> objectMap, Map<String, List<SObject>> sourceObjMap, boolean allOrNone){
        
        String sObjName = String.valueOf(objectMap.getSObjectType());

        List<SObject> objectList = new List<SObject>();
        List<String> objectKeyList = new List<String>();

        for (String objKey : objectMap.keySet()) {
            objectKeyList.add(objKey);
            objectList.add(objectMap.get(objKey));
        }

        try {
            integer counter = 0;

            List<Database.UpsertResult> saveResults = Database.upsert(objectList, allOrNone, AccessLevel.USER_MODE);
            for(Database.UpsertResult ur : saveResults){
                if(!ur.isSuccess()){
                    SObject errorRecord = objectList.get(counter);
                    String objKey = objectKeyList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(ur.getErrors()[0].getMessage());

                    if(sourceObjMap.containsKey(objKey)){
                        List<SObject> targetChildrenToError = sourceObjMap.get(objKey);
                        for (SObject child : targetChildrenToError){
                            child.addError(errorMsg);
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Upsert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
     * @param objectMap Map of SObjects to upsert with key as the identifier
     * @param sourceObjMap Map of source objects grouped by the identifier to be error if exception found during the insert
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doUpsert(Map<String, List<SObject>> objectMap, Map<String, List<SObject>> sourceObjMap, boolean allOrNone){
        
        String sObjName = '';

        if (!objectMap.isEmpty()) {
            String firstKey = objectMap.keySet().iterator().next();
            List<SObject> sObjList = objectMap.get(firstKey);
            
            if (!sObjList.isEmpty()) {
                sObjName = String.valueOf(sObjList[0].getSObjectType());
            }
        }
    
        List<SObject> objectList = new List<SObject>();
        List<String> recordKeyList = new List<String>();
    
        for (String objKey : objectMap.keySet()) {
            for (SObject record : objectMap.get(objKey)) {
                objectList.add(record);
                recordKeyList.add(objKey);
            }
        }
    
        try {
            List<Database.UpsertResult> saveResults = Database.upsert(objectList, allOrNone, AccessLevel.USER_MODE);
            for (integer counter = 0; counter < saveResults.size(); counter++) {
                Database.UpsertResult ur = saveResults[counter];
                if (!ur.isSuccess()) {
                    SObject errorRecord = objectList.get(counter);
                    String objKey = recordKeyList.get(counter); 
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(ur.getErrors()[0].getMessage());

                    if (sourceObjMap.containsKey(objKey)) {
                        List<SObject> targetChildrenToError = sourceObjMap.get(objKey);
                        for (SObject child : targetChildrenToError) {
                            child.addError(errorMsg);
                        }
                    } else {
                        List<String> paramList = new List<String>{Label.Upsert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
                        String exMsg = String.format(Label.DML_Error, paramList);
                        throw new REDU_ApplicationException(exMsg);
                    }
                }
            }
        } catch (DmlException dex) {
            REDU_ObjectSecurity_UTIL.handleDmlException(sObjName, dex, AccessType.UPSERTABLE.name(), false);
        }
    }

    /**
     * @description Upsert DML method
     * @param objectMap Map of SObject Lists to upsert with key as the identifier
     * @param sourceObjMap Map of source objects grouped by the identifier to be error if exception found during the upsert
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doUpsert(Map<String, List<SObject>> objectMap, Map<String, SObject> sourceObjMap, boolean allOrNone) {
        
        String sObjName;

        List<SObject> objectList = new List<SObject>();
        List<String> objectKeyList = new List<String>();

        for (String objKey : objectMap.keySet()) {
            for (SObject sobj : objectMap.get(objKey)) {
                objectKeyList.add(objKey);
                objectList.add(sobj);

                if (String.isBlank(sObjName)) {
                    sObjName = String.valueOf(sobj.getSObjectType());
                }
            }
        }

        try {
            Integer counter = 0;
            List<Database.UpsertResult> saveResults = Database.upsert(objectList, allOrNone, AccessLevel.USER_MODE);

            for (Database.UpsertResult ur : saveResults) {
                if (!ur.isSuccess()) {
                    SObject errorRecord = objectList.get(counter);
                    String objKey = objectKeyList.get(counter);
                    String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(ur.getErrors()[0].getMessage());

                    if (sourceObjMap.containsKey(objKey)) {
                        SObject sourceObj = sourceObjMap.get(objKey);
                        sourceObj.addError(errorMsg);
                    } else {
                        List<String> paramList = new List<String>{Label.Upsert, String.valueOf(errorRecord.getSObjectType()), errorMsg};
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
     * @description Delete DML method
     * @param objectList List of SObjects to insert
     * @return void
     */
    global static void doDelete(List<SObject> objectList) {

        REDU_ObjectSecurity_UTIL.validateDeleteAccess(objectList, false);

        Database.delete(objectList, AccessLevel.USER_MODE);
    }

    /**
     * @description Delete DML method
     * @param objectList List of SObjects to delete
     * @param sourceObjMap Map of source objects (e.g., Trigger.oldMap) to be error if exception found during the delete
     * @param parentFieldName The parent field API name from the object to be deleted that can be used to match the record in sourceObjMap
     * @param allOrNone Disallow partial success
     * @return void
     */
    global static void doDelete(List<SObject> objectList, Map<Id, SObject> sourceObjMap, String parentFieldName, boolean allOrNone){
        
        REDU_ObjectSecurity_UTIL.validateDeleteAccess(objectList, false);

        integer counter = 0;

        List<Database.DeleteResult> saveResults = Database.delete(objectList, allOrNone, AccessLevel.USER_MODE);
        for(Database.DeleteResult sr : saveResults){
            if(!sr.isSuccess()){
                SObject errorRecord = objectList.get(counter);
                String errorMsg = REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage());

                if(errorRecord.get(parentFieldName) != null && sourceObjMap.containsKey( String.valueOf(errorRecord.get(parentFieldName))) ){
                    SObject targetParentToError = sourceObjMap.get( String.valueOf(errorRecord.get(parentFieldName)) );
                    targetParentToError.addError(errorMsg);
                } else {
                    List<String> paramList = new List<String>{Label.Delete, String.valueOf(errorRecord.getSObjectType()), errorMsg};
                    String exMsg = String.format(Label.DML_Error, paramList);
                    throw new REDU_ApplicationException(exMsg);
                }
            }
            counter++;
        }
        
    }
    
    /**
     * @description Remove the salesforce standard error prefix from the error message
     * @param errorMsg Error message to be cleansed
     * @return String Cleansed message
     */
    global static String cleanseErrorMessage(String errorMsg){
        
        REDU_Logging_UTIL.debug('REDU_Database_UTIL.cleanseErrorMessage', errorMsg);

        List<String> errorPrefixes = SFVALIDATIONMSG.split(REDU_List_UTIL.DELIMITER);
        for(String errorPrx : errorPrefixes){
            errorPrx = errorPrx.trim();
            if(errorMsg.containsIgnoreCase(errorPrx)){
                errorMsg = errorMsg.substringAfterLast(errorPrx);
            }
        }

        List<String> noises = SFERRORNOISE.split(REDU_List_UTIL.DELIMITER);
        for(String noise : noises){
            noise = noise.trim();
            if(errorMsg.containsIgnoreCase(noise)){
                errorMsg = errorMsg.replace(noise, '');
            }
        }
        
        return errorMsg;
    }

    /**
     * @description Get the bind map of multiselect picklist for queryWithBinds
     * @param  placeholderName the placeholder name in query (:example)
     * @param  valueList       a LIST of value
     * @return                 Map<String, Object>
     */
    global static Map<String, Object> getMultiPicklistBindMap(String placeholderName, Object valueList) {
        List<Object> deserializedList = (List<Object>) valueList;
        Map<String, Object> result = new Map<String, Object>();
        Integer counter = 0;
        for(Object value : deserializedList) {
            counter++;
            result.put(placeholderName + counter, value);
        }

        return result;
    }

    /**
     * @description get the placeholders to be included in the query
     * @param  bindMapKeySet the keyset of the bind map returned from getMultiPicklistBindMap
     * @return               Set<String>
     */
    global static Set<String> getMultiPicklistPlaceholders(Set<String> bindMapKeySet) {
        Set<String> result = new Set<String>();
        for(String placeholder : bindMapKeySet) {
            result.add(':' + placeholder);
        }
        return result;
    }
}