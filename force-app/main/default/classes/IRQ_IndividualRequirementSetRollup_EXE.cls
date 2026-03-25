/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Requirement
 * @description Rollup Total Requirement, reviewed and submitted to Individual Requirement
 * @changehistory
 * ISS-002128 06-05-2025 XW - new class
 * ISS-002665 11-11-2025 XiRouh - Added SUBMITTED_STATUSES and SUBMISSION_STATUS_TYPE_MAP
 * ISS-002675 14-01-2026 XiRouh - Added new fields to store the rollup results in the corresponding visibility-specific fields
 */

public without sharing class IRQ_IndividualRequirementSetRollup_EXE extends REDU_TriggerExecutable {

    static List<String> REVIEWED_STATUSES = IRQ_Helper.getReviewedStatuses();
    static List<String> SUBMITTED_STATUSES = IRQ_Helper.getSubmissionSubmittedStatuses();

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

            Map<Id, reduivy__Individual_Requirement__c> workingMap = new Map<Id, reduivy__Individual_Requirement__c>();
            for (reduivy__Individual_Requirement__c irqNew : (List<reduivy__Individual_Requirement__c>) newList) {
                if(String.isNotBlank(irqNew.reduivy__Individual_Requirement_Set__c) && irqNew.reduivy__Status__c == IRQ_Helper.STATUS_ACTIVE) {
                    workingMap.put(irqNew.Id, irqNew);
                }
            }

            if(!workingMap.isEmpty()) {
                rollupIrs(workingMap, null);
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

            Map<Id, reduivy__Individual_Requirement__c> workingMap = new Map<Id, reduivy__Individual_Requirement__c>();
            Map<Id, reduivy__Individual_Requirement__c> oldWorkingMap = new Map<Id, reduivy__Individual_Requirement__c>();
            
            for (reduivy__Individual_Requirement__c irqNew : (List<reduivy__Individual_Requirement__c>) newList) {
                reduivy__Individual_Requirement__c irqOld = (reduivy__Individual_Requirement__c) oldMap.get(irqNew.Id);

                if (
                    reviewStatusUpdated(irqOld, irqNew) ||
                    submissionStatusUpdated(irqOld, irqNew) ||
                    irqNew.reduivy__Individual_Requirement_Set__c != irqOld.reduivy__Individual_Requirement_Set__c  ||
                    (
                        irqNew.reduivy__Status__c != irqOld.reduivy__Status__c &&
                        (
                            irqNew.reduivy__Status__c == IRQ_Helper.STATUS_ACTIVE ||
                            irqOld.reduivy__Status__c == IRQ_Helper.STATUS_ACTIVE
                        )
                    ) || 
                    irqNew.reduivy__Requirement_Visibility__c != irqOld.reduivy__Requirement_Visibility__c
                ) {
                    if(String.isNotBlank(irqNew.reduivy__Individual_Requirement_Set__c)) {
                        workingMap.put(irqNew.Id, irqNew);
                    }
                    if(irqNew.reduivy__Individual_Requirement_Set__c != irqOld.reduivy__Individual_Requirement_Set__c && String.isNotBlank(irqOld.reduivy__Individual_Requirement_Set__c)) {
                        oldWorkingMap.put(irqOld.Id, irqOld);
                    }
                }
            }

            if(!workingMap.isEmpty()) {
                rollupIrs(workingMap, oldWorkingMap.isEmpty() ? null : oldWorkingMap);
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

            Map<Id, reduivy__Individual_Requirement__c> workingMap = new Map<Id, reduivy__Individual_Requirement__c>();
            for (reduivy__Individual_Requirement__c irqOld : (List<reduivy__Individual_Requirement__c>) oldList) {
                if(String.isNotBlank(irqOld.reduivy__Individual_Requirement_Set__c) && irqOld.reduivy__Status__c == IRQ_Helper.STATUS_ACTIVE) {
                    workingMap.put(irqOld.Id, irqOld);
                }

            }

            if(!workingMap.isEmpty()) {
                rollupIrs(workingMap, null);
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

            Map<Id, reduivy__Individual_Requirement__c> workingMap = new Map<Id, reduivy__Individual_Requirement__c>();
            for (reduivy__Individual_Requirement__c irqNew : (List<reduivy__Individual_Requirement__c>) newList) {
                if(String.isNotBlank(irqNew.reduivy__Individual_Requirement_Set__c) && irqNew.reduivy__Status__c == IRQ_Helper.STATUS_ACTIVE) {
                    workingMap.put(irqNew.Id, irqNew);
                }
            }

            if(!workingMap.isEmpty()) {
                rollupIrs(workingMap, null);
            }
        }
    }
	
    /**
     * @description do rollup to individual requirement sets
     * @param irqMap the affected individual requirement map
     * @param oldIrqMap the old affected individual requirement map (for moved records)
     * @return void
     */
    private void rollupIrs(Map<Id, reduivy__Individual_Requirement__c> irqMap, Map<Id, reduivy__Individual_Requirement__c> oldIrqMap) {
        Map<Id, List<reduivy__Individual_Requirement__c>> irsIdToIrqMap = new Map<Id, List<reduivy__Individual_Requirement__c>>();
        List<reduivy__Individual_Requirement_Set__c> irsToUpdateList = new List<reduivy__Individual_Requirement_Set__c>();
        
        // Map new records to their IRS
        for(reduivy__Individual_Requirement__c irq : irqMap.values()) {
            if(!irsIdToIrqMap.containsKey(irq.reduivy__Individual_Requirement_Set__c)) {
                irsIdToIrqMap.put(irq.reduivy__Individual_Requirement_Set__c, new List<reduivy__Individual_Requirement__c>());
            }
            irsIdToIrqMap.get(irq.reduivy__Individual_Requirement_Set__c).add(irq);
        }

        // Map old records to their previous IRS (for moved records)
        if(oldIrqMap != null) {
            for(reduivy__Individual_Requirement__c irqOld : oldIrqMap.values()) {
                if(!irsIdToIrqMap.containsKey(irqOld.reduivy__Individual_Requirement_Set__c)) {
                    irsIdToIrqMap.put(irqOld.reduivy__Individual_Requirement_Set__c, new List<reduivy__Individual_Requirement__c>());
                }
                irsIdToIrqMap.get(irqOld.reduivy__Individual_Requirement_Set__c).add(irqMap.get(irqOld.Id));
            }
        }

        Set<String> irsFields = new Set<String> {
            'Id',
            'reduivy__Total_Requirement__c',
            'reduivy__Total_Reviewed__c',
            'reduivy__Total_Submitted__c',
            'reduivy__Total_Requirement_Faculty__c',
            'reduivy__Total_Reviewed_Faculty__c',
            'reduivy__Total_Submitted_Faculty__c',
            'reduivy__Total_Requirement_Student__c',
            'reduivy__Total_Reviewed_Student__c',
            'reduivy__Total_Submitted_Student__c'
        };

        Set<String> irqFields = new Set<String> {
            'Id',
            'reduivy__Review_Status__c',
            'reduivy__Submission_Status__c',
            'reduivy__Requirement_Visibility__c'
        };

        String irsQuery = 'SELECT ' + String.join(irsFields, ', ') + ', (' +
                         ' SELECT ' + String.join(irqFields, ', ') + 
                         ' FROM reduivy__Individual_Requirements__r' +
                         ' WHERE reduivy__Status__c = :statusActive )' +
                         ' FROM ' + IRS_Helper.getApiName() + 
                         ' WHERE Id IN :irsId' + 
                         ' FOR UPDATE';

        Map<String, Object> bindMap = new Map<String, Object> {
            'irsId' => irsIdToIrqMap.keySet(),
            'statusActive' => IRQ_Helper.STATUS_ACTIVE
        };

        Map<String, Set<String>> objectFieldsForFls = new Map<String, Set<String>>{
            IRS_Helper.getApiName() => irsFields,
            IRQ_Helper.getApiName() => irqFields
        };

        for(reduivy__Individual_Requirement_Set__c irs : (List<reduivy__Individual_Requirement_Set__c>) REDU_SystemMode_UTIL.doQuery(irsQuery, bindMap, objectFieldsForFls)) {

            Integer requirementAdmin = 0;
            Integer reviewedAdmin = 0;
            Integer submittedAdmin = 0;
            
            Integer requirementFaculty = 0;
            Integer reviewedFaculty = 0;
            Integer submittedFaculty = 0;
            
            Integer requirementStudent = 0;
            Integer reviewedStudent = 0;
            Integer submittedStudent = 0;

            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                String reviewStatus = irq.reduivy__Review_Status__c;
                String submissionStatus = irq.reduivy__Submission_Status__c;
                String visibility = irq.reduivy__Requirement_Visibility__c;

                Boolean isReviewed = REVIEWED_STATUSES.contains(reviewStatus);
                Boolean isSubmitted = SUBMITTED_STATUSES.contains(submissionStatus);

                requirementAdmin++;

                if (isReviewed) reviewedAdmin++;
                if (isSubmitted) submittedAdmin++;

                Boolean isFacultyVisible = visibility == IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY || visibility == IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;

                if (isFacultyVisible) {
                    requirementFaculty++;

                    if (isReviewed) reviewedFaculty++;
                    if (isSubmitted) submittedFaculty++;
                }

                Boolean isStudentVisible = visibility == IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;

                if (isStudentVisible) {
                    requirementStudent++;

                    if (isReviewed) reviewedStudent++;
                    if (isSubmitted) submittedStudent++;
                }
            }

            if(
                irs.reduivy__Total_Requirement__c != requirementAdmin ||
                irs.reduivy__Total_Reviewed__c != reviewedAdmin ||
                irs.reduivy__Total_Submitted__c != submittedAdmin ||
                irs.reduivy__Total_Requirement_Faculty__c != requirementFaculty ||
                irs.reduivy__Total_Reviewed_Faculty__c != reviewedFaculty ||
                irs.reduivy__Total_Submitted_Faculty__c != submittedFaculty ||
                irs.reduivy__Total_Requirement_Student__c != requirementStudent ||
                irs.reduivy__Total_Reviewed_Student__c != reviewedStudent ||
                irs.reduivy__Total_Submitted_Student__c != submittedStudent
            ) {
                reduivy__Individual_Requirement_Set__c irsToUpdate = new reduivy__Individual_Requirement_Set__c(Id = irs.Id);

                // Admin fields
                irsToUpdate.reduivy__Total_Requirement__c = requirementAdmin;
                irsToUpdate.reduivy__Total_Reviewed__c = reviewedAdmin;
                irsToUpdate.reduivy__Total_Submitted__c = submittedAdmin;
                
                // Faculty fields
                irsToUpdate.reduivy__Total_Requirement_Faculty__c = requirementFaculty;
                irsToUpdate.reduivy__Total_Reviewed_Faculty__c = reviewedFaculty;
                irsToUpdate.reduivy__Total_Submitted_Faculty__c = submittedFaculty;
                
                // Student fields
                irsToUpdate.reduivy__Total_Requirement_Student__c = requirementStudent;
                irsToUpdate.reduivy__Total_Reviewed_Student__c = reviewedStudent;
                irsToUpdate.reduivy__Total_Submitted_Student__c = submittedStudent;

                irsToUpdateList.add(irsToUpdate);
            }
        }

        if(!irsToUpdateList.isEmpty()) {
            REDU_SystemMode_UTIL.doUpdate(irsToUpdateList, irsIdToIrqMap, 'Id', false);
        }
    }

    /**
     * @description return true if the review status type is updated 
     * @param  irqOld irq old
     * @param  irqNew irq new
     * @return        return description
     */
    private Boolean reviewStatusUpdated(reduivy__Individual_Requirement__c irqOld, reduivy__Individual_Requirement__c irqNew){
        Boolean reviewStatusUpdated = irqOld.reduivy__Review_Status__c != irqNew.reduivy__Review_Status__c;
        Boolean reviewStatusTypeUpdated = 
                    (
                        REVIEWED_STATUSES.contains(irqOld.reduivy__Review_Status__c) && !REVIEWED_STATUSES.contains(irqNew.reduivy__Review_Status__c)
                    ) || 
                    (
                        !REVIEWED_STATUSES.contains(irqOld.reduivy__Review_Status__c) && REVIEWED_STATUSES.contains(irqNew.reduivy__Review_Status__c)
                    );
        Boolean result = reviewStatusUpdated && reviewStatusTypeUpdated;

        return result;
    }

    /**
     * @description return true if the submission status type is updated 
     * @param  irqOld irq old
     * @param  irqNew irq new
     * @return        true if submission status type changed
     */
    private Boolean submissionStatusUpdated(reduivy__Individual_Requirement__c irqOld, reduivy__Individual_Requirement__c irqNew){
        Boolean submissionStatusUpdated = irqOld.reduivy__Submission_Status__c != irqNew.reduivy__Submission_Status__c;
        Boolean submissionStatusTypeUpdated = 
                    (
                        SUBMITTED_STATUSES.contains(irqOld.reduivy__Submission_Status__c) && !SUBMITTED_STATUSES.contains(irqNew.reduivy__Submission_Status__c)
                    ) || 
                    (
                        !SUBMITTED_STATUSES.contains(irqOld.reduivy__Submission_Status__c) && SUBMITTED_STATUSES.contains(irqNew.reduivy__Submission_Status__c)
                    );
        Boolean result = submissionStatusUpdated && submissionStatusTypeUpdated;

        return result;
    }
}