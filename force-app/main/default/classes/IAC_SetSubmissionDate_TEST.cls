/**
 * @author      WDCi (XW)
 * @date        Nov 2025
 * @group       Test
 * @description Test class for IAC_SetSubmissionDate_EXE
 * @changehistory
 * ISS-002633 17-11-2025 XW - new class
 */
@IsTest
public inherited sharing class IAC_SetSubmissionDate_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static List<String> SUBMITTED_STATUSES = IAC_Helper.getSubmittedVerificationStatuses();
    static List<String> CANCELLED_STATUSES = IAC_Helper.getCancelledVerificationStatuses();
    static String IAC_SRC = 'IAC';

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
        	
            //please adjust the data according to your needs
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for inserting submitted iac
     */
    @IsTest
    static void testForInsert_SubmittedStatus_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(SUBMITTED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(ADMIN_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), insertedIac.reduivy__Submission_Date__c, 'Wrong submission date!');

        Test.stopTest();
    }

	
    /**
     * @description Test as admin for inserting nonsubmitted iac
     */
    @IsTest
    static void testForInsert_NonSubmittedStatus_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(CANCELLED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(ADMIN_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        Test.stopTest();
    }
	
    /**
     * @description Test as admin for inserting empty status iac
     */
    @IsTest
    static void testForInsert_EmptyStatus_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(CANCELLED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(ADMIN_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        Test.stopTest();
    }

	
    /**
     * @description Test as admin for inserting submitted iac
     */
    @IsTest
    static void testForBulkInsert_SubmittedStatus_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        List<reduivy__Individual_Achievement__c> iacList = new List<reduivy__Individual_Achievement__c>();
        for(Integer i = 0; i < 100; i++) {
            reduivy__Individual_Achievement__c iac = createIac(SUBMITTED_STATUSES[0]);
            iac.reduivy__Sample_Record_Code__c = IAC_SRC + i;
            iacList.add(iac);
            System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        }
        
		System.runAs(ADMIN_USER){
            insert iacList;
		}

        String iacSrc = IAC_SRC + '%';
        List<reduivy__Individual_Achievement__c> insertedIacList = [
            SELECT Id, reduivy__Verification_Status__c, reduivy__Submission_Date__c
            FROM reduivy__Individual_Achievement__c 
            WHERE reduivy__Sample_Record_Code__c LIKE :iacSrc
        ];
        System.Assert.areEqual(100, insertedIacList.size(), 'Wrong iac size!');
        
        for(reduivy__Individual_Achievement__c insertedIac : insertedIacList) {
            System.Assert.areEqual(SUBMITTED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
            System.Assert.areEqual(System.today(), insertedIac.reduivy__Submission_Date__c, 'Wrong submission date!');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for updating iac from non submitted to submitted
     */
    @IsTest
    static void testForUpdate_NonSubmittedToSubmittedStatus_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(CANCELLED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(ADMIN_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        insertedIac.reduivy__Verification_Status__c = SUBMITTED_STATUSES[0];

		System.runAs(ADMIN_USER){
            update insertedIac;
		}

        reduivy__Individual_Achievement__c updatedIac = queryIac();
        System.Assert.areEqual(iac.Id, updatedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], updatedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), updatedIac.reduivy__Submission_Date__c, 'Submission date should be updated to today!');

        Test.stopTest();
    }

    /**
     * @description Test as admin for updating iac from submitted to non submitted
     */
    @IsTest
    static void testForUpdate_SubmittedToNonSubmittedStatus_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();


        reduivy__Individual_Achievement__c iac = createIac(SUBMITTED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(ADMIN_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), insertedIac.reduivy__Submission_Date__c, 'Wrong submission date!');

        //update the submission date to simulate that the iac was submitted 2 days ago
        insertedIac.reduivy__Submission_Date__c = System.today().addDays(-2);
        update insertedIac;

        insertedIac.reduivy__Verification_Status__c = CANCELLED_STATUSES[0];
        
		System.runAs(ADMIN_USER){
            update insertedIac;
		}

        reduivy__Individual_Achievement__c updatedIac = queryIac();
        System.Assert.areEqual(iac.Id, updatedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], updatedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today().addDays(-2), updatedIac.reduivy__Submission_Date__c, 'Submission date should be not updated!');
        Test.stopTest();
    }

    /**
     * @description Test as admin for updating iac from empty to submitted
     */
    @IsTest
    static void testForUpdate_EmptyToSubmittedStatus_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(null);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(ADMIN_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(null, insertedIac.reduivy__Verification_Status__c, 'Submission status should be empty!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        insertedIac.reduivy__Verification_Status__c = SUBMITTED_STATUSES[0];

		System.runAs(ADMIN_USER){
            update insertedIac;
		}

        reduivy__Individual_Achievement__c updatedIac = queryIac();
        System.Assert.areEqual(iac.Id, updatedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], updatedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), updatedIac.reduivy__Submission_Date__c, 'Submission date should be updated to today!');

        Test.stopTest();
    }

    /**
     * @description Test as admin for updating iac from submitted to non submitted
     */
    @IsTest
    static void testForBulkUpdate_SubmittedToNonSubmittedStatus_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        List<reduivy__Individual_Achievement__c> iacList = new List<reduivy__Individual_Achievement__c>();
        for(Integer i = 0; i < 100; i++) {
            reduivy__Individual_Achievement__c iac = createIac(SUBMITTED_STATUSES[0]);
            iac.reduivy__Sample_Record_Code__c = IAC_SRC + i;
            iacList.add(iac);
            System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        }
        
		System.runAs(ADMIN_USER){
            insert iacList;
		}

        String iacSrc = IAC_SRC + '%';
        List<reduivy__Individual_Achievement__c> insertedIacList = [
            SELECT Id, reduivy__Verification_Status__c, reduivy__Submission_Date__c
            FROM reduivy__Individual_Achievement__c 
            WHERE reduivy__Sample_Record_Code__c LIKE :iacSrc
        ];
        System.Assert.areEqual(100, insertedIacList.size(), 'Wrong iac size!');

        for(reduivy__Individual_Achievement__c insertedIac : insertedIacList) {
            System.Assert.areEqual(SUBMITTED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
            System.Assert.areEqual(System.today(), insertedIac.reduivy__Submission_Date__c, 'Wrong submission date!');
        }

        //update the submission date to simulate that the iac was submitted 2 days ago
        for(reduivy__Individual_Achievement__c insertedIac : insertedIacList) {
            insertedIac.reduivy__Submission_Date__c = System.today().addDays(-2);
        }
        update insertedIacList;

        for(reduivy__Individual_Achievement__c insertedIac : insertedIacList) {
            insertedIac.reduivy__Verification_Status__c = CANCELLED_STATUSES[0];
        }
        
		System.runAs(ADMIN_USER){
            update insertedIacList;
		}


        List<reduivy__Individual_Achievement__c> updatedIacList = [
            SELECT Id, reduivy__Verification_Status__c, reduivy__Submission_Date__c
            FROM reduivy__Individual_Achievement__c 
            WHERE reduivy__Sample_Record_Code__c LIKE :iacSrc
        ];
        System.Assert.areEqual(100, updatedIacList.size(), 'Wrong iac size!');

        for(reduivy__Individual_Achievement__c updatedIac : updatedIacList) {
            System.Assert.areEqual(CANCELLED_STATUSES[0], updatedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
            System.Assert.areEqual(System.today().addDays(-2), updatedIac.reduivy__Submission_Date__c, 'Submission date should be not updated!');
        }

        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for inserting submitted iac
     */
    @IsTest
    static void testForInsert_SubmittedStatus_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(SUBMITTED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(FACULTY_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), insertedIac.reduivy__Submission_Date__c, 'Wrong submission date!');

        Test.stopTest();
    }

	
    /**
     * @description Test as faculty for inserting nonsubmitted iac
     */
    @IsTest
    static void testForInsert_NonSubmittedStatus_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(CANCELLED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(FACULTY_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for inserting empty status iac
     */
    @IsTest
    static void testForInsert_EmptyStatus_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(CANCELLED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(FACULTY_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for updating iac from non submitted to submitted
     */
    @IsTest
    static void testForUpdate_NonSubmittedToSubmittedStatus_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(CANCELLED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(FACULTY_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        insertedIac.reduivy__Verification_Status__c = SUBMITTED_STATUSES[0];

		System.runAs(FACULTY_USER){
            update insertedIac;
		}

        reduivy__Individual_Achievement__c updatedIac = queryIac();
        System.Assert.areEqual(iac.Id, updatedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], updatedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), updatedIac.reduivy__Submission_Date__c, 'Submission date should be updated to today!');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for updating iac from submitted to non submitted
     */
    @IsTest
    static void testForUpdate_SubmittedToNonSubmittedStatus_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();


        reduivy__Individual_Achievement__c iac = createIac(SUBMITTED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(FACULTY_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), insertedIac.reduivy__Submission_Date__c, 'Wrong submission date!');

        //update the submission date to simulate that the iac was submitted 2 days ago
        insertedIac.reduivy__Submission_Date__c = System.today().addDays(-2);
        update insertedIac;

        insertedIac.reduivy__Verification_Status__c = CANCELLED_STATUSES[0];
        
		System.runAs(FACULTY_USER){
            update insertedIac;
		}

        reduivy__Individual_Achievement__c updatedIac = queryIac();
        System.Assert.areEqual(iac.Id, updatedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], updatedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today().addDays(-2), updatedIac.reduivy__Submission_Date__c, 'Submission date should be not updated!');
        Test.stopTest();
    }

    /**
     * @description Test as faculty for updating iac from empty to submitted
     */
    @IsTest
    static void testForUpdate_EmptyToSubmittedStatus_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(null);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(FACULTY_USER){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(null, insertedIac.reduivy__Verification_Status__c, 'Submission status should be empty!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        insertedIac.reduivy__Verification_Status__c = SUBMITTED_STATUSES[0];

		System.runAs(FACULTY_USER){
            update insertedIac;
		}

        reduivy__Individual_Achievement__c updatedIac = queryIac();
        System.Assert.areEqual(iac.Id, updatedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], updatedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), updatedIac.reduivy__Submission_Date__c, 'Submission date should be updated to today!');

        Test.stopTest();
    }

	
    /**
     * @description Test as student for inserting submitted iac
     */
    @IsTest
    static void testForInsert_SubmittedStatus_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(SUBMITTED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(studentUser){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), insertedIac.reduivy__Submission_Date__c, 'Wrong submission date!');

        Test.stopTest();
    }

	
    /**
     * @description Test as student for inserting nonsubmitted iac
     */
    @IsTest
    static void testForInsert_NonSubmittedStatus_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(CANCELLED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(studentUser){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        Test.stopTest();
    }
	
    /**
     * @description Test as student for inserting empty status iac
     */
    @IsTest
    static void testForInsert_EmptyStatus_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(CANCELLED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(studentUser){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        Test.stopTest();
    }

    /**
     * @description Test as student for updating iac from non submitted to submitted
     */
    @IsTest
    static void testForUpdate_NonSubmittedToSubmittedStatus_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(CANCELLED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(studentUser){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        insertedIac.reduivy__Verification_Status__c = SUBMITTED_STATUSES[0];

		System.runAs(studentUser){
            update insertedIac;
		}

        reduivy__Individual_Achievement__c updatedIac = queryIac();
        System.Assert.areEqual(iac.Id, updatedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], updatedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), updatedIac.reduivy__Submission_Date__c, 'Submission date should be updated to today!');

        Test.stopTest();
    }

    /**
     * @description Test as student for updating iac from submitted to non submitted
     */
    @IsTest
    static void testForUpdate_SubmittedToNonSubmittedStatus_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();


        reduivy__Individual_Achievement__c iac = createIac(SUBMITTED_STATUSES[0]);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(studentUser){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], insertedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), insertedIac.reduivy__Submission_Date__c, 'Wrong submission date!');

        //update the submission date to simulate that the iac was submitted 2 days ago
        insertedIac.reduivy__Submission_Date__c = System.today().addDays(-2);
        update insertedIac;

        insertedIac.reduivy__Verification_Status__c = CANCELLED_STATUSES[0];
        
		System.runAs(studentUser){
            update insertedIac;
		}

        reduivy__Individual_Achievement__c updatedIac = queryIac();
        System.Assert.areEqual(iac.Id, updatedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(CANCELLED_STATUSES[0], updatedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today().addDays(-2), updatedIac.reduivy__Submission_Date__c, 'Submission date should be not updated!');
        Test.stopTest();
    }

    /**
     * @description Test as student for updating iac from empty to submitted
     */
    @IsTest
    static void testForUpdate_EmptyToSubmittedStatus_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Achievement__c iac = createIac(null);
        System.Assert.isNull(iac.reduivy__Submission_Date__c, 'Submission date should be empty!');
        
		System.runAs(studentUser){
            insert iac;
		}

        reduivy__Individual_Achievement__c insertedIac = queryIac();
        System.Assert.areEqual(iac.Id, insertedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(null, insertedIac.reduivy__Verification_Status__c, 'Submission status should be empty!');
        System.Assert.areEqual(null, insertedIac.reduivy__Submission_Date__c, 'Submission date should be empty!');

        insertedIac.reduivy__Verification_Status__c = SUBMITTED_STATUSES[0];

		System.runAs(studentUser){
            update insertedIac;
		}

        reduivy__Individual_Achievement__c updatedIac = queryIac();
        System.Assert.areEqual(iac.Id, updatedIac.Id, 'Wrong IAC queried!');
        System.Assert.areEqual(SUBMITTED_STATUSES[0], updatedIac.reduivy__Verification_Status__c, 'Wrong submission status!');
        System.Assert.areEqual(System.today(), updatedIac.reduivy__Submission_Date__c, 'Submission date should be updated to today!');

        Test.stopTest();
    }

    static reduivy__Individual_Achievement__c createIac(String status) {
        reduivy__Individual_Achievement__c iac = new reduivy__Individual_Achievement__c(
            reduivy__Verification_Status__c = status, 
            reduivy__Sample_Record_Code__c = IAC_SRC
        );

        return iac;
    }

    static reduivy__Individual_Achievement__c queryIac(){
        return [
            SELECT Id, reduivy__Verification_Status__c, reduivy__Submission_Date__c
            FROM reduivy__Individual_Achievement__c 
            WHERE reduivy__Sample_Record_Code__c = :IAC_SRC
        ];
    }
}