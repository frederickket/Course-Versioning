/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description Completion engine for individual enrollment to set the credits earned
 * @changehistory
 * ISS-001822 12-01-2024 Lean - new class
 * ISS-002486 10-10-2025 XiRouh - Updated from checking whether the grade result is a positive grade result to checking whether the enrollment status is a completed pass status
 */
public inherited sharing class IEN_SetCreditsEarned_EXE extends REDU_TriggerExecutable {
    
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
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)
        ) {

            List<reduivy__Individual_Enrollment__c> workingList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {

                if (isNewlyReleasedOrReleaseInfoChanges(ienNew, null)) {
                    workingList.add(ienNew);
                }
            }

            setCreditsEarned(workingList);
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

            setCreditsEarned(workingList);
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
        
        //ISS-002486
        Boolean isEnrollmentStatusChanged = (ienOld != null ? IEN_ENROLLMENT_COMPLETED_PASS_STATUSES.contains(ienOld.reduivy__Enrollment_Status__c) : null) != (ienNew != null ? IEN_ENROLLMENT_COMPLETED_PASS_STATUSES.contains(ienNew.reduivy__Enrollment_Status__c) : null);

        return ienNew.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID && (
            (isReleased && !wasReleased) ||
            (!isReleased && wasReleased) ||
            (
                isReleased && 
                (
                    isEnrollmentStatusChanged
                )
            )
        );
    }

    /**
     * @description Set the credits earned for individual enrollment for pass/bypass with credits attempted or 0 for fail
     * @param ienList List of individual enrollment
     * @return void
     */
    private void setCreditsEarned(List<reduivy__Individual_Enrollment__c> ienList) {
        
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            
            if (IEN_GRADE_RELEASED_STATUSES.contains(ien.reduivy__Grade_Release_Status__c)) {

                if (IEN_ENROLLMENT_COMPLETED_PASS_STATUSES.contains(ien.reduivy__Enrollment_Status__c)) {
                    ien.reduivy__Credits_Earned__c = ien.reduivy__Credits_Attempted__c;
                } else {
                    ien.reduivy__Credits_Earned__c = 0;
                }

            } else {
                ien.reduivy__Credits_Earned__c = null;
            }
        }
    }
}