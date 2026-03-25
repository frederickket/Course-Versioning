/**
 * @author      WDCi (VTan)
 * @date        Nov 2023
 * @group       Trigger executable
 * @description This is to create all required unit individual plan structure or optional unit individual plan structure if the student has any in progress/completed individual enrollment for the unit when a new group individual plan structure is created.
 * @changehistory
 * ISS-001823 27-11-2023 VTan - new class
 * ISS-001815 08-12-2023 Lean - Enhanced to support creation of option unit ips if it has existing ien
 * ISS-001910 25-03-2024 VTan - Enhancement to set the IPS Unit status
 * ISS-002395 26-05-2025 XiRouh - Updated to retrieve the contactIdWithIen using IEN_Helper.sortStudentIenBasedOnPriority()
 * ISS-002486 12-06-2025 XiRouh - Updated getCompletedStatuses to getCompletedPassStatuses
 * ISS-002542 14-07-2025 XiRouh - Updated to also create a placeholder IEN if the study plan's creation mode is set to 'Required Units Only'
 * ISS-002743 09-12-2025 XiRouh - Updated to use IPF-based grouping instead of Contact-based grouping
 * ISS-002513 26-01-2026 XiRouh - Enhanced to support auto unit recognition cloning
 */
public inherited sharing class IPS_CreateUnitIps_EXE extends REDU_TriggerExecutable {
    
    static final Set<String> IEN_POSITIVE_STATUSES = new Set<String>();
    static {
        IEN_POSITIVE_STATUSES.addAll(IEN_Helper.getInProgressStatuses());
        IEN_POSITIVE_STATUSES.addAll(IEN_Helper.getCompletedPassStatuses());
        IEN_POSITIVE_STATUSES.addAll(IEN_Helper.getWithdrawalRequestedStatuses());
        IEN_POSITIVE_STATUSES.addAll(IEN_Helper.getDeferredStatuses());
    }

    static final String IEN_OPEN_STATUSES = IEN_Helper.getOpenStatuses().get(0);

    /**
     * @description Auto Unit Recognition Config Enrollment Status With Grade Result Map
     */
    private static final Map<String, Set<String>> UNIT_RECOGNITION_STATUS_GRADE_MAP = IEN_Helper.getUnitRecognitionStatusGradeMap();

    /**
     * @description Auto Unit Recognition Config Enrollment Statuses
     */
    private static final Set<String> IEN_RECOGNIZABLE_ENROLLMENT_STATUSES = UNIT_RECOGNITION_STATUS_GRADE_MAP.keySet();

    /**
     * @description IEN statuses that should be updated (not inserted) when cloning occurs.
     */
    static final Set<String> IEN_UPDATEABLE_FOR_CLONING_STATUSES = new Set<String>();
    static {
        IEN_UPDATEABLE_FOR_CLONING_STATUSES.addAll(IEN_Helper.getOpenStatuses());
        IEN_UPDATEABLE_FOR_CLONING_STATUSES.addAll(IEN_Helper.getEnrollmentRequestedStatuses());
        IEN_UPDATEABLE_FOR_CLONING_STATUSES.addAll(IEN_Helper.getInProgressStatuses());
        IEN_UPDATEABLE_FOR_CLONING_STATUSES.addAll(IEN_Helper.getWaitlistedStatuses());
    }

    /**
     * @description AfterInsert
     */
    public override void executeAfterInsert (
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult
    ) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Id ipsGroupRecordTypeId = IPS_Helper.getGroupRecordTypeId();
            Id ipsUnitRecordTypeId = IPS_Helper.getUnitRecordTypeId();
            Id spsUnitRecordTypeId = SPS_Helper.getUnitRecordTypeId();

            Map<Id, reduivy__Individual_Plan_Structure__c> ipsGroupMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
            Map<String, reduivy__Individual_Plan_Structure__c> sourceObjMapForIenInsertion = new Map<String, reduivy__Individual_Plan_Structure__c>();
            Set<Id> spsGroupIds = new Set<Id>();
            Set<Id> sourceIpeIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();

            for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>) newList) {
                if (String.isNotBlank(ips.reduivy__Contact_Id__c) &&
                    String.isNotBlank(ips.reduivy__Individual_Program_Enrollment__c) && 
                    String.isNotBlank(ips.reduivy__Study_Plan_Structure__c) && 
                    ips.RecordTypeId == ipsGroupRecordTypeId
                ) {
                    ipsGroupMap.put(ips.Id, ips);
                    sourceObjMapForIenInsertion.put(ips.Id, ips);
                    spsGroupIds.add(ips.reduivy__Study_Plan_Structure__c);
                    sourceIpeIds.add(ips.reduivy__Individual_Program_Enrollment__c);
                    contactIds.add(ips.reduivy__Contact_Id__c);
                }
            }

            if (!ipsGroupMap.isEmpty()) {

                // Query ALL IPE under these contacts for scope validation and cloning
                Map<Id, Id> ipeToIpfMap = new Map<Id, Id>();
                Map<Id, Id> sourceIpeToIpfMap = new Map<Id, Id>();
                Set<Id> ipfIds = new Set<Id>();
                Set<Id> sourceIpfIds = new Set<Id>();
                Map<Id, List<reduivy__Individual_Program_Enrollment__c>> ipfIdWithIpes = new Map<Id, List<reduivy__Individual_Program_Enrollment__c>>();
                Map<Id, List<reduivy__Individual_Program_Enrollment__c>> ipfIdWithSourceIpes = new Map<Id, List<reduivy__Individual_Program_Enrollment__c>>();
                Set<Id> splIds = new Set<Id>();

                Boolean hasAnyAutoRecognitionScope = false;

                for (reduivy__Individual_Program_Enrollment__c ipe : [
                    SELECT Id, 
                        reduivy__Contact__c,
                        reduivy__Individual_Academic_Profile__c,
                        reduivy__Master_Enrollment__c,
                        reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c,
                        reduivy__Study_Plan__c,
                        reduivy__Study_Program__c,
                        reduivy__Study_Program__r.reduivy__Auto_Unit_Recognition_Scope__c
                    FROM reduivy__Individual_Program_Enrollment__c
                    WHERE reduivy__Contact__c IN :contactIds
                    WITH USER_MODE
                ]) {
                    Id ipfId = IPE_Helper.getIpfId(ipe);
                    
                    if(String.isNotBlank(ipfId)) {

                        if(!ipfIdWithIpes.containsKey(ipfId)) {
                            ipfIdWithIpes.put(ipfId, new List<reduivy__Individual_Program_Enrollment__c>());
                        }
                        ipfIdWithIpes.get(ipfId).add(ipe);

                        // Check if any IPE has the auto unit recognition scope configured
                        if(!hasAnyAutoRecognitionScope && ipe?.reduivy__Study_Program__r?.reduivy__Auto_Unit_Recognition_Scope__c == SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES) {
                            hasAnyAutoRecognitionScope = true;
                        }

                        if(sourceIpeIds.contains(ipe.Id)) {

                            ipeToIpfMap.put(ipe.Id, ipfId);
                            ipfIds.add(ipfId);

                            if(sourceIpeIds.contains(ipe.Id)) {
                                sourceIpeToIpfMap.put(ipe.Id, ipfId);
                                sourceIpfIds.add(ipfId);
                            }

                            if(String.isNotBlank(ipe.reduivy__Study_Plan__c)) {
                                splIds.add(ipe.reduivy__Study_Plan__c);
                            }

                            if(!ipfIdWithSourceIpes.containsKey(ipfId)) {
                                ipfIdWithSourceIpes.put(ipfId, new List<reduivy__Individual_Program_Enrollment__c>());
                            }
                            ipfIdWithSourceIpes.get(ipfId).add(ipe);
                        }
                    }
                }

                Set<Id> ipfIdsWithMixedScopes = new Set<Id>();

                Set<Id> ipfIdsEligibleForCloning = new Set<Id>();

                if(hasAnyAutoRecognitionScope) {
                    ipfIdsWithMixedScopes = IPE_Helper.validateIpfsWithMixedAutoUnitScopes(ipfIdWithIpes);

                    for(Id ipfId : sourceIpfIds) {
                        if(!ipfIdsWithMixedScopes.contains(ipfId) && ipfIdWithSourceIpes.containsKey(ipfId)) {
                            for(reduivy__Individual_Program_Enrollment__c ipe : ipfIdWithSourceIpes.get(ipfId)) {
                                if(String.isNotBlank(ipe?.reduivy__Study_Program__r?.reduivy__Auto_Unit_Recognition_Scope__c) && ipe?.reduivy__Study_Program__r?.reduivy__Auto_Unit_Recognition_Scope__c == SPG_Helper.AUTO_UNIT_RECOGNITION_SCOPE_ALL_ACADEMIC_PROFILES) {
                                    ipfIdsEligibleForCloning.add(ipfId);
                                    break;
                                }
                            }
                        }
                    }
                }

                Map<Id, List<reduivy__Study_Plan_Structure__c>> spsUnitsMap = new Map<Id, List<reduivy__Study_Plan_Structure__c>>();
                Set<Id> sunIds = new Set<Id>();
                Map<Id, Set<Id>> splIdWithSunIds = new Map<Id, Set<Id>>(); 

                for(reduivy__Study_Plan_Structure__c spsUnit : [SELECT Id, 
                    Name,
                    reduivy__Parent_Study_Plan_Structure__c, 
                    reduivy__Study_Unit__c,
                    reduivy__Study_Unit__r.Name,
                    reduivy__Allow_Pre_Enrollment__c,
                    reduivy__Category__c, 
                    reduivy__Credits__c,
                    reduivy__Description__c,
                    reduivy__Hide_in_Enrollment__c,
                    reduivy__Sequence__c, 
                    reduivy__Study_Plan__c,
                    reduivy__Study_Plan__r.reduivy__Individual_Enrollment_Creation_Mode__c
                    FROM reduivy__Study_Plan_Structure__c
                    WHERE RecordTypeId = :spsUnitRecordTypeId 
                    AND reduivy__Parent_Study_Plan_Structure__c IN :spsGroupIds
                    WITH USER_MODE
                ]){
                    if(!spsUnitsMap.containsKey(spsUnit.reduivy__Parent_Study_Plan_Structure__c)){
                        spsUnitsMap.put(spsUnit.reduivy__Parent_Study_Plan_Structure__c, new List<reduivy__Study_Plan_Structure__c>{spsUnit});
                    } else {
                        spsUnitsMap.get(spsUnit.reduivy__Parent_Study_Plan_Structure__c).add(spsUnit);
                    }

                    if (String.isNotBlank(spsUnit.reduivy__Study_Unit__c)) {
                        sunIds.add(spsUnit.reduivy__Study_Unit__c);
                    }

                    if(String.isNotBlank(spsUnit.reduivy__Study_Plan__c) && String.isNotBlank(spsUnit.reduivy__Study_Unit__c)) {
                        if(!splIdWithSunIds.containsKey(spsUnit.reduivy__Study_Plan__c)) {
                            splIdWithSunIds.put(spsUnit.reduivy__Study_Plan__c, new Set<Id>());
                        }
                        splIdWithSunIds.get(spsUnit.reduivy__Study_Plan__c).add(spsUnit.reduivy__Study_Unit__c);
                    }
                }

                if(!spsUnitsMap.isEmpty()){
                    Map<String, IEN_Helper.AutoRecognitionMappingConfig> initialMappingData = new Map<String, IEN_Helper.AutoRecognitionMappingConfig>();
                    Set<String> allFieldsToQuery = new Set<String>();

                    if(hasAnyAutoRecognitionScope) {
                        initialMappingData = IEN_Helper.prepareAutoRecognitionFieldMappings(new List<reduivy__Individual_Enrollment__c>());
                        
                        for(IEN_Helper.AutoRecognitionMappingConfig mappingData : initialMappingData.values()) {
                            if(!mappingData.fieldsToQuery.isEmpty()) {
                                allFieldsToQuery.addAll(mappingData.fieldsToQuery);
                            }
                        }
                    }

                    Set<String> ienFields = new Set<String>{
                        'Id',
                        'reduivy__Contact__c',
                        'reduivy__Individual_Academic_Profile__c',
                        'reduivy__Target_Unit_Id__c',
                        'reduivy__Enrollment_Status__c',
                        'reduivy__Grade_Result__c',
                        'reduivy__Attempt_Number__c',
                        'reduivy__Start_Date__c',
                        'reduivy__Enrollment_Date__c',
                        'CreatedDate'
                    };
                    
                    if(!allFieldsToQuery.isEmpty()) {
                        ienFields.addAll(allFieldsToQuery);
                    }

                    Set<String> statusesToBeQueried = new Set<String>();
                    statusesToBeQueried.addAll(IEN_POSITIVE_STATUSES);
                    statusesToBeQueried.addAll(IEN_Helper.getOpenStatuses());

                    String ienSoql;
                    Map<String, Object> ienBindParams = new Map<String, Object>();

                    if(hasAnyAutoRecognitionScope) {
                        statusesToBeQueried.addAll(IEN_RECOGNIZABLE_ENROLLMENT_STATUSES);
                        statusesToBeQueried.addAll(IEN_Helper.getNonEnrollableStatuses());

                        ienSoql = 'SELECT ' + String.join(new List<String>(ienFields), ', ') +
                                    ' FROM reduivy__Individual_Enrollment__c ' +
                                    ' WHERE reduivy__Contact__c IN :contactIds ' +
                                    ' AND reduivy__Target_Unit_Id__c IN :sunIds ' +
                                    ' AND reduivy__Enrollment_Status__c IN :statusesToBeQueried ' +
                                    ' AND reduivy__Enrollment_Type__c = :enrollmentType ' +
                                    ' ORDER BY CreatedDate DESC ';

                        ienBindParams.put('contactIds', contactIds);
                    } else {
                        ienSoql = 'SELECT ' + String.join(new List<String>(ienFields), ', ') +
                                    ' FROM reduivy__Individual_Enrollment__c ' +
                                    ' WHERE reduivy__Individual_Academic_Profile__c IN :ipfIds ' +
                                    ' AND reduivy__Target_Unit_Id__c IN :sunIds ' +
                                    ' AND reduivy__Enrollment_Status__c IN :statusesToBeQueried ' +
                                    ' AND reduivy__Enrollment_Type__c = :enrollmentType ' +
                                    ' ORDER BY CreatedDate DESC ';

                        ienBindParams.put('ipfIds', ipfIds);
                    }

                    ienBindParams.put('sunIds', sunIds);
                    ienBindParams.put('statusesToBeQueried', statusesToBeQueried);
                    ienBindParams.put('enrollmentType', IEN_Helper.ENROLLMENT_TYPE_PROGRAM);

                    Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();
                    List<reduivy__Individual_Enrollment__c> activeIenList = new List<reduivy__Individual_Enrollment__c>();

                    Map<Id, reduivy__Individual_Enrollment__c> allIensById = new Map<Id, reduivy__Individual_Enrollment__c>();
                    Map<String, List<reduivy__Individual_Enrollment__c>> recognizableIenByContactSun = new Map<String, List<reduivy__Individual_Enrollment__c>>();
                    Map<String, reduivy__Individual_Enrollment__c> existingIenMap = new Map<String, reduivy__Individual_Enrollment__c>();

                    Map<String, List<reduivy__Individual_Enrollment__c>> existingUpdateableIenMap = new Map<String, List<reduivy__Individual_Enrollment__c>>();

                    for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(ienSoql, ienBindParams, AccessLevel.USER_MODE)) {

                        if(IEN_POSITIVE_STATUSES.contains(ien.reduivy__Enrollment_Status__c)) {
                            activeIenList.add(ien);
                            ienMap.put(ien.Id, ien);
                        }

                        String key = ien.reduivy__Individual_Academic_Profile__c + '_' + ien.reduivy__Target_Unit_Id__c;

                        if(IEN_UPDATEABLE_FOR_CLONING_STATUSES.contains(ien.reduivy__Enrollment_Status__c)) {
                            if(!existingUpdateableIenMap.containsKey(key)) {
                                existingUpdateableIenMap.put(key, new List<reduivy__Individual_Enrollment__c>());
                            }
                            existingUpdateableIenMap.get(key).add(ien);
                        }

                        if(hasAnyAutoRecognitionScope) {
                            allIensById.put(ien.Id, ien);

                            // Store recognizable IENs by CONTACT_SUN key
                            if(IEN_Helper.isRecognizable(ien, null)) {
                                String contactSunKey = ien.reduivy__Contact__c + '_' + ien.reduivy__Target_Unit_Id__c;
                                if(!recognizableIenByContactSun.containsKey(contactSunKey)) {
                                    recognizableIenByContactSun.put(contactSunKey, new List<reduivy__Individual_Enrollment__c>());
                                }
                                recognizableIenByContactSun.get(contactSunKey).add(ien);
                            }

                            if(IEN_Helper.getNonEnrollableStatuses().contains(ien.reduivy__Enrollment_Status__c)) {
                                existingIenMap.put(key, ien);
                            }
                        }
                    }

                    Map<Id, Map<Id, reduivy__Individual_Enrollment__c>> ipfIdWithIen = IEN_Helper.sortStudentIenBasedOnPriority(activeIenList);

                    List<reduivy__Individual_Plan_Structure__c> newIpsUnitList = new List<reduivy__Individual_Plan_Structure__c>();
                    Map<String, List<reduivy__Individual_Enrollment__c>> allNewIensMap = new Map<String, List<reduivy__Individual_Enrollment__c>>();

                    Map<String, reduivy__Individual_Enrollment__c> cloningRequestMap = new Map<String, reduivy__Individual_Enrollment__c>();
                    Map<Id, reduivy__Individual_Enrollment__c> sourceIensForCloning = new Map<Id, reduivy__Individual_Enrollment__c>();
                    Map<String, reduivy__Individual_Plan_Structure__c> sourceIpsMapForCloning = new Map<String, reduivy__Individual_Plan_Structure__c>();
                    Map<String, List<Id>> existingUpdateableIenToUpdate = new Map<String, List<Id>>();

                    String spgAutoUnitRecognitionScopeFieldLabel = Schema.SObjectType.reduivy__Study_Program__c.fields.reduivy__Auto_Unit_Recognition_Scope__c.getLabel();

                    for(reduivy__Individual_Plan_Structure__c ipsGroup : ipsGroupMap.values()){

                        if(spsUnitsMap.containsKey(ipsGroup.reduivy__Study_Plan_Structure__c)){

                            Id ipfId = ipeToIpfMap.get(ipsGroup.reduivy__Individual_Program_Enrollment__c);

                            for(reduivy__Study_Plan_Structure__c spsUnit : spsUnitsMap.get(ipsGroup.reduivy__Study_Plan_Structure__c)){
                                String targetUnitId = spsUnit.reduivy__Study_Unit__c;
                                
                                String key = ipfId + '_' + targetUnitId;
                                String contactSunKey = ipsGroup.reduivy__Contact_Id__c + '_' + targetUnitId;
                                
                                Boolean hasExistingUpdateableIen = existingUpdateableIenMap.containsKey(key);
                                Boolean hasExistingActiveIen = ipfIdWithIen.containsKey(ipfId) && ipfIdWithIen.get(ipfId).containsKey(targetUnitId);
                                Boolean isRequired = spsUnit.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED;
                                Boolean hasRecognizableIen = hasAnyAutoRecognitionScope && recognizableIenByContactSun.containsKey(contactSunKey) && !existingIenMap.containsKey(key);
                                Boolean needPlaceholder = spsUnit.reduivy__Study_Plan__r.reduivy__Individual_Enrollment_Creation_Mode__c == SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;

                                if (isRequired || hasExistingActiveIen || hasRecognizableIen || hasExistingUpdateableIen) {
                                    Id targetIenId;
                                    Boolean willClone = false;

                                    if(hasExistingActiveIen) {
                                        targetIenId = ipfIdWithIen.get(ipfId).get(targetUnitId).Id;
                                    } else if(hasRecognizableIen) {
                                        Boolean canClone = ipfIdsEligibleForCloning.contains(ipfId);
                                        Boolean hasMixedScope = ipfIdsWithMixedScopes.contains(ipfId);

                                        if(canClone) {
                                            // Get recognizable IENs from CONTACT_SUN list and find one from different IPF
                                            List<reduivy__Individual_Enrollment__c> recognizableIens = recognizableIenByContactSun.get(contactSunKey);
                                            for(reduivy__Individual_Enrollment__c sourceIen : recognizableIens) {
                                                if(sourceIen.reduivy__Individual_Academic_Profile__c != ipfId) {
                                                    String requestKey = key;
                                                    cloningRequestMap.put(requestKey, sourceIen);
                                                    sourceIensForCloning.put(sourceIen.Id, sourceIen);
                                                    sourceIpsMapForCloning.put(requestKey, ipsGroup);
                                                    willClone = true;
                                                    
                                                    // If updateable IENs exist, mark all of them for update
                                                    if(hasExistingUpdateableIen) {
                                                        List<Id> ienIdsToUpdate = new List<Id>();
                                                        for(reduivy__Individual_Enrollment__c existingIen : existingUpdateableIenMap.get(key)) {
                                                            ienIdsToUpdate.add(existingIen.Id);
                                                        }
                                                        existingUpdateableIenToUpdate.put(requestKey, ienIdsToUpdate);
                                                    }
                                                    break;
                                                }
                                            }
                                        } else if(hasMixedScope) {
                                            ipsGroup.addError((String.format(Label.Mixture_Of_Recognition_Scope_Found, new List<String>{SPG_Helper.getObjectPluralLabel(), spgAutoUnitRecognitionScopeFieldLabel, IPF_Helper.getObjectLabel()})));
                                        }
                                    }

                                    reduivy__Individual_Plan_Structure__c ipsUnit = IPS_Helper.initUnitPlanStructure(
                                        ipsGroup.reduivy__Individual_Program_Enrollment__c,
                                        ipsGroup.Id,
                                        targetIenId,
                                        spsUnit
                                    );

                                    newIpsUnitList.add(ipsUnit);

                                    if(String.isNotBlank(ipfId) && 
                                       isRequired && 
                                       !hasExistingActiveIen &&
                                       !willClone &&
                                       !hasExistingUpdateableIen &&
                                       needPlaceholder) {
                                        reduivy__Individual_Enrollment__c ien = new reduivy__Individual_Enrollment__c(
                                            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                                            reduivy__Enrollment_Status__c = IEN_OPEN_STATUSES,
                                            reduivy__Study_Unit__c = targetUnitId,
                                            reduivy__Contact__c = ipsGroup.reduivy__Contact_Id__c,
                                            reduivy__Individual_Academic_Profile__c = ipfId
                                        );

                                        if(allNewIensMap.containsKey(ipsGroup.Id)) {
                                            allNewIensMap.get(ipsGroup.Id).add(ien);
                                        } else {
                                            allNewIensMap.put(ipsGroup.Id, new List<reduivy__Individual_Enrollment__c>{ien});
                                        }
                                        
                                        if(!existingUpdateableIenMap.containsKey(key)) {
                                            existingUpdateableIenMap.put(key, new List<reduivy__Individual_Enrollment__c>());
                                        }
                                        existingUpdateableIenMap.get(key).add(ien);
                                    }
                                }
                            }
                        }
                    }

                    if(!cloningRequestMap.isEmpty()) {
                        Map<String, IEN_Helper.AutoRecognitionMappingConfig> statusGradeToMappingData = IEN_Helper.prepareAutoRecognitionFieldMappings(sourceIensForCloning.values());

                        Map<Id, reduivy__Individual_Enrollment__c> sourceIensWithAllFields = new Map<Id, reduivy__Individual_Enrollment__c>();
                        for(Id sourceIenId : sourceIensForCloning.keySet()) {
                            if(allIensById.containsKey(sourceIenId)) {
                                sourceIensWithAllFields.put(sourceIenId, allIensById.get(sourceIenId));
                            }
                        }

                        Map<String, List<reduivy__Individual_Enrollment__c>> clonedIensMap = IEN_Helper.prepareClonedIens(
                            cloningRequestMap, 
                            sourceIensWithAllFields, 
                            existingIenMap, 
                            statusGradeToMappingData,
                            existingUpdateableIenToUpdate
                        );

                        for(String requestKey : clonedIensMap.keySet()) {
                            List<reduivy__Individual_Enrollment__c> clonedIens = clonedIensMap.get(requestKey);
                            reduivy__Individual_Plan_Structure__c sourceIps = sourceIpsMapForCloning.get(requestKey);
                            
                            if(sourceIps != null) {
                                String sourceKey = sourceIps.Id;
                                
                                if(allNewIensMap.containsKey(sourceKey)) {
                                    allNewIensMap.get(sourceKey).addAll(clonedIens);
                                } else {
                                    allNewIensMap.put(sourceKey, clonedIens);
                                }
                            }
                        }
                    }

                    newIpsUnitList = IPS_Helper.updateIpsUnitStatus(newIpsUnitList, ienMap);

                    if (!newIpsUnitList.isEmpty()) {
                        REDU_Database_UTIL.doInsert(newIpsUnitList, ipsGroupMap, 'reduivy__Parent_Plan_Structure__c', false);
                    }

                    if(!allNewIensMap.isEmpty()) {
                        REDU_Database_UTIL.doUpsert(allNewIensMap, sourceObjMapForIenInsertion, false);
                    }
                }
            }
        }
    }
}