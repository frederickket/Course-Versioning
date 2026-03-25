/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Trigger executable
 * @description To do rollup for study session's booked place and waitlisted place when update, insert, delete or undelete the individual session enrollment
 * @changehistory
 * ISS-002455 09-06-2025 XW - created rollupFieldsApiNameByStatus and rollupStatusesByField
 */
public without sharing class ISN_StudySessionRollup_EXE extends REDU_TriggerExecutable {
    
    private static final Id ISN_STUDENT_RTID =  ISN_Helper.getStudentRecordTypeId();

    /**
     * @description All of the Enrollmennt Statuses defined in custom metadata with include rollup = true
     */
    static final Set<String> ISN_ROLLUP_STATUSES;
    
    /**
     * @description All of the Study Intake Rollup fields defined in custom metadata
     */
    static final Set<String> ISN_ROLLUP_FIELDS;

    /**
     * @description Map<SIT Rollup field, Set<Isn enrollment statuses>>
     */
    static final Map<String, Set<String>> ROLLUP_STATUSES_BY_FIELD = ISN_Helper.getRollupStatusesByField();

    /**
     * @description Map<Isn enrollment statuses, Set<SIT Rollup field>>
     */
    static final Map<String, Set<String>> ROLLUP_FIELDS_API_NAME_BY_STATUS = ISN_Helper.getRollupFieldsApiNameByStatus();

    static final Set<Schema.DisplayType> DISPLAY_TYPE_NUMERIC = new Set<Schema.DisplayType> {
        Schema.DisplayType.DOUBLE,
        Schema.DisplayType.INTEGER,
        Schema.DisplayType.LONG
    };

    static {
        // Get the individual session enrollment statuses for booked and waitlisted places
        ISN_ROLLUP_STATUSES = ROLLUP_FIELDS_API_NAME_BY_STATUS.keySet();
        ISN_ROLLUP_FIELDS = ROLLUP_STATUSES_BY_FIELD.keySet();
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

            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>();

            for(reduivy__Individual_Session_Enrollment__c isn : (List<reduivy__Individual_Session_Enrollment__c>) newList){
                if(
                    isn.RecordTypeId == ISN_STUDENT_RTID 
                    && String.isNotBlank(isn.reduivy__Enrollment_Status__c)
                    && ISN_ROLLUP_STATUSES.contains(isn.reduivy__Enrollment_Status__c)
                    && String.isNotBlank(isn.reduivy__Study_Session__c)
                ){
                    isnList.add(isn);
                }
            }

            if(!isnList.isEmpty()){
                doRollup(isnList);
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

            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>();

            for(reduivy__Individual_Session_Enrollment__c isn : (List<reduivy__Individual_Session_Enrollment__c>) newList){
                reduivy__Individual_Session_Enrollment__c oldIsn = (reduivy__Individual_Session_Enrollment__c) oldMap.get(isn.Id);

                if(
                    isn.reduivy__Study_Session__c != oldIsn.reduivy__Study_Session__c
                    || isn.reduivy__Enrollment_Status__c != oldIsn.reduivy__Enrollment_Status__c
                    || isn.RecordTypeId != oldIsn.RecordTypeId 
                ){
                    if(
                        ISN_ROLLUP_STATUSES.contains(isn.reduivy__Enrollment_Status__c)
                        || (ISN_ROLLUP_STATUSES.contains(oldIsn.reduivy__Enrollment_Status__c) && !ISN_ROLLUP_STATUSES.contains(isn.reduivy__Enrollment_Status__c))
                    ){
                        isnList.add(isn);
                    }

                    if(
                        String.isNotBlank(oldIsn.reduivy__Study_Session__c)
                        && isn.reduivy__Study_Session__c != oldIsn.reduivy__Study_Session__c
                    ){
                        isnList.add(oldIsn);
                    }
                }
            }

            if(!isnList.isEmpty()){
                doRollup(isnList);
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

            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>();

            for(reduivy__Individual_Session_Enrollment__c isn : (List<reduivy__Individual_Session_Enrollment__c>) oldList){
                if(
                    isn.RecordTypeId == ISN_STUDENT_RTID 
                    && String.isNotBlank(isn.reduivy__Enrollment_Status__c)
                    && ISN_ROLLUP_STATUSES.contains(isn.reduivy__Enrollment_Status__c)
                    && String.isNotBlank(isn.reduivy__Study_Session__c)
                ){
                    isnList.add(isn);
                }
            }

            if(!isnList.isEmpty()){
                doRollup(isnList);
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

            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>();

            for(reduivy__Individual_Session_Enrollment__c isn : (List<reduivy__Individual_Session_Enrollment__c>) newList){
                if(
                    isn.RecordTypeId == ISN_STUDENT_RTID 
                    && String.isNotBlank(isn.reduivy__Enrollment_Status__c)
                    && ISN_ROLLUP_STATUSES.contains(isn.reduivy__Enrollment_Status__c)
                    && String.isNotBlank(isn.reduivy__Study_Session__c)
                ){
                    isnList.add(isn);
                }
            }

            if(!isnList.isEmpty()){
                doRollup(isnList);
            }
        }
    }

    /**
     * @description This is the method that performs the roll up calculation.
     * @param isnList individual session enrollment list to rollup
     */
    private static void doRollup(List<reduivy__Individual_Session_Enrollment__c> isnList){

        List<reduivy__Study_Session__c> sseToUpdate = new List<reduivy__Study_Session__c>();
        Map<Id, List<reduivy__Individual_Session_Enrollment__c>> parentChildsMap = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();

        for(reduivy__Individual_Session_Enrollment__c isn : isnList){
            
            if(!parentChildsMap.containsKey(isn.reduivy__Study_Session__c)){
                parentChildsMap.put(isn.reduivy__Study_Session__c, new List<reduivy__Individual_Session_Enrollment__c>());
            }
            parentChildsMap.get(isn.reduivy__Study_Session__c).add(isn);
        }

        //validate metadata config
        Boolean isValid = validateConfigurationAndAddError(isnList);
        if(!isValid) {
            return;
        }

        Set<String> isnFields = new Set<String> {
            'Id',
            'reduivy__Enrollment_Status__c'
        };

        Set<String> sseFields = new Set<String> {
            'Id', 
            'Name',
            'reduivy__Booked_Places__c', 
            'reduivy__Waitlist_Places__c', 
            'reduivy__Unlimited_Places__c', 
            'reduivy__Capacity__c'
        };
        sseFields.addAll(ISN_ROLLUP_FIELDS);

        String isnQuery = 'SELECT ' + String.join(isnFields, ', ') +
                         ' FROM reduivy__Individual_Session_Enrollments__r' +
                         ' WHERE RecordTypeId = :isnStudentRecordTypeId' +
                         ' AND reduivy__Enrollment_Status__c IN :ISN_ROLLUP_STATUSES';

        String sseQuery = 'SELECT ' + String.join(sseFields, ', ') + ', (' + isnQuery + ')' +
                         ' FROM ' + SSE_Helper.getApiName() +
                         ' WHERE Id IN :sseSet' +
                         ' FOR UPDATE';

        Map<String, Object> bindMap = new Map<String, Object> {
            'isnStudentRecordTypeId' => ISN_STUDENT_RTID,
            'ISN_ROLLUP_STATUSES' => ISN_ROLLUP_STATUSES,
            'sseSet' => parentChildsMap.keySet()
        };

        for (reduivy__Study_Session__c sse : (List<reduivy__Study_Session__c>) Database.queryWithBinds(sseQuery, bindMap, AccessLevel.SYSTEM_MODE)){
            Map<String, Integer> rollupFieldValueMap = new Map<String, Integer>();

            for(String rollupField : ISN_ROLLUP_FIELDS) {
                rollupFieldValueMap.put(rollupField, 0);
            }
            if(!rollupFieldValueMap.containsKey('reduivy__Booked_Places__c')) {
                rollupFieldValueMap.put('reduivy__Booked_Places__c', 0);
            }
            if(!rollupFieldValueMap.containsKey('reduivy__Waitlist_Places__c')) {
                rollupFieldValueMap.put('reduivy__Waitlist_Places__c', 0);
            }

            for (reduivy__Individual_Session_Enrollment__c isn : sse.reduivy__Individual_Session_Enrollments__r) {

                Set<String> rollupFields = ROLLUP_FIELDS_API_NAME_BY_STATUS.get(isn.reduivy__Enrollment_Status__c);
                for(String rollupField : rollupFields) {
                    Integer numOfIsn = rollupFieldValueMap.get(rollupField);
                    numOfIsn++;
                    rollupFieldValueMap.put(rollupField, numOfIsn);
                }
            }

            Boolean isUpdated = false;
            for(String rollupField : rollupFieldValueMap.keySet()) {
                if(rollupFieldValueMap.get(rollupField) != Integer.valueOf(sse.get(rollupField))){
                    isUpdated = true;
                    break;
                }
            }
            
            if (isUpdated) {

                // Throw an error to notify the student if the study session is over capacity
                if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT)) {
                    Integer booked = rollupFieldValueMap.get('reduivy__Booked_Places__c');
                    if ((!sse.reduivy__Unlimited_Places__c) && ((sse.reduivy__Capacity__c - booked) < 0)) {
                        if (parentChildsMap.containsKey(sse.Id)) {
                            for (reduivy__Individual_Session_Enrollment__c isn : parentChildsMap.get(sse.Id)) {
                                isn.addError(
                                    String.format(Label.Error_No_Available_Places_Remaining_In_Study_Session,
                                    new List<String>{SSE_Helper.getObjectLabel(), sse.Name})
                                );
                            }    
                            continue;
                        }
                    }
                } 

                reduivy__Study_Session__c sseUpdate = new reduivy__Study_Session__c();
                sseUpdate.Id = sse.Id;
                for(String rollupFieldName : rollupFieldValueMap.keySet()) {
                    sseUpdate.put(rollupFieldName, rollupFieldValueMap.get(rollupFieldName));
                }

                sseToUpdate.add(sseUpdate);
            }
        }
        
        //update isn
        if(!sseToUpdate.isEmpty()){
            //Rollup using system mode as the fields are non editable by normal user
            REDU_SystemMode_UTIL.doUpdate(sseToUpdate, parentChildsMap, 'Id', false);
        }

    }

    

    /**
     * @description validate configuration and add error if configuration is invalid
     * @param  isnList        
     * @return                       return true if is valid
     */
    private static Boolean validateConfigurationAndAddError(List<reduivy__Individual_Session_Enrollment__c> isnList) {
        Set<String> invalidConfigSet = new Set<String>();

        //check if rollup field exists in study session and is valid field type
        Map<String, Schema.SObjectField> sseFieldsResult = Schema.SObjectType.reduivy__Study_Session__c.fields.getMap();
        for(String sseRollupField : ISN_ROLLUP_FIELDS) {
            if(!sseFieldsResult.containsKey(sseRollupField) ||                                                          //field not found in study intake
                !DISPLAY_TYPE_NUMERIC.contains(sseFieldsResult.get(sseRollupField).getDescribe().getType()) ||          //field is not numeric type
                sseFieldsResult.get(sseRollupField).getDescribe().isCalculated()                                        //field is formula
            ){
                invalidConfigSet.addAll(ROLLUP_STATUSES_BY_FIELD.get(sseRollupField));
            }
        }

        //if invalid sit rollup field is configured, error is thrown
        if(!invalidConfigSet.isEmpty()) {

            String errorMessage = String.format(Label.IdvSn_Enrollment_Status_Rollup_Field_Is_Not_Configured_Invalid,
                new List<String> {String.join(invalidConfigSet, ', ')}
            );

            //add error
            for(reduivy__Individual_Session_Enrollment__c isn : isnList){
                isn.addError(errorMessage);
            }
        }

        return invalidConfigSet.isEmpty();
    }
}