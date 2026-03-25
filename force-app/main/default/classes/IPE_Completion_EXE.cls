/**
 * @author      WDCi (dblack)
 * @date        Jan 2024
 * @group       Trigger executable
 * @description Update the individual program enrollment status and completion percentage
 * @changehistory
 * ISS-001817 03-01-2024 dblack - new class
 * ISS-002323 13-03-2025 Lean - Fixed decimal points issue
 * ISS-002441 06-05-2025 XW - Consider required children IPS Group when updating ipe status
 */
public inherited sharing class IPE_Completion_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual program enrollment in-progress statuses
     */
    private static final List<String> IPE_INPROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();

    /**
     * @description Individual program enrollment completed statuses
     */
    private static final List<String> IPE_COMPLETED_STATUSES = IPE_Helper.getCompletedStatuses();

    /**
     * @description Individual program enrollment positive statuses
     */
    private static final List<String> IPE_POSITIVE_STATUSES = IPE_Helper.getPositiveStatuses();

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

            Map<Id, reduivy__Individual_Program_Enrollment__c> workingMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
            
            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                reduivy__Individual_Program_Enrollment__c ipeOld = (reduivy__Individual_Program_Enrollment__c) oldMap.get(ipeNew.Id);

                if (
                    ((ipeNew.reduivy__Remaining_Credits_Required__c != null) && (ipeNew.reduivy__Remaining_Credits_Required__c != ipeOld.reduivy__Remaining_Credits_Required__c)) ||
                    ipeNew.reduivy__Required_Children_Completed__c != ipeOld.reduivy__Required_Children_Completed__c
                ) {
                    workingMap.put(ipeNew.Id, ipeNew);
                }
            }

            if (!workingMap.isEmpty()) {
                setIpeCompletion(workingMap, (List<reduivy__Individual_Program_Enrollment__c>) oldList);
            }
        }
    }

    /**
     * @description Set the individual program enrollment status and completion percentage
     * @param ipeMap Map<Id, reduivy__Individual_Program_Enrollment__c>
     */
    private static void setIpeCompletion(Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap, List<reduivy__Individual_Program_Enrollment__c> oldList) {

        Map<Id, reduivy__Individual_Program_Enrollment__c> oldMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(oldList);

        Schema.DescribeFieldResult completionPercentageDfr = SObjectType.reduivy__Individual_Program_Enrollment__c.fields.reduivy__Completion_Percentage__c;
        Integer completionPercentageScale = completionPercentageDfr.getScale();

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
            reduivy__Individual_Program_Enrollment__c ipeOld = oldMap.get(ipe.Id);

            // we only change the status if it is currently in progress/completed
            if (IPE_POSITIVE_STATUSES.contains(ipe.reduivy__Enrollment_Status__c)) {

                String currentStatus = IPE_INPROGRESS_STATUSES.contains(ipe.reduivy__Enrollment_Status__c) ? ipe.reduivy__Enrollment_Status__c : (IPE_INPROGRESS_STATUSES.contains(ipeOld.reduivy__Enrollment_Status__c) ? ipeOld.reduivy__Enrollment_Status__c : IPE_INPROGRESS_STATUSES.get(0));

                // Set the enrollment status
                if (ipe.reduivy__Remaining_Credits_Required__c == 0 && ipe.reduivy__Required_Children_Completed__c) {
                    //Set to completed if no more remaining credits and the Required Children Completed is true
                    ipe.reduivy__Enrollment_Status__c = (IPE_COMPLETED_STATUSES.contains(ipe.reduivy__Enrollment_Status__c) ? ipe.reduivy__Enrollment_Status__c : IPE_COMPLETED_STATUSES.get(0));
                } else {
                    ipe.reduivy__Enrollment_Status__c = currentStatus;
                }
            }

            // Set the completion percentage
            Decimal ipeCompletionPercentage = (ipe.Total_Credits_Required__c == null || ipe.Total_Credits_Required__c == 0) ? null : ((ipe.reduivy__Total_Credits_Earned__c == null ? 0 : ipe.reduivy__Total_Credits_Earned__c) / ipe.Total_Credits_Required__c) * 100;
            ipe.reduivy__Completion_Percentage__c = ipeCompletionPercentage > 100 ? 100 : ipeCompletionPercentage;

            ipe.reduivy__Completion_Percentage__c = REDU_Number_UTIL.setScale(ipe.reduivy__Completion_Percentage__c, completionPercentageScale);
        }
    }
}