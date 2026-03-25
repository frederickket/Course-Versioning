/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Study Plan Structure object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001662 08-10-2023 dblack - added method: getGroupMap()
 * ISS-001946 19-06-2024 Sueanne - add sequence field in group ips creation
 */
global inherited sharing class SPS_Helper implements SObject_Helper {

    /**
     * @description Category - Required
     */
	public static final String CATEGORY_REQUIRED = 'Required';

    /**
     * @description Category - Optional
     */
    public static final String CATEGORY_OPTIONAL = 'Optional';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Plan_Structure__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Plan_Structure__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Plan_Structure__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Plan_Structure__c);

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
            rtMap = Schema.SObjectType.reduivy__Study_Plan_Structure__c.getRecordtypeInfosByDeveloperName();
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
     * @description Return group map: study plan Id => map: study plan structure parent Id => list of study plan structure (record type: Group)
     * @param ipeList List<reduivy__Individual_Program_Enrollment__c>
     * @return Map<Id, Map<Id, List<reduivy__Study_Plan_Structure__c>>> (key1: study plan Id; key2: parent study plan structure Id)
     */
    public static Map<Id, Map<Id, List<reduivy__Study_Plan_Structure__c>>> getGroupMap(List<reduivy__Individual_Program_Enrollment__c> ipeList) {

        Map<Id, Map<Id, List<reduivy__Study_Plan_Structure__c>>> groupMap = new Map<Id, Map<Id, List<reduivy__Study_Plan_Structure__c>>>();
        List<reduivy__Study_Plan_Structure__c> grpList = new List<reduivy__Study_Plan_Structure__c>();
        Set<Id> splIdSet = new Set<Id>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            if (String.isNotBlank(ipe.reduivy__Study_Plan__c)) {
                splIdSet.add(ipe.reduivy__Study_Plan__c);
            }
        }
        if (!splIdSet.isEmpty()) {
            grpList = [
                SELECT  Id, Name, reduivy__Category__c, reduivy__Credits__c, reduivy__Max_Credits__c, reduivy__Credits_equivalent_per_Unit__c,
                        reduivy__Description__c, reduivy__Study_Unit__c, reduivy__Units_Required__c, reduivy__Hide_in_Enrollment__c,
                        reduivy__Study_Plan__c, reduivy__Parent_Study_Plan_Structure__c, reduivy__Sequence__c
                FROM reduivy__Study_Plan_Structure__c
                WHERE reduivy__Study_Plan__c IN :splIdSet
                AND RecordTypeId = :getGroupRecordTypeId()
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ];
            if (!grpList.isEmpty()) {
                for (reduivy__Study_Plan_Structure__c grp : grpList) {
                    if (!groupMap.containsKey(grp.reduivy__Study_Plan__c)) {
                        groupMap.put(grp.reduivy__Study_Plan__c, new Map<Id, List<reduivy__Study_Plan_Structure__c>>());
                    }
                    if (!groupMap.get(grp.reduivy__Study_Plan__c).containsKey(grp.reduivy__Parent_Study_Plan_Structure__c)) {
                        groupMap.get(grp.reduivy__Study_Plan__c).put(grp.reduivy__Parent_Study_Plan_Structure__c, new List<reduivy__Study_Plan_Structure__c>());
                    }
                    groupMap.get(grp.reduivy__Study_Plan__c).get(grp.reduivy__Parent_Study_Plan_Structure__c).add(grp);
                }
            }
        }

        return groupMap;
    }
}