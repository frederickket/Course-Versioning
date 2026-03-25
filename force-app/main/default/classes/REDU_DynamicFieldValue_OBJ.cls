/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Utility
 * @description Field wrapper object to hold the field info and value
 * @changehistory
 * 22-08-2024 CM - ISS-001918 Added picklistOptions
 * 08-03-2025 Jordan - ISS-002261 Added isCreateable and isUpdateable
 */
public inherited sharing class REDU_DynamicFieldValue_OBJ {
    
    /**
     * @description Object API name
     */
    @AuraEnabled
    public String objectName {set; get;}

    /**
     * @description Field API name
     */
    @AuraEnabled
    public String fieldName {set; get;}

    /**
     * @description Field label
     */
    @AuraEnabled
    public String label {set; get;}

    /**
     * @description Field formatted value
     */
    @AuraEnabled
    public String value {set; get;}

    /**
     * @description REDU_SObject_UTIL field type
     */
    @AuraEnabled
    public String fieldType {set; get;}

    /**
     * @description Schema.DisplayType name
     */
    @AuraEnabled
    public String displayType {set; get;}

    /**
     * @description Schema.SoapType name
     */
    @AuraEnabled
    public String soapDisplayType {set; get;}

    /**
     * @description Field original value
     */
    @AuraEnabled
    public String fieldRawValue {set; get;}

    /**
     * @description ISS-002261 True if the field is createable
     */
    @AuraEnabled
    public Boolean isCreateable {set; get;}

    /**
     * @description ISS-002261 True if the field is updateable
     */
    @AuraEnabled
    public Boolean isUpdateable {set; get;}

    /**
     * @description True if the fieldValue is not blank
     */
    @AuraEnabled
    public Boolean isSet {set; get;}

    /**
     * @description True if the field is required
     */
    @AuraEnabled
    public Boolean isRequired {set; get;}

    /**
     * @description help text
     */
    @AuraEnabled
    public String helpText {set; get;}
    
    /**
     * @description The number of decimal places if the display type is double
     */
    @AuraEnabled
    public Integer doubleDecimalPlaces {set; get;}

    /**
     * @description The reference object name of the field if the display type is reference
     */
    @AuraEnabled
    public String lookupFieldObjectName {set; get;}

    /**
     * @description The reference object name of the field if the display type is reference
     */
    @AuraEnabled
    public Boolean isFormula {set; get;}

    /**
     * @description Gets all active picklist options for PICKLIST or MULTIPICKLIST displaytypes. Currently not restricted to RecordTypes
     */
    @AuraEnabled
    public List<REDU_PicklistOption_OBJ> picklistOptions {set; get;}

    /**
     * @description default constructure
     */
    public REDU_DynamicFieldValue_OBJ() {

    }

    /**
     * @description default constructure
     * @param objectName
     * @param fieldName
     * @param label
     * @param value
     * @param displayType
     * @param fieldRawValue
     * @param isCreateable
     * @param isUpdateable
     */
    public REDU_DynamicFieldValue_OBJ(String objectName, String fieldName, String label, String value, String displayType, String fieldRawValue, Boolean isCreateable, Boolean isUpdateable) {
        this(objectName, fieldName, label, value, displayType, null, fieldRawValue, null, null, isCreateable, isUpdateable, false);
    }

    /**
     * @description default constructure
     * @param objectName
     * @param fieldName
     * @param label
     * @param value
     * @param displayType
     * @param fieldRawValue
     * @param isCreateable
     * @param isUpdateable
     * @param isRequired
     */
    public REDU_DynamicFieldValue_OBJ(String objectName, String fieldName, String label, String value, String displayType, String fieldRawValue, Boolean isCreateable, Boolean isUpdateable, Boolean isRequired) {
        this(objectName, fieldName, label, value, displayType, null, fieldRawValue, null, null, isCreateable, isUpdateable, isRequired);
    }

    /**
     * @description default constructure
     * @param objectName
     * @param fieldName
     * @param label
     * @param value
     * @param displayType
     * @param soapDisplayType
     * @param fieldRawValue
     * @param isCreateable
     * @param isUpdateable
     * @param isRequired
     */
    public REDU_DynamicFieldValue_OBJ(String objectName, String fieldName, String label, String value, String displayType, String soapDisplayType, String fieldRawValue, String helpText, Integer doubleDecimalPlaces, Boolean isCreateable, Boolean isUpdateable, Boolean isRequired) {
        this.objectName = objectName;
        this.fieldName = fieldName;
        this.label = label;
        this.value = value;
        this.displayType = displayType;
        this.soapDisplayType = soapDisplayType;
        this.fieldRawValue = fieldRawValue;
        this.helpText = helpText;
        this.doubleDecimalPlaces = doubleDecimalPlaces;
        this.isCreateable = isCreateable; //ISS-002261
        this.isUpdateable = isUpdateable; //ISS-002261
        this.isRequired = isRequired;
        
        if(value != null && String.isNotBlank( String.valueOf(value) )){
            this.isSet = true;
        } else {
            this.isSet = false;
        }

        this.fieldType = REDU_SObject_UTIL.getFieldType(soapDisplayType);

        //Populate picklist options if needed
        this.picklistOptions = new List<REDU_PicklistOption_OBJ>();
        if (this.displayType == 'PICKLIST' || this.displayType == 'MULTIPICKLIST'){
            //Uses less CPU time than getGlobalDescribe()
            List<Schema.DescribeSObjectResult> describeSobjResults = Schema.describeSObjects(new String[] { this.objectName }, SObjectDescribeOptions.DEFERRED);
            List<Schema.PicklistEntry> pleList = describeSobjResults[0].fields.getMap().get(this.fieldName).getDescribe().getPicklistValues();
            for(Schema.PicklistEntry ple : pleList){
                if(ple.isActive()) {
                    picklistOptions.add(new REDU_PicklistOption_OBJ(ple.getLabel(), ple.getValue(), ple.isDefaultValue()));
                }
            }

        } else if (this.displayType == Schema.DisplayType.REFERENCE.name()) {
            List<Schema.DescribeSObjectResult> describeSobjResults = Schema.describeSObjects(new String[] { this.objectName }, SObjectDescribeOptions.DEFERRED);
            Schema.DescribeSObjectResult describeLookupSObjectResult = describeSobjResults[0].fields.getMap().get(this.fieldName).getDescribe().getReferenceTo()[0].getDescribe(Schema.SObjectDescribeOptions.DEFERRED);
            this.lookupFieldObjectName = describeLookupSObjectResult.getName();
        }

    }

    public REDU_DynamicFieldValue_OBJ(Schema.DescribeFieldResult fieldDescribe, String value, String fieldRawValue, Boolean isRequired) {
        this.objectName = fieldDescribe.getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED).getName();
        this.fieldName = fieldDescribe.getName();
        this.label = fieldDescribe.getLabel();
        this.value = value;
        this.displayType = fieldDescribe.getType().name();
        this.soapDisplayType = fieldDescribe.getSoapType().name();
        this.fieldRawValue = fieldRawValue;
        this.isCreateable = fieldDescribe.isCreateable(); //ISS-002261
        this.isUpdateable = fieldDescribe.isUpdateable(); //ISS-002261
        this.helpText = fieldDescribe.getInlineHelpText();
        this.doubleDecimalPlaces = fieldDescribe.getScale();
        this.isRequired = isRequired;
        this.isFormula = fieldDescribe.isCalculated();


        if(value != null && String.isNotBlank( String.valueOf(value) )){
            this.isSet = true;
        } else {
            this.isSet = false;
        }

        this.fieldType = REDU_SObject_UTIL.getFieldType(this.soapDisplayType);

        //Populate picklist options if needed
        this.picklistOptions = new List<REDU_PicklistOption_OBJ>();
        if (this.displayType == 'PICKLIST' || this.displayType == 'MULTIPICKLIST'){
            //Uses less CPU time than getGlobalDescribe()
            List<Schema.PicklistEntry> pleList = fieldDescribe.getPicklistValues();
            for(Schema.PicklistEntry ple : pleList){
                if(ple.isActive()) {
                    picklistOptions.add(new REDU_PicklistOption_OBJ(ple.getLabel(), ple.getValue(), ple.isDefaultValue()));
                }
            }

        }
    }
}