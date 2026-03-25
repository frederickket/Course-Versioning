/**
 * @author      WDCi (Lean)
 * @date        June 2025
 * @group       Enrollment Wizard
 * @description Enrollment finalization
 * @changehistory
 * ISS-002493 10-06-2025 Lean - new class
 */
@IsTest
public inherited sharing class REDU_IpePathwayEnrollmentFinalize_TEST {

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
     * @description Test as admin for getting individual enrollments based on the ipr id
     */
    @IsTest
    static void testForAdminGetIndividualEnrollments() {

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
            REDU_LightningResponse response = REDU_IpePathwayEnrollmentFinalize_LCTRL.getIndividualEnrollments(ipr.Id);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');

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
    static void testForStudentGetIndividualEnrollments() {

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
            REDU_LightningResponse response = REDU_IpePathwayEnrollmentFinalize_LCTRL.getIndividualEnrollments(ipr.Id);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');

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
    static void testForFacultyGetIndividualEnrollments() {

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
            REDU_LightningResponse response = REDU_IpePathwayEnrollmentFinalize_LCTRL.getIndividualEnrollments(ipr.Id);
            List<reduivy__Individual_Enrollment__c> actualIenList = (List<reduivy__Individual_Enrollment__c>) JSON.deserialize(response.responseData, List<reduivy__Individual_Enrollment__c>.class);
            
            System.Assert.isTrue(!actualIenList.isEmpty(), 'ien list should be retrieved!');

            for(reduivy__Individual_Enrollment__c ien : actualIenList) {
                System.Assert.isTrue(expectedIdSet.contains(ien.Id));
            }
        }

        Test.stopTest();
		
    }
}