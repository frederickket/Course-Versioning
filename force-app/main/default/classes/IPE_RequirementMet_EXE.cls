/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Update the individual plan unit requirement record's requirement met field
 * @changehistory
 * ISS-001662 03-10-2023 dblack - new class
 * ISS-001927 29-03-2024 VTan - Enhance logic to consider requirement met for child IPE
 * ISS-001993 03-07-2024 Lean - fixed unmuteTriggers typo
 * ISS-002155 26-12-2024 XW - we have to query at first to get the ipur, so the trigger is rewritten
 */
public inherited sharing class IPE_RequirementMet_EXE extends REDU_TriggerExecutable {

    /**
     * @description Triggers to mute - this is to avoid duplicate query and processing to revalidate the requirement met checkbox again in IUR_RequirementMet_EXE
     */
    private static final Set<String> TRIGGERS_TO_MUTE = new Set<String>{'IUR_RequirementMet_Before'};
    static final Id IPE_MASTER_ENROLLMENT_RECORD_TYPE_ID = IPE_Helper.getMasterEnrollmentRecordTypeId();

	/**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult) {

        if ((operationType == TriggerOperation.AFTER_UPDATE) && 
            ((REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) || 
             (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)))) {
            
            List<reduivy__Individual_Program_Enrollment__c> newIpeList = (List<reduivy__Individual_Program_Enrollment__c>) newList;
            Map<Id, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();

            for(reduivy__Individual_Program_Enrollment__c ipe : newIpeList) {
                if(ipe.RecordTypeId == IPE_MASTER_ENROLLMENT_RECORD_TYPE_ID) {
                    newIpeMap.put(ipe.Id, ipe);
                }
            }

            //skip if all of the ipe are child ipe
            if(newIpeMap.isEmpty()) {
                return;
            }

            List<reduivy__Individual_Program_Enrollment__c> oldIpeList = (List<reduivy__Individual_Program_Enrollment__c>) oldList;
            Map<Id, reduivy__Individual_Program_Enrollment__c> oldIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>(oldIpeList);

            List<reduivy__Individual_Plan_Unit_Requirement__c> ipurListToBeUpdated = new List<reduivy__Individual_Plan_Unit_Requirement__c>();
            Map<Id, reduivy__Individual_Program_Enrollment__c> ipurId_IpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
            
            Map<String, Schema.SObjectField> sObjectFieldMap = REDU_Metadata_UTIL.describeSObject(IPE_Helper.getApiName()).fields.getMap();
            Set<String> reqTypeSet = new Set<String>{IUR_Helper.REQTYPE_CUSTOM, IUR_Helper.REQTYPE_CREDITS};
            Map<Id, List<reduivy__Individual_Plan_Unit_Requirement__c>> iurMap = IUR_Helper.getIurMap(newIpeMap.keySet(), reqTypeSet);
            
            for(Id masterIpeId : iurMap.keySet()) {
                for(reduivy__Individual_Plan_Unit_Requirement__c ipur : iurMap.get(masterIpeId)) {
                    Boolean reqMet = ipur.reduivy__Requirement_Met__c;
                    if(ipur.reduivy__Requirement_Type__c == IUR_Helper.REQTYPE_CREDITS) {
                        if(newIpeMap.containsKey(masterIpeId)
                            && newIpeMap.get(masterIpeId).reduivy__Credits_Earned__c != oldIpeMap.get(masterIpeId).reduivy__Credits_Earned__c) {

                            reqMet = newIpeMap.get(masterIpeId).reduivy__Credits_Earned__c >= ipur.reduivy__Credits__c;
                        }
                    } else if (ipur.reduivy__Requirement_Type__c == IUR_Helper.REQTYPE_CUSTOM) {
                        if(newIpeMap.containsKey(masterIpeId)
                            && newIpeMap.get(masterIpeId).get(ipur.reduivy__Field_Name__c) != oldIpeMap.get(masterIpeId).get(ipur.reduivy__Field_Name__c)) {

                            reduivy__Individual_Program_Enrollment__c ipe = newIpeMap.get(masterIpeId);
                            Schema.DescribeFieldResult fieldResult = sObjectFieldMap.get(ipur.reduivy__Field_Name__c).getDescribe();
                            Object actualValue = ipe.get(ipur.reduivy__Field_Name__c);
                            String operator = ipur.reduivy__Field_Matching_Operator__c;
                            String expectedValue = ipur.reduivy__Field_Matching_Value__c;

                            try {
                                reqMet = REDU_MatchingOperator_UTIL.calculate(fieldResult.getType(), actualValue, operator, expectedValue);
                            } catch(Exception exp) {
                                String errorMessage = REDU_MatchingOperator_UTIL.getErrorMessage(exp.getMessage(), operator, IUR_Helper.getApiName(), ipur.reduivy__Field_Name__c);
                                throw new REDU_ApplicationException(errorMessage);
                            }
                        }
                    }

                    if(ipur.reduivy__Requirement_Met__c != reqMet) {
                        ipurListToBeUpdated.add(new reduivy__Individual_Plan_Unit_Requirement__c(Id = ipur.Id, reduivy__Requirement_Met__c = reqMet));
                        ipurId_IpeMap.put(ipur.Id, newIpeMap.get(masterIpeId));
                    }
                }
            }

            if (!ipurListToBeUpdated.isEmpty()) {

                //skip the IRU_RequirementMet_EXE before trigger
                REDU_TriggerController.muteTriggers(TRIGGERS_TO_MUTE);

                REDU_Database_UTIL.doUpdate(ipurListToBeUpdated, ipurId_IpeMap, 'Id', false);

                REDU_TriggerController.unmuteTriggers(TRIGGERS_TO_MUTE);
            }

        }
    }
}