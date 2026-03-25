/**
 * @author      WDCi (XW)
 * @date        Mar 2025
 * @group       Trigger executable
 * @description Rollup Individual Program Application count to Study Intake
 * @changehistory
 * ISS-002090 10-03-2025 XW - add new class
 * ISS-002415 23-04-2025 XW - Allow Storing the Count of Applications in different field
 * ISS-002501 10-06-2025 XW - Study Intake rollup should skip record update if there is no changes in the count
 * ISS-002526 15-06-2025 XW - modified to support both study intake and study intake group parent
 */

public without sharing class IPA_StudyIntakeRollUp_EXE extends REDU_TriggerExecutable {

    /**
     * @description All of the Application Statuses defined in custom metadata with include rollup = true
     */
    static final Set<String> ROLLUP_STATUSES;
    
    /**
     * @description All of the Study Intake Rollup fields defined in custom metadata
     */
    static final Set<String> ROLLUP_FIELDS;

    /**
     * @description Map<parent Rollup field, Set<IPA application statuses>>
     */
    static final Map<String, Set<String>> ROLLUP_STATUSES_BY_FIELD = IPA_Helper.getRollupStatusesByField();

    /**
     * @description Map<IPA application statuses, Set<parent Rollup field>>
     */
    static final Map<String, Set<String>> ROLLUP_FIELDS_API_NAME_BY_STATUS = IPA_Helper.getRollupFieldsApiNameByStatus();

    static final String PARENT_FIELD_BOOKED_PLACES = 'reduivy__Booked_Places__c';

    static String rollupParentField;
    static Boolean isUsingStudyIntakeGroup = REDU_AppSetting_UTIL.isUsingStudyIntakeGroup();

    static final Set<Schema.DisplayType> DISPLAY_TYPE_NUMERIC = new Set<Schema.DisplayType> {
        Schema.DisplayType.DOUBLE,
        Schema.DisplayType.INTEGER,
        Schema.DisplayType.LONG
    };
    
    static {
        ROLLUP_STATUSES = ROLLUP_FIELDS_API_NAME_BY_STATUS.keySet();
        ROLLUP_FIELDS = ROLLUP_STATUSES_BY_FIELD.keySet();

        if(isUsingStudyIntakeGroup) {
            rollupParentField = 'reduivy__Study_Intake_Group__c';
        } else {
            rollupParentField = 'reduivy__Study_Intake__c';
        }
    }

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

            Map<Id, reduivy__Individual_Program_Application__c> workingMap = new Map<Id, reduivy__Individual_Program_Application__c>();
            for (reduivy__Individual_Program_Application__c objNew : (List<reduivy__Individual_Program_Application__c>) newList) {
                
                if(String.isNotBlank((String)objNew.get(rollupParentField)) && ROLLUP_STATUSES.contains(objNew.reduivy__Application_Status__c)){
                    workingMap.put(objNew.Id, objNew);
                }
            }

            if(!workingMap.isEmpty()) {
                rollupStudyIntake(workingMap, null);
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

            Map<Id, reduivy__Individual_Program_Application__c> newIpaWorkingMap = new Map<Id, reduivy__Individual_Program_Application__c>();
            Map<Id, reduivy__Individual_Program_Application__c> oldIpaWorkingMap = new Map<Id, reduivy__Individual_Program_Application__c>();
            for (reduivy__Individual_Program_Application__c objNew : (List<reduivy__Individual_Program_Application__c>) newList) {
                reduivy__Individual_Program_Application__c objOld = (reduivy__Individual_Program_Application__c) oldMap.get(objNew.Id);

                if (
                    (String)objNew.get(rollupParentField) != (String)objOld.get(rollupParentField) ||
                    (
                        objNew.reduivy__Application_Status__c != objOld.reduivy__Application_Status__c &&
                        ROLLUP_FIELDS_API_NAME_BY_STATUS.get(objNew.reduivy__Application_Status__c) != ROLLUP_FIELDS_API_NAME_BY_STATUS.get(objOld.reduivy__Application_Status__c)
                    )
                ) {
                    if(String.isNotBlank((String)objNew.get(rollupParentField))) {
                        newIpaWorkingMap.put(objNew.Id, objNew);
                    }
                    
                    if(String.isNotBlank((String)objOld.get(rollupParentField))) {
                        oldIpaWorkingMap.put(objOld.Id, objOld);
                    }
                }
            }

            if(!newIpaWorkingMap.isEmpty() || !oldIpaWorkingMap.isEmpty()) {
                rollupStudyIntake(newIpaWorkingMap, oldIpaWorkingMap);
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

            Map<Id, reduivy__Individual_Program_Application__c> workingMap = new Map<Id, reduivy__Individual_Program_Application__c>();
            for (reduivy__Individual_Program_Application__c objOld : (List<reduivy__Individual_Program_Application__c>) oldList) {

                if(String.isNotBlank((String)objOld.get(rollupParentField)) && ROLLUP_STATUSES.contains(objOld.reduivy__Application_Status__c)){
                    workingMap.put(objOld.Id, objOld);
                }

            }

            if(!workingMap.isEmpty()) {
                rollupStudyIntake(workingMap, null);
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

            Map<Id, reduivy__Individual_Program_Application__c> workingMap = new Map<Id, reduivy__Individual_Program_Application__c>();
            for (reduivy__Individual_Program_Application__c objNew : (List<reduivy__Individual_Program_Application__c>) newList) {

                if(String.isNotBlank((String)objNew.get(rollupParentField)) && ROLLUP_STATUSES.contains(objNew.reduivy__Application_Status__c)){
                    workingMap.put(objNew.Id, objNew);
                }
            }

            if(!workingMap.isEmpty()) {
                rollupStudyIntake(workingMap, null);
            }
        }
    }

    private void rollupStudyIntake(Map<Id, reduivy__Individual_Program_Application__c> ipaMap, Map<Id, reduivy__Individual_Program_Application__c> oldIpaMap){
        Map<Id, List<reduivy__Individual_Program_Application__c>> parent_IpaListMap = new Map<Id, List<reduivy__Individual_Program_Application__c>>();
        
        for(reduivy__Individual_Program_Application__c ipa: ipaMap.values()) {

            if(!parent_IpaListMap.containsKey((String)ipa.get(rollupParentField))) {
                parent_IpaListMap.put((String)ipa.get(rollupParentField), new List<reduivy__Individual_Program_Application__c>());
            }
            parent_IpaListMap.get((String)ipa.get(rollupParentField)).add(ipa);
        }

        if(oldIpaMap != null && !oldIpaMap.isEmpty()) {
            for(reduivy__Individual_Program_Application__c oldIpa: oldIpaMap.values()) {
                if(String.isBlank((String)oldipa.get(rollupParentField))){
                    continue;
                }
                
                if(!parent_IpaListMap.containsKey((String)oldIpa.get(rollupParentField))) {
                    parent_IpaListMap.put((String)oldIpa.get(rollupParentField), new List<reduivy__Individual_Program_Application__c>());
                }
                parent_IpaListMap.get((String)oldIpa.get(rollupParentField)).add(ipaMap.get(oldIpa.Id));
            }
        }
        REDU_Logging_UTIL.debugJsonString('parent_IpaListMap', parent_IpaListMap);

        if(!parent_IpaListMap.isEmpty()) {
            
            //validate metadata configuration 
            Boolean isValid = validateConfigurationAndAddError(parent_IpaListMap);
            if(!isValid) {
                return;
            }
            
            rollupParent(parent_IpaListMap);
        }


    }
	
    /**
     * @description recalculate the study intake booked places based on the valid ipas
     * @param  ipaMap    the valid ipa map
     * @param  oldIpaMap the valid ipa map for old records if the records are updated
     */
    private void rollupParent(Map<Id, List<reduivy__Individual_Program_Application__c>> parent_IpaListMap) {
        
        Set<String> ipaFields = new Set<String> {
            'Id',
            'Name',
            'reduivy__Application_Status__c'
        };

        Set<String> parentFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Capacity__c',
            'reduivy__Booked_Places__c'
        };
        parentFields.addAll(ROLLUP_FIELDS);
        
        String ipaQuery =  'SELECT ' + String.join(ipaFields, ', ')
                        + ' FROM reduivy__Individual_Program_Applications__r'
                        + ' WHERE reduivy__Application_Status__c IN :rollupStatuses';

        String parentQuery =  'SELECT ' + String.join(parentFields, ', ') + ', (' + ipaQuery + ')'
                        + ' FROM ' + (isUsingStudyIntakeGroup ? SIG_Helper.getApiName() : SIT_Helper.getApiName())
                        + ' WHERE Id IN :parentSet'
                        + ' FOR UPDATE';
        
        Map<String, Object> bindMap = new Map<String, Object>{
            'rollupStatuses' => ROLLUP_STATUSES,
            'parentSet' => parent_IpaListMap.keySet()
        };

        List<SObject> parentToUpdateList = new List<SObject>();

        //get all the child IPA of the affected Study Intake
        for(SObject parent : Database.queryWithBinds(parentQuery, bindMap, AccessLevel.SYSTEM_MODE)) {
            Boolean overCapacity = false;
            Map<String, Integer> rollupFieldValue = new Map<String, Integer>();
            for(String rollupField : ROLLUP_FIELDS) {
                rollupFieldValue.put(rollupField, 0);
            }
            rollupFieldValue.put(PARENT_FIELD_BOOKED_PLACES, 0);
            
            //loop through all the children IPA of the study intake to calculate the rollup field
            for(reduivy__Individual_Program_Application__c ipa : parent.getSObjects('reduivy__Individual_Program_Applications__r')) {

                //calculate number of applications for each application status
                Set<String> rollupFields = ROLLUP_FIELDS_API_NAME_BY_STATUS.get(ipa.reduivy__Application_Status__c);
                for(String rollupField : rollupFields) {
                    Integer numOfApplications = rollupFieldValue.get(rollupField);
                    numOfApplications++;
                    rollupFieldValue.put(rollupField, numOfApplications);
                }

                // Throw an error to notify the user if the study intake is over capacity (booked places > capacity), and the user is a student or is using study intake group
                if (
                    ROLLUP_FIELDS.contains(PARENT_FIELD_BOOKED_PLACES) &&
                    rollupFieldValue.get(PARENT_FIELD_BOOKED_PLACES) > (Decimal) parent.get('reduivy__Capacity__c') &&
                    (
                        REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT) 
                        || isUsingStudyIntakeGroup
                    )
                ) {
                    overCapacity = true;
                    break;
                }
            }

            if (overCapacity) {
                //add error for all of the child IPA for this study intake if study intake has no more available places
                if(parent_IpaListMap.containsKey(parent.Id)) {
                    for(reduivy__Individual_Program_Application__c ipa : parent_IpaListMap.get(parent.Id)) {

                        String errorMsg = String.format(Label.Error_No_Available_Places_Remaining_In_Study_Intake, new List<String> {
                            SIT_Helper.getObjectLabel(), (String)parent.get('Name')
                        });

                        ipa.addError(errorMsg);
                    }
                }
                continue;
                
            }

            Boolean parentIsUpdated = false;
            for(String rollupField : ROLLUP_FIELDS) {
                if(Integer.valueOf(parent.get(rollupField)) != rollupFieldValue.get(rollupField)) {
                    parentIsUpdated = true;
                    break;
                }
            }
            
            if(parentIsUpdated) {
                if(isUsingStudyIntakeGroup) {

                    reduivy__Study_Intake_Group__c sigToUpdate = new reduivy__Study_Intake_Group__c(Id = parent.Id);
                    for(String rollupField : ROLLUP_FIELDS) {
                        sigToUpdate.put(rollupField, rollupFieldValue.get(rollupField));
                    }
                    parentToUpdateList.add(sigToUpdate);

                } else {

                    reduivy__Study_Intake__c sitToUpdate = new reduivy__Study_Intake__c(Id = parent.Id);
                    for(String rollupField : ROLLUP_FIELDS) {
                        sitToUpdate.put(rollupField, rollupFieldValue.get(rollupField));
                    }
                    parentToUpdateList.add(sitToUpdate);

                }
            }

        }
        
        if(!parentToUpdateList.isEmpty()) {
            REDU_SystemMode_UTIL.doUpdate(parentToUpdateList, parent_IpaListMap, 'Id', false);
        }
    }

    /**
     * @description validate configuration and add error if configuration is invalid
     * @param  parent_IpaListMap        
     * @return                       return true if is valid
     */
    private static Boolean validateConfigurationAndAddError(Map<Id, List<reduivy__Individual_Program_Application__c>> parent_IpaListMap) {
        Set<String> invalidConfigSet = new Set<String>();

        //check if rollup field exists in study intake and is valid field type
        Map<String, Schema.SObjectField> ieldsResult = isUsingStudyIntakeGroup ? Schema.SObjectType.reduivy__Study_Intake_Group__c.fields.getMap() : Schema.SObjectType.reduivy__Study_Intake__c.fields.getMap();
        for(String rollupField : ROLLUP_FIELDS) {
            if(!ieldsResult.containsKey(rollupField) ||                                                          //field not found in study intake
                !DISPLAY_TYPE_NUMERIC.contains(ieldsResult.get(rollupField).getDescribe().getType()) ||          //field is not numeric type
                ieldsResult.get(rollupField).getDescribe().isCalculated()                                        //field is formula
            ){
                invalidConfigSet.addAll(ROLLUP_STATUSES_BY_FIELD.get(rollupField));
            }
        }

        //if invalid parent rollup field is configured, error is thrown
        if(!invalidConfigSet.isEmpty()) {

            String errorMessage = String.format(Label.IdvPa_Application_Status_Rollup_Field_Is_Not_Configured_Invalid,
                new List<String> {String.join(invalidConfigSet, ', ')}
            );

            //add error
            for(List<reduivy__Individual_Program_Application__c> ipaList : parent_IpaListMap.values()){
                for(reduivy__Individual_Program_Application__c ipa : ipaList) {
                    ipa.addError(errorMessage);
                }
            }
        }

        return invalidConfigSet.isEmpty();
    }

}