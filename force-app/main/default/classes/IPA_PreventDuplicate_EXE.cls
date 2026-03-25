/**
 * @author      WDCi (XiRouh)
 * @date        July 2025
 * @group       
 * @description Trigger to prevent duplicate Individual Program Application records in Salesforce
 * @changehistory
 * ISS-002508 03-07-2025 XiRouh - New Class
 */
public inherited sharing class IPA_PreventDuplicate_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description IPA Active statuses: Draft, Submitted, Reviewing, Approved, Offer, Offer Accepted
     */
    static final List<String> IPA_ACTIVE_STATUSES = IPA_Helper.getActiveStatuses();

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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Program_Application__c> workingList = new List<reduivy__Individual_Program_Application__c>();
            for (reduivy__Individual_Program_Application__c objNew : (List<reduivy__Individual_Program_Application__c>) newList) {
                if(objNew.reduivy__Skip_Duplicate_Rules__c == false && 
                    String.isNotBlank(objNew.reduivy__Application_Status__c) && 
                    IPA_ACTIVE_STATUSES.contains(objNew.reduivy__Application_Status__c) 
                ) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                checkDuplicateIPA(workingList, operationType);
            }
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Individual_Program_Application__c> workingList = new List<reduivy__Individual_Program_Application__c>();
            for (reduivy__Individual_Program_Application__c objNew : (List<reduivy__Individual_Program_Application__c>) newList) {
                reduivy__Individual_Program_Application__c objOld = (reduivy__Individual_Program_Application__c) oldMap.get(objNew.Id);

                if(
                    (
                        objNew.reduivy__Contact__c != objOld.reduivy__Contact__c ||
                        objNew.reduivy__Study_Program__c != objOld.reduivy__Study_Program__c ||
                        objNew.reduivy__Study_Intake__c != objOld.reduivy__Study_Intake__c ||
                        objNew.reduivy__Master_Study_Plan__c != objOld.reduivy__Master_Study_Plan__c ||
                        objNew.reduivy__Skip_Duplicate_Rules__c != objOld.reduivy__Skip_Duplicate_Rules__c ||
                        IPA_ACTIVE_STATUSES.contains(objOld.reduivy__Application_Status__c) != IPA_ACTIVE_STATUSES.contains(objNew.reduivy__Application_Status__c)
                    ) &&
                    (
                        // If the record is currently in an active status and the skip flag is not checked, 
                        // we will proceed to check for duplicates.
                        (objNew.reduivy__Skip_Duplicate_Rules__c == false && 
                        String.isNotBlank(objNew.reduivy__Application_Status__c) && 
                        IPA_ACTIVE_STATUSES.contains(objNew.reduivy__Application_Status__c)) ||
                        // If the record is currently not in an active status but was previously active, 
                        // we also need to include it in the list, as this is a before-trigger

                        // Example situation:
                        // - IPA 1 and IPA 2 are matching.
                        // - IPA 1 is currently in an active status and is being updated to a non-active status.
                        // - IPA 2 is currently in a non-active status and is being updated to an active status.

                        // In this case, we need to include both records in the list, since IPA 2 should be allowed to proceed as IPA 1 will be updated to an inactive status.
                        // If we do not add both records to the list, when checkDuplicateIPA queries existing IPAs, IPA 1 will still be considered active, causing the update of IPA 2 to fail.
                        (IPA_ACTIVE_STATUSES.contains(objOld.reduivy__Application_Status__c) &&
                        String.isNotBlank(objNew.reduivy__Application_Status__c) && 
                        !IPA_ACTIVE_STATUSES.contains(objNew.reduivy__Application_Status__c))
                    )
                ) {
                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                checkDuplicateIPA(workingList, operationType);
            }
        }
    }

    /**
     * @description To check if any duplicate IPAs exist
     * @param List<reduivy__Individual_Program_Application__c> ipaMap
     * @return void
     */
    private void checkDuplicateIPA(List<reduivy__Individual_Program_Application__c> ipaList, System.TriggerOperation operationType) {
    
        Set<Id> contactIds = new Set<Id>();
        Set<Id> studyProgramIds = new Set<Id>();

        Map<String, List<reduivy__Individual_Program_Application__c>> ipaWithCompositeKey = new Map<String, List<reduivy__Individual_Program_Application__c>>();
        
        for(reduivy__Individual_Program_Application__c ipa : ipaList) {
            //The inactive IPA will only be used in the NOT IN clause of the query
            if(!IPA_ACTIVE_STATUSES.contains(ipa.reduivy__Application_Status__c)) {
                continue;
            }

            if(String.isNotBlank(ipa.reduivy__Contact__c)) {
                contactIds.add(ipa.reduivy__Contact__c);
            }

            if(String.isNotBlank(ipa.reduivy__Study_Program__c)) {
                studyProgramIds.add(ipa.reduivy__Study_Program__c);
            }
            
            String key = generateRecordKey(ipa);
        
            if(!ipaWithCompositeKey.containsKey(key)) {
                ipaWithCompositeKey.put(key, new List<reduivy__Individual_Program_Application__c>());
            }

            ipaWithCompositeKey.get(key).add(ipa);
        }
        
        Set<String> duplicateFoundKeys = new Set<String>();
        
        for(String key : ipaWithCompositeKey.keySet()) {
            List<reduivy__Individual_Program_Application__c> duplicateRecords = ipaWithCompositeKey.get(key);
            //Indicates that multiple active IPAs with the same key are being updated
            if(duplicateRecords.size() > 1) {
                duplicateFoundKeys.add(key);
            }
        }

        //Check for duplicates against existing records in database
        if(!ipaWithCompositeKey.isEmpty()) {
            Set<String> existingIpaKeys = new Set<String>();

            String queryString = 'SELECT Id, reduivy__Contact__c, reduivy__Study_Program__c, reduivy__Study_Intake__c, ' +
                                'reduivy__Master_Study_Plan__c, reduivy__Application_Status__c ' +
                                'FROM reduivy__Individual_Program_Application__c ' +
                                'WHERE reduivy__Contact__c IN :contactIds ' +
                                'AND reduivy__Study_Program__c IN :studyProgramIds ' +
                                'AND reduivy__Application_Status__c IN :IPA_ACTIVE_STATUSES';
            
            Map<String, Object> bindParams = new Map<String, Object>{
                'contactIds' => contactIds,
                'studyProgramIds' => studyProgramIds,
                'IPA_ACTIVE_STATUSES' => IPA_ACTIVE_STATUSES
            };
            
            if(operationType == System.TriggerOperation.BEFORE_UPDATE) {
                queryString += ' AND Id NOT IN :ipaList';
                bindParams.put('ipaList', ipaList);
            }
            
            for(reduivy__Individual_Program_Application__c ipa : (List<reduivy__Individual_Program_Application__c>) Database.queryWithBinds(queryString, bindParams, AccessLevel.USER_MODE)) {
                String key = generateRecordKey(ipa);
                existingIpaKeys.add(key);
            }

            for(String key : ipaWithCompositeKey.keySet()) {
                if(existingIpaKeys.contains(key)) {
                    duplicateFoundKeys.add(key);
                }
            }
        }
        
        if(!duplicateFoundKeys.isEmpty()) {
            String masterStudyPlanFieldLabel = Schema.SObjectType.reduivy__Individual_Program_Application__c.fields.reduivy__Master_Study_Plan__c.getLabel();

            for(String key : duplicateFoundKeys) {
                List<reduivy__Individual_Program_Application__c> duplicateRecords = ipaWithCompositeKey.get(key);
                
                for(reduivy__Individual_Program_Application__c ipa : duplicateRecords) {
                    ipa.addError(String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), masterStudyPlanFieldLabel}));
                }
            }
        }
    }

    /**
     * @description Return the key
     * @param ipaRecord reduivy__Individual_Program_Application__c to be used to generate the key
     * @return String
     */
    private String generateRecordKey(reduivy__Individual_Program_Application__c ipaRecord) {
        String contactId = (String) ipaRecord.reduivy__Contact__c ?? '-';
        String studyProgramId = (String) ipaRecord.reduivy__Study_Program__c ?? '-';
        String studyIntakeId = (String) ipaRecord.reduivy__Study_Intake__c ?? '-';
        String masterStudyPlanId = (String) ipaRecord.reduivy__Master_Study_Plan__c ?? '-';

        String key = contactId + '|' + studyProgramId + '|' + studyIntakeId + '|' + masterStudyPlanId;

        return key;
    }
}