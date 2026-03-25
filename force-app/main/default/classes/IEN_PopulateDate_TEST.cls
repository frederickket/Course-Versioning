/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for IEN_PopulateDate_EXE
 * @changehistory
 * ISS-001763 27-10-2023 dblack - new class
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@IsTest
public inherited sharing class IEN_PopulateDate_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
	static final String STUDY_UNIT_BUS101 = 'BUS101';
    static final String STUDY_UNIT_BUS102 = 'BUS102';

    /**
     * @description Create settings and test data
     */
	@TestSetup
    static void makeData() {
		
		// Create settings
		testFactory.setupDefaultSettings();

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SUN_Helper.getApiName());
			testFactory.initOfferingData(SOF_Helper.getApiName());
			testFactory.initStudentData(IPR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin that each of the individual enrollment record date fields are populated (before insert)
     */
    @IsTest
    static void testIenPopulateDateBeforeInsertAsAdminUser() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Study_Offering__c> sofList = [SELECT Id, 
            reduivy__Academic_Term__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Delivery_Method__c,
            reduivy__Scheduled_Duration_Unit__c,
            reduivy__Scheduled_Duration__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR 
            reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS102)
            AND reduivy__Campus__r.reduivy__Code__c =: 'SYDNEY'
        ];

        sofList.get(0).reduivy__Delivery_Method__c = 'Online - Self Learning';
        sofList.get(0).reduivy__Scheduled_Duration_Unit__c = 'Hour';
        sofList.get(0).reduivy__Scheduled_Duration__c = 24;

        REDU_SystemMode_UTIL.doUpdate(sofList);

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        // Create individual enrollment and individual plan structure (unit)
        Map<String, reduivy__Individual_Enrollment__c> ipeIdvEnrollment = new Map<String, reduivy__Individual_Enrollment__c>();
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();

        List<Contact> students = new List<Contact>();
        for(Contact student : [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ]){
            students.add(student);

            //ien with sof
            for (reduivy__Study_Offering__c sof : sofList) {
                String key = student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c;

                ipeIdvEnrollment.put(
                    key, 
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        key, 
                        student.Id,
                        sof.Id, 
                        ienInProgressStatus[0], 
                        1, 
                        null, 
                        null, 
                        null, 
                        null, 
                        10,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    )
                );
            }

            //ien without sof
            ipeIdvEnrollment.put(
                student.reduivy__Sample_Record_Code__c + '_emptysof', 
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_emptysof', 
                    student.Id,
                    null, 
                    ienInProgressStatus[0], 
                    1, 
                    date.today(), 
                    date.today(), 
                    date.today(), 
                    date.today(), 
                    10,
                    null,
                    studentToIPFMap.get(student.Id),
                    true
                )
            );
        }

        System.Assert.areEqual(false, ipeIdvEnrollment.isEmpty(), 'Missing individual enrollment records.');        

        System.runAs(ADMIN_USER) {

            // Perform test
            Test.startTest();

            REDU_Database_UTIL.doinsert(ipeIdvEnrollment.values());
            
            Test.stopTest();
        }

		// Verify test results
		List<reduivy__Individual_Enrollment__c> ienList = [
			SELECT 	reduivy__Enrollment_Status__c, reduivy__Enrollment_Date__c,
                    reduivy__Start_Date__c, reduivy__Census_Date__c,
                    reduivy__Due_Date__c, reduivy__End_Date__c,
                    reduivy__Study_Offering__c,
                    reduivy__Study_Offering__r.reduivy__Delivery_Method__c,
                    reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c,
                    reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c
			FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ipeIdvEnrollment.values()
		];
        
		System.Assert.areEqual(
			students.size() * 3,
			ienList.size(),
			'There should be the expected number of individual enrollment records'
		);

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                if (ien.reduivy__Enrollment_Status__c == 'Enrolled') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__Enrollment_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') ? 
                            System.today() : ien.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                        ien.reduivy__Start_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        ien.reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                        ien.reduivy__Census_Date__c,
                        'The actual value should be as expected'
                    );

                    if (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') {
                        Integer sofDuration = 
                            (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c != null) ? 
                             Integer.valueOf(ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c) : 0;
                        
                        if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Hour') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addHours(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        } else if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Minute') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addMinutes(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        }
                    } else {
                        System.Assert.areEqual(
                            ien.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c,
                            ien.reduivy__Due_Date__c,
                            'The actual value should be as expected'
                        );
                    }

                    System.Assert.isNull(
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                } else if (ien.reduivy__Enrollment_Status__c == 'Completed') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                }
            } else {
                System.Assert.isNull(
                    ien.reduivy__Enrollment_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Start_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Census_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Due_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__End_Date__c,
                    'The actual value should be as expected'
                );
            }
        }
	}

    /**
     * @description Test as admin that each of the individual enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testIenPopulateDateBeforeUpdateAsAdminUser() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Study_Offering__c> sofList = [SELECT Id, 
            reduivy__Academic_Term__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Delivery_Method__c,
            reduivy__Scheduled_Duration_Unit__c,
            reduivy__Scheduled_Duration__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR 
            reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS102)
            AND reduivy__Campus__r.reduivy__Code__c =: 'SYDNEY'
        ];

        sofList.get(0).reduivy__Delivery_Method__c = 'Online - Self Learning';
        sofList.get(0).reduivy__Scheduled_Duration_Unit__c = 'Hour';
        sofList.get(0).reduivy__Scheduled_Duration__c = 24;

        REDU_SystemMode_UTIL.doUpdate(sofList);

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        // Create individual enrollment and individual plan structure (unit)
        Map<String, reduivy__Individual_Enrollment__c> ipeIdvEnrollment = new Map<String, reduivy__Individual_Enrollment__c>();
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        List<String> ienOpenStatuses = IEN_Helper.getOpenStatuses();

        List<Contact> students = new List<Contact>();
        for(Contact student : [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ]){
            students.add(student);

            //ien with status = Not started
            for (reduivy__Study_Offering__c sof : sofList) {
                String key = student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c;

                ipeIdvEnrollment.put(
                    key, 
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        key, 
                        student.Id,
                        sof.Id, 
                        ienOpenStatuses[0], 
                        1, 
                        null, 
                        null, 
                        null, 
                        null, 
                        10,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    )
                );
            }

            //ien with sof and status = In Progress
            ipeIdvEnrollment.put(
                student.reduivy__Sample_Record_Code__c + '_emptysof', 
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_emptysof', 
                    student.Id,
                    sofList.get(0).Id, 
                    ienInProgressStatus[0], 
                    1, 
                    date.today(), 
                    date.today(), 
                    date.today(), 
                    date.today(), 
                    10,
                    null,
                    studentToIPFMap.get(student.Id),
                    true
                )
            );
        }

        System.Assert.areEqual(false, ipeIdvEnrollment.isEmpty(), 'Missing individual enrollment records.');        

        Test.startTest();

        System.runAs(ADMIN_USER) {

            REDU_Database_UTIL.doinsert(ipeIdvEnrollment.values());
            
        }

		// Verify test results
		List<reduivy__Individual_Enrollment__c> ienList = [
			SELECT 	reduivy__Enrollment_Status__c, reduivy__Enrollment_Date__c,
                    reduivy__Start_Date__c, reduivy__Census_Date__c,
                    reduivy__Due_Date__c, reduivy__End_Date__c,
                    reduivy__Study_Offering__c,
                    reduivy__Study_Offering__r.reduivy__Delivery_Method__c,
                    reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c,
                    reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c
			FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ipeIdvEnrollment.values()
		];

		System.Assert.areEqual(
			students.size() * 3,
			ienList.size(),
			'There should be the expected number of individual enrollment records'
		);

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                if (ien.reduivy__Enrollment_Status__c == 'Enrolled') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__Enrollment_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') ? 
                            System.today() : ien.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                        ien.reduivy__Start_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        ien.reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                        ien.reduivy__Census_Date__c,
                        'The actual value should be as expected'
                    );

                    if (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') {
                        Integer sofDuration = 
                            (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c != null) ? 
                             Integer.valueOf(ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c) : 0;
                        
                        if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Hour') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addHours(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        } else if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Minute') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addMinutes(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        }
                    } else {
                        System.Assert.areEqual(
                            ien.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c,
                            ien.reduivy__Due_Date__c,
                            'The actual value should be as expected'
                        );
                    }

                    System.Assert.isNotNull(
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );

                } else if (ien.reduivy__Enrollment_Status__c == 'Completed') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                }
            } else {
                System.Assert.isNull(
                    ien.reduivy__Enrollment_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Start_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Census_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Due_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__End_Date__c,
                    'The actual value should be as expected'
                );
            }
        }

        for (reduivy__Individual_Enrollment__c ien : ipeIdvEnrollment.values()) {
            if (ienInProgressStatus.contains(ien.reduivy__Enrollment_Status__c)) {
                ien.reduivy__Enrollment_Status__c = ienOpenStatuses.get(0);

            } else if (ienOpenStatuses.contains(ien.reduivy__Enrollment_Status__c)) {
                ien.reduivy__Enrollment_Status__c = ienInProgressStatus.get(0);
            }
        }

        System.runAs(ADMIN_USER) {

            REDU_Database_UTIL.doUpdate(ipeIdvEnrollment.values());
            
        }

        Test.stopTest();

        // Verify test results
		ienList = [
			SELECT 	reduivy__Enrollment_Status__c, reduivy__Enrollment_Date__c,
                    reduivy__Start_Date__c, reduivy__Census_Date__c,
                    reduivy__Due_Date__c, reduivy__End_Date__c,
                    reduivy__Study_Offering__c,
                    reduivy__Study_Offering__r.reduivy__Delivery_Method__c,
                    reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c,
                    reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c
			FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ipeIdvEnrollment.values()
		];

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                if (ien.reduivy__Enrollment_Status__c == 'Enrolled') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__Enrollment_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') ? 
                            System.today() : ien.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                        ien.reduivy__Start_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        ien.reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                        ien.reduivy__Census_Date__c,
                        'The actual value should be as expected'
                    );

                    if (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') {
                        Integer sofDuration = 
                            (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c != null) ? 
                             Integer.valueOf(ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c) : 0;
                        
                        if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Hour') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addHours(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        } else if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Minute') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addMinutes(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        }
                    } else {
                        System.Assert.areEqual(
                            ien.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c,
                            ien.reduivy__Due_Date__c,
                            'The actual value should be as expected'
                        );
                    }

                    System.Assert.isNull(
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );

                } else if (ien.reduivy__Enrollment_Status__c == 'Completed') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                }
            } else {
                System.Assert.isNull(
                    ien.reduivy__Enrollment_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Start_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Census_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Due_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__End_Date__c,
                    'The actual value should be as expected'
                );
            }
        }
    }

    /**
     * @description Test as student that each of the individual enrollment record date fields are populated (before insert)
     */
    @IsTest
    static void testIenPopulateDateBeforeInsertAsStudentUser() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<reduivy__Study_Offering__c> sofList = [SELECT Id, 
            reduivy__Academic_Term__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Delivery_Method__c,
            reduivy__Scheduled_Duration_Unit__c,
            reduivy__Scheduled_Duration__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR 
            reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS102)
            AND reduivy__Campus__r.reduivy__Code__c =: 'SYDNEY'
        ];

        sofList.get(0).reduivy__Delivery_Method__c = 'Online - Self Learning';
        sofList.get(0).reduivy__Scheduled_Duration_Unit__c = 'Hour';
        sofList.get(0).reduivy__Scheduled_Duration__c = 24;

        REDU_SystemMode_UTIL.doUpdate(sofList);

        // Create individual enrollment and individual plan structure (unit)
        Map<String, reduivy__Individual_Enrollment__c> ipeIdvEnrollment = new Map<String, reduivy__Individual_Enrollment__c>();
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();

        User studentUser = testFactory.getStudentUser();

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];
        
        //ien with sof
        for (reduivy__Study_Offering__c sof : sofList) {
            String key = studentUser.ContactId + '_' + sof.reduivy__Sample_Record_Code__c;

            ipeIdvEnrollment.put(
                key, 
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    key, 
                    studentUser.ContactId,
                    sof.Id, 
                    ienInProgressStatus[0], 
                    1, 
                    null, 
                    null, 
                    null, 
                    null, 
                    10,
                    null,
                    studentIpfs[0].Id,
                    true
                )
            );
        }

        //ien without sof
        ipeIdvEnrollment.put(
            studentUser.ContactId + '_emptysof', 
            REDU_TestData_UTIL.newStudentIndividualEnrollment(
                studentUser.ContactId + '_emptysof', 
                studentUser.ContactId,
                null, 
                ienInProgressStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                date.today(), 
                date.today(), 
                10,
                null,
                studentIpfs[0].Id,
                true
            )
        );

        System.Assert.areEqual(false, ipeIdvEnrollment.isEmpty(), 'Missing individual enrollment records.');        

        System.runAs(studentUser) {

            // Perform test
            Test.startTest();

            REDU_Database_UTIL.doinsert(ipeIdvEnrollment.values());
            
            Test.stopTest();
        }

		// Verify test results
		List<reduivy__Individual_Enrollment__c> ienList = [
			SELECT 	reduivy__Enrollment_Status__c, reduivy__Enrollment_Date__c,
                    reduivy__Start_Date__c, reduivy__Census_Date__c,
                    reduivy__Due_Date__c, reduivy__End_Date__c,
                    reduivy__Study_Offering__c,
                    reduivy__Study_Offering__r.reduivy__Delivery_Method__c,
                    reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c,
                    reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c
			FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ipeIdvEnrollment.values()
		];
        
		System.Assert.areEqual(
			3,
			ienList.size(),
			'There should be the expected number of individual enrollment records'
		);

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                if (ien.reduivy__Enrollment_Status__c == 'Enrolled') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__Enrollment_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') ? 
                            System.today() : ien.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                        ien.reduivy__Start_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        ien.reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                        ien.reduivy__Census_Date__c,
                        'The actual value should be as expected'
                    );

                    if (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') {
                        Integer sofDuration = 
                            (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c != null) ? 
                             Integer.valueOf(ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c) : 0;
                        
                        if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Hour') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addHours(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        } else if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Minute') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addMinutes(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        }
                    } else {
                        System.Assert.areEqual(
                            ien.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c,
                            ien.reduivy__Due_Date__c,
                            'The actual value should be as expected'
                        );
                    }

                    System.Assert.isNull(
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                } else if (ien.reduivy__Enrollment_Status__c == 'Completed') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                }
            } else {
                System.Assert.isNull(
                    ien.reduivy__Enrollment_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Start_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Census_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Due_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__End_Date__c,
                    'The actual value should be as expected'
                );
            }
        }
	}

    /**
     * @description Test as student that each of the individual enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testIenPopulateDateBeforeUpdateAsStudentUser() {

        List<reduivy__Study_Offering__c> sofList = [SELECT Id, 
            reduivy__Academic_Term__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Delivery_Method__c,
            reduivy__Scheduled_Duration_Unit__c,
            reduivy__Scheduled_Duration__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR 
            reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS102)
            AND reduivy__Campus__r.reduivy__Code__c =: 'SYDNEY'
        ];

        sofList.get(0).reduivy__Delivery_Method__c = 'Online - Self Learning';
        sofList.get(0).reduivy__Scheduled_Duration_Unit__c = 'Hour';
        sofList.get(0).reduivy__Scheduled_Duration__c = 24;

        REDU_SystemMode_UTIL.doUpdate(sofList);

        // Create individual enrollment and individual plan structure (unit)
        Map<String, reduivy__Individual_Enrollment__c> ipeIdvEnrollment = new Map<String, reduivy__Individual_Enrollment__c>();
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        List<String> ienOpenStatuses = IEN_Helper.getOpenStatuses();

        User studentUser = testFactory.getStudentUser();

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__c = :studentUser.ContactId LIMIT 1];

        //ien with status = Not started
        for (reduivy__Study_Offering__c sof : sofList) {
            String key = studentUser.ContactId + '_' + sof.reduivy__Sample_Record_Code__c;

            ipeIdvEnrollment.put(
                key, 
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    key, 
                    studentUser.ContactId,
                    sof.Id, 
                    ienOpenStatuses[0], 
                    1, 
                    null, 
                    null, 
                    null, 
                    null, 
                    10,
                    null,
                    studentIpfs[0].Id,
                    true
                )
            );
        }

        //ien with sof and status = In Progress
        ipeIdvEnrollment.put(
            studentUser.ContactId + '_emptysof', 
            REDU_TestData_UTIL.newStudentIndividualEnrollment(
                studentUser.ContactId + '_emptysof', 
                studentUser.ContactId,
                sofList.get(0).Id, 
                ienInProgressStatus[0], 
                1, 
                date.today(), 
                date.today(), 
                date.today(), 
                date.today(), 
                10,
                null,
                studentIpfs[0].Id,
                true
            )
        );

        System.Assert.areEqual(false, ipeIdvEnrollment.isEmpty(), 'Missing individual enrollment records.');        

        Test.startTest();

        System.runAs(studentUser) {

            REDU_Database_UTIL.doinsert(ipeIdvEnrollment.values());
            
        }

		// Verify test results
		List<reduivy__Individual_Enrollment__c> ienList = [
			SELECT 	reduivy__Enrollment_Status__c, reduivy__Enrollment_Date__c,
                    reduivy__Start_Date__c, reduivy__Census_Date__c,
                    reduivy__Due_Date__c, reduivy__End_Date__c,
                    reduivy__Study_Offering__c,
                    reduivy__Study_Offering__r.reduivy__Delivery_Method__c,
                    reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c,
                    reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c
			FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ipeIdvEnrollment.values()
		];

		System.Assert.areEqual(
			3,
			ienList.size(),
			'There should be the expected number of individual enrollment records'
		);

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                if (ien.reduivy__Enrollment_Status__c == 'Enrolled') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__Enrollment_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') ? 
                            System.today() : ien.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                        ien.reduivy__Start_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        ien.reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                        ien.reduivy__Census_Date__c,
                        'The actual value should be as expected'
                    );

                    if (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') {
                        Integer sofDuration = 
                            (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c != null) ? 
                             Integer.valueOf(ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c) : 0;
                        
                        if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Hour') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addHours(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        } else if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Minute') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addMinutes(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        }
                    } else {
                        System.Assert.areEqual(
                            ien.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c,
                            ien.reduivy__Due_Date__c,
                            'The actual value should be as expected'
                        );
                    }

                    System.Assert.isNotNull(
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );

                } else if (ien.reduivy__Enrollment_Status__c == 'Completed') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                }
            } else {
                System.Assert.isNull(
                    ien.reduivy__Enrollment_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Start_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Census_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Due_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__End_Date__c,
                    'The actual value should be as expected'
                );
            }
        }

        for (reduivy__Individual_Enrollment__c ien : ipeIdvEnrollment.values()) {
            if (ienInProgressStatus.contains(ien.reduivy__Enrollment_Status__c)) {
                ien.reduivy__Enrollment_Status__c = ienOpenStatuses.get(0);

            } else if (ienOpenStatuses.contains(ien.reduivy__Enrollment_Status__c)) {
                ien.reduivy__Enrollment_Status__c = ienInProgressStatus.get(0);
            }
        }

        System.runAs(studentUser) {

            REDU_Database_UTIL.doUpdate(ipeIdvEnrollment.values());
            
        }

        Test.stopTest();

        // Verify test results
		ienList = [
			SELECT 	reduivy__Enrollment_Status__c, reduivy__Enrollment_Date__c,
                    reduivy__Start_Date__c, reduivy__Census_Date__c,
                    reduivy__Due_Date__c, reduivy__End_Date__c,
                    reduivy__Study_Offering__c,
                    reduivy__Study_Offering__r.reduivy__Delivery_Method__c,
                    reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c,
                    reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c
			FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ipeIdvEnrollment.values()
		];

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                if (ien.reduivy__Enrollment_Status__c == 'Enrolled') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__Enrollment_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') ? 
                            System.today() : ien.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                        ien.reduivy__Start_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        ien.reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                        ien.reduivy__Census_Date__c,
                        'The actual value should be as expected'
                    );

                    if (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') {
                        Integer sofDuration = 
                            (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c != null) ? 
                             Integer.valueOf(ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c) : 0;
                        
                        if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Hour') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addHours(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        } else if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Minute') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addMinutes(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        }
                    } else {
                        System.Assert.areEqual(
                            ien.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c,
                            ien.reduivy__Due_Date__c,
                            'The actual value should be as expected'
                        );
                    }

                    System.Assert.isNull(
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );

                } else if (ien.reduivy__Enrollment_Status__c == 'Completed') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                }
            } else {
                System.Assert.isNull(
                    ien.reduivy__Enrollment_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Start_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Census_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Due_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__End_Date__c,
                    'The actual value should be as expected'
                );
            }
        }
    }

    /**
     * @description Test as faculty that each of the individual enrollment record date fields are populated (before insert)
     */
    @IsTest
    static void testIenPopulateDateBeforeInsertAsFacultyUser() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<reduivy__Study_Offering__c> sofList = [SELECT Id, 
            reduivy__Academic_Term__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Delivery_Method__c,
            reduivy__Scheduled_Duration_Unit__c,
            reduivy__Scheduled_Duration__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR 
            reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS102)
            AND reduivy__Campus__r.reduivy__Code__c =: 'SYDNEY'
        ];

        sofList.get(0).reduivy__Delivery_Method__c = 'Online - Self Learning';
        sofList.get(0).reduivy__Scheduled_Duration_Unit__c = 'Hour';
        sofList.get(0).reduivy__Scheduled_Duration__c = 24;

        REDU_SystemMode_UTIL.doUpdate(sofList);

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        // Create individual enrollment and individual plan structure (unit)
        Map<String, reduivy__Individual_Enrollment__c> ipeIdvEnrollment = new Map<String, reduivy__Individual_Enrollment__c>();
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();

        List<Contact> students = new List<Contact>();
        for(Contact student : [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ]){
            students.add(student);

            //ien with sof
            for (reduivy__Study_Offering__c sof : sofList) {
                String key = student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c;

                ipeIdvEnrollment.put(
                    key, 
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        key, 
                        student.Id,
                        sof.Id, 
                        ienInProgressStatus[0], 
                        1, 
                        null, 
                        null, 
                        null, 
                        null, 
                        10,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    )
                );
            }

            //ien without sof
            ipeIdvEnrollment.put(
                student.reduivy__Sample_Record_Code__c + '_emptysof', 
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_emptysof', 
                    student.Id,
                    null, 
                    ienInProgressStatus[0], 
                    1, 
                    date.today(), 
                    date.today(), 
                    date.today(), 
                    date.today(), 
                    10,
                    null,
                    studentToIPFMap.get(student.Id),
                    true
                )
            );
        }

        System.Assert.areEqual(false, ipeIdvEnrollment.isEmpty(), 'Missing individual enrollment records.');        

        System.runAs(FACULTY_USER) {

            // Perform test
            Test.startTest();

            REDU_Database_UTIL.doinsert(ipeIdvEnrollment.values());
            
            Test.stopTest();
        }

		// Verify test results
		List<reduivy__Individual_Enrollment__c> ienList = [
			SELECT 	reduivy__Enrollment_Status__c, reduivy__Enrollment_Date__c,
                    reduivy__Start_Date__c, reduivy__Census_Date__c,
                    reduivy__Due_Date__c, reduivy__End_Date__c,
                    reduivy__Study_Offering__c,
                    reduivy__Study_Offering__r.reduivy__Delivery_Method__c,
                    reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c,
                    reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c
			FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ipeIdvEnrollment.values()
		];
        
		System.Assert.areEqual(
			students.size() * 3,
			ienList.size(),
			'There should be the expected number of individual enrollment records'
		);

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                if (ien.reduivy__Enrollment_Status__c == 'Enrolled') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__Enrollment_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') ? 
                            System.today() : ien.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                        ien.reduivy__Start_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        ien.reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                        ien.reduivy__Census_Date__c,
                        'The actual value should be as expected'
                    );

                    if (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') {
                        Integer sofDuration = 
                            (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c != null) ? 
                             Integer.valueOf(ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c) : 0;
                        
                        if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Hour') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addHours(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        } else if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Minute') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addMinutes(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        }
                    } else {
                        System.Assert.areEqual(
                            ien.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c,
                            ien.reduivy__Due_Date__c,
                            'The actual value should be as expected'
                        );
                    }

                    System.Assert.isNull(
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                } else if (ien.reduivy__Enrollment_Status__c == 'Completed') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                }
            } else {
                System.Assert.isNull(
                    ien.reduivy__Enrollment_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Start_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Census_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Due_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__End_Date__c,
                    'The actual value should be as expected'
                );
            }
        }
	}

    /**
     * @description Test as faculty that each of the individual enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testIenPopulateDateBeforeUpdateAsFacultyUser() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Study_Offering__c> sofList = [SELECT Id, 
            reduivy__Academic_Term__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Delivery_Method__c,
            reduivy__Scheduled_Duration_Unit__c,
            reduivy__Scheduled_Duration__c
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND (reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS101 OR 
            reduivy__Study_Unit__r.reduivy__Unit_Code__c =: STUDY_UNIT_BUS102)
            AND reduivy__Campus__r.reduivy__Code__c =: 'SYDNEY'
        ];

        sofList.get(0).reduivy__Delivery_Method__c = 'Online - Self Learning';
        sofList.get(0).reduivy__Scheduled_Duration_Unit__c = 'Hour';
        sofList.get(0).reduivy__Scheduled_Duration__c = 24;

        REDU_SystemMode_UTIL.doUpdate(sofList);

        List<reduivy__Individual_Academic_Profile__c> studentIpfs = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Academic_Profile__c WHERE reduivy__Contact__r.reduivy__Sample_Record_Code__c <> '' AND reduivy__Contact__r.reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT];
        Map<Id, Id> studentToIPFMap = new Map<Id, Id>();

        for (reduivy__Individual_Academic_Profile__c ipf : studentIpfs) {
            studentToIPFMap.put(ipf.reduivy__Contact__c, ipf.Id);
        }

        // Create individual enrollment and individual plan structure (unit)
        Map<String, reduivy__Individual_Enrollment__c> ipeIdvEnrollment = new Map<String, reduivy__Individual_Enrollment__c>();
        List<String> ienInProgressStatus = IEN_Helper.getInProgressStatuses();
        List<String> ienOpenStatuses = IEN_Helper.getOpenStatuses();

        List<Contact> students = new List<Contact>();
        for(Contact student : [SELECT Id,
            reduivy__Sample_Record_Code__c
            FROM Contact
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
        ]){
            students.add(student);

            //ien with status = Not started
            for (reduivy__Study_Offering__c sof : sofList) {
                String key = student.reduivy__Sample_Record_Code__c + '_' + sof.reduivy__Sample_Record_Code__c;

                ipeIdvEnrollment.put(
                    key, 
                    REDU_TestData_UTIL.newStudentIndividualEnrollment(
                        key, 
                        student.Id,
                        sof.Id, 
                        ienOpenStatuses[0], 
                        1, 
                        null, 
                        null, 
                        null, 
                        null, 
                        10,
                        null,
                        studentToIPFMap.get(student.Id),
                        true
                    )
                );
            }

            //ien with sof and status = In Progress
            ipeIdvEnrollment.put(
                student.reduivy__Sample_Record_Code__c + '_emptysof', 
                REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_emptysof', 
                    student.Id,
                    sofList.get(0).Id, 
                    ienInProgressStatus[0], 
                    1, 
                    date.today(), 
                    date.today(), 
                    date.today(), 
                    date.today(), 
                    10,
                    null,
                    studentToIPFMap.get(student.Id),
                    true
                )
            );
        }

        System.Assert.areEqual(false, ipeIdvEnrollment.isEmpty(), 'Missing individual enrollment records.');        

        Test.startTest();

        System.runAs(FACULTY_USER) {

            REDU_Database_UTIL.doinsert(ipeIdvEnrollment.values());
            
        }

		// Verify test results
		List<reduivy__Individual_Enrollment__c> ienList = [
			SELECT 	reduivy__Enrollment_Status__c, reduivy__Enrollment_Date__c,
                    reduivy__Start_Date__c, reduivy__Census_Date__c,
                    reduivy__Due_Date__c, reduivy__End_Date__c,
                    reduivy__Study_Offering__c,
                    reduivy__Study_Offering__r.reduivy__Delivery_Method__c,
                    reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c,
                    reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c
			FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ipeIdvEnrollment.values()
		];

		System.Assert.areEqual(
			students.size() * 3,
			ienList.size(),
			'There should be the expected number of individual enrollment records'
		);

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                if (ien.reduivy__Enrollment_Status__c == 'Enrolled') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__Enrollment_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') ? 
                            System.today() : ien.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                        ien.reduivy__Start_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        ien.reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                        ien.reduivy__Census_Date__c,
                        'The actual value should be as expected'
                    );

                    if (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') {
                        Integer sofDuration = 
                            (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c != null) ? 
                             Integer.valueOf(ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c) : 0;
                        
                        if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Hour') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addHours(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        } else if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Minute') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addMinutes(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        }
                    } else {
                        System.Assert.areEqual(
                            ien.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c,
                            ien.reduivy__Due_Date__c,
                            'The actual value should be as expected'
                        );
                    }

                    System.Assert.isNotNull(
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );

                } else if (ien.reduivy__Enrollment_Status__c == 'Completed') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                }
            } else {
                System.Assert.isNull(
                    ien.reduivy__Enrollment_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Start_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Census_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Due_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__End_Date__c,
                    'The actual value should be as expected'
                );
            }
        }

        for (reduivy__Individual_Enrollment__c ien : ipeIdvEnrollment.values()) {
            if (ienInProgressStatus.contains(ien.reduivy__Enrollment_Status__c)) {
                ien.reduivy__Enrollment_Status__c = ienOpenStatuses.get(0);

            } else if (ienOpenStatuses.contains(ien.reduivy__Enrollment_Status__c)) {
                ien.reduivy__Enrollment_Status__c = ienInProgressStatus.get(0);
            }
        }

        System.runAs(FACULTY_USER) {

            REDU_Database_UTIL.doUpdate(ipeIdvEnrollment.values());
            
        }

        Test.stopTest();

        // Verify test results
		ienList = [
			SELECT 	reduivy__Enrollment_Status__c, reduivy__Enrollment_Date__c,
                    reduivy__Start_Date__c, reduivy__Census_Date__c,
                    reduivy__Due_Date__c, reduivy__End_Date__c,
                    reduivy__Study_Offering__c,
                    reduivy__Study_Offering__r.reduivy__Delivery_Method__c,
                    reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c,
                    reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c,
                    reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c
			FROM reduivy__Individual_Enrollment__c
            WHERE Id IN: ipeIdvEnrollment.values()
		];

        for (reduivy__Individual_Enrollment__c ien : ienList) {
            if (String.isNotBlank(ien.reduivy__Study_Offering__c)) {
                if (ien.reduivy__Enrollment_Status__c == 'Enrolled') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__Enrollment_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') ? 
                            System.today() : ien.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c,
                        ien.reduivy__Start_Date__c,
                        'The actual value should be as expected'
                    );

                    System.Assert.areEqual(
                        ien.reduivy__Study_Offering__r.reduivy__Census_Date_Calculated__c,
                        ien.reduivy__Census_Date__c,
                        'The actual value should be as expected'
                    );

                    if (ien.reduivy__Study_Offering__r.reduivy__Delivery_Method__c == 'Online - Self Learning') {
                        Integer sofDuration = 
                            (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c != null) ? 
                             Integer.valueOf(ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration__c) : 0;
                        
                        if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Hour') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addHours(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        } else if (ien.reduivy__Study_Offering__r.reduivy__Scheduled_Duration_Unit__c == 'Minute') {
                            System.Assert.areEqual(
                                Date.valueOf(System.now().addMinutes(sofDuration)),
                                ien.reduivy__Due_Date__c,
                                'The actual value should be as expected'
                            );
                        }
                    } else {
                        System.Assert.areEqual(
                            ien.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c,
                            ien.reduivy__Due_Date__c,
                            'The actual value should be as expected'
                        );
                    }

                    System.Assert.isNull(
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );

                } else if (ien.reduivy__Enrollment_Status__c == 'Completed') {
                    System.Assert.areEqual(
                        System.today(),
                        ien.reduivy__End_Date__c,
                        'The actual value should be as expected'
                    );
                }
            } else {
                System.Assert.isNull(
                    ien.reduivy__Enrollment_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Start_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Census_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__Due_Date__c,
                    'The actual value should be as expected'
                );

                System.Assert.isNull(
                    ien.reduivy__End_Date__c,
                    'The actual value should be as expected'
                );
            }
        }
    }
}