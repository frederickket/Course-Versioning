/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Object Helper
 * @description Study Pathway Term object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001662 12-10-2023 dblack - added method: getPathwayTermsMap()
 */
global inherited sharing class SPT_Helper implements SObject_Helper {
    
    /**
     * @description Enrollment Method - Manual
     */
    public static final String ENROLLMENTMETHOD_MANUAL = 'Manual';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Pathway_Term__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Pathway_Term__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Pathway_Term__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Pathway_Term__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Return map of the study pathway term records
     * @param ipeList List<reduivy__Individual_Program_Enrollment__c>
     * @return sptMap Map<Id, List<reduivy__Study_Pathway_Term__c>> (mapKey: study pathway Id)
     */
    public static Map<Id, List<reduivy__Study_Pathway_Term__c>> getPathwayTermMap(List<reduivy__Individual_Program_Enrollment__c> ipeList) {

        Map<Id, List<reduivy__Study_Pathway_Term__c>> sptMap = new Map<Id, List<reduivy__Study_Pathway_Term__c>>();
        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            sptMap.put(ipe.reduivy__Study_Pathway__c, new List<reduivy__Study_Pathway_Term__c>());
        }
        if (!sptMap.isEmpty()) {
            List<reduivy__Study_Pathway_Term__c> sptList = [
                SELECT  Id, reduivy__Description__c, reduivy__Enrollment_Method__c,
                        reduivy__Max_Credits__c, reduivy__Recommended_Credits__c,
                        reduivy__Study_Pathway__c, reduivy__Term_Number__c,
                        reduivy__Study_Pathway__r.reduivy__Default__c,
                        reduivy__Study_Pathway__r.reduivy__Study_Plan__c
                FROM reduivy__Study_Pathway_Term__c
                WHERE reduivy__Study_Pathway__c IN :sptMap.keySet()
                AND reduivy__Study_Pathway__r.reduivy__Status__c = 'Active'
                WITH USER_MODE
                ORDER BY reduivy__Term_Number__c
            ];
            if (!sptList.isEmpty()) {
                for (reduivy__Study_Pathway_Term__c spt : sptList) {
                    if (sptMap.containsKey(spt.reduivy__Study_Pathway__c)) {
                        sptMap.get(spt.reduivy__Study_Pathway__c).add(spt);
                    }
                }
            }
        }

        return sptMap;
    }
}