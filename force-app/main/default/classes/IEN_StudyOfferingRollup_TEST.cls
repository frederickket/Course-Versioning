/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IEN_StudyOfferingRollup_EXE
 * @changehistory
 * ISS-001761 26-10-2023 dblack - new class
 * ISS-001890 06-06-2024 sueanne - update test when status change to 'Withdrawn'
 * ISS-002060 14-10-2024 Sueanne - added undelete event test
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IEN_StudyOfferingRollup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Create settings and test data
     */
	@TestSetup
    static void makeData() {

		// Create settings
		testFactory.setupDefaultSettings();
        
        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SUN_Helper.getApiName());
			testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IEN_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin that individual enrollments rollup booked and waitlist places to the Study Offering record after insert ien status = Waitlisted
     */
    @IsTest
    static void testRollupInsertWaitlistedAsAdminUser() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get statuses
        List<String> ienWaitlistedStatus = IEN_Helper.getWaitlistedStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so = null;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Student Individual Enrollment map should not be empty.');

        //create new ien
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        if(!ienToTest.isEmpty()){
            //get 1 ien to create the similar ien
            reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

            //prepare ien to insert
            datetime dtNow = datetime.now();
            ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
                selectedIen.reduivy__Contact__c,
                so.Id,
                ienWaitlistedStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                null, 
                null, 
                10,
                null,
                selectedIen.reduivy__Individual_Academic_Profile__c,
                true
            ));
        }
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment To Insert Map should not be empty.');

        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            //get study offering before insert
            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //Insertion test - check whether update waitlisted place in Study Offering after ien insert
            REDU_Database_UTIL.doInsert(ienToInsert);

            //get study offering after insert
			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = : so.Id
            ];
            
			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c + 1, soAfter.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated');

            Test.stopTest();

        }
	}

    /**
     * @description Test as admin that individual enrollments rollup booked and waitlist places to the Study Offering record after insert ien status = InProgress
     */
    @IsTest
    static void testRollupInsertInProgressAsAdminUser() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so = null;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Student Individual Enrollment map should not be empty.');

        //create new ien
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        if(!ienToTest.isEmpty()){
            //get 1 ien to create the similar ien
            reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

            //prepare ien to insert
            datetime dtNow = datetime.now();
            ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
                selectedIen.reduivy__Contact__c,
                so.Id,
                ienInProgressStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                null, 
                null, 
                10,
                null,
                selectedIen.reduivy__Individual_Academic_Profile__c,
                true
            ));
        }
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment To Insert Map should not be empty.');

        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            //get study offering before insert
            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //Insertion test - check whether update waitlisted place in Study Offering after ien insert
            REDU_Database_UTIL.doInsert(ienToInsert);

            //get study offering after insert
			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = : so.Id
            ];
            
			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c + 1, soAfter.reduivy__Booked_Places__c, 'Booked Place is not updated');

            Test.stopTest();

        }
	}

    /**
     * @description Test as admin that individual enrollments rollup booked and waitlist places to the Study Offering record after insert ien status = Withdrawn
     */
    @IsTest
    static void testRollupInsertWithdrawnAsAdminUser() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get statuses
        List<String> ienWithdrawnStatus = IEN_Helper.getWithdrawnStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so = null;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Student Individual Enrollment map should not be empty.');

        //create new ien
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        if(!ienToTest.isEmpty()){
            //get 1 ien to create the similar ien
            reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

            //prepare ien to insert
            datetime dtNow = datetime.now();
            ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
                selectedIen.reduivy__Contact__c,
                so.Id,
                ienWithdrawnStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                null, 
                null, 
                10,
                null,
                selectedIen.reduivy__Individual_Academic_Profile__c,
                true
            ));
        }
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment To Insert Map should not be empty.');

        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            //get study offering before insert
            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //Insertion test - check whether update waitlisted place in Study Offering after ien insert
            REDU_Database_UTIL.doInsert(ienToInsert);

            //get study offering after insert
			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = : so.Id
            ];
            
			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c, soAfter.reduivy__Booked_Places__c, 'Booked Place should not update.');
			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c, soAfter.reduivy__Waitlist_Places__c, 'Booked Place should not update.');

            Test.stopTest();

        }
    }

    /**
     * @description Test as admin that individual enrollments rollup booked and waitlist places to the Study Offering record after update status = Waitlisted
     */
    @IsTest
    static void testRollupUpdateWaitlistedAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get withdrawn statuses
        List<String> ienWaitlistedStatus = IEN_Helper.getWaitlistedStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment To Test Map should not be empty.');

        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            //Update test - ensure booked and waitlist place will be update after ien status updated to ienWaitlistedStatus[0]
            for(Id ienId : ienToTest.keySet()){
                ienToTest.get(ienId).reduivy__Enrollment_Status__c = ienWaitlistedStatus[0];
            }
            
            REDU_Database_UTIL.doUpdate(ienToTest.values());

			reduivy__Study_Offering__c soffCheck = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :so.Id];

			System.Assert.areEqual(0, soffCheck.reduivy__Booked_Places__c, 'Booked Place is not updated');
			System.Assert.areEqual(ienToTest.size(), soffCheck.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated');

            Test.stopTest();

        }
    }

    /**
     * @description Test as admin that individual enrollments rollup booked and waitlist places to the Study Offering record after update status = InProgress
     */
    @IsTest
    static void testRollupUpdateInProgressAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get withdrawn statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment To Test Map should not be empty.');

        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            //Update test - ensure booked and waitlist place will be update after ien status updated to ienInProgressStatus[0]
            for(Id ienId : ienToTest.keySet()){
                ienToTest.get(ienId).reduivy__Enrollment_Status__c = ienInProgressStatus[0];
            }
            
            REDU_Database_UTIL.doUpdate(ienToTest.values());

			reduivy__Study_Offering__c soffCheck = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :so.Id];

			System.Assert.areEqual(ienToTest.size(), soffCheck.reduivy__Booked_Places__c, 'Booked Place is not updated');
			System.Assert.areEqual(0, soffCheck.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated');

            Test.stopTest();

        }
    }

    /**
     * @description Test as admin that individual enrollments rollup booked and waitlist places to the Study Offering record after update status = Withdrawn
     */
    @IsTest
    static void testRollupUpdateWithdrawnAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get withdrawn statuses
        List<String> ienWithdrawnStatus = IEN_Helper.getWithdrawnStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment To Test Map should not be empty.');

        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            //Update test - ensure booked and waitlist place will no update after ien status updated to ienWithdrawnStatus[0]
            for(Id ienId : ienToTest.keySet()){
                ienToTest.get(ienId).reduivy__Enrollment_Status__c = ienWithdrawnStatus[0];
            }
            
            REDU_Database_UTIL.doUpdate(ienToTest.values());

			reduivy__Study_Offering__c soffCheck = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :so.Id];

			System.Assert.areEqual(0, soffCheck.reduivy__Booked_Places__c, 'Booked Place is not updated');
			System.Assert.areEqual(0, soffCheck.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated');

            Test.stopTest();

        }
    }

    /**
     * @description Test as admin that individual enrollments rollup booked and waitlist places to the Study Offering record after delete status = Waitlisted
     */
    @IsTest
    static void testRollupDeletionWaitlistedAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get statuses
        List<String> ienWaitlistedStatus = IEN_Helper.getWaitlistedStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment map should not be empty.');
        
        //get 1 ien to create the similar ien
        reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

        //prepare ien to insert
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        datetime dtNow = datetime.now();
        ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
            selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
            selectedIen.reduivy__Contact__c,
            so.Id,
            ienWaitlistedStatus[0], 
            1, 
            date.today(), 
            date.today(), 
            null, 
            null, 
            10,
            null,
            selectedIen.reduivy__Individual_Academic_Profile__c,
            true
        ));

        REDU_Database_UTIL.doInsert(ienToInsert);
        
        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //ien Deletion Test
			REDU_Database_UTIL.doDelete(ienToInsert);

			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c, soAfter.reduivy__Booked_Places__c, 'Booked Place should not update.');
			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c - 1, soAfter.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated.');

            Test.stopTest();

        }
    }

    /**
     * @description Test as admin that individual enrollments rollup booked and waitlist places to the Study Offering record after delete status = InProgress
     */
    @IsTest
    static void testRollupDeletionInProgressAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment map should not be empty.');
        
        //get 1 ien to create the similar ien
        reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

        //prepare ien to insert
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        datetime dtNow = datetime.now();
        ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
            selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
            selectedIen.reduivy__Contact__c,
            so.Id,
            ienInProgressStatus[0], 
            1, 
            date.today(), 
            date.today(), 
            null, 
            null, 
            10,
            null,
            selectedIen.reduivy__Individual_Academic_Profile__c,
            true
        ));

        REDU_Database_UTIL.doInsert(ienToInsert);
        
        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //ien Deletion Test
			REDU_Database_UTIL.doDelete(ienToInsert);

			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c - 1, soAfter.reduivy__Booked_Places__c, 'Booked Place is not updated.');
			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c, soAfter.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated.');

            Test.stopTest();

        }
    }
    

    /**
     * @description Test as faculty that individual enrollments rollup booked and waitlist places to the Study Offering record after insert ien status = Waitlisted
     */
    @IsTest
    static void testRollupInsertWaitlistedAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //get statuses
        List<String> ienWaitlistedStatus = IEN_Helper.getWaitlistedStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so = null;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Student Individual Enrollment map should not be empty.');

        //create new ien
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        if(!ienToTest.isEmpty()){
            //get 1 ien to create the similar ien
            reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

            //prepare ien to insert
            datetime dtNow = datetime.now();
            ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
                selectedIen.reduivy__Contact__c,
                so.Id,
                ienWaitlistedStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                null, 
                null, 
                10,
                null,
                selectedIen.reduivy__Individual_Academic_Profile__c,
                true
            ));
        }
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment To Insert Map should not be empty.');

        System.runAs(FACULTY_USER) {

            // Perform test
            Test.startTest();

            //get study offering before insert
            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //Insertion test - check whether update waitlisted place in Study Offering after ien insert
            REDU_Database_UTIL.doInsert(ienToInsert);

            //get study offering after insert
			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = : so.Id
            ];
            
			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c + 1, soAfter.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated');

            Test.stopTest();

        }
	}
	
    /**
     * @description Test as faculty that individual enrollments rollup booked and waitlist places to the Study Offering record after insert ien status = InProgress
     */
    @IsTest
    static void testRollupInsertInProgressAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //get statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so = null;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Student Individual Enrollment map should not be empty.');

        //create new ien
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        if(!ienToTest.isEmpty()){
            //get 1 ien to create the similar ien
            reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

            //prepare ien to insert
            datetime dtNow = datetime.now();
            ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
                selectedIen.reduivy__Contact__c,
                so.Id,
                ienInProgressStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                null, 
                null, 
                10,
                null,
                selectedIen.reduivy__Individual_Academic_Profile__c,
                true
            ));
        }
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment To Insert Map should not be empty.');

        System.runAs(FACULTY_USER) {

            // Perform test
            Test.startTest();

            //get study offering before insert
            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //Insertion test - check whether update waitlisted place in Study Offering after ien insert
            REDU_Database_UTIL.doInsert(ienToInsert);

            //get study offering after insert
			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = : so.Id
            ];
            
			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c + 1, soAfter.reduivy__Booked_Places__c, 'Booked Place is not updated');

            Test.stopTest();

        }
	}

    /**
     * @description Test as faculty that individual enrollments rollup booked and waitlist places to the Study Offering record after insert ien status = Withdrawn
     */
    @IsTest
    static void testRollupInsertWithdrawnAsFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //get statuses
        List<String> ienWithdrawnStatus = IEN_Helper.getWithdrawnStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so = null;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Student Individual Enrollment map should not be empty.');

        //create new ien
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        if(!ienToTest.isEmpty()){
            //get 1 ien to create the similar ien
            reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

            //prepare ien to insert
            datetime dtNow = datetime.now();
            ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
                selectedIen.reduivy__Contact__c,
                so.Id,
                ienWithdrawnStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                null, 
                null, 
                10,
                null,
                selectedIen.reduivy__Individual_Academic_Profile__c,
                true
            ));
        }
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment To Insert Map should not be empty.');

        System.runAs(FACULTY_USER) {

            // Perform test
            Test.startTest();

            //get study offering before insert
            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //Insertion test - check whether update waitlisted place in Study Offering after ien insert
            REDU_Database_UTIL.doInsert(ienToInsert);

            //get study offering after insert
			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = : so.Id
            ];
            
			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c, soAfter.reduivy__Booked_Places__c, 'Booked Place should not update.');
			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c, soAfter.reduivy__Waitlist_Places__c, 'Booked Place should not update.');

            Test.stopTest();

        }
    }

    /**
     * @description Test as faculty that individual enrollments rollup booked and waitlist places to the Study Offering record after update status = Waitlisted
     */
    @IsTest
    static void testRollupUpdateWaitlistedAsFacultyUser() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //get withdrawn statuses
        List<String> ienWaitlistedStatus = IEN_Helper.getWaitlistedStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment To Test Map should not be empty.');

        System.runAs(FACULTY_USER) {

            // Perform test
            Test.startTest();

            //Update test - ensure booked and waitlist place will be update after ien status updated to ienWaitlistedStatus[0]
            for(Id ienId : ienToTest.keySet()){
                ienToTest.get(ienId).reduivy__Enrollment_Status__c = ienWaitlistedStatus[0];
            }
            
            REDU_Database_UTIL.doUpdate(ienToTest.values());

			reduivy__Study_Offering__c soffCheck = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :so.Id];

			System.Assert.areEqual(0, soffCheck.reduivy__Booked_Places__c, 'Booked Place is not updated');
			System.Assert.areEqual(ienToTest.size(), soffCheck.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated');

            Test.stopTest();

        }
    }

    /**
     * @description Test as faculty that individual enrollments rollup booked and waitlist places to the Study Offering record after update status = InProgress
     */
    @IsTest
    static void testRollupUpdateInProgressAsFacultyUser() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //get withdrawn statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment To Test Map should not be empty.');

        System.runAs(FACULTY_USER) {

            // Perform test
            Test.startTest();

            //Update test - ensure booked and waitlist place will be update after ien status updated to ienInProgressStatus[0]
            for(Id ienId : ienToTest.keySet()){
                ienToTest.get(ienId).reduivy__Enrollment_Status__c = ienInProgressStatus[0];
            }
            
            REDU_Database_UTIL.doUpdate(ienToTest.values());

			reduivy__Study_Offering__c soffCheck = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :so.Id];

			System.Assert.areEqual(ienToTest.size(), soffCheck.reduivy__Booked_Places__c, 'Booked Place is not updated');
			System.Assert.areEqual(0, soffCheck.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated');

            Test.stopTest();

        }
    }

    /**
     * @description Test as faculty that individual enrollments rollup booked and waitlist places to the Study Offering record after update status = Withdrawn
     */
    @IsTest
    static void testRollupUpdateWithdrawnAsFacultyUser() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //get withdrawn statuses
        List<String> ienWithdrawnStatus = IEN_Helper.getWithdrawnStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment To Test Map should not be empty.');

        System.runAs(FACULTY_USER) {

            // Perform test
            Test.startTest();

            //Update test - ensure booked and waitlist place will no update after ien status updated to ienWithdrawnStatus[0]
            for(Id ienId : ienToTest.keySet()){
                ienToTest.get(ienId).reduivy__Enrollment_Status__c = ienWithdrawnStatus[0];
            }
            
            REDU_Database_UTIL.doUpdate(ienToTest.values());

			reduivy__Study_Offering__c soffCheck = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :so.Id];

			System.Assert.areEqual(0, soffCheck.reduivy__Booked_Places__c, 'Booked Place is not updated');
			System.Assert.areEqual(0, soffCheck.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated');

            Test.stopTest();

        }
    }

    /**
     * @description Test as faculty that individual enrollments rollup booked and waitlist places to the Study Offering record after individual enrollments deleted
     */
    @IsTest
    static void testRollupIenDeletionAsFacultyUser() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment map should not be empty.');

        System.runAs(FACULTY_USER) {

            // Perform test
            Test.startTest();

            try {
			    REDU_Database_UTIL.doDelete(ienToTest.values());
                System.Assert.fail('Faculty should not have delete access.');

            } catch (Exception exp) {
                System.Assert.areEqual('Insufficient Delete access on following object(s) and field(s) - reduivy__Individual_Enrollment__c', exp.getMessage());
            }

            Test.stopTest();

        }
    }



    /**
     * @description Test as student that individual enrollments rollup booked and waitlist places to the Study Offering record after insert ien status = Waitlisted
     */
    @IsTest
    static void testRollupInsertWaitlistedAsStudentUser() {

        //get a student for test
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];


        //get statuses
        List<String> ienWaitlistedStatus = IEN_Helper.getWaitlistedStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so = null;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Student Individual Enrollment map should not be empty.');

        //create new ien
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        if(!ienToTest.isEmpty()){
            //get 1 ien to create the similar ien
            reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

            //prepare ien to insert
            datetime dtNow = datetime.now();
            ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
                selectedIen.reduivy__Contact__c,
                so.Id,
                ienWaitlistedStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                null, 
                null, 
                10,
                null,
                selectedIen.reduivy__Individual_Academic_Profile__c,
                true
            ));
        }
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment To Insert Map should not be empty.');

        System.runAs(studentUser) {

            // Perform test
            Test.startTest();

            //get study offering before insert
            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //Insertion test - check whether update waitlisted place in Study Offering after ien insert
            REDU_Database_UTIL.doInsert(ienToInsert);

            //get study offering after insert
			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = : so.Id
            ];
            
			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c + 1, soAfter.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated');

            Test.stopTest();

        }
	}
	
    /**
     * @description Test as student that individual enrollments rollup booked and waitlist places to the Study Offering record after insert ien status = InProgress
     */
    @IsTest
    static void testRollupInsertInProgressAsStudentUser() {

        //get a student for test
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

        //get statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so = null;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Student Individual Enrollment map should not be empty.');

        //create new ien
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        if(!ienToTest.isEmpty()){
            //get 1 ien to create the similar ien
            reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

            //prepare ien to insert
            datetime dtNow = datetime.now();
            ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
                selectedIen.reduivy__Contact__c,
                so.Id,
                ienInProgressStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                null, 
                null, 
                10,
                null,
                selectedIen.reduivy__Individual_Academic_Profile__c,
                true
            ));
        }
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment To Insert Map should not be empty.');

        System.runAs(studentUser) {

            // Perform test
            Test.startTest();

            //get study offering before insert
            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //Insertion test - check whether update waitlisted place in Study Offering after ien insert
            REDU_Database_UTIL.doInsert(ienToInsert);

            //get study offering after insert
			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = : so.Id
            ];
            
			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c + 1, soAfter.reduivy__Booked_Places__c, 'Booked Place is not updated');

            Test.stopTest();

        }
	}

	
    /**
     * @description Test as student that individual enrollments rollup booked and waitlist places to the Study Offering record after insert ien status = InProgress, but is fully booked
     */
    @IsTest
    static void testRollupInsertInProgressFullyBookedAsStudentUser() {

        //get a student for test
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

        //get statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so = null;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        so.reduivy__Capacity__c = so.reduivy__Booked_Places__c;
        update so;

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Student Individual Enrollment map should not be empty.');

        //create new ien
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        if(!ienToTest.isEmpty()){
            //get 1 ien to create the similar ien
            reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

            //prepare ien to insert
            datetime dtNow = datetime.now();
            ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
                selectedIen.reduivy__Contact__c,
                so.Id,
                ienInProgressStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                null, 
                null, 
                10,
                null,
                selectedIen.reduivy__Individual_Academic_Profile__c,
                true
            ));
        }
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment To Insert Map should not be empty.');

        System.runAs(studentUser) {

            // Perform test
            Test.startTest();

            //get study offering before insert
            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, Name
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //Insertion test - check whether update waitlisted place in Study Offering after ien insert
            try{
                REDU_Database_UTIL.doInsert(ienToInsert);
                System.Assert.fail('Should be failed due to Study Session Capacity!');
            } catch(Exception exp) {
                String expectedError = String.format(
                    Label.Error_No_Available_Places_Remaining_In_Study_Offering,
                    new List<String> { SOF_Helper.getObjectLabel(), soBefore.Name}
                );

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Wrong exception message! Excepted: ' + expectedError + ', Actual: ' + exp.getMessage());
            }

            //get study offering after insert
			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = : so.Id
            ];
            
			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c, soAfter.reduivy__Booked_Places__c, 'Booked Place is not updated');

            Test.stopTest();

        }
	}

    /**
     * @description Test as student that individual enrollments rollup booked and waitlist places to the Study Offering record after insert ien status = Withdrawn
     */
    @IsTest
    static void testRollupInsertWithdrawnAsStudentUser() {

        //get a student for test
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

        //get statuses
        List<String> ienWithdrawnStatus = IEN_Helper.getWithdrawnStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so = null;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Study_Offering__c = :so.Id
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Student Individual Enrollment map should not be empty.');

        //create new ien
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        if(!ienToTest.isEmpty()){
            //get 1 ien to create the similar ien
            reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

            //prepare ien to insert
            datetime dtNow = datetime.now();
            ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
                selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
                selectedIen.reduivy__Contact__c,
                so.Id,
                ienWithdrawnStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                null, 
                null, 
                10,
                null,
                selectedIen.reduivy__Individual_Academic_Profile__c,
                true
            ));
        }
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment To Insert Map should not be empty.');

        System.runAs(studentUser) {

            // Perform test
            Test.startTest();

            //get study offering before insert
            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //Insertion test - check whether update waitlisted place in Study Offering after ien insert
            REDU_Database_UTIL.doInsert(ienToInsert);

            //get study offering after insert
			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = : so.Id
            ];
            
			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c, soAfter.reduivy__Booked_Places__c, 'Booked Place should not update.');
			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c, soAfter.reduivy__Waitlist_Places__c, 'Booked Place should not update.');

            Test.stopTest();

        }
    }

    /**
     * @description Test as student that individual enrollments rollup booked and waitlist places to the Study Offering record after update status = Waitlisted
     */
    @IsTest
    static void testRollupUpdateWaitlistedAsStudentUser() {

        //get withdrawn statuses
        List<String> ienWaitlistedStatus = IEN_Helper.getWaitlistedStatuses();
        
        //get ien
        reduivy__Individual_Enrollment__c ienToTest = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Study_Offering__c, reduivy__Contact__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Enrollment_Status__c NOT IN :ienWaitlistedStatus
            WITH SYSTEM_MODE
            LIMIT 1
        ];

		System.Assert.areNotEqual(null, ienToTest, 'Individual Enrollment should not be empty.');

        //get a student for test
		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId = :ienToTest.reduivy__Contact__c
        ];

        System.runAs(studentUser) {

            // Perform test
            Test.startTest();

            reduivy__Study_Offering__c soBefore = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :ienToTest.reduivy__Study_Offering__c];

            //Update test - ensure booked and waitlist place will be update after ien status updated to ienWaitlistedStatus[0]
            ienToTest.reduivy__Enrollment_Status__c = ienWaitlistedStatus[0];
            List<reduivy__Individual_Enrollment__c> listToUpdate = new List<reduivy__Individual_Enrollment__c>();
            listToUpdate.add(ienToTest);
            REDU_Database_UTIL.doUpdate(listToUpdate);

			reduivy__Study_Offering__c soAfter = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :ienToTest.reduivy__Study_Offering__c];

			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c + 1, soAfter.reduivy__Waitlist_Places__c, 'Waitlist Place is not updated');

            Test.stopTest();

        }
    }

    /**
     * @description Test as student that individual enrollments rollup booked and waitlist places to the Study Offering record after update status = InProgress
     */
    @IsTest
    static void testRollupUpdateInProgressAsStudentUser() {
        
        //get withdrawn statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        List<String> ienWithdrawnStatus = IEN_Helper.getWithdrawnStatuses();
        
        //get ien
        reduivy__Individual_Enrollment__c ienToTest = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Study_Offering__c, reduivy__Contact__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        //update ien to non 'Withdrawn' to test as test data dont have any ien not in InProgress and Completed status
        ienToTest.reduivy__Enrollment_Status__c = ienWithdrawnStatus[0];
        List<reduivy__Individual_Enrollment__c> toUpdate = new List<reduivy__Individual_Enrollment__c>();
        toUpdate.add(ienToTest);
        REDU_Database_UTIL.doUpdate(toUpdate);

        //get a student for test
		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId = :ienToTest.reduivy__Contact__c
            LIMIT 1
        ];

        System.runAs(studentUser) {

            // Perform test
            Test.startTest();

            reduivy__Study_Offering__c soBefore = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :ienToTest.reduivy__Study_Offering__c];

            //Update test - ensure booked and waitlist place will be update after ien status updated to ienInProgressStatus[0]
            ienToTest.reduivy__Enrollment_Status__c = ienInProgressStatus[0];
            List<reduivy__Individual_Enrollment__c> listToUpdate = new List<reduivy__Individual_Enrollment__c>();
            listToUpdate.add(ienToTest);
            REDU_Database_UTIL.doUpdate(listToUpdate);

			reduivy__Study_Offering__c soAfter = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :ienToTest.reduivy__Study_Offering__c];

            System.Assert.areEqual(soBefore.reduivy__Booked_Places__c + 1, soAfter.reduivy__Booked_Places__c, 'Booked Place is not updated.');

            Test.stopTest();

        }
    }

    /**
     * @description Test as student that individual enrollments rollup booked and waitlist places to the Study Offering record after update status = InProgress, but is fully booked
     */
    @IsTest
    static void testRollupUpdateInProgressFullyBookedAsStudentUser() {
        
        //get withdrawn statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        List<String> ienWithdrawnStatus = IEN_Helper.getWithdrawnStatuses();
        
        //get ien
        reduivy__Individual_Enrollment__c ienToTest = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Study_Offering__c, reduivy__Contact__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        //update ien to non 'Withdrawn' to test as test data dont have any ien not in InProgress and Completed status
        ienToTest.reduivy__Enrollment_Status__c = ienWithdrawnStatus[0];
        List<reduivy__Individual_Enrollment__c> toUpdate = new List<reduivy__Individual_Enrollment__c>();
        toUpdate.add(ienToTest);
        REDU_Database_UTIL.doUpdate(toUpdate);

        //get a student for test
		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId = :ienToTest.reduivy__Contact__c
            LIMIT 1
        ];

        reduivy__Study_Offering__c soBefore = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c, reduivy__Capacity__c, Name
                FROM reduivy__Study_Offering__c 
                WHERE Id = :ienToTest.reduivy__Study_Offering__c];

        //update the capacity to 1
        soBefore.reduivy__Capacity__c = 1;
        update soBefore;

        System.runAs(studentUser) {

            // Perform test
            Test.startTest();


            //Update test - ensure booked and waitlist place will be update after ien status updated to ienInProgressStatus[0]
            ienToTest.reduivy__Enrollment_Status__c = ienInProgressStatus[0];
            List<reduivy__Individual_Enrollment__c> listToUpdate = new List<reduivy__Individual_Enrollment__c>();
            listToUpdate.add(ienToTest);

            try{
                REDU_Database_UTIL.doUpdate(listToUpdate);
                System.Assert.fail('Should be failed due to Study Session Capacity!');
            } catch(Exception exp) {
                String expectedError = String.format(
                    Label.Error_No_Available_Places_Remaining_In_Study_Offering,
                    new List<String> { SOF_Helper.getObjectLabel(), soBefore.Name}
                );

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Wrong exception message! Excepted: ' + expectedError + ', Actual: ' + exp.getMessage());
            }

			reduivy__Study_Offering__c soAfter = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c, reduivy__Capacity__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :ienToTest.reduivy__Study_Offering__c];

            System.Assert.areEqual(soBefore.reduivy__Booked_Places__c, soAfter.reduivy__Booked_Places__c, 'Booked Place is not updated.');

            Test.stopTest();

        }
    }

    /**
     * @description Test as student that individual enrollments rollup booked and waitlist places to the Study Offering record after update status = Withdrawn
     */
    @IsTest
    static void testRollupUpdateWithdrawnAsStudentUser() {

        //get withdrawn statuses
        List<String> ienWithdrawnStatus = IEN_Helper.getWithdrawnStatuses();
        Set<String> ienBookedStatusSet = new Set<String>();
        ienBookedStatusSet.addAll(IEN_Helper.getInProgressStatuses());
        ienBookedStatusSet.addAll(IEN_Helper.getCompletedStatuses());

        //get ien for that study offering
        reduivy__Individual_Enrollment__c ienToTest = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Study_Offering__c, reduivy__Contact__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            AND reduivy__Enrollment_Status__c IN :ienBookedStatusSet
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        //get a student for test
		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId = :ienToTest.reduivy__Contact__c
        ];

        System.runAs(studentUser) {

            // Perform test
            Test.startTest();

            reduivy__Study_Offering__c soBefore = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :ienToTest.reduivy__Study_Offering__c];

            //Update test - ensure booked and waitlist place will be update after ien status updated to ienWithdrawnStatus[0]
            ienToTest.reduivy__Enrollment_Status__c = ienWithdrawnStatus[0];
            List<reduivy__Individual_Enrollment__c> listToUpdate = new List<reduivy__Individual_Enrollment__c>();
            listToUpdate.add(ienToTest);
            REDU_Database_UTIL.doUpdate(listToUpdate);

			reduivy__Study_Offering__c soAfter = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
					FROM reduivy__Study_Offering__c 
					WHERE Id = :ienToTest.reduivy__Study_Offering__c];

			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c - 1, soAfter.reduivy__Booked_Places__c, 'Booked Place is not updated.');

            Test.stopTest();

        }
    }

    /**
     * @description Test as student that individual enrollments rollup booked and waitlist places to the Study Offering record after individual enrollments deleted
     */
    @IsTest
    static void testRollupIenDeletionAsStudentUser() {
        //get a student for test
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment map should not be empty.');

        System.runAs(studentUser) {

            // Perform test
            Test.startTest();

            try {
			    REDU_Database_UTIL.doDelete(ienToTest.values());
                System.Assert.fail('Student should not have delete access.');

            } catch (Exception exp) {
                System.Assert.areEqual('Insufficient Delete access on following object(s) and field(s) - reduivy__Individual_Enrollment__c', exp.getMessage());
            }

            Test.stopTest();

        }
    }


    /**
     * @description Test as student that individual enrollments rollup booked and waitlist places to the Study Offering record and over the capacity
     */
    @IsTest
    static void testIenStudyOfferingRollupNoCapacity() {
        Boolean hasError = false;

        //get withdrawn statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();

		//get ien
        reduivy__Individual_Enrollment__c ienToTest = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Study_Offering__c, reduivy__Contact__c, reduivy__Sample_Record_Code__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            WITH SYSTEM_MODE
            LIMIT 1
        ];

		reduivy__Study_Offering__c soffCheck = new reduivy__Study_Offering__c();
		soffCheck.Id = ienToTest.reduivy__Study_Offering__c;
		soffCheck.reduivy__Capacity__c = 0;

        List<reduivy__Study_Offering__c> soToUpdate = new List<reduivy__Study_Offering__c>();
        soToUpdate.add(soffCheck);
		REDU_Database_UTIL.doUpdate(soToUpdate);

        User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId = :ienToTest.reduivy__Contact__c
            LIMIT 1
        ];
        
        //prepare ien to insert
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        datetime dtNow = datetime.now();
        ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
            ienToTest.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
            ienToTest.reduivy__Contact__c,
            ienToTest.reduivy__Study_Offering__c,
            ienInProgressStatus[0], 
            1, 
            date.today(), 
            date.today(), 
            null, 
            null, 
            10,
            null,
            ienToTest.reduivy__Individual_Academic_Profile__c,
            true
        ));
        System.Assert.areNotEqual(0, ienToInsert.size(), 'Individual Enrollment to insert should not be empty.');

		System.runAs(studentUser) {
			try{
				// Perform test
				Test.startTest();
				
                reduivy__Study_Offering__c soBefore = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
						FROM reduivy__Study_Offering__c 
						WHERE Id = :ienToTest.reduivy__Study_Offering__c];

                REDU_Database_UTIL.doInsert(ienToInsert);

				reduivy__Study_Offering__c soAfter = [SELECT Id, reduivy__Academic_Term__c, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Sample_Record_Code__c
						FROM reduivy__Study_Offering__c 
						WHERE Id = :ienToTest.reduivy__Study_Offering__c];

				System.Assert.areEqual(soBefore.reduivy__Booked_Places__c, soAfter.reduivy__Booked_Places__c, 'Booked Place should not update.');

				Test.stopTest();
			} catch (Exception exp) {

				REDU_Logging_UTIL.debug('testForSetupUser', exp.getMessage());
				hasError = true;
			}

		}
		
		System.Assert.areEqual(true, hasError, 'Enrollment should be failed with error no available places remaining in study offering');
	}


    /**
     * @description Test as admin that individual enrollments rollup waitlist places to the Study Offering after undelete
     */
    @IsTest
    static void testRollupUndeleteWaitlistedAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get statuses
        List<String> ienWaitlistedStatus = IEN_Helper.getWaitlistedStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment map should not be empty.');
        
        //get 1 ien to create the similar ien
        reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

        //prepare ien to insert
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        datetime dtNow = datetime.now();
        ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
            selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
            selectedIen.reduivy__Contact__c,
            so.Id,
            ienWaitlistedStatus[0], 
            1, 
            date.today(), 
            date.today(), 
            null, 
            null, 
            10,
            null,
            selectedIen.reduivy__Individual_Academic_Profile__c,
            true
        ));

        REDU_Database_UTIL.doInsert(ienToInsert);
        
        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //ien Deletion Test
			REDU_Database_UTIL.doDelete(ienToInsert);

			undelete ienToInsert;

			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c, soAfter.reduivy__Booked_Places__c, 'Booked Place should same as previous.');
			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c, soAfter.reduivy__Waitlist_Places__c, 'Waitlist Place should same as previous.');

            Test.stopTest();

        }
    }

    /**
     * @description Test as admin that individual enrollments rollup booked and waitlist places to the Study Offering record after delete status = InProgress
     */
    @IsTest
    static void testRollupUndeleteInProgressAsAdminUser() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get statuses
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        
        //get 1 study offering for test
        reduivy__Study_Offering__c so;
        for (reduivy__Study_Offering__c sof : [
            SELECT  Id, Name, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c, reduivy__Capacity__c, reduivy__Unlimited_Places__c,
                (select Id
                from reduivy__Individual_Enrollments__r
                where RecordTypeId = :IEN_Helper.getStudentRecordTypeId())
            FROM reduivy__Study_Offering__c
            WITH SYSTEM_MODE
        ]) {
            if(sof.reduivy__Individual_Enrollments__r != null && !sof.reduivy__Individual_Enrollments__r.isEmpty()){
                so = sof;
                break;
            }
        }
		System.Assert.areNotEqual(null, so, 'Study Offering should not be null.');

        //get ien for that study offering
        Map<Id, reduivy__Individual_Enrollment__c> ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>();
        ienToTest = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
            WITH SYSTEM_MODE
        ]);
		System.Assert.areNotEqual(0, ienToTest.size(), 'Individual Enrollment map should not be empty.');
        
        //get 1 ien to create the similar ien
        reduivy__Individual_Enrollment__c selectedIen = ienToTest.values().get(0);

        //prepare ien to insert
        List<reduivy__Individual_Enrollment__c> ienToInsert = new List<reduivy__Individual_Enrollment__c>();
        datetime dtNow = datetime.now();
        ienToInsert.add(REDU_TestData_UTIL.newStudentIndividualEnrollment(
            selectedIen.reduivy__Sample_Record_Code__c + '_testData: ' + dtNow.format('MM/dd/yyyy HH:mm:ss'),
            selectedIen.reduivy__Contact__c,
            so.Id,
            ienInProgressStatus[0], 
            1, 
            date.today(), 
            date.today(), 
            null, 
            null, 
            10,
            null,
            selectedIen.reduivy__Individual_Academic_Profile__c,
            true
        ));

        REDU_Database_UTIL.doInsert(ienToInsert);
        
        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            reduivy__Study_Offering__c soBefore = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

            //ien Deletion Test
			REDU_Database_UTIL.doDelete(ienToInsert);

            undelete ienToInsert;

			reduivy__Study_Offering__c soAfter = [
                SELECT Id, reduivy__Booked_Places__c, reduivy__Waitlist_Places__c
                FROM reduivy__Study_Offering__c 
                WHERE Id = :so.Id
            ];

			System.Assert.areEqual(soBefore.reduivy__Booked_Places__c, soAfter.reduivy__Booked_Places__c, 'Booked Place should same as previous.');
			System.Assert.areEqual(soBefore.reduivy__Waitlist_Places__c, soAfter.reduivy__Waitlist_Places__c, 'Waitlist Place should same as previous.');

            Test.stopTest();

        }
    }

}