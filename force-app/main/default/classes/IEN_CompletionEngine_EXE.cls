/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Trigger Executable
 * @description Completion engine for individual enrollment
 * @changehistory
 * ISS-001822 11-01-2024 Lean - new class
 * ISS-001942 14-05-2024 Sueanne - fixed release grade issue
 * ISS-001950 24-05-2024 VTan - Unset grade point and result when IEN is unreleased
 * ISS-002055 29-08-2024 VTan - Consider attendance percentage during grade release
 * ISS-002405 23-04-2025 XW - Consider if Grade Result updated from non-released to released
 * ISS-002486 10-06-2025 XiRouh - Updated to determine which enrollment status should be assigned to the IEN based on the grade result—'Pass', 'Fail', or Bypass statuses, and match it to the custom metadata
 * ISS-002485 11-06-2025 XiRouh - Updated isNewlyReleasedOrReleaseInfoChanges() logic, updated processCompletion() logic to update reduivy__Enrollment_Status__c if a status change is needed
 * ISS-002513 02-03-2026 XiRouh - Added ienNew.reduivy__Skip_Completion_Engine__c == false to the fire condition
 */
public inherited sharing class IEN_CompletionEngine_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description Individual enrollment student record type Id
     */
    private static final Id IEN_STUDENT_RECORDTYPE_ID = IEN_Helper.getStudentRecordTypeId();

    /**
     * @description Individual enrollment - grade released statuses
     */
    private static final List<String> IEN_GRADE_RELEASED_STATUSES = IEN_Helper.getGradeReleasedStatuses();

    /**
     * @description Individual enrollment - final grade released statuses (to update the Enrollment status to completed)
     */
    private static final List<String> IEN_FINAL_GRADE_RELEASED_STATUSES = IEN_Helper.getFinalGradeReleasedStatuses();

    /**
     * @description Individual enrollment - completed pass statuses
     */
    private static final List<String> IEN_ENROLLMENT_COMPLETED_PASS_STATUSES = IEN_Helper.getCompletedPassStatuses();

    /**
     * @description Individual enrollment - completed fail statuses
     */
    private static final List<String> IEN_ENROLLMENT_COMPLETED_FAIL_STATUSES = IEN_Helper.getCompletedFailStatuses();

    /**
     * @description Individual enrollment - completed statuses
     */
    private static final List<String> IEN_ENROLLMENT_COMPLETED_STATUSES = IEN_Helper.getCompletedStatuses();

    /**
     * @description Individual enrollment - in progress statuses
     */
    private static final List<String> IEN_ENROLLMENT_INPROGRESS_STATUSES = IEN_Helper.getInProgressStatuses();

    /**
     * @description Grade by pass statuses
     */
    private static final List<String> IEN_GRADE_RESULT_BYPASS_STATUSES = IEN_Helper.getGradeResultBypassStatuses();

    /**
     * @description Grade pass statuses
     */
    private static final List<String> IEN_GRADE_RESULT_PASS_STATUSES = IEN_Helper.getGradeResultPassStatuses();

    /**
     * @description Grade fail statuses
     */
    private static final List<String> IEN_GRADE_RESULT_FAIL_STATUSES = IEN_Helper.getGradeResultFailStatuses();

    /**
     * @description IEN statuses that are considered active and should have their status updated if applicable
     */
    static final Set<String> IEN_ACTIVE_STATUSES = new Set<String>();
    static {
        IEN_ACTIVE_STATUSES.addAll(IEN_Helper.getCompletedStatuses());
        IEN_ACTIVE_STATUSES.addAll(IEN_Helper.getInProgressStatuses());
        IEN_ACTIVE_STATUSES.addAll(IEN_Helper.getWithdrawalRequestedStatuses());
    }

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

            if (!workingList.isEmpty()) {
                processCompletion(workingList, null);
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

            if (!workingList.isEmpty()) {
                processCompletion(workingList, (List<reduivy__Individual_Enrollment__c>) oldList);
            }
        }
    }

    /**
     * @description Determine if the individual enrollment is valid for completion engine processing
     * @param ienNew New individual enrollment
     * @param ienOld Old individual enrollment
     * @return Boolean
     */
    private Boolean isNewlyReleasedOrReleaseInfoChanges(reduivy__Individual_Enrollment__c ienNew, reduivy__Individual_Enrollment__c ienOld) {
    
        //Check if the old record was in any released status (Internal Release, Internal Audit, Released)
        Boolean wasReleased = (ienOld != null && IEN_GRADE_RELEASED_STATUSES.contains(ienOld.reduivy__Grade_Release_Status__c));
        
        //Check if the new record is in any released status (Internal Release, Internal Audit, Released)
        Boolean isReleased = (ienNew != null && IEN_GRADE_RELEASED_STATUSES.contains(ienNew.reduivy__Grade_Release_Status__c));

        //ISS-002485 - Detect transitions between any released statuses, for example if the internal release is somehow set to "Completed", we need to revert it back to "Enrolled" when it changes to "Internal Audit"
        //(e.g., Internal Release ↔ Internal Audit, Internal Release/Audit → Release, Release → Internal Release/Audit)
        Boolean isReleasedStatusChanged = isReleased && wasReleased && 
                                        (ienOld.reduivy__Grade_Release_Status__c != ienNew.reduivy__Grade_Release_Status__c);
        
        //Check for changes in grade-related fields
        Boolean isLetterGradeChanged = (ienOld != null ? ienOld.reduivy__Letter_Grade__c : null) != (ienNew != null ? ienNew.reduivy__Letter_Grade__c : null); 
        Boolean isNumericalGradeChanged = (ienOld != null ? ienOld.reduivy__Final_Numerical_Grade__c : null) != (ienNew != null ? ienNew.reduivy__Final_Numerical_Grade__c : null);
        Boolean isAttendanceRequirementMetChanged = (ienOld != null ? ienOld.reduivy__Attendance_Requirement_Met__c : null) != (ienNew != null ? ienNew.reduivy__Attendance_Requirement_Met__c : null);

        return ienNew.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID && ienNew.reduivy__Skip_Completion_Engine__c == false && (
            (isReleased && !wasReleased) || //1. Changed from non-released to any released status
            (!isReleased && wasReleased) || //2. Changed from any released status to non-released
            (isReleasedStatusChanged) || //3. Changed between any released statuses 
            ( //4. Grade information updated while in released status
                isReleased && 
                (
                    isLetterGradeChanged ||
                    isNumericalGradeChanged ||
                    isAttendanceRequirementMetChanged
                )
            )
        );
    }
	
    /**
     * @description Process the completion for individual enrollment
     * @param ienList List of individual enrollment
     * @return void
     */
    private void processCompletion(List<reduivy__Individual_Enrollment__c> ienList, List<reduivy__Individual_Enrollment__c> oldIenList) {

        String ienSgsFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Study_Grade_Setting__c.getLabel();
        String ienLetterGradeFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Letter_Grade__c.getLabel();
        String ienNumericalGradeFieldLabel = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Final_Numerical_Grade__c.getLabel();

        Map<Id, reduivy__Individual_Enrollment__c> oldIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        if (oldIenList != null) {
            oldIenMap = new Map<Id, reduivy__Individual_Enrollment__c>(oldIenList);
        }

        List<reduivy__Individual_Enrollment__c> qualifiedIenList = new List<reduivy__Individual_Enrollment__c>();
        Set<Id> sgsIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            // Ensure that we have study grade setting and either letter grade or numerical grade
            if (String.isBlank(ien.reduivy__Study_Grade_Setting__c) || (String.isBlank(ien.reduivy__Letter_Grade__c) && ien.reduivy__Final_Numerical_Grade__c == null)) {
                ien.addError(String.format(Label.Missing_Fields_For_Grade_Release, new List<String>{ienSgsFieldLabel, ienNumericalGradeFieldLabel, ienLetterGradeFieldLabel}));
                continue;
            }

            // compile list of qualified ien
            qualifiedIenList.add(ien);
            sgsIds.add(ien.reduivy__Study_Grade_Setting__c);
        }

        // get the study grading scheme
        Map<Id, List<reduivy__Study_Grading_Scheme__c>> sgdBySgsMap = SGD_Helper.getStudyGradingSchemes(sgsIds, true);

        // prepare the list of letter grade grading scheme with bypass grade result to support admin releasing result for ien with bypass grade result
        Set<String> sgdLetterGradeWithBypassGradeResults = new Set<String>();
        for (List<reduivy__Study_Grading_Scheme__c> sgdList : sgdBySgsMap.values()) {
            for (reduivy__Study_Grading_Scheme__c sgd : sgdList) {
                if (String.isNotBlank(sgd.reduivy__Grade_Result__c) && IEN_GRADE_RESULT_BYPASS_STATUSES.contains(sgd.reduivy__Grade_Result__c)) {
                    sgdLetterGradeWithBypassGradeResults.add(sgd.reduivy__Study_Grade_Setting__c + '_' + sgd.reduivy__Letter_Grade__c);
                }
            }
        }

        for (reduivy__Individual_Enrollment__c ien : qualifiedIenList) {

            //ISS-001950 unset grade point and result if unreleased
            if(IEN_GRADE_RELEASED_STATUSES.contains(ien.reduivy__Grade_Release_Status__c)){

                // Ensure that the study grade setting that we will be using is valid and has grading scheme defined
                if (!sgdBySgsMap.containsKey(ien.reduivy__Study_Grade_Setting__c)) {
                    String recordUrl = REDU_OrganizationInfo_UTIL.getDomainUrl() + ien.reduivy__Study_Grade_Setting__c;
                    ien.addError(String.format(Label.Missing_Grading_Scheme_For_Grade_Release, new List<String>{SGD_Helper.getObjectLabel(), SGS_Helper.getObjectLabel(), recordUrl}));
                    continue;
                }

                // get the old record for comparison
                reduivy__Individual_Enrollment__c ienOld;

                if (String.isNotBlank(ien.Id) && oldIenMap.containsKey(ien.Id)) {
                    ienOld = oldIenMap.get(ien.Id);
                }

                Boolean matchByBypassLetterGrade = String.isNotBlank(ien.reduivy__Letter_Grade__c) && sgdLetterGradeWithBypassGradeResults.contains(ien.reduivy__Study_Grade_Setting__c + '_' + ien.reduivy__Letter_Grade__c);
                Boolean matchByNumericalGrade = ien.reduivy__Final_Numerical_Grade__c != null && (ienOld != null ? ienOld.reduivy__Final_Numerical_Grade__c : null) != (ien != null ? ien.reduivy__Final_Numerical_Grade__c : null);
                Boolean matchByLetterGrade = String.isNotBlank(ien.reduivy__Letter_Grade__c) && (ienOld != null ? ienOld.reduivy__Letter_Grade__c : null) != (ien != null ? ien.reduivy__Letter_Grade__c : null);
                
                Decimal numericalGrade = ien.reduivy__Final_Numerical_Grade__c;
                String letterGrade = ien.reduivy__Letter_Grade__c;

                if (!matchByBypassLetterGrade && !matchByNumericalGrade && !matchByLetterGrade) {
                    if (ien.reduivy__Final_Numerical_Grade__c != null) {
                        matchByNumericalGrade = true;
                    } else if (String.isNotBlank(ien.reduivy__Letter_Grade__c)) {
                        matchByLetterGrade = true;
                    }
                }

                // Matching sequence priority
                if (matchByBypassLetterGrade) {
                    // match by letter grade if the grade result for the current letter grade = bypass type
                    numericalGrade = null;
                } else if (matchByNumericalGrade) {
                    // match by numerical grade if the numerical grade is changed
                    letterGrade = null;
                } else if (matchByLetterGrade) {
                    // match by letter grade if the letter grade is changed
                    numericalGrade = null;
                }

                Map<String, Object> gradingSchemeInfo = SGD_Helper.matchGradingScheme(numericalGrade, letterGrade, sgdBySgsMap.get(ien.reduivy__Study_Grade_Setting__c), ien.reduivy__Attendance_Requirement_Met__c);

                if (gradingSchemeInfo == null) {
                    ien.addError(String.format(Label.Matching_Grading_Scheme_Failed_For_Grade_Release, new List<String>{SGD_Helper.getObjectLabel(), ienNumericalGradeFieldLabel, ienLetterGradeFieldLabel}));
                    continue;
                }

                // based on the grading scheme matched, we will set the fields on individual enrollment
                // we will only set the field if it is not null to avoid the completion engine to overwrite the existing value to cater for more flexibility
                if (matchByNumericalGrade) {
                    if (String.isNotBlank((String) gradingSchemeInfo.get('reduivy__Letter_Grade__c'))) {
                        ien.reduivy__Letter_Grade__c = (String) gradingSchemeInfo.get('reduivy__Letter_Grade__c');
                    }
                } else {
                    if (gradingSchemeInfo.get('reduivy__Numerical_Grade__c') != null) {
                        ien.reduivy__Numerical_Grade__c = (Decimal) gradingSchemeInfo.get('reduivy__Numerical_Grade__c');
                    }
                }

                if (gradingSchemeInfo.get('reduivy__Grade_Points__c') != null) {
                    ien.reduivy__Grade_Points__c = (Decimal) gradingSchemeInfo.get('reduivy__Grade_Points__c');
                }

                String gradeResult = '';

                if (String.isNotBlank((String) gradingSchemeInfo.get('reduivy__Grade_Result__c'))) {
                    ien.reduivy__Grade_Result__c = (String) gradingSchemeInfo.get('reduivy__Grade_Result__c');

                    gradeResult = (String) gradingSchemeInfo.get('reduivy__Grade_Result__c');
                }

                if (String.isNotBlank((String) gradingSchemeInfo.get('reduivy__Exclude_Credits_Earned__c'))) {
                    ien.reduivy__Exclude_Credits_Earned__c = String.valueOf(gradingSchemeInfo.get('reduivy__Exclude_Credits_Earned__c')).endsWithIgnoreCase(SGD_Helper.EXCLUDE_CREDITSEARNED_YES) ? true : false;
                }

                if (String.isNotBlank((String) gradingSchemeInfo.get('reduivy__Exclude_GPA_Calculation__c'))) {
                    ien.reduivy__Exclude_GPA_Calculation__c = String.valueOf(gradingSchemeInfo.get('reduivy__Exclude_GPA_Calculation__c')).endsWithIgnoreCase(SGD_Helper.EXCLUDE_GPA_YES) ? true : false;
                }

                //ISS-002485 - Changed from checking IEN_ENROLLMENT_INPROGRESS_STATUSES to IEN_ACTIVE_STATUSES 
                //because there may be scenarios where the IEN has a status of 'Completed' or 'Completed - Fail', but the grade has changed from pass to fail or vice versa, and we have to consider 'Withdrawal Requested' too 
                if (IEN_ACTIVE_STATUSES.contains(ien.reduivy__Enrollment_Status__c)) {
                    //If the IEN is active (the student is still considered to be in the course), and the grade release status is 'Final Release', the status will be set based on the grading scheme setting or as either 'Completed - Pass' or 'Completed - Fail' based on the grade result
                    if(IEN_FINAL_GRADE_RELEASED_STATUSES.contains(ien.reduivy__Grade_Release_Status__c)) {
                        String completionStatus = (String) gradingSchemeInfo.get('reduivy__Enrollment_Status__c') ?? '';

                        //ISS-002486 - Only assign a new enrollment status if one doesn't already set in the grading scheme and a gradeResult is present
                        if (String.isBlank(completionStatus) && String.isNotBlank(gradeResult)) {
                            if (IEN_GRADE_RESULT_PASS_STATUSES.contains(gradeResult) || IEN_GRADE_RESULT_BYPASS_STATUSES.contains(gradeResult)) {
                                completionStatus = IEN_ENROLLMENT_COMPLETED_PASS_STATUSES.get(0);
                            } else if (IEN_GRADE_RESULT_FAIL_STATUSES.contains(gradeResult)) {
                                completionStatus = IEN_ENROLLMENT_COMPLETED_FAIL_STATUSES.get(0);
                            }
                        }

                        //ISS-002486 - Update the enrollment status if a status has been determined; otherwise, leave it unchanged since we are unsure which status to assign.
                        if (String.isNotBlank(completionStatus)) {
                            ien.reduivy__Enrollment_Status__c = completionStatus;
                        }
                    } else { //ISS-002485
                        //If the IEN is active (the student is still considered to be in the course) and the grade release status is 'Internal Release/Audit', set the status to 'In Progress' to cover scenarios where a grade has been released and marked as completed, but later reverted to an internal release/audit
                        if (IEN_ENROLLMENT_COMPLETED_STATUSES.contains(ien.reduivy__Enrollment_Status__c)) {
                            ien.reduivy__Enrollment_Status__c = IEN_ENROLLMENT_INPROGRESS_STATUSES.get(0);
                        }
                    }   
                }

            } else {
                //ISS-002485 - If the IEN is not in any of the release statuses but is in a completed status, revert it back to 'In Progress' status
                if (IEN_ENROLLMENT_COMPLETED_STATUSES.contains(ien.reduivy__Enrollment_Status__c)) {
                    ien.reduivy__Enrollment_Status__c = IEN_ENROLLMENT_INPROGRESS_STATUSES.get(0);
                }
                
                ien.reduivy__Grade_Points__c = null;
                ien.reduivy__Grade_Result__c = null;
            }
        }
    }    

}