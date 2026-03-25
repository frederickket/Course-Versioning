/**
 * @author      WDCi (XiRouh)
 * @date        Dec 2025
 * @group       Test
 * @description Test class for IEN_AcademicProfile_EXE
 * @changehistory
 * ISS-002743 XiRouh 08-12-2025 - New class
 */
@isTest
public inherited sharing class IEN_AcademicProfile_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static final String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {

            Test.startTest();

            testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test new individual enrollment with valid IPE and study plan structure - single match as admin
     */
    @IsTest
    static void testNewIenWithValidIpeAndStudyPlanStructureAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS101'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        
        // Create individual academic profiles for the students
        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
        }

        insert newIpfMap.values();

        // Create individual program enrollments
        for (Contact student: studentContacts) {
            String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
            
            newIpeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    academicTerm.Id,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    newIpfMap.get(ipfKey).Id
                )
            );
        }

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {
            //Create individual enrollments for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    newIenList.add(
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null,
                            null,
                            null,
                            3,
                            null,
                            null,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), ienMap.size());

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'Individual Academic Profile should be set');
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, 
                ien.reduivy__Individual_Academic_Profile__c,
                'Individual Academic Profile should match the IPE profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test individual enrollment with multiple matching IPEs - should error as admin
     */
    @IsTest
    static void testIenWithMultipleMatchingIpesAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS103'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Program_Enrollment__c> newIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

        
        Contact student = studentContacts[0];
        
        // Create two individual academic profiles for the student
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_Profile1',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_Profile1',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_Profile1',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );
        
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_Profile2',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_Profile2',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_Profile2',
                IPF_Helper.STATUS_ACTIVE,
                false
            )
        );

        insert newIpfMap.values();

        // Create two individual program enrollments with the same study plan
        newIpeList.add(
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id
            )
        );
        
        newIpeList.add(
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id
            )
        );

        insert newIpeList;

        System.runAs(ADMIN_USER) {

            //Try to create individual enrollment - should error
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        null,
                        true
                    )
                );
            }

            try {
                insert newIenList;

                System.Assert.fail('This should fail with error.');
            } catch (DmlException exp) {
                String expectedError = String.format(Label.Multiple_Matching_Record_Found, new List<String>{IPF_Helper.getObjectLabel()});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test individual enrollment with no matching IPE - should error as admin
     */
    @IsTest
    static void testIenWithNoMatchingIpeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'COM101'
            LIMIT 1
        ];

        
        Contact student = studentContacts[0];

        //Try to create individual enrollment without any IPE - should error
        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Unit__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c = :studyUnit.Id
            LIMIT 1
        ]) {
            newIenList.add(
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    student.Id,
                    sof.Id,
                    IEN_INPROGRESS_STATUS,
                    1,
                    System.today(),
                    null,
                    null,
                    null,
                    3,
                    null,
                    null,
                    true
                )
            );
        }

        System.runAs(ADMIN_USER) {

            try {
                insert newIenList;

                System.Assert.fail('This should fail with error.');
            } catch (DmlException exp) {
                String expectedError = String.format(Label.No_Active_Record_Found, new List<String>{IPE_Helper.getObjectLabel(), IPF_Helper.getObjectLabel()});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test individual enrollment with unit not in study plan structure - should error as admin
     */
    @IsTest
    static void testIenWithUnitNotInStudyPlanStructureAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Educational_Institution__c
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Account campus = [SELECT Id 
            FROM Account 
            WHERE reduivy__Sample_Record_Code__c = 'SYDNEY' 
            LIMIT 1
        ];

        reduivy__Study_Unit__c testSunNotInSps = REDU_TestData_UTIL.newStudyUnit(
            'TEST_SUN', 
            academicTerm.reduivy__Educational_Institution__c, 
            null, 
            'TEST_SUN', 
            'TEST_SUN', 
            10, 
            null, 
            null, 
            null, 
            null
        );

        insert testSunNotInSps;

        reduivy__Study_Offering__c testSof = REDU_TestData_UTIL.newStudyOffering(
            'TEST_SOF', 
            testSunNotInSps.Id,
            academicTerm.Id, 
            campus.Id,
            'TEST_SOF',
            20,
            System.today(),
            System.today().addDays(10)
        );

        insert testSof;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        Contact student = studentContacts[0];
        
        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment
        String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
        
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(ipfKey).Id
            )
        );

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {

            //Try to create individual enrollment with unit not in structure - should error
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            
            newIenList.add(
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + testSof.Id,
                    student.Id,
                    testSof.Id,
                    IEN_INPROGRESS_STATUS,
                    1,
                    System.today(),
                    null,
                    null,
                    null,
                    3,
                    null,
                    null,
                    true
                )
            );
            
            try {
                insert newIenList;

                System.Assert.fail('This should fail with error.');
            } catch (DmlException exp) {
                String expectedError = String.format(Label.No_Matching_Record_Found, new List<String>{IPF_Helper.getObjectLabel()});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test bulk new individual enrollments with valid IPE and study plan structure as admin
     */
    @IsTest
    static void testBulkNewIenWithValidIpeAndStudyPlanStructureAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get multiple study units from structure
        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c IN ('BUS101', 'BUS102', 'BUS103', 'COM101')
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        
        // Create individual academic profiles for the students
        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
        }

        insert newIpfMap.values();

        // Create individual program enrollments
        for (Contact student: studentContacts) {
            String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
            
            newIpeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    academicTerm.Id,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    newIpfMap.get(ipfKey).Id
                )
            );
        }

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {

            //Create multiple individual enrollments for all students across all units
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN :studyUnits
            ]) {
                for (Contact student : studentContacts) {
                    newIenList.add(
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null,
                            null,
                            null,
                            3,
                            null,
                            null,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ];

        System.Assert.isTrue(ienList.size() > studentContacts.size(), 'Should have multiple enrollments per student');

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'Individual Academic Profile should be set');
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, 
                ien.reduivy__Individual_Academic_Profile__c,
                'Individual Academic Profile should match the IPE profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test update IEN target unit - should trigger IPF lookup as admin
     */
    @IsTest
    static void testUpdateIenTargetUnitAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get two study units from structure
        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c IN ('BUS101', 'COM101')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        Contact student = studentContacts[0];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        reduivy__Individual_Enrollment__c ien;

        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment
        String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
        
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(ipfKey).Id
            )
        );

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {

            //Create individual enrollment with BUS101
            List<reduivy__Study_Offering__c> sofList = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN :studyUnits
                ORDER BY reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            ];

            ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sofList[0].reduivy__Sample_Record_Code__c,
                student.Id,
                sofList[0].Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                null,
                null,
                null,
                3,
                null,
                newIpfMap.get(ipfKey).Id,
                true
            );

            insert ien;

            // Update to COM101 offering - should re-trigger IPF lookup
            ien.reduivy__Study_Offering__c = sofList[1].Id;
            ien.reduivy__Individual_Academic_Profile__c = null; // Clear IPF to trigger
            update ien;
        }

        reduivy__Individual_Enrollment__c updatedIen = [
            SELECT Id,
            reduivy__Study_Offering__c,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id = :ien.Id
        ];

        System.Assert.isNotNull(updatedIen.reduivy__Individual_Academic_Profile__c, 'IPF should be set after unit change');
        System.Assert.areEqual(
            newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
            updatedIen.reduivy__Individual_Academic_Profile__c,
            'IPF should still match the profile'
        );

        Test.stopTest();
    }

    /**
     * @description Test update IEN with IPF already set - should not trigger as admin
     */
    @IsTest
    static void testUpdateIenWithIpfAlreadySetAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS103'
            LIMIT 1
        ];

        Contact student = studentContacts[0];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        reduivy__Individual_Enrollment__c ien;

        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment
        String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
        
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(ipfKey).Id
            )
        );

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {

            //Create individual enrollment with IPF
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                null,
                null,
                null,
                3,
                null,
                newIpfMap.get(ipfKey).Id,
                true
            );

            insert ien;

            Id originalIpfId = ien.reduivy__Individual_Academic_Profile__c;

            // Update some other field but keep IPF - should not re-trigger
            ien.reduivy__Enrollment_Status__c = IEN_Helper.getCompletedStatuses().get(0);
            update ien;

            reduivy__Individual_Enrollment__c updatedIen = [
                SELECT Id,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ien.Id
            ];

            System.Assert.areEqual(originalIpfId, updatedIen.reduivy__Individual_Academic_Profile__c, 'IPF should remain unchanged');
            System.Assert.areEqual(IEN_Helper.getCompletedStatuses().get(0), updatedIen.reduivy__Enrollment_Status__c, 'Status should be updated');
        }

        Test.stopTest();
    }

    /**
     * @description Test bulk update IENs with cleared IPF field as admin
     */
    @IsTest
    static void testBulkUpdateIenWithClearedIpfAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS101'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        // Create individual academic profiles for the students
        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
        }

        insert newIpfMap.values();

        // Create individual program enrollments
        for (Contact student: studentContacts) {
            String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
            
            newIpeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    academicTerm.Id,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    newIpfMap.get(ipfKey).Id
                )
            );
        }

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {

            //Create individual enrollments with IPF
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            for (Contact student : studentContacts) {
                String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
                ienList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        newIpfMap.get(ipfKey).Id,
                        true
                    )
                );
            }

            insert ienList;

            // Clear IPF and update - should re-trigger IPF lookup
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Individual_Academic_Profile__c = null;
            }

            update ienList;
        }

        List<reduivy__Individual_Enrollment__c> updatedIenList = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienList
        ];

        System.Assert.areEqual(studentContacts.size(), updatedIenList.size());

        for (reduivy__Individual_Enrollment__c ien : updatedIenList) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'IPF should be set after bulk update');
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
                ien.reduivy__Individual_Academic_Profile__c,
                'IPF should match the correct profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test update IEN contact - should trigger IPF lookup as admin
     */
    @IsTest
    static void testUpdateIenContactAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        Contact student1 = studentContacts[0];
        Contact student2 = studentContacts[1];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        reduivy__Individual_Enrollment__c ien;

        // Create individual academic profile
        newIpfMap.put(
            student1.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student1.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student1.Id,
                student1.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        newIpfMap.put(
            student2.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student2.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student2.Id,
                student2.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment for student2            
        newIpeMap.put(
            student2.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student2.reduivy__Sample_Record_Code__c + '_IPE',
                student2.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(student2.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id
            )
        );

        insert newIpeMap.values();

        System.runAs(ADMIN_USER) {

            //Create individual enrollment for student1 (without IPF)
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student1.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student1.Id,
                sof.Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                null,
                null,
                null,
                3,
                null,
                newIpfMap.get(student1.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, // Set initial IPF to bypass trigger
                true
            );

            insert ien;

            // Update contact to student2 - should trigger IPF lookup
            ien.reduivy__Contact__c = student2.Id;
            ien.reduivy__Individual_Academic_Profile__c = null; // Clear IPF to trigger
            update ien;
        }

        reduivy__Individual_Enrollment__c updatedIen = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id = :ien.Id
        ];

        System.Assert.areEqual(student2.Id, updatedIen.reduivy__Contact__c, 'Contact should be updated');
        System.Assert.isNotNull(updatedIen.reduivy__Individual_Academic_Profile__c, 'IPF should be set after contact change');
        System.Assert.areEqual(
            newIpfMap.get(student2.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
            updatedIen.reduivy__Individual_Academic_Profile__c,
            'IPF should match student2 profile'
        );

        Test.stopTest();
    }

    /**
     * @description Test that IEN is linked to master IPE's IPF when unit matches child IPE's study plan as admin
     */
    @IsTest
    static void testIenLinkedToMasterIpfViaChildIpeMatchAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
                
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get two different study plans
        //Master IPE will have studyPlan1 (which doesn't contain the test unit)
        //Child IPE will have studyPlan2 (which DOES contain the test unit)
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c IN ('BACBIS_MajorA', 'BACBIS_MinorA')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        System.Assert.areEqual(2, studyPlans.size(), 'Should have 2 study plans');

        reduivy__Study_Plan__c masterStudyPlan = studyPlans[0]; // BACBIS_MajorA
        reduivy__Study_Plan__c childStudyPlan = studyPlans[1];  // BACBIS_MinorA

        //Get a study unit that exists in childStudyPlan but not in masterStudyPlan
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        System.Assert.isNotNull(studyUnit, 'Study unit BUS102 should exist');

        List<reduivy__Study_Plan_Structure__c> spsList = [
            SELECT Id, reduivy__Study_Plan__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE (reduivy__Study_Plan__c = :childStudyPlan.Id OR reduivy__Study_Plan__c = :masterStudyPlan.Id)
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        List<reduivy__Study_Plan_Structure__c> masterSps = new List<reduivy__Study_Plan_Structure__c>();
        List<reduivy__Study_Plan_Structure__c> childSps = new List<reduivy__Study_Plan_Structure__c>();

        for(reduivy__Study_Plan_Structure__c sps : spsList) {
            if(sps.reduivy__Study_Plan__c == childStudyPlan.Id) {
                childSps.add(sps);
            } else {
                masterSps.add(sps);
            }
        }

        delete masterSps;

        System.Assert.isFalse(childSps.isEmpty(), 'BUS102 should be in child study plan');

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        Contact student = studentContacts[0];
        
        // Create individual academic profile for the student
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        String ipfKey = student.reduivy__Sample_Record_Code__c + '_MasterProfile';
        Id masterIpfId = newIpfMap.get(ipfKey).Id;

        // Create MASTER individual program enrollment with masterStudyPlan
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterIPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_MasterIPE',
                student.Id,
                masterStudyPlan.reduivy__Study_Program__c,
                masterStudyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                masterIpfId
            )
        );

        insert newIpeMap.values();

        Id masterIpeId = newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_MasterIPE').Id;

        // Create CHILD individual program enrollment with childStudyPlan
        // Note: Child IPE does NOT have its own IPF - it references master via Master_Enrollment__c
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_ChildIPE',
            REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_ChildIPE',
                student.Id,
                childStudyPlan.reduivy__Study_Program__c,
                childStudyPlan.Id,
                masterIpeId,
                IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY,
                true,
                IPE_INPROGRESS_STATUS
            )
        );

        insert newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_ChildIPE');

        //Verify the IPE structure
        List<reduivy__Individual_Program_Enrollment__c> allIpes = [
            SELECT Id, 
            reduivy__Study_Plan__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Master_Enrollment__c,
            reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            RecordTypeId
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
        ];

        System.Assert.areEqual(2, allIpes.size(), 'Should have 2 IPEs (master + child)');

        reduivy__Individual_Program_Enrollment__c masterIpe;
        reduivy__Individual_Program_Enrollment__c childIpe;

        for (reduivy__Individual_Program_Enrollment__c ipe : allIpes) {
            if (ipe.RecordTypeId == IPE_Helper.getMasterEnrollmentRecordTypeId()) {
                masterIpe = ipe;
            } else if (ipe.RecordTypeId == IPE_Helper.getChildEnrollmentRecordTypeId()) {
                childIpe = ipe;
            }
        }

        System.Assert.isNotNull(masterIpe, 'Master IPE should exist');
        System.Assert.isNotNull(childIpe, 'Child IPE should exist');
        System.Assert.areEqual(masterIpfId, masterIpe.reduivy__Individual_Academic_Profile__c, 
            'Master IPE should have IPF');
        System.Assert.isNull(childIpe.reduivy__Individual_Academic_Profile__c, 
            'Child IPE should NOT have its own IPF');
        System.Assert.areEqual(masterIpe.Id, childIpe.reduivy__Master_Enrollment__c, 
            'Child IPE should reference master IPE');
        System.Assert.areEqual(masterIpfId, childIpe.reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            'Child IPE should reference master IPF through master enrollment');

        System.runAs(ADMIN_USER) {
            //Create individual enrollment for the unit that's ONLY in child IPE's study plan
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        null, // IPF should be auto-populated
                        true
                    )
                );
            }

            System.Assert.isFalse(newIenList.isEmpty(), 'Should have IEN to insert');

            insert newIenList;
        }

        //Query and verify the created IEN
        List<reduivy__Individual_Enrollment__c> createdIens = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(1, createdIens.size(), 'Should have created 1 IEN');

        reduivy__Individual_Enrollment__c ien = createdIens[0];

        // CRITICAL ASSERTIONS
        System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 
            'IEN should have Individual Academic Profile populated');
        
        System.Assert.areEqual(masterIpfId, ien.reduivy__Individual_Academic_Profile__c,
            'IEN should be linked to MASTER IPE\'s IPF (not child IPE) even though unit was matched via child IPE\'s study plan');
        
        System.Assert.areEqual(studyUnit.Id, ien.reduivy__Target_Unit_Id__c,
            'IEN should target the correct study unit');

        Test.stopTest();
    }

    /**
     * @description Test that IEN with unit in both master and child study plans links to master IPF as admin
     */
    @IsTest
    static void testIenWithUnitInBothMasterAndChildStudyPlansAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get two different study plans that share some units
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c IN ('BACBIS_MajorA', 'BACBIS_MinorA')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        System.Assert.areEqual(2, studyPlans.size(), 'Should have 2 study plans');

        reduivy__Study_Plan__c masterStudyPlan = studyPlans[0]; // BACBIS_MajorA
        reduivy__Study_Plan__c childStudyPlan = studyPlans[1];  // BACBIS_MinorA

        //Get a study unit that exists in BOTH study plans (BUS102 is common)
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Verify the unit exists in both study plan structures
        List<reduivy__Study_Plan_Structure__c> masterSps = [
            SELECT Id 
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :masterStudyPlan.Id
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        List<reduivy__Study_Plan_Structure__c> childSps = [
            SELECT Id 
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :childStudyPlan.Id
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        System.Assert.isFalse(masterSps.isEmpty(), 'BUS102 should be in master study plan');
        System.Assert.isFalse(childSps.isEmpty(), 'BUS102 should be in child study plan');

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        Contact student = studentContacts[0];
        
        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        String ipfKey = student.reduivy__Sample_Record_Code__c + '_MasterProfile';
        Id masterIpfId = newIpfMap.get(ipfKey).Id;

        // Create MASTER IPE
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterIPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_MasterIPE',
                student.Id,
                masterStudyPlan.reduivy__Study_Program__c,
                masterStudyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                masterIpfId
            )
        );

        insert newIpeMap.values();

        Id masterIpeId = newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_MasterIPE').Id;

        // Create CHILD IPE
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_ChildIPE',
            REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_ChildIPE',
                student.Id,
                childStudyPlan.reduivy__Study_Program__c,
                childStudyPlan.Id,
                masterIpeId,
                IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY,
                true,
                IPE_INPROGRESS_STATUS
            )
        );

        insert newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_ChildIPE');

        System.runAs(ADMIN_USER) {
            //Create IEN for unit that exists in BOTH study plans
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        null,
                        true
                    )
                );
            }

            // Both point to same master IPF, so should have only 1 unique IPF
            insert newIenList;
            
            // If successful, verify it linked to master IPF
            List<reduivy__Individual_Enrollment__c> createdIens = [
                SELECT Id,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];
            
            System.Assert.areEqual(1, createdIens.size(), 'Should have created 1 IEN');
            System.Assert.areEqual(masterIpfId, createdIens[0].reduivy__Individual_Academic_Profile__c,
                'IEN should be linked to master IPF (both master and child IPE point to same IPF)');
        }

        Test.stopTest();
    }

    /**
     * @description Test new individual enrollment with valid IPE and study plan structure - single match as faculty
     */
    @IsTest
    static void testNewIenWithValidIpeAndStudyPlanStructureAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS101'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        
        // Create individual academic profiles for the students
        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
        }

        insert newIpfMap.values();

        // Create individual program enrollments
        for (Contact student: studentContacts) {
            String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
            
            newIpeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    academicTerm.Id,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    newIpfMap.get(ipfKey).Id
                )
            );
        }

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {
            //Create individual enrollments for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    newIenList.add(
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null,
                            null,
                            null,
                            3,
                            null,
                            null,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), ienMap.size());

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'Individual Academic Profile should be set');
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, 
                ien.reduivy__Individual_Academic_Profile__c,
                'Individual Academic Profile should match the IPE profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test individual enrollment with multiple matching IPEs - should error as faculty
     */
    @IsTest
    static void testIenWithMultipleMatchingIpesAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS103'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Program_Enrollment__c> newIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

        
        Contact student = studentContacts[0];
        
        // Create two individual academic profiles for the student
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_Profile1',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_Profile1',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_Profile1',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );
        
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_Profile2',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_Profile2',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_Profile2',
                IPF_Helper.STATUS_ACTIVE,
                false
            )
        );

        insert newIpfMap.values();

        // Create two individual program enrollments with the same study plan
        newIpeList.add(
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id
            )
        );
        
        newIpeList.add(
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id
            )
        );

        insert newIpeList;

        System.runAs(FACULTY_USER) {

            //Try to create individual enrollment - should error
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        null,
                        true
                    )
                );
            }

            try {
                insert newIenList;

                System.Assert.fail('This should fail with error.');
            } catch (DmlException exp) {
                String expectedError = String.format(Label.Multiple_Matching_Record_Found, new List<String>{IPF_Helper.getObjectLabel()});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test individual enrollment with no matching IPE - should error as faculty
     */
    @IsTest
    static void testIenWithNoMatchingIpeAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'COM101'
            LIMIT 1
        ];

        
        Contact student = studentContacts[0];

        //Try to create individual enrollment without any IPE - should error
        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Unit__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c = :studyUnit.Id
            LIMIT 1
        ]) {
            newIenList.add(
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    student.Id,
                    sof.Id,
                    IEN_INPROGRESS_STATUS,
                    1,
                    System.today(),
                    null,
                    null,
                    null,
                    3,
                    null,
                    null,
                    true
                )
            );
        }

        System.runAs(FACULTY_USER) {

            try {
                insert newIenList;

                System.Assert.fail('This should fail with error.');
            } catch (DmlException exp) {
                String expectedError = String.format(Label.No_Active_Record_Found, new List<String>{IPE_Helper.getObjectLabel(), IPF_Helper.getObjectLabel()});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test individual enrollment with unit not in study plan structure - should error as faculty
     */
    @IsTest
    static void testIenWithUnitNotInStudyPlanStructureAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Educational_Institution__c
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Account campus = [SELECT Id 
            FROM Account 
            WHERE reduivy__Sample_Record_Code__c = 'SYDNEY' 
            LIMIT 1
        ];

        reduivy__Study_Unit__c testSunNotInSps = REDU_TestData_UTIL.newStudyUnit(
            'TEST_SUN', 
            academicTerm.reduivy__Educational_Institution__c, 
            null, 
            'TEST_SUN', 
            'TEST_SUN', 
            10, 
            null, 
            null, 
            null, 
            null
        );

        insert testSunNotInSps;

        reduivy__Study_Offering__c testSof = REDU_TestData_UTIL.newStudyOffering(
            'TEST_SOF', 
            testSunNotInSps.Id,
            academicTerm.Id, 
            campus.Id,
            'TEST_SOF',
            20,
            System.today(),
            System.today().addDays(10)
        );

        insert testSof;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        Contact student = studentContacts[0];
        
        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment
        String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
        
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(ipfKey).Id
            )
        );

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {

            //Try to create individual enrollment with unit not in structure - should error
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            
            newIenList.add(
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + testSof.Id,
                    student.Id,
                    testSof.Id,
                    IEN_INPROGRESS_STATUS,
                    1,
                    System.today(),
                    null,
                    null,
                    null,
                    3,
                    null,
                    null,
                    true
                )
            );
            
            try {
                insert newIenList;

                System.Assert.fail('This should fail with error.');
            } catch (DmlException exp) {
                String expectedError = String.format(Label.No_Matching_Record_Found, new List<String>{IPF_Helper.getObjectLabel()});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test bulk new individual enrollments with valid IPE and study plan structure as faculty
     */
    @IsTest
    static void testBulkNewIenWithValidIpeAndStudyPlanStructureAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get multiple study units from structure
        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c IN ('BUS101', 'BUS102', 'BUS103', 'COM101')
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        
        // Create individual academic profiles for the students
        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
        }

        insert newIpfMap.values();

        // Create individual program enrollments
        for (Contact student: studentContacts) {
            String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
            
            newIpeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    academicTerm.Id,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    newIpfMap.get(ipfKey).Id
                )
            );
        }

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {

            //Create multiple individual enrollments for all students across all units
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN :studyUnits
            ]) {
                for (Contact student : studentContacts) {
                    newIenList.add(
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null,
                            null,
                            null,
                            3,
                            null,
                            null,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ];

        System.Assert.isTrue(ienList.size() > studentContacts.size(), 'Should have multiple enrollments per student');

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'Individual Academic Profile should be set');
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, 
                ien.reduivy__Individual_Academic_Profile__c,
                'Individual Academic Profile should match the IPE profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test update IEN target unit - should trigger IPF lookup as faculty
     */
    @IsTest
    static void testUpdateIenTargetUnitAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get two study units from structure
        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c IN ('BUS101', 'COM101')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        Contact student = studentContacts[0];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        reduivy__Individual_Enrollment__c ien;

        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment
        String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
        
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(ipfKey).Id
            )
        );

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {

            //Create individual enrollment with BUS101
            List<reduivy__Study_Offering__c> sofList = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN :studyUnits
                ORDER BY reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            ];

            ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sofList[0].reduivy__Sample_Record_Code__c,
                student.Id,
                sofList[0].Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                null,
                null,
                null,
                3,
                null,
                newIpfMap.get(ipfKey).Id,
                true
            );

            insert ien;

            // Update to COM101 offering - should re-trigger IPF lookup
            ien.reduivy__Study_Offering__c = sofList[1].Id;
            ien.reduivy__Individual_Academic_Profile__c = null; // Clear IPF to trigger
            update ien;
        }

        reduivy__Individual_Enrollment__c updatedIen = [
            SELECT Id,
            reduivy__Study_Offering__c,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id = :ien.Id
        ];

        System.Assert.isNotNull(updatedIen.reduivy__Individual_Academic_Profile__c, 'IPF should be set after unit change');
        System.Assert.areEqual(
            newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
            updatedIen.reduivy__Individual_Academic_Profile__c,
            'IPF should still match the profile'
        );

        Test.stopTest();
    }

    /**
     * @description Test update IEN with IPF already set - should not trigger as faculty
     */
    @IsTest
    static void testUpdateIenWithIpfAlreadySetAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS103'
            LIMIT 1
        ];

        Contact student = studentContacts[0];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        reduivy__Individual_Enrollment__c ien;

        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment
        String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
        
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(ipfKey).Id
            )
        );

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {

            //Create individual enrollment with IPF
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                null,
                null,
                null,
                3,
                null,
                newIpfMap.get(ipfKey).Id,
                true
            );

            insert ien;

            Id originalIpfId = ien.reduivy__Individual_Academic_Profile__c;

            // Update some other field but keep IPF - should not re-trigger
            ien.reduivy__Enrollment_Status__c = IEN_Helper.getCompletedStatuses().get(0);
            update ien;

            reduivy__Individual_Enrollment__c updatedIen = [
                SELECT Id,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ien.Id
            ];

            System.Assert.areEqual(originalIpfId, updatedIen.reduivy__Individual_Academic_Profile__c, 'IPF should remain unchanged');
            System.Assert.areEqual(IEN_Helper.getCompletedStatuses().get(0), updatedIen.reduivy__Enrollment_Status__c, 'Status should be updated');
        }

        Test.stopTest();
    }

    /**
     * @description Test bulk update IENs with cleared IPF field as faculty
     */
    @IsTest
    static void testBulkUpdateIenWithClearedIpfAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS101'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        // Create individual academic profiles for the students
        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
        }

        insert newIpfMap.values();

        // Create individual program enrollments
        for (Contact student: studentContacts) {
            String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
            
            newIpeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    academicTerm.Id,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    newIpfMap.get(ipfKey).Id
                )
            );
        }

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {

            //Create individual enrollments with IPF
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            for (Contact student : studentContacts) {
                String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
                ienList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        newIpfMap.get(ipfKey).Id,
                        true
                    )
                );
            }

            insert ienList;

            // Clear IPF and update - should re-trigger IPF lookup
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Individual_Academic_Profile__c = null;
            }

            update ienList;
        }

        List<reduivy__Individual_Enrollment__c> updatedIenList = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienList
        ];

        System.Assert.areEqual(studentContacts.size(), updatedIenList.size());

        for (reduivy__Individual_Enrollment__c ien : updatedIenList) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'IPF should be set after bulk update');
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
                ien.reduivy__Individual_Academic_Profile__c,
                'IPF should match the correct profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test update IEN contact - should trigger IPF lookup as faculty
     */
    @IsTest
    static void testUpdateIenContactAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 2
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        Contact student1 = studentContacts[0];
        Contact student2 = studentContacts[1];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        reduivy__Individual_Enrollment__c ien;

        // Create individual academic profile
        newIpfMap.put(
            student1.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student1.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student1.Id,
                student1.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        newIpfMap.put(
            student2.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student2.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student2.Id,
                student2.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment for student2            
        newIpeMap.put(
            student2.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student2.reduivy__Sample_Record_Code__c + '_IPE',
                student2.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(student2.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id
            )
        );

        insert newIpeMap.values();

        System.runAs(FACULTY_USER) {

            //Create individual enrollment for student1 (without IPF)
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student1.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student1.Id,
                sof.Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                null,
                null,
                null,
                3,
                null,
                newIpfMap.get(student1.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, // Set initial IPF to bypass trigger
                true
            );

            insert ien;

            // Update contact to student2 - should trigger IPF lookup
            ien.reduivy__Contact__c = student2.Id;
            ien.reduivy__Individual_Academic_Profile__c = null; // Clear IPF to trigger
            update ien;
        }

        reduivy__Individual_Enrollment__c updatedIen = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id = :ien.Id
        ];

        System.Assert.areEqual(student2.Id, updatedIen.reduivy__Contact__c, 'Contact should be updated');
        System.Assert.isNotNull(updatedIen.reduivy__Individual_Academic_Profile__c, 'IPF should be set after contact change');
        System.Assert.areEqual(
            newIpfMap.get(student2.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
            updatedIen.reduivy__Individual_Academic_Profile__c,
            'IPF should match student2 profile'
        );

        Test.stopTest();
    }

    /**
     * @description Test that IEN is linked to master IPE's IPF when unit matches child IPE's study plan as faculty
     */
    @IsTest
    static void testIenLinkedToMasterIpfViaChildIpeMatchAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
                
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get two different study plans
        //Master IPE will have studyPlan1 (which doesn't contain the test unit)
        //Child IPE will have studyPlan2 (which DOES contain the test unit)
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c IN ('BACBIS_MajorA', 'BACBIS_MinorA')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        System.Assert.areEqual(2, studyPlans.size(), 'Should have 2 study plans');

        reduivy__Study_Plan__c masterStudyPlan = studyPlans[0]; // BACBIS_MajorA
        reduivy__Study_Plan__c childStudyPlan = studyPlans[1];  // BACBIS_MinorA

        //Get a study unit that exists in childStudyPlan but not in masterStudyPlan
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        System.Assert.isNotNull(studyUnit, 'Study unit BUS102 should exist');

        List<reduivy__Study_Plan_Structure__c> spsList = [
            SELECT Id, reduivy__Study_Plan__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE (reduivy__Study_Plan__c = :childStudyPlan.Id OR reduivy__Study_Plan__c = :masterStudyPlan.Id)
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        List<reduivy__Study_Plan_Structure__c> masterSps = new List<reduivy__Study_Plan_Structure__c>();
        List<reduivy__Study_Plan_Structure__c> childSps = new List<reduivy__Study_Plan_Structure__c>();

        for(reduivy__Study_Plan_Structure__c sps : spsList) {
            if(sps.reduivy__Study_Plan__c == childStudyPlan.Id) {
                childSps.add(sps);
            } else {
                masterSps.add(sps);
            }
        }

        delete masterSps;

        System.Assert.isFalse(childSps.isEmpty(), 'BUS102 should be in child study plan');

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        Contact student = studentContacts[0];
        
        // Create individual academic profile for the student
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        String ipfKey = student.reduivy__Sample_Record_Code__c + '_MasterProfile';
        Id masterIpfId = newIpfMap.get(ipfKey).Id;

        // Create MASTER individual program enrollment with masterStudyPlan
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterIPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_MasterIPE',
                student.Id,
                masterStudyPlan.reduivy__Study_Program__c,
                masterStudyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                masterIpfId
            )
        );

        insert newIpeMap.values();

        Id masterIpeId = newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_MasterIPE').Id;

        // Create CHILD individual program enrollment with childStudyPlan
        // Note: Child IPE does NOT have its own IPF - it references master via Master_Enrollment__c
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_ChildIPE',
            REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_ChildIPE',
                student.Id,
                childStudyPlan.reduivy__Study_Program__c,
                childStudyPlan.Id,
                masterIpeId,
                IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY,
                true,
                IPE_INPROGRESS_STATUS
            )
        );

        insert newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_ChildIPE');

        //Verify the IPE structure
        List<reduivy__Individual_Program_Enrollment__c> allIpes = [
            SELECT Id, 
            reduivy__Study_Plan__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Master_Enrollment__c,
            reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            RecordTypeId
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
        ];

        System.Assert.areEqual(2, allIpes.size(), 'Should have 2 IPEs (master + child)');

        reduivy__Individual_Program_Enrollment__c masterIpe;
        reduivy__Individual_Program_Enrollment__c childIpe;

        for (reduivy__Individual_Program_Enrollment__c ipe : allIpes) {
            if (ipe.RecordTypeId == IPE_Helper.getMasterEnrollmentRecordTypeId()) {
                masterIpe = ipe;
            } else if (ipe.RecordTypeId == IPE_Helper.getChildEnrollmentRecordTypeId()) {
                childIpe = ipe;
            }
        }

        System.Assert.isNotNull(masterIpe, 'Master IPE should exist');
        System.Assert.isNotNull(childIpe, 'Child IPE should exist');
        System.Assert.areEqual(masterIpfId, masterIpe.reduivy__Individual_Academic_Profile__c, 
            'Master IPE should have IPF');
        System.Assert.isNull(childIpe.reduivy__Individual_Academic_Profile__c, 
            'Child IPE should NOT have its own IPF');
        System.Assert.areEqual(masterIpe.Id, childIpe.reduivy__Master_Enrollment__c, 
            'Child IPE should reference master IPE');
        System.Assert.areEqual(masterIpfId, childIpe.reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            'Child IPE should reference master IPF through master enrollment');

        System.runAs(FACULTY_USER) {
            //Create individual enrollment for the unit that's ONLY in child IPE's study plan
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        null, // IPF should be auto-populated
                        true
                    )
                );
            }

            System.Assert.isFalse(newIenList.isEmpty(), 'Should have IEN to insert');

            insert newIenList;
        }

        //Query and verify the created IEN
        List<reduivy__Individual_Enrollment__c> createdIens = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(1, createdIens.size(), 'Should have created 1 IEN');

        reduivy__Individual_Enrollment__c ien = createdIens[0];

        // CRITICAL ASSERTIONS
        System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 
            'IEN should have Individual Academic Profile populated');
        
        System.Assert.areEqual(masterIpfId, ien.reduivy__Individual_Academic_Profile__c,
            'IEN should be linked to MASTER IPE\'s IPF (not child IPE) even though unit was matched via child IPE\'s study plan');
        
        System.Assert.areEqual(studyUnit.Id, ien.reduivy__Target_Unit_Id__c,
            'IEN should target the correct study unit');

        Test.stopTest();
    }

    /**
     * @description Test that IEN with unit in both master and child study plans links to master IPF as faculty
     */
    @IsTest
    static void testIenWithUnitInBothMasterAndChildStudyPlansAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get two different study plans that share some units
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c IN ('BACBIS_MajorA', 'BACBIS_MinorA')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        System.Assert.areEqual(2, studyPlans.size(), 'Should have 2 study plans');

        reduivy__Study_Plan__c masterStudyPlan = studyPlans[0]; // BACBIS_MajorA
        reduivy__Study_Plan__c childStudyPlan = studyPlans[1];  // BACBIS_MinorA

        //Get a study unit that exists in BOTH study plans (BUS102 is common)
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Verify the unit exists in both study plan structures
        List<reduivy__Study_Plan_Structure__c> masterSps = [
            SELECT Id 
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :masterStudyPlan.Id
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        List<reduivy__Study_Plan_Structure__c> childSps = [
            SELECT Id 
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :childStudyPlan.Id
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        System.Assert.isFalse(masterSps.isEmpty(), 'BUS102 should be in master study plan');
        System.Assert.isFalse(childSps.isEmpty(), 'BUS102 should be in child study plan');

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        Contact student = studentContacts[0];
        
        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        String ipfKey = student.reduivy__Sample_Record_Code__c + '_MasterProfile';
        Id masterIpfId = newIpfMap.get(ipfKey).Id;

        // Create MASTER IPE
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterIPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_MasterIPE',
                student.Id,
                masterStudyPlan.reduivy__Study_Program__c,
                masterStudyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                masterIpfId
            )
        );

        insert newIpeMap.values();

        Id masterIpeId = newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_MasterIPE').Id;

        // Create CHILD IPE
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_ChildIPE',
            REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_ChildIPE',
                student.Id,
                childStudyPlan.reduivy__Study_Program__c,
                childStudyPlan.Id,
                masterIpeId,
                IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY,
                true,
                IPE_INPROGRESS_STATUS
            )
        );

        insert newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_ChildIPE');

        System.runAs(FACULTY_USER) {
            //Create IEN for unit that exists in BOTH study plans
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        null,
                        true
                    )
                );
            }

            // Both point to same master IPF, so should have only 1 unique IPF
            insert newIenList;
            
            // If successful, verify it linked to master IPF
            List<reduivy__Individual_Enrollment__c> createdIens = [
                SELECT Id,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];
            
            System.Assert.areEqual(1, createdIens.size(), 'Should have created 1 IEN');
            System.Assert.areEqual(masterIpfId, createdIens[0].reduivy__Individual_Academic_Profile__c,
                'IEN should be linked to master IPF (both master and child IPE point to same IPF)');
        }

        Test.stopTest();
    }

    /**
     * @description Test new individual enrollment with valid IPE and study plan structure - single match as student
     */
    @IsTest
    static void testNewIenWithValidIpeAndStudyPlanStructureAsStudent(){
                
        Test.startTest();
        
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
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS101'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        
        // Create individual academic profiles for the students
        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
        }

        insert newIpfMap.values();

        // Create individual program enrollments
        for (Contact student: studentContacts) {
            String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
            
            newIpeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    academicTerm.Id,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    newIpfMap.get(ipfKey).Id
                )
            );
        }

        insert newIpeMap.values();

        System.runAs(studentUser) {
            //Create individual enrollments for the students
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    newIenList.add(
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null,
                            null,
                            null,
                            3,
                            null,
                            null,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ]);

        System.Assert.areEqual(studentContacts.size(), ienMap.size());

        for (reduivy__Individual_Enrollment__c ien : ienMap.values()) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'Individual Academic Profile should be set');
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, 
                ien.reduivy__Individual_Academic_Profile__c,
                'Individual Academic Profile should match the IPE profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test individual enrollment with multiple matching IPEs - should error as student
     */
    @IsTest
    static void testIenWithMultipleMatchingIpesAsStudent(){
                
        Test.startTest();
        
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
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS103'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        List<reduivy__Individual_Program_Enrollment__c> newIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

        
        Contact student = studentContacts[0];
        
        // Create two individual academic profiles for the student
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_Profile1',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_Profile1',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_Profile1',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );
        
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_Profile2',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_Profile2',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_Profile2',
                IPF_Helper.STATUS_ACTIVE,
                false
            )
        );

        insert newIpfMap.values();

        // Create two individual program enrollments with the same study plan
        newIpeList.add(
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE1',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile1').Id
            )
        );
        
        newIpeList.add(
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE2',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_Profile2').Id
            )
        );

        insert newIpeList;

        System.runAs(studentUser) {

            //Try to create individual enrollment - should error
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        null,
                        true
                    )
                );
            }

            try {
                insert newIenList;

                System.Assert.fail('This should fail with error.');
            } catch (DmlException exp) {
                String expectedError = String.format(Label.Multiple_Matching_Record_Found, new List<String>{IPF_Helper.getObjectLabel()});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test individual enrollment with no matching IPE - should error as student
     */
    @IsTest
    static void testIenWithNoMatchingIpeAsStudent(){
                
        Test.startTest();
        
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
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'COM101'
            LIMIT 1
        ];

        
        Contact student = studentContacts[0];

        //Try to create individual enrollment without any IPE - should error
        List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Unit__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
            AND reduivy__Study_Unit__c = :studyUnit.Id
            LIMIT 1
        ]) {
            newIenList.add(
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                    student.Id,
                    sof.Id,
                    IEN_INPROGRESS_STATUS,
                    1,
                    System.today(),
                    null,
                    null,
                    null,
                    3,
                    null,
                    null,
                    true
                )
            );
        }

        System.runAs(studentUser) {

            try {
                insert newIenList;

                System.Assert.fail('This should fail with error.');
            } catch (DmlException exp) {
                String expectedError = String.format(Label.No_Active_Record_Found, new List<String>{IPE_Helper.getObjectLabel(), IPF_Helper.getObjectLabel()});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test individual enrollment with unit not in study plan structure - should error as student
     */
    @IsTest
    static void testIenWithUnitNotInStudyPlanStructureAsStudent(){
                
        Test.startTest();
        
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
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Educational_Institution__c
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Account campus = [SELECT Id 
            FROM Account 
            WHERE reduivy__Sample_Record_Code__c = 'SYDNEY' 
            LIMIT 1
        ];

        reduivy__Study_Unit__c testSunNotInSps = REDU_TestData_UTIL.newStudyUnit(
            'TEST_SUN', 
            academicTerm.reduivy__Educational_Institution__c, 
            null, 
            'TEST_SUN', 
            'TEST_SUN', 
            10, 
            null, 
            null, 
            null, 
            null
        );

        insert testSunNotInSps;

        reduivy__Study_Offering__c testSof = REDU_TestData_UTIL.newStudyOffering(
            'TEST_SOF', 
            testSunNotInSps.Id,
            academicTerm.Id, 
            campus.Id,
            'TEST_SOF',
            20,
            System.today(),
            System.today().addDays(10)
        );

        insert testSof;

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        Contact student = studentContacts[0];
        
        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment
        String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
        
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(ipfKey).Id
            )
        );

        insert newIpeMap.values();

        System.runAs(studentUser) {

            //Try to create individual enrollment with unit not in structure - should error
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            
            newIenList.add(
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_' + testSof.Id,
                    student.Id,
                    testSof.Id,
                    IEN_INPROGRESS_STATUS,
                    1,
                    System.today(),
                    null,
                    null,
                    null,
                    3,
                    null,
                    null,
                    true
                )
            );
            
            try {
                insert newIenList;

                System.Assert.fail('This should fail with error.');
            } catch (DmlException exp) {
                String expectedError = String.format(Label.No_Matching_Record_Found, new List<String>{IPF_Helper.getObjectLabel()});

                System.Assert.isTrue(exp.getMessage().contains(expectedError), 'Invalid expected message: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test bulk new individual enrollments with valid IPE and study plan structure as student
     */
    @IsTest
    static void testBulkNewIenWithValidIpeAndStudyPlanStructureAsStudent(){
                
        Test.startTest();
        
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
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get multiple study units from structure
        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c IN ('BUS101', 'BUS102', 'BUS103', 'COM101')
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        
        // Create individual academic profiles for the students
        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
        }

        insert newIpfMap.values();

        // Create individual program enrollments
        for (Contact student: studentContacts) {
            String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
            
            newIpeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    academicTerm.Id,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    newIpfMap.get(ipfKey).Id
                )
            );
        }

        insert newIpeMap.values();

        System.runAs(studentUser) {

            //Create multiple individual enrollments for all students across all units
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN :studyUnits
            ]) {
                for (Contact student : studentContacts) {
                    newIenList.add(
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null,
                            null,
                            null,
                            3,
                            null,
                            null,
                            true
                        )
                    );
                }
            }

            insert newIenList;
        }

        List<reduivy__Individual_Enrollment__c> ienList = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c IN: studentContacts
        ];

        System.Assert.isTrue(ienList.size() > studentContacts.size(), 'Should have multiple enrollments per student');

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'Individual Academic Profile should be set');
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id, 
                ien.reduivy__Individual_Academic_Profile__c,
                'Individual Academic Profile should match the IPE profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test update IEN target unit - should trigger IPF lookup as student
     */
    @IsTest
    static void testUpdateIenTargetUnitAsStudent(){
                
        Test.startTest();
        
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
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get two study units from structure
        List<reduivy__Study_Unit__c> studyUnits = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c IN ('BUS101', 'COM101')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        Contact student = studentContacts[0];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        reduivy__Individual_Enrollment__c ien;

        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment
        String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
        
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(ipfKey).Id
            )
        );

        insert newIpeMap.values();

        System.runAs(studentUser) {

            //Create individual enrollment with BUS101
            List<reduivy__Study_Offering__c> sofList = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN :studyUnits
                ORDER BY reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            ];

            ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sofList[0].reduivy__Sample_Record_Code__c,
                student.Id,
                sofList[0].Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                null,
                null,
                null,
                3,
                null,
                newIpfMap.get(ipfKey).Id,
                true
            );

            insert ien;

            // Update to COM101 offering - should re-trigger IPF lookup
            ien.reduivy__Study_Offering__c = sofList[1].Id;
            ien.reduivy__Individual_Academic_Profile__c = null; // Clear IPF to trigger
            update ien;
        }

        reduivy__Individual_Enrollment__c updatedIen = [
            SELECT Id,
            reduivy__Study_Offering__c,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id = :ien.Id
        ];

        System.Assert.isNotNull(updatedIen.reduivy__Individual_Academic_Profile__c, 'IPF should be set after unit change');
        System.Assert.areEqual(
            newIpfMap.get(student.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
            updatedIen.reduivy__Individual_Academic_Profile__c,
            'IPF should still match the profile'
        );

        Test.stopTest();
    }

    /**
     * @description Test update IEN with IPF already set - should not trigger as student
     */
    @IsTest
    static void testUpdateIenWithIpfAlreadySetAsStudent(){
                
        Test.startTest();
        
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
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS103'
            LIMIT 1
        ];

        Contact student = studentContacts[0];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        reduivy__Individual_Enrollment__c ien;

        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        // Create individual program enrollment
        String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
        
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_IPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                student.Id,
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                newIpfMap.get(ipfKey).Id
            )
        );

        insert newIpeMap.values();

        System.runAs(studentUser) {

            //Create individual enrollment with IPF
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                student.Id,
                sof.Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                null,
                null,
                null,
                3,
                null,
                newIpfMap.get(ipfKey).Id,
                true
            );

            insert ien;

            Id originalIpfId = ien.reduivy__Individual_Academic_Profile__c;

            // Update some other field but keep IPF - should not re-trigger
            ien.reduivy__Enrollment_Status__c = IEN_Helper.getCompletedStatuses().get(0);
            update ien;

            reduivy__Individual_Enrollment__c updatedIen = [
                SELECT Id,
                reduivy__Individual_Academic_Profile__c,
                reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Enrollment__c
                WHERE Id = :ien.Id
            ];

            System.Assert.areEqual(originalIpfId, updatedIen.reduivy__Individual_Academic_Profile__c, 'IPF should remain unchanged');
            System.Assert.areEqual(IEN_Helper.getCompletedStatuses().get(0), updatedIen.reduivy__Enrollment_Status__c, 'Status should be updated');
        }

        Test.stopTest();
    }

    /**
     * @description Test bulk update IENs with cleared IPF field as student
     */
    @IsTest
    static void testBulkUpdateIenWithClearedIpfAsStudent(){
                
        Test.startTest();
        
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
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get study plan with structure
        reduivy__Study_Plan__c studyPlan = [SELECT Id,
            reduivy__Sample_Record_Code__c, 
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        //Get study unit from structure
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS101'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> ienList = new List<reduivy__Individual_Enrollment__c>();

        // Create individual academic profiles for the students
        for (Contact student: studentContacts) {
            newIpfMap.put(
                student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_PrimaryProfile',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
        }

        insert newIpfMap.values();

        // Create individual program enrollments
        for (Contact student: studentContacts) {
            String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
            
            newIpeMap.put(
                student.reduivy__Sample_Record_Code__c + '_IPE',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null,
                    academicTerm.Id,
                    null,
                    null,
                    null,
                    null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    newIpfMap.get(ipfKey).Id
                )
            );
        }

        insert newIpeMap.values();

        System.runAs(studentUser) {

            //Create individual enrollments with IPF
            reduivy__Study_Offering__c sof = [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ];

            for (Contact student : studentContacts) {
                String ipfKey = student.reduivy__Sample_Record_Code__c + '_PrimaryProfile';
                ienList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        newIpfMap.get(ipfKey).Id,
                        true
                    )
                );
            }

            insert ienList;

            // Clear IPF and update - should re-trigger IPF lookup
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Individual_Academic_Profile__c = null;
            }

            update ienList;
        }

        List<reduivy__Individual_Enrollment__c> updatedIenList = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c
            WHERE Id IN :ienList
        ];

        System.Assert.areEqual(studentContacts.size(), updatedIenList.size());

        for (reduivy__Individual_Enrollment__c ien : updatedIenList) {
            System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 'IPF should be set after bulk update');
            System.Assert.areEqual(
                newIpfMap.get(ien.reduivy__Contact__r.reduivy__Sample_Record_Code__c + '_PrimaryProfile').Id,
                ien.reduivy__Individual_Academic_Profile__c,
                'IPF should match the correct profile'
            );
        }

        Test.stopTest();
    }

    /**
     * @description Test that IEN is linked to master IPE's IPF when unit matches child IPE's study plan as student
     */
    @IsTest
    static void testIenLinkedToMasterIpfViaChildIpeMatchAsStudent(){
                
        Test.startTest();
        
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
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get two different study plans
        //Master IPE will have studyPlan1 (which doesn't contain the test unit)
        //Child IPE will have studyPlan2 (which DOES contain the test unit)
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c IN ('BACBIS_MajorA', 'BACBIS_MinorA')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        System.Assert.areEqual(2, studyPlans.size(), 'Should have 2 study plans');

        reduivy__Study_Plan__c masterStudyPlan = studyPlans[0]; // BACBIS_MajorA
        reduivy__Study_Plan__c childStudyPlan = studyPlans[1];  // BACBIS_MinorA

        //Get a study unit that exists in childStudyPlan but not in masterStudyPlan
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        System.Assert.isNotNull(studyUnit, 'Study unit BUS102 should exist');

        List<reduivy__Study_Plan_Structure__c> spsList = [
            SELECT Id, reduivy__Study_Plan__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE (reduivy__Study_Plan__c = :childStudyPlan.Id OR reduivy__Study_Plan__c = :masterStudyPlan.Id)
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        List<reduivy__Study_Plan_Structure__c> masterSps = new List<reduivy__Study_Plan_Structure__c>();
        List<reduivy__Study_Plan_Structure__c> childSps = new List<reduivy__Study_Plan_Structure__c>();

        for(reduivy__Study_Plan_Structure__c sps : spsList) {
            if(sps.reduivy__Study_Plan__c == childStudyPlan.Id) {
                childSps.add(sps);
            } else {
                masterSps.add(sps);
            }
        }

        delete masterSps;

        System.Assert.isFalse(childSps.isEmpty(), 'BUS102 should be in child study plan');

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        Contact student = studentContacts[0];
        
        // Create individual academic profile for the student
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        String ipfKey = student.reduivy__Sample_Record_Code__c + '_MasterProfile';
        Id masterIpfId = newIpfMap.get(ipfKey).Id;

        // Create MASTER individual program enrollment with masterStudyPlan
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterIPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_MasterIPE',
                student.Id,
                masterStudyPlan.reduivy__Study_Program__c,
                masterStudyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                masterIpfId
            )
        );

        insert newIpeMap.values();

        Id masterIpeId = newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_MasterIPE').Id;

        // Create CHILD individual program enrollment with childStudyPlan
        // Note: Child IPE does NOT have its own IPF - it references master via Master_Enrollment__c
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_ChildIPE',
            REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_ChildIPE',
                student.Id,
                childStudyPlan.reduivy__Study_Program__c,
                childStudyPlan.Id,
                masterIpeId,
                IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY,
                true,
                IPE_INPROGRESS_STATUS
            )
        );

        insert newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_ChildIPE');

        //Verify the IPE structure
        List<reduivy__Individual_Program_Enrollment__c> allIpes = [
            SELECT Id, 
            reduivy__Study_Plan__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Master_Enrollment__c,
            reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            RecordTypeId
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
        ];

        System.Assert.areEqual(2, allIpes.size(), 'Should have 2 IPEs (master + child)');

        reduivy__Individual_Program_Enrollment__c masterIpe;
        reduivy__Individual_Program_Enrollment__c childIpe;

        for (reduivy__Individual_Program_Enrollment__c ipe : allIpes) {
            if (ipe.RecordTypeId == IPE_Helper.getMasterEnrollmentRecordTypeId()) {
                masterIpe = ipe;
            } else if (ipe.RecordTypeId == IPE_Helper.getChildEnrollmentRecordTypeId()) {
                childIpe = ipe;
            }
        }

        System.Assert.isNotNull(masterIpe, 'Master IPE should exist');
        System.Assert.isNotNull(childIpe, 'Child IPE should exist');
        System.Assert.areEqual(masterIpfId, masterIpe.reduivy__Individual_Academic_Profile__c, 
            'Master IPE should have IPF');
        System.Assert.isNull(childIpe.reduivy__Individual_Academic_Profile__c, 
            'Child IPE should NOT have its own IPF');
        System.Assert.areEqual(masterIpe.Id, childIpe.reduivy__Master_Enrollment__c, 
            'Child IPE should reference master IPE');
        System.Assert.areEqual(masterIpfId, childIpe.reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            'Child IPE should reference master IPF through master enrollment');

        System.runAs(studentUser) {
            //Create individual enrollment for the unit that's ONLY in child IPE's study plan
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        null, // IPF should be auto-populated
                        true
                    )
                );
            }

            System.Assert.isFalse(newIenList.isEmpty(), 'Should have IEN to insert');

            insert newIenList;
        }

        //Query and verify the created IEN
        List<reduivy__Individual_Enrollment__c> createdIens = [
            SELECT Id,
            reduivy__Contact__c,
            reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c = :student.Id
            AND reduivy__Target_Unit_Id__c = :studyUnit.Id
        ];

        System.Assert.areEqual(1, createdIens.size(), 'Should have created 1 IEN');

        reduivy__Individual_Enrollment__c ien = createdIens[0];

        // CRITICAL ASSERTIONS
        System.Assert.isNotNull(ien.reduivy__Individual_Academic_Profile__c, 
            'IEN should have Individual Academic Profile populated');
        
        System.Assert.areEqual(masterIpfId, ien.reduivy__Individual_Academic_Profile__c,
            'IEN should be linked to MASTER IPE\'s IPF (not child IPE) even though unit was matched via child IPE\'s study plan');
        
        System.Assert.areEqual(studyUnit.Id, ien.reduivy__Target_Unit_Id__c,
            'IEN should target the correct study unit');

        Test.stopTest();
    }

    /**
     * @description Test that IEN with unit in both master and child study plans links to master IPF as student
     */
    @IsTest
    static void testIenWithUnitInBothMasterAndChildStudyPlansAsStudent(){
                
        Test.startTest();
        
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
        
        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        //Get two different study plans that share some units
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id,
            reduivy__Sample_Record_Code__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c IN ('BACBIS_MajorA', 'BACBIS_MinorA')
            ORDER BY reduivy__Sample_Record_Code__c
        ];

        System.Assert.areEqual(2, studyPlans.size(), 'Should have 2 study plans');

        reduivy__Study_Plan__c masterStudyPlan = studyPlans[0]; // BACBIS_MajorA
        reduivy__Study_Plan__c childStudyPlan = studyPlans[1];  // BACBIS_MinorA

        //Get a study unit that exists in BOTH study plans (BUS102 is common)
        reduivy__Study_Unit__c studyUnit = [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Unit__c
            WHERE reduivy__Sample_Record_Code__c = 'BUS102'
            LIMIT 1
        ];

        //Verify the unit exists in both study plan structures
        List<reduivy__Study_Plan_Structure__c> masterSps = [
            SELECT Id 
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :masterStudyPlan.Id
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        List<reduivy__Study_Plan_Structure__c> childSps = [
            SELECT Id 
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :childStudyPlan.Id
            AND reduivy__Study_Unit__c = :studyUnit.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ];

        System.Assert.isFalse(masterSps.isEmpty(), 'BUS102 should be in master study plan');
        System.Assert.isFalse(childSps.isEmpty(), 'BUS102 should be in child study plan');

        Map<String, reduivy__Individual_Academic_Profile__c> newIpfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> newIpeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();

        Contact student = studentContacts[0];
        
        // Create individual academic profile
        newIpfMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterProfile',
            REDU_TestData_UTIL.newIndividualAcademicProfile(
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                student.Id,
                student.reduivy__Sample_Record_Code__c + '_MasterProfile',
                IPF_Helper.STATUS_ACTIVE,
                true
            )
        );

        insert newIpfMap.values();

        String ipfKey = student.reduivy__Sample_Record_Code__c + '_MasterProfile';
        Id masterIpfId = newIpfMap.get(ipfKey).Id;

        // Create MASTER IPE
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_MasterIPE',
            REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_MasterIPE',
                student.Id,
                masterStudyPlan.reduivy__Study_Program__c,
                masterStudyPlan.Id,
                null,
                academicTerm.Id,
                null,
                null,
                null,
                null,
                true,
                IPE_INPROGRESS_STATUS,
                masterIpfId
            )
        );

        insert newIpeMap.values();

        Id masterIpeId = newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_MasterIPE').Id;

        // Create CHILD IPE
        newIpeMap.put(
            student.reduivy__Sample_Record_Code__c + '_ChildIPE',
            REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                student.reduivy__Sample_Record_Code__c + '_ChildIPE',
                student.Id,
                childStudyPlan.reduivy__Study_Program__c,
                childStudyPlan.Id,
                masterIpeId,
                IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY,
                true,
                IPE_INPROGRESS_STATUS
            )
        );

        insert newIpeMap.get(student.reduivy__Sample_Record_Code__c + '_ChildIPE');

        System.runAs(studentUser) {
            //Create IEN for unit that exists in BOTH study plans
            List<reduivy__Individual_Enrollment__c> newIenList = new List<reduivy__Individual_Enrollment__c>();
            for (reduivy__Study_Offering__c sof : [SELECT Id,
                reduivy__Sample_Record_Code__c,
                reduivy__Study_Unit__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c = :studyUnit.Id
                LIMIT 1
            ]) {
                newIenList.add(
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c,
                        student.Id,
                        sof.Id,
                        IEN_INPROGRESS_STATUS,
                        1,
                        System.today(),
                        null,
                        null,
                        null,
                        3,
                        null,
                        null,
                        true
                    )
                );
            }

            // Both point to same master IPF, so should have only 1 unique IPF
            insert newIenList;
            
            // If successful, verify it linked to master IPF
            List<reduivy__Individual_Enrollment__c> createdIens = [
                SELECT Id,
                reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Enrollment__c
                WHERE reduivy__Contact__c = :student.Id
                AND reduivy__Target_Unit_Id__c = :studyUnit.Id
            ];
            
            System.Assert.areEqual(1, createdIens.size(), 'Should have created 1 IEN');
            System.Assert.areEqual(masterIpfId, createdIens[0].reduivy__Individual_Academic_Profile__c,
                'IEN should be linked to master IPF (both master and child IPE point to same IPF)');
        }

        Test.stopTest();
    }
}