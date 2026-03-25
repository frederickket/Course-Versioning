/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Object Helper
 * @description Study Cohort Enrollment object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001979 19-07-2024 Sueanne - added enrollment settings
 */
global inherited sharing class SCE_Helper implements SObject_Helper {

    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Unit Enrollment Setting - Default
     */
    public static final String UNIT_ENROLLMENT_DEFAULT = 'Default';

    /**
     * @description Unit Enrollment Setting - Allow Enrolled Pre-requisite Units
     */
    public static final String UNIT_ENROLLMENT_ALLOW_PREREQUISITE = 'Allow Enrolled Pre-requisite Units';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Cohort_Enrollment__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Cohort_Enrollment__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Cohort_Enrollment__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Cohort_Enrollment__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Return study cohort enrollment that matches the IPE details
     * @param academicTermId
     * @param cohortID
     * @param classStanding
     * @param classYear
     * @return reduivy__Study_Cohort_Enrollment__c
     */
    public static reduivy__Study_Cohort_Enrollment__c getStudyCohortEnrollment(Id academicTermId, String cohortID, String classStanding, String classYear) {

        reduivy__Study_Cohort_Enrollment__c sce;

        for (reduivy__Study_Cohort_Enrollment__c availableSce : [SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c,
            reduivy__Cohort_ID__c,
            reduivy__Pre_enrollment_Open_Date__c,
            reduivy__Enrollment_Open_Date__c,
            reduivy__Enrollment_Close_Date__c,
            reduivy__Study_Offering_Status__c,
            reduivy__Unit_Enrollment_Setting__c
            FROM reduivy__Study_Cohort_Enrollment__c
            WHERE reduivy__Academic_Term__c =: academicTermId
            AND reduivy__Status__c =: SCE_Helper.STATUS_ACTIVE
            WITH USER_MODE
            ORDER BY Name
        ]) {
            if (String.isNotBlank(cohortID) 
                && String.isNotBlank(availableSce.reduivy__Cohort_ID__c)
                && cohortID == availableSce.reduivy__Cohort_ID__c
            ) {
                //by Cohort_ID
                sce = availableSce;
                break;

            } else if (String.isNotBlank(classStanding)
                && String.isNotBlank(classYear)
                && String.isNotBlank(availableSce.reduivy__Class_Standing__c)
                && String.isNotBlank(availableSce.reduivy__Class_Year__c)
                && classStanding == availableSce.reduivy__Class_Standing__c
                && classYear == availableSce.reduivy__Class_Year__c
            ) {
                //by class year and class standing
                sce = availableSce;
                break;

            } else if(String.isNotBlank(availableSce.reduivy__Class_Standing__c)
                && String.isBlank(availableSce.reduivy__Class_Year__c)
                && classStanding == availableSce.reduivy__Class_Standing__c
            ) {
                //by class standing
                sce = availableSce;
                break;

            } else if(String.isNotBlank(availableSce.reduivy__Class_Year__c)
                && String.isBlank(availableSce.reduivy__Class_Standing__c)
                && classYear == availableSce.reduivy__Class_Year__c
            ) {
                //by class year
                sce = availableSce;
                break;
            }
        }

        return sce;
    }
	
}