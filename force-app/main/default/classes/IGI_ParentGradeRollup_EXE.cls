/**
 * @author      WDCi (dblack)
 * @date        Jan 2024
 * @group       Trigger executable
 * @description Individual Grade Item: grade calculation and rollup to parent individual grade item
 * @changehistory
 * ISS-001827 12-01-2024 dblack - new class
 * ISS-001954 24-05-2024 VTan - Update "FOR UPDATE" keyword on the SOQL to avoid race condition
 * ISS-002060 03-09-2024 Lean - Changed to without sharing
 */
public without sharing class IGI_ParentGradeRollup_EXE extends REDU_TriggerExecutable {

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

                if ((String.isNotBlank(igi.reduivy__Parent_Grade_Item__c)) && 
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

                if ((String.isNotBlank(igiNew.reduivy__Parent_Grade_Item__c)) && 
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
     * @description Sum the weighted grades and rolls up the result to the parent individual grade item record 
     * @param igiList List<reduivy__Individual_Grade_Item__c>
     */
    private static void rollupGrade(List<reduivy__Individual_Grade_Item__c> igiList) {

        // Populate the individual grade item map

        Map<Id, List<reduivy__Individual_Grade_Item__c>> igiChildMap = new Map<Id, List<reduivy__Individual_Grade_Item__c>>();

        for (reduivy__Individual_Grade_Item__c igi : igiList) {

            if (String.isNotBlank(igi.reduivy__Parent_Grade_Item__c)) {

                if (!igiChildMap.containsKey(igi.reduivy__Parent_Grade_Item__c)) {
                    igiChildMap.put(igi.reduivy__Parent_Grade_Item__c, new List<reduivy__Individual_Grade_Item__c>());
                }

                igiChildMap.get(igi.reduivy__Parent_Grade_Item__c).add(igi);
            }
        }

        if (!igiChildMap.isEmpty()) {

            // Sum the child individual grade items: weighted grade

            List<reduivy__Individual_Grade_Item__c> igiParentList = new List<reduivy__Individual_Grade_Item__c>();

            for (reduivy__Individual_Grade_Item__c igiParent : getIgiParentList(new Map<String, Object>{
                'igiParentIdSet' => igiChildMap.keySet()
            })) {
                Decimal igiParentNumericalGrade = 0;

                for (reduivy__Individual_Grade_Item__c igiChild : igiParent.reduivy__Child_Grade_Items__r) {
                    igiParentNumericalGrade += (igiChild.reduivy__Weighted_Grade__c == null) ? 0 : igiChild.reduivy__Weighted_Grade__c;
                }

                reduivy__Individual_Grade_Item__c igiParentUpdate = new reduivy__Individual_Grade_Item__c(
                    Id = igiParent.Id,
                    reduivy__Numerical_Grade__c = igiParentNumericalGrade
                );

                igiParentList.add(igiParentUpdate);
            }

            REDU_SystemMode_UTIL.doUpdate(igiParentList, igiChildMap, 'Id', false);
        }
    }

    /**
     * @description Get the list of individual enrollment grade records with the child individual enrollment grade item records
     * @param bindMap Map<String, Object> (key: 'igiParentIdSet')
     * @return List<reduivy__Individual_Grade_Item__c>
     */
    private static List<reduivy__Individual_Grade_Item__c> getIgiParentList(Map<String, Object> bindMap) {

        Set<String> parentIgiFields = new Set<String>{
            'Id'
        };

        Set<String> igiFields = new Set<String>{
            'Id', 
            'reduivy__Parent_Grade_Item__c', 
            'reduivy__Weighted_Grade__c'
        };

        String queryStr = 
            'SELECT ' + String.join(parentIgiFields, ', ') + ', ' +
            ' (SELECT ' + String.join(igiFields, ', ') + 
                ' FROM reduivy__Child_Grade_Items__r) ' + 
            ' FROM reduivy__Individual_Grade_Item__c ' + 
            ' WHERE Id IN :igiParentIdSet ' + 
            ' FOR UPDATE ';

        Map<String, Set<String>> igiObjectFieldsFls = new Map<String, Set<String>>();
        igiObjectFieldsFls.put(IGI_Helper.getApiName(), igiFields);

        return (List<reduivy__Individual_Grade_Item__c>) REDU_SystemMode_UTIL.doQuery(queryStr, bindMap, igiObjectFieldsFls);
    }
}