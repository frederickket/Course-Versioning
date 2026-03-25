/**
 * @author      WDCi (dblack)
 * @date        Jan 2024
 * @group       Trigger executable
 * @description Individual Grade Item: grade calculation and rollup to individual enrollment grade
 * @changehistory
 * ISS-001827 12-01-2024 dblack - new class
 * ISS-001954 24-05-2024 VTan - Update "FOR UPDATE" keyword on the SOQL to avoid race condition
 * ISS-001969 14-06-2024 Sueanne - Rollup IGD numerical grade based on parent IGI only
 * ISS-002060 03-09-2024 Lean - Changed to without sharing
 */
public without sharing class IGI_IgdGradeRollup_EXE extends REDU_TriggerExecutable {

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
            List<reduivy__Individual_Grade_Item__c> workingList = new List<reduivy__Individual_Grade_Item__c>();

            for (reduivy__Individual_Grade_Item__c igi : (List<reduivy__Individual_Grade_Item__c>) newList) {

                if ((String.isBlank(igi.reduivy__Parent_Grade_Item__c)) && 
                    (igi.reduivy__Weighted_Grade__c != null)
                ) {
                    workingList.add(igi);
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
            List<reduivy__Individual_Grade_Item__c> workingList = new List<reduivy__Individual_Grade_Item__c>();

            for (reduivy__Individual_Grade_Item__c igiNew : (List<reduivy__Individual_Grade_Item__c>) newList) {
                reduivy__Individual_Grade_Item__c igiOld = (reduivy__Individual_Grade_Item__c) oldMap.get(igiNew.Id);

                if ((String.isBlank(igiNew.reduivy__Parent_Grade_Item__c)) && 
                    (igiNew.reduivy__Weighted_Grade__c != igiOld.reduivy__Weighted_Grade__c)
                ) {
                    workingList.add(igiNew);
                }
            }

            if (!workingList.isEmpty()) {
                rollupGrade(workingList);
            }
        }
    }

    /**
     * @description Sum the weighted grades and rolls up the result to the individual enrollment grade record 
     * @param igiList List<reduivy__Individual_Grade_Item__c>
     */
    public static void rollupGrade(List<reduivy__Individual_Grade_Item__c> igiList) {

        // Populate the individual grade item map

        Map<Id, List<reduivy__Individual_Grade_Item__c>> igiMap = new Map<Id, List<reduivy__Individual_Grade_Item__c>>();

        for (reduivy__Individual_Grade_Item__c igi : igiList) {

            if (!igiMap.containsKey(igi.reduivy__Individual_Enrollment_Grade__c)) {
                igiMap.put(igi.reduivy__Individual_Enrollment_Grade__c, new List<reduivy__Individual_Grade_Item__c>());
            }

            igiMap.get(igi.reduivy__Individual_Enrollment_Grade__c).add(igi);
        }

        if (!igiMap.isEmpty()) {

            // Sum the individual grade items: weighted grade

            List<reduivy__Individual_Enrollment_Grade__c> igdList = new List<reduivy__Individual_Enrollment_Grade__c>();

            for (reduivy__Individual_Enrollment_Grade__c igd : getIgdList(new Map<String, Object>{
                'igdIdSet' => igiMap.keySet()
            })) {
                Decimal igdNumericalGrade = 0;

                for (reduivy__Individual_Grade_Item__c igi : igd.reduivy__Individual_Grade_Items__r) {
                    igdNumericalGrade += (igi.reduivy__Weighted_Grade__c == null) ? 0 : igi.reduivy__Weighted_Grade__c;
                }

                reduivy__Individual_Enrollment_Grade__c igdUpdate = new reduivy__Individual_Enrollment_Grade__c(
                    Id = igd.Id,
                    reduivy__Numerical_Grade__c = igdNumericalGrade
                );

                igdList.add(igdUpdate);
            }

            REDU_SystemMode_UTIL.doUpdate(igdList, igiMap, 'Id', false);
        }
    }

    /**
     * @description Get the list of individual enrollment grade records with the child individual enrollment grade item records
     * @param bindMap Map<String, Object> (key: 'igdIdSet')
     * @return List<reduivy__Individual_Enrollment_Grade__c>
     */
    private static List<reduivy__Individual_Enrollment_Grade__c> getIgdList(Map<String, Object> bindMap) {

        Set<String> igdFields = new Set<String>{
            'Id'
        };

        Set<String> igiFields = new Set<String>{
            'Id', 
            'reduivy__Individual_Enrollment_Grade__c', 
            'reduivy__Weighted_Grade__c'
        };

        String queryStr = 
            'SELECT ' + String.join(igdFields, ', ') + ', ' + 
            ' (SELECT ' + String.join(igiFields, ', ') + 
                ' FROM reduivy__Individual_Grade_Items__r ' +
                ' WHERE reduivy__Parent_Grade_Item__c = null) ' + 
            ' FROM reduivy__Individual_Enrollment_Grade__c ' + 
            ' WHERE Id IN :igdIdSet ' + 
            ' FOR UPDATE ';

        Map<String, Set<String>> igdObjectFieldsFls = new Map<String, Set<String>>();
        igdObjectFieldsFls.put(IGD_Helper.getApiName(), igdFields);
        igdObjectFieldsFls.put(IGI_Helper.getApiName(), igiFields);

        return (List<reduivy__Individual_Enrollment_Grade__c>) REDU_SystemMode_UTIL.doQuery(queryStr, bindMap, igdObjectFieldsFls);
    }
}