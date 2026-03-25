/**
 * @author      WDCi (Jordan)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for REDU_IpePathwayTerm_LCTRL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_IpePathwayTerm_TEST {

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

            testFactory.initMasterData(null);
			testFactory.initOfferingData(SIT_Helper.getApiName());
			testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTerm_LCTRL
     */
    @isTest   
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        List<String> positiveIpeEnrollmentStatuses = IPE_Helper.getPositiveStatuses();

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id,
            RecordTypeId,
            Name,
            reduivy__Enrollment_Status__c,
            (
                SELECT Id,
                RecordTypeId,
                Name,
                reduivy__Enrollment_Status__c
                FROM reduivy__Child_Individual_Program_Enrollments__r
                WHERE reduivy__Enrollment_Status__c IN: positiveIpeEnrollmentStatuses
                ORDER BY CreatedDate
            )
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id =: masterIPE.Id
        ];

        List<reduivy__Individual_Program_Enrollment__c> sortedIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
        for (reduivy__Individual_Program_Enrollment__c masterIpeLoop : ipeList) {
            sortedIpeList.add(masterIpeLoop);

            for (reduivy__Individual_Program_Enrollment__c childIpe : masterIpeLoop.reduivy__Child_Individual_Program_Enrollments__r) {
                sortedIpeList.add(childIpe);
            }
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTerm_LCTRL.getIndividualProgramEnrollments(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTerm_TEST');

            List<reduivy__Individual_Program_Enrollment__c> sortedIpeListResponse = (List<reduivy__Individual_Program_Enrollment__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Individual_Program_Enrollment__c>.class);
            System.Assert.areEqual(sortedIpeList.size(), sortedIpeListResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as student user for REDU_IpePathwayTerm_LCTRL
     */
    @isTest   
    static void testForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        List<String> positiveIpeEnrollmentStatuses = IPE_Helper.getPositiveStatuses();

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id,
            RecordTypeId,
            Name,
            reduivy__Enrollment_Status__c,
            (
                SELECT Id,
                RecordTypeId,
                Name,
                reduivy__Enrollment_Status__c
                FROM reduivy__Child_Individual_Program_Enrollments__r
                WHERE reduivy__Enrollment_Status__c IN: positiveIpeEnrollmentStatuses
                ORDER BY CreatedDate
            )
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id =: masterIPE.Id
        ];

        List<reduivy__Individual_Program_Enrollment__c> sortedIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
        for (reduivy__Individual_Program_Enrollment__c masterIpeLoop : ipeList) {
            sortedIpeList.add(masterIpeLoop);

            for (reduivy__Individual_Program_Enrollment__c childIpe : masterIpeLoop.reduivy__Child_Individual_Program_Enrollments__r) {
                sortedIpeList.add(childIpe);
            }
        }

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTerm_LCTRL.getIndividualProgramEnrollments(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTerm_TEST');

            List<reduivy__Individual_Program_Enrollment__c> sortedIpeListResponse = (List<reduivy__Individual_Program_Enrollment__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Individual_Program_Enrollment__c>.class);
            System.Assert.areEqual(sortedIpeList.size(), sortedIpeListResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpePathwayTerm_LCTRL
     */
    @isTest   
    static void testForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        List<String> positiveIpeEnrollmentStatuses = IPE_Helper.getPositiveStatuses();

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id,
            RecordTypeId,
            Name,
            reduivy__Enrollment_Status__c,
            (
                SELECT Id,
                RecordTypeId,
                Name,
                reduivy__Enrollment_Status__c
                FROM reduivy__Child_Individual_Program_Enrollments__r
                WHERE reduivy__Enrollment_Status__c IN: positiveIpeEnrollmentStatuses
                ORDER BY CreatedDate
            )
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id =: masterIPE.Id
        ];

        List<reduivy__Individual_Program_Enrollment__c> sortedIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
        for (reduivy__Individual_Program_Enrollment__c masterIpeLoop : ipeList) {
            sortedIpeList.add(masterIpeLoop);

            for (reduivy__Individual_Program_Enrollment__c childIpe : masterIpeLoop.reduivy__Child_Individual_Program_Enrollments__r) {
                sortedIpeList.add(childIpe);
            }
        }

        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTerm_LCTRL.getIndividualProgramEnrollments(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTerm_TEST');

            List<reduivy__Individual_Program_Enrollment__c> sortedIpeListResponse = (List<reduivy__Individual_Program_Enrollment__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Individual_Program_Enrollment__c>.class);
            System.Assert.areEqual(sortedIpeList.size(), sortedIpeListResponse.size());
            
            Test.stopTest();
        }
    }
}