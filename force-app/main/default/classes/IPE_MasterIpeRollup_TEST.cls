/**
 * @author      WDCi (Jordan)
 * @date        Jan 2025
 * @group       Test
 * @description Test as admin class for IPE_MasterIpeRollup_EXE
 * @changehistory
 * ISS-002203 16-01-2025 Jordan - new class
 */
@IsTest
public inherited sharing class IPE_MasterIpeRollup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();	

    static final List<String> IPE_DRAFT_STATUSES = IPE_Helper.getDraftStatuses();
    static final List<String> IPE_COMPLETED_STATUSES = IPE_Helper.getCompletedStatuses();
    static final List<String> IPE_WITHDRAWN_STATUSES = IPE_Helper.getWithdrawnStatuses();
    static final Id IPE_MASTER_RECORDTYPE_ID = IPE_Helper.getMasterEnrollmentRecordTypeId();

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
			testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin when child program enrollment is created.
     */
    @IsTest
    static void testInsertChildIpeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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
            
            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];

            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when multiple child program enrollments are created.
     */
    @IsTest
    static void testInsertMultipleChildIpeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                for (Integer i = 0; i < 2; i++) {
                    reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA_' + i, student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                    childIpe.reduivy__Credits_Earned__c = 40;
                    childProgramEnrollments.add(childIpe);
                }
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            Integer masterIpeCounter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                masterIpeCounter = (Integer) Math.floor(counter / 2);
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(masterIpeCounter).Id;
                counter++;
            }
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(320, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when draft child program enrollment is created.
     */
    @IsTest
    static void testInsertDraftChildIpeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_DRAFT_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_DRAFT_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when child program enrollment is created with credits required = blank.
     */
    @IsTest
    static void testInsertChildIpeAsAdminCreditsRequiredBlank(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];

            minorStudyPlan.reduivy__Total_Required_Credits__c = null;
            update minorStudyPlan;
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = null;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when child program enrollment is created with credits required = 0.
     */
    @IsTest
    static void testInsertChildIpeAsAdminCreditsRequiredZero(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];

            minorStudyPlan.reduivy__Total_Required_Credits__c = 0;
            update minorStudyPlan;
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 0;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when optional child program enrollment is created.
     */
    @IsTest
    static void testInsertOptionalChildIpeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_OPTIONAL, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when child program enrollment's enrollment status is updated to completed.
     */
    @IsTest
    static void testUpdateChildIpeToCompletedAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_DRAFT_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }

            insert childProgramEnrollments;

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Enrollment_Status__c = IPE_COMPLETED_STATUSES[0];
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when child program enrollment's enrollment status is updated to withdrawn.
     */
    @IsTest
    static void testUpdateChildIpeToWithdrawnAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }

            insert childProgramEnrollments;

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Enrollment_Status__c = IPE_WITHDRAWN_STATUSES[0];
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when child program enrollment's completion requirement is updated to mandatory.
     */
    @IsTest
    static void testUpdateChildIpeToMandatoryAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_OPTIONAL, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }

            insert childProgramEnrollments;

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Completion_Requirement__c = IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY;
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when child program enrollment's completion requirement is updated to optional.
     */
    @IsTest
    static void testUpdateChildIpeToOptionalAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }

            insert childProgramEnrollments;

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Completion_Requirement__c = IPE_Helper.COMPLETION_REQUIREMENT_OPTIONAL;
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when child program enrollment's credits earned is updated.
     */
    @IsTest
    static void testUpdateChildIpeCreditsEarnedAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }

            insert childProgramEnrollments;

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Credits_Earned__c = 50;
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(50, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(130, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(110, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when child program enrollment is deleted.
     */
    @IsTest
    static void testDeleteChildIpeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }

            insert childProgramEnrollments;

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
            
            // Execute test
            Test.startTest();

            delete childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as admin when child program enrollment is undeleted.
     */
    @IsTest
    static void testUndeleteChildIpeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        System.runAs(ADMIN_USER){
            
            //student contact
            String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
            for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
                studentMap.put(student.Id, student);
            }

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

            //get minor study plan
            reduivy__Study_Plan__c minorStudyPlan = [
                SELECT Id, reduivy__Study_Program__c
                FROM reduivy__Study_Plan__c 
                WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
                LIMIT 1
            ];
            
            //individual program enrollment
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
                masterIpe.reduivy__Credits_Earned__c = 80;
                masterProgramEnrollments.add(masterIpe);

                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }

            insert childProgramEnrollments;

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }

            delete childProgramEnrollments;

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
            
            // Execute test
            Test.startTest();

            undelete childProgramEnrollments;
            Test.stopTest();

            ///Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when child program enrollment is created.
     */
    @IsTest
    static void testInsertChildIpeAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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
        
        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }
        
        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when multiple child program enrollments are created.
     */
    @IsTest
    static void testInsertMultipleChildIpeAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            for (Integer i = 0; i < 2; i++) {
                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA_' + i, student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        Integer masterIpeCounter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            masterIpeCounter = (Integer) Math.floor(counter / 2);
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(masterIpeCounter).Id;
            counter++;
        }
        
        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(320, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when draft child program enrollment is created.
     */
    @IsTest
    static void testInsertDraftChildIpeAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_DRAFT_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_DRAFT_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when child program enrollment is created with credits required = blank.
     */
    @IsTest
    static void testInsertChildIpeAsFacultyCreditsRequiredBlank(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        minorStudyPlan.reduivy__Total_Required_Credits__c = null;
        update minorStudyPlan;
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = null;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when child program enrollment is created with credits required = 0.
     */
    @IsTest
    static void testInsertChildIpeAsFacultyCreditsRequiredZero(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();
        
        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        minorStudyPlan.reduivy__Total_Required_Credits__c = 0;
        update minorStudyPlan;
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 0;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when optional child program enrollment is created.
     */
    @IsTest
    static void testInsertOptionalChildIpeAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_OPTIONAL, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when child program enrollment's enrollment status is updated to completed.
     */
    @IsTest
    static void testUpdateChildIpeToCompletedAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_DRAFT_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        insert childProgramEnrollments;

        //Assert rollup was successful
        for (reduivy__Individual_Program_Enrollment__c masterIpe : [
            SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
            reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
        ]) {
            System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
            System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
            System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
            System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
        }

        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Enrollment_Status__c = IPE_COMPLETED_STATUSES[0];
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when child program enrollment's enrollment status is updated to withdrawn.
     */
    @IsTest
    static void testUpdateChildIpeToWithdrawnAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        insert childProgramEnrollments;

        //Assert rollup was successful
        for (reduivy__Individual_Program_Enrollment__c masterIpe : [
            SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
            reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
        ]) {
            System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
            System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
            System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
        }

        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Enrollment_Status__c = IPE_WITHDRAWN_STATUSES[0];
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when child program enrollment's completion requirement is updated to mandatory.
     */
    @IsTest
    static void testUpdateChildIpeToMandatoryAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_OPTIONAL, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        insert childProgramEnrollments;

        //Assert rollup was successful
        for (reduivy__Individual_Program_Enrollment__c masterIpe : [
            SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
            reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
        ]) {
            System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
            System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
            System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
            System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
        }

        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Completion_Requirement__c = IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY;
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when child program enrollment's completion requirement is updated to optional.
     */
    @IsTest
    static void testUpdateChildIpeToOptionalAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        insert childProgramEnrollments;

        //Assert rollup was successful
        for (reduivy__Individual_Program_Enrollment__c masterIpe : [
            SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
            reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
        ]) {
            System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
            System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
            System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
        }

        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Completion_Requirement__c = IPE_Helper.COMPLETION_REQUIREMENT_OPTIONAL;
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as faculty when child program enrollment's credits earned is updated.
     */
    @IsTest
    static void testUpdateChildIpeCreditsEarnedAsFaculty(){

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent]){
            studentMap.put(student.Id, student);
        }

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        insert childProgramEnrollments;

        //Assert rollup was successful
        for (reduivy__Individual_Program_Enrollment__c masterIpe : [
            SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
            reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
        ]) {
            System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
            System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
            System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
        }

        System.runAs(FACULTY_USER){
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Credits_Earned__c = 50;
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(50, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(130, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(110, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when child program enrollment is created.
     */
    @IsTest
    static void testInsertChildIpeAsStudent(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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
        
        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }
        
        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when multiple child program enrollments are created.
     */
    @IsTest
    static void testInsertMultipleChildIpeAsStudent(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            for (Integer i = 0; i < 2; i++) {
                reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA_' + i, student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
                childIpe.reduivy__Credits_Earned__c = 40;
                childProgramEnrollments.add(childIpe);
            }
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        Integer masterIpeCounter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            masterIpeCounter = (Integer) Math.floor(counter / 2);
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(masterIpeCounter).Id;
            counter++;
        }
        
        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(320, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when draft child program enrollment is created.
     */
    @IsTest
    static void testInsertDraftChildIpeAsStudent(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_DRAFT_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_DRAFT_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when child program enrollment is created with credits required = blank.
     */
    @IsTest
    static void testInsertChildIpeAsStudentCreditsRequiredBlank(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        minorStudyPlan.reduivy__Total_Required_Credits__c = null;
        update minorStudyPlan;
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = null;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when child program enrollment is created with credits required = 0.
     */
    @IsTest
    static void testInsertChildIpeAsStudentCreditsRequiredZero(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];

        minorStudyPlan.reduivy__Total_Required_Credits__c = 0;
        update minorStudyPlan;
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 0;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when optional child program enrollment is created.
     */
    @IsTest
    static void testInsertOptionalChildIpeAsStudent(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_OPTIONAL, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when child program enrollment's enrollment status is updated to completed.
     */
    @IsTest
    static void testUpdateChildIpeToCompletedAsStudent(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_DRAFT_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        insert childProgramEnrollments;

        //Assert rollup was successful
        for (reduivy__Individual_Program_Enrollment__c masterIpe : [
            SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
            reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
        ]) {
            System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
            System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
            System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
            System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
        }

        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Enrollment_Status__c = IPE_COMPLETED_STATUSES[0];
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when child program enrollment's enrollment status is updated to withdrawn.
     */
    @IsTest
    static void testUpdateChildIpeToWithdrawnAsStudent(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        insert childProgramEnrollments;

        //Assert rollup was successful
        for (reduivy__Individual_Program_Enrollment__c masterIpe : [
            SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
            reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
        ]) {
            System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
            System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
            System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
        }

        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Enrollment_Status__c = IPE_WITHDRAWN_STATUSES[0];
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when child program enrollment's completion requirement is updated to mandatory.
     */
    @IsTest
    static void testUpdateChildIpeToMandatoryAsStudent(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_OPTIONAL, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        insert childProgramEnrollments;

        //Assert rollup was successful
        for (reduivy__Individual_Program_Enrollment__c masterIpe : [
            SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
            reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
        ]) {
            System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
            System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Required__c);
            System.Assert.isNull(masterIpe.reduivy__Additional_Credits_Earned__c);
            System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
        }

        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Completion_Requirement__c = IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY;
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when child program enrollment's completion requirement is updated to optional.
     */
    @IsTest
    static void testUpdateChildIpeToOptionalAsStudent(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        insert childProgramEnrollments;

        //Assert rollup was successful
        for (reduivy__Individual_Program_Enrollment__c masterIpe : [
            SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
            reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
        ]) {
            System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
            System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
            System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
        }

        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Completion_Requirement__c = IPE_Helper.COMPLETION_REQUIREMENT_OPTIONAL;
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(0, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(160, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }

    /**
     * @description Test as student when child program enrollment's credits earned is updated.
     */
    @IsTest
    static void testUpdateChildIpeCreditsEarnedAsStudent(){

        Map<id, Contact> studentMap = new Map<id, Contact>();

        //student contact
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        for(Contact student : [SELECT Id, reduivy__Contact_Type__c, email FROM Contact WHERE reduivy__Contact_Type__c =: contactTypeStudent LIMIT 1]){
            studentMap.put(student.Id, student);
        }

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId IN :studentMap.keySet() 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
            LIMIT 1
        ];

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

        //get minor study plan
        reduivy__Study_Plan__c minorStudyPlan = [
            SELECT Id, reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c 
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MinorA'
            LIMIT 1
        ];
        
        //individual program enrollment
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            reduivy__Individual_Program_Enrollment__c masterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, IPE_COMPLETED_STATUSES[0], null);
            masterIpe.reduivy__Credits_Earned__c = 80;
            masterProgramEnrollments.add(masterIpe);

            reduivy__Individual_Program_Enrollment__c childIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MinorA', student.Id, minorStudyPlan.reduivy__Study_Program__c, minorStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, IPE_COMPLETED_STATUSES[0]);
            childIpe.reduivy__Credits_Earned__c = 40;
            childProgramEnrollments.add(childIpe);
        }

        insert masterProgramEnrollments;

        Integer counter = 0;
        for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
            childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
            counter++;
        }

        insert childProgramEnrollments;

        //Assert rollup was successful
        for (reduivy__Individual_Program_Enrollment__c masterIpe : [
            SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
            reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
        ]) {
            System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
            System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
            System.Assert.areEqual(40, masterIpe.reduivy__Additional_Credits_Earned__c);
            System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Total_Credits_Earned__c);
            System.Assert.areEqual(120, masterIpe.reduivy__Remaining_Credits_Required__c);
        }

        System.runAs(studentUser){
            
            // Execute test
            Test.startTest();

            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Credits_Earned__c = 50;
            }

            update childProgramEnrollments;
            Test.stopTest();

            //Assert rollup was successful
            for (reduivy__Individual_Program_Enrollment__c masterIpe : [
                SELECT reduivy__Credits_Required__c, reduivy__Credits_Earned__c, reduivy__Additional_Credits_Required__c, reduivy__Additional_Credits_Earned__c, reduivy__Total_Credits_Required__c, 
                reduivy__Total_Credits_Earned__c, reduivy__Remaining_Credits_Required__c
                FROM reduivy__Individual_Program_Enrollment__c 
                WHERE RecordTypeId =: IPE_MASTER_RECORDTYPE_ID
            ]) {
                System.Assert.areEqual(160, masterIpe.reduivy__Credits_Required__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Credits_Earned__c);
                System.Assert.areEqual(80, masterIpe.reduivy__Additional_Credits_Required__c);
                System.Assert.areEqual(50, masterIpe.reduivy__Additional_Credits_Earned__c);
                System.Assert.areEqual(240, masterIpe.reduivy__Total_Credits_Required__c);
                System.Assert.areEqual(130, masterIpe.reduivy__Total_Credits_Earned__c);
                System.Assert.areEqual(110, masterIpe.reduivy__Remaining_Credits_Required__c);
            }
        }
    }
}