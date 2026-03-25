/**
 * @author      WDCi (XiRouh)
 * @date        June 2025
 * @group       Individual Requirement Set
 * @description Update parent object completion indicators when IRS totals change
 * @changehistory
 * ISS-002675 13-11-2025 XiRouh - new class
 */

public without sharing class IRS_UpdateParentCompletionIndicator_EXE extends REDU_TriggerExecutable {

    private static final Integer MAX_PARENT_OBJECTS = 5;

    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            Map<Id, reduivy__Individual_Requirement_Set__c> irsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
            
            for (reduivy__Individual_Requirement_Set__c irsNew : (List<reduivy__Individual_Requirement_Set__c>) newList) {
                if (String.isNotBlank(irsNew.reduivy__Study_Requirement_Set__c) &&
                    irsNew.reduivy__Status__c == IRS_Helper.STATUS_ACTIVE && 
                    (
                        (irsNew.reduivy__Total_Requirement__c != null && irsNew.reduivy__Total_Requirement__c != 0) ||
                        (irsNew.reduivy__Total_Requirement_Faculty__c != null && irsNew.reduivy__Total_Requirement_Faculty__c != 0) ||
                        (irsNew.reduivy__Total_Requirement_Student__c != null && irsNew.reduivy__Total_Requirement_Student__c != 0)
                    )
                ) {
                    irsMap.put(irsNew.Id, irsNew);
                }
            }

            if (!irsMap.isEmpty()) {
                updateParentCompletionIndicators(irsMap, null);
            }
        }
    }

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Map<Id, reduivy__Individual_Requirement_Set__c> irsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
            Map<Id, reduivy__Individual_Requirement_Set__c> irsOldMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();

            Set<String> irsLookupFields = REDU_Metadata_UTIL.getLookupFieldsFromObject(IRS_Helper.getApiName());
            
            for (reduivy__Individual_Requirement_Set__c irsNew : (List<reduivy__Individual_Requirement_Set__c>) newList) {
                reduivy__Individual_Requirement_Set__c irsOld = (reduivy__Individual_Requirement_Set__c) oldMap.get(irsNew.Id);

                Boolean addedToMap = false;

                // Check if totals or status changed
                if (
                    irsNew.reduivy__Status__c != irsOld.reduivy__Status__c ||
                    irsNew.reduivy__Total_Requirement__c != irsOld.reduivy__Total_Requirement__c ||
                    irsNew.reduivy__Total_Reviewed__c != irsOld.reduivy__Total_Reviewed__c ||
                    irsNew.reduivy__Total_Submitted__c != irsOld.reduivy__Total_Submitted__c ||
                    irsNew.reduivy__Total_Requirement_Faculty__c != irsOld.reduivy__Total_Requirement_Faculty__c ||
                    irsNew.reduivy__Total_Reviewed_Faculty__c != irsOld.reduivy__Total_Reviewed_Faculty__c ||
                    irsNew.reduivy__Total_Submitted_Faculty__c != irsOld.reduivy__Total_Submitted_Faculty__c ||
                    irsNew.reduivy__Total_Requirement_Student__c != irsOld.reduivy__Total_Requirement_Student__c ||
                    irsNew.reduivy__Total_Reviewed_Student__c != irsOld.reduivy__Total_Reviewed_Student__c ||
                    irsNew.reduivy__Total_Submitted_Student__c != irsOld.reduivy__Total_Submitted_Student__c ||
                    irsNew.reduivy__Study_Requirement_Set__c != irsOld.reduivy__Study_Requirement_Set__c
                ) {
                    if (String.isNotBlank(irsNew.reduivy__Study_Requirement_Set__c)) {
                        irsMap.put(irsNew.Id, irsNew);

                        addedToMap = true;
                    }
                }

                // Check if any parent lookup field changed
                for (String lookupField : irsLookupFields) {
                    if (irsNew.get(lookupField) != irsOld.get(lookupField)) {
                        if (addedToMap == false && String.isNotBlank(irsNew.reduivy__Study_Requirement_Set__c)) {
                            irsMap.put(irsNew.Id, irsNew);
                        }

                        if (String.isNotBlank(irsOld.reduivy__Study_Requirement_Set__c)) {
                            irsOldMap.put(irsOld.Id, irsOld);
                        }

                        break;
                    }
                }
            }

            if (!irsMap.isEmpty()) {
                updateParentCompletionIndicators(irsMap, irsOldMap.isEmpty() ? null : irsOldMap);
            }
        }
    }

    /**
     * @description AfterDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            Map<Id, reduivy__Individual_Requirement_Set__c> irsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
            
            for (reduivy__Individual_Requirement_Set__c irsOld : (List<reduivy__Individual_Requirement_Set__c>) oldList) {
                if (String.isNotBlank(irsOld.reduivy__Study_Requirement_Set__c) &&
                    irsOld.reduivy__Status__c == IRS_Helper.STATUS_ACTIVE && 
                    (
                        (irsOld.reduivy__Total_Requirement__c != null && irsOld.reduivy__Total_Requirement__c != 0) ||
                        (irsOld.reduivy__Total_Requirement_Faculty__c != null && irsOld.reduivy__Total_Requirement_Faculty__c != 0) ||
                        (irsOld.reduivy__Total_Requirement_Student__c != null && irsOld.reduivy__Total_Requirement_Student__c != 0)
                    )
                ) {
                    irsMap.put(irsOld.Id, irsOld);
                }
            }

            if (!irsMap.isEmpty()) {
                updateParentCompletionIndicators(irsMap, null);
            }
        }
    }

    /**
     * @description AfterUndelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUndelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            Map<Id, reduivy__Individual_Requirement_Set__c> irsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
            
            for (reduivy__Individual_Requirement_Set__c irsNew : (List<reduivy__Individual_Requirement_Set__c>) newList) {
                if (String.isNotBlank(irsNew.reduivy__Study_Requirement_Set__c) &&
                    irsNew.reduivy__Status__c == IRS_Helper.STATUS_ACTIVE && 
                    (
                        (irsNew.reduivy__Total_Requirement__c != null && irsNew.reduivy__Total_Requirement__c != 0) ||
                        (irsNew.reduivy__Total_Requirement_Faculty__c != null && irsNew.reduivy__Total_Requirement_Faculty__c != 0) ||
                        (irsNew.reduivy__Total_Requirement_Student__c != null && irsNew.reduivy__Total_Requirement_Student__c != 0)
                    )
                ) {
                    irsMap.put(irsNew.Id, irsNew);
                }
            }

            if (!irsMap.isEmpty()) {
                updateParentCompletionIndicators(irsMap, null);
            }
        }
    }

    /**
     * @description Update parent object completion indicators
     * @param irsIds Set of Individual Requirement Set Ids
     * @param triggerRecordsMap Map of trigger context IRS records for error handling
     * @return void
     */
    private void updateParentCompletionIndicators(Map<Id, reduivy__Individual_Requirement_Set__c> irsMap, Map<Id, reduivy__Individual_Requirement_Set__c> oldIrsMap) {
        
        List<reduivy__Individual_Requirement_Set__c> relatedIrsList = new List<reduivy__Individual_Requirement_Set__c>();
        if(irsMap != null && !irsMap.isEmpty()) {
            relatedIrsList.addAll(irsMap.values());
        }

        if(oldIrsMap != null && !oldIrsMap.isEmpty()) {
            relatedIrsList.addAll(oldIrsMap.values());
        }

        Set<Id> srsIds = new Set<Id>();

        for(reduivy__Individual_Requirement_Set__c irs : relatedIrsList) {
            if(String.isNotBlank(irs.reduivy__Study_Requirement_Set__c)) {
                srsIds.add(irs.reduivy__Study_Requirement_Set__c);
            }
        }

        // Query Study Requirement Set details
        Set<String> srsFields = new Set<String> {
            'Id',
            'reduivy__Object__c',
            'reduivy__Completion_Indicator_Admin__c',
            'reduivy__Completion_Indicator_Faculty__c',
            'reduivy__Completion_Indicator_Student__c'
        };

        String srsQuery = 'SELECT ' + String.join(new List<String>(srsFields), ', ') + 
                         ' FROM ' + SRS_Helper.getApiName() + 
                         ' WHERE Id IN :srsIds';

        Map<String, Object> srsBindMap = new Map<String, Object> {
            'srsIds' => srsIds
        };

        Map<String, Set<String>> srsObjectFieldsForFls = new Map<String, Set<String>>{
            SRS_Helper.getApiName() => srsFields
        };

        // Get the parent objects for each SRS
        Map<Id, reduivy__Study_Requirement_Set__c> srsMap = new Map<Id, reduivy__Study_Requirement_Set__c>();
        Set<String> srsParentObjects = new Set<String>();

        for(reduivy__Study_Requirement_Set__c srs : (List<reduivy__Study_Requirement_Set__c>) REDU_SystemMode_UTIL.doQuery(srsQuery, srsBindMap, srsObjectFieldsForFls)) {
            srsMap.put(srs.Id, srs);

            if(String.isNotBlank(srs.reduivy__Object__c)) {
                srsParentObjects.add(srs.reduivy__Object__c);
            }
        }

        // We will need to perform DML within a loop later; this is to reduce the chances of hitting limits
        if(srsParentObjects.size() > MAX_PARENT_OBJECTS) {
            for(reduivy__Individual_Requirement_Set__c irs : irsMap.values()) {
                irs.addError(
                    String.format(Label.Too_Many_Parent_Objects_In_Transaction,
                            new List<String>{SRS_Helper.getObjectLabel(), String.join(srsParentObjects, ',')})
                );
            }
            return;
        }

        // Get the lookup field name in the IRS for each parent object
        Map<String, String> objectLookupFieldsMap = new Map<String, String>();

        if(!srsParentObjects.isEmpty()) {
            objectLookupFieldsMap = REDU_Metadata_UTIL.getObjectLookupField(IRS_Helper.getApiName(), srsParentObjects);
        }

        // Collect all parent objects and their lookup field names
        Map<String, Set<Id>> objectToParentIdsMap = new Map<String, Set<Id>>();
        Map<Id, List<reduivy__Individual_Requirement_Set__c>> sourceMapForUpdate = new Map<Id, List<reduivy__Individual_Requirement_Set__c>>();

        for (reduivy__Individual_Requirement_Set__c irs : relatedIrsList) {
            reduivy__Study_Requirement_Set__c parentSrs = srsMap.containsKey(irs.reduivy__Study_Requirement_Set__c) ? srsMap.get(irs.reduivy__Study_Requirement_Set__c) : null;
            String parentObjectName = parentSrs != null ? parentSrs.reduivy__Object__c : '';

            String parentLookupField = String.isNotBlank(parentObjectName) && objectLookupFieldsMap.containsKey(parentObjectName) 
            ? objectLookupFieldsMap.get(parentObjectName) : '';

            Id parentRecordId = String.isNotBlank(parentLookupField) ?(Id) irs.get(parentLookupField) : null;

            if (parentRecordId != null) {
                if (!sourceMapForUpdate.containsKey(parentRecordId)) {
                    sourceMapForUpdate.put(parentRecordId, new List<reduivy__Individual_Requirement_Set__c>());
                }
                sourceMapForUpdate.get(parentRecordId).add(irs);

                if (!objectToParentIdsMap.containsKey(parentObjectName)) {
                    objectToParentIdsMap.put(parentObjectName, new Set<Id>());
                }
                objectToParentIdsMap.get(parentObjectName).add(parentRecordId);
            }
        }

        // For each parent object, query all related IRS records
        Map<String, Map<Id, List<reduivy__Individual_Requirement_Set__c>>> objectToParentIrsMap = new Map<String, Map<Id, List<reduivy__Individual_Requirement_Set__c>>>();

        Set<String> irsFields = new Set<String> {
            'Id',
            'reduivy__Total_Requirement__c',
            'reduivy__Total_Reviewed__c',
            'reduivy__Total_Submitted__c',
            'reduivy__Total_Requirement_Faculty__c',
            'reduivy__Total_Reviewed_Faculty__c',
            'reduivy__Total_Submitted_Faculty__c',
            'reduivy__Total_Requirement_Student__c',
            'reduivy__Total_Reviewed_Student__c',
            'reduivy__Total_Submitted_Student__c',
            'reduivy__Study_Requirement_Set__c',
            'reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Admin__c',
            'reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Faculty__c',
            'reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Student__c',
            'reduivy__Status__c',
            'reduivy__Study_Requirement_Set__r.reduivy__Object__c'
        };

        if(!objectLookupFieldsMap.isEmpty()) {
            irsFields.addAll(objectLookupFieldsMap.values());
        }

        Map<String, Set<String>> irsObjectFieldsForFls = new Map<String, Set<String>>{IRS_Helper.getApiName() => irsFields};

        // Collect all parent objects and build OR conditions
        List<String> whereConditions = new List<String>();
        Map<String, Object> allIrsBindMap = new Map<String, Object>();
        Integer bindCounter = 0;

        for (String objectName : objectToParentIdsMap.keySet()) {
            Set<Id> parentIds = objectToParentIdsMap.get(objectName);
            String lookupFieldName = objectLookupFieldsMap.containsKey(objectName) ? objectLookupFieldsMap.get(objectName) : '';
            
            if (String.isNotBlank(lookupFieldName)) {
                String parentIdsKey = 'parentIds' + bindCounter;
                String objectNameKey = 'objectName' + bindCounter;
                
                whereConditions.add('(' + lookupFieldName + ' IN :' + parentIdsKey + 
                                ' AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :' + objectNameKey + ')');
                
                allIrsBindMap.put(parentIdsKey, parentIds);
                allIrsBindMap.put(objectNameKey, objectName);
                bindCounter++;
            }
        }

        if (!whereConditions.isEmpty()) {
            String allIrsQuery = 'SELECT ' + String.join(new List<String>(irsFields), ', ') + 
                                ' FROM ' + IRS_Helper.getApiName() + 
                                ' WHERE ' + String.join(whereConditions, ' OR ');

            for (String objectName : objectToParentIdsMap.keySet()) {
                objectToParentIrsMap.put(objectName, new Map<Id, List<reduivy__Individual_Requirement_Set__c>>());
            }

            for (reduivy__Individual_Requirement_Set__c irs : (List<reduivy__Individual_Requirement_Set__c>) REDU_SystemMode_UTIL.doQuery(allIrsQuery, allIrsBindMap, irsObjectFieldsForFls)) {
                String parentObjectName = irs.reduivy__Study_Requirement_Set__r.reduivy__Object__c;
                String lookupFieldName = objectLookupFieldsMap.get(parentObjectName);
                
                if (String.isNotBlank(lookupFieldName)) {
                    Id parentRecordId = (Id) irs.get(lookupFieldName);
                    
                    if (!objectToParentIrsMap.get(parentObjectName).containsKey(parentRecordId)) {
                        objectToParentIrsMap.get(parentObjectName).put(parentRecordId, new List<reduivy__Individual_Requirement_Set__c>());
                    }
                    objectToParentIrsMap.get(parentObjectName).get(parentRecordId).add(irs);
                }
            }
        }

        // Process each parent object type and update separately
        for (String objectName : objectToParentIrsMap.keySet()) {
            List<SObject> parentsToUpdate = processParentObject(objectName, objectToParentIrsMap.get(objectName), irsMap);
            
            if (!parentsToUpdate.isEmpty()) {
                REDU_SystemMode_UTIL.doUpdate(parentsToUpdate, sourceMapForUpdate, 'Id', false);
            }
        }
    }

    /**
     * @description Process parent object and calculate completion indicators
     * @param objectName Parent object API name
     * @param parentIrsMap Map of parent record Id to IRS list
     * @param triggerRecordsMap Map of trigger context IRS records for error handling
     * @return List of parent SObjects to update
     */
    private List<SObject> processParentObject(String objectName, Map<Id, List<reduivy__Individual_Requirement_Set__c>> parentIrsMap, Map<Id, reduivy__Individual_Requirement_Set__c> sourceMap) {
        
        List<SObject> parentsToUpdate = new List<SObject>();
        
        // Collect all indicator fields for this parent object and map them to IRS IDs so they can be used with addError and queried later
        Map<String, Set<Id>> indicatorFieldsWithIrsIds = new Map<String, Set<Id>>();
        
        for (Id parentId : parentIrsMap.keySet()) {
            List<reduivy__Individual_Requirement_Set__c> irsList = parentIrsMap.get(parentId);
            for (reduivy__Individual_Requirement_Set__c irs : irsList) {
                if (String.isNotBlank(irs?.reduivy__Study_Requirement_Set__r?.reduivy__Completion_Indicator_Admin__c)) {
                    if (!indicatorFieldsWithIrsIds.containsKey(irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Admin__c)) {
                        indicatorFieldsWithIrsIds.put(irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Admin__c, new Set<Id>());
                    }
                    indicatorFieldsWithIrsIds.get(irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Admin__c).add(irs.Id);
                }
                if (String.isNotBlank(irs?.reduivy__Study_Requirement_Set__r?.reduivy__Completion_Indicator_Faculty__c)) {
                    if (!indicatorFieldsWithIrsIds.containsKey(irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Faculty__c)) {
                        indicatorFieldsWithIrsIds.put(irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Faculty__c, new Set<Id>());
                    }
                    indicatorFieldsWithIrsIds.get(irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Faculty__c).add(irs.Id);
                }
                if (String.isNotBlank(irs?.reduivy__Study_Requirement_Set__r?.reduivy__Completion_Indicator_Student__c)) {
                    if (!indicatorFieldsWithIrsIds.containsKey(irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Student__c)) {
                        indicatorFieldsWithIrsIds.put(irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Student__c, new Set<Id>());
                    }
                    indicatorFieldsWithIrsIds.get(irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Student__c).add(irs.Id);
                }
            }
        }

        if (indicatorFieldsWithIrsIds.isEmpty()) {
            return parentsToUpdate;
        }

        // This is for addError to identify the source record, so it can be removed from the map later
        Map<Id, Id> irsIdToParentIdMap = new Map<Id, Id>();
        for (Id parentId : parentIrsMap.keySet()) {
            for (reduivy__Individual_Requirement_Set__c irs : parentIrsMap.get(parentId)) {
                irsIdToParentIdMap.put(irs.Id, parentId);
            }
        }

        // Validate indicator fields exist and are checkboxes
        Map<String, Schema.SObjectField> fieldMap = REDU_Metadata_UTIL.describeSObject(objectName).fields.getMap();
        
        Set<Id> parentIdsWithErrors = new Set<Id>();
        List<String> fieldsToRemove = new List<String>();

        for (String fieldName : indicatorFieldsWithIrsIds.keySet()) {
            if (!fieldMap.containsKey(fieldName)) {
                // Add error to trigger context records
                for (Id irsId : indicatorFieldsWithIrsIds.get(fieldName)) {
                    if (sourceMap.containsKey(irsId)) {
                        sourceMap.get(irsId).addError(
                            String.format(Label.Invalid_Object_Field_Error,
                            new List<String>{fieldName, objectName})
                        );

                        if (irsIdToParentIdMap.containsKey(irsId)) {
                            parentIdsWithErrors.add(irsIdToParentIdMap.get(irsId));
                        }
                    }
                }

                fieldsToRemove.add(fieldName);

                continue;
            }
            
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if (fieldDescribe.getType() != Schema.DisplayType.BOOLEAN) {
                // Add error to trigger context records
                for (Id irsId : indicatorFieldsWithIrsIds.get(fieldName)) {
                    if (sourceMap.containsKey(irsId)) {
                        sourceMap.get(irsId).addError(
                            String.format(Label.Field_Not_Boolean,
                            new List<String>{fieldName, objectName})
                        );

                        if (irsIdToParentIdMap.containsKey(irsId)) {
                            parentIdsWithErrors.add(irsIdToParentIdMap.get(irsId));
                        }
                    }

                    fieldsToRemove.add(fieldName);
                }
            }
        }

        for(String f : fieldsToRemove){
            indicatorFieldsWithIrsIds.remove(f);
        }

        Set<Id> parentIdsToQuery = new Set<Id>(parentIrsMap.keySet());
        parentIdsToQuery.removeAll(parentIdsWithErrors);

        if (parentIdsToQuery.isEmpty()) {
            return parentsToUpdate;
        }

        // Query parent records
        Set<String> queryFields = new Set<String>{'Id'};

        if(!indicatorFieldsWithIrsIds.isEmpty()) {
            queryFields.addAll(indicatorFieldsWithIrsIds.keySet());
        }
        
        String parentQuery = 'SELECT ' + String.join(new List<String>(queryFields), ', ') + 
                            ' FROM ' + objectName + 
                            ' WHERE Id IN :parentIdsToQuery' + 
                            ' FOR UPDATE';

        Map<String, Object> bindMap = new Map<String, Object> {
            'parentIdsToQuery' => parentIdsToQuery
        };

        Map<String, Set<String>> objectFieldsForFls = new Map<String, Set<String>>{
            objectName => queryFields
        };

        // Calculate completion for each parent
        for (SObject parentRecord : (List<SObject>) REDU_SystemMode_UTIL.doQuery(parentQuery, bindMap, objectFieldsForFls)) {
            List<reduivy__Individual_Requirement_Set__c> irsList = parentIrsMap.containsKey(parentRecord.Id) ?parentIrsMap.get(parentRecord.Id) :null;
            
            if (irsList != null && !irsList.isEmpty()) {
                // Group IRS by indicator fields
                Map<String, List<reduivy__Individual_Requirement_Set__c>> adminIndicatorMap = new Map<String, List<reduivy__Individual_Requirement_Set__c>>();
                Map<String, List<reduivy__Individual_Requirement_Set__c>> facultyIndicatorMap = new Map<String, List<reduivy__Individual_Requirement_Set__c>>();
                Map<String, List<reduivy__Individual_Requirement_Set__c>> studentIndicatorMap = new Map<String, List<reduivy__Individual_Requirement_Set__c>>();

                for (reduivy__Individual_Requirement_Set__c irs : irsList) {
                    String adminField = irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Admin__c;
                    String facultyField = irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Faculty__c;
                    String studentField = irs.reduivy__Study_Requirement_Set__r.reduivy__Completion_Indicator_Student__c;

                    if (String.isNotBlank(adminField)) {
                        if (!adminIndicatorMap.containsKey(adminField)) {
                            adminIndicatorMap.put(adminField, new List<reduivy__Individual_Requirement_Set__c>());
                        }
                        adminIndicatorMap.get(adminField).add(irs);
                    }

                    if (String.isNotBlank(facultyField)) {
                        if (!facultyIndicatorMap.containsKey(facultyField)) {
                            facultyIndicatorMap.put(facultyField, new List<reduivy__Individual_Requirement_Set__c>());
                        }
                        facultyIndicatorMap.get(facultyField).add(irs);
                    }

                    if (String.isNotBlank(studentField)) {
                        if (!studentIndicatorMap.containsKey(studentField)) {
                            studentIndicatorMap.put(studentField, new List<reduivy__Individual_Requirement_Set__c>());
                        }
                        studentIndicatorMap.get(studentField).add(irs);
                    }
                }

                SObject parentToUpdate = parentRecord.getSObjectType().newSObject(parentRecord.Id);
                Boolean hasChanges = false;

                // Update admin indicators
                for (String adminField : adminIndicatorMap.keySet()) {
                    Boolean adminComplete = calculateCompletion(adminIndicatorMap.get(adminField), IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN);
                    if (parentRecord.get(adminField) != adminComplete) {
                        parentToUpdate.put(adminField, adminComplete);
                        hasChanges = true;
                    }
                }

                // Update faculty indicators
                for (String facultyField : facultyIndicatorMap.keySet()) {
                    Boolean facultyComplete = calculateCompletion(facultyIndicatorMap.get(facultyField), IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY);
                    if (parentRecord.get(facultyField) != facultyComplete) {
                        parentToUpdate.put(facultyField, facultyComplete);
                        hasChanges = true;
                    }
                }

                // Update student indicators
                for (String studentField : studentIndicatorMap.keySet()) {
                    Boolean studentComplete = calculateCompletion(studentIndicatorMap.get(studentField), IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT);
                    if (parentRecord.get(studentField) != studentComplete) {
                        parentToUpdate.put(studentField, studentComplete);
                        hasChanges = true;
                    }
                }

                if (hasChanges) {
                    parentsToUpdate.add(parentToUpdate);
                }
            }
        }

        return parentsToUpdate;
    }

    /**
     * @description Calculate completion for a specific visibility
     * @param irsList List of Individual Requirement Sets
     * @param visibility visibility type (Admin, Faculty, Student)
     * @return Boolean indicating completion
     */
    private Boolean calculateCompletion(List<reduivy__Individual_Requirement_Set__c> irsList, String visibility) {
        
        for (reduivy__Individual_Requirement_Set__c irs : irsList) {
            // Skip inactive IRS
            if (irs.reduivy__Status__c != IRS_Helper.STATUS_ACTIVE) {
                continue;
            }

            Decimal totalRequirement = 0;
            Decimal totalCompleted = 0;

            if (visibility == IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN) {
                totalRequirement = irs.reduivy__Total_Requirement__c != null ? irs.reduivy__Total_Requirement__c : 0;
                totalCompleted = irs.reduivy__Total_Reviewed__c != null ? irs.reduivy__Total_Reviewed__c : 0;
            } else if (visibility == IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY) {
                totalRequirement = irs.reduivy__Total_Requirement_Faculty__c != null ? irs.reduivy__Total_Requirement_Faculty__c : 0;
                totalCompleted = irs.reduivy__Total_Reviewed_Faculty__c != null ? irs.reduivy__Total_Reviewed_Faculty__c : 0;
            } else if (visibility == IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT) {
                totalRequirement = irs.reduivy__Total_Requirement_Student__c != null ? irs.reduivy__Total_Requirement_Student__c : 0;
                totalCompleted = irs.reduivy__Total_Submitted_Student__c != null ? irs.reduivy__Total_Submitted_Student__c : 0;
            }

            // If any active IRS is not complete, return false
            if (totalRequirement > 0 && totalCompleted < totalRequirement) {
                return false;
            }
        }

        // All active IRS are complete
        return true;
    }
}