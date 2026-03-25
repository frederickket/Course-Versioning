/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Trigger executable
 * @description To populate the waitlist date when individual session enrollment status changed to 'Waitlisted'
 * @changehistory
 * ISS-002056 23-08-2024 Sueanne - new class
 */
public inherited sharing class ISN_WaitlistDate_EXE extends REDU_TriggerExecutable {
    
    private static final Id ISN_STUDENT_RTID =  ISN_Helper.getStudentRecordTypeId();

    private static final Boolean PRESERVE_WAITLIST_DATE = REDU_AppSetting_UTIL.isPreservePreEnrolmentWaitlistDate();
            
    private static final List<String> ISN_WAITLISTED_STATUSES = ISN_Helper.getWaitlistedStatuses();
    private static final List<String> ISN_ENROLLEMENTREQUESTED_STATUSES = ISN_Helper.getEnrollmentRequestedStatuses();
    private static final List<String> ISN_OPEN_STATUSES = ISN_Helper.getOpenStatuses();

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

            // Set the waitlist date whenever a student requests enrollment or is waitlisted
            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>();

            for (reduivy__Individual_Session_Enrollment__c isnNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {
                
                if (isnNew.RecordTypeId == ISN_STUDENT_RTID) {
                    if (String.isBlank(isnNew.reduivy__Enrollment_Status__c) || ISN_OPEN_STATUSES.contains(isnNew.reduivy__Enrollment_Status__c)) {
                        isnNew.reduivy__Waitlist_Date__c = null;

                    } else if (needsWaitlistDate(null, isnNew)) {
                        isnNew.reduivy__Waitlist_Date__c = System.now();
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
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            // Set the waitlist date whenever a student requests enrollment or is waitlisted
            List<reduivy__Individual_Session_Enrollment__c> ienList = new List<reduivy__Individual_Session_Enrollment__c>();

            for (reduivy__Individual_Session_Enrollment__c isnNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {
                reduivy__Individual_Session_Enrollment__c isnOld = (reduivy__Individual_Session_Enrollment__c) oldMap.get(isnNew.Id);

                if (isnNew.RecordTypeId == ISN_STUDENT_RTID && isnNew.reduivy__Enrollment_Status__c != isnOld.reduivy__Enrollment_Status__c) {

                    if (String.isBlank(isnNew.reduivy__Enrollment_Status__c) || ISN_OPEN_STATUSES.contains(isnNew.reduivy__Enrollment_Status__c)) {
                        isnNew.reduivy__Waitlist_Date__c = null;
                        
                    } else if (needsWaitlistDate(isnOld, isnNew)) {
                        isnNew.reduivy__Waitlist_Date__c = System.now();
                    }
                }
            }
        }
    }

    /**
     * @description To check if have updated from non waitlisted status to waitlisted status
     * @param oldIsn old individual session enrollment
     * @param newIsn new individual session enrollment
     */
    private boolean needsWaitlistDate(reduivy__Individual_Session_Enrollment__c oldIsn, reduivy__Individual_Session_Enrollment__c newIsn) {

        Boolean wasWaitlisted = (oldIsn != null) && (ISN_ENROLLEMENTREQUESTED_STATUSES.contains(oldIsn.reduivy__Enrollment_Status__c) || ISN_WAITLISTED_STATUSES.contains(oldIsn.reduivy__Enrollment_Status__c));
        Boolean isWaitlisted = (newIsn != null) && (ISN_ENROLLEMENTREQUESTED_STATUSES.contains(newIsn.reduivy__Enrollment_Status__c) || ISN_WAITLISTED_STATUSES.contains(newIsn.reduivy__Enrollment_Status__c));
        
        Datetime newWaitlistDate = (newIsn != null) ? newIsn.reduivy__Waitlist_Date__c : null;

        Boolean needsNewDate = isWaitlisted && (newWaitlistDate == null || !PRESERVE_WAITLIST_DATE);

        return needsNewDate;
    }
}