/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for ACC_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class ACC_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    @TestSetup
    static void makeData(){
                
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.Account.getLabel(), ACC_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.Account.getLabelPlural(), ACC_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.Account.getName(), ACC_Helper.getApiName());

        Test.stopTest();
        
    }
    
    /**
     * @description Test record type id method
     */
    @IsTest
    static void testGetRecordTypes(){
        
        Test.startTest();
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Account.getRecordtypeInfosByDeveloperName();

        System.Assert.areEqual(rtMap.get('Administrative').getRecordTypeId(), ACC_Helper.getAdministrativeRecordTypeId());
        System.Assert.areEqual(rtMap.get('Administrative').getName(), ACC_Helper.getAdministrativeRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('Campus').getRecordTypeId(), ACC_Helper.getCampusRecordTypeId());
        System.Assert.areEqual(rtMap.get('Campus').getName(), ACC_Helper.getCampusRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('Department').getRecordTypeId(), ACC_Helper.getDepartmentRecordTypeId());
        System.Assert.areEqual(rtMap.get('Department').getName(), ACC_Helper.getDepartmentRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('Educational_Institution').getRecordTypeId(), ACC_Helper.getEducationalInstitutionRecordTypeId());
        System.Assert.areEqual(rtMap.get('Educational_Institution').getName(), ACC_Helper.getEducationalInstitutionRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('External_Educational_Institution').getRecordTypeId(), ACC_Helper.getExternalEducationalInstitutionRecordTypeId());
        System.Assert.areEqual(rtMap.get('External_Educational_Institution').getName(), ACC_Helper.getExternalEducationalInstitutionRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('Organization').getRecordTypeId(), ACC_Helper.getOrganizationRecordTypeId());
        System.Assert.areEqual(rtMap.get('Organization').getName(), ACC_Helper.getOrganizationRecordTypeLabel());

        Test.stopTest();
        
    }
}