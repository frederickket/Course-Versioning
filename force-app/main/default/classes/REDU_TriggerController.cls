/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Util
 * @description Trigger controller
 * @changehistory
 * ISS-001591 30-03-2023 Lean - new class
 */
global inherited sharing class REDU_TriggerController {

    /**
     * @description User filter - ProfileId
     */
    public static final String USER_FILTER_PROFILEID = 'ProfileId';

    /**
     * @description User filter - UserType
     */
    public static final String USER_FILTER_USERTYPE = 'UserType';

    /**
     * @description User filter - Username
     */
    public static final String USER_FILTER_USERNAME = 'Username';

    /**
     * @description User filter - CustomPermission
     */
    public static final String USER_FILTER_CUSTOMPERMISSION = 'CustomPermission';

    /**
     * @description Trigger list identifier for new list - newList
     */
    public static final String TRIGGERLIST_NEW = 'newList';

    /**
     * @description Trigger list identifier for old list - oldList
     */
    public static final String TRIGGERLIST_OLD = 'oldList';

    /**
     * @description Set<String> to hold the class name, sobject and config name for muted triggers
     */
    private static Set<String> triggersToMute;

    /**
     * @description Boolean flag to mute all triggers
     */
    private static Boolean muteAll = false;

    /**
     * @description Mute triggers
     * @param triggers Set<String> of trigger controller class name, sobject or config name
     */
    global static void muteTriggers(Set<String> triggers) {
        if (triggersToMute == null) {
            triggersToMute = triggers;
        } else {
            triggersToMute.addAll(triggers);
        }
        
    }

    /**
     * @description Unmute triggers
     * @param triggers Set<String> of trigger controller class name, sobject or config name
     */
    global static void unmuteTriggers(Set<String> triggers) {
        if (triggersToMute != null) {
            triggersToMute.removeAll(triggers);
        }
    }

    /**
     * @description Mute all triggers
     */
    global static void muteAllTriggers() {
        muteAll = true;
    }

    /**
     * @description Unmute all triggers
     */
    global static void unmuteAllTriggers() {
        muteAll = false;
        triggersToMute = new Set<String>();
    }

    /**
     * @description Main method to initiate check for user, exclude records and initiate trigger controller class
     * @param operationType TriggerOperation enum
     * @param rawNewList Trigger.new
     * @param rawOldList Trigger.old
     * @param sobjResult Schema.SobjectType
     */
    public static void execute(System.TriggerOperation operationType, List<SObject> rawNewList, List<SObject> rawOldList, Schema.DescribeSObjectResult sobjResult) {

        try {
            //will skip all trigger controllers if muteAll is enabled or app is disabled
            if (muteAll || !REDU_AppSetting_UTIL.isRioEducationEnabled()) {
                return;
            }

            List<reduivy__Trigger_Controller__mdt> triggerControllers = getObjectTriggerControllerConfigs(operationType, sobjResult);

            for (reduivy__Trigger_Controller__mdt tc : triggerControllers) {
                if (isEligble(tc)) {
                    Type classType = Type.forName(tc.reduivy__Class_Name__c);

                    if (classType != null) {
                        Map<String, List<SObject>> filteredRecords = getRecordsForTriggers(tc, rawNewList, rawOldList);
                        List<SObject> newList = filteredRecords.get(TRIGGERLIST_NEW);
                        List<SObject> oldList = filteredRecords.get(TRIGGERLIST_OLD);

                        if (newList.isEmpty() && oldList.isEmpty()) {
                            //if there is no records, we will skip to the next class
                            return;
                        }

                        Object classInstance = classType.newInstance();

                        if(classInstance instanceof REDU_TriggerExecutable) {
                            REDU_TriggerExecutable executable = (REDU_TriggerExecutable) classInstance;
                            
                            Map<Id, SObject> newMap = new Map<Id, SObject>();
                            Map<Id, SObject> oldMap = (oldList != null ? new Map<Id, SObject>(oldList) : new Map<Id, SObject>());

                            switch on operationType {
                                when BEFORE_INSERT {
                                    //BeforeInsert shouldn't have newMap as the id is null as what defined in sf doc
                                    executable.executeBeforeInsert(operationType, newList, newMap, oldList, oldMap, sobjResult);
                                }
                                when BEFORE_UPDATE {
                                    newMap = new Map<Id, SObject>(newList);
                                    executable.executeBeforeUpdate(operationType, newList, newMap, oldList, oldMap, sobjResult);
                                }
                                when BEFORE_DELETE {
                                    executable.executeBeforeDelete(operationType, newList, newMap, oldList, oldMap, sobjResult);
                                }
                                when AFTER_INSERT {
                                    newMap = new Map<Id, SObject>(newList);
                                    executable.executeAfterInsert(operationType, newList, newMap, oldList, oldMap, sobjResult);
                                }
                                when AFTER_UPDATE {
                                    newMap = new Map<Id, SObject>(newList);
                                    executable.executeAfterUpdate(operationType, newList, newMap, oldList, oldMap, sobjResult);
                                }
                                when AFTER_DELETE {
                                    executable.executeAfterDelete(operationType, newList, newMap, oldList, oldMap, sobjResult);
                                }
                                when AFTER_UNDELETE {
                                    newMap = new Map<Id, SObject>(newList);
                                    executable.executeAfterUndelete(operationType, newList, newMap, oldList, oldMap, sobjResult);
                                }
                                when else {
                                    throw new REDU_ApplicationException(String.format(Label.Invalid_Trigger_Operation_Error, new List<String>{operationType.name()}));
                                }
                            }
                        }
                    }
                }
            }
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);

            List<SObject> triggerList = rawNewList ?? rawOldList;

            for (SObject triggerSobj : rawNewList) {
                triggerSobj.addError(errorMsg);
            }
        }
        
    }

    /**
     * @description Check if an Apex Trigger controller is eligible to run e.g., not muted or running user is not excluded
     * @param tc reduivy__Trigger_Controller__mdt
     * @return Boolean
     */
    private static Boolean isEligble(reduivy__Trigger_Controller__mdt tc) {
        if (triggersToMute != null && (triggersToMute.contains(tc.reduivy__Class_Name__c) || triggersToMute.contains(tc.reduivy__SObject__c) || triggersToMute.contains(tc.DeveloperName))) {
            return false;
        }

        if (String.isNotBlank(tc.reduivy__User_Exclusion_Field__c) && String.isNotBlank(tc.reduivy__User_Exclusion_Value__c)) {
            Set<String> filterValues = new Set<String>(tc.reduivy__User_Exclusion_Value__c.split(';'));

            String profileId = UserInfo.getProfileId();
            String username = UserInfo.getUserName();
            String userType = UserInfo.getUserType();
            
            for (String fv : filterValues) {
                if (tc.reduivy__User_Exclusion_Field__c == USER_FILTER_PROFILEID && profileId.equals(fv.trim())) {
                    //user profile id
                    return false;
                } else if (tc.reduivy__User_Exclusion_Field__c == USER_FILTER_USERNAME && username.equalsIgnoreCase(fv.trim())) {
                    //username
                    return false;
                } else if (tc.reduivy__User_Exclusion_Field__c == USER_FILTER_USERTYPE && userType.equalsIgnoreCase(fv.trim())) {
                    //user type
                    return false;
                } else if(tc.reduivy__User_Exclusion_Field__c == USER_FILTER_CUSTOMPERMISSION && FeatureManagement.checkPermission(fv.trim())) {
                    //custom permission
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * @description Method to prepare a new list for Trigger.new and Trigger.old after excluding the records based on the criteria defined
     * @param tc reduivy__Trigger_Controller__mdt
     * @param rawNewList Trigger.new
     * @param rawOldList Trigger.old
     * @return Map<String, List<SObject>> A map that contains two list: newList and oldList
     */
    private static Map<String, List<SObject>> getRecordsForTriggers(reduivy__Trigger_Controller__mdt tc, List<SObject> rawNewList, List<SObject> rawOldList) {

        Map<String, List<SObject>> triggerListMap = new Map<String, List<SObject>>();

        if (String.isNotBlank(tc.reduivy__Record_Exclusion_Field__c) && String.isNotBlank(tc.reduivy__Record_Exclusion_Value__c)) {
            Object exclusionValue = initFilterValue(tc.reduivy__SObject__c, tc.reduivy__Record_Exclusion_Field__c, tc.reduivy__Record_Exclusion_Value__c);

            List<SObject> filteredNewList = new List<SObject>();
            List<SObject> filteredOldList = new List<SObject>();

            if (rawNewList != null) {
                Integer counter = 0;
                for (SObject sobj : rawNewList) {
                    Object currentValue = sobj.get(tc.reduivy__Record_Exclusion_Field__c);

                    if (exclusionValue != currentValue) {
                        filteredNewList.add(sobj);

                        if (rawOldList != null) {
                            filteredOldList.add(rawOldList.get(counter));
                        }
                    }

                    counter ++;
                }
            } else if (rawOldList != null) {
                Integer counter = 0;
                for (SObject sobj : rawOldList) {
                    Object currentValue = sobj.get(tc.reduivy__Record_Exclusion_Field__c);

                    if (exclusionValue != currentValue) {
                        filteredOldList.add(rawOldList.get(counter));
                    }

                    counter ++;
                }
            }

            triggerListMap.put(TRIGGERLIST_NEW, filteredNewList);
            triggerListMap.put(TRIGGERLIST_OLD, filteredOldList);

        } else {
            triggerListMap.put(TRIGGERLIST_NEW, (rawNewList == null ? new List<SObject>() : rawNewList));
            triggerListMap.put(TRIGGERLIST_OLD, (rawOldList == null ? new List<SObject>() : rawOldList));
        }

        return triggerListMap;
    }

    /**
     * @description Init the filter value from string
     * @param filterFieldDesc The SObjectField used in the filtering comparison.
     * @return Object The value to compare against when filtering, already in the correct type. 
     */
    private static Object initFilterValue(String objectName, String fieldName, String value) {
        
        if (String.isNotBlank(value)) {
            Schema.DescribeFieldResult fieldDescResult = REDU_Metadata_UTIL.describeSObjectField(objectName, fieldName);
            Schema.DisplayType fieldType = fieldDescResult.getType();

            if(fieldType == Schema.DisplayType.BOOLEAN) {
                if(value.equalsIgnoreCase('true')) {
                    return true;
                } else if(value.equalsIgnoreCase('false')) {
                    return false;
                }
            } else if(fieldType == Schema.DisplayType.DATE) {
                return Date.parse(value);

            } else if(fieldType == Schema.DisplayType.DATETIME) {
                return Datetime.parse(value);

            } else if(fieldType == Schema.DisplayType.REFERENCE) {
                return ID.valueOf(value);

            } else if(fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.PERCENT) {
                return Decimal.valueOf(value);

            } else if(fieldType == Schema.DisplayType.INTEGER) {
                return Integer.valueOf(value);

            } else if(fieldType == Schema.DisplayType.DOUBLE) {
                return Double.valueOf(value);

            } else if(fieldType == Schema.DisplayType.LONG) {
                return Long.valueOf(value);
                
            } else { //treat the rest as string
                return value;
            }
        }

        return null;
    }

    /**
     * @description Return a list of sorted active reduivy__Trigger_Controller__mdt for the trigger object and operation
     * @param operationType TriggerOperation enum
     * @param sobjResult DescribeSObjectResult for Schema.SobjectType
     * @return List<reduivy__Trigger_Controller__mdt>
     */
    private static List<reduivy__Trigger_Controller__mdt> getObjectTriggerControllerConfigs(System.TriggerOperation operationType, Schema.DescribeSObjectResult sobjResult) {

        List<reduivy__Trigger_Controller__mdt> triggerConfigs = new List<reduivy__Trigger_Controller__mdt>();

        String sobjName = sobjResult.getName();

        //To skip the sample triggers that we need for test coverage if it is not called by test class
        Set<String> testTriggersToSkip = new Set<String>();
        if (!Test.isRunningTest()) {
            testTriggersToSkip.add('ACC_Sample_EXE');
        }

        //we will include trigger with objectname = AllObjects e.g., UUID generation so that we don't have to create the trigger controller metadata record for every object
        Set<String> objectNames = new Set<String>{sobjName, 'AllObjects'};

        for (String objName : objectNames) {
            if (getTriggerControllerConfigs().containsKey(objName)) {
                for (reduivy__Trigger_Controller__mdt tc : getTriggerControllerConfigs().get(objName)) {
                    if (!testTriggersToSkip.contains(tc.reduivy__Class_Name__c)) {
                        if (operationType == TriggerOperation.BEFORE_INSERT && tc.reduivy__Before_Insert__c) {
                            triggerConfigs.add(tc);
                        } else if (operationType == TriggerOperation.BEFORE_UPDATE && tc.reduivy__Before_Update__c) {
                            triggerConfigs.add(tc);
                        } else if (operationType == TriggerOperation.BEFORE_DELETE && tc.reduivy__Before_Delete__c) {
                            triggerConfigs.add(tc);
                        } else if (operationType == TriggerOperation.AFTER_INSERT && tc.reduivy__After_Insert__c) {
                            triggerConfigs.add(tc);
                        } else if (operationType == TriggerOperation.AFTER_UPDATE && tc.reduivy__After_Update__c) {
                            triggerConfigs.add(tc);
                        } else if (operationType == TriggerOperation.AFTER_DELETE && tc.reduivy__After_Delete__c) {
                            triggerConfigs.add(tc);
                        } else if (operationType == TriggerOperation.AFTER_UNDELETE && tc.reduivy__After_Undelete__c) {
                            triggerConfigs.add(tc);
                        }
                    }
                }
            }
        }

        List<REDU_SObjectComparator.SortCriterion> criteria = new List<REDU_SObjectComparator.SortCriterion>{
            new REDU_SObjectComparator.SortCriterion(reduivy__Trigger_Controller__mdt.reduivy__Sequence__c, REDU_SObjectComparator.SortOrder.Ascend, REDU_SObjectComparator.NullOrder.NullsLast)
        };
        
        triggerConfigs.sort(new REDU_SObjectComparator(criteria));

        return triggerConfigs;
    }

    /**
     * @description Map of reduivy__Trigger_Controller__mdt
     */
    @TestVisible
    private static Map<String, List<reduivy__Trigger_Controller__mdt>> triggerControllerConfigs;

    /**
     * @description Return the list of reduivy__Trigger_Controller__mdt grouped by object
     * @return Map<String, List<reduivy__Trigger_Controller__mdt>>
     */
    private static Map<String, List<reduivy__Trigger_Controller__mdt>> getTriggerControllerConfigs() {

        if (triggerControllerConfigs == null) {

            Map<String, List<reduivy__Trigger_Controller__mdt>> tcByObjects = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
            for (reduivy__Trigger_Controller__mdt tc : reduivy__Trigger_Controller__mdt.getAll().values()) {
                if (tc.reduivy__Active__c) {
                    if (!tcByObjects.containsKey(tc.reduivy__SObject__c)) {
                        tcByObjects.put(tc.reduivy__SObject__c, new List<reduivy__Trigger_Controller__mdt>{tc});
                    } else {
                        tcByObjects.get(tc.reduivy__SObject__c).add(tc);
                    }
                }
            }

            triggerControllerConfigs = tcByObjects;
        }

        return triggerControllerConfigs;
    }
}