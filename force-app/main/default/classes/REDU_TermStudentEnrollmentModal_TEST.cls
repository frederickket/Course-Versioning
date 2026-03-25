/**
 * @author      WDCi (XiRouh)
 * @date        Feb 2025
 * @group       Term Student Enrollment
 * @description Test class for REDU_TermStudentEnrollmentModal_LCTRL
 * @changehistory
 * ISS-002229 14-02-2025 XiRouh - new class
 * ISS-002547 16-07-2025 Lean - Change to use job queue group
 */
@isTest
public inherited sharing class REDU_TermStudentEnrollmentModal_TEST {

    private static final String JOB_OPERATION = 'Term_Student_Enrollment';

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
    static final String SPL_MAJOR = 'BACBIS_MajorA';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_CYINTAKE';

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
            testFactory.FULLDATA = true;
            testFactory.initMasterData(null);
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(IAC_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> masterIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

            for (Contact student : testFactory.students.values()) {
                String masterIpekey = student.reduivy__Sample_Record_Code__c + '_' + SPL_MAJOR;

                reduivy__Individual_Program_Enrollment__c newMasterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    masterIpekey, 
                    student.Id, 
                    testFactory.studyPlans.get(SPL_MAJOR).reduivy__Study_Program__c, 
                    testFactory.studyPlans.get(SPL_MAJOR).Id, 
                    testFactory.studyIntakes.get(STUDY_INTAKE).Id, 
                    testFactory.academicTerms.get('CYT1').Id, 
                    testFactory.studyIntakes.get(STUDY_INTAKE).reduivy__Default_Study_Pathway__c, 
                    testFactory.campuses.get('SYDNEY').Id, 
                    String.valueOf(testFactory.academicTerms.get('CYT1').reduivy__Start_Date__c.year()), 
                    'Freshman', 
                    true, 
                    IPE_INPROGRESS_STATUS, 
                    null
                );

                masterIpeList.add(newMasterIpe);
            }

            //To set sequence for each contact
            REDU_SystemMode_UTIL.doUpdate(testFactory.students.values());
            REDU_SystemMode_UTIL.doInsert(masterIpeList);

            List<reduivy__Individual_Program_Enrollment__c> ipes = [SELECT Id, (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) FROM reduivy__Individual_Program_Enrollment__c ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC];
            List<reduivy__Individual_Pathway__c> ipwsToBeUpdated = new List<reduivy__Individual_Pathway__c>();
            List<reduivy__Individual_Pathway__c> ipwsToBeDeleted = new List<reduivy__Individual_Pathway__c>();
            List<reduivy__Individual_Program_Enrollment__c> ipesToBeUpdated = new List<reduivy__Individual_Program_Enrollment__c>();

            Id pastAcademicTermId = testFactory.academicTerms.get('CYT1').Id;
            Id toBeEnrolledTermId = testFactory.academicTerms.get('CYT2').Id;
            Id randomTermId = testFactory.academicTerms.get('PYT1').Id;

            //Setup ipr to cover each scenario (Total 12 scenario + IPW_Enrolled_And_Completed_In_New_Term_Error have to test seperately due to have to change the study term date)
            for(Integer i = 0; i < 13; i++) {
                reduivy__Individual_Program_Enrollment__c ipe = ipes[i];

                ipesToBeUpdated.add(new reduivy__Individual_Program_Enrollment__c(Id = ipe.Id, reduivy__Auto_Enrollment__c = IPE_Helper.AUTO_ENROLLMENT_AUTO));
                for(reduivy__Individual_Pathway__c ipw : ipe.reduivy__Individual_Pathways__r) {

                    if(i == 0) {
                        //Multiple_IPWs_Enrolled_In_Current_Term_Error
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = pastAcademicTermId));
                        }

                        if(ipw.reduivy__Term_Number__c == 2) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = pastAcademicTermId));
                        }
                    }

                    if(i == 1) {
                        //Multiple_IPWs_Enrolled_In_New_Term_Error
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = toBeEnrolledTermId));
                        }

                        if(ipw.reduivy__Term_Number__c == 2) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = toBeEnrolledTermId));
                        }
                    }

                    if(i == 2) {
                        //IPW_Not_Found_In_Selected_Terms_But_Enrolled_Elsewhere_Error
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = null, reduivy__Individual_Academic_Progress__c = null));
                        }

                        if(ipw.reduivy__Term_Number__c == 2) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = randomTermId));
                        }
                    }

                    if(i == 3) {
                        //Term_Not_Found_Or_Already_Enrolled_Error
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = randomTermId));
                        }
                    }

                    if(i == 4) {
                        //IPW_Subsequent_Enrollment_Mismatch_Error (processScenario2)
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = toBeEnrolledTermId));
                        }

                        if(ipw.reduivy__Term_Number__c == 2) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = randomTermId));
                        }
                    }

                    if(i == 5) {
                        //IPW_Not_Found_In_Current_And_Not_IPW_1_In_Enrolled_Term_Error
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = null, reduivy__Individual_Academic_Progress__c = null));
                        }

                        if(ipw.reduivy__Term_Number__c == 2) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = toBeEnrolledTermId));
                        }
                    }

                    if(i == 6) {
                        //IPW_Subsequent_Enrollment_Mismatch_Error (processScenario3)
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = pastAcademicTermId));
                        }

                        if(ipw.reduivy__Term_Number__c == 2) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = randomTermId));
                        }
                    }

                    if(i == 7) {
                        //IPW_Terms_Not_Subsequential_Error
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = pastAcademicTermId));
                        }

                        if(ipw.reduivy__Term_Number__c == 2) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = randomTermId));
                        }

                        if(ipw.reduivy__Term_Number__c == 3) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = toBeEnrolledTermId));
                        }
                    }

                    if(i == 8) {
                        //No ipw at all
                        ipwsToBeDeleted.add(ipw);
                    }

                    if(i == 9) {
                        //Eligible for unit enrollment only
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = toBeEnrolledTermId));
                        }
                    }

                    if(i == 10) {
                        //Eligible for both term and unit enrollment (processScenario3)
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = pastAcademicTermId));
                        }
                    }

                    if(i == 11) {
                        //Eligible for both term and unit enrollment (processScenario1)
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = null));
                        }
                    }

                    if(i == 12) {
                        //Eligible for unit enrollment only (processScenario4)
                        if(ipw.reduivy__Term_Number__c == 1) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = pastAcademicTermId));
                        }

                        if(ipw.reduivy__Term_Number__c == 2) {
                            ipwsToBeUpdated.add(new reduivy__Individual_Pathway__c(Id = ipw.Id, reduivy__Academic_Term__c = toBeEnrolledTermId));
                        }
                    }
                }
            }

            REDU_SystemMode_UTIL.doUpdate(ipesToBeUpdated);
            REDU_SystemMode_UTIL.doUpdate(ipwsToBeUpdated);
            REDU_SystemMode_UTIL.doDelete(ipwsToBeDeleted);
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getStudyTermDetails() as admin
     */
    @IsTest
    static void testgetStudyTermDetailsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
    
        System.runAs(ADMIN_USER) {
            List<reduivy__Study_Term__c> studyTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, String> returnedMap = (Map<String, String>) JSON.deserialize(response.responseData, Map<String, String>.class);
            
            System.Assert.isTrue(returnedMap.containsKey('studyTermName'), 'ReturnedMap map should contain studyTermName key');
            System.Assert.isTrue(returnedMap.containsKey('academicYearName'), 'ReturnedMap map should contain academicYearName key');
            System.Assert.isTrue(returnedMap.containsKey('eduInstitutionId'), 'ReturnedMap map should contain eduInstitutionId key');

            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermName')), 'studyTermName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('academicYearName')), 'academicYearName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('eduInstitutionId')), 'eduInstitutionId should not be blank');
        }

        Test.stopTest();
    }

    /**
     * @description Test getStudyTermDetails() as faculty
     */
    @IsTest
    static void testgetStudyTermDetailsAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
    
        Test.startTest();
        
        System.runAs(FACULTY_USER) {

            List<reduivy__Study_Term__c> studyTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, String> returnedMap = (Map<String, String>) JSON.deserialize(response.responseData, Map<String, String>.class);
            
            System.Assert.isTrue(returnedMap.containsKey('studyTermName'), 'ReturnedMap map should contain studyTermName key');
            System.Assert.isTrue(returnedMap.containsKey('academicYearName'), 'ReturnedMap map should contain academicYearName key');
            System.Assert.isTrue(returnedMap.containsKey('eduInstitutionId'), 'ReturnedMap map should contain eduInstitutionId key');

            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermName')), 'studyTermName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('academicYearName')), 'academicYearName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('eduInstitutionId')), 'eduInstitutionId should not be blank');
        }

        Test.stopTest();
    }

    /**
     * @description Test getStudyTermDetails() as student
     */
    @IsTest
    static void testgetStudyTermDetailsAsStudent(){
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
    
        Test.startTest();
        
        System.runAs(reduStudent) {

            List<reduivy__Study_Term__c> studyTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, String> returnedMap = (Map<String, String>) JSON.deserialize(response.responseData, Map<String, String>.class);
            
            System.Assert.isTrue(returnedMap.containsKey('studyTermName'), 'ReturnedMap map should contain studyTermName key');
            System.Assert.isTrue(returnedMap.containsKey('academicYearName'), 'ReturnedMap map should contain academicYearName key');
            System.Assert.isTrue(returnedMap.containsKey('eduInstitutionId'), 'ReturnedMap map should contain eduInstitutionId key');

            System.Assert.isFalse(String.isBlank(returnedMap.get('studyTermName')), 'studyTermName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('academicYearName')), 'academicYearName should not be blank');
            System.Assert.isFalse(String.isBlank(returnedMap.get('eduInstitutionId')), 'eduInstitutionId should not be blank');
        }

        Test.stopTest();
    }

     /**
     * @description Negative Test for getStudyTermDetails()
     */
    @IsTest
    static void testgetStudyTermDetailsWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();


        System.runAs(ADMIN_USER) {
            Test.startTest();

            List<reduivy__Study_Term__c> studyTerm = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicYearRecordTypeId() LIMIT 1];
            
            // Test with blank study term id
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.getStudyTermDetails(null);
                System.Assert.fail('Expected an AuraHandledException for blank study Term ID');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'studyTermRecordId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            // Test with academic year
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.getStudyTermDetails(studyTerm[0].Id);
                System.Assert.fail('Expected an AuraHandledException for academic year Id');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Invalid_Record_Id_For_Object_Type,
                new List<String>{studyTerm[0].Id, STM_Helper.getAcademicTermRecordTypeLabel()})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getComboboxOptions() as admin
     */
    @IsTest
    static void testgetComboboxOptionsAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            List<Account> eduInstitutionId = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getEducationalInstitutionRecordTypeId()];
            List<reduivy__Study_Term__c> currentTermId = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId() LIMIT 1];

            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getComboboxOptions(eduInstitutionId[0].Id, currentTermId[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            
            Map<String, Object> optionsMap = 
            (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(optionsMap.containsKey('term'), 'Options map should contain term key');
            System.Assert.isTrue(optionsMap.containsKey('campus'), 'Options map should contain campus key');
            System.Assert.isTrue(optionsMap.containsKey('studyProgram'), 'Options map should contain Study Program key');

            System.Assert.isFalse(((List<Object>) optionsMap.get('term')).isEmpty(), 'term options should not be empty');
            System.Assert.isFalse(((List<Object>) optionsMap.get('campus')).isEmpty(), 'campus options should not be empty');
            System.Assert.isFalse(((List<Object>) optionsMap.get('studyProgram')).isEmpty(), 'Study Program options should not be empty');

            System.Assert.isFalse(((List<Object>) optionsMap.get('term')).contains(currentTermId[0].Id), 'term options should not contains current term id');
        }

        Test.stopTest();
    }

    /**
     * @description Test getComboboxOptions() as faculty
     */
    @IsTest
    static void testgetComboboxOptionsAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();
    
        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            List<Account> eduInstitutionId = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getEducationalInstitutionRecordTypeId()];
            List<reduivy__Study_Term__c> currentTermId = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicYearRecordTypeId() LIMIT 1];

            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getComboboxOptions(eduInstitutionId[0].Id, currentTermId[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            
            Map<String, Object> optionsMap = 
            (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(optionsMap.containsKey('term'), 'Options map should contain term key');
            System.Assert.isTrue(optionsMap.containsKey('campus'), 'Options map should contain campus key');
            System.Assert.isTrue(optionsMap.containsKey('studyProgram'), 'Options map should contain Study Program key');

            System.Assert.isFalse(((List<Object>) optionsMap.get('term')).isEmpty(), 'term options should not be empty');
            System.Assert.isFalse(((List<Object>) optionsMap.get('campus')).isEmpty(), 'campus options should not be empty');
            System.Assert.isFalse(((List<Object>) optionsMap.get('studyProgram')).isEmpty(), 'Study Program options should not be empty');

            System.Assert.isFalse(((List<Object>) optionsMap.get('term')).contains(currentTermId[0].Id), 'term options should not contains current term id');
        }

        Test.stopTest();
    }

    /**
     * @description Test getComboboxOptions() as student
     */
    @IsTest
    static void testgetComboboxOptionsAsStudent(){
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
    
        Test.startTest();
        
        System.runAs(reduStudent) {
            List<Account> eduInstitutionId = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getEducationalInstitutionRecordTypeId()];
            List<reduivy__Study_Term__c> currentTermId = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicYearRecordTypeId() LIMIT 1];

            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getComboboxOptions(eduInstitutionId[0].Id, currentTermId[0].Id);

            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            
            Map<String, Object> optionsMap = 
            (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

            System.Assert.isTrue(optionsMap.containsKey('term'), 'Options map should contain term key');
            System.Assert.isTrue(optionsMap.containsKey('campus'), 'Options map should contain campus key');
            System.Assert.isTrue(optionsMap.containsKey('studyProgram'), 'Options map should contain Study Program key');

            System.Assert.isFalse(((List<Object>) optionsMap.get('term')).isEmpty(), 'term options should not be empty');
            System.Assert.isFalse(((List<Object>) optionsMap.get('campus')).isEmpty(), 'campus options should not be empty');
            System.Assert.isFalse(((List<Object>) optionsMap.get('studyProgram')).isEmpty(), 'Study Program options should not be empty');
        
            System.Assert.isFalse(((List<Object>) optionsMap.get('term')).contains(currentTermId[0].Id), 'term options should not contains current term id');
        }

        Test.stopTest();
    }

     /**
     * @description Negative Test for getComboboxOptions()
     */
    @IsTest
    static void testgetComboboxOptionsWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            List<Account> eduInstitutionId = [SELECT Id FROM Account WHERE RecordTypeId = :ACC_Helper.getEducationalInstitutionRecordTypeId()];
            List<reduivy__Study_Term__c> currentTermId = [SELECT Id FROM reduivy__Study_Term__c WHERE RecordTypeId = :STM_Helper.getAcademicYearRecordTypeId() LIMIT 1];

            //Test for null eduInstitutionId
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.getComboboxOptions(null, currentTermId[0].Id);
                System.Assert.fail('Expected an AuraHandledException for blank eduInstitutionId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(Label.Educational_Institution_Id_Not_Found), 
                                    'Unexpected error: ' + e.getMessage());
            }

            //Test for null currentTermId
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.getComboboxOptions(eduInstitutionId[0].Id, null);
                System.Assert.fail('Expected an AuraHandledException for blank eduInstitutionId');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'currentTermId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test getStudyIntakes() as admin
     */
    @IsTest
    static void testgetStudyIntakesAsAdmin(){
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        List<reduivy__Individual_Program_Enrollment__c> ipe = [SELECT Id, reduivy__Default_Campus__c, reduivy__Study_Program__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
        String studyIntakeSelectionTableFields = 'Name;reduivy__Study_Program__r.Name';
    
        System.runAs(ADMIN_USER) {
            Test.startTest();
    
            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getStudyIntakes(ipe[0].reduivy__Study_Program__c, ipe[0].reduivy__Default_Campus__c, studyIntakeSelectionTableFields, UserInfo.getLanguage(), true);
            
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(responseMap.containsKey(REDU_Datatable_UTIL.COLUMNS_PARAM), 'Response should contain columns');
            System.Assert.isTrue(responseMap.containsKey(REDU_Datatable_UTIL.RECORDS_PARAM), 'Response should contain records');
            System.Assert.isTrue(responseMap.containsKey(REDU_Datatable_UTIL.REFLINKS_PARAM), 'Response should contain reference links');
            
            List<Object> columns = (List<Object>) responseMap.get(REDU_Datatable_UTIL.COLUMNS_PARAM);
            System.Assert.areEqual(2, columns.size(), 'Column map should contain 2 entries');
    
            List<Object> records = (List<Object>) responseMap.get(REDU_Datatable_UTIL.RECORDS_PARAM);
            if (!records.isEmpty()) {
                Map<String, Object> firstRecord = (Map<String, Object>) records[0];
                System.Assert.isTrue(firstRecord.containsKey('Id'), 'Data row should have an Id');
            }
    
            Test.stopTest();
        }  
    }

    /**
     * @description Test getStudyIntakes() as faculty
     */
    @IsTest
    static void testgetStudyIntakesAsFaculty(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<reduivy__Individual_Program_Enrollment__c> ipe = [SELECT Id, reduivy__Default_Campus__c, reduivy__Study_Program__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];

        String studyIntakeSelectionTableFields = 'Name;reduivy__Study_Program__r.Name';

        System.runAs(FACULTY_USER) {
            Test.startTest();

            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getStudyIntakes(ipe[0].reduivy__Study_Program__c, ipe[0].reduivy__Default_Campus__c, studyIntakeSelectionTableFields, UserInfo.getLanguage(), true);
            
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(responseMap.containsKey(REDU_Datatable_UTIL.COLUMNS_PARAM), 'Response should contain columns');
            System.Assert.isTrue(responseMap.containsKey(REDU_Datatable_UTIL.RECORDS_PARAM), 'Response should contain records');
            System.Assert.isTrue(responseMap.containsKey(REDU_Datatable_UTIL.REFLINKS_PARAM), 'Response should contain reference links');
            
            List<Object> columns = (List<Object>) responseMap.get(REDU_Datatable_UTIL.COLUMNS_PARAM);
            System.Assert.areEqual(2, columns.size(), 'Column map should contain 2 entries');
    
            List<Object> records = (List<Object>) responseMap.get(REDU_Datatable_UTIL.RECORDS_PARAM);
            if (!records.isEmpty()) {
                Map<String, Object> firstRecord = (Map<String, Object>) records[0];
                System.Assert.isTrue(firstRecord.containsKey('Id'), 'Data row should have an Id');
            }

            Test.stopTest();
        }  
    }

    /**
     * @description Test getStudyIntakes() as student
     */
    @IsTest
    static void testgetStudyIntakesAsStudent(){
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Individual_Program_Enrollment__c> ipe = [SELECT Id, reduivy__Default_Campus__c, reduivy__Study_Program__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];

        String studyIntakeSelectionTableFields = 'Name;reduivy__Study_Program__r.Name';

        System.runAs(reduStudent) {
            Test.startTest();

            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getStudyIntakes(ipe[0].reduivy__Study_Program__c, ipe[0].reduivy__Default_Campus__c, studyIntakeSelectionTableFields, UserInfo.getLanguage(), true);
            
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            System.Assert.isTrue(responseMap.containsKey(REDU_Datatable_UTIL.COLUMNS_PARAM), 'Response should contain columns');
            System.Assert.isTrue(responseMap.containsKey(REDU_Datatable_UTIL.RECORDS_PARAM), 'Response should contain records');
            System.Assert.isTrue(responseMap.containsKey(REDU_Datatable_UTIL.REFLINKS_PARAM), 'Response should contain reference links');
            
            List<Object> columns = (List<Object>) responseMap.get(REDU_Datatable_UTIL.COLUMNS_PARAM);
            System.Assert.areEqual(2, columns.size(), 'Column map should contain 2 entries');
    
            List<Object> records = (List<Object>) responseMap.get(REDU_Datatable_UTIL.RECORDS_PARAM);
            if (!records.isEmpty()) {
                Map<String, Object> firstRecord = (Map<String, Object>) records[0];
                System.Assert.isTrue(firstRecord.containsKey('Id'), 'Data row should have an Id');
            }

            Test.stopTest();
        }  
    }

    /**
     * @description Negative Test for getStudyIntakes()
     */
    @IsTest
    static void testgetStudyIntakesWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Individual_Program_Enrollment__c> ipe = [SELECT Id, reduivy__Default_Campus__c, reduivy__Study_Program__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];

        String studyIntakeSelectionTableFields = 'Name;reduivy__Study_Program__r.Name';

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Test with blank selectedStudyProgramId
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.getStudyIntakes(null, ipe[0].reduivy__Default_Campus__c, studyIntakeSelectionTableFields, UserInfo.getLanguage(), true);
                System.Assert.fail('Expected an AuraHandledException for blank Academic Term ID');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedStudyProgramId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            // Test with blank Campus ID
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.getStudyIntakes(ipe[0].reduivy__Study_Program__c, null, studyIntakeSelectionTableFields, UserInfo.getLanguage(), true);
                System.Assert.fail('Expected an AuraHandledException for blank Campus ID');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedCampusId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            // Test with both IDs blank
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.getStudyIntakes(null, null, studyIntakeSelectionTableFields, UserInfo.getLanguage(), true);
                System.Assert.fail('Expected an AuraHandledException for both blank IDs');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedStudyProgramId'})), 
                                    'Unexpected error: ' + e.getMessage());
            }

            // Test with studyIntakeFields blank
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.getStudyIntakes(ipe[0].reduivy__Study_Program__c, ipe[0].reduivy__Default_Campus__c, null, UserInfo.getLanguage(), true);
                System.Assert.fail('Expected an AuraHandledException for both blank IDs');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters,
                new List<String>{'studyIntakeSelectionTableFields'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test for getTermEnrollmentRecords() as admin
     */
    @IsTest
    static void testgetTermEnrollmentRecordsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Individual_Program_Enrollment__c> ipe = [SELECT Id, reduivy__Default_Campus__c, reduivy__Starting_Term__c, reduivy__Starting_Term__r.reduivy__End_Date__c, reduivy__Study_Intake__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
        Date toBeEnrolledTermStartDate = ipe[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id, reduivy__End_Date__c FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];

        String eligibleStudentCountTableStudyIntakeField = 'Name;reduivy__Study_Program__r.Name';

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getTermEnrollmentRecords(new List<Id>{ipe[0].reduivy__Study_Intake__c}, ipe[0].reduivy__Default_Campus__c, ipe[0].reduivy__Starting_Term__c, terms[0].Id, eligibleStudentCountTableStudyIntakeField, true);

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> finalMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap.containsKey('columns'), 'Response should contain columns key');
            System.Assert.isTrue(finalMap.containsKey('records'), 'Response should contain records key');
            System.Assert.isTrue(finalMap.containsKey('studyIntakesWithIPWToBeProcessedInTermEnrollment'), 
                                'Response should contain studyIntakesWithIPWToBeProcessedInTermEnrollment key');
            System.Assert.isTrue(finalMap.containsKey('studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment'), 
                                'Response should contain studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment key');
            System.Assert.isTrue(finalMap.containsKey('studyIntakesIdWithName'), 
                                'Response should contain studyIntakesIdWithName key');
            
            // Verify columns structure
            List<Object> columnsMapObj = (List<Object>) finalMap.get('columns');
            System.Assert.areEqual(4, columnsMapObj.size(), 'columns map should contain 4 entries');
            
            // Verify data
            List<Object> recordsMapObj = (List<Object>) finalMap.get('records');
            System.Assert.isFalse(recordsMapObj.isEmpty(), 'records map should not be empty');
            
            // Verify counts
            Map<String, Object> studyIntakesWithIPWToBeProcessedInTermEnrollment = 
                (Map<String, Object>) finalMap.get('studyIntakesWithIPWToBeProcessedInTermEnrollment');

            System.Assert.isFalse(studyIntakesWithIPWToBeProcessedInTermEnrollment.isEmpty(), 'Term Enrollment Count map should not be empty');
            
            Map<String, Object> studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment = 
                (Map<String, Object>) finalMap.get('studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment');

            System.Assert.isFalse(studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment.isEmpty(), 'Unit Enrollment Count map should not be empty');

            //Test for IPW_Enrolled_And_Completed_In_New_Term_Error
            //we update the term end date to make it as a completed term
            terms[0].reduivy__Start_Date__c = System.today().addDays(-8);
            terms[0].reduivy__End_Date__c = System.today().addDays(-7);
            update terms[0];

            REDU_LightningResponse errorResponse = REDU_TermStudentEnrollmentModal_LCTRL.getTermEnrollmentRecords(new List<Id>{ipe[0].reduivy__Study_Intake__c}, ipe[0].reduivy__Default_Campus__c, ipe[0].reduivy__Starting_Term__c, terms[0].Id, eligibleStudentCountTableStudyIntakeField, true);
            Map<String, Object> errorResponseMap = (Map<String, Object>) JSON.deserializeUntyped(errorResponse.responseData);
            System.Assert.isTrue(errorResponseMap.containsKey('records'), 'Response should contain records key');

            List<Map<String, String>> errorRecords = (List<Map<String, String>>) JSON.deserialize(JSON.serialize(errorResponseMap.get('records')), List<Map<String, String>>.class);
            System.Assert.areEqual(1, errorRecords.size());

            for (Map<String, String> records : errorRecords) {
                System.Assert.areEqual(ipe[0].reduivy__Study_Intake__c, records.get('Id'));
                System.Assert.areEqual('10', records.get('numberOfRecordsToBeExcluded'));
                System.Assert.areEqual('9', records.get('numberOfRecordsToBeProcessed'));
                System.Assert.isTrue(records.get('detailsOfRecordsToBeExcluded').startsWith('Excluded Records: 10'), 'Unexpected error: ' + records.get('detailsOfRecordsToBeExcluded'));
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test for getTermEnrollmentRecords() as faculty
     */
    @IsTest
    static void testgetTermEnrollmentRecordsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<reduivy__Individual_Program_Enrollment__c> ipe = [SELECT Id, reduivy__Default_Campus__c, reduivy__Starting_Term__c, reduivy__Starting_Term__r.reduivy__End_Date__c, reduivy__Study_Intake__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
        Date toBeEnrolledTermStartDate = ipe[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];

        String eligibleStudentCountTableStudyIntakeField = 'Name;reduivy__Study_Program__r.Name';

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getTermEnrollmentRecords(new List<Id>{ipe[0].reduivy__Study_Intake__c}, ipe[0].reduivy__Default_Campus__c, ipe[0].reduivy__Starting_Term__c, terms[0].Id, eligibleStudentCountTableStudyIntakeField, true);

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> finalMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap.containsKey('columns'), 'Response should contain columns key');
            System.Assert.isTrue(finalMap.containsKey('records'), 'Response should contain records key');
            System.Assert.isTrue(finalMap.containsKey('studyIntakesWithIPWToBeProcessedInTermEnrollment'), 
                                'Response should contain studyIntakesWithIPWToBeProcessedInTermEnrollment key');
            System.Assert.isTrue(finalMap.containsKey('studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment'), 
                                'Response should contain studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment key');
            System.Assert.isTrue(finalMap.containsKey('studyIntakesIdWithName'), 
                                'Response should contain studyIntakesIdWithName key');
            
            // Verify columns structure
            List<Object> columnsMapObj = (List<Object>) finalMap.get('columns');
            System.Assert.areEqual(4, columnsMapObj.size(), 'Columns map should contain 4 entries');
            
            // Verify records
            List<Object> recordsMapObj = (List<Object>) finalMap.get('records');
            System.Assert.isFalse(recordsMapObj.isEmpty(), 'records map should not be empty');
            
            // Verify counts
            Map<String, Object> studyIntakesWithIPWToBeProcessedInTermEnrollment = 
                (Map<String, Object>) finalMap.get('studyIntakesWithIPWToBeProcessedInTermEnrollment');

            System.Assert.isFalse(studyIntakesWithIPWToBeProcessedInTermEnrollment.isEmpty(), 'Term Enrollment Count map should not be empty');
            
            Map<String, Object> studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment = 
                (Map<String, Object>) finalMap.get('studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment');

            System.Assert.isFalse(studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment.isEmpty(), 'Unit Enrollment Count map should not be empty');

            //Test for IPW_Enrolled_And_Completed_In_New_Term_Error
            //we update the term end date to make it as a completed term
            terms[0].reduivy__Start_Date__c = System.today().addDays(-8);
            terms[0].reduivy__End_Date__c = System.today().addDays(-7);
            update terms[0];

            REDU_LightningResponse errorResponse = REDU_TermStudentEnrollmentModal_LCTRL.getTermEnrollmentRecords(new List<Id>{ipe[0].reduivy__Study_Intake__c}, ipe[0].reduivy__Default_Campus__c, ipe[0].reduivy__Starting_Term__c, terms[0].Id, eligibleStudentCountTableStudyIntakeField, true);
            Map<String, Object> errorResponseMap = (Map<String, Object>) JSON.deserializeUntyped(errorResponse.responseData);
            System.Assert.isTrue(errorResponseMap.containsKey('records'), 'Response should contain records key');

            List<Map<String, String>> errorRecords = (List<Map<String, String>>) JSON.deserialize(JSON.serialize(errorResponseMap.get('records')), List<Map<String, String>>.class);
            System.Assert.areEqual(1, errorRecords.size());

            for (Map<String, String> records : errorRecords) {
                System.Assert.areEqual(ipe[0].reduivy__Study_Intake__c, records.get('Id'));
                System.Assert.areEqual('10', records.get('numberOfRecordsToBeExcluded'));
                System.Assert.areEqual('9', records.get('numberOfRecordsToBeProcessed'));
                System.Assert.isTrue(records.get('detailsOfRecordsToBeExcluded').startsWith('Excluded Records: 10'), 'Unexpected error: ' + records.get('detailsOfRecordsToBeExcluded'));
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test for getTermEnrollmentRecords() as student
     */
    @IsTest
    static void testgetTermEnrollmentRecordsAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Individual_Program_Enrollment__c> ipe = [SELECT Id, reduivy__Default_Campus__c, reduivy__Starting_Term__c, reduivy__Starting_Term__r.reduivy__End_Date__c, reduivy__Study_Intake__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
        Date toBeEnrolledTermStartDate = ipe[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];

        String eligibleStudentCountTableStudyIntakeField = 'Name;reduivy__Study_Program__r.Name';

        System.runAs(reduStudent) {
            Test.startTest();
            
            REDU_LightningResponse response = REDU_TermStudentEnrollmentModal_LCTRL.getTermEnrollmentRecords(new List<Id>{ipe[0].reduivy__Study_Intake__c}, ipe[0].reduivy__Default_Campus__c, ipe[0].reduivy__Starting_Term__c, terms[0].Id, eligibleStudentCountTableStudyIntakeField, true);

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');

            Map<String, Object> finalMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            
            // Verify map structure
            System.Assert.isTrue(finalMap.containsKey('columns'), 'Response should contain columns key');
            System.Assert.isTrue(finalMap.containsKey('records'), 'Response should contain records key');
            System.Assert.isTrue(finalMap.containsKey('studyIntakesWithIPWToBeProcessedInTermEnrollment'), 
                                'Response should contain studyIntakesWithIPWToBeProcessedInTermEnrollment key');
            System.Assert.isTrue(finalMap.containsKey('studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment'), 
                                'Response should contain studyIntakesWithIPWToBeProcessedInOnlyUnitEnrollment key');
            System.Assert.isTrue(finalMap.containsKey('studyIntakesIdWithName'), 
                                'Response should contain studyIntakesIdWithName key');
            
            // Verify columns structure
            List<Object> columnsMapObj = (List<Object>) finalMap.get('columns');
            System.Assert.areEqual(4, columnsMapObj.size(), 'Columns map should contain 4 entries');
            
            // Verify records
            List<Object> recordsMapObj = (List<Object>) finalMap.get('records');
            System.Assert.isFalse(recordsMapObj.isEmpty(), 'records map should not be empty');
            
            Test.stopTest();
        }
    }

    /**
     * @description Negative Test for getTermEnrollmentRecords()
     */
    @IsTest
    static void testgetTermEnrollmentRecordsWithInvalidParams() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Individual_Program_Enrollment__c> ipe = [SELECT Id, reduivy__Default_Campus__c, reduivy__Starting_Term__c, reduivy__Starting_Term__r.reduivy__End_Date__c, reduivy__Study_Intake__c FROM reduivy__Individual_Program_Enrollment__c LIMIT 1];
        Date toBeEnrolledTermStartDate = ipe[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id, reduivy__End_Date__c FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];

        String eligibleStudentCountTableStudyIntakeField = 'Name;reduivy__Study_Program__r.Name';

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            //Test for blank eligibleStudentCountTableStudyIntakeField
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.getTermEnrollmentRecords(new List<Id>{ipe[0].reduivy__Study_Intake__c}, ipe[0].reduivy__Default_Campus__c, ipe[0].reduivy__Starting_Term__c, terms[0].Id, null, true);                
                System.Assert.fail('Expected an AuraHandledException for both blank IDs');
            } catch (AuraHandledException e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains(String.format(Label.Missing_Required_Parameters,
                new List<String>{'eligibleStudentCountTableStudyIntakeField'})), 
                                    'Unexpected error: ' + e.getMessage());
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test for initQueueJob() as admin
     */
    @IsTest
    static void testinitQueueJobAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Individual_Program_Enrollment__c> ipes = [SELECT Id, reduivy__Starting_Term__r.reduivy__End_Date__c, (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) FROM reduivy__Individual_Program_Enrollment__c ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC];
        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];
        List<Id> toBeProcessedIds = new List<Id>();
        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled';

        for(reduivy__Individual_Pathway__c ipw : ipes[9].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 1) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        for(reduivy__Individual_Pathway__c ipw : ipes[10].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 2) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        for(reduivy__Individual_Pathway__c ipw : ipes[11].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 1) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        for(reduivy__Individual_Pathway__c ipw : ipes[12].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 2) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            REDU_TermStudentEnrollmentModal_LCTRL.initQueueJob(JOB_OPERATION, toBeProcessedIds, terms[0].Id, false, false, existingIndividualEnrollmentStatuses);

            List<reduivy__Job_Queue__c> jobQueue = [SELECT Id, reduivy__Job_Operation__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Term_Student_Enrollment'];
            
            System.Assert.areEqual(1, jobQueue.size(), 'A Job Queue should be created.');

            Test.stopTest();
        }
    }

    /**
     * @description Test for initQueueJob() as faculty
     */
    @IsTest
    static void testinitQueueJobAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<reduivy__Individual_Program_Enrollment__c> ipes = [SELECT Id, reduivy__Starting_Term__r.reduivy__End_Date__c, (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) FROM reduivy__Individual_Program_Enrollment__c ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC];
        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];
        List<Id> toBeProcessedIds = new List<Id>();
        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled';

        for(reduivy__Individual_Pathway__c ipw : ipes[9].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 1) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        for(reduivy__Individual_Pathway__c ipw : ipes[10].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 2) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        for(reduivy__Individual_Pathway__c ipw : ipes[11].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 1) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        for(reduivy__Individual_Pathway__c ipw : ipes[12].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 2) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.initQueueJob(JOB_OPERATION, toBeProcessedIds, terms[0].Id, false, false, existingIndividualEnrollmentStatuses);
                System.Assert.fail('Expected an exception due to insufficient access to reduivy__Job_Queue_Group__c.');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains('Access to entity \'reduivy__Job_Queue_Group__c\' denied'), 
                                    'Unexpected error: ' + errorMsg);
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test for initQueueJob() as student
     */
    @IsTest
    static void testinitQueueJobAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Individual_Program_Enrollment__c> ipes = [SELECT Id, reduivy__Starting_Term__r.reduivy__End_Date__c, (SELECT Id, reduivy__Term_Number__c, reduivy__Academic_Term__c, reduivy__Individual_Academic_Progress__c FROM reduivy__Individual_Pathways__r ORDER BY reduivy__Term_Number__c) FROM reduivy__Individual_Program_Enrollment__c ORDER BY reduivy__Contact__r.reduivy__Sequence__c ASC];
        Date toBeEnrolledTermStartDate = ipes[0].reduivy__Starting_Term__r.reduivy__End_Date__c.addDays(31);
        List<reduivy__Study_Term__c> terms = [SELECT Id FROM reduivy__Study_Term__c WHERE reduivy__Start_Date__c = :toBeEnrolledTermStartDate];
        List<Id> toBeProcessedIds = new List<Id>();
        String existingIndividualEnrollmentStatuses = 'Completed;Withdrawn;Enrolled;Cancelled';

        for(reduivy__Individual_Pathway__c ipw : ipes[9].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 1) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        for(reduivy__Individual_Pathway__c ipw : ipes[10].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 2) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        for(reduivy__Individual_Pathway__c ipw : ipes[11].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 1) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        for(reduivy__Individual_Pathway__c ipw : ipes[12].reduivy__Individual_Pathways__r) {
            if(ipw.reduivy__Term_Number__c == 2) {
                toBeProcessedIds.add(ipw.Id);
            }
        }

        System.runAs(reduStudent) {
            Test.startTest();
            
            try {
                REDU_TermStudentEnrollmentModal_LCTRL.initQueueJob(JOB_OPERATION, toBeProcessedIds, terms[0].Id, false, false, existingIndividualEnrollmentStatuses);
                System.Assert.fail('Expected an exception due to insufficient access to reduivy__Job_Queue_Group__c.');
            } catch (Exception e) {
                String errorMsg = e.getMessage();
                System.Assert.isTrue(errorMsg.contains('Access to entity \'reduivy__Job_Queue_Group__c\' denied'), 
                                    'Unexpected error: ' + errorMsg);
            }

            Test.stopTest();
        }
    }
}