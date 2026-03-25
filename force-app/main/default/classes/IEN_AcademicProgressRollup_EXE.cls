/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description To rollup the credits from Individual Enrollment to Individual Academic Progress
 * @changehistory
 * ISS-001818 05-01-2024 Lean - new class
 * ISS-001929 05-04-2024 Jordan - Fixed bug with rolling up to old IPRs after IPR changed
 * ISS-001954 24-05-2024 VTan - Update "FOR UPDATE" keyword on the SOQL to avoid race condition
 * ISS-002060 03-09-2024 Lean - Changed to without sharing
 * ISS-002231 25-03-2025 Lean - Added deferred status
 * ISS-002433 28-01-2026 Lean - Corrected credits earned rollup
 */
public without sharing class IEN_AcademicProgressRollup_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description Individual enrollment student record type Id
     */
    private static final Id IEN_STUDENT_RECORDTYPE_ID = IEN_Helper.getStudentRecordTypeId();

    static final Set<String> IEN_ROLLUP_STATUSES = new Set<String>();
    static {
        IEN_ROLLUP_STATUSES.addAll(IEN_Helper.getInProgressStatuses());
        IEN_ROLLUP_STATUSES.addAll(IEN_Helper.getCompletedStatuses());
        IEN_ROLLUP_STATUSES.addAll(IEN_Helper.getWithdrawalRequestedStatuses());
        IEN_ROLLUP_STATUSES.addAll(IEN_Helper.getDeferredStatuses());
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

            List<reduivy__Individual_Enrollment__c> ienToRollup = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                if (isNewlyReleasedOrReleaseInfoChanges(ienNew, null)) {
                    ienToRollup.add(ienNew);
                }
            }

            if (!ienToRollup.isEmpty()) {
                rollupToAcademicProgress(ienToRollup, null);
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

            List<reduivy__Individual_Enrollment__c> ienToRollup = new List<reduivy__Individual_Enrollment__c>();
            List<reduivy__Individual_Enrollment__c> oldIenToRollup = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);

                if (isNewlyReleasedOrReleaseInfoChanges(ienNew, ienOld)) {
                    ienToRollup.add(ienNew);
                    oldIenToRollup.add(ienOld);
                }
            }

            if (!ienToRollup.isEmpty()) {
                rollupToAcademicProgress(ienToRollup, oldIenToRollup);
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

            List<reduivy__Individual_Enrollment__c> ienToRollup = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienOld : (List<reduivy__Individual_Enrollment__c>) oldList) {
                if (isNewlyReleasedOrReleaseInfoChanges(null, ienOld)) {
                    ienToRollup.add(ienOld);
                }
            }

            if (!ienToRollup.isEmpty()) {
                rollupToAcademicProgress(ienToRollup, null);
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

            List<reduivy__Individual_Enrollment__c> ienToRollup = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                if (isNewlyReleasedOrReleaseInfoChanges(ienNew, null)) {
                    ienToRollup.add(ienNew);
                }
            }

            if (!ienToRollup.isEmpty()) {
                rollupToAcademicProgress(ienToRollup, null);
            }
        }
    }

    /**
     * @description This is to validate the new individual enrollment's grade is released or the existing individual enrollment's grade is unreleased or changed. The enrollment status is considered too to calculate the credits enrolled.
     * @param ienNew New individual enrollment
     * @param ienOld Old individual enrollment
     * @return Boolean
     */
    private Boolean isNewlyReleasedOrReleaseInfoChanges(reduivy__Individual_Enrollment__c ienNew, reduivy__Individual_Enrollment__c ienOld) {
        
        Boolean wasReleased = (ienOld != null && ienOld.reduivy__Grade_Release_Status__c == IEN_Helper.GRADE_RELEASE_STATUS_RELEASED);
        Boolean isReleased = (ienNew != null && ienNew.reduivy__Grade_Release_Status__c == IEN_Helper.GRADE_RELEASE_STATUS_RELEASED);
        
        Boolean wasEnrolled = (ienOld != null && IEN_ROLLUP_STATUSES.contains(ienOld.reduivy__Enrollment_Status__c));
        Boolean isEnrolled = (ienNew != null && IEN_ROLLUP_STATUSES.contains(ienNew.reduivy__Enrollment_Status__c));

        Boolean isCreditsAttemptedChanged = (ienOld != null ? ienOld.reduivy__Credits_Attempted__c : null) != (ienNew != null ? ienNew.reduivy__Credits_Attempted__c : null);
        Boolean isCreditsEarnedChanged = (ienOld != null ? ienOld.reduivy__Credits_Earned__c : null) != (ienNew != null ? ienNew.reduivy__Credits_Earned__c : null);
        Boolean isExcludeCreditsChanged = (ienOld != null ? ienOld.reduivy__Exclude_Credits_Earned__c : null) != (ienNew != null ? ienNew.reduivy__Exclude_Credits_Earned__c : null);
        Boolean isExcludeGpaChanged = (ienOld != null ? ienOld.reduivy__Exclude_GPA_Calculation__c : null) != (ienNew != null ? ienNew.reduivy__Exclude_GPA_Calculation__c : null);
        Boolean isQualityPointsChanged = (ienOld != null ? ienOld.reduivy__Quality_Points__c : null) != (ienNew != null ? ienNew.reduivy__Quality_Points__c : null);
        Boolean isAcademicProgressChanged = (ienOld != null ? ienOld.reduivy__Individual_Academic_Progress__c : null) != (ienNew != null ? ienNew.reduivy__Individual_Academic_Progress__c : null);
        
        return ((ienNew != null && ienNew.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID) || (ienNew == null && ienOld != null && ienOld.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID)) && (
            ((isEnrolled && !wasEnrolled) || (!isEnrolled && wasEnrolled)) ||
            ((isReleased && !wasReleased) || (!isReleased && wasReleased)) ||
            (
                isReleased && 
                (
                    isCreditsAttemptedChanged ||
                    isCreditsEarnedChanged ||
                    isExcludeCreditsChanged ||
                    isExcludeGpaChanged ||
                    isQualityPointsChanged ||
                    isAcademicProgressChanged
                )
            )
        );
    }
	
    /**
     * @description Rollup the credits and unit count to individual academic progress
     * @param ienList List of individual enrollments
     * @param oldIenList List of individual enrollments which the individual academic progress has changed for recalculation
     * @return void
     */
    private void rollupToAcademicProgress(List<reduivy__Individual_Enrollment__c> ienList, List<reduivy__Individual_Enrollment__c> oldIenList) {
        
        Set<Id> contactIds = new Set<Id>();
        Map<Id, List<reduivy__Individual_Enrollment__c>> qualifiedIenByIprMap = new Map<Id, List<reduivy__Individual_Enrollment__c>>();

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Contact__c) &&
                String.isNotBlank(ien.reduivy__Individual_Academic_Progress__c)
            ) {
                contactIds.add(ien.reduivy__Contact__c);

                if (qualifiedIenByIprMap.containsKey(ien.reduivy__Individual_Academic_Progress__c)) {
                    qualifiedIenByIprMap.get(ien.reduivy__Individual_Academic_Progress__c).add(ien);
                } else {
                    qualifiedIenByIprMap.put(ien.reduivy__Individual_Academic_Progress__c, new List<reduivy__Individual_Enrollment__c>{ien});
                }
            }
        }

        //to cater for recalculation of the previous ipr
        if (oldIenList != null && !oldIenList.isEmpty()) {
            Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>(ienList);

            for (reduivy__Individual_Enrollment__c ienOld : oldIenList) {
                if (String.isNotBlank(ienOld.reduivy__Individual_Academic_Progress__c)) {
    
                    if (qualifiedIenByIprMap.containsKey(ienOld.reduivy__Individual_Academic_Progress__c)) {
                        qualifiedIenByIprMap.get(ienOld.reduivy__Individual_Academic_Progress__c).add(ienMap.get(ienOld.Id));
                    } else {
                        qualifiedIenByIprMap.put(ienOld.reduivy__Individual_Academic_Progress__c, new List<reduivy__Individual_Enrollment__c>{ienMap.get(ienOld.Id)});
                    }
                }
            }
        }

        List<reduivy__Individual_Academic_Progress__c> iprUpdateList = new List<reduivy__Individual_Academic_Progress__c>();

        Map<String, Object> ipfBindParams = new Map<String, Object>();
        ipfBindParams.put('ipfIds', qualifiedIenByIprMap.keySet());
        ipfBindParams.put('contactIds', contactIds);

        Set<String> iprFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Units_Completed__c',
            'reduivy__Units_Enrolled__c',
            'reduivy__Credits_Attempted__c',
            'reduivy__Credits_Earned__c',
            'reduivy__Credits_Enrolled__c',
            'reduivy__Quality_Points__c'
        };

        Set<String> ienFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Credits_Attempted__c',
            'reduivy__Credits_Earned__c',
            'reduivy__Credits_Offered__c',
            'reduivy__Quality_Points__c',
            'reduivy__Exclude_Credits_Earned__c',
            'reduivy__Exclude_GPA_Calculation__c',
            'reduivy__Enrollment_Status__c',
            'reduivy__Grade_Release_Status__c',
            'reduivy__Target_Unit_Id__c',
            'reduivy__Best_Attempt__c'
        };

        String ipfQuery = 'SELECT ' + String.join(iprFields, ', ') + ', ' + 
            ' (SELECT ' + String.join(ienFields, ', ') +
                ' FROM reduivy__Individual_Enrollments__r) ' +
            ' FROM reduivy__Individual_Academic_Progress__c ' +
            ' WHERE Id IN: ipfIds AND reduivy__Contact__c IN: contactIds '+
            ' FOR UPDATE';

        Map<String, Set<String>> iprObjectFieldsForFls = new Map<String, Set<String>>();
        iprObjectFieldsForFls.put(IPR_Helper.getApiName(), iprFields);
        iprObjectFieldsForFls.put(IEN_Helper.getApiName(), ienFields);

        if (!qualifiedIenByIprMap.isEmpty()) {
            for (reduivy__Individual_Academic_Progress__c ipr : (List<reduivy__Individual_Academic_Progress__c>) REDU_SystemMode_UTIL.doQuery(ipfQuery, ipfBindParams, iprObjectFieldsForFls)) {

                Decimal sumUnitsCompleted = 0;
                Decimal sumUnitsEnrolled = 0;
                Decimal sumCreditsAttempted = 0;
                Decimal sumCreditsEarned = 0;
                Decimal sumCreditsEnrolled = 0;
                Decimal sumQualityPoints = 0;

                Map<Id, reduivy__Individual_Enrollment__c> unitsToCreditsEarnedIen = new Map<Id, reduivy__Individual_Enrollment__c>();

                for (reduivy__Individual_Enrollment__c ien : ipr.reduivy__Individual_Enrollments__r) {

                    Decimal creditsAttempted = ien.reduivy__Credits_Attempted__c == null ? 0 : ien.reduivy__Credits_Attempted__c;
                    Decimal creditsEarned = ien.reduivy__Credits_Earned__c == null ? 0 : ien.reduivy__Credits_Earned__c;
                    Decimal creditsOffered = ien.reduivy__Credits_Offered__c == null ? 0 : ien.reduivy__Credits_Offered__c;
                    Decimal qualityPoints = ien.reduivy__Quality_Points__c == null ? 0 : ien.reduivy__Quality_Points__c;
                    
                    if (ien.reduivy__Grade_Release_Status__c == IEN_Helper.GRADE_RELEASE_STATUS_RELEASED) {
                        // ISS-002433 skip the credits earned if it is excluded or attempted multiple times in the same term
                        if (!ien.reduivy__Exclude_Credits_Earned__c) {
                            if (IEN_Helper.isCurrentHigherCreditsEarned(ien, unitsToCreditsEarnedIen.get(ien.reduivy__Target_Unit_Id__c))) {

                                sumCreditsEarned += creditsEarned - (unitsToCreditsEarnedIen.get(ien.reduivy__Target_Unit_Id__c)?.reduivy__Credits_Earned__c ?? 0);
                                unitsToCreditsEarnedIen.put(ien.reduivy__Target_Unit_Id__c, ien);
                            }

                            // if (unitsToCreditsEarnedIen.containsKey(ien.reduivy__Target_Unit_Id__c)) {

                            //     if (ien.reduivy__Best_Attempt__c || 
                            //         (
                            //             !unitsToCreditsEarnedIen.get(ien.reduivy__Target_Unit_Id__c).reduivy__Best_Attempt__c &&
                            //             creditsEarned > (unitsToCreditsEarnedIen.get(ien.reduivy__Target_Unit_Id__c).reduivy__Credits_Earned__c ?? 0)
                            //         )
                            //     ) {
                            //         sumCreditsEarned += creditsEarned - unitsToCreditsEarnedIen.get(ien.reduivy__Target_Unit_Id__c).reduivy__Credits_Earned__c;
                            //         unitsToCreditsEarnedIen.put(ien.reduivy__Target_Unit_Id__c, ien);
                            //     }
                            // } else {
                            //     sumCreditsEarned += creditsEarned;
                            //     unitsToCreditsEarnedIen.put(ien.reduivy__Target_Unit_Id__c, ien);
                            // }
                            
                        }

                        if (!ien.reduivy__Exclude_GPA_Calculation__c) {
                            sumCreditsAttempted += creditsAttempted;
                            sumQualityPoints += qualityPoints;
                        }

                        sumUnitsCompleted ++;
                    }

                    if (IEN_ROLLUP_STATUSES.contains(ien.reduivy__Enrollment_Status__c)) {
                        sumCreditsEnrolled += (ien.reduivy__Grade_Release_Status__c == IEN_Helper.GRADE_RELEASE_STATUS_RELEASED ? creditsAttempted : creditsOffered);
                        sumUnitsEnrolled ++;
                    }
                }

                if (sumUnitsCompleted != ipr.reduivy__Units_Completed__c ||
                    sumUnitsEnrolled != ipr.reduivy__Units_Enrolled__c ||
                    sumCreditsAttempted != ipr.reduivy__Credits_Attempted__c ||
                    sumCreditsEarned != ipr.reduivy__Credits_Earned__c ||
                    sumCreditsEnrolled != ipr.reduivy__Credits_Enrolled__c ||
                    sumQualityPoints != ipr.reduivy__Quality_Points__c
                ) {
                    reduivy__Individual_Academic_Progress__c iprToUpdate = new reduivy__Individual_Academic_Progress__c(
                        Id = ipr.Id,
                        reduivy__Units_Completed__c = sumUnitsCompleted,
                        reduivy__Units_Enrolled__c = sumUnitsEnrolled,
                        reduivy__Credits_Attempted__c = sumCreditsAttempted,
                        reduivy__Credits_Earned__c = sumCreditsEarned,
                        reduivy__Credits_Enrolled__c = sumCreditsEnrolled,
                        reduivy__Quality_Points__c = sumQualityPoints
                    );

                    iprUpdateList.add(iprToUpdate);
                }
            }

            if (!iprUpdateList.isEmpty()) {
                //for student, we will use system mode as they don't have edit permission to some fields
                REDU_SystemMode_UTIL.doUpdate(iprUpdateList, qualifiedIenByIprMap, 'Id', false);
            }
        }
    }
}