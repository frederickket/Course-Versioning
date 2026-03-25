/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Trigger executable
 * @description Rollup from individual plan structure (group) to individual program enrollment
 * @changehistory
 * ISS-001817 13-12-2023 dblack - new class
 * ISS-001954 24-05-2024 VTan - Update "FOR UPDATE" keyword on the SOQL to avoid race condition
 * ISS-002441 06-05-2025 XW - Consider required children IPS Group when updating parent status
 */
public without sharing class IPS_IpeCompletion_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual plan structure (group) record type Id
     */
    private static final Id IPS_GROUP_RECORD_TYPE_ID = IPS_Helper.getGroupRecordTypeId();
    private static final List<String> IPS_GROUP_COMPLETED_STATUSES = IPS_Helper.getGroupCompletedStatuses();

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

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> workingMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();

            for (reduivy__Individual_Plan_Structure__c ipsNew : (List<reduivy__Individual_Plan_Structure__c>) newList) {

                if ((ipsNew.RecordTypeId == IPS_GROUP_RECORD_TYPE_ID) && 
                    (String.isBlank(ipsNew.reduivy__Parent_Plan_Structure__c)) && 
                    (String.isNotBlank(ipsNew.reduivy__Individual_Program_Enrollment__c))
                ) {

                    reduivy__Individual_Plan_Structure__c ipsOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsNew.Id);

                    if ((ipsNew.reduivy__Credits_Enrolled__c != ipsOld.reduivy__Credits_Enrolled__c) || 
                        (ipsNew.reduivy__Units_Enrolled__c != ipsOld.reduivy__Units_Enrolled__c) || 
                        (ipsNew.reduivy__Credits_Earned__c != ipsOld.reduivy__Credits_Earned__c) ||
                        (ipsNew.reduivy__Required_Children_Completed__c != ipsOld.reduivy__Required_Children_Completed__c)
                    ) {
                        if (!workingMap.containsKey(ipsNew.reduivy__Individual_Program_Enrollment__c)) {
                            workingMap.put(ipsNew.reduivy__Individual_Program_Enrollment__c, new List<reduivy__Individual_Plan_Structure__c>());
                        }

                        workingMap.get(ipsNew.reduivy__Individual_Program_Enrollment__c).add(ipsNew);
                    }
                }
            }

            if (!workingMap.isEmpty()) {
                rollupToIpe(workingMap);
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

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> workingMap = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();

            for (reduivy__Individual_Plan_Structure__c ipsOld : (List<reduivy__Individual_Plan_Structure__c>) oldList) {

                if ((ipsOld.RecordTypeId == IPS_GROUP_RECORD_TYPE_ID) && 
                    (String.isBlank(ipsOld.reduivy__Parent_Plan_Structure__c)) && 
                    (String.isNotBlank(ipsOld.reduivy__Individual_Program_Enrollment__c))
                ) {

                    if (!workingMap.containsKey(ipsOld.reduivy__Individual_Program_Enrollment__c)) {
                        workingMap.put(ipsOld.reduivy__Individual_Program_Enrollment__c, new List<reduivy__Individual_Plan_Structure__c>());
                    }

                    workingMap.get(ipsOld.reduivy__Individual_Program_Enrollment__c).add(ipsOld);
                }
            }

            if (!workingMap.isEmpty()) {
                rollupToIpe(workingMap);
            }
        }
    }

    /**
     * @description Rollup credits earned from individual plan structure (group) to individual program enrollment
     * @param ipsgMap Map<Id, List<reduivy__Individual_Plan_Structure__c>>
     */
    private static void rollupToIpe(Map<Id, List<reduivy__Individual_Plan_Structure__c>> ipsgMap) {

        // Rollup from individual plan structure (group) to individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();

        for (reduivy__Individual_Program_Enrollment__c ipe : getIpeList(new Map<String, Object>{
            'ipsGroupRecordTypeId' => IPS_GROUP_RECORD_TYPE_ID,
            'ipeIdSet' => ipsgMap.keySet()
        })) {

            Decimal ipeCreditsEnrolled = 0;
            Decimal ipeUnitsEnrolled = 0;
            Decimal ipeCreditsEarned = 0;
            Integer incompleteRequiredChildrenCount = 0;
            Boolean requiredChildrenCompleted;

            for (reduivy__Individual_Plan_Structure__c ipsg : ipe.reduivy__Individual_Plan_Structures__r) {

                if (ipsg.reduivy__Credits_Enrolled__c != null) {
                    ipeCreditsEnrolled += ipsg.reduivy__Credits_Enrolled__c;
                }

                if (ipsg.reduivy__Units_Enrolled__c != null) {
                    ipeUnitsEnrolled += ipsg.reduivy__Units_Enrolled__c;
                }

                if (ipsg.reduivy__Credits_Earned__c != null) {
                    ipeCreditsEarned += ipsg.reduivy__Credits_Earned__c;
                }

                if(ipsg.reduivy__Category__c == IPS_Helper.CATEGORY_REQUIRED) {
                    incompleteRequiredChildrenCount++;

                    if(IPS_GROUP_COMPLETED_STATUSES.contains(ipsg.reduivy__Status__c)){
                        incompleteRequiredChildrenCount--;
                    }
                }

            }

            requiredChildrenCompleted = incompleteRequiredChildrenCount == 0;

            if (ipe.reduivy__Credits_Enrolled__c != ipeCreditsEnrolled || ipe.reduivy__Units_Enrolled__c != ipeUnitsEnrolled || ipe.reduivy__Credits_Earned__c != ipeCreditsEarned || ipe.reduivy__Required_Children_Completed__c != requiredChildrenCompleted ) {
                
                reduivy__Individual_Program_Enrollment__c ipeUpdate = new reduivy__Individual_Program_Enrollment__c(
                    Id = ipe.Id,
                    reduivy__Credits_Enrolled__c = ipeCreditsEnrolled,
                    reduivy__Units_Enrolled__c = ipeUnitsEnrolled,
                    reduivy__Credits_Earned__c = ipeCreditsEarned,
                    reduivy__Required_Children_Completed__c = requiredChildrenCompleted
                );

                ipeList.add(ipeUpdate);
            }
        }

        if (!ipeList.isEmpty()) {
            //Rollup using system mode as the fields are non editable by normal user
            REDU_SystemMode_UTIL.doUpdate(ipeList, ipsgMap, 'Id', false);
        }
    }

    /**
     * @description Get the list of individual program enrollment records with child individual plan structure records
     * @param bindMap Map<String, Object> (keys: 'ipsGroupRecordTypeId', 'ipeIdSet')
     * @return List<reduivy__Individual_Program_Enrollment__c>
     */
    private static List<reduivy__Individual_Program_Enrollment__c> getIpeList(Map<String, Object> bindMap) {

        Set<String> ipeFields = new Set<String>{
            'Id',
            'reduivy__Credits_Enrolled__c',
            'reduivy__Units_Enrolled__c',
            'reduivy__Credits_Earned__c',
            'reduivy__Required_Children_Completed__c'
        };

        Set<String> ipsFields = new Set<String>{
            'Id',
            'reduivy__Credits_Enrolled__c',
            'reduivy__Units_Enrolled__c',
            'reduivy__Credits_Earned__c',
            'reduivy__Category__c',
            'reduivy__Status__c'
        };

        String queryStr = 
            'SELECT ' + String.join(ipeFields, ', ') + ', ' +
                ' (SELECT ' + String.join(ipsFields, ',') +
                ' FROM reduivy__Individual_Plan_Structures__r ' + 
                ' WHERE RecordTypeId = :ipsGroupRecordTypeId ' + 
                ' AND reduivy__Parent_Plan_Structure__c = null ' + 
                ' ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC) ' + 
            ' FROM reduivy__Individual_Program_Enrollment__c ' + 
            ' WHERE Id IN :ipeIdSet ' +
            ' FOR UPDATE';
        
        Map<String, Set<String>> ipeObjectFieldsFls = new Map<String, Set<String>>();
        ipeObjectFieldsFls.put(IPE_Helper.getApiName(), ipeFields);
        ipeObjectFieldsFls.put(IPS_Helper.getApiName(), ipsFields);

        return (List<reduivy__Individual_Program_Enrollment__c>) REDU_SystemMode_UTIL.doQuery(queryStr, bindMap, ipeObjectFieldsFls);
    }
}