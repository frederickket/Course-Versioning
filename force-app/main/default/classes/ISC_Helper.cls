/**
 * @author      WDCi (XW)
 * @date        Jul 2025
 * @group       Object Helper
 * @description Individual Score object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-002506 16-07-2025 XW - new class
 */
global inherited sharing class ISC_Helper implements SObject_Helper {
    
    /**
     * @description Status - Active
     */
    global static String STATUS_ACTIVE = 'Active';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Score__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Score__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Score__c.getName();
    }
	
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Score__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    
    /**
     * @description list of fields that has the same name in study scoring config and individual score
     * @return   Set<String>
     */
    private static Set<String> scfIscCommonFields;

    /**
     * @description get list of fields that has the same name in study scoring config and individual score
     * @return   Set<String>
     */
    public static Set<String> getScfIscCommonFields(){
        if(scfIscCommonFields == null) {
            scfIscCommonFields = new Set<String>();
            Set<String> iscCloningFields = REDU_Metadata_UTIL.getObjectFieldsForCloning(getApiName(), AccessType.CREATABLE);

            Map<String, Schema.SObjectField> scfFieldsMap = Schema.SObjectType.reduivy__Study_Scoring_Config__c.fields.getMap();
            Map<String, Schema.SObjectField> iscFieldsMap = Schema.SObjectType.reduivy__Individual_Score__c.fields.getMap();
            
            for(Schema.SObjectField scfField : scfFieldsMap.values()) {
                Schema.DescribeFieldResult scfFieldResult = scfField.getDescribe();
                String scfFieldName = scfFieldResult.getName();
                
                if(iscCloningFields.contains(scfFieldName)) {
                    scfIscCommonFields.add(scfFieldName);
                }
            }
        }

        return scfIscCommonFields;
      
    }

    /**
     * @description create individual score from the given study scoring config and sobject
     * @param  scf  study scoring config to be cloned from
     * @param  sobj sobject
     * @return      individual score
     */
    public static reduivy__Individual_Score__c createIsc(reduivy__Study_Scoring_Config__c scf, SObject sobj) {
        reduivy__Individual_Score__c isc = new reduivy__Individual_Score__c();
        
        String sobjectLookupField = REDU_Metadata_UTIL.getObjectLookupField(SCF_Helper.getApiName(), sobj.getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName());
        
        //common fields
        Set<String> commonFields = getScfIscCommonFields();
        for(String field : commonFields) {
            isc.put(field, scf.get(field));
        }

        //non common fields
        isc.reduivy__Study_Scoring_Config__c = scf.Id;
        isc.put(sobjectLookupField, sobj.Id);

        if(String.isNotBlank(scf.reduivy__Contact_Field__c)) {
            isc.reduivy__Contact__c = (Id) sobj.get(scf.reduivy__Contact_Field__c);
        }

        return isc;
    }
}