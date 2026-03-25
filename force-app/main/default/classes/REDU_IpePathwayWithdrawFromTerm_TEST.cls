/**
 * @author      WDCi (XW)
 * @date        May 2025
 * @group       Test
 * @description Test class for REDU_IpePathwayWithdrawFromTerm_LCTRL
 * @changehistory
 * ISS-002436 06-05-2025 XW - create new class
 */
@IsTest
public inherited sharing class REDU_IpePathwayWithdrawFromTerm_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String SRC_CON = 'sandydoe@redu.example';
    static final String SRC_IPR = SRC_CON + '_' + 'CYT1';

    static final String ENROLLMENT_STATUS_ENROLLMENT_REQUESTED = 'Enrollment Requested';
    static final String ENROLLMENT_STATUS_ENROLLED = 'Enrolled';
    static final String ENROLLMENT_STATUS_WITHDRAWN = 'Withdrawn';
    static final String ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED = 'Withdrawal Requested';

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
        	
            testFactory.initMasterData(null);
            testFactory.initOfferingData(null);
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IPE_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }

    /**
     * @description Test as admin for getting enrolled (in progress) individual enrollments based on the ipr id
     */
    @IsTest
    static void testForAdminGetInprogressIen() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "Enrolled"!');
            expectedIdSet.add(ien.Id);
        }

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, ENROLLMENT_STATUS_ENROLLED);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');

            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for getting enrollment requested individual enrollments based on the ipr id
     */
    @IsTest
    static void testForAdminGetEnrollmentRequestedIen() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Set<Id> expectedIdSet = new Set<Id>();
        List<reduivy__Individual_Enrollment__c> expectedIenList = new List<reduivy__Individual_Enrollment__c>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            ien.reduivy__Enrollment_Status__c = ENROLLMENT_STATUS_ENROLLMENT_REQUESTED;
            expectedIenList.add(ien);
            expectedIdSet.add(ien.Id);
        }

        update expectedIenList;

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLMENT_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be updated!');
        }


        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, ENROLLMENT_STATUS_ENROLLMENT_REQUESTED);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');
            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for getting all individual enrollments based on the ipr id
     */
    @IsTest
    static void testForAdminGetIenWithoutStatus() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "Enrolled"!');
            expectedIdSet.add(ien.Id);
        }

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, null);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');

            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for getting Withdrawal Requested individual enrollments based on the ipr id
     */
    @IsTest
    static void testForAdminGetWithdrawalRequestedIen() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Set<Id> expectedIdSet = new Set<Id>();
        List<reduivy__Individual_Enrollment__c> expectedIenList = new List<reduivy__Individual_Enrollment__c>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            ien.reduivy__Enrollment_Status__c = ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED;
            expectedIenList.add(ien);
            expectedIdSet.add(ien.Id);
        }

        update expectedIenList;

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be updated!');
        }

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for getting default withdrawn status
     */
    @IsTest
    static void testForAdminGetDefaultWithdrawnStatus() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getDefaultWithdrawnStatus();

            System.Assert.areEqual(IEN_Helper.getWithdrawnStatuses()[0], response.responseData, 'Wrong default Withdraw status!');
		}

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for updating enrollment status
     */
    @IsTest
    static void testForAdminUpdateEnrollmentStatus() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        List<Id> ienIdList = new List<Id>();

        Id iprId;
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Academic_Progress__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Invalid Enrollment Status!');
            ienIdList.add(ien.Id);
            iprId = ien.reduivy__Individual_Academic_Progress__c;
        }

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.updateEnrollmentStatus(iprId, ienIdList, ENROLLMENT_STATUS_WITHDRAWN);
            List<String> actualIenList = (List<String>) JSON.deserialize(response.responseData, List<String>.class);

            System.Assert.isFalse(actualIenList.isEmpty(), 'Individual Enrollment should not be empty!');
		}

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be updated to Withdrawn!');
        }

        Test.stopTest();
		
    }

    
    /**
     * @description Test as student for getting enrolled (in progress) individual enrollments based on the ipr id
     */
    @IsTest
    static void testForStudentGetInprogressIen() {

        User studentUser = testFactory.getStudentUser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "Enrolled"!');
            expectedIdSet.add(ien.Id);
        }

        Test.startTest();
        
		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, ENROLLMENT_STATUS_ENROLLED);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');

            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as student for getting enrollment requested individual enrollments based on the ipr id
     */
    @IsTest
    static void testForStudentGetEnrollmentRequestedIen() {

        User studentUser = testFactory.getStudentUser();
        Set<Id> expectedIdSet = new Set<Id>();
        List<reduivy__Individual_Enrollment__c> expectedIenList = new List<reduivy__Individual_Enrollment__c>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            ien.reduivy__Enrollment_Status__c = ENROLLMENT_STATUS_ENROLLMENT_REQUESTED;
            expectedIenList.add(ien);
            expectedIdSet.add(ien.Id);
        }

        update expectedIenList;

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLMENT_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be updated!');
        }


        Test.startTest();
        
		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, ENROLLMENT_STATUS_ENROLLMENT_REQUESTED);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');
            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }

    
    /**
     * @description Test as student for getting Withdrawal Requested individual enrollments based on the ipr id
     */
    @IsTest
    static void testForStudentGetWithdrawalRequestedIen() {

        User studentUser = testFactory.getStudentUser();
        Set<Id> expectedIdSet = new Set<Id>();
        List<reduivy__Individual_Enrollment__c> expectedIenList = new List<reduivy__Individual_Enrollment__c>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            ien.reduivy__Enrollment_Status__c = ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED;
            expectedIenList.add(ien);
            expectedIdSet.add(ien.Id);
        }

        update expectedIenList;

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be updated!');
        }

        Test.startTest();
        
		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as student for getting all individual enrollments based on the ipr id
     */
    @IsTest
    static void testForStudentGetIenWithoutStatus() {

        User studentUser = testFactory.getStudentUser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "Enrolled"!');
            expectedIdSet.add(ien.Id);
        }

        Test.startTest();
        
		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, null);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');

            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for getting default withdrawn status
     */
    @IsTest
    static void testForStudentGetDefaultWithdrawnStatus() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getDefaultWithdrawnStatus();

            System.Assert.areEqual(IEN_Helper.getWithdrawnStatuses()[0], response.responseData, 'Wrong default Withdraw status!');
		}

        Test.stopTest();
        
		
    }

    
    /**
     * @description Test as student for updating enrollment status
     */
    @IsTest
    static void testForStudentUpdateEnrollmentStatus() {

        User studentUser = testFactory.getStudentUser();
        List<Id> ienIdList = new List<Id>();
        Id iprId;

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Academic_Progress__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Invalid Enrollment Status!');
            ienIdList.add(ien.Id);
            iprId = ien.reduivy__Individual_Academic_Progress__c;
        }

        Test.startTest();
        
		System.runAs(studentUser){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.updateEnrollmentStatus(iprId, ienIdList, ENROLLMENT_STATUS_WITHDRAWN);
            List<String> actualIenList = (List<String>) JSON.deserialize(response.responseData, List<String>.class);

            System.Assert.isFalse(actualIenList.isEmpty(), 'Individual Enrollment should not be empty!');
		}

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be updated to Withdrawn!');
        }

        Test.stopTest();
		
    }

    
    /**
     * @description Test as faculty for getting enrolled (in progress) individual enrollments based on the ipr id
     */
    @IsTest
    static void testForFacultyGetInprogressIen() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "Enrolled"!');
            expectedIdSet.add(ien.Id);
        }

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, ENROLLMENT_STATUS_ENROLLED);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');

            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for getting enrollment requested individual enrollments based on the ipr id
     */
    @IsTest
    static void testForFacultyGetEnrollmentRequestedIen() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Set<Id> expectedIdSet = new Set<Id>();
        List<reduivy__Individual_Enrollment__c> expectedIenList = new List<reduivy__Individual_Enrollment__c>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            ien.reduivy__Enrollment_Status__c = ENROLLMENT_STATUS_ENROLLMENT_REQUESTED;
            expectedIenList.add(ien);
            expectedIdSet.add(ien.Id);
        }

        update expectedIenList;

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLMENT_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be updated!');
        }


        Test.startTest();
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, ENROLLMENT_STATUS_ENROLLMENT_REQUESTED);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');
            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }

    
    /**
     * @description Test as faculty for getting Withdrawal Requested individual enrollments based on the ipr id
     */
    @IsTest
    static void testForFacultyGetWithdrawalRequestedIen() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Set<Id> expectedIdSet = new Set<Id>();
        List<reduivy__Individual_Enrollment__c> expectedIenList = new List<reduivy__Individual_Enrollment__c>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            ien.reduivy__Enrollment_Status__c = ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED;
            expectedIenList.add(ien);
            expectedIdSet.add(ien.Id);
        }

        update expectedIenList;

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be updated!');
        }

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for getting all individual enrollments based on the ipr id
     */
    @IsTest
    static void testForFacultyGetIenWithoutStatus() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "Enrolled"!');
            expectedIdSet.add(ien.Id);
        }

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getIndividualEnrollments(ipr.Id, null);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');

            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for getting default withdrawn status
     */
    @IsTest
    static void testForFacultyGetDefaultWithdrawnStatus() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.getDefaultWithdrawnStatus();

            System.Assert.areEqual(IEN_Helper.getWithdrawnStatuses()[0], response.responseData, 'Wrong default Withdraw status!');
		}

        Test.stopTest();
		
    }
    
    /**
     * @description Test as faculty for updating enrollment status
     */
    @IsTest
    static void testForFacultyUpdateEnrollmentStatus() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        List<Id> ienIdList = new List<Id>();
        Id iprId;

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Academic_Progress__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Invalid Enrollment Status!');
            ienIdList.add(ien.Id);
            iprId = ien.reduivy__Individual_Academic_Progress__c;
        }

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_IpePathwayWithdrawFromTerm_LCTRL.updateEnrollmentStatus(iprId, ienIdList, ENROLLMENT_STATUS_WITHDRAWN);
            List<String> actualIenList = (List<String>) JSON.deserialize(response.responseData, List<String>.class);

            System.Assert.isFalse(actualIenList.isEmpty(), 'Individual Enrollment should not be empty!');
		}

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be updated to Withdrawn!');
        }

        Test.stopTest();
		
    }

	
	
}