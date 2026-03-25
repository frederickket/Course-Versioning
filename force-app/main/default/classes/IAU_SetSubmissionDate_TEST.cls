/**
 * @author      WDCi (XW)
 * @date        Feb 2026
 * @group       Test
 * @description Test class for IAU_SetSubmissionDate_LCTRL
 * @changehistory
 * ISS-002633 03-02-2026 XW - new class
 */
@IsTest
public inherited sharing class IAU_SetSubmissionDate_TEST {

    private static List<String> IAU_SUBMITTED_VERIFICATION_STATUSES = IAU_Helper.getSubmittedVerificationStatuses();
    private static List<String> IAU_OPEN_VERIFICATION_STATUSES = IAU_Helper.getOpenVerificationStatuses();

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String CON_SRC = 'sandydoe@redu.example';
    static final String IAC_SRC = CON_SRC + 'Individual_Achievement';
    static final String NEW_IAC_SRC = 'NEW' + CON_SRC + 'Individual_Achievement';
    
    static final String ARU_SRC = 'ARU_Introduction_to_Business_Studies';

    static final String INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG = 'Insufficient UPDATABLE access';

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
            testFactory.initMasterData(ARU_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IAU_Helper.getApiName(), true);

            update testFactory.idvAchievement.values();
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for inserting open iau
     */
    @IsTest
    static void testForInsert_OpenIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(ADMIN_USER){
            insert newIau;
		}

        reduivy__Individual_Achievement_Unit__c insertedIau = queryIau(newIau.Id);
        System.Assert.isNull(insertedIau.reduivy__Submission_Date__c, 'Submission date should be null! Actual: ' + insertedIau.reduivy__Submission_Date__c);
        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for inserting submitted iau
     */
    @IsTest
    static void testForInsert_SubmittedIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(ADMIN_USER){
            insert newIau;
		}

        reduivy__Individual_Achievement_Unit__c insertedIau = queryIau(newIau.Id);
        System.Assert.areEqual(System.today(), insertedIau.reduivy__Submission_Date__c, 'Submission date should be today!');
        Test.stopTest();
    }
	
    /**
     * @description Test as admin for updating open iau to submitted
     */
    @IsTest
    static void testForUpdate_OpenToSubmittedIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(ADMIN_USER){
            insert newIau;
		}

        reduivy__Individual_Achievement_Unit__c insertedIau = queryIau(newIau.Id);
        System.Assert.isNull(insertedIau.reduivy__Submission_Date__c, 'Submission date should be null! Actual: ' + insertedIau.reduivy__Submission_Date__c);

        insertedIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
		System.runAs(ADMIN_USER){
            update insertedIau;
		}

        reduivy__Individual_Achievement_Unit__c updatedIau = queryIau(insertedIau.Id);
        System.Assert.areEqual(System.today(), updatedIau.reduivy__Submission_Date__c, 'Submission date should be today!');

        Test.stopTest();
    }

    /**
     * @description Test as admin for updating submitted iau to open
     */
    @IsTest
    static void testForUpdate_SubmittedToOpenIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(ADMIN_USER){
            insert newIau;
		}

        reduivy__Individual_Achievement_Unit__c insertedIau = queryIau(newIau.Id);
        System.Assert.areEqual(System.today(), insertedIau.reduivy__Submission_Date__c, 'Submission date should be today!');
        
        insertedIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
		System.runAs(ADMIN_USER){
            update insertedIau;
		}

        reduivy__Individual_Achievement_Unit__c updatedIau = queryIau(insertedIau.Id);
        System.Assert.areEqual(System.today(), updatedIau.reduivy__Submission_Date__c, 'Submission date should be today!');

        Test.stopTest();
    }

	
    /**
     * @description Test as faculty for inserting open iau
     */
    @IsTest
    static void testForInsert_OpenIau_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(FACULTY_USER){
            try {
                insert newIau;
                System.Assert.fail('Should failed with ' + INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG);
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG), 'Wrong exception message! Actual: ' + exp.getMessage());
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for inserting submitted iau
     */
    @IsTest
    static void testForInsert_SubmittedIau_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(FACULTY_USER){
            insert newIau;
		}

        reduivy__Individual_Achievement_Unit__c insertedIau = queryIau(newIau.Id);
        System.Assert.areEqual(System.today(), insertedIau.reduivy__Submission_Date__c, 'Submission date should be today!');
        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for updating open iau to submitted
     */
    @IsTest
    static void testForUpdate_OpenToSubmittedIau_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(FACULTY_USER){
            try {
                insert newIau;
                System.Assert.fail('Should failed with ' + INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG);
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG), 'Wrong exception message! Actual: ' + exp.getMessage());
            }
		}
        
        Test.stopTest();
    }

    /**
     * @description Test as faculty for updating submitted iau to open
     */
    @IsTest
    static void testForUpdate_SubmittedToOpenIau_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(FACULTY_USER){
            insert newIau;
		}

        reduivy__Individual_Achievement_Unit__c insertedIau = queryIau(newIau.Id);
        System.Assert.areEqual(System.today(), insertedIau.reduivy__Submission_Date__c, 'Submission date should be today!');
        
        insertedIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
		System.runAs(FACULTY_USER){
            update insertedIau;
		}

        reduivy__Individual_Achievement_Unit__c updatedIau = queryIau(insertedIau.Id);
        System.Assert.areEqual(System.today(), updatedIau.reduivy__Submission_Date__c, 'Submission date should be today!');

        Test.stopTest();
    }
    
    
	
    /**
     * @description Test as student for inserting open iau
     */
    @IsTest
    static void testForInsert_OpenIau_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(studentUser){
            insert newIau;
		}

        reduivy__Individual_Achievement_Unit__c insertedIau = queryIau(newIau.Id);
        System.Assert.isNull(insertedIau.reduivy__Submission_Date__c, 'Submission date should be null! Actual: ' + insertedIau.reduivy__Submission_Date__c);
        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for inserting submitted iau
     */
    @IsTest
    static void testForInsert_SubmittedIau_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(studentUser){
            insert newIau;
		}

        reduivy__Individual_Achievement_Unit__c insertedIau = queryIau(newIau.Id);
        System.Assert.areEqual(System.today(), insertedIau.reduivy__Submission_Date__c, 'Submission date should be today!');
        Test.stopTest();
    }
	
    /**
     * @description Test as student for updating open iau to submitted
     */
    @IsTest
    static void testForUpdate_OpenToSubmittedIau_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(studentUser){
            insert newIau;
		}

        reduivy__Individual_Achievement_Unit__c insertedIau = queryIau(newIau.Id);
        System.Assert.isNull(insertedIau.reduivy__Submission_Date__c, 'Submission date should be null! Actual: ' + insertedIau.reduivy__Submission_Date__c);

        insertedIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
		System.runAs(studentUser){
            update insertedIau;
		}

        reduivy__Individual_Achievement_Unit__c updatedIau = queryIau(insertedIau.Id);
        System.Assert.areEqual(System.today(), updatedIau.reduivy__Submission_Date__c, 'Submission date should be today!');

        Test.stopTest();
    }

    /**
     * @description Test as student for updating submitted iau to open
     */
    @IsTest
    static void testForUpdate_SubmittedToOpenIau_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(studentUser){
            insert newIau;
		}

        reduivy__Individual_Achievement_Unit__c insertedIau = queryIau(newIau.Id);
        System.Assert.areEqual(System.today(), insertedIau.reduivy__Submission_Date__c, 'Submission date should be today!');
        
        insertedIau.reduivy__Verification_Status__c = IAU_SUBMITTED_VERIFICATION_STATUSES.get(0);
		System.runAs(studentUser){
            update insertedIau;
		}

        reduivy__Individual_Achievement_Unit__c updatedIau = queryIau(insertedIau.Id);
        System.Assert.areEqual(System.today(), updatedIau.reduivy__Submission_Date__c, 'Submission date should be today!');

        Test.stopTest();
    }

    public static reduivy__Individual_Achievement_Unit__c createNewIau(Id aruId, Id iacId) {
        return new reduivy__Individual_Achievement_Unit__c(
            reduivy__Sample_Record_Code__c = NEW_IAC_SRC,
            reduivy__Agreement_Recognition_Unit__c = aruId,
            reduivy__Individual_Achievement__c = iacId,
            reduivy__Numerical_Grade__c = 80,
            reduivy__Verification_Status__c = null
        );
    }

    public static reduivy__Individual_Achievement_Unit__c queryIau(Id iauId) {
        return [
            SELECT Id, reduivy__Submission_Date__c
            FROM reduivy__Individual_Achievement_Unit__c
            WHERE id = :iauId
        ];
    }


    public static reduivy__Individual_Achievement__c queryIac() {
        return [
            SELECT Id, reduivy__Verification_Status__c
            FROM reduivy__Individual_Achievement__c
            WHERE reduivy__Sample_Record_Code__c = :IAC_SRC
        ];
    }

    public static reduivy__Agreement_Recognition_Unit__c queryAru() {
        return [
            SELECT Id
            FROM reduivy__Agreement_Recognition_Unit__c
            WHERE reduivy__Sample_Record_Code__c = :ARU_SRC
        ];
    }
	
}