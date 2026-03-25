/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Test
 * @description Test class for IRQ_IndividualRequirementSetRollup_EXE
 * @changehistory
 * ISS-002128 05-06-2025 XW - new class
 * ISS-002675 14-01-2026 XiRouh - Added new test methods to cover roll-up results for different visibility types in the new roll-up fields
 */
@IsTest
public inherited sharing class IRQ_IndividualRequirementSetRollup_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String SRS_LOCAL = 'SRS_Local';
    static final String SRS_GENERAL = 'SRS_General';
    static final String SRQ_LOCAL = 'SRS_Local_UploadID';
    static final String SRQ_GENERAL = 'SRS_General_UploadTranscript';
    static final String IRS_LOCAL = 'sandydoe@redu.example_SRS_Local';
    static final String IRS_GENERAL = 'sandydoe@redu.example_SRS_General';

    static reduivy__Study_Requirement__c srqLocal;
    static reduivy__Study_Requirement__c srqGeneral;

    static reduivy__Individual_Requirement_Set__c irsLocal;
    static reduivy__Individual_Requirement_Set__c irsGeneral;

    static String INSUFFICIENT_ACCESS_ERROR_MESSAGE = 'INSUFFICIENT_ACCESS_OR_READONLY';
    static Integer IRQ_SIZE = 10;
    
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
        	
            testFactory.initMasterData(SRQ_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IRQ_Helper.getApiName(), true);

            Test.stopTest();
		}


    }
	
    /**
     * @description Test as admin for creating irq with active true
     */
    @IsTest
    static void testForCreate_ActiveTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');


		System.runAs(ADMIN_USER){
            insert newIrq;
		}

        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for creating irq with active false
     */
    @IsTest
    static void testForCreate_ActiveFalse_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');


		System.runAs(ADMIN_USER){
            insert newIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for creating irq without irs parent
     * invalid anymore, as a new validation rule enforces every irq should have a parent irs
     */
    /*@IsTest
    static void testForCreate_WithoutIrsParent_AsAdmin() {
    }*/

    /**
     * @description Test as admin for updating irq to test parent irs to null and not null
     * invalid anymore, as a new validation rule enforces every irq should have a parent irs
     */
    /*@IsTest
    static void testForUpdate_ParentIrs_AsAdmin() {

    }*/

    /**
     * @description Test as admin for updating irq to test active to false and true
     */
    @IsTest
    static void testForUpdate_Active_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];
        targetIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;

		System.runAs(ADMIN_USER){
            update targetIrq;
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        targetIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        System.runAs(ADMIN_USER){
            update targetIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for updating irq to set submitted to true and false
     */
    @IsTest
    static void testForUpdate_Submitted_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        irsGeneral.reduivy__Individual_Requirements__r[0].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;

		System.runAs(ADMIN_USER){
            update irsGeneral.reduivy__Individual_Requirements__r[0];
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        irsGeneral.reduivy__Individual_Requirements__r[0].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        System.runAs(ADMIN_USER){
            update irsGeneral.reduivy__Individual_Requirements__r[0];
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for updating irq to set review status to Conditionally Accepted, to Accepted and to Open
     */
    @IsTest
    static void testForUpdate_ReviewStatus_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];
        targetIrq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED;
        targetIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;

		System.runAs(ADMIN_USER){
            update targetIrq;
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        targetIrq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;

        System.runAs(ADMIN_USER){
            update targetIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(1, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(1, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        targetIrq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;
        targetIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;

        System.runAs(ADMIN_USER){
            update targetIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs3 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs3.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs3.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs3.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for deleting and undeleting irq with active true
     */
    @IsTest
    static void testForDeleteUndelete_ActiveTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //validate before delete new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];

		System.runAs(ADMIN_USER){
            delete targetIrq;
		}

        reduivy__Individual_Requirement_Set__c irsWithDeletedIrq = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(1, irsWithDeletedIrq.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsWithDeletedIrq.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsWithDeletedIrq.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        System.runAs(ADMIN_USER){
            undelete targetIrq;
		}

        reduivy__Individual_Requirement_Set__c irsWithUndeletedIrq = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, irsWithUndeletedIrq.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsWithUndeletedIrq.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsWithUndeletedIrq.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for deleting and undeleting irq with active false
     */
    @IsTest
    static void testForDeleteUndelete_ActiveFalse_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //update active to false first
        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];
        targetIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;

        update targetIrq;

        irsGeneral = queryIrs(irsGeneral.Id);

        //validate before delete new irq
        System.Assert.areEqual(1, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');


		System.runAs(ADMIN_USER){
            delete targetIrq;
		}

        reduivy__Individual_Requirement_Set__c irsWithDeletedIrq = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(1, irsWithDeletedIrq.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsWithDeletedIrq.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsWithDeletedIrq.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        System.runAs(ADMIN_USER){
            undelete targetIrq;
		}

        reduivy__Individual_Requirement_Set__c irsWithUndeletedIrq = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(1, irsWithUndeletedIrq.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsWithUndeletedIrq.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsWithUndeletedIrq.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

	
    /**
     * @description Test as admin for deleting and undeleting irq without Parent Irs
     * invalid anymore, as a new validation rule enforces every irq should have a parent irs
     */
    /*@IsTest
    static void testForDeleteUndelete_WithoutParentIrs_AsAdmin() {
		
    }*/


    /**
     * @description Test as admin for creating irq with active true, bulk
     */
    @IsTest
    static void testForBulkCreate_ActiveTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        for(Integer i = 0; i < IRQ_SIZE; i++) {
            reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            irqList.add(newIrq);
        }

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

		System.runAs(ADMIN_USER){
            insert irqList;
		}

        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(12, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for creating irq with active false, bulk
     */
    @IsTest
    static void testForBulkCreate_ActiveFalse_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        for(Integer i = 0; i < IRQ_SIZE; i++) {
            reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            newIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;
            irqList.add(newIrq);
        }
        
        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

		System.runAs(ADMIN_USER){
            insert irqList;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for creating irq without irs parent, bulk
     * invalid anymore, as a new validation rule enforces every irq should have a parent irs
     */
    /*@IsTest
    static void testForBulkCreate_WithoutIrsParent_AsAdmin() {

        
    }*/

    /**
     * @description Test as admin for updating irq to test parent irs to null and not null, bulk
     */
    @IsTest
    static void testForBulkUpdate_ParentIrs_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        System.Assert.areEqual(2, irsLocal.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsLocal.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsLocal.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        

        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];
        targetIrq.reduivy__Individual_Requirement_Set__c = irsLocal.Id;

		System.runAs(ADMIN_USER){
            update targetIrq;
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrsGeneral = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(1, updatedIrsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        reduivy__Individual_Requirement_Set__c updatedIrsLocal = queryIrs(irsLocal.Id);
        System.Assert.areEqual(3, updatedIrsLocal.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrsLocal.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrsLocal.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');


        
        targetIrq.reduivy__Individual_Requirement_Set__c = irsGeneral.Id;
        System.runAs(ADMIN_USER){
            update targetIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrsGeneral2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrsGeneral2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrsGeneral2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrsGeneral2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        reduivy__Individual_Requirement_Set__c updatedIrsLocal2 = queryIrs(irsLocal.Id);
        System.Assert.areEqual(2, updatedIrsLocal2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrsLocal2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrsLocal2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating irq to test active to false and true, bulk
     */
    @IsTest
    static void testForBulkUpdate_Active_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        for(Integer i = 0; i < IRQ_SIZE; i++) {
            reduivy__Individual_Requirement__c targetIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            targetIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
            irqList.add(targetIrq);
        }

		System.runAs(ADMIN_USER){
            insert irqList;
		}
        reduivy__Individual_Requirement_Set__c insertedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(12, insertedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, insertedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, insertedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        for(reduivy__Individual_Requirement__c irq : irqList) {
            irq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;
        }

		System.runAs(ADMIN_USER){
            update irqList;
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        for(reduivy__Individual_Requirement__c irq : irqList) {
            irq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        }

        System.runAs(ADMIN_USER){
            update irqList;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(12, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating irq to test submitted to false and true, bulk
     */
    @IsTest
    static void testForBulkUpdate_Submitted_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        for(Integer i = 0; i < IRQ_SIZE; i++) {
            reduivy__Individual_Requirement__c targetIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            targetIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqList.add(targetIrq);
        }

		System.runAs(ADMIN_USER){
            insert irqList;
		}
        reduivy__Individual_Requirement_Set__c insertedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(12, insertedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, insertedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, insertedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        for(reduivy__Individual_Requirement__c irq : irqList) {
            irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        }

		System.runAs(ADMIN_USER){
            update irqList;
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(12, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(10, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        for(reduivy__Individual_Requirement__c irq : irqList) {
            irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        }

        System.runAs(ADMIN_USER){
            update irqList;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(12, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }

    	
    /**
     * @description Test as admin for updating irq to test submitted to false and true, bulk
     */
    @IsTest
    static void testForBulkUpdate_ReviewStatus_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        for(Integer i = 0; i < IRQ_SIZE; i++) {
            reduivy__Individual_Requirement__c targetIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            targetIrq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED;
            targetIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqList.add(targetIrq);
        }

		System.runAs(ADMIN_USER){
            insert irqList;
		}
        reduivy__Individual_Requirement_Set__c insertedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(12, insertedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(10, insertedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(10, insertedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        for(reduivy__Individual_Requirement__c irq : irqList) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        }

		System.runAs(ADMIN_USER){
            update irqList;
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(12, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(10, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(10, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        for(reduivy__Individual_Requirement__c irq : irqList) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;
            irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        }

        System.runAs(ADMIN_USER){
            update irqList;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(12, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for deleting and undeleting irq with active true, bulk
     */
    @IsTest
    static void testForBulkDeleteUndelete_ActiveTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        for(Integer i = 0; i < IRQ_SIZE; i++) {
            reduivy__Individual_Requirement__c targetIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            irqList.add(targetIrq);
        }

		System.runAs(ADMIN_USER){
            insert irqList;
		}
        reduivy__Individual_Requirement_Set__c insertedIrs = queryIrs(irsGeneral.Id);

        //validate before delete new irq
        System.Assert.areEqual(12, insertedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, insertedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, insertedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

		System.runAs(ADMIN_USER){
            delete irqList;
		}

        reduivy__Individual_Requirement_Set__c irsWithDeletedIrq = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, irsWithDeletedIrq.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsWithDeletedIrq.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsWithDeletedIrq.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        System.runAs(ADMIN_USER){
            undelete irqList;
		}

        reduivy__Individual_Requirement_Set__c irsWithUndeletedIrq = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(12, irsWithUndeletedIrq.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsWithUndeletedIrq.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsWithUndeletedIrq.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for deleting and undeleting irq with active false, bulk
     */
    @IsTest
    static void testForBulkDeleteUndelete_ActiveFalse_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        for(Integer i = 0; i < IRQ_SIZE; i++) {
            reduivy__Individual_Requirement__c targetIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            irqList.add(targetIrq);
        }
        
		System.runAs(ADMIN_USER){
            insert irqList;
		}
        
        irsGeneral = queryIrs(irsGeneral.Id);
        
        System.Assert.areEqual(12, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        //update active to false first
        for(reduivy__Individual_Requirement__c irq : irqList) {
            irq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;
        }

        update irqList;

        reduivy__Individual_Requirement_Set__c irsWithUpdatedDraftIrq = queryIrs(irsGeneral.Id);

        //validate before delete new irq
        System.Assert.areEqual(2, irsWithUpdatedDraftIrq.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsWithUpdatedDraftIrq.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsWithUpdatedDraftIrq.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

		System.runAs(ADMIN_USER){
            delete irqList;
		}

        reduivy__Individual_Requirement_Set__c irsWithDeletedIrq = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, irsWithDeletedIrq.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsWithDeletedIrq.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsWithDeletedIrq.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        System.runAs(ADMIN_USER){
            undelete irqList;
		}

        reduivy__Individual_Requirement_Set__c irsWithUndeletedIrq = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, irsWithUndeletedIrq.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsWithUndeletedIrq.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsWithUndeletedIrq.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

	
    /**
     * @description Test as admin for deleting and undeleting irq without Parent Irs, bulk
     * invalid anymore, as a new validation rule enforces every irq should have a parent irs
     */
    /*@IsTest
    static void testForBulkDeleteUndelete_WithoutParentIrs_AsAdmin() {

    }*/
	
    /**
     * @description Test as faculty for creating irq with active true
     */
    @IsTest
    static void testForCreate_ActiveTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');


		System.runAs(FACULTY_USER){
            insert newIrq;
		}

        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for creating irq with active false
     */
    @IsTest
    static void testForCreate_ActiveFalse_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');


		System.runAs(FACULTY_USER){
            insert newIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);


        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for creating irq without irs parent
     * invalid anymore, as a new validation rule enforces every irq should have a parent irs
     */
    /*@IsTest
    static void testForCreate_WithoutIrsParent_AsFaculty() {
    }*/

    /**
     * @description Test as faculty for updating irq to test parent irs to null and not null
     */
    /*@IsTest
    static void testForUpdate_ParentIrs_AsFaculty() {

    }*/

    /**
     * @description Test as faculty for updating irq to test active to false and true
     */
    @IsTest
    static void testForUpdate_Active_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];
        targetIrq.OwnerId = FACULTY_USER.Id;
        update targetIrq;


        targetIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;

		System.runAs(FACULTY_USER){
            update targetIrq;
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        targetIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        System.runAs(FACULTY_USER){
            update targetIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for updating irq to set submitted to true and false
     */
    @IsTest
    static void testForUpdate_Submitted_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        irsGeneral.reduivy__Individual_Requirements__r[0].OwnerId = FACULTY_USER.Id;
        update irsGeneral.reduivy__Individual_Requirements__r[0];
        
        irsGeneral.reduivy__Individual_Requirements__r[0].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;

		System.runAs(FACULTY_USER){
            update irsGeneral.reduivy__Individual_Requirements__r[0];
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        irsGeneral.reduivy__Individual_Requirements__r[0].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        System.runAs(FACULTY_USER){
            update irsGeneral.reduivy__Individual_Requirements__r[0];
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for updating irq to set review status to Conditionally Accepted, to Accepted and to Open
     */
    @IsTest
    static void testForUpdate_ReviewStatus_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        irsGeneral.reduivy__Individual_Requirements__r[0].OwnerId = FACULTY_USER.Id;
        update irsGeneral.reduivy__Individual_Requirements__r[0];

        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];
        targetIrq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED;
        targetIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;

		System.runAs(FACULTY_USER){
            update targetIrq;
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        targetIrq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;

        System.runAs(FACULTY_USER){
            update targetIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(1, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(1, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        targetIrq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;
        targetIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;

        System.runAs(FACULTY_USER){
            update targetIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs3 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs3.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs3.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs3.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for deleting and undeleting irq with active true
     */
    @IsTest
    static void testForDeleteUndelete_ActiveTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //validate before delete new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];

		System.runAs(FACULTY_USER){
            try{
                delete targetIrq;
                System.Assert.fail('Should be failed with error message: ' + INSUFFICIENT_ACCESS_ERROR_MESSAGE);
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_ACCESS_ERROR_MESSAGE), 'Wrong error message!');
            }
		}

        reduivy__Individual_Requirement_Set__c irsAfterDeleted = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, irsAfterDeleted.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsAfterDeleted.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsAfterDeleted.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
		
    }
	
    /**
     * @description Test as faculty for deleting and undeleting irq with active false
     */
    @IsTest
    static void testForDeleteUndelete_ActiveFalse_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //update active to false first
        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];
        targetIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;

        update targetIrq;

        irsGeneral = queryIrs(irsGeneral.Id);

        //validate before delete new irq
        System.Assert.areEqual(1, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');


		System.runAs(FACULTY_USER){
            try{
                delete targetIrq;
                System.Assert.fail('Should be failed with error message: ' + INSUFFICIENT_ACCESS_ERROR_MESSAGE);
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_ACCESS_ERROR_MESSAGE), 'Wrong error message!');
            }
		}

        reduivy__Individual_Requirement_Set__c irsAfterDeleted = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(1, irsAfterDeleted.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsAfterDeleted.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsAfterDeleted.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
		
        Test.stopTest();
		
    }

	
    /**
     * @description Test as faculty for deleting and undeleting irq without Parent Irs
     * invalid anymore, as a new validation rule enforces every irq should have a parent irs
     */
    /*@IsTest
    static void testForDeleteUndelete_WithoutParentIrs_AsFaculty() {
		
    }*/


	
    /**
     * @description Test as student for creating irq with active true
     */
    @IsTest
    static void testForCreate_ActiveTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');


		System.runAs(studentUser){
            insert newIrq;
		}

        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for creating irq with active false
     */
    @IsTest
    static void testForCreate_ActiveFalse_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');


		System.runAs(studentUser){
            insert newIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for creating irq without irs parent
     * invalid anymore, as a new validation rule enforces every irq should have a parent irs
     */
    /*@IsTest
    static void testForCreate_WithoutIrsParent_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, null, studentUser.Id);

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');


		System.runAs(studentUser){
            insert newIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        Test.stopTest();
		
    }*/

    /**
     * @description Test as student for updating irq to test parent irs to null and not null
     * invalid anymore, as a new validation rule enforces every irq should have a parent irs
     */
    /*@IsTest
    static void testForUpdate_ParentIrs_AsStudent() {

    }*/

    /**
     * @description Test as student for updating irq to test active to false and true
     */
    @IsTest
    static void testForUpdate_Active_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        irsGeneral.reduivy__Individual_Requirements__r[0].OwnerId = studentUser.Id;
        update irsGeneral.reduivy__Individual_Requirements__r[0];

        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];
        targetIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;

		System.runAs(studentUser){
            update targetIrq;
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        targetIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        System.runAs(studentUser){
            update targetIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for updating irq to set submitted to true and false
     */
    @IsTest
    static void testForUpdate_Submitted_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        irsGeneral.reduivy__Individual_Requirements__r[0].OwnerId = studentUser.Id;
        update irsGeneral.reduivy__Individual_Requirements__r[0];
        
        irsGeneral.reduivy__Individual_Requirements__r[0].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;

		System.runAs(studentUser){
            update irsGeneral.reduivy__Individual_Requirements__r[0];
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        irsGeneral.reduivy__Individual_Requirements__r[0].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        System.runAs(studentUser){
            update irsGeneral.reduivy__Individual_Requirements__r[0];
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for updating irq to set review status to Conditionally Accepted, to Accepted and to Open
     */
    @IsTest
    static void testForUpdate_ReviewStatus_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //validate before insert new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        irsGeneral.reduivy__Individual_Requirements__r[0].OwnerId = studentUser.Id;
        update irsGeneral.reduivy__Individual_Requirements__r[0];

        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];
        targetIrq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED;
        targetIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;

		System.runAs(studentUser){
            update targetIrq;
		}
        
        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        targetIrq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;

        System.runAs(studentUser){
            update targetIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs2 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs2.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(1, updatedIrs2.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(1, updatedIrs2.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        targetIrq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;
        targetIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;

        System.runAs(studentUser){
            update targetIrq;
		}

        reduivy__Individual_Requirement_Set__c updatedIrs3 = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, updatedIrs3.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, updatedIrs3.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, updatedIrs3.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for deleting and undeleting irq with active true
     */
    @IsTest
    static void testForDeleteUndelete_ActiveTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //validate before delete new irq
        System.Assert.areEqual(2, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];

		System.runAs(studentUser){
            try{
                delete targetIrq;
                System.Assert.fail('Should be failed with error message: ' + INSUFFICIENT_ACCESS_ERROR_MESSAGE);
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_ACCESS_ERROR_MESSAGE), 'Wrong error message!');
            }
		}
        reduivy__Individual_Requirement_Set__c irsAfterDeleted = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(2, irsAfterDeleted.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsAfterDeleted.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsAfterDeleted.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
		
        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for deleting and undeleting irq with active false
     */
    @IsTest
    static void testForDeleteUndelete_ActiveFalse_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();

        //update active to false first
        reduivy__Individual_Requirement__c targetIrq = irsGeneral.reduivy__Individual_Requirements__r[0];
        targetIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;

        update targetIrq;

        irsGeneral = queryIrs(irsGeneral.Id);

        //validate before delete new irq
        System.Assert.areEqual(1, irsGeneral.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsGeneral.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');

		System.runAs(studentUser){
            try{
                delete targetIrq;
                System.Assert.fail('Should be failed with error message: ' + INSUFFICIENT_ACCESS_ERROR_MESSAGE);
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().contains(INSUFFICIENT_ACCESS_ERROR_MESSAGE), 'Wrong error message!');
            }
		}
        reduivy__Individual_Requirement_Set__c irsAfterDeleted = queryIrs(irsGeneral.Id);

        System.Assert.areEqual(1, irsAfterDeleted.reduivy__Total_Requirement__c, 'Wrong reduivy__Total_Requirement__c!');
        System.Assert.areEqual(0, irsAfterDeleted.reduivy__Total_Reviewed__c, 'Wrong reduivy__Total_Reviewed__c!');
        System.Assert.areEqual(0, irsAfterDeleted.reduivy__Total_Submitted__c, 'Wrong reduivy__Total_Submitted__c!');
		
        Test.stopTest();
		
    }

    /**
     * @description Test creating IRQs with different visibility settings
     */
    @IsTest
    static void testForCreate_DifferentVisibilities_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create IRQs with different visibilities
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Admin visibility (visible to Admin only)
        reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        irqList.add(irqAdmin);
        
        // Faculty visibility (visible to Admin and Faculty)
        reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        irqList.add(irqFaculty);
        
        // Student visibility (visible to Admin, Faculty, and Student)
        reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqList.add(irqStudent);

        System.runAs(ADMIN_USER){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all (2 existing + 3 new = 5)
        System.Assert.areEqual(5, updatedIrs.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c!');
        
        // Faculty sees Faculty and Student (1 Faculty + 1 Student + 1 Existing Student = 3)
        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c!');
        
        // Student sees only Student (1 Student + 1 Existing Student = 2)
        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test updating IRQ visibility and verify rollup changes
     */
    @IsTest
    static void testForUpdate_ChangeVisibility_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        List<reduivy__Individual_Requirement__c> targetIrq = new List<reduivy__Individual_Requirement__c>();
        for(reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
            // Initially set to Admin visibility
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;

            targetIrq.add(irq);
        }
        
        
        System.runAs(ADMIN_USER){
            update targetIrq;
        }
        
        reduivy__Individual_Requirement_Set__c irsAfterAdmin = queryIrs(irsGeneral.Id);
        
        System.Assert.areEqual(2, irsAfterAdmin.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c!');
        System.Assert.areEqual(0, irsAfterAdmin.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c after Admin!');
        System.Assert.areEqual(0, irsAfterAdmin.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c after Admin!');
        
        for(reduivy__Individual_Requirement__c irq : targetIrq) {
            // Change to Faculty visibility
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        }
        
        System.runAs(ADMIN_USER){
            update targetIrq;
        }
        
        reduivy__Individual_Requirement_Set__c irsAfterFaculty = queryIrs(irsGeneral.Id);
        
        System.Assert.areEqual(2, irsAfterFaculty.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c!');
        System.Assert.areEqual(2, irsAfterFaculty.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c after Faculty!');
        System.Assert.areEqual(0, irsAfterFaculty.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c after Faculty!');
        
        for(reduivy__Individual_Requirement__c irq : targetIrq) {
            // Change to Student visibility
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        }
        
        System.runAs(ADMIN_USER){
            update targetIrq;
        }
        
        reduivy__Individual_Requirement_Set__c irsAfterStudent = queryIrs(irsGeneral.Id);
        
        System.Assert.areEqual(2, irsAfterStudent.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c!');
        System.Assert.areEqual(2, irsAfterStudent.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c after Student!');
        System.Assert.areEqual(2, irsAfterStudent.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c after Student!');

        Test.stopTest();
    }

    /**
     * @description Test reviewed counts with different visibilities
     */
    @IsTest
    static void testForCreate_ReviewedWithVisibility_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Create Admin visibility IRQ
        reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        irqAdmin.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqList.add(irqAdmin);
        
        // Create Faculty visibility IRQ
        reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        irqFaculty.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqList.add(irqFaculty);
        
        // Create Student visibility IRQ
        reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqStudent.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqList.add(irqStudent);

        System.runAs(ADMIN_USER){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all reviewed (3 new reviewed)
        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong Total_Reviewed__c!');
        
        // Faculty sees Faculty and Student reviewed (2 reviewed)
        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Reviewed_Faculty__c, 'Wrong Total_Reviewed_Faculty__c!');
        
        // Student sees only Student reviewed (1 reviewed)
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Reviewed_Student__c, 'Wrong Total_Reviewed_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test submitted counts with different visibilities
     */
    @IsTest
    static void testForCreate_SubmittedWithVisibility_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        delete irsGeneral.reduivy__Individual_Requirements__r;

        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Create multiple IRQs with different visibilities, all submitted
        for(Integer i = 0; i < 3; i++) {
            reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            irqAdmin.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqAdmin.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;
            irqList.add(irqAdmin);
            
            reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
            irqFaculty.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqFaculty.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;
            irqList.add(irqFaculty);
            
            reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
            irqStudent.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqStudent.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;
            irqList.add(irqStudent);
        }

        System.runAs(ADMIN_USER){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all submitted (9 new)
        System.Assert.areEqual(9, updatedIrs.reduivy__Total_Submitted__c, 'Wrong Total_Submitted__c!');
        
        // Faculty sees Faculty and Student submitted (3 Faculty + 3 Student = 6)
        System.Assert.areEqual(6, updatedIrs.reduivy__Total_Submitted_Faculty__c, 'Wrong Total_Submitted_Faculty__c!');
        
        // Student sees only Student submitted (3 Student)
        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Submitted_Student__c, 'Wrong Total_Submitted_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test bulk operations with mixed visibilities
     */
    @IsTest
    static void testForBulk_MixedVisibilities_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Create 30 IRQs with rotating visibilities
        for(Integer i = 0; i < 30; i++) {
            reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            
            if(Math.mod(i, 3) == 0) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            } else if(Math.mod(i, 3) == 1) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
            } else {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
            }
            
            irqList.add(irq);
        }

        System.runAs(ADMIN_USER){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all (2 existing + 30 new = 32)
        System.Assert.areEqual(32, updatedIrs.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c!');
        
        // Faculty sees Faculty and Student (10 Faculty + 10 Student + 1 Existing Student = 20)
        System.Assert.areEqual(21, updatedIrs.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c!');
        
        // Student sees only Student (10 Student + 1 Existing Student = 11)
        System.Assert.areEqual(11, updatedIrs.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test delete with different visibilities
     */
    @IsTest
    static void testForDelete_DifferentVisibilities_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create IRQs with different visibilities
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        irqList.add(irqAdmin);
        
        reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        irqList.add(irqFaculty);
        
        reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqList.add(irqStudent);

        System.runAs(ADMIN_USER){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c irsBeforeDelete = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(5, irsBeforeDelete.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c before delete!');

        // Delete the Faculty visibility IRQ
        System.runAs(ADMIN_USER){
            delete irqFaculty;
        }

        reduivy__Individual_Requirement_Set__c irsAfterDelete = queryIrs(irsGeneral.Id);

        // Admin still sees 4 (1 deleted)
        System.Assert.areEqual(4, irsAfterDelete.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c after delete!');
        
        // Faculty sees only Student now (1 + 1 Existing Student)
        System.Assert.areEqual(2, irsAfterDelete.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c after delete!');
        
        // Student still sees 1 + 1 Existing Student 
        System.Assert.areEqual(2, irsAfterDelete.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c after delete!');

        Test.stopTest();
    }

    /**
     * @description Test changing visibility from Student to Admin (decrements Faculty and Student counts)
     */
    @IsTest
    static void testForUpdate_StudentToAdmin_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;

        System.runAs(ADMIN_USER){
            insert irq;
        }

        reduivy__Individual_Requirement_Set__c irsBeforeUpdate = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(1, irsBeforeUpdate.reduivy__Total_Reviewed_Faculty__c, 'Wrong Total_Reviewed_Faculty__c before update!');
        System.Assert.areEqual(1, irsBeforeUpdate.reduivy__Total_Reviewed_Student__c, 'Wrong Total_Reviewed_Student__c before update!');
        
        // Change to Admin visibility
        irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        
        System.runAs(ADMIN_USER){
            update irq;
        }

        reduivy__Individual_Requirement_Set__c irsAfterUpdate = queryIrs(irsGeneral.Id);
        
        // Admin count stays the same (1)
        System.Assert.areEqual(1, irsAfterUpdate.reduivy__Total_Reviewed__c, 'Wrong Total_Reviewed__c after update!');
        
        // Faculty and Student counts should decrement (0)
        System.Assert.areEqual(0, irsAfterUpdate.reduivy__Total_Reviewed_Faculty__c, 'Wrong Total_Reviewed_Faculty__c after update!');
        System.Assert.areEqual(0, irsAfterUpdate.reduivy__Total_Reviewed_Student__c, 'Wrong Total_Reviewed_Student__c after update!');

        Test.stopTest();
    }

    /**
     * @description Test as admin for moving irq between IRS with different visibility scenarios
     */
    @IsTest
    static void testForUpdate_MoveIrqBetweenIrs_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create an IRQ with Student visibility in irsGeneral
        reduivy__Individual_Requirement__c irqToMove = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        irqToMove.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqToMove.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqToMove.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        
        System.runAs(ADMIN_USER){
            insert irqToMove;
        }
        
        // Validate initial state of irsGeneral (2 existing + 1 new = 3)
        reduivy__Individual_Requirement_Set__c irsGeneralBefore = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(3, irsGeneralBefore.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Reviewed__c, 'Wrong irsGeneral Total_Reviewed__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Submitted__c, 'Wrong irsGeneral Total_Submitted__c before move!');
        System.Assert.areEqual(2, irsGeneralBefore.reduivy__Total_Requirement_Faculty__c, 'Wrong irsGeneral Total_Requirement_Faculty__c before move!');
        System.Assert.areEqual(2, irsGeneralBefore.reduivy__Total_Requirement_Student__c, 'Wrong irsGeneral Total_Requirement_Student__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsGeneral Total_Reviewed_Faculty__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Reviewed_Student__c, 'Wrong irsGeneral Total_Reviewed_Student__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Submitted_Faculty__c, 'Wrong irsGeneral Total_Submitted_Faculty__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Submitted_Student__c, 'Wrong irsGeneral Total_Submitted_Student__c before move!');
        
        // Validate initial state of irsLocal (2 existing)
        reduivy__Individual_Requirement_Set__c irsLocalBefore = queryIrs(irsLocal.Id);
        System.Assert.areEqual(2, irsLocalBefore.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c before move!');
        System.Assert.areEqual(0, irsLocalBefore.reduivy__Total_Reviewed__c, 'Wrong irsLocal Total_Reviewed__c before move!');
        System.Assert.areEqual(0, irsLocalBefore.reduivy__Total_Submitted__c, 'Wrong irsLocal Total_Submitted__c before move!');
        System.Assert.areEqual(1, irsLocalBefore.reduivy__Total_Requirement_Faculty__c, 'Wrong irsLocal Total_Requirement_Faculty__c before move!');
        System.Assert.areEqual(1, irsLocalBefore.reduivy__Total_Requirement_Student__c, 'Wrong irsLocal Total_Requirement_Student__c before move!');
        
        // Move the IRQ from irsGeneral to irsLocal
        irqToMove.reduivy__Individual_Requirement_Set__c = irsLocal.Id;
        
        System.runAs(ADMIN_USER){
            update irqToMove;
        }
        
        // Validate irsGeneral after move (should decrease by 1)
        reduivy__Individual_Requirement_Set__c irsGeneralAfter = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(2, irsGeneralAfter.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed__c, 'Wrong irsGeneral Total_Reviewed__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted__c, 'Wrong irsGeneral Total_Submitted__c after move!');
        System.Assert.areEqual(1, irsGeneralAfter.reduivy__Total_Requirement_Faculty__c, 'Wrong irsGeneral Total_Requirement_Faculty__c after move!');
        System.Assert.areEqual(1, irsGeneralAfter.reduivy__Total_Requirement_Student__c, 'Wrong irsGeneral Total_Requirement_Student__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsGeneral Total_Reviewed_Faculty__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed_Student__c, 'Wrong irsGeneral Total_Reviewed_Student__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted_Faculty__c, 'Wrong irsGeneral Total_Submitted_Faculty__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted_Student__c, 'Wrong irsGeneral Total_Submitted_Student__c after move!');
        
        // Validate irsLocal after move (should increase by 1)
        reduivy__Individual_Requirement_Set__c irsLocalAfter = queryIrs(irsLocal.Id);
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Reviewed__c, 'Wrong irsLocal Total_Reviewed__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Submitted__c, 'Wrong irsLocal Total_Submitted__c after move!');
        System.Assert.areEqual(2, irsLocalAfter.reduivy__Total_Requirement_Faculty__c, 'Wrong irsLocal Total_Requirement_Faculty__c after move!');
        System.Assert.areEqual(2, irsLocalAfter.reduivy__Total_Requirement_Student__c, 'Wrong irsLocal Total_Requirement_Student__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsLocal Total_Reviewed_Faculty__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Reviewed_Student__c, 'Wrong irsLocal Total_Reviewed_Student__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Submitted_Faculty__c, 'Wrong irsLocal Total_Submitted_Faculty__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Submitted_Student__c, 'Wrong irsLocal Total_Submitted_Student__c after move!');
        
        Test.stopTest();
    }

    /**
     * @description Test bulk move of IRQs between IRS with mixed visibilities as admin
     */
    @IsTest
    static void testForBulkUpdate_MoveIrqsBetweenIrs_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create 10 IRQs with different visibilities in irsGeneral
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        for(Integer i = 0; i < 10; i++) {
            reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
            
            // Rotate visibilities: Admin, Faculty, Student
            if(Math.mod(i, 3) == 0) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            } else if(Math.mod(i, 3) == 1) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            } else {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            
            irqList.add(irq);
        }
        
        System.runAs(ADMIN_USER){
            insert irqList;
        }
        
        // Validate initial state of irsGeneral (2 existing + 10 new = 12)
        reduivy__Individual_Requirement_Set__c irsGeneralBefore = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(12, irsGeneralBefore.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c before move!');
        
        // Validate initial state of irsLocal (2 existing)
        reduivy__Individual_Requirement_Set__c irsLocalBefore = queryIrs(irsLocal.Id);
        System.Assert.areEqual(2, irsLocalBefore.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c before move!');
        
        // Move all 10 IRQs from irsGeneral to irsLocal
        for(reduivy__Individual_Requirement__c irq : irqList) {
            irq.reduivy__Individual_Requirement_Set__c = irsLocal.Id;
        }
        
        System.runAs(ADMIN_USER){
            update irqList;
        }
        
        // Validate irsGeneral after move (should be back to 2)
        reduivy__Individual_Requirement_Set__c irsGeneralAfter = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(2, irsGeneralAfter.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed__c, 'Wrong irsGeneral Total_Reviewed__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted__c, 'Wrong irsGeneral Total_Submitted__c after move!');
        
        reduivy__Individual_Requirement_Set__c irsLocalAfter = queryIrs(irsLocal.Id);
        System.Assert.areEqual(12, irsLocalAfter.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c after move!');
        System.Assert.areEqual(7, irsLocalAfter.reduivy__Total_Requirement_Faculty__c, 'Wrong irsLocal Total_Requirement_Faculty__c after move!');
        System.Assert.areEqual(4, irsLocalAfter.reduivy__Total_Requirement_Student__c, 'Wrong irsLocal Total_Requirement_Student__c after move!');
        
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Reviewed__c, 'Wrong irsLocal Total_Reviewed__c after move!');
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsLocal Total_Reviewed_Faculty__c after move!');
        System.Assert.areEqual(0, irsLocalAfter.reduivy__Total_Reviewed_Student__c, 'Wrong irsLocal reduivy__Total_Reviewed_Student__c after move!');
        
        System.Assert.areEqual(6, irsLocalAfter.reduivy__Total_Submitted__c, 'Wrong irsLocal Total_Submitted__c after move!');
        System.Assert.areEqual(6, irsLocalAfter.reduivy__Total_Submitted_Faculty__c, 'Wrong irsLocal reduivy__Total_Submitted_Faculty__c after move!');
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Submitted_Student__c, 'Wrong irsLocal Total_Submitted_Student__c after move!');
        
        Test.stopTest();
    }

    /**
     * @description Test creating IRQs with different visibility settings
     */
    @IsTest
    static void testForCreate_DifferentVisibilities_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create IRQs with different visibilities
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Admin visibility (visible to Admin only)
        reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        irqList.add(irqAdmin);
        
        // Faculty visibility (visible to Admin and Faculty)
        reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        irqList.add(irqFaculty);
        
        // Student visibility (visible to Admin, Faculty, and Student)
        reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqList.add(irqStudent);

        System.runAs(FACULTY_USER){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all (2 existing + 3 new = 5)
        System.Assert.areEqual(5, updatedIrs.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c!');
        
        // Faculty sees Faculty and Student (1 Faculty + 1 Student + 1 Existing Student = 3)
        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c!');
        
        // Student sees only Student (1 Student + 1 Existing Student = 2)
        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test reviewed counts with different visibilities
     */
    @IsTest
    static void testForCreate_ReviewedWithVisibility_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Create Admin visibility IRQ
        reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        irqAdmin.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqList.add(irqAdmin);
        
        // Create Faculty visibility IRQ
        reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        irqFaculty.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqList.add(irqFaculty);
        
        // Create Student visibility IRQ
        reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqStudent.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqList.add(irqStudent);

        System.runAs(FACULTY_USER){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all reviewed (3 new reviewed)
        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong Total_Reviewed__c!');
        
        // Faculty sees Faculty and Student reviewed (2 reviewed)
        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Reviewed_Faculty__c, 'Wrong Total_Reviewed_Faculty__c!');
        
        // Student sees only Student reviewed (1 reviewed)
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Reviewed_Student__c, 'Wrong Total_Reviewed_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test submitted counts with different visibilities
     */
    @IsTest
    static void testForCreate_SubmittedWithVisibility_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        delete irsGeneral.reduivy__Individual_Requirements__r;

        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Create multiple IRQs with different visibilities, all submitted
        for(Integer i = 0; i < 3; i++) {
            reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
            irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            irqAdmin.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqAdmin.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;
            irqList.add(irqAdmin);
            
            reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
            irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
            irqFaculty.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqFaculty.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;
            irqList.add(irqFaculty);
            
            reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
            irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
            irqStudent.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqStudent.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;
            irqList.add(irqStudent);
        }

        System.runAs(FACULTY_USER){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all submitted (9 new)
        System.Assert.areEqual(9, updatedIrs.reduivy__Total_Submitted__c, 'Wrong Total_Submitted__c!');
        
        // Faculty sees Faculty and Student submitted (3 Faculty + 3 Student = 6)
        System.Assert.areEqual(6, updatedIrs.reduivy__Total_Submitted_Faculty__c, 'Wrong Total_Submitted_Faculty__c!');
        
        // Student sees only Student submitted (3 Student)
        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Submitted_Student__c, 'Wrong Total_Submitted_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test bulk operations with mixed visibilities
     */
    @IsTest
    static void testForBulk_MixedVisibilities_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Create 30 IRQs with rotating visibilities
        for(Integer i = 0; i < 30; i++) {
            reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
            
            if(Math.mod(i, 3) == 0) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            } else if(Math.mod(i, 3) == 1) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
            } else {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
            }
            
            irqList.add(irq);
        }

        System.runAs(FACULTY_USER){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all (2 existing + 30 new = 32)
        System.Assert.areEqual(32, updatedIrs.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c!');
        
        // Faculty sees Faculty and Student (10 Faculty + 10 Student + 1 Existing Student = 20)
        System.Assert.areEqual(21, updatedIrs.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c!');
        
        // Student sees only Student (10 Student + 1 Existing Student = 11)
        System.Assert.areEqual(11, updatedIrs.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test delete with different visibilities
     */
    @IsTest
    static void testForDelete_DifferentVisibilities_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create IRQs with different visibilities
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        irqList.add(irqAdmin);
        
        reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        irqList.add(irqFaculty);
        
        reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqList.add(irqStudent);

        System.runAs(FACULTY_USER){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c irsBeforeDelete = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(5, irsBeforeDelete.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c before delete!');

        // Delete the Faculty visibility IRQ
        System.runAs(FACULTY_USER){
            delete irqFaculty;
        }

        reduivy__Individual_Requirement_Set__c irsAfterDelete = queryIrs(irsGeneral.Id);

        // Admin still sees 4 (1 deleted)
        System.Assert.areEqual(4, irsAfterDelete.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c after delete!');
        
        // Faculty sees only Student now (1 + 1 Existing Student)
        System.Assert.areEqual(2, irsAfterDelete.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c after delete!');
        
        // Student still sees 1 + 1 Existing Student 
        System.Assert.areEqual(2, irsAfterDelete.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c after delete!');

        Test.stopTest();
    }

    /**
     * @description Test changing visibility from Student to Admin (decrements Faculty and Student counts)
     */
    @IsTest
    static void testForUpdate_StudentToAdmin_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;

        System.runAs(FACULTY_USER){
            insert irq;
        }

        reduivy__Individual_Requirement_Set__c irsBeforeUpdate = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(1, irsBeforeUpdate.reduivy__Total_Reviewed_Faculty__c, 'Wrong Total_Reviewed_Faculty__c before update!');
        System.Assert.areEqual(1, irsBeforeUpdate.reduivy__Total_Reviewed_Student__c, 'Wrong Total_Reviewed_Student__c before update!');
        
        // Change to Admin visibility
        irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        
        System.runAs(FACULTY_USER){
            update irq;
        }

        reduivy__Individual_Requirement_Set__c irsAfterUpdate = queryIrs(irsGeneral.Id);
        
        // Admin count stays the same (1)
        System.Assert.areEqual(1, irsAfterUpdate.reduivy__Total_Reviewed__c, 'Wrong Total_Reviewed__c after update!');
        
        // Faculty and Student counts should decrement (0)
        System.Assert.areEqual(0, irsAfterUpdate.reduivy__Total_Reviewed_Faculty__c, 'Wrong Total_Reviewed_Faculty__c after update!');
        System.Assert.areEqual(0, irsAfterUpdate.reduivy__Total_Reviewed_Student__c, 'Wrong Total_Reviewed_Student__c after update!');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for moving irq between IRS with different visibility scenarios
     */
    @IsTest
    static void testForUpdate_MoveIrqBetweenIrs_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create an IRQ with Student visibility in irsGeneral
        reduivy__Individual_Requirement__c irqToMove = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        irqToMove.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqToMove.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqToMove.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        
        System.runAs(FACULTY_USER){
            insert irqToMove;
        }
        
        // Validate initial state of irsGeneral (2 existing + 1 new = 3)
        reduivy__Individual_Requirement_Set__c irsGeneralBefore = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(3, irsGeneralBefore.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Reviewed__c, 'Wrong irsGeneral Total_Reviewed__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Submitted__c, 'Wrong irsGeneral Total_Submitted__c before move!');
        System.Assert.areEqual(2, irsGeneralBefore.reduivy__Total_Requirement_Faculty__c, 'Wrong irsGeneral Total_Requirement_Faculty__c before move!');
        System.Assert.areEqual(2, irsGeneralBefore.reduivy__Total_Requirement_Student__c, 'Wrong irsGeneral Total_Requirement_Student__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsGeneral Total_Reviewed_Faculty__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Reviewed_Student__c, 'Wrong irsGeneral Total_Reviewed_Student__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Submitted_Faculty__c, 'Wrong irsGeneral Total_Submitted_Faculty__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Submitted_Student__c, 'Wrong irsGeneral Total_Submitted_Student__c before move!');
        
        // Validate initial state of irsLocal (2 existing)
        reduivy__Individual_Requirement_Set__c irsLocalBefore = queryIrs(irsLocal.Id);
        System.Assert.areEqual(2, irsLocalBefore.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c before move!');
        System.Assert.areEqual(0, irsLocalBefore.reduivy__Total_Reviewed__c, 'Wrong irsLocal Total_Reviewed__c before move!');
        System.Assert.areEqual(0, irsLocalBefore.reduivy__Total_Submitted__c, 'Wrong irsLocal Total_Submitted__c before move!');
        System.Assert.areEqual(1, irsLocalBefore.reduivy__Total_Requirement_Faculty__c, 'Wrong irsLocal Total_Requirement_Faculty__c before move!');
        System.Assert.areEqual(1, irsLocalBefore.reduivy__Total_Requirement_Student__c, 'Wrong irsLocal Total_Requirement_Student__c before move!');
        
        // Move the IRQ from irsGeneral to irsLocal
        irqToMove.reduivy__Individual_Requirement_Set__c = irsLocal.Id;
        
        System.runAs(FACULTY_USER){
            update irqToMove;
        }
        
        // Validate irsGeneral after move (should decrease by 1)
        reduivy__Individual_Requirement_Set__c irsGeneralAfter = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(2, irsGeneralAfter.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed__c, 'Wrong irsGeneral Total_Reviewed__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted__c, 'Wrong irsGeneral Total_Submitted__c after move!');
        System.Assert.areEqual(1, irsGeneralAfter.reduivy__Total_Requirement_Faculty__c, 'Wrong irsGeneral Total_Requirement_Faculty__c after move!');
        System.Assert.areEqual(1, irsGeneralAfter.reduivy__Total_Requirement_Student__c, 'Wrong irsGeneral Total_Requirement_Student__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsGeneral Total_Reviewed_Faculty__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed_Student__c, 'Wrong irsGeneral Total_Reviewed_Student__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted_Faculty__c, 'Wrong irsGeneral Total_Submitted_Faculty__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted_Student__c, 'Wrong irsGeneral Total_Submitted_Student__c after move!');
        
        // Validate irsLocal after move (should increase by 1)
        reduivy__Individual_Requirement_Set__c irsLocalAfter = queryIrs(irsLocal.Id);
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Reviewed__c, 'Wrong irsLocal Total_Reviewed__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Submitted__c, 'Wrong irsLocal Total_Submitted__c after move!');
        System.Assert.areEqual(2, irsLocalAfter.reduivy__Total_Requirement_Faculty__c, 'Wrong irsLocal Total_Requirement_Faculty__c after move!');
        System.Assert.areEqual(2, irsLocalAfter.reduivy__Total_Requirement_Student__c, 'Wrong irsLocal Total_Requirement_Student__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsLocal Total_Reviewed_Faculty__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Reviewed_Student__c, 'Wrong irsLocal Total_Reviewed_Student__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Submitted_Faculty__c, 'Wrong irsLocal Total_Submitted_Faculty__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Submitted_Student__c, 'Wrong irsLocal Total_Submitted_Student__c after move!');
        
        Test.stopTest();
    }

    /**
     * @description Test bulk move of IRQs between IRS with mixed visibilities as faculty
     */
    @IsTest
    static void testForBulkUpdate_MoveIrqsBetweenIrs_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create 10 IRQs with different visibilities in irsGeneral
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        for(Integer i = 0; i < 10; i++) {
            reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
            
            // Rotate visibilities: Admin, Faculty, Student
            if(Math.mod(i, 3) == 0) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            } else if(Math.mod(i, 3) == 1) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            } else {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            
            irqList.add(irq);
        }
        
        System.runAs(FACULTY_USER){
            insert irqList;
        }
        
        // Validate initial state of irsGeneral (2 existing + 10 new = 12)
        reduivy__Individual_Requirement_Set__c irsGeneralBefore = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(12, irsGeneralBefore.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c before move!');
        
        // Validate initial state of irsLocal (2 existing)
        reduivy__Individual_Requirement_Set__c irsLocalBefore = queryIrs(irsLocal.Id);
        System.Assert.areEqual(2, irsLocalBefore.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c before move!');
        
        // Move all 10 IRQs from irsGeneral to irsLocal
        for(reduivy__Individual_Requirement__c irq : irqList) {
            irq.reduivy__Individual_Requirement_Set__c = irsLocal.Id;
        }
        
        System.runAs(FACULTY_USER){
            update irqList;
        }
        
        // Validate irsGeneral after move (should be back to 2)
        reduivy__Individual_Requirement_Set__c irsGeneralAfter = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(2, irsGeneralAfter.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed__c, 'Wrong irsGeneral Total_Reviewed__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted__c, 'Wrong irsGeneral Total_Submitted__c after move!');
        
        reduivy__Individual_Requirement_Set__c irsLocalAfter = queryIrs(irsLocal.Id);
        System.Assert.areEqual(12, irsLocalAfter.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c after move!');
        System.Assert.areEqual(7, irsLocalAfter.reduivy__Total_Requirement_Faculty__c, 'Wrong irsLocal Total_Requirement_Faculty__c after move!');
        System.Assert.areEqual(4, irsLocalAfter.reduivy__Total_Requirement_Student__c, 'Wrong irsLocal Total_Requirement_Student__c after move!');
        
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Reviewed__c, 'Wrong irsLocal Total_Reviewed__c after move!');
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsLocal Total_Reviewed_Faculty__c after move!');
        System.Assert.areEqual(0, irsLocalAfter.reduivy__Total_Reviewed_Student__c, 'Wrong irsLocal reduivy__Total_Reviewed_Student__c after move!');
        
        System.Assert.areEqual(6, irsLocalAfter.reduivy__Total_Submitted__c, 'Wrong irsLocal Total_Submitted__c after move!');
        System.Assert.areEqual(6, irsLocalAfter.reduivy__Total_Submitted_Faculty__c, 'Wrong irsLocal reduivy__Total_Submitted_Faculty__c after move!');
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Submitted_Student__c, 'Wrong irsLocal Total_Submitted_Student__c after move!');
        
        Test.stopTest();
    }

    /**
     * @description Test creating IRQs with different visibility settings
     */
    @IsTest
    static void testForCreate_DifferentVisibilities_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create IRQs with different visibilities
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Admin visibility (visible to Admin only)
        reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        irqList.add(irqAdmin);
        
        // Faculty visibility (visible to Admin and Faculty)
        reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        irqList.add(irqFaculty);
        
        // Student visibility (visible to Admin, Faculty, and Student)
        reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqList.add(irqStudent);

        System.runAs(studentUser){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all (2 existing + 3 new = 5)
        System.Assert.areEqual(5, updatedIrs.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c!');
        
        // Faculty sees Faculty and Student (1 Faculty + 1 Student + 1 Existing Student = 3)
        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c!');
        
        // Student sees only Student (1 Student + 1 Existing Student = 2)
        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test reviewed counts with different visibilities
     */
    @IsTest
    static void testForCreate_ReviewedWithVisibility_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Create Admin visibility IRQ
        reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        irqAdmin.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqList.add(irqAdmin);
        
        // Create Faculty visibility IRQ
        reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        irqFaculty.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqList.add(irqFaculty);
        
        // Create Student visibility IRQ
        reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqStudent.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqList.add(irqStudent);

        System.runAs(studentUser){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all reviewed (3 new reviewed)
        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Reviewed__c, 'Wrong Total_Reviewed__c!');
        
        // Faculty sees Faculty and Student reviewed (2 reviewed)
        System.Assert.areEqual(2, updatedIrs.reduivy__Total_Reviewed_Faculty__c, 'Wrong Total_Reviewed_Faculty__c!');
        
        // Student sees only Student reviewed (1 reviewed)
        System.Assert.areEqual(1, updatedIrs.reduivy__Total_Reviewed_Student__c, 'Wrong Total_Reviewed_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test submitted counts with different visibilities
     */
    @IsTest
    static void testForCreate_SubmittedWithVisibility_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        delete irsGeneral.reduivy__Individual_Requirements__r;

        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Create multiple IRQs with different visibilities, all submitted
        for(Integer i = 0; i < 3; i++) {
            reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
            irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            irqAdmin.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqAdmin.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;
            irqList.add(irqAdmin);
            
            reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
            irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
            irqFaculty.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqFaculty.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;
            irqList.add(irqFaculty);
            
            reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
            irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
            irqStudent.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqStudent.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;
            irqList.add(irqStudent);
        }

        System.runAs(studentUser){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all submitted (9 new)
        System.Assert.areEqual(9, updatedIrs.reduivy__Total_Submitted__c, 'Wrong Total_Submitted__c!');
        
        // Faculty sees Faculty and Student submitted (3 Faculty + 3 Student = 6)
        System.Assert.areEqual(6, updatedIrs.reduivy__Total_Submitted_Faculty__c, 'Wrong Total_Submitted_Faculty__c!');
        
        // Student sees only Student submitted (3 Student)
        System.Assert.areEqual(3, updatedIrs.reduivy__Total_Submitted_Student__c, 'Wrong Total_Submitted_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test bulk operations with mixed visibilities
     */
    @IsTest
    static void testForBulk_MixedVisibilities_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        // Create 30 IRQs with rotating visibilities
        for(Integer i = 0; i < 30; i++) {
            reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
            
            if(Math.mod(i, 3) == 0) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            } else if(Math.mod(i, 3) == 1) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
            } else {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
            }
            
            irqList.add(irq);
        }

        System.runAs(studentUser){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c updatedIrs = queryIrs(irsGeneral.Id);

        // Admin sees all (2 existing + 30 new = 32)
        System.Assert.areEqual(32, updatedIrs.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c!');
        
        // Faculty sees Faculty and Student (10 Faculty + 10 Student + 1 Existing Student = 20)
        System.Assert.areEqual(21, updatedIrs.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c!');
        
        // Student sees only Student (10 Student + 1 Existing Student = 11)
        System.Assert.areEqual(11, updatedIrs.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c!');

        Test.stopTest();
    }

    /**
     * @description Test delete with different visibilities
     */
    @IsTest
    static void testForDelete_DifferentVisibilities_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create IRQs with different visibilities
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        
        reduivy__Individual_Requirement__c irqAdmin = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irqAdmin.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        irqList.add(irqAdmin);
        
        reduivy__Individual_Requirement__c irqFaculty = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irqFaculty.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        irqList.add(irqFaculty);
        
        reduivy__Individual_Requirement__c irqStudent = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irqStudent.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqList.add(irqStudent);

        System.runAs(studentUser){
            insert irqList;
        }

        reduivy__Individual_Requirement_Set__c irsBeforeDelete = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(5, irsBeforeDelete.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c before delete!');

        // Delete the Faculty visibility IRQ
        System.runAs(studentUser){
            delete irqFaculty;
        }

        reduivy__Individual_Requirement_Set__c irsAfterDelete = queryIrs(irsGeneral.Id);

        // Admin still sees 4 (1 deleted)
        System.Assert.areEqual(4, irsAfterDelete.reduivy__Total_Requirement__c, 'Wrong Total_Requirement__c after delete!');
        
        // Faculty sees only Student now (1 + 1 Existing Student)
        System.Assert.areEqual(2, irsAfterDelete.reduivy__Total_Requirement_Faculty__c, 'Wrong Total_Requirement_Faculty__c after delete!');
        
        // Student still sees 1 + 1 Existing Student 
        System.Assert.areEqual(2, irsAfterDelete.reduivy__Total_Requirement_Student__c, 'Wrong Total_Requirement_Student__c after delete!');

        Test.stopTest();
    }

    /**
     * @description Test changing visibility from Student to Admin (decrements Faculty and Student counts)
     */
    @IsTest
    static void testForUpdate_StudentToAdmin_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;

        System.runAs(studentUser){
            insert irq;
        }

        reduivy__Individual_Requirement_Set__c irsBeforeUpdate = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(1, irsBeforeUpdate.reduivy__Total_Reviewed_Faculty__c, 'Wrong Total_Reviewed_Faculty__c before update!');
        System.Assert.areEqual(1, irsBeforeUpdate.reduivy__Total_Reviewed_Student__c, 'Wrong Total_Reviewed_Student__c before update!');
        
        // Change to Admin visibility
        irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
        
        System.runAs(studentUser){
            update irq;
        }

        reduivy__Individual_Requirement_Set__c irsAfterUpdate = queryIrs(irsGeneral.Id);
        
        // Admin count stays the same (1)
        System.Assert.areEqual(1, irsAfterUpdate.reduivy__Total_Reviewed__c, 'Wrong Total_Reviewed__c after update!');
        
        // Faculty and Student counts should decrement (0)
        System.Assert.areEqual(0, irsAfterUpdate.reduivy__Total_Reviewed_Faculty__c, 'Wrong Total_Reviewed_Faculty__c after update!');
        System.Assert.areEqual(0, irsAfterUpdate.reduivy__Total_Reviewed_Student__c, 'Wrong Total_Reviewed_Student__c after update!');

        Test.stopTest();
    }

    /**
     * @description Test as student for moving irq between IRS with different visibility scenarios
     */
    @IsTest
    static void testForUpdate_MoveIrqBetweenIrs_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create an IRQ with Student visibility in irsGeneral
        reduivy__Individual_Requirement__c irqToMove = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        irqToMove.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        irqToMove.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
        irqToMove.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        
        System.runAs(studentUser){
            insert irqToMove;
        }
        
        // Validate initial state of irsGeneral (2 existing + 1 new = 3)
        reduivy__Individual_Requirement_Set__c irsGeneralBefore = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(3, irsGeneralBefore.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Reviewed__c, 'Wrong irsGeneral Total_Reviewed__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Submitted__c, 'Wrong irsGeneral Total_Submitted__c before move!');
        System.Assert.areEqual(2, irsGeneralBefore.reduivy__Total_Requirement_Faculty__c, 'Wrong irsGeneral Total_Requirement_Faculty__c before move!');
        System.Assert.areEqual(2, irsGeneralBefore.reduivy__Total_Requirement_Student__c, 'Wrong irsGeneral Total_Requirement_Student__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsGeneral Total_Reviewed_Faculty__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Reviewed_Student__c, 'Wrong irsGeneral Total_Reviewed_Student__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Submitted_Faculty__c, 'Wrong irsGeneral Total_Submitted_Faculty__c before move!');
        System.Assert.areEqual(1, irsGeneralBefore.reduivy__Total_Submitted_Student__c, 'Wrong irsGeneral Total_Submitted_Student__c before move!');
        
        // Validate initial state of irsLocal (2 existing)
        reduivy__Individual_Requirement_Set__c irsLocalBefore = queryIrs(irsLocal.Id);
        System.Assert.areEqual(2, irsLocalBefore.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c before move!');
        System.Assert.areEqual(0, irsLocalBefore.reduivy__Total_Reviewed__c, 'Wrong irsLocal Total_Reviewed__c before move!');
        System.Assert.areEqual(0, irsLocalBefore.reduivy__Total_Submitted__c, 'Wrong irsLocal Total_Submitted__c before move!');
        System.Assert.areEqual(1, irsLocalBefore.reduivy__Total_Requirement_Faculty__c, 'Wrong irsLocal Total_Requirement_Faculty__c before move!');
        System.Assert.areEqual(1, irsLocalBefore.reduivy__Total_Requirement_Student__c, 'Wrong irsLocal Total_Requirement_Student__c before move!');
        
        // Move the IRQ from irsGeneral to irsLocal
        irqToMove.reduivy__Individual_Requirement_Set__c = irsLocal.Id;
        
        System.runAs(studentUser){
            update irqToMove;
        }
        
        // Validate irsGeneral after move (should decrease by 1)
        reduivy__Individual_Requirement_Set__c irsGeneralAfter = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(2, irsGeneralAfter.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed__c, 'Wrong irsGeneral Total_Reviewed__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted__c, 'Wrong irsGeneral Total_Submitted__c after move!');
        System.Assert.areEqual(1, irsGeneralAfter.reduivy__Total_Requirement_Faculty__c, 'Wrong irsGeneral Total_Requirement_Faculty__c after move!');
        System.Assert.areEqual(1, irsGeneralAfter.reduivy__Total_Requirement_Student__c, 'Wrong irsGeneral Total_Requirement_Student__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsGeneral Total_Reviewed_Faculty__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed_Student__c, 'Wrong irsGeneral Total_Reviewed_Student__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted_Faculty__c, 'Wrong irsGeneral Total_Submitted_Faculty__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted_Student__c, 'Wrong irsGeneral Total_Submitted_Student__c after move!');
        
        // Validate irsLocal after move (should increase by 1)
        reduivy__Individual_Requirement_Set__c irsLocalAfter = queryIrs(irsLocal.Id);
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Reviewed__c, 'Wrong irsLocal Total_Reviewed__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Submitted__c, 'Wrong irsLocal Total_Submitted__c after move!');
        System.Assert.areEqual(2, irsLocalAfter.reduivy__Total_Requirement_Faculty__c, 'Wrong irsLocal Total_Requirement_Faculty__c after move!');
        System.Assert.areEqual(2, irsLocalAfter.reduivy__Total_Requirement_Student__c, 'Wrong irsLocal Total_Requirement_Student__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsLocal Total_Reviewed_Faculty__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Reviewed_Student__c, 'Wrong irsLocal Total_Reviewed_Student__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Submitted_Faculty__c, 'Wrong irsLocal Total_Submitted_Faculty__c after move!');
        System.Assert.areEqual(1, irsLocalAfter.reduivy__Total_Submitted_Student__c, 'Wrong irsLocal Total_Submitted_Student__c after move!');
        
        Test.stopTest();
    }

    /**
     * @description Test bulk move of IRQs between IRS with mixed visibilities as student
     */
    @IsTest
    static void testForBulkUpdate_MoveIrqsBetweenIrs_AsStudent() {
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        
        // Create 10 IRQs with different visibilities in irsGeneral
        List<reduivy__Individual_Requirement__c> irqList = new List<reduivy__Individual_Requirement__c>();
        for(Integer i = 0; i < 10; i++) {
            reduivy__Individual_Requirement__c irq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
            
            // Rotate visibilities: Admin, Faculty, Student
            if(Math.mod(i, 3) == 0) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            } else if(Math.mod(i, 3) == 1) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            } else {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            
            irqList.add(irq);
        }
        
        System.runAs(studentUser){
            insert irqList;
        }
        
        // Validate initial state of irsGeneral (2 existing + 10 new = 12)
        reduivy__Individual_Requirement_Set__c irsGeneralBefore = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(12, irsGeneralBefore.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c before move!');
        
        // Validate initial state of irsLocal (2 existing)
        reduivy__Individual_Requirement_Set__c irsLocalBefore = queryIrs(irsLocal.Id);
        System.Assert.areEqual(2, irsLocalBefore.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c before move!');
        
        // Move all 10 IRQs from irsGeneral to irsLocal
        for(reduivy__Individual_Requirement__c irq : irqList) {
            irq.reduivy__Individual_Requirement_Set__c = irsLocal.Id;
        }
        
        System.runAs(studentUser){
            update irqList;
        }
        
        // Validate irsGeneral after move (should be back to 2)
        reduivy__Individual_Requirement_Set__c irsGeneralAfter = queryIrs(irsGeneral.Id);
        System.Assert.areEqual(2, irsGeneralAfter.reduivy__Total_Requirement__c, 'Wrong irsGeneral Total_Requirement__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Reviewed__c, 'Wrong irsGeneral Total_Reviewed__c after move!');
        System.Assert.areEqual(0, irsGeneralAfter.reduivy__Total_Submitted__c, 'Wrong irsGeneral Total_Submitted__c after move!');
        
        reduivy__Individual_Requirement_Set__c irsLocalAfter = queryIrs(irsLocal.Id);
        System.Assert.areEqual(12, irsLocalAfter.reduivy__Total_Requirement__c, 'Wrong irsLocal Total_Requirement__c after move!');
        System.Assert.areEqual(7, irsLocalAfter.reduivy__Total_Requirement_Faculty__c, 'Wrong irsLocal Total_Requirement_Faculty__c after move!');
        System.Assert.areEqual(4, irsLocalAfter.reduivy__Total_Requirement_Student__c, 'Wrong irsLocal Total_Requirement_Student__c after move!');
        
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Reviewed__c, 'Wrong irsLocal Total_Reviewed__c after move!');
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Reviewed_Faculty__c, 'Wrong irsLocal Total_Reviewed_Faculty__c after move!');
        System.Assert.areEqual(0, irsLocalAfter.reduivy__Total_Reviewed_Student__c, 'Wrong irsLocal reduivy__Total_Reviewed_Student__c after move!');
        
        System.Assert.areEqual(6, irsLocalAfter.reduivy__Total_Submitted__c, 'Wrong irsLocal Total_Submitted__c after move!');
        System.Assert.areEqual(6, irsLocalAfter.reduivy__Total_Submitted_Faculty__c, 'Wrong irsLocal reduivy__Total_Submitted_Faculty__c after move!');
        System.Assert.areEqual(3, irsLocalAfter.reduivy__Total_Submitted_Student__c, 'Wrong irsLocal Total_Submitted_Student__c after move!');
        
        Test.stopTest();
    }

    static void setSrqList() {
        for(reduivy__Study_Requirement__c srq : [
            SELECT Id, Name, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Due_Days__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, reduivy__Sample_Record_Code__c, reduivy__File_Category__c, reduivy__File_Visibility__c, reduivy__File_Format__c, reduivy__File_Count__c, reduivy__File_Share_Type__c, reduivy__Create_Salesforce_Task__c, reduivy__Priority__c, reduivy__Task_Owner_Id__c, reduivy__Requirement_Type__c, reduivy__Object_Relation_Field__c, reduivy__Object_Fields__c, reduivy__Link_To_Individual_Achievement__c, reduivy__Translation_Map__c
            FROM reduivy__Study_Requirement__c
            WHERE reduivy__Sample_Record_Code__c IN (:SRQ_LOCAL, :SRQ_GENERAL)
        ]) {
            if(srq.reduivy__Sample_Record_Code__c == SRQ_LOCAL) {
                srqLocal = srq;
            }  else if(srq.reduivy__Sample_Record_Code__c == SRQ_GENERAL) {
                srqGeneral = srq;
            }
        }
    }

    static void setIrsList(){
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, reduivy__Status__c, reduivy__Code__c, reduivy__Description__c, reduivy__Study_Requirement_Set__c, reduivy__Total_Requirement__c, reduivy__Total_Reviewed__c, reduivy__Total_Submitted__c, reduivy__Sample_Record_Code__c, OwnerId, 
            (
                SELECT Id, Name, reduivy__Status__c, reduivy__Acceptance_Notes__c, reduivy__Due_Date__c, reduivy__Individual_Requirement_Set__c, reduivy__Code__c, reduivy__Requirement_Details__c, reduivy__Study_Requirement__c, reduivy__Requirement_Visibility__c, reduivy__Sequence__c, OwnerId, reduivy__Object_Relation_Field__c, reduivy__Object_Fields__c, reduivy__Link_To_Individual_Achievement__c
                FROM reduivy__Individual_Requirements__r
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c IN (:IRS_LOCAL, :IRS_GENERAL)
        ]) {
            if(irs.reduivy__Sample_Record_Code__c == IRS_LOCAL) {
                irsLocal = irs;
            } else if(irs.reduivy__Sample_Record_Code__c == IRS_GENERAL) {
                irsGeneral = irs;
            }
        }
    }

    static reduivy__Individual_Requirement_Set__c queryIrs(Id irsId) {
        return [
            SELECT Id, Name, reduivy__Status__c, reduivy__Code__c, reduivy__Description__c, reduivy__Study_Requirement_Set__c, reduivy__Total_Requirement__c, reduivy__Total_Reviewed__c, reduivy__Total_Submitted__c, reduivy__Total_Requirement_Faculty__c, reduivy__Total_Requirement_Student__c, reduivy__Total_Submitted_Faculty__c, reduivy__Total_Submitted_Student__c, reduivy__Total_Reviewed_Faculty__c, reduivy__Total_Reviewed_Student__c
            FROM reduivy__Individual_Requirement_Set__c
            WHERE Id = :irsId
            LIMIT 1
        ];
    }
	
}