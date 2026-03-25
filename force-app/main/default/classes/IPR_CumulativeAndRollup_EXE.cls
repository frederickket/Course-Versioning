/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description To calculate the cumulative information on Individual Academic Progress and rollup to Individual Academic Profile
 * @changehistory
 * ISS-001836 03-01-2024 Lean - new class
 * ISS-001954 24-05-2024 VTan - Update "FOR UPDATE" keyword on the SOQL to avoid race condition
 * ISS-002060 03-09-2024 Lean - Changed to without sharing
 * ISS-002433 28-01-2026 Lean - Fixed GPA/CGPA calculation for past term and corrected credits earned rollup
 */
public without sharing class IPR_CumulativeAndRollup_EXE extends REDU_TriggerExecutable {

    /**
     * @description Exclude GPA for repeated unit app setting
     */
    private static final Boolean EXCLUDE_GPA_FOR_REPEATED_UNIT = REDU_AppSetting_UTIL.isExcludeGpaForRepeatedUnit();

    /**
     * @description Calculate the cumulative information for the Individual Academic Progress and rollup to Individual Academic Profile
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Academic_Progress__c> iprForCumList = new List<reduivy__Individual_Academic_Progress__c>();

            for (reduivy__Individual_Academic_Progress__c iprNew : (List<reduivy__Individual_Academic_Progress__c>) newList) {
                if (isCumulativeInfoChanges(iprNew, null)) {
                    iprForCumList.add(iprNew);
                }
            }

            if (!iprForCumList.isEmpty()) {
                calculateAndRollupCumulativeInfo(iprForCumList, null);
            }
        }
    }

    /**
     * @description Calculate the cumulative information for the Individual Academic Progress and rollup to Individual Academic Profile
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Academic_Progress__c> iprForCumList = new List<reduivy__Individual_Academic_Progress__c>();
            List<reduivy__Individual_Academic_Progress__c> oldIprForCumList = new List<reduivy__Individual_Academic_Progress__c>();

            for (reduivy__Individual_Academic_Progress__c newIpr : (List<reduivy__Individual_Academic_Progress__c>) newList) {
                reduivy__Individual_Academic_Progress__c oldIpr = (reduivy__Individual_Academic_Progress__c) oldMap.get(newIpr.Id);

                if (isCumulativeInfoChanges(newIpr, oldIpr)) {
                    iprForCumList.add(newIpr);

                    if (newIpr.reduivy__Individual_Academic_Profile__c != oldIpr.reduivy__Individual_Academic_Profile__c) {
                        oldIprForCumList.add(oldIpr);
                    }
                }
            }

            if (!iprForCumList.isEmpty()) {
                calculateAndRollupCumulativeInfo(iprForCumList, oldIprForCumList);
            }
        }
    }

    /**
     * @description Calculate the cumulative information for the Individual Academic Progress and rollup to Individual Academic Profile
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Academic_Progress__c> iprForCumList = new List<reduivy__Individual_Academic_Progress__c>();

            for (reduivy__Individual_Academic_Progress__c iprOld : (List<reduivy__Individual_Academic_Progress__c>) oldList) {
                if (isCumulativeInfoChanges(null, iprOld)) {
                    iprForCumList.add(iprOld);
                }
            }

            if (!iprForCumList.isEmpty()) {
                calculateAndRollupCumulativeInfo(iprForCumList, null);
            }
        }
    }

    /**
     * @description Calculate the cumulative information for the Individual Academic Progress and rollup to Individual Academic Profile
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUndelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Academic_Progress__c> iprForCumList = new List<reduivy__Individual_Academic_Progress__c>();

            for (reduivy__Individual_Academic_Progress__c iprNew : (List<reduivy__Individual_Academic_Progress__c>) newList) {
                if (isCumulativeInfoChanges(iprNew, null)) {
                    iprForCumList.add(iprNew);
                }
            }

            if (!iprForCumList.isEmpty()) {
                calculateAndRollupCumulativeInfo(iprForCumList, null);
            }
        }
    }

    /**
     * @description This to validate the new individual academic progress info for cumulative info is set or the existing cumulative info is changed
     * @param iprNew New individual academic progress
     * @param iprOld Old individual academic progress
     * @return Boolean
     */
    private Boolean isCumulativeInfoChanges(reduivy__Individual_Academic_Progress__c iprNew, reduivy__Individual_Academic_Progress__c iprOld) {

        Boolean isUnitsCompletedChanged = (iprOld != null ? iprOld.reduivy__Units_Completed__c : null) != (iprNew != null ? iprNew.reduivy__Units_Completed__c : null);
        Boolean isUnitsEnrolledChanged = (iprOld != null ? iprOld.reduivy__Units_Enrolled__c : null) != (iprNew != null ? iprNew.reduivy__Units_Enrolled__c : null);
        Boolean isCreditsAttemptedChanged = (iprOld != null ? iprOld.reduivy__Credits_Attempted__c : null) != (iprNew != null ? iprNew.reduivy__Credits_Attempted__c : null);
        Boolean isCreditsEarnedChanged = (iprOld != null ? iprOld.reduivy__Credits_Earned__c : null) != (iprNew != null ? iprNew.reduivy__Credits_Earned__c : null);
        Boolean isCreditsEnrolledChanged = (iprOld != null ? iprOld.reduivy__Credits_Enrolled__c : null) != (iprNew != null ? iprNew.reduivy__Credits_Enrolled__c : null);
        Boolean isQualityPointsChanged = (iprOld != null ? iprOld.reduivy__Quality_Points__c : null) != (iprNew != null ? iprNew.reduivy__Quality_Points__c : null);
        Boolean isAcademicProfileChanged = (iprOld != null ? iprOld.reduivy__Individual_Academic_Profile__c : null) != (iprNew != null ? iprNew.reduivy__Individual_Academic_Profile__c : null);

        return (
            isUnitsCompletedChanged || 
            isUnitsEnrolledChanged || 
            isCreditsAttemptedChanged || 
            isCreditsEarnedChanged || 
            isCreditsEnrolledChanged || 
            isQualityPointsChanged || 
            isAcademicProfileChanged
        );
    }

    /**
     * @description Sum the cumulative information accross ipr and rollup to ipf
     * @param iprList List of reduivy__Individual_Academic_Progress__c
     * @param oldIprList List of old reduivy__Individual_Academic_Progress__c which the individual academic profile has changed for recalculation
     * @return void
     */
    private void calculateAndRollupCumulativeInfo(List<reduivy__Individual_Academic_Progress__c> iprList, List<reduivy__Individual_Academic_Progress__c> oldIprList) {

        Set<Id> contactIds = new Set<Id>();
        Map<Id, List<reduivy__Individual_Academic_Progress__c>> qualifiedIprByIpfMap = new Map<Id, List<reduivy__Individual_Academic_Progress__c>>();

        //collect the record ids for query
        for (reduivy__Individual_Academic_Progress__c ipr : iprList) {
            if (String.isNotBlank(ipr.reduivy__Individual_Academic_Profile__c) &&
                String.isNotBlank(ipr.reduivy__Academic_Term__c) &&
                String.isNotBlank(ipr.reduivy__Contact__c)
            ) {
                contactIds.add(ipr.reduivy__Contact__c);

                if (qualifiedIprByIpfMap.containsKey(ipr.reduivy__Individual_Academic_Profile__c)) {
                    qualifiedIprByIpfMap.get(ipr.reduivy__Individual_Academic_Profile__c).add(ipr);
                } else {
                    qualifiedIprByIpfMap.put(ipr.reduivy__Individual_Academic_Profile__c, new List<reduivy__Individual_Academic_Progress__c>{ipr});
                }
            }
        }

        // To cater the recalculation of the previous ipf
        if (oldIprList != null && !oldIprList.isEmpty()) {
            Map<Id, reduivy__Individual_Academic_Progress__c> iprMap = new Map<Id, reduivy__Individual_Academic_Progress__c>(iprList);

            for (reduivy__Individual_Academic_Progress__c oldIpr : oldIprList) {
                if (String.isNotBlank(oldIpr.reduivy__Individual_Academic_Profile__c)) {

                    //we add the ipr from the iprMap so that we can addError to it if dml failed
                    if (qualifiedIprByIpfMap.containsKey(oldIpr.reduivy__Individual_Academic_Profile__c)) {
                        qualifiedIprByIpfMap.get(oldIpr.reduivy__Individual_Academic_Profile__c).add(iprMap.get(oldIpr.Id));
                    } else {
                        qualifiedIprByIpfMap.put(oldIpr.reduivy__Individual_Academic_Profile__c, new List<reduivy__Individual_Academic_Progress__c>{iprMap.get(oldIpr.Id)});
                    }
                }
            }
        }

        List<reduivy__Individual_Academic_Progress__c> iprUpdateList = new List<reduivy__Individual_Academic_Progress__c>();
        List<reduivy__Individual_Academic_Profile__c> ipfUpdateList = new List<reduivy__Individual_Academic_Profile__c>();
        
        Set<String> ipfFields = new Set<String>{
            'Id',
            'reduivy__Cumulative_Credits_Attempted__c',
            'reduivy__Cumulative_Quality_Points__c',
            'reduivy__Cumulative_GPA__c'
        };

        Set<String> iprFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Units_Completed__c',
            'reduivy__Units_Enrolled__c',
            'reduivy__Credits_Attempted__c',
            'reduivy__Credits_Earned__c',
            'reduivy__Credits_Enrolled__c',
            'reduivy__Quality_Points__c',
            'reduivy__Cumulative_Units_Completed__c',
            'reduivy__Cumulative_Units_Enrolled__c',
            'reduivy__Cumulative_Credits_Attempted__c',
            'reduivy__Cumulative_Credits_Earned__c',
            'reduivy__Cumulative_Credits_Enrolled__c',
            'reduivy__Cumulative_Quality_Points__c',
            'reduivy__Cumulative_GPA__c',
            'reduivy__Individual_Academic_Profile__c',
            'reduivy__Academic_Term__c',
            'reduivy__Academic_Term__r.reduivy__Start_Date__c'
        };

        Set<String> ienFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Attempt_Number__c',
            'reduivy__Best_Attempt__c',
            'reduivy__Credits_Attempted__c',
            'reduivy__Credits_Earned__c',
            'reduivy__Quality_Points__c',
            'reduivy__Exclude_Credits_Earned__c',
            'reduivy__Exclude_GPA_Calculation__c',
            'reduivy__Individual_Academic_Progress__c',
            'reduivy__Target_Unit_Id__c',
            'reduivy__Grade_Release_Status__c',
            'reduivy__Final_Numerical_Grade__c',
            'reduivy__Start_Date__c'
        };

        Map<String, Object> ipfBindParams = new Map<String, Object>();
        ipfBindParams.put('ipfIds', qualifiedIprByIpfMap.keySet());
        ipfBindParams.put('contactIds', contactIds);

        Map<String, Object> ienBindParams = new Map<String, Object>();
        ienBindParams.put('ipfIds', qualifiedIprByIpfMap.keySet());
        ienBindParams.put('contactIds', contactIds);
        ienBindParams.put('gradeReleaseStatus', IEN_Helper.GRADE_RELEASE_STATUS_RELEASED);

        String ipfQuery = 'SELECT ' + String.join(ipfFields, ', ') +
            ' FROM reduivy__Individual_Academic_Profile__c ' +
            ' WHERE Id IN: ipfIds ' +
            ' AND reduivy__Contact__c IN: contactIds ' + 
            ' FOR UPDATE';

        String iprQuery = 'SELECT ' + String.join(iprFields, ', ') +
            ' FROM reduivy__Individual_Academic_Progress__c ' +
            ' WHERE reduivy__Individual_Academic_Profile__c IN: ipfIds ' +
            ' AND reduivy__Contact__c IN: contactIds ' + 
            ' FOR UPDATE';

        String ienQuery = 'SELECT ' + String.join(ienFields, ', ') +
            ' FROM reduivy__Individual_Enrollment__c ' +
            ' WHERE reduivy__Individual_Academic_Progress__r.reduivy__Individual_Academic_Profile__c IN: ipfIds ' +
            ' AND reduivy__Contact__c IN: contactIds ' +
            ' AND reduivy__Grade_Release_Status__c =: gradeReleaseStatus ' +
            ' ORDER BY reduivy__Quality_Points__c DESC, reduivy__Start_Date__c DESC ';

        Map<String, Set<String>> ipfObjectFieldsFls = new Map<String, Set<String>>();
        ipfObjectFieldsFls.put(IPF_Helper.getApiName(), ipfFields);

        Map<String, Set<String>> iprObjectFieldsFls = new Map<String, Set<String>>();
        iprObjectFieldsFls.put(IPR_Helper.getApiName(), iprFields);

        Map<String, Set<String>> ienObjectFieldsFls = new Map<String, Set<String>>();
        ienObjectFieldsFls.put(IEN_Helper.getApiName(), ienFields);

        //query individual academic progress and group by profile
        Map<Id, List<reduivy__Individual_Academic_Progress__c>> iprListByIpfId = new Map<Id, List<reduivy__Individual_Academic_Progress__c>>();
        for (reduivy__Individual_Academic_Progress__c ipr : (List<reduivy__Individual_Academic_Progress__c>) REDU_SystemMode_UTIL.doQuery(iprQuery, ipfBindParams, iprObjectFieldsFls)) {
            if (String.isNotBlank(ipr.reduivy__Individual_Academic_Profile__c)) {
                if (!iprListByIpfId.containsKey(ipr.reduivy__Individual_Academic_Profile__c)) {
                    iprListByIpfId.put(ipr.reduivy__Individual_Academic_Profile__c, new List<reduivy__Individual_Academic_Progress__c>());
                }

                iprListByIpfId.get(ipr.reduivy__Individual_Academic_Profile__c).add(ipr);
            }
        }

        //query individual enrollment and group by academic progress
        Map<Id, List<reduivy__Individual_Enrollment__c>> ienListByIprId = new Map<Id, List<reduivy__Individual_Enrollment__c>>();
        for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) REDU_SystemMode_UTIL.doQuery(ienQuery, ienBindParams, ienObjectFieldsFls)) {
            if (String.isNotBlank(ien.reduivy__Individual_Academic_Progress__c)) {
                if (!ienListByIprId.containsKey(ien.reduivy__Individual_Academic_Progress__c)) {
                    ienListByIprId.put(ien.reduivy__Individual_Academic_Progress__c, new List<reduivy__Individual_Enrollment__c>());
                }

                ienListByIprId.get(ien.reduivy__Individual_Academic_Progress__c).add(ien);
            }
        }

        //for sorting academic progress's start date asc null last here as we can't do that in query together with FOR UPDATE keyword
        List<REDU_SObjectComparator.SortCriterion> iprSortingCriteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion('reduivy__Individual_Academic_Progress__c.reduivy__Academic_Term__r.reduivy__Start_Date__c', REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        //compile the relevant ipr ordered by academic term's start date
        //Go through the ipf and ipr to recalculate the cumulative information and see if they need to be updated
        for (reduivy__Individual_Academic_Profile__c ipf : (List<reduivy__Individual_Academic_Profile__c>) REDU_SystemMode_UTIL.doQuery(ipfQuery, ipfBindParams, ipfObjectFieldsFls)) {

            Decimal cumUnitsCompleted = 0;
            Decimal cumUnitsEnrolled = 0;
            Decimal cumCreditsAttempted = 0;
            Decimal cumCreditsEarned = 0;
            Decimal cumCreditsEnrolled = 0;
            Decimal cumQualityPoints = 0;
            Decimal cumGpa = 0;

            Map<Id, reduivy__Individual_Enrollment__c> unitToLatestCgpaIen = new Map<Id, reduivy__Individual_Enrollment__c>();
            Map<Id, reduivy__Individual_Enrollment__c> unitToCreditsEarnedIen = new Map<Id, reduivy__Individual_Enrollment__c>();

            //sort the IPR
            List<reduivy__Individual_Academic_Progress__c> ipfIprList = (iprListByIpfId.containsKey(ipf.Id) ? iprListByIpfId.get(ipf.Id) : new List<reduivy__Individual_Academic_Progress__c>());
            ipfIprList.sort(new REDU_SObjectComparator(iprSortingCriteria));

            //loop through all ipr to calculate the cumulative
            for (reduivy__Individual_Academic_Progress__c ipr : ipfIprList) {

                //skip any ipr without academic term
                if (String.isBlank(ipr.reduivy__Academic_Term__c)) {
                    continue;
                }

                Decimal unitsCompleted = ipr.reduivy__Units_Completed__c == null ? 0 : ipr.reduivy__Units_Completed__c;
                Decimal unitsEnrolled = ipr.reduivy__Units_Enrolled__c == null ? 0 : ipr.reduivy__Units_Enrolled__c;
                Decimal creditsAttempted = ipr.reduivy__Credits_Attempted__c == null ? 0 : ipr.reduivy__Credits_Attempted__c;
                Decimal creditsEarned = ipr.reduivy__Credits_Earned__c == null ? 0 : ipr.reduivy__Credits_Earned__c;
                Decimal creditsEnrolled = ipr.reduivy__Credits_Enrolled__c == null ? 0 : ipr.reduivy__Credits_Enrolled__c;
                Decimal qualityPoints = ipr.reduivy__Quality_Points__c == null ? 0 : ipr.reduivy__Quality_Points__c;
                
                // ISS-002433 cumulated info from prev term
                Decimal prevTermCreditsAttempted = cumCreditsAttempted;
                Decimal prevTermCreditsEarned = cumCreditsEarned;
                Decimal prevQualityPoints = cumQualityPoints;

                // ISS-002433 track the credits to be excluded in this term
                Decimal repeatedCreditsAttempted = 0;
                Decimal repeatedCreditsEarned = 0;
                Decimal repeatedQualityPoints = 0;

                //ISS-002433 logic to identify the repeated units and exclude them from GPA and credits earned cumulation
                Set<Id> unitsDecreditedInTheTerm = new Set<Id>();
                List<reduivy__Individual_Enrollment__c> iprIenList = ienListByIprId.get(ipr.Id) ?? new List<reduivy__Individual_Enrollment__c>();

                for (reduivy__Individual_Enrollment__c ien : iprIenList) {
                    Id sunId = ien.reduivy__Target_Unit_Id__c;
                    
                    if (sunId == null) {
                        continue;
                    }
                    
                    // Determine exclusion based on mode
                    if (EXCLUDE_GPA_FOR_REPEATED_UNIT && !ien.reduivy__Exclude_GPA_Calculation__c) {
                        
                        if (unitToLatestCgpaIen.containsKey(sunId)) {
                            reduivy__Individual_Enrollment__c prevBestIen = unitToLatestCgpaIen.get(sunId);
                            
                            // Identify which IEN to exclude from cumulative calculation
                            reduivy__Individual_Enrollment__c ienToExclude;
                            if (IEN_Helper.isCurrentBetterAttempt(ien, prevBestIen)) {
                                ienToExclude = prevBestIen;
                                unitToLatestCgpaIen.put(sunId, ien); // Update map with the new best

                            } else {
                                ienToExclude = ien;
                            }

                            repeatedCreditsAttempted += (ienToExclude.reduivy__Credits_Attempted__c ?? 0);
                            repeatedQualityPoints += (ienToExclude.reduivy__Quality_Points__c ?? 0);

                        } else {
                            unitToLatestCgpaIen.put(sunId, ien);
                        }
                    }

                    if (!ien.reduivy__Exclude_Credits_Earned__c) {
                        if (unitToCreditsEarnedIen.containsKey(sunId)) {
                            reduivy__Individual_Enrollment__c prevHighestIen = unitToCreditsEarnedIen.get(sunId);

                            if (IEN_Helper.isCurrentHigherCreditsEarned(ien, unitToCreditsEarnedIen.get(sunId))) {

                                if (!unitsDecreditedInTheTerm.contains(sunId) && ien.reduivy__Individual_Academic_Progress__c != prevHighestIen.reduivy__Individual_Academic_Progress__c) {
                                    repeatedCreditsEarned += (prevHighestIen.reduivy__Credits_Earned__c ?? 0);
                                    unitsDecreditedInTheTerm.add(sunId);
                                }

                                unitToCreditsEarnedIen.put(sunId, ien);
                            } else {
                                if (!unitsDecreditedInTheTerm.contains(sunId) && ien.reduivy__Individual_Academic_Progress__c != prevHighestIen.reduivy__Individual_Academic_Progress__c) {
                                    repeatedCreditsEarned += (ien.reduivy__Credits_Earned__c ?? 0);
                                    unitsDecreditedInTheTerm.add(sunId);
                                }
                            }
                        } else {
                            unitToCreditsEarnedIen.put(sunId, ien);
                        }
                    }                    
                }

                cumUnitsCompleted += unitsCompleted;
                cumUnitsEnrolled += unitsEnrolled;
                cumCreditsEnrolled += creditsEnrolled;

                // ISS-002433 deduct the excluded points
                cumCreditsEarned = prevTermCreditsEarned + creditsEarned - repeatedCreditsEarned;
                cumCreditsAttempted = prevTermCreditsAttempted + creditsAttempted - repeatedCreditsAttempted;
                cumQualityPoints = prevQualityPoints + qualityPoints - repeatedQualityPoints;

                cumGpa = (cumCreditsAttempted != 0 && cumQualityPoints !=0 ? cumQualityPoints.divide(cumCreditsAttempted, 4, System.RoundingMode.HALF_UP) : 0);

                //only update ipr if one of the existing field is different
                if (cumUnitsCompleted != ipr.reduivy__Cumulative_Units_Completed__c ||
                    cumUnitsEnrolled != ipr.reduivy__Cumulative_Units_Enrolled__c ||
                    cumCreditsAttempted != ipr.reduivy__Cumulative_Credits_Attempted__c ||
                    cumCreditsEarned != ipr.reduivy__Cumulative_Credits_Earned__c ||
                    cumCreditsEnrolled != ipr.reduivy__Cumulative_Credits_Enrolled__c ||
                    cumQualityPoints != ipr.reduivy__Cumulative_Quality_Points__c ||
                    cumGpa != ipr.reduivy__Cumulative_GPA__c
                ) {
                    reduivy__Individual_Academic_Progress__c iprToUpdate = new reduivy__Individual_Academic_Progress__c(
                        Id = ipr.Id,
                        reduivy__Cumulative_Units_Completed__c = cumUnitsCompleted,
                        reduivy__Cumulative_Units_Enrolled__c = cumUnitsEnrolled,
                        reduivy__Cumulative_Credits_Attempted__c = cumCreditsAttempted,
                        reduivy__Cumulative_Credits_Earned__c = cumCreditsEarned,
                        reduivy__Cumulative_Credits_Enrolled__c = cumCreditsEnrolled,
                        reduivy__Cumulative_Quality_Points__c = cumQualityPoints,
                        reduivy__Cumulative_GPA__c = cumGpa
                    );

                    iprUpdateList.add(iprToUpdate);
                }
            }

            //only update ipf if one of the existing fields is different
            if (cumCreditsAttempted != ipf.reduivy__Cumulative_Credits_Attempted__c ||
                cumQualityPoints != ipf.reduivy__Cumulative_Quality_Points__c
            ) {
                reduivy__Individual_Academic_Profile__c ipfToUpdate = new reduivy__Individual_Academic_Profile__c(
                    Id = ipf.Id,
                    reduivy__Cumulative_Credits_Attempted__c = cumCreditsAttempted,
                    reduivy__Cumulative_Quality_Points__c = cumQualityPoints
                );

                ipfUpdateList.add(ipfToUpdate);
            }
        }

        if (!iprUpdateList.isEmpty()) {
            //for student, we will use system mode as they don't have edit permission to cumulative fields
            REDU_SystemMode_UTIL.doUpdate(iprUpdateList, qualifiedIprByIpfMap, 'reduivy__Individual_Academic_Profile__c', false);
        }
        
        if (!ipfUpdateList.isEmpty()) {
            //for student, we will use system mode as they don't have edit permission to cumulative fields
            REDU_SystemMode_UTIL.doUpdate(ipfUpdateList, qualifiedIprByIpfMap, 'Id', false);
        }
    }
}