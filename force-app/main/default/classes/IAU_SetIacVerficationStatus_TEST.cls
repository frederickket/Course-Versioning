/**
 * @author      WDCi (XW)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for IAU_SetIacVerficationStatus_EXE
 * @changehistory
 * ISS-002633 21-01-2026 XW - new class
 */
@IsTest
public inherited sharing class IAU_SetIacVerficationStatus_TEST {

    private static List<String> IAC_VERIFIED_VERIFICATION_STATUSES = IAC_Helper.getVerifiedVerificationStatuses();
    private static List<String> IAC_OPEN_VERIFICATION_STATUSES = IAC_Helper.getOpenVerificationStatuses();
    private static List<String> IAU_VERIFIED_VERIFICATION_STATUSES = IAU_Helper.getVerifiedVerificationStatuses();
    private static List<String> IAU_OPEN_VERIFICATION_STATUSES = IAU_Helper.getOpenVerificationStatuses();
    static final String INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG = 'Insufficient UPDATABLE access';

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String CON_SRC = 'sandydoe@redu.example';
    static final String IAC_SRC = CON_SRC + 'Individual_Achievement';
    static final String NEW_IAC_SRC = 'NEW' + CON_SRC + 'Individual_Achievement';
    
    static final String ARU_SRC = 'ARU_Introduction_to_Business_Studies';
    static final String IAU_SRC = IAC_SRC + '_' + ARU_SRC;
    static final String NEW_IAU_SRC = 'NEW' + IAC_SRC + '_' + ARU_SRC;

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

            for(reduivy__Individual_Achievement__c iac : testFactory.idvAchievement.values()) {
                iac.reduivy__Verification_Status__c = IAC_VERIFIED_VERIFICATION_STATUSES.get(0);
            }
            
            update testFactory.idvAchievement.values();
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for inserting new open iau
     */
    @IsTest
    static void testForInsert_OpenIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(ADMIN_USER){
            insert newIau;
		}

        System.Assert.areEqual(IAU_OPEN_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for bulk inserting new open iau
     */
    @IsTest
    static void testForBulkInsert_OpenIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        List<reduivy__Individual_Achievement__c> newIacList = new List<reduivy__Individual_Achievement__c>();
        reduivy__Individual_Achievement__c oriIac = queryIac();
        for(Integer i = 0; i < 100; i++) {
            reduivy__Individual_Achievement__c iac = oriIac.clone(false, false);
            newIacList.add(iac);
            System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));
        }

        insert newIacList;

        List<reduivy__Individual_Achievement_Unit__c> newIauList = new List<reduivy__Individual_Achievement_Unit__c>();
        for(reduivy__Individual_Achievement__c iac : newIacList) {
            reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
            newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
            newIauList.add(newIau);
        }

        
		System.runAs(ADMIN_USER){
            insert newIauList;
		}
        Map<Id, reduivy__Individual_Achievement__c> iacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList(newIacList));
        for(reduivy__Individual_Achievement_Unit__c newIau : newIauList) {
            System.Assert.areEqual(IAU_OPEN_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
            reduivy__Individual_Achievement__c iac = iacMap.get(newIau.reduivy__Individual_Achievement__c);
            System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));
        }


        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for inserting new verified iau
     */
    @IsTest
    static void testForInsert_VerifiedIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_VERIFIED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(ADMIN_USER){
            insert newIau;
		}

        System.Assert.areEqual(IAU_VERIFIED_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for inserting new verified iau
     */
    @IsTest
    static void testForInsert_BlankStatusIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = null;
        
		System.runAs(ADMIN_USER){
            insert newIau;
		}

        System.Assert.isNull(newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating iau from open to verified 
     */
    @IsTest
    static void testForUpdate_OpenIauToVerfiedIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(ADMIN_USER){
            insert newIau;
		}

        System.Assert.areEqual(IAU_OPEN_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', open statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));

        //update
        newIau.reduivy__Verification_Status__c = IAU_VERIFIED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(ADMIN_USER){
            update newIau;
        }

        
        System.Assert.areEqual(IAU_VERIFIED_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));



        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for updating iau from verified to open
     */
    @IsTest
    static void testForUpdate_VerifiedIauToOpenIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_VERIFIED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(ADMIN_USER){
            insert newIau;
		}

        System.Assert.areEqual(IAU_VERIFIED_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        //update
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(ADMIN_USER){
            update newIau;
        }

        
        System.Assert.areEqual(IAU_OPEN_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', open statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));



        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating iau from verified to open
     */
    @IsTest
    static void testForBulkUpdate_VerifiedIauToOpenIau_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        List<reduivy__Individual_Achievement__c> newIacList = new List<reduivy__Individual_Achievement__c>();
        reduivy__Individual_Achievement__c oriIac = queryIac();
        for(Integer i = 0; i < 100; i++) {
            reduivy__Individual_Achievement__c iac = oriIac.clone(false, false);
            newIacList.add(iac);
            System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));
        }

        insert newIacList;

        List<reduivy__Individual_Achievement_Unit__c> newIauList = new List<reduivy__Individual_Achievement_Unit__c>();
        for(reduivy__Individual_Achievement__c iac : newIacList) {
            reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
            newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
            newIauList.add(newIau);
        }

        
		System.runAs(ADMIN_USER){
            insert newIauList;
		}
        Map<Id, reduivy__Individual_Achievement__c> iacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList(newIacList));
        for(reduivy__Individual_Achievement_Unit__c newIau : newIauList) {
            System.Assert.areEqual(IAU_OPEN_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
            reduivy__Individual_Achievement__c iac = iacMap.get(newIau.reduivy__Individual_Achievement__c);
            System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));
        }

        //update
        for(reduivy__Individual_Achievement_Unit__c newIau : newIauList) {
            newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        }
        
		System.runAs(ADMIN_USER){
            update newIauList;
        }

        
        iacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList(newIacList));
        for(reduivy__Individual_Achievement_Unit__c newIau : newIauList) {
            System.Assert.areEqual(IAU_OPEN_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
            reduivy__Individual_Achievement__c iac = iacMap.get(newIau.reduivy__Individual_Achievement__c);
            System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', open statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));
        }



        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for inserting new open iau
     */
    @IsTest
    static void testForInsert_OpenIau_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(FACULTY_USER){
            try {
                insert newIau;
                System.Assert.fail('Should be failed due to ' + INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG);
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG), 'Wrong error message! Actual message: ' + exp.getMessage());
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for inserting new verified iau
     */
    @IsTest
    static void testForInsert_VerifiedIau_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_VERIFIED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(FACULTY_USER){
            insert newIau;
		}

        System.Assert.areEqual(IAU_VERIFIED_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for inserting new verified iau
     */
    @IsTest
    static void testForInsert_BlankStatusIau_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = null;
        
		System.runAs(FACULTY_USER){
            insert newIau;
		}

        System.Assert.isNull(newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating iau from open to verified 
     */
    @IsTest
    static void testForUpdate_OpenIauToVerfiedIau_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
         
		System.runAs(FACULTY_USER){
            try {
                insert newIau;
                System.Assert.fail('Should be failed due to ' + INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG);
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG), 'Wrong error message! Actual message: ' + exp.getMessage());
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for updating iau from verified to open
     */
    @IsTest
    static void testForUpdate_VerifiedIauToOpenIau_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_VERIFIED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(FACULTY_USER){
            insert newIau;
		}

        System.Assert.areEqual(IAU_VERIFIED_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        //update
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(FACULTY_USER){
            try {
                update newIau;
                System.Assert.fail('Should be failed due to ' + INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG);
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_UPDATABLE_ACCESS_ERROR_MSG), 'Wrong error message! Actual message: ' + exp.getMessage());
            }
        }

        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for inserting new open iau
     */
    @IsTest
    static void testForInsert_OpenIau_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
         
		System.runAs(studentUser){
            insert newIau; 
		}

        System.Assert.areEqual(IAU_OPEN_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', open statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for inserting new verified iau
     */
    @IsTest
    static void testForInsert_VerifiedIau_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_VERIFIED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(studentUser){
            insert newIau;
		}

        System.Assert.areEqual(IAU_VERIFIED_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        Test.stopTest();
		
    }

    /**
     * @description Test as student for inserting new verified iau
     */
    @IsTest
    static void testForInsert_BlankStatusIau_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = null;
        
		System.runAs(studentUser){
            insert newIau;
		}

        System.Assert.isNull(newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating iau from open to verified 
     */
    @IsTest
    static void testForUpdate_OpenIauToVerfiedIau_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
         
        
		System.runAs(studentUser){
            insert newIau;
		}

        System.Assert.areEqual(IAU_OPEN_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', open statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));

        //update
        newIau.reduivy__Verification_Status__c = IAU_VERIFIED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(studentUser){
            update newIau;
        }
        
        System.Assert.areEqual(IAU_VERIFIED_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', open statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));




        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for updating iau from verified to open
     */
    @IsTest
    static void testForUpdate_VerifiedIauToOpenIau_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        reduivy__Agreement_Recognition_Unit__c aru = queryAru();
        reduivy__Individual_Achievement__c iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        reduivy__Individual_Achievement_Unit__c newIau = createNewIau(aru.Id, iac.Id);
        newIau.reduivy__Verification_Status__c = IAU_VERIFIED_VERIFICATION_STATUSES.get(0);
        
		System.runAs(studentUser){
            insert newIau;
		}

        System.Assert.areEqual(IAU_VERIFIED_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_VERIFIED_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be verified! Status: ' + iac.reduivy__Verification_Status__c + ', verified statuses list: ' + String.join(IAC_VERIFIED_VERIFICATION_STATUSES, ', '));

        //update
        newIau.reduivy__Verification_Status__c = IAU_OPEN_VERIFICATION_STATUSES.get(0);
        
		System.runAs(studentUser){
            update newIau;
        }

        
        System.Assert.areEqual(IAU_OPEN_VERIFICATION_STATUSES.get(0), newIau.reduivy__Verification_Status__c, 'Wrong IAU verification status!');
        iac = queryIac();
        System.Assert.isTrue(IAC_OPEN_VERIFICATION_STATUSES.contains(iac.reduivy__Verification_Status__c), 'Verification status should be open! Status: ' + iac.reduivy__Verification_Status__c + ', open statuses list: ' + String.join(IAC_OPEN_VERIFICATION_STATUSES, ', '));



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

    public static reduivy__Individual_Achievement_Unit__c queryIau() {
        return [
            SELECT Id, reduivy__Verification_Status__c
            FROM reduivy__Individual_Achievement_Unit__c
            WHERE reduivy__Sample_Record_Code__c = :IAU_SRC
        ];
    }

    public static reduivy__Individual_Achievement__c queryIac() {
        return [
            SELECT Id, reduivy__Verification_Status__c
            FROM reduivy__Individual_Achievement__c
            WHERE reduivy__Sample_Record_Code__c = :IAC_SRC
        ];
    }

    public static List<reduivy__Individual_Achievement__c> queryIacList(List<reduivy__Individual_Achievement__c> iacList) {
        return [
            SELECT Id, reduivy__Verification_Status__c
            FROM reduivy__Individual_Achievement__c
            WHERE Id IN :iacList
        ];
    }

    


    public static reduivy__Agreement_Recognition_Unit__c queryAru() {
        return [
            SELECT Id
            FROM reduivy__Agreement_Recognition_Unit__c
            WHERE reduivy__Sample_Record_Code__c = :ARU_SRC
        ];
    }

    public static Contact queryCon() {
        return [
            SELECT Id
            FROM Contact
            WHERE reduivy__Sample_Record_Code__c = :CON_SRC
        ];
    }
	
    
	
}