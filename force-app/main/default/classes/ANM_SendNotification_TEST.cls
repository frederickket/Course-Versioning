/**
 * @author      WDCi (XW)
 * @date        Sept 2024
 * @group       Test
 * @description Test class for ANM_SendNotification_EXE
 * @changehistory
 * ISS-001920 05-09-2024 XW - create new class
 */
@IsTest
public inherited sharing class ANM_SendNotification_TEST {

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
        	
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for xxx
     */
    @IsTest
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<User> userList = [SELECT Id, 
            Name,
            ProfileId
            FROM User
            WHERE ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        Map<Id, User> userMap = new Map<Id, User>(userList);

        List<reduivy__Announcement__c> anmList = new List<reduivy__Announcement__c>();
        reduivy__Announcement__c announcementUpdate = REDU_TestData_UTIL.newAnnouncement('ANM_1', 'Details Testing', ANM_Helper.STATUS_DRAFT, userList[0].Id, ANM_Helper.NTT_RECORD_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        
        List<reduivy__Announcement__c> anmInsertList = new List<reduivy__Announcement__c>();
        reduivy__Announcement__c announcementInsert1 = REDU_TestData_UTIL.newAnnouncement('ANM_2', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_NAMED_PAGE_EXPERIENCE_CLOUD, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), UserInfo.getUserId(), System.now());
        reduivy__Announcement__c announcementInsert2 = REDU_TestData_UTIL.newAnnouncement('ANM_3', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_NAMED_PAGE_STANDARD, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert3 = REDU_TestData_UTIL.newAnnouncement('ANM_4', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_NAVIGATION_ITEM_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert4 = REDU_TestData_UTIL.newAnnouncement('ANM_5', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_RECORD_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert5 = REDU_TestData_UTIL.newAnnouncement('ANM_6', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_WEB_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert6 = REDU_TestData_UTIL.newAnnouncement('ANM_7', 'Details Testing 123', ANM_Helper.STATUS_SEND, '', ANM_Helper.NTT_WEB_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        anmInsertList.add(announcementInsert1);
        anmInsertList.add(announcementInsert2);
        anmInsertList.add(announcementInsert3);
        anmInsertList.add(announcementInsert4);
        anmInsertList.add(announcementInsert5);

        insert announcementUpdate;

        
        anmList.addAll(anmInsertList);
        anmList.add(announcementUpdate);
        

        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
            
            Test.startTest();
            upsert anmList;
            Test.stopTest();

		}

        for(reduivy__Announcement__c anm : [
            SELECT Id, reduivy__Status__c
            FROM reduivy__Announcement__c
            WHERE Id IN :anmInsertList
        ]){
            System.Assert.areEqual(ANM_Helper.STATUS_PUBLISHED, anm.reduivy__Status__c, 'Status is not Published');
        }


        
		
    }
	
    /**
     * @description Test as student for xxx
     */
	@IsTest
    static void testForStudent() {

        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();
        List<User> userList = [SELECT Id, 
            Name,
            ProfileId
            FROM User
            WHERE ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        Map<Id, User> userMap = new Map<Id, User>(userList);

        List<reduivy__Announcement__c> anmList = new List<reduivy__Announcement__c>();
        reduivy__Announcement__c announcementUpdate = REDU_TestData_UTIL.newAnnouncement('ANM_1', 'Details Testing', ANM_Helper.STATUS_DRAFT, userList[0].Id, ANM_Helper.NTT_RECORD_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        
        List<reduivy__Announcement__c> anmInsertList = new List<reduivy__Announcement__c>();
        reduivy__Announcement__c announcementInsert1 = REDU_TestData_UTIL.newAnnouncement('ANM_2', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_NAMED_PAGE_EXPERIENCE_CLOUD, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), UserInfo.getUserId(), System.now());
        reduivy__Announcement__c announcementInsert2 = REDU_TestData_UTIL.newAnnouncement('ANM_3', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_NAMED_PAGE_STANDARD, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert3 = REDU_TestData_UTIL.newAnnouncement('ANM_4', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_NAVIGATION_ITEM_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert4 = REDU_TestData_UTIL.newAnnouncement('ANM_5', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_RECORD_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert5 = REDU_TestData_UTIL.newAnnouncement('ANM_6', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_WEB_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert6 = REDU_TestData_UTIL.newAnnouncement('ANM_7', 'Details Testing 123', ANM_Helper.STATUS_SEND, '', ANM_Helper.NTT_WEB_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        anmInsertList.add(announcementInsert1);
        anmInsertList.add(announcementInsert2);
        anmInsertList.add(announcementInsert3);
        anmInsertList.add(announcementInsert4);
        anmInsertList.add(announcementInsert5);

        insert announcementUpdate;

        
        anmList.addAll(anmInsertList);
        anmList.add(announcementUpdate);
        

		System.runAs(studentUser){
            
            Test.startTest();
            try{
                upsert anmList;
            }
            catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY'), 'Wrong exp type: '+ exp.getMessage());
            }
            Test.stopTest();

		}


		
    }
	
    /**
     * @description Test as faculty for xxx
     */
	@IsTest
    static void testForFaculty() {
		        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<User> userList = [SELECT Id, 
            Name,
            ProfileId
            FROM User
            WHERE ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        Map<Id, User> userMap = new Map<Id, User>(userList);

        List<reduivy__Announcement__c> anmList = new List<reduivy__Announcement__c>();
        reduivy__Announcement__c announcementUpdate = REDU_TestData_UTIL.newAnnouncement('ANM_1', 'Details Testing', ANM_Helper.STATUS_DRAFT, userList[0].Id, ANM_Helper.NTT_RECORD_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        
        List<reduivy__Announcement__c> anmInsertList = new List<reduivy__Announcement__c>();
        reduivy__Announcement__c announcementInsert1 = REDU_TestData_UTIL.newAnnouncement('ANM_2', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_NAMED_PAGE_EXPERIENCE_CLOUD, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), UserInfo.getUserId(), System.now());
        reduivy__Announcement__c announcementInsert2 = REDU_TestData_UTIL.newAnnouncement('ANM_3', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_NAMED_PAGE_STANDARD, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert3 = REDU_TestData_UTIL.newAnnouncement('ANM_4', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_NAVIGATION_ITEM_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert4 = REDU_TestData_UTIL.newAnnouncement('ANM_5', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_RECORD_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert5 = REDU_TestData_UTIL.newAnnouncement('ANM_6', 'Details Testing 123', ANM_Helper.STATUS_SEND, userList[0].Id, ANM_Helper.NTT_WEB_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        reduivy__Announcement__c announcementInsert6 = REDU_TestData_UTIL.newAnnouncement('ANM_7', 'Details Testing 123', ANM_Helper.STATUS_SEND, '', ANM_Helper.NTT_WEB_PAGE, ANM_Helper.NCT_NOTIFICATION, String.join(userMap.keySet(), ';' ), '', System.now());
        anmInsertList.add(announcementInsert1);
        anmInsertList.add(announcementInsert2);
        anmInsertList.add(announcementInsert3);
        anmInsertList.add(announcementInsert4);
        anmInsertList.add(announcementInsert5);

        insert announcementUpdate;

        
        anmList.addAll(anmInsertList);
        anmList.add(announcementUpdate);
        

		System.runAs(FACULTY_USER){
            
            Test.startTest();
            upsert anmList;
            Test.stopTest();

		}

        for(reduivy__Announcement__c anm : [
            SELECT Id, reduivy__Status__c
            FROM reduivy__Announcement__c
            WHERE Id IN :anmInsertList
        ]){
            System.Assert.areEqual(ANM_Helper.STATUS_PUBLISHED, anm.reduivy__Status__c, 'Status is not Published');
        }
		
    }
	
}