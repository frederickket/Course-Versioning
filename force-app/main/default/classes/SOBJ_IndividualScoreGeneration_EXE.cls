/**
 * @author      WDCi (XW)
 * @date        July 2025
 * @group       Application Scoring 
 * @description Generate Individual Score Individual Score Detail records when the criteria matches.
 * @changehistory
 * ISS-002506 16-07-2025 XW - new class
 */

public inherited sharing class SOBJ_IndividualScoreGeneration_EXE extends REDU_TriggerExecutable {

    private String objectLookupField;
    private Boolean parentRecordsAreReferred = false;
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {            
            if(!newMap.isEmpty()) {
                validateCreation(newMap, oldMap, sobjResult.getSObjectType());
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            if(!newMap.isEmpty()) {
                validateCreation(newMap, oldMap, sobjResult.getSObjectType());
            }
        }
    }

    /**
     * @description validate the creation of individual score and create if valid
     * @param  sobjMap  map of sobject id => sobject
     * @param  sobjType sobject type
     */
    private void validateCreation(Map<Id, SObject> sobjMap, Map<Id, SObject> oldSobjMap, Schema.SObjectType sobjType) {
        objectLookupField = REDU_Metadata_UTIL.getObjectLookupField(SCF_Helper.getApiName(), sobjType.getDescribe().getName());
        Map<Id, reduivy__Study_Scoring_Config__c> scfMap = getScfMap(sobjType);
        Map<Id, FormulaEval.FormulaInstance> formulaMap = getFormulaMap(scfMap, sobjType);
        List<SObject> sobjToEvaluate = getSobjToEvaluate(sobjMap.values(), formulaMap.values());

        Map<Id, Set<Id>> sobjIdToScfIdSetMap = new Map<Id, Set<Id>>();

        for(Id scfId : formulaMap.keySet()) {
            FormulaEval.FormulaInstance formula = formulaMap.get(scfId);

            for(SObject sobj : sobjToEvaluate) {
                Boolean isValid = (Boolean) formula.evaluate(sobj);
                Boolean wasValid = parentRecordsAreReferred || oldSobjMap.isEmpty() ? false : (Boolean) formula.evaluate(oldSobjMap.get(sobj.Id));

                if(!wasValid && isValid) {
                    if(!sobjIdToScfIdSetMap.containsKey(sobj.Id)) {
                        sobjIdToScfIdSetMap.put(sobj.Id, new Set<Id>());
                    }
                    sobjIdToScfIdSetMap.get(sobj.Id).add(scfId);
                }
            }
        }

        if(!sobjIdToScfIdSetMap.isEmpty()) {
            //check if the individual score is created before

            Set<String> existingIscFields = new Set<String> {
                'Id',
                'reduivy__Study_Scoring_Config__c',
                'Name'
            };
            existingIscFields.add(objectLookupField);

            String existingIscQuery = 'SELECT ' + String.join(existingIscFields, ', ')
                                   + ' FROM ' + ISC_Helper.getApiName()
                                   + ' WHERE reduivy__Study_Scoring_Config__c IN :scfIdSet'
                                   + ' AND ' + objectLookupField + ' IN :sobjIdSet';

            Map<String, Object> existingIscBindMap = new Map<String, Object> {
                'scfIdSet' => scfMap.keySet(),
                'sobjIdSet' => sobjIdToScfIdSetMap.keySet()
            };
            
            for(reduivy__Individual_Score__c isc : (List<reduivy__Individual_Score__c>) Database.queryWithBinds(existingIscQuery, existingIscBindMap, AccessLevel.USER_MODE)) {
                Id targetSObjectId = (Id)isc.get(objectLookupField);
                if(String.isNotBlank(targetSObjectId) && sobjIdToScfIdSetMap.containsKey(targetSObjectId)) {
                    sobjIdToScfIdSetMap.get(targetSObjectId).remove(isc.reduivy__Study_Scoring_Config__c);
                }
            }
        }

        
        //group the validated sobject to create ics for them
        List<reduivy__Individual_Score__c> iscListToInsert = new List<reduivy__Individual_Score__c>();
        if(!sobjIdToScfIdSetMap.isEmpty()) {
            
            for(Id sobjId : sobjIdToScfIdSetMap.keySet()) {
                SObject sobj = sobjMap.get(sobjId);

                for(Id scfId : sobjIdToScfIdSetMap.get(sobjId)) {

                    reduivy__Individual_Score__c newIsc = ISC_Helper.createIsc(scfMap.get(scfId), sobj);

                    iscListToInsert.add(newIsc);
                }
            }
        }

        if(!iscListToInsert.isEmpty()) {
            REDU_Database_UTIL.doInsert(iscListToInsert, sobjMap, objectLookupField, false); 
        }
    }

    /**
     * @description get map of study scoring config id => study scoring config. the study scoring config must have criteria field populated
     * @param
     * @return void
     */
    private Map<Id, reduivy__Study_Scoring_Config__c> getScfMap(Schema.SObjectType sobjType) {
        List<FormulaEval.FormulaInstance> formulaList = new List<FormulaEval.FormulaInstance>();
        Map<Id, reduivy__Study_Scoring_Config__c> scfMap = new Map<Id, reduivy__Study_Scoring_Config__c>();

        Set<String> scfFields = new Set<String>{
            'reduivy__Code__c',
            'reduivy__Contact_Field__c',
            'reduivy__Criteria__c',
            'reduivy__SObject_Type__c',
            'Name'
        };
        scfFields.addAll(ISC_Helper.getScfIscCommonFields());

        String scfQuery = 'SELECT ' + String.join(scfFields, ', ') +
                         ' FROM ' + SCF_Helper.getApiName() +
                         ' WHERE reduivy__Status__c =: scfStatusActive' +
                         ' AND reduivy__SObject_Type__c = :sobjType';
                         

        Map<String, Object> bindMap = new Map<String, Object> {
            'scfStatusActive' => SCF_Helper.STATUS_ACTIVE,
            'sobjType' => sobjType.getDescribe().getName()
        };


        for(reduivy__Study_Scoring_Config__c scf : (List<reduivy__Study_Scoring_Config__c>) Database.queryWithBinds(scfQuery, bindMap, AccessLevel.USER_MODE)) {
            if(String.isNotBlank(scf.reduivy__Criteria__c)) {
                scfMap.put(scf.Id, scf);
            }
        
        }

        return scfMap;
    }

    private Map<Id, FormulaEval.FormulaInstance> getFormulaMap(Map<Id, reduivy__Study_Scoring_Config__c> scfMap, Schema.SObjectType sobjType){
        Map<Id, FormulaEval.FormulaInstance> formulaMap = new Map<Id, FormulaEval.FormulaInstance>();

        for(reduivy__Study_Scoring_Config__c scf : scfMap.values()) { 
            
            FormulaEval.FormulaInstance formula = Formula.builder()
                                                         .withReturnType(FormulaEval.FormulaReturnType.Boolean)
                                                         .withType(sobjType)
                                                         .withFormula(scf.reduivy__Criteria__c)
                                                         .build();
            formulaMap.put(scf.Id, formula);

        }

        return formulaMap;
    }

    /**
     * @description get the sobject list to be evaluated for the formula
     * @param  sobjList    list of sobject from the trigger
     * @param  formulaList formula list
     * @return             list of sobject to be evaluated
     */
    private List<SObject> getSobjToEvaluate(List<SObject> sobjList, List<FormulaEval.FormulaInstance> formulaList) {
        List<SObject> sObjectToEvaluateList;

        Set<String> allReferencedFieldsSet = new Set<String>();

        for(FormulaEval.FormulaInstance referencedFieldsSet : formulaList) {
            allReferencedFieldsSet.addAll(referencedFieldsSet.getReferencedFields());
        }
        for(String referencedField : allReferencedFieldsSet) {
            if(referencedField.contains('.')) {
                parentRecordsAreReferred = true;
                break;
            }
        }

        if(parentRecordsAreReferred) {
            sObjectToEvaluateList = new List<SObject>();
            String objectName = sobjList[0].getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName();
            String queryString = 'SELECT ' + String.join(allReferencedFieldsSet, ', ') + 
                                ' FROM ' + objectName + 
                                ' WHERE Id IN :sobjectList';

            Map<String, Object> bindMap = new Map<String, Object> {
                'sobjectList' => (new Map<Id, SObject> (sobjList)).keySet()
            };

            Map<String, Set<String>> flsFields = new Map<String, Set<String>>{
                objectName => allReferencedFieldsSet
            };
            
            for(SObject sobj : REDU_SystemMode_UTIL.doQuery(queryString, bindMap, flsFields)) {
                sObjectToEvaluateList.add(sobj);
            }
        } else {
            sObjectToEvaluateList = sobjList;
        }

        return sObjectToEvaluateList;
    }
}