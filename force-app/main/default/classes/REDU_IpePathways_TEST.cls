/**
 * @author      WDCi (Jordan)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for REDU_IpePathways_LCTRL
 * @changehistory
 * ISS-001924 31-05-2024 Sueanne - add Major/Minor Enrollment Test
 * ISS-002336 25-03-2024 XiRouh - add getMissedFailedStudyUnits test
 * ISS-002401 22-04-2025 Lean - Added enrollment action status test
 * ISS-002459 14-05-2025 Lean - Added ipe status config test
 */
@isTest
public inherited sharing class REDU_IpePathways_TEST {

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
			testFactory.initOfferingData(SIT_Helper.getApiName());
			testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathways_LCTRL.getIndividualPathways()
     */
    @isTest   
    static void testGetIndividualPathwaysForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        List<reduivy__Individual_Pathway__c> idvPathways = new List<reduivy__Individual_Pathway__c>();
        for (reduivy__Individual_Pathway__c ipw : [SELECT Id, 
            reduivy__Term_Number__c,
            reduivy__Status__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
            ORDER BY reduivy__Term_Number__c ASC NULLS LAST
        ]) {
            idvPathways.add(ipw);
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.getIndividualPathways(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            List<reduivy__Individual_Pathway__c> idvPathwaysResponse = (List<reduivy__Individual_Pathway__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Individual_Pathway__c>.class);
            System.Assert.areEqual(idvPathways.size(), idvPathwaysResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathways_LCTRL.getCampuses()
     */
    @isTest   
    static void testGetCampusesForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, 
            reduivy__Default_Campus__c,
            reduivy__Study_Program__c,
            reduivy__Study_Program__r.reduivy__Educational_Institution__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id =: masterIPE.Id
            LIMIT 1
        ];

        List<Account> campuses = new List<Account>();
        if (!ipeList.isEmpty() && String.isNotBlank(ipeList.get(0).reduivy__Study_Program__r.reduivy__Educational_Institution__c)) {
            
            for (Account campus : [SELECT Id,
                Name
                FROM Account
                WHERE RecordTypeId =: ACC_Helper.getCampusRecordTypeId()
                AND ParentId =: ipeList.get(0).reduivy__Study_Program__r.reduivy__Educational_Institution__c
                ORDER BY Name
            ]) {
                campuses.add(campus);
            }
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.getCampuses(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            List<Account> campusesResponse = (List<Account>) JSON.deserialize(objResponse.responseData, List<Account>.class);
            System.Assert.areEqual(campuses.size(), campusesResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathways_LCTRL.createIndividualPathway()
     */
    @isTest   
    static void testCreateIndividualPathwayForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Integer count = 0;
        reduivy__Individual_Pathway__c lastIpw;

        for (reduivy__Individual_Pathway__c ipw : [SELECT Id,
            reduivy__Description__c,
            reduivy__Enrollment_Method__c,
            reduivy__Max_Credits__c,
            reduivy__Recommended_Credits__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
            ORDER BY reduivy__Term_Number__c ASC NULLS LAST
        ]) {
            count ++;

            lastIpw = ipw;
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.createIndividualPathway(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            reduivy__Individual_Pathway__c newPathway = (reduivy__Individual_Pathway__c) JSON.deserialize(objResponse.responseData, reduivy__Individual_Pathway__c.class);
            System.Assert.areEqual(masterIPE.Id, newPathway.reduivy__Individual_Program_Enrollment__c);
            System.Assert.areEqual(count + 1, newPathway.reduivy__Term_Number__c);

            if (lastIpw != null) {
                System.Assert.areEqual(lastIpw.reduivy__Description__c, newPathway.reduivy__Description__c);
                System.Assert.areEqual(lastIpw.reduivy__Enrollment_Method__c, newPathway.reduivy__Enrollment_Method__c);
                System.Assert.areEqual(lastIpw.reduivy__Max_Credits__c, newPathway.reduivy__Max_Credits__c);
                System.Assert.areEqual(lastIpw.reduivy__Recommended_Credits__c, newPathway.reduivy__Recommended_Credits__c);

                if (String.isNotBlank(lastIpw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c)) {
                    for (reduivy__Study_Pathway_Term__c spt : [SELECT Id,
                        reduivy__Description__c,
                        reduivy__Enrollment_Method__c,
                        reduivy__Max_Credits__c,
                        reduivy__Recommended_Credits__c
                        FROM reduivy__Study_Pathway_Term__c
                        WHERE reduivy__Study_Pathway__c =: lastIpw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c
                        AND reduivy__Term_Number__c =: count
                        LIMIT 1
                    ]) {
                        System.Assert.areEqual(spt.reduivy__Description__c, newPathway.reduivy__Description__c);
                        System.Assert.areEqual(spt.reduivy__Enrollment_Method__c, newPathway.reduivy__Enrollment_Method__c);
                        System.Assert.areEqual(spt.reduivy__Max_Credits__c, newPathway.reduivy__Max_Credits__c);
                        System.Assert.areEqual(spt.reduivy__Recommended_Credits__c, newPathway.reduivy__Recommended_Credits__c);
                    }
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student user for REDU_IpePathways_LCTRL.getIndividualPathways()
     */
    @isTest   
    static void testGetIndividualPathwaysForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        List<reduivy__Individual_Pathway__c> idvPathways = new List<reduivy__Individual_Pathway__c>();
        for (reduivy__Individual_Pathway__c ipw : [SELECT Id, 
            reduivy__Term_Number__c,
            reduivy__Status__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
            ORDER BY reduivy__Term_Number__c ASC NULLS LAST
        ]) {
            idvPathways.add(ipw);
        }

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.getIndividualPathways(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTerm_TEST');

            List<reduivy__Individual_Pathway__c> idvPathwaysResponse = (List<reduivy__Individual_Pathway__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Individual_Pathway__c>.class);
            System.Assert.areEqual(idvPathways.size(), idvPathwaysResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as student user for REDU_IpePathways_LCTRL.getCampuses()
     */
    @isTest   
    static void testGetCampusesForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, 
            reduivy__Default_Campus__c,
            reduivy__Study_Program__c,
            reduivy__Study_Program__r.reduivy__Educational_Institution__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id =: masterIPE.Id
            LIMIT 1
        ];

        List<Account> campuses = new List<Account>();
        if (!ipeList.isEmpty() && String.isNotBlank(ipeList.get(0).reduivy__Study_Program__r.reduivy__Educational_Institution__c)) {
            
            for (Account campus : [SELECT Id,
                Name
                FROM Account
                WHERE RecordTypeId =: ACC_Helper.getCampusRecordTypeId()
                AND ParentId =: ipeList.get(0).reduivy__Study_Program__r.reduivy__Educational_Institution__c
                ORDER BY Name
            ]) {
                campuses.add(campus);
            }
        }

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.getCampuses(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTerm_TEST');

            List<Account> campusesResponse = (List<Account>) JSON.deserialize(objResponse.responseData, List<Account>.class);
            System.Assert.areEqual(campuses.size(), campusesResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as student user for REDU_IpePathways_LCTRL.createIndividualPathway()
     */
    @isTest   
    static void testCreateIndividualPathwayForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Integer count = 0;
        reduivy__Individual_Pathway__c lastIpw;

        for (reduivy__Individual_Pathway__c ipw : [SELECT Id,
            reduivy__Description__c,
            reduivy__Enrollment_Method__c,
            reduivy__Max_Credits__c,
            reduivy__Recommended_Credits__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
            ORDER BY reduivy__Term_Number__c ASC NULLS LAST
        ]) {
            count ++;

            lastIpw = ipw;
        }

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.createIndividualPathway(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTerm_TEST');

            reduivy__Individual_Pathway__c newPathway = (reduivy__Individual_Pathway__c) JSON.deserialize(objResponse.responseData, reduivy__Individual_Pathway__c.class);
            System.Assert.areEqual(masterIPE.Id, newPathway.reduivy__Individual_Program_Enrollment__c);
            System.Assert.areEqual(count + 1, newPathway.reduivy__Term_Number__c);

            if (lastIpw != null) {
                System.Assert.areEqual(lastIpw.reduivy__Description__c, newPathway.reduivy__Description__c);
                System.Assert.areEqual(lastIpw.reduivy__Enrollment_Method__c, newPathway.reduivy__Enrollment_Method__c);
                System.Assert.areEqual(lastIpw.reduivy__Max_Credits__c, newPathway.reduivy__Max_Credits__c);
                System.Assert.areEqual(lastIpw.reduivy__Recommended_Credits__c, newPathway.reduivy__Recommended_Credits__c);

                if (String.isNotBlank(lastIpw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c)) {
                    for (reduivy__Study_Pathway_Term__c spt : [SELECT Id,
                        reduivy__Description__c,
                        reduivy__Enrollment_Method__c,
                        reduivy__Max_Credits__c,
                        reduivy__Recommended_Credits__c
                        FROM reduivy__Study_Pathway_Term__c
                        WHERE reduivy__Study_Pathway__c =: lastIpw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c
                        AND reduivy__Term_Number__c =: count
                        LIMIT 1
                    ]) {
                        System.Assert.areEqual(spt.reduivy__Description__c, newPathway.reduivy__Description__c);
                        System.Assert.areEqual(spt.reduivy__Enrollment_Method__c, newPathway.reduivy__Enrollment_Method__c);
                        System.Assert.areEqual(spt.reduivy__Max_Credits__c, newPathway.reduivy__Max_Credits__c);
                        System.Assert.areEqual(spt.reduivy__Recommended_Credits__c, newPathway.reduivy__Recommended_Credits__c);
                    }
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpePathways_LCTRL.getIndividualPathways()
     */
    @isTest   
    static void testGetIndividualPathwaysForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        List<reduivy__Individual_Pathway__c> idvPathways = new List<reduivy__Individual_Pathway__c>();
        for (reduivy__Individual_Pathway__c ipw : [SELECT Id, 
            reduivy__Term_Number__c,
            reduivy__Status__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
            ORDER BY reduivy__Term_Number__c ASC NULLS LAST
        ]) {
            idvPathways.add(ipw);
        }

        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.getIndividualPathways(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTerm_TEST');

            List<reduivy__Individual_Pathway__c> idvPathwaysResponse = (List<reduivy__Individual_Pathway__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Individual_Pathway__c>.class);
            System.Assert.areEqual(idvPathways.size(), idvPathwaysResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpePathways_LCTRL.getCampuses()
     */
    @isTest   
    static void testGetCampusesForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        List<reduivy__Individual_Program_Enrollment__c> ipeList = [SELECT Id, 
            reduivy__Default_Campus__c,
            reduivy__Study_Program__c,
            reduivy__Study_Program__r.reduivy__Educational_Institution__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id =: masterIPE.Id
            LIMIT 1
        ];

        List<Account> campuses = new List<Account>();
        if (!ipeList.isEmpty() && String.isNotBlank(ipeList.get(0).reduivy__Study_Program__r.reduivy__Educational_Institution__c)) {
            
            for (Account campus : [SELECT Id,
                Name
                FROM Account
                WHERE RecordTypeId =: ACC_Helper.getCampusRecordTypeId()
                AND ParentId =: ipeList.get(0).reduivy__Study_Program__r.reduivy__Educational_Institution__c
                ORDER BY Name
            ]) {
                campuses.add(campus);
            }
        }

        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.getCampuses(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTerm_TEST');

            List<Account> campusesResponse = (List<Account>) JSON.deserialize(objResponse.responseData, List<Account>.class);
            System.Assert.areEqual(campuses.size(), campusesResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpePathways_LCTRL.createIndividualPathway()
     */
    @isTest   
    static void testCreateIndividualPathwayForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Integer count = 0;
        reduivy__Individual_Pathway__c lastIpw;

        for (reduivy__Individual_Pathway__c ipw : [SELECT Id,
            reduivy__Description__c,
            reduivy__Enrollment_Method__c,
            reduivy__Max_Credits__c,
            reduivy__Recommended_Credits__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
            ORDER BY reduivy__Term_Number__c ASC NULLS LAST
        ]) {
            count ++;

            lastIpw = ipw;
        }

        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.createIndividualPathway(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTerm_TEST');

            reduivy__Individual_Pathway__c newPathway = (reduivy__Individual_Pathway__c) JSON.deserialize(objResponse.responseData, reduivy__Individual_Pathway__c.class);
            System.Assert.areEqual(masterIPE.Id, newPathway.reduivy__Individual_Program_Enrollment__c);
            System.Assert.areEqual(count + 1, newPathway.reduivy__Term_Number__c);

            if (lastIpw != null) {
                System.Assert.areEqual(lastIpw.reduivy__Description__c, newPathway.reduivy__Description__c);
                System.Assert.areEqual(lastIpw.reduivy__Enrollment_Method__c, newPathway.reduivy__Enrollment_Method__c);
                System.Assert.areEqual(lastIpw.reduivy__Max_Credits__c, newPathway.reduivy__Max_Credits__c);
                System.Assert.areEqual(lastIpw.reduivy__Recommended_Credits__c, newPathway.reduivy__Recommended_Credits__c);

                if (String.isNotBlank(lastIpw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c)) {
                    for (reduivy__Study_Pathway_Term__c spt : [SELECT Id,
                        reduivy__Description__c,
                        reduivy__Enrollment_Method__c,
                        reduivy__Max_Credits__c,
                        reduivy__Recommended_Credits__c
                        FROM reduivy__Study_Pathway_Term__c
                        WHERE reduivy__Study_Pathway__c =: lastIpw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Pathway__c
                        AND reduivy__Term_Number__c =: count
                        LIMIT 1
                    ]) {
                        System.Assert.areEqual(spt.reduivy__Description__c, newPathway.reduivy__Description__c);
                        System.Assert.areEqual(spt.reduivy__Enrollment_Method__c, newPathway.reduivy__Enrollment_Method__c);
                        System.Assert.areEqual(spt.reduivy__Max_Credits__c, newPathway.reduivy__Max_Credits__c);
                        System.Assert.areEqual(spt.reduivy__Recommended_Credits__c, newPathway.reduivy__Recommended_Credits__c);
                    }
                }
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathways_LCTRL.getSpoStudentEnrollment()
     */
    @isTest   
    static void testGetSpoStudentEnrollmentForAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        Map<Id, reduivy__Individual_Program_Enrollment__c> childIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            AND reduivy__Master_Enrollment__c = :masterIpe.Id
            AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
            AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
            WITH USER_MODE
        ]){
            childIpeMap.put(ipe.reduivy__Study_Plan__c, ipe);
        }

        Map<Id, reduivy__Study_Plan_Option__c> spoMap = new Map<Id, reduivy__Study_Plan_Option__c>();
        for(reduivy__Study_Plan_Option__c spo : [
            SELECT Id, reduivy__Child_Study_Plan__c, reduivy__Status__c 
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :masterIpe.reduivy__Study_Plan__c
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]){
            spoMap.put(spo.reduivy__Child_Study_Plan__c, spo);
        }

        System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.getSpoStudentEnrollment(masterIpe.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            List<REDU_IpePathways_LCTRL.spoEnrollWrapper> spoEnrollResponse = (List<REDU_IpePathways_LCTRL.spoEnrollWrapper>) JSON.deserialize(objResponse.responseData, List<REDU_IpePathways_LCTRL.spoEnrollWrapper>.class);
            System.Assert.areEqual(spoMap.size(), spoEnrollResponse.size());

            for(REDU_IpePathways_LCTRL.spoEnrollWrapper wrapper : spoEnrollResponse){
                System.Assert.areEqual(childIpeMap.containsKey(wrapper.StudyPlan.Id), wrapper.isEnrolled);
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathways_LCTRL.manageChildIpeEnrollment() for enroll child ipe
     */
    @isTest   
    static void testEnrollChildIpeForAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        Map<Id, reduivy__Individual_Program_Enrollment__c> childIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            AND reduivy__Master_Enrollment__c = :masterIpe.Id
            AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
            AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
            WITH USER_MODE
        ]){
            childIpeMap.put(ipe.reduivy__Study_Plan__c, ipe);
        }
        
        Map<String, List<reduivy__Study_Plan__c>> mapToTest = new Map<String, List<reduivy__Study_Plan__c>>();
        for(reduivy__Study_Plan_Option__c spo : [
            SELECT Id, reduivy__Child_Study_Plan__c, reduivy__Status__c,
            reduivy__Child_Study_Plan__r.Id,
            reduivy__Child_Study_Plan__r.Name,
            reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :masterIpe.reduivy__Study_Plan__c
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]){
            if(!childIpeMap.containsKey(spo.reduivy__Child_Study_Plan__c)){
                if(!mapToTest.containsKey('enroll')){
                    mapToTest.put('enroll', new List<reduivy__Study_Plan__c>());
                }
                reduivy__Study_Plan__c sp = new reduivy__Study_Plan__c(  
                    id = spo.reduivy__Child_Study_Plan__r.Id,  
                    Name = spo.reduivy__Child_Study_Plan__r.Name,  
                    reduivy__Study_Program__c = spo.reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
                ); 
                mapToTest.get('enroll').add(sp);
            }
        }

        String mapToTestJson = JSON.serialize(mapToTest);

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.manageChildIpeEnrollment(masterIpe.Id, mapToTestJson);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            Map<Id, reduivy__Individual_Program_Enrollment__c> newChildIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
            for(reduivy__Individual_Program_Enrollment__c ipe : [
                SELECT Id, reduivy__Study_Plan__c
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
                AND reduivy__Master_Enrollment__c = :masterIpe.Id
                AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
                AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
                WITH USER_MODE
            ]){
                newChildIpeMap.put(ipe.reduivy__Study_Plan__c, ipe);
            }
            
            for(reduivy__Study_Plan__c sp : mapToTest.get('enroll')){
                System.Assert.areEqual(true, newChildIpeMap.containsKey(sp.Id), 'The child ipe should be enroll.');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathways_LCTRL.manageChildIpeEnrollment() for unenroll child ipe
     */
    @isTest   
    static void testUnenrollChildIpeForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        Map<Id, String> childIpeMap = new Map<Id, String>();
        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            AND reduivy__Master_Enrollment__c = :masterIpe.Id
            AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
            AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
            WITH USER_MODE
        ]){
            childIpeMap.put(ipe.reduivy__Study_Plan__c, ipe.reduivy__Enrollment_Status__c);
        }
        
        Map<String, List<reduivy__Study_Plan__c>> mapToTest = new Map<String, List<reduivy__Study_Plan__c>>();
        for(reduivy__Study_Plan_Option__c spo : [
            SELECT Id, reduivy__Child_Study_Plan__c, reduivy__Status__c,
            reduivy__Child_Study_Plan__r.Id,
            reduivy__Child_Study_Plan__r.Name,
            reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :masterIpe.reduivy__Study_Plan__c
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]){
            if(childIpeMap.get(spo.reduivy__Child_Study_Plan__c) == IPE_Helper.getInProgressStatuses()[0]){
                if(!mapToTest.containsKey('unenroll')){
                    mapToTest.put('unenroll', new List<reduivy__Study_Plan__c>());
                }
                reduivy__Study_Plan__c sp = new reduivy__Study_Plan__c(  
                    id = spo.reduivy__Child_Study_Plan__r.Id,  
                    Name = spo.reduivy__Child_Study_Plan__r.Name,  
                    reduivy__Study_Program__c = spo.reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
                ); 
                mapToTest.get('unenroll').add(sp);
            }
        }

        String mapToTestJson = JSON.serialize(mapToTest);

        System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.manageChildIpeEnrollment(masterIpe.Id, mapToTestJson);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            Map<Id, String> newChildIpeMap = new Map<Id, String>();
            for(reduivy__Individual_Program_Enrollment__c ipe : [
                SELECT Id, reduivy__Study_Plan__c, reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Master_Enrollment__c = :masterIpe.Id
                AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
                AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
                WITH USER_MODE
            ]){
                newChildIpeMap.put(ipe.reduivy__Study_Plan__c, ipe.reduivy__Enrollment_Status__c);
            }
            
            for(reduivy__Study_Plan__c sp : mapToTest.get('unenroll')){
                System.Assert.areEqual(IPE_Helper.getWithdrawnStatuses()[0], newChildIpeMap.get(sp.Id), 'The child ipe should be enroll.');
            }
             
            Test.stopTest();
        }
    }


    /**
     * @description Test as student for REDU_IpePathways_LCTRL.getSpoStudentEnrollment()
     */
    @isTest   
    static void testGetSpoStudentEnrollmentForStudentUser() {
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        //get a student for test
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIpe.reduivy__Contact__c];

        Map<Id, reduivy__Individual_Program_Enrollment__c> childIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            AND reduivy__Master_Enrollment__c = :masterIpe.Id
            AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
            AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
            WITH USER_MODE
        ]){
            childIpeMap.put(ipe.reduivy__Study_Plan__c, ipe);
        }

        Map<Id, reduivy__Study_Plan_Option__c> spoMap = new Map<Id, reduivy__Study_Plan_Option__c>();
        for(reduivy__Study_Plan_Option__c spo : [
            SELECT Id, reduivy__Child_Study_Plan__c, reduivy__Status__c 
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :masterIpe.reduivy__Study_Plan__c
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]){
            spoMap.put(spo.reduivy__Child_Study_Plan__c, spo);
        }

        System.runAs(studentUser){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.getSpoStudentEnrollment(masterIpe.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            List<REDU_IpePathways_LCTRL.spoEnrollWrapper> spoEnrollResponse = (List<REDU_IpePathways_LCTRL.spoEnrollWrapper>) JSON.deserialize(objResponse.responseData, List<REDU_IpePathways_LCTRL.spoEnrollWrapper>.class);
            System.Assert.areEqual(spoMap.size(), spoEnrollResponse.size());

            for(REDU_IpePathways_LCTRL.spoEnrollWrapper wrapper : spoEnrollResponse){
                System.Assert.areEqual(childIpeMap.containsKey(wrapper.StudyPlan.Id), wrapper.isEnrolled);
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_IpePathways_LCTRL.manageChildIpeEnrollment() for enroll child ipe
     */
    @isTest
    static void testEnrollChildIpeForStudentUser() {
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        //get a student for test
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIpe.reduivy__Contact__c];

        Map<Id, reduivy__Individual_Program_Enrollment__c> childIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            AND reduivy__Master_Enrollment__c = :masterIpe.Id
            AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
            AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
            WITH USER_MODE
        ]){
            childIpeMap.put(ipe.reduivy__Study_Plan__c, ipe);
        }
        
        Map<String, List<reduivy__Study_Plan__c>> mapToTest = new Map<String, List<reduivy__Study_Plan__c>>();
        for(reduivy__Study_Plan_Option__c spo : [
            SELECT Id, reduivy__Child_Study_Plan__c, reduivy__Status__c,
            reduivy__Child_Study_Plan__r.Id,
            reduivy__Child_Study_Plan__r.Name,
            reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :masterIpe.reduivy__Study_Plan__c
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]){
            if(!childIpeMap.containsKey(spo.reduivy__Child_Study_Plan__c)){
                if(!mapToTest.containsKey('enroll')){
                    mapToTest.put('enroll', new List<reduivy__Study_Plan__c>());
                }
                reduivy__Study_Plan__c sp = new reduivy__Study_Plan__c(  
                    id = spo.reduivy__Child_Study_Plan__r.Id,  
                    Name = spo.reduivy__Child_Study_Plan__r.Name,  
                    reduivy__Study_Program__c = spo.reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
                ); 
                mapToTest.get('enroll').add(sp);
            }
        }

        String mapToTestJson = JSON.serialize(mapToTest);

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.manageChildIpeEnrollment(masterIpe.Id, mapToTestJson);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            Map<Id, reduivy__Individual_Program_Enrollment__c> newChildIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
            for(reduivy__Individual_Program_Enrollment__c ipe : [
                SELECT Id, reduivy__Study_Plan__c
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
                AND reduivy__Master_Enrollment__c = :masterIpe.Id
                AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
                AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
                WITH USER_MODE
            ]){
                newChildIpeMap.put(ipe.reduivy__Study_Plan__c, ipe);
            }
            
            for(reduivy__Study_Plan__c sp : mapToTest.get('enroll')){
                System.Assert.areEqual(true, newChildIpeMap.containsKey(sp.Id), 'The child ipe should be enroll.');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_IpePathways_LCTRL.manageChildIpeEnrollment() for unenroll child ipe
     */
    @isTest   
    static void testUnenrollChildIpeForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        //get a student for test
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIpe.reduivy__Contact__c];

        Map<Id, String> childIpeMap = new Map<Id, String>();
        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            AND reduivy__Master_Enrollment__c = :masterIpe.Id
            AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
            AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
            WITH USER_MODE
        ]){
            childIpeMap.put(ipe.reduivy__Study_Plan__c, ipe.reduivy__Enrollment_Status__c);
        }
        
        Map<String, List<reduivy__Study_Plan__c>> mapToTest = new Map<String, List<reduivy__Study_Plan__c>>();
        for(reduivy__Study_Plan_Option__c spo : [
            SELECT Id, reduivy__Child_Study_Plan__c, reduivy__Status__c,
            reduivy__Child_Study_Plan__r.Id,
            reduivy__Child_Study_Plan__r.Name,
            reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :masterIpe.reduivy__Study_Plan__c
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]){
            if(childIpeMap.get(spo.reduivy__Child_Study_Plan__c) == IPE_Helper.getInProgressStatuses()[0]){
                if(!mapToTest.containsKey('unenroll')){
                    mapToTest.put('unenroll', new List<reduivy__Study_Plan__c>());
                }
                reduivy__Study_Plan__c sp = new reduivy__Study_Plan__c(  
                    id = spo.reduivy__Child_Study_Plan__r.Id,  
                    Name = spo.reduivy__Child_Study_Plan__r.Name,  
                    reduivy__Study_Program__c = spo.reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
                ); 
                mapToTest.get('unenroll').add(sp);
            }
        }

        String mapToTestJson = JSON.serialize(mapToTest);

        System.runAs(studentUser){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.manageChildIpeEnrollment(masterIpe.Id, mapToTestJson);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            Map<Id, String> newChildIpeMap = new Map<Id, String>();
            for(reduivy__Individual_Program_Enrollment__c ipe : [
                SELECT Id, reduivy__Study_Plan__c, reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Master_Enrollment__c = :masterIpe.Id
                AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
                AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
                WITH USER_MODE
            ]){
                newChildIpeMap.put(ipe.reduivy__Study_Plan__c, ipe.reduivy__Enrollment_Status__c);
            }
            
            for(reduivy__Study_Plan__c sp : mapToTest.get('unenroll')){
                System.Assert.areEqual(IPE_Helper.getWithdrawnStatuses()[0], newChildIpeMap.get(sp.Id), 'The child ipe should be enroll.');
            }
             
            Test.stopTest();
        }
    }


    /**
     * @description Test as faculty for REDU_IpePathways_LCTRL.getSpoStudentEnrollment()
     */
    @isTest   
    static void testGetSpoStudentEnrollmentForFacultyUser() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        Map<Id, reduivy__Individual_Program_Enrollment__c> childIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            AND reduivy__Master_Enrollment__c = :masterIpe.Id
            AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
            AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
            WITH USER_MODE
        ]){
            childIpeMap.put(ipe.reduivy__Study_Plan__c, ipe);
        }

        Map<Id, reduivy__Study_Plan_Option__c> spoMap = new Map<Id, reduivy__Study_Plan_Option__c>();
        for(reduivy__Study_Plan_Option__c spo : [
            SELECT Id, reduivy__Child_Study_Plan__c, reduivy__Status__c 
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :masterIpe.reduivy__Study_Plan__c
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]){
            spoMap.put(spo.reduivy__Child_Study_Plan__c, spo);
        }

        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.getSpoStudentEnrollment(masterIpe.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            List<REDU_IpePathways_LCTRL.spoEnrollWrapper> spoEnrollResponse = (List<REDU_IpePathways_LCTRL.spoEnrollWrapper>) JSON.deserialize(objResponse.responseData, List<REDU_IpePathways_LCTRL.spoEnrollWrapper>.class);
            System.Assert.areEqual(spoMap.size(), spoEnrollResponse.size());

            for(REDU_IpePathways_LCTRL.spoEnrollWrapper wrapper : spoEnrollResponse){
                System.Assert.areEqual(childIpeMap.containsKey(wrapper.StudyPlan.Id), wrapper.isEnrolled);
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathways_LCTRL.manageChildIpeEnrollment() for enroll child ipe
     */
    @isTest
    static void testEnrollChildIpeForFacultyUser() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        Map<Id, reduivy__Individual_Program_Enrollment__c> childIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            AND reduivy__Master_Enrollment__c = :masterIpe.Id
            AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
            AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
            WITH USER_MODE
        ]){
            childIpeMap.put(ipe.reduivy__Study_Plan__c, ipe);
        }
        
        Map<String, List<reduivy__Study_Plan__c>> mapToTest = new Map<String, List<reduivy__Study_Plan__c>>();
        for(reduivy__Study_Plan_Option__c spo : [
            SELECT Id, reduivy__Child_Study_Plan__c, reduivy__Status__c,
            reduivy__Child_Study_Plan__r.Id,
            reduivy__Child_Study_Plan__r.Name,
            reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :masterIpe.reduivy__Study_Plan__c
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]){
            if(!childIpeMap.containsKey(spo.reduivy__Child_Study_Plan__c)){
                if(!mapToTest.containsKey('enroll')){
                    mapToTest.put('enroll', new List<reduivy__Study_Plan__c>());
                }
                reduivy__Study_Plan__c sp = new reduivy__Study_Plan__c(  
                    id = spo.reduivy__Child_Study_Plan__r.Id,  
                    Name = spo.reduivy__Child_Study_Plan__r.Name,  
                    reduivy__Study_Program__c = spo.reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
                ); 
                mapToTest.get('enroll').add(sp);
            }
        }

        String mapToTestJson = JSON.serialize(mapToTest);

        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.manageChildIpeEnrollment(masterIpe.Id, mapToTestJson);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            Map<Id, reduivy__Individual_Program_Enrollment__c> newChildIpeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>();
            for(reduivy__Individual_Program_Enrollment__c ipe : [
                SELECT Id, reduivy__Study_Plan__c
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
                AND reduivy__Master_Enrollment__c = :masterIpe.Id
                AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
                AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
                WITH USER_MODE
            ]){
                newChildIpeMap.put(ipe.reduivy__Study_Plan__c, ipe);
            }
            
            for(reduivy__Study_Plan__c sp : mapToTest.get('enroll')){
                System.Assert.areEqual(true, newChildIpeMap.containsKey(sp.Id), 'The child ipe should be enroll.');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathways_LCTRL.manageChildIpeEnrollment() for unenroll child ipe
     */
    @isTest   
    static void testUnenrollChildIpeForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        Map<Id, String> childIpeMap = new Map<Id, String>();
        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, reduivy__Study_Plan__c, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :IPE_Helper.getInProgressStatuses()
            AND reduivy__Master_Enrollment__c = :masterIpe.Id
            AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
            AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
            WITH USER_MODE
        ]){
            childIpeMap.put(ipe.reduivy__Study_Plan__c, ipe.reduivy__Enrollment_Status__c);
        }
        
        Map<String, List<reduivy__Study_Plan__c>> mapToTest = new Map<String, List<reduivy__Study_Plan__c>>();
        for(reduivy__Study_Plan_Option__c spo : [
            SELECT Id, reduivy__Child_Study_Plan__c, reduivy__Status__c,
            reduivy__Child_Study_Plan__r.Id,
            reduivy__Child_Study_Plan__r.Name,
            reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
            FROM reduivy__Study_Plan_Option__c
            WHERE reduivy__Master_Study_Plan__c = :masterIpe.reduivy__Study_Plan__c
            AND reduivy__Status__c = :SPO_Helper.STATUS_ACTIVE
            WITH USER_MODE
        ]){
            if(childIpeMap.get(spo.reduivy__Child_Study_Plan__c) == IPE_Helper.getInProgressStatuses()[0]){
                if(!mapToTest.containsKey('unenroll')){
                    mapToTest.put('unenroll', new List<reduivy__Study_Plan__c>());
                }
                reduivy__Study_Plan__c sp = new reduivy__Study_Plan__c(  
                    id = spo.reduivy__Child_Study_Plan__r.Id,  
                    Name = spo.reduivy__Child_Study_Plan__r.Name,  
                    reduivy__Study_Program__c = spo.reduivy__Child_Study_Plan__r.reduivy__Study_Program__c  
                ); 
                mapToTest.get('unenroll').add(sp);
            }
        }

        String mapToTestJson = JSON.serialize(mapToTest);

        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathways_LCTRL.manageChildIpeEnrollment(masterIpe.Id, mapToTestJson);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathways_TEST');

            Map<Id, String> newChildIpeMap = new Map<Id, String>();
            for(reduivy__Individual_Program_Enrollment__c ipe : [
                SELECT Id, reduivy__Study_Plan__c, reduivy__Enrollment_Status__c
                FROM reduivy__Individual_Program_Enrollment__c
                WHERE reduivy__Master_Enrollment__c = :masterIpe.Id
                AND reduivy__Contact__c = :masterIpe.reduivy__Contact__c
                AND RecordTypeId = :IPE_Helper.getChildEnrollmentRecordTypeId()
                WITH USER_MODE
            ]){
                newChildIpeMap.put(ipe.reduivy__Study_Plan__c, ipe.reduivy__Enrollment_Status__c);
            }
            
            for(reduivy__Study_Plan__c sp : mapToTest.get('unenroll')){
                System.Assert.areEqual(IPE_Helper.getWithdrawnStatuses()[0], newChildIpeMap.get(sp.Id), 'The child ipe should be enroll.');
            }
             
            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathways_LCTRL.getMissedFailedStudyUnits() with missed units
     */
    @isTest  
    static void testGetMissedFailedStudyUnitsForMissedStudyUnitsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c, reduivy__Study_Pathway__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        //Removed all individual enrollments to create missed study units
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        System.runAs(ADMIN_USER){

            Test.startTest();

            Set<Id> missedFailedSunIds = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(masterIpe.Id, masterIpe.reduivy__Study_Plan__c, masterIpe.reduivy__Study_Pathway__c, USR_Helper.USER_MODE_ADMIN, 3, 'All');
            System.Assert.areEqual(6, missedFailedSunIds.size(), 'It should have 6 missed study units.');

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathways_LCTRL.getMissedFailedStudyUnits() with failed units
     */
    @isTest  
    static void testGetMissedFailedStudyUnitsForFailedStudyUnitsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Grade_Setting__c> sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];

        Set<Id> sunIds = new Set<Id>();

        //Removed all individual enrollments
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        //Create failed ien for above ipe
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = masterIpe.reduivy__Starting_Term__c,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed',
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 0,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        System.runAs(ADMIN_USER){

            Test.startTest();

            Set<Id> missedFailedSunIds = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(masterIpe.Id, masterIpe.reduivy__Study_Plan__c, masterIpe.reduivy__Study_Pathway__c, USR_Helper.USER_MODE_ADMIN, 3, 'All');
            System.Assert.areEqual(6, missedFailedSunIds.size(), 'It should have 6 failed study units.');

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathways_LCTRL.getMissedFailedStudyUnits() without any missed/failed units
     */
    @isTest  
    static void testGetMissedFailedStudyUnitsWithoutMissedFailedStudyUnitsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Grade_Setting__c> sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];

        Set<Id> sunIds = new Set<Id>();

        //Removed all individual enrollments
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        //Create failed ien for above ipe
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = masterIpe.reduivy__Starting_Term__c,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed',
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 100,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        System.runAs(ADMIN_USER){

            Test.startTest();

            Set<Id> missedFailedSunIds = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(masterIpe.Id, masterIpe.reduivy__Study_Plan__c, masterIpe.reduivy__Study_Pathway__c, USR_Helper.USER_MODE_ADMIN, 3, 'All');
            System.Assert.areEqual(0, missedFailedSunIds.size(), 'It should have 0 missed/failed study units.');

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathways_LCTRL.getMissedFailedStudyUnits() with missed units
     */
    @isTest  
    static void testGetMissedFailedStudyUnitsForMissedStudyUnitsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c, reduivy__Study_Pathway__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        //Removed all individual enrollments to create missed study units
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        System.runAs(FACULTY_USER){

            Test.startTest();

            Set<Id> missedFailedSunIds = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(masterIpe.Id, masterIpe.reduivy__Study_Plan__c, masterIpe.reduivy__Study_Pathway__c, USR_Helper.USER_MODE_FACULTY, 3, 'All');
            System.Assert.areEqual(6, missedFailedSunIds.size(), 'It should have 6 missed study units.');

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathways_LCTRL.getMissedFailedStudyUnits() with failed units
     */
    @isTest  
    static void testGetMissedFailedStudyUnitsForFailedStudyUnitsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Grade_Setting__c> sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];

        Set<Id> sunIds = new Set<Id>();

        //Removed all individual enrollments
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        //Create failed ien for above ipe
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = masterIpe.reduivy__Starting_Term__c,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed',
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 0,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        System.runAs(FACULTY_USER){

            Test.startTest();

            Set<Id> missedFailedSunIds = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(masterIpe.Id, masterIpe.reduivy__Study_Plan__c, masterIpe.reduivy__Study_Pathway__c, USR_Helper.USER_MODE_FACULTY, 3, 'All');
            System.Assert.areEqual(6, missedFailedSunIds.size(), 'It should have 6 failed study units.');

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathways_LCTRL.getMissedFailedStudyUnits() without any missed/failed units
     */
    @isTest  
    static void testGetMissedFailedStudyUnitsWithoutMissedFailedStudyUnitsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Grade_Setting__c> sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];

        Set<Id> sunIds = new Set<Id>();

        //Removed all individual enrollments
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        //Create failed ien for above ipe
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = masterIpe.reduivy__Starting_Term__c,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed',
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 100,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        System.runAs(FACULTY_USER){

            Test.startTest();

            Set<Id> missedFailedSunIds = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(masterIpe.Id, masterIpe.reduivy__Study_Plan__c, masterIpe.reduivy__Study_Pathway__c, USR_Helper.USER_MODE_FACULTY, 3, 'All');
            System.Assert.areEqual(0, missedFailedSunIds.size(), 'It should have 0 missed/failed study units.');

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_IpePathways_LCTRL.getMissedFailedStudyUnits() with missed units
     */
    @isTest  
    static void testGetMissedFailedStudyUnitsForMissedStudyUnitsAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];     

        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c, reduivy__Study_Pathway__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        //Removed all individual enrollments to create missed study units
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        System.runAs(reduStudent){

            Test.startTest();

            Set<Id> missedFailedSunIds = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(masterIpe.Id, masterIpe.reduivy__Study_Plan__c, masterIpe.reduivy__Study_Pathway__c, USR_Helper.USER_MODE_STUDENT, 3, 'All');
            System.Assert.areEqual(6, missedFailedSunIds.size(), 'It should have 6 missed study units.');

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_IpePathways_LCTRL.getMissedFailedStudyUnits() with failed units
     */
    @isTest  
    static void testGetMissedFailedStudyUnitsForFailedStudyUnitsAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Grade_Setting__c> sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];

        Set<Id> sunIds = new Set<Id>();

        //Removed all individual enrollments
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        //Create failed ien for above ipe
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = masterIpe.reduivy__Starting_Term__c,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed',
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 0,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        System.runAs(reduStudent){

            Test.startTest();

            Set<Id> missedFailedSunIds = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(masterIpe.Id, masterIpe.reduivy__Study_Plan__c, masterIpe.reduivy__Study_Pathway__c, USR_Helper.USER_MODE_STUDENT, 3, 'All');
            System.Assert.areEqual(6, missedFailedSunIds.size(), 'It should have 6 failed study units.');

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_IpePathways_LCTRL.getMissedFailedStudyUnits() without any missed/failed units
     */
    @isTest  
    static void testGetMissedFailedStudyUnitsWithoutMissedFailedStudyUnitsAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];
        
        reduivy__Individual_Program_Enrollment__c masterIpe = [
            SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c
            FROM reduivy__Individual_Program_Enrollment__c 
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId() 
            LIMIT 1
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        List<reduivy__Study_Grade_Setting__c> sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];

        Set<Id> sunIds = new Set<Id>();

        //Removed all individual enrollments
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        //Create failed ien for above ipe
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = masterIpe.reduivy__Starting_Term__c,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed',
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 100,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        System.runAs(reduStudent){

            Test.startTest();

            Set<Id> missedFailedSunIds = REDU_IpePathways_LCTRL.getMissedFailedStudyUnits(masterIpe.Id, masterIpe.reduivy__Study_Plan__c, masterIpe.reduivy__Study_Pathway__c, USR_Helper.USER_MODE_STUDENT, 3, 'All');
            System.Assert.areEqual(0, missedFailedSunIds.size(), 'It should have 0 missed/failed study units.');

            Test.stopTest();
        }
    }

    @IsTest
    static void testGetEnrollmentActionStatusConfigAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_IpePathways_LCTRL.getEnrollmentActionStatusConfigs();
            Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> configs = (Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt>) JSON.deserialize(response.responseData, Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt>.class);

            List<reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> easConfigs = IPW_Helper.getEnrollmentActionStatusConfigs();
            System.Assert.isTrue(!configs.isEmpty());
            
            for (reduivy__IdvPw_Enrollment_Action_Status_Config__mdt eas : easConfigs) {
                System.Assert.isTrue(configs.containsKey(eas.reduivy__Enrollment_Action_Status__c));
            }
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testGetEnrollmentActionStatusConfigAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_IpePathways_LCTRL.getEnrollmentActionStatusConfigs();
            Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> configs = (Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt>) JSON.deserialize(response.responseData, Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt>.class);

            List<reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> easConfigs = IPW_Helper.getEnrollmentActionStatusConfigs();
            System.Assert.isTrue(!configs.isEmpty());
            
            for (reduivy__IdvPw_Enrollment_Action_Status_Config__mdt eas : easConfigs) {
                System.Assert.isTrue(configs.containsKey(eas.reduivy__Enrollment_Action_Status__c));
            }
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testGetEnrollmentActionStatusConfigAsStudent(){
        
        User STUDENT_USER = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(STUDENT_USER){
            REDU_LightningResponse response = REDU_IpePathways_LCTRL.getEnrollmentActionStatusConfigs();
            Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> configs = (Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt>) JSON.deserialize(response.responseData, Map<String, reduivy__IdvPw_Enrollment_Action_Status_Config__mdt>.class);

            List<reduivy__IdvPw_Enrollment_Action_Status_Config__mdt> easConfigs = IPW_Helper.getEnrollmentActionStatusConfigs();
            System.Assert.isTrue(!configs.isEmpty());
            
            for (reduivy__IdvPw_Enrollment_Action_Status_Config__mdt eas : easConfigs) {
                System.Assert.isTrue(configs.containsKey(eas.reduivy__Enrollment_Action_Status__c));
            }
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testGetIpeStatusConfigAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_IpePathways_LCTRL.getIpeStatusConfigs();
            Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt> configs = (Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt>) JSON.deserialize(response.responseData, Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt>.class);

            List<reduivy__IdvPe_Enrollment_Status_Config__mdt> ipeConfigs = IPE_Helper.getEnrollmentStatusConfig();
            System.Assert.isTrue(!configs.isEmpty());
            
            for (reduivy__IdvPe_Enrollment_Status_Config__mdt ipec : ipeConfigs) {
                System.Assert.isTrue(configs.containsKey(ipec.reduivy__Enrollment_Status__c));
            }
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testGetIpeStatusConfigAsFaculty(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_IpePathways_LCTRL.getIpeStatusConfigs();
            Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt> configs = (Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt>) JSON.deserialize(response.responseData, Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt>.class);

            List<reduivy__IdvPe_Enrollment_Status_Config__mdt> ipeConfigs = IPE_Helper.getEnrollmentStatusConfig();
            System.Assert.isTrue(!configs.isEmpty());
            
            for (reduivy__IdvPe_Enrollment_Status_Config__mdt ipec : ipeConfigs) {
                System.Assert.isTrue(configs.containsKey(ipec.reduivy__Enrollment_Status__c));
            }
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testGetIpeStatusConfigAsStudent(){
        
        User STUDENT_USER = testFactory.getStudentUser();

        Test.startTest();

        System.runAs(STUDENT_USER){
            REDU_LightningResponse response = REDU_IpePathways_LCTRL.getIpeStatusConfigs();
            Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt> configs = (Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt>) JSON.deserialize(response.responseData, Map<String, reduivy__IdvPe_Enrollment_Status_Config__mdt>.class);

            List<reduivy__IdvPe_Enrollment_Status_Config__mdt> ipeConfigs = IPE_Helper.getEnrollmentStatusConfig();
            System.Assert.isTrue(!configs.isEmpty());
            
            for (reduivy__IdvPe_Enrollment_Status_Config__mdt ipec : ipeConfigs) {
                System.Assert.isTrue(configs.containsKey(ipec.reduivy__Enrollment_Status__c));
            }
        }

        Test.stopTest();
        
    }
}