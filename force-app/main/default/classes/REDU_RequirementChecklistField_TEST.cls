/**
 * @author      WDCi (XW)
 * @date        July 2025
 * @group       Test
 * @description Test class for REDU_RequirementChecklistField_LCTRL
 * @changehistory
 * ISS-002128 04-07-2025 XW - new class
 */
@IsTest
public inherited sharing class REDU_RequirementChecklistField_TEST {

    static String RESPONSE_RECORD_ID = 'RESPONSE_RECORD_ID';
    static String RESPONSE_OBJECT_API_NAME = 'RESPONSE_OBJECT_API_NAME';

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String SRC_STUDENT_CON = 'sandydoe@redu.example';

    static String SRC_IAC1_POSTFIX = 'Individual_Achievement';
    static String SRC_IAC2_POSTFIX = 'Individual_Achievement_2';
    static String SRC_CVS1 = 'CVS1';
    static String SRC_CVS2 = 'CVS2';

    static final String SRS_LOCAL = 'SRS_Local';
    static final String SRS_GENERAL = 'SRS_General';
    static final String SRQ_LOCAL1 = 'ID Requirement 1';
    static final String SRQ_LOCAL2 = 'ID Requirement 2';
    static final String SRQ_GENERAL1 = 'Transcript Requirement 1';
    static final String SRQ_GENERAL2 = 'Transcript Requirement 2';
    static final String POSTFIX_SRQ_CONDITIONS = ' Conditions';
    static final Integer SRQ_DUE_DAYS = 7;

    static final String IPA_SPG_SRC = 'BACBIS';
    static final String IPA_MSP_SRC = 'BACBIS_MajorA';
    static final String IPA_SSP_SRC = 'BACBIS_MinorA';
    static final String IPA_CON_SRC = 'sandydoe@redu.example';
    static final String IPA_SRC = IPA_CON_SRC;
    static final String IRQ_GENERAL = 'sandydoe@redu.example_SRS_General_SRS_General_UploadTranscript';

    static reduivy__Individual_Requirement__c irq;
    static Contact studentCon;
    static reduivy__Individual_Program_Application__c ipa;

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
        	
            testFactory.initMasterData(SRQ_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IRQ_Helper.getApiName(), true);

            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for getting ipa id and object name
     */
    @IsTest
    static void testFor_Ipa_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        setIrq();
        setCon();
        setIpa();

        Test.startTest();
		System.runAs(ADMIN_USER){
            REDU_LightningResponse responseResult = REDU_RequirementChecklistField_LCTRL.getObjectNameAndRecord(irq.Id, 'reduivy__Individual_Program_Application__c');
            Map<String, String> responseData = (Map<String, String>) JSON.deserialize(responseResult.responseData, Map<String, String>.class);

            String actualIpaId = responseData.get(RESPONSE_RECORD_ID);
            String actualObjectName = responseData.get(RESPONSE_OBJECT_API_NAME);


            System.Assert.areEqual(ipa.Id, actualIpaId, 'Wrong ipa id!');
            System.Assert.areEqual(IPA_Helper.getApiName(), actualObjectName, 'Wrong object name!');
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for getting ipa contact id and object name
     */
    @IsTest
    static void testFor_IpaContact_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        setIrq();
        setCon();
        setIpa();

        Test.startTest();
		System.runAs(ADMIN_USER){
            REDU_LightningResponse responseResult = REDU_RequirementChecklistField_LCTRL.getObjectNameAndRecord(irq.Id, 'reduivy__Individual_Program_Application__r.reduivy__Contact__c');
            Map<String, String> responseData = (Map<String, String>) JSON.deserialize(responseResult.responseData, Map<String, String>.class);

            String actualConId = responseData.get(RESPONSE_RECORD_ID);
            String actualObjectName = responseData.get(RESPONSE_OBJECT_API_NAME);


            System.Assert.areEqual(studentCon.Id, actualconId, 'Wrong con id!');
            System.Assert.areEqual(CON_Helper.getApiName(), actualObjectName, 'Wrong object name!');
		}

        Test.stopTest();
		
    }
    
	
    /**
     * @description Test as faculty for getting ipa id and object name
     */
    @IsTest
    static void testFor_Ipa_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        setIrq();
        setCon();
        setIpa();

        Test.startTest();
		System.runAs(FACULTY_USER){
            REDU_LightningResponse responseResult = REDU_RequirementChecklistField_LCTRL.getObjectNameAndRecord(irq.Id, 'reduivy__Individual_Program_Application__c');
            Map<String, String> responseData = (Map<String, String>) JSON.deserialize(responseResult.responseData, Map<String, String>.class);

            String actualIpaId = responseData.get(RESPONSE_RECORD_ID);
            String actualObjectName = responseData.get(RESPONSE_OBJECT_API_NAME);


            System.Assert.areEqual(ipa.Id, actualIpaId, 'Wrong ipa id!');
            System.Assert.areEqual(IPA_Helper.getApiName(), actualObjectName, 'Wrong object name!');
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for getting ipa contact id and object name
     */
    @IsTest
    static void testFor_IpaContact_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        setIrq();
        setCon();
        setIpa();

        Test.startTest();
		System.runAs(FACULTY_USER){
            REDU_LightningResponse responseResult = REDU_RequirementChecklistField_LCTRL.getObjectNameAndRecord(irq.Id, 'reduivy__Individual_Program_Application__r.reduivy__Contact__c');
            Map<String, String> responseData = (Map<String, String>) JSON.deserialize(responseResult.responseData, Map<String, String>.class);

            String actualConId = responseData.get(RESPONSE_RECORD_ID);
            String actualObjectName = responseData.get(RESPONSE_OBJECT_API_NAME);


            System.Assert.areEqual(studentCon.Id, actualconId, 'Wrong con id!');
            System.Assert.areEqual(CON_Helper.getApiName(), actualObjectName, 'Wrong object name!');
		}

        Test.stopTest();
		
    }
    
	
    /**
     * @description Test as student for getting ipa id and object name
     */
    @IsTest
    static void testFor_Ipa_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        setIrq();
        setCon();
        setIpa();

        Test.startTest();
		System.runAs(studentUser){
            REDU_LightningResponse responseResult = REDU_RequirementChecklistField_LCTRL.getObjectNameAndRecord(irq.Id, 'reduivy__Individual_Program_Application__c');
            Map<String, String> responseData = (Map<String, String>) JSON.deserialize(responseResult.responseData, Map<String, String>.class);

            String actualIpaId = responseData.get(RESPONSE_RECORD_ID);
            String actualObjectName = responseData.get(RESPONSE_OBJECT_API_NAME);


            System.Assert.areEqual(ipa.Id, actualIpaId, 'Wrong ipa id!');
            System.Assert.areEqual(IPA_Helper.getApiName(), actualObjectName, 'Wrong object name!');
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for getting ipa contact id and object name
     */
    @IsTest
    static void testFor_IpaContact_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        setIrq();
        setCon();
        setIpa();

        Test.startTest();
		System.runAs(studentUser){
            REDU_LightningResponse responseResult = REDU_RequirementChecklistField_LCTRL.getObjectNameAndRecord(irq.Id, 'reduivy__Individual_Program_Application__r.reduivy__Contact__c');
            Map<String, String> responseData = (Map<String, String>) JSON.deserialize(responseResult.responseData, Map<String, String>.class);

            String actualConId = responseData.get(RESPONSE_RECORD_ID);
            String actualObjectName = responseData.get(RESPONSE_OBJECT_API_NAME);


            System.Assert.areEqual(studentCon.Id, actualconId, 'Wrong con id!');
            System.Assert.areEqual(CON_Helper.getApiName(), actualObjectName, 'Wrong object name!');
		}

        Test.stopTest();
		
    }
    
    static void setIrq(){
        irq = [
            SELECT Id, Name, reduivy__Status__c, reduivy__Submission_Status__c, reduivy__Review_Status__c, reduivy__Submission_Date__c, reduivy__Review_Date__c, reduivy__Object_Relation_Field__c, reduivy__Object_Fields__c, reduivy__Link_To_Individual_Achievement__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Sample_Record_Code__c = :IRQ_GENERAL
            LIMIT 1
        ];
    }

    static void setCon(){
        studentCon = [
            SELECT Id, Name
            FROM Contact
            WHERE reduivy__Sample_Record_Code__c = :SRC_STUDENT_CON
            LIMIT 1
        ];
    }

    static void setIpa(){
        ipa = [
            SELECT Id, Name
            FROM reduivy__Individual_Program_Application__c
            WHERE reduivy__Sample_Record_Code__c = :IPA_SRC
            LIMIT 1
        ];
    }
	
}