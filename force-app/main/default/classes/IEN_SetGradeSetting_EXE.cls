/**
 * @author      WDCi (dblack)
 * @date        Nov 2023
 * @group       Trigger executable
 * @description Individual Enrollment: set the grade setting type
 * @changehistory
 * ISS-001766 06-11-2023 dblack - new class
 *            31-01-2024 vtan - Get grade setting type from study unit if study offering is blank
 * ISS-002513 02-03-2026 XiRouh - Added String.isBlank(ien.reduivy__Study_Grade_Setting__c) to the fire condition
 */
public inherited sharing class IEN_SetGradeSetting_EXE extends REDU_TriggerExecutable {
    
    private static final Id IEN_STUDENT_RTID =  IEN_Helper.getStudentRecordTypeId();
    private static final List<String> IEN_GRADE_RELEASED_STATUSES = IEN_Helper.getGradeReleasedStatuses();

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

        if (operationType == TriggerOperation.BEFORE_INSERT) {

            Map<Id, List<reduivy__Individual_Enrollment__c>> ienMap = new Map<Id, List<reduivy__Individual_Enrollment__c>>();

            for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) newList) {                  
                if (ien.RecordTypeId == IEN_STUDENT_RTID && String.isBlank(ien.reduivy__Study_Grade_Setting__c)) {
                    if(String.isNotBlank(ien.reduivy__Study_Offering__c)){

                        if (!ienMap.containsKey(ien.reduivy__Study_Offering__c)) {
                            ienMap.put(ien.reduivy__Study_Offering__c, new List<reduivy__Individual_Enrollment__c>());
                        }
    
                        ienMap.get(ien.reduivy__Study_Offering__c).add(ien);

                    // check study unit only if study offering is empty
                    }else if(String.isNotBlank(ien.reduivy__Study_Unit__c)){
                        
                        if (!ienMap.containsKey(ien.reduivy__Study_Unit__c)) {
                            ienMap.put(ien.reduivy__Study_Unit__c, new List<reduivy__Individual_Enrollment__c>());
                        }
    
                        ienMap.get(ien.reduivy__Study_Unit__c).add(ien);

                    }
                }
            }

            if (!ienMap.isEmpty()) {
                setGradeSetting(ienMap);                
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

        if (operationType == TriggerOperation.BEFORE_UPDATE) {

            Map<Id, List<reduivy__Individual_Enrollment__c>> ienMap = new Map<Id, List<reduivy__Individual_Enrollment__c>>();

            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {             
                if ((ienNew.RecordTypeId == IEN_STUDENT_RTID) && (String.isNotBlank(ienNew.reduivy__Study_Offering__c) || String.isNotBlank(ienNew.reduivy__Study_Unit__c))) {
                    reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);

                    Boolean isGradeReleaseStatusChangedToReleased = String.isNotBlank(ienNew.reduivy__Grade_Release_Status__c) && IEN_GRADE_RELEASED_STATUSES.contains(ienNew.reduivy__Grade_Release_Status__c) && ienNew.reduivy__Grade_Release_Status__c != ienOld.reduivy__Grade_Release_Status__c;

                    Boolean isSofOrSunChanged = ienNew.reduivy__Study_Offering__c != ienOld.reduivy__Study_Offering__c || ienNew.reduivy__Study_Unit__c != ienOld.reduivy__Study_Unit__c;

                    if (isSofOrSunChanged || (isGradeReleaseStatusChangedToReleased && String.isBlank(ienNew.reduivy__Study_Grade_Setting__c))) {

                        if (String.isNotBlank(ienNew.reduivy__Study_Offering__c)) {
                            if (!ienMap.containsKey(ienNew.reduivy__Study_Offering__c)) {
                                ienMap.put(ienNew.reduivy__Study_Offering__c, new List<reduivy__Individual_Enrollment__c>());
                            }

                            ienMap.get(ienNew.reduivy__Study_Offering__c).add(ienNew);

                        } else if (String.isNotBlank(ienNew.reduivy__Study_Unit__c)) {
                            if (!ienMap.containsKey(ienNew.reduivy__Study_Unit__c)) {
                                ienMap.put(ienNew.reduivy__Study_Unit__c, new List<reduivy__Individual_Enrollment__c>());
                            }

                            ienMap.get(ienNew.reduivy__Study_Unit__c).add(ienNew);
                        }
                    }
                }
            }

            if (!ienMap.isEmpty()) {
                setGradeSetting(ienMap);                
            }
        }
    }

    /**
     * @description Set the study grade setting on individual enrollment
     * @param ienMapBySofSu
     * @return void
     */
    private void setGradeSetting(Map<Id, List<reduivy__Individual_Enrollment__c>> ienMapBySofSu) {

        Map<Id, reduivy__Study_Offering__c> sofMap = SOF_Helper.getStudyOfferings(ienMapBySofSu.keySet(), true);
        
        Map<Id, reduivy__Study_Unit__c> suMap = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, reduivy__Study_Grade_Setting__c
            FROM reduivy__Study_Unit__c 
            WHERE Id IN :ienMapBySofSu.keySet()
            WITH USER_MODE 
        ]);

        if (!sofMap.isEmpty()) {
            for(Id sofId : sofMap.keySet()){
                if (ienMapBySofSu.containsKey(sofId)) {
                    for(reduivy__Individual_Enrollment__c ien : ienMapBySofSu.get(sofId)){
                        if (String.isNotBlank(sofMap.get(sofId).reduivy__Study_Grade_Setting__c)) {
                            ien.reduivy__Study_Grade_Setting__c = sofMap.get(sofId).reduivy__Study_Grade_Setting__c;
                        } else if (String.isNotBlank(sofMap.get(sofId).reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c)) {
                            ien.reduivy__Study_Grade_Setting__c = sofMap.get(sofId).reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c;
                        }
                    }
                }
            }
        }

        if (!suMap.isEmpty()) {
            for(Id studyUnitId : suMap.keySet()){
                if (ienMapBySofSu.containsKey(studyUnitId)) {
                    for(reduivy__Individual_Enrollment__c ien : ienMapBySofSu.get(studyUnitId)){
                        if(String.isNotBlank(suMap.get(studyUnitId).reduivy__Study_Grade_Setting__c)){
                            ien.reduivy__Study_Grade_Setting__c = suMap.get(studyUnitId).reduivy__Study_Grade_Setting__c;
                        }
                    }
                }
            }
        }
    }
}