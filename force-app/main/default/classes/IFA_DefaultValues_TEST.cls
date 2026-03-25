/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for IFA_DefaultValues_EXE
 * @changehistory
 * ISS-002168 10-01-2025 Lean - new class
 */
@IsTest
public inherited sharing class IFA_DefaultValues_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

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
        	
            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initOfferingData(STM_Helper.getApiName());
            testFactory.initStudentData(IFA_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test inheriting default max per term from study funding
     */
    @IsTest
    static void testInheritDefaultFromStudyFundingAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            //get study fundings
            Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
                SELECT Id, reduivy__Max_Per_Term__c
                FROM reduivy__Study_Funding__c
            ]);

            Integer counter = 1;
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                sfd.reduivy__Max_Per_Term__c = counter;

                counter ++;
            }

            REDU_Database_UTIL.doUpdate(sfdMap.values());

            List<Contact> studentContacts = [SELECT Id
                FROM Contact 
                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
                AND reduivy__Sample_Record_Code__c <> ''
            ];

            List<reduivy__Individual_Funding_Allocation__c> newIfaList = new List<reduivy__Individual_Funding_Allocation__c>();
            
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                for (Contact student : studentContacts) {
                    reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                        null,
                        student.Id,
                        sfd.Id,
                        5000,
                        System.today(),
                        System.today().addDays(30),
                        null,
                        IFA_Helper.STATUS_ACTIVE
                    );

                    newIfaList.add(ifa);
                }
            }

            System.Assert.areEqual(false, newIfaList.isEmpty(), 'There is no record for testing.');

            REDU_Database_UTIL.doInsert(newIfaList);

            for (reduivy__Individual_Funding_Allocation__c ifa : [SELECT Id, reduivy__Max_Per_Term__c, reduivy__Study_Funding__c
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE Id IN: newIfaList
            ]) {
                System.Assert.areEqual(sfdMap.get(ifa.reduivy__Study_Funding__c).reduivy__Max_Per_Term__c, ifa.reduivy__Max_Per_Term__c);
            }
		}

        Test.stopTest();
		
    }

    /**
     * @description Test skip inheriting default max per term from study funding
     */
    @IsTest
    static void testSkipDefaultFromStudyFundingAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            //get study fundings
            Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
                SELECT Id, reduivy__Max_Per_Term__c
                FROM reduivy__Study_Funding__c
            ]);

            Integer counter = 1;
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                sfd.reduivy__Max_Per_Term__c = counter;

                counter ++;
            }

            REDU_Database_UTIL.doUpdate(sfdMap.values());

            List<Contact> studentContacts = [SELECT Id
                FROM Contact 
                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
                AND reduivy__Sample_Record_Code__c <> ''
            ];

            List<reduivy__Individual_Funding_Allocation__c> newIfaList = new List<reduivy__Individual_Funding_Allocation__c>();
            
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                for (Contact student : studentContacts) {
                    reduivy__Individual_Funding_Allocation__c ifa = REDU_TestData_UTIL.newIdvFundingAllocation(
                        null,
                        student.Id,
                        sfd.Id,
                        5000,
                        System.today(),
                        System.today().addDays(30),
                        null,
                        IFA_Helper.STATUS_ACTIVE
                    );

                    ifa.reduivy__Max_Per_Term__c = 1000;

                    newIfaList.add(ifa);
                }
            }

            System.Assert.areEqual(false, newIfaList.isEmpty(), 'There is no record for testing.');

            REDU_Database_UTIL.doInsert(newIfaList);

            for (reduivy__Individual_Funding_Allocation__c ifa : [SELECT Id, reduivy__Max_Per_Term__c, reduivy__Study_Funding__c
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE Id IN: newIfaList
            ]) {
                System.Assert.areEqual(1000, ifa.reduivy__Max_Per_Term__c);
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test inheriting default max per term from study funding
     */
    @IsTest
    static void testInheritDefaultFromStudyFundingAsFaculty() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Max_Per_Term__c
            FROM reduivy__Study_Funding__c
        ]);

		System.runAs(ADMIN_USER){
            
            Integer counter = 1;
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                sfd.reduivy__Max_Per_Term__c = counter;

                counter ++;
            }

            REDU_Database_UTIL.doUpdate(sfdMap.values());
        }

        //test as faculty
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {

            List<Contact> studentContacts = [SELECT Id
                FROM Contact 
                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
                AND reduivy__Sample_Record_Code__c <> ''
            ];

            List<reduivy__Individual_Funding_Allocation__c> newIfaList = new List<reduivy__Individual_Funding_Allocation__c>();
            
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                for (Contact student : studentContacts) {
                    reduivy__Individual_Funding_Allocation__c ifa = new reduivy__Individual_Funding_Allocation__c(
                        reduivy__Contact__c = student.Id,
                        reduivy__Study_Funding__c = sfd.Id,
                        reduivy__Status__c = IFA_Helper.STATUS_ACTIVE
                    );

                    newIfaList.add(ifa);
                }
            }

            System.Assert.areEqual(false, newIfaList.isEmpty(), 'There is no record for testing.');

            REDU_Database_UTIL.doInsert(newIfaList);

            for (reduivy__Individual_Funding_Allocation__c ifa : [SELECT Id, reduivy__Max_Per_Term__c, reduivy__Study_Funding__c
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE Id IN: newIfaList
            ]) {
                System.Assert.areEqual(sfdMap.get(ifa.reduivy__Study_Funding__c).reduivy__Max_Per_Term__c, ifa.reduivy__Max_Per_Term__c);
            }
		}

        Test.stopTest();
		
    }

    /**
     * @description Test skip inheriting default max per term from study funding, this should fail with FLS as faculty doesn't have right to set max per term on ifa
     */
    @IsTest
    static void testSkipDefaultFromStudyFundingAsFaculty() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Max_Per_Term__c
            FROM reduivy__Study_Funding__c
        ]);

		System.runAs(ADMIN_USER){

            Integer counter = 1;
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                sfd.reduivy__Max_Per_Term__c = counter;

                counter ++;
            }

            REDU_Database_UTIL.doUpdate(sfdMap.values());
        }

        //test as faculty
        User FACULTY_USER = testFactory.getReduFacultyUser();

        System.runAs(FACULTY_USER) {
            List<Contact> studentContacts = [SELECT Id
                FROM Contact 
                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
                AND reduivy__Sample_Record_Code__c <> ''
            ];

            List<reduivy__Individual_Funding_Allocation__c> newIfaList = new List<reduivy__Individual_Funding_Allocation__c>();
            
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                for (Contact student : studentContacts) {
                    reduivy__Individual_Funding_Allocation__c ifa = new reduivy__Individual_Funding_Allocation__c(
                        reduivy__Contact__c = student.Id,
                        reduivy__Study_Funding__c = sfd.Id,
                        reduivy__Status__c = IFA_Helper.STATUS_ACTIVE
                    );

                    ifa.reduivy__Max_Per_Term__c = 1000;

                    newIfaList.add(ifa);
                }
            }

            System.Assert.areEqual(false, newIfaList.isEmpty(), 'There is no record for testing.');

            try {
                REDU_Database_UTIL.doInsert(newIfaList);
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient CREATABLE access on following object(s) and field(s) - reduivy__Individual_Funding_Allocation__c: reduivy__Max_Per_Term__c'), 'Unexpected error: ' + exp.getMessage());
            }
		}

        Test.stopTest();
		
    }

    /**
     * @description Test inheriting default max per term from study funding
     */
    @IsTest
    static void testInheritDefaultFromStudyFundingAsStudent() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Max_Per_Term__c
            FROM reduivy__Study_Funding__c
        ]);

		System.runAs(ADMIN_USER){
            
            Integer counter = 1;
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                sfd.reduivy__Max_Per_Term__c = counter;

                counter ++;
            }

            REDU_Database_UTIL.doUpdate(sfdMap.values());
        }

        //test as student
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser) {

            List<Contact> studentContacts = [SELECT Id
                FROM Contact 
                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
                AND reduivy__Sample_Record_Code__c <> ''
                AND Id =: studentUser.ContactId
            ];

            List<reduivy__Individual_Funding_Allocation__c> newIfaList = new List<reduivy__Individual_Funding_Allocation__c>();
            
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                for (Contact student : studentContacts) {
                    reduivy__Individual_Funding_Allocation__c ifa = new reduivy__Individual_Funding_Allocation__c(
                        reduivy__Contact__c = student.Id,
                        reduivy__Study_Funding__c = sfd.Id,
                        reduivy__Status__c = IFA_Helper.STATUS_ACTIVE
                    );

                    newIfaList.add(ifa);
                }
            }

            System.Assert.areEqual(false, newIfaList.isEmpty(), 'There is no record for testing.');

            REDU_Database_UTIL.doInsert(newIfaList);

            for (reduivy__Individual_Funding_Allocation__c ifa : [SELECT Id, reduivy__Max_Per_Term__c, reduivy__Study_Funding__c
                FROM reduivy__Individual_Funding_Allocation__c
                WHERE Id IN: newIfaList
            ]) {
                System.Assert.areEqual(sfdMap.get(ifa.reduivy__Study_Funding__c).reduivy__Max_Per_Term__c, ifa.reduivy__Max_Per_Term__c);
            }
		}

        Test.stopTest();
		
    }

    /**
     * @description Test skip inheriting default max per term from study funding, this should fail with FLS as student doesn't have right to set max per term on ifa
     */
    @IsTest
    static void testSkipDefaultFromStudyFundingAsStudent() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Max_Per_Term__c
            FROM reduivy__Study_Funding__c
        ]);

		System.runAs(ADMIN_USER){

            Integer counter = 1;
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                sfd.reduivy__Max_Per_Term__c = counter;

                counter ++;
            }

            REDU_Database_UTIL.doUpdate(sfdMap.values());
        }

        //test as student
        User studentUser = testFactory.getStudentUser();

        System.runAs(studentUser) {
            List<Contact> studentContacts = [SELECT Id
                FROM Contact 
                WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
                AND reduivy__Sample_Record_Code__c <> ''
                AND Id =: studentUser.ContactId
            ];

            List<reduivy__Individual_Funding_Allocation__c> newIfaList = new List<reduivy__Individual_Funding_Allocation__c>();
            
            for (reduivy__Study_Funding__c sfd : sfdMap.values()) {
                for (Contact student : studentContacts) {
                    reduivy__Individual_Funding_Allocation__c ifa = new reduivy__Individual_Funding_Allocation__c(
                        reduivy__Contact__c = student.Id,
                        reduivy__Study_Funding__c = sfd.Id,
                        reduivy__Status__c = IFA_Helper.STATUS_ACTIVE
                    );

                    ifa.reduivy__Max_Per_Term__c = 1000;

                    newIfaList.add(ifa);
                }
            }

            System.Assert.areEqual(false, newIfaList.isEmpty(), 'There is no record for testing.');

            try {
                REDU_Database_UTIL.doInsert(newIfaList);
            } catch (Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains('Insufficient CREATABLE access on following object(s) and field(s) - reduivy__Individual_Funding_Allocation__c: reduivy__Max_Per_Term__c'), 'Unexpected error: ' + exp.getMessage());
            }
		}

        Test.stopTest();
		
    }
	
}