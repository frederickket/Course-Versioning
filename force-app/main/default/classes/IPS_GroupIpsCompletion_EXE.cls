/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Trigger executable
 * @description Set individual plan structure (group) status and rollup from child individual plan structure (group) to parent individual plan structure (group)
 * @changehistory
 * ISS-001817 13-12-2023 dblack - new class
 * ISS-001954 24-05-2024 VTan - Update "FOR UPDATE" keyword on the SOQL to avoid race condition
 * ISS-002005 15-07-2024 Lean - Fixed completion during creation of new IPE with existing completed IEN
 * ISS-002069 02-09-2024 VTan - Introduce # of Units Contributed for IPS Group
 * ISS-002323 13-03-2025 Lean - Fixed decimal points issue
 * ISS-002441 06-05-2025 XW - Consider required children IPS Group when updating parent status
 */
public without sharing class IPS_GroupIpsCompletion_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual plan structure (group) record type Id
     */
    private static final Id IPS_GROUP_RECORD_TYPE_ID = IPS_Helper.getGroupRecordTypeId();

    /**
     * @description Individual plan structure (group) not-started statuses
     */
    private static final List<String> IPS_GROUP_NOTSTARTED_STATUSES = IPS_Helper.getGroupNotStartedStatuses();

    /**
     * @description Individual plan structure (group) in-progress statuses
     */
    private static final List<String> IPS_GROUP_INPROGRESS_STATUSES = IPS_Helper.getGroupInProgressStatuses();

    /**
     * @description Individual plan structure (group) completed statuses
     */
    private static final List<String> IPS_GROUP_COMPLETED_STATUSES = IPS_Helper.getGroupCompletedStatuses();

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
                if (ipsNew.RecordTypeId == IPS_GROUP_RECORD_TYPE_ID) {
                    reduivy__Individual_Plan_Structure__c ipsOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsNew.Id);

                    if ((ipsNew.reduivy__Max_Credits__c != ipsOld.reduivy__Max_Credits__c) || 
                        (ipsNew.reduivy__Credits__c != ipsOld.reduivy__Credits__c) || 
                        (ipsNew.reduivy__Units_Required__c != ipsOld.reduivy__Units_Required__c) || 
                        (ipsNew.reduivy__Credits_Enrolled__c != ipsOld.reduivy__Credits_Enrolled__c) || 
                        (ipsNew.reduivy__Units_Enrolled__c != ipsOld.reduivy__Units_Enrolled__c) || 
                        (ipsNew.reduivy__Credits_Earned__c != ipsOld.reduivy__Credits_Earned__c) || 
                        (ipsNew.reduivy__Units_Passed__c != ipsOld.reduivy__Units_Passed__c) || 
                        (ipsNew.reduivy__Units_Contributed__c != ipsOld.reduivy__Units_Contributed__c) ||
                        (ipsNew.reduivy__Required_Children_Completed__c != ipsOld.reduivy__Required_Children_Completed__c)
                    ) {
                        workingList.add(ipsNew);
                    }
                }
            }

            if (!workingList.isEmpty()) {
                setIpsGroupStatus(workingList);
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
                if (ipsNew.RecordTypeId == IPS_GROUP_RECORD_TYPE_ID) {
                    reduivy__Individual_Plan_Structure__c ipsOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsNew.Id);

                    if ((ipsNew.reduivy__Max_Credits__c != ipsOld.reduivy__Max_Credits__c) || 
                        (ipsNew.reduivy__Credits__c != ipsOld.reduivy__Credits__c) || 
                        (ipsNew.reduivy__Units_Required__c != ipsOld.reduivy__Units_Required__c) || 
                        (ipsNew.reduivy__Credits_Enrolled__c != ipsOld.reduivy__Credits_Enrolled__c) || 
                        (ipsNew.reduivy__Units_Enrolled__c != ipsOld.reduivy__Units_Enrolled__c) || 
                        (ipsNew.reduivy__Credits_Earned__c != ipsOld.reduivy__Credits_Earned__c) || 
                        (ipsNew.reduivy__Units_Passed__c != ipsOld.reduivy__Units_Passed__c) || 
                        (ipsNew.reduivy__Units_Contributed__c != ipsOld.reduivy__Units_Contributed__c) ||
                        (ipsNew.reduivy__Parent_Plan_Structure__c != ipsOld.reduivy__Parent_Plan_Structure__c) || 
                        (ipsNew.reduivy__Required_Children_Completed__c != ipsOld.reduivy__Required_Children_Completed__c)
                    ) {
                        if (String.isNotBlank(ipsNew.reduivy__Parent_Plan_Structure__c)) {
        
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

                if ((ipsOld.RecordTypeId == IPS_GROUP_RECORD_TYPE_ID) && 
                    (String.isNotBlank(ipsOld.reduivy__Parent_Plan_Structure__c))
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
     * @description Set the group status
     * @param ipsGroupList List<reduivy__Individual_Plan_Structure__c>
     */
    private static void setIpsGroupStatus(List<reduivy__Individual_Plan_Structure__c> ipsGroupList) {

        Schema.DescribeFieldResult completionPercentageDfr = SObjectType.reduivy__Individual_Plan_Structure__c.fields.reduivy__Completion_Percentage__c;
        Integer completionPercentageScale = completionPercentageDfr.getScale();

        for (reduivy__Individual_Plan_Structure__c ipsGroup : ipsGroupList) {

            // If the group is using credits
            if (ipsGroup.reduivy__Credits__c != null) {

                ipsGroup.reduivy__Credits_Enrolled__c = (ipsGroup.reduivy__Credits_Enrolled__c == null) ? 0 : ipsGroup.reduivy__Credits_Enrolled__c;
                ipsGroup.reduivy__Credits_Earned__c = (ipsGroup.reduivy__Credits_Earned__c == null) ? 0 : ipsGroup.reduivy__Credits_Earned__c;

                if (ipsGroup.reduivy__Credits_Enrolled__c == 0) {
                    ipsGroup.reduivy__Status__c = IPS_GROUP_NOTSTARTED_STATUSES.get(0);

                } else if (ipsGroup.reduivy__Credits_Enrolled__c > 0) {
                    ipsGroup.reduivy__Status__c = IPS_GROUP_INPROGRESS_STATUSES.get(0);
                }

                if (ipsGroup.reduivy__Credits_Earned__c >= ipsGroup.reduivy__Credits__c && ipsGroup.reduivy__Required_Children_Completed__c) {
                    ipsGroup.reduivy__Status__c = IPS_GROUP_COMPLETED_STATUSES.get(0);
                }

                if (ipsGroup.reduivy__Credits__c > 0) {
                    Decimal ipsgCompletionPercentage = (ipsGroup.reduivy__Credits_Earned__c / ipsGroup.reduivy__Credits__c) * 100;
                    ipsGroup.reduivy__Completion_Percentage__c = ipsgCompletionPercentage > 100 ? 100 : ipsgCompletionPercentage;
                    
                    ipsGroup.reduivy__Completion_Percentage__c = REDU_Number_UTIL.setScale(ipsGroup.reduivy__Completion_Percentage__c, completionPercentageScale);
                }

            // If the group is using # of units required
            } else if (ipsGroup.reduivy__Units_Required__c != null) {

                ipsGroup.reduivy__Units_Enrolled__c = (ipsGroup.reduivy__Units_Enrolled__c == null) ? 0 : ipsGroup.reduivy__Units_Enrolled__c;
                ipsGroup.reduivy__Units_Passed__c = (ipsGroup.reduivy__Units_Passed__c == null) ? 0 : ipsGroup.reduivy__Units_Passed__c;
                ipsGroup.reduivy__Units_Contributed__c = (ipsGroup.reduivy__Units_Contributed__c == null) ? 0 : ipsGroup.reduivy__Units_Contributed__c; 

                if (ipsGroup.reduivy__Units_Enrolled__c == 0) {
                    ipsGroup.reduivy__Status__c = IPS_GROUP_NOTSTARTED_STATUSES.get(0);

                } else if (ipsGroup.reduivy__Units_Enrolled__c > 0) {
                    ipsGroup.reduivy__Status__c = IPS_GROUP_INPROGRESS_STATUSES.get(0);
                }

                if (ipsGroup.reduivy__Units_Contributed__c >= ipsGroup.reduivy__Units_Required__c && ipsGroup.reduivy__Required_Children_Completed__c) {
                    ipsGroup.reduivy__Status__c = IPS_GROUP_COMPLETED_STATUSES.get(0);
                }

                if (ipsGroup.reduivy__Units_Required__c > 0) {
                    Decimal ipsgCompletionPercentage = (ipsGroup.reduivy__Units_Contributed__c / ipsGroup.reduivy__Units_Required__c) * 100;
                    ipsGroup.reduivy__Completion_Percentage__c = ipsgCompletionPercentage > 100 ? 100 : ipsgCompletionPercentage;

                    ipsGroup.reduivy__Completion_Percentage__c = REDU_Number_UTIL.setScale(ipsGroup.reduivy__Completion_Percentage__c, completionPercentageScale);
                }
            }
        }
    }

    /**
     * @description Rollup credits earned and units passed from child individual plan structure (group) to parent individual plan structure (group)
     * @param ipsgMap Map<Id, List<reduivy__Individual_Plan_Structure__c>>
     */
    private static void rollupToIpsGroup(Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipsgMap) {

        // Rollup from child individual plan structure (group) to parent individual plan structure (group)
        List<reduivy__Individual_Plan_Structure__c> ipsgParentUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
        
        for (reduivy__Individual_Plan_Structure__c ipsgParent : getIpsGroupList(new Map<String, Object>{
            'ipsGroupRecordTypeId' => IPS_GROUP_RECORD_TYPE_ID,
            'ipsGroupIdSet' => ipsgMap.keySet()
        })) {

            Decimal groupCreditsEnrolled = 0;
            Decimal groupUnitsEnrolled = 0;
            Decimal groupCreditsEarned = 0;
            Decimal groupUnitsPassed = 0;
            Decimal groupUnitsContributed = 0;
            Integer incompleteRequiredChildrenCount = 0;
            Boolean requiredChildrenCompleted;
            

            for (reduivy__Individual_Plan_Structure__c ipsgChild : ipsgParent.reduivy__Individual_Plan_Structures__r) {

                // Credits enrolled
                if (ipsgChild.reduivy__Credits_Enrolled__c != null) {
                    groupCreditsEnrolled += ipsgChild.reduivy__Credits_Enrolled__c;
                }

                // Units enrolled
                if (ipsgChild.reduivy__Units_Enrolled__c != null) {
                    groupUnitsEnrolled += ipsgChild.reduivy__Units_Enrolled__c;
                }

                // Credits earned
                if (ipsgChild.reduivy__Credits_Earned__c != null) {
                    groupCreditsEarned += ipsgChild.reduivy__Credits_Earned__c;

                    if (ipsgParent.reduivy__Max_Credits__c != null) {
                        groupCreditsEarned = (groupCreditsEarned > ipsgParent.reduivy__Max_Credits__c) ? ipsgParent.reduivy__Max_Credits__c : groupCreditsEarned;
                    }
                }

                // Units passed
                if (ipsgChild.reduivy__Units_Passed__c != null) {
                    groupUnitsPassed += ipsgChild.reduivy__Units_Passed__c;
                }

                // Units contributed
                if (ipsgChild.reduivy__Units_Contributed__c != null) {
                    groupUnitsContributed += ipsgChild.reduivy__Units_Contributed__c;
                }

                //all required child ipsg should be completed to set the reduivy__Required_Children_Completed__c to true
                if(ipsgChild.reduivy__Category__c == IPS_Helper.CATEGORY_REQUIRED) {
                    incompleteRequiredChildrenCount++;

                    if(IPS_GROUP_COMPLETED_STATUSES.contains(ipsgChild.reduivy__Status__c)) {
                        incompleteRequiredChildrenCount--;
                    }
                }
            }

            requiredChildrenCompleted = incompleteRequiredChildrenCount == 0;

            if (groupCreditsEnrolled != ipsgParent.reduivy__Credits_Enrolled__c || groupUnitsEnrolled != ipsgParent.reduivy__Units_Enrolled__c || groupCreditsEarned != ipsgParent.reduivy__Credits_Earned__c || groupUnitsPassed != ipsgParent.reduivy__Units_Passed__c || groupUnitsContributed != ipsgParent.reduivy__Units_Contributed__c || requiredChildrenCompleted != ipsgParent.reduivy__Required_Children_Completed__c ) {
                reduivy__Individual_Plan_Structure__c ipsgParentUpdate = new reduivy__Individual_Plan_Structure__c(
                    Id = ipsgParent.Id,
                    reduivy__Credits_Enrolled__c = groupCreditsEnrolled,
                    reduivy__Units_Enrolled__c = groupUnitsEnrolled,
                    reduivy__Credits_Earned__c = groupCreditsEarned,
                    reduivy__Units_Passed__c = groupUnitsPassed,
                    reduivy__Units_Contributed__c = groupUnitsContributed,
                    reduivy__Required_Children_Completed__c = requiredChildrenCompleted
                );

                ipsgParentUpdateList.add(ipsgParentUpdate);
            }
        }

        if (!ipsgParentUpdateList.isEmpty()) {
            //Rollup using system mode as the fields are non editable by normal user
            REDU_SystemMode_UTIL.doUpdate(ipsgParentUpdateList, ipsgMap, 'Id', false);
        }
    }

    /**
     * @description Get the list of individual plan structure group records with child group records
     * @param bindMap Map<String, Object> (keys: 'ipsGroupRecordTypeId', 'ipsGroupIdSet')
     * @return List<reduivy__Individual_Plan_Structure__c>
     */
    private static List<reduivy__Individual_Plan_Structure__c> getIpsGroupList(Map<String, Object> bindMap) {

        Set<String> ipsFields = new Set<String>{
            'Id',
            'reduivy__Individual_Program_Enrollment__c',
            'reduivy__Max_Credits__c',
            'reduivy__Parent_Plan_Structure__c', 
            'reduivy__Credits_Enrolled__c',
            'reduivy__Units_Enrolled__c', 
            'reduivy__Credits_Earned__c',
            'reduivy__Units_Passed__c', 
            'reduivy__Units_Contributed__c',
            'reduivy__Sequence_Key__c',
            'reduivy__Category__c',
            'reduivy__Status__c',
            'reduivy__Required_Children_Completed__c'
        };

        String queryStr = 'SELECT ' + String.join(ipsFields, ', ') + ', ' +
                ' (SELECT ' + String.join(ipsFields, ', ') +
                ' FROM reduivy__Individual_Plan_Structures__r ' + 
                ' WHERE RecordTypeId = :ipsGroupRecordTypeId ' + 
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
}