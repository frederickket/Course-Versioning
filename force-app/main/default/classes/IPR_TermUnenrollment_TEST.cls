/**
 * @author      WDCi (XW)
 * @date        May 2025
 * @group       Test
 * @description Test class for IPR_TermUnenrollment_FLOW
 * @changehistory
 * ISS-002436 13-05-2025 XW - new class
 */
@IsTest
public inherited sharing class IPR_TermUnenrollment_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String SRC_STM_CYT1 = 'CYT1';

    static final String SRC_CON = 'sandydoe@redu.example';
    static final String SRC_IPR = SRC_CON + '_' + SRC_STM_CYT1;
    
    static final String SRC_CON2 = 'johndoe@redu.example';
    static final String SRC_IPR2 = SRC_CON2 + '_' + SRC_STM_CYT1;
    
    static final String SRC_SUN_BUS101 = 'BUS101';
    static final String SRC_SUN_BUS102 = 'BUS102';
    static final String SRC_SUN_BUS103 = 'BUS103';
    static final String SRC_SUN_COM101 = 'COM101';

    static final String SRC_SUN_MGT301 = 'MGT301';
    static final String SRC_SUN_MGT302 = 'MGT302';
    static final String SRC_SUN_ICT101 = 'ICT101';
    static final String SRC_SUN_ICT102 = 'ICT102';

    static final String ENROLLMENT_STATUS_ENROLLMENT_REQUESTED = 'Enrollment Requested';
    static final String ENROLLMENT_STATUS_ENROLLED = 'Enrolled';
    static final String ENROLLMENT_STATUS_WITHDRAWN = 'Withdrawn';
    static final String ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED = 'Withdrawal Requested';

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();
        	
            testFactory.initMasterData(null);
            testFactory.initOfferingData(null);
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IPE_Helper.getApiName(), true);

            List<reduivy__Individual_Enrollment__c> ienToUpdate = new List<reduivy__Individual_Enrollment__c>();
            reduivy__Individual_Enrollment__c ienBus102 = testFactory.studentIndividualEnrollments.get(SRC_CON + '_' + SRC_SUN_BUS102 + '_' + SRC_STM_CYT1 + '_' + 'SYDNEY');
            ienBus102.reduivy__Enrollment_Status__c = ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED;
            ienToUpdate.add(ienBus102);

            reduivy__Individual_Enrollment__c ienBus103 = testFactory.studentIndividualEnrollments.get(SRC_CON + '_' + SRC_SUN_BUS103 + '_' + SRC_STM_CYT1 + '_' + 'SYDNEY');
            ienBus103.reduivy__Enrollment_Status__c = ENROLLMENT_STATUS_ENROLLMENT_REQUESTED;
            ienToUpdate.add(ienBus103);

            reduivy__Individual_Enrollment__c ienMgt302 = testFactory.studentIndividualEnrollments.get(SRC_CON2 + '_' + SRC_SUN_MGT302 + '_' + SRC_STM_CYT1 + '_' + 'SYDNEY');
            ienMgt302.reduivy__Enrollment_Status__c = ENROLLMENT_STATUS_ENROLLMENT_REQUESTED;
            ienToUpdate.add(ienMgt302);

            update ienToUpdate;
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for unenrolling enrolled ien from 1 ipr
     */
    @IsTest
    static void testFor_UnenrollEnrolledIen_From1Ipr_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_COM101)
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            expectedIdSet.add(ien.Id);
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdSet);
        request.individualAcademicProgressId = ipr.Id;

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request});

            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :actualIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for unenrolling enrolled ien from 1 ipr, selected ien
     */
    @IsTest
    static void testFor_UnenrollEnrolledIen_SelectedIen_From1Ipr_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Set<Id> expectedIdSet = new Set<Id>();
        Set<Id> allIenIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_COM101)
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            
            allIenIdSet.add(ien.Id);
            if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_COM101) {
                expectedIdSet.add(ien.Id);
            }
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdSet);
        request.individualAcademicProgressId = ipr.Id;

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request});

            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c, reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :allIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_COM101) {
                    System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
                } else {
                    System.Assert.areNotEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'BUS101 IEN Status should not be updated!');
                }
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for unenrolling enrolled & withdrawal requested ien from 1 ipr
     */
    @IsTest
    static void testFor_UnenrollEnrolledWithdrawalRequestedIen_From1Ipr_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_BUS102, :SRC_SUN_COM101)
        ]){
            if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_BUS102) {
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED + '"!');
            } else {
                System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            }
            expectedIdSet.add(ien.Id);
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdSet);
        request.individualAcademicProgressId = ipr.Id;

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request});

            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :actualIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for unenrolling enrolled & withdrawal requested ien from 2 ipr
     */
    @IsTest
    static void testFor_UnenrollEnrolledWithdrawalRequestedIen_From2Ipr_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Set<Id> expectedIdSet = new Set<Id>();
        Set<Id> expectedIdIpr1Set = new Set<Id>();
        Set<Id> expectedIdIpr2Set = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr;
        reduivy__Individual_Academic_Progress__c ipr2;
        for(reduivy__Individual_Academic_Progress__c tempipr : [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c IN (:SRC_IPR, :SRC_IPR2)
            LIMIT 2
        ]){
            if(tempipr.reduivy__Sample_Record_Code__c == SRC_IPR) {
                ipr = tempipr;
            }
            else if(tempipr.reduivy__Sample_Record_Code__c == SRC_IPR2) {
                ipr2 = tempipr;
            }
        }


        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c,
            reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c IN (:SRC_IPR, :SRC_IPR2)
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_BUS102, :SRC_SUN_COM101, :SRC_SUN_MGT301, :SRC_SUN_MGT302, :SRC_SUN_ICT101, :SRC_SUN_ICT102)
        ]){
            if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_BUS102) {
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED + '"!');
            } else if(
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_BUS103 || 
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_MGT302
            ){
                System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLMENT_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLMENT_REQUESTED + '"!');
            } else {
                System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            }

            if(ien.reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c == SRC_IPR) {
                expectedIdIpr1Set.add(ien.Id);
            } else {
                expectedIdIpr2Set.add(ien.Id);
            }
            expectedIdSet.add(ien.Id);
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdIpr1Set);
        request.individualAcademicProgressId = ipr.Id;

        IPR_TermUnenrollment_FLOW.Request request2 = new IPR_TermUnenrollment_FLOW.Request();
        request2.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request2.ienIdList = new List<Id>(expectedIdIpr2Set);
        request2.individualAcademicProgressId = ipr2.Id;

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request, request2});

            system.debug(JSON.serialize(responses));
            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :actualIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
            }
        }

        Test.stopTest();

    }



    /**
     * @description Test as student for unenrolling enrolled from 1 ipr
     */
    @IsTest
    static void testFor_UnenrollEnrolledIen_From1Ipr_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_COM101)
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            expectedIdSet.add(ien.Id);
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdSet);
        request.individualAcademicProgressId = ipr.Id;

        Test.startTest();
        
		System.runAs(studentUser){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request});

            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :actualIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
            }
        }

        Test.stopTest();
		
    }

    
    /**
     * @description Test as student for unenrolling enrolled ien from 1 ipr, selected ien
     */
    @IsTest
    static void testFor_UnenrollEnrolledIen_SelectedIen_From1Ipr_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        Set<Id> expectedIdSet = new Set<Id>();
        Set<Id> allIenIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_COM101)
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            
            allIenIdSet.add(ien.Id);
            if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_COM101) {
                expectedIdSet.add(ien.Id);
            }
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdSet);
        request.individualAcademicProgressId = ipr.Id;

        Test.startTest();
        
		System.runAs(studentUser){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request});

            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c, reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :allIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_COM101) {
                    System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
                } else {
                    System.Assert.areNotEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'BUS101 IEN Status should not be updated!');
                }
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as student for unenrolling enrolled & withdrawal requested ien from 1 ipr
     */
    @IsTest
    static void testFor_UnenrollEnrolledWithdrawalRequestedIen_From1Ipr_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_BUS102, :SRC_SUN_COM101)
        ]){
            if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_BUS102) {
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED + '"!');
            } else {
                System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            }
            expectedIdSet.add(ien.Id);
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdSet);
        request.individualAcademicProgressId = ipr.Id;

        Test.startTest();
        
		System.runAs(studentUser){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request});

            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :actualIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as student for unenrolling enrolled & withdrawal requested ien from 2 ipr
     */
    @IsTest
    static void testFor_UnenrollEnrolledWithdrawalRequestedIen_From2Ipr_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        Set<Id> expectedIdSet = new Set<Id>();
        Set<Id> expectedIdIpr1Set = new Set<Id>();
        Set<Id> expectedIdIpr2Set = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr;
        reduivy__Individual_Academic_Progress__c ipr2;
        for(reduivy__Individual_Academic_Progress__c tempipr : [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c IN (:SRC_IPR, :SRC_IPR2)
            LIMIT 2
        ]){
            if(tempipr.reduivy__Sample_Record_Code__c == SRC_IPR) {
                ipr = tempipr;
            }
            else if(tempipr.reduivy__Sample_Record_Code__c == SRC_IPR2) {
                ipr2 = tempipr;
            }
        }


        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c,
            reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c IN (:SRC_IPR, :SRC_IPR2)
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_BUS102, :SRC_SUN_COM101, :SRC_SUN_MGT301, :SRC_SUN_MGT302, :SRC_SUN_ICT101, :SRC_SUN_ICT102)
        ]){
            if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_BUS102) {
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED + '"!');
            } else if(
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_BUS103 || 
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_MGT302
            ){
                System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLMENT_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLMENT_REQUESTED + '"!');
            } else {
                System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            }
            
            if(ien.reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c == SRC_IPR) {
                expectedIdIpr1Set.add(ien.Id);
            } else {
                expectedIdIpr2Set.add(ien.Id);
            }
            expectedIdSet.add(ien.Id);
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdIpr1Set);
        request.individualAcademicProgressId = ipr.Id;

        IPR_TermUnenrollment_FLOW.Request request2 = new IPR_TermUnenrollment_FLOW.Request();
        request2.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request2.ienIdList = new List<Id>(expectedIdIpr2Set);
        request2.individualAcademicProgressId = ipr2.Id;

        Test.startTest();
        
		System.runAs(studentUser){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request, request2});

            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            Set<Id> actualIenIdSet = new Set<Id>();
            
            Integer responseIndex = 0;
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.FAIL, response.status);
                System.Assert.isTrue(response.ienIdList.isEmpty(), 'ien list should be empty as an ipr that is not belongs to the student is updated!');
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :actualIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                System.Assert.areNotEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Status should not be updated!');
            }
        }

        Test.stopTest();

    }
    
    /**
     * @description Test as faculty for unenrolling enrolled ien from 1 ipr
     */
    @IsTest
    static void testFor_UnenrollEnrolledIen_From1Ipr_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyuser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_COM101)
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            expectedIdSet.add(ien.Id);
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdSet);
        request.individualAcademicProgressId = ipr.Id;

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request});

            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :actualIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
            }
        }

        Test.stopTest();
		
    }

    
    /**
     * @description Test as faculty for unenrolling enrolled ien from 1 ipr, selected ien
     */
    @IsTest
    static void testFor_UnenrollEnrolledIen_SelectedIen_From1Ipr_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Set<Id> expectedIdSet = new Set<Id>();
        Set<Id> allIenIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_COM101)
        ]){
            System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            
            allIenIdSet.add(ien.Id);
            if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_COM101) {
                expectedIdSet.add(ien.Id);
            }
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdSet);
        request.individualAcademicProgressId = ipr.Id;

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request});

            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c, reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :allIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_COM101) {
                    System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
                } else {
                    System.Assert.areNotEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'BUS101 IEN Status should not be updated!');
                }
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for unenrolling enrolled & withdrawal requested ien from 1 ipr
     */
    @IsTest
    static void testFor_UnenrollEnrolledWithdrawalRequestedIen_From1Ipr_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyuser();
        Set<Id> expectedIdSet = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr = [
            SELECT Id
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c = :SRC_IPR 
            LIMIT 1
        ];

        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c = :SRC_IPR
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_BUS102, :SRC_SUN_COM101)
        ]){
            if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_BUS102) {
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED + '"!');
            } else {
                System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            }
            expectedIdSet.add(ien.Id);
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdSet);
        request.individualAcademicProgressId = ipr.Id;

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request});

            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :actualIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
            }
        }

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for unenrolling enrolled & withdrawal requested ien from 2 ipr
     */
    @IsTest
    static void testFor_UnenrollEnrolledWithdrawalRequestedIen_From2Ipr_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyuser();
        Set<Id> expectedIdSet = new Set<Id>();
        Set<Id> expectedIdIpr1Set = new Set<Id>();
        Set<Id> expectedIdIpr2Set = new Set<Id>();
        reduivy__Individual_Academic_Progress__c ipr;
        reduivy__Individual_Academic_Progress__c ipr2;
        for(reduivy__Individual_Academic_Progress__c tempipr : [
            SELECT Id, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Academic_Progress__c 
            WHERE reduivy__Sample_Record_Code__c IN (:SRC_IPR, :SRC_IPR2)
            LIMIT 2
        ]){
            if(tempipr.reduivy__Sample_Record_Code__c == SRC_IPR) {
                ipr = tempipr;
            }
            else if(tempipr.reduivy__Sample_Record_Code__c == SRC_IPR2) {
                ipr2 = tempipr;
            }
        }


        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Enrollment_Status__c,
            reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c,
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c IN (:SRC_IPR, :SRC_IPR2)
            AND reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c IN (:SRC_SUN_BUS101, :SRC_SUN_BUS102, :SRC_SUN_COM101, :SRC_SUN_MGT301, :SRC_SUN_MGT302, :SRC_SUN_ICT101, :SRC_SUN_ICT102)
        ]){
            if(ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_BUS102) {
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_WITHDRAWAL_REQUESTED + '"!');
            } else if(
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_BUS103 || 
                ien.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == SRC_SUN_MGT302
            ){
                System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLMENT_REQUESTED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLMENT_REQUESTED + '"!');
            } else {
                System.Assert.areEqual(ENROLLMENT_STATUS_ENROLLED, ien.reduivy__Enrollment_Status__c, 'Enrollment Status should be "' + ENROLLMENT_STATUS_ENROLLED + '"!');
            }

            if(ien.reduivy__Individual_Academic_Progress__r.reduivy__Sample_Record_Code__c == SRC_IPR) {
                expectedIdIpr1Set.add(ien.Id);
            } else {
                expectedIdIpr2Set.add(ien.Id);
            }
            expectedIdSet.add(ien.Id);
        }

        IPR_TermUnenrollment_FLOW.Request request = new IPR_TermUnenrollment_FLOW.Request();
        request.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request.ienIdList = new List<Id>(expectedIdIpr1Set);
        request.individualAcademicProgressId = ipr.Id;

        IPR_TermUnenrollment_FLOW.Request request2 = new IPR_TermUnenrollment_FLOW.Request();
        request2.enrollmentStatus = ENROLLMENT_STATUS_WITHDRAWN;
        request2.ienIdList = new List<Id>(expectedIdIpr2Set);
        request2.individualAcademicProgressId = ipr2.Id;

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            List<IPR_TermUnenrollment_FLOW.Response> responses = IPR_TermUnenrollment_FLOW.execute(new List<IPR_TermUnenrollment_FLOW.Request>{request, request2});

            system.debug(JSON.serialize(responses));
            System.Assert.isTrue(!responses.isEmpty(), 'ien list should be retrieved!');
            Set<Id> actualIenIdSet = new Set<Id>();
            
            for(IPR_TermUnenrollment_FLOW.Response response : responses) {
                System.Assert.areEqual(REDU_LightningResponse.SUCCESS, response.status);
                System.Assert.isTrue(!response.ienIdList.isEmpty(), 'ien list should not be empty!');
                for(Id ienId : response.ienIdList) {
                    System.Assert.isTrue(expectedIdSet.contains(ienId), 'Should be found in the expectedIdSet!');
                    actualIenIdSet.add(ienId);
                }
            }
            List<reduivy__Individual_Enrollment__c> expectedIenList = [SELECT Id, reduivy__Enrollment_Status__c FROM reduivy__Individual_Enrollment__c WHERE Id IN :actualIenIdSet];

            for(reduivy__Individual_Enrollment__c ien : expectedIenList){
                System.Assert.areEqual(ENROLLMENT_STATUS_WITHDRAWN, ien.reduivy__Enrollment_Status__c, 'Wrong status!');
            }
        }

        Test.stopTest();

    }
	
}