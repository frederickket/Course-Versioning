/**
 * @author      WDCi (XW)
 * @date        May 2024
 * @group       Test
 * @description Test class for Program Completion 
 * @changehistory
 * ISS-001916 20-05-2024 name - Program Completion Visualizer Test Class
 */
@IsTest
public inherited sharing class REDU_ChatbotProgComVisualizer_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';

    static String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER){
            Test.startTest();
            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (Contact student : testFactory.students.values()) {
				String sampleRecordCode = student.Id + '_' + testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = testFactory.studyPrograms.get(STUDY_PROGRAM).Id;
				Id studyPlanId = testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
				Id idvAcademicProfileId = null;
				reduivy__Individual_Program_Enrollment__c ipe = 
					REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
						sampleRecordCode, 
						contactId, 
						studyProgramId, 
						studyPlanId, 
						studyIntakeId, 
						startingTermId, 
						studyPathwayId, 
						defaultCampusId, 
						classYear, 
						classStanding, 
						eligibleToEnroll, 
						enrollmentStatus,
						idvAcademicProfileId
					);

				ipeList.add(ipe);
			}
			
			insert ipeList;

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for testing all the method
     */
    @IsTest
    static void testForAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Study_Program__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            LIMIT 1];


        // TO DO: implement unit test run as admin
        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse response1 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeRecord(masterIPE.Id);
            System.Assert.areEqual(true, response1.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isFalse(String.isBlank(response1.responseData), 'Response is empty from REDU_ChatbotProgComVisualizer_TEST');

            //id is not found
            try{
                REDU_LightningResponse response2 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeRecord('a0DDR000006Uz6K2AS');
                System.Assert.isTrue(String.isBlank(response2.responseData), 'Excepted to get no records from getIpeRecord');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('List has no rows for assignment to SObject'), 'The exception is invalid: ' + exp.getMessage());
            }

            REDU_LightningResponse response3 = REDU_ChatbotProgComVisualizer_LCTRL.getAllProgram();
            System.Assert.areEqual(true, response3.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isFalse(String.isBlank(response3.responseData), 'Should be getting response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response4 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeProgramByContactId(masterIPE.reduivy__Contact__c);
            System.Assert.areEqual(true, response4.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(!response4.responseData.contains('"comboboxOptions" : [ ]'), 'Should be getting response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response5 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeProgramByContactId(masterIPE.reduivy__Study_Program__c);
            System.Assert.areEqual(true, response5.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(response5.responseData.contains('"comboboxOptions" : [ ]'), 'Should not be getting any response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response6 = REDU_ChatbotProgComVisualizer_LCTRL.getStudyPlansByProgramId(masterIPE.reduivy__Study_Program__c);
            System.Assert.areEqual(true, response6.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isFalse(String.isBlank(response6.responseData), 'Should be getting response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response7 = REDU_ChatbotProgComVisualizer_LCTRL.getStudyPlansByProgramId(masterIPE.reduivy__Contact__c);
            System.Assert.areEqual(true, response7.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(String.isBlank(response7.responseData), 'Should not be getting any response from REDU_ChatbotProgComVisualizer_TEST');


            Test.stopTest();

        }
    }

    /**
     * @description Test as student for testing all the method
     */
    @IsTest
    static void testForStudent(){

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Study_Program__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            LIMIT 1];

        List<Contact> studentContacts = [SELECT Id, reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1];

        User studentUser = [SELECT Id, ContactId, ProfileId
            FROM User
            WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId IN:studentContacts
            LIMIT 1];

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse response1 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeRecord(masterIPE.Id);
            System.Assert.areEqual(true, response1.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(String.isNotEmpty(response1.responseData), 'Response is empty from REDU_ChatbotProgComVisualizer_TEST. Response: ' + response1.responseData);

            //id is not found
            try{
                REDU_LightningResponse response2 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeRecord('a0DDR000006Uz6K2AA');
                System.Assert.isTrue(String.isBlank(response2.responseData), 'Excepted to get no records from getIpeRecord');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('List has no rows for assignment to SObject'), 'The exception is invalid: ' + exp.getMessage());
            }

            //
            try{
                REDU_LightningResponse response3 = REDU_ChatbotProgComVisualizer_LCTRL.getContactIdByUserId(studentUser.Id);
                System.Assert.isTrue(String.isNotBlank(response3.responseData), 'Excepted to get records from getContactIdByUserId');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('List has no rows for assignment to SObject'), 'The exception is invalid: ' + exp.getMessage());
            }

            REDU_LightningResponse response4 = REDU_ChatbotProgComVisualizer_LCTRL.getAllProgram();
            System.Assert.areEqual(true, response4.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(String.isNotEmpty(response4.responseData), 'Should be getting response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response5 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeProgramByContactId(masterIPE.reduivy__Contact__c);
            System.Assert.areEqual(true, response5.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(!response5.responseData.contains('"comboboxOptions" : [ ]'), 'Should be getting response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response6 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeProgramByContactId(masterIPE.reduivy__Study_Program__c);
            System.Assert.areEqual(true, response6.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(response6.responseData.contains('"comboboxOptions" : [ ]'), 'Should not be getting any response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response7 = REDU_ChatbotProgComVisualizer_LCTRL.getStudyPlansByProgramId(masterIPE.reduivy__Study_Program__c);
            System.Assert.areEqual(true, response7.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(String.isNotEmpty(response7.responseData), 'Should be getting response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response8 = REDU_ChatbotProgComVisualizer_LCTRL.getStudyPlansByProgramId(masterIPE.reduivy__Contact__c);
            System.Assert.areEqual(true, response8.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(String.isEmpty(response8.responseData), 'Should not be getting any response from REDU_ChatbotProgComVisualizer_TEST');

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for testing all the method
     */
    @IsTest
    static void testForFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Study_Program__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            LIMIT 1];

        // TO DO: implement unit test run as faculty
        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse response1 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeRecord(masterIPE.Id);
            System.Assert.areEqual(true, response1.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isFalse(String.isBlank(response1.responseData), 'Response is empty from REDU_ChatbotProgComVisualizer_TEST');

            //id is not found
            try{
                REDU_LightningResponse response2 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeRecord('a0DDR000006Uz6K111');
                System.Assert.isTrue(String.isBlank(response2.responseData), 'Excepted to get no records from getIpeRecord');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('List has no rows for assignment to SObject'), 'The exception is invalid: ' + exp.getMessage());
            }

            REDU_LightningResponse response3 = REDU_ChatbotProgComVisualizer_LCTRL.getAllProgram();
            System.Assert.areEqual(true, response3.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isFalse(String.isBlank(response3.responseData), 'Should be getting response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response4 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeProgramByContactId(masterIPE.reduivy__Contact__c);
            System.Assert.areEqual(true, response4.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(!response4.responseData.contains('"comboboxOptions" : [ ]'), 'Should be getting response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response5 = REDU_ChatbotProgComVisualizer_LCTRL.getIpeProgramByContactId(masterIPE.reduivy__Study_Program__c);
            System.Assert.areEqual(true, response5.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(response5.responseData.contains('"comboboxOptions" : [ ]'), 'Should not be getting any response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response6 = REDU_ChatbotProgComVisualizer_LCTRL.getStudyPlansByProgramId(masterIPE.reduivy__Study_Program__c);
            System.Assert.areEqual(true, response6.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isFalse(String.isBlank(response6.responseData), 'Should be getting response from REDU_ChatbotProgComVisualizer_TEST');

            REDU_LightningResponse response7 = REDU_ChatbotProgComVisualizer_LCTRL.getStudyPlansByProgramId(masterIPE.reduivy__Contact__c);
            System.Assert.areEqual(true, response7.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
            System.Assert.isTrue(String.isBlank(response7.responseData), 'Should not be getting any response from REDU_ChatbotProgComVisualizer_TEST');

            Test.stopTest();
        }
    }

    
    /**
     * @description Test as setup user for testing all the method. Used to test if user has no permission to read
     */
    @isTest
    static void testForSetupUser(){
        User SETUP_USER = testFactory.getSetupUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Study_Program__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            LIMIT 1];

        System.runAs(SETUP_USER){
            Test.startTest();

            REDU_LightningResponse response = null;
            try{
                response = REDU_ChatbotProgComVisualizer_LCTRL.getIpeRecord(masterIPE.Id);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
                System.Assert.isFalse(String.isBlank(response.responseData), 'Response is empty from REDU_ChatbotProgComVisualizer_TEST');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('sObject type \'reduivy__Individual_Program_Enrollment__c\' is not supported.'), 'The exception is invalid: ' + exp.getMessage());
            }

            try{
                response = REDU_ChatbotProgComVisualizer_LCTRL.getContactIdByUserId(masterIPE.Id);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
                System.Assert.isTrue(String.isBlank(response.responseData), 'Response is not empty from REDU_ChatbotProgComVisualizer_TEST');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('No such column \'ContactId\' on entity \'User\''), 'The exception is invalid: ' + exp.getMessage());
            }


            try{
                response = REDU_ChatbotProgComVisualizer_LCTRL.getAllProgram();
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
                System.Assert.isFalse(String.isBlank(response.responseData), 'Response is empty from REDU_ChatbotProgComVisualizer_TEST');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Study_Program__c: Name'), 'The exception is invalid: ' + exp.getMessage());
            }

            try{
                response = REDU_ChatbotProgComVisualizer_LCTRL.getIpeProgramByContactId(masterIPE.reduivy__Contact__c);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
                System.Assert.isFalse(String.isBlank(response.responseData), 'Response is empty from REDU_ChatbotProgComVisualizer_TEST');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Individual_Program_Enrollment__c: Name, RecordTypeId, reduivy__Enrollment_Status__c. reduivy__Study_Program__c: Name, reduivy__Program_Code__c. reduivy__Study_Plan__c: reduivy__Type__c'), 'The exception is invalid: ' + exp.getMessage());
            }

            try{
                response = REDU_ChatbotProgComVisualizer_LCTRL.getIpeProgramByContactId(masterIPE.reduivy__Study_Program__c);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
                System.Assert.isTrue(String.isBlank(response.responseData), 'Shouldn\'t be getting any response from REDU_ChatbotProgComVisualizer_TEST');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Individual_Program_Enrollment__c: Name, RecordTypeId, reduivy__Enrollment_Status__c. reduivy__Study_Program__c: Name, reduivy__Program_Code__c. reduivy__Study_Plan__c: reduivy__Type__c'), 'The exception is invalid: ' + exp.getMessage());
            }

            try{
                response = REDU_ChatbotProgComVisualizer_LCTRL.getStudyPlansByProgramId(masterIPE.reduivy__Study_Program__c);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
                System.Assert.isFalse(String.isBlank(response.responseData), 'Should be getting any response from REDU_ChatbotProgComVisualizer_TEST');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Study_Plan__c: Name'), 'The exception is invalid: ' + exp.getMessage());
            }

            try{
                response = REDU_ChatbotProgComVisualizer_LCTRL.getStudyPlansByProgramId(masterIPE.reduivy__Contact__c);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_ChatbotProgComVisualizer_TEST');
                System.Assert.isTrue(String.isBlank(response.responseData), 'Shouldn\'t be getting any response from REDU_ChatbotProgComVisualizer_TEST');
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s) - reduivy__Study_Plan__c: Name'), 'The exception is invalid: ' + exp.getMessage());
            }

            Test.stopTest();
        }
    }

}