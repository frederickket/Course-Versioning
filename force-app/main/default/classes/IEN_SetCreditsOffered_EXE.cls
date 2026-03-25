/**
 * @author      WDCi (dblack)
 * @date        Jan 2024
 * @group       Trigger executable
 * @description Individual Enrollment - automation to set credits offered upon enrollment
 * @changehistory
 * ISS-001837 09-01-2024 dblack - new class
 * ISS-002752 16-12-2025 XiRouh - Updated to check for Study Offering changes when updating
 */
public inherited sharing class IEN_SetCreditsOffered_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual enrollment student record type Id
     */
    private static final Id IEN_STUDENT_RECORDTYPE_ID = IEN_Helper.getStudentRecordTypeId();
    
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

            List<reduivy__Individual_Enrollment__c> workingList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) newList) {

                if ((ien.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID) && 
                    (String.isNotBlank(ien.reduivy__Study_Offering__c)) && 
                    (ien.reduivy__Credits_Offered__c == null)
                ) {
                    workingList.add(ien);
                }
            }

            if (!workingList.isEmpty()) {
                setCreditsOffered(workingList);
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

            List<reduivy__Individual_Enrollment__c> workingList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                if (ienNew.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID) {
                    reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);
                        
                    if ((String.isNotBlank(ienNew.reduivy__Study_Offering__c)) && 
                        ((ienNew.reduivy__Credits_Offered__c == null && ienNew.reduivy__Credits_Offered__c != ienOld.reduivy__Credits_Offered__c ) || (ienNew.reduivy__Credits_Offered__c == null && ienNew.reduivy__Study_Offering__c != ienOld.reduivy__Study_Offering__c))
                    ) {
                        workingList.add(ienNew);
                    }
                }
            }

            if (!workingList.isEmpty()) {
                setCreditsOffered(workingList);
            }
        }
    }

    /**
     * @description Set the credits offered on the individual enrollment record
     * @param ienList List<reduivy__Individual_Enrollment__c>
     */
    private static void setCreditsOffered(List<reduivy__Individual_Enrollment__c> ienList) {

        Set<Id> sofIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                sofIds.add(ien.reduivy__Study_Offering__c);
            }
        }

        if (!sofIds.isEmpty()) {

            Map<Id, reduivy__Study_Offering__c> sofMap = SOF_Helper.getStudyOfferings(sofIds, true);

            for (reduivy__Individual_Enrollment__c ien : ienList) {
                if (sofMap.containsKey(ien.reduivy__Study_Offering__c)) {
                    ien.reduivy__Credits_Offered__c = sofMap.get(ien.reduivy__Study_Offering__c).reduivy__Study_Unit__r.reduivy__Credits__c;
                }
            }
        }
    }
}