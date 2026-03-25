/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Individual enrollment: populate the waitlist date
 * @changehistory
 * ISS-001763 27-10-2023 dblack - new class
 */
public inherited sharing class IEN_WaitlistDate_EXE extends REDU_TriggerExecutable {
    
    private static final Id IEN_STUDENT_RTID =  IEN_Helper.getStudentRecordTypeId();

    private static final Boolean PRESERVE_WAITLIST_DATE = REDU_AppSetting_UTIL.isPreservePreEnrolmentWaitlistDate();
            
    private static final List<String> IEN_WAITLISTED_STATUSES = IEN_Helper.getWaitlistedStatuses();
    private static final List<String> IEN_ENROLLEMENTREQUESTED_STATUSES = IEN_Helper.getEnrollmentRequestedStatuses();
    private static final List<String> IEN_OPEN_STATUSES = IEN_Helper.getOpenStatuses();

	/**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult) {

        if ((operationType == TriggerOperation.BEFORE_INSERT) && 
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)
        ) {

            // Set the waitlist date whenever a student requests enrollment or is waitlisted
            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                
                if (ienNew.RecordTypeId == IEN_STUDENT_RTID) {
                    if (String.isBlank(ienNew.reduivy__Enrollment_Status__c) || IEN_OPEN_STATUSES.contains(ienNew.reduivy__Enrollment_Status__c)) {
                        ienNew.reduivy__Waitlist_Date__c = null;

                    } else if (needsWaitlistDate(null, ienNew)) {
                        ienNew.reduivy__Waitlist_Date__c = System.now();
                    }
                }
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
    public override void executeBeforeUpdate(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult) {

        if ((operationType == TriggerOperation.BEFORE_UPDATE) && 				 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            // Set the waitlist date whenever a student requests enrollment or is waitlisted
            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);

                if (ienNew.RecordTypeId == IEN_STUDENT_RTID &&
                    ienNew.reduivy__Enrollment_Status__c != ienOld.reduivy__Enrollment_Status__c
                ) {

                    if (String.isBlank(ienNew.reduivy__Enrollment_Status__c) || IEN_OPEN_STATUSES.contains(ienNew.reduivy__Enrollment_Status__c)) {
                        ienNew.reduivy__Waitlist_Date__c = null;
                        
                    } else if (needsWaitlistDate(ienOld, ienNew)) {
                        ienNew.reduivy__Waitlist_Date__c = System.now();
                    }
                }
            }
        }
    }

    private boolean needsWaitlistDate(reduivy__Individual_Enrollment__c oldIen, reduivy__Individual_Enrollment__c newIen) {

        Boolean isWaitlisted = (newIen != null) && (IEN_ENROLLEMENTREQUESTED_STATUSES.contains(newIen.reduivy__Enrollment_Status__c) || IEN_WAITLISTED_STATUSES.contains(newIen.reduivy__Enrollment_Status__c));
        
        Datetime newWaitlistDate = (newIen != null) ? newIen.reduivy__Waitlist_Date__c : null;

        Boolean needsNewDate = isWaitlisted && (newWaitlistDate == null || !PRESERVE_WAITLIST_DATE);

        return needsNewDate;
    }
}