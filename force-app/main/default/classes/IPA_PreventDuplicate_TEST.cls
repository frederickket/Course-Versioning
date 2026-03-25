/**
 * @author      WDCi (XiRouh)
 * @date        July 2025
 * @group       
 * @description Test class for IPA_PreventDuplicate_EXE
 * @changehistory
 * ISS-002508 08-07-2025 XiRouh - new class
 */
@IsTest
public with sharing class IPA_PreventDuplicate_TEST {

   /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String BIS_SPG_PROGRAM_CODE = 'BACBIS';
    static final String MAJOR_STUDY_PLAN = 'BACBIS_MajorA';
    static final String MINORB_STUDY_PLAN = 'BACBIS_MinorB';
    static final String MINORA_STUDY_PLAN = 'BACBIS_MinorA';
    static final String CAMPUS = 'SYDNEY';
    static final String MAJOR_A_DEFAULT_STUDY_PATHWAY = 'BACBIS_MajorA_DEFAULT';
    static final String MINOR_A_DEFAULT_STUDY_PATHWAY = 'BACBIS_MinorA_DEFAULT';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_CYINTAKE';

    static final String IPA_ACTIVE_STATUS = IPA_Helper.getActiveStatuses().get(0);
    static final String IPA_INACTIVE_STATUS = IPA_Helper.APPLICATION_STATUS_REJECTED;

    static final String MASTER_STUDY_PLAN_FIELD_LABEL = Schema.SObjectType.reduivy__Individual_Program_Application__c.fields.reduivy__Master_Study_Plan__c.getLabel();

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

            testFactory.initMasterData(SPU_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
		}
    }

    /**
     * @description Test creating an IPA that matches an existing IPA, as Admin.
     */
    @IsTest
    static void createIpaWithExistingMatchesIpaAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];
        List<reduivy__Study_Pathway__c> spwList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Sample_Record_Code__c = :MAJOR_A_DEFAULT_STUDY_PATHWAY LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(ADMIN_USER) {
            Test.startTest();
        
            insert ipaToBeCreated[0];  
        }
        
        List<reduivy__Individual_Program_Application__c> ipaList = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE reduivy__Contact__c = :studentContacts[0].Id];
        System.Assert.areEqual(1, ipaList.size(), 'An IPA should be created.');

        System.runAs(ADMIN_USER) {        
            try{
                insert ipaToBeCreated[1];
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test creating an IPA that matches an existing IPA, as Faculty.
     */
    @IsTest
    static void createIpaWithExistingMatchesIpaAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];
        List<reduivy__Study_Pathway__c> spwList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Sample_Record_Code__c = :MAJOR_A_DEFAULT_STUDY_PATHWAY LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(FACULTY_USER) {
            Test.startTest();
        
            insert ipaToBeCreated[0];  
        }
        
        List<reduivy__Individual_Program_Application__c> ipaList = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE reduivy__Contact__c = :studentContacts[0].Id];
        System.Assert.areEqual(1, ipaList.size(), 'An IPA should be created.');

        System.runAs(FACULTY_USER) {        
            try{
                insert ipaToBeCreated[1];
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test creating an IPA that matches an existing IPA, as Student.
     */
    @IsTest
    static void createIpaWithExistingMatchesIpaAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];
        List<reduivy__Study_Pathway__c> spwList = [SELECT Id FROM reduivy__Study_Pathway__c WHERE reduivy__Sample_Record_Code__c = :MAJOR_A_DEFAULT_STUDY_PATHWAY LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(studentUser) {
            Test.startTest();
        
            insert ipaToBeCreated[0];  
        }
        
        List<reduivy__Individual_Program_Application__c> ipaList = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE reduivy__Contact__c = :studentContacts[0].Id];
        System.Assert.areEqual(1, ipaList.size(), 'An IPA should be created.');

        System.runAs(studentUser) {        
            try{
                insert ipaToBeCreated[1];
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }

            Test.stopTest();
        }
    }

    /**
    * @description Test updating an IPA to match an existing IPA, as Admin.
    */
    @IsTest
    static void updateIpaToMatchExistingIpaAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create first IPA with specific combination
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create second IPA with different combination initially
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[1].Id, // Different contact
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert ipaToBeCreated;
            
            // Update second IPA to match first IPA (should trigger duplicate error)
            ipaToBeCreated[1].reduivy__Contact__c = studentContacts[0].Id;
            
            try{
                update ipaToBeCreated[1];
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }

            Test.stopTest();
        }
    }

    /**
    * @description Test updating an IPA to match an existing IPA, as Faculty.
    */
    @IsTest
    static void updateIpaToMatchExistingIpaAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create first IPA with specific combination
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create second IPA with different combination initially
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[1].Id, // Different contact
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert ipaToBeCreated;
            
            // Update second IPA to match first IPA (should trigger duplicate error)
            ipaToBeCreated[1].reduivy__Contact__c = studentContacts[0].Id;
            
            try{
                update ipaToBeCreated[1];
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }

            Test.stopTest();
        }
    }

    /**
    * @description Test updating an IPA to match an existing IPA, as Student.
    */
    @IsTest
    static void updateIpaToMatchExistingIpaAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create first IPA with specific combination
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create second IPA with different combination initially
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = null, // Different contact
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(studentUser) {
            Test.startTest();
            
            insert ipaToBeCreated;
            
            // Update second IPA to match first IPA (should trigger duplicate error)
            ipaToBeCreated[1].reduivy__Contact__c = studentContacts[0].Id;
            
            try{
                update ipaToBeCreated[1];
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test creating IPA with Skip_Duplicate_Rules flag set to true, as Admin.
     */
    @IsTest
    static void createIpaWithSkipDuplicateRulesAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // First IPA
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Second IPA with same combination but skip duplicate rules flag set to true
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Skip_Duplicate_Rules__c = true // Skip duplicate check
        ));

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert ipaToBeCreated[0];
            
            // This should succeed because skip flag is true
            insert ipaToBeCreated[1];
            
            // Verify both records were created
            List<reduivy__Individual_Program_Application__c> createdIpas = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaToBeCreated];
            System.Assert.areEqual(2, createdIpas.size(), 'Both IPAs should be created when skip flag is true');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating IPA with Skip_Duplicate_Rules flag set to true, as Faculty.
     */
    @IsTest
    static void createIpaWithSkipDuplicateRulesAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // First IPA
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Second IPA with same combination but skip duplicate rules flag set to true
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Skip_Duplicate_Rules__c = true // Skip duplicate check
        ));

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert ipaToBeCreated[0];
            
            // This should succeed because skip flag is true
            insert ipaToBeCreated[1];
            
            // Verify both records were created
            List<reduivy__Individual_Program_Application__c> createdIpas = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaToBeCreated];
            System.Assert.areEqual(2, createdIpas.size(), 'Both IPAs should be created when skip flag is true');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating IPA with Skip_Duplicate_Rules flag set to true, as Student.
     */
    @IsTest
    static void createIpaWithSkipDuplicateRulesAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // First IPA
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Second IPA with same combination but skip duplicate rules flag set to true
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Skip_Duplicate_Rules__c = true // Skip duplicate check
        ));

        System.runAs(studentUser) {
            Test.startTest();
            
            insert ipaToBeCreated[0];
            
            // This should succeed because skip flag is true
            insert ipaToBeCreated[1];
            
            // Verify both records were created
            List<reduivy__Individual_Program_Application__c> createdIpas = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaToBeCreated];
            System.Assert.areEqual(2, createdIpas.size(), 'Both IPAs should be created when skip flag is true');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating IPA with inactive status (should not trigger duplicate check), as Admin.
     */
    @IsTest
    static void createIpaWithInactiveStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // First IPA with active status
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Second IPA with same combination but inactive status
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_INACTIVE_STATUS, // Inactive status
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert ipaToBeCreated[0];
            
            // This should succeed because second IPA has inactive status
            insert ipaToBeCreated[1];
            
            // Verify both records were created
            List<reduivy__Individual_Program_Application__c> createdIpas = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaToBeCreated];
            System.Assert.areEqual(2, createdIpas.size(), 'Both IPAs should be created when second has inactive status');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating IPA with inactive status (should not trigger duplicate check), as Faculty.
     */
    @IsTest
    static void createIpaWithInactiveStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // First IPA with active status
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Second IPA with same combination but inactive status
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_INACTIVE_STATUS, // Inactive status
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert ipaToBeCreated[0];
            
            // This should succeed because second IPA has inactive status
            insert ipaToBeCreated[1];
            
            // Verify both records were created
            List<reduivy__Individual_Program_Application__c> createdIpas = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaToBeCreated];
            System.Assert.areEqual(2, createdIpas.size(), 'Both IPAs should be created when second has inactive status');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating IPA with inactive status (should not trigger duplicate check), as Student.
     */
    @IsTest
    static void createIpaWithInactiveStatusAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // First IPA with active status
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Second IPA with same combination but inactive status
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_INACTIVE_STATUS, // Inactive status
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(studentUser) {
            Test.startTest();
            
            insert ipaToBeCreated[0];
            
            // This should succeed because second IPA has inactive status
            insert ipaToBeCreated[1];
            
            // Verify both records were created
            List<reduivy__Individual_Program_Application__c> createdIpas = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaToBeCreated];
            System.Assert.areEqual(2, createdIpas.size(), 'Both IPAs should be created when second has inactive status');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test updating IPA from active to inactive status (should allow duplicate to be created), as Admin.
     */
    @IsTest
    static void updateIpaFromActiveToInactiveStatusAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        reduivy__Individual_Program_Application__c existingIpa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        );

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert existingIpa;
            
            // Update existing IPA to inactive status
            existingIpa.reduivy__Application_Status__c = IPA_INACTIVE_STATUS;
            update existingIpa;
            
            // Now create a new IPA with same combination - should succeed
            reduivy__Individual_Program_Application__c newIpa = new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = studentContacts[0].Id,
                reduivy__Application_Date__c = System.today(),
                reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
                reduivy__Default_Campus__c = campusList[0].Id,
                reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
                reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
                reduivy__Study_Intake__c = sitList[0].Id,
                reduivy__Study_Program__c = spgList[0].Id
            );
            
            insert newIpa;
            
            // Verify new IPA was created
            List<reduivy__Individual_Program_Application__c> activeIpas = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE reduivy__Application_Status__c = :IPA_ACTIVE_STATUS];
            System.Assert.areEqual(1, activeIpas.size(), 'New IPA should be created after existing one became inactive');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test updating IPA from active to inactive status (should allow duplicate to be created), as faculty.
     */
    @IsTest
    static void updateIpaFromActiveToInactiveStatusAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        reduivy__Individual_Program_Application__c existingIpa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        );

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert existingIpa;
            
            // Update existing IPA to inactive status
            existingIpa.reduivy__Application_Status__c = IPA_INACTIVE_STATUS;
            update existingIpa;
            
            // Now create a new IPA with same combination - should succeed
            reduivy__Individual_Program_Application__c newIpa = new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = studentContacts[0].Id,
                reduivy__Application_Date__c = System.today(),
                reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
                reduivy__Default_Campus__c = campusList[0].Id,
                reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
                reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
                reduivy__Study_Intake__c = sitList[0].Id,
                reduivy__Study_Program__c = spgList[0].Id
            );
            
            insert newIpa;
            
            // Verify new IPA was created
            List<reduivy__Individual_Program_Application__c> activeIpas = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE reduivy__Application_Status__c = :IPA_ACTIVE_STATUS];
            System.Assert.areEqual(1, activeIpas.size(), 'New IPA should be created after existing one became inactive');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test updating IPA from active to inactive status (should allow duplicate to be created), as student.
     */
    @IsTest
    static void updateIpaFromActiveToInactiveStatusAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        reduivy__Individual_Program_Application__c existingIpa = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        );

        System.runAs(studentUser) {
            Test.startTest();
            
            insert existingIpa;
            
            // Update existing IPA to inactive status
            existingIpa.reduivy__Application_Status__c = IPA_INACTIVE_STATUS;
            update existingIpa;
            
            // Now create a new IPA with same combination - should succeed
            reduivy__Individual_Program_Application__c newIpa = new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = studentContacts[0].Id,
                reduivy__Application_Date__c = System.today(),
                reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
                reduivy__Default_Campus__c = campusList[0].Id,
                reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
                reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
                reduivy__Study_Intake__c = sitList[0].Id,
                reduivy__Study_Program__c = spgList[0].Id
            );
            
            insert newIpa;
            
            // Verify new IPA was created
            List<reduivy__Individual_Program_Application__c> activeIpas = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE reduivy__Application_Status__c = :IPA_ACTIVE_STATUS];
            System.Assert.areEqual(1, activeIpas.size(), 'New IPA should be created after existing one became inactive');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test simultaneous update scenario - one IPA going from active to inactive, another from inactive to active, as Admin.
     */
    @IsTest
    static void updateSimultaneousActiveInactiveSwapAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();

        // First IPA - active status
        ipaList.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Second IPA - inactive status, same combination
        ipaList.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_INACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert ipaList;
            
            // Swap statuses - first goes inactive, second goes active
            ipaList[0].reduivy__Application_Status__c = IPA_INACTIVE_STATUS;
            ipaList[1].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;
            
            // This should succeed as they're swapping statuses
            update ipaList;
            
            // Verify the swap was successful
            List<reduivy__Individual_Program_Application__c> updatedIpas = [SELECT Id, reduivy__Application_Status__c FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaList ORDER BY Id];
            System.Assert.areEqual(IPA_INACTIVE_STATUS, updatedIpas[0].reduivy__Application_Status__c, 'First IPA should be inactive');
            System.Assert.areEqual(IPA_ACTIVE_STATUS, updatedIpas[1].reduivy__Application_Status__c, 'Second IPA should be active');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test simultaneous update scenario - one IPA going from active to inactive, another from inactive to active, as Faculty.
     */
    @IsTest
    static void updateSimultaneousActiveInactiveSwapAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();

        // First IPA - active status
        ipaList.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Second IPA - inactive status, same combination
        ipaList.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_INACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert ipaList;
            
            // Swap statuses - first goes inactive, second goes active
            ipaList[0].reduivy__Application_Status__c = IPA_INACTIVE_STATUS;
            ipaList[1].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;
            
            // This should succeed as they're swapping statuses
            update ipaList;
            
            // Verify the swap was successful
            List<reduivy__Individual_Program_Application__c> updatedIpas = [SELECT Id, reduivy__Application_Status__c FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaList ORDER BY Id];
            System.Assert.areEqual(IPA_INACTIVE_STATUS, updatedIpas[0].reduivy__Application_Status__c, 'First IPA should be inactive');
            System.Assert.areEqual(IPA_ACTIVE_STATUS, updatedIpas[1].reduivy__Application_Status__c, 'Second IPA should be active');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test simultaneous update scenario - one IPA going from active to inactive, another from inactive to active, as Student.
     */
    @IsTest
    static void updateSimultaneousActiveInactiveSwapAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();

        // First IPA - active status
        ipaList.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Second IPA - inactive status, same combination
        ipaList.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_INACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        System.runAs(studentUser) {
            Test.startTest();
            
            insert ipaList;
            
            // Swap statuses - first goes inactive, second goes active
            ipaList[0].reduivy__Application_Status__c = IPA_INACTIVE_STATUS;
            ipaList[1].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;
            
            // This should succeed as they're swapping statuses
            update ipaList;
            
            // Verify the swap was successful
            List<reduivy__Individual_Program_Application__c> updatedIpas = [SELECT Id, reduivy__Application_Status__c FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaList ORDER BY Id];
            System.Assert.areEqual(IPA_INACTIVE_STATUS, updatedIpas[0].reduivy__Application_Status__c, 'First IPA should be inactive');
            System.Assert.areEqual(IPA_ACTIVE_STATUS, updatedIpas[1].reduivy__Application_Status__c, 'Second IPA should be active');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating multiple IPAs with same combination simultaneously, as Admin.
     */
    @IsTest
    static void createMultipleMatchingIpasSimultaneouslyAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create three IPAs with same combination
        for(Integer i = 0; i < 3; i++) {
            ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = studentContacts[0].Id,
                reduivy__Application_Date__c = System.today(),
                reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
                reduivy__Default_Campus__c = campusList[0].Id,
                reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
                reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
                reduivy__Study_Intake__c = sitList[0].Id,
                reduivy__Study_Program__c = spgList[0].Id
            ));
        }

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            try{
                insert ipaToBeCreated;
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating multiple IPAs with same combination simultaneously, as Faculty.
     */
    @IsTest
    static void createMultipleMatchingIpasSimultaneouslyAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create three IPAs with same combination
        for(Integer i = 0; i < 3; i++) {
            ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = studentContacts[0].Id,
                reduivy__Application_Date__c = System.today(),
                reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
                reduivy__Default_Campus__c = campusList[0].Id,
                reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
                reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
                reduivy__Study_Intake__c = sitList[0].Id,
                reduivy__Study_Program__c = spgList[0].Id
            ));
        }

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            try{
                insert ipaToBeCreated;
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating multiple IPAs with same combination simultaneously, as Student.
     */
    @IsTest
    static void createMultipleMatchingIpasSimultaneouslyAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create three IPAs with same combination
        for(Integer i = 0; i < 3; i++) {
            ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = studentContacts[0].Id,
                reduivy__Application_Date__c = System.today(),
                reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
                reduivy__Default_Campus__c = campusList[0].Id,
                reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
                reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
                reduivy__Study_Intake__c = sitList[0].Id,
                reduivy__Study_Program__c = spgList[0].Id
            ));
        }

        System.runAs(studentUser) {
            Test.startTest();
            
            try{
                insert ipaToBeCreated;
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test updating multiple IPAs with same combination simultaneously, as Admin.
     */
    @IsTest
    static void updateMultipleMatchingIpasSimultaneouslyAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create three IPAs with same combination
        for(Integer i = 0; i < 3; i++) {
            ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = studentContacts[0].Id,
                reduivy__Application_Date__c = System.today(),
                reduivy__Application_Status__c = IPA_INACTIVE_STATUS,
                reduivy__Default_Campus__c = campusList[0].Id,
                reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
                reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
                reduivy__Study_Intake__c = sitList[0].Id,
                reduivy__Study_Program__c = spgList[0].Id
            ));
        }

        insert ipaToBeCreated;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;
        ipaToBeCreated[1].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;
        ipaToBeCreated[2].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            try{
                update ipaToBeCreated;
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test updating multiple IPAs with same combination simultaneously, as Faculty.
     */
    @IsTest
    static void updateMultipleMatchingIpasSimultaneouslyAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create three IPAs with same combination
        for(Integer i = 0; i < 3; i++) {
            ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = studentContacts[0].Id,
                reduivy__Application_Date__c = System.today(),
                reduivy__Application_Status__c = IPA_INACTIVE_STATUS,
                reduivy__Default_Campus__c = campusList[0].Id,
                reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
                reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
                reduivy__Study_Intake__c = sitList[0].Id,
                reduivy__Study_Program__c = spgList[0].Id
            ));
        }

        insert ipaToBeCreated;

        ipaToBeCreated[0].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;
        ipaToBeCreated[1].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;
        ipaToBeCreated[2].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            try{
                update ipaToBeCreated;
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test updating multiple IPAs with same combination simultaneously, as student.
     */
    @IsTest
    static void updateMultipleMatchingIpasSimultaneouslyAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN) LIMIT 2];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else {
                childStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create three IPAs with same combination
        for(Integer i = 0; i < 3; i++) {
            ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
                reduivy__Contact__c = studentContacts[0].Id,
                reduivy__Application_Date__c = System.today(),
                reduivy__Application_Status__c = IPA_INACTIVE_STATUS,
                reduivy__Default_Campus__c = campusList[0].Id,
                reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
                reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
                reduivy__Study_Intake__c = sitList[0].Id,
                reduivy__Study_Program__c = spgList[0].Id
            ));
        }

        System.runAs(studentUser) {

            insert ipaToBeCreated;

            Test.startTest();
            
            try{
                ipaToBeCreated[0].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;
                ipaToBeCreated[1].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;
                ipaToBeCreated[2].reduivy__Application_Status__c = IPA_ACTIVE_STATUS;

                update ipaToBeCreated;
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.' + exp.getMessage());
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating IPA with partial null values (testing composite key logic), as Admin.
     */
    @IsTest
    static void createIpaWithPartialNullValuesAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create IPAs with some null values (should still check for duplicates)
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
            // Master_Study_Plan__c and Study_Intake__c are null
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
            // Master_Study_Plan__c and Study_Intake__c are null
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            // Master_Study_Plan__c is null
            reduivy__Study_Intake__c = sitList[0].Id
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            // Master_Study_Plan__c is null
            reduivy__Study_Intake__c = sitList[0].Id
        ));

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            insert ipaToBeCreated[0];
            insert ipaToBeCreated[2];
            
            try{
                insert ipaToBeCreated[1];
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }

            try{
                insert ipaToBeCreated[3];
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.'); 
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating IPA with partial null values (testing composite key logic), as Faculty.
     */
    @IsTest
    static void createIpaWithPartialNullValuesAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create IPAs with some null values (should still check for duplicates)
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
            // Master_Study_Plan__c and Study_Intake__c are null
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
            // Master_Study_Plan__c and Study_Intake__c are null
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            // Master_Study_Plan__c is null
            reduivy__Study_Intake__c = sitList[0].Id
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            // Master_Study_Plan__c is null
            reduivy__Study_Intake__c = sitList[0].Id
        ));

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            insert ipaToBeCreated[0];
            insert ipaToBeCreated[2];
            
            try{
                insert ipaToBeCreated[1];
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }

            try{
                insert ipaToBeCreated[3];
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.'); 
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test creating IPA with partial null values (testing composite key logic), as Student.
     */
    @IsTest
    static void createIpaWithPartialNullValuesAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create IPAs with some null values (should still check for duplicates)
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
            // Master_Study_Plan__c and Study_Intake__c are null
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
            // Master_Study_Plan__c and Study_Intake__c are null
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            // Master_Study_Plan__c is null
            reduivy__Study_Intake__c = sitList[0].Id
        ));

        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            // Master_Study_Plan__c is null
            reduivy__Study_Intake__c = sitList[0].Id
        ));

        System.runAs(studentUser) {
            Test.startTest();
            
            insert ipaToBeCreated[0];
            insert ipaToBeCreated[2];
            
            try{
                insert ipaToBeCreated[1];
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.');
            }

            try{
                insert ipaToBeCreated[3];
                System.Assert.fail('Expected duplicate error but none was thrown');
            }
            catch(Exception exp){
                String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                        new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});

                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value.'); 
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test updating different fields in IPA records to trigger duplicate validation as admin
     */
    @IsTest
    static void updateIpaWithDifferentFieldChangesAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 3
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN, :MINORA_STUDY_PLAN) LIMIT 3];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c otherChildStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else if (spl.reduivy__Sample_Record_Code__c == MINORB_STUDY_PLAN) {
                childStudyPlan = spl;
            } else {
                otherChildStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create reference IPA that will be used for duplicate comparison
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create test IPA 1 - will test Contact field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[1].Id, // Different contact initially
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create test IPA 2 - will test Master Study Plan field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = childStudyPlan.Id, // Different study plan initially
            reduivy__Secondary_Study_Plan__c = otherChildStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create test IPA 3 - will test Skip Duplicate Rules field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Skip_Duplicate_Rules__c = true // Initially skip duplicate rules
        ));

        // Create test IPA 4 - will test Study Intake field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = null,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Skip_Duplicate_Rules__c = false
        ));

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Insert all test records
            insert ipaToBeCreated;
            
            String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                    new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});
            
            // Test 1: Update Contact field to create duplicate
            try {
                ipaToBeCreated[1].reduivy__Contact__c = studentContacts[0].Id; // Change to match reference IPA
                update ipaToBeCreated[1];
                System.Assert.fail('Expected duplicate error for Contact field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Contact field update. Actual: ' + exp.getMessage());
            }
            
            // Test 2: Update Master Study Plan field to create duplicate
            try {
                ipaToBeCreated[2].reduivy__Master_Study_Plan__c = masterStudyPlan.Id; // Change to match reference IPA
                update ipaToBeCreated[2];
                System.Assert.fail('Expected duplicate error for Master Study Plan field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Master Study Plan field update. Actual: ' + exp.getMessage());
            }
            
            // Test 3: Update Skip Duplicate Rules field (should trigger duplicate check when set to false)
            try {
                ipaToBeCreated[3].reduivy__Skip_Duplicate_Rules__c = false; // Change to false to trigger duplicate check
                update ipaToBeCreated[3];
                System.Assert.fail('Expected duplicate error for Skip Duplicate Rules field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Skip Duplicate Rules field update. Actual: ' + exp.getMessage());
            }

            // Test 5: Update Study Intake field to create duplicate
            try {
                ipaToBeCreated[4].reduivy__Study_Intake__c = sitList[0].Id; // Change to match reference IPA
                update ipaToBeCreated[4];
                System.Assert.fail('Expected duplicate error for Study Intake field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Master Study Plan field update. Actual: ' + exp.getMessage());
            }
            
            Test.stopTest();
        }
        
        // Verify original records still exist
        List<reduivy__Individual_Program_Application__c> finalIpaList = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaToBeCreated];
        System.Assert.areEqual(5, finalIpaList.size(), 'All original IPA records should still exist after failed updates');
    }

    /**
     * @description Test updating different fields in IPA records to trigger duplicate validation as faculty
     */
    @IsTest
    static void updateIpaWithDifferentFieldChangesAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 3
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN, :MINORA_STUDY_PLAN) LIMIT 3];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c otherChildStudyPlan = new reduivy__Study_Plan__c();

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else if (spl.reduivy__Sample_Record_Code__c == MINORB_STUDY_PLAN) {
                childStudyPlan = spl;
            } else {
                otherChildStudyPlan = spl;
            }
        }

        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create reference IPA that will be used for duplicate comparison
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create test IPA 1 - will test Contact field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[1].Id, // Different contact initially
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create test IPA 2 - will test Master Study Plan field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = childStudyPlan.Id, // Different study plan initially
            reduivy__Secondary_Study_Plan__c = otherChildStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create test IPA 3 - will test Skip Duplicate Rules field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Skip_Duplicate_Rules__c = true // Initially skip duplicate rules
        ));

        // Create test IPA 4 - will test Study Intake field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = null,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Skip_Duplicate_Rules__c = false
        ));

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Insert all test records
            insert ipaToBeCreated;
            
            String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                    new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});
            
            // Test 1: Update Contact field to create duplicate
            try {
                ipaToBeCreated[1].reduivy__Contact__c = studentContacts[0].Id; // Change to match reference IPA
                update ipaToBeCreated[1];
                System.Assert.fail('Expected duplicate error for Contact field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Contact field update. Actual: ' + exp.getMessage());
            }
            
            // Test 2: Update Master Study Plan field to create duplicate
            try {
                ipaToBeCreated[2].reduivy__Master_Study_Plan__c = masterStudyPlan.Id; // Change to match reference IPA
                update ipaToBeCreated[2];
                System.Assert.fail('Expected duplicate error for Master Study Plan field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Master Study Plan field update. Actual: ' + exp.getMessage());
            }
            
            // Test 3: Update Skip Duplicate Rules field (should trigger duplicate check when set to false)
            try {
                ipaToBeCreated[3].reduivy__Skip_Duplicate_Rules__c = false; // Change to false to trigger duplicate check
                update ipaToBeCreated[3];
                System.Assert.fail('Expected duplicate error for Skip Duplicate Rules field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Skip Duplicate Rules field update. Actual: ' + exp.getMessage());
            }

            // Test 5: Update Study Intake field to create duplicate
            try {
                ipaToBeCreated[4].reduivy__Study_Intake__c = sitList[0].Id; // Change to match reference IPA
                update ipaToBeCreated[4];
                System.Assert.fail('Expected duplicate error for Study Intake field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Master Study Plan field update. Actual: ' + exp.getMessage());
            }
            
            Test.stopTest();
        }
        
        // Verify original records still exist
        List<reduivy__Individual_Program_Application__c> finalIpaList = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaToBeCreated];
        System.Assert.areEqual(5, finalIpaList.size(), 'All original IPA records should still exist after failed updates');
    }

    /**
     * @description Test updating different fields in IPA records to trigger duplicate validation as student
     */
    @IsTest
    static void updateIpaWithDifferentFieldChangesAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: studentContacts[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        List<reduivy__Study_Plan__c> splList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Study_Plan__c WHERE reduivy__Sample_Record_Code__c IN (:MAJOR_STUDY_PLAN, :MINORB_STUDY_PLAN, :MINORA_STUDY_PLAN) LIMIT 3];
        List<reduivy__Study_Intake__c> sitList = [SELECT Id FROM reduivy__Study_Intake__c WHERE reduivy__Sample_Record_Code__c = :STUDY_INTAKE LIMIT 1];
        List<Account> campusList = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS LIMIT 1];

        reduivy__Study_Plan__c masterStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c childStudyPlan = new reduivy__Study_Plan__c();
        reduivy__Study_Plan__c otherChildStudyPlan = new reduivy__Study_Plan__c();  

        for(reduivy__Study_Plan__c spl : splList) {
            if(spl.reduivy__Sample_Record_Code__c == MAJOR_STUDY_PLAN) {
                masterStudyPlan = spl;
            } else if (spl.reduivy__Sample_Record_Code__c == MINORB_STUDY_PLAN) {
                childStudyPlan = spl;
            } else {
                otherChildStudyPlan = spl;
            }
        }
        
        List<reduivy__Individual_Program_Application__c> ipaToBeCreated = new List<reduivy__Individual_Program_Application__c>();

        // Create reference IPA that will be used for duplicate comparison
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create test IPA 1 - will test Contact field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = null, // Different contact initially
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create test IPA 2 - will test Master Study Plan field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = childStudyPlan.Id, // Different study plan initially
            reduivy__Secondary_Study_Plan__c = otherChildStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id
        ));

        // Create test IPA 3 - will test Skip Duplicate Rules field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = sitList[0].Id,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Skip_Duplicate_Rules__c = true // Initially skip duplicate rules
        ));

        // Create test IPA 4 - will test Study Intake field update
        ipaToBeCreated.add(new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_ACTIVE_STATUS,
            reduivy__Default_Campus__c = campusList[0].Id,
            reduivy__Master_Study_Plan__c = masterStudyPlan.Id,
            reduivy__Secondary_Study_Plan__c = childStudyPlan.Id,
            reduivy__Study_Intake__c = null,
            reduivy__Study_Program__c = spgList[0].Id,
            reduivy__Skip_Duplicate_Rules__c = false
        ));

        System.runAs(studentUser) {
            Test.startTest();
            
            // Insert all test records
            insert ipaToBeCreated;
            
            String expectedMsg = String.format(Label.Duplicate_IPA_Found,
                    new List<String>{IPA_Helper.getObjectPluralLabel(), SPG_Helper.getObjectLabel(), SIT_Helper.getObjectLabel(), MASTER_STUDY_PLAN_FIELD_LABEL});
            
            // Test 1: Update Contact field to create duplicate
            try {
                ipaToBeCreated[1].reduivy__Contact__c = studentContacts[0].Id; // Change to match reference IPA
                update ipaToBeCreated[1];
                System.Assert.fail('Expected duplicate error for Contact field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Contact field update. Actual: ' + exp.getMessage());
            }
            
            // Test 2: Update Master Study Plan field to create duplicate
            try {
                ipaToBeCreated[2].reduivy__Master_Study_Plan__c = masterStudyPlan.Id; // Change to match reference IPA
                update ipaToBeCreated[2];
                System.Assert.fail('Expected duplicate error for Master Study Plan field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Master Study Plan field update. Actual: ' + exp.getMessage());
            }
            
            // Test 3: Update Skip Duplicate Rules field (should trigger duplicate check when set to false)
            try {
                ipaToBeCreated[3].reduivy__Skip_Duplicate_Rules__c = false; // Change to false to trigger duplicate check
                update ipaToBeCreated[3];
                System.Assert.fail('Expected duplicate error for Skip Duplicate Rules field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Skip Duplicate Rules field update. Actual: ' + exp.getMessage());
            }

            // Test 4: Update Study Intake field to create duplicate
            try {
                ipaToBeCreated[4].reduivy__Study_Intake__c = sitList[0].Id; // Change to match reference IPA
                update ipaToBeCreated[4];
                System.Assert.fail('Expected duplicate error for Study Intake field update but none was thrown');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(expectedMsg), 'The exception message should match the expected value for Master Study Plan field update. Actual: ' + exp.getMessage());
            }
            
            Test.stopTest();
        }
        
        // Verify original records still exist
        List<reduivy__Individual_Program_Application__c> finalIpaList = [SELECT Id FROM reduivy__Individual_Program_Application__c WHERE Id IN :ipaToBeCreated];
        System.Assert.areEqual(5, finalIpaList.size(), 'All original IPA records should still exist after failed updates');
    }
}