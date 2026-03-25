/**
 * @author      WDCi (dblack)
 * @date        Nov 2023
 * @group       Trigger executable
 * @description Individual Enrollment: Populate the EFTSL value
 * @changehistory
 * ISS-001765 03-11-2023 dblack - new class
 * ISS-001837 10-01-2024 dblack - updated so that the EFTSL logic is consistent with the credits offered logic
 * ISS-002752 16-12-2025 XiRouh - Updated to check for Study Offering changes when updating
 */
public inherited sharing class IEN_PopulateEftsl_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description Individual enrollment student record type Id
     */
    private static final Id IEN_STUDENT_RECORDTYPE_ID = IEN_Helper.getStudentRecordTypeId();

    /**
     * @description Individual enrollment type
     */
    private static final String IEN_ENROLLMENTTYPE_PROGRAM = IEN_Helper.ENROLLMENT_TYPE_PROGRAM;

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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Enrollment__c> workingList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) newList) {

                if (ien.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID && 
                    ien.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM &&
                    String.isNotBlank(ien.reduivy__Study_Offering__c) && 
                    ien.reduivy__EFTSL__c == null
                ) {
                    workingList.add(ien);
                }
            }

            if (!workingList.isEmpty()) {
                setEftsl(workingList);
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Enrollment__c> workingList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                if (ienNew.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID &&
                    ienNew.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM
                ) {
                    reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);

                    if ((String.isNotBlank(ienNew.reduivy__Study_Offering__c)) && 
                        ((ienNew.reduivy__EFTSL__c == null && ienNew.reduivy__EFTSL__c != ienOld.reduivy__EFTSL__c) || (ienNew.reduivy__EFTSL__c == null && ienNew.reduivy__Study_Offering__c != ienOld.reduivy__Study_Offering__c))
                    ) {
                        workingList.add(ienNew);
                    }
                }
            }

            if (!workingList.isEmpty()) {
                setEftsl(workingList);
            }
        }
    }

    /**
     * @description Set the EFTSL on the individual enrollment record
     * @param ienList List<reduivy__Individual_Enrollment__c>
     */
    private static void setEftsl(List<reduivy__Individual_Enrollment__c> ienList) {

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
                    ien.reduivy__EFTSL__c = sofMap.get(ien.reduivy__Study_Offering__c)?.reduivy__Study_Unit__r?.reduivy__Default_EFTSL__c;
                }
            }
        }
    }
}