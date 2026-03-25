/**
 * @author      WDCi (XW)
 * @date        Feb 2025
 * @group       Test
 * @description Test class for SOBJ_CreateTranslationMap_EXE
 * @changehistory
 * ISS-002230 06-02-2025 XW - create new class
 * ISS-002312 07-03-2025 XW - create test methods for cloning translation records
 */
@IsTest
public inherited sharing class SOBJ_CreateTranslationMap_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String SAMPLE_RECORD_CODE_EDUINST = 'RIOUNI';
    static final String SAMPLE_RECORD_CODE_CAMPUS = 'SYDNEY';
    static final String SAMPLE_RECORD_CODE_SGS = 'PERCENTAGE_SCORE';

    private static final Integer INVALID_FIELD = -1;

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
            setCreateTLMCustomSetting(true);
        	
            testFactory.initMasterData(ACC_Helper.getApiName());

            //Study Grade Setting
            testFactory.studyGradeSettings.put('PERCENTAGE_SCORE', REDU_TestData_UTIL.newStudyGradeSetting('PERCENTAGE_SCORE', testFactory.eduInst.Id, 'Percentage/Score', SGS_Helper.GRADING_SETTING_TYPE_PERCENTAGE_LETTER));
            testFactory.studyGradeSettings.put('PASS_FAIL', REDU_TestData_UTIL.newStudyGradeSetting('PASS_FAIL', testFactory.eduInst.Id, 'Pass/Fail', SGS_Helper.GRADING_SETTING_TYPE_PASSFAIL));

            REDU_SystemMode_UTIL.doInsert(testFactory.studyGradeSettings.values());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for creating study unit
     */
    @IsTest
    static void testForAdminSettingEnabled() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        //create study unit
        String sampleRecordCode = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name = sampleRecordCode;
        String code = sampleRecordCode;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;

        reduivy__Study_Unit__c studyUnitToInsert = REDU_TestData_UTIL.newStudyUnit(
            sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
            code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
        );

        Integer numberOfField = getNumberOfFields(SUN_Helper.getApiName());

        Test.startTest();
        
        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
            try {
                insert studyUnitToInsert;
                System.Assert.areEqual(1, numberOfField, 'Error should be prompted if more than 1 field or no field is found!');
            } catch(Exception exp) {
                System.Assert.areNotEqual(1, numberOfField, 'Error should not be prompted if only 1 field is found!');
                return;
            }
		}

        reduivy__Study_Unit__c studyUnitAfterInsert = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c
            FROM reduivy__Study_Unit__c
            WHERE Id = :studyUnitToInsert.Id
            LIMIT 1
        ];

        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__c, 'Translation Map should be created!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Translation Map Reference should be inserted!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation should be created!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.Name, 'Translation Name should be inserted!');
        
        if(numberOfField == 1) {
            System.Assert.areEqual('BUS101', studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default Translated Name should be BUS101!');
        } else if(numberOfField == 0) {
            System.Assert.isNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default Translated Name should be empty!');
        }


        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating study unit
     */
	@IsTest
    static void testForStudentSettingEnabled() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }

        //get the student record if you need one for testing using student.ContactId
		User studentUser = testFactory.getStudentUser();

        //create study unit
        String sampleRecordCode = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name = sampleRecordCode;
        String code = sampleRecordCode;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;

        reduivy__Study_Unit__c studyUnitToInsert = REDU_TestData_UTIL.newStudyUnit(
            sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
            code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
        );


        Test.startTest();

        // TO DO: implement unit test run as student
		System.runAs(studentUser){
            try{
                REDU_Database_UTIL.doInsert(new List<reduivy__Study_Unit__c> {studyUnitToInsert});
                System.Assert.fail('Study Unit shouldnt be inserted by student!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('DML operation INSERT not allowed'));
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating study unit
     */
	@IsTest
    static void testForFacultySettingEnabled() {
		
        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }

        //get the faculty with allocation for testing, if you don't need the one with allocation, you can simplify the code to use testFactory.getReduFacultyUser()
        User FACULTY_USER = testFactory.getAllocatedFacultyUser();
        if (FACULTY_USER == null) {
            FACULTY_USER = testFactory.getReduFacultyUser();
        }

        //create study unit
        String sampleRecordCode = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name = sampleRecordCode;
        String code = sampleRecordCode;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;

        reduivy__Study_Unit__c studyUnitToInsert = REDU_TestData_UTIL.newStudyUnit(
            sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
            code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
        );

        Test.startTest();

        // TO DO: implement unit test run as faculty
		System.runAs(FACULTY_USER){
            try{
                REDU_Database_UTIL.doInsert(new List<reduivy__Study_Unit__c> {studyUnitToInsert});
                System.Assert.fail('Study Unit shouldnt be inserted by student!');
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('DML operation INSERT not allowed'));
            }
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for creating study unit with setting disabled
     */
    @IsTest
    static void testForAdminSettingDisabled() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }

        setCreateTLMCustomSetting(false);
        User ADMIN_USER = testFactory.getReduAdminUser();

        //create study unit
        String sampleRecordCode = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name = sampleRecordCode;
        String code = sampleRecordCode;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;

        reduivy__Study_Unit__c studyUnitToInsert = REDU_TestData_UTIL.newStudyUnit(
            sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
            code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
        );


        Test.startTest();
        
        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
            insert studyUnitToInsert;   
		}

        reduivy__Study_Unit__c studyUnitAfterInsert = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name
            FROM reduivy__Study_Unit__c
            WHERE Id = :studyUnitToInsert.Id
            LIMIT 1
        ];

        System.Assert.isNull(studyUnitAfterInsert.reduivy__Translation_Map__c, 'Translation Map should not be created!');

        Test.stopTest();
		
    }

     /**
     * @description Test as admin for creating 2 study units
     */
    @IsTest
    static void testForAdmin2StudyUnits() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        //create study unit
        String sampleRecordCode1 = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name1 = sampleRecordCode1;
        String code1 = sampleRecordCode1;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;

        String sampleRecordCode2 = 'BUS102';
        String name2 = sampleRecordCode2;
        String code2 = sampleRecordCode2;

        reduivy__Study_Unit__c studyUnitToInsert1 = REDU_TestData_UTIL.newStudyUnit(
            sampleRecordCode1, eduInst.Id, studyGradeSetting.Id, name1, 
            code1, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
        );

        reduivy__Study_Unit__c studyUnitToInsert2 = REDU_TestData_UTIL.newStudyUnit(
            sampleRecordCode2, eduInst.Id, studyGradeSetting.Id, name2, 
            code2, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
        );

        List<reduivy__Study_Unit__c> studyUnitBeforeList =new List<reduivy__Study_Unit__c> {
            studyUnitToInsert1, studyUnitToInsert2
        };

        Integer numberOfField = getNumberOfFields(SUN_Helper.getApiName());

        Test.startTest();
        
        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
            try {
                insert studyUnitBeforeList;
                System.Assert.areEqual(1, numberOfField, 'Error should be prompted if more than 1 field or no field is found!');
            } catch(Exception exp) {
                System.Assert.areNotEqual(1, numberOfField, 'Error should not be prompted if only 1 field is found!');
                return;
            }
		}

        List<reduivy__Study_Unit__c> studyUnitAfterList = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c
            FROM reduivy__Study_Unit__c
            WHERE Id IN :studyUnitBeforeList
        ];

        System.Assert.areEqual(2, studyUnitBeforeList.size(), 'Invalid study unit count!');
        
        for(reduivy__Study_Unit__c sun : studyUnitAfterList) {
            System.Assert.isNotNull(sun.reduivy__Translation_Map__c, 'Translation Map should be created!');
            System.Assert.isNotNull(sun.reduivy__Translation_Map__r.reduivy__Reference__c, 'Translation Map Reference should be inserted!');
            System.Assert.isNotNull(sun.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation should be created!');
            System.Assert.isNotNull(sun.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c, 'Translation Reference should be inserted!');

            if(numberOfField == 1) {
                System.Assert.areEqual(sun.Name, sun.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default Translated Name should be BUS101!');
            } else if(numberOfField == 0) {
                System.Assert.isNull(sun.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default Translated Name should be empty!');
            }
        }

        Test.stopTest();
		
    }

    
     /**
     * @description Test as admin, test handling invalid formula format when finding tln formula 
     */
    @IsTest
    static void testForAdminInvalidFormula() {
        
        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        //create study unit
        String sampleRecordCode = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name = sampleRecordCode;
        String code = sampleRecordCode;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;

        reduivy__Study_Unit__c studyUnitToInsert = REDU_TestData_UTIL.newStudyUnit(
            sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
            code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
        );

        try {
            insert studyUnitToInsert;
        } catch (Exception exp) {
            return; //do not test for study offering if the sun is failed to be inserted
        }
        
        Account campus = getCampusAccount();
        
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }
            
        Date currentYearTerm1EndDate = currentYearTerm1StartDate.addDays(137);
        Date currentYearTerm2StartDate = currentYearTerm1EndDate.addDays(31);
        Date currentYearTerm2EndDate = currentYearTerm2StartDate.addDays(137);

        //academic year
        reduivy__Study_Term__c academicYear = REDU_TestData_UTIL.newAcademicYearStudyTerm('CY', eduInst.Id, 'Year ' + currentYearTerm1StartDate.year(), 'Academic Year ' + currentYearTerm1StartDate.year(), STM_Helper.TYPE_SCHOOLYEAR, currentYearTerm1StartDate, currentYearTerm2EndDate);

        List<reduivy__Study_Term__c> academicYears = new List<reduivy__Study_Term__c> {academicYear};
        REDU_SystemMode_UTIL.doInsert(academicYears);

        //academic terms
        List<reduivy__Study_Term__c> academicTerms = new List<reduivy__Study_Term__c>{
            REDU_TestData_UTIL.newAcademicTermStudyTerm('CYT1', academicYears.get(0).Id, 'T1 ' + currentYearTerm1StartDate.year(), 'Academic Term 1 ' + currentYearTerm1StartDate.year(), STM_Helper.TYPE_SEMESTER, currentYearTerm1StartDate, currentYearTerm1EndDate, currentYearTerm1StartDate.addDays(14), Datetime.newInstance(currentYearTerm1StartDate.addDays(-21), Time.newInstance(0, 0, 0, 0)) , Datetime.newInstance(currentYearTerm1StartDate.addDays(-14), Time.newInstance(0, 0, 0, 0)), Datetime.newInstance(currentYearTerm1StartDate, Time.newInstance(0, 0, 0, 0)), false),
            REDU_TestData_UTIL.newAcademicTermStudyTerm('CYT2', academicYears.get(0).Id, 'T2 ' + currentYearTerm1StartDate.year(), 'Academic Term 2 ' + currentYearTerm2StartDate.year(), STM_Helper.TYPE_SEMESTER, currentYearTerm2StartDate, currentYearTerm2EndDate, currentYearTerm2StartDate.addDays(14), Datetime.newInstance(currentYearTerm2StartDate.addDays(-21), Time.newInstance(0, 0, 0, 0)) , Datetime.newInstance(currentYearTerm2StartDate.addDays(-14), Time.newInstance(0, 0, 0, 0)), Datetime.newInstance(currentYearTerm2StartDate, Time.newInstance(0, 0, 0, 0)), false)
        };

        REDU_SystemMode_UTIL.doInsert(academicTerms);

        String sofName = 'BUS101 Study Offering';
        reduivy__Study_Offering__c sof = REDU_TestData_UTIL.newstudyOffering(sofName, studyUnitToInsert.Id, academicTerms.get(0).Id, campus.Id, sofName, 10, currentYearTerm1StartDate, currentYearTerm1EndDate );

        
        Integer numberOfField = getNumberOfFields(SOF_Helper.getApiName());

        System.runAs(ADMIN_USER) {
            Test.startTest();
            try{
                insert sof;
                System.Assert.areEqual(1, numberOfField, 'Error should be prompted if more than 1 field or no field is found!');
                
                reduivy__Study_Offering__c insertedSof = [SELECT Id, reduivy__Translation_Map__c FROM reduivy__Study_Offering__c WHERE Id =: sof.Id];

                if(sofHasTlmFormula()) {
                    System.Assert.isNotNull(insertedSof.reduivy__Translation_Map__c, 'Translation Map should not be empty!');
                } else {
                    System.Assert.isNull(insertedSof.reduivy__Translation_Map__c, 'Translation Map should be empty!');
                }

            } catch(Exception exp) {
                System.Assert.isFalse(exp.getMessage().containsIgnoreCase('Attempt to de-reference a null'), 'Invalid format of formula should not be throwing any error! Exception: ' + exp.getMessage());
                System.Assert.areNotEqual(1, numberOfField, 'Error should not be prompted if only 1 field is found!');

            }
            Test.stopTest();
        }
    }

    /**
     * @description performance test with 200 tlm
     */
    @IsTest
    static void testGenerate100TlmPerformanceTest() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        //create study unit
        String sampleRecordCode = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name = sampleRecordCode;
        String code = sampleRecordCode;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;

        List<reduivy__Study_Unit__c> studyUnitToInsertList = new List<reduivy__Study_Unit__c>();
        for(Integer i = 0; i < 100; i++) {
            reduivy__Study_Unit__c studyUnitToInsert = REDU_TestData_UTIL.newStudyUnit(
                sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
                code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
            );
            studyUnitToInsertList.add(studyUnitToInsert);
        }

        Integer numberOfField = getNumberOfFields(SUN_Helper.getApiName());

        Test.startTest();
        
        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
            
            Integer startCpu = Limits.getCpuTime();
            try {
                insert studyUnitToInsertList;
                System.Assert.areEqual(1, numberOfField, 'Error should be prompted if more than 1 field is found!');
            } catch(Exception exp) {
                System.Assert.areNotEqual(1, numberOfField, 'Error should not be prompted if only 1 field is found!');
            }
            Integer endCpu = Limits.getCpuTime();
            Integer consumedCpu = endCpu - startCpu;
            
            REDU_Logging_UTIL.debug('consumedCpu', consumedCpu);
            System.Assert.isTrue(consumedCpu <= 400, 'The Apex CPU time consumed is too much: ' + consumedCpu);
		}

        Test.stopTest();
    }

    /**
     * @description performance test with 200 tlm
     */
    @IsTest
    static void testGenerate200TlmPerformanceTest() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        //create study unit
        String sampleRecordCode = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name = sampleRecordCode;
        String code = sampleRecordCode;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;


        List<reduivy__Study_Unit__c> studyUnitToInsertList = new List<reduivy__Study_Unit__c>();
        for(Integer i = 0; i < 200; i++) {
            reduivy__Study_Unit__c studyUnitToInsert = REDU_TestData_UTIL.newStudyUnit(
                sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
                code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
            );
            studyUnitToInsertList.add(studyUnitToInsert);
        }

        Integer numberOfField = getNumberOfFields(SUN_Helper.getApiName());

        Test.startTest();
        
        // TO DO: implement unit test run as admin
		System.runAs(ADMIN_USER){
            
            Integer startCpu = Limits.getCpuTime();
            try {
                insert studyUnitToInsertList;
                System.Assert.areEqual(1, numberOfField, 'Error should be prompted if more than 1 field or no field is found!');
            } catch(Exception exp) {
                System.Assert.areNotEqual(1, numberOfField, 'Error should not be prompted if only 1 field is found!');
            }
            Integer endCpu = Limits.getCpuTime();
            Integer consumedCpu = endCpu - startCpu;
            
            REDU_Logging_UTIL.debug('consumedCpu', consumedCpu);
            System.Assert.isTrue(consumedCpu <= 700, 'The Apex CPU time consumed is too much: ' + consumedCpu);
		}

        Test.stopTest();
    }

    /**
     * @description study unit are cloned, the translation records should be cloned but not the default and reference
     */
    @IsTest
    static void testCloneOnceAndTwiceAndTlmIsNotEmpty() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        //create study unit
        String sampleRecordCode = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name = sampleRecordCode;
        String code = sampleRecordCode;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;

        reduivy__Study_Unit__c studyUnitToInsert = REDU_TestData_UTIL.newStudyUnit(
            sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
            code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
        );

        Integer numberOfField = getNumberOfFields(SUN_Helper.getApiName());

        Test.startTest();
        insert studyUnitToInsert;

        reduivy__Study_Unit__c studyUnitAfterInsert = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c
            FROM reduivy__Study_Unit__c
            WHERE Id = :studyUnitToInsert.Id
            LIMIT 1
        ];

        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__c, 'Translation Map should be created!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Translation Map Reference should be inserted!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation should be created!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.Name, 'Translation Name should be inserted!');
        System.Assert.isNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c, 'Clone From Id should be empty!');
        
        if(numberOfField == 1) {
            System.Assert.areEqual('BUS101', studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default Translated Name should be BUS101!');
        } else if(numberOfField == 0) {
            System.Assert.isNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default Translated Name should be empty!');
        }

        //update the translation
        studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c = 'BUS101 fr';
        studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c = 'BUS101 es';
        studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c = 'BUS101 en';

        update studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r;

        reduivy__Study_Unit__c clonedStudyUnit = studyUnitAfterInsert.clone(false, true, false, false);
        clonedStudyUnit.Name = 'BUS102 clone';
        insert clonedStudyUnit;

        reduivy__Study_Unit__c clonedStudyUnitAfterInsert = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Clone_From_Id__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Id,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c
            FROM reduivy__Study_Unit__c
            WHERE Id = :clonedStudyUnit.Id
            LIMIT 1
        ];

        System.Assert.isNotNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__c, 'Translation Map should be created!');
        System.Assert.isNotNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Translation Map Reference should be inserted!');
        System.Assert.areEqual('BUS102 clone Translation Map', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Wrong reference!');
        System.Assert.areEqual(
            studyUnitAfterInsert.reduivy__Translation_Map__r.Id,
            clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Clone_From_Id__c,
            'Wrong Clone From Id!'
        );

        System.Assert.isNotNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation should be created!');
        System.Assert.isNotNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c, 'Translation Name should be inserted!');
        System.Assert.areEqual('BUS102 clone Study Unit Name', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c, 'Translation Name should be inserted!');
        System.Assert.areEqual('BUS102 clone', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Wrong Default!');
        System.Assert.areEqual('BUS101 fr', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c, 'Wrong fr value!');
        System.Assert.areEqual('BUS101 es', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c, 'Wrong es value!');
        System.Assert.areEqual('BUS101 en', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c, 'Wrong en value!');
        System.Assert.areEqual(
            studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.Id,
            clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c,
            'Wrong Clone From Id!'
        );

        //update the translation
        clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c = 'BUS102 fr';
        clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c = 'BUS102 es';
        clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c = 'BUS102 en';
        
        update clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r;
        
        reduivy__Study_Unit__c cloned2 = clonedStudyUnitAfterInsert.clone(false, true, false, false);
        cloned2.Name = 'BUS103 clone2';
        insert cloned2;

        reduivy__Study_Unit__c cloned2AfterInsert = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Clone_From_Id__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Id,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c
            FROM reduivy__Study_Unit__c
            WHERE Id = :cloned2.Id
            LIMIT 1
        ];

        System.Assert.isNotNull(cloned2AfterInsert.reduivy__Translation_Map__c, 'Translation Map should be created!');
        System.Assert.isNotNull(cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Translation Map Reference should be inserted!');
        System.Assert.areEqual('BUS103 clone2 Translation Map', cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Wrong reference!');
        System.Assert.areEqual(
            clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.Id,
            cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Clone_From_Id__c,
            'Wrong Clone From Id!'
        );

        System.Assert.isNotNull(cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation should be created!');
        System.Assert.isNotNull(cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c, 'Translation Name should be inserted!');
        System.Assert.areEqual('BUS103 clone2 Study Unit Name', cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c, 'Translation Name should be inserted!');
        System.Assert.areEqual('BUS103 clone2', cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Wrong Default!');
        System.Assert.areEqual('BUS102 fr', cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c, 'Wrong fr value!');
        System.Assert.areEqual('BUS102 es', cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c, 'Wrong es value!');
        System.Assert.areEqual('BUS102 en', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c, 'Wrong en value!');
        System.Assert.areEqual(
            clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.Id,
            cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c,
            'Wrong Clone From Id!'
        );

        Test.stopTest();
    }

    /**
     * @description test cloned study unit, but the translation map is different from the source. no translation should be cloned
     */
    @IsTest
    static void testClonedStudyUnitButDifferentTranslationMap() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        //create study unit
        String sampleRecordCode = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name = sampleRecordCode;
        String code = sampleRecordCode;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;

        reduivy__Study_Unit__c studyUnitToInsert = REDU_TestData_UTIL.newStudyUnit(
            sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
            code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
        );

        Integer numberOfField = getNumberOfFields(SUN_Helper.getApiName());

        Test.startTest();
        insert studyUnitToInsert;

        reduivy__Study_Unit__c studyUnitAfterInsert = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c
            FROM reduivy__Study_Unit__c
            WHERE Id = :studyUnitToInsert.Id
            LIMIT 1
        ];

        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__c, 'Translation Map should be created!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Translation Map Reference should be inserted!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation should be created!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.Name, 'Translation Name should be inserted!');
        System.Assert.isNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c, 'Clone From Id should be empty!');
        
        if(numberOfField == 1) {
            System.Assert.areEqual('BUS101', studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default Translated Name should be BUS101!');
        } else if(numberOfField == 0) {
            System.Assert.isNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default Translated Name should be empty!');
        }

        //update the translation
        studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c = 'BUS101 fr';
        studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c = 'BUS101 es';
        studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c = 'BUS101 en';

        update studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r;

        
        //new translation map and translation records
        reduivy__Translation__c tln = new reduivy__Translation__c();
        insert tln;
        reduivy__Translation_Map__c tlm = new reduivy__Translation_Map__c();
        tlm.reduivy__Translation_1__c = tln.Id;
        insert tlm;

        reduivy__Study_Unit__c clonedStudyUnit = studyUnitAfterInsert.clone(false, true, false, false);
        clonedStudyUnit.reduivy__Translation_Map__c = tlm.Id;
        clonedStudyUnit.Name = 'BUS102 clone';

        insert clonedStudyUnit;

        reduivy__Study_Unit__c clonedStudyUnitAfterInsert = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Id,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c
            FROM reduivy__Study_Unit__c
            WHERE Id = :clonedStudyUnit.Id
            LIMIT 1
        ];

        System.Assert.isNotNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__c, 'Translation Map should be created!');
        System.Assert.isNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Translation Map Reference should not be inserted!');
        System.Assert.isNotNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation should be created!');
        System.Assert.isNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c, 'Translation Name should not be inserted!');
        System.Assert.isNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default should be empty!');
        System.Assert.isNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c, 'fr value should be empty!');
        System.Assert.isNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c, 'es value should be empty!');
        System.Assert.isNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c, 'en value should be empty!');
        System.Assert.isNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c,'Clone From Id should be empty!');


        Test.stopTest();
    }

    
    /**
     * @description test cloned study unit with empty translation map, translation should be cloned too
     */ 
    @IsTest
    static void testCloneOnceAndTwiceAndTlmIsEmpty() {

        if (!REDU_TranslationManager.canRunTranslationTest()) {
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        //create study unit
        String sampleRecordCode = 'BUS101';
        Account eduInst = getEduInstAccount();
        reduivy__Study_Grade_Setting__c studyGradeSetting = getStudyGradeSetting();
        String name = sampleRecordCode;
        String code = sampleRecordCode;
        Decimal credits = 10;
        String fieldOfStudy = 'Business, Management, and Marketing';
        String unitLevel = '100';
        Decimal eftsl = 0.125;
        String reqLogic = null;

        reduivy__Study_Unit__c studyUnitToInsert = REDU_TestData_UTIL.newStudyUnit(
            sampleRecordCode, eduInst.Id, studyGradeSetting.Id, name, 
            code, credits, fieldOfStudy, unitLevel, eftsl, reqLogic
        );

        Integer numberOfField = getNumberOfFields(SUN_Helper.getApiName());

        Test.startTest();
        insert studyUnitToInsert;

        reduivy__Study_Unit__c studyUnitAfterInsert = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c
            FROM reduivy__Study_Unit__c
            WHERE Id = :studyUnitToInsert.Id
            LIMIT 1
        ];

        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__c, 'Translation Map should be created!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Translation Map Reference should be inserted!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation should be created!');
        System.Assert.isNotNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.Name, 'Translation Name should be inserted!');
        System.Assert.isNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c, 'Clone From Id should be empty!');
        
        if(numberOfField == 1) {
            System.Assert.areEqual('BUS101', studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default Translated Name should be BUS101!');
        } else if(numberOfField == 0) {
            System.Assert.isNull(studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Default Translated Name should be empty!');
        }

        //update the translation
        studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c = 'BUS101 fr';
        studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c = 'BUS101 es';
        studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c = 'BUS101 en';

        update studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r;

        reduivy__Study_Unit__c clonedStudyUnit = studyUnitAfterInsert.clone(false, true, false, false);
        clonedStudyUnit.Name = 'BUS102 clone';
        clonedStudyUnit.reduivy__Translation_Map__c = null;
        insert clonedStudyUnit;

        reduivy__Study_Unit__c clonedStudyUnitAfterInsert = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Clone_From_Id__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Id,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c
            FROM reduivy__Study_Unit__c
            WHERE Id = :clonedStudyUnit.Id
            LIMIT 1
        ];

        System.Assert.isNotNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__c, 'Translation Map should be created!');
        System.Assert.isNotNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Translation Map Reference should be inserted!');
        System.Assert.areEqual('BUS102 clone Translation Map', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Wrong reference!');
        System.Assert.areEqual(
            studyUnitAfterInsert.reduivy__Translation_Map__r.Id,
            clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Clone_From_Id__c,
            'Wrong Clone From Id!'
        );

        System.Assert.isNotNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation should be created!');
        System.Assert.isNotNull(clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c, 'Translation Name should be inserted!');
        System.Assert.areEqual('BUS102 clone Study Unit Name', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c, 'Translation Name should be inserted!');
        System.Assert.areEqual('BUS102 clone', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Wrong Default!');
        System.Assert.areEqual('BUS101 fr', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c, 'Wrong fr value!');
        System.Assert.areEqual('BUS101 es', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c, 'Wrong es value!');
        System.Assert.areEqual('BUS101 en', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c, 'Wrong en value!');
        System.Assert.areEqual(
            studyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.Id,
            clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c,
            'Wrong Clone From Id!'
        );

        //update the translation
        clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c = 'BUS102 fr';
        clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c = 'BUS102 es';
        clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c = 'BUS102 en';
        
        update clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r;
        
        reduivy__Study_Unit__c cloned2 = clonedStudyUnitAfterInsert.clone(false, true, false, false);
        cloned2.Name = 'BUS103 clone2';
        cloned2.reduivy__Translation_Map__c = null;
        insert cloned2;

        reduivy__Study_Unit__c cloned2AfterInsert = [
            SELECT Id, Name, reduivy__Translation_Map__c,
            reduivy__Translation_Map__r.Name,
            reduivy__Translation_Map__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Clone_From_Id__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Id,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.Name,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c,
            reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c
            FROM reduivy__Study_Unit__c
            WHERE Id = :cloned2.Id
            LIMIT 1
        ];

        System.Assert.isNotNull(cloned2AfterInsert.reduivy__Translation_Map__c, 'Translation Map should be created!');
        System.Assert.isNotNull(cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Translation Map Reference should be inserted!');
        System.Assert.areEqual('BUS103 clone2 Translation Map', cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Reference__c, 'Wrong reference!');
        System.Assert.areEqual(
            clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.Id,
            cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Clone_From_Id__c,
            'Wrong Clone From Id!'
        );

        System.Assert.isNotNull(cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__c, 'Translation should be created!');
        System.Assert.isNotNull(cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c, 'Translation Name should be inserted!');
        System.Assert.areEqual('BUS103 clone2 Study Unit Name', cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Reference__c, 'Translation Name should be inserted!');
        System.Assert.areEqual('BUS103 clone2', cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Default__c, 'Wrong Default!');
        System.Assert.areEqual('BUS102 fr', cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__fr__c, 'Wrong fr value!');
        System.Assert.areEqual('BUS102 es', cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__es__c, 'Wrong es value!');
        System.Assert.areEqual('BUS102 en', clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__en__c, 'Wrong en value!');
        System.Assert.areEqual(
            clonedStudyUnitAfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.Id,
            cloned2AfterInsert.reduivy__Translation_Map__r.reduivy__Translation_1__r.reduivy__Clone_From_Id__c,
            'Wrong Clone From Id!'
        );

        Test.stopTest();
    }

    /**
     * @description return true if Study offering has formula that is referring to translation map
     */
    private static Boolean sofHasTlmFormula(){
        Schema.DescribeSObjectResult sofDescribe = Schema.SObjectType.reduivy__Study_Offering__c;

        Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfoForSObject(sofDescribe);
        if (translationInfo.containsKey(REDU_TranslationManager.TRANSLATION_MAP_FIELD_NAME) && String.isNotBlank((String) translationInfo.get(REDU_TranslationManager.TRANSLATION_MAP_FIELD_NAME))) {
            return true;
        }

        return false;
    }

    /**
     * @description get number of fields in study unit translated name comments
     * @return number of fields
     */
    private static Integer getNumberOfFields(String objectApiName){
        
        Map<String, Schema.SObjectField> sunFields = REDU_Metadata_UTIL.describeSObject(objectApiName).fields.getMap();
        String formula = sunFields.get('reduivy__Translated_Name__c').getDescribe().getCalculatedFormula();

        List<String> comments = REDU_TranslationManager.extractCommentsFromFormula(formula);
        comments.remove(0);

        List<String> fields = REDU_StringMerge_UTIL.extractFieldNames(null, String.join(comments, ' ')).values();
        

        if(fields.size() == 1 && !sunFields.containsKey(fields.get(0))) {
            return INVALID_FIELD;
        }

        return fields.size();
        
    }

    /**
     * @description get education institution account
     */
    private static Account getEduInstAccount(){
        Account eduInst = [SELECT Id, Name
            FROM Account
            WHERE reduivy__Sample_Record_Code__c = :SAMPLE_RECORD_CODE_EDUINST
            LIMIT 1];
        
        return eduInst;
    }

    /**
     * @description get campus account
     */
    private static Account getCampusAccount(){
        Account campus = [SELECT Id, Name
            FROM Account
            WHERE reduivy__Sample_Record_Code__c = :SAMPLE_RECORD_CODE_CAMPUS
            LIMIT 1];
        
        return campus;
    }

    /**
     * @description get study grade setting
     */
    private static reduivy__Study_Grade_Setting__c getStudyGradeSetting(){
        reduivy__Study_Grade_Setting__c sgs = [SELECT Id, Name
            FROM reduivy__Study_Grade_Setting__c
            WHERE reduivy__Sample_Record_Code__c = :SAMPLE_RECORD_CODE_SGS
            LIMIT 1];
        
        return sgs;
    }

    /**
     * @description set the record value translation setting to the value given
     */
    private static void setCreateTLMCustomSetting(Boolean value) {
        if(REDU_AppSetting_UTIL.isRecordValueTranslationEnabled() != value) {
            reduivy__RIO_Education_Ivy_Settings__c setting = REDU_AppSetting_UTIL.getOrgDefaultSetting();
            setting.reduivy__Enable_Record_Value_Translation__c = value;
            update setting;
        }
    }
	
 
}