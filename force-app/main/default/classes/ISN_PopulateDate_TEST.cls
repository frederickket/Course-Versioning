/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for ISN_PopulateDate_EXE
 * @changehistory
 * ISS-002057 26-08-2024 Sueanne - new class
 */
@IsTest
public inherited sharing class ISN_PopulateDate_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final Id ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
    static String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static String ISN_INPROGRESS_STATUS = ISN_Helper.getInProgressStatuses().get(0);

    /**
     * @description Create settings and test data
     */
	@TestSetup
    static void makeData() {
		
		testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SUN_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(IEN_Helper.getApiName(), true);
            
            //find student idv enrollment status = enrolled, select first studyOfferingId for each student
            Map<reduivy__Individual_Enrollment__c, reduivy__Study_Offering__c> idvEnrollWithStudyOffer = new Map<reduivy__Individual_Enrollment__c, reduivy__Study_Offering__c>();
            Set<Id> studentIds = new Set<Id>();

            for(reduivy__Individual_Enrollment__c idvEnroll : testFactory.studentIndividualEnrollments.values()){
                if(idvEnroll.reduivy__Enrollment_Status__c == IEN_INPROGRESS_STATUS && idvEnroll.RecordTypeId == IEN_Helper.getStudentRecordTypeId() && !studentIds.contains(idvEnroll.reduivy__Contact__c)){
                    
                    for(reduivy__Study_Offering__c so : testFactory.studyOfferings.values()){
                        if(so.Id == idvEnroll.reduivy__Study_Offering__c){
                            idvEnrollWithStudyOffer.put(idvEnroll, so);
                            studentIds.add(idvEnroll.reduivy__Contact__c);
                        }
                    }

                }
            }

            //enroll students into Lecture study session (create student session enrollment)
            Map<String, reduivy__Individual_Session_Enrollment__c> studentIndividualSessionEnrollments = new Map<String, reduivy__Individual_Session_Enrollment__c>();

            for(reduivy__Individual_Enrollment__c idvEnroll : idvEnrollWithStudyOffer.keySet()){
                for(reduivy__Study_Session__c ss : testFactory.studySessions.values()){
                    if(ss.reduivy__Study_Offering__c == idvEnrollWithStudyOffer.get(idvEnroll).Id && ss.reduivy__Type__c == 'Lecture'){
                        String isnSampleRecord = ss.Name + '_' + idvEnroll.reduivy__Sample_Record_Code__c;
                        studentIndividualSessionEnrollments.put(isnSampleRecord, REDU_TestData_UTIL.newStudentIndividualSessionEnrollment(isnSampleRecord, ss.Id, idvEnroll.Id, ss.reduivy__Start_Date__c, ISN_INPROGRESS_STATUS));
                    }
                }
            }

            REDU_SystemMode_UTIL.doInsert(studentIndividualSessionEnrollments.values());

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin that each of the individual session enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testIenPopulateDateBeforeUpdateAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study session
        List<reduivy__Study_Session__c> sseList = [SELECT Id, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, 
            reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c 
            FROM reduivy__Study_Session__c 
            LIMIT 1
        ];
        reduivy__Study_Session__c sse = sseList[0];

        //set enrollment dates as null
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnToClearEnrollementDate = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
            AND reduivy__Study_Session__c != :sse.Id
        ]);

        for(reduivy__Individual_Session_Enrollment__c isn : isnToClearEnrollementDate.values()){
            isn.reduivy__Enrollment_Date__c = null;
        }
        REDU_SystemMode_UTIL.doUpdate(isnToClearEnrollementDate.values());

        //check the dates should be null
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnToClearEnrollementDate.keySet()
        ]);

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            System.assertEquals(null, isn.reduivy__Enrollment_Date__c, 'Individual sesion enrollment\'s enrollment date should be null.');
        }

        System.runAs(ADMIN_USER) {

            //set individual session enrollment study session
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Study_Session__c = sse.Id;
            }

            //update isn
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //check whether isn update the dates
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, isn.reduivy__Start_Date__c, 'Individual sesion enrollment\'s start date does not match to the study offering\'s start date.');
            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c, isn.reduivy__End_Date__c, 'Individual sesion enrollment\'s end date does not match to the study offering\'s end date.');
            System.assertEquals(System.today(), isn.reduivy__Enrollment_Date__c, 'Individual sesion enrollment\'s enrollment date should match today\'s date.');
        }

        Test.stopTest(); 
    }

    /**
     * @description Test as admin that each of the individual enrollment record date fields are populated (before insert)
     */
    @IsTest
    static void testIenPopulateDateBeforeInsertAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get individual enrollment
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c LIMIT 1];
        reduivy__Individual_Enrollment__c ien = ienList[0];

        //get study session
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, 
            reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c 
            FROM reduivy__Study_Session__c
        ]);

        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();
        System.runAs(ADMIN_USER) {

            //create individual session enrollment 
            for(reduivy__Study_Session__c sse : sseMap.values()){
                isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test dates population', sse.Id, ien.Id, null, ISN_INPROGRESS_STATUS));
            }

            //insert isn
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
        }

        //get isn Id
        List<Id> isnIds = new List<Id>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToInsert){
            isnIds.add(isn.Id);
        }

        //check whether isn update the dates
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE Id IN :isnIds
        ]){
            reduivy__Study_Session__c sse = sseMap.get(isn.reduivy__Study_Session__c);

            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, isn.reduivy__Start_Date__c, 'Individual sesion enrollment\'s start date does not match to the study offering\'s start date.');
            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c, isn.reduivy__End_Date__c, 'Individual sesion enrollment\'s end date does not match to the study offering\'s end date.');
            System.assertEquals(System.today(), isn.reduivy__Enrollment_Date__c, 'Individual sesion enrollment\'s enrollment date should match today\'s date.');
        }

        Test.stopTest(); 
    }

    /**
     * @description Test as faculty that each of the individual session enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testIenPopulateDateBeforeUpdateAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get study session
        List<reduivy__Study_Session__c> sseList = [SELECT Id, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, 
            reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c 
            FROM reduivy__Study_Session__c 
            LIMIT 1
        ];
        reduivy__Study_Session__c sse = sseList[0];

        //set enrollment dates as null
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnToClearEnrollementDate = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
            AND reduivy__Study_Session__c != :sse.Id
        ]);

        for(reduivy__Individual_Session_Enrollment__c isn : isnToClearEnrollementDate.values()){
            isn.reduivy__Enrollment_Date__c = null;
        }
        REDU_SystemMode_UTIL.doUpdate(isnToClearEnrollementDate.values());

        //check the dates should be null
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnToClearEnrollementDate.keySet()
        ]);

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            System.assertEquals(null, isn.reduivy__Enrollment_Date__c, 'Individual sesion enrollment\'s enrollment date should be null.');
        }

        System.runAs(FACULTY_USER) {

            //set individual session enrollment study session
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Study_Session__c = sse.Id;
            }

            //update isn
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //check whether isn update the dates
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, isn.reduivy__Start_Date__c, 'Individual sesion enrollment\'s start date does not match to the study offering\'s start date.');
            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c, isn.reduivy__End_Date__c, 'Individual sesion enrollment\'s end date does not match to the study offering\'s end date.');
            System.assertEquals(System.today(), isn.reduivy__Enrollment_Date__c, 'Individual sesion enrollment\'s enrollment date should match today\'s date.');
        }

        Test.stopTest(); 
    }

    /**
     * @description Test as faculty that each of the individual enrollment record date fields are populated (before insert)
     */
    @IsTest
    static void testIenPopulateDateBeforeInsertAsFaculty() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get individual enrollment
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c LIMIT 1];
        reduivy__Individual_Enrollment__c ien = ienList[0];

        //get study session
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, 
            reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c 
            FROM reduivy__Study_Session__c
        ]);

        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();
        System.runAs(FACULTY_USER) {

            //create individual session enrollment 
            for(reduivy__Study_Session__c sse : sseMap.values()){
                isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test dates population', sse.Id, ien.Id, null, ISN_INPROGRESS_STATUS));
            }

            //insert isn
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
        }

        //get isn Id
        List<Id> isnIds = new List<Id>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToInsert){
            isnIds.add(isn.Id);
        }

        //check whether isn update the dates
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE Id IN :isnIds
        ]){
            reduivy__Study_Session__c sse = sseMap.get(isn.reduivy__Study_Session__c);

            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, isn.reduivy__Start_Date__c, 'Individual sesion enrollment\'s start date does not match to the study offering\'s start date.');
            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c, isn.reduivy__End_Date__c, 'Individual sesion enrollment\'s end date does not match to the study offering\'s end date.');
            System.assertEquals(System.today(), isn.reduivy__Enrollment_Date__c, 'Individual sesion enrollment\'s enrollment date should match today\'s date.');
        }

        Test.stopTest(); 
    }

    /**
     * @description Test as student that each of the individual session enrollment record date fields are populated (before update)
     */
    @IsTest
    static void testIenPopulateDateBeforeUpdateAsStudent() {

        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get study session
        List<reduivy__Study_Session__c> sseList = [SELECT Id, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, 
            reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c 
            FROM reduivy__Study_Session__c 
            LIMIT 1
        ];
        reduivy__Study_Session__c sse = sseList[0];

        //set enrollment dates as null
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnToClearEnrollementDate = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE RecordTypeId = :ISN_STUDENT_RTID
            AND reduivy__Study_Session__c != :sse.Id
        ]);

        for(reduivy__Individual_Session_Enrollment__c isn : isnToClearEnrollementDate.values()){
            isn.reduivy__Enrollment_Date__c = null;
        }
        REDU_SystemMode_UTIL.doUpdate(isnToClearEnrollementDate.values());

        //check the dates should be null
        Map<Id, reduivy__Individual_Session_Enrollment__c> isnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnToClearEnrollementDate.keySet()
        ]);

        for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
            System.assertEquals(null, isn.reduivy__Enrollment_Date__c, 'Individual sesion enrollment\'s enrollment date should be null.');
        }

        System.runAs(studentUser) {

            //set individual session enrollment study session
            for(reduivy__Individual_Session_Enrollment__c isn : isnMap.values()){
                isn.reduivy__Study_Session__c = sse.Id;
            }

            //update isn
            REDU_SystemMode_UTIL.doUpdate(isnMap.values());
        }

        //check whether isn update the dates
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN :isnMap.keySet()
        ]){
            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, isn.reduivy__Start_Date__c, 'Individual sesion enrollment\'s start date does not match to the study offering\'s start date.');
            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c, isn.reduivy__End_Date__c, 'Individual sesion enrollment\'s end date does not match to the study offering\'s end date.');
            System.assertEquals(System.today(), isn.reduivy__Enrollment_Date__c, 'Individual sesion enrollment\'s enrollment date should match today\'s date.');
        }

        Test.stopTest(); 
    }

    /**
     * @description Test as student that each of the individual enrollment record date fields are populated (before insert)
     */
    @IsTest
    static void testIenPopulateDateBeforeInsertAsStudent() {
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get individual enrollment
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c LIMIT 1];
        reduivy__Individual_Enrollment__c ien = ienList[0];

        //get study session
        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, 
            reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c 
            FROM reduivy__Study_Session__c
        ]);

        List<reduivy__Individual_Session_Enrollment__c> isnToInsert = new List<reduivy__Individual_Session_Enrollment__c>();
        System.runAs(studentUser) {

            //create individual session enrollment 
            for(reduivy__Study_Session__c sse : sseMap.values()){
                isnToInsert.add(REDU_TestData_UTIL.newStudentIndividualSessionEnrollment('To test dates population', sse.Id, ien.Id, null, ISN_INPROGRESS_STATUS));
            }

            //insert isn
            REDU_SystemMode_UTIL.doInsert(isnToInsert);
        }

        //get isn Id
        List<Id> isnIds = new List<Id>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToInsert){
            isnIds.add(isn.Id);
        }

        //check whether isn update the dates
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Study_Session__c, reduivy__Enrollment_Date__c, reduivy__Start_Date__c, reduivy__End_Date__c
            FROM reduivy__Individual_Session_Enrollment__c 
            WHERE Id IN :isnIds
        ]){
            reduivy__Study_Session__c sse = sseMap.get(isn.reduivy__Study_Session__c);

            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__Start_Date_Calculated__c, isn.reduivy__Start_Date__c, 'Individual sesion enrollment\'s start date does not match to the study offering\'s start date.');
            System.assertEquals(sse.reduivy__Study_Offering__r.reduivy__End_Date_Calculated__c, isn.reduivy__End_Date__c, 'Individual sesion enrollment\'s end date does not match to the study offering\'s end date.');
            System.assertEquals(System.today(), isn.reduivy__Enrollment_Date__c, 'Individual sesion enrollment\'s enrollment date should match today\'s date.');
        }

        Test.stopTest(); 
    }
}