/**
 * @author      WDCi (XW)
 * @date        Jul 2025
 * @group       Object Helper
 * @description Study Scoring Criteria object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002506 16-07-2025 XW - new class
 */
global inherited sharing class SCR_Helper implements SObject_Helper {

    /**
     * @description Status - Draft
     */
    global static String STATUS_DRAFT = 'Draft';

    /**
     * @description Status - Active
     */
    global static String STATUS_ACTIVE = 'Active';

    /**
     * @description Status - Archived
     */
    global static String STATUS_ARCHIVED = 'Archived';
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Scoring_Criteria__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Scoring_Criteria__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Scoring_Criteria__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Scoring_Criteria__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Return group map: study scoring config Id => map: study scoring criteria parent Id => list of study scoring criteria
     * @param scfLiscfIdSetst set of study scoring config Id
     * @return Map<Id, Map<Id, List<reduivy__Study_Scoring_Criteria__c>>> (key1: study scoring config Id; key2: parent study scoring criteria id)
     */
    public static Map<Id, Map<Id, List<reduivy__Study_Scoring_Criteria__c>>> getGroupMap(Set<Id> scfIdSet) {

        Map<Id, Map<Id, List<reduivy__Study_Scoring_Criteria__c>>> groupMap = new Map<Id, Map<Id, List<reduivy__Study_Scoring_Criteria__c>>>();
        if (scfIdSet != null && !scfIdSet.isEmpty()) {
            Set<String> scrFields = new Set<String> {
                'reduivy__Code__c', 
                'reduivy__Study_Scoring_Config__c', 
                'reduivy__Parent_Criteria__c',
                'reduivy__Study_Requirement__r.reduivy__Study_Requirement_Set__c',
                'reduivy__Sample_Record_Code__c'
            };

            scrFields.addAll(ISD_Helper.getScrIsdCommonFields());

            String scrQuery = 'SELECT ' + String.join(scrFields, ', ') +
                             ' FROM ' + SCR_Helper.getApiName() +
                             ' WHERE reduivy__Study_Scoring_Config__c IN :scfIdSet' +
                             ' AND reduivy__Status__c = :scrStatusActive' +
                             ' AND reduivy__Study_Scoring_Config__r.reduivy__Status__c = :scfStatusActive' +
                             ' ORDER BY reduivy__Sequence__c ASC NULLS LAST';

            Map<String, Object> bindMap = new Map<String, Object> {
                'scrStatusActive' => SCR_Helper.STATUS_ACTIVE,
                'scfStatusActive' => STATUS_ACTIVE,
                'scfIdSet' => scfIdSet
            };

            for (reduivy__Study_Scoring_Criteria__c scrGroup : (List<reduivy__Study_Scoring_Criteria__c>) Database.queryWithBinds(scrQuery, bindMap, AccessLevel.USER_MODE)) {
                if (!groupMap.containsKey(scrGroup.reduivy__Study_Scoring_Config__c)) {
                    groupMap.put(scrGroup.reduivy__Study_Scoring_Config__c, new Map<Id, List<reduivy__Study_Scoring_Criteria__c>>());
                }

                //expecting null key in the map as the parent criteria could be null for top level criteria
                if (!groupMap.get(scrGroup.reduivy__Study_Scoring_Config__c).containsKey(scrGroup.reduivy__Parent_Criteria__c)) {
                    groupMap.get(scrGroup.reduivy__Study_Scoring_Config__c).put(scrGroup.reduivy__Parent_Criteria__c, new List<reduivy__Study_Scoring_Criteria__c>());
                }
                
                groupMap.get(scrGroup.reduivy__Study_Scoring_Config__c).get(scrGroup.reduivy__Parent_Criteria__c).add(scrGroup);
            }
            
        }

        return groupMap;
    }
}