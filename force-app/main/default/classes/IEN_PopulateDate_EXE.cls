/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Individual enrollment: populate enrollment date, start date, census date, due date and end date
 * @changehistory
 * ISS-001763 27-10-2023 dblack - new class
 * ISS-001970 19-06-2024 Sueanne - update start date, end date and due date populating logic
 * ISS-002231 25-03-2025 Lean - Added deferred status
 */
public inherited sharing class IEN_PopulateDate_EXE extends REDU_TriggerExecutable {
    
    static final Id IEN_STUDENT_RTID =  IEN_Helper.getStudentRecordTypeId();

    /**
     * @description Individual enrollment - completed statuses
     */
    private static final List<String> IEN_ENROLLMENT_COMPLETED_STATUSES = IEN_Helper.getCompletedStatuses();

    /**
     * @description Individual enrollment - in progress statuses
     */
    private static final List<String> IEN_ENROLLMENT_INPROGRESS_STATUSES = IEN_Helper.getInProgressStatuses();

    /**
     * @description Individual enrollment - deferred statuses
     */
    private static final List<String> IEN_ENROLLMENT_DEFERRED_STATUSES = IEN_Helper.getDeferredStatuses();

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
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            // Set each of the individual enrollment dates: enrollment date, start date, census date, due date and end date
            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                if (ienNew.RecordTypeId == IEN_STUDENT_RTID) {
                    ienList.add(ienNew);
                }
            }

            if (!ienList.isEmpty()) {
                setDates(ienList);
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

            // Set each of the individual enrollment dates: enrollment date, start date, census date, due date and end date
            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);

                if (ienNew.RecordTypeId == IEN_STUDENT_RTID &&
                    (
                        (ienNew.reduivy__Study_Offering__c != ienOld.reduivy__Study_Offering__c) || 
                        (ienNew.reduivy__Enrollment_Status__c != ienOld.reduivy__Enrollment_Status__c)
                    )
                ) {
                    ienList.add(ienNew);
                }

                if (!ienList.isEmpty()) {
                    setDates(ienList);
                }
            }
        }
    }

    /**
     * @description Sets the individual enrollment dates: enrollment date, start date, census date, due date and end date
     * @param ienList List<reduivy__Individual_Enrollment__c>
     */
    public void setDates(List<reduivy__Individual_Enrollment__c> ienList) {

        List<reduivy__Individual_Enrollment__c> qualifiedIens = new List<reduivy__Individual_Enrollment__c>();
        Set<Id> sofIds = new Set<Id>();

        for (reduivy__Individual_Enrollment__c ien : ienList) {

            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                if ((
                        IEN_ENROLLMENT_INPROGRESS_STATUSES.contains(ien.reduivy__Enrollment_Status__c) || 
                        IEN_ENROLLMENT_COMPLETED_STATUSES.contains(ien.reduivy__Enrollment_Status__c) ||
                        IEN_ENROLLMENT_DEFERRED_STATUSES.contains(ien.reduivy__Enrollment_Status__c)
                    ) && 
                    ((ien.reduivy__Enrollment_Date__c == null) || (ien.reduivy__Start_Date__c == null) || (ien.reduivy__Census_Date__c == null) || (ien.reduivy__Due_Date__c == null))
                ) {

                    qualifiedIens.add(ien);
                    sofIds.add(ien.reduivy__Study_Offering__c);

                } 
                
                if ((IEN_Helper.getCompletedStatuses().contains(ien.reduivy__Enrollment_Status__c)) && (ien.reduivy__End_Date__c == null)) {
                    ien.reduivy__End_Date__c = System.today();
                }
            } else {
                ien.reduivy__Enrollment_Date__c = null;
                ien.reduivy__Start_Date__c = null;
                ien.reduivy__Census_Date__c = null;
                ien.reduivy__Due_Date__c = null;
                ien.reduivy__End_Date__c = null;
            }
        }

        if (!qualifiedIens.isEmpty()) {
            Map<Id, reduivy__Study_Offering__c> sofMap = SOF_Helper.getStudyOfferings(sofIds, true);

            for (reduivy__Individual_Enrollment__c ien : qualifiedIens) {
                if (sofMap.containsKey(ien.reduivy__Study_Offering__c)) {
                    reduivy__Study_Offering__c sof = sofMap.get(ien.reduivy__Study_Offering__c);
                    
                    if (ien.reduivy__Enrollment_Date__c == null) {
                        ien.reduivy__Enrollment_Date__c = System.today();
                    }

                    ien.reduivy__Census_Date__c = sof.reduivy__Census_Date_Calculated__c;

                    if (sof.reduivy__Delivery_Method__c == 'Online - Self Learning') {
                        ien.reduivy__Start_Date__c = System.today();
                        Integer sofDuration = (sof.reduivy__Scheduled_Duration__c != null) ? Integer.valueOf(sof.reduivy__Scheduled_Duration__c) : 0;

                        if (sof.reduivy__Scheduled_Duration_Unit__c == 'Hour') {
                            ien.reduivy__Due_Date__c = Date.valueOf(System.now().addHours(sofDuration));
                        } else if (sof.reduivy__Scheduled_Duration_Unit__c == 'Minute') {
                            ien.reduivy__Due_Date__c = Date.valueOf(System.now().addMinutes(sofDuration));
                        }
                        
                    } else {
                        ien.reduivy__Start_Date__c = sof.reduivy__Start_Date_Calculated__c;
                        ien.reduivy__Due_Date__c = sof.reduivy__End_Date_Calculated__c;
                    }
                }
            }
        }
    }
}
