/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Trigger Executable
 * @description This is to validate the max attempt of the related ien when the ips is set to enrolled
 * @changehistory
 * ISS-002231 08-04-2025 Lean - Max attempt configuration and validation
 * ISS-002447 13-05-2025 Lean - Max attempt indication
 */

public inherited sharing class IPS_ValidateMaxAttempt_EXE extends REDU_TriggerExecutable {

    /*
     * @description Individual plan structure unit record type Id
     */
    private static final Id IPS_UNIT_RTID = IPS_Helper.getUnitRecordTypeId();

    /**
     * @description IPS Unit not started statuses
     */
    private static final List<String> IPS_NOTSTARTED_STATUSES = IPS_Helper.getUnitNotStartedStatuses();

    /**
     * @description IPS Unit in progress statuses
     */
    private static final List<String> IPS_INPROGRESS_STATUSES = IPS_Helper.getUnitInProgressStatuses();

    /**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        List<reduivy__Individual_Plan_Structure__c> workingList = new List<reduivy__Individual_Plan_Structure__c>();
        List<reduivy__Individual_Plan_Structure__c> resetList = new List<reduivy__Individual_Plan_Structure__c>();
        
        for (reduivy__Individual_Plan_Structure__c ipsu : (List<reduivy__Individual_Plan_Structure__c>) newList) {
            if (ipsu.RecordTypeId == IPS_UNIT_RTID && 
                String.isNotBlank(ipsu.reduivy__Target_Unit_Id__c) &&
                String.isNotBlank(ipsu.reduivy__Master_Individual_Program_Enrollment_Id__c)
            ) {
                if (IPS_INPROGRESS_STATUSES.contains(ipsu.reduivy__Status__c)) {
                    workingList.add(ipsu);
                } else if (IPS_NOTSTARTED_STATUSES.contains(ipsu.reduivy__Status__c)) {
                    resetList.add(ipsu);
                }
            }
        }

        if (!resetList.isEmpty()) {
            resetAttemptLimitInfo(resetList);
        }

        if (!workingList.isEmpty()) {
            validateMaxAttempt(workingList);
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
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        List<reduivy__Individual_Plan_Structure__c> workingList = new List<reduivy__Individual_Plan_Structure__c>();
        List<reduivy__Individual_Plan_Structure__c> resetList = new List<reduivy__Individual_Plan_Structure__c>();

        for (reduivy__Individual_Plan_Structure__c ipsu : (List<reduivy__Individual_Plan_Structure__c>) newList) {
            reduivy__Individual_Plan_Structure__c ipsuOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsu.Id);

            if (ipsu.RecordTypeId == IPS_UNIT_RTID && 
                String.isNotBlank(ipsu.reduivy__Target_Unit_Id__c) &&
                String.isNotBlank(ipsu.reduivy__Master_Individual_Program_Enrollment_Id__c)
            ) {
                if (IPS_INPROGRESS_STATUSES.contains(ipsu.reduivy__Status__c) &&
                    (
                        ipsu.reduivy__Target_Unit_Id__c != ipsuOld.reduivy__Target_Unit_Id__c ||
                        ipsu.reduivy__Individual_Enrollment__c != ipsuOld.reduivy__Individual_Enrollment__c ||
                        (ipsu.reduivy__Status__c != ipsuOld.reduivy__Status__c && !IPS_INPROGRESS_STATUSES.contains(ipsuOld.reduivy__Status__c))
                    )
                ) {
                    workingList.add(ipsu);

                } else if (IPS_NOTSTARTED_STATUSES.contains(ipsu.reduivy__Status__c) &&
                    !IPS_NOTSTARTED_STATUSES.contains(ipsuOld.reduivy__Status__c) &&
                    ipsu.reduivy__Status__c != ipsuOld.reduivy__Status__c
                ) {
                    resetList.add(ipsu);
                }
            }
        }

        if (!resetList.isEmpty()) {
            resetAttemptLimitInfo(resetList);
        }

        if (!workingList.isEmpty()) {
            validateMaxAttempt(workingList);
        }
    }

    /**
     * @description To reset the attempt limit status is changed to not started
     * @param ipsuList
     */
    private void resetAttemptLimitInfo(List<reduivy__Individual_Plan_Structure__c> ipsuList) {

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            ipsu.reduivy__Attempt_Limit_Status__c = null;
        }
    }

    /**
     * @description To set the attempt limit, attempt limit status and throw error if the study enrollment setting's action is blocked when the ips status is changed to In Progress
     * @param ipsuList
     */
    private void validateMaxAttempt(List<reduivy__Individual_Plan_Structure__c> ipsuList) {

        Set<Id> sunIds = new Set<Id>();
        Set<Id> ipeIds = new Set<Id>();
        Set<Id> ienIds = new Set<Id>();
        Set<Id> eduInstIds = new Set<Id>();
        Set<Id> spgIds = new Set<Id>();

        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            if (String.isNotBlank(ipsu.reduivy__Target_Unit_Id__c)) {
                sunIds.add(ipsu.reduivy__Target_Unit_Id__c);
            }

            if (String.isNotBlank(ipsu.reduivy__Master_Individual_Program_Enrollment_Id__c)) {
                ipeIds.add(ipsu.reduivy__Master_Individual_Program_Enrollment_Id__c);
            }

            if (String.isNotBlank(ipsu.reduivy__Individual_Enrollment__c)) {
                ienIds.add(ipsu.reduivy__Individual_Enrollment__c);
            }
        }

        Map<String, Object> ipeBindParams = new Map<String, Object>();
        ipeBindParams.put('ipeIds', ipeIds);

        String ipeSoql = 'SELECT Id, ' +
            ' reduivy__Study_Program__c, ' +
            ' reduivy__Study_Program__r.reduivy__Educational_Institution__c ' +
            ' FROM reduivy__Individual_Program_Enrollment__c ' +
            ' WHERE Id IN: ipeIds';
        
        for (reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>)Database.queryWithBinds(ipeSoql, ipeBindParams, AccessLevel.USER_MODE)) {

            if (String.isNotBlank(ipe?.reduivy__Study_Program__c)) {
                spgIds.add(ipe.reduivy__Study_Program__c);
            }

            if (String.isNotBlank(ipe?.reduivy__Study_Program__r?.reduivy__Educational_Institution__c)) {
                eduInstIds.add(ipe.reduivy__Study_Program__r.reduivy__Educational_Institution__c);
            }

            ipeMap.put(ipe.Id, ipe);
        }

        Map<String, Object> ienBindParams = new Map<String, Object>();
        ienBindParams.put('ienIds', ienIds);

        String ienSoql = 'SELECT Id, ' +
            ' reduivy__Attempt_Number__c, ' +
            ' reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c, ' +
            ' reduivy__Study_Unit__r.reduivy__Unit_Code__c ' +
            ' FROM reduivy__Individual_Enrollment__c ' +
            ' WHERE Id IN: ienIds ';

        for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>)Database.queryWithBinds(ienSoql, ienBindParams, AccessLevel.USER_MODE)) {
            ienMap.put(ien.Id, ien);
        }

        Map<String, reduivy__Study_Enrollment_Setting__c> sesMap = SES_Helper.getStudyEnrollmentSettings(
            SES_Helper.TYPE_UNIT_MAX_ATTEMPT,
            eduInstIds,
            spgIds,
            sunIds,
            ipeIds
        );

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            if (ipeMap.containsKey(ipsu.reduivy__Master_Individual_Program_Enrollment_Id__c) && 
                ienMap.containsKey(ipsu.reduivy__Individual_Enrollment__c)
            ) {
                reduivy__Individual_Program_Enrollment__c ipe = ipeMap.get(ipsu.reduivy__Master_Individual_Program_Enrollment_Id__c);
                reduivy__Individual_Enrollment__c ien = ienMap.get(ipsu.reduivy__Individual_Enrollment__c);

                String eduInstId = ipe?.reduivy__Study_Program__r?.reduivy__Educational_Institution__c;
                String spgId = ipe?.reduivy__Study_Program__c;
                String sunId = ipsu.reduivy__Target_Unit_Id__c;
                String ipeId = ipe.Id;

                //preparing potential matching keys by priority
                List<String> matchingKeys = new List<String>();
                matchingKeys.add(SES_Helper.generateIdentifier(new List<String>{ipeId, sunId}));
                matchingKeys.add(SES_Helper.generateIdentifier(new List<String>{ipeId}));
                matchingKeys.add(SES_Helper.generateIdentifier(new List<String>{eduInstId, spgId, sunId}));
                matchingKeys.add(SES_Helper.generateIdentifier(new List<String>{eduInstId, sunId}));
                matchingKeys.add(SES_Helper.generateIdentifier(new List<String>{eduInstId, spgId}));
                matchingKeys.add(SES_Helper.generateIdentifier(new List<String>{eduInstId}));

                //loop through all the settings, but we will only get the first one found
                for (String matchKey : matchingKeys) {
                    if (sesMap.containsKey(matchKey)) {
                        reduivy__Study_Enrollment_Setting__c ses = sesMap.get(matchKey);

                        if (ien.reduivy__Attempt_Number__c != null && 
                            ses.reduivy__Number__c != null
                        ) {
                            Decimal ienAttemptNumber = ien.reduivy__Attempt_Number__c;
                            Decimal sesAttemptLimit = ses.reduivy__Number__c;

                            ipsu.reduivy__Attempt_Limit__c = sesAttemptLimit;
                            
                            if (ienAttemptNumber > sesAttemptLimit) {
                                ipsu.reduivy__Attempt_Limit_Status__c = IPS_Helper.ATTEMPT_LIMIT_STATUS_EXCEEDEDLIMIT;
                            } else if (ienAttemptNumber == sesAttemptLimit) {
                                ipsu.reduivy__Attempt_Limit_Status__c = IPS_Helper.ATTEMPT_LIMIT_STATUS_ATLIMIT;
                            } else {
                                ipsu.reduivy__Attempt_Limit_Status__c = IPS_Helper.ATTEMPT_LIMIT_STATUS_BELOWLIMIT;
                            }

                            if (ses.reduivy__Action__c == SES_Helper.ACTION_BLOCK && 
                                ipsu.reduivy__Attempt_Limit_Status__c == IPS_Helper.ATTEMPT_LIMIT_STATUS_EXCEEDEDLIMIT
                            ) {
                                String unitCode = ien?.reduivy__Study_Offering__r?.reduivy__Study_Unit__r.reduivy__Unit_Code__c ?? ien.reduivy__Study_Unit__r.reduivy__Unit_Code__c;
                                String errorMsg = String.format(Label.Unit_Enrollment_Exceeded_Max_Attempt_Allowed, new List<String>{unitCode, String.valueOf(ses.reduivy__Number__c.intValue())});

                                ipsu.addError(errorMsg);
                            }
                        }

                        //we stop and break if there is one setting found
                        break;
                    }
                }
            }
        }
    }
}