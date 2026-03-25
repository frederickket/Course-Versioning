/**
 * @author      WDCi (XW)
 * @date        July 2025
 * @group       Application Scoring 
 * @description 
 * @changehistory
 * ISS-002506 31-07-2025 XW - new class
 */

public without sharing class SOBJ_IndividualScoreEvaluation_EXE extends REDU_TriggerExecutable {
    
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
                validateEvaluation(newMap, oldMap, sobjResult);
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
                validateEvaluation(newMap, oldMap, sobjResult);
            }
        }
    }

    /**
     * @description validate the evaluation and calculate the score
     * @param
     * @return void
     */
    private void validateEvaluation(Map<Id, SObject> sobjMap, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        //find the created individual score and related individual score details where score logic != null
        String objectLookupField = REDU_Metadata_UTIL.getObjectLookupField(ISC_Helper.getApiName(), sobjResult.getName());

        List<reduivy__Individual_Score__c> iscList = getIndividualScore(sobjMap.keySet(), objectLookupField);

        //get all the fields that are referred in the formula.
        Set<String> referenceFields = new Set<String>();
        Map<Id, FormulaEval.FormulaInstance> isdToFormulaMap = new Map<Id, FormulaEval.FormulaInstance>();
        Map<Id, SObject> isdToSobjMap = new Map<Id, SObject>();
        Map<Id, reduivy__Individual_Score_Detail__c> isdMap = new Map<Id, reduivy__Individual_Score_Detail__c>();
        for(reduivy__Individual_Score__c isc : iscList) {
            SObject sobj = sobjMap.get((Id)isc.get(objectLookupField));
            
            for(reduivy__Individual_Score_Detail__c isd : isc.reduivy__Individual_Score_Details__r) {
                if(String.isBlank(isd.reduivy__Score_Logic__c)) {
                    continue;
                }

                try {
                    FormulaEval.FormulaInstance formulaInstance = Formula.builder().withReturnType(FormulaEval.FormulaReturnType.DECIMAL)
                                                                    .withType(sobjResult.getSObjectType())
                                                                    .withFormula(isd.reduivy__Score_Logic__c)
                                                                    .build();

                    referenceFields.addAll(formulaInstance.getReferencedFields());
                    isdToFormulaMap.put(isd.Id, formulaInstance);
                    isdToSobjMap.put(isd.Id, sobj);
                    isdMap.put(isd.Id, isd);

                } catch (System.FormulaValidationException exp) {
                    String errorMsg = String.format(Label.FormulaEval_Wrong_Result_Data_Type_Number, new List<String> {isd.reduivy__Score_Logic__c});
                    sobj.addError(exp.getMessage());    
                    
                    
                }


            }
        }

        //if there are parent records being referred, query the parent records
        Map<Id, SObject> sObjectToEvaluateMap = getSObjectToEvaluateMap(sobjMap.values(), referenceFields);
        
        //calculate the score based on the formula 
        Map<Id, Decimal> scoreMap = new Map<Id, Decimal>();
        for(Id isdId : isdToFormulaMap.keySet()) {
            FormulaEval.FormulaInstance formulaInstance = isdToFormulaMap.get(isdId);
            SObject sobj = sObjectToEvaluateMap.get(isdToSobjMap.get(isdId).Id);
            if(sobj == null) {
                continue;
            } 

        
            //check if the referenced field of this sobj is changed
            SObject oldSObj = oldMap.get(sobj.Id);
            if(oldSObj != null) {
                Boolean referencedFieldHasChanged = false;
                for(String field : formulaInstance.getReferencedFields()) {
                    if(field.contains('.') || oldSObj.get(field) != sobj.get(field)) {
                        referencedFieldHasChanged = true;
                        break;
                    }
                }

                //check if the score is evaluated before. if no, we evaluate the score
                Boolean scoreIsEvalautedBefore = isdMap.get(isdId).reduivy__Score__c != null;

                if(!referencedFieldHasChanged && scoreIsEvalautedBefore) {
                    continue;
                }
            }
            Decimal score = (Decimal) formulaInstance.evaluate(sobj);
            scoreMap.put(isdId, score);
        }

        REDU_Logging_UTIL.debugJsonString('SOBJ_IndividualScoreEvaluation_EXE :: scoreMap', scoreMap);

        //get weightage and max score
        List<reduivy__Individual_Score_Detail__c> isdListToUpdate = new List<reduivy__Individual_Score_Detail__c>();
        for(Id isdId : scoreMap.keySet()) {
            Decimal score = scoreMap.get(isdId) ?? 0;
            reduivy__Individual_Score_Detail__c isd = isdMap.get(isdId);
            Decimal weightage = isd.reduivy__Weight__c;
            Decimal maxScore = isd.reduivy__Max_Score__c;
            Decimal weightedScore = 0;

            if(weightage == null) {
                isdToSobjMap.get(isdId).addError(Label.Required_Weight);
                continue;
            }

            //calculate the weighted score 
            if (maxScore == null) {
                weightedScore = score * weightage / 100.0;
            } else if (maxScore != null) {
                weightedScore = Math.min(score * weightage / 100.0, maxScore);
            }
            
            //update if weighted score or score is updated
            if(isd.reduivy__Weighted_Score__c != weightedScore || isd.reduivy__Score__c != score) {
                isdListToUpdate.add(
                    new reduivy__Individual_Score_Detail__c(
                        Id = isdId, 
                        reduivy__Score__c = score,
                        reduivy__Weighted_Score__c = weightedScore
                    )
                );
            }
        }

        if(!isdListToUpdate.isEmpty()) {
            REDU_SystemMode_UTIL.doUpdate(isdListToUpdate, isdToSobjMap, 'Id', false);
        }
    }

    /**
     * @description get the related individual scores of the updated sobject
     * @param  sobjIdSet         set of sobject id
     * @param  objectLookupField the object lookup field to the sobject
     * @return                   list of individual score
     */
    private List<reduivy__Individual_Score__c> getIndividualScore(Set<Id> sobjIdSet, String objectLookupField) {
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();
        
        Set<String> isdFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Parent_Score_Detail__c',
            'reduivy__Study_Scoring_Criteria__c',
            'reduivy__Individual_Requirement__c',
            'reduivy__Study_Requirement__c',
            'reduivy__Score_Logic__c',
            'reduivy__Weight__c',
            'reduivy__Max_Score__c',
            'reduivy__Weighted_Score__c',
            'reduivy__Score__c'
        };


        String isdQuery = 'SELECT ' + String.join(isdFields, ', ')
                       + ' FROM reduivy__Individual_Score_Details__r'
                       + ' WHERE reduivy__Status__c = :isdStatusActive';

        Set<String> iscFields = new Set<String> {
            'Id',
            'Name',
            'reduivy__Study_Scoring_Config__c',
            'reduivy__Total_Score__c',
            objectLookupField
        };

        String iscQuery = 'SELECT ' + String.join(iscFields, ', ')
                       + ', (' + isdQuery + ')'
                       + ' FROM ' + ISC_Helper.getApiName()
                       + ' WHERE reduivy__Status__c = :iscStatusActive'
                       + ' AND ' + objectLookupField + ' IN :sobjIdSet';

        Map<String, Object> bindMap = new Map<String, Object>{
            'isdStatusActive' => ISD_Helper.STATUS_ACTIVE,
            'iscStatusActive' => ISC_Helper.STATUS_ACTIVE,
            'sobjIdSet' => sobjIdSet
        };

        Map<String, Set<String>> flsMap = new Map<String, Set<String>>{
            ISC_Helper.getApiName() => iscFields,
            ISD_Helper.getApiName() => isdFields
        };

        for(reduivy__Individual_Score__c isc : (List<reduivy__Individual_Score__c>) REDU_SystemMode_UTIL.doQuery(iscQuery, bindMap, flsMap)) {
            iscList.add(isc);
        }

        return iscList;
    }

    /**
     * @description get the map of the sobject for evaluating the formula
     * @param  referenceFields referenced fields of the formula
     * @return                 Map<Id, SObject>
     */
    private Map<Id, SObject> getSObjectToEvaluateMap(List<SObject> sobjList, Set<String> referenceFields) {
        Map<Id, SObject> sObjectToEvaluateMap;
        if(referenceFields != null && !referenceFields.isEmpty()) {
            Boolean queryParentRecordsAreNeeded = false;
            for(String referencedField : referenceFields) {
                if(referencedField.contains('.')) {
                    queryParentRecordsAreNeeded = true;
                    break;
                }
            }

            if(queryParentRecordsAreNeeded) {
                Schema.SObjectType originObjectType = sobjList[0].getSObjectType();
                Map<String, Set<String>> flsMap = new Map<String, Set<String>>();
                
                for(String field : referenceFields) {
                    if(field.contains('.')) {
                        Schema.DescribeFieldResult dfr = REDU_Datatable_UTIL.getFieldDescribe(field, originObjectType);
                        String parentObjectName = dfr.getSObjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName();
                        if(!flsMap.containsKey(parentObjectName)) {
                            flsMap.put(parentObjectName, new Set<String>());
                        }
                        flsMap.get(parentObjectName).add(dfr.getName());
                    }
                }
                sObjectToEvaluateMap = new Map<Id, SObject>();
                String queryString = 'SELECT ' + String.join(referenceFields, ', ') + 
                                    ' FROM ' + originObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getName() + 
                                    ' WHERE Id IN :sobjList';

                Map<String, Object> bindMap = new Map<String, Object> {
                    'sobjList' => sobjList
                };

                for(SObject sobj : REDU_SystemMode_UTIL.doQuery(queryString, bindMap, flsMap)) {
                    sObjectToEvaluateMap.put(sobj.Id, sobj);
                }
            } else {
                sObjectToEvaluateMap = new Map<Id, SObject>(sobjList);
            }
        } else {
            sObjectToEvaluateMap = new Map<Id, SObject>(sobjList);
        }

        return sObjectToEvaluateMap;
    }



}