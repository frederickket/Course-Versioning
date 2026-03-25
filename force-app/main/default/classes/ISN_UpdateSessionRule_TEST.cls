/**
 * @author      WDCi (XW)
 * @date        Sept 2024
 * @group       Test
 * @description Test class for ISN_UpdateSessionRule_EXE
 * @changehistory
 * ISS-002070 04-09-2024 XW - create new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class ISN_UpdateSessionRule_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
	static User ADMIN_USER = testFactory.getReduAdminUser();
	static User FACULTY_USER = testFactory.getReduFacultyUser();
    static List<reduivy__Study_Session__c> targetSseLectureAndTutorial;
    static reduivy__Individual_Enrollment__c TARGET_IEN;
    static String SOF_KEY = 'BUS101_CYT1_SYDNEY';
    static String IEN_KEY = 'amydoe@redu.example_BUS101_CYT1_SYDNEY';
    static String SSE_LECTURE_KEY = 'Lecture_BUS101_CYT1_SYDNEY';
    static String SSE_TUTORIAL_KEY = 'Tutorial_BUS101_CYT1_SYDNEY';
    static String ISN_INPROGRESS_STATUS = ISN_Helper.getInProgressStatuses().get(0);

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        // Create settings
        testFactory.setupDefaultSettings();

        // Create test data
		System.runAs(ADMIN_USER) {
            Test.startTest();
        	
            //please adjust the data according to your needs
            testFactory.FULLDATA = true;
            testFactory.initMasterData(null);
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initOfferingData(SST_Helper.getApiName());
            testFactory.initStudentData(IEN_Helper.getApiName(), true);

            reduivy__Study_Offering__c sof = testFactory.studyOfferings.get(SOF_KEY);
            sof.reduivy__Study_Session_Enrollment_Rule__c = 'Lecture=1;Tutorial=2';
            update sof;

            User studentUser = testFactory.getStudentUser();
            reduivy__Individual_Enrollment__c studentIen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                IEN_KEY, 
                studentUser.ContactId, 
                sof.Id, 
                'Enrolled', 
                1, 
                null,
                null,
                null,
                null, 
                null, 
                null,
                testFactory.individualAcademicProfiles.get('sandydoe@redu.example').Id,
                true
            );
            insert studentIen;
            Test.stopTest();
        
            
		}

    }
	
    /**
     * @description Test as admin for Insert Isn
     */
    @IsTest
    static void testForInsertIsnAsAdmin() {
        

        reduivy__Individual_Enrollment__c ien = getTargetIen();
        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];
        reduivy__Study_Session__c sseTutorial = getTargetSseList()[1];


        reduivy__Individual_Session_Enrollment__c firstIsnToInsert = getIsnToInsert(ien.Id, sseLecture.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c secondIsnToInsert = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c thirdIsnToInsert = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c forthIsnToInsert = getIsnToInsert(ien.Id, sseLecture.Id, ISN_INPROGRESS_STATUS);

        Test.startTest();
        
		System.runAs(ADMIN_USER){

            List<reduivy__Individual_Session_Enrollment__c> isn1stAnd2ndList = new List<reduivy__Individual_Session_Enrollment__c>{firstIsnToInsert, secondIsnToInsert};
            insert isn1stAnd2ndList;
            reduivy__Individual_Enrollment__c firstResultIen = getTargetIen();
            System.Assert.areEqual('Lecture=1;Tutorial=1', firstResultIen.reduivy__Study_Session_Enrollment_Rule_Result__c, 'Wrong Rule Result');
            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT, firstResultIen.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');

            insert thirdIsnToInsert;
            reduivy__Individual_Enrollment__c thirdResultIen = getTargetIen();
            System.Assert.areEqual('Lecture=1;Tutorial=2', thirdResultIen.reduivy__Study_Session_Enrollment_Rule_Result__c, 'Wrong Rule Result');
            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_SUFFICIENT, thirdResultIen.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be sufficient');

            insert forthIsnToInsert;
            reduivy__Individual_Enrollment__c forthResultIen = getTargetIen();
            System.Assert.areEqual('Lecture=2;Tutorial=2', forthResultIen.reduivy__Study_Session_Enrollment_Rule_Result__c, 'Wrong Rule Result');
            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER, forthResultIen.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be over');

		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for Update valid Isn, Insufficient to Sufficient
     */
    @IsTest
    static void testForUpdateIsnAsAdmin_ItoS() {

        reduivy__Individual_Enrollment__c ien = getTargetIen();
        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];

        reduivy__Individual_Session_Enrollment__c isnToUpdate = getIsnToInsert(ien.Id,sseLecture.Id,ISN_Helper.getEnrollmentRequestedStatuses()[0]);
        insert isnToUpdate;

        reduivy__Individual_Enrollment__c ienBeforeUpdate = getTargetIen();

        System.Assert.areEqual(null, ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be null');
        System.Assert.isTrue(String.isBlank(ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c));

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            isnToUpdate.reduivy__Enrollment_Status__c = ISN_Helper.getCompletedStatuses()[0];

            update isnToUpdate;
              
            reduivy__Individual_Enrollment__c ienAfterUpdate = getTargetIen();


            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT, ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');
            System.Assert.areEqual('Lecture=1', ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c, 'Wrong Rule Result');

            isnToUpdate.reduivy__Enrollment_Status__c = ISN_Helper.getDroppedStatuses()[0];

            update isnToUpdate;

            ienAfterUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT, ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');
            System.Assert.isTrue(String.isBlank(ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c));
    
		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for Update valid Isn, Insufficient to Over
     */
    @IsTest
    static void testForUpdateIsnAsAdmin_ItoO() {

        reduivy__Individual_Enrollment__c ien = getTargetIen();
        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];
        reduivy__Study_Session__c sseTutorial = getTargetSseList()[1];
        
        Test.startTest();
        System.runAs(ADMIN_USER){

            reduivy__Individual_Session_Enrollment__c isnToUpdateLec1 = getIsnToInsert(ien.Id,sseLecture.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateLec2 = getIsnToInsert(ien.Id,sseLecture.Id,ISN_Helper.getEnrollmentRequestedStatuses()[0]);
            reduivy__Individual_Session_Enrollment__c isnToUpdateTut1 = getIsnToInsert(ien.Id,sseTutorial.Id,ISN_Helper.getEnrollmentRequestedStatuses()[0]);
            reduivy__Individual_Session_Enrollment__c isnToUpdateTut2 = getIsnToInsert(ien.Id,sseTutorial.Id,ISN_Helper.getEnrollmentRequestedStatuses()[0]);
            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>{
                isnToUpdateLec1, isnToUpdateLec2, isnToUpdateTut1, isnToUpdateTut2
            };
            insert isnList;
            
            reduivy__Individual_Enrollment__c ienBeforeUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT, ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');
            System.Assert.areEqual('Lecture=1', ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c, 'Wrong Rule Result');
            
            for(reduivy__Individual_Session_Enrollment__c isn : isnList) {
                isn.reduivy__Enrollment_Status__c = ISN_Helper.getCompletedStatuses()[0];
            }

            update isnList;

            reduivy__Individual_Enrollment__c ienAfterUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER, ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be over');
            System.Assert.isTrue(new List<String>{'Lecture=2;Tutorial=2', 'Lecture=2;Tutorial=2'}.contains(ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c), 'Wrong Rule Result, Expected: Lecture=2;Tutorial=2, Actual: ' + ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c);
    
		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for Update valid Isn, Sufficient to Over
     */
    @IsTest
    static void testForUpdateIsnAsAdmin_StoO() {

        reduivy__Individual_Enrollment__c ien = getTargetIen();
        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];
        reduivy__Study_Session__c sseTutorial = getTargetSseList()[1];
        
        Test.startTest();
        System.runAs(ADMIN_USER){

            reduivy__Individual_Session_Enrollment__c isnToUpdateLec1 = getIsnToInsert(ien.Id,sseLecture.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateLec2 = getIsnToInsert(ien.Id,sseLecture.Id,ISN_Helper.getEnrollmentRequestedStatuses()[0]);
            reduivy__Individual_Session_Enrollment__c isnToUpdateTut1 = getIsnToInsert(ien.Id,sseTutorial.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateTut2 = getIsnToInsert(ien.Id,sseTutorial.Id,ISN_INPROGRESS_STATUS);
            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>{
                isnToUpdateLec1, isnToUpdateLec2, isnToUpdateTut1, isnToUpdateTut2
            };
            insert isnList;
            
            reduivy__Individual_Enrollment__c ienBeforeUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_SUFFICIENT, ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');
            System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=2', 'Tutorial=2;Lecture=1'}.contains(ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=1;Tutorial=2, Actual: ' + ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c);
            
            isnToUpdateLec2.reduivy__Enrollment_Status__c = ISN_Helper.getCompletedStatuses()[0];
            
            update isnList;

            reduivy__Individual_Enrollment__c ienAfterUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER, ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be over');
            System.Assert.isTrue(new List<String>{'Lecture=2;Tutorial=2', 'Tutorial=2;Lecture=2'}.contains(ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c), 'Wrong Rule Result, Expected: Lecture=2;Tutorial=2, Actual: ' + ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c);
    
		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for Update valid Isn, Sufficient to Insufficient
     */
    @IsTest
    static void testForUpdateIsnAsAdmin_StoI() {

        reduivy__Individual_Enrollment__c ien = getTargetIen();
        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];
        reduivy__Study_Session__c sseTutorial = getTargetSseList()[1];
        
        Test.startTest();
        System.runAs(ADMIN_USER){

            reduivy__Individual_Session_Enrollment__c isnToUpdateLec1 = getIsnToInsert(ien.Id,sseLecture.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateLec2 = getIsnToInsert(ien.Id,sseLecture.Id,ISN_Helper.getEnrollmentRequestedStatuses()[0]);
            reduivy__Individual_Session_Enrollment__c isnToUpdateTut1 = getIsnToInsert(ien.Id,sseTutorial.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateTut2 = getIsnToInsert(ien.Id,sseTutorial.Id,ISN_INPROGRESS_STATUS);
            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>{
                isnToUpdateLec1, isnToUpdateLec2, isnToUpdateTut1, isnToUpdateTut2
            };
            insert isnList;
            
            reduivy__Individual_Enrollment__c ienBeforeUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_SUFFICIENT, ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be sufficient');
            System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=2', 'Tutorial=2;Lecture=1'}.contains(ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=1;Tutorial=2, Actual: ' + ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c);
            
            isnToUpdateLec1.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
            
            update isnList;

            reduivy__Individual_Enrollment__c ienAfterUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT, ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');
            System.Assert.areEqual('Tutorial=2', ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c, 'Wrong Rule Result');
    
		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for Update valid Isn, Over to Sufficient
     */
    @IsTest
    static void testForUpdateIsnAsAdmin_OtoS() {

        reduivy__Individual_Enrollment__c ien = getTargetIen();
        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];
        reduivy__Study_Session__c sseTutorial = getTargetSseList()[1];
        
        Test.startTest();
        System.runAs(ADMIN_USER){

            reduivy__Individual_Session_Enrollment__c isnToUpdateLec1 = getIsnToInsert(ien.Id,sseLecture.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateLec2 = getIsnToInsert(ien.Id,sseLecture.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateTut1 = getIsnToInsert(ien.Id,sseTutorial.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateTut2 = getIsnToInsert(ien.Id,sseTutorial.Id,ISN_INPROGRESS_STATUS);
            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>{
                isnToUpdateLec1, isnToUpdateLec2, isnToUpdateTut1, isnToUpdateTut2
            };
            insert isnList;
            
            reduivy__Individual_Enrollment__c ienBeforeUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER, ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be over');
            System.Assert.isTrue(new List<String>{'Lecture=2;Tutorial=2', 'Tutorial=2;Lecture=2'}.contains(ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=2;Tutorial=2, Actual: ' + ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c);
            
            isnToUpdateLec1.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
            
            update isnList;

            reduivy__Individual_Enrollment__c ienAfterUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_SUFFICIENT, ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be sufficient');
            System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=2', 'Tutorial=2;Lecture=1'}.contains(ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=1;Tutorial=2, Actual: ' + ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c);
            
		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for Update valid Isn, Over to Insufficient
     */
    @IsTest
    static void testForUpdateIsnAsAdmin_OtoI() {

        reduivy__Individual_Enrollment__c ien = getTargetIen();
        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];
        reduivy__Study_Session__c sseTutorial = getTargetSseList()[1];
        
        Test.startTest();
        System.runAs(ADMIN_USER){

            reduivy__Individual_Session_Enrollment__c isnToUpdateLec1 = getIsnToInsert(ien.Id,sseLecture.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateLec2 = getIsnToInsert(ien.Id,sseLecture.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateTut1 = getIsnToInsert(ien.Id,sseTutorial.Id,ISN_INPROGRESS_STATUS);
            reduivy__Individual_Session_Enrollment__c isnToUpdateTut2 = getIsnToInsert(ien.Id,sseTutorial.Id,ISN_INPROGRESS_STATUS);
            List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>{
                isnToUpdateLec1, isnToUpdateLec2, isnToUpdateTut1, isnToUpdateTut2
            };
            insert isnList;
            
            reduivy__Individual_Enrollment__c ienBeforeUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER, ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be over');
            System.Assert.isTrue(new List<String>{'Lecture=2;Tutorial=2', 'Tutorial=2;Lecture=2'}.contains(ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=2;Tutorial=2, Actual: ' + ienBeforeUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c);
            
            isnToUpdateLec1.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
            isnToUpdateTut1.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
            
            update isnList;

            reduivy__Individual_Enrollment__c ienAfterUpdate = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT, ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');
            System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=1', 'Tutorial=1;Lecture=1'}.contains(ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c), 
            'Wrong Rule Result, Expected: Lecture=1;Tutorial=1, Actual: ' + ienAfterUpdate.reduivy__Study_Session_Enrollment_Rule_Result__c);
        
		}

        Test.stopTest();
    }


    /**
     * @description Test as admin for Delete and undelete valid Isn, Over > Sufficient > Over
     */
    @IsTest
    static void testForDeleteAndUndeleteIsnAsAdmin_OtoStoO() {
        

        reduivy__Individual_Enrollment__c ien = getTargetIen();


        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];
        reduivy__Study_Session__c sseTutorial = getTargetSseList()[1];

        reduivy__Individual_Session_Enrollment__c isnLecture1 = getIsnToInsert(ien.Id, sseLecture.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c isnLecture2 = getIsnToInsert(ien.Id, sseLecture.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c isnTutorial1 = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c isnTutorial2 = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_INPROGRESS_STATUS);
        List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>{
            isnLecture1, isnLecture2, isnTutorial1, isnTutorial2
        };
        
        insert isnList;
        reduivy__Individual_Enrollment__c ienBeforeDelete = getTargetIen();
        

        System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER, ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be over');
        System.Assert.isTrue(new List<String>{'Lecture=2;Tutorial=2', 'Tutorial=2;Lecture=2'}.contains(ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Result__c), 
        'Wrong Rule Result, Expected: Lecture=2;Tutorial=2, Actual: ' + ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Result__c);
        
        Test.startTest();
        
		System.runAs(ADMIN_USER){

            delete isnLecture1;

            reduivy__Individual_Enrollment__c ienAfterDeleted = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_SUFFICIENT, ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be sufficient');
            System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=2', 'Tutorial=2;Lecture=1'}.contains(ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=1;Tutorial=2, Actual: ' + ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Result__c);
            
            undelete isnLecture1;

            reduivy__Individual_Enrollment__c ienAfterUndeleted = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER, ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be over');
            System.Assert.isTrue(new List<String>{'Lecture=2;Tutorial=2', 'Tutorial=2;Lecture=2'}.contains(ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=2;Tutorial=2, Actual: ' + ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Result__c);
		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for Delete and undelete valid Isn, Sufficient > Insufficient > Sufficient
     */
    @IsTest
    static void testForDeleteAndUndeleteIsnAsAdmin_StoItoS() {
        

        reduivy__Individual_Enrollment__c ien = getTargetIen();


        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];
        reduivy__Study_Session__c sseTutorial = getTargetSseList()[1];

        reduivy__Individual_Session_Enrollment__c isnLecture1 = getIsnToInsert(ien.Id, sseLecture.Id, ISN_Helper.getEnrollmentRequestedStatuses()[0]);
        reduivy__Individual_Session_Enrollment__c isnLecture2 = getIsnToInsert(ien.Id, sseLecture.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c isnTutorial1 = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c isnTutorial2 = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_INPROGRESS_STATUS);
        List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>{
            isnLecture1, isnLecture2, isnTutorial1, isnTutorial2
        };
        
        insert isnList;
        reduivy__Individual_Enrollment__c ienBeforeDelete = getTargetIen();
        

        System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_SUFFICIENT, ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be sufficient');
        System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=2', 'Tutorial=2;Lecture=1'}.contains(ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Result__c), 
            'Wrong Rule Result, Expected: Lecture=1;Tutorial=2, Actual: ' + ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Result__c);
        
        Test.startTest();
        
		System.runAs(ADMIN_USER){

            delete isnTutorial1;

            reduivy__Individual_Enrollment__c ienAfterDeleted = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT, ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');
            System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=1', 'Tutorial=1;Lecture=1'}.contains(ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=1;Tutorial=1, Actual: ' + ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Result__c);
            
            undelete isnTutorial1;

            reduivy__Individual_Enrollment__c ienAfterUndeleted = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_SUFFICIENT, ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be sufficient');
            System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=2', 'Tutorial=2;Lecture=1'}.contains(ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=1;Tutorial=2, Actual: ' + ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Result__c);
		}

        Test.stopTest();
    }

    /**
     * @description Test as admin for Delete and undelete valid Isn, Insufficient > Insufficient > Insufficient
     */
    @IsTest
    static void testForDeleteAndUndeleteIsnAsAdmin_ItoItoI() {
        

        reduivy__Individual_Enrollment__c ien = getTargetIen();


        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];
        reduivy__Study_Session__c sseTutorial = getTargetSseList()[1];

        reduivy__Individual_Session_Enrollment__c isnLecture1 = getIsnToInsert(ien.Id, sseLecture.Id, ISN_Helper.getEnrollmentRequestedStatuses()[0]);
        reduivy__Individual_Session_Enrollment__c isnLecture2 = getIsnToInsert(ien.Id, sseLecture.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c isnTutorial1 = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_Helper.getEnrollmentRequestedStatuses()[0]);
        reduivy__Individual_Session_Enrollment__c isnTutorial2 = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_INPROGRESS_STATUS);
        List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>{
            isnLecture1, isnLecture2, isnTutorial1, isnTutorial2
        };
        
        insert isnList;
        reduivy__Individual_Enrollment__c ienBeforeDelete = getTargetIen();
        

        System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT, ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');
        System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=1', 'Tutorial=1;Lecture=1'}.contains(ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Result__c), 
            'Wrong Rule Result, Expected: Lecture=1;Tutorial=1, Actual: ' + ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Result__c);
        
        Test.startTest();
        
		System.runAs(ADMIN_USER){

            delete isnTutorial2;

            reduivy__Individual_Enrollment__c ienAfterDeleted = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT, ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');
            System.Assert.areEqual('Lecture=1', ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Result__c, 'Wrong Rule Result');
            
            undelete isnTutorial2;

            reduivy__Individual_Enrollment__c ienAfterUndeleted = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_INSUFFICIENT, ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be insufficient');
            System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=1', 'Tutorial=1;Lecture=1'}.contains(ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=1;Tutorial=1, Actual: ' + ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Result__c);
		}

        Test.stopTest();
    }


    /**
     * @description Test as admin for Delete and undelete valid Isn, Over > Over > Over
     */
    @IsTest
    static void testForDeleteAndUndeleteIsnAsAdmin_OtoOtoO() {
        

        reduivy__Individual_Enrollment__c ien = getTargetIen();


        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];
        reduivy__Study_Session__c sseTutorial = getTargetSseList()[1];

        reduivy__Individual_Session_Enrollment__c isnLecture1 = getIsnToInsert(ien.Id, sseLecture.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c isnLecture2 = getIsnToInsert(ien.Id, sseLecture.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c isnTutorial1 = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c isnTutorial2 = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_INPROGRESS_STATUS);
        reduivy__Individual_Session_Enrollment__c isnTutorial3 = getIsnToInsert(ien.Id, sseTutorial.Id, ISN_INPROGRESS_STATUS);
        List<reduivy__Individual_Session_Enrollment__c> isnList = new List<reduivy__Individual_Session_Enrollment__c>{
            isnLecture1, isnLecture2, isnTutorial1, isnTutorial2, isnTutorial3
        };
        
        insert isnList;
        reduivy__Individual_Enrollment__c ienBeforeDelete = getTargetIen();
        

        System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER, ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be over');
        System.Assert.isTrue(new List<String>{'Lecture=2;Tutorial=3', 'Tutorial=3;Lecture=2'}.contains(ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Result__c), 
        'Wrong Rule Result, Expected: Lecture=2;Tutorial=3, Actual: ' + ienBeforeDelete.reduivy__Study_Session_Enrollment_Rule_Result__c);
        
        Test.startTest();
        
		System.runAs(ADMIN_USER){

            delete isnLecture1;

            reduivy__Individual_Enrollment__c ienAfterDeleted = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER, ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be over');
            System.Assert.isTrue(new List<String>{'Lecture=1;Tutorial=3', 'Tutorial=3;Lecture=1'}.contains(ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=1;Tutorial=3, Actual: ' + ienAfterDeleted.reduivy__Study_Session_Enrollment_Rule_Result__c);
            
            undelete isnLecture1;

            reduivy__Individual_Enrollment__c ienAfterUndeleted = getTargetIen();

            System.Assert.areEqual(IEN_Helper.SESSION_ENROLLMENT_RULE_STATUS_OVER, ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be over');
            System.Assert.isTrue(new List<String>{'Lecture=2;Tutorial=3', 'Tutorial=3;Lecture=2'}.contains(ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Result__c), 
                'Wrong Rule Result, Expected: Lecture=2;Tutorial=3, Actual: ' + ienAfterUndeleted.reduivy__Study_Session_Enrollment_Rule_Result__c);
		}

        Test.stopTest();
    }

    /**
    * @description Test as admin for invalid Session Rule
    */
    @IsTest
    static void testForInvalidAndNoStudySessionRule() {

        reduivy__Study_Offering__c sof = [SELECT Id,
            Name, 
            reduivy__Study_Session_Enrollment_Rule__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Sample_Record_Code__c = :SOF_KEY
            LIMIT 1
        ];
        sof.reduivy__Study_Session_Enrollment_Rule__c = 'Lecture=invalid;Tutorial=1';
        update sof;

        reduivy__Individual_Enrollment__c ien = getTargetIen();

        reduivy__Study_Session__c sseLecture = getTargetSseList()[0];

        reduivy__Individual_Session_Enrollment__c isnToInsert = getIsnToInsert(ien.Id, sseLecture.Id, ISN_INPROGRESS_STATUS);
        
        String sserLabel = reduivy__Study_Offering__c.fields.reduivy__Study_Session_Enrollment_Rule__c.getDescribe().getLabel();
        String expectedMessage = String.format(Label.Invalid_Study_Session_Enrollment_Rule, new List<String> {sserLabel, SOF_Helper.getObjectLabel()});

        System.runAs(ADMIN_USER){
            Test.startTest();
            
            try{
                insert isnToInsert;
            } catch( Exception exp){
                System.Assert.isTrue(exp.getMessage().contains(expectedMessage), 'Wrong exception message: Expected: '+ expectedMessage + '; Actual: ' + exp.getMessage());
            }
            

            sof.reduivy__Study_Session_Enrollment_Rule__c = 'Lecture=;Tutorial=1';
            update sof;
            try{
                insert isnToInsert;
            } catch( Exception exp){
                System.Assert.isTrue(exp.getMessage().contains(expectedMessage), 'Wrong exception message: Expected: '+ expectedMessage + '; Actual: ' + exp.getMessage());
            }


            //No session rule
            sof.reduivy__Study_Session_Enrollment_Rule__c = '';
            update sof;
            
            insert isnToInsert;

            reduivy__Individual_Enrollment__c ienOfFirstUndeletedisn = getTargetIen();

            System.Assert.areEqual(null, ienOfFirstUndeletedisn.reduivy__Study_Session_Enrollment_Rule_Status__c, 'Enrollment status should be null');
            System.Assert.areEqual(null, ienOfFirstUndeletedisn.reduivy__Study_Session_Enrollment_Rule_Result__c, 'Enrollment result should be null');

            Test.stopTest();
        }
    }

    /**
     * @description get the test data ien record
     * @return   ien record
     */
    private static reduivy__Individual_Enrollment__c getTargetIen(){
        return [SELECT Id,
                Name,
                reduivy__Study_Session_Enrollment_Rule_Status__c,
                reduivy__Study_Session_Enrollment_Rule_Result__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Sample_Record_Code__c = :IEN_KEY
                LIMIT 1
        ];
    }

    /**
     * @description get sse record, lecture and tutorial
     * @return   list of sse record, [0] = lecture; [1] = tutorial
     */
    private static List<reduivy__Study_Session__c> getTargetSseList(){
        if (targetSseLectureAndTutorial == null) {
            targetSseLectureAndTutorial = [SELECT Id,
                Name,
                reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Session__c
                WHERE reduivy__Sample_Record_Code__c IN (:SSE_LECTURE_KEY, :SSE_TUTORIAL_KEY)
                LIMIT 2
            ];
        }

        return targetSseLectureAndTutorial;
    }
    

    /**
     * @description create and return a new Individual Session Enrollment
     * @param  ienId          ien Id
     * @param  sseId          sse Id
     * @param  statusToInsert The status of Isn
     * @return                newly created Isn
     */
    static reduivy__Individual_Session_Enrollment__c getIsnToInsert(Id ienId, Id sseId, String statusToInsert){
        if(String.isBlank(ienId) || String.isBlank(sseId) || String.isBlank(statusToInsert)) return null;
        reduivy__Individual_Session_Enrollment__c isnToInsert = new reduivy__Individual_Session_Enrollment__c(
            reduivy__Individual_Enrollment__c = ienId,
            reduivy__Study_Session__c = sseId,
            reduivy__Enrollment_Status__c = statusToInsert,
            RecordTypeId = ISN_Helper.getStudentRecordTypeId()
        );
        return isnToInsert;
    }

	
}