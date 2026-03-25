/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Test
 * @description Test class for IRQ_SetDates_EXE
 * @changehistory
 * ISS-002128 16-06-2025 XW - new class
 */
@IsTest
public inherited sharing class IRQ_SetDates_TEST {

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

    static List<String> REVIEWED_STATUSES = IRQ_Helper.getReviewedStatuses();
    static String REVIEWED_STATUS = REVIEWED_STATUSES[0];
    static List<String> UNREVIEWED_STATUSES = IRQ_Helper.getUnreviewedStatuses();
    static String UNREVIEWED_STATUS = UNREVIEWED_STATUSES[1];
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
     * @description Test as admin for creating new irq, status = active, submitted = true, reviewed status = true
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedTrueReviewedTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        Datetime expectedDate;
		System.runAs(ADMIN_USER){
            insert newIrq;
            expectedDate = System.now();
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating new irq, status = active, submitted = true, reviewed status = false
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedTrueReviewedFalse_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

        Datetime expectedDate;
		System.runAs(ADMIN_USER){
            insert newIrq;
            expectedDate = System.now();
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating new irq, status = active, submitted = false, reviewed status = true
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedFalseReviewedTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        Datetime expectedDate;
		System.runAs(ADMIN_USER){
            insert newIrq;
            expectedDate = System.now();
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating new irq, status = active, submitted = false, reviewed status = false
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedFalseReviewedFalse_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

		System.runAs(ADMIN_USER){
            insert newIrq;
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for creating new irq, active = false, submitted = true, reviewed status = true
     */
    @IsTest
    static void testForCreate_StatusDraftSubmittedTrueReviewedTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

		System.runAs(ADMIN_USER){
            insert newIrq;
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating new irq, status = active, submitted to true, reviewed status to true
     */
    @IsTest
    static void testForUpdate_StatusActiveSubmittedToTrueReviewedToTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

        insert newIrq;
		
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        Datetime expectedDate;
        System.runAs(ADMIN_USER) {   
            update newIrq;    
            expectedDate = System.now();
        }

        reduivy__Individual_Requirement__c updatedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating new irq, status = active, submitted = true, reviewed status to true
     */
    @IsTest
    static void testForUpdate_StatusActiveSubmittedTrueReviewedToTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

        insert newIrq;
        Datetime expectedDate = System.now();
		
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        System.runAs(ADMIN_USER) {   
            update newIrq;    
            expectedDate = System.now();
        }

        reduivy__Individual_Requirement__c updatedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }
    

    /**
     * @description Test as admin for updating new irq, active to false, submitted to true, reviewed status to true
     */
    @IsTest
    static void testForUpdate_ActiveToFalseSubmittedToTrueReviewedToTrue_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, ADMIN_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

        insert newIrq;
		
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        System.runAs(ADMIN_USER) {   
            update newIrq;    
        }

        reduivy__Individual_Requirement__c updatedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(updatedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(updatedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating new irq, status = active, submitted = true, reviewed status = true
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedTrueReviewedTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        Datetime expectedDate;
		System.runAs(studentUser){
            insert newIrq;
            expectedDate = System.now();
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating new irq, status = active, submitted = true, reviewed status = false
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedTrueReviewedFalse_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

        Datetime expectedDate;
		System.runAs(studentUser){
            insert newIrq;
            expectedDate = System.now();
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating new irq, status = active, submitted = false, reviewed status = true
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedFalseReviewedTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        Datetime expectedDate;
		System.runAs(studentUser){
            insert newIrq;
            expectedDate = System.now();
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c! Expected: ');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating new irq, status = active, submitted = false, reviewed status = false
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedFalseReviewedFalse_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

		Datetime expectedDate;
		System.runAs(studentUser){
            insert newIrq;
            expectedDate = System.now();
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for creating new irq, active = false, submitted = true, reviewed status = true
     */
    @IsTest
    static void testForCreate_StatusDraftSubmittedTrueReviewedTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

		System.runAs(studentUser){
            insert newIrq;
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating new irq, status = active, submitted to true, reviewed status to true
     */
    @IsTest
    static void testForUpdate_StatusActiveSubmittedToTrueReviewedToTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;
        newIrq.OwnerId = studentUser.Id;

        System.runAs(studentUser) {   
            insert newIrq;
        }
		
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;
        
        Datetime expectedDate;
        System.runAs(studentUser) {   
            update newIrq;    
            expectedDate = System.now();
        }

        reduivy__Individual_Requirement__c updatedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating new irq, status = active, submitted = true, reviewed status to true
     */
    @IsTest
    static void testForUpdate_StatusActiveSubmittedTrueReviewedToTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;
        newIrq.OwnerId = studentUser.Id;

        Datetime expectedDate;
        System.runAs(studentUser) {   
            insert newIrq;
            expectedDate = System.now();
        }
		
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        System.runAs(studentUser) {   
            update newIrq;    
            expectedDate = System.now();
        }

        reduivy__Individual_Requirement__c updatedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }
    

    /**
     * @description Test as student for updating new irq, active to false, submitted to true, reviewed status to true
     */
    @IsTest
    static void testForUpdate_ActiveToFalseSubmittedToTrueReviewedToTrue_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, studentUser.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;
        newIrq.OwnerId = studentUser.Id;

        System.runAs(studentUser) {   
            insert newIrq;
        }
		
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        System.runAs(studentUser) {   
            update newIrq;    
        }

        reduivy__Individual_Requirement__c updatedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(updatedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(updatedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating new irq, status = active, submitted = true, reviewed status = true
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedTrueReviewedTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        Datetime expectedDate;
		System.runAs(FACULTY_USER){
            insert newIrq;
            expectedDate = System.now();
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating new irq, status = active, submitted = true, reviewed status = false
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedTrueReviewedFalse_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

        Datetime expectedDate;
		System.runAs(FACULTY_USER){
            insert newIrq;
            expectedDate = System.now();
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating new irq, status = active, submitted = false, reviewed status = true
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedFalseReviewedTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        Datetime expectedDate;
		System.runAs(FACULTY_USER){
            insert newIrq;
            expectedDate = System.now();
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating new irq, status = active, submitted = false, reviewed status = false
     */
    @IsTest
    static void testForCreate_StatusActiveSubmittedFalseReviewedFalse_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

		System.runAs(FACULTY_USER){
            insert newIrq;
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for creating new irq, active = false, submitted = true, reviewed status = true
     */
    @IsTest
    static void testForCreate_StatusDraftSubmittedTrueReviewedTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

		System.runAs(FACULTY_USER){
            insert newIrq;
		}
        
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating new irq, status = active, submitted to true, reviewed status to true
     */
    @IsTest
    static void testForUpdate_StatusActiveSubmittedToTrueReviewedToTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

        insert newIrq;
		
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        Datetime expectedDate;
        System.runAs(FACULTY_USER) {   
            update newIrq;    
            expectedDate = System.now();
        }

        reduivy__Individual_Requirement__c updatedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating new irq, status = active, submitted = true, reviewed status to true
     */
    @IsTest
    static void testForUpdate_StatusActiveSubmittedTrueReviewedToTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

        insert newIrq;
        Datetime expectedDate = System.now();
		
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id); queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, insertedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        System.runAs(FACULTY_USER) {   
            update newIrq;    
            expectedDate = System.now();
        }

        reduivy__Individual_Requirement__c updatedIrq = queryIrq(newIrq.Id);

        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Submission_Date__c), 'Wrong reduivy__Submission_Date__c!');
        System.Assert.isTrue(compareDatetimeWithin2Sec(expectedDate, updatedIrq.reduivy__Review_Date__c), 'Wrong reduivy__Review_Date__c!');

        Test.stopTest();
		
    }
    

    /**
     * @description Test as faculty for updating new irq, active to false, submitted to true, reviewed status to true
     */
    @IsTest
    static void testForUpdate_ActiveToFalseSubmittedToTrueReviewedToTrue_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        setIrsList();
        setSrqList();
        reduivy__Individual_Requirement__c newIrq = IRQ_Helper.createIrq(srqGeneral, irsGeneral.Id, FACULTY_USER.Id);
        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_ACTIVE;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
        newIrq.reduivy__Review_Status__c = UNREVIEWED_STATUS;

        insert newIrq;
		
        reduivy__Individual_Requirement__c insertedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(insertedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(insertedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

        newIrq.reduivy__Status__c = IRQ_Helper.STATUS_DRAFT;
        newIrq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        newIrq.reduivy__Review_Status__c = REVIEWED_STATUS;

        System.runAs(FACULTY_USER) {   
            update newIrq;    
        }

        reduivy__Individual_Requirement__c updatedIrq = queryIrq(newIrq.Id);

        System.Assert.isNull(updatedIrq.reduivy__Submission_Date__c, 'reduivy__Submission_Date__c should be null!');
        System.Assert.isNull(updatedIrq.reduivy__Review_Date__c, 'reduivy__Review_Date__c should be null!');

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
            } else if(srq.reduivy__Sample_Record_Code__c == SRQ_GENERAL) {
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

    static reduivy__Individual_Requirement__c queryIrq(Id irqId){
        return [
            SELECT Id, Name, reduivy__Status__c, reduivy__Submission_Status__c, reduivy__Review_Status__c, reduivy__Submission_Date__c, reduivy__Review_Date__c, reduivy__Object_Relation_Field__c, reduivy__Object_Fields__c, reduivy__Link_To_Individual_Achievement__c
            FROM reduivy__Individual_Requirement__c
            WHERE Id = :irqId
            LIMIT 1
        ];
    }

    static Boolean compareDatetimeWithin2Sec(Datetime expectedDate, Datetime datetimeToCompare){
        return expectedDate.getTime() - datetimeToCompare.getTime() < 2000;

    }
	
}