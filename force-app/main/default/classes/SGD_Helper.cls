/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Object Helper
 * @description Study Grading Scheme object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SGD_Helper implements SObject_Helper {
    
    /**
     * @description Letter grade scoring range - Lower range
     */
    public static final String SCORINGRANGE_LOWERRANGE = 'Lower Range';

    /**
     * @description Letter grade scoring range - Higher range
     */
    public static final String SCORINGRANGE_HIGHERRANGE = 'Higher Range';

    /**
     * @description Exclude Credits Earned - Yes
     */
    public static final String EXCLUDE_CREDITSEARNED_YES = 'Yes';

    /**
     * @description Exclude Credits Earned - No
     */
    public static final String EXCLUDE_CREDITSEARNED_NO = 'No';

    /**
     * @description Exclude GPA - Yes
     */
    public static final String EXCLUDE_GPA_YES = 'Yes';

    /**
     * @description Exclude GPA - No
     */
    public static final String EXCLUDE_GPA_No = 'No';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Grading_Scheme__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Grading_Scheme__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Grading_Scheme__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Grading_Scheme__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
	
    /**
     * @description Study grading schemes grouped by study grade setting available in the educational institution
     */
    private static Map<Id, List<reduivy__Study_Grading_Scheme__c>> sgdBySgsMap;

    /**
     * @description Return all study grading schemes grouped by study grade setting
     * @param studyGradeSettingIds Set of study grade setting id
     * @param useCachedData Use cached data to reduce query
     * @return Map<Id, List<reduivy__Study_Grading_Scheme__c>>
     */
    public static Map<Id, List<reduivy__Study_Grading_Scheme__c>> getStudyGradingSchemes(Set<Id> studyGradeSettingIds, Boolean useCachedData) {

        if (sgdBySgsMap == null) {
            sgdBySgsMap = new Map<Id, List<reduivy__Study_Grading_Scheme__c>>();
        }

        if (!studyGradeSettingIds.isEmpty()) {
            Set<Id> sgsIdsForQuery = new Set<Id>();

            if (useCachedData) {
                for (Id sgsId : studyGradeSettingIds) {
                    //we only query the record if it doesn't exist in the map
                    if (!sgdBySgsMap.containsKey(sgsId)) {
                        sgsIdsForQuery.add(sgsId);
                    }
                }
            } else {
                sgsIdsForQuery.addAll(studyGradeSettingIds);
            }

            if (!sgsIdsForQuery.isEmpty()) {
                for (reduivy__Study_Grading_Scheme__c sgd : [SELECT Id,
                    Name,
                    reduivy__Numerical_Grade_Lower_Range__c,
                    reduivy__Numerical_Grade_Higher_Range__c,
                    reduivy__Letter_Grade__c,
                    reduivy__Letter_Grade_Scoring_Range__c,
                    reduivy__Grade_Points__c,
                    reduivy__Grade_Result__c,
                    reduivy__For_Fail_Absent__c,
                    reduivy__Exclude_Credits_Earned__c,
                    reduivy__Exclude_GPA_Calculation__c,
                    reduivy__Study_Grade_Setting__c,
                    reduivy__Enrollment_Status__c
                    FROM reduivy__Study_Grading_Scheme__c
                    WHERE reduivy__Study_Grade_Setting__c IN: sgsIdsForQuery
                    WITH USER_MODE
                    ORDER BY reduivy__Sequence__c ASC NULLS LAST
                ]) {
                    if (!sgdBySgsMap.containsKey(sgd.reduivy__Study_Grade_Setting__c)) {
                        sgdBySgsMap.put(sgd.reduivy__Study_Grade_Setting__c, new List<reduivy__Study_Grading_Scheme__c>());
                    }

                    sgdBySgsMap.get(sgd.reduivy__Study_Grade_Setting__c).add(sgd);
                }
            }
        }

        return sgdBySgsMap;
    }

    /**
     * @description Match the study grading scheme and return the related info
     * @param numericalGrade
     * @param letterGrade
     * @param studyGradingSchemes
     * @return Map<String, Object>
     */
    public static Map<String, Object> matchGradingScheme(Decimal numericalGrade, String letterGrade, List<reduivy__Study_Grading_Scheme__c> studyGradingSchemes, String attRequirementMet) {
        
        reduivy__Study_Grading_Scheme__c matchedGradingScheme;

        for (reduivy__Study_Grading_Scheme__c sgd : (studyGradingSchemes == null ? new List<reduivy__Study_Grading_Scheme__c>() : studyGradingSchemes)) {

            // Marked ien as fail absent if the related individual session enrollment doesn't meet the required attendance percentage
            if (attRequirementMet == IEN_Helper.ATTENDANCE_REQUIREMENT_MET_NO) {
                if (sgd.reduivy__For_Fail_Absent__c) {
                    matchedGradingScheme = sgd;
                    break;
                }
            } else if (numericalGrade != null) {
                //numerical grade takes precedence
                if (sgd.reduivy__Numerical_Grade_Lower_Range__c != null && 
                    sgd.reduivy__Numerical_Grade_Higher_Range__c != null &&
                    sgd.reduivy__Numerical_Grade_Lower_Range__c <= numericalGrade &&
                    sgd.reduivy__Numerical_Grade_Higher_Range__c >= numericalGrade
                ) {
                    matchedGradingScheme = sgd;

                    break;
                }
            } else if (String.isNotBlank(letterGrade)) {
                if (letterGrade.equals(sgd.reduivy__Letter_Grade__c)) {
                    matchedGradingScheme = sgd;

                    break;
                }
            }
        }

        if (matchedGradingScheme != null) {
            Map<String, Object> gradingSchemeInfo = new Map<String, Object>();
            gradingSchemeInfo.put('reduivy__Letter_Grade__c', matchedGradingScheme.reduivy__Letter_Grade__c);
            gradingSchemeInfo.put('reduivy__Numerical_Grade__c', matchedGradingScheme.reduivy__Letter_Grade_Scoring_Range__c == SGD_Helper.SCORINGRANGE_LOWERRANGE ? matchedGradingScheme.reduivy__Numerical_Grade_Lower_Range__c : matchedGradingScheme.reduivy__Numerical_Grade_Higher_Range__c);
            gradingSchemeInfo.put('reduivy__Grade_Points__c', matchedGradingScheme.reduivy__Grade_Points__c);
            gradingSchemeInfo.put('reduivy__Grade_Result__c', matchedGradingScheme.reduivy__Grade_Result__c);
            gradingSchemeInfo.put('reduivy__Exclude_Credits_Earned__c', matchedGradingScheme.reduivy__Exclude_Credits_Earned__c);
            gradingSchemeInfo.put('reduivy__Exclude_GPA_Calculation__c', matchedGradingScheme.reduivy__Exclude_GPA_Calculation__c);
            gradingSchemeInfo.put('reduivy__Enrollment_Status__c', matchedGradingScheme.reduivy__Enrollment_Status__c);

            return gradingSchemeInfo;

        } else {
            return null;
        }
    }

}