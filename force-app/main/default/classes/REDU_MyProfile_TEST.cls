/**
 * @Author 		WDCi (vtan)
 * @Date 		Oct 2024
 * @group 		Test
 * @Description Test class for REDU_MyProfile_LCTRL
 * @changehistory
 * ISS-002151 25-10-2024 vtan - Test class for REDU_MyProfile_LCTRL
 */

@IsTest
public inherited sharing class REDU_MyProfile_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER){

            Test.startTest();

            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test get user without contact as admin
     */
    @IsTest
    static void testGetProfileWithoutContactAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_MyProfile_LCTRL.getUser();
            User testUser = (User) JSON.deserialize(response.responseData, User.class);

            System.Assert.areEqual(ADMIN_USER.Id, testUser.Id);
            System.Assert.isNull(testUser.ContactId, 'This should be null');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get user with contact as admin
     */
    @IsTest
    static void testGetProfileWithContactAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        System.runAs(ADMIN_USER){

            Account facultyAccount = REDU_TestData_UTIL.newAdministrativeAccount('testadminprofile@redu.example', 'testadminprofile@redu.example');
            insert facultyAccount;

            Contact facultyContact = REDU_TestData_UTIL.newFacultyContact('testadminprofile@redu.example', facultyAccount.Id, 'Albedo', 'Ford', 'testadminprofile@redu.example');
            facultyContact.reduivy__User__c = ADMIN_USER.Id;
            insert facultyContact;

            REDU_LightningResponse response = REDU_MyProfile_LCTRL.getUser();
            User testUser = (User) JSON.deserialize(response.responseData, User.class);

            System.Assert.areEqual(ADMIN_USER.Id, testUser.Id);
            System.Assert.areEqual(facultyContact.Id, testUser.ContactId);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get user without contact as faculty
     */
    @IsTest
    static void testGetProfileWithoutContactAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_MyProfile_LCTRL.getUser();
            User testUser = (User) JSON.deserialize(response.responseData, User.class);

            System.Assert.areEqual(FACULTY_USER.Id, testUser.Id);
            System.Assert.isNull(testUser.ContactId, 'This should be null');
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get user with contact as faculty
     */
    @IsTest
    static void testGetProfileWithContactAsFaculty(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        Contact facultyContact;

        System.runAs(ADMIN_USER){

            Account facultyAccount = REDU_TestData_UTIL.newAdministrativeAccount('testfacultyprofile@redu.example', 'testfacultyprofile@redu.example');
            insert facultyAccount;

            facultyContact = REDU_TestData_UTIL.newFacultyContact('testfacultyprofile@redu.example', facultyAccount.Id, 'Albedo', 'Ford', 'testfacultyprofile@redu.example');
            facultyContact.reduivy__User__c = FACULTY_USER.Id;
            insert facultyContact;
        }

        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_MyProfile_LCTRL.getUser();
            User testUser = (User) JSON.deserialize(response.responseData, User.class);

            System.Assert.areEqual(FACULTY_USER.Id, testUser.Id);
            System.Assert.areEqual(facultyContact.Id, testUser.ContactId);
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get user with contact as student
     */
    @IsTest
    static void testGetProfileWithContactAsStudent(){
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(studentUser) {
            REDU_LightningResponse response = REDU_MyProfile_LCTRL.getUser();
            User testUser = (User) JSON.deserialize(response.responseData, User.class);

            System.Assert.areEqual(studentUser.Id, testUser.Id);
            System.Assert.areEqual(studentUser.ContactId, testUser.ContactId);
        }

        Test.stopTest();
        
    }
}