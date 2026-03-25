/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_LicenseManagement_UTIL
 * @changehistory
 * ISS-002574 04-08-2025 Lean - Decommission the applicant license type count
 */
@isTest
public inherited sharing class REDU_LicenseManagement_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
		// Create settings
		testFactory.setupDefaultSettings();
		
		// Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initSampleData(null, USR_Helper.getApiName(), null, USR_Helper.getApiName(), true, true);

            Contact updateContact = [SELECT Id FROM Contact WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1];
            updateContact.reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_Applicant;

            update updateContact;

            //call the batch job
            REDU_License_BATCH adminLicenseJob = new REDU_License_BATCH(REDU_LicenseManagement_UTIL.ADMIN);
            Database.executeBatch(adminLicenseJob, 2000);

            REDU_License_BATCH studentLicenseJob = new REDU_License_BATCH(REDU_LicenseManagement_UTIL.STUDENT);
            Database.executeBatch(studentLicenseJob, 2000);

            REDU_License_BATCH facultyLicenseJob = new REDU_License_BATCH(REDU_LicenseManagement_UTIL.FACULTY);
            Database.executeBatch(facultyLicenseJob, 2000);

            Test.stopTest();
        }
    }

    /**
     * @description Test initLicenseCheckJob
     */
    @IsTest
    static void testLicenseCheckJob(){

        Test.startTest();

        REDU_LicenseManagement_UTIL.initLicenseCheckJob(false, false);
        List<AsyncApexJob> jobCheck = [SELECT ApexClassId, ApexClass.name, Id, JobItemsProcessed, JobType, Status, NumberOfErrors, MethodName
                                        FROM AsyncApexJob
                                        WHERE JobType in ('BatchApexWorker','ScheduledApex')];

        System.Assert.isFalse(jobCheck.isEmpty(), 'The actual value should be as expected');

        Test.stopTest();
        
    }

    /**
     * @description Test getReduStudentLicensesSubscribed
     */
    @IsTest
    static void testLicenseCheckStudentSubscribed(){

        Test.startTest();

        // Test getReduStudentLicensesSubscribed
        System.Assert.areEqual(0, REDU_LicenseManagement_UTIL.getReduStudentLicensesSubscribed());

        Test.stopTest();
        
    }

    /**
     * @description Test getReduFacultyLicensesSubscribed
     */
    @IsTest
    static void testLicenseCheckFacultySubscribed(){

        Test.startTest();

        // Test getReduFacultyLicensesSubscribed
        System.Assert.areEqual(0, REDU_LicenseManagement_UTIL.getReduFacultyLicensesSubscribed());

        Test.stopTest();
        
    }

    /**
     * @description Test getReduAdminLicensesSubscribed
     */
    @IsTest
    static void testLicenseCheckAdminSubscribed(){

        Test.startTest();

        // Test getReduAdminLicensesSubscribed
        System.Assert.areEqual(0, REDU_LicenseManagement_UTIL.getReduAdminLicensesSubscribed());

        Test.stopTest();
        
    }

    /**
     * @description Test getReduStudentLicensesUsed
     */
    @IsTest
    static void testLicenseCheckStudentUsed(){

        Test.startTest();

        // Test getReduStudentLicensesUsed
        System.Assert.areNotEqual(0, REDU_LicenseManagement_UTIL.getReduStudentLicensesUsed());

        Test.stopTest();
        
    }

    /**
     * @description Test getReduFacultyLicensesUsed
     */
    @IsTest
    static void testLicenseCheckFacultyUsed(){

        Test.startTest();

        // Test getReduFacultyLicensesUsed
        System.Assert.areNotEqual(0, REDU_LicenseManagement_UTIL.getReduFacultyLicensesUsed());

        Test.stopTest();
        
    }

    /**
     * @description Test getReduAdminLicensesUsed
     */
    @IsTest
    static void testLicenseCheckAdminUsed(){

        Test.startTest();

        // Test getReduAdminLicensesUsed
        System.Assert.areNotEqual(0, REDU_LicenseManagement_UTIL.getReduAdminLicensesUsed());

        Test.stopTest();
        
    }
}