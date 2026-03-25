/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Study offering booked places and waitlist places rollup from individual enrollments
 * @changehistory
 * ISS-001761 26-10-2023 dblack - new class
 * ISS-001890 06-06-2024 Sueanne - update booked place when status change to 'Withdrawn'
 * ISS-002060 14-10-2024 Sueanne - added undelete event
 * ISS-002231 25-03-2025 Lean - Added deferred status
 * ISS-002454 10-06-2025 XW - Make individual enrollment rollup to study offering configurable
 */
public without sharing class IEN_StudyOfferingRollup_EXE extends REDU_TriggerExecutable {

    static final Id IEN_STUDENT_RTID =  IEN_Helper.getStudentRecordTypeId();
    /**
     * @description All of the Enrollment Statuses defined in custom metadata with include rollup = true
     */
    static final Set<String> IEN_ROLLUP_STATUSES;
    
    /**
     * @description All of the Study Offering Rollup fields defined in custom metadata
     */
    static final Set<String> IEN_ROLLUP_FIELDS;

    /**
     * @description Map<SOF Rollup field, Set<IEN enrollment statuses>>
     */
    static final Map<String, Set<String>> ROLLUP_STATUSES_BY_FIELD = IEN_Helper.getRollupStatusesByField();

    /**
     * @description Map<IEN enrollment statuses, Set<SOF Rollup field>>
     */
    static final Map<String, Set<String>> ROLLUP_FIELDS_API_NAME_BY_STATUS = IEN_Helper.getRollupFieldsApiNameByStatus();

    static final Set<Schema.DisplayType> DISPLAY_TYPE_NUMERIC = new Set<Schema.DisplayType> {
        Schema.DisplayType.DOUBLE,
        Schema.DisplayType.INTEGER,
        Schema.DisplayType.LONG
    };

    static {
        // Get the individual enrollment statuses for booked and waitlisted places
        IEN_ROLLUP_STATUSES = ROLLUP_FIELDS_API_NAME_BY_STATUS.keySet();
        IEN_ROLLUP_FIELDS = ROLLUP_STATUSES_BY_FIELD.keySet();
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
    public override void executeAfterInsert(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult
    ) {
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();

        for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                
            if(IEN_ROLLUP_STATUSES.contains(ienNew.reduivy__Enrollment_Status__c)){
                ienMap.put(ienNew.Id, ienNew);
            }
        }

        if (!ienMap.isEmpty()) {
            doStudyOfferingRollup(ienMap, null);
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
    public override void executeAfterUpdate(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult
    ) {

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Map<Id, reduivy__Individual_Enrollment__c> oldIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();

        for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
            reduivy__Individual_Enrollment__c ienOld = (reduivy__Individual_Enrollment__c) oldMap.get(ienNew.Id);
            
            if (ienNew.reduivy__Enrollment_Status__c != ienOld.reduivy__Enrollment_Status__c ||
                ienNew.reduivy__Study_Offering__c != ienOld.reduivy__Study_Offering__c
            ) {
                
                if(IEN_ROLLUP_STATUSES.contains(ienNew.reduivy__Enrollment_Status__c) || 
                (IEN_ROLLUP_STATUSES.contains(ienOld.reduivy__Enrollment_Status__c) && !IEN_ROLLUP_STATUSES.contains(ienNew.reduivy__Enrollment_Status__c))){
                    
                    ienMap.put(ienNew.Id, ienNew);
                }

                if (String.isNotBlank(ienOld.reduivy__Study_Offering__c) &&
                    ienNew.reduivy__Study_Offering__c != ienOld.reduivy__Study_Offering__c
                ) {
                    oldIenMap.put(ienOld.Id, ienOld);
                }
            }
        }

        if (!ienMap.isEmpty()) {
            doStudyOfferingRollup(ienMap, oldIenMap);
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
    public override void executeAfterDelete(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult
    ) {
        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();

        for (reduivy__Individual_Enrollment__c ienOld : (List<reduivy__Individual_Enrollment__c>) oldList) {
                
            if(IEN_ROLLUP_STATUSES.contains(ienOld.reduivy__Enrollment_Status__c)){
                ienMap.put(ienOld.Id, ienOld);
            }
        }

        if (!ienMap.isEmpty()) {
            doStudyOfferingRollup(ienMap, null);
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

            Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ienNew : (List<reduivy__Individual_Enrollment__c>) newList) {
                    
                if(IEN_ROLLUP_STATUSES.contains(ienNew.reduivy__Enrollment_Status__c)){
                    ienMap.put(ienNew.Id, ienNew);
                }
            }

            if (!ienMap.isEmpty()) {
                doStudyOfferingRollup(ienMap, null);
            }
        }
    }

    /**
     * @description Rollup indvidual enrollment booked places and waitlisted places to the parent study offering record
     * @param ienList List<reduivy__Individual_Enrollment__c>
     */
    public void doStudyOfferingRollup(Map<Id, reduivy__Individual_Enrollment__c> ienMap, Map<Id, reduivy__Individual_Enrollment__c> oldIenMap) {

        // Get the relevant individual enrollment records
        Map<Id, List<reduivy__Individual_Enrollment__c>> ienBySofMap = new Map<Id, List<reduivy__Individual_Enrollment__c>>();

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            if ((ien.RecordTypeId == IEN_STUDENT_RTID) && 
                String.isNotBlank(ien.reduivy__Study_Offering__c)){

                if (!ienBySofMap.containsKey(ien.reduivy__Study_Offering__c)) {
                    ienBySofMap.put(ien.reduivy__Study_Offering__c, new List<reduivy__Individual_Enrollment__c>());
                }

                ienBySofMap.get(ien.reduivy__Study_Offering__c).add(ien);
            }
        }

        // To cater the recalculation of the previous sof
        if (oldIenMap != null) {
            for (reduivy__Individual_Enrollment__c ienOld : oldIenMap.values()) {
                if ((ienOld.RecordTypeId == IEN_STUDENT_RTID) && 
                    (String.isNotBlank(ienOld.reduivy__Study_Offering__c)) && 
                    (IEN_ROLLUP_STATUSES.contains(ienOld.reduivy__Enrollment_Status__c))
                ) {
                    if (!ienBySofMap.containsKey(ienOld.reduivy__Study_Offering__c)) {
                        ienBySofMap.put(ienOld.reduivy__Study_Offering__c, new List<reduivy__Individual_Enrollment__c>());
                    }

                    //we add the ien from the ienMap so that we can addError to it if dml failed
                    ienBySofMap.get(ienOld.reduivy__Study_Offering__c).add(ienMap.get(ienOld.Id));
                }
            }
        }

        Boolean isValid = validateConfigurationAndAddError(ienBySofMap);
        if(!isValid) {
            return;
        }

        if (!ienBySofMap.isEmpty()) {
            List<reduivy__Study_Offering__c> sofUpdateList = new List<reduivy__Study_Offering__c>();

            Set<String> ienFields = new Set<String>{
                'Id',
                'RecordTypeId',
                'reduivy__Enrollment_Status__c'
            };

            String ienQuery = 'SELECT ' + String.join(ienFields, ', ') +
                             ' FROM reduivy__Individual_Enrollments__r' +
                             ' WHERE RecordTypeId = :IEN_STUDENT_RTID' + 
                             ' AND reduivy__Enrollment_Status__c in :IEN_ROLLUP_STATUSES';

            Set<String> sofFields = new Set<String>{
                'Id', 
                'Name', 
                'reduivy__Booked_Places__c', 
                'reduivy__Waitlist_Places__c', 
                'reduivy__Capacity__c', 
                'reduivy__Unlimited_Places__c'
            };
            sofFields.addAll(IEN_ROLLUP_FIELDS);

            String sofQuery = 'SELECT ' + String.join(sofFields, ', ') + ', (' + ienQuery + ')' +
                             ' FROM ' + SOF_Helper.getApiName() + 
                             ' WHERE Id IN :sofSet ' +
                             ' FOR UPDATE';
            Map<String, Object> bindMap = new Map<String, Object>{
                'IEN_STUDENT_RTID' => IEN_STUDENT_RTID,
                'IEN_ROLLUP_STATUSES' => IEN_ROLLUP_STATUSES,
                'sofSet' => ienBySofMap.keySet()
            };


            for (reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofQuery, bindMap, AccessLevel.SYSTEM_MODE)) {
                // Count the number of booked and waitlisted places
                Map<String, Integer> rollupFieldValue = new Map<String, Integer>();
                for(String rollupField : IEN_ROLLUP_FIELDS){
                    rollupFieldValue.put(rollupField, 0);
                }

                rollupFieldValue.put('reduivy__Booked_Places__c', 0);
                rollupFieldValue.put('reduivy__Waitlist_Places__c', 0);

                for (reduivy__Individual_Enrollment__c ien : sof.reduivy__Individual_Enrollments__r) {

                    Set<String> rollupFields = ROLLUP_FIELDS_API_NAME_BY_STATUS.get(ien.reduivy__Enrollment_Status__c);
                    for(String rollupField : rollupFields) {
                        Integer numOfEnrollments = Integer.valueOf(rollupFieldValue.get(rollupField));
                        numOfEnrollments++;
                        rollupFieldValue.put(rollupField, numOfEnrollments);
                    }

                }

                // Zero any null values
                sof.reduivy__Booked_Places__c = (sof.reduivy__Booked_Places__c == null) ? 0 : sof.reduivy__Booked_Places__c;
                sof.reduivy__Waitlist_Places__c = (sof.reduivy__Waitlist_Places__c == null) ? 0 : sof.reduivy__Waitlist_Places__c;
                sof.reduivy__Capacity__c = (sof.reduivy__Capacity__c == null) ? 0 : sof.reduivy__Capacity__c;

                Boolean sofIsUpdated = false;
                for(String rollupField : IEN_ROLLUP_FIELDS) {
                    if(Integer.valueOf(sof.get(rollupField)) != rollupFieldValue.get(rollupField)) {
                        sofIsUpdated = true;
                        break;
                    }
                }

                if(!sofIsUpdated) {
                    return;
                }

                // Update the study offering if the counted number of places does not match the number of places on the study offering record
                if (sofIsUpdated) {

                    // Throw an error to notify the student if the study offering is over capacity
                    if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT)) {
                        Integer bookedPlaces = rollupFieldValue.get('reduivy__Booked_Places__c');
                        if ((!sof.reduivy__Unlimited_Places__c) && ((sof.reduivy__Capacity__c - bookedPlaces) < 0)) {
                            if (ienBySofMap.containsKey(sof.Id)) {
                                for (reduivy__Individual_Enrollment__c ien : ienBySofMap.get(sof.Id)) {
                                    ien.addError(
                                        String.format(Label.Error_No_Available_Places_Remaining_In_Study_Offering,
                                        new List<String>{SOF_Helper.getObjectLabel(), sof.Name})
                                    );
                                }    
                                continue;
                            }
                        }
                    }

                    // Update the study offering record with only the relevant fields
                    reduivy__Study_Offering__c sofUpdate = new reduivy__Study_Offering__c();
                    sofUpdate.Id = sof.Id;
                    for(String rollupField : IEN_ROLLUP_FIELDS) {
                        sofUpdate.put(rollupField, rollupFieldValue.get(rollupField));
                    }
                    sofUpdateList.add(sofUpdate);
                }
            }

            if (!sofUpdateList.isEmpty()) {
                //Rollup using system mode as the fields are non editable by normal user
                REDU_SystemMode_UTIL.doUpdate(sofUpdateList, ienBySofMap, 'Id', false);
            }
        }
    }

    

    /**
     * @description validate configuration and add error if configuration is invalid
     * @param  ienBySofMap        
     * @return                       return true if is valid
     */
    private static Boolean validateConfigurationAndAddError(Map<Id, List<reduivy__Individual_Enrollment__c>> ienBySofMap) {
        Set<String> invalidConfigSet = new Set<String>();

        //check if rollup field exists in study offering and is valid field type
        Map<String, Schema.SObjectField> sofFieldsResult = Schema.SObjectType.reduivy__Study_Offering__c.fields.getMap();
        for(String sofRollupField : IEN_ROLLUP_FIELDS) {
            if(!sofFieldsResult.containsKey(sofRollupField) ||                                                          //field not found in study offering
                !DISPLAY_TYPE_NUMERIC.contains(sofFieldsResult.get(sofRollupField).getDescribe().getType()) ||          //field is not numeric type
                sofFieldsResult.get(sofRollupField).getDescribe().isCalculated()                                        //field is formula
            ){
                invalidConfigSet.addAll(ROLLUP_STATUSES_BY_FIELD.get(sofRollupField));
            }
        }

        //if invalid sof rollup field is configured, error is thrown
        if(!invalidConfigSet.isEmpty()) {

            String errorMessage = String.format(Label.IdvEn_Enrollment_Status_Rollup_Field_Is_Not_Configured_Invalid,
                new List<String> {String.join(invalidConfigSet, ', ')}
            );

            //add error
            for(List<reduivy__Individual_Enrollment__c> ienList : ienBySofMap.values()){
                for(reduivy__Individual_Enrollment__c ien : ienList) {
                    ien.addError(errorMessage);
                }
            }
        }

        return invalidConfigSet.isEmpty();
    }
}