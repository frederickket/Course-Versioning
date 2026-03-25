/**
 * @author      WDCi (VTan)
 * @date        Nov 2023
 * @group       Program Completion Wizard
 * @description Test class for REDU_IpeAuditUnitHistoryModal_CTRL
 * @changehistory
 * ISS-001824 04-12-2023 VTan - New Class
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 * ISS-002743 15-12-2025 XiRouh - Added test methods to consider the IEN within the same Individual Academic Profile context and Updated test methods that create IENs to link them with IPF
 */
@isTest
private class REDU_IpeAuditUnitHistoryModal_TEST{
    
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
            
            testFactory.initMasterData(null);
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpeAuditUnitHistoryModal_CTRL
     */
    @isTest   
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Id ispUnitRTID = IPS_Helper.getUnitRecordTypeId();
        String idvEnrollmentFields = 'Name;reduivy__Enrollment_Date__c;reduivy__Attempt_Number__c;reduivy__Credits_Earned__c;reduivy__Grade_Result__c;reduivy__Grade_Points__c;reduivy__Enrollment_Status__c';
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsUnitMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c != null AND RecordTypeId = : ispUnitRTID LIMIT 5]);

        System.Assert.areEqual(false, ipsUnitMap.isEmpty(), 'Missing Individual Plan Structure record');

        System.runAs(ADMIN_USER){
            Test.startTest();
            
            for(Id ipsUnitId : ipsUnitMap.keySet()){

                REDU_LightningResponse objResponse = REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory(ipsUnitId, idvEnrollmentFields, true, '_self', UserInfo.getLanguage(), true);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditUnitHistoryModal_TEST');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as setup user for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForSetupUser() {

        User setupUser = testFactory.getSetupUser();
        Boolean hasError = false;

        Id ispUnitRTID = IPS_Helper.getUnitRecordTypeId();
        String idvEnrollmentFields = 'Name;reduivy__Enrollment_Date__c;reduivy__Attempt_Number__c;reduivy__Credits_Earned__c;reduivy__Grade_Result__c;reduivy__Grade_Points__c;reduivy__Enrollment_Status__c';
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsUnitMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c != null AND RecordTypeId = : ispUnitRTID]);

        Test.startTest();
        try{
            System.runAs(setupUser){
                
                for(Id ipsUnitId : ipsUnitMap.keySet()){

                    REDU_LightningResponse objResponse = REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory(ipsUnitId, idvEnrollmentFields, true, '_self', UserInfo.getLanguage(), true);
                    System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditUnitHistoryModal_TEST');
                }
            }
        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForSetupUser', exp.getMessage());
            hasError = true;
        }
        Test.stopTest();

        System.Assert.areEqual(true, hasError, 'Setup user should not have access to RIO Education fields.');
        
    }

    /**
     * @description Test as student user for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForStudentUser() {

        Id ispUnitRTID = IPS_Helper.getUnitRecordTypeId();
        String idvEnrollmentFields = 'Name;reduivy__Enrollment_Date__c;reduivy__Attempt_Number__c;reduivy__Credits_Earned__c;reduivy__Grade_Result__c;reduivy__Grade_Points__c;reduivy__Enrollment_Status__c';

        reduivy__Individual_Plan_Structure__c ipsUnit = [SELECT Id, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c != null AND RecordTypeId = : ispUnitRTID LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : ipsUnit.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c];

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory(ipsUnit.Id, idvEnrollmentFields, true, '_self', UserInfo.getLanguage(), true);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditUnitHistoryModal_TEST');

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Id ispUnitRTID = IPS_Helper.getUnitRecordTypeId();
        String idvEnrollmentFields = 'Name;reduivy__Enrollment_Date__c;reduivy__Attempt_Number__c;reduivy__Credits_Earned__c;reduivy__Grade_Result__c;reduivy__Grade_Points__c;reduivy__Enrollment_Status__c';
        Map<Id, reduivy__Individual_Plan_Structure__c> ipsUnitMap = new Map<Id, reduivy__Individual_Plan_Structure__c>([SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Enrollment__c != null AND RecordTypeId = : ispUnitRTID LIMIT 5]);

        System.Assert.areEqual(false, ipsUnitMap.isEmpty(), 'Missing Individual Plan Structure record');

        System.runAs(FACULTY_USER){
            Test.startTest();
            
            for(Id ipsUnitId : ipsUnitMap.keySet()){

                REDU_LightningResponse objResponse = REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory(ipsUnitId, idvEnrollmentFields, true, '_self', UserInfo.getLanguage(), true);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpeAuditUnitHistoryModal_TEST');
            }

            Test.stopTest();
        }
    }
	
    /**
     * @description Test that getIdvEnrollmentHistory only returns IEN records belonging to the same IPF and excludes Open status records as admin
     */
    @isTest   
    static void testEnrollmentHistoryFilteredByIpfAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        System.Assert.isFalse(studentContacts.isEmpty(), 'No student contacts found for testing');

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            LIMIT 1
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No study units found for testing');

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> ienMap = new Map<String, reduivy__Individual_Enrollment__c>();
        
        String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
        String IEN_COMPLETED_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);
        String IEN_OPEN_STATUS = IEN_Helper.getOpenStatuses().get(0);
        String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
        String STUDY_PROGRAM = 'BACBIS';
        String STUDY_PLAN = 'BACBIS_MajorA';

        // Create two IPF for the same student
        for (Contact student : studentContacts) {
            ipfMap.put(
                'IPF_Primary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
            
            ipfMap.put(
                'IPF_Secondary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }
        
        insert ipfMap.values();
        
        // Create IPE for each IPF
        for (Contact student : studentContacts) {
            ipeMap.put(
                'IPE_Primary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Primary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF_Primary').Id
                )
            );
            
            ipeMap.put(
                'IPE_Secondary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Secondary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF_Secondary').Id
                )
            );
        }
        
        insert ipeMap.values();
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            // Create multiple IEN for both IPF with different statuses
            for (reduivy__Study_Offering__c sof : [SELECT Id
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN: studyUnits.values()
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    // Primary IPF - Completed status (Attempt 2) - should be returned and linked to IPS
                    ienMap.put(
                        'IEN_Primary_Completed',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Primary_Completed',
                            student.Id,
                            sof.Id,
                            IEN_COMPLETED_STATUS,
                            2,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Primary').Id,
                            true
                        )
                    );
                    
                    // Primary IPF - In Progress status (Attempt 1) - should be returned
                    ienMap.put(
                        'IEN_Primary_InProgress',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Primary_InProgress',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today().addDays(-10),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Primary').Id,
                            true
                        )
                    );
                    
                    // Primary IPF - Open status (Attempt 3) - should NOT be returned
                    ienMap.put(
                        'IEN_Primary_Open',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Primary_Open',
                            student.Id,
                            sof.Id,
                            IEN_OPEN_STATUS,
                            3,
                            System.today().addDays(1),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Primary').Id,
                            true
                        )
                    );
                    
                    // Secondary IPF - InProgress status - should NOT be returned (different IPF)
                    ienMap.put(
                        'IEN_Secondary_InProgress',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Secondary_InProgress',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Secondary').Id,
                            true
                        )
                    );
                }
            }
            
            insert ienMap.values();
        }
        
        // Get the IPS Unit that should be linked to Primary IPF's InProgress IEN
        reduivy__Individual_Plan_Structure__c ipsUnit = [
            SELECT Id,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c = :ipeMap.get('IPE_Primary').Id
            AND reduivy__Target_Unit_Id__c IN :studyUnits.keySet()
            LIMIT 1
        ];
        
        System.Assert.isNotNull(ipsUnit, 'IPS Unit should exist for Primary IPF');
        System.Assert.areEqual(
            ienMap.get('IEN_Primary_Completed').Id,
            ipsUnit.reduivy__Individual_Enrollment__c,
            'IPS should be linked to Primary IPF Completed IEN'
        );
        
        // Test the getIdvEnrollmentHistory method
        String idvEnrollmentFields = 'Name;reduivy__Enrollment_Date__c;reduivy__Attempt_Number__c;reduivy__Enrollment_Status__c;reduivy__Individual_Academic_Profile__c';
        
        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory(
                ipsUnit.Id, 
                idvEnrollmentFields, 
                true, 
                '_self', 
                UserInfo.getLanguage(), 
                true
            );
            
            Test.stopTest();
            
            System.Assert.areEqual(true, response.isSuccess, 'Response should be successful');
            
            Map<String, Object> responseJSON = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<Object> records = (List<Object>) responseJSON.get(REDU_Datatable_UTIL.RECORDS_PARAM);
            
            System.Assert.isNotNull(records, 'Records should not be null');
            
            // Should return 2 records: InProgress and Completed from Primary IPF
            // Should NOT return: Open status IEN or Secondary IPF IEN
            System.Assert.areEqual(2, records.size(), 
                'Should return exactly 2 records (InProgress and Completed from Primary IPF only)');
            
            // Verify the returned records
            Set<Id> returnedIenIds = new Set<Id>();
            for (Object record : records) {
                Map<String, Object> ienRecord = (Map<String, Object>) record;
                returnedIenIds.add((Id) ienRecord.get('Id'));
            }
            
            // Assert Primary IPF InProgress is returned
            System.Assert.isTrue(
                returnedIenIds.contains(ienMap.get('IEN_Primary_InProgress').Id),
                'Should return Primary IPF InProgress IEN'
            );
            
            // Assert Primary IPF Completed is returned
            System.Assert.isTrue(
                returnedIenIds.contains(ienMap.get('IEN_Primary_Completed').Id),
                'Should return Primary IPF Completed IEN'
            );
            
            // Assert Primary IPF Open is NOT returned
            System.Assert.isFalse(
                returnedIenIds.contains(ienMap.get('IEN_Primary_Open').Id),
                'Should NOT return Open status IEN'
            );
            
            // Assert Secondary IPF IEN is NOT returned
            System.Assert.isFalse(
                returnedIenIds.contains(ienMap.get('IEN_Secondary_InProgress').Id),
                'Should NOT return IEN from different IPF'
            );
        }
    }

    /**
     * @description Test that enrollment history returns empty list when no valid IEN exists as admin
     */
    @isTest   
    static void testEnrollmentHistoryWithNoValidRecordsAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id
            FROM reduivy__Study_Unit__c
            LIMIT 1
        ]);

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        
        String IEN_OPEN_STATUS = IEN_Helper.getOpenStatuses().get(0);
        String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
        String STUDY_PROGRAM = 'BACBIS';
        String STUDY_PLAN = 'BACBIS_MajorA';            
            
        // Create IPF and IPE
        for (Contact student : studentContacts) {
            ipfMap.put('IPF', REDU_TestData_UTIL.newIndividualAcademicProfile(
                'IPF', student.Id, 'IPF', IPF_Helper.STATUS_ACTIVE, true));
        }
        insert ipfMap.values();
        
        for (Contact student : studentContacts) {
            ipeMap.put('IPE', REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                'IPE', 
                student.Id, 
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null,
                true, IPE_INPROGRESS_STATUS, ipfMap.get('IPF').Id));
        }
        insert ipeMap.values();
        
        // Create only Open status IEN (should be filtered out)
        for (reduivy__Study_Offering__c sof : [SELECT Id
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Study_Unit__c IN: studyUnits.values()
            LIMIT 1
        ]) {
            for (Contact student : studentContacts) {
                reduivy__Individual_Enrollment__c ienOpen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    'IEN_Open', student.Id, sof.Id, IEN_OPEN_STATUS, 1,
                    System.today(), null, null, null, 3, null, ipfMap.get('IPF').Id, true);
                insert ienOpen;
            }
        }
        
        // Get IPS
        reduivy__Individual_Plan_Structure__c ipsUnit = [
            SELECT Id
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c = :ipeMap.get('IPE').Id
            LIMIT 1
        ];
        
        String idvEnrollmentFields = 'Name;reduivy__Enrollment_Status__c';
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            REDU_LightningResponse response = REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory(
                ipsUnit.Id, 
                idvEnrollmentFields, 
                true, 
                '_self', 
                UserInfo.getLanguage(), 
                true
            );
            
            Test.stopTest();
            
            System.Assert.areEqual(true, response.isSuccess, 'Response should be successful');
            
            Map<String, Object> responseJSON = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<Object> records = (List<Object>) responseJSON.get(REDU_Datatable_UTIL.RECORDS_PARAM);
            
            // Should return empty list since only Open status IEN exists
            System.Assert.areEqual(0, records.size(), 
                'Should return empty list when only Open status enrollments exist');
        }
    }

    /**
     * @description Test that getIdvEnrollmentHistory only returns IEN records belonging to the same IPF and excludes Open status records as faculty
     */
    @isTest   
    static void testEnrollmentHistoryFilteredByIpfAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        System.Assert.isFalse(studentContacts.isEmpty(), 'No student contacts found for testing');

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            LIMIT 1
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No study units found for testing');

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> ienMap = new Map<String, reduivy__Individual_Enrollment__c>();
        
        String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
        String IEN_COMPLETED_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);
        String IEN_OPEN_STATUS = IEN_Helper.getOpenStatuses().get(0);
        String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
        String STUDY_PROGRAM = 'BACBIS';
        String STUDY_PLAN = 'BACBIS_MajorA';

        // Create two IPF for the same student
        for (Contact student : studentContacts) {
            ipfMap.put(
                'IPF_Primary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
            
            ipfMap.put(
                'IPF_Secondary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }
        
        insert ipfMap.values();
        
        // Create IPE for each IPF
        for (Contact student : studentContacts) {
            ipeMap.put(
                'IPE_Primary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Primary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF_Primary').Id
                )
            );
            
            ipeMap.put(
                'IPE_Secondary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Secondary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF_Secondary').Id
                )
            );
        }
        
        insert ipeMap.values();
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            // Create multiple IEN for both IPF with different statuses
            for (reduivy__Study_Offering__c sof : [SELECT Id
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN: studyUnits.values()
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    // Primary IPF - Completed status (Attempt 2) - should be returned and linked to IPS
                    ienMap.put(
                        'IEN_Primary_Completed',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Primary_Completed',
                            student.Id,
                            sof.Id,
                            IEN_COMPLETED_STATUS,
                            2,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Primary').Id,
                            true
                        )
                    );
                    
                    // Primary IPF - In Progress status (Attempt 1) - should be returned
                    ienMap.put(
                        'IEN_Primary_InProgress',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Primary_InProgress',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today().addDays(-10),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Primary').Id,
                            true
                        )
                    );
                    
                    // Primary IPF - Open status (Attempt 3) - should NOT be returned
                    ienMap.put(
                        'IEN_Primary_Open',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Primary_Open',
                            student.Id,
                            sof.Id,
                            IEN_OPEN_STATUS,
                            3,
                            System.today().addDays(1),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Primary').Id,
                            true
                        )
                    );
                    
                    // Secondary IPF - InProgress status - should NOT be returned (different IPF)
                    ienMap.put(
                        'IEN_Secondary_InProgress',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Secondary_InProgress',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Secondary').Id,
                            true
                        )
                    );
                }
            }
            
            insert ienMap.values();
        }
        
        // Get the IPS Unit that should be linked to Primary IPF's InProgress IEN
        reduivy__Individual_Plan_Structure__c ipsUnit = [
            SELECT Id,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c = :ipeMap.get('IPE_Primary').Id
            AND reduivy__Target_Unit_Id__c IN :studyUnits.keySet()
            LIMIT 1
        ];
        
        System.Assert.isNotNull(ipsUnit, 'IPS Unit should exist for Primary IPF');
        System.Assert.areEqual(
            ienMap.get('IEN_Primary_Completed').Id,
            ipsUnit.reduivy__Individual_Enrollment__c,
            'IPS should be linked to Primary IPF Completed IEN'
        );
        
        // Test the getIdvEnrollmentHistory method
        String idvEnrollmentFields = 'Name;reduivy__Enrollment_Date__c;reduivy__Attempt_Number__c;reduivy__Enrollment_Status__c;reduivy__Individual_Academic_Profile__c';
        
        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory(
                ipsUnit.Id, 
                idvEnrollmentFields, 
                true, 
                '_self', 
                UserInfo.getLanguage(), 
                true
            );
            
            Test.stopTest();
            
            System.Assert.areEqual(true, response.isSuccess, 'Response should be successful');
            
            Map<String, Object> responseJSON = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<Object> records = (List<Object>) responseJSON.get(REDU_Datatable_UTIL.RECORDS_PARAM);
            
            System.Assert.isNotNull(records, 'Records should not be null');
            
            // Should return 2 records: InProgress and Completed from Primary IPF
            // Should NOT return: Open status IEN or Secondary IPF IEN
            System.Assert.areEqual(2, records.size(), 
                'Should return exactly 2 records (InProgress and Completed from Primary IPF only)');
            
            // Verify the returned records
            Set<Id> returnedIenIds = new Set<Id>();
            for (Object record : records) {
                Map<String, Object> ienRecord = (Map<String, Object>) record;
                returnedIenIds.add((Id) ienRecord.get('Id'));
            }
            
            // Assert Primary IPF InProgress is returned
            System.Assert.isTrue(
                returnedIenIds.contains(ienMap.get('IEN_Primary_InProgress').Id),
                'Should return Primary IPF InProgress IEN'
            );
            
            // Assert Primary IPF Completed is returned
            System.Assert.isTrue(
                returnedIenIds.contains(ienMap.get('IEN_Primary_Completed').Id),
                'Should return Primary IPF Completed IEN'
            );
            
            // Assert Primary IPF Open is NOT returned
            System.Assert.isFalse(
                returnedIenIds.contains(ienMap.get('IEN_Primary_Open').Id),
                'Should NOT return Open status IEN'
            );
            
            // Assert Secondary IPF IEN is NOT returned
            System.Assert.isFalse(
                returnedIenIds.contains(ienMap.get('IEN_Secondary_InProgress').Id),
                'Should NOT return IEN from different IPF'
            );
        }
    }

    /**
     * @description Test that enrollment history returns empty list when no valid IEN exists as faculty
     */
    @isTest   
    static void testEnrollmentHistoryWithNoValidRecordsAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id
            FROM reduivy__Study_Unit__c
            LIMIT 1
        ]);

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        
        String IEN_OPEN_STATUS = IEN_Helper.getOpenStatuses().get(0);
        String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
        String STUDY_PROGRAM = 'BACBIS';
        String STUDY_PLAN = 'BACBIS_MajorA';            
            
        // Create IPF and IPE
        for (Contact student : studentContacts) {
            ipfMap.put('IPF', REDU_TestData_UTIL.newIndividualAcademicProfile(
                'IPF', student.Id, 'IPF', IPF_Helper.STATUS_ACTIVE, true));
        }
        insert ipfMap.values();
        
        for (Contact student : studentContacts) {
            ipeMap.put('IPE', REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                'IPE', 
                student.Id, 
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null,
                true, IPE_INPROGRESS_STATUS, ipfMap.get('IPF').Id));
        }
        insert ipeMap.values();
        
        // Create only Open status IEN (should be filtered out)
        for (reduivy__Study_Offering__c sof : [SELECT Id
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Study_Unit__c IN: studyUnits.values()
            LIMIT 1
        ]) {
            for (Contact student : studentContacts) {
                reduivy__Individual_Enrollment__c ienOpen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    'IEN_Open', student.Id, sof.Id, IEN_OPEN_STATUS, 1,
                    System.today(), null, null, null, 3, null, ipfMap.get('IPF').Id, true);
                insert ienOpen;
            }
        }
        
        // Get IPS
        reduivy__Individual_Plan_Structure__c ipsUnit = [
            SELECT Id
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c = :ipeMap.get('IPE').Id
            LIMIT 1
        ];
        
        String idvEnrollmentFields = 'Name;reduivy__Enrollment_Status__c';
        
        System.runAs(FACULTY_USER) {
            Test.startTest();
            
            REDU_LightningResponse response = REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory(
                ipsUnit.Id, 
                idvEnrollmentFields, 
                true, 
                '_self', 
                UserInfo.getLanguage(), 
                true
            );
            
            Test.stopTest();
            
            System.Assert.areEqual(true, response.isSuccess, 'Response should be successful');
            
            Map<String, Object> responseJSON = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<Object> records = (List<Object>) responseJSON.get(REDU_Datatable_UTIL.RECORDS_PARAM);
            
            // Should return empty list since only Open status IEN exists
            System.Assert.areEqual(0, records.size(), 
                'Should return empty list when only Open status enrollments exist');
        }
    }

    /**
     * @description Test that getIdvEnrollmentHistory only returns IEN records belonging to the same IPF and excludes Open status records as student
     */
    @isTest   
    static void testEnrollmentHistoryFilteredByIpfAsStudent() {
        
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

        System.Assert.isFalse(studentContacts.isEmpty(), 'No student contacts found for testing');

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id, reduivy__Unit_Code__c
            FROM reduivy__Study_Unit__c
            LIMIT 1
        ]);

        System.Assert.isFalse(studyUnits.isEmpty(), 'No study units found for testing');

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        Map<String, reduivy__Individual_Enrollment__c> ienMap = new Map<String, reduivy__Individual_Enrollment__c>();
        
        String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
        String IEN_COMPLETED_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);
        String IEN_OPEN_STATUS = IEN_Helper.getOpenStatuses().get(0);
        String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
        String STUDY_PROGRAM = 'BACBIS';
        String STUDY_PLAN = 'BACBIS_MajorA';

        // Create two IPF for the same student
        for (Contact student : studentContacts) {
            ipfMap.put(
                'IPF_Primary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Primary',
                    IPF_Helper.STATUS_ACTIVE,
                    true
                )
            );
            
            ipfMap.put(
                'IPF_Secondary',
                REDU_TestData_UTIL.newIndividualAcademicProfile(
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    student.Id,
                    student.reduivy__Sample_Record_Code__c + '_IPF_Secondary',
                    IPF_Helper.STATUS_ACTIVE,
                    false
                )
            );
        }
        
        insert ipfMap.values();
        
        // Create IPE for each IPF
        for (Contact student : studentContacts) {
            ipeMap.put(
                'IPE_Primary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Primary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF_Primary').Id
                )
            );
            
            ipeMap.put(
                'IPE_Secondary',
                REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    student.reduivy__Sample_Record_Code__c + '_IPE_Secondary',
                    student.Id,
                    studyPlan.reduivy__Study_Program__c,
                    studyPlan.Id,
                    null, null, null, null, null, null,
                    true,
                    IPE_INPROGRESS_STATUS,
                    ipfMap.get('IPF_Secondary').Id
                )
            );
        }
        
        insert ipeMap.values();
        
        System.runAs(studentUser) {
            Test.startTest();
            
            // Create multiple IEN for both IPF with different statuses
            for (reduivy__Study_Offering__c sof : [SELECT Id
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Academic_Term__c =: academicTerm.Id 
                AND reduivy__Campus__r.reduivy__Code__c = 'SYDNEY'
                AND reduivy__Study_Unit__c IN: studyUnits.values()
                LIMIT 1
            ]) {
                for (Contact student : studentContacts) {
                    // Primary IPF - Completed status (Attempt 2) - should be returned and linked to IPS
                    ienMap.put(
                        'IEN_Primary_Completed',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Primary_Completed',
                            student.Id,
                            sof.Id,
                            IEN_COMPLETED_STATUS,
                            2,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Primary').Id,
                            true
                        )
                    );
                    
                    // Primary IPF - In Progress status (Attempt 1) - should be returned
                    ienMap.put(
                        'IEN_Primary_InProgress',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Primary_InProgress',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today().addDays(-10),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Primary').Id,
                            true
                        )
                    );
                    
                    // Primary IPF - Open status (Attempt 3) - should NOT be returned
                    ienMap.put(
                        'IEN_Primary_Open',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Primary_Open',
                            student.Id,
                            sof.Id,
                            IEN_OPEN_STATUS,
                            3,
                            System.today().addDays(1),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Primary').Id,
                            true
                        )
                    );
                    
                    // Secondary IPF - InProgress status - should NOT be returned (different IPF)
                    ienMap.put(
                        'IEN_Secondary_InProgress',
                        REDU_TestData_UTIL.newStudentIndividualEnrollment(
                            'IEN_Secondary_InProgress',
                            student.Id,
                            sof.Id,
                            IEN_INPROGRESS_STATUS,
                            1,
                            System.today(),
                            null, null, null, 3, null,
                            ipfMap.get('IPF_Secondary').Id,
                            true
                        )
                    );
                }
            }
            
            insert ienMap.values();
        }
        
        // Get the IPS Unit that should be linked to Primary IPF's InProgress IEN
        reduivy__Individual_Plan_Structure__c ipsUnit = [
            SELECT Id,
            reduivy__Individual_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c = :ipeMap.get('IPE_Primary').Id
            AND reduivy__Target_Unit_Id__c IN :studyUnits.keySet()
            LIMIT 1
        ];
        
        System.Assert.isNotNull(ipsUnit, 'IPS Unit should exist for Primary IPF');
        System.Assert.areEqual(
            ienMap.get('IEN_Primary_Completed').Id,
            ipsUnit.reduivy__Individual_Enrollment__c,
            'IPS should be linked to Primary IPF Completed IEN'
        );
        
        // Test the getIdvEnrollmentHistory method
        String idvEnrollmentFields = 'Name;reduivy__Enrollment_Date__c;reduivy__Attempt_Number__c;reduivy__Enrollment_Status__c;reduivy__Individual_Academic_Profile__c';
        
        System.runAs(studentUser) {
            REDU_LightningResponse response = REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory(
                ipsUnit.Id, 
                idvEnrollmentFields, 
                true, 
                '_self', 
                UserInfo.getLanguage(), 
                true
            );
            
            Test.stopTest();
            
            System.Assert.areEqual(true, response.isSuccess, 'Response should be successful');
            
            Map<String, Object> responseJSON = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<Object> records = (List<Object>) responseJSON.get(REDU_Datatable_UTIL.RECORDS_PARAM);
            
            System.Assert.isNotNull(records, 'Records should not be null');
            
            // Should return 2 records: InProgress and Completed from Primary IPF
            // Should NOT return: Open status IEN or Secondary IPF IEN
            System.Assert.areEqual(2, records.size(), 
                'Should return exactly 2 records (InProgress and Completed from Primary IPF only)');
            
            // Verify the returned records
            Set<Id> returnedIenIds = new Set<Id>();
            for (Object record : records) {
                Map<String, Object> ienRecord = (Map<String, Object>) record;
                returnedIenIds.add((Id) ienRecord.get('Id'));
            }
            
            // Assert Primary IPF InProgress is returned
            System.Assert.isTrue(
                returnedIenIds.contains(ienMap.get('IEN_Primary_InProgress').Id),
                'Should return Primary IPF InProgress IEN'
            );
            
            // Assert Primary IPF Completed is returned
            System.Assert.isTrue(
                returnedIenIds.contains(ienMap.get('IEN_Primary_Completed').Id),
                'Should return Primary IPF Completed IEN'
            );
            
            // Assert Primary IPF Open is NOT returned
            System.Assert.isFalse(
                returnedIenIds.contains(ienMap.get('IEN_Primary_Open').Id),
                'Should NOT return Open status IEN'
            );
            
            // Assert Secondary IPF IEN is NOT returned
            System.Assert.isFalse(
                returnedIenIds.contains(ienMap.get('IEN_Secondary_InProgress').Id),
                'Should NOT return IEN from different IPF'
            );
        }
    }

    /**
     * @description Test that enrollment history returns empty list when no valid IEN exists as student
     */
    @isTest   
    static void testEnrollmentHistoryWithNoValidRecordsAsStudent() {
        
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

        Map<Id, reduivy__Study_Unit__c> studyUnits = new Map<Id, reduivy__Study_Unit__c>([
            SELECT Id
            FROM reduivy__Study_Unit__c
            LIMIT 1
        ]);

        reduivy__Study_Term__c academicTerm = [SELECT Id
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        Map<String, reduivy__Individual_Academic_Profile__c> ipfMap = new Map<String, reduivy__Individual_Academic_Profile__c>();
        Map<String, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<String, reduivy__Individual_Program_Enrollment__c>();
        
        String IEN_OPEN_STATUS = IEN_Helper.getOpenStatuses().get(0);
        String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
        String STUDY_PROGRAM = 'BACBIS';
        String STUDY_PLAN = 'BACBIS_MajorA';            
            
        // Create IPF and IPE
        for (Contact student : studentContacts) {
            ipfMap.put('IPF', REDU_TestData_UTIL.newIndividualAcademicProfile(
                'IPF', student.Id, 'IPF', IPF_Helper.STATUS_ACTIVE, true));
        }
        insert ipfMap.values();
        
        for (Contact student : studentContacts) {
            ipeMap.put('IPE', REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                'IPE', 
                student.Id, 
                studyPlan.reduivy__Study_Program__c,
                studyPlan.Id,
                null, null, null, null, null, null,
                true, IPE_INPROGRESS_STATUS, ipfMap.get('IPF').Id));
        }
        insert ipeMap.values();
        
        // Create only Open status IEN (should be filtered out)
        for (reduivy__Study_Offering__c sof : [SELECT Id
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__c =: academicTerm.Id 
            AND reduivy__Study_Unit__c IN: studyUnits.values()
            LIMIT 1
        ]) {
            for (Contact student : studentContacts) {
                reduivy__Individual_Enrollment__c ienOpen = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                    'IEN_Open', student.Id, sof.Id, IEN_OPEN_STATUS, 1,
                    System.today(), null, null, null, 3, null, ipfMap.get('IPF').Id, true);
                insert ienOpen;
            }
        }
        
        // Get IPS
        reduivy__Individual_Plan_Structure__c ipsUnit = [
            SELECT Id
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c = :ipeMap.get('IPE').Id
            LIMIT 1
        ];
        
        String idvEnrollmentFields = 'Name;reduivy__Enrollment_Status__c';
        
        System.runAs(studentUser) {
            Test.startTest();
            
            REDU_LightningResponse response = REDU_IpeAuditUnitHistoryModal_LCTRL.getIdvEnrollmentHistory(
                ipsUnit.Id, 
                idvEnrollmentFields, 
                true, 
                '_self', 
                UserInfo.getLanguage(), 
                true
            );
            
            Test.stopTest();
            
            System.Assert.areEqual(true, response.isSuccess, 'Response should be successful');
            
            Map<String, Object> responseJSON = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<Object> records = (List<Object>) responseJSON.get(REDU_Datatable_UTIL.RECORDS_PARAM);
            
            // Should return empty list since only Open status IEN exists
            System.Assert.areEqual(0, records.size(), 
                'Should return empty list when only Open status enrollments exist');
        }
    }
}