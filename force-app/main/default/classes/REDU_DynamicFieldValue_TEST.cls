/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_DynamicFieldValue_OBJ
 * @changehistory
 * ISS-001918 29-08-2024 CM - Added testPicklistOptions()
 * ISS-002261 10-03-2025 Jordan - Added isCreateable and isUpdateable
 */
@IsTest
public inherited sharing class REDU_DynamicFieldValue_TEST {

    /**
     * @description Test constructor with 8 params
     */
    @IsTest
    static void testConstructor1(){
        
        Test.startTest();
        
        //with value
        REDU_DynamicFieldValue_OBJ dfv1 = new REDU_DynamicFieldValue_OBJ('objectName', 'fieldName', 'label', 'value', 'displayType', 'fieldRawValue', true, true);
        System.Assert.areEqual('objectName', dfv1.objectName);
        System.Assert.areEqual('fieldName', dfv1.fieldName);
        System.Assert.areEqual('label', dfv1.label);
        System.Assert.areEqual('value', dfv1.value);
        System.Assert.areEqual('displayType', dfv1.displayType);
        System.Assert.areEqual('fieldRawValue', dfv1.fieldRawValue);
        System.Assert.areEqual(null, dfv1.helpText);
        System.Assert.areEqual(null, dfv1.doubleDecimalPlaces);
        System.Assert.areEqual(true, dfv1.isCreateable);
        System.Assert.areEqual(true, dfv1.isUpdateable);
        System.Assert.areEqual(false, dfv1.isRequired);
        System.Assert.areEqual(null, dfv1.soapdisplayType);
        System.Assert.areEqual(true, dfv1.isSet);

        //without value
        REDU_DynamicFieldValue_OBJ dfv2 = new REDU_DynamicFieldValue_OBJ('objectName', 'fieldName', 'label', null, 'displayType', 'fieldRawValue', true, true);
        System.Assert.areEqual('objectName', dfv2.objectName);
        System.Assert.areEqual('fieldName', dfv2.fieldName);
        System.Assert.areEqual('label', dfv2.label);
        System.Assert.areEqual(null, dfv2.value);
        System.Assert.areEqual('displayType', dfv2.displayType);
        System.Assert.areEqual('fieldRawValue', dfv2.fieldRawValue);
        System.Assert.areEqual(null, dfv2.helpText);
        System.Assert.areEqual(null, dfv2.doubleDecimalPlaces);
        System.Assert.areEqual(true, dfv2.isCreateable);
        System.Assert.areEqual(true, dfv2.isUpdateable);
        System.Assert.areEqual(false, dfv2.isRequired);
        System.Assert.areEqual(null, dfv2.soapdisplayType);
        System.Assert.areEqual(false, dfv2.isSet);

        Test.stopTest();
        
    }

    /**
     * @description Test constructor with 9 params
     */
    @IsTest
    static void testConstructor2(){
        
        Test.startTest();
        
        //with value and required
        REDU_DynamicFieldValue_OBJ dfv1 = new REDU_DynamicFieldValue_OBJ('objectName', 'fieldName', 'label', 'value', 'displayType', 'fieldRawValue', true, true, true);
        System.Assert.areEqual('objectName', dfv1.objectName);
        System.Assert.areEqual('fieldName', dfv1.fieldName);
        System.Assert.areEqual('label', dfv1.label);
        System.Assert.areEqual('value', dfv1.value);
        System.Assert.areEqual('displayType', dfv1.displayType);
        System.Assert.areEqual('fieldRawValue', dfv1.fieldRawValue);
        System.Assert.areEqual(null, dfv1.helpText);
        System.Assert.areEqual(null, dfv1.doubleDecimalPlaces);
        System.Assert.areEqual(true, dfv1.isCreateable);
        System.Assert.areEqual(true, dfv1.isUpdateable);
        System.Assert.areEqual(true, dfv1.isRequired);
        System.Assert.areEqual(null, dfv1.soapdisplayType);
        System.Assert.areEqual(true, dfv1.isSet);

        //without value and optional
        REDU_DynamicFieldValue_OBJ dfv2 = new REDU_DynamicFieldValue_OBJ('objectName', 'fieldName', 'label', null, 'displayType', 'fieldRawValue', true, true, false);
        System.Assert.areEqual('objectName', dfv2.objectName);
        System.Assert.areEqual('fieldName', dfv2.fieldName);
        System.Assert.areEqual('label', dfv2.label);
        System.Assert.areEqual(null, dfv2.value);
        System.Assert.areEqual('displayType', dfv2.displayType);
        System.Assert.areEqual('fieldRawValue', dfv2.fieldRawValue);
        System.Assert.areEqual(null, dfv1.helpText);
        System.Assert.areEqual(null, dfv1.doubleDecimalPlaces);
        System.Assert.areEqual(true, dfv2.isCreateable);
        System.Assert.areEqual(true, dfv2.isUpdateable);
        System.Assert.areEqual(false, dfv2.isRequired);
        System.Assert.areEqual(null, dfv2.soapdisplayType);
        System.Assert.areEqual(false, dfv2.isSet);

        Test.stopTest();
        
    }

    /**
     * @description Test constructor with 12 params
     */
    @IsTest
    static void testConstructor3(){
        
        Test.startTest();
        
        //with value and required
        REDU_DynamicFieldValue_OBJ dfv1 = new REDU_DynamicFieldValue_OBJ('objectName', 'fieldName', 'label', 'value', 'displayType', 'DATE', 'fieldRawValue', 'helpText', 3, true, true, true);
        System.Assert.areEqual('objectName', dfv1.objectName);
        System.Assert.areEqual('fieldName', dfv1.fieldName);
        System.Assert.areEqual('label', dfv1.label);
        System.Assert.areEqual('value', dfv1.value);
        System.Assert.areEqual('displayType', dfv1.displayType);
        System.Assert.areEqual('fieldRawValue', dfv1.fieldRawValue);
        System.Assert.areEqual('helpText', dfv1.helpText);
        System.Assert.areEqual(3, dfv1.doubleDecimalPlaces);
        System.Assert.areEqual(true, dfv1.isCreateable);
        System.Assert.areEqual(true, dfv1.isUpdateable);
        System.Assert.areEqual(true, dfv1.isRequired);
        System.Assert.areEqual('DATE', dfv1.soapdisplayType);
        System.Assert.areEqual('D', dfv1.fieldType);
        System.Assert.areEqual(true, dfv1.isSet);

        //without value and optional
        REDU_DynamicFieldValue_OBJ dfv2 = new REDU_DynamicFieldValue_OBJ('objectName', 'fieldName', 'label', null, 'displayType', 'DATE', 'fieldRawValue', 'helpText', 3, true, true, false);
        System.Assert.areEqual('objectName', dfv2.objectName);
        System.Assert.areEqual('fieldName', dfv2.fieldName);
        System.Assert.areEqual('label', dfv2.label);
        System.Assert.areEqual(null, dfv2.value);
        System.Assert.areEqual('displayType', dfv2.displayType);
        System.Assert.areEqual('fieldRawValue', dfv2.fieldRawValue);
        System.Assert.areEqual('helpText', dfv1.helpText);
        System.Assert.areEqual(3, dfv1.doubleDecimalPlaces);
        System.Assert.areEqual(true, dfv2.isCreateable);
        System.Assert.areEqual(true, dfv2.isUpdateable);
        System.Assert.areEqual(false, dfv2.isRequired);
        System.Assert.areEqual('DATE', dfv2.soapdisplayType);
        System.Assert.areEqual('D', dfv1.fieldType);
        System.Assert.areEqual(false, dfv2.isSet);

        Test.stopTest();
        
    }


    /**
     * @description Test constructor with describe field result
     */
    @IsTest
    static void testConstructor4(){
        
        Test.startTest();
        
        //with value and required
        Schema.DescribeFieldResult expectedDfr = SObjectType.reduivy__Study_Unit__c.fields.reduivy__Credits__c;
        REDU_DynamicFieldValue_OBJ dfv1 = new REDU_DynamicFieldValue_OBJ(expectedDfr, 'value', 'fieldRawValue', true);
        System.Assert.areEqual(SUN_Helper.getApiName(), dfv1.objectName);
        System.Assert.areEqual(expectedDfr.getName(), dfv1.fieldName);
        System.Assert.areEqual(expectedDfr.getLabel(), dfv1.label);
        System.Assert.areEqual('value', dfv1.value);
        System.Assert.areEqual(expectedDfr.getType().name(), dfv1.displayType);
        System.Assert.areEqual('fieldRawValue', dfv1.fieldRawValue);
        System.Assert.areEqual(expectedDfr.getInlineHelpText(), dfv1.helpText);
        System.Assert.areEqual(expectedDfr.getScale(), dfv1.doubleDecimalPlaces);
        System.Assert.areEqual(expectedDfr.isCreateable(), dfv1.isCreateable);
        System.Assert.areEqual(expectedDfr.isUpdateable(), dfv1.isUpdateable);
        System.Assert.areEqual(true, dfv1.isRequired);
        System.Assert.areEqual(expectedDfr.getSoapType().name(), dfv1.soapdisplayType);
        System.Assert.areEqual('N', dfv1.fieldType);
        System.Assert.areEqual(true, dfv1.isSet);

        //without value and optional
        REDU_DynamicFieldValue_OBJ dfv2 = new REDU_DynamicFieldValue_OBJ(expectedDfr, null, null, true);
        System.Assert.areEqual(SUN_Helper.getApiName(), dfv2.objectName);
        System.Assert.areEqual(expectedDfr.getName(), dfv2.fieldName);
        System.Assert.areEqual(expectedDfr.getLabel(), dfv2.label);
        System.Assert.areEqual(null, dfv2.value);
        System.Assert.areEqual(expectedDfr.getType().name(), dfv2.displayType);
        System.Assert.areEqual(null, dfv2.fieldRawValue);
        System.Assert.areEqual(expectedDfr.getInlineHelpText(), dfv2.helpText);
        System.Assert.areEqual(expectedDfr.getScale(), dfv2.doubleDecimalPlaces);
        System.Assert.areEqual(expectedDfr.isCreateable(), dfv2.isCreateable);
        System.Assert.areEqual(expectedDfr.isUpdateable(), dfv2.isUpdateable);
        System.Assert.areEqual(true, dfv2.isRequired);
        System.Assert.areEqual(expectedDfr.getSoapType().name(), dfv2.soapdisplayType);
        System.Assert.areEqual('N', dfv2.fieldType);
        System.Assert.areEqual(false, dfv2.isSet);

        Test.stopTest();
        
    }

    /**
     * @description Test returning a picklist field with its active values. Using IGI for test
     */
    @IsTest
    static void testPicklistOptions(){
        
        Test.startTest();
        
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Grade_Item__c.fields.reduivy__Status__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();
        //getStatuses() will only return active values, so we need to filter our checking list.
        List<Schema.PicklistEntry> activePleList = new List<Schema.PicklistEntry>();
        for (Schema.PicklistEntry ple : pleList){
            if (ple.isActive()){
                activePleList.add(ple);
            }
        }

        REDU_DynamicFieldValue_OBJ dfv = new REDU_DynamicFieldValue_OBJ('reduivy__Individual_Grade_Item__c', 'reduivy__Status__c', 'Status', null, 'PICKLIST', 'fieldRawValue', true, true);
        System.Assert.isFalse(dfv.picklistOptions.isEmpty());
        Integer counter = 0;
        for (Schema.PicklistEntry ple : activePleList) {
            System.Assert.areEqual(ple.getValue(), dfv.picklistOptions.get(counter).value);

            counter ++;
        }

        Test.stopTest();
        
    }
}