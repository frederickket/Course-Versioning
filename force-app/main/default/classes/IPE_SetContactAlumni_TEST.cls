/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Trigger executable
 * @description Test class for IPE_SetContactAlumni_EXE
 * @changehistory
 * ISS-002088 08-11-2024 Jordan - new class
 */
@IsTest
public inherited sharing class IPE_SetContactAlumni_TEST{

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
     * @description Test setting the contact type to alumni when program enrollment is created.
     */
    @IsTest
    static void testIpeInsertSetContactAlumniAsAdmin(){

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

        //individual program enrollment
        List<String> enrollmentCompletedStatuses = IPE_Helper.getCompletedStatuses();
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            masterProgramEnrollments.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, enrollmentCompletedStatuses[0], null));
        }
        
        // Execute test
        Test.startTest();

        insert masterProgramEnrollments;
        Test.stopTest();
        }

        for(Contact con : [SELECT Id, Name, reduivy__Contact_Type__c FROM Contact WHERE Id IN: studentMap.keySet()]){
            System.Assert.areEqual(CON_Helper.CONTACT_TYPE_ALUMNI, con.reduivy__Contact_Type__c, 'The contact type for student should be updated to alumni.');
        }
    }

    /**
     * @description Test setting the contact type to alumni when program enrollment is updated.
     */
    @IsTest
    static void testIpeUpdateSetContactAlumniAsAdmin(){

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

        //individual program enrollment
        List<String> enrollmentInProgressStatuses = IPE_Helper.getInProgressStatuses();
        List<String> enrollmentCompletedStatuses = IPE_Helper.getCompletedStatuses();
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            masterProgramEnrollments.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, enrollmentInProgressStatuses[0], null));
        }
        insert masterProgramEnrollments;

        for(reduivy__Individual_Program_Enrollment__c ipe : masterProgramEnrollments){
            ipe.reduivy__Enrollment_Status__c = enrollmentCompletedStatuses[0];
        }
        
        
        // Execute test
        Test.startTest();

        update masterProgramEnrollments;
        Test.stopTest();
        }

        for(Contact con : [SELECT Id, Name, reduivy__Contact_Type__c FROM Contact WHERE Id IN: studentMap.keySet()]){
            System.Assert.areEqual(CON_Helper.CONTACT_TYPE_ALUMNI, con.reduivy__Contact_Type__c, 'The contact type for student should be updated to alumni.');
        }
        
    }

    /**
     * @description Test when child program enrollment is created.
     */
    @IsTest
    static void testIpeInsertChildIpeAsAdmin(){

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

            reduivy__Study_Plan__c childStudyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE reduivy__Study_Program__c = :currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c AND Id != :currentIntake.reduivy__Default_Study_Plan__c LIMIT 1];

            //individual program enrollment
            List<String> enrollmentCompletedStatuses = IPE_Helper.getCompletedStatuses();
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();

            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                masterProgramEnrollments.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, enrollmentCompletedStatuses[0], null));

                childProgramEnrollments.add(REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, childStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, enrollmentCompletedStatuses[0]));
            }

            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }

            for (Contact student : studentMap.values()) {
                student.reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT;
            }

            update studentMap.values();
            
            // Execute test
            Test.startTest();

            insert childProgramEnrollments;
            Test.stopTest();
        }

        for(Contact con : [SELECT Id, Name, reduivy__Contact_Type__c FROM Contact WHERE Id IN: studentMap.keySet()]){
            System.Assert.areEqual(CON_Helper.CONTACT_TYPE_STUDENT, con.reduivy__Contact_Type__c, 'The contact type should be student.');
        }
    }

    /**
     * @description Test when child program enrollment is updated.
     */
    @IsTest
    static void testIpeUpdateChildIpeAsAdmin(){

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

            reduivy__Study_Plan__c childStudyPlan = [SELECT Id FROM reduivy__Study_Plan__c WHERE reduivy__Study_Program__c = :currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c AND Id != :currentIntake.reduivy__Default_Study_Plan__c LIMIT 1];

            //individual program enrollment
            List<String> enrollmentInProgressStatuses = IPE_Helper.getInProgressStatuses();
            List<String> enrollmentCompletedStatuses = IPE_Helper.getCompletedStatuses();
            List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
            for(Contact student : studentMap.values()){

                System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

                masterProgramEnrollments.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, enrollmentCompletedStatuses[0], null));

                childProgramEnrollments.add(REDU_TestData_UTIL.newChildIndividualProgramEnrollment(student.email + '_BACBIS_MajorA', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, childStudyPlan.Id, null, IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, true, enrollmentInProgressStatuses[0]));
            }
            insert masterProgramEnrollments;

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childProgramEnrollments) {
                childIpe.reduivy__Master_Enrollment__c = masterProgramEnrollments.get(counter).Id;
                counter++;
            }

            for (Contact student : studentMap.values()) {
                student.reduivy__Contact_Type__c = CON_Helper.CONTACT_TYPE_STUDENT;
            }

            update studentMap.values();

            insert childProgramEnrollments;

            for(reduivy__Individual_Program_Enrollment__c ipe : childProgramEnrollments){
                ipe.reduivy__Enrollment_Status__c = enrollmentCompletedStatuses[0];
            }
            
            // Execute test
            Test.startTest();

            update childProgramEnrollments;
            Test.stopTest();
        }

        for(Contact con : [SELECT Id, Name, reduivy__Contact_Type__c FROM Contact WHERE Id IN: studentMap.keySet()]){
            System.Assert.areEqual(CON_Helper.CONTACT_TYPE_STUDENT, con.reduivy__Contact_Type__c, 'The contact type should be student.');
        }
        
    }

    /**
     * @description Test when completed program enrollment is created and there is another in-progress master program enrollment for the student.
     */
    @IsTest
    static void testIpeInsertOtherInProgressIpeAsAdmin(){

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

        //individual program enrollment
        List<String> enrollmentInProgressStatuses = IPE_Helper.getInProgressStatuses();
        List<String> enrollmentCompletedStatuses = IPE_Helper.getCompletedStatuses();
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            masterProgramEnrollments.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA_1', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, enrollmentInProgressStatuses[0], null));
            masterProgramEnrollments.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA_2', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, enrollmentCompletedStatuses[0], null));
        }
        
        // Execute test
        Test.startTest();

        insert masterProgramEnrollments;
        Test.stopTest();
        }

        for(Contact con : [SELECT Id, Name, reduivy__Contact_Type__c FROM Contact WHERE Id IN: studentMap.keySet()]){
            System.Assert.areEqual(CON_Helper.CONTACT_TYPE_STUDENT, con.reduivy__Contact_Type__c, 'The contact type should be student.');
        }
    }

    /**
     * @description Test when program enrollment is updated to completed and there is another in-progress master program enrollment for the student.
     */
    @IsTest
    static void testIpeUpdateOtherInProgressIpeAsAdmin(){

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

        //individual program enrollment
        List<String> enrollmentInProgressStatuses = IPE_Helper.getInProgressStatuses();
        List<String> enrollmentCompletedStatuses = IPE_Helper.getCompletedStatuses();
        List<reduivy__Individual_Program_Enrollment__c> masterProgramEnrollments = new List<reduivy__Individual_Program_Enrollment__c>();
        for(Contact student : studentMap.values()){

            System.Assert.areEqual(contactTypeStudent, student.reduivy__Contact_Type__c, 'The contact type should be student as no program enrollment yet.');

            masterProgramEnrollments.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA_1', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, enrollmentInProgressStatuses[0], null));
            masterProgramEnrollments.add(REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(student.email + '_BACBIS_MajorA_2', student.Id, currentIntake.reduivy__Default_Study_Plan__r.reduivy__Study_Program__c, currentIntake.reduivy__Default_Study_Plan__c, currentIntake.Id, currentIntake.reduivy__Academic_Term__c, currentIntake.reduivy__Default_Study_Pathway__c, currentIntake.reduivy__Campus__c, String.valueOf(currentIntake.reduivy__Academic_Term__r.reduivy__Start_Date__c.year()), 'Freshman', true, enrollmentInProgressStatuses[0], null));
        }
        insert masterProgramEnrollments;

        masterProgramEnrollments[0].reduivy__Enrollment_Status__c = enrollmentCompletedStatuses[0];
        
        // Execute test
        Test.startTest();

        update masterProgramEnrollments[0];
        Test.stopTest();
        }

        for(Contact con : [SELECT Id, Name, reduivy__Contact_Type__c FROM Contact WHERE Id IN: studentMap.keySet()]){
            System.Assert.areEqual(CON_Helper.CONTACT_TYPE_STUDENT, con.reduivy__Contact_Type__c, 'The contact type should be student.');
        }
        
    }
}