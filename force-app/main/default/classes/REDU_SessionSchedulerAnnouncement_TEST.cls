/**
 * @author      WDCi (XW)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for REDU_SessionSchedulerAnnouncement_LCTRL
 * @changehistory
 * ISS-001920 XW 26-08-2024 XW - create new class
 */
@IsTest
public inherited sharing class REDU_SessionSchedulerAnnouncement_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String INSERT_NOT_ALLOWED = 'DML operation INSERT not allowed';

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
            testFactory.initSampleData(null, USR_Helper.getApiName(), SST_Helper.getApiName(), null, true, true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for sendAnnouncement
     */
    @IsTest
    static void testForAdminSendAnnouncement() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session__c sse = [
            SELECT Id, Name, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        Test.startTest();
        
        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
            REDU_SessionSchedulerAnnouncement_LCTRL.sendAnnouncement(sse.Id, 'Summary Title', 'Summary Details', true, true, null, null, ANM_Helper.NCT_NOTIFICATION);
            REDU_SessionSchedulerAnnouncement_LCTRL.sendAnnouncement(sse.Id, 'Summary Title', 'Summary Details', true, true, null, sse.reduivy__End_Date__c, ANM_Helper.NCT_NOTIFICATION);
            REDU_SessionSchedulerAnnouncement_LCTRL.sendAnnouncement(sse.Id, 'Summary Title', 'Summary Details', true, true, sse.reduivy__Start_Date__c, null, ANM_Helper.NCT_NOTIFICATION);
            REDU_SessionSchedulerAnnouncement_LCTRL.sendAnnouncement(sse.Id, 'Summary Title', 'Summary Details', true, true, sse.reduivy__Start_Date__c, sse.reduivy__End_Date__c, ANM_Helper.NCT_NOTIFICATION);

            List<reduivy__Announcement__c> anm = [
                SELECT Id, Name, reduivy__Notification_Receivers_Contact_Id__c
                FROM reduivy__Announcement__c
                WHERE Name = 'Summary Title'
            ];

            System.Assert.areEqual(4, anm.size(), 'Wrong Announcement size!');
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for sendAnnouncement
     */
	@IsTest
    static void testForStudentSendAnnouncement() {

        reduivy__Study_Session__c sse = [
            SELECT Id, Name
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();

        Test.startTest();

        // TO DO: implement unit test run as student
		System.runAs(studentUser){
            try{
                REDU_SessionSchedulerAnnouncement_LCTRL.sendAnnouncement(sse.Id, 'Summary Title', 'Summary Details', true, true, null, null, ANM_Helper.NCT_NOTIFICATION);
            } catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains(INSERT_NOT_ALLOWED), 'Wrong exception type: '+ exp.getMessage());
            }


		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for sendAnnouncement
     */
	@IsTest
    static void testForFacultySendAnnouncement() {
		        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Session__c sse = [
            SELECT Id, Name
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        //get the faculty with allocation for testing, if you don't need the one with allocation, you can simplify the code to use testFactory.getReduFacultyUser()
        User facultyUser = testFactory.getAllocatedFacultyUser();
        if (facultyUser == null) {
            facultyUser = testFactory.getReduFacultyUser();
        }

        //get the student record if you need one for testing using student.ContactId
        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();

        // TO DO: implement unit test run as faculty
		System.runAs(facultyUser){
            try{
                REDU_SessionSchedulerAnnouncement_LCTRL.sendAnnouncement(sse.Id, 'Summary Title', 'Summary Details', true, true, null, null, ANM_Helper.NCT_NOTIFICATION);
            } catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains(INSERT_NOT_ALLOWED), 'Wrong exception type: '+ exp.getMessage());
            }
		}

        Test.stopTest();
		
    }
	
}