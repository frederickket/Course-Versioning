/**
 * @author      WDCi (CM)
 * @date        Aug 2024
 * @group       Grade Management
 * @description Test class for REDU_StudentGrading_LCTRL
 * @changehistory
 * ISS-001918 27-08-2024 CM - new class
 */
@isTest
public inherited sharing class REDU_StudentGrading_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    static final String IEN_INPROGRESS_STATUSES = String.join(IEN_Helper.getInProgressStatuses(), ';');
    static final String ISN_INPROGRESS_STATUSES = String.join(ISN_Helper.getInProgressStatuses(), ';');

    static final String sseGradedSofSampleCode = 'BUS101_CYT1_SYDNEY';
    static final String sofGradedSofSampleCode = 'BUS102_CYT1_SYDNEY';

    static String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static String ISN_INPROGRESS_STATUS = ISN_Helper.getInProgressStatuses().get(0);
    
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
            testFactory.initMasterData(SGI_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(IEN_Helper.getApiName(), false);

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

            //Set one of the Study Offerings to be graded by Study Offering
            reduivy__Study_Offering__c sofGradeStudyOffering = [
                SELECT Id, 
                reduivy__Grade_By__c, 
                reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Sample_Record_Code__c = :sofGradedSofSampleCode
            ];
            sofGradeStudyOffering.reduivy__Grade_By__c = SOF_Helper.GRADE_BY_STUDYOFFERING;
            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Offering__c>{sofGradeStudyOffering});

            //Already assigned a faculty to BUS101 Sydney, want to assign to BUS102 Sydney too
            //Get faculty contact id
            User facultyUser = testFactory.getAllocatedFacultyUser();
            Contact facultyContact = [SELECT Id FROM Contact WHERE reduivy__User__c = :facultyUser.Id];
            System.Assert.isNotNull(facultyContact);
            //Create 2nd Faculty Individual Enrollment
            reduivy__Individual_Enrollment__c facultyIen2 = REDU_TestData_UTIL.newFacultyIndividualEnrollment(null, facultyContact.Id, sofGradeStudyOffering.Id, IEN_Helper.getInProgressStatuses()[0]);
            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{facultyIen2});

        }

    }

    /**
     * @description Test as admin for REDU_StudentGrading_LCTRL
     */
    @isTest
    static void testForAdminGetListings() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //Get faculty contact id
        User facultyUser = testFactory.getAllocatedFacultyUser();
        Contact facultyContact = [SELECT Id FROM Contact WHERE reduivy__User__c = :facultyUser.Id];
        System.Assert.isNotNull(facultyContact);

        List<reduivy__Individual_Enrollment__c> facultyIenEnrollments = [
            SELECT Id, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Grade_By__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c =: facultyContact.Id
        ];
        System.Assert.isTrue(facultyIenEnrollments.size() > 0);
        List<reduivy__Individual_Session_Enrollment__c> facultyIsnEnrollments = [
            SELECT Id, 
            reduivy__Study_Session__c, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Grade_By__c 
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Individual_Enrollment__r.reduivy__Contact__c =: facultyContact.Id
        ];
        System.Assert.isTrue(facultyIsnEnrollments.size() > 0);

        //Calculate the expected listings
        Integer expectedListings = 0;
        Integer expectedListingsWhenshowRecordsBasedOnAllocationChecked = 0;
        Set<Id> sofListingIds = new Set<Id>();
        Set<Id> sseListingIds = new Set<Id>();
        for (reduivy__Individual_Enrollment__c ien : facultyIenEnrollments){
            if (ien.reduivy__Study_Offering__r.reduivy__Grade_By__c == SOF_Helper.GRADE_BY_STUDYOFFERING){
                expectedListings++;
                expectedListingsWhenshowRecordsBasedOnAllocationChecked++;
                sofListingIds.add(ien.reduivy__Study_Offering__c);
            }
        }
        for (reduivy__Individual_Session_Enrollment__c isn : facultyIsnEnrollments){
            if (isn.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Grade_By__c == SOF_Helper.GRADE_BY_STUDYSESSION){
                expectedListings++;
                sseListingIds.add(isn.reduivy__Study_Session__c);
            }
        }

        Test.startTest();
        System.runAs(ADMIN_USER){

            //Run component with admin contact (which does not exist)
            REDU_LightningResponse response = REDU_StudentGrading_LCTRL.getListings(null, null, false, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, false);
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check listings - should be empty
            List<REDU_StudentGrading_LCTRL.ListingWrapper> listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.isTrue(listingWrappers.isEmpty(), 'Admin should not belong to any Study Offerings/Study Sessions');

            //Run component with faculty contact
            response = REDU_StudentGrading_LCTRL.getListings(facultyContact.Id, null, false, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, false);
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check listings - should be equal to the number of their enrollments
            listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.areEqual(expectedListings, listingWrappers.size(), 'Faculty should return a list of their assigned Study Offerings/Sessions');

            //Ensure returned data is correct
            Integer sofListingCount = 0;
            Integer sseListingCount = 0;
            for (REDU_StudentGrading_LCTRL.ListingWrapper lw : listingWrappers){
                if (lw.sObjectName == SOF_Helper.getApiName()){
                    System.Assert.isTrue(sofListingIds.contains(lw.id), 'Incorrect listing type returned');
                    sofListingCount++;
                } else if (lw.sObjectName == SSE_Helper.getApiName()){
                    System.Assert.isTrue(sseListingIds.contains(lw.id), 'Incorrect listing type returned');
                    sseListingCount++;
                }
            }
            System.Assert.areEqual(sofListingIds.size(), sofListingCount, 'Incorrect number of Study Offering listings returned');
            System.Assert.areEqual(sseListingIds.size(), sseListingCount, 'Incorrect number of Study Session listings returned');

            //showRecordsBasedOnAllocation checked (With Study Event Relations data exist)
            response = REDU_StudentGrading_LCTRL.getListings(facultyContact.Id, null, false, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, true);
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check listings - should be equal to the number of their enrollments
            listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.areEqual(expectedListings, listingWrappers.size(), 'Faculty should not return any data as no study event relations data exist');

            List<reduivy__Study_Event_Relation__c> studyEventRelations = [SELECT Id FROM reduivy__Study_Event_Relation__c];
            delete studyEventRelations;

            //showRecordsBasedOnAllocation checked (Without Study Event Relations data exist)
            response = REDU_StudentGrading_LCTRL.getListings(facultyContact.Id, null, false, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, true);
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check listings - should be equal to the number of their enrollments
            listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.areEqual(expectedListingsWhenshowRecordsBasedOnAllocationChecked, listingWrappers.size(), 'Faculty should not return any data as no study event relations data exist');
        }

        Test.stopTest();

    }

    /**
     * @description Test as faculty for REDU_StudentGrading_LCTRL
     */
    @isTest
    static void testForFacultyGetListings() {
        
        //Get faculty contact id
        User facultyUser = testFactory.getAllocatedFacultyUser();
        Contact facultyContact = [
            SELECT Id 
            FROM Contact 
            WHERE reduivy__User__c = :facultyUser.Id
        ];
        System.Assert.isNotNull(facultyContact);

        List<reduivy__Individual_Enrollment__c> facultyIenEnrollments = [
            SELECT Id, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Grade_By__c 
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c =: facultyContact.Id
        ];
        System.Assert.isTrue(facultyIenEnrollments.size() > 0);
        List<reduivy__Individual_Session_Enrollment__c> facultyIsnEnrollments = [
            SELECT Id, 
            reduivy__Study_Session__c, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Grade_By__c 
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Individual_Enrollment__r.reduivy__Contact__c =: facultyContact.Id
        ];
        System.Assert.isTrue(facultyIsnEnrollments.size() > 0);

        //Calculate the expected listings
        Integer expectedListings = 0;
        Integer expectedListingsWhenshowRecordsBasedOnAllocationChecked = 0;
        Set<Id> sofListingIds = new Set<Id>();
        Set<Id> sseListingIds = new Set<Id>();
        
        for (reduivy__Individual_Enrollment__c ien : facultyIenEnrollments){
            if (ien.reduivy__Study_Offering__r.reduivy__Grade_By__c == SOF_Helper.GRADE_BY_STUDYOFFERING){
                expectedListings++;
                expectedListingsWhenshowRecordsBasedOnAllocationChecked++;
                sofListingIds.add(ien.reduivy__Study_Offering__c);
            }
        }
        for (reduivy__Individual_Session_Enrollment__c isn : facultyIsnEnrollments){
            if (isn.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Grade_By__c == SOF_Helper.GRADE_BY_STUDYSESSION){
                expectedListings++;
                sseListingIds.add(isn.reduivy__Study_Session__c);
            }
        }

        Test.startTest();
        System.runAs(facultyUser){

            //Run component with admin contact (which does not exist)
            REDU_LightningResponse response = REDU_StudentGrading_LCTRL.getListings(null, null, false, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, false);
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check listings - should be equal to the number of their enrollments
            List<REDU_StudentGrading_LCTRL.ListingWrapper> listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.areEqual(expectedListings, listingWrappers.size(), 'Faculty should return a list of their assigned Study Offerings/Sessions');

            //Ensure returned data is correct
            Integer sofListingCount = 0;
            Integer sseListingCount = 0;
            for (REDU_StudentGrading_LCTRL.ListingWrapper lw : listingWrappers){
                if (lw.sObjectName == SOF_Helper.getApiName()){
                    System.Assert.isTrue(sofListingIds.contains(lw.id), 'Incorrect listing type returned');
                    sofListingCount++;
                } else if (lw.sObjectName == SSE_Helper.getApiName()){
                    System.Assert.isTrue(sseListingIds.contains(lw.id), 'Incorrect listing type returned');
                    sseListingCount++;
                }
            }

            System.Assert.areEqual(sofListingIds.size(), sofListingCount, 'Incorrect number of Study Offering listings returned');
            System.Assert.areEqual(sseListingIds.size(), sseListingCount, 'Incorrect number of Study Session listings returned');

            //showRecordsBasedOnAllocation checked (With Study Event Relations data exist)
            response = REDU_StudentGrading_LCTRL.getListings(facultyContact.Id, null, false, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, true);
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check listings - should be equal to the number of their enrollments
            listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.areEqual(expectedListings, listingWrappers.size(), 'Faculty should not return any data as no study event relations data exist');
        }

        List<reduivy__Study_Event_Relation__c> studyEventRelations = [SELECT Id FROM reduivy__Study_Event_Relation__c];
        delete studyEventRelations;

        System.runAs(facultyUser){
            //showRecordsBasedOnAllocation checked (Without Study Event Relations data exist)
            REDU_LightningResponse response = REDU_StudentGrading_LCTRL.getListings(facultyContact.Id, null, false, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, true);
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check listings - should be equal to the number of their enrollments
            List<REDU_StudentGrading_LCTRL.ListingWrapper> listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.areEqual(expectedListingsWhenshowRecordsBasedOnAllocationChecked, listingWrappers.size(), 'Faculty should not return any data as no study event relations data exist');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for the no grades indicator
     */
    @isTest
    static void testForAdminShowNoGrades() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //Get faculty contact id
        User facultyUser = testFactory.getAllocatedFacultyUser();
        Contact facultyContact = [
            SELECT Id 
            FROM Contact 
            WHERE reduivy__User__c = :facultyUser.Id
        ];
        System.Assert.isNotNull(facultyContact);

        List<reduivy__Individual_Enrollment__c> facultyIenEnrollments = [
            SELECT Id, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Grade_By__c, 
            reduivy__Study_Offering__r.reduivy__Academic_Term__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c =: facultyContact.Id
        ];
        System.Assert.isTrue(facultyIenEnrollments.size() > 0);
        List<reduivy__Individual_Session_Enrollment__c> facultyIsnEnrollments = [
            SELECT Id, 
            reduivy__Study_Session__c, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Grade_By__c, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Academic_Term__c 
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Individual_Enrollment__r.reduivy__Contact__c =: facultyContact.Id
        ];
        System.Assert.isTrue(facultyIsnEnrollments.size() > 0);

        //Prepare Grades for each student enrolled into the study offerings
        Set<Id> sofListingIds = new Set<Id>();
        Set<Id> sseListingIds = new Set<Id>();
        Map<Id, Id> termToSgpMap = new Map<Id, Id>();
        for (reduivy__Individual_Enrollment__c ien : facultyIenEnrollments){
            sofListingIds.add(ien.reduivy__Study_Offering__c);
            termToSgpMap.put(ien.reduivy__Study_Offering__r.reduivy__Academic_Term__c, null);
        }
        for (reduivy__Individual_Session_Enrollment__c isn : facultyIsnEnrollments){
            sofListingIds.add(isn.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__c);
            termToSgpMap.put(isn.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Academic_Term__c, null);
            sseListingIds.add(isn.reduivy__Study_Session__c);
        }

        //Some Study Sessions don't have students. We'll ignore them in the test assertions.
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [
            SELECT Id, 
            reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseListingIds 
            AND RecordTypeId = :ISN_Helper.getStudentRecordTypeId()
        ];
        System.Assert.isFalse(studentIsnList.isEmpty(), 'No students enrolled in study sessions');
        Set<Id> sseWithStudents = new Set<Id>();
        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList){
            sseWithStudents.add(isn.reduivy__Study_Session__c);
        }

        List<reduivy__Study_Grade_Period_Setting__c> sgpList = [
            SELECT Id, 
            reduivy__Academic_Term__c
            FROM reduivy__Study_Grade_Period_Setting__c
            WHERE reduivy__Academic_Term__c IN :termToSgpMap.keySet()
        ];
        for (reduivy__Study_Grade_Period_Setting__c sgp : sgpList){
            termToSgpMap.put(sgp.reduivy__Academic_Term__c, sgp.Id);
        }

        List<reduivy__Individual_Enrollment__c> studentIenList = [
            SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Academic_Term__c 
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofListingIds 
            AND RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ];
        List<reduivy__Individual_Enrollment_Grade__c> studentIgdList = new List<reduivy__Individual_Enrollment_Grade__c>();
        for (reduivy__Individual_Enrollment__c ien : studentIenList){
            reduivy__Individual_Enrollment_Grade__c igd = REDU_TestData_UTIL.newIndividualEnrollmentGrade(
                null, ien.reduivy__Contact__c, ien.Id, ien.reduivy__Study_Offering__r.reduivy__Academic_Term__c, termToSgpMap.get(ien.reduivy__Study_Offering__r.reduivy__Academic_Term__c), ien.reduivy__Study_Offering__c, 
                null, null, null, null, null, null
            );
            studentIgdList.add(igd);
        }


        Test.startTest();
        System.runAs(ADMIN_USER){

            //Run component with faculty contact
            REDU_LightningResponse response = REDU_StudentGrading_LCTRL.getListings(facultyContact.Id, null, true, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, false);
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check listings - none of them should have grades marked
            List<REDU_StudentGrading_LCTRL.ListingWrapper> listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.isFalse(listingWrappers.isEmpty(), 'Faculty should return a list of their assigned Study Offerings/Sessions');

            for (REDU_StudentGrading_LCTRL.ListingWrapper lw : listingWrappers){
                if (sofListingIds.contains(lw.id) || sseWithStudents.contains(lw.id)){
                    System.Assert.isTrue(lw.showNoGradeWarning, 'Should show No Grade Warning. ' + JSON.serialize(lw));
                }
            }

            //Add grades for all students in all study offerings
            REDU_Database_UTIL.doInsert(studentIgdList);

            //Re-run component
            response = REDU_StudentGrading_LCTRL.getListings(facultyContact.Id, null, true, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, false);
            System.Assert.isTrue(response.isSuccess, response.message);

            //Check listings - all of them should have grades marked
            listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.isFalse(listingWrappers.isEmpty(), 'Faculty should return a list of their assigned Study Offerings/Sessions');

            for (REDU_StudentGrading_LCTRL.ListingWrapper lw : listingWrappers){
                if (sofListingIds.contains(lw.id) || sseWithStudents.contains(lw.id)){
                    System.Assert.isFalse(lw.showNoGradeWarning, 'Should no longer show No Grade Warning');
                }
            }

        }
        Test.stopTest();
        
    }

    /**
     * @description Test as admin for the no grades indicator
     */
    @isTest
    static void testForFacultyShowNoGrades() {

        //Get faculty contact id
        User facultyUser = testFactory.getAllocatedFacultyUser();
        Contact facultyContact = [
            SELECT Id 
            FROM Contact 
            WHERE reduivy__User__c = :facultyUser.Id
        ];
        System.Assert.isNotNull(facultyContact);

        List<reduivy__Individual_Enrollment__c> facultyIenEnrollments = [
            SELECT Id, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Grade_By__c, 
            reduivy__Study_Offering__r.reduivy__Academic_Term__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Contact__c =: facultyContact.Id
        ];
        System.Assert.isTrue(facultyIenEnrollments.size() > 0);
        List<reduivy__Individual_Session_Enrollment__c> facultyIsnEnrollments = [
            SELECT Id, 
            reduivy__Study_Session__c, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Grade_By__c, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Academic_Term__c 
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Individual_Enrollment__r.reduivy__Contact__c =: facultyContact.Id
        ];
        System.Assert.isTrue(facultyIsnEnrollments.size() > 0);

        //Prepare Grades for each student enrolled into the study offerings
        Set<Id> sofListingIds = new Set<Id>();
        Set<Id> sseListingIds = new Set<Id>();
        Map<Id, Id> termToSgpMap = new Map<Id, Id>();
        for (reduivy__Individual_Enrollment__c ien : facultyIenEnrollments){
            sofListingIds.add(ien.reduivy__Study_Offering__c);
            termToSgpMap.put(ien.reduivy__Study_Offering__r.reduivy__Academic_Term__c, null);
        }
        for (reduivy__Individual_Session_Enrollment__c isn : facultyIsnEnrollments){
            sofListingIds.add(isn.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__c);
            termToSgpMap.put(isn.reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Academic_Term__c, null);
            sseListingIds.add(isn.reduivy__Study_Session__c);
        }

        //Some Study Sessions don't have students. We'll ignore them in the test assertions.
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [
            SELECT Id, 
            reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseListingIds 
            AND RecordTypeId = :ISN_Helper.getStudentRecordTypeId()
        ];
        System.Assert.isFalse(studentIsnList.isEmpty(), 'No students enrolled in study sessions');
        Set<Id> sseWithStudents = new Set<Id>();
        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList){
            sseWithStudents.add(isn.reduivy__Study_Session__c);
        }

        List<reduivy__Study_Grade_Period_Setting__c> sgpList = [
            SELECT Id, 
            reduivy__Academic_Term__c
            FROM reduivy__Study_Grade_Period_Setting__c
            WHERE reduivy__Academic_Term__c IN :termToSgpMap.keySet()
        ];
        for (reduivy__Study_Grade_Period_Setting__c sgp : sgpList){
            termToSgpMap.put(sgp.reduivy__Academic_Term__c, sgp.Id);
        }

        List<reduivy__Individual_Enrollment__c> studentIenList = [
            SELECT Id, 
            reduivy__Contact__c, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Academic_Term__c 
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofListingIds 
            AND RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ];
        List<reduivy__Individual_Enrollment_Grade__c> studentIgdList = new List<reduivy__Individual_Enrollment_Grade__c>();
        for (reduivy__Individual_Enrollment__c ien : studentIenList){
            reduivy__Individual_Enrollment_Grade__c igd = REDU_TestData_UTIL.newIndividualEnrollmentGrade(
                null, ien.reduivy__Contact__c, ien.Id, ien.reduivy__Study_Offering__r.reduivy__Academic_Term__c, termToSgpMap.get(ien.reduivy__Study_Offering__r.reduivy__Academic_Term__c), ien.reduivy__Study_Offering__c, 
                null, null, null, null, null, null
            );
            studentIgdList.add(igd);
        }


        Test.startTest();
        System.runAs(facultyUser){

            //Run component with faculty contact
            REDU_LightningResponse response = REDU_StudentGrading_LCTRL.getListings(null, null, true, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, false);
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check listings - none of them should have grades marked
            List<REDU_StudentGrading_LCTRL.ListingWrapper> listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.isFalse(listingWrappers.isEmpty(), 'Faculty should return a list of their assigned Study Offerings/Sessions');

            for (REDU_StudentGrading_LCTRL.ListingWrapper lw : listingWrappers){
                if (sofListingIds.contains(lw.id) || sseWithStudents.contains(lw.id)){
                    System.Assert.isTrue(lw.showNoGradeWarning, 'Should show No Grade Warning. ' + JSON.serialize(lw));
                }
            }

            //Add grades for all students in all study offerings
            REDU_Database_UTIL.doInsert(studentIgdList);

            //Re-run component
            response = REDU_StudentGrading_LCTRL.getListings(null, null, true, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, null, null, null, false);
            System.Assert.isTrue(response.isSuccess, response.message);

            //Check listings - all of them should have grades marked
            listingWrappers = (List<REDU_StudentGrading_LCTRL.ListingWrapper>) JSON.deserialize(response.responseData, List<REDU_StudentGrading_LCTRL.ListingWrapper>.class);
            System.Assert.isFalse(listingWrappers.isEmpty(), 'Faculty should return a list of their assigned Study Offerings/Sessions');

            for (REDU_StudentGrading_LCTRL.ListingWrapper lw : listingWrappers){
                if (sofListingIds.contains(lw.id) || sseWithStudents.contains(lw.id)){
                    System.Assert.isFalse(lw.showNoGradeWarning, 'Should no longer show No Grade Warning');
                }
            }

        }
        Test.stopTest();
        
    }

}