/**
 * @author      WDCi (XiRouh)
 * @date        Jan 2026
 * @group       
 * @description To clone new Individual Enrollment across to a different academic profile based on the recognition mapping if the criteria matches.
 * @changehistory
 * ISS-002513 16-01-2026 XiRouh - new class
 */
public inherited sharing class IEN_CloneRecognizedUnit_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual Program Enrollment - in progress statuses
     */
    private static final List<String> IPE_IN_PROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();

    /**
     * @description Study Plan Structure - Unit Record Type Id
     */
    private static final Id SPS_UNIT_RTID = SPS_Helper.getUnitRecordTypeId();

    /**
     * @description Individual enrollment student record type
     */
    private static final Id IEN_STUDENT_RTID = IEN_Helper.getStudentRecordTypeId();

    /**
     * @description IEN statuses that should be updated (not inserted) when cloning occurs.
     */
    private static final Set<String> IEN_UPDATEABLE_FOR_CLONING_STATUSES = new Set<String>();
    static {
        IEN_UPDATEABLE_FOR_CLONING_STATUSES.addAll(IEN_Helper.getOpenStatuses());
        IEN_UPDATEABLE_FOR_CLONING_STATUSES.addAll(IEN_Helper.getEnrollmentRequestedStatuses());
        IEN_UPDATEABLE_FOR_CLONING_STATUSES.addAll(IEN_Helper.getInProgressStatuses());
        IEN_UPDATEABLE_FOR_CLONING_STATUSES.addAll(IEN_Helper.getWaitlistedStatuses());
    }

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

            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                if(ienNew.RecordTypeId == IEN_STUDENT_RTID && 
                    !ienNew.reduivy__Credit_Transfer_Received__c && 
                    String.isNotBlank(ienNew.reduivy__Individual_Academic_Profile__c) &&
                    String.isNotBlank(ienNew.reduivy__Target_Unit_Id__c) &&
                    IEN_Helper.isRecognizable(ienNew, null)
                ) {
                    ienList.add(ienNew);
                }
            }

            cloneRecognizedUnit(ienList);
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

            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);

                if(ienNew.RecordTypeId == IEN_STUDENT_RTID &&
                    !ienNew.reduivy__Credit_Transfer_Received__c && 
                    String.isNotBlank(ienNew.reduivy__Individual_Academic_Profile__c) &&
                    String.isNotBlank(ienNew.reduivy__Target_Unit_Id__c) &&
                    (
                        (IEN_Helper.isRecognizable(ienNew, ienOld)) ||
                        (IEN_Helper.isRecognizable(ienNew, null) &&
                            (ienNew.reduivy__Target_Unit_Id__c != ienOld.reduivy__Target_Unit_Id__c) ||
                            (ienNew.reduivy__Individual_Academic_Profile__c != ienOld.reduivy__Individual_Academic_Profile__c)
                        )
                    )
                ) {
                    ienList.add(ienNew);
                }
            }

            cloneRecognizedUnit(ienList);
        }
    }

    /**
     * @description Clone Individual Enrollment records to other Academic Profiles based on Auto Unit Recognition Scope
     * @param ienList List of Individual Enrollment records to process
     * @return void
     */
    private void cloneRecognizedUnit(List<reduivy__Individual_Enrollment__c> ienList) {

        Map<Id, List<reduivy__Individual_Enrollment__c>> contactToIenMap = new Map<Id, List<reduivy__Individual_Enrollment__c>>();
        Map<Id, Set<Id>> contactToSunIds = new Map<Id, Set<Id>>();
        Set<Id> sunIds = new Set<Id>();

        for(reduivy__Individual_Enrollment__c ien : ienList) {
            
            if(String.isNotBlank(ien.reduivy__Contact__c) && String.isNotBlank(ien.reduivy__Target_Unit_Id__c)) {
                if(!contactToSunIds.containsKey(ien.reduivy__Contact__c)) {
                    contactToSunIds.put(ien.reduivy__Contact__c, new Set<Id>());
                }
                contactToSunIds.get(ien.reduivy__Contact__c).add(ien.reduivy__Target_Unit_Id__c);
            }
            
            if(String.isNotBlank(ien.reduivy__Contact__c)) {
                if(!contactToIenMap.containsKey(ien.reduivy__Contact__c)) {
                    contactToIenMap.put(ien.reduivy__Contact__c, new List<reduivy__Individual_Enrollment__c>());
                }
                contactToIenMap.get(ien.reduivy__Contact__c).add(ien);
            }

            if(String.isNotBlank(ien.reduivy__Target_Unit_Id__c)) {
                sunIds.add(ien.reduivy__Target_Unit_Id__c);
            }
        }

        if(contactToIenMap.isEmpty()) {
            return;
        }

        // Find all the IPE under the contact
        Set<Id> splIds = new Set<Id>();
        Map<Id, List<reduivy__Individual_Program_Enrollment__c>> ipfIdWithIpes = new Map<Id, List<reduivy__Individual_Program_Enrollment__c>>();
        Map<Id, List<reduivy__Individual_Program_Enrollment__c>> contactToIpeMap = new Map<Id, List<reduivy__Individual_Program_Enrollment__c>>();
        Map<Id, Id> ipfToContactId = new Map<Id, Id>();

        Boolean hasAnyAutoRecognitionScope = false;

        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, 
                reduivy__Contact__c,
                reduivy__Individual_Academic_Profile__c, 
                reduivy__Master_Enrollment__c,
                reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c,
                reduivy__Study_Plan__c,
                reduivy__Study_Program__c,
                reduivy__Study_Program__r.reduivy__Auto_Unit_Recognition_Scope__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__c IN :contactToIenMap.keySet()
            AND reduivy__Enrollment_Status__c IN :IPE_IN_PROGRESS_STATUSES
            WITH USER_MODE
        ]) {
            if(String.isNotBlank(ipe.reduivy__Study_Plan__c)) {
                splIds.add(ipe.reduivy__Study_Plan__c);

                if(!contactToIpeMap.containsKey(ipe.reduivy__Contact__c)) {
                    contactToIpeMap.put(ipe.reduivy__Contact__c, new List<reduivy__Individual_Program_Enrollment__c>());
                }

                contactToIpeMap.get(ipe.reduivy__Contact__c).add(ipe);

                Id ipfId = IPE_Helper.getIpfId(ipe);
                
                // Group IPEs by academic profile for mixed-scope validation
                if(!ipfIdWithIpes.containsKey(ipfId)) {
                    ipfIdWithIpes.put(ipfId, new List<reduivy__Individual_Program_Enrollment__c>());
                }
                ipfIdWithIpes.get(ipfId).add(ipe);

                if(String.isNotBlank(ipfId)) {
                    ipfToContactId.put(ipfId, ipe.reduivy__Contact__c);
                }

                // Check if any IPE has the auto unit recognition scope configured
                if(!hasAnyAutoRecognitionScope && ipe?.reduivy__Study_Program__r?.reduivy__Auto_Unit_Recognition_Scope__c == SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES) {
                    hasAnyAutoRecognitionScope = true;
                }
            }
        }

        if(!hasAnyAutoRecognitionScope || splIds.isEmpty() || sunIds.isEmpty()) {
            return;
        }

        // Find out which Study Plans contain which Study Units
        Map<Id, Set<Id>> splIdWithSunIds = new Map<Id, Set<Id>>();

        for(reduivy__Study_Plan_Structure__c spsUnit : [
            SELECT Id, 
                Name,
                reduivy__Study_Unit__c,
                reduivy__Study_Plan__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE RecordTypeId = :SPS_UNIT_RTID
            AND reduivy__Study_Plan__c IN :splIds
            AND reduivy__Study_Unit__c IN :sunIds
            WITH USER_MODE
        ]){
            if(!splIdWithSunIds.containsKey(spsUnit.reduivy__Study_Plan__c)) {
                splIdWithSunIds.put(spsUnit.reduivy__Study_Plan__c, new Set<Id>());
            }
            splIdWithSunIds.get(spsUnit.reduivy__Study_Plan__c).add(spsUnit.reduivy__Study_Unit__c);
        }

        if(splIdWithSunIds.isEmpty()) {
            return;
        }

        // Validate mixture of Auto Unit Recognition Scope and determine target IPFs
        Set<Id> ipfIdsWithMixedScopes = IPE_Helper.validateIpfsWithMixedAutoUnitScopes(ipfIdWithIpes);

        // To track which IPF should receive clones for which Study Units
        // IPF Id, Set of Study Unit Ids that should be cloned to this IPF
        Map<Id, Set<Id>> ipfWithSunIdsToBeCloned = new Map<Id, Set<Id>>();
        
        // To track source IEN for each IPF and Study Unit combination
        // IPF Id, Study Unit Id, Source IEN
        Map<Id, Map<Id, reduivy__Individual_Enrollment__c>> ipfToSunToSourceIen = new Map<Id, Map<Id, reduivy__Individual_Enrollment__c>>();

        // Process each contact's enrollments
        for(Id contactId : contactToIenMap.keySet()) {
            if(!contactToSunIds.containsKey(contactId) || contactToSunIds.get(contactId).isEmpty()) {
                continue;
            }

            // The study unit IDs that need to be cloned for this contact
            Set<Id> contactSunIds = contactToSunIds.get(contactId);

            // The contact's source IEN
            List<reduivy__Individual_Enrollment__c> contactIens = contactToIenMap.get(contactId);

            // Get all IPFs for this contact
            Map<Id, Set<Id>> ipfToSunIdsInStudyPlan = new Map<Id, Set<Id>>();

            List<reduivy__Individual_Program_Enrollment__c> contactIpes = contactToIpeMap.containsKey(contactId) ? contactToIpeMap.get(contactId) : null;
            
            if(contactIpes == null || contactIpes.isEmpty()) {
                continue;
            }

            for(reduivy__Individual_Program_Enrollment__c ipe : contactIpes) {
                Id ipfId = IPE_Helper.getIpfId(ipe);
                
                // Skip if this IPF has scope = None 
                if(String.isBlank(ipe?.reduivy__Study_Program__r?.reduivy__Auto_Unit_Recognition_Scope__c) || ipe?.reduivy__Study_Program__r?.reduivy__Auto_Unit_Recognition_Scope__c != SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES) {
                    continue;
                }

                // Get Study Units in this IPE's Study Plan
                if(String.isNotBlank(ipe.reduivy__Study_Plan__c) && splIdWithSunIds.containsKey(ipe.reduivy__Study_Plan__c)) {
                    if(!ipfToSunIdsInStudyPlan.containsKey(ipfId)) {
                        ipfToSunIdsInStudyPlan.put(ipfId, new Set<Id>());
                    }
                    ipfToSunIdsInStudyPlan.get(ipfId).addAll(splIdWithSunIds.get(ipe.reduivy__Study_Plan__c));
                }
            }

            // For each source IEN, determine which IPFs should receive clones
            for(reduivy__Individual_Enrollment__c sourceIen : contactIens) {
                Id sourceIpfId = sourceIen.reduivy__Individual_Academic_Profile__c;
                Id sunId = sourceIen.reduivy__Target_Unit_Id__c;

                if(String.isBlank(sunId) || String.isBlank(sourceIpfId)) {
                    continue;
                }

                // Check all other IPFs for this contact
                for(Id targetIpfId : ipfToSunIdsInStudyPlan.keySet()) {

                    // Don't clone to the same IPF
                    if((ipfToContactId.containsKey(targetIpfId) && (ipfToContactId.get(targetIpfId) != contactId)) || targetIpfId == sourceIpfId) {
                        continue;
                    }

                    // Check if this IPF's study plans contain this Study Unit
                    if(ipfToSunIdsInStudyPlan.get(targetIpfId).contains(sunId)) {
                        if(!ipfWithSunIdsToBeCloned.containsKey(targetIpfId)) {
                            ipfWithSunIdsToBeCloned.put(targetIpfId, new Set<Id>());
                            ipfToSunToSourceIen.put(targetIpfId, new Map<Id, reduivy__Individual_Enrollment__c>());
                        }
                        ipfWithSunIdsToBeCloned.get(targetIpfId).add(sunId);
                        ipfToSunToSourceIen.get(targetIpfId).put(sunId, sourceIen);
                    }
                }
            }
        }

        // targetIpfId_studyUnitId, source IEN
        Map<String, reduivy__Individual_Enrollment__c> cloningRequestMap = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> sourceIenByKey = new Map<String, reduivy__Individual_Enrollment__c>();
        Map<Id, reduivy__Individual_Enrollment__c> sourceIens = new Map<Id, reduivy__Individual_Enrollment__c>();

        String spgAutoUnitRecognitionScopeFieldLabel = Schema.SObjectType.reduivy__Study_Program__c.fields.reduivy__Auto_Unit_Recognition_Scope__c.getLabel();
        
        for(Id targetIpfId : ipfWithSunIdsToBeCloned.keySet()) {
            // Check if this IPF has mixed scopes
            if(ipfIdsWithMixedScopes.contains(targetIpfId)) {
        
                Map<Id, reduivy__Individual_Enrollment__c> sunToSourceIen = 
                    ipfToSunToSourceIen.containsKey(targetIpfId) ? ipfToSunToSourceIen.get(targetIpfId) : null;

                if(sunToSourceIen != null) {
                    for(reduivy__Individual_Enrollment__c sourceIen : sunToSourceIen.values()) {
                        sourceIen.addError(String.format(Label.Mixture_Of_Recognition_Scope_Found, new List<String>{SPG_Helper.getObjectPluralLabel(), spgAutoUnitRecognitionScopeFieldLabel, IPF_Helper.getObjectLabel()}));
                    }
                }

                continue;
            }

            for(Id sunId : ipfWithSunIdsToBeCloned.get(targetIpfId)) {
                reduivy__Individual_Enrollment__c sourceIen = 
                    ipfToSunToSourceIen.containsKey(targetIpfId) && ipfToSunToSourceIen.get(targetIpfId).containsKey(sunId) 
                        ? ipfToSunToSourceIen.get(targetIpfId).get(sunId)
                        : null;
                
                if(sourceIen != null) {
                    String requestKey = targetIpfId + '_' + sunId;
                    cloningRequestMap.put(requestKey, sourceIen);
                    sourceIens.put(sourceIen.Id, sourceIen);

                    // Track source IEN for error handling
                    String sourceKey = sourceIen.Id;
                    if(!sourceIenByKey.containsKey(sourceKey)) {
                        sourceIenByKey.put(sourceKey, sourceIen);
                    }
                }
            }
        }

        Map<String, List<reduivy__Individual_Enrollment__c>> clonedIensMap = new Map<String, List<reduivy__Individual_Enrollment__c>>();
        Map<String, List<Id>> existingUpdateableIenToUpdate = new Map<String, List<Id>>();

        if(!cloningRequestMap.isEmpty()) {
            // Parse cloning request map to extract target IPFs and Study Units
            Set<Id> allTargetIpfIds = new Set<Id>();
            Set<Id> allTargetSunIds = new Set<Id>();

            for(String requestKey : cloningRequestMap.keySet()) {
                List<String> parts = requestKey.split('_');
                if(parts.size() == 2) {
                    allTargetIpfIds.add((Id)parts[0]);
                    allTargetSunIds.add((Id)parts[1]);
                }
            }

            // Prepare field mappings grouped by status_grade
            Map<String, IEN_Helper.AutoRecognitionMappingConfig> statusGradeToMappingData = IEN_Helper.prepareAutoRecognitionFieldMappings(sourceIens.values());

            // Collect all fields needed across all mappings
            Set<String> allFieldsToQuery = new Set<String>();

            for(IEN_Helper.AutoRecognitionMappingConfig mappingData : statusGradeToMappingData.values()) {
                if(!mappingData.fieldsToQuery.isEmpty()) {
                    allFieldsToQuery.addAll(mappingData.fieldsToQuery);
                }
            }

            // Source IENs with all required fields
            Map<Id, reduivy__Individual_Enrollment__c> sourceIensWithAllFields = new Map<Id, reduivy__Individual_Enrollment__c>();

            // Existing IENs to avoid duplicates (non-enrollable)
            Map<String, reduivy__Individual_Enrollment__c> existingIenMap = new Map<String, reduivy__Individual_Enrollment__c>();
            
            Map<String, List<reduivy__Individual_Enrollment__c>> existingUpdateableIenMap = new Map<String, List<reduivy__Individual_Enrollment__c>>();

            Set<String> ienFields = new Set<String>{
                'Id',
                'reduivy__Contact__c',
                'reduivy__Target_Unit_Id__c',
                'reduivy__Individual_Academic_Profile__c',
                'reduivy__Enrollment_Status__c',
                'reduivy__Grade_Result__c'
            };

            if(!allFieldsToQuery.isEmpty()) {
                ienFields.addAll(allFieldsToQuery);
            }

            Set<String> statusesToQuery = new Set<String>();
            statusesToQuery.addAll(IEN_Helper.getNonEnrollableStatuses());
            statusesToQuery.addAll(IEN_UPDATEABLE_FOR_CLONING_STATUSES);
            
            String ienSoql = 'SELECT ' + String.join(new List<String>(ienFields), ', ') +
                        ' FROM reduivy__Individual_Enrollment__c ' +
                        ' WHERE Id IN :sourceIenIds ' +
                        ' OR (reduivy__Individual_Academic_Profile__c IN :allTargetIpfIds ' +
                        ' AND reduivy__Target_Unit_Id__c IN :allTargetSunIds ' +
                        ' AND RecordTypeId = :studentRTId ' +
                        ' AND reduivy__Enrollment_Status__c IN :statusesToQuery) ' + 
                        ' ORDER BY CreatedDate DESC ';

            Map<String, Object> ienBindParams = new Map<String, Object>();
            ienBindParams.put('sourceIenIds', sourceIens.keySet());
            ienBindParams.put('allTargetIpfIds', allTargetIpfIds);
            ienBindParams.put('allTargetSunIds', allTargetSunIds);
            ienBindParams.put('studentRTId', IEN_Helper.getStudentRecordTypeId());
            ienBindParams.put('statusesToQuery', statusesToQuery);
            
            for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(ienSoql, ienBindParams, AccessLevel.USER_MODE)) {
                // If IEN is a source IEN
                if(sourceIens.containsKey(ien.Id)) {
                    sourceIensWithAllFields.put(ien.Id, ien);
                }

                // If IEN matches target IPF + target study unit
                if(allTargetIpfIds.contains(ien.reduivy__Individual_Academic_Profile__c) && allTargetSunIds.contains(ien.reduivy__Target_Unit_Id__c)) {
                    String key = ien.reduivy__Individual_Academic_Profile__c + '_' + ien.reduivy__Target_Unit_Id__c;
                    
                    // Track all updateable status IENs for reuse
                    if(IEN_UPDATEABLE_FOR_CLONING_STATUSES.contains(ien.reduivy__Enrollment_Status__c)) {
                        if(!existingUpdateableIenMap.containsKey(key)) {
                            existingUpdateableIenMap.put(key, new List<reduivy__Individual_Enrollment__c>());
                        }
                        existingUpdateableIenMap.get(key).add(ien);
                    } else if(IEN_Helper.getNonEnrollableStatuses().contains(ien.reduivy__Enrollment_Status__c)) {
                        existingIenMap.put(key, ien);
                    }
                }
            }

            // Mark all existing updateable IENs for update
            for(String requestKey : cloningRequestMap.keySet()) {
                if(existingUpdateableIenMap.containsKey(requestKey)) {
                    List<Id> ienIdsToUpdate = new List<Id>();
                    for(reduivy__Individual_Enrollment__c existingIen : existingUpdateableIenMap.get(requestKey)) {
                        ienIdsToUpdate.add(existingIen.Id);
                    }
                    existingUpdateableIenToUpdate.put(requestKey, ienIdsToUpdate);
                }
            }

            clonedIensMap = IEN_Helper.prepareClonedIens(cloningRequestMap, sourceIensWithAllFields, existingIenMap, statusGradeToMappingData, existingUpdateableIenToUpdate);
        }

        if(!clonedIensMap.isEmpty()) {
            Map<String, List<reduivy__Individual_Enrollment__c>> clonesBySourceId = new Map<String, List<reduivy__Individual_Enrollment__c>>();
            
            for(String requestKey : clonedIensMap.keySet()) {
                List<reduivy__Individual_Enrollment__c> clonedIens = clonedIensMap.get(requestKey);
                reduivy__Individual_Enrollment__c sourceIen = cloningRequestMap.get(requestKey);
                String sourceKey = sourceIen.Id;
                
                if(!clonesBySourceId.containsKey(sourceKey)) {
                    clonesBySourceId.put(sourceKey, new List<reduivy__Individual_Enrollment__c>());
                }
                
                // Add all cloned IENs to the list
                clonesBySourceId.get(sourceKey).addAll(clonedIens);
            }
            
            REDU_Database_UTIL.doUpsert(clonesBySourceId, sourceIenByKey, false);
        }
    }
}