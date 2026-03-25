/**
 * @author      WDCi (Sueanne)
 * @date        Sept 2024
 * @group       Test
 * @description Test class for REDU_IpePathwayStudySession_LCTRL
 * @changehistory
 * ISS-002050 26-09-2024 Sueanne - new class
 */
@IsTest
public inherited sharing class REDU_IpePathwayStudySession_TEST {

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
        User ADMIN_USER = testFactory.getReduAdminUser();
		
		// Create test data
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(null);
            testFactory.initOfferingData(null);

            Test.stopTest();
        }
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL
     */
    @IsTest
    static void testInitStudySessionAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            LIMIT 1
        ];

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ipe.Id
            LIMIT 1
        ];


        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseIds
            AND reduivy__Individual_Enrollment__c IN :ienIds
            AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
        ]){
            sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
        }

        System.runAs(ADMIN_USER){
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                    
                }
            }

            //test for getStudySessionStatuses()
            REDU_LightningResponse sseStatusResponse = REDU_IpePathwayStudySession_LCTRL.getStudySessionStatuses();
            System.Assert.areEqual(true, sseStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

            //test for getIndividualSessionEnrollmentStatuses()
            REDU_LightningResponse isnStatusResponse = REDU_IpePathwayStudySession_LCTRL.getIndividualSessionEnrollmentStatuses();
            System.Assert.areEqual(true, isnStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL
     */
    @IsTest
    static void testInitStudySessionAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            LIMIT 1
        ];

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ipe.Id
            LIMIT 1
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }

        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseIds
            AND reduivy__Individual_Enrollment__c IN :ienIds
            AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
        ]){
            sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
        }

        System.runAs(FACULTY_USER){
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');
                }
            }

            //test for getStudySessionStatuses()
            REDU_LightningResponse sseStatusResponse = REDU_IpePathwayStudySession_LCTRL.getStudySessionStatuses();
            System.Assert.areEqual(true, sseStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

            //test for getIndividualSessionEnrollmentStatuses()
            REDU_LightningResponse isnStatusResponse = REDU_IpePathwayStudySession_LCTRL.getIndividualSessionEnrollmentStatuses();
            System.Assert.areEqual(true, isnStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL
     */
    @IsTest
    static void testInitStudySessionAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Contact__c = :studentUser.ContactId
            LIMIT 1
        ];

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ipe.Id
            LIMIT 1
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }

        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, 
            reduivy__Enrollment_Status__c, 
            reduivy__Individual_Enrollment__c, 
            reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseIds
            AND reduivy__Individual_Enrollment__c IN :ienIds
            AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
            AND reduivy__Contact_Id__c = :studentUser.ContactId
        ]){
            sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
        }

        System.runAs(studentUser){
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                }
            }

            //test for getStudySessionStatuses()
            REDU_LightningResponse sseStatusResponse = REDU_IpePathwayStudySession_LCTRL.getStudySessionStatuses();
            System.Assert.areEqual(true, sseStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

            //test for getIndividualSessionEnrollmentStatuses()
            REDU_LightningResponse isnStatusResponse = REDU_IpePathwayStudySession_LCTRL.getIndividualSessionEnrollmentStatuses();
            System.Assert.areEqual(true, isnStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.initStudySession() to check class year and class standing match in study cohort enrollment record
     */
    @IsTest
    static void testMatchClassYearClassStandingCohortAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        //get current term start date
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Academic_Term__r.reduivy__Start_Date__c = :currentYearTerm1StartDate
            AND reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c = false
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Class_Year__c = :String.valueOf(currentYearTerm1StartDate.year())
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND Id = :ipw.reduivy__Individual_Program_Enrollment__c
            LIMIT 1
        ];

        //get sce to check
        reduivy__Study_Cohort_Enrollment__c sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);

        reduivy__Study_Term__c stm = [
            SELECT Id, reduivy__Enable_Cohort_Enrollment__c
            FROM reduivy__Study_Term__c
            WHERE Id = :sce.reduivy__Academic_Term__c
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseIds
            AND reduivy__Individual_Enrollment__c IN :ienIds
            AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
        ]){
            sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
        }

        

        System.runAs(ADMIN_USER){

            //to enable cohort enrollment
            stm.reduivy__Enable_Cohort_Enrollment__c = true;
            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Term__c>{stm});
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                    Map<String, Object> sceData = (Map<String, Object>) data.get('sce');
                    System.Assert.areEqual(sce.Id, sceData.get('Id'), 'The study cohort enrollment Id should match.');
                }
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.initStudySession() to check class year and class standing match in study cohort enrollment record
     */
    @IsTest
    static void testMatchClassYearClassStandingCohortAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        //get current term start date
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Academic_Term__r.reduivy__Start_Date__c = :currentYearTerm1StartDate
            AND reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c = false
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Class_Year__c = :String.valueOf(currentYearTerm1StartDate.year())
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND Id = :ipw.reduivy__Individual_Program_Enrollment__c
            LIMIT 1
        ];

        //get sce to check
        reduivy__Study_Cohort_Enrollment__c sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);

        reduivy__Study_Term__c stm = [
            SELECT Id, reduivy__Enable_Cohort_Enrollment__c
            FROM reduivy__Study_Term__c
            WHERE Id = :sce.reduivy__Academic_Term__c
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseIds
            AND reduivy__Individual_Enrollment__c IN :ienIds
            AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
        ]){
            sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
        }

        //to enable cohort enrollment
        stm.reduivy__Enable_Cohort_Enrollment__c = true;
        REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Term__c>{stm});

        System.runAs(FACULTY_USER){
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                    Map<String, Object> sceData = (Map<String, Object>) data.get('sce');
                    System.Assert.areEqual(sce.Id, sceData.get('Id'), 'The study cohort enrollment Id should match.');
                }
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.initStudySession() to check class year and class standing match in study cohort enrollment record
     */
    @IsTest
    static void testMatchClassYearClassStandingCohortAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        //get current term start date
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Academic_Term__r.reduivy__Start_Date__c = :currentYearTerm1StartDate
            AND reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c = false
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Class_Year__c = :String.valueOf(currentYearTerm1StartDate.year())
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c =: studentUser.ContactId
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND Id = :ipw.reduivy__Individual_Program_Enrollment__c
            LIMIT 1
        ];

        //get sce to check
        reduivy__Study_Cohort_Enrollment__c sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);

        reduivy__Study_Term__c stm = [
            SELECT Id, reduivy__Enable_Cohort_Enrollment__c
            FROM reduivy__Study_Term__c
            WHERE Id = :sce.reduivy__Academic_Term__c
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }
        
        //to enable cohort enrollment
        stm.reduivy__Enable_Cohort_Enrollment__c = true;
        REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Term__c>{stm});

        System.runAs(studentUser){
            
            Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
            for(reduivy__Individual_Session_Enrollment__c isn : [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseIds
                AND reduivy__Individual_Enrollment__c IN :ienIds
                AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
            ]){
                sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
            }
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                    Map<String, Object> sceData = (Map<String, Object>) data.get('sce');
                    System.Assert.areEqual(sce.Id, sceData.get('Id'), 'The study cohort enrollment Id should match.');
                }
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.initStudySession() to check class standing match in study cohort enrollment record
     */
    @IsTest
    static void testMatchClassStandingCohortAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        //get current term start date
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Academic_Term__r.reduivy__Start_Date__c = :currentYearTerm1StartDate
            AND reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c = false
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Class_Year__c = :String.valueOf(currentYearTerm1StartDate.year())
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND Id = :ipw.reduivy__Individual_Program_Enrollment__c
            LIMIT 1
        ];

        List<reduivy__Study_Cohort_Enrollment__c> sceList = [SELECT Id,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c,
            reduivy__Cohort_ID__c,
            reduivy__Pre_enrollment_Open_Date__c,
            reduivy__Enrollment_Open_Date__c,
            reduivy__Enrollment_Close_Date__c,
            reduivy__Study_Offering_Status__c,
            reduivy__Unit_Enrollment_Setting__c,
            reduivy__Academic_Term__c
            FROM reduivy__Study_Cohort_Enrollment__c
            WHERE reduivy__Academic_Term__c = :ipw.reduivy__Academic_Term__c
            LIMIT 1
        ];

        for(reduivy__Study_Cohort_Enrollment__c sce : sceList){
            sce.reduivy__Class_Year__c = null;
        }
        REDU_SystemMode_UTIL.doUpdate(sceList);

        //get sce to check
        reduivy__Study_Cohort_Enrollment__c sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);

        reduivy__Study_Term__c stm = [
            SELECT Id, reduivy__Enable_Cohort_Enrollment__c
            FROM reduivy__Study_Term__c
            WHERE Id = :sce.reduivy__Academic_Term__c
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseIds
            AND reduivy__Individual_Enrollment__c IN :ienIds
            AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
        ]){
            sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
        }

        

        System.runAs(ADMIN_USER){

            //to enable cohort enrollment
            stm.reduivy__Enable_Cohort_Enrollment__c = true;
            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Term__c>{stm});
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                    Map<String, Object> sceData = (Map<String, Object>) data.get('sce');
                    System.Assert.areEqual(sce.Id, sceData.get('Id'), 'The study cohort enrollment Id should match.');
                }
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.initStudySession() to check class standing match in study cohort enrollment record
     */
    @IsTest
    static void testMatchClassStandingCohortAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        //get current term start date
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Academic_Term__r.reduivy__Start_Date__c = :currentYearTerm1StartDate
            AND reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c = false
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Class_Year__c = :String.valueOf(currentYearTerm1StartDate.year())
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND Id = :ipw.reduivy__Individual_Program_Enrollment__c
            LIMIT 1
        ];

        List<reduivy__Study_Cohort_Enrollment__c> sceList = [SELECT Id,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c,
            reduivy__Cohort_ID__c,
            reduivy__Pre_enrollment_Open_Date__c,
            reduivy__Enrollment_Open_Date__c,
            reduivy__Enrollment_Close_Date__c,
            reduivy__Study_Offering_Status__c,
            reduivy__Unit_Enrollment_Setting__c,
            reduivy__Academic_Term__c
            FROM reduivy__Study_Cohort_Enrollment__c
            WHERE reduivy__Academic_Term__c = :ipw.reduivy__Academic_Term__c
            LIMIT 1
        ];

        for(reduivy__Study_Cohort_Enrollment__c sce : sceList){
            sce.reduivy__Class_Year__c = null;
        }
        REDU_SystemMode_UTIL.doUpdate(sceList);

        //get sce to check
        reduivy__Study_Cohort_Enrollment__c sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);

        reduivy__Study_Term__c stm = [
            SELECT Id, reduivy__Enable_Cohort_Enrollment__c
            FROM reduivy__Study_Term__c
            WHERE Id = :sce.reduivy__Academic_Term__c
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseIds
            AND reduivy__Individual_Enrollment__c IN :ienIds
            AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
        ]){
            sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
        }

        //to enable cohort enrollment
        stm.reduivy__Enable_Cohort_Enrollment__c = true;
        REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Term__c>{stm});

        System.runAs(FACULTY_USER){
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                    Map<String, Object> sceData = (Map<String, Object>) data.get('sce');
                    System.Assert.areEqual(sce.Id, sceData.get('Id'), 'The study cohort enrollment Id should match.');
                }
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.initStudySession() to check class standing match in study cohort enrollment record
     */
    @IsTest
    static void testMatchClassStandingCohortAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        //get current term start date
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Academic_Term__r.reduivy__Start_Date__c = :currentYearTerm1StartDate
            AND reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c = false
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Class_Year__c = :String.valueOf(currentYearTerm1StartDate.year())
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c =: studentUser.ContactId
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND Id = :ipw.reduivy__Individual_Program_Enrollment__c
            LIMIT 1
        ];

        List<reduivy__Study_Cohort_Enrollment__c> sceList = [SELECT Id,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c,
            reduivy__Cohort_ID__c,
            reduivy__Pre_enrollment_Open_Date__c,
            reduivy__Enrollment_Open_Date__c,
            reduivy__Enrollment_Close_Date__c,
            reduivy__Study_Offering_Status__c,
            reduivy__Unit_Enrollment_Setting__c,
            reduivy__Academic_Term__c
            FROM reduivy__Study_Cohort_Enrollment__c
            WHERE reduivy__Academic_Term__c = :ipw.reduivy__Academic_Term__c
            LIMIT 1
        ];

        for(reduivy__Study_Cohort_Enrollment__c sce : sceList){
            sce.reduivy__Class_Year__c = null;
        }
        REDU_SystemMode_UTIL.doUpdate(sceList);

        //get sce to check
        reduivy__Study_Cohort_Enrollment__c sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);

        reduivy__Study_Term__c stm = [
            SELECT Id, reduivy__Enable_Cohort_Enrollment__c
            FROM reduivy__Study_Term__c
            WHERE Id = :sce.reduivy__Academic_Term__c
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }
        
        //to enable cohort enrollment
        stm.reduivy__Enable_Cohort_Enrollment__c = true;
        REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Term__c>{stm});
        
        System.runAs(studentUser){
            
            Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
            for(reduivy__Individual_Session_Enrollment__c isn : [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseIds
                AND reduivy__Individual_Enrollment__c IN :ienIds
                AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
            ]){
                sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
            }
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                    Map<String, Object> sceData = (Map<String, Object>) data.get('sce');
                    System.Assert.areEqual(sce.Id, sceData.get('Id'), 'The study cohort enrollment Id should match.');
                }
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.initStudySession() to check class year match in study cohort enrollment record
     */
    @IsTest
    static void testMatchClassYearCohortAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        //get current term start date
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Academic_Term__r.reduivy__Start_Date__c = :currentYearTerm1StartDate
            AND reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c = false
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Class_Year__c = :String.valueOf(currentYearTerm1StartDate.year())
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND Id = :ipw.reduivy__Individual_Program_Enrollment__c
            LIMIT 1
        ];

        List<reduivy__Study_Cohort_Enrollment__c> sceList = [SELECT Id,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c,
            reduivy__Cohort_ID__c,
            reduivy__Pre_enrollment_Open_Date__c,
            reduivy__Enrollment_Open_Date__c,
            reduivy__Enrollment_Close_Date__c,
            reduivy__Study_Offering_Status__c,
            reduivy__Unit_Enrollment_Setting__c,
            reduivy__Academic_Term__c
            FROM reduivy__Study_Cohort_Enrollment__c
            WHERE reduivy__Academic_Term__c = :ipw.reduivy__Academic_Term__c
            LIMIT 1
        ];

        for(reduivy__Study_Cohort_Enrollment__c sce : sceList){
            sce.reduivy__Class_Standing__c = null;
        }
        REDU_SystemMode_UTIL.doUpdate(sceList);

        //get sce to check
        reduivy__Study_Cohort_Enrollment__c sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);

        reduivy__Study_Term__c stm = [
            SELECT Id, reduivy__Enable_Cohort_Enrollment__c
            FROM reduivy__Study_Term__c
            WHERE Id = :sce.reduivy__Academic_Term__c
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseIds
            AND reduivy__Individual_Enrollment__c IN :ienIds
            AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
        ]){
            sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
        }

        

        System.runAs(ADMIN_USER){

            //to enable cohort enrollment
            stm.reduivy__Enable_Cohort_Enrollment__c = true;
            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Term__c>{stm});
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                    Map<String, Object> sceData = (Map<String, Object>) data.get('sce');
                    System.Assert.areEqual(sce.Id, sceData.get('Id'), 'The study cohort enrollment Id should match.');
                }
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.initStudySession() to check class year match in study cohort enrollment record
     */
    @IsTest
    static void testMatchClassYearCohortAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        //get current term start date
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Academic_Term__r.reduivy__Start_Date__c = :currentYearTerm1StartDate
            AND reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c = false
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Class_Year__c = :String.valueOf(currentYearTerm1StartDate.year())
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND Id = :ipw.reduivy__Individual_Program_Enrollment__c
            LIMIT 1
        ];

        List<reduivy__Study_Cohort_Enrollment__c> sceList = [SELECT Id,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c,
            reduivy__Cohort_ID__c,
            reduivy__Pre_enrollment_Open_Date__c,
            reduivy__Enrollment_Open_Date__c,
            reduivy__Enrollment_Close_Date__c,
            reduivy__Study_Offering_Status__c,
            reduivy__Unit_Enrollment_Setting__c,
            reduivy__Academic_Term__c
            FROM reduivy__Study_Cohort_Enrollment__c
            WHERE reduivy__Academic_Term__c = :ipw.reduivy__Academic_Term__c
            LIMIT 1
        ];

        for(reduivy__Study_Cohort_Enrollment__c sce : sceList){
            sce.reduivy__Class_Standing__c = null;
        }
        REDU_SystemMode_UTIL.doUpdate(sceList);

        //get sce to check
        reduivy__Study_Cohort_Enrollment__c sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);

        reduivy__Study_Term__c stm = [
            SELECT Id, reduivy__Enable_Cohort_Enrollment__c
            FROM reduivy__Study_Term__c
            WHERE Id = :sce.reduivy__Academic_Term__c
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseIds
            AND reduivy__Individual_Enrollment__c IN :ienIds
            AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
        ]){
            sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
        }

        //to enable cohort enrollment
        stm.reduivy__Enable_Cohort_Enrollment__c = true;
        REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Term__c>{stm});

        System.runAs(FACULTY_USER){
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                    Map<String, Object> sceData = (Map<String, Object>) data.get('sce');
                    System.Assert.areEqual(sce.Id, sceData.get('Id'), 'The study cohort enrollment Id should match.');
                }
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.initStudySession() to check class year match in study cohort enrollment record
     */
    @IsTest
    static void testMatchClassYearCohortAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        //get current term start date
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Academic_Term__r.reduivy__Start_Date__c = :currentYearTerm1StartDate
            AND reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c = false
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Class_Year__c = :String.valueOf(currentYearTerm1StartDate.year())
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c =: studentUser.ContactId
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND Id = :ipw.reduivy__Individual_Program_Enrollment__c
            LIMIT 1
        ];

        List<reduivy__Study_Cohort_Enrollment__c> sceList = [SELECT Id,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c,
            reduivy__Cohort_ID__c,
            reduivy__Pre_enrollment_Open_Date__c,
            reduivy__Enrollment_Open_Date__c,
            reduivy__Enrollment_Close_Date__c,
            reduivy__Study_Offering_Status__c,
            reduivy__Unit_Enrollment_Setting__c,
            reduivy__Academic_Term__c
            FROM reduivy__Study_Cohort_Enrollment__c
            WHERE reduivy__Academic_Term__c = :ipw.reduivy__Academic_Term__c
            LIMIT 1
        ];

        for(reduivy__Study_Cohort_Enrollment__c sce : sceList){
            sce.reduivy__Class_Standing__c = null;
        }
        REDU_SystemMode_UTIL.doUpdate(sceList);

        //get sce to check
        reduivy__Study_Cohort_Enrollment__c sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);

        reduivy__Study_Term__c stm = [
            SELECT Id, reduivy__Enable_Cohort_Enrollment__c
            FROM reduivy__Study_Term__c
            WHERE Id = :sce.reduivy__Academic_Term__c
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //to enable cohort enrollment
        stm.reduivy__Enable_Cohort_Enrollment__c = true;
        REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Term__c>{stm});
        
        System.runAs(studentUser){
            
            Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
            for(reduivy__Individual_Session_Enrollment__c isn : [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseIds
                AND reduivy__Individual_Enrollment__c IN :ienIds
                AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
            ]){
                sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
            }
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.'); 

                    Map<String, Object> sceData = (Map<String, Object>) data.get('sce');
                    System.Assert.areEqual(sce.Id, sceData.get('Id'), 'The study cohort enrollment Id should match.');
                }
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.initStudySession() to check cohort Id match in study cohort enrollment record
     */
    @IsTest
    static void testMatchCohortIdCohortAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }

        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        //get current term start date
        Date mondayDate = Date.newInstance(2022, 2, 7); //mon
        Date currentYearTerm1StartDate = System.today();
        Integer daysBetween = mondayDate.daysBetween(currentYearTerm1StartDate);
        Integer todayDateDayOfWeek = Math.mod(daysBetween, 7);

        if(todayDateDayOfWeek != 0) {
            currentYearTerm1StartDate = currentYearTerm1StartDate.addDays(-todayDateDayOfWeek);
        }

        reduivy__Individual_Pathway__c ipw = [
            SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c,
            reduivy__Individual_Program_Enrollment__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Academic_Term__r.reduivy__Start_Date__c = :currentYearTerm1StartDate
            AND reduivy__Academic_Term__r.reduivy__Enable_Cohort_Enrollment__c = false
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Class_Year__c = :String.valueOf(currentYearTerm1StartDate.year())
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c ipe = [SELECT Id,
            reduivy__Cohort_ID__c,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND Id = :ipw.reduivy__Individual_Program_Enrollment__c
            LIMIT 1
        ];

        List<reduivy__Study_Cohort_Enrollment__c> sceList = [SELECT Id,
            reduivy__Class_Standing__c,
            reduivy__Class_Year__c,
            reduivy__Cohort_ID__c,
            reduivy__Pre_enrollment_Open_Date__c,
            reduivy__Enrollment_Open_Date__c,
            reduivy__Enrollment_Close_Date__c,
            reduivy__Study_Offering_Status__c,
            reduivy__Unit_Enrollment_Setting__c,
            reduivy__Academic_Term__c
            FROM reduivy__Study_Cohort_Enrollment__c
            WHERE reduivy__Academic_Term__c = :ipw.reduivy__Academic_Term__c
            LIMIT 1
        ];

        for(reduivy__Study_Cohort_Enrollment__c sce : sceList){
            ipe.reduivy__Cohort_ID__c = sce.reduivy__Cohort_ID__c;
            break;
        }
        REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Individual_Program_Enrollment__c>{ipe});

        //get sce to check
        reduivy__Study_Cohort_Enrollment__c sce = SCE_Helper.getStudyCohortEnrollment(ipw.reduivy__Academic_Term__c, ipe.reduivy__Cohort_ID__c, ipe.reduivy__Class_Standing__c, ipe.reduivy__Class_Year__c);

        reduivy__Study_Term__c stm = [
            SELECT Id, reduivy__Enable_Cohort_Enrollment__c
            FROM reduivy__Study_Term__c
            WHERE Id = :sce.reduivy__Academic_Term__c
        ];

        Map<Id, List<reduivy__Study_Session__c>> sofSseMap = new Map<Id, List<reduivy__Study_Session__c>>();
        Set<Id> sseIds = new Set<Id>();
        for(reduivy__Study_Session__c sse : [SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
        ]){
            if(!sofSseMap.containsKey(sse.reduivy__Study_Offering__c)){
                sofSseMap.put(sse.reduivy__Study_Offering__c, new List<reduivy__Study_Session__c>());
            }
            sofSseMap.get(sse.reduivy__Study_Offering__c).add(sse);
            sseIds.add(sse.Id);
        }


        Map<Id, reduivy__Individual_Enrollment__c> sofIenMap = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c IN :sofSseMap.keySet()
        ]){
            sofIenMap.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        Map<Id, reduivy__Individual_Session_Enrollment__c> sseIsnMap = new Map<Id, reduivy__Individual_Session_Enrollment__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseIds
            AND reduivy__Individual_Enrollment__c IN :ienIds
            AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
        ]){
            sseIsnMap.put(isn.reduivy__Study_Session__c, isn);
        }

        

        System.runAs(ADMIN_USER){

            //to enable cohort enrollment
            stm.reduivy__Enable_Cohort_Enrollment__c = true;
            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Term__c>{stm});
            
            for(Id sofId : sofSseMap.keySet()){

                for(reduivy__Study_Session__c sse : sofSseMap.get(sofId)){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.initStudySession(sse.Id, sofIenMap.get(sofId).Id, ipe.Id, ipw.Id, 'Name');
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
        
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
                    Map<String, Object> sseData = (Map<String, Object>) data.get('sse');
                    System.Assert.areEqual(sse.Id, sseData.get('Id'), 'The study session Id should match.');

                    Map<String, Object> isnData = (Map<String, Object>) data.get('isn');
                    Id isnId = isnData == null ? null : (Id) isnData.get('Id');
                    System.Assert.areEqual(sseIsnMap.get(sse.Id)?.Id, isnId, 'The individual session enrollment Id should match.');

                    Map<String, Object> sceData = (Map<String, Object>) data.get('sce');
                    System.Assert.areEqual(sce.Id, sceData.get('Id'), 'The study cohort enrollment Id should match.');
                }
            }

        }

        Test.stopTest();
        
    }


    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.getStudySessionTime()
     */
    @IsTest
    static void testGetStudySessionTimeAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        Map<Id, List<reduivy__Study_Session_Time__c>> sstBySseId = new Map<Id, List<reduivy__Study_Session_Time__c>>();
        for(reduivy__Study_Session__c sse : [
            SELECT Id, Name, 
            (SELECT Id FROM reduivy__Study_Session_Times__r)
            FROM reduivy__Study_Session__c
        ]){
            if(!sstBySseId.containsKey(sse.Id)){
                sstBySseId.put(sse.Id, new List<reduivy__Study_Session_Time__c>());
            }

            for(reduivy__Study_Session_Time__c sst : sse.reduivy__Study_Session_Times__r){

                sstBySseId.get(sse.Id).add(sst);
            }
        }

        System.runAs(ADMIN_USER){

            
            for(Id sseId : sstBySseId.keySet()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.getStudySessionTime(sseId);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
    
                List<reduivy__Study_Session_Time__c> data = (List<reduivy__Study_Session_Time__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Session_Time__c>.class);
                System.Assert.areEqual(sstBySseId.get(sseId).size(), data.size(), 'The study session time size should match.');

            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.getStudySessionTime()
     */
    @IsTest
    static void testGetStudySessionTimeAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Map<Id, List<reduivy__Study_Session_Time__c>> sstBySseId = new Map<Id, List<reduivy__Study_Session_Time__c>>();
        for(reduivy__Study_Session__c sse : [
            SELECT Id, Name, 
            (SELECT Id FROM reduivy__Study_Session_Times__r)
            FROM reduivy__Study_Session__c
        ]){
            if(!sstBySseId.containsKey(sse.Id)){
                sstBySseId.put(sse.Id, new List<reduivy__Study_Session_Time__c>());
            }

            for(reduivy__Study_Session_Time__c sst : sse.reduivy__Study_Session_Times__r){

                sstBySseId.get(sse.Id).add(sst);
            }
        }

        System.runAs(FACULTY_USER){

            
            for(Id sseId : sstBySseId.keySet()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.getStudySessionTime(sseId);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
    
                List<reduivy__Study_Session_Time__c> data = (List<reduivy__Study_Session_Time__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Session_Time__c>.class);
                System.Assert.areEqual(sstBySseId.get(sseId).size(), data.size(), 'The study session time size should match.');

            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.getStudySessionTime()
     */
    @IsTest
    static void testGetStudySessionTimeAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        Map<Id, List<reduivy__Study_Session_Time__c>> sstBySseId = new Map<Id, List<reduivy__Study_Session_Time__c>>();
        for(reduivy__Study_Session__c sse : [
            SELECT Id, Name, 
            (SELECT Id FROM reduivy__Study_Session_Times__r)
            FROM reduivy__Study_Session__c
        ]){
            if(!sstBySseId.containsKey(sse.Id)){
                sstBySseId.put(sse.Id, new List<reduivy__Study_Session_Time__c>());
            }

            for(reduivy__Study_Session_Time__c sst : sse.reduivy__Study_Session_Times__r){

                sstBySseId.get(sse.Id).add(sst);
            }
        }

        System.runAs(studentUser){

            
            for(Id sseId : sstBySseId.keySet()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.getStudySessionTime(sseId);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_TEST');
    
                List<reduivy__Study_Session_Time__c> data = (List<reduivy__Study_Session_Time__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Session_Time__c>.class);
                System.Assert.areEqual(sstBySseId.get(sseId).size(), data.size(), 'The study session time size should match.');

            }

        }

        Test.stopTest();
        
    }



    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn pre-enrollment
     */
    @IsTest
    static void testIsnEnrollmentRequestedAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_ENROLLREQUESTED;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        
        System.runAs(ADMIN_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getEnrollmentRequestedStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Enrollment Requested.');
                }
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn pre-enrollment
     */
    @IsTest
    static void testIsnEnrollmentRequestedAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_ENROLLREQUESTED;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        
        System.runAs(FACULTY_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
                AND reduivy__Enrollment_Status__c IN :currentIsnValidStatuses
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getEnrollmentRequestedStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Enrollment Requested.');
                }
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn pre-enrollment
     */
    @IsTest
    static void testIsnEnrollmentRequestedAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_ENROLLREQUESTED;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        
        System.runAs(studentUser){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getEnrollmentRequestedStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Enrollment Requested.');
                }
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn withdraw pre-enrollment
     */
    @IsTest
    static void testIsnWithdrawEnrollmentRequestedAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        System.runAs(ADMIN_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getOpenStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Not Started.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn withdraw pre-enrollment
     */
    @IsTest
    static void testIsnWithdrawEnrollmentRequestedAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        System.runAs(FACULTY_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getOpenStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Not Started.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn withdraw pre-enrollment
     */
    @IsTest
    static void testIsnWithdrawEnrollmentRequestedAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //update isn to pre-enroll
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 

        //update all isn to request enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
        }
        REDU_SystemMode_UTIL.doUpdate(isnToUpdate);


        System.runAs(studentUser){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getOpenStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Not Started.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn enrollment
     */
    @IsTest
    static void testIsnEnrollmentAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_ENROLL;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //update isn to pre-enroll
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 

        //update all isn to request enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
        }
        REDU_SystemMode_UTIL.doUpdate(isnToUpdate);


        System.runAs(ADMIN_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getInProgressStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Enrolled.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn enrollment
     */
    @IsTest
    static void testIsnEnrollmentAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_ENROLL;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //update isn to pre-enroll
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 

        //update all isn to request enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
        }
        REDU_SystemMode_UTIL.doUpdate(isnToUpdate);


        System.runAs(FACULTY_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getInProgressStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Enrolled.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn enrollment
     */
    @IsTest
    static void testIsnEnrollmentAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_ENROLL;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //update isn to pre-enroll
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 

        //update all isn to request enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
        }
        REDU_SystemMode_UTIL.doUpdate(isnToUpdate);


        System.runAs(studentUser){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getInProgressStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Enrolled.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn unenrollment without attendance record
     */
    @IsTest
    static void testIsnUnenrollWithoutAttendanceAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_UNENROLL;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }
        System.Assert.areEqual(false, ienIds.isEmpty(), 'The individual enrollment id list should not be empty.');


        
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c,
            (SELECT Id FROM reduivy__Study_Event_Relations__r)
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 
        System.Assert.areEqual(false, isnToUpdate.isEmpty(), 'The individual session enrollment list should not be empty.');

        //clear attendance for each isn
        List<reduivy__Study_Event_Relation__c> sevToDelete = new List<reduivy__Study_Event_Relation__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){

            if(isn.reduivy__Study_Event_Relations__r.size() > 0){

                for(reduivy__Study_Event_Relation__c sev : isn.reduivy__Study_Event_Relations__r){
                    sevToDelete.add(sev);
                }
            }
        }

        if(!sevToDelete.isEmpty()){
            REDU_SystemMode_UTIL.doDelete(sevToDelete);
        }

        System.runAs(ADMIN_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(true, isnList.isEmpty(), 'The individual session enrollment list should be empty after unenroll study session.');
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn unenrollment without attendance record
     */
    @IsTest
    static void testIsnUnenrollWithoutAttendanceAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_UNENROLL;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }
        System.Assert.areEqual(false, ienIds.isEmpty(), 'The individual enrollment id list should not be empty.');


        
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c,
            (SELECT Id FROM reduivy__Study_Event_Relations__r)
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 
        System.Assert.areEqual(false, isnToUpdate.isEmpty(), 'The individual session enrollment list should not be empty.');

        //clear attendance for each isn
        List<reduivy__Study_Event_Relation__c> sevToDelete = new List<reduivy__Study_Event_Relation__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){

            if(isn.reduivy__Study_Event_Relations__r.size() > 0){

                for(reduivy__Study_Event_Relation__c sev : isn.reduivy__Study_Event_Relations__r){
                    sevToDelete.add(sev);
                }
            }
        }

        if(!sevToDelete.isEmpty()){
            REDU_SystemMode_UTIL.doDelete(sevToDelete);
        }

        System.runAs(FACULTY_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(true, isnList.isEmpty(), 'The individual session enrollment list should be empty after unenroll study session.');
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn unenrollment without attendance record
     */
    @IsTest
    static void testIsnUnenrollWithoutAttendanceAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_UNENROLL;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }
        System.Assert.areEqual(false, ienIds.isEmpty(), 'The individual enrollment id list should not be empty.');


        
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c,
            (SELECT Id FROM reduivy__Study_Event_Relations__r)
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 
        System.Assert.areEqual(false, isnToUpdate.isEmpty(), 'The individual session enrollment list should not be empty.');

        //clear attendance for each isn
        List<reduivy__Study_Event_Relation__c> sevToDelete = new List<reduivy__Study_Event_Relation__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){

            if(isn.reduivy__Study_Event_Relations__r.size() > 0){

                for(reduivy__Study_Event_Relation__c sev : isn.reduivy__Study_Event_Relations__r){
                    sevToDelete.add(sev);
                }
            }
        }

        if(!sevToDelete.isEmpty()){
            REDU_SystemMode_UTIL.doDelete(sevToDelete);
        }

        System.runAs(studentUser){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(true, isnList.isEmpty(), 'The individual session enrollment list should be empty after unenroll study session.');
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn unenrollment with attendance record
     */
    @IsTest
    static void testIsnUnenrollWithAttendanceAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_UNENROLL;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }
        System.Assert.areEqual(false, ienIds.isEmpty(), 'The individual enrollment id list should not be empty.');


        
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c, reduivy__Contact_Id__c,
            (SELECT Id FROM reduivy__Study_Event_Relations__r)
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 
        System.Assert.areEqual(false, isnToUpdate.isEmpty(), 'The individual session enrollment list should not be empty.');

        //clear attendance for each isn
        List<reduivy__Study_Event_Relation__c> sevToInsert = new List<reduivy__Study_Event_Relation__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){

            if(isn.reduivy__Study_Event_Relations__r.size() <= 0){

                //create sev
                reduivy__Study_Event_Relation__c newSev = REDU_TestData_UTIL.newStudentStudyEventRelation('', isn.reduivy__Contact_Id__c, null, isn.Id, null, null, null);
                sevToInsert.add(newSev);

            }
        }

        if(!sevToInsert.isEmpty()){
            REDU_SystemMode_UTIL.doInsert(sevToInsert);
        }

        System.runAs(ADMIN_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getWithdrawnStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Withdrawn.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn unenrollment with attendance record
     */
    @IsTest
    static void testIsnUnenrollWithAttendanceAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_UNENROLL;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }
        System.Assert.areEqual(false, ienIds.isEmpty(), 'The individual enrollment id list should not be empty.');


        
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c, reduivy__Contact_Id__c,
            (SELECT Id FROM reduivy__Study_Event_Relations__r)
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 
        System.Assert.areEqual(false, isnToUpdate.isEmpty(), 'The individual session enrollment list should not be empty.');

        //clear attendance for each isn
        List<reduivy__Study_Event_Relation__c> sevToInsert = new List<reduivy__Study_Event_Relation__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){

            if(isn.reduivy__Study_Event_Relations__r.size() <= 0){

                //create sev
                reduivy__Study_Event_Relation__c newSev = REDU_TestData_UTIL.newStudentStudyEventRelation('', isn.reduivy__Contact_Id__c, null, isn.Id, null, null, null);
                sevToInsert.add(newSev);

            }
        }

        if(!sevToInsert.isEmpty()){
            REDU_SystemMode_UTIL.doInsert(sevToInsert);
        }

        System.runAs(FACULTY_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getWithdrawnStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Withdrawn.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn unenrollment with attendance record
     */
    @IsTest
    static void testIsnUnenrollWithAttendanceAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_UNENROLL;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }
        System.Assert.areEqual(false, ienIds.isEmpty(), 'The individual enrollment id list should not be empty.');


        
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c, reduivy__Contact_Id__c,
            (SELECT Id FROM reduivy__Study_Event_Relations__r)
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 
        System.Assert.areEqual(false, isnToUpdate.isEmpty(), 'The individual session enrollment list should not be empty.');

        //clear attendance for each isn
        List<reduivy__Study_Event_Relation__c> sevToInsert = new List<reduivy__Study_Event_Relation__c>();
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){

            if(isn.reduivy__Study_Event_Relations__r.size() <= 0){

                //create sev
                reduivy__Study_Event_Relation__c newSev = REDU_TestData_UTIL.newStudentStudyEventRelation('', isn.reduivy__Contact_Id__c, null, isn.Id, null, null, null);
                sevToInsert.add(newSev);

            }
        }

        if(!sevToInsert.isEmpty()){
            REDU_SystemMode_UTIL.doInsert(sevToInsert);
        }

        System.runAs(studentUser){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getWithdrawnStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Withdrawn.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn join waitlist
     */
    @IsTest
    static void testIsnWaitlistedAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_JOINWAITLIST;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //update isn to pre-enroll
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 

        //update all isn to request enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
        }
        REDU_SystemMode_UTIL.doUpdate(isnToUpdate);


        System.runAs(ADMIN_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getWaitlistedStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Waitlisted.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn join waitlist
     */
    @IsTest
    static void testIsnWaitlistedAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_JOINWAITLIST;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //update isn to pre-enroll
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 

        //update all isn to request enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
        }
        REDU_SystemMode_UTIL.doUpdate(isnToUpdate);


        System.runAs(FACULTY_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getWaitlistedStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Waitlisted.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn join waitlist
     */
    @IsTest
    static void testIsnWaitlistedAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_JOINWAITLIST;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //update isn to pre-enroll
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 

        //update all isn to request enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
        }
        REDU_SystemMode_UTIL.doUpdate(isnToUpdate);


        System.runAs(studentUser){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getWaitlistedStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Waitlisted.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn withdrawn from waitlist
     */
    @IsTest
    static void testIsnWithdrawnWaitlistedAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_WITHDRAWWAITLIST;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //update isn to pre-enroll
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 

        //update all isn to request enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
        }
        REDU_SystemMode_UTIL.doUpdate(isnToUpdate);


        System.runAs(ADMIN_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getOpenStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Not Started.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn withdrawn from waitlist
     */
    @IsTest
    static void testIsnWithdrawnWaitlistedAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_WITHDRAWWAITLIST;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //update isn to pre-enroll
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 

        //update all isn to request enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
        }
        REDU_SystemMode_UTIL.doUpdate(isnToUpdate);


        System.runAs(FACULTY_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getOpenStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Not Started.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.upsertEnrollment() for isn withdrawn from waitlist
     */
    @IsTest
    static void testIsnWithdrawnWaitlistedAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        
        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        List<String> currentIsnValidStatuses = new List<String>();
        currentIsnValidStatuses.addAll(ISN_Helper.getInProgressStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getEnrollmentRequestedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getWaitlistedStatuses());
        currentIsnValidStatuses.addAll(ISN_Helper.getOpenStatuses());

        String enrollmentAction = ISN_Helper.ENROLLMENT_ACTION_WITHDRAWWAITLIST;

        Id sofId;
        for(reduivy__Study_Offering__c sof : [
            SELECT Id,
            (SELECT Id FROM reduivy__Study_Sessions__r),
            (SELECT Id FROM reduivy__Individual_Enrollments__r)
            FROM reduivy__Study_Offering__c
        ]){
            if(sof.reduivy__Study_Sessions__r.size() > 0 && sof.reduivy__Individual_Enrollments__r.size() > 0){
                sofId = sof.Id;
                break;
            }
        }
        System.Assert.areEqual(true, sofId != null, 'The study offering id should not be null.');

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Map<Id, reduivy__Individual_Enrollment__c> ienBySofId = new Map<Id, reduivy__Individual_Enrollment__c>();
        Set<Id> ienIds = new Set<Id>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Academic_Term_Id__c, reduivy__Study_Offering__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sofId
        ]){
            ienBySofId.put(ien.reduivy__Study_Offering__c, ien);
            ienIds.add(ien.Id);
        }

        //update isn to pre-enroll
        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = [
            SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c IN :sseMap.keySet()
            AND reduivy__Individual_Enrollment__c IN :ienIds
        ]; 

        //update all isn to request enrollment
        for(reduivy__Individual_Session_Enrollment__c isn : isnToUpdate){
            isn.reduivy__Enrollment_Status__c = ISN_Helper.getEnrollmentRequestedStatuses()[0];
        }
        REDU_SystemMode_UTIL.doUpdate(isnToUpdate);


        System.runAs(studentUser){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.upsertEnrollment(ienBySofId.get(sofId).Id, JSON.serialize(sse), enrollmentAction);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                Set<Id> data = (Set<Id>) JSON.deserialize(response.responseData, Set<Id>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Processed individual session enrollment id set should not be empty.');
            }

            //check result
            List<reduivy__Individual_Session_Enrollment__c> isnList = [
                SELECT Id, reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__c, reduivy__Study_Session__c
                FROM reduivy__Individual_Session_Enrollment__c
                WHERE reduivy__Study_Session__c IN :sseMap.keySet()
                AND reduivy__Individual_Enrollment__c IN :ienIds
            ];
            System.Assert.areEqual(false, isnList.isEmpty(), 'The individual session enrollment list should not be empty.');

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(reduivy__Individual_Session_Enrollment__c isn : isnList){

                    System.Assert.areEqual(true, ISN_Helper.getOpenStatuses().contains(isn.reduivy__Enrollment_Status__c), 'The individual session enrollment status should be Not Started.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.checkEventConflict()
     */
    @IsTest
    static void testCheckEventConflictAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            LIMIT 3
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');

        List<Contact> contactList = [
            SELECT Id 
            FROM Contact
            LIMIT 3
        ];
        System.Assert.areEqual(false, contactList.isEmpty(), 'The contact list should not be empty.');

        Test.startTest();

        //get an event from each study session
        Map<Id, reduivy__Study_Event__c> sevBySseId = new Map<Id, reduivy__Study_Event__c>();
        for(reduivy__Study_Event__c sev : [SELECT Id,
            reduivy__Study_Session_Time__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__c,
            reduivy__Start_Date_Non_TZ__c,
            reduivy__Start_Time_Non_TZ__c,
            reduivy__End_Time_Non_TZ__c,
            reduivy__Start__c,
            reduivy__End__c
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN :sseMap.keySet()
            WITH USER_MODE
        ]){
            if(!sevBySseId.containsKey(sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c)){
                sevBySseId.put(sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c, sev);
            }
        }

        //create a study event for contacts to conflict with study session's event
        List<reduivy__Study_Event__c> sevToInsert = new List<reduivy__Study_Event__c>();
        for(Id sseId : sevBySseId.keySet()){
            reduivy__Study_Event__c existingSev = sevBySseId.get(sseId);

            reduivy__Study_Event__c newSev = REDU_TestData_UTIL.newSessionStudyEvent('', existingSev.reduivy__Study_Session_Time__c, 'sev test', null, 'Confirmed', existingSev.reduivy__Start__c, existingSev.reduivy__End__c);
            sevToInsert.add(newSev);
        }
        System.Assert.areEqual(false, sevToInsert.isEmpty(), 'The study event list to insert should not be empty.');

        REDU_SystemMode_UTIL.doInsert(sevToInsert);


        //get the inserted event
        List<reduivy__Study_Event__c> insertedSev = [
            SELECT Id
            FROM reduivy__Study_Event__c
            WHERE Name = 'sev test'
        ];
        System.Assert.areEqual(false, insertedSev.isEmpty(), 'The inserted study event list should not be empty.');


        //create study event relation for the inserted events
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();
        for(Contact con : contactList){

            for(reduivy__Study_Event__c sev : insertedSev){

                reduivy__Study_Event_Relation__c newSer = REDU_TestData_UTIL.newFacultyStudyEventRelation('', con.Id, sev.Id, null);
                serToInsert.add(newSer);
            }
        }
        System.Assert.areEqual(false, serToInsert.isEmpty(), 'The study event relation list to insert should not be empty.');

        REDU_SystemMode_UTIL.doInsert(serToInsert);



        System.runAs(ADMIN_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(Contact con : contactList){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.checkEventConflict(sse.Id, con.Id);
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');
    
                    List<reduivy__Study_Event__c> data = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
                    System.Assert.areEqual(false, data.isEmpty(), 'Conflicted study event list should not be empty.');
                }

            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.checkEventConflict()
     */
    @IsTest
    static void testCheckEventConflictAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            LIMIT 3
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');

        List<Contact> contactList = [
            SELECT Id 
            FROM Contact
            LIMIT 3
        ];
        System.Assert.areEqual(false, contactList.isEmpty(), 'The contact list should not be empty.');

        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        //get an event from each study session
        Map<Id, reduivy__Study_Event__c> sevBySseId = new Map<Id, reduivy__Study_Event__c>();
        for(reduivy__Study_Event__c sev : [SELECT Id,
            reduivy__Study_Session_Time__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__c,
            reduivy__Start_Date_Non_TZ__c,
            reduivy__Start_Time_Non_TZ__c,
            reduivy__End_Time_Non_TZ__c,
            reduivy__Start__c,
            reduivy__End__c
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN :sseMap.keySet()
            WITH USER_MODE
        ]){
            if(!sevBySseId.containsKey(sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c)){
                sevBySseId.put(sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c, sev);
            }
        }

        //create a study event for contacts to conflict with study session's event
        List<reduivy__Study_Event__c> sevToInsert = new List<reduivy__Study_Event__c>();
        for(Id sseId : sevBySseId.keySet()){
            reduivy__Study_Event__c existingSev = sevBySseId.get(sseId);

            reduivy__Study_Event__c newSev = REDU_TestData_UTIL.newSessionStudyEvent('', existingSev.reduivy__Study_Session_Time__c, 'sev test', null, 'Confirmed', existingSev.reduivy__Start__c, existingSev.reduivy__End__c);
            sevToInsert.add(newSev);
        }
        System.Assert.areEqual(false, sevToInsert.isEmpty(), 'The study event list to insert should not be empty.');

        REDU_SystemMode_UTIL.doInsert(sevToInsert);


        //get the inserted event
        List<reduivy__Study_Event__c> insertedSev = [
            SELECT Id
            FROM reduivy__Study_Event__c
            WHERE Name = 'sev test'
        ];
        System.Assert.areEqual(false, insertedSev.isEmpty(), 'The inserted study event list should not be empty.');


        //create study event relation for the inserted events
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();
        for(Contact con : contactList){

            for(reduivy__Study_Event__c sev : insertedSev){

                reduivy__Study_Event_Relation__c newSer = REDU_TestData_UTIL.newFacultyStudyEventRelation('', con.Id, sev.Id, null);
                serToInsert.add(newSer);
            }
        }
        System.Assert.areEqual(false, serToInsert.isEmpty(), 'The study event relation list to insert should not be empty.');

        REDU_SystemMode_UTIL.doInsert(serToInsert);



        System.runAs(FACULTY_USER){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                for(Contact con : contactList){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.checkEventConflict(sse.Id, con.Id);
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');
    
                    List<reduivy__Study_Event__c> data = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
                    System.Assert.areEqual(false, data.isEmpty(), 'Conflicted study event list should not be empty.');
                }

            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.checkEventConflict()
     */
    @IsTest
    static void testCheckEventConflictAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name, 
            reduivy__Type__c, 
            reduivy__Study_Offering__c,
            reduivy__Pre_enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Open_Date_Calculated__c,
            reduivy__Enrollment_Close_Date_Calculated__c,
            reduivy__Start_Date_Calculated__c,
            reduivy__End_Date_Calculated__c,
            reduivy__Available_Places__c,
            reduivy__Unlimited_Places__c,
            reduivy__Status__c,
            reduivy__Enable_Waitlist__c
            FROM reduivy__Study_Session__c
            LIMIT 3
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');


        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        //get an event from each study session
        Map<Id, reduivy__Study_Event__c> sevBySseId = new Map<Id, reduivy__Study_Event__c>();
        for(reduivy__Study_Event__c sev : [SELECT Id,
            reduivy__Study_Session_Time__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__c,
            reduivy__Start_Date_Non_TZ__c,
            reduivy__Start_Time_Non_TZ__c,
            reduivy__End_Time_Non_TZ__c,
            reduivy__Start__c,
            reduivy__End__c
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN :sseMap.keySet()
            WITH USER_MODE
        ]){
            if(!sevBySseId.containsKey(sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c)){
                sevBySseId.put(sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c, sev);
            }
        }

        //create a study event for contacts to conflict with study session's event
        List<reduivy__Study_Event__c> sevToInsert = new List<reduivy__Study_Event__c>();
        for(Id sseId : sevBySseId.keySet()){
            reduivy__Study_Event__c existingSev = sevBySseId.get(sseId);

            reduivy__Study_Event__c newSev = REDU_TestData_UTIL.newSessionStudyEvent('', existingSev.reduivy__Study_Session_Time__c, 'sev test', null, 'Confirmed', existingSev.reduivy__Start__c, existingSev.reduivy__End__c);
            sevToInsert.add(newSev);
        }
        System.Assert.areEqual(false, sevToInsert.isEmpty(), 'The study event list to insert should not be empty.');

        REDU_SystemMode_UTIL.doInsert(sevToInsert);


        //get the inserted event
        List<reduivy__Study_Event__c> insertedSev = [
            SELECT Id
            FROM reduivy__Study_Event__c
            WHERE Name = 'sev test'
        ];
        System.Assert.areEqual(false, insertedSev.isEmpty(), 'The inserted study event list should not be empty.');


        //create study event relation for the inserted events
        List<reduivy__Study_Event_Relation__c> serToInsert = new List<reduivy__Study_Event_Relation__c>();

        for(reduivy__Study_Event__c sev : insertedSev){

            reduivy__Study_Event_Relation__c newSer = REDU_TestData_UTIL.newFacultyStudyEventRelation('', studentUser.ContactId, sev.Id, null);
            serToInsert.add(newSer);
        }
        System.Assert.areEqual(false, serToInsert.isEmpty(), 'The study event relation list to insert should not be empty.');

        REDU_SystemMode_UTIL.doInsert(serToInsert);



        System.runAs(studentUser){

            for(reduivy__Study_Session__c sse : sseMap.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.checkEventConflict(sse.Id, studentUser.ContactId);
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');

                List<reduivy__Study_Event__c> data = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
                System.Assert.areEqual(false, data.isEmpty(), 'Conflicted study event list should not be empty.');
                

            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySession_LCTRL.checkEventConflict()
     */
    @IsTest
    static void testCheckEventNoConflictAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name
            FROM reduivy__Study_Session__c
            LIMIT 1
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');

        List<Contact> contactList = [
            SELECT Id 
            FROM Contact
            LIMIT 1
        ];
        System.Assert.areEqual(false, contactList.isEmpty(), 'The contact list should not be empty.');

        
        List<String> enrollStatuses = new List<String>();
        enrollStatuses.addAll(ISN_Helper.getInProgressStatuses());
        enrollStatuses.addAll(ISN_Helper.getCompletedStatuses());

        Test.startTest();

        //get an event from each study session
        Set<Id> sseIdNoConflict = new Set<Id>();
        Set<Id> sseIdToSkip = new Set<Id>();
        Map<Id, reduivy__Study_Event__c> sevBySseId = new Map<Id, reduivy__Study_Event__c>();
        for(reduivy__Study_Event__c sev : [SELECT Id,
            reduivy__Study_Session_Time__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Start_Date_Calculated__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__End_Date_Calculated__c,
            reduivy__Start_Date_Non_TZ__c,
            reduivy__Start_Time_Non_TZ__c,
            reduivy__End_Time_Non_TZ__c,
            reduivy__Start__c,
            reduivy__End__c
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN :sseMap.keySet()
        ]){
            Id sseId = sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c;

            Date startDate = sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Start_Date_Calculated__c;
            Date endDate = sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__End_Date_Calculated__c;
            Datetime startDt = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
            Datetime endDt = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 0, 0, 0);

            //get contact's events
            List<reduivy__Study_Event__c> contactSev = CON_Helper.getContactEvents(contactList[0].Id, startDt, endDt, enrollStatuses);

            for(reduivy__Study_Event__c conSev : contactSev){

                if(
                    sseIdToSkip.contains(sseId)
                    || (
                        conSev.reduivy__Start_Time_Non_TZ__c <= sev.reduivy__Start_Time_Non_TZ__c
                        && sev.reduivy__Start_Time_Non_TZ__c < conSev.reduivy__End_Time_Non_TZ__c
                    )
                ){
                    sseIdToSkip.add(sseId);

                    if(sseIdNoConflict.contains(sseId)){
                        sseIdNoConflict.remove(sseId);
                    }
                    continue;
                } 

                sseIdNoConflict.add(sseId);
            }
        }


        System.runAs(ADMIN_USER){

            for(Id sseId : sseIdNoConflict){

                for(Contact con : contactList){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.checkEventConflict(sseId, con.Id);
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');
    
                    List<reduivy__Study_Event__c> data = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
                    System.Assert.areEqual(true, data.isEmpty(), 'Conflicted study event list should be empty.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySession_LCTRL.checkEventConflict()
     */
    @IsTest
    static void testCheckEventNoConflictAsFaculty(){

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name
            FROM reduivy__Study_Session__c
            LIMIT 1
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');

        List<Contact> contactList = [
            SELECT Id 
            FROM Contact
            LIMIT 1
        ];
        System.Assert.areEqual(false, contactList.isEmpty(), 'The contact list should not be empty.');

        
        List<String> enrollStatuses = new List<String>();
        enrollStatuses.addAll(ISN_Helper.getInProgressStatuses());
        enrollStatuses.addAll(ISN_Helper.getCompletedStatuses());

        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        //get an event from each study session
        Set<Id> sseIdNoConflict = new Set<Id>();
        Set<Id> sseIdToSkip = new Set<Id>();
        Map<Id, reduivy__Study_Event__c> sevBySseId = new Map<Id, reduivy__Study_Event__c>();
        for(reduivy__Study_Event__c sev : [SELECT Id,
            reduivy__Study_Session_Time__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Start_Date_Calculated__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__End_Date_Calculated__c,
            reduivy__Start_Date_Non_TZ__c,
            reduivy__Start_Time_Non_TZ__c,
            reduivy__End_Time_Non_TZ__c,
            reduivy__Start__c,
            reduivy__End__c
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN :sseMap.keySet()
        ]){
            Id sseId = sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c;

            Date startDate = sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Start_Date_Calculated__c;
            Date endDate = sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__End_Date_Calculated__c;
            Datetime startDt = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
            Datetime endDt = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 0, 0, 0);

            //get contact's events
            List<reduivy__Study_Event__c> contactSev = CON_Helper.getContactEvents(contactList[0].Id, startDt, endDt, enrollStatuses);

            for(reduivy__Study_Event__c conSev : contactSev){

                if(
                    sseIdToSkip.contains(sseId)
                    || (
                        conSev.reduivy__Start_Time_Non_TZ__c <= sev.reduivy__Start_Time_Non_TZ__c
                        && sev.reduivy__Start_Time_Non_TZ__c < conSev.reduivy__End_Time_Non_TZ__c
                    )
                ){
                    sseIdToSkip.add(sseId);

                    if(sseIdNoConflict.contains(sseId)){
                        sseIdNoConflict.remove(sseId);
                    }
                    continue;
                } 

                sseIdNoConflict.add(sseId);
            }
        }


        System.runAs(FACULTY_USER){

            for(Id sseId : sseIdNoConflict){

                for(Contact con : contactList){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.checkEventConflict(sseId, con.Id);
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');
    
                    List<reduivy__Study_Event__c> data = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
                    System.Assert.areEqual(true, data.isEmpty(), 'Conflicted study event list should be empty.');
                }
            }
        }

        Test.stopTest(); 
        
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySession_LCTRL.checkEventConflict()
     */
    @IsTest
    static void testCheckEventNoConflictAsStudent(){

        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            testFactory.initStudentData(SER_Helper.getApiName(), true);
        }
        

        Map<Id, reduivy__Study_Session__c> sseMap = new Map<Id, reduivy__Study_Session__c>([SELECT Id, 
            Name
            FROM reduivy__Study_Session__c
            LIMIT 1
        ]);
        System.Assert.areEqual(false, sseMap.isEmpty(), 'The study session map should not be empty.');

        List<Contact> contactList = [
            SELECT Id 
            FROM Contact
            LIMIT 1
        ];
        System.Assert.areEqual(false, contactList.isEmpty(), 'The contact list should not be empty.');

        
        List<String> enrollStatuses = new List<String>();
        enrollStatuses.addAll(ISN_Helper.getInProgressStatuses());
        enrollStatuses.addAll(ISN_Helper.getCompletedStatuses());

        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        //get an event from each study session
        Set<Id> sseIdNoConflict = new Set<Id>();
        Set<Id> sseIdToSkip = new Set<Id>();
        Map<Id, reduivy__Study_Event__c> sevBySseId = new Map<Id, reduivy__Study_Event__c>();
        for(reduivy__Study_Event__c sev : [SELECT Id,
            reduivy__Study_Session_Time__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Start_Date_Calculated__c,
            reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__End_Date_Calculated__c,
            reduivy__Start_Date_Non_TZ__c,
            reduivy__Start_Time_Non_TZ__c,
            reduivy__End_Time_Non_TZ__c,
            reduivy__Start__c,
            reduivy__End__c
            FROM reduivy__Study_Event__c
            WHERE reduivy__Study_Session_Time__r.reduivy__Study_Session__c IN :sseMap.keySet()
        ]){
            Id sseId = sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__c;

            Date startDate = sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__Start_Date_Calculated__c;
            Date endDate = sev.reduivy__Study_Session_Time__r.reduivy__Study_Session__r.reduivy__End_Date_Calculated__c;
            Datetime startDt = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
            Datetime endDt = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 0, 0, 0);

            //get contact's events
            List<reduivy__Study_Event__c> contactSev = CON_Helper.getContactEvents(contactList[0].Id, startDt, endDt, enrollStatuses);

            for(reduivy__Study_Event__c conSev : contactSev){

                if(
                    sseIdToSkip.contains(sseId)
                    || (
                        conSev.reduivy__Start_Time_Non_TZ__c <= sev.reduivy__Start_Time_Non_TZ__c
                        && sev.reduivy__Start_Time_Non_TZ__c < conSev.reduivy__End_Time_Non_TZ__c
                    )
                ){
                    sseIdToSkip.add(sseId);

                    if(sseIdNoConflict.contains(sseId)){
                        sseIdNoConflict.remove(sseId);
                    }
                    continue;
                } 

                sseIdNoConflict.add(sseId);
            }
        }


        System.runAs(studentUser){

            for(Id sseId : sseIdNoConflict){

                for(Contact con : contactList){

                    REDU_LightningResponse response = REDU_IpePathwayStudySession_LCTRL.checkEventConflict(sseId, con.Id);
                    System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwayStudySession_LCTRL');
    
                    List<reduivy__Study_Event__c> data = (List<reduivy__Study_Event__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Event__c>.class);
                    System.Assert.areEqual(true, data.isEmpty(), 'Conflicted study event list should be empty.');
                }
            }
        }

        Test.stopTest(); 
        
    }
    
}