/**
 * @author      WDCi (XW)
 * @date        Jul 2025
 * @group       Object Helper
 * @description Individual Score Detail object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002506 16-07-2025 XW - new class
 */
global inherited sharing class ISD_Helper implements SObject_Helper {
    
    /**
     * @description Status - Active
     */
    global static String STATUS_ACTIVE = 'Active';
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Score_Detail__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Score_Detail__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Score_Detail__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Score_Detail__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
    
    /**
     * @description list of fields that has the same name in study requirement and individual requirement
     * @return   Set<String>
     */
    private static Set<String> scrIsdCommonFields;

    /**
     * @description get list of fields that has the same name in study requirement and individual requirement
     * @return   Set<String>
     */
    public static Set<String> getScrIsdCommonFields(){
        if(scrIsdCommonFields == null) {
            scrIsdCommonFields = new Set<String>();
            Set<String> isdCloningFields = REDU_Metadata_UTIL.getObjectFieldsForCloning(getApiName(), AccessType.CREATABLE);

            Map<String, Schema.SObjectField> scrFieldsMap = Schema.SObjectType.reduivy__Study_Scoring_Criteria__c.fields.getMap();
            Map<String, Schema.SObjectField> isdFieldsMap = Schema.SObjectType.reduivy__Individual_Score_Detail__c.fields.getMap();
            
            for(Schema.SObjectField scrField : scrFieldsMap.values()) {
                Schema.DescribeFieldResult scrFieldResult = scrField.getDescribe();
                String scrFieldName = scrFieldResult.getName();

                if(isdCloningFields.contains(scrFieldName)) {
                    scrIsdCommonFields.add(scrFieldName);
                }
            }
        }

        return scrIsdCommonFields;
      
    }

    /**
     * @description create a individual score detail from the given study scoring criteria and the individual score id
     * @param  scr   study scoring criteria
     * @param  iscId individual score id
     * @return       reduivy__Individual_Score_Detail__c
     */
    public static reduivy__Individual_Score_Detail__c createIsd(reduivy__Study_Scoring_Criteria__c scr, Id iscId) {
        Set<String> commonFields = getScrIsdCommonFields();

        reduivy__Individual_Score_Detail__c isd = new reduivy__Individual_Score_Detail__c();
        for(String commonField : commonFields) {
            isd.put(commonField, scr.get(commonField));
        }

        isd.reduivy__Study_Scoring_Criteria__c = scr.Id;
        isd.reduivy__Individual_Score__c = iscId;

        return isd;


    }


}