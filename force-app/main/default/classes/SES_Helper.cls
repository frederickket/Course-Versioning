/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Object Helper
 * @description Study Enrollment Setting object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002231 08-04-2025 Lean - Max attempt configuration and validation
 * ISS-002447 13-05-2025 Lean - Max attempt indication
 */
global inherited sharing class SES_Helper implements SObject_Helper {
    
    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Status - Active
     */
    public static final String TYPE_UNIT_MAX_ATTEMPT = 'Unit Enrollment Max Attempt';

    /**
     * @description Action - Allow
     */
    public static final String ACTION_ALLOW = 'Allow';

    /**
     * @description Action - Block
     */
    public static final String ACTION_BLOCK = 'Block';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Enrollment_Setting__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Enrollment_Setting__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Enrollment_Setting__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Enrollment_Setting__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Get study enrollment settings by type and related parent ids
     * @param type
     * @param eduInstIds
     * @param spgIds
     * @param sunIds
     * @param ipeIds
     * @return Map<String, reduivy__Study_Enrollment_Setting__c> 
     */
    public static Map<String, reduivy__Study_Enrollment_Setting__c> getStudyEnrollmentSettings(String type, Set<Id> eduInstIds, Set<Id> spgIds, Set<Id> sunIds, Set<Id> ipeIds) {

        Set<String> sesFields = new Set<String>{
            'Id',
            'Name',
            'reduivy__Action__c',
            'reduivy__Educational_Institution__c',
            'reduivy__Study_Program__c',
            'reduivy__Study_Unit__c',
            'reduivy__Individual_Program_Enrollment__c',
            'reduivy__Number__c',
            'reduivy__Type__c'            
        };

        Map<String, Object> sesBindParams = new Map<String, Object>();
        sesBindParams.put('type', type);
        sesBindParams.put('status', STATUS_ACTIVE);

        String sesSoql = 'SELECT ' + String.join(sesFields, ', ') + 
            ' FROM reduivy__Study_Enrollment_Setting__c ' +
            ' WHERE reduivy__Type__c =: type ' +
            ' AND reduivy__Status__c =: status ';
        
        List<String> sesAddOnCriteria = new List<String>();

        if (eduInstIds != null && !eduInstIds.isEmpty()) {
            sesBindParams.put('eduInstIds', eduInstIds);
            sesAddOnCriteria.add(' reduivy__Educational_Institution__c IN: eduInstIds ');
        }

        if (spgIds != null && !spgIds.isEmpty()) {
            sesBindParams.put('spgIds', spgIds);
            sesAddOnCriteria.add(' reduivy__Study_Program__c IN: spgIds ');
        }

        if (sunIds != null && !sunIds.isEmpty()) {
            sesBindParams.put('sunIds', sunIds);
            sesAddOnCriteria.add(' reduivy__Study_Unit__c IN: sunIds ');
        }

        if (ipeIds != null && !ipeIds.isEmpty()) {
            sesBindParams.put('ipeIds', ipeIds);
            sesAddOnCriteria.add(' reduivy__Individual_Program_Enrollment__c IN: ipeIds ');
        }

        if (!sesAddOnCriteria.isEmpty()) {
            sesSoql += ' AND ( ' + String.join(sesAddOnCriteria, ' OR ') + ' ) ';
        }

        sesSoql += ' ORDER BY Name ASC';

        Map<String, Set<String>> objectFieldsForFls = new Map<String, Set<String>>();
        objectFieldsForFls.put(SES_Helper.getApiName(), sesFields);

        //query the study enrollment settings which is a system setting that normal user doesn't have direct access
        Map<String, reduivy__Study_Enrollment_Setting__c> sesMap = new Map<String, reduivy__Study_Enrollment_Setting__c>();
        for (reduivy__Study_Enrollment_Setting__c ses : (List<reduivy__Study_Enrollment_Setting__c>) REDU_SystemMode_UTIL.doQuery(sesSoql, sesBindParams, objectFieldsForFls)) {
            
            if (String.isNotBlank(ses.reduivy__Educational_Institution__c) &&
                String.isBlank(ses.reduivy__Study_Program__c) &&
                String.isBlank(ses.reduivy__Study_Unit__c)            
            ) {
                //edu inst
                sesMap.put(
                    generateIdentifier(new List<String>{ses.reduivy__Educational_Institution__c}), 
                    ses
                );

            } else if (String.isNotBlank(ses.reduivy__Educational_Institution__c) &&
                String.isNotBlank(ses.reduivy__Study_Program__c) &&
                String.isBlank(ses.reduivy__Study_Unit__c)
            ) {
                //edu inst + study program
                sesMap.put(
                    generateIdentifier(new List<String>{ses.reduivy__Educational_Institution__c, ses.reduivy__Study_Program__c}), 
                    ses
                );

            } else if (String.isNotBlank(ses.reduivy__Educational_Institution__c) &&
                String.isNotBlank(ses.reduivy__Study_Unit__c) &&
                String.isBlank(ses.reduivy__Study_Program__c) 
            ) {
                //edu inst + study unit
                sesMap.put(
                    generateIdentifier(new List<String>{ses.reduivy__Educational_Institution__c, ses.reduivy__Study_Unit__c}), 
                    ses
                );
                
            } else if (String.isNotBlank(ses.reduivy__Educational_Institution__c) &&
                String.isNotBlank(ses.reduivy__Study_Unit__c) &&
                String.isNotBlank(ses.reduivy__Study_Program__c) 
            ) {
                //edu inst + study program + study unit
                sesMap.put(
                    generateIdentifier(new List<String>{ses.reduivy__Educational_Institution__c, ses.reduivy__Study_Program__c, ses.reduivy__Study_Unit__c}), 
                    ses
                );
                
            } else if (String.isNotBlank(ses.reduivy__Individual_Program_Enrollment__c) &&
                String.isBlank(ses.reduivy__Study_Unit__c)
            ) {
                //individual program enrollment
                sesMap.put(
                    generateIdentifier(new List<String>{ses.reduivy__Individual_Program_Enrollment__c}), 
                    ses
                );
                
            } else if (String.isNotBlank(ses.reduivy__Individual_Program_Enrollment__c) &&
                String.isNotBlank(ses.reduivy__Study_Unit__c)
            ) {
                //individual program enrollment + study unit
                sesMap.put(
                    generateIdentifier(new List<String>{ses.reduivy__Individual_Program_Enrollment__c, ses.reduivy__Study_Unit__c}), 
                    ses
                );
            }
        }

        return sesMap;
    }

    /**
     * @description Generate study enrollment settings key
     * @param keys
     * @return String
     */
    public static String generateIdentifier(List<String> keys) {
        return String.join(keys, '_');
    }
}