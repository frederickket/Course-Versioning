/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for ISN_DeleteStudyEventRelations_EXE
 * @changehistory
 * ISS-002052 21-08-2024 Sueanne - new class
 */
@isTest
public inherited sharing class ISN_DeleteStudyEventRelations_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static String ISN_INPROGRESS_STATUS = ISN_Helper.getInProgressStatuses().get(0);
    
    /**
     * @description Default method to setup required data for automated test
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

            if (!testFactory.studyEvents.isEmpty()) {
                //create study event relation for student
                //Map studySessionId + IndividualSessionEnrollment (Map 1) --- match studySessionId
                Map<Id, List<reduivy__Individual_Session_Enrollment__c>> ssIdWithIsnList = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();
                for(reduivy__Individual_Session_Enrollment__c isn : studentIndividualSessionEnrollments.values()){
                    if(isn.RecordTypeId == ISN_Helper.getStudentRecordTypeId()){
                        if (ssIdWithIsnList.containsKey(isn.reduivy__Study_Session__c)) {
                            ssIdWithIsnList.get(isn.reduivy__Study_Session__c).add(isn);
                        } else {
                            ssIdWithIsnList.put(isn.reduivy__Study_Session__c, new List<reduivy__Individual_Session_Enrollment__c>{isn});
                        }
                    }
                }
    
                //Map studySessionTimeId + studySessionId -> Map studySessionId + StudyEvent (Map 2)
                Map<Id, Id> sstIdWithSsId = new Map<Id, Id>();
                for(reduivy__Study_Session_Time__c sst : testFactory.studySessionTimes.values()){
                    sstIdWithSsId.put(sst.Id, sst.reduivy__Study_Session__c);
                }
    
                Map<Id, List<reduivy__Study_Event__c>> ssIdWithSe = new Map<Id, List<reduivy__Study_Event__c>>();
                for(reduivy__Study_Event__c se : testFactory.studyEvents.values()){
                    Id ssId = sstIdWithSsId.get(se.reduivy__Study_Session_Time__c);
                    if(ssId != null){
                        if(!ssIdWithSe.containsKey(ssId)){
                            ssIdWithSe.put(ssId, new List<reduivy__Study_Event__c>());
                        }
                        ssIdWithSe.get(ssId).add(se);
                    }
                }
    
                //match studySessionId Map 1 and Map 2 (for create study event relations)
                Map<Id, reduivy__Individual_Enrollment__c> iensMapById = new Map<Id, reduivy__Individual_Enrollment__c>(testFactory.studentIndividualEnrollments.values());
                Map<String, reduivy__Study_Event_Relation__c> studentStudyEventRelations = new Map<String, reduivy__Study_Event_Relation__c>();
                
                for(Id ssId : ssIdWithIsnList.keySet()){
                    if(ssIdWithSe.containsKey(ssId)){
                        List<reduivy__Study_Event__c> seList = ssIdWithSe.get(ssId);
                        List<reduivy__Individual_Session_Enrollment__c> isnList = ssIdWithIsnList.get(ssId);
                        for (reduivy__Individual_Session_Enrollment__c isn : isnList) {
                            for(reduivy__Study_Event__c se : seList){
                                DateTime startDt = se.reduivy__Start__c;
                                DateTime endDt = se.reduivy__End__c;
                                
                                if(endDt.date() <= System.today()){
                                    Time checkInTime = startDt.time();
                                    Time checkOutTime = endDt.time();
                                    String attendStatus = 'Attended';
                                    String serSampleRecord = isn.reduivy__Sample_Record_Code__c + '_' + se.reduivy__Sample_Record_Code__c;
                                    studentStudyEventRelations.put(serSampleRecord, REDU_TestData_UTIL.newStudentStudyEventRelation(serSampleRecord, iensMapById.get(isn.reduivy__Individual_Enrollment__c).reduivy__Contact__c, se.Id, isn.Id, checkInTime, checkOutTime, attendStatus));
                                }
                            }
                        }
                    }
                }
    
                REDU_SystemMode_UTIL.doInsert(studentStudyEventRelations.values());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin to delete individual session enrollment
     */
    @isTest
    static void testDeleteIsnAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> allIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id
            FROM reduivy__Individual_Session_Enrollment__c
        ]);
        System.Assert.areEqual(false, allIsnMap.isEmpty(), 'Individual Session Enrollment map should not be empty.');

        //get study event relations
        Map<Id, reduivy__Study_Event_Relation__c> serMap = new Map<Id, reduivy__Study_Event_Relation__c>([
            SELECT Id
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Individual_Session_Enrollment__c IN :allIsnMap.keySet()
        ]);
        System.Assert.areEqual(false, serMap.isEmpty(), 'Study Event Relation map should not be empty.');


        System.runAs(ADMIN_USER) {
            REDU_SystemMode_UTIL.doDelete(allIsnMap.values());
        }

        //check whether associated study event relation still exist
        Map<Id, reduivy__Study_Event_Relation__c> serAfterIsnDelete = new Map<Id, reduivy__Study_Event_Relation__c>([
            SELECT Id
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Individual_Session_Enrollment__c IN :allIsnMap.keySet()
        ]);
        System.Assert.areEqual(true, serAfterIsnDelete.isEmpty(), 'Study Event Relation record should be delete.');


        Test.stopTest();

    }

    /**
     * @description Test as faculty to delete student individual session enrollment
     */
    @isTest
    static void testDeleteIsnAsFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> allIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id
            FROM reduivy__Individual_Session_Enrollment__c
        ]);
        System.Assert.areEqual(false, allIsnMap.isEmpty(), 'Individual Session Enrollment map should not be empty.');

        //get study event relations
        Map<Id, reduivy__Study_Event_Relation__c> serMap = new Map<Id, reduivy__Study_Event_Relation__c>([
            SELECT Id
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Individual_Session_Enrollment__c IN :allIsnMap.keySet()
        ]);
        System.Assert.areEqual(false, serMap.isEmpty(), 'Study Event Relation map should not be empty.');


        System.runAs(FACULTY_USER) {
            REDU_SystemMode_UTIL.doDelete(allIsnMap.values());
        }

        //check whether associated study event relation still exist
        Map<Id, reduivy__Study_Event_Relation__c> serAfterIsnDelete = new Map<Id, reduivy__Study_Event_Relation__c>([
            SELECT Id
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Individual_Session_Enrollment__c IN :allIsnMap.keySet()
        ]);
        System.Assert.areEqual(true, serAfterIsnDelete.isEmpty(), 'Study Event Relation record should be delete.');


        Test.stopTest();

    }

    /**
     * @description Test as student to delete student individual session enrollment
     */
    @isTest
    static void testDeleteIsnAsStudent() {

        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get individual session enrollments
        Map<Id, reduivy__Individual_Session_Enrollment__c> allIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>([
            SELECT Id
            FROM reduivy__Individual_Session_Enrollment__c
        ]);
        System.Assert.areEqual(false, allIsnMap.isEmpty(), 'Individual Session Enrollment map should not be empty.');

        //get study event relations
        Map<Id, reduivy__Study_Event_Relation__c> serMap = new Map<Id, reduivy__Study_Event_Relation__c>([
            SELECT Id
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Individual_Session_Enrollment__c IN :allIsnMap.keySet()
        ]);
        System.Assert.areEqual(false, serMap.isEmpty(), 'Study Event Relation map should not be empty.');


        System.runAs(studentUser) {
            REDU_SystemMode_UTIL.doDelete(allIsnMap.values());
        }

        //check whether associated study event relation still exist
        Map<Id, reduivy__Study_Event_Relation__c> serAfterIsnDelete = new Map<Id, reduivy__Study_Event_Relation__c>([
            SELECT Id
            FROM reduivy__Study_Event_Relation__c
            WHERE reduivy__Individual_Session_Enrollment__c IN :allIsnMap.keySet()
        ]);
        System.Assert.areEqual(true, serAfterIsnDelete.isEmpty(), 'Study Event Relation record should be delete.');


        Test.stopTest();

    }
}