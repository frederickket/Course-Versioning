/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Individual Plan Structure object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001662 08-10-2023 dblack - added method: createGroup()
 * ISS-001817 03-01-2024 dblack - added methods: getGroupNotStartedStatuses(), getGroupInProgressStatuses() and getGroupCompletedStatuses()
 * ISS-001911 27-03-2024 VTan - Update retry statuses for enrollment wizard
 * ISS-001946 19-06-2024 Sueanne - add sequence field in group ips creation
 * ISS-002230 18-02-2025 XW - able to get custom requirement description
 * ISS-002231 25-03-2025 Lean - Added deferred status
 * ISS-002447 13-05-2025 Lean - New attempt limit status
 * ISS-002464 13-05-2025 Lean - Reset status when ien is unlinked
 * ISS-002513 09-02-2026 XiRouh - Updated createGroup() to update the IPS records only when the insertion is successful
 */
global inherited sharing class IPS_Helper implements SObject_Helper {
    
    /**
     * @description Status Type - Not Started
     */
    public static final String STATUS_TYPE_NOTSTARTED = 'Not_Started';

    /**
     * @description Status Type - In Progress
     */
    public static final String STATUS_TYPE_INPROGRESS = 'In_Progress';

    /**
     * @description Status Type - Completed
     */
    public static final String STATUS_TYPE_COMPLETED = 'Completed';

    /**
     * @description Status Type - Failed
     */
    public static final String STATUS_TYPE_FAILED = 'Failed';

    /**
     * @description Status Type - Withdrawn
     */
    public static final String STATUS_TYPE_WITHDRAWN = 'Withdrawn';

    /**
     * @description Status Type - Dropped
     */
    public static final String STATUS_TYPE_DROPPED = 'Dropped';

    /**
     * @description Status Type - Deferred
     */
    public static final String STATUS_TYPE_DEFERRED = 'Deferred';

    /**
     * @description Status Type - Non Enrollable
     */
    public static final String STATUS_TYPE_NONENROLLABLE = 'Non_Enrollable';

    /**
     * @description Category - Required
     */
	public static final String CATEGORY_REQUIRED = 'Required';

    /**
     * @description Category - Optional
     */
    public static final String CATEGORY_OPTIONAL = 'Optional';

    /**
     * @description Requirement Info - reqLogic
     */
    public static final String REQINFO_LOGIC = 'reqLogic';

    /**
     * @description Requirement Info - reqDesc
     */
    public static final String REQINFO_DESC = 'reqDesc';

    /**
     * @description Credits Contribution - Yes
     */
    public static final String CREDITS_CONTRIBUTION_YES = 'Yes';

    /**
     * @description Credits Contribution - No
     */
    public static final String CREDITS_CONTRIBUTION_NO = 'No';

    /**
     * @description Attempt Limit Status - Below Limit
     */
    public static final String ATTEMPT_LIMIT_STATUS_BELOWLIMIT = 'Below Limit';

    /**
     * @description Attempt Limit Status - AT Limit
     */
    public static final String ATTEMPT_LIMIT_STATUS_ATLIMIT = 'At Limit';

    /**
     * @description Attempt Limit Status - Exceeded Limit
     */
    public static final String ATTEMPT_LIMIT_STATUS_EXCEEDEDLIMIT = 'Exceeded Limit';

	/**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Plan_Structure__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Plan_Structure__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Plan_Structure__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Plan_Structure__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description RecordTypeInfo map
     */
    private static Map<String, Schema.RecordTypeInfo> rtMap;

    /**
     * @description Return record type map by developername
     * @return Map<String, Schema.RecordTypeInfo>
     */
    global static Map<String, Schema.RecordTypeInfo> getRecordTypes() {
        if (rtMap == null) {
            rtMap = Schema.SObjectType.reduivy__Individual_Plan_Structure__c.getRecordtypeInfosByDeveloperName();
        }

        return rtMap;
    }

    /**
     * @description Return group record type id
     * @return Id
     */
    global static Id getGroupRecordTypeId() {
        return getRecordTypes().get('Group').getRecordTypeId();
    }

    /**
     * @description Return group record type UI label
     * @return String
     */
    global static String getGroupRecordTypeLabel() {
        return getRecordTypes().get('Group').getName();
    }

    /**
     * @description Return unit record type id
     * @return Id
     */
    global static Id getUnitRecordTypeId() {
        return getRecordTypes().get('Unit').getRecordTypeId();
    }

    /**
     * @description Return unit record type UI label
     * @return String
     */
    global static String getUnitRecordTypeLabel() {
        return getRecordTypes().get('Unit').getName();
    }

    /**
     * @description List of reduivy__Study_Offering_Status_Config__mdt
     */
    private static List<reduivy__IdvPs_Status_Config__mdt> statusConfigs;

    /**
     * @description Status configs metadata sorted according to Status field for Group record type
     * @return List<reduivy__IdvPs_Status_Config__mdt>
     */
    public static List<reduivy__IdvPs_Status_Config__mdt> getGroupStatusConfig(){

        if (statusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Plan_Structure__c.fields.reduivy__Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvPs_Status_Config__mdt> configs = reduivy__IdvPs_Status_Config__mdt.getAll().values();
            List<reduivy__IdvPs_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvPs_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__IdvPs_Status_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Status__c && config.reduivy__Record_Type__c == 'Group') {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            statusConfigs = sortedConfigs;
        }

        return statusConfigs;
    }

    /**
     * @description Group not started statuses
     */
    private static List<String> groupNotStartedStatuses;

    /**
     * @description Return a list of not started statuses for group
     * @return List<String>
     */
    public static List<String> getGroupNotStartedStatuses() {

        if (groupNotStartedStatuses == null) {
            groupNotStartedStatuses = new List<String>();

            for (reduivy__IdvPs_Status_Config__mdt config : getGroupStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_NOTSTARTED) {
                    groupNotStartedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return groupNotStartedStatuses;
    }

    /**
     * @description Group in progress statuses
     */
    private static List<String> groupInProgressStatuses;

    /**
     * @description Return a list of in progress statuses for group
     * @return List<String>
     */
    public static List<String> getGroupInProgressStatuses() {

        if (groupInProgressStatuses == null) {
            groupInProgressStatuses = new List<String>();

            for (reduivy__IdvPs_Status_Config__mdt config : getGroupStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_INPROGRESS) {
                    groupInProgressStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return groupInProgressStatuses;
    }

    /**
     * @description Group completed statuses
     */
    private static List<String> groupCompletedStatuses;

    /**
     * @description Return a list of completed statuses for group
     * @return List<String>
     */
    public static List<String> getGroupCompletedStatuses() {

        if (groupCompletedStatuses == null) {
            groupCompletedStatuses = new List<String>();

            for (reduivy__IdvPs_Status_Config__mdt config : getGroupStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_COMPLETED) {
                    groupCompletedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return groupCompletedStatuses;
    }

    /**
     * @description Status configs metadata sorted according to Status field for Unit record type
     * @return List<reduivy__IdvPs_Status_Config__mdt>
     */
    public static List<reduivy__IdvPs_Status_Config__mdt> getUnitStatusConfig(){

        if (statusConfigs == null) {
            Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Plan_Structure__c.fields.reduivy__Status__c;
            List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

            List<reduivy__IdvPs_Status_Config__mdt> configs = reduivy__IdvPs_Status_Config__mdt.getAll().values();
            List<reduivy__IdvPs_Status_Config__mdt> sortedConfigs = new List<reduivy__IdvPs_Status_Config__mdt>();

            for (Schema.PicklistEntry ple : pleList) {
                if(ple.isActive()) {
                    for (reduivy__IdvPs_Status_Config__mdt config : configs) {
                        if (config.reduivy__Active__c && ple.getValue() == config.reduivy__Status__c && config.reduivy__Record_Type__c == 'Unit') {
                            sortedConfigs.add(config);
                        }
                    }
                }
            }

            statusConfigs = sortedConfigs;
        }

        return statusConfigs;
    }

    /**
     * @description Unit not started statuses
     */
    private static List<String> unitNotStartedStatuses;

    /**
     * @description Return a list of not started statuses for unit
     * @return List<String>
     */
    public static List<String> getUnitNotStartedStatuses() {

        if (unitNotStartedStatuses == null) {
            unitNotStartedStatuses = new List<String>();

            for (reduivy__IdvPs_Status_Config__mdt config : getUnitStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_NOTSTARTED) {
                    unitNotStartedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return unitNotStartedStatuses;
    }

    /**
     * @description Unit in progress statuses
     */
    private static List<String> unitInProgressStatuses;

    /**
     * @description Return a list of in progress statuses for unit
     * @return List<String>
     */
    public static List<String> getUnitInProgressStatuses() {

        if (unitInProgressStatuses == null) {
            unitInProgressStatuses = new List<String>();

            for (reduivy__IdvPs_Status_Config__mdt config : getUnitStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_INPROGRESS) {
                    unitInProgressStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return unitInProgressStatuses;
    }

    /**
     * @description Unit completed statuses
     */
    private static List<String> unitCompletedStatuses;

    /**
     * @description Return a list of completed statuses for unit
     * @return List<String>
     */
    public static List<String> getUnitCompletedStatuses() {

        if (unitCompletedStatuses == null) {
            unitCompletedStatuses = new List<String>();

            for (reduivy__IdvPs_Status_Config__mdt config : getUnitStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_COMPLETED) {
                    unitCompletedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return unitCompletedStatuses;
    }

    /**
     * @description Unit failed statuses
     */
    private static List<String> unitFailedStatuses;

    /**
     * @description Return a list of failed statuses for unit
     * @return List<String>
     */
    public static List<String> getUnitFailedStatuses() {

        if (unitFailedStatuses == null) {
            unitFailedStatuses = new List<String>();

            for (reduivy__IdvPs_Status_Config__mdt config : getUnitStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_FAILED) {
                    unitFailedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return unitFailedStatuses;
    }

    /**
     * @description Unit withdrawn statuses
     */
    private static List<String> unitWithdrawnStatuses;

    /**
     * @description Return a list of Withdrawn statuses for unit
     * @return List<String>
     */
    public static List<String> getUnitWithdrawnStatuses() {

        if (unitWithdrawnStatuses == null) {
            unitWithdrawnStatuses = new List<String>();

            for (reduivy__IdvPs_Status_Config__mdt config : getUnitStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_WITHDRAWN) {
                    unitWithdrawnStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return unitWithdrawnStatuses;
    }

    /**
     * @description Unit dropped statuses
     */
    private static List<String> unitDroppedStatuses;

    /**
     * @description Return a list of Dropped statuses for unit
     * @return List<String>
     */
    public static List<String> getUnitDroppedStatuses() {

        if (unitDroppedStatuses == null) {
            unitDroppedStatuses = new List<String>();

            for (reduivy__IdvPs_Status_Config__mdt config : getUnitStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_DROPPED) {
                    unitDroppedStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return unitDroppedStatuses;
    }

    /**
     * @description Unit deferred statuses
     */
    private static List<String> unitDeferredStatuses;

    /**
     * @description Return a list of Deferred statuses for unit
     * @return List<String>
     */
    public static List<String> getUnitDeferredStatuses() {

        if (unitDeferredStatuses == null) {
            unitDeferredStatuses = new List<String>();

            for (reduivy__IdvPs_Status_Config__mdt config : getUnitStatusConfig()) {
                if (config.reduivy__Type__c == STATUS_TYPE_DEFERRED) {
                    unitDeferredStatuses.add(config.reduivy__Status__c);
                }
            }
        }

        return unitDeferredStatuses;
    }

    /**
     * @description Unit non enrollable statuses
     */
    private static List<String> unitNonEnrollableStatuses;

    /**
     * @description Return a list of non enrollable statuses for unit
     * @return List<String>
     */
    public static List<String> getUnitNonEnrollableStatuses() {
        
        if (unitNonEnrollableStatuses == null) {
            unitNonEnrollableStatuses = new List<String>();

            unitNonEnrollableStatuses.addAll(getUnitInProgressStatuses());
            unitNonEnrollableStatuses.addAll(getUnitCompletedStatuses());
        }

        return unitNonEnrollableStatuses;
    }

    /**
     * @description Return a list of statuses for retry
     * @return List<String>
     */
    public static List<String> getRetryStatuses() {

        List<String> statuses = new List<String>();

        statuses.addAll(getUnitDroppedStatuses());
        statuses.addAll(getUnitFailedStatuses());
        statuses.addAll(getUnitWithdrawnStatuses());
        statuses.addAll(getUnitDeferredStatuses());

        return statuses;
    }

    /**
     * @description Init new unit individual plan structure based on unit study plan structure
     * @param individualPeId
     * @param parentGroupId
     * @param unitSps
     * @return reduivy__Individual_Plan_Structure__c
     */
    public static reduivy__Individual_Plan_Structure__c initUnitPlanStructure(Id individualPeId, Id parentGroupId, Id individualEnrollmentId, reduivy__Study_Plan_Structure__c unitSps) {

        reduivy__Individual_Plan_Structure__c newUnitIps = new reduivy__Individual_Plan_Structure__c(
            RecordTypeId = getUnitRecordTypeId(),
            reduivy__Individual_Program_Enrollment__c = individualPeId,
            reduivy__Study_Plan_Structure__c = unitSps.Id,
            reduivy__Parent_Plan_Structure__c = parentGroupId,
            reduivy__Allow_Pre_Enrollment__c = unitSps.reduivy__Allow_Pre_Enrollment__c,
            reduivy__Category__c = unitSps.reduivy__Category__c,
            reduivy__Credits__c = unitSps.reduivy__Credits__c,
            reduivy__Description__c = unitSps.reduivy__Description__c,
            reduivy__Hide_in_Enrollment__c = unitSps.reduivy__Hide_in_Enrollment__c,
            reduivy__Sequence__c = unitSps.reduivy__Sequence__c,
            reduivy__Individual_Enrollment__c = individualEnrollmentId
        );

        return newUnitIps;
    }

    /**
     * @description Return target unit id for new initiated unit ips. If null, will return either the reduivy__Alternate_Study_Unit__c or reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c
     * @param unitIps
     * @return Id
     */
    public static Id getTargetUnitId(reduivy__Individual_Plan_Structure__c unitIps, reduivy__Study_Plan_Structure__c unitSps){

        if (unitIps != null && String.isNotBlank(unitIps.reduivy__Target_Unit_Id__c)) {
            return Id.valueOf(unitIps.reduivy__Target_Unit_Id__c);
        } else if (unitIps != null && String.isNotBlank(unitIps.reduivy__Alternate_Study_Unit__c)) {
            return unitIps.reduivy__Alternate_Study_Unit__c;
        } else if (unitSps != null) {
            return unitSps.reduivy__Study_Unit__c;
        }

        return null;
    }

    /**
     * @description Return requirement logic
     * @param unitSps
     * @param sun
     * @param alternateSun
     * @return Map<String, String>
     */
    public static Map<String, String> getRequirementInfo(reduivy__Study_Plan_Structure__c unitSps, reduivy__Study_Unit__c sun, reduivy__Study_Unit__c alternateSun) {
        
        Map<String, String> requirementInfo = new Map<String, String>();
        requirementInfo.put(REQINFO_LOGIC, null);
        requirementInfo.put(REQINFO_DESC, null);

        if (alternateSun != null) {

            requirementInfo.put(REQINFO_LOGIC, alternateSun.reduivy__Requirement_Logic__c);
            requirementInfo.put(REQINFO_DESC, alternateSun.reduivy__Requirement_Description__c);

        } else if (unitSps != null && String.isNotBlank(unitSps.reduivy__Requirement_Logic__c)) {

            requirementInfo.put(REQINFO_LOGIC, unitSps.reduivy__Requirement_Logic__c);
            requirementInfo.put(REQINFO_DESC, unitSps.reduivy__Requirement_Description__c);

        } else if (sun != null) {

            requirementInfo.put(REQINFO_LOGIC, sun.reduivy__Requirement_Logic__c);
            requirementInfo.put(REQINFO_DESC, sun.reduivy__Requirement_Description__c);
        }

        return requirementInfo;
    }

    /**
     * @description Create individual plan structure group records
     * @param ipeMap Map<Id, reduivy__Individual_Program_Enrollment__c>
     */
    public static void createGroup(Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap) {

        Map<Id, Map<Id, List<reduivy__Study_Plan_Structure__c>>> spsGroupMap = SPS_Helper.getGroupMap(ipeMap.values());

        if (!spsGroupMap.isEmpty()) {
            
            // Create the ips group records and add them to the map in accordance with the sps group hierarchy
            Map<String, List<reduivy__Individual_Plan_Structure__c>> ipsGroupByParentMap = new Map<String, List<reduivy__Individual_Plan_Structure__c>>();
            Id ipsGroupRecordTypeId = IPS_Helper.getGroupRecordTypeId();

            for (reduivy__Individual_Program_Enrollment__c ipe : ipeMap.values()) {
                Map<Id, List<reduivy__Study_Plan_Structure__c>> spsgMap = spsGroupMap.get(ipe.reduivy__Study_Plan__c);

                for (Id spsgParentId : spsgMap.keySet()) {
                    for (reduivy__Study_Plan_Structure__c spsg : spsgMap.get(spsgParentId)) {
                        reduivy__Individual_Plan_Structure__c ipsg = new reduivy__Individual_Plan_Structure__c();
                        ipsg.RecordTypeId = ipsGroupRecordTypeId;
                        ipsg.reduivy__Individual_Program_Enrollment__c = ipe.Id;
                        ipsg.reduivy__Study_Plan_Structure__c = spsg.Id;
                        ipsg.reduivy__Category__c = spsg.reduivy__Category__c;
                        ipsg.reduivy__Credits__c = spsg.reduivy__Credits__c;
                        ipsg.reduivy__Max_Credits__c = spsg.reduivy__Max_Credits__c;
                        ipsg.reduivy__Description__c = spsg.reduivy__Description__c;
                        ipsg.reduivy__Units_Required__c = spsg.reduivy__Units_Required__c;
                        ipsg.reduivy__Hide_in_Enrollment__c = spsg.reduivy__Hide_in_Enrollment__c;
                        ipsg.reduivy__Credits_equivalent_per_Unit__c = spsg.reduivy__Credits_equivalent_per_Unit__c;
                        ipsg.reduivy__Sequence__c = spsg.reduivy__Sequence__c;

                        String ipeSpsParentKey = ipe.Id + '_' + spsgParentId;

                        if (!ipsGroupByParentMap.containsKey(ipeSpsParentKey)) {
                            ipsGroupByParentMap.put(ipeSpsParentKey, new List<reduivy__Individual_Plan_Structure__c>());
                        }

                        ipsGroupByParentMap.get(ipeSpsParentKey).add(ipsg);
                    }
                }
            }
            if (!ipsGroupByParentMap.isEmpty()) {

                // Insert the records
                List<reduivy__Individual_Plan_Structure__c> ipsGroupsList = new List<reduivy__Individual_Plan_Structure__c>();
                for (List<reduivy__Individual_Plan_Structure__c> ipsGroups : ipsGroupByParentMap.values()) {
                    ipsGroupsList.addAll(ipsGroups);
                }

                REDU_Database_UTIL.doInsert(ipsGroupsList, ipeMap, 'reduivy__Individual_Program_Enrollment__c', false);

                List<reduivy__Individual_Plan_Structure__c> ipsGroupsListToUpdate = new List<reduivy__Individual_Plan_Structure__c>();
                for(reduivy__Individual_Plan_Structure__c ipsGroupToUpdate : ipsGroupsList) {
                    if(ipsGroupToUpdate.Id != null) {
                        ipsGroupsListToUpdate.add(ipsGroupToUpdate);
                    }
                }

                // Update the child records with their parent Ids
                for (reduivy__Individual_Plan_Structure__c ipsg : ipsGroupsListToUpdate) {
                    String ipeSpsParentKey = ipsg.reduivy__Individual_Program_Enrollment__c + '_' + ipsg.reduivy__Study_Plan_Structure__c;

                    if (ipsGroupByParentMap.containsKey(ipeSpsParentKey)) {
                        for (reduivy__Individual_Plan_Structure__c ipsgChild : ipsGroupByParentMap.get(ipeSpsParentKey)) {
                            ipsgChild.reduivy__Parent_Plan_Structure__c = ipsg.Id;
                        }
                    }
                }

                REDU_Database_UTIL.doUpdate(ipsGroupsListToUpdate, ipeMap, 'reduivy__Individual_Program_Enrollment__c', false);
            }
        }
    }

    /**
     * @description Update the Individual Plan Structure Unit's status according to the custom metadata
     * @param ipsUnitList
     * @param ienMap Required fields are reduivy__Grade_Result__c, reduivy__Enrollment_Status__c
     * @return List<reduivy__Individual_Plan_Structure__c>
     */
    public static List<reduivy__Individual_Plan_Structure__c> updateIpsUnitStatus(List<reduivy__Individual_Plan_Structure__c> ipsUnitList, Map<Id, reduivy__Individual_Enrollment__c> ienMap){

        Map<String, String> ipsuStatusMap = getIpsuStatusMap();

        //ISS-002464
        String notStartedStatus = getUnitNotStartedStatuses().get(0);

        for (reduivy__Individual_Plan_Structure__c ipsu : ipsUnitList) {

            if(String.isNotBlank(ipsu.reduivy__Individual_Enrollment__c) && ienMap.containsKey(ipsu.reduivy__Individual_Enrollment__c)){

                // Create individual enrollment key for individual plan structure status map
                // We will match based on enrollment status + result, if not found, will try with enrollment status only
                String ienStatusResultKey = String.isNotBlank(ienMap.get(ipsu.reduivy__Individual_Enrollment__c).reduivy__Grade_Result__c) ? ienMap.get(ipsu.reduivy__Individual_Enrollment__c).reduivy__Enrollment_Status__c + '_' + ienMap.get(ipsu.reduivy__Individual_Enrollment__c).reduivy__Grade_Result__c : ienMap.get(ipsu.reduivy__Individual_Enrollment__c).reduivy__Enrollment_Status__c;
                String ienStatusKey = ienMap.get(ipsu.reduivy__Individual_Enrollment__c).reduivy__Enrollment_Status__c;

                // Update the individual plan structure status according the custom metadata mapping
                String targetStatus;
                if (ipsuStatusMap.containsKey(ienStatusResultKey)) {
                    targetStatus = ipsuStatusMap.get(ienStatusResultKey);
                } else if (ipsuStatusMap.containsKey(ienStatusKey)) {
                    targetStatus = ipsuStatusMap.get(ienStatusKey);
                }

                ipsu.reduivy__Status__c = String.isNotBlank(targetStatus) ? targetStatus : ipsu.reduivy__Status__c;

            } else if (String.isBlank(ipsu.reduivy__Individual_Enrollment__c)) {
                //ISS-002464 reset if the ien is blank
                ipsu.reduivy__Status__c = notStartedStatus;
            }
        }

        return ipsUnitList;
    }

    /**
     * @description Get map of individual plan structure (unit) statuses
     * @return Map<String, String>
     */
    public static Map<String, String> getIpsuStatusMap() {

        Map<String, String> ipsuStatusMap = new Map<String, String>();
        List<reduivy__IdvEn_Enrollment_Status_Config__mdt> ienEnrollmentStatusConfigs = IEN_Helper.getEnrollmentStatusConfig();

        for (reduivy__IdvEn_Enrollment_Status_Config__mdt sc : ienEnrollmentStatusConfigs) {

            String mapKey = sc.reduivy__Enrollment_Status__c;
            if (String.isNotBlank(sc.reduivy__Grade_Result__c)) {
                mapKey = mapKey + '_' + sc.reduivy__Grade_Result__c;
            }

            ipsuStatusMap.put(mapKey, sc.reduivy__Individual_Plan_Structure_Unit_Status__c);
        }

        return ipsuStatusMap;
    }

    /**
     * @description Get Individual Academic Profile Id from Individual Plan Structure Unit
     * @param ipsUnit
     * @return Id
     */
    public static Id getIpfId(reduivy__Individual_Plan_Structure__c ipsUnit) {
        Id academicProfileId = String.isNotBlank(ipsUnit?.reduivy__Individual_Program_Enrollment__r?.reduivy__Master_Enrollment__c) 
        ? ipsUnit?.reduivy__Individual_Program_Enrollment__r?.reduivy__Master_Enrollment__r?.reduivy__Individual_Academic_Profile__c 
        : ipsUnit?.reduivy__Individual_Program_Enrollment__r?.reduivy__Individual_Academic_Profile__c;
        
        return academicProfileId;
    }
}