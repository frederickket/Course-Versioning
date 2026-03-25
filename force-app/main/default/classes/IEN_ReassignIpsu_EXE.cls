/**
 * @author      WDCi (dblack)
 * @date        Nov 2023
 * @group       Trigger executable
 * @description This is to create new unit individual plan structure or reassign the existing unit individual plan structure when a new individual enrollment is created. When individual enrollment is deleted, the unit individual plan structure is reassigned too.
 * @changehistory
 * ISS-001763 02-11-2023 dblack - new class
 * ISS-001910 25-03-2024 VTan - Enhancement to set the IPS Unit status
 * ISS-002395 11-04-2025 XiRouh - Enhancement to reassign the IPS only when its status changes to or from active statuses, and added after update logic
 * ISS-002395 11-04-2025 XiRouh - updated to cater the revised after insert and after update logic: the reassignment logic will now run for all statuses, and will determine the appropriate IEN based on priority, attempt number, start date, and enrollment date
 * ISS-002395 26-05-2025 XiRouh - Updated to retrieve the contactIdWithIen using IEN_Helper.sortStudentIenBasedOnPriority()
 * ISS-002542 29-07-2025 XiRouh - Updated the trigger condition to run only when the combination of status and grade results matches the configured priority.
 * ISS-002743 09-12-2025 XiRouh - Updated to use IPF-based grouping instead of Contact-based grouping for IPS reassignment
 */
public inherited sharing class IEN_ReassignIpsu_EXE extends REDU_TriggerExecutable {

    static final Id IEN_STUDENT_RTID = IEN_Helper.getStudentRecordTypeId();
    static final Id IPS_UNIT_RTID = IPS_Helper.getUnitRecordTypeId();
    static final Id IPS_GROUP_RTID = IPS_Helper.getGroupRecordTypeId();
    static final Id SPS_UNIT_RTID = SPS_Helper.getUnitRecordTypeId();

    private static final Map<String, Integer> IEN_STATUSES_WITH_PRIORITY = IEN_Helper.getStatusPriorityMap();

    /**
     * @description Individual enrollment type
     */
    private static final String IEN_ENROLLMENTTYPE_PROGRAM = IEN_Helper.ENROLLMENT_TYPE_PROGRAM;

    /**
     * @description This is to create new unit individual plan structure or reassign the existing unit individual plan structure when a new individual enrollment is created.
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if ((operationType == TriggerOperation.AFTER_INSERT) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            Set<Id> sunIdSet = new Set<Id>();
            Set<Id> splIds = new Set<Id>();

            Map<Id, Set<Id>> ipfIenStudyUnitIdMap = new Map<Id, Set<Id>>();
            Map<String, List<reduivy__Individual_Enrollment__c>> sourceObjMap = new Map<String, List<reduivy__Individual_Enrollment__c>>();

            Set<String> enrollmentStatusWithPriority = IEN_STATUSES_WITH_PRIORITY.keySet();

            for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) newList) {
                if (ien.RecordTypeId == IEN_STUDENT_RTID &&
                    ien.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM &&
                    String.isNotBlank(ien.reduivy__Individual_Academic_Profile__c) &&
                    String.isNotBlank(ien.reduivy__Target_Unit_Id__c) &&
                    shouldReassign(ien, null)
                ) {
                    sunIdSet.add(ien.reduivy__Target_Unit_Id__c);

                    if (!ipfIenStudyUnitIdMap.containsKey(ien.reduivy__Individual_Academic_Profile__c)) {
                        ipfIenStudyUnitIdMap.put(ien.reduivy__Individual_Academic_Profile__c, new Set<Id>());
                    }
                    ipfIenStudyUnitIdMap.get(ien.reduivy__Individual_Academic_Profile__c).add(ien.reduivy__Target_Unit_Id__c);

                    String ipfSunKey = getIpfSunKey(ien);
                    if (!sourceObjMap.containsKey(ipfSunKey)) {
                        sourceObjMap.put(ipfSunKey, new List<reduivy__Individual_Enrollment__c>());
                    }
                    sourceObjMap.get(ipfSunKey).add(ien);
                }
            }

            if (!ipfIenStudyUnitIdMap.isEmpty()) {
                reassignIpsu(ipfIenStudyUnitIdMap, sunIdSet, sourceObjMap);
            }
        }
    }

    /**
     * @description  When individual enrollment is updated, the unit individual plan structure is reassigned to the last attempted individual enrollment.
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        if ((operationType == TriggerOperation.AFTER_UPDATE) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {
            Set<Id> sunIdSet = new Set<Id>();

            Map<Id, Set<Id>> ipfIenStudyUnitIdMap = new Map<Id, Set<Id>>();
            Map<String, List<reduivy__Individual_Enrollment__c>> sourceObjMap = new Map<String, List<reduivy__Individual_Enrollment__c>>();

            Set<String> enrollmentStatusWithPriority = IEN_STATUSES_WITH_PRIORITY.keySet();

            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);

                if (ienNew.RecordTypeId == IEN_STUDENT_RTID &&
                    ienNew.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM &&
                    String.isNotBlank(ienNew.reduivy__Individual_Academic_Profile__c) &&
                    String.isNotBlank(ienNew.reduivy__Target_Unit_Id__c) &&
                    shouldReassign(ienNew, ienOld)
                ) {
                    sunIdSet.add(ienNew.reduivy__Target_Unit_Id__c);

                    if (!ipfIenStudyUnitIdMap.containsKey(ienNew.reduivy__Individual_Academic_Profile__c)) {
                        ipfIenStudyUnitIdMap.put(ienNew.reduivy__Individual_Academic_Profile__c, new Set<Id>());
                    }
                    ipfIenStudyUnitIdMap.get(ienNew.reduivy__Individual_Academic_Profile__c).add(ienNew.reduivy__Target_Unit_Id__c);

                    String ipfSunKey = getIpfSunKey(ienNew);
                    if (!sourceObjMap.containsKey(ipfSunKey)) {
                        sourceObjMap.put(ipfSunKey, new List<reduivy__Individual_Enrollment__c>());
                    }
                    sourceObjMap.get(ipfSunKey).add(ienNew);
                }
            }

            if (!ipfIenStudyUnitIdMap.isEmpty()) {
                reassignIpsu(ipfIenStudyUnitIdMap, sunIdSet, sourceObjMap);
            }
        }
    }

    /**
     * @description Reassign the IPSU when it is not linked to the highest attempt number and the latest start date
     * @param ipfIenStudyUnitIdMap Map of IPF Id to Set of Study Unit Ids
     * @param sunIdSet Set of Study Unit Ids
     * @param sourceObjMap Map of IPF_SUN key to List of IENs
     * @return void
     */
    private void reassignIpsu(Map<Id, Set<Id>> ipfIenStudyUnitIdMap, Set<Id> sunIdSet, Map<String, List<reduivy__Individual_Enrollment__c>> sourceObjMap) {
        Map<Id, List<reduivy__Individual_Program_Enrollment__c>> ipfIpeMap = new Map<Id, List<reduivy__Individual_Program_Enrollment__c>>();
        Map<Id, Map<Id, List<reduivy__Study_Plan_Structure__c>>> splUnitSpsBySunMap = new Map<Id, Map<Id, List<reduivy__Study_Plan_Structure__c>>>();
        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipeGroupIpsBySpsMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipeUnitIpsBySunMap = new Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>();
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> splIds = new Set<Id>();

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        for (reduivy__Individual_Enrollment__c ien : [
            SELECT Id, 
                reduivy__Target_Unit_Id__c, 
                reduivy__Individual_Academic_Profile__c,
                reduivy__Attempt_Number__c,
                reduivy__Grade_Result__c,
                reduivy__Enrollment_Status__c,
                reduivy__Start_Date__c,
                reduivy__Enrollment_Date__c,
                CreatedDate
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_STUDENT_RTID
            AND reduivy__Enrollment_Type__c = :IEN_ENROLLMENTTYPE_PROGRAM
            AND reduivy__Target_Unit_Id__c IN :sunIdSet
            AND reduivy__Individual_Academic_Profile__c IN :ipfIenStudyUnitIdMap.keySet()
            WITH USER_MODE
        ]) {
            ienList.add(ien);
        }

        //To get the IEN that should have the ips linked for each IPF
        Map<Id, Map<Id, reduivy__Individual_Enrollment__c>> ipfIdWithIen = IEN_Helper.sortStudentIenBasedOnPriority(ienList);

        // Query the IPF individual program enrollment and related individual plan structure (both unit and group)
        for (reduivy__Individual_Program_Enrollment__c ipe : [SELECT Id,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Master_Enrollment__c,
            reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Study_Plan__c,
            (
                SELECT Id, 
                reduivy__Target_Unit_Id__c,
                reduivy__Study_Plan_Structure__c,
                reduivy__Status__c,
                reduivy__Individual_Program_Enrollment__c,
                reduivy__Individual_Enrollment__c,
                RecordTypeId
                FROM reduivy__Individual_Plan_Structures__r
                WHERE (RecordTypeId = :IPS_UNIT_RTID AND reduivy__Target_Unit_Id__c IN :sunIdSet) 
                OR RecordTypeId =: IPS_GROUP_RTID
                ORDER BY reduivy__Sequence_Key__c NULLS LAST, Name ASC
            )
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE (
                reduivy__Individual_Academic_Profile__c IN: ipfIenStudyUnitIdMap.keySet() 
                OR reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c IN: ipfIenStudyUnitIdMap.keySet()
            )
            AND reduivy__Enrollment_Status__c IN: IPE_Helper.getInProgressStatuses()
            WITH USER_MODE
        ]) {
            
            Id academicProfileId = IPE_Helper.getIpfId(ipe);

            if (String.isNotBlank(ipe.reduivy__Study_Plan__c) && String.isNotBlank(academicProfileId)) {
                if (!ipfIpeMap.containsKey(academicProfileId)) {
                    ipfIpeMap.put(academicProfileId, new List<reduivy__Individual_Program_Enrollment__c>());
                }

                // track the IPF ipe
                ipfIpeMap.get(academicProfileId).add(ipe);

                // track the ipe group ips by sps for new unit ips
                Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipsGroupBySps = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
                // track the ipe unit ips by sun for update
                Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipsUnitBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();

                for (reduivy__Individual_Plan_Structure__c ips : ipe.reduivy__Individual_Plan_Structures__r) {
                    if (ips.RecordTypeId == IPS_GROUP_RTID) {
                        if (String.isNotBlank(ips.reduivy__Study_Plan_Structure__c)) {
                            if (!ipsGroupBySps.containsKey(ips.reduivy__Study_Plan_Structure__c)) {
                                ipsGroupBySps.put(ips.reduivy__Study_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
                            }

                            ipsGroupBySps.get(ips.reduivy__Study_Plan_Structure__c).add(ips);
                        }

                    } else if (ips.RecordTypeId == IPS_UNIT_RTID) {
                        if (String.isNotBlank(ips.reduivy__Target_Unit_Id__c)) {
                            if (!ipsUnitBySun.containsKey(ips.reduivy__Target_Unit_Id__c)) {
                                ipsUnitBySun.put(ips.reduivy__Target_Unit_Id__c, new List<reduivy__Individual_Plan_Structure__c>());
                            }

                            ipsUnitBySun.get(ips.reduivy__Target_Unit_Id__c).add(ips);
                        }

                    }
                }

                ipeGroupIpsBySpsMap.put(ipe.Id, ipsGroupBySps);
                ipeUnitIpsBySunMap.put(ipe.Id, ipsUnitBySun);

                splIds.add(ipe.reduivy__Study_Plan__c);
            }
        }

        // Query study plan structure unit by study plan id and sun id
        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id,
            reduivy__Parent_Study_Plan_Structure__c, 
            reduivy__Study_Unit__c,
            reduivy__Allow_Pre_Enrollment__c,
            reduivy__Category__c, 
            reduivy__Credits__c,
            reduivy__Description__c,
            reduivy__Hide_in_Enrollment__c,
            reduivy__Sequence__c,
            reduivy__Study_Plan__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c IN: splIds
            AND reduivy__Study_Unit__c IN: sunIdSet
            AND RecordTypeId =: SPS_UNIT_RTID
            WITH USER_MODE
            ORDER BY reduivy__Sequence_Key__c NULLS LAST, Name ASC
        ]) {
            if (String.isNotBlank(sps.reduivy__Study_Unit__c)) {
                // Track the unit sps by study plan and sun id
                if (splUnitSpsBySunMap.containsKey(sps.reduivy__Study_Plan__c)) {
                    Map<Id, List<reduivy__Study_Plan_Structure__c>> spsBySun = splUnitSpsBySunMap.get(sps.reduivy__Study_Plan__c);

                    if (spsBySun.containsKey(sps.reduivy__Study_Unit__c)) {
                        spsBySun.get(sps.reduivy__Study_Unit__c).add(sps);
                    } else {
                        spsBySun.put(sps.reduivy__Study_Unit__c, new List<reduivy__Study_Plan_Structure__c>{sps});
                    }

                    splUnitSpsBySunMap.put(sps.reduivy__Study_Plan__c, spsBySun);

                } else {
                    Map<Id, List<reduivy__Study_Plan_Structure__c>> spsBySun = new Map<Id, List<reduivy__Study_Plan_Structure__c>>();
                    spsBySun.put(sps.reduivy__Study_Unit__c, new List<reduivy__Study_Plan_Structure__c>{sps});

                    splUnitSpsBySunMap.put(sps.reduivy__Study_Plan__c, spsBySun);
                }
            }
        }

        Map<String, List<reduivy__Individual_Plan_Structure__c>> ipsuUpsertMap = new Map<String, List<reduivy__Individual_Plan_Structure__c>>();
        List<String> ipsUnitCompletedStatuses = IPS_Helper.getUnitCompletedStatuses();

        // Go through all ipe grouped by IPF
        for (List<reduivy__Individual_Program_Enrollment__c> ipfIpes : ipfIpeMap.values()) {
            for (reduivy__Individual_Program_Enrollment__c ipe : ipfIpes) {
                Id ipfId = IPE_Helper.getIpfId(ipe);

                // Get the related ien for this IPF
                if (ipfIenStudyUnitIdMap.containsKey(ipfId) && ipfIdWithIen.containsKey(ipfId)) {
                    Set<Id> targetSunIds = ipfIenStudyUnitIdMap.get(ipfId);
                    
                    for (Id targetSunId : targetSunIds) {
                        if (!ipfIdWithIen.get(ipfId).containsKey(targetSunId)) {
                            //skip if the IPF doesn't have an ien for the study unit
                            continue;
                        }

                        String ipfSunKey = ipfId + '_' + targetSunId;
                        Set<Id> existedUnitSpsId = new Set<Id>();
                        //ien that should link to the ips
                        reduivy__Individual_Enrollment__c ienRecord = ipfIdWithIen.get(ipfId).get(targetSunId);

                        // Get the individual plan structure unit records to be reassigned to the new individual enrollment records
                        if (ipeUnitIpsBySunMap.containsKey(ipe.Id) &&
                            ipeUnitIpsBySunMap.get(ipe.Id).containsKey(targetSunId)
                        ) {
                            for (reduivy__Individual_Plan_Structure__c ipsUnit : ipeUnitIpsBySunMap.get(ipe.Id).get(targetSunId)) {
                                // Ensure that we only update the non completed individual plan structure unit and ien is not the same
                                if (!ipsUnitCompletedStatuses.contains(ipsUnit.reduivy__Status__c) &&
                                ipsUnit.reduivy__Individual_Enrollment__c != ienRecord.Id) {
                                    
                                    reduivy__Individual_Plan_Structure__c ipsuUpdate = new reduivy__Individual_Plan_Structure__c();
                                    ipsuUpdate.Id = ipsUnit.Id;
                                    //We will link the IPS to the IEN with the highest number of attempts and the most recent start date
                                    //as long as the IPS are not already linked to the correct one, regardless of whether it's a new IEN or not
                                    ipsuUpdate.reduivy__Individual_Enrollment__c = ienRecord.Id;

                                    if (!ipsuUpsertMap.containsKey(ipfSunKey)) {
                                        ipsuUpsertMap.put(ipfSunKey, new List<reduivy__Individual_Plan_Structure__c>());
                                    }

                                    ipsuUpsertMap.get(ipfSunKey).add(ipsuUpdate);
                                }

                                if (String.isNotBlank(ipsUnit.reduivy__Study_Plan_Structure__c)) {
                                    existedUnitSpsId.add(ipsUnit.reduivy__Study_Plan_Structure__c);
                                }
                            }
                        }

                        // Check if the ipe has all the unit ips needed for the new ien by sun id
                        // We need to create the missing unit ips as any elective sps won't be created upfront
                        if (splUnitSpsBySunMap.containsKey(ipe.reduivy__Study_Plan__c) &&
                            splUnitSpsBySunMap.get(ipe.reduivy__Study_Plan__c).containsKey(targetSunId) &&
                            ipeGroupIpsBySpsMap.containsKey(ipe.Id)
                        ) {
                            for (reduivy__Study_Plan_Structure__c spsUnit : splUnitSpsBySunMap.get(ipe.reduivy__Study_Plan__c).get(targetSunId)) {
                                if (!existedUnitSpsId.contains(spsUnit.Id) && ipeGroupIpsBySpsMap.get(ipe.Id).containsKey(spsUnit.reduivy__Parent_Study_Plan_Structure__c)) {
                                    
                                    reduivy__Individual_Plan_Structure__c ipsuNew = IPS_Helper.initUnitPlanStructure(
                                        ipe.Id,
                                        ipeGroupIpsBySpsMap.get(ipe.Id).get(spsUnit.reduivy__Parent_Study_Plan_Structure__c).get(0).Id,
                                        ienRecord.Id, 
                                        spsUnit
                                    );

                                    if (!ipsuUpsertMap.containsKey(ipfSunKey)) {
                                        ipsuUpsertMap.put(ipfSunKey, new List<reduivy__Individual_Plan_Structure__c>());
                                    }

                                    ipsuUpsertMap.get(ipfSunKey).add(ipsuNew);
                                }
                            }
                        }

                        // To create the IEN map for updateIpsUnitStatus
                        ienMap.put(ienRecord.Id, ienRecord);
                    }
                }
            }
        }

        if (!ipsuUpsertMap.isEmpty()){
            List<reduivy__Individual_Plan_Structure__c> ipsListInsert = new List<reduivy__Individual_Plan_Structure__c>();

            for (List<reduivy__Individual_Plan_Structure__c> ipsList : ipsuUpsertMap.values()) {
                ipsListInsert.addAll(ipsList);
            }

            //Get the status of IPS Unit based on the latest IEN
            IPS_Helper.updateIpsUnitStatus(ipsListInsert, ienMap);

            REDU_Database_UTIL.doUpsert(ipsuUpsertMap, sourceObjMap, false);
        }
    }

    /**
     * @description  When individual enrollment is deleted, the unit individual plan structure is reassigned to the last attempted individual enrollment.
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if ((operationType == TriggerOperation.BEFORE_DELETE) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();
            Map<Id, reduivy__Individual_Enrollment__c> ienMapForUpdateStatus = new Map<Id, reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c oldIen : (List<reduivy__Individual_Enrollment__c>) oldList) {
                if (oldIen.RecordTypeId == IEN_STUDENT_RTID &&
                    oldIen.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM
                ) {
                    ienMap.put(oldIen.Id, oldIen);
                }
            }        

            Set<Id> sunIdSet = new Set<Id>();
            Set<Id> ipfIdSet = new Set<Id>();

            List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();

            for (reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, 
                reduivy__Individual_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Master_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c,
                reduivy__Target_Unit_Id__c,
                RecordTypeId
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE reduivy__Individual_Enrollment__c IN :ienMap.keySet()
                AND RecordTypeId = :IPS_UNIT_RTID
                WITH USER_MODE
            ]){
                Id academicProfileId = IPS_Helper.getIpfId(ipsUnit);

                if (String.isNotBlank(ipsUnit.reduivy__Target_Unit_Id__c) && 
                    String.isNotBlank(academicProfileId)
                ) {
                    sunIdSet.add(ipsUnit.reduivy__Target_Unit_Id__c);
                    ipfIdSet.add(academicProfileId);
                }

                ipsuList.add(ipsUnit);
            }

            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : [
                SELECT Id, 
                    reduivy__Target_Unit_Id__c, 
                    reduivy__Individual_Academic_Profile__c,
                    reduivy__Attempt_Number__c,
                    reduivy__Grade_Result__c,
                    reduivy__Enrollment_Status__c,
                    reduivy__Start_Date__c,
                    reduivy__Enrollment_Date__c,
                    CreatedDate
                FROM reduivy__Individual_Enrollment__c
                WHERE RecordTypeId = :IEN_STUDENT_RTID
                AND reduivy__Enrollment_Type__c =: IEN_ENROLLMENTTYPE_PROGRAM
                AND reduivy__Target_Unit_Id__c IN :sunIdSet
                AND reduivy__Individual_Academic_Profile__c IN :ipfIdSet
                WITH USER_MODE
            ]) {
                if (!ienMap.containsKey(ien.Id)) { // Ignore the records that are being deleted
                    ienList.add(ien);
                }
            }

            //To get the IEN that should have the ips linked for each IPF
            Map<Id, Map<Id, reduivy__Individual_Enrollment__c>> ipfIdWithIen = IEN_Helper.sortStudentIenBasedOnPriority(ienList);

            // Reassign an individual enrollment record to the otherwise orphaned individual plan structure unit records
            List<reduivy__Individual_Plan_Structure__c> ipsuUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
            for (reduivy__Individual_Plan_Structure__c ipsUnit : ipsuList) {

                reduivy__Individual_Plan_Structure__c ipsuUpdate = new reduivy__Individual_Plan_Structure__c();
                ipsuUpdate.Id = ipsUnit.Id;

                Id ipfId = IPS_Helper.getIpfId(ipsUnit);

                Id targetUnitId = ipsUnit.reduivy__Target_Unit_Id__c;
                
                if(ipfIdWithIen.containsKey(ipfId) && ipfIdWithIen.get(ipfId).containsKey(targetUnitId)) {
                    reduivy__Individual_Enrollment__c ienToBeAssigned = ipfIdWithIen.get(ipfId).get(targetUnitId);

                    ipsuUpdate.reduivy__Individual_Enrollment__c = ienToBeAssigned.Id;

                    ienMapForUpdateStatus.put(ienToBeAssigned.Id, ienToBeAssigned);
                } else if ((String.isNotBlank(ipsUnit.reduivy__Individual_Enrollment__c)) && (ienMap.containsKey(ipsUnit.reduivy__Individual_Enrollment__c))) {
                    ipsuUpdate.reduivy__Individual_Enrollment__c = null;
                }

                ipsuUpdateList.add(ipsuUpdate);
            }

            ipsuUpdateList = IPS_Helper.updateIpsUnitStatus(ipsuUpdateList, ienMapForUpdateStatus);

            if (!ipsuUpdateList.isEmpty()) {
                REDU_Database_UTIL.doUpdate(ipsuUpdateList, ienMap, 'reduivy__Individual_Enrollment__c', false);
            }
        }
    }

    /**
     * @description Determine if the individual enrollment is valid for reassign logic processing
     * @param ienNew New individual enrollment
     * @param ienOld Old individual enrollment
     * @return Boolean
     */
    private static Boolean shouldReassign(reduivy__Individual_Enrollment__c ienNew, reduivy__Individual_Enrollment__c ienOld) {
        if (ienNew == null) {
            return false;
        }

        String newKey = IEN_Helper.constructStatusKey(ienNew.reduivy__Enrollment_Status__c, ienNew.reduivy__Grade_Result__c);

        String oldKey;
        if (ienOld != null) {
            oldKey = IEN_Helper.constructStatusKey(ienOld.reduivy__Enrollment_Status__c, ienOld.reduivy__Grade_Result__c);
        }

        Boolean newContained = (String.isNotBlank(newKey) && IEN_STATUSES_WITH_PRIORITY.containsKey(newKey));
        Boolean oldContained = (ienOld != null && String.isNotBlank(oldKey) && IEN_STATUSES_WITH_PRIORITY.containsKey(oldKey));

        //for insert
        //contains = run
        if (ienOld == null) {
            return newContained;
        }

        //for update
        //non > contains = run
        //contains > non = run
        //contains > contains && priority changed = run
        //contains > contains && priority not changed = skip
        //non > non = skip
        if ((!oldContained && newContained) || (oldContained && !newContained)) {

            return true;

        } else if (oldContained && newContained) {
            
            Integer oldPriority = IEN_STATUSES_WITH_PRIORITY.get(oldKey);
            Integer newPriority = IEN_STATUSES_WITH_PRIORITY.get(newKey);

            return oldPriority != newPriority;
        }

        return false;
    }

    /**
     * @description Get Individual Academic Profile + study unit id key
     * @param ien Individual enrollment
     * @return String
     */
    private String getIpfSunKey(reduivy__Individual_Enrollment__c ien) {
        return ien.reduivy__Individual_Academic_Profile__c + '_' + ien.reduivy__Target_Unit_Id__c;
    }
}