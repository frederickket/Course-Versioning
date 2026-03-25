/**
 * @author      WDCi (Jordan)
 * @date        Jan 2025
 * @group       Trigger Executable
 * @description To perform the sum of both Credits Required and Credits Earned for all child individual program enrollments to master individual program enrollment
 * @changehistory
 * ISS-002203 16-01-2025 Jordan - new class
 */
public without sharing class IPE_MasterIpeRollup_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual program enrollment child record type Id
     */
    private static final Id IPE_CHILD_RECORDTYPE_ID = IPE_Helper.getChildEnrollmentRecordTypeId();

    /**
     * @description Individual program enrollment positive statuses
     */
    private static final List<String> IPE_POSITIVE_STATUSES = IPE_Helper.getPositiveStatuses();
    
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

            List<reduivy__Individual_Program_Enrollment__c> ipeToRollup = new List<reduivy__Individual_Program_Enrollment__c>();
            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                if (isRollupCriteriaMet(ipeNew, null)) {
                    ipeToRollup.add(ipeNew);
                }
            }

            if (!ipeToRollup.isEmpty()) {
                rollupToMasterIpe(ipeToRollup);
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

            List<reduivy__Individual_Program_Enrollment__c> ipeToRollup = new List<reduivy__Individual_Program_Enrollment__c>();

            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                reduivy__Individual_Program_Enrollment__c ipeOld = (reduivy__Individual_Program_Enrollment__c) oldMap.get(ipeNew.Id);

                if (isRollupCriteriaMet(ipeNew, ipeOld)) {
                    ipeToRollup.add(ipeNew);
                }
            }

            if (!ipeToRollup.isEmpty()) {
                rollupToMasterIpe(ipeToRollup);
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

            List<reduivy__Individual_Program_Enrollment__c> ipeToRollup = new List<reduivy__Individual_Program_Enrollment__c>();
            for (reduivy__Individual_Program_Enrollment__c ipeOld : (List<reduivy__Individual_Program_Enrollment__c>) oldList) {
                if (isRollupCriteriaMet(null, ipeOld)) {
                    ipeToRollup.add(ipeOld);
                }
            }

            if (!ipeToRollup.isEmpty()) {
                rollupToMasterIpe(ipeToRollup);
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

            List<reduivy__Individual_Program_Enrollment__c> ipeToRollup = new List<reduivy__Individual_Program_Enrollment__c>();
            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                if (isRollupCriteriaMet(ipeNew, null)) {
                    ipeToRollup.add(ipeNew);
                }
            }

            if (!ipeToRollup.isEmpty()) {
                rollupToMasterIpe(ipeToRollup);
            }
        }
    }

    /**
     * @description This is to validate the enrollment status, credits earned, and completion requirement of the indvidual program enrollment to determine whether a rollup is necessary.
     * @param ipeNew New individual program enrollment
     * @param ipeOld Old individual program enrollment
     * @return Boolean
     */
    private Boolean isRollupCriteriaMet(reduivy__Individual_Program_Enrollment__c ipeNew, reduivy__Individual_Program_Enrollment__c ipeOld) {
        // Early returns for null checks
        if (ipeNew == null && ipeOld == null) {
            return false;
        }
    
        // Check if the record is a child (based on either new or old record type)
        Boolean isChild = (ipeNew?.RecordTypeId == IPE_CHILD_RECORDTYPE_ID) || (ipeOld?.RecordTypeId == IPE_CHILD_RECORDTYPE_ID);
    
        // Check if completion requirement is mandatory (on either new or old record)
        Boolean isMandatory = (ipeNew?.reduivy__Completion_Requirement__c == IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY) ||
                              (ipeOld?.reduivy__Completion_Requirement__c == IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY);
    
        // Enrollment status logic (simplified for better readability)
        Boolean wasEnrolledCompleted = ipeOld != null && IPE_POSITIVE_STATUSES.contains(ipeOld.reduivy__Enrollment_Status__c);
        Boolean isEnrolledCompleted = (ipeNew != null && IPE_POSITIVE_STATUSES.contains(ipeNew.reduivy__Enrollment_Status__c)) || 
                                      (ipeOld != null && IPE_POSITIVE_STATUSES.contains(ipeOld.reduivy__Enrollment_Status__c));
    
        // Credit conditions
        Boolean hasCreditsRequired = (ipeNew?.reduivy__Credits_Required__c != null && ipeNew.reduivy__Credits_Required__c != 0) ||
                                     (ipeOld?.reduivy__Credits_Required__c != null && ipeOld.reduivy__Credits_Required__c != 0);
    
        Boolean hasCreditsEarned = (ipeNew?.reduivy__Credits_Earned__c != null && ipeNew.reduivy__Credits_Earned__c != 0) ||
                                   (ipeOld?.reduivy__Credits_Earned__c != null && ipeOld.reduivy__Credits_Earned__c != 0);
    
        // Credit earned or completion requirement changes
        Boolean isCreditsEarnedChanged = ipeNew?.reduivy__Credits_Earned__c != ipeOld?.reduivy__Credits_Earned__c;
        Boolean isCompletionRequirementChanged = ipeNew?.reduivy__Completion_Requirement__c != ipeOld?.reduivy__Completion_Requirement__c;
    
        // Main logic for determining if rollup is necessary
        return isChild && 
               ((isEnrolledCompleted && isMandatory && (hasCreditsRequired || hasCreditsEarned)) || 
                (ipeNew != null && ipeOld != null && (
                    (isEnrolledCompleted && !wasEnrolledCompleted) ||
                    (!isEnrolledCompleted && wasEnrolledCompleted) ||
                    (isEnrolledCompleted && (isCreditsEarnedChanged || isCompletionRequirementChanged))
                )));
    }
	
    /**
     * @description Rollup the credits required and credits earned to master individual program enrollment
     * @param ipeList List of individual program enrollments
     * @return void
     */
    private void rollupToMasterIpe(List<reduivy__Individual_Program_Enrollment__c> ipeList) {
        
        Set<Id> contactIds = new Set<Id>();
        Map<Id, List<reduivy__Individual_Program_Enrollment__c>> qualifiedChildIpeByMasterIpeMap = new Map<Id, List<reduivy__Individual_Program_Enrollment__c>>();

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            if (String.isNotBlank(ipe.reduivy__Contact__c) &&
                String.isNotBlank(ipe.reduivy__Master_Enrollment__c)
            ) {
                contactIds.add(ipe.reduivy__Contact__c);

                if (qualifiedChildIpeByMasterIpeMap.containsKey(ipe.reduivy__Master_Enrollment__c)) {
                    qualifiedChildIpeByMasterIpeMap.get(ipe.reduivy__Master_Enrollment__c).add(ipe);
                } else {
                    qualifiedChildIpeByMasterIpeMap.put(ipe.reduivy__Master_Enrollment__c, new List<reduivy__Individual_Program_Enrollment__c>{ipe});
                }
            }
        }

        List<reduivy__Individual_Program_Enrollment__c> masterIpeUpdateList = new List<reduivy__Individual_Program_Enrollment__c>();

        Map<String, Object> masterIpeBindParams = new Map<String, Object>();
        masterIpeBindParams.put('masterIpeIds', qualifiedChildIpeByMasterIpeMap.keySet());
        masterIpeBindParams.put('contactIds', contactIds);

        Set<String> masterIpeFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Additional_Credits_Earned__c',
            'reduivy__Additional_Credits_Required__c'
        };

        Set<String> childIpeFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Completion_Requirement__c',
            'reduivy__Credits_Earned__c',
            'reduivy__Credits_Required__c',
            'reduivy__Enrollment_Status__c'
        };

        String masterIpeQuery = 'SELECT ' + String.join(masterIpeFields, ', ') + ', ' + 
            ' (SELECT ' + String.join(childIpeFields, ', ') +
                ' FROM reduivy__Child_Individual_Program_Enrollments__r) ' +
            ' FROM reduivy__Individual_Program_Enrollment__c ' +
            ' WHERE Id IN: masterIpeIds AND reduivy__Contact__c IN: contactIds '+
            ' FOR UPDATE';

        Map<String, Set<String>> ipeObjectFieldsForFls = new Map<String, Set<String>>();
        Set<String> ipeFields = new Set<String>(masterIpeFields);
        ipeFields.addAll(childIpeFields);
        ipeObjectFieldsForFls.put(IPE_Helper.getApiName(), ipeFields);

        if (!qualifiedChildIpeByMasterIpeMap.isEmpty()) {
            for (reduivy__Individual_Program_Enrollment__c masterIpe : (List<reduivy__Individual_Program_Enrollment__c>) REDU_SystemMode_UTIL.doQuery(masterIpeQuery, masterIpeBindParams, ipeObjectFieldsForFls)) {

                Decimal sumCreditsRequired = 0;
                Decimal sumCreditsEarned = 0;

                for (reduivy__Individual_Program_Enrollment__c childIpe : masterIpe.reduivy__Child_Individual_Program_Enrollments__r) {

                    Decimal creditsRequired = childIpe.reduivy__Credits_Required__c == null ? 0 : childIpe.reduivy__Credits_Required__c;
                    Decimal creditsEarned = childIpe.reduivy__Credits_Earned__c == null ? 0 : childIpe.reduivy__Credits_Earned__c;
                    
                    if (IPE_POSITIVE_STATUSES.contains(childIpe.reduivy__Enrollment_Status__c) && childIpe.reduivy__Completion_Requirement__c == IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY) {
                        sumCreditsRequired += creditsRequired;
                        sumCreditsEarned += creditsEarned;
                    }
                }

                if (sumCreditsRequired != masterIpe.reduivy__Additional_Credits_Required__c ||
                    sumCreditsEarned != masterIpe.reduivy__Additional_Credits_Earned__c
                ) {
                    reduivy__Individual_Program_Enrollment__c masterIpeToUpdate = new reduivy__Individual_Program_Enrollment__c(
                        Id = masterIpe.Id,
                        reduivy__Additional_Credits_Required__c = sumCreditsRequired,
                        reduivy__Additional_Credits_Earned__c = sumCreditsEarned
                    );

                    masterIpeUpdateList.add(masterIpeToUpdate);
                }
            }

            if (!masterIpeUpdateList.isEmpty()) {
                REDU_SystemMode_UTIL.doUpdate(masterIpeUpdateList, qualifiedChildIpeByMasterIpeMap, 'Id', false);
            }
        }
    }
}