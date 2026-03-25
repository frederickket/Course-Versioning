/**
 * @author      WDCi (dblack)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for SOF_CancelOffering_EXE
 * @changehistory
 * ISS-001825 07-12-2023 dblack - new class
 */
@isTest
public inherited sharing class SOF_CancelOffering_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData() {
        
        // Create settings
		testFactory.setupDefaultSettings();
        
		// Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initOfferingData(REDU_TestData_FACTORY.FACULTY_SER);
            testFactory.initStudentData(ISN_Helper.getApiName(), true);

            Test.stopTest();
        }
    }
	
    /**
     * @description Test as an admin user that when a study offering is cancelled the related individual enrollment status is set to withdrawn
     */
    @isTest
    static void testCancelOfferingAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Setup test data

        List<String> sofCancelledStatuses = SOF_Helper.getCancelledStatuses();

        // Get the study offering records
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id, reduivy__Status__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Status__c NOT IN :sofCancelledStatuses
            ORDER BY reduivy__Study_Unit__r.reduivy__Unit_Code__c
        ]);

        //Get the individual enrollments
        List<reduivy__Individual_Enrollment__c> ienBeforeList = [
            SELECT reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Study_Offering__c IN :sofMap.keySet()
        ];

        // Update the study offering status to cancelled
        String sofStatusTypeCancelled = SOF_Helper.STATUS_TYPE_CANCELLED;

        for (reduivy__Study_Offering__c sof : sofMap.values()) {

            sof.reduivy__Status_Override__c = sofStatusTypeCancelled;
        }

		System.runAs(ADMIN_USER) {
		
            // Execute test
            Test.startTest();
            update sofMap.values();
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Enrollment__c> ienAfterList = [
            SELECT reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE Id IN :ienBeforeList
        ];

        System.Assert.isFalse(
            ienAfterList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        List<String> ienPositiveStatuses = new List<String>();
        ienPositiveStatuses.addAll(IEN_Helper.getInProgressStatuses());
        ienPositiveStatuses.addAll(IEN_Helper.getEnrollmentRequestedStatuses());
        ienPositiveStatuses.addAll(IEN_Helper.getWaitlistedStatuses());
        String ienStatusTypeWithdrawn = IEN_Helper.getWithdrawnStatuses().get(0);

        for (Integer i = 0; i < ienBeforeList.size(); i++) {
            if (ienPositiveStatuses.contains(ienBeforeList.get(i).reduivy__Enrollment_Status__c)) {
                System.Assert.areEqual(
                    ienStatusTypeWithdrawn,
                    ienAfterList.get(i).reduivy__Enrollment_Status__c,
                    'The individual enrollment status should be set to withdrawn'
                );
            } else {
                System.Assert.areEqual(
                    ienBeforeList.get(i).reduivy__Enrollment_Status__c,
                    ienAfterList.get(i).reduivy__Enrollment_Status__c,
                    'The individual enrollment status should be unchanged'
                );
            }
        }
    }

    /**
     * @description Test as a faculty user that when a study offering is cancelled the related individual enrollment status is not set to withdrawn
     */
    @isTest
    static void testCancelOfferingAsFaculty() {
	        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Setup test data

        List<String> sofCancelledStatuses = SOF_Helper.getCancelledStatuses();

        // Get the study offering records
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id, reduivy__Status__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Status__c NOT IN :sofCancelledStatuses
            ORDER BY reduivy__Study_Unit__r.reduivy__Unit_Code__c
        ]);

        // Update the study offering status to cancelled
        String sofStatusTypeCancelled = SOF_Helper.STATUS_TYPE_CANCELLED;

        for (reduivy__Study_Offering__c sof : sofMap.values()) {

            sof.reduivy__Status_Override__c = sofStatusTypeCancelled;
        }

		System.runAs(FACULTY_USER) {
		
            // Execute test
            Test.startTest();
            update sofMap.values();
            Test.stopTest();
		}

        // Verify test results
        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT reduivy__Enrollment_Status__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Study_Offering__c IN :sofMap.keySet()
        ];

        System.Assert.isFalse(
            ienList.isEmpty(),
            'The list should contain individual enrollment records'
        );

        String ienStatusTypeWithdrawn = IEN_Helper.getWithdrawnStatuses().get(0);

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            System.Assert.areNotEqual(
                ienStatusTypeWithdrawn,
                ien.reduivy__Enrollment_Status__c,
                'The individual enrollment status should not be set to withdrawn'
            );
        }
    }

    /**
     * @description Test as a student user that when a study offering is cancelled the related individual enrollment status is not set to withdrawn
     */
    @isTest
    static void testCancelOfferingAsStudent() {
	
        // Setup test data

        List<String> sofCancelledStatuses = SOF_Helper.getCancelledStatuses();

        // Get the study offering records
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id, reduivy__Status__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Status__c NOT IN :sofCancelledStatuses
            ORDER BY reduivy__Study_Unit__r.reduivy__Unit_Code__c
        ]);

        // Update the study offering status to cancelled
        String sofStatusTypeCancelled = SOF_Helper.STATUS_TYPE_CANCELLED;

        for (reduivy__Study_Offering__c sof : sofMap.values()) {

            sof.reduivy__Status_Override__c = sofStatusTypeCancelled;
        }

        User studentUser = testFactory.getStudentUser();
        
		System.runAs(studentUser) {
		
            try {

                // Execute test
                Test.startTest();
                update sofMap.values();
                Test.stopTest();

                System.Assert.fail('An exception should have been thrown');

            } catch (Exception e) {

                // Verify test results

                System.Assert.areEqual(
                    'Update failed',
                    e.getMessage().substringBefore('.'),
                    'The student user should not have sufficient access rights to cancel study offering records'
                );

                List<reduivy__Individual_Enrollment__c> ienList = [
                    SELECT reduivy__Enrollment_Status__c 
                    FROM reduivy__Individual_Enrollment__c 
                    WHERE reduivy__Study_Offering__c IN :sofMap.keySet()
                ];

                System.Assert.isFalse(
                    ienList.isEmpty(),
                    'The list should contain individual enrollment records'
                );

                String ienStatusTypeWithdrawn = IEN_Helper.getWithdrawnStatuses().get(0);

                for (reduivy__Individual_Enrollment__c ien : ienList) {
                    System.Assert.areNotEqual(
                        ienStatusTypeWithdrawn,
                        ien.reduivy__Enrollment_Status__c,
                        'The individual enrollment status should not be set to withdrawn'
                    );
                }
            }
		}
    }
}