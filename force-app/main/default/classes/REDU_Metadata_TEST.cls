/**
 * @author      WDCi (Lean)
 * @date        March 2023
 * @group       Test
 * @description Test class for REDU_Metadata_UTIL
 * @changehistory
 * ISS-001591 31-03-2023 Lean - new class
 * ISS-002153 15-11-2024 Jordan - new test methods (getObjectFieldsForCloning)
 */
@IsTest
public inherited sharing class REDU_Metadata_TEST {

    /**
     * @description Test describe sobject
     */
    @IsTest
    static void testDescribeSObject(){
        
        Test.startTest();
        
        Schema.DescribeSObjectResult objDescRes = REDU_Metadata_UTIL.describeSObject('Account');
        
        System.Assert.isTrue(objDescRes != null);
        System.Assert.areEqual('Account', objDescRes.getName());

        Test.stopTest();
        
    }

    /**
     * @description Test describe sobject with valid field
     */
    @IsTest
    static void testDescribeSObjectField(){
        
        Test.startTest();
        
        Schema.DescribeFieldResult fieldDescRes = REDU_Metadata_UTIL.describeSObjectField('Account', 'Name');
        
        System.Assert.isTrue(fieldDescRes != null);
        System.Assert.areEqual('Name', fieldDescRes.getName());

        Test.stopTest();
        
    }

    /**
     * @description Test describe sobject with invalid field
     */
    @IsTest
    static void testDescribeSObjectFieldError(){
        
        Test.startTest();
        
        try {
            Schema.DescribeFieldResult fieldDescRes = REDU_Metadata_UTIL.describeSObjectField('Account', 'Namess');
            System.Assert.isTrue(false, 'This should fail');
        } catch (Exception exp) {
            String expectedError = String.format(Label.Invalid_Object_Field_Error, new List<String>{'Namess', 'Account'});
            System.Assert.areEqual(expectedError, exp.getMessage());
        }

        Test.stopTest();
        
    }

    /**
     * @description Test describe sobject fields
     */
    @IsTest
    static void testDescribeSObjectFields(){
        
        Test.startTest();
        
        Map<String, Schema.DescribeFieldResult> fieldsDescribeMap = REDU_Metadata_UTIL.describeSObjectFields('Account', new List<String>{'Name', 'AccountNumber'});
        
        System.Assert.isTrue(fieldsDescribeMap != null);
        System.Assert.areEqual(2, fieldsDescribeMap.size());

        for (String fieldName : fieldsDescribeMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldsDescribeMap.get(fieldName);
            System.Assert.areEqual(fieldName, dfr.getName());
        }

        Test.stopTest();
        
    }

    /**
     * @description Test getFieldSetMembers()
     */
    @IsTest
    static void testGetFieldSetMembers(){
        
        Test.startTest();
        
        List<REDU_DynamicFieldValue_OBJ> fields = REDU_Metadata_UTIL.getFieldSetMembers('Contact', 'reduivy__UnitTesting');

        System.Assert.areEqual(false, fields.isEmpty(), 'There should be fields in the field set.');
        System.Assert.areEqual(5, fields.size(), 'There should be AccountId, FirstName, LastName, Birthdate and Email in the field set.');

        for (REDU_DynamicFieldValue_OBJ dfv : fields) {

            if (dfv.fieldName == 'AccountId') {
                System.Assert.areEqual('Contact', dfv.objectName);
                System.Assert.areEqual('AccountId', dfv.fieldName);
                System.Assert.areEqual('Account ID', dfv.label);
                System.Assert.areEqual(null, dfv.value);
                System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), dfv.displayType);
                System.Assert.areEqual(Schema.SoapType.ID.name(), dfv.soapDisplayType);
                System.Assert.areEqual(null, dfv.fieldRawValue);
                System.Assert.areEqual(false, dfv.isRequired);
                System.Assert.areEqual(false, dfv.isSet);
                System.Assert.areEqual('A', dfv.fieldType);

            } else if (dfv.fieldName == 'FirstName') {
                System.Assert.areEqual('Contact', dfv.objectName);
                System.Assert.areEqual('FirstName', dfv.fieldName);
                System.Assert.areEqual('First Name', dfv.label);
                System.Assert.areEqual(null, dfv.value);
                System.Assert.areEqual(Schema.DisplayType.STRING.name(), dfv.displayType);
                System.Assert.areEqual(Schema.SoapType.STRING.name(), dfv.soapDisplayType);
                System.Assert.areEqual(null, dfv.fieldRawValue);
                System.Assert.areEqual(false, dfv.isRequired);
                System.Assert.areEqual(false, dfv.isSet);
                System.Assert.areEqual('A', dfv.fieldType);

            } else if (dfv.fieldName == 'LastName') {
                System.Assert.areEqual('Contact', dfv.objectName);
                System.Assert.areEqual('LastName', dfv.fieldName);
                System.Assert.areEqual('Last Name', dfv.label);
                System.Assert.areEqual(null, dfv.value);
                System.Assert.areEqual(Schema.DisplayType.STRING.name(), dfv.displayType);
                System.Assert.areEqual(Schema.SoapType.STRING.name(), dfv.soapDisplayType);
                System.Assert.areEqual(null, dfv.fieldRawValue);
                System.Assert.areEqual(false, dfv.isRequired);
                System.Assert.areEqual(false, dfv.isSet);
                System.Assert.areEqual('A', dfv.fieldType);
                
            } else if (dfv.fieldName == 'Birthdate') {
                System.Assert.areEqual('Contact', dfv.objectName);
                System.Assert.areEqual('Birthdate', dfv.fieldName);
                System.Assert.areEqual('Birthdate', dfv.label);
                System.Assert.areEqual(null, dfv.value);
                System.Assert.areEqual(Schema.DisplayType.DATE.name(), dfv.displayType);
                System.Assert.areEqual(Schema.SoapType.DATE.name(), dfv.soapDisplayType);
                System.Assert.areEqual(null, dfv.fieldRawValue);
                System.Assert.areEqual(false, dfv.isRequired);
                System.Assert.areEqual(false, dfv.isSet);
                System.Assert.areEqual('D', dfv.fieldType);
                
            } else if (dfv.fieldName == 'Email') {
                System.Assert.areEqual('Contact', dfv.objectName);
                System.Assert.areEqual('Email', dfv.fieldName);
                System.Assert.areEqual('Email', dfv.label);
                System.Assert.areEqual(null, dfv.value);
                System.Assert.areEqual(Schema.DisplayType.EMAIL.name(), dfv.displayType);
                System.Assert.areEqual(Schema.SoapType.STRING.name(), dfv.soapDisplayType);
                System.Assert.areEqual(null, dfv.fieldRawValue);
                System.Assert.areEqual(false, dfv.isRequired);
                System.Assert.areEqual(false, dfv.isSet);
                System.Assert.areEqual('A', dfv.fieldType);

            } else {
                System.Assert.fail('Unexpected field: ' + dfv.fieldName);
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test getFieldSetMembers() with column number
     */
    @IsTest
    static void testGetFieldSetMembersWithColumnNo(){
        
        Test.startTest();
        
        List<List<REDU_DynamicFieldValue_OBJ>> fieldRows = REDU_Metadata_UTIL.getFieldSetMembers('Contact', 'reduivy__UnitTesting', 2);

        System.Assert.areEqual(false, fieldRows.isEmpty(), 'There should be fields in the field set.');
        System.Assert.areEqual(3, fieldRows.size(), 'There should be 2 rows.');

        Integer row = 1;
        for (List<REDU_DynamicFieldValue_OBJ> fields : fieldRows) {
            for (REDU_DynamicFieldValue_OBJ dfv : fields) {

                if (dfv.fieldName == 'AccountId' && row == 1) {
                    System.Assert.areEqual('Contact', dfv.objectName);
                    System.Assert.areEqual('AccountId', dfv.fieldName);
                    System.Assert.areEqual('Account ID', dfv.label);
                    System.Assert.areEqual(null, dfv.value);
                    System.Assert.areEqual(Schema.DisplayType.REFERENCE.name(), dfv.displayType);
                    System.Assert.areEqual(Schema.SoapType.ID.name(), dfv.soapDisplayType);
                    System.Assert.areEqual(null, dfv.fieldRawValue);
                    System.Assert.areEqual(false, dfv.isRequired);
                    System.Assert.areEqual(false, dfv.isSet);
                    System.Assert.areEqual('A', dfv.fieldType);

                } else if (dfv.fieldName == 'FirstName' && row == 1) {
                    System.Assert.areEqual('Contact', dfv.objectName);
                    System.Assert.areEqual('FirstName', dfv.fieldName);
                    System.Assert.areEqual('First Name', dfv.label);
                    System.Assert.areEqual(null, dfv.value);
                    System.Assert.areEqual(Schema.DisplayType.STRING.name(), dfv.displayType);
                    System.Assert.areEqual(Schema.SoapType.STRING.name(), dfv.soapDisplayType);
                    System.Assert.areEqual(null, dfv.fieldRawValue);
                    System.Assert.areEqual(false, dfv.isRequired);
                    System.Assert.areEqual(false, dfv.isSet);
                    System.Assert.areEqual('A', dfv.fieldType);

                } else if (dfv.fieldName == 'LastName' && row == 2) {
                    System.Assert.areEqual('Contact', dfv.objectName);
                    System.Assert.areEqual('LastName', dfv.fieldName);
                    System.Assert.areEqual('Last Name', dfv.label);
                    System.Assert.areEqual(null, dfv.value);
                    System.Assert.areEqual(Schema.DisplayType.STRING.name(), dfv.displayType);
                    System.Assert.areEqual(Schema.SoapType.STRING.name(), dfv.soapDisplayType);
                    System.Assert.areEqual(null, dfv.fieldRawValue);
                    System.Assert.areEqual(false, dfv.isRequired);
                    System.Assert.areEqual(false, dfv.isSet);
                    System.Assert.areEqual('A', dfv.fieldType);
                    
                } else if (dfv.fieldName == 'Birthdate' && row == 2) {
                    System.Assert.areEqual('Contact', dfv.objectName);
                    System.Assert.areEqual('Birthdate', dfv.fieldName);
                    System.Assert.areEqual('Birthdate', dfv.label);
                    System.Assert.areEqual(null, dfv.value);
                    System.Assert.areEqual(Schema.DisplayType.DATE.name(), dfv.displayType);
                    System.Assert.areEqual(Schema.SoapType.DATE.name(), dfv.soapDisplayType);
                    System.Assert.areEqual(null, dfv.fieldRawValue);
                    System.Assert.areEqual(false, dfv.isRequired);
                    System.Assert.areEqual(false, dfv.isSet);
                    System.Assert.areEqual('D', dfv.fieldType);
                    
                } else if (dfv.fieldName == 'Email' && row == 3) {
                    System.Assert.areEqual('Contact', dfv.objectName);
                    System.Assert.areEqual('Email', dfv.fieldName);
                    System.Assert.areEqual('Email', dfv.label);
                    System.Assert.areEqual(null, dfv.value);
                    System.Assert.areEqual(Schema.DisplayType.EMAIL.name(), dfv.displayType);
                    System.Assert.areEqual(Schema.SoapType.STRING.name(), dfv.soapDisplayType);
                    System.Assert.areEqual(null, dfv.fieldRawValue);
                    System.Assert.areEqual(false, dfv.isRequired);
                    System.Assert.areEqual(false, dfv.isSet);
                    System.Assert.areEqual('A', dfv.fieldType);

                } else {
                    System.Assert.fail('Unexpected field: ' + dfv.fieldName);
                }
            }

            row ++;
        }

        Test.stopTest();
        
    }

    /**
     * @description Test getFields() with column number
     */
    @IsTest
    static void testGetFieldsWithColumnNo(){
        
        Test.startTest();
        
        List<List<String>> fieldRows = REDU_Metadata_UTIL.getFields('Contact', 'reduivy__UnitTesting', 2);

        System.Assert.areEqual(false, fieldRows.isEmpty(), 'There should be fields in the field set.');
        System.Assert.areEqual(3, fieldRows.size(), 'There should be 2 rows.');

        Integer row = 1;
        for (List<String> fields : fieldRows) {
            for (String dfv : fields) {

                if (dfv == 'AccountId' && row == 1) {
                    System.Assert.areEqual('AccountId', dfv);

                } else if (dfv == 'FirstName' && row == 1) {
                    System.Assert.areEqual('FirstName', dfv);

                } else if (dfv == 'LastName' && row == 2) {
                    System.Assert.areEqual('LastName', dfv);
                    
                } else if (dfv == 'Birthdate' && row == 2) {
                    System.Assert.areEqual('Birthdate', dfv);
                    
                } else if (dfv == 'Email' && row == 3) {
                    System.Assert.areEqual('Email', dfv);

                } else {
                    System.Assert.fail('Unexpected field: ' + dfv);
                }
            }

            row ++;
        }

        Test.stopTest();
        
    }

    /**
     * @description Test getFields() with use name for reference field
     */
    @IsTest
    static void testGetFieldsWithUseNameForReferenceFields(){
        
        Test.startTest();
        
        List<String> fields = REDU_Metadata_UTIL.getFields('Contact', 'reduivy__UnitTesting', true);

        System.Assert.areEqual(false, fields.isEmpty(), 'There should be fields in the field set.');
        System.Assert.areEqual(5, fields.size(), 'There should be 2 rows.');

        for (String dfv : fields) {

            if (dfv == 'Account.Name') {
                System.Assert.areEqual('Account.Name', dfv);

            } else if (dfv == 'FirstName') {
                System.Assert.areEqual('FirstName', dfv);

            } else if (dfv == 'LastName') {
                System.Assert.areEqual('LastName', dfv);
                
            } else if (dfv == 'Birthdate') {
                System.Assert.areEqual('Birthdate', dfv);
                
            } else if (dfv == 'Email') {
                System.Assert.areEqual('Email', dfv);

            } else {
                System.Assert.fail('Unexpected field: ' + dfv);
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get object fields for cloning
     */
    @IsTest
    static void testGetObjectFieldsForCloning(){
        
        Test.startTest();
        
        Set<String> spsFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan_Structure__c', AccessType.READABLE);

        Map<String, Schema.DescribeFieldResult> fieldsDescribeMap = REDU_Metadata_UTIL.describeSObjectFields('reduivy__Study_Plan_Structure__c', spsFields);

        for (String fieldName : fieldsDescribeMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldsDescribeMap.get(fieldName);

            if (
                dfr.isAccessible() && !dfr.isExternalId() && 
                dfr.getName() != 'OwnerId'
            ) {
                System.assert(spsFields.contains(fieldName));
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get object fields for cloning (createable only)
     */
    @IsTest
    static void testGetObjectFieldsForCloningCreateableOnly(){
        
        Test.startTest();
        
        Set<String> spsFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan_Structure__c', AccessType.CREATABLE);

        Map<String, Schema.DescribeFieldResult> fieldsDescribeMap = REDU_Metadata_UTIL.describeSObjectFields('reduivy__Study_Plan_Structure__c', spsFields);

        for (String fieldName : fieldsDescribeMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldsDescribeMap.get(fieldName);

            if (
                dfr.isCreateable() && !dfr.isExternalId() && 
                dfr.getName() != 'OwnerId'
            ) {
                System.assert(spsFields.contains(fieldName));
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get object fields for cloning (updatable only)
     */
    @IsTest
    static void testGetObjectFieldsForCloningUpdatableOnly(){
        
        Test.startTest();
        
        Set<String> spsFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan_Structure__c', AccessType.UPDATABLE);

        Map<String, Schema.DescribeFieldResult> fieldsDescribeMap = REDU_Metadata_UTIL.describeSObjectFields('reduivy__Study_Plan_Structure__c', spsFields);

        for (String fieldName : fieldsDescribeMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldsDescribeMap.get(fieldName);

            if (
                dfr.isUpdateable() && !dfr.isExternalId() && 
                dfr.getName() != 'OwnerId'
            ) {
                System.assert(spsFields.contains(fieldName));
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get object fields for cloning (upsertable only)
     */
    @IsTest
    static void testGetObjectFieldsForCloningUpsertableOnly(){
        
        Test.startTest();
        
        Set<String> spsFields = REDU_Metadata_UTIL.getObjectFieldsForCloning('reduivy__Study_Plan_Structure__c', AccessType.UPSERTABLE);

        Map<String, Schema.DescribeFieldResult> fieldsDescribeMap = REDU_Metadata_UTIL.describeSObjectFields('reduivy__Study_Plan_Structure__c', spsFields);

        for (String fieldName : fieldsDescribeMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldsDescribeMap.get(fieldName);

            if (
                dfr.isUpdateable() && dfr.isCreateable() && !dfr.isExternalId() && 
                dfr.getName() != 'OwnerId'
            ) {
                System.assert(spsFields.contains(fieldName));
            }
        }

        Test.stopTest();
        
    }
}