/**
 * @author      WDCi (XW)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for REDU_ChatbotUtilityBar_LCTRL
 * @changehistory
 * ISS-001991 10-07-2024 XW - create new class
 */
@IsTest
public inherited sharing class REDU_ChatbotUtilityBar_TEST {

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
		System.runAs(ADMIN_USER) {
            testFactory.initStudentData(USR_Helper.getApiName(), true);
		}
    }
	
    /**
     * @description Test as admin for getObjectApiName
     */
    @IsTest
    static void testForAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];

		System.runAs(ADMIN_USER){
            Test.startTest();
            
            REDU_LightningResponse response = REDU_ChatbotUtilityBar_LCTRL.getObjectApiName(studentContacts[0].Id);
            Test.stopTest();

            System.Assert.areEqual('Contact', response.responseData);

		}
		
    }
	
    /**
     * @description Test as student for getObjectApiName
     */
	@IsTest
    static void testForStudent() {
        
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

		System.runAs(studentUser){
            Test.startTest();
            
            REDU_LightningResponse response = REDU_ChatbotUtilityBar_LCTRL.getObjectApiName(studentContacts[0].Id);
            Test.stopTest();

            System.Assert.areEqual('Contact', response.responseData);
		}
		
    }
	
    /**
     * @description Test as faculty for getObjectApiName
     */
	@IsTest
    static void testForFaculty() {
		        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
		System.runAs(FACULTY_USER){
            Test.startTest();
            
            REDU_LightningResponse response = REDU_ChatbotUtilityBar_LCTRL.getObjectApiName(studentContacts[0].Id);
            Test.stopTest();

            System.Assert.areEqual('Contact', response.responseData);
		}
		
    }
	
}