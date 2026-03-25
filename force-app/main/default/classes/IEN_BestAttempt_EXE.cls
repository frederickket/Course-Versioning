/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description Completion engine for individual enrollment to identify the best attempt individual enrollment to set the excludes flag
 * @changehistory
 * ISS-001822 16-01-2024 Lean - new class
 * ISS-002486 10-06-2025 XiRouh - Updated from checking whether the grade result is a positive grade result to checking whether the enrollment status is a completed pass status
 * ISS-002486 25-07-2025 XiRouh - Updated the IEN query to sort by final numerical grade in asc order so we can compare all the IENs when determining the best IEN
 * ISS-002743 20-11-2025 XiRouh - Updated to evaluate best attempt within the same Individual Academic Profile context
 * ISS-002783 28-01-2026 Lean - Changed the best attempt identification to use quality points and skip updating Exclude GPA Calculation and Exclude Credits Earned flag
 */
public inherited sharing class IEN_BestAttempt_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual enrollment student record type Id
     */
    private static final Id IEN_STUDENT_RECORDTYPE_ID = IEN_Helper.getStudentRecordTypeId();
    
    /**
     * @description Individual enrollment - grade released statuses
     */
    private static final List<String> IEN_GRADE_RELEASED_STATUSES = IEN_Helper.getGradeReleasedStatuses();

    /**
     * @description Individual enrollment - completed pass statuses
     */
    private static final List<String> IEN_ENROLLMENT_COMPLETED_PASS_STATUSES = IEN_Helper.getCompletedPassStatuses();

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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)
        ) {

            List<reduivy__Individual_Enrollment__c> workingList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {

                if (isNewlyReleasedOrReleaseInfoChanges(ienNew, null)) {
                    workingList.add(ienNew);
                }
            }

            identifyBestAttempt(workingList);
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)
        ) {
            List<reduivy__Individual_Enrollment__c> workingList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {

                reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);

                if (isNewlyReleasedOrReleaseInfoChanges(ienNew, ienOld)) {
                    workingList.add(ienNew);
                }
            }

            identifyBestAttempt(workingList);
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)
        ) {
            List<reduivy__Individual_Enrollment__c> workingList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienOld : (List<reduivy__Individual_Enrollment__c>) oldList) {

                if (isNewlyReleasedOrReleaseInfoChanges(null, ienOld)) {
                    workingList.add(ienOld);
                }
            }

            identifyBestAttempt(workingList);
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)
        ) {

            List<reduivy__Individual_Enrollment__c> workingList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {

                if (isNewlyReleasedOrReleaseInfoChanges(ienNew, null)) {
                    workingList.add(ienNew);
                }
            }

            identifyBestAttempt(workingList);
        }
    }

    /**
     * @description Determine if the individual enrollment is valid for completion engine processing
     * @param ienNew New individual enrollment
     * @param ienOld Old individual enrollment
     * @return Boolean
     */
    private Boolean isNewlyReleasedOrReleaseInfoChanges(reduivy__Individual_Enrollment__c ienNew, reduivy__Individual_Enrollment__c ienOld) {
        
        Boolean wasReleased = (ienOld != null && IEN_GRADE_RELEASED_STATUSES.contains(ienOld.reduivy__Grade_Release_Status__c));
        Boolean isReleased = (ienNew != null && IEN_GRADE_RELEASED_STATUSES.contains(ienNew.reduivy__Grade_Release_Status__c));
        
        //ISS-002783
        Boolean isQualityPointsChanged = (ienOld != null ? ienOld.reduivy__Quality_Points__c : null) != (ienNew != null ? ienNew.reduivy__Quality_Points__c : null);
        Boolean isCreditsEarnedChanged = (ienOld != null ? ienOld.reduivy__Credits_Earned__c : null) != (ienNew != null ? ienNew.reduivy__Credits_Earned__c : null);
        Boolean isExcludeCreditsChanged = (ienOld != null ? ienOld.reduivy__Exclude_Credits_Earned__c : null) != (ienNew != null ? ienNew.reduivy__Exclude_Credits_Earned__c : null);
        Boolean isExcludeGpaChanged = (ienOld != null ? ienOld.reduivy__Exclude_GPA_Calculation__c : null) != (ienNew != null ? ienNew.reduivy__Exclude_GPA_Calculation__c : null);
        Boolean isFinalNumericalChanged = (ienOld != null ? ienOld.reduivy__Final_Numerical_Grade__c : null) != (ienNew != null ? ienNew.reduivy__Final_Numerical_Grade__c : null);
        Boolean isStartDateChanged = (ienOld != null ? ienOld.reduivy__Start_Date__c : null) != (ienNew != null ? ienNew.reduivy__Start_Date__c : null);

        Boolean isRecordQualified = ((ienNew != null && ienNew.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID) || (ienNew == null && ienOld != null && ienOld.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID)) && (
            (isReleased && !wasReleased) ||
            (!isReleased && wasReleased) ||
            (
                isReleased && 
                (
                    isQualityPointsChanged ||
                    isCreditsEarnedChanged ||
                    isExcludeCreditsChanged ||
                    isExcludeGpaChanged ||
                    isFinalNumericalChanged ||
                    isStartDateChanged
                )
            )
        );

        return isRecordQualified;
    }
	
    /**
     * @description Identify the best attempt individual enrollment for the contact and set the Best Attempt flag
     * @param ienList List of individual enrollment
     * @return void
     */
    private void identifyBestAttempt(List<reduivy__Individual_Enrollment__c> ienList) {
        
        Map<String, List<reduivy__Individual_Enrollment__c>> ienListByipfSun = new Map<String, List<reduivy__Individual_Enrollment__c>>();

        Set<Id> contactIds = new Set<Id>();
        Set<Id> sunIds = new Set<Id>();
        Set<Id> ipfIds = new Set<Id>();

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Contact__c) && String.isNotBlank(ien.reduivy__Target_Unit_Id__c) && String.isNotBlank(ien.reduivy__Individual_Academic_Profile__c)) {
                String ipfSunKey = getIpfSunKey(ien);

                if (ienListByipfSun.containsKey(ipfSunKey)) {
                    ienListByipfSun.get(ipfSunKey).add(ien);
                } else {
                    ienListByipfSun.put(ipfSunKey, new List<reduivy__Individual_Enrollment__c>{ien});
                }

                contactIds.add(ien.reduivy__Contact__c);
                sunIds.add(ien.reduivy__Target_Unit_Id__c);
                ipfIds.add(ien.reduivy__Individual_Academic_Profile__c);
            }
        }

        if (!ienListByipfSun.isEmpty()) {

            Map<String, List<reduivy__Individual_Enrollment__c>> ienToValidateByipfSun = new Map<String, List<reduivy__Individual_Enrollment__c>>();
            Map<String, List<reduivy__Individual_Enrollment__c>> ienUpdateMapByipfSun = new Map<String, List<reduivy__Individual_Enrollment__c>>();

            for (reduivy__Individual_Enrollment__c ien : [
                SELECT reduivy__Contact__c, 
                reduivy__Target_Unit_Id__c,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Final_Numerical_Grade__c,
                reduivy__Credits_Earned__c,
                reduivy__Quality_Points__c,
                reduivy__Grade_Result__c,
                reduivy__Exclude_GPA_Calculation__c,
                reduivy__Exclude_Credits_Earned__c,
                reduivy__Best_Attempt__c,
                reduivy__Grade_Release_Status__c,
                reduivy__Start_Date__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c IN :contactIds
                AND reduivy__Target_Unit_Id__c IN :sunIds
                AND reduivy__Individual_Academic_Profile__c IN :ipfIds
                AND reduivy__Grade_Release_Status__c =: IEN_Helper.GRADE_RELEASE_STATUS_RELEASED
                WITH USER_MODE
                ORDER BY reduivy__Quality_Points__c DESC, reduivy__Start_Date__c DESC //ISS-002783 - Sort by final quality points in asc order so we can compare all the IENs when determining the best IEN
            ]) {

                String ipfSunKey = getIpfSunKey(ien);

                if (ienToValidateByipfSun.containsKey(ipfSunKey)) {
                    ienToValidateByipfSun.get(ipfSunKey).add(ien);
                } else {
                    ienToValidateByipfSun.put(ipfSunKey, new List<reduivy__Individual_Enrollment__c>{ien});
                }
            }

            for (String ipfSunKey : ienToValidateByipfSun.keySet()) {
                reduivy__Individual_Enrollment__c bestIen;

                for (reduivy__Individual_Enrollment__c ien : ienToValidateByipfSun.get(ipfSunKey)) {

                    if (IEN_Helper.isCurrentBetterAttempt(ien, bestIen)) {
                        bestIen = ien;
                    }
                }

                for (reduivy__Individual_Enrollment__c ien : ienToValidateByipfSun.get(ipfSunKey)) {
                    if (bestIen != null && ien.Id == bestIen.Id) {
                        // set the info for best attempt ien if it wasn't the best
                        if (!ien.reduivy__Best_Attempt__c) {
                            reduivy__Individual_Enrollment__c ienUpdate = new reduivy__Individual_Enrollment__c(
                                Id = ien.Id,
                                reduivy__Best_Attempt__c = true
                            );

                            if (ienUpdateMapByipfSun.containsKey(ipfSunKey)) {
                                ienUpdateMapByipfSun.get(ipfSunKey).add(ienUpdate);
                            } else {
                                ienUpdateMapByipfSun.put(ipfSunKey, new List<reduivy__Individual_Enrollment__c> {ienUpdate});
                            }
                        }
                    } else {
                        // set the info for non best attempt ien
                        reduivy__Individual_Enrollment__c ienUpdate = new reduivy__Individual_Enrollment__c(
                            Id = ien.Id
                        );

                        if (ien.reduivy__Best_Attempt__c) {
                            ienUpdate.reduivy__Best_Attempt__c = false;

                            if (ienUpdateMapByipfSun.containsKey(ipfSunKey)) {
                                ienUpdateMapByipfSun.get(ipfSunKey).add(ienUpdate);
                            } else {
                                ienUpdateMapByipfSun.put(ipfSunKey, new List<reduivy__Individual_Enrollment__c> {ienUpdate});
                            }
                        }
                    }
                }
            }

            if (!ienUpdateMapByipfSun.isEmpty()) {
                REDU_Database_UTIL.doUpdate(ienUpdateMapByipfSun, ienListByipfSun, false);
            }
        }
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