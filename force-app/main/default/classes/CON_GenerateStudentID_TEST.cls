/**
 * @author      WDCi (XW)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for CON_GenerateStudentID_EXE
 * @changehistory
 * ISS-002089 04-03-2025 XW - new class
 */
@IsTest
public inherited sharing class CON_GenerateStudentID_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Integer NUMBER_OF_CONTACTS = 10;
    static final String ACC_PREFIX = 'ACC-';
    static final String CON_PREFIX = 'CON-';

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        // Create settings
        testFactory.setupDefaultSettings();
        testFactory.initFacultyData(USR_Helper.getApiName(), true);
        testFactory.initStudentData(USR_Helper.getApiName(), true);

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();
        	
            reduivy__System_Variable__c syv = new reduivy__System_Variable__c();
            syv.reduivy__Format__c = 'STUD-{0000}';
            syv.reduivy__Number__c = 0;
            syv.Name = CON_GenerateStudentID_EXE.KEY_STUDENT_ID;

            insert syv;
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for insert first batch of students with generate student id checked
     */
    @IsTest
    static void testAsAdminInsertFirstBatch() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> conList = new List<Contact>();
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = ACC_PREFIX + String.valueOf(i);
            Account acc = REDU_TestData_UTIL.newAdministrativeAccount(name, name);
            accList.add(acc);
        }

        insert accList;

        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = CON_PREFIX + String.valueOf(i);
            Contact con = REDU_TestData_UTIL.newStudentContact(name, accList[i].Id, CON_PREFIX, String.valueOf(i), String.valueOf(i) + '@example.com', null);
            con.reduivy__Generate_Student_ID__c = true;
            conList.add(con);
        }

        Test.startTest();
        
        insert conList;

        Test.stopTest();
		
        Integer i = 1;
        for(Contact conAfter : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList]){
            
            System.Assert.areEqual(true, conAfter.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.areEqual('STUD-' + String.valueOf(i).leftPad(4, '0'), conAfter.reduivy__Student_ID__c, 'Wrong Student ID generated for ' + conAfter.Name + '!');
            i++;
        }

        reduivy__System_Variable__c syvAfter = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(NUMBER_OF_CONTACTS, syvAfter.reduivy__Number__c, 'Student ID should be generated!');
    }

    /**
     * @description Test as admin for update first batch of students to generate student id
     */
    @IsTest
    static void testAsAdminUpdateFirstBatch() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> conList = new List<Contact>();
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = ACC_PREFIX + String.valueOf(i);
            Account acc = REDU_TestData_UTIL.newAdministrativeAccount(name, name);
            accList.add(acc);
        }

        insert accList;

        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = CON_PREFIX + String.valueOf(i);
            Contact con = REDU_TestData_UTIL.newStudentContact(name, accList[i].Id, CON_PREFIX, String.valueOf(i), String.valueOf(i) + '@example.com', null);
            con.reduivy__Generate_Student_ID__c = false;
            conList.add(con);
        }

        insert conList;

        //student id should not be generated yet before update
        for(Contact conBefore : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList]){
            
            System.Assert.areEqual(false, conBefore.reduivy__Generate_Student_ID__c, 'Generate Student ID should not be true!');
            System.Assert.isNull(conBefore.reduivy__Student_ID__c, 'Student ID should not be generated yet!');
        }

        reduivy__System_Variable__c syvBefore = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(0, syvBefore.reduivy__Number__c, 'Student ID should not be generated yet!');
        
        Test.startTest();
        
        for(Contact con : conList) {
            con.reduivy__Generate_Student_Id__c = true;
        }
		System.runAs(ADMIN_USER){
            update conList;
		}

        Test.stopTest();
		
        Integer i = 1;
        for(Contact conAfter : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList]){
            
            System.Assert.areEqual(true, conAfter.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.areEqual('STUD-' + String.valueOf(i).leftPad(4, '0'), conAfter.reduivy__Student_ID__c, 'Wrong Student ID generated for ' + conAfter.Name + '!');
            i++;
        }

        reduivy__System_Variable__c syvAfter = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(NUMBER_OF_CONTACTS, syvAfter.reduivy__Number__c, 'Student ID should be generated!');
    }

    /**
     * @description Test as admin for insert second batch of students with generate student id checked
     */
    @IsTest
    static void testAsAdminInsertSecondBatch() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> conList1 = new List<Contact>();
        List<Contact> conList2 = new List<Contact>();
        List<Account> accList = new List<Account>();
        
        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = ACC_PREFIX + String.valueOf(i);
            Account acc = REDU_TestData_UTIL.newAdministrativeAccount(name, name);
            accList.add(acc);
        }

        insert accList;

        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = CON_PREFIX + String.valueOf(i);
            Contact con = REDU_TestData_UTIL.newStudentContact(name, accList[i].Id, CON_PREFIX, String.valueOf(i), String.valueOf(i) + '@example.com', null);
            con.reduivy__Generate_Student_ID__c = true;

            if(i < NUMBER_OF_CONTACTS / 2)
                conList1.add(con);
            else {
                conList2.add(con);
            }
        }

        insert conList1;
		
        Integer i = 0;
        for(Contact conAfter : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList1]){
            i++;
            System.Assert.areEqual(true, conAfter.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.areEqual('STUD-' + String.valueOf(i).leftPad(4, '0'), conAfter.reduivy__Student_ID__c, 'Wrong Student ID generated for ' + conAfter.Name + '!');
        }

        reduivy__System_Variable__c syvAfter = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(NUMBER_OF_CONTACTS / 2, syvAfter.reduivy__Number__c, 'Student ID should be generated!');


        Test.startTest();

        System.runAs(ADMIN_USER) {
            insert conList2;
        }

        Test.stopTest();

        for(Contact conAfter2 : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList2]){
            i++;
            System.Assert.areEqual(true, conAfter2.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.areEqual('STUD-' + String.valueOf(i).leftPad(4, '0'), conAfter2.reduivy__Student_ID__c, 'Wrong Student ID generated for ' + conAfter2.Name + '!');
        }

        reduivy__System_Variable__c syvAfter2 = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(NUMBER_OF_CONTACTS, syvAfter2.reduivy__Number__c, 'Student ID should be generated!');

        
    }

    /**
     * @description Test as admin for update second batch of students to generate student id 
     */
    @IsTest
    static void testAsAdminUpdateSecondBatch() {


        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> conList1 = new List<Contact>();
        List<Contact> conList2 = new List<Contact>();
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = ACC_PREFIX + String.valueOf(i);
            Account acc = REDU_TestData_UTIL.newAdministrativeAccount(name, name);
            accList.add(acc);
        }

        insert accList;

        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = CON_PREFIX + String.valueOf(i);
            Contact con = REDU_TestData_UTIL.newStudentContact(name, accList[i].Id, CON_PREFIX, String.valueOf(i), String.valueOf(i) + '@example.com', null);
            con.reduivy__Generate_Student_ID__c = false;
            if(i < NUMBER_OF_CONTACTS / 2) {
                conList1.add(con);
                con.reduivy__Generate_Student_ID__c = true; 
            }
            else {
                conList2.add(con);
            }
        }

        insert conList1;

        Integer i = 0;
        //student id should be generated before second batch
        for(Contact conBefore : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList1]){
            i++;
            System.Assert.areEqual(true, conBefore.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.areEqual('STUD-' + String.valueOf(i).leftPad(4, '0'), conBefore.reduivy__Student_ID__c, 'Student ID should be generated!');
        }

        reduivy__System_Variable__c syvBefore = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(NUMBER_OF_CONTACTS / 2, syvBefore.reduivy__Number__c, 'Student ID should not be generated yet!');
        
        insert conList2;

        //student id should not be generated yet before update
        for(Contact conBefore : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList2]){
            
            System.Assert.areEqual(false, conBefore.reduivy__Generate_Student_ID__c, 'Generate Student ID should not be true!');
            System.Assert.isNull(conBefore.reduivy__Student_ID__c, 'Student ID should not be generated yet!');
        }

        Test.startTest();
        
        for(Contact con : conList2) {
            con.reduivy__Generate_Student_Id__c = true;
        }
		System.runAs(ADMIN_USER){
            update conList2;
		}

        Test.stopTest();
		
        for(Contact conAfter : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList2]){
            i++;
            System.Assert.areEqual(true, conAfter.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.areEqual('STUD-' + String.valueOf(i).leftPad(4, '0'), conAfter.reduivy__Student_ID__c, 'Wrong Student ID generated for ' + conAfter.Name + '!');
        }

        reduivy__System_Variable__c syvAfter = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(NUMBER_OF_CONTACTS, syvAfter.reduivy__Number__c, 'Student ID should be generated!');
		
    }
	
    /**
     * @description Test as faculty for insert first batch of students with generate student id checked
     */
	@IsTest
    static void testAsFacultyInsertFirstBatch() {
		
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> conList = new List<Contact>();
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = ACC_PREFIX + String.valueOf(i);
            Account acc = REDU_TestData_UTIL.newAdministrativeAccount(name, name);
            accList.add(acc);
        }

        insert accList;

        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = CON_PREFIX + String.valueOf(i);
            Contact con = REDU_TestData_UTIL.newStudentContact(name, accList[i].Id, CON_PREFIX, String.valueOf(i), String.valueOf(i) + '@example.com', null);
            con.reduivy__Generate_Student_ID__c = true;
            conList.add(con);
        }

        Test.startTest();
        System.runAs(FACULTY_USER) {
            insert conList;
        }
        Test.stopTest();
		
        Integer i = 1;
        for(Contact conAfter : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList]){
            
            System.Assert.areEqual(true, conAfter.reduivy__Generate_Student_ID__c, 'SGenerate Student ID should be true!');
            System.Assert.isNull(conAfter.reduivy__Student_ID__c, 'Student ID should not be generated by Faculty!');
            i++;
        }

        reduivy__System_Variable__c syvAfter = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(0, syvAfter.reduivy__Number__c, 'Student ID should not be generated!');
		
    }

    /**
     * @description Test as faculty for update first batch of students to generate student id
     */
    @IsTest
    static void testAsFacultyUpdateFirstBatch() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> conList = new List<Contact>();
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = ACC_PREFIX + String.valueOf(i);
            Account acc = REDU_TestData_UTIL.newAdministrativeAccount(name, name);
            accList.add(acc);
        }

        insert accList;

        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = CON_PREFIX + String.valueOf(i);
            Contact con = REDU_TestData_UTIL.newStudentContact(name, accList[i].Id, CON_PREFIX, String.valueOf(i), String.valueOf(i) + '@example.com', null);
            con.reduivy__Generate_Student_ID__c = false;
            conList.add(con);
        }

        insert conList;

        //student id should not be generated yet before update
        for(Contact conBefore : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList]){
            
            System.Assert.areEqual(false, conBefore.reduivy__Generate_Student_ID__c, 'Generate Student ID should not be true!');
            System.Assert.isNull(conBefore.reduivy__Student_ID__c, 'Student ID should not be generated yet!');
        }

        reduivy__System_Variable__c syvBefore = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(0, syvBefore.reduivy__Number__c, 'Student ID should not be generated yet!');
        
        Test.startTest();
        
        for(Contact con : conList) {
            con.reduivy__Generate_Student_Id__c = true;
        }
		System.runAs(FACULTY_USER){
            update conList;
		}

        Test.stopTest();
		
        Integer i = 1;
        for(Contact conAfter : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList]){
            
            System.Assert.areEqual(true, conAfter.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.isNull(conAfter.reduivy__Student_ID__c, 'Student ID should not be generated by Faculty!');
            i++;
        }

        reduivy__System_Variable__c syvAfter = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(0, syvAfter.reduivy__Number__c, 'Student ID should not be generated!');
    }

    /**
     * @description Test as faculty for insert second batch of students with generate student id checked
     */
    @IsTest
    static void testAsFacultyInsertSecondBatch() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> conList1 = new List<Contact>();
        List<Contact> conList2 = new List<Contact>();
        List<Account> accList = new List<Account>();
        
        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = ACC_PREFIX + String.valueOf(i);
            Account acc = REDU_TestData_UTIL.newAdministrativeAccount(name, name);
            accList.add(acc);
        }

        insert accList;

        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = CON_PREFIX + String.valueOf(i);
            Contact con = REDU_TestData_UTIL.newStudentContact(name, accList[i].Id, CON_PREFIX, String.valueOf(i), String.valueOf(i) + '@example.com', null);
            con.reduivy__Generate_Student_ID__c = true;

            if(i < NUMBER_OF_CONTACTS / 2)
                conList1.add(con);
            else {
                conList2.add(con);
            }
        }

        insert conList1;
		
        Integer i = 0;
        for(Contact conAfter : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList1]){
            i++;
            System.Assert.areEqual(true, conAfter.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.areEqual('STUD-' + String.valueOf(i).leftPad(4, '0'), conAfter.reduivy__Student_ID__c, 'Wrong Student ID generated for ' + conAfter.Name + '!');
        }

        reduivy__System_Variable__c syvAfter = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(NUMBER_OF_CONTACTS / 2, syvAfter.reduivy__Number__c, 'Student ID should be generated!');


        Test.startTest();

        System.runAs(FACULTY_USER) {
            insert conList2;
        }

        Test.stopTest();

        for(Contact conAfter2 : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList2]){
            i++;
            System.Assert.areEqual(true, conAfter2.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.isNull(conAfter2.reduivy__Student_ID__c, 'Student ID should not be generated!');
        }

        reduivy__System_Variable__c syvAfter2 = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(NUMBER_OF_CONTACTS / 2, syvAfter2.reduivy__Number__c, 'Student ID should not be generated!');

        
    }

    /**
     * @description Test as faculty for update second batch of students to generate student id
     */
    @IsTest
    static void testAsFacultyUpdateSecondBatch() {


        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> conList1 = new List<Contact>();
        List<Contact> conList2 = new List<Contact>();
        List<Account> accList = new List<Account>();
        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = ACC_PREFIX + String.valueOf(i);
            Account acc = REDU_TestData_UTIL.newAdministrativeAccount(name, name);
            accList.add(acc);
        }

        insert accList;

        for(Integer i = 0; i < NUMBER_OF_CONTACTS; i++) {
            String name = CON_PREFIX + String.valueOf(i);
            Contact con = REDU_TestData_UTIL.newStudentContact(name, accList[i].Id, CON_PREFIX, String.valueOf(i), String.valueOf(i) + '@example.com', null);
            con.reduivy__Generate_Student_ID__c = false;
            if(i < NUMBER_OF_CONTACTS / 2) {
                conList1.add(con);
                con.reduivy__Generate_Student_ID__c = true; 
            }
            else {
                conList2.add(con);
            }
        }

        insert conList1;

        Integer i = 0;
        //student id should be generated before second batch
        for(Contact conBefore : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList1]){
            i++;
            System.Assert.areEqual(true, conBefore.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.areEqual('STUD-' + String.valueOf(i).leftPad(4, '0'), conBefore.reduivy__Student_ID__c, 'Student ID should be generated!');
        }

        reduivy__System_Variable__c syvBefore = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(NUMBER_OF_CONTACTS / 2, syvBefore.reduivy__Number__c, 'Student ID should not be generated yet!');
        
        insert conList2;

        //student id should not be generated yet before update
        for(Contact conBefore : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList2]){
            
            System.Assert.areEqual(false, conBefore.reduivy__Generate_Student_ID__c, 'Generate Student ID should not be true!');
            System.Assert.isNull(conBefore.reduivy__Student_ID__c, 'Student ID should not be generated yet!');
        }

        Test.startTest();
        
        for(Contact con : conList2) {
            con.reduivy__Generate_Student_Id__c = true;
        }
		System.runAs(FACULTY_USER){
            update conList2;
		}

        Test.stopTest();
		
        for(Contact conAfter : [SELECT Id, Name, reduivy__Student_ID__c, reduivy__Generate_Student_ID__c FROM Contact WHERE Id IN :conList2]){
            i++;
            System.Assert.areEqual(true, conAfter.reduivy__Generate_Student_ID__c, 'Generate Student ID should be true!');
            System.Assert.isNull(conAfter.reduivy__Student_ID__c, 'Student ID should not be generated!');
        }

        reduivy__System_Variable__c syvAfter = [SELECT Id, 
            reduivy__Number__c,
            reduivy__Format__c, 
            Name 
            FROM reduivy__System_Variable__c 
            WHERE Name = :CON_GenerateStudentID_EXE.KEY_STUDENT_ID
            LIMIT 1
        ];

        System.Assert.areEqual(NUMBER_OF_CONTACTS / 2, syvAfter.reduivy__Number__c, 'Student ID should be generated!');
		
    }

}