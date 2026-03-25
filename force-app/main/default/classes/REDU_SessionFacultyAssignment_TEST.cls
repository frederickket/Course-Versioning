/**
 * @author      WDCi (XW)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for REDU_SessionFacultyAssignment_LCTRL
 * @changehistory
 * ISS-001920 16-08-2024 XW - create new class
 */
@IsTest
public inherited sharing class REDU_SessionFacultyAssignment_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static String INVALID_CROSS_REFERENCE_KEY = 'INVALID_CROSS_REFERENCE_KEY';

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
            testFactory.initFacultyData(QFA_Helper.getApiName(), true);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            Test.stopTest();
		}
    }


    @IsTest
    static void testForAdminGetAllQualifiedFaculty() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Qualified_Faculty__c> qualifiedFacultyList;
        List<reduivy__Study_Session__c> targetStudySession = [
            SELECT reduivy__Study_Offering__r.reduivy__Study_Unit__c
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];
        
        if(!targetStudySession.isEmpty()){

            qualifiedFacultyList = [
                SELECT Id, reduivy__Study_Unit__c, reduivy__Contact__c,
                reduivy__Contact__r.Name, reduivy__Faculty_Role__c
                FROM reduivy__Qualified_Faculty__c
                WHERE reduivy__Status__c = :QFA_Helper.STATUS_ACTIVE
                AND reduivy__Study_Unit__c = :targetStudySession[0].reduivy__Study_Offering__r.reduivy__Study_Unit__c
            ];
        }

        System.runAs(ADMIN_USER) {
            Test.startTest();

            try{

                REDU_LightningResponse response = REDU_SessionFacultyAssignment_LCTRL.getAllQualifiedFaculty(targetStudySession[0].Id);
                System.Assert.areEqual(JSON.serialize(qualifiedFacultyList), response.responseData, 'Qualified Faculties are different!');
                
            }catch (Exception exp) {
                
                System.Assert.fail(exp.getMessage());
            }

            Test.stopTest();
        }
    }


    @IsTest
    static void testForStudentGetAllQualifiedFaculty() {
        
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

        List<reduivy__Qualified_Faculty__c> qualifiedFacultyList;
        List<reduivy__Study_Session__c> targetStudySession = [
            SELECT Id, reduivy__Study_Offering__r.reduivy__Study_Unit__c
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];
        
        if(!targetStudySession.isEmpty()){

            qualifiedFacultyList = [
                SELECT Id, reduivy__Study_Unit__c, reduivy__Contact__c,
                reduivy__Contact__r.Name, reduivy__Faculty_Role__c
                FROM reduivy__Qualified_Faculty__c
                WHERE reduivy__Status__c = :QFA_Helper.STATUS_ACTIVE
                AND reduivy__Study_Unit__c = :targetStudySession[0].reduivy__Study_Offering__r.reduivy__Study_Unit__c
            ];
        }

        System.runAs(studentUser) {
            Test.startTest();

            try{

                REDU_LightningResponse response = REDU_SessionFacultyAssignment_LCTRL.getAllQualifiedFaculty(targetStudySession[0].Id);
                List<reduivy__Qualified_Faculty__c> resultQualifiedFacultyList = (List<reduivy__Qualified_Faculty__c>) JSON.deserialize(response.responseData, List<reduivy__Qualified_Faculty__c>.class);
                System.Assert.areNotEqual(0, resultQualifiedFacultyList.size(), 'Student should be getting any qualified faculty!');
                
            }catch (Exception exp) {
                
                System.Assert.fail(exp.getMessage());
            }
            
            Test.stopTest();
        }
    }

    
    @IsTest
    static void testForFacultyGetAllQualifiedFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Qualified_Faculty__c> qualifiedFacultyList;
        List<reduivy__Study_Session__c> targetStudySession = [
            SELECT reduivy__Study_Offering__r.reduivy__Study_Unit__c
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];
        
        if(!targetStudySession.isEmpty()){

            qualifiedFacultyList = [
                SELECT Id, reduivy__Study_Unit__c, reduivy__Contact__c,
                reduivy__Contact__r.Name, reduivy__Faculty_Role__c
                FROM reduivy__Qualified_Faculty__c
                WHERE reduivy__Status__c = :QFA_Helper.STATUS_ACTIVE
                AND reduivy__Study_Unit__c = :targetStudySession[0].reduivy__Study_Offering__r.reduivy__Study_Unit__c
            ];
        }

        System.runAs(FACULTY_USER) {
            Test.startTest();

            try{
                REDU_LightningResponse response = REDU_SessionFacultyAssignment_LCTRL.getAllQualifiedFaculty(targetStudySession[0].Id);
                List<reduivy__Qualified_Faculty__c> resultQualifiedFacultyList = (List<reduivy__Qualified_Faculty__c>) JSON.deserialize(response.responseData, List<reduivy__Qualified_Faculty__c>.class);
                System.Assert.areNotEqual(0, resultQualifiedFacultyList.size(), 'Faculty should be getting any qualified faculty!');
                
            }catch (Exception exp) {
                System.Assert.fail(exp.getMessage());
            }
            
            Test.stopTest();
        }
    }

    @IsTest
    static void testForAdminAssignNewFacultyWithoutQfaRecord_WithoutQfaSet() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session__c sse = [SELECT Id, 
            Name, 
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            (
                SELECT Id
                FROM reduivy__Study_Session_Times__r
            )
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        Set<Id> assignedContactSet = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : [SELECT Id, 
            Name, 
            reduivy__Contact__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :sse.Id
        ]){
            assignedContactSet.add(ser.reduivy__Contact__c);
        }

        Contact unassignedContact = [
            SELECT Id, Name
            FROM Contact
            WHERE Id NOT IN :assignedContactSet
            AND reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_FACULTY
            LIMIT 1
        ];
        
        System.runAs(ADMIN_USER) {   
            Test.startTest();

            List<Id> sstListToModify = new List<Id>((new Map<Id, reduivy__Study_Session_Time__c> (sse.reduivy__Study_Session_Times__r)).keySet());
            REDU_LightningResponse response = REDU_SessionFacultyAssignment_LCTRL.assignNewFaculty(
                unassignedContact.Id, sstListToModify,
                SER_Helper.RESPONSE_STATUS_ACCEPTED, sse.reduivy__Start_Date__c, sse.reduivy__End_Date__c, 
                true, true, null);
            
            List<Id> modifiedId = (List<Id>) JSON.deserialize(response.responseData, List<Id>.class);
            System.Assert.areNotEqual(0, modifiedId.size(), 'Modified Id should not be empty');

            reduivy__Study_Session_Time__c modifiedSst = [SELECT Id, 
                reduivy__Study_Session__r.reduivy__Primary_Faculty__c,
                reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Primary_Faculty__c
                FROM reduivy__Study_Session_Time__c
                WHERE Id IN :sstListToModify
                WITH USER_MODE
                LIMIT 1
            ];
            System.Assert.areEqual(unassignedContact.Id,
                modifiedSst.reduivy__Study_Session__r.reduivy__Primary_Faculty__c,
                'Study Session Primary Faculty should be the same!');

            System.Assert.areEqual(unassignedContact.Id,
                modifiedSst.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Primary_Faculty__c,
                'Study Offering Primary Faculty should be the same!');

            List<reduivy__Individual_Session_Enrollment__c> actualFacultyIsn = new List<reduivy__Individual_Session_Enrollment__c>();
            actualFacultyIsn = [SELECT Id, reduivy__Faculty_Role__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Individual_Enrollment__r.reduivy__Contact__c = :unassignedContact.Id
                AND RecordTypeId = :ISN_Helper.getFacultyRecordTypeId()
                AND reduivy__Study_Session__c = :sse.Id
                LIMIT 1
            ];

            System.Assert.areEqual(1, actualFacultyIsn.size(), 'Faculty Isn for the faculty should be created!');
            System.Assert.isNull(actualFacultyIsn[0].reduivy__Faculty_Role__c, 'Faculty role should not be populated since no Qualified Faculty for this!');

            Test.stopTest();
        }
    }

    @IsTest
    static void testForAdminAssignNewFacultyWithQfaRecord_WithoutQfaSet() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session__c sse = [SELECT Id, 
            Name, 
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__c,
            (
                SELECT Id
                FROM reduivy__Study_Session_Times__r
            )
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        Set<Id> assignedContactSet = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : [SELECT Id, 
            Name, 
            reduivy__Contact__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :sse.Id
        ]){
            assignedContactSet.add(ser.reduivy__Contact__c);
        }

        Contact unassignedContact = [
            SELECT Id, Name
            FROM Contact
            WHERE Id NOT IN :assignedContactSet
            AND reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_FACULTY
            LIMIT 1
        ];

        reduivy__Qualified_Faculty__c newQfa = new reduivy__Qualified_Faculty__c(
            reduivy__Study_Unit__c = sse.reduivy__Study_Offering__r.reduivy__Study_Unit__c,
            reduivy__Contact__c = unassignedContact.Id,
            reduivy__Faculty_Role__c = 'Lecturer;Lab Assistant;Tutor;Assistant;Trainer',
            reduivy__Status__c = 'Active'
        );

        insert newQfa;
        
        System.runAs(ADMIN_USER) {   
            Test.startTest();

            List<Id> sstListToModify = new List<Id>((new Map<Id, reduivy__Study_Session_Time__c> (sse.reduivy__Study_Session_Times__r)).keySet());
            REDU_LightningResponse response = REDU_SessionFacultyAssignment_LCTRL.assignNewFaculty(
                unassignedContact.Id, sstListToModify,
                SER_Helper.RESPONSE_STATUS_ACCEPTED, sse.reduivy__Start_Date__c, sse.reduivy__End_Date__c, 
                true, true, null);
            
            List<Id> modifiedId = (List<Id>) JSON.deserialize(response.responseData, List<Id>.class);
            System.Assert.areNotEqual(0, modifiedId.size(), 'Modified Id should not be empty');

            reduivy__Study_Session_Time__c modifiedSst = [SELECT Id, 
                reduivy__Study_Session__r.reduivy__Primary_Faculty__c,
                reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Primary_Faculty__c
                FROM reduivy__Study_Session_Time__c
                WHERE Id IN :sstListToModify
                WITH USER_MODE
                LIMIT 1
            ];
            System.Assert.areEqual(unassignedContact.Id,
                modifiedSst.reduivy__Study_Session__r.reduivy__Primary_Faculty__c,
                'Study Session Primary Faculty should be the same!');

            System.Assert.areEqual(unassignedContact.Id,
                modifiedSst.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Primary_Faculty__c,
                'Study Offering Primary Faculty should be the same!');

            List<reduivy__Individual_Session_Enrollment__c> actualFacultyIsn = new List<reduivy__Individual_Session_Enrollment__c>();
            actualFacultyIsn = [SELECT Id, reduivy__Faculty_Role__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Individual_Enrollment__r.reduivy__Contact__c = :unassignedContact.Id
                AND RecordTypeId = :ISN_Helper.getFacultyRecordTypeId()
                AND reduivy__Study_Session__c = :sse.Id
                LIMIT 1
            ];

            System.Assert.areEqual(1, actualFacultyIsn.size(), 'Faculty Isn for the faculty should be created!');
            System.Assert.areEqual('Lecturer;Lab Assistant;Tutor;Assistant;Trainer', actualFacultyIsn[0].reduivy__Faculty_Role__c, 'Faculty role should be the same!');

            Test.stopTest();
        }
    }

    @IsTest
    static void testForAdminAssignNewFacultyWithoutQfaRecord_WithQfaSet() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session__c sse = [SELECT Id, 
            Name, 
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            (
                SELECT Id
                FROM reduivy__Study_Session_Times__r
            )
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        Set<Id> assignedContactSet = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : [SELECT Id, 
            Name, 
            reduivy__Contact__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :sse.Id
        ]){
            assignedContactSet.add(ser.reduivy__Contact__c);
        }

        Contact unassignedContact = [
            SELECT Id, Name
            FROM Contact
            WHERE Id NOT IN :assignedContactSet
            AND reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_FACULTY
            LIMIT 1
        ];
        
        System.runAs(ADMIN_USER) {   
            Test.startTest();

            List<Id> sstListToModify = new List<Id>((new Map<Id, reduivy__Study_Session_Time__c> (sse.reduivy__Study_Session_Times__r)).keySet());
            REDU_LightningResponse response = REDU_SessionFacultyAssignment_LCTRL.assignNewFaculty(
                unassignedContact.Id, sstListToModify,
                SER_Helper.RESPONSE_STATUS_ACCEPTED, sse.reduivy__Start_Date__c, sse.reduivy__End_Date__c, 
                true, true, null);
            
            List<Id> modifiedId = (List<Id>) JSON.deserialize(response.responseData, List<Id>.class);
            System.Assert.areNotEqual(0, modifiedId.size(), 'Modified Id should not be empty');

            reduivy__Study_Session_Time__c modifiedSst = [SELECT Id, 
                reduivy__Study_Session__r.reduivy__Primary_Faculty__c,
                reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Primary_Faculty__c
                FROM reduivy__Study_Session_Time__c
                WHERE Id IN :sstListToModify
                WITH USER_MODE
                LIMIT 1
            ];
            System.Assert.areEqual(unassignedContact.Id,
                modifiedSst.reduivy__Study_Session__r.reduivy__Primary_Faculty__c,
                'Study Session Primary Faculty should be the same!');

            System.Assert.areEqual(unassignedContact.Id,
                modifiedSst.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Primary_Faculty__c,
                'Study Offering Primary Faculty should be the same!');

            List<reduivy__Individual_Session_Enrollment__c> actualFacultyIsn = new List<reduivy__Individual_Session_Enrollment__c>();
            actualFacultyIsn = [SELECT Id, reduivy__Faculty_Role__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Individual_Enrollment__r.reduivy__Contact__c = :unassignedContact.Id
                AND RecordTypeId = :ISN_Helper.getFacultyRecordTypeId()
                AND reduivy__Study_Session__c = :sse.Id
                LIMIT 1
            ];

            System.Assert.areEqual(1, actualFacultyIsn.size(), 'Faculty Isn for the faculty should be created!');
            System.Assert.isNull(actualFacultyIsn[0].reduivy__Faculty_Role__c, 'Faculty role should not be populated since no Qualified Faculty for this!');

            Test.stopTest();
        }
    }

    @IsTest
    static void testForAdminAssignNewFacultyWithQfaRecord_WithQfaSet() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session__c sse = [SELECT Id, 
            Name, 
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__c,
            (
                SELECT Id
                FROM reduivy__Study_Session_Times__r
            )
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        Set<Id> assignedContactSet = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : [SELECT Id, 
            Name, 
            reduivy__Contact__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :sse.Id
        ]){
            assignedContactSet.add(ser.reduivy__Contact__c);
        }

        Contact unassignedContact = [
            SELECT Id, Name
            FROM Contact
            WHERE Id NOT IN :assignedContactSet
            AND reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_FACULTY
            LIMIT 1
        ];

        reduivy__Qualified_Faculty__c newQfa = new reduivy__Qualified_Faculty__c(
            reduivy__Study_Unit__c = sse.reduivy__Study_Offering__r.reduivy__Study_Unit__c,
            reduivy__Contact__c = unassignedContact.Id,
            reduivy__Faculty_Role__c = 'Lecturer;Lab Assistant;Tutor;Assistant;Trainer',
            reduivy__Status__c = 'Active'
        );

        insert newQfa;
        
        System.runAs(ADMIN_USER) {   
            Test.startTest();

            List<Id> sstListToModify = new List<Id>((new Map<Id, reduivy__Study_Session_Time__c> (sse.reduivy__Study_Session_Times__r)).keySet());
            REDU_LightningResponse response = REDU_SessionFacultyAssignment_LCTRL.assignNewFaculty(
                unassignedContact.Id, sstListToModify,
                SER_Helper.RESPONSE_STATUS_ACCEPTED, sse.reduivy__Start_Date__c, sse.reduivy__End_Date__c, 
                true, true, new List<String> {'Lecturer;Tutor'});
            
            List<Id> modifiedId = (List<Id>) JSON.deserialize(response.responseData, List<Id>.class);
            System.Assert.areNotEqual(0, modifiedId.size(), 'Modified Id should not be empty');

            reduivy__Study_Session_Time__c modifiedSst = [SELECT Id, 
                reduivy__Study_Session__r.reduivy__Primary_Faculty__c,
                reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Primary_Faculty__c
                FROM reduivy__Study_Session_Time__c
                WHERE Id IN :sstListToModify
                WITH USER_MODE
                LIMIT 1
            ];
            System.Assert.areEqual(unassignedContact.Id,
                modifiedSst.reduivy__Study_Session__r.reduivy__Primary_Faculty__c,
                'Study Session Primary Faculty should be the same!');

            System.Assert.areEqual(unassignedContact.Id,
                modifiedSst.reduivy__Study_Session__r.reduivy__Study_Offering__r.reduivy__Primary_Faculty__c,
                'Study Offering Primary Faculty should be the same!');

            List<reduivy__Individual_Session_Enrollment__c> actualFacultyIsn = new List<reduivy__Individual_Session_Enrollment__c>();
            actualFacultyIsn = [SELECT Id, reduivy__Faculty_Role__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Individual_Enrollment__r.reduivy__Contact__c = :unassignedContact.Id
                AND RecordTypeId = :ISN_Helper.getFacultyRecordTypeId()
                AND reduivy__Study_Session__c = :sse.Id
                LIMIT 1
            ];

            System.Assert.areEqual(1, actualFacultyIsn.size(), 'Faculty Isn for the faculty should be created!');
            System.Assert.areEqual('Lecturer;Tutor', actualFacultyIsn[0].reduivy__Faculty_Role__c, 'Faculty role should be the same!');

            Test.stopTest();
        }
    }

    @IsTest
    static void testForFacultyAssignNewFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Session__c sse = [
            SELECT Id, Name, (
                SELECT Id
                FROM reduivy__Study_Session_Times__r
            ), reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        Set<Id> assignedContactSet = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : [
            SELECT Id, Name, reduivy__Contact__c, reduivy__Contact__r.reduivy__Contact_Type__c, 
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :sse.Id
        ]){
            assignedContactSet.add(ser.reduivy__Contact__c);
            System.debug(ser.reduivy__Contact__r.reduivy__Contact_Type__c);
        }

        System.debug('assignedContactSet: ' + assignedContactSet);

        Contact unassignedContact = [
            SELECT Id, Name
            FROM Contact
            WHERE Id NOT IN :assignedContactSet
            AND Name LIKE '%Ford'
            LIMIT 1
        ];

        
        
        System.runAs(FACULTY_USER) {   
            Test.startTest();
            
            REDU_LightningResponse response = REDU_SessionFacultyAssignment_LCTRL.assignNewFaculty(
                unassignedContact.Id, 
                new List<Id>((new Map<Id, reduivy__Study_Session_Time__c> (sse.reduivy__Study_Session_Times__r)).keySet()),
                SER_Helper.RESPONSE_STATUS_ACCEPTED, sse.reduivy__Start_Date__c, sse.reduivy__End_Date__c, 
                false, false, null);


            Set<Id> newAssignedContactSet = new Set<Id>();
            for(reduivy__Study_Event_Relation__c ser : [
                SELECT Id, Name, reduivy__Contact__c,
                reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
                FROM reduivy__Study_Event_Relation__c
                WHERE reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :sse.Id
            ]){
                newAssignedContactSet.add(ser.reduivy__Contact__c);
            }

            System.Assert.isTrue(newAssignedContactSet.contains(unassignedContact.Id), 'Contact is not assigned!');

            Test.stopTest();
        }
    }

    
    @IsTest
    static void testForStudentAssignNewFaculty() {

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
            SELECT Id, Name, (
                SELECT Id
                FROM reduivy__Study_Session_Times__r
            ), reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        Set<Id> assignedContactSet = new Set<Id>();
        for(reduivy__Study_Event_Relation__c ser : [
            SELECT Id, Name, reduivy__Contact__c,
            reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Study_Event__r.reduivy__Study_Session_Time__r.reduivy__Study_Session__c = :sse.Id
        ]){
            assignedContactSet.add(ser.reduivy__Contact__c);
        }

        Contact unassignedContact = [
            SELECT Id, Name
            FROM Contact
            WHERE Id NOT IN :assignedContactSet
            AND Name LIKE '%Ford'
            LIMIT 1
        ];

        
        
        System.runAs(studentUser) {   
            Test.startTest();
            
            try{

            REDU_LightningResponse response = REDU_SessionFacultyAssignment_LCTRL.assignNewFaculty(
                unassignedContact.Id, 
                new List<Id>((new Map<Id, reduivy__Study_Session_Time__c> (sse.reduivy__Study_Session_Times__r)).keySet()),
                SER_Helper.RESPONSE_STATUS_ACCEPTED, sse.reduivy__Start_Date__c, sse.reduivy__End_Date__c, 
                false, false, null);
            } catch (Exception exp){
                System.Assert.isTrue(exp.getMessage().contains(INVALID_CROSS_REFERENCE_KEY), 'Wrong Exception Type: ' + exp.getMessage());   
            }
                    


            Test.stopTest();
        }
    }
	
	
}