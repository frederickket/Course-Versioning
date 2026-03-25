/**
 * @author      WDCi (XW)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for REDU_SessionScheduler_LCTRL
 * @changehistory
 * ISS-001920 16-08-2024 XW - create new class
 * ISS-002269 20-02-2025 XW - added test case for objectToReturn
 */
@IsTest
public inherited sharing class REDU_SessionScheduler_TEST {
    private static String INSUFFICIENT_READABLE_ACCESS = 'Insufficient READABLE access';
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static String EDU_INST_SAMPLE_RECORD_CODE = 'RIOUNI';
    static String CAMPUS_SAMPLE_RECORD_CODE = 'SYDNEY';
    static String ACADEMIC_TERM_SAMPLE_RECORD_CODE = 'CYT1';
    static String STUDY_UNIT_SAMPLE_RECORD_CODE = 'BUS101';
    static String STUDY_OFFERING_SAMPLE_RECORD_CODE = 'BUS101_CYT1_SYDNEY';

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();

        	testFactory.initMasterData(SUN_Helper.getApiName());
            testFactory.initFacultyData(null, true);
            testFactory.initOfferingData(REDU_TestData_FACTORY.FACULTY_SER);
            testFactory.initStudentData(IPR_Helper.getApiName(), true);

            Test.stopTest();
		}
    }
	
    /**
     * @description Test as admin for GetEducationalInstitutions
     */
    @IsTest
    static void testForAdminGetEducationalInstitutions() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Account> eduInstList = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            ORDER BY Name
        ];

		System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getEducationalInstitutions();
            System.Assert.areEqual(JSON.serialize(eduInstList), response.responseData, 'Wrong Education Inst!');

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as student for GetEducationalInstitutions
     */
	@IsTest
    static void testForStudentGetEducationalInstitutions() {
        
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

        List<Account> eduInstList = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            ORDER BY Name
        ];

		System.runAs(studentUser){

            Test.startTest();

            try{
                REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getEducationalInstitutions();
                System.Assert.areEqual(JSON.serialize(eduInstList), response.responseData, 'Wrong Educational Institutions!');

            }catch(Exception exp){
                System.Assert.isTrue(exp.getTypeName().contains('QueryException'), 'Wrong exp type'+ exp.getMessage());
            }

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as faculty for GetEducationalInstitutions
     */
	@IsTest
    static void testForFacultyGetEducationalInstitutions() {
		        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Account> eduInstList = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            ORDER BY Name
        ];

		System.runAs(FACULTY_USER){

            Test.startTest();

            try{
                REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getEducationalInstitutions();
                System.Assert.areEqual(JSON.serialize(eduInstList), response.responseData, 'Wrong Educational Institutions!');

            }catch(Exception exp){
                System.Assert.isTrue(exp.getTypeName().contains('QueryException'), 'Wrong exp type'+ exp.getMessage());
            }

            Test.stopTest();
		}
		
    }
	

        /**
     * @description Test as admin for GetCampuses
     */
    @IsTest
    static void testForAdminGetCampuses() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Account eduInst = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            LIMIT 1
        ];

        List<Account> campusList = [
            SELECT Id,
            Name,
            reduivy__Code__c
            FROM Account
            WHERE ParentId =: eduInst.Id
            AND RecordTypeId =: ACC_Helper.getCampusRecordTypeId()
            WITH USER_MODE
            ORDER BY Name
        ];

		System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getCampuses(eduInst.Id);
            System.Assert.areEqual(JSON.serialize(campusList), response.responseData, 'Wrong Campus');

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as student for GetCampuses
     */
	@IsTest
    static void testForStudentGetCampuses() {
        
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

        Account eduInst = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            LIMIT 1
        ];

        List<Account> campusList = [
            SELECT Id,
            Name,
            reduivy__Code__c
            FROM Account
            WHERE ParentId =: eduInst.Id
            AND RecordTypeId =: ACC_Helper.getCampusRecordTypeId()
            WITH USER_MODE
            ORDER BY Name
        ];

		System.runAs(studentUser){

            Test.startTest();

            
            try{
                REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getCampuses(eduInst.Id);       
                System.Assert.fail('Should not be here!');

            }catch(Exception exp){
                System.Assert.isTrue(exp.getTypeName().contains('QueryException'), 'Wrong exp type'+ exp.getMessage());
            }

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as faculty for GetCampuses
     */
	@IsTest
    static void testForFacultyGetCampuses() {
		        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Account eduInst = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            LIMIT 1
        ];

        List<Account> campusList = [
            SELECT Id,
            Name,
            reduivy__Code__c
            FROM Account
            WHERE ParentId =: eduInst.Id
            AND RecordTypeId =: ACC_Helper.getCampusRecordTypeId()
            WITH USER_MODE
            ORDER BY Name
        ];

		System.runAs(FACULTY_USER){

            Test.startTest();

            try{
                REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getCampuses(eduInst.Id);       
                System.Assert.fail('Should not be here!');
            }catch(Exception exp){
                System.Assert.isTrue(exp.getTypeName().contains('QueryException'), 'Wrong exp type'+ exp.getMessage());
            }

            Test.stopTest();
		}
		
    }

    
        /**
     * @description Test as admin for GetStudyUnits
     */
    @IsTest
    static void testForAdminGetStudyUnits() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Account eduInst = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            LIMIT 1
        ];


        List<reduivy__Study_Unit__c> studyUnitList = [
            SELECT Id, 
            Name,
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Educational_Institution__c =: eduInst.Id
            WITH USER_MODE
            ORDER BY Name
        ];



		System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudyUnits(eduInst.Id);
            System.Assert.areEqual(JSON.serialize(studyUnitList), response.responseData, 'Wrong Study Unit');

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as student for GetStudyUnits
     */
	@IsTest
    static void testForStudentGetStudyUnits() {
        
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

        Account eduInst = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            LIMIT 1
        ];

        List<reduivy__Study_Unit__c> studyUnitList = [
            SELECT Id, 
            Name,
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Educational_Institution__c =: eduInst.Id
            WITH USER_MODE
            ORDER BY Name
        ];

		System.runAs(studentUser){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudyUnits(eduInst.Id);
            System.Assert.areEqual(JSON.serialize(studyUnitList), response.responseData, 'Wrong study units!');

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as faculty for GetStudyUnits
     */
	@IsTest
    static void testForFacultyGetStudyUnits() {
		        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Account eduInst = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            LIMIT 1
        ];

        List<reduivy__Study_Unit__c> studyUnitList = [
            SELECT Id, 
            Name,
            reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Educational_Institution__c =: eduInst.Id
            WITH USER_MODE
            ORDER BY Name
        ];

		System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudyUnits(eduInst.Id);
            System.Assert.areEqual(JSON.serialize(studyUnitList), response.responseData, 'Wrong study units!');


            Test.stopTest();
		}
		
    }



        
        /**
     * @description Test as admin for GetAcademicTerms
     */
    @IsTest
    static void testForAdminGetAcademicTerms() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Account eduInst = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            LIMIT 1
        ];


        List<reduivy__Study_Term__c> studyTermList = [
            SELECT Id, 
            Name, 
            reduivy__Academic_Year__r.Name
            FROM reduivy__Study_Term__c
            WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: eduInst.Id
            AND RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId()
            AND (reduivy__End_Date__c >= TODAY OR reduivy__End_Date__c = NULL)
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c NULLS LAST, Name
        ];



		System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getAcademicTerms(eduInst.Id);
            System.Assert.areEqual(JSON.serialize(studyTermList), response.responseData, 'Wrong Study Term');

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as student for GetAcademicTerms
     */
	@IsTest
    static void testForStudentGetAcademicTerms() {
        
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

        Account eduInst = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            LIMIT 1
        ];

        List<reduivy__Study_Term__c> studyTermList = [
            SELECT Id, 
            Name, 
            reduivy__Academic_Year__r.Name
            FROM reduivy__Study_Term__c
            WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: eduInst.Id
            AND RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId()
            AND (reduivy__End_Date__c >= TODAY OR reduivy__End_Date__c = NULL)
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c NULLS LAST, Name
        ];

		System.runAs(studentUser){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getAcademicTerms(eduInst.Id);
            System.Assert.areEqual(JSON.serialize(studyTermList),response.responseData, 'Wrong Academic Terms!');

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as faculty for GetAcademicTerms
     */
	@IsTest
    static void testForFacultyGetAcademicTerms() {
		        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Account eduInst = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            WITH USER_MODE
            LIMIT 1
        ];
        List<reduivy__Study_Term__c> studyTermList = [
            SELECT Id, 
            Name, 
            reduivy__Academic_Year__r.Name
            FROM reduivy__Study_Term__c
            WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: eduInst.Id
            AND RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId()
            AND (reduivy__End_Date__c >= TODAY OR reduivy__End_Date__c = NULL)
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c NULLS LAST, Name
        ];

		System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getAcademicTerms(eduInst.Id);
            System.Assert.areEqual(JSON.serialize(studyTermList),response.responseData, 'Wrong Academic Terms!');
                


            Test.stopTest();
		}
		
    }





    /**
     * @description Test as admin for getStudyOfferings
     */
    @IsTest
    static void testForAdminGetStudyOffering() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Offering__c selectedSof = [
            SELECT Id, Name, reduivy__Campus__c, 
            reduivy__Academic_Term__c, 
            reduivy__Study_Unit__c
            FROM reduivy__Study_Offering__c
            LIMIT 1
        ];

        List<reduivy__Study_Offering__c> sofList = [
            SELECT Id, Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Campus__c = :selectedSof.reduivy__Campus__c
            AND reduivy__Academic_Term__c = :selectedSof.reduivy__Academic_Term__c
            AND reduivy__Study_Unit__c = :selectedSof.reduivy__Study_Unit__c
        ];


		System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudyOfferings(selectedSof.reduivy__Campus__c, selectedSof.reduivy__Academic_Term__c, selectedSof.reduivy__Study_Unit__c);
            System.Assert.areEqual(JSON.serialize(sofList), response.responseData, 'Wrong Study Offering!');
           

            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as student for GetStudyOfferings
     */
	@IsTest
    static void testForStudentGetStudyOfferings() {
        
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

        reduivy__Study_Offering__c selectedSof = [
            SELECT Id, Name, reduivy__Campus__c, 
            reduivy__Academic_Term__c, 
            reduivy__Study_Unit__c
            FROM reduivy__Study_Offering__c
            LIMIT 1
        ];

        List<reduivy__Study_Offering__c> sofList = [
            SELECT Id, Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Campus__c = :selectedSof.reduivy__Campus__c
            AND reduivy__Academic_Term__c = :selectedSof.reduivy__Academic_Term__c
            AND reduivy__Study_Unit__c = :selectedSof.reduivy__Study_Unit__c
        ];
		System.runAs(studentUser){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudyOfferings(selectedSof.reduivy__Campus__c, selectedSof.reduivy__Academic_Term__c, selectedSof.reduivy__Study_Unit__c);
            System.Assert.areEqual(JSON.serialize(sofList), response.responseData, 'Wrong Study Offering!');


            Test.stopTest();
		}
		
    }
	
     /**
     * @description Test as student for GetStudyOfferings
     */
	@IsTest
    static void testForFacultyGetStudyOfferings() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Offering__c selectedSof = [
            SELECT Id, Name, reduivy__Campus__c, 
            reduivy__Academic_Term__c, 
            reduivy__Study_Unit__c
            FROM reduivy__Study_Offering__c
            LIMIT 1
        ];

        List<reduivy__Study_Offering__c> sofList = [
            SELECT Id, Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Campus__c = :selectedSof.reduivy__Campus__c
            AND reduivy__Academic_Term__c = :selectedSof.reduivy__Academic_Term__c
            AND reduivy__Study_Unit__c = :selectedSof.reduivy__Study_Unit__c
        ];
		System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudyOfferings(selectedSof.reduivy__Campus__c, selectedSof.reduivy__Academic_Term__c, selectedSof.reduivy__Study_Unit__c);
            System.Assert.areEqual(JSON.serialize(sofList), response.responseData, 'Wrong Study Offering!');


            Test.stopTest();
		}
		
    }


     /**
     * @description Test as admin for GetStudySessions
     */
    @IsTest
    static void testForAdminGetStudySessions(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Date fromDate =  System.today().toStartOfMonth();
        Date toDate = fromDate.addMonths(1).toStartOfMonth();

        List<reduivy__Study_Session_Time__c> sstList = [
            SELECT Id, Name
            FROM reduivy__Study_Session_Time__c
            WHERE reduivy__Start_Date_Calculated__c < :toDate
            AND reduivy__End_Date_Calculated__c >= :fromDate
        ];

        List<reduivy__Study_Session__c> sseList = [
            SELECT Id, Name, reduivy__Study_Offering__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Educational_Institution__c,
            reduivy__Study_Offering__r.reduivy__Campus__c,
            reduivy__Study_Offering__r.reduivy__Academic_Term__c
            FROM reduivy__Study_Session__c
            WHERE Id IN (
                SELECT reduivy__Study_Session__c
                FROM reduivy__Study_Session_Time__c
                WHERE Id IN :sstList
            )
        ];

        List<reduivy__Study_Event__c> sevList = [
            SELECT Id, Name
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN :sseList
            AND reduivy__Start__c >=: fromDate
            AND reduivy__Start__c <=: toDate
        ];

        System.runAs(ADMIN_USER) {   
            Test.startTest();
            
            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudySessions('{Name}', '', 
                (Datetime)fromDate, (Datetime)toDate,
                '{"schedulingType":"Facility"}', 'Name;reduivy__Type__c;reduivy__Study_Offering__c'
            );

            StudySessionWrapper ssw = (StudySessionWrapper) JSON.deserialize(response.responseData, StudySessionWrapper.class);

            Integer resultSstSize = 0;
            Integer resultSevSize = 0;
            for(String sseId: ssw.sessionTimes.keySet()){
                for(reduivy__Study_Session_Time__c sst : ssw.sessionTimes.get(sseId)){
                    resultSstSize++;
                }
            }

            for(String sseId: ssw.sessionStudyEvents.keySet()){
                for(reduivy__Study_Event__c sst : ssw.sessionStudyEvents.get(sseId)){
                    resultSevSize++;
                }
            }
            
            System.Assert.areEqual(sseList.size(), ssw.sessions.size(), 'Wrong Study Session Size');
            System.Assert.areEqual(sstList.size(), resultSstSize, 'Wrong Study Session Time Size');
            System.Assert.areEqual(sevList.size(), resultSevSize, 'Wrong Study Event Size');


            //with educationalInstitutionId campusId academicTermId studyUnitId studyOfferingId in filter
            Map<String, String> filterMap = new Map<String, String>{
                'studyOfferingId' => sseList[0].reduivy__Study_Offering__c,
                'educationalInstitutionId' => sseList[0].reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Educational_Institution__c,
                'campusId' => sseList[0].reduivy__Study_Offering__r.reduivy__Campus__c,
                'studyUnitId' => sseList[0].reduivy__Study_Offering__r.reduivy__Study_Unit__c,
                'academicTermId' => sseList[0].reduivy__Study_Offering__r.reduivy__Academic_Term__c,
                'studyOfferingId' => sseList[0].reduivy__Study_Offering__c,
                'schedulingType' => SER_Helper.RELATION_TYPE_FACILITY
            };

            REDU_LightningResponse filterResponse = REDU_SessionScheduler_LCTRL.getStudySessions('{Name}', 'reduivy__Type__c = \'Lecture\'', 
                (Datetime)fromDate, (Datetime)toDate,
                JSON.serialize(filterMap), 'Name;reduivy__Type__c;reduivy__Study_Offering__c'
            );

            ssw = (StudySessionWrapper) JSON.deserialize(response.responseData, StudySessionWrapper.class);
            Boolean sseIsFound = false;
            for(reduivy__Study_Session__c sse: ssw.sessions) {
               if(sse.Id == sseList[0].Id) {
                   sseIsFound = true;
                   break;
               }
            }
            
            System.Assert.isTrue(sseIsFound, 'Wrong Filter results');

            Test.stopTest();
        }
    }


     /**
     * @description Test as student for GetStudySessions
     */
    @IsTest
    static void testForStudentGetStudySessions(){
        Date fromDate =  System.today().toStartOfMonth();
        Date toDate = fromDate.addMonths(1).toStartOfMonth();
        

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

        List<reduivy__Study_Session_Time__c> sstList = [
            SELECT Id, Name
            FROM reduivy__Study_Session_Time__c
            WHERE reduivy__Start_Date_Calculated__c < :toDate
            AND reduivy__End_Date_Calculated__c >= :fromDate
        ];

        List<reduivy__Study_Session__c> sseList = [
            SELECT Id, Name, reduivy__Study_Offering__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Educational_Institution__c,
            reduivy__Study_Offering__r.reduivy__Campus__c,
            reduivy__Study_Offering__r.reduivy__Academic_Term__c
            FROM reduivy__Study_Session__c
            WHERE Id IN (
                SELECT reduivy__Study_Session__c
                FROM reduivy__Study_Session_Time__c
                WHERE Id IN :sstList
            )
        ];

        List<reduivy__Study_Event__c> sevList = [
            SELECT Id, Name
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN :sseList
            AND reduivy__Start__c >= :fromDate
            AND reduivy__End__c <= :toDate
        ];

        System.runAs(studentUser) {   
            Test.startTest();
            
            try{
                REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudySessions('{Name}', '', 
                    (Datetime)fromDate, (Datetime)toDate,
                    '{"schedulingType":"Facility"}', 'Name;reduivy__Type__c;reduivy__Study_Offering__c'
                );
            }catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_READABLE_ACCESS), 'Wrong exception type: '+ exp.getMessage());
            }



            Test.stopTest();
        }
    }


    /**
     * @description Test as faculty for GetStudySessions
     */
    @IsTest
    static void testForFacultyGetStudySessions(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Date fromDate =  System.today().toStartOfMonth();
        Date toDate = fromDate.addMonths(1).toStartOfMonth();
        
        List<reduivy__Study_Session_Time__c> sstList = [
            SELECT Id, Name
            FROM reduivy__Study_Session_Time__c
            WHERE reduivy__Start_Date_Calculated__c < :toDate
            AND reduivy__End_Date_Calculated__c >= :fromDate
        ];

        List<reduivy__Study_Session__c> sseList = [
            SELECT Id, Name, reduivy__Study_Offering__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Educational_Institution__c,
            reduivy__Study_Offering__r.reduivy__Campus__c,
            reduivy__Study_Offering__r.reduivy__Academic_Term__c
            FROM reduivy__Study_Session__c
            WHERE Id IN (
                SELECT reduivy__Study_Session__c
                FROM reduivy__Study_Session_Time__c
                WHERE Id IN :sstList
            )
        ];

        List<reduivy__Study_Event__c> sevList = [
            SELECT Id, Name
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN :sseList
            AND reduivy__Start__c >= :fromDate
            AND reduivy__End__c <= :toDate
        ];

        System.runAs(FACULTY_USER) {   
            Test.startTest();

            try{
                REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudySessions('{Name}', '', 
                    (Datetime)fromDate, (Datetime)toDate,
                    '{"schedulingType":"Facility"}', 'Name;reduivy__Type__c;reduivy__Study_Offering__c'
                );
            }catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_READABLE_ACCESS), 'Wrong exception type: '+ exp.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for GetFacultyContacts
     */
    @IsTest
    static void testForAdminGetFacultyContacts() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Account eduInst = [
            SELECT Id, Name, 
            reduivy__Code__c
            FROM Account
            WHERE RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId()
            LIMIT 1
        ];

        List<Contact> contactList = [
            SELECT Id, Name
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_FACULTY
        ];

        List<reduivy__Contact_Association__c> casList = [
            SELECT Id, Name
            FROM reduivy__Contact_Association__c
            WHERE reduivy__Account__c = :eduInst.Id
            AND reduivy__Contact__c IN :contactList
        ];

        System.runAs(ADMIN_USER) {   
            Test.startTest();
            
            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getFacultyContacts('{Name}', 'reduivy__Contact_Type__c = \'Faculty\'', '{"schedulingType":"Faculty"}', '');
            List<Contact> resultContactList = (List<Contact>) JSON.deserialize(response.responseData, List<Contact>.class);
            System.Assert.areEqual(contactList.size(), resultContactList.size(), 'Size is not the same');

            //with educational institution
            //
            Map<String, String> filterMap = new Map<String, String>{
                'schedulingType' => 'Faculty',
                'educationalInstitutionId' => eduInst.Id
            };
            REDU_LightningResponse eduResponse = REDU_SessionScheduler_LCTRL.getFacultyContacts('{Name}', 'reduivy__Contact_Type__c = \'Faculty\'', JSON.serialize(filterMap) , '');
            List<Contact> eduFilteredResultContactList = (List<Contact>) JSON.deserialize(eduResponse.responseData, List<Contact>.class);
            System.Assert.areEqual(casList.size(), eduFilteredResultContactList.size(), 'Size is not the same');

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for GetFacultyContacts
     */
    @IsTest
    static void testForStudentGetFacultyContacts() {
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

        List<Contact> contactList = [
            SELECT Id, Name
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_HELPER.CONTACT_TYPE_FACULTY
        ];


        System.runAs(studentUser) {   
            Test.startTest();
            try{
                REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getFacultyContacts('{Name}', 'reduivy__Contact_Type__c = \'Faculty\'', '{"schedulingType":"Faculty"}', '');
            }catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_READABLE_ACCESS), 'Wrong exception type: '+ exp.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for GetFacultyContacts
     */
    @IsTest
    static void testForFacultyGetFacultyContacts() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> contactList = [
            SELECT Id, Name
            FROM Contact
            WHERE reduivy__Contact_Type__c = :CON_HELPER.CONTACT_TYPE_FACULTY
        ];


        System.runAs(FACULTY_USER) {   
            Test.startTest();
            
            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getFacultyContacts('{Name}', 'reduivy__Contact_Type__c = \'Faculty\'', '{"schedulingType":"Faculty"}', '');
            List<Contact> resultContactList = (List<Contact>) JSON.deserialize(response.responseData, List<Contact>.class);
            System.Assert.areEqual(contactList.size(), resultContactList.size(), 'Size is not the same');

            Test.stopTest();
        }
    }




    /**
     * @description Test as admin for GetFacilities
     */
    @IsTest
    static void testForAdminGetFacilitiesWithoutSelectedFacility() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Facility__c> facilityList = [
            SELECT Id, Name
            FROM reduivy__Facility__c
            WHERE reduivy__Active__c = TRUE
        ];

        System.runAs(ADMIN_USER) {   
            Test.startTest();
            
            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getFacilities('{Name}', 'Active__c = true', '{"schedulingType":"Facility"}', null);
            Map<String, Object> responseJSON = (Map<String, Object>) json.deserializeUntyped(response.responseData);
            List<reduivy__Facility__c> resultFacilityList = (List<reduivy__Facility__c>) JSON.deserialize(JSON.serialize(responseJSON.get('facilities')), List<reduivy__Facility__c>.class);
            System.Assert.areEqual(facilityList.size(), resultFacilityList.size(), 'Size is not the same');
            Boolean selectedFacilityMetDefaultCriteria = (Boolean) responseJSON.get('selectedFacilityMetDefaultCriteria');
            System.Assert.areEqual(true, selectedFacilityMetDefaultCriteria, 'Should be matching the criteria');


            Test.stopTest();
        }
    }

    /**
     * @description Test as student for GetFacilities
     */
    @IsTest
    static void testForStudentGetFacilitiesWithoutSelectedFacility() {
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

        List<reduivy__Facility__c> facilityList = [
            SELECT Id, Name
            FROM reduivy__Facility__c
            WHERE reduivy__Active__c = TRUE
        ];

        System.runAs(studentUser) {   
            Test.startTest();
            try{
                REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getFacilities('{Name}', 'Active__c = true', '{"schedulingType":"Facility"}', null);
            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_READABLE_ACCESS), 'Wrong exp type' + exp.getMessage());
            }
         
            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for GetFacilities
     */
    @IsTest
    static void testForFacultyGetGetFacilitiesWithoutSelectedFacility() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Facility__c> facilityList = [
            SELECT Id, Name
            FROM reduivy__Facility__c
            WHERE reduivy__Active__c = TRUE
        ];

        System.runAs(FACULTY_USER) {   
            Test.startTest();
            
            try{
                REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getFacilities('{Name}', 'Active__c = true', '{"schedulingType":"Facility"}', null);
            
            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_READABLE_ACCESS), 'Wrong exp type' + exp.getMessage());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for GetFacilities
     */
    @IsTest
    static void testForAdminGetFacilitiesWithSelectedFacility() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Facility__c> facilityList = [
            SELECT Id, Name
            FROM reduivy__Facility__c
            WHERE reduivy__Active__c = TRUE
        ];
        
        reduivy__Facility__c newFac = new reduivy__Facility__c( Name = 'Inactive', reduivy__Active__c = false);
        insert newFac;

        

        System.runAs(ADMIN_USER) {   
            Test.startTest();
            
            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getFacilities('{Name}', 'Active__c = true', '{"schedulingType":"Facility"}', newFac.Id);
            Map<String, Object> responseJSON = (Map<String, Object>) json.deserializeUntyped(response.responseData);
            List<reduivy__Facility__c> resultFacilityList = (List<reduivy__Facility__c>) JSON.deserialize(JSON.serialize(responseJSON.get('facilities')), List<reduivy__Facility__c>.class);
            System.Assert.areEqual(facilityList.size() + 1, resultFacilityList.size(), 'Size is not the same');
            Boolean selectedFacilityMetDefaultCriteria = (Boolean) responseJSON.get('selectedFacilityMetDefaultCriteria');
            System.Assert.areEqual(false, selectedFacilityMetDefaultCriteria, 'Should be not matching the criteria');


            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for getStudySessionTimes
     */
    @IsTest
    static void testForAdminGetStudySessionTimes() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session__c sse = [
            SELECT Id, Name,(
                SELECT Id, Name
                FROM reduivy__Study_Session_Times__r
            )
            FROM reduivy__Study_Session__c
            WHERE Name LIKE '%Lecture%'
            LIMIT 1
        ];


		System.runAs(ADMIN_USER){
            Test.startTest();
            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudySessionTimes(sse.Id);
            System.Assert.areEqual(1, sse.reduivy__Study_Session_Times__r.size(), 'Wrong size');
            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as student for getStudySessionTimes
     */
	@IsTest
    static void testForStudentGetStudySessionTimes() {
        
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

        reduivy__Study_Session__c sse = [
            SELECT Id, Name,(
                SELECT Id, Name
                FROM reduivy__Study_Session_Times__r
            )
            FROM reduivy__Study_Session__c
            WHERE Name LIKE '%Lecture%'
            LIMIT 1
        ];


        // TO DO: implement unit test run as student
		System.runAs(studentUser){
            Test.startTest();
            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudySessionTimes(sse.Id);
            System.Assert.areEqual(1, sse.reduivy__Study_Session_Times__r.size(), 'Wrong size');
            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as faculty for xxx
     */
	@IsTest
    static void testForFacultyGetStudySessionTimes() {
		        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        reduivy__Study_Session__c sse = [
            SELECT Id, Name,(
                SELECT Id, Name
                FROM reduivy__Study_Session_Times__r
            )
            FROM reduivy__Study_Session__c
            WHERE Name LIKE '%Lecture%'
            LIMIT 1
        ];

        
        // TO DO: implement unit test run as faculty
		System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse response = REDU_SessionScheduler_LCTRL.getStudySessionTimes(sse.Id);
            System.Assert.areEqual(1, sse.reduivy__Study_Session_Times__r.size(), 'Wrong size');
            Test.stopTest();
		}
		
    }

    /**
     * @description Test get study sessions by filter as admin
     */
    @IsTest
    static void testForAdminGetStudySessionsByFilter() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Account eduInst = [SELECT Id from Account WHERE reduivy__Sample_Record_Code__c = :EDU_INST_SAMPLE_RECORD_CODE LIMIT 1];
        Account campus = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Term__c term = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c =: ACADEMIC_TERM_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c =: STUDY_UNIT_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Offering__c studyOffering = [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Sample_Record_Code__c =: STUDY_OFFERING_SAMPLE_RECORD_CODE LIMIT 1];
        
        
        Test.startTest();

        Datetime fromDate = (Datetime)System.today().toStartOfMonth();

        Datetime toDate = (Datetime)System.today().toStartOfMonth().addMonths(1).addDays(-1);
        REDU_SessionFilterValue_OBJ filterValue = (REDU_SessionFilterValue_OBJ) JSON.deserialize('{}', REDU_SessionFilterValue_OBJ.class);
        filterValue.educationalInstitutionId =eduInst.Id;
        filterValue.campusId = campus.Id;
        filterValue.studyUnitId = studyUnit.Id;
        filterValue.academicTermId = term.Id;
        filterValue.studyOfferingId = studyOffering.Id;

        List<reduivy__Study_Session__c> expectedStudySessions = [
            SELECT Id, 
            reduivy__Study_Offering__c,
            reduivy__Study_Offering__r.reduivy__Campus__c,
            reduivy__Study_Offering__r.reduivy__Campus__r.ParentId,
            reduivy__Study_Offering__r.reduivy__Study_Unit__c,
            reduivy__Study_Offering__r.reduivy__Academic_Term__c
            FROM reduivy__Study_Session__c
            WHERE Id IN (SELECT reduivy__Study_Session__c 
                FROM reduivy__Study_Session_Time__c 
                WHERE reduivy__Study_Session__r.reduivy__Study_Offering__c = :studyOffering.Id
                AND reduivy__Start_Date_Calculated__c < :toDate.date()
                AND reduivy__End_Date_Calculated__c >= :fromDate.date()
            )
        ];
        Map<Id, reduivy__Study_Session__c> expectedStudySessionsMap = new Map<Id, reduivy__Study_Session__c> (expectedStudySessions);



        String defaultCriteria = '';
        List<String> studySessionGroupByFields = new List<String> { 
            'Name','reduivy__Type__c','reduivy__Study_Offering__c'
        };
        List<String> sseAddonFields = new List<String> {
            'reduivy__Study_Offering__r.reduivy__Study_Unit__c',
            'reduivy__Study_Offering__r.reduivy__Academic_Term__c'
        };
        List<reduivy__Study_Session__c> actualStudySessions = null;
        System.runAs(ADMIN_USER) {
            actualStudySessions = REDU_SessionScheduler_UTIL.getStudySessionsByFilter(fromDate, toDate, filterValue, defaultCriteria, sseAddonFields,studySessionGroupByFields );
        }
        System.Assert.isNotNull(actualStudySessions, 'getStudySessionsByFilter should be called!');

        System.Assert.areEqual(expectedStudySessions.size(), actualStudySessions.size(), 'Study Session Size should be the same!');
        for(reduivy__Study_Session__c actualSse : actualStudySessions) {
            reduivy__Study_Session__c expectedStudySession = expectedStudySessionsMap.get(actualSse.Id);
            System.Assert.isNotNull(expectedStudySession, 'Expected Study Session should be found!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__c, actualSse.reduivy__Study_Offering__c, 'Study Offering should be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Campus__c, actualSse.reduivy__Study_Offering__r.reduivy__Campus__c, 'Campus should be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId, actualSse.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId, 'Edu Inst should be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Study_Unit__c, actualSse.reduivy__Study_Offering__r.reduivy__Study_Unit__c, 'Study Unitshould be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Academic_Term__c, actualSse.reduivy__Study_Offering__r.reduivy__Academic_Term__c, 'Academic Term should be the same!');
        }

        Test.stopTest();
    }

    
    /**
     * @description Test get study sessions by filter as admin with filtering session name
     */
    @IsTest
    static void testForAdminGetStudySessionsByFilterSessionFilterName() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Account eduInst = [SELECT Id from Account WHERE reduivy__Sample_Record_Code__c = :EDU_INST_SAMPLE_RECORD_CODE LIMIT 1];
        Account campus = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Term__c term = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c =: ACADEMIC_TERM_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c =: STUDY_UNIT_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Offering__c studyOffering = [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Sample_Record_Code__c =: STUDY_OFFERING_SAMPLE_RECORD_CODE LIMIT 1];
        
        
        Test.startTest();

        Datetime fromDate = (Datetime)System.today().toStartOfMonth();

        Datetime toDate = (Datetime)System.today().toStartOfMonth().addMonths(1).addDays(-1);
        String filterValueString = '{ "sessionFilter": [{"targetSoapFieldType": "STRING","targetObjectType": "reduivy__Study_Session__c","targetFieldType": "STRING","targetFieldName": "Name","targetFieldBinder": "Name LIKE: Name","sourceSobj": {"attributes": {"type": "reduivy__Study_Session__c"},"Name": "BUS"},"sourceFieldName": "Name","showFilter": true,"seq": 0,"picklistOptions": null,"mapping": "Name=Name","lwcReactor": null,"label": "Study Session Name"}]}';
        REDU_SessionFilterValue_OBJ filterValue = (REDU_SessionFilterValue_OBJ) JSON.deserialize(filterValueString, REDU_SessionFilterValue_OBJ.class);

        List<reduivy__Study_Session__c> expectedStudySessions = [
            SELECT Id, 
            Name,
            reduivy__Study_Offering__c,
            reduivy__Study_Offering__r.reduivy__Campus__c,
            reduivy__Study_Offering__r.reduivy__Campus__r.ParentId,
            reduivy__Study_Offering__r.reduivy__Study_Unit__c,
            reduivy__Study_Offering__r.reduivy__Academic_Term__c
            FROM reduivy__Study_Session__c
            WHERE Id IN (SELECT reduivy__Study_Session__c 
                FROM reduivy__Study_Session_Time__c 
                WHERE reduivy__Start_Date_Calculated__c < :toDate.date()
                AND reduivy__End_Date_Calculated__c >= :fromDate.date()
            )
            AND Name LIKE 'BUS%'
        ];
        Map<Id, reduivy__Study_Session__c> expectedStudySessionsMap = new Map<Id, reduivy__Study_Session__c> (expectedStudySessions);



        String defaultCriteria = '';
        List<String> studySessionGroupByFields = new List<String> { 
            'Name','reduivy__Type__c','reduivy__Study_Offering__c'
        };
        List<String> sseAddonFields = new List<String> {
            'reduivy__Study_Offering__r.reduivy__Study_Unit__c',
            'reduivy__Study_Offering__r.reduivy__Academic_Term__c'
        };
        List<reduivy__Study_Session__c> actualStudySessions = null;
        System.runAs(ADMIN_USER) {
            actualStudySessions = REDU_SessionScheduler_UTIL.getStudySessionsByFilter(fromDate, toDate, filterValue, defaultCriteria, sseAddonFields,studySessionGroupByFields );
        }
        System.Assert.isNotNull(actualStudySessions, 'getStudySessionsByFilter should be called!');

        System.Assert.areEqual(expectedStudySessions.size(), actualStudySessions.size(), 'Study Session Size should be the same!');
        for(reduivy__Study_Session__c actualSse : actualStudySessions) {
            reduivy__Study_Session__c expectedStudySession = expectedStudySessionsMap.get(actualSse.Id);
            System.Assert.isNotNull(expectedStudySession, 'Expected Study Session should be found!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__c, actualSse.reduivy__Study_Offering__c, 'Study Offering should be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Campus__c, actualSse.reduivy__Study_Offering__r.reduivy__Campus__c, 'Campus should be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId, actualSse.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId, 'Edu Inst should be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Study_Unit__c, actualSse.reduivy__Study_Offering__r.reduivy__Study_Unit__c, 'Study Unitshould be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Academic_Term__c, actualSse.reduivy__Study_Offering__r.reduivy__Academic_Term__c, 'Academic Term should be the same!');
        }

        Test.stopTest();
    }

      /**
     * @description Test get study sessions by filter as admin with filtering session type
     */
    @IsTest
    static void testForAdminGetStudySessionsByFilterSessionFilterType() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Account eduInst = [SELECT Id from Account WHERE reduivy__Sample_Record_Code__c = :EDU_INST_SAMPLE_RECORD_CODE LIMIT 1];
        Account campus = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Term__c term = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c =: ACADEMIC_TERM_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c =: STUDY_UNIT_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Offering__c studyOffering = [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Sample_Record_Code__c =: STUDY_OFFERING_SAMPLE_RECORD_CODE LIMIT 1];
        
        
        Test.startTest();

        Datetime fromDate = (Datetime)System.today().toStartOfMonth();

        Datetime toDate = (Datetime)System.today().toStartOfMonth().addMonths(1).addDays(-1);
        String filterValueString = '{"sessionFilter":[{"targetSoapFieldType":"STRING","targetObjectType":"reduivy__Study_Session__c","targetFieldType":"STRING","targetFieldName":"Name","targetFieldBinder":"Name LIKE: Name","sourceSobj":{"attributes":{"type":"reduivy__Study_Session__c"}},"sourceFieldName":"Name","showFilter":true,"seq":0,"picklistOptions":null,"mapping":"Name=Name","lwcReactor":null,"label":"Study Session Name"},{"targetSoapFieldType":"STRING","targetObjectType":"reduivy__Study_Session__c","targetFieldType":"PICKLIST","targetFieldName":"reduivy__Type__c","targetFieldBinder":"reduivy__Type__c IN: reduivy__Type__c","sourceSobj":{"attributes":{"type":"reduivy__Study_Session__c"},"reduivy__Type__c":"Lecture"},"sourceFieldName":"reduivy__Type__c","showFilter":true,"seq":1,"picklistOptions":[{"value":"Exam","selected":false,"label":"Exam","id":"Exam","childOptions":[]},{"value":"Lecture","selected":false,"label":"Lecture","id":"Lecture","childOptions":[]},{"value":"Tutorial","selected":false,"label":"Tutorial","id":"Tutorial","childOptions":[]},{"value":"Workshop","selected":false,"label":"Workshop","id":"Workshop","childOptions":[]}],"mapping":"reduivy__Type__c=reduivy__Type__c","lwcReactor":null,"label":"Type"},{"targetSoapFieldType":"DOUBLE","targetObjectType":"reduivy__Study_Session__c","targetFieldType":"DOUBLE","targetFieldName":"reduivy__Capacity__c","targetFieldBinder":"reduivy__Capacity__c =: reduivy__Capacity__c","sourceSobj":{"attributes":{"type":"reduivy__Study_Session__c"}},"sourceFieldName":"reduivy__Capacity__c","showFilter":true,"seq":2,"picklistOptions":null,"mapping":"reduivy__Capacity__c=reduivy__Capacity__c","lwcReactor":null,"label":"Capacity"}]}';
        REDU_SessionFilterValue_OBJ filterValue = (REDU_SessionFilterValue_OBJ) JSON.deserialize(filterValueString, REDU_SessionFilterValue_OBJ.class);

        List<reduivy__Study_Session__c> expectedStudySessions = [
            SELECT Id, 
            Name,
            reduivy__Study_Offering__c,
            reduivy__Study_Offering__r.reduivy__Campus__c,
            reduivy__Study_Offering__r.reduivy__Campus__r.ParentId,
            reduivy__Study_Offering__r.reduivy__Study_Unit__c,
            reduivy__Study_Offering__r.reduivy__Academic_Term__c
            FROM reduivy__Study_Session__c
            WHERE Id IN (SELECT reduivy__Study_Session__c 
                FROM reduivy__Study_Session_Time__c 
                WHERE reduivy__Start_Date_Calculated__c < :toDate.date()
                AND reduivy__End_Date_Calculated__c >= :fromDate.date()
            )
            AND reduivy__Type__c IN ('Lecture')
        ];
        Map<Id, reduivy__Study_Session__c> expectedStudySessionsMap = new Map<Id, reduivy__Study_Session__c> (expectedStudySessions);



        String defaultCriteria = '';
        List<String> studySessionGroupByFields = new List<String> { 
            'Name','reduivy__Type__c','reduivy__Study_Offering__c'
        };
        List<String> sseAddonFields = new List<String> {
            'reduivy__Study_Offering__r.reduivy__Study_Unit__c',
            'reduivy__Study_Offering__r.reduivy__Academic_Term__c'
        };
        List<reduivy__Study_Session__c> actualStudySessions = null;
        System.runAs(ADMIN_USER) {
            actualStudySessions = REDU_SessionScheduler_UTIL.getStudySessionsByFilter(fromDate, toDate, filterValue, defaultCriteria, sseAddonFields,studySessionGroupByFields );
        }
        System.Assert.isNotNull(actualStudySessions, 'getStudySessionsByFilter should be called!');

        System.Assert.areEqual(expectedStudySessions.size(), actualStudySessions.size(), 'Study Session Size should be the same!');
        for(reduivy__Study_Session__c actualSse : actualStudySessions) {
            reduivy__Study_Session__c expectedStudySession = expectedStudySessionsMap.get(actualSse.Id);
            System.Assert.isNotNull(expectedStudySession, 'Expected Study Session should be found!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__c, actualSse.reduivy__Study_Offering__c, 'Study Offering should be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Campus__c, actualSse.reduivy__Study_Offering__r.reduivy__Campus__c, 'Campus should be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId, actualSse.reduivy__Study_Offering__r.reduivy__Campus__r.ParentId, 'Edu Inst should be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Study_Unit__c, actualSse.reduivy__Study_Offering__r.reduivy__Study_Unit__c, 'Study Unitshould be the same!');
            System.Assert.areEqual(expectedStudySession.reduivy__Study_Offering__r.reduivy__Academic_Term__c, actualSse.reduivy__Study_Offering__r.reduivy__Academic_Term__c, 'Academic Term should be the same!');
        }

        Test.stopTest();
    }

    
    @IsTest
    static void testForFacultyGetStudySessionsByFilter() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Account eduInst = [SELECT Id from Account WHERE reduivy__Sample_Record_Code__c = :EDU_INST_SAMPLE_RECORD_CODE LIMIT 1];
        Account campus = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Term__c term = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c =: ACADEMIC_TERM_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c =: STUDY_UNIT_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Offering__c studyOffering = [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Sample_Record_Code__c =: STUDY_OFFERING_SAMPLE_RECORD_CODE LIMIT 1];
        
        
        Test.startTest();

        Datetime fromDate = (Datetime)System.today().toStartOfMonth();

        Datetime toDate = (Datetime)System.today().toStartOfMonth().addMonths(1).addDays(-1);
        REDU_SessionFilterValue_OBJ filterValue = (REDU_SessionFilterValue_OBJ) JSON.deserialize('{}', REDU_SessionFilterValue_OBJ.class);
        filterValue.educationalInstitutionId =eduInst.Id;
        filterValue.campusId = campus.Id;
        filterValue.studyUnitId = studyUnit.Id;
        filterValue.academicTermId = term.Id;
        filterValue.studyOfferingId = studyOffering.Id;

        List<reduivy__Study_Session__c> expectedStudySessions = [
            SELECT Id, 
            reduivy__Study_Offering__c,
            reduivy__Study_Offering__r.reduivy__Campus__c,
            reduivy__Study_Offering__r.reduivy__Campus__r.ParentId,
            reduivy__Study_Offering__r.reduivy__Study_Unit__c,
            reduivy__Study_Offering__r.reduivy__Academic_Term__c
            FROM reduivy__Study_Session__c
            WHERE Id IN (SELECT reduivy__Study_Session__c 
                FROM reduivy__Study_Session_Time__c 
                WHERE reduivy__Study_Session__r.reduivy__Study_Offering__c = :studyOffering.Id
                AND reduivy__Start_Date_Calculated__c < :toDate.date()
                AND reduivy__End_Date_Calculated__c >= :fromDate.date()
            )
        ];
        Map<Id, reduivy__Study_Session__c> expectedStudySessionsMap = new Map<Id, reduivy__Study_Session__c> (expectedStudySessions);



        String defaultCriteria = '';
        List<String> studySessionGroupByFields = new List<String> { 
            'Name','reduivy__Type__c','reduivy__Study_Offering__c'
        };

        List<String> sseAddonFields = new List<String> {
            'reduivy__Study_Offering__r.reduivy__Study_Unit__c',
            'reduivy__Study_Offering__r.reduivy__Academic_Term__c'
        };
        List<reduivy__Study_Session__c> actualStudySessions = null;
        System.runAs(FACULTY_USER) {
            try{
                actualStudySessions = REDU_SessionScheduler_UTIL.getStudySessionsByFilter(fromDate, toDate, filterValue, defaultCriteria, sseAddonFields,studySessionGroupByFields );
                System.Assert.fail('Should be failed when getting study event generation status!');
            } catch (Exception exp) {

            }
        }
        Test.stopTest();
    }    

    @IsTest
    static void testForStudentGetStudySessionsByFilter() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Account eduInst = [SELECT Id from Account WHERE reduivy__Sample_Record_Code__c = :EDU_INST_SAMPLE_RECORD_CODE LIMIT 1];
        Account campus = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = :CAMPUS_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Term__c term = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Sample_Record_Code__c =: ACADEMIC_TERM_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Unit__c studyUnit = [SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c =: STUDY_UNIT_SAMPLE_RECORD_CODE LIMIT 1];
        reduivy__Study_Offering__c studyOffering = [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Sample_Record_Code__c =: STUDY_OFFERING_SAMPLE_RECORD_CODE LIMIT 1];
        
        
        Test.startTest();

        Datetime fromDate = (Datetime)System.today().toStartOfMonth();

        Datetime toDate = (Datetime)System.today().toStartOfMonth().addMonths(1).addDays(-1);
        REDU_SessionFilterValue_OBJ filterValue = (REDU_SessionFilterValue_OBJ) JSON.deserialize('{}', REDU_SessionFilterValue_OBJ.class);
        filterValue.educationalInstitutionId =eduInst.Id;
        filterValue.campusId = campus.Id;
        filterValue.studyUnitId = studyUnit.Id;
        filterValue.academicTermId = term.Id;
        filterValue.studyOfferingId = studyOffering.Id;

        List<reduivy__Study_Session__c> expectedStudySessions = [
            SELECT Id, 
            reduivy__Study_Offering__c,
            reduivy__Study_Offering__r.reduivy__Campus__c,
            reduivy__Study_Offering__r.reduivy__Campus__r.ParentId,
            reduivy__Study_Offering__r.reduivy__Study_Unit__c,
            reduivy__Study_Offering__r.reduivy__Academic_Term__c
            FROM reduivy__Study_Session__c
            WHERE Id IN (SELECT reduivy__Study_Session__c 
                FROM reduivy__Study_Session_Time__c 
                WHERE reduivy__Study_Session__r.reduivy__Study_Offering__c = :studyOffering.Id
                AND reduivy__Start_Date_Calculated__c < :toDate.date()
                AND reduivy__End_Date_Calculated__c >= :fromDate.date()
            )
        ];
        Map<Id, reduivy__Study_Session__c> expectedStudySessionsMap = new Map<Id, reduivy__Study_Session__c> (expectedStudySessions);



        String defaultCriteria = '';
        List<String> studySessionGroupByFields = new List<String> { 
            'Name','reduivy__Type__c','reduivy__Study_Offering__c'
        };

        List<String> sseAddonFields = new List<String> {
            'reduivy__Study_Offering__r.reduivy__Study_Unit__c',
            'reduivy__Study_Offering__r.reduivy__Academic_Term__c'
        };
        List<reduivy__Study_Session__c> actualStudySessions = null;
        System.runAs(FACULTY_USER) {
            try{
                actualStudySessions = REDU_SessionScheduler_UTIL.getStudySessionsByFilter(fromDate, toDate, filterValue, defaultCriteria, sseAddonFields,studySessionGroupByFields );
                System.Assert.fail('Should be failed when getting study event generation status!');
            } catch (Exception exp) {

            }
        }
       
        Test.stopTest();
    }

    private class StudySessionWrapper {
        Map<String, List<reduivy__Study_Session_Time__c>> sessionTimes;
        Map<String, List<reduivy__Study_Event__c>> sessionStudyEvents;
        List<reduivy__Study_Session__c> sessions;


    }


    




    
}