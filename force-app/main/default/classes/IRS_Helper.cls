/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Object Helper
 * @description Individual Requirement Set object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002128 05-06-2025 XW - new class
 */

global inherited sharing class IRS_Helper implements SObject_Helper{

    /**
     * @description Individual Requirement Status - Draft
     */
    global static final String STATUS_DRAFT = 'Draft';
    
    /**
     * @description Individual Requirement Status - Active
     */
    global static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Individual Requirement Status - Archived
     */
    global static final String STATUS_ARCHIVED = 'Archived';

    /**
     * @description Individual Requirement Generation Mode - Auto
     */
    global static final String REQUIREMENT_GENERATION_MODE_AUTO = 'Auto';
    
    /**
     * @description Individual Requirement Generation Mode - Manual
     */
    global static final String REQUIREMENT_GENERATION_MODE_MANUAL = 'Manual';
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Requirement_Set__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Requirement_Set__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Requirement_Set__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Requirement_Set__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description create an individual requirement set from a study requirement set
     * @param  srs   the study requirement set record
     * @param  sobj  parent sobj record
     * @return       individual requirement set
     */
    public static reduivy__Individual_Requirement_Set__c createIrs(reduivy__Study_Requirement_Set__c srs, SObject sobj, Id ownerId) {
        reduivy__Individual_Requirement_Set__c irs = new reduivy__Individual_Requirement_Set__c();
        
        //non common fields
        irs.OwnerId = ownerId; 
        irs.reduivy__Study_Requirement_Set__c = srs.Id;
        
        //common fields
        Set<String> commonFields = getSrsIrsCommonFields();
        for(String field : commonFields) {
            irs.put(field, srs.get(field));
        }

        if(sobj != null) {
            String objectLookupField = REDU_Metadata_UTIL.getObjectLookupField(IRS_Helper.getApiName(), srs.reduivy__Object__c);
            irs.put(objectLookupField, sobj.Id);
            if(String.isNotBlank(srs.reduivy__Contact_Field__c)) {
                irs.reduivy__Contact__c = (Id) REDU_SObject_UTIL.extractFieldValue(sobj, srs.reduivy__Contact_Field__c);
            }
        }

        return irs;
    }

    /**
     * @description list of fields that has the same name in study requirement set and individual requirement set
     * @return   Set<String>
     */
    private static Set<String> srsIrsCommonFields;

    /**
     * @description get list of fields that has the same name in study requirement set and individual requirement set
     * @return   Set<String>
     */
    public static Set<String> getSrsIrsCommonFields(){
        if(srsIrsCommonFields == null) {
            srsIrsCommonFields = new Set<String>();
            Set<String> irsCloningFields = REDU_Metadata_UTIL.getObjectFieldsForCloning(getApiName(), AccessType.CREATABLE);

            Map<String, Schema.SObjectField> srsFieldsMap = Schema.SObjectType.reduivy__Study_Requirement_Set__c.fields.getMap();
            Map<String, Schema.SObjectField> irsFieldsMap = Schema.SObjectType.reduivy__Individual_Requirement_Set__c.fields.getMap();

            for(Schema.SObjectField srsField : srsFieldsMap.values()) {
                Schema.DescribeFieldResult srsFieldResult = srsField.getDescribe();
                String srsFieldName = srsFieldResult.getName();
                
                if(irsCloningFields.contains(srsFieldName)) {
                    srsIrsCommonFields.add(srsFieldName);
                }
            }
        }

        return srsIrsCommonFields;
      
    }
}