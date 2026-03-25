/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IPR_ValidateAcademicTerm_EXE
 * @changehistory
 * ISS-001816 22-23-2023 Lean - new class
 */
@IsTest
public inherited sharing class IPR_ValidateAcademicTerm_TEST {

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

            Test.startTest();

        	testFactory.initMasterData(SPT_Helper.getApiName());
			testFactory.initOfferingData(SGP_Helper.getApiName());
			testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
		}
    }
	
    /**
     * @description Test to change the individual academic progress's academic term as admin
     */
    @IsTest
    static void testChangeTermAsAdmin() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
		System.runAs(ADMIN_USER){
            reduivy__Study_Term__c academicTerm = [
                SELECT Id
                FROM reduivy__Study_Term__c
                WHERE RecordTypeId = : STM_Helper.getAcademicTermRecordTypeId()
                ORDER BY reduivy__End_Date__c DESC
                LIMIT 1
            ];

            List<reduivy__Individual_Academic_Progress__c> iprUpdateList = new List<reduivy__Individual_Academic_Progress__c>();
            for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id
                FROM reduivy__Individual_Academic_Progress__c
                WHERE reduivy__Academic_Term__c !=: academicTerm.Id
            ]) {
                //simulate the change term
                ipr.reduivy__Academic_Term__c = academicTerm.Id;
                iprUpdateList.add(ipr);
            }

            try {
                update iprUpdateList;
                System.Assert.fail('This should fail with update failed error.');

            } catch (Exception exp) {
                List<String> affectedChilds = new List<String>{IEN_Helper.getObjectPluralLabel(), IPW_Helper.getObjectPluralLabel()};
                String expectedMsg = String.format(Label.Cannot_Update_Field_Child_Error, new List<String>{SObjectType.reduivy__Individual_Academic_Progress__c.fields.reduivy__Academic_Term__c.getLabel(), String.join(affectedChilds, ', ')});
                String actualMsg = REDU_Database_UTIL.cleanseErrorMessage(exp.getMessage());

                System.Assert.isTrue(actualMsg.contains(expectedMsg));
            }
		}
		
    }
	
    /**
     * @description Test as student for xxx
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

        User studentUser = [SELECT Id, ContactId, ProfileId 
            FROM User 
            WHERE ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts 
            LIMIT 1
        ];

		System.runAs(studentUser){
            reduivy__Study_Term__c academicTerm = [
                SELECT Id
                FROM reduivy__Study_Term__c
                WHERE RecordTypeId = : STM_Helper.getAcademicTermRecordTypeId()
                ORDER BY reduivy__End_Date__c DESC
                LIMIT 1
            ];

            List<reduivy__Individual_Academic_Progress__c> iprUpdateList = new List<reduivy__Individual_Academic_Progress__c>();
            for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id
                FROM reduivy__Individual_Academic_Progress__c
                WHERE reduivy__Academic_Term__c !=: academicTerm.Id
            ]) {
                //simulate the change term
                ipr.reduivy__Academic_Term__c = academicTerm.Id;

                iprUpdateList.add(ipr);
            }

            try {
                update iprUpdateList;
                System.Assert.fail('This should fail with update failed error.');

            } catch (Exception exp) {
                List<String> affectedChilds = new List<String>{IEN_Helper.getObjectPluralLabel(), IPW_Helper.getObjectPluralLabel()};
                String expectedMsg = String.format(Label.Cannot_Update_Field_Child_Error, new List<String>{SObjectType.reduivy__Individual_Academic_Progress__c.fields.reduivy__Academic_Term__c.getLabel(), String.join(affectedChilds, ', ')});
                String actualMsg = REDU_Database_UTIL.cleanseErrorMessage(exp.getMessage());

                System.Assert.isTrue(actualMsg.contains(expectedMsg));
            }

		}
		
    }
	
    /**
     * @description Test as faculty for xxx
     */
	@IsTest
    static void testForFaculty() {
		        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
		System.runAs(FACULTY_USER){
            reduivy__Study_Term__c academicTerm = [
                SELECT Id
                FROM reduivy__Study_Term__c
                WHERE RecordTypeId = : STM_Helper.getAcademicTermRecordTypeId()
                ORDER BY reduivy__End_Date__c DESC
                LIMIT 1
            ];

            List<reduivy__Individual_Academic_Progress__c> iprUpdateList = new List<reduivy__Individual_Academic_Progress__c>();
            for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id
                FROM reduivy__Individual_Academic_Progress__c
                WHERE reduivy__Academic_Term__c !=: academicTerm.Id
            ]) {
                //simulate the change term
                ipr.reduivy__Academic_Term__c = academicTerm.Id;

                iprUpdateList.add(ipr);
            }

            try {
                update iprUpdateList;
                System.Assert.fail('This should fail with update failed error.');

            } catch (Exception exp) {
                List<String> affectedChilds = new List<String>{IEN_Helper.getObjectPluralLabel(), IPW_Helper.getObjectPluralLabel()};
                String expectedMsg = String.format(Label.Cannot_Update_Field_Child_Error, new List<String>{SObjectType.reduivy__Individual_Academic_Progress__c.fields.reduivy__Academic_Term__c.getLabel(), String.join(affectedChilds, ', ')});
                String actualMsg = REDU_Database_UTIL.cleanseErrorMessage(exp.getMessage());

                System.Assert.isTrue(actualMsg.contains(expectedMsg));
            }
		}
		
    }
	
}