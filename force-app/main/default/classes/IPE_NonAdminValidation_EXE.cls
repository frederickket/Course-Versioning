/**
 * @author      WDCi (Lean)
 * @date        Oct 2024
 * @group       Individual Program Enrollment
 * @description This is a validation to prevent student from creating non-preview master IPE, deleting non-preview IPE or change the IPE enrollment status
 * @changehistory
 * ISS-002148 24-10-2024 Lean - New class
 */
public inherited sharing class IPE_NonAdminValidation_EXE extends REDU_TriggerExecutable {
    
    static final Id IPE_MASTER_RTID = IPE_Helper.getMasterEnrollmentRecordTypeId();
    static final List<String> IPE_PREVIEW_STATUSES = IPE_Helper.getPreviewStatuses();

	/**
     * @description Prevent student from creating non-preview master IPE
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)        
        ) {
            
            for (reduivy__Individual_Program_Enrollment__c newIpe : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                if (newIpe.RecordTypeId == IPE_MASTER_RTID && 
                    !IPE_PREVIEW_STATUSES.contains(newIpe.reduivy__Enrollment_Status__c)
                ) {
                    newIpe.addError(String.format(Label.Creation_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel()}));
                }
            }
        }
    }

    /**
     * @description Prevent student from changing master IPE enrollment status
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)        
        ) {
            
            Map<Id, reduivy__Individual_Program_Enrollment__c> oldIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>((List<reduivy__Individual_Program_Enrollment__c>)oldList);

            for (reduivy__Individual_Program_Enrollment__c newIpe : (List<reduivy__Individual_Program_Enrollment__c>) newList) {

                if (newIpe.RecordTypeId == IPE_MASTER_RTID && 
                    newIpe.reduivy__Enrollment_Status__c != oldIpeMap.get(newIpe.Id).reduivy__Enrollment_Status__c
                ) {
                    newIpe.addError(String.format(Label.Updation_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel(), newIpe.Name}));
                }
            }
        }
    }

    /**
     * @description Prevent student from deleting non-preview master/child IPE
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.GUEST)        
        ) {
            
            for (reduivy__Individual_Program_Enrollment__c oldIpe : (List<reduivy__Individual_Program_Enrollment__c>) oldList) {

                if (!IPE_PREVIEW_STATUSES.contains(oldIpe.reduivy__Enrollment_Status__c)) {
                    oldIpe.addError(String.format(Label.Deletion_Disallowed_Error, new List<String>{IPE_Helper.getObjectLabel(), oldIpe.Name}));
                }
            }
        }
    }
}