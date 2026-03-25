/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Trigger executable
 * @description Rollup from individual plan structure (unit) to parent individual plan structure group
 * @changehistory
 * ISS-001817 13-12-2023 dblack - new class
 * ISS-001954 24-05-2024 VTan - Update "FOR UPDATE" keyword on the SOQL to avoid race condition
 * ISS-002002 12-07-2024 XW - Add condition to check credits earned before rolling up to parent Ips
 * ISS-002005 15-07-2024 Lean - Fixed completion during creation of new IPE with existing completed IEN
 * ISS-002069 02-09-2024 VTan - Introduce # of Units Contributed for IPS Group
 * ISS-002136 16-10-2024 Lean - Fixed the credits contribution for IPS unit created via credit transfer application (type = manual)
 * ISS-002034 24-01-2025 XW - Fixed the credits contribution for Non-primary IPS unit
 * ISS-002272 17-02-2025 XW - Failed ips unit is now counted as unit enrolled when rolling up to parent ips group
 * ISS-002441 06-05-2025 XW - Consider required children IPS Unit when updating parent status
 */
public without sharing class IPS_UnitIpsCompletion_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual plan structure (group) record type Id
     */
    private static final Id IPS_GROUP_RECORD_TYPE_ID = IPS_Helper.getGroupRecordTypeId();

    /**
     * @description Individual plan structure (unit) record type Id
     */
    private static final Id IPS_UNIT_RECORD_TYPE_ID = IPS_Helper.getUnitRecordTypeId();

    /**
     * @description Individual plan structure (unit) in-progress statuses
     */
    private static final List<String> IPS_UNIT_INPROGRESS_STATUSES = IPS_Helper.getUnitInProgressStatuses();

    /**
     * @description Individual plan structure (unit) completed statuses
     */
    private static final List<String> IPS_UNIT_COMPLETED_STATUSES = IPS_Helper.getUnitCompletedStatuses();

    /**
     * @description Individual plan structure (unit) failed statuses
     */
    private static final List<String> IPS_UNIT_FAILED_STATUSES = IPS_Helper.getUnitFailedStatuses();

    /**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Plan_Structure__c> workingList = new List<reduivy__Individual_Plan_Structure__c>();

            for (reduivy__Individual_Plan_Structure__c ipsNew : (List<reduivy__Individual_Plan_Structure__c>) newList) {

                if ((ipsNew.RecordTypeId == IPS_UNIT_RECORD_TYPE_ID) && 
                    (String.isNotBlank(ipsNew.reduivy__Parent_Plan_Structure__c))
                ) {
                    if ((
                        IPS_UNIT_COMPLETED_STATUSES.contains(ipsNew.reduivy__Status__c) ||
                        ipsNew.reduivy__Revalidate_Completion__c
                    )) {
                        ipsNew.reduivy__Revalidate_Completion__c = false;

                        workingList.add(ipsNew);

                    } else {
                        //unset the flag for non completed ips
                        ipsNew.reduivy__Credits_Earned__c = null;
                        ipsNew.reduivy__Credits_Contribution__c = null;
                    }
                }
            }

            if (!workingList.isEmpty()) {
                setIpsUnitCreditsEarned(workingList);
            }
        }
    }

    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Plan_Structure__c> workingList = new List<reduivy__Individual_Plan_Structure__c>();

            for (reduivy__Individual_Plan_Structure__c ipsNew : (List<reduivy__Individual_Plan_Structure__c>) newList) {

                if ((ipsNew.RecordTypeId == IPS_UNIT_RECORD_TYPE_ID) && 
                    (String.isNotBlank(ipsNew.reduivy__Parent_Plan_Structure__c))) {

                    reduivy__Individual_Plan_Structure__c ipsOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsNew.Id);

                    if (((IPS_UNIT_COMPLETED_STATUSES.contains(ipsNew.reduivy__Status__c)) && (!IPS_UNIT_COMPLETED_STATUSES.contains(ipsOld.reduivy__Status__c))) || 
                        ((!IPS_UNIT_COMPLETED_STATUSES.contains(ipsNew.reduivy__Status__c)) && (IPS_UNIT_COMPLETED_STATUSES.contains(ipsOld.reduivy__Status__c))) || 
                        (ipsNew.reduivy__Credits_Earned__c != ipsOld.reduivy__Credits_Earned__c) || 
                        (ipsNew.reduivy__Revalidate_Completion__c && !ipsOld.reduivy__Revalidate_Completion__c)
                    ) {
                        ipsNew.reduivy__Revalidate_Completion__c = false;

                        workingList.add(ipsNew);
                    }
                }
            }

            if (!workingList.isEmpty()) {
                setIpsUnitCreditsEarned(workingList);
            }
        }
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

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> workingMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();

            for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>) newList) {

                if ((ips.RecordTypeId == IPS_UNIT_RECORD_TYPE_ID) && 
                    (String.isNotBlank(ips.reduivy__Parent_Plan_Structure__c)) && 
                    (
                        (IPS_UNIT_INPROGRESS_STATUSES.contains(ips.reduivy__Status__c)) || 
                        (IPS_UNIT_COMPLETED_STATUSES.contains(ips.reduivy__Status__c)) ||
                        (IPS_UNIT_FAILED_STATUSES.contains(ips.reduivy__Status__c))
                    )
                ) {
                    if (!workingMap.containsKey(ips.reduivy__Parent_Plan_Structure__c)) {
                        workingMap.put(ips.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
                    }

                    workingMap.get(ips.reduivy__Parent_Plan_Structure__c).add(ips);
                }
            }

            if (!workingMap.isEmpty()) {
                rollupToIpsGroup(workingMap);
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

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> workingMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();

            for (reduivy__Individual_Plan_Structure__c ipsNew : (List<reduivy__Individual_Plan_Structure__c>) newList) {

                if ((ipsNew.RecordTypeId == IPS_UNIT_RECORD_TYPE_ID) && 
                    (String.isNotBlank(ipsNew.reduivy__Parent_Plan_Structure__c))) {

                    reduivy__Individual_Plan_Structure__c ipsOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsNew.Id);

                    if (((IPS_UNIT_INPROGRESS_STATUSES.contains(ipsNew.reduivy__Status__c)) && (!IPS_UNIT_INPROGRESS_STATUSES.contains(ipsOld.reduivy__Status__c))) || 
                        ((!IPS_UNIT_INPROGRESS_STATUSES.contains(ipsNew.reduivy__Status__c)) && (IPS_UNIT_INPROGRESS_STATUSES.contains(ipsOld.reduivy__Status__c))) || 
                        ((IPS_UNIT_COMPLETED_STATUSES.contains(ipsNew.reduivy__Status__c)) && (!IPS_UNIT_COMPLETED_STATUSES.contains(ipsOld.reduivy__Status__c))) || 
                        ((!IPS_UNIT_COMPLETED_STATUSES.contains(ipsNew.reduivy__Status__c)) && (IPS_UNIT_COMPLETED_STATUSES.contains(ipsOld.reduivy__Status__c))) || 
                        ((IPS_UNIT_FAILED_STATUSES.contains(ipsNew.reduivy__Status__c)) && (!IPS_UNIT_FAILED_STATUSES.contains(ipsOld.reduivy__Status__c))) ||
                        ((!IPS_UNIT_FAILED_STATUSES.contains(ipsNew.reduivy__Status__c)) && (IPS_UNIT_FAILED_STATUSES.contains(ipsOld.reduivy__Status__c))) ||
                        (ipsNew.reduivy__Credits_Earned__c != ipsOld.reduivy__Credits_Earned__c) || 
                        (ipsNew.reduivy__Revalidate_Completion__c && !ipsOld.reduivy__Revalidate_Completion__c) ||
                        (ipsNew.reduivy__Credits_Contribution__c != ipsOld.reduivy__Credits_Contribution__c) ||
                        (ipsNew.reduivy__Parent_Plan_Structure__c != ipsOld.reduivy__Parent_Plan_Structure__c)
                    ) {
                        if (!workingMap.containsKey(ipsNew.reduivy__Parent_Plan_Structure__c)) {
                            workingMap.put(ipsNew.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
                        }

                        workingMap.get(ipsNew.reduivy__Parent_Plan_Structure__c).add(ipsNew);

                        //need to update the old parent plan structure too
                        if (ipsNew.reduivy__Parent_Plan_Structure__c != ipsOld.reduivy__Parent_Plan_Structure__c &&
                            String.isNotBlank(ipsOld.reduivy__Parent_Plan_Structure__c)
                        ) {
                            if (!workingMap.containsKey(ipsOld.reduivy__Parent_Plan_Structure__c)) {
                                workingMap.put(ipsOld.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
                            }
    
                            workingMap.get(ipsOld.reduivy__Parent_Plan_Structure__c).add(ipsNew);
                        }
                    }
                }
            }

            if (!workingMap.isEmpty()) {
                rollupToIpsGroup(workingMap);
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

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> workingMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();

            for (reduivy__Individual_Plan_Structure__c ipsOld : (List<reduivy__Individual_Plan_Structure__c>) oldList) {

                if ((ipsOld.RecordTypeId == IPS_UNIT_RECORD_TYPE_ID) && 
                    (String.isNotBlank(ipsOld.reduivy__Parent_Plan_Structure__c)) &&
                    (
                        (IPS_UNIT_INPROGRESS_STATUSES.contains(ipsOld.reduivy__Status__c)) ||
                        (IPS_UNIT_COMPLETED_STATUSES.contains(ipsOld.reduivy__Status__c)) ||
                        (IPS_UNIT_FAILED_STATUSES.contains(ipsOld.reduivy__Status__c)) 
                    )
                ) {
                    if (!workingMap.containsKey(ipsOld.reduivy__Parent_Plan_Structure__c)) {
                        workingMap.put(ipsOld.reduivy__Parent_Plan_Structure__c, new List<reduivy__Individual_Plan_Structure__c>());
                    }

                    workingMap.get(ipsOld.reduivy__Parent_Plan_Structure__c).add(ipsOld);
                }
            }

            if (!workingMap.isEmpty()) {
                rollupToIpsGroup(workingMap);
            }
        }
    }

    /**
     * @description Set the credits earned on the individual plan structure unit records
     * @param ipsuMap Map<Id, List<reduivy__Individual_Plan_Structure__c>>
     */
    private void setIpsUnitCreditsEarned(List<reduivy__Individual_Plan_Structure__c> ipsuList) {
        
        Set<Id> sunIds = new Set<Id>();
        Set<Id> ipeIds = new Set<Id>();

        List<reduivy__Individual_Plan_Structure__c> qualifiedIpsuList = new List<reduivy__Individual_Plan_Structure__c>();
        Map<String, reduivy__Individual_Plan_Structure__c> primaryIpsuMap = new Map<String, reduivy__Individual_Plan_Structure__c>();
        Map<String, Set<Id>> ipeSunToGroupsXref = new Map<String, Set<Id>>();
        Map<Id, reduivy__Individual_Plan_Structure__c> groupIpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            //the IPS unit without valid target unit id e.g., IPS unit for credit transfer application with type = manual assignment should not be recalculated
            if (String.isNotBlank(ipsu.reduivy__Individual_Program_Enrollment__c) && String.isNotBlank(ipsu.reduivy__Target_Unit_Id__c)) {
                String identifier = getIdentifierKey(ipsu);

                if (ipsu.reduivy__Primary__c) {
                    //if primary found, it should take precendence
                    primaryIpsuMap.put(identifier, ipsu);
                    
                } else {
                    //if not primary, we will try to search for one
                    ipeIds.add(ipsu.reduivy__Individual_Program_Enrollment__c);
                    sunIds.add(ipsu.reduivy__Target_Unit_Id__c);
                }

                //populate the groups for study unit by ipe
                if (ipeSunToGroupsXref.containsKey(identifier)) {
                    ipeSunToGroupsXref.get(identifier).add(ipsu.reduivy__Parent_Plan_Structure__c);
                } else {
                    ipeSunToGroupsXref.put(identifier, new Set<Id>{ipsu.reduivy__Parent_Plan_Structure__c});
                }

                qualifiedIpsuList.add(ipsu);
            }
        }

        Map<String, Object> ipsBindMap = new Map<String, Object>();
        ipsBindMap.put('ipeIds', ipeIds);
        ipsBindMap.put('ipsGroupRtId', IPS_GROUP_RECORD_TYPE_ID);
        ipsBindMap.put('ipsUnitRtId', IPS_UNIT_RECORD_TYPE_ID);
        ipsBindMap.put('sunIds', sunIds);

        Set<String> ipsFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Credits__c',
            'reduivy__Max_Credits__c',
            'reduivy__Credits_Earned__c',
            'reduivy__Primary__c',
            'reduivy__Parent_Plan_Structure__c',
            'reduivy__Individual_Program_Enrollment__c',
            'reduivy__Target_Unit_Id__c',
            'reduivy__Credits_Contribution__c',
            'RecordTypeId',
            'reduivy__Sequence_Key__c'
        };

        String ipsQuery = 'SELECT ' + String.join(ipsFields, ', ') + 
            ' FROM reduivy__Individual_Plan_Structure__c ' +
            ' WHERE reduivy__Individual_Program_Enrollment__c IN: ipeIds ' +
            ' AND (RecordTypeId =: ipsGroupRtId OR (RecordTypeId =: ipsUnitRtId AND reduivy__Target_Unit_Id__c IN: sunIds)) ' +
            ' ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC';

        Map<String, Set<String>> ipsObjectFieldsFls = new Map<String, Set<String>>();
        ipsObjectFieldsFls.put(IPS_Helper.getApiName(), ipsFields);

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>) REDU_SystemMode_UTIL.doQuery(ipsQuery, ipsBindMap, ipsObjectFieldsFls)) {
            if (ips.RecordTypeId == IPS_GROUP_RECORD_TYPE_ID) {

                //we set the null value to zero so that it is easier for us to perform the sum later
                //the credits sum for groups is meant for identify the credits contribution for ipsu only, it won't be saved
                ips.reduivy__Credits_Earned__c = ips.reduivy__Credits_Earned__c == null ? 0 : ips.reduivy__Credits_Earned__c;
                ips.reduivy__Credits__c = ips.reduivy__Credits__c == null ? 0 : ips.reduivy__Credits__c;

                groupIpsMap.put(ips.Id, ips);

            } else if (ips.RecordTypeId == IPS_UNIT_RECORD_TYPE_ID) {

                String identifier = getIdentifierKey(ips);

                if (ips.reduivy__Primary__c) {
                    if (!primaryIpsuMap.containsKey(identifier)) {
                        primaryIpsuMap.put(identifier, ips);
                    }
                }

                //populate the groups for study unit by ipe
                if (ipeSunToGroupsXref.containsKey(identifier)) {
                    ipeSunToGroupsXref.get(identifier).add(ips.reduivy__Parent_Plan_Structure__c);
                } else {
                    ipeSunToGroupsXref.put(identifier, new Set<Id>{ips.reduivy__Parent_Plan_Structure__c});
                }
            }
        }

        List<reduivy__Individual_Plan_Structure__c> nonPrimaryCompletedIpsuList = new List<reduivy__Individual_Plan_Structure__c>();

        for (reduivy__Individual_Plan_Structure__c ipsu : qualifiedIpsuList) {
            String identifier = getIdentifierKey(ipsu);

            if (IPS_UNIT_COMPLETED_STATUSES.contains(ipsu.reduivy__Status__c)) {
                //all completed will have credits earned, we then will use the credit contribution flag to decide the rollup
                ipsu.reduivy__Credits_Earned__c = ipsu.reduivy__Credits__c == null ? 0 : ipsu.reduivy__Credits__c;

                if (primaryIpsuMap.containsKey(identifier)) {
                    //for primary and matches the id, set to yes, otherwise set to no
                    if (primaryIpsuMap.get(identifier).Id == ipsu.Id) {
                        ipsu.reduivy__Credits_Contribution__c = IPS_Helper.CREDITS_CONTRIBUTION_YES;

                        if (groupIpsMap.containsKey(ipsu.reduivy__Parent_Plan_Structure__c)) {
                            // for primary, it will always contribute to the parent group
                            reduivy__Individual_Plan_Structure__c ipsg = groupIpsMap.get(ipsu.reduivy__Parent_Plan_Structure__c);
                            ipsg.reduivy__Credits_Earned__c += ipsu.reduivy__Credits_Earned__c;
                        }
                        
                    } else {
                        //we can skip this since it is not going to contribute to the group
                        ipsu.reduivy__Credits_Contribution__c = IPS_Helper.CREDITS_CONTRIBUTION_NO;
                    }
                } else {
                    //add to non primary list so that we can identify the credits contribution later
                    nonPrimaryCompletedIpsuList.add(ipsu);
                }

            } else {
                ipsu.reduivy__Credits_Contribution__c = null;
                ipsu.reduivy__Credits_Earned__c = null;
            }
        }

        //go through the non primary to identify the group to be contributed to
        Map<String, reduivy__Individual_Plan_Structure__c> targetGroupsForContributionByIdentifier = new Map<String, reduivy__Individual_Plan_Structure__c>();
        for (reduivy__Individual_Plan_Structure__c nonPrimaryIpsu : nonPrimaryCompletedIpsuList) {

            String identifier = getIdentifierKey(nonPrimaryIpsu);
            if(targetGroupsForContributionByIdentifier.containsKey(identifier)) {
                continue; //skip if contribution found
            }

            // for non primary, we will go through the related group and count the remaining credits required
            Set<Id> ipsGroupIds = ipeSunToGroupsXref.containsKey(identifier) ? ipeSunToGroupsXref.get(identifier) : new Set<Id>();
            Map<String, reduivy__Individual_Plan_Structure__c> ipsGroupsBySeq = new Map<String, reduivy__Individual_Plan_Structure__c>();

            for (Id ipsgId : ipsGroupIds) {
                if (groupIpsMap.containsKey(ipsgId)) {
                    reduivy__Individual_Plan_Structure__c ipsg = groupIpsMap.get(ipsgId);
                    // e.g., G0001_G0002_U0001_GroupName_GroupId
                    String key = ipsg.reduivy__Sequence_Key__c + '_' + ipsg.Name + '_' + ipsg.Id;
                    
                    ipsGroupsBySeq.put(key, ipsg);
                }
            }

            // sort the keys
            List<String> groupKeys = new List<String>(ipsGroupsBySeq.keySet());
            groupKeys.sort();

            // we will go through the sorted group and see which one is eligible to take the credits from ips unit
            for (String groupKey : groupKeys) {
                reduivy__Individual_Plan_Structure__c ipsg = ipsGroupsBySeq.get(groupKey);
                
                //increase the group credits earned and store the id to the map
                if (ipsg.reduivy__Credits_Earned__c < (ipsg.reduivy__Max_Credits__c != null ? ipsg.reduivy__Max_Credits__c : ipsg.reduivy__Credits__c)) { //ISS-002002
                    ipsg.reduivy__Credits_Earned__c += nonPrimaryIpsu.reduivy__Credits_Earned__c;

                    targetGroupsForContributionByIdentifier.put(identifier, ipsg);
                    break;
                }
            }
        }

        //go through the non primary list again, this time we will set the credits contribution flag
        for (reduivy__Individual_Plan_Structure__c nonPrimaryIpsu : nonPrimaryCompletedIpsuList) {
            String identifier = getIdentifierKey(nonPrimaryIpsu);

            if (targetGroupsForContributionByIdentifier.containsKey(identifier) &&
                targetGroupsForContributionByIdentifier.get(identifier).Id == nonPrimaryIpsu.reduivy__Parent_Plan_Structure__c
            ) {
                nonPrimaryIpsu.reduivy__Credits_Contribution__c = IPS_Helper.CREDITS_CONTRIBUTION_YES;
            } else {
                nonPrimaryIpsu.reduivy__Credits_Contribution__c = IPS_Helper.CREDITS_CONTRIBUTION_NO;
            }
        }

    }

    /**
     * @description Rollup credits earned and units passed from individual plan structure (unit) to parent individual plan structure (group)
     * @param ipsuMap Map<Id, List<reduivy__Individual_Plan_Structure__c>>
     */
    private static void rollupToIpsGroup(Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipsuMap) {

        // Rollup from individual plan structure (unit) to parent individual plan structure (group)

        List<reduivy__Individual_Plan_Structure__c> ipsgList = new List<reduivy__Individual_Plan_Structure__c>();

        for (reduivy__Individual_Plan_Structure__c ipsg : getIpsGroupList(new Map<String, Object>{
            'ipsGroupRecordTypeId' => IPS_GROUP_RECORD_TYPE_ID,
            'ipsUnitRecordTypeId' => IPS_UNIT_RECORD_TYPE_ID,
            'ipsGroupIdSet' => ipsuMap.keySet()
        })) {

            Decimal ipsgCreditsEnrolled = 0;
            Decimal ipsgUnitsEnrolled = 0;
            Decimal ipsgCreditsEarned = 0;
            Decimal ipsgUnitsPassed = 0;
            Decimal ipsgUnitsContributed = 0;
            Integer incompleteRequiredChildrenCount = 0;
            Boolean requiredChildrenCompleted;

            for (reduivy__Individual_Plan_Structure__c ipsu : ipsg.reduivy__Individual_Plan_Structures__r) {

                if(ipsu.reduivy__Category__c == IPS_Helper.CATEGORY_REQUIRED) {
                    incompleteRequiredChildrenCount++;
                }
                
                if ((IPS_UNIT_INPROGRESS_STATUSES.contains(ipsu.reduivy__Status__c)) || 
                    (IPS_UNIT_COMPLETED_STATUSES.contains(ipsu.reduivy__Status__c)) || 
                    (IPS_UNIT_FAILED_STATUSES.contains(ipsu.reduivy__Status__c))
                ) {

                    // Credits enrolled
                    if (ipsu.reduivy__Credits__c != null) {
                        ipsgCreditsEnrolled += ipsu.reduivy__Credits__c;
                    }

                    // Units enrolled
                    ++ipsgUnitsEnrolled;


                    if (IPS_UNIT_COMPLETED_STATUSES.contains(ipsu.reduivy__Status__c)) {

                        // Credits earned
                        if(ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES){

                            if (ipsu.reduivy__Credits_Earned__c != null) {
                                ipsgCreditsEarned += ipsu.reduivy__Credits_Earned__c;
    
                                if (ipsg.reduivy__Max_Credits__c != null) {
                                    ipsgCreditsEarned = (ipsgCreditsEarned > ipsg.reduivy__Max_Credits__c) ? ipsg.reduivy__Max_Credits__c : ipsgCreditsEarned;
                                }
                            }
    
                            // Units contributed
                            ++ipsgUnitsContributed;
                        }

                        // Units passed
                        ++ipsgUnitsPassed;

                        if(ipsu.reduivy__Category__c == IPS_Helper.CATEGORY_REQUIRED) {
                            incompleteRequiredChildrenCount--;
                        }
                    }
                }
            }

            requiredChildrenCompleted = incompleteRequiredChildrenCount == 0;

            if (ipsgCreditsEnrolled != ipsg.reduivy__Credits_Enrolled__c || ipsgUnitsEnrolled != ipsg.reduivy__Units_Enrolled__c || ipsgCreditsEarned != ipsg.reduivy__Credits_Earned__c || ipsgUnitsPassed != ipsg.reduivy__Units_Passed__c || ipsgUnitsContributed != ipsg.reduivy__Units_Contributed__c || requiredChildrenCompleted != ipsg.reduivy__Required_Children_Completed__c) {
                reduivy__Individual_Plan_Structure__c ipsGroup = new reduivy__Individual_Plan_Structure__c(
                    Id = ipsg.Id,
                    reduivy__Credits_Enrolled__c = ipsgCreditsEnrolled,
                    reduivy__Units_Enrolled__c = ipsgUnitsEnrolled,
                    reduivy__Credits_Earned__c = ipsgCreditsEarned,
                    reduivy__Units_Passed__c = ipsgUnitsPassed,
                    reduivy__Units_Contributed__c = ipsgUnitsContributed,
                    reduivy__Required_Children_Completed__c = requiredChildrenCompleted
                );

                ipsgList.add(ipsGroup);
            }
        }

        if (!ipsgList.isEmpty()) {
            //Rollup using system mode as the fields are non editable by normal user
            REDU_SystemMode_UTIL.doUpdate(ipsgList, ipsuMap, 'Id', false);
        }
    }

    /**
     * @description Get the list of individual plan structure group records with child unit records
     * @param bindMap Map<String, Object> (keys: 'ipsGroupRecordTypeId', 'ipsUnitRecordTypeId', 'ipsGroupIdSet')
     * @return List<reduivy__Individual_Plan_Structure__c>
     */
    private static List<reduivy__Individual_Plan_Structure__c> getIpsGroupList(Map<String, Object> bindMap) {

        Set<String> ipsFields = new Set<String>{
            'Id',
            'reduivy__Individual_Program_Enrollment__c',
            'reduivy__Max_Credits__c', 
            'reduivy__Credits__c',
            'reduivy__Credits_Enrolled__c', 
            'reduivy__Credits_Earned__c', 
            'reduivy__Units_Enrolled__c',
            'reduivy__Units_Passed__c', 
            'reduivy__Units_Contributed__c', 
            'reduivy__Sequence_Key__c', 
            'reduivy__Credits_Contribution__c',
            'reduivy__Status__c',
            'reduivy__Target_Unit_Id__c',
            'reduivy__Primary__c',
            'reduivy__Parent_Plan_Structure__c',
            'reduivy__Category__c',
            'reduivy__Required_Children_Completed__c'
        };

        String queryStr = 'SELECT ' + String.join(ipsFields, ', ') + ', ' +
                ' (SELECT ' + String.join(ipsFields, ', ') +
                ' FROM reduivy__Individual_Plan_Structures__r ' + 
                ' WHERE RecordTypeId = :ipsUnitRecordTypeId ' + 
                ' ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC) ' + 
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE Id IN :ipsGroupIdSet ' + 
            ' AND RecordTypeId = :ipsGroupRecordTypeId ' + 
            ' FOR UPDATE ';

        Map<String, Set<String>> ipsObjectFieldsFls = new Map<String, Set<String>>();
        ipsObjectFieldsFls.put(IPS_Helper.getApiName(), ipsFields);

        List<reduivy__Individual_Plan_Structure__c> ispGroupList = new List<reduivy__Individual_Plan_Structure__c>();
        for(reduivy__Individual_Plan_Structure__c ipsGroup : (List<reduivy__Individual_Plan_Structure__c>) REDU_SystemMode_UTIL.doQuery(queryStr, bindMap, ipsObjectFieldsFls)){
            for (reduivy__Individual_Plan_Structure__c childGroup : ipsGroup.reduivy__Individual_Plan_Structures__r) {
                //loop to get all data
            }
            
            ispGroupList.add(ipsGroup);
        }

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Individual_Plan_Structure__c.reduivy__Sequence_Key__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        ispGroupList.sort(new REDU_SObjectComparator(criteria));

        return ispGroupList;
    }

    /**
     * @description Get map of primary individual plan structure (unit) Ids: Map: ipe Id => Set: primary ipsuId
     * @param ipsgMap Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>>
     * @return ipsuPrimaryMap Map<Id, Set<Id>>
     */
    private static Map<Id, Set<Id>> getIpsuPrimaryMap(Map<Id, Map<Id, List<reduivy__Individual_Plan_Structure__c>>> ipsgMap) {

        Map<Id, Set<Id>> ipsuPrimaryMap = new Map<Id, Set<Id>>();

        for (Id ipeId : ipsgMap.keySet()) {
            ipsuPrimaryMap.put(ipeId, new Set<Id>());
            for (Id ipsgId : ipsgMap.get(ipeId).keySet()) {
                for (reduivy__Individual_Plan_Structure__c ipsu : ipsgMap.get(ipeId).get(ipsgId)) {
                    if (ipsu.reduivy__Primary__c) {
                        ipsuPrimaryMap.get(ipeId).add(ipsu.reduivy__Target_Unit_Id__c);
                    }
                }
            }
        }

        return ipsuPrimaryMap;
    }

    /**
     * @description Return the ipe + sun id key
     * @return String
     */
    private String getIdentifierKey(reduivy__Individual_Plan_Structure__c ipsu) {
        return ipsu.reduivy__Individual_Program_Enrollment__c + '_' + ipsu.reduivy__Target_Unit_Id__c;
    }
}