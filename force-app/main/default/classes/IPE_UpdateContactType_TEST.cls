/**
 * @author      WDCi (VTan)
 * @date        Mar 2024
 * @group       Trigger executable
 * @description Test class for IPE_UpdateContactType_EXE
 * @changehistory
 * ISS-001909 21-03-202 VTan - new class
 */
@IsTest
public inherited sharing class IPE_UpdateContactType_TEST{

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();	

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        // Create rio education ivy settings and sample data
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
			testFactory.initStudentData(CON_Helper.getApiName(), false);

            Test.stopTest();
        }
    }

    /**
     * @description Test the update contact type when program enrollment is created.
     */
    @IsTest
    static void testIpeInsertUpdateConTypeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> applicantMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
        //applicant contact
        String contactTypeApplicant = CON_Helper.CONTACT_TYPE_APPLICANT;
        for(Contact appplicant : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT]){

            appplicant.reduivy__Contact_Type__c = contactTypeApplicant;
            applicantMap.put(appplicant.Id, appplicant);
        }
        update applicantMap.values();

        //get study intake info in preparation for enrollment record creation
        reduivy__Study_Intake__c currentIntake = [SELECT Id, 
                                                reduivy__Default_Study_Plan__c, 
                                                reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, 
                                                reduivy__Academic_Term__c, 
                                                reduivy__Academic_Term__r.reduivy__Start_Date__c, 
                                                reduivy__Default_Study_Pathway__c,
                                                reduivy__Campus__c
                                                FROM reduivy__Study_Intake__c 
                                                WHERE reduivy__Registration_Close_Date__c >: System.today()
                                                LIMIT 1];

        //individual program enrollment
        List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact applicant : applicantMap.values()){

            System.Assert.areEqual(contactTypeApplicant, applicant.reduivy__Contact_Type__c, 'The contact type should be applicant as no program enrollment yet.');

            masterProgramEnrollments.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(applicant.email + '_BACBIS_MajorA', applicant.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, enrollmentStatuses[0], null));
        }
        
        // Execute test
        Test.startTest();

        insert masterProgramEnrollments;
        Test.stopTest();
        }

        for(Contact con : [SELECT Id, Name, reduivy__Contact_Type__c FROM Contact WHERE Id IN: applicantMap.keySet()]){
            System.Assert.areEqual(false, con.reduivy__Contact_Type__c == CON_Helper.CONTACT_TYPE_APPLICANT, 'The contact type for applicant should be updated to student.');
        }
    }

    /**
     * @description Test update the contact type when program enrollment is updated.
     */
    @IsTest
    static void testIpeUpdateUpdateConTypeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> applicantMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
        //applicant contact
        String contactTypeApplicant = CON_Helper.CONTACT_TYPE_APPLICANT;
        for(Contact appplicant : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT]){

            appplicant.reduivy__Contact_Type__c = contactTypeApplicant;
            applicantMap.put(appplicant.Id, appplicant);
        }
        update applicantMap.values();

        //get study intake info in preparation for enrollment record creation
        reduivy__Study_Intake__c currentIntake = [SELECT Id, 
                                                reduivy__Default_Study_Plan__c, 
                                                reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, 
                                                reduivy__Academic_Term__c, 
                                                reduivy__Academic_Term__r.reduivy__Start_Date__c, 
                                                reduivy__Default_Study_Pathway__c,
                                                reduivy__Campus__c
                                                FROM reduivy__Study_Intake__c 
                                                WHERE reduivy__Registration_Close_Date__c >: System.today()
                                                LIMIT 1];

        //individual program enrollment
        List<String> enrollmentDraftStatuses = IPE_Helper.getDraftStatuses();
        List<String> enrollmentStatuses = IPE_Helper.getInProgressStatuses();
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact applicant : applicantMap.values()){

            System.Assert.areEqual(contactTypeApplicant, applicant.reduivy__Contact_Type__c, 'The contact type should be applicant as no program enrollment yet.');

            masterProgramEnrollments.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(applicant.email + '_BACBIS_MajorA', applicant.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, enrollmentDraftStatuses[0], null));
        }
        insert masterProgramEnrollments;

        for(reduivy__Individual_Program_Enrollment__c ipe : masterProgramEnrollments){
            ipe.reduivy__Enrollment_Status__c = enrollmentStatuses[0];
        }
        
        
        // Execute test
        Test.startTest();

        update masterProgramEnrollments;
        Test.stopTest();
        }

        for(Contact con : [SELECT Id, Name, reduivy__Contact_Type__c FROM Contact WHERE Id IN: applicantMap.keySet()]){
            System.Assert.areEqual(false, con.reduivy__Contact_Type__c == CON_Helper.CONTACT_TYPE_APPLICANT, 'The contact type for applicant should be updated to student.');
        }
        
    }
}