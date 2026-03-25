/**
 * @author      WDCi (dblack)
 * @date        Jan 2024
 * @group       Trigger executable
 * @description Individual Enrollment Grade: grade calculation and rollup to individual enrollment
 * @changehistory
 * ISS-001827 12-01-2024 dblack - new class
 * ISS-001954 24-05-2024 VTan - Update "FOR UPDATE" keyword on the SOQL to avoid race condition
 * ISS-002060 03-09-2024 Lean - Changed to without sharing
 */
public without sharing class IGD_IenGradeRollup_EXE extends REDU_TriggerExecutable {

    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if ((REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) || 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY))
        ) {
            List<reduivy__Individual_Enrollment_Grade__c> workingList = new List<reduivy__Individual_Enrollment_Grade__c>();

            for (reduivy__Individual_Enrollment_Grade__c igd : (List<reduivy__Individual_Enrollment_Grade__c>) newList) {

                if (igd.reduivy__Weighted_Grade__c != null) {
                    workingList.add(igd);
                }
            }

            if (!workingList.isEmpty()) {
                rollupGrade(workingList);
            }
        }
    }

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

        if ((REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) || 
            (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY))
        ) {
            List<reduivy__Individual_Enrollment_Grade__c> workingList = new List<reduivy__Individual_Enrollment_Grade__c>();

            for (reduivy__Individual_Enrollment_Grade__c igdNew : (List<reduivy__Individual_Enrollment_Grade__c>) newList) {
                reduivy__Individual_Enrollment_Grade__c igdOld = (reduivy__Individual_Enrollment_Grade__c) oldMap.get(igdNew.Id);

                if (igdNew.reduivy__Weighted_Grade__c != igdOld.reduivy__Weighted_Grade__c) {
                    workingList.add(igdNew);
                }
            }

            if (!workingList.isEmpty()) {
                rollupGrade(workingList);
            }
        }
    }
	
    /**
     * @description Sum the weighted grades and rolls up the result to the individual enrollment record 
     * @param igdList List<reduivy__Individual_Enrollment_Grade__c>
     */
    private static void rollupGrade(List<reduivy__Individual_Enrollment_Grade__c> igdList) {

        // Populate the individual enrollment grade map

        Map<Id, List<reduivy__Individual_Enrollment_Grade__c>> igdMap = new Map<Id, List<reduivy__Individual_Enrollment_Grade__c>>();

        for (reduivy__Individual_Enrollment_Grade__c igd : igdList) {

            if (String.isNotBlank(igd.reduivy__Individual_Enrollment__c)) {
                
                if (!igdMap.containsKey(igd.reduivy__Individual_Enrollment__c)) {
                    igdMap.put(igd.reduivy__Individual_Enrollment__c, new List<reduivy__Individual_Enrollment_Grade__c>());
                }

                igdMap.get(igd.reduivy__Individual_Enrollment__c).add(igd);
            }
        }

        if (!igdMap.isEmpty()) {

            // Sum the individual enrollment grades: weighted grade

            List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : getIenList(new Map<String, Object>{
                'ienIdSet' => igdMap.keySet()
            })) {
                Decimal ienNumericalGrade = 0;

                for (reduivy__Individual_Enrollment_Grade__c igd : ien.reduivy__Individual_Enrollment_Grades__r) {
                    ienNumericalGrade += (igd.reduivy__Weighted_Grade__c == null) ? 0 : igd.reduivy__Weighted_Grade__c;
                }

                reduivy__Individual_Enrollment__c ienUpdate = new reduivy__Individual_Enrollment__c(
                    Id = ien.Id,
                    reduivy__Numerical_Grade__c = ienNumericalGrade
                );

                ienList.add(ienUpdate);
            }

            REDU_SystemMode_UTIL.doUpdate(ienList, igdMap, 'Id', false);
        }
    }

    /**
     * @description Get the list of individual enrollment records with the child individual enrollment grade records
     * @param bindMap Map<String, Object> (key: 'ienIdSet')
     * @return List<reduivy__Individual_Enrollment__c>
     */
    private static List<reduivy__Individual_Enrollment__c> getIenList(Map<String, Object> bindMap) {

        Set<String> ienFields = new Set<String>{
            'Id',
            'reduivy__Attempt_Number__c'
        };

        Set<String> igdFields = new Set<String>{
            'Id',
            'reduivy__Individual_Enrollment__c',
            'reduivy__Weighted_Grade__c'
        };

        String queryStr = 'SELECT ' + String.join(ienFields, ', ') + ', ' +
            ' (SELECT ' + String.join(igdFields, ', ') +
                ' FROM reduivy__Individual_Enrollment_Grades__r) ' + 
            ' FROM reduivy__Individual_Enrollment__c ' + 
            ' WHERE Id IN :ienIdSet ' + 
            ' FOR UPDATE ';

        Map<String, Set<String>> ienObjectFieldsForFls = new Map<String, Set<String>>();
        ienObjectFieldsForFls.put(IEN_Helper.getApiName(), ienFields);
        ienObjectFieldsForFls.put(IGD_Helper.getApiName(), igdFields);

        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) REDU_SystemMode_UTIL.doQuery(queryStr, bindMap, ienObjectFieldsForFls)){
            ienList.add(ien);
        }

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Individual_Enrollment__c.reduivy__Attempt_Number__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };

        ienList.sort(new REDU_SObjectComparator(criteria));

        return ienList;
    }
}