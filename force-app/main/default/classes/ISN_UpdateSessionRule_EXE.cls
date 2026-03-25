/**
 * @author      WDCi (XW)
 * @date        Sep 2024
 * @group       Trigger
 * @description Update the Individual Enrollment Study Session Enrollment Rules Status and Study Session Enrollment Rules Result 
 *              based on the Study Session Enrollment Rules after an Individual Session Enrollment is inserted / updated / deleted / undeleted
 * @changehistory
 * ISS-002070 04-09-2024 XW - create new class
 */
public without sharing class ISN_UpdateSessionRule_EXE extends REDU_TriggerExecutable {
    
    private static String sserLabel = reduivy__Study_Offering__c.fields.reduivy__Study_Session_Enrollment_Rule__c.getDescribe().getLabel();
    private static String invalidRuleMessage = String.format(Label.Invalid_Study_Session_Enrollment_Rule, new List<String> {sserLabel, SOF_Helper.getObjectLabel()});

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

            List<String> positiveStatuses = getPositiveStatuses();
            List<reduivy__Individual_Session_Enrollment__c> validIsnList = new List<reduivy__Individual_Session_Enrollment__c>();

            for (reduivy__Individual_Session_Enrollment__c objNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {
                if (positiveStatuses.contains(objNew.reduivy__Enrollment_Status__c) && 
                    objNew.RecordTypeId == ISN_Helper.getStudentRecordTypeId()
                ){

                    validIsnList.add(objNew);
                }
            }

            if(!validIsnList.isEmpty()){
                updateRulesStatusAndResult(validIsnList);
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

            List<String> positiveStatuses = getPositiveStatuses();
            List<reduivy__Individual_Session_Enrollment__c> validIsnList = new List<reduivy__Individual_Session_Enrollment__c>();

            for (reduivy__Individual_Session_Enrollment__c objNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {
                reduivy__Individual_Session_Enrollment__c objOld = (reduivy__Individual_Session_Enrollment__c) oldMap.get(objNew.Id);

                if (objNew.RecordTypeId == ISN_Helper.getStudentRecordTypeId() &&
                    objNew.reduivy__Enrollment_Status__c != objOld.reduivy__Enrollment_Status__c &&
                    (
                        (positiveStatuses.contains(objNew.reduivy__Enrollment_Status__c) && !positiveStatuses.contains(objOld.reduivy__Enrollment_Status__c)) ||
                        (positiveStatuses.contains(objOld.reduivy__Enrollment_Status__c) && !positiveStatuses.contains(objNew.reduivy__Enrollment_Status__c))
                    )                    
                ) {

                    validIsnList.add(objNew);
                }
            }

            if(!validIsnList.isEmpty()){
                updateRulesStatusAndResult(validIsnList);
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

            List<String> positiveStatuses = getPositiveStatuses();
            List<reduivy__Individual_Session_Enrollment__c> validIsnList = new List<reduivy__Individual_Session_Enrollment__c>();

            for (reduivy__Individual_Session_Enrollment__c objOld : (List<reduivy__Individual_Session_Enrollment__c>) oldList) {

                if (positiveStatuses.contains(objOld.reduivy__Enrollment_Status__c) && 
                    objOld.RecordTypeId == ISN_Helper.getStudentRecordTypeId()
                ) {

                    validIsnList.add(objOld);
                }
            }

            if(!validIsnList.isEmpty()){
                updateRulesStatusAndResult(validIsnList);
            }
        }
    }

    /**
     * @description AfterUndelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUndelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<String> positiveStatuses = getPositiveStatuses();
            List<reduivy__Individual_Session_Enrollment__c> validIsnList = new List<reduivy__Individual_Session_Enrollment__c>();

            for (reduivy__Individual_Session_Enrollment__c objNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {

                if (positiveStatuses.contains(objNew.reduivy__Enrollment_Status__c) && 
                    objNew.RecordTypeId == ISN_Helper.getStudentRecordTypeId()
                ) {

                    validIsnList.add(objNew);
                }
            }

            if(!validIsnList.isEmpty()){
                updateRulesStatusAndResult(validIsnList);
            }
        }
    }
	
    /**
     * @description update the session status and result in isn
     * @param  updatedIsnList list of updated isn (created/updated/deleted/undeleted)
     */
    public void updateRulesStatusAndResult(List<reduivy__Individual_Session_Enrollment__c> updatedIsnList){

        Map<Id, List<reduivy__Individual_Session_Enrollment__c>> ienToIsnMap = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();
        for(reduivy__Individual_Session_Enrollment__c isn : updatedIsnList) {
            if(String.isNotBlank(isn.reduivy__Individual_Enrollment__c)){
                if(ienToIsnMap.containsKey(isn.reduivy__Individual_Enrollment__c)){
                    ienToIsnMap.get(isn.reduivy__Individual_Enrollment__c).add(isn);
                } else {
                    ienToIsnMap.put(isn.reduivy__Individual_Enrollment__c, new List<reduivy__Individual_Session_Enrollment__c>{isn});
                }
            }
        }
  
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();
        //get the ien and inprogress & completed isn
        for (reduivy__Individual_Enrollment__c ien : [SELECT Id, 
            Name, 
            reduivy__Study_Offering__c,
            reduivy__Study_Offering__r.reduivy__Study_Session_Enrollment_Rule__c,
            reduivy__Study_Session_Enrollment_Rule_Result__c,
            reduivy__Study_Session_Enrollment_Rule_Status__c,
            (
                SELECT Id,
                Name,
                reduivy__Study_Session__c,
                reduivy__Study_Session__r.reduivy__Type__c
                FROM reduivy__Individual_Session_Enrollments__r
                WHERE reduivy__Enrollment_Status__c IN :getPositiveStatuses()
            )
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienToIsnMap.keySet()
            WITH USER_MODE
        ]){
            ienList.add(ien);
        }

        List<reduivy__Individual_Enrollment__c> ienToUpdate = new List<reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c ien: ienList){
            
            Map<String, Integer> sessionRuleMap = new Map<String, Integer>();
            if(String.isBlank(ien.reduivy__Study_Offering__r.reduivy__Study_Session_Enrollment_Rule__c)){
                continue;
            }
            
            //calculate rules
            sessionRuleMap = calculateExpectedRule(ien.reduivy__Study_Offering__r.reduivy__Study_Session_Enrollment_Rule__c);
            REDU_Logging_UTIL.debug('sessionRuleMap', sessionRuleMap);
            
            //calculate result
            Map<String, Integer> sessionRuleResultMap = new Map<String, Integer>();
            if(!sessionRuleMap.isEmpty()){
                sessionRuleResultMap = calculateActualResult(ien);
                REDU_Logging_UTIL.debug('sessionRuleResultMap', sessionRuleResultMap);
            }
            
            if(!sessionRuleMap.isEmpty()){
                
                //calculate status
                String newRuleStatus = ien.reduivy__Individual_Session_Enrollments__r.isEmpty() 
                    ? IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT 
                    : IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_SUFFICIENT;

                for(String expectedSessionType : sessionRuleMap.keySet()){
                    Integer expectedValue = sessionRuleMap.get(expectedSessionType);

                    if(sessionRuleResultMap.containsKey(expectedSessionType)){
                        if(newRuleStatus != IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT){
                            Integer actualValue = sessionRuleResultMap.get(expectedSessionType);
                            if(actualValue < expectedValue) {
                                newRuleStatus = IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT;
                            } else if(actualValue > expectedValue) {
                                newRuleStatus = IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER;
                            }
                        }
                    } else {
                        newRuleStatus = IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT;
                    }
                }
                
                REDU_Logging_UTIL.debug('newRuleStatus', newRuleStatus);
                
                //update result and status in the ien
                List<String> newRuleResultForEachSse = new List<String>();
                for(String type : sessionRuleResultMap.keySet()){
                    newRuleResultForEachSse.add(type + '=' + sessionRuleResultMap.get(type));
                }
                String newRuleResult = String.join(newRuleResultForEachSse, ';');
                
                if(ien.reduivy__Study_Session_Enrollment_Rule_Result__c != newRuleResult){
                    ienToUpdate.add(new reduivy__Individual_Enrollment__c(
                        Id = ien.Id,
                        reduivy__Study_Session_Enrollment_Rule_Result__c = newRuleResult,
                        reduivy__Study_Session_Enrollment_Rule_Status__c = newRuleStatus
                    ));
                }
            }
        }

        REDU_Logging_UTIL.debug('ienToUpdate', ienToUpdate);
        REDU_Database_UTIL.doUpdate(ienToUpdate, ienToIsnMap, 'reduivy__Individual_Enrollment__c', false);
    }

    /**
     * @description calculate the expected rule from the study offering 
     * @param  expectedRule the enrollment rules, located in reduivy__Study_Offering__r.reduivy__Study_Session_Enrollment_Rule__c
     * @return              return map of session type and number of session type should be enrolled
     */
    private Map<String, Integer> calculateExpectedRule(String expectedRule) {
        Map<String, Integer> sessionRuleMap = new Map<String, Integer>();
        List<String> sessionRuleList = expectedRule.split(';');
        for(String sessionRule : sessionRuleList){
            if(String.isNotBlank(sessionRule) && sessionRule.contains('=')){
                sessionRule = sessionRule.trim();
                List<String> sessionRuleValue = sessionRule.split('=');
                try{
                    if(sessionRuleValue.size() == 2){
                        sessionRuleMap.put(sessionRuleValue[0], Integer.valueOf(sessionRuleValue[1]));
                    } else {
                        throw new REDU_ApplicationException(invalidRuleMessage);
                    }
                }catch(Exception exp){
                    throw new REDU_ApplicationException(invalidRuleMessage);
                }
            }
        }

        return sessionRuleMap;

    }

    /**
     * @description Get the actual session rule result of the enrolled IEN
     * @param  ien the enrolled IEN
     * @return     Map of session type and number of session type enrolled
     */
    private Map<String, Integer> calculateActualResult(reduivy__Individual_Enrollment__c ien){
        Map<String, Integer> sessionRuleResultMap = new Map<String, Integer>();
        
        for(reduivy__Individual_Session_Enrollment__c isn : ien.reduivy__Individual_Session_Enrollments__r){
            String type = isn.reduivy__Study_Session__r.reduivy__Type__c;
            if(sessionRuleResultMap.containsKey(type)) {
                sessionRuleResultMap.put(type, sessionRuleResultMap.get(type) + 1);
            } else {
                sessionRuleResultMap.put(type, 1);
            }
        }
        
        return sessionRuleResultMap;
    }

    /**
     * @description Get the statuses that counts as a Positive status (Complete, In progress)
     * @return   All the positive statuses
     */
    private List<String> getPositiveStatuses(){
        List<String> positiveStatuses = new List<String>();
        positiveStatuses.addAll(ISN_Helper.getCompletedStatuses());
        positiveStatuses.addAll(ISN_Helper.getInProgressStatuses());
        return positiveStatuses;
    }

}