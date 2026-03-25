/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Trigger executable
 * @description Individual Enrollment - increment the attempt number if the student has previously attempted the study unit
 * @changehistory
 * ISS-001832 20-12-2023 dblack - new class
 * ISS-001982 01-07-2024 Sueanne - set default attempt number as 1 when enroll first time
 * ISS-002448 07-05-2025 XiRouh - Updated to use custom metadata to determine which statuses should increase attempt number
 * ISS-002743 09-12-2025 XiRouh - Updated to use IPF-based grouping instead of Contact-based grouping
 */
public inherited sharing class IEN_IncrementAttemptNumber_EXE extends REDU_TriggerExecutable {
    
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
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            incrementIenAttemptNumber((List<reduivy__Individual_Enrollment__c>) newList);
        }
    }

    /**
     * @description Increment the individual enrollment attempt number if the student has previously attempted the study unit
     * @param ienList List<reduivy__Individual_Enrollment__c>
     */
    private void incrementIenAttemptNumber(List<reduivy__Individual_Enrollment__c> ienList) {

        Set<Id> sunIdSet = new Set<Id>();
        Set<Id> ipfIdSet = new Set<Id>();

        List<String> increaseAttmptNumberStatuses = IEN_Helper.getIncreaseAttemptNumberStatuses();

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            if (ien.RecordTypeId == IEN_STUDENT_RECORDTYPE_ID && 
                ien.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM &&
                ien.reduivy__Attempt_Number__c == null) {

                //set the default atempt number as 1
                ien.reduivy__Attempt_Number__c = 1;

                if (String.isNotBlank(ien.reduivy__Target_Unit_Id__c)) {
                    sunIdSet.add(ien.reduivy__Target_Unit_Id__c);
                }

                if (String.isNotBlank(ien.reduivy__Individual_Academic_Profile__c)) {
                    ipfIdSet.add(ien.reduivy__Individual_Academic_Profile__c);
                }
            }
        }

        if ((!sunIdSet.isEmpty()) && (!ipfIdSet.isEmpty())) {

            // Create Map: Individual Academic Profile + contact Id + study unit Id => individual enrollment record

            Map<String, reduivy__Individual_Enrollment__c> ienAttemptedMapByIpfSun = new Map<String, reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : [
                SELECT reduivy__Contact__c, 
                reduivy__Target_Unit_Id__c, 
                reduivy__Attempt_Number__c,
                reduivy__Enrollment_Status__c,
                reduivy__Grade_Result__c,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Target_Unit_Id__c IN :sunIdSet
                AND reduivy__Individual_Academic_Profile__c IN :ipfIdSet
                AND RecordTypeId =: IEN_STUDENT_RECORDTYPE_ID
                AND reduivy__Enrollment_Type__c =: IEN_ENROLLMENTTYPE_PROGRAM
                WITH USER_MODE
                ORDER BY reduivy__Attempt_Number__c DESC NULLS LAST, reduivy__Start_Date__c DESC NULLS LAST, CreatedDate DESC
            ]) {

                String ipfSunKey = getIpfSunKey(ien);

                if (!ienAttemptedMapByIpfSun.containsKey(ipfSunKey)) {
                    ienAttemptedMapByIpfSun.put(ipfSunKey, ien);
                }
            }

            // Set the attempt number
            for (reduivy__Individual_Enrollment__c ien : ienList) {

                // Only process if IPF is populated
                if (String.isBlank(ien.reduivy__Individual_Academic_Profile__c)) {
                    continue;
                }

                String ipfSunKey = getIpfSunKey(ien);

                if (ienAttemptedMapByIpfSun.containsKey(ipfSunKey)) {

                    reduivy__Individual_Enrollment__c ienLastAttempted = ienAttemptedMapByIpfSun.get(ipfSunKey);

                    if (increaseAttmptNumberStatuses.contains(ienLastAttempted.reduivy__Enrollment_Status__c)) {
                        ien.reduivy__Attempt_Number__c = ienLastAttempted.reduivy__Attempt_Number__c + 1;
                    } else {
                        ien.reduivy__Attempt_Number__c = ienLastAttempted.reduivy__Attempt_Number__c;
                    }
                }
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