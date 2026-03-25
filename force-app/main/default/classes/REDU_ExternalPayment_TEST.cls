/**
 * @author      WDCi (XW)
 * @date        Sept 2024
 * @group       Test
 * @description Test class for REDU_ExternalPayment_REST
 * @changehistory
 * ISS-002352 21-05-2025 XW - new class
 */
@IsTest
public inherited sharing class REDU_ExternalPayment_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String HTTP_METHOD_PUT = 'PUT';
    static final String HTTP_METHOD_POST = 'POST';
    static final String SRC_STUDENT_1 = 'sandydoe@redu.example';
    static final String SRC_STUDENT_2 = 'amydoe@redu.example';
    static final String SRC_PREFIX_TRO = 'TRO_';
    static final String SRC_PREFIX_TRP = 'TRP_';
    static final Integer TRP_AMOUNT = 1000;
    static final Integer TRP_AMOUNT_BEFORE = 500;
    static final String ERROR_UPDATE_NOT_ALLOWED = 'DML operation UPDATE not allowed on reduivy__Transaction_Payment__c';

    /**
     * @description Contact Identifier for response, required
     */
    public static final String REQUEST_IDENTIFIER_CON = REDU_ExternalPayment_REST.REQUEST_IDENTIFIER_CON;
    /**
     * @description Contact Identifier for transaction order, optional
     */
    public static final String REQUEST_IDENTIFIER_TRO = REDU_ExternalPayment_REST.REQUEST_IDENTIFIER_TRO;
    /**
     * @description Transaction payment object, required
     */
    public static final String REQUEST_TRP = REDU_ExternalPayment_REST.REQUEST_TRP;

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
        	
            //please adjust the data according to your needs
            testFactory.initMasterData(ACC_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            List<reduivy__Transaction_Order__c> troList = new List<reduivy__Transaction_Order__c>();
            List<reduivy__Transaction_Payment__c> trpList = new List<reduivy__Transaction_Payment__c>();

            for(Contact student : testFactory.students.values()) {
                reduivy__Transaction_Order__c tro = new reduivy__Transaction_Order__c();
                tro.reduivy__Contact__c = student.Id;
                tro.reduivy__Status__c = TRO_Helper.STATUS_TYPE_CONFIRMED;
                tro.reduivy__Transaction_Date__c = Date.today();
                tro.reduivy__Total_Amount__c = 1000;
                tro.reduivy__Sample_Record_Code__c = SRC_PREFIX_TRO + student.reduivy__Sample_Record_Code__c;

                troList.add(tro);

                reduivy__Transaction_Payment__c trp = new reduivy__Transaction_Payment__c();
                trp.reduivy__Contact__c = student.Id;
                trp.reduivy__Sample_Record_Code__c = SRC_PREFIX_TRP + student.reduivy__Sample_Record_Code__c;
                trp.reduivy__Status__c = TRP_Helper.STATUS_DRAFT;
                trp.reduivy__Amount__c = TRP_AMOUNT_BEFORE;


                trpList.add(trp);
            }

            insert troList;
            insert trpList;
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for for post with con Id, tro id, and with trp
     */
    @IsTest
    static void testFor_Post_ConId_TroId_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        System.Assert.isTrue(String.isNotBlank(response.recordId), 'TRP record should be created!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.areEqual(tro.Id, actualTrp.reduivy__Transaction_Order__c, 'TRP record should have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_CREATED, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }	

    /**
     * @description Test as admin for post with con email, tro id, and with trp
     */
    @IsTest
    static void testFor_Post_ConEmail_TroId_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Email;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        System.Assert.isTrue(String.isNotBlank(response.recordId), 'TRP record should be created!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.areEqual(tro.Id, actualTrp.reduivy__Transaction_Order__c, 'TRP record should have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_CREATED, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for post with con id, tro name, and with trp
     */
    @IsTest
    static void testFor_Post_ConId_TroName_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Name;
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        System.Assert.isTrue(String.isNotBlank(response.recordId), 'TRP record should be created!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.areEqual(tro.Id, actualTrp.reduivy__Transaction_Order__c, 'TRP record should have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_CREATED, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for post with con id, without tro, and with trp
     */
    @IsTest
    static void testFor_Post_ConId_WithoutTro_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        System.Assert.isTrue(String.isNotBlank(response.recordId), 'TRP record should be created!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.isTrue(String.isBlank(actualTrp.reduivy__Transaction_Order__c), 'TRP record should not have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_CREATED, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for post without con, tro name, and with trp
     */
    @IsTest
    static void testFor_Post_WithoutCon_TroName_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.transactionOrderIdentifier = tro.Name;
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        String errorMessage = String.format(Label.Missing_Required_Parameters, new List<String>{REQUEST_IDENTIFIER_CON});
        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should not be created!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_BAD_REQUEST, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for post with con id, tro id, and without trp
     */
    @IsTest
    static void testFor_Post_ConId_TroId_WithoutTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Name;

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        String errorMessage = String.format(Label.Missing_Required_Parameters, new List<String>{REQUEST_TRP});
        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should not be created!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_BAD_REQUEST, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for post with invalid con id, tro id, and with trp
     */
    @IsTest
    static void testFor_Post_InvalidCon_TroId_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = 'Invalid';
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
            new List<String>{
                epw.contactIdentifier, CON_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should not be created!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_NOT_FOUND, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for post with con id, invalid tro name, and with trp
     */
    @IsTest
    static void testFor_Post_ConId_InvalidTro_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = 'Invalid';
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
            new List<String>{
                epw.transactionOrderIdentifier, TRO_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should not be created!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_NOT_FOUND, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }
    /**
     * @description Test as admin for post with con id and tro contact mismatch, and with trp
     */
    @IsTest
    static void testFor_Post_ContactMismatch_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_2);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        String errorMessage = String.format(Label.Contact_Does_Not_Match_Transaction_Order_Contact, 
            new List<String>{
                CON_Helper.getObjectLabel(), student1.Id, TRO_Helper.getObjectLabel()
            }
    );

        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should not be created!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_FORBIDDEN, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }
    	
    /**
     * @description Test as student for for post with con Id, tro id, and with trp
     */
    @IsTest
    static void testFor_Post_ConId_TroId_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        System.Assert.isTrue(String.isNotBlank(response.recordId), 'TRP record should be created!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.areEqual(tro.Id, actualTrp.reduivy__Transaction_Order__c, 'TRP record should have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_CREATED, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }	

    /**
     * @description Test as student for post with con id, tro id, and without trp
     */
    @IsTest
    static void testFor_Post_ConId_TroId_WithoutTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Name;

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        String errorMessage = String.format(Label.Missing_Required_Parameters, new List<String>{REQUEST_TRP});
        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should not be created!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_BAD_REQUEST, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for post with invalid con id, tro id, and with trp
     */
    @IsTest
    static void testFor_Post_InvalidCon_TroId_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = 'Invalid';
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
            new List<String>{
                epw.contactIdentifier, CON_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should not be created!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_NOT_FOUND, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for post with con id, invalid tro name, and with trp
     */
    @IsTest
    static void testFor_Post_ConId_InvalidTro_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = 'Invalid';
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
            new List<String>{
                epw.transactionOrderIdentifier, TRO_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should not be created!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_NOT_FOUND, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }
    /**
     * @description Test as student for post with con id and tro contact mismatch, and with trp
     */
    @IsTest
    static void testFor_Post_ContactMismatch_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_2);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = new reduivy__Transaction_Payment__c(
            reduivy__Amount__c = TRP_AMOUNT,
            reduivy__Status__c = TRP_Helper.STATUS_DRAFT
        );

        setupRestRequest(HTTP_METHOD_POST, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePostRequest();
		}
        
        //students are not able to see other user's tro 
        String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
            new List<String>{
                epw.transactionOrderIdentifier, TRO_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should not be created!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_NOT_FOUND, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for for PUT with con Id, tro id, and with trp
     */
    @IsTest
    static void testFor_Put_ConId_TroId_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        System.Assert.areEqual(trp.Id, response.recordId, 'Wrong Trp Id!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.areEqual(tro.Id, actualTrp.reduivy__Transaction_Order__c, 'TRP record should have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_ACTIVE, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_OK, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }	

    /**
     * @description Test as admin for PUT with con email, tro id, and with trp
     */
    @IsTest
    static void testFor_Put_ConEmail_TroId_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Email;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        System.Assert.areEqual(trp.Id, response.recordId, 'Wrong Trp Id!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.areEqual(tro.Id, actualTrp.reduivy__Transaction_Order__c, 'TRP record should have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_ACTIVE, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_OK, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for PUT with con id, tro name, and with trp
     */
    @IsTest
    static void testFor_Put_ConId_TroName_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Name;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        System.Assert.areEqual(trp.Id, response.recordId, 'Wrong Trp Id!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.areEqual(tro.Id, actualTrp.reduivy__Transaction_Order__c, 'TRP record should have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_ACTIVE, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_OK, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for PUT with con id, without tro, and with trp
     */
    @IsTest
    static void testFor_Put_ConId_WithoutTro_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        System.Assert.areEqual(trp.Id, response.recordId, 'Wrong Trp Id!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.isTrue(String.isBlank(actualTrp.reduivy__Transaction_Order__c), 'TRP record should not have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_ACTIVE, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_OK, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for PUT without con, tro name, and with trp
     */
    @IsTest
    static void testFor_Put_WithoutCon_TroName_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.transactionOrderIdentifier = tro.Name;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Missing_Required_Parameters, new List<String>{REQUEST_IDENTIFIER_CON});
        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_BAD_REQUEST, RestContext.response.statusCode, 'Wrong status code!');

        trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Amount should not be updated after PUT is failed!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Status should not be updated after PUT is failed!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for PUT with con id, tro id, and without trp
     */
    @IsTest
    static void testFor_Put_ConId_TroId_WithoutTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Name;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Missing_Required_Parameters, new List<String>{REQUEST_TRP});
        System.Assert.isTrue(String.isBlank(response.recordId), 'Record Id should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_BAD_REQUEST, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for PUT with con id, tro id, and without trp
     */
    @IsTest
    static void testFor_Put_ConId_TroId_WithoutTrpId_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        trp.Id = null;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Name;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Transaction_Payment_Id_Not_Found_In_Request, new List<String>{TRP_Helper.getObjectLabel()});
        System.Assert.isTrue(String.isBlank(response.recordId), 'Record Id should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_BAD_REQUEST, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for PUT with invalid con id, tro id, and with trp
     */
    @IsTest
    static void testFor_Put_InvalidCon_TroId_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = 'Invalid';
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
            new List<String>{
                epw.contactIdentifier, CON_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'Record Id should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_NOT_FOUND, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for PUT with con id, invalid tro name, and with trp
     */
    @IsTest
    static void testFor_Put_ConId_InvalidTro_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = 'Invalid';
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
            new List<String>{
                epw.transactionOrderIdentifier, TRO_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'Record id should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_NOT_FOUND, RestContext.response.statusCode, 'Wrong status code!');

        trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Amount should not be updated after PUT is failed!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Status should not be updated after PUT is failed!');

        Test.stopTest();
		
    }
    /**
     * @description Test as admin for PUT with con id and tro contact mismatch, and with trp
     */
    @IsTest
    static void testFor_Put_ContactMismatch_WithTrp_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_2);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(ADMIN_USER){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Contact_Does_Not_Match_Transaction_Order_Contact, 
            new List<String>{
                CON_Helper.getObjectLabel(), student1.Id, TRO_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'Record Id should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_FORBIDDEN, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for for PUT with con Id, tro id, and with trp
     */
    @IsTest
    static void testFor_Put_ConId_TroId_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        System.Assert.areEqual(trp.Id, response.recordId, 'Wrong Trp Id!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.areEqual(tro.Id, actualTrp.reduivy__Transaction_Order__c, 'TRP record should have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_ACTIVE, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_OK, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }	

    /**
     * @description Test as student for PUT with con email, tro id, and with trp
     */
    @IsTest
    static void testFor_Put_ConEmail_TroId_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Email;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}

        
        System.Assert.areEqual(trp.Id, response.recordId, 'Wrong Trp Id!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.areEqual(tro.Id, actualTrp.reduivy__Transaction_Order__c, 'TRP record should have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_ACTIVE, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_OK, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for PUT with con id, tro name, and with trp
     */
    @IsTest
    static void testFor_Put_ConId_TroName_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Name;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUSer){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
                
        System.Assert.areEqual(trp.Id, response.recordId, 'Wrong Trp Id!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.areEqual(tro.Id, actualTrp.reduivy__Transaction_Order__c, 'TRP record should have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_ACTIVE, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_OK, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for PUT with con id, without tro, and with trp
     */
    @IsTest
    static void testFor_Put_ConId_WithoutTro_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
          
        System.Assert.areEqual(trp.Id, response.recordId, 'Wrong Trp Id!');
        reduivy__Transaction_Payment__c actualTrp = queryTransactionPaymentId(response.recordId);
        System.Assert.isTrue(String.isBlank(actualTrp.reduivy__Transaction_Order__c), 'TRP record should not have Transaction Order linked!');
        System.Assert.areEqual(student1.Id, actualTrp.reduivy__Contact__c, 'TRP record should have Contact Id linked!');
        System.Assert.areEqual(TRP_AMOUNT, actualTrp.reduivy__Amount__c, 'Wrong amount!');
        System.Assert.areEqual(TRP_Helper.STATUS_ACTIVE, actualTrp.reduivy__Status__c, 'Wrong status!');

        System.Assert.areEqual(true, response.isSuccess, 'isSuccess should be true!');
        System.Assert.areEqual(REDU_RestResponse.SUCCESS, response.status, 'Status should be success!');
        System.Assert.areEqual(Label.Request_Completed_Successfully, response.message);
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_OK, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for PUT without con, tro name, and with trp
     */
    @IsTest
    static void testFor_Put_WithoutCon_TroName_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.transactionOrderIdentifier = tro.Name;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Missing_Required_Parameters, new List<String>{REQUEST_IDENTIFIER_CON});
        System.Assert.isTrue(String.isBlank(response.recordId), 'TRP record should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_BAD_REQUEST, RestContext.response.statusCode, 'Wrong status code!');

        trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Amount should not be updated after PUT is failed!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Status should not be updated after PUT is failed!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for PUT with con id, tro id, and without trp
     */
    @IsTest
    static void testFor_Put_ConId_TroId_WithoutTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Name;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Missing_Required_Parameters, new List<String>{REQUEST_TRP});
        System.Assert.isTrue(String.isBlank(response.recordId), 'Record Id should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_BAD_REQUEST, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for PUT with con id, tro id, and without trp
     */
    @IsTest
    static void testFor_Put_ConId_TroId_WithoutTrpId_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        trp.Id = null;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Name;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Transaction_Payment_Id_Not_Found_In_Request, new List<String>{TRP_Helper.getObjectLabel()});
        System.Assert.isTrue(String.isBlank(response.recordId), 'Record Id should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_BAD_REQUEST, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for PUT with invalid con id, tro id, and with trp
     */
    @IsTest
    static void testFor_Put_InvalidCon_TroId_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        
        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = 'Invalid';
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
            new List<String>{
                epw.contactIdentifier, CON_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'Record Id should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_NOT_FOUND, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for PUT with con id, invalid tro name, and with trp
     */
    @IsTest
    static void testFor_Put_ConId_InvalidTro_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = 'Invalid';
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
            new List<String>{
                epw.transactionOrderIdentifier, TRO_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'Record id should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_NOT_FOUND, RestContext.response.statusCode, 'Wrong status code!');

        trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Amount should not be updated after PUT is failed!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Status should not be updated after PUT is failed!');

        Test.stopTest();
		
    }
    /**
     * @description Test as student for PUT with con id and tro contact mismatch, and with trp
     */
    @IsTest
    static void testFor_Put_ContactMismatch_WithTrp_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Contact student1 = queryContact(SRC_STUDENT_1);
        reduivy__Transaction_Order__c tro = queryTransactionOrder(SRC_PREFIX_TRO + SRC_STUDENT_2);
        reduivy__Transaction_Payment__c trp = queryTransactionPayment(SRC_PREFIX_TRP + SRC_STUDENT_1);
        System.Assert.areEqual(TRP_AMOUNT_BEFORE, trp.reduivy__Amount__c, 'Wrong amount before PUT!');
        System.Assert.areEqual(TRP_Helper.STATUS_DRAFT, trp.reduivy__Status__c, 'Wrong status before PUT!');
        trp.reduivy__Amount__c = TRP_AMOUNT;
        trp.reduivy__Status__c = TRP_Helper.STATUS_ACTIVE;
        
        REDU_ExternalPayment_REST.ExternalPaymentWrapper epw = new REDU_ExternalPayment_REST.ExternalPaymentWrapper();
        epw.contactIdentifier = student1.Id;
        epw.transactionOrderIdentifier = tro.Id;
        epw.transactionPayment = trp;

        setupRestRequest(HTTP_METHOD_PUT, JSON.serialize(epw));
        RestContext.response = new RestResponse();

        Test.startTest();
        
        REDU_RestResponse response;
		System.runAs(studentUser){
            response = REDU_ExternalPayment_REST.handlePutRequest();
		}
        
        //students are not able to see other user's tro 
        String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
            new List<String>{
                epw.transactionOrderIdentifier, TRO_Helper.getObjectLabel()
            }
        );

        System.Assert.isTrue(String.isBlank(response.recordId), 'Record Id should be empty!');
        System.Assert.areEqual(false, response.isSuccess, 'isSuccess should be false!');
        System.Assert.areEqual(REDU_RestResponse.FAIL, response.status, 'Status should be fail!');
        System.Assert.areEqual(errorMessage, response.message, 'Wrong error message!');
        System.Assert.areEqual(REDU_ExternalPayment_REST.STATUS_CODE_NOT_FOUND, RestContext.response.statusCode, 'Wrong status code!');

        Test.stopTest();
		
    }

    /**
     * @description query Transaction Order based on sample record code
     * @param  sampleRecordCode 
     * @return                  reduivy__Transaction_Order__c
     */
    private static reduivy__Transaction_Order__c queryTransactionOrder(String sampleRecordCode){
        return [
            SELECT Id, Name
            FROM reduivy__Transaction_Order__c
            WHERE reduivy__Sample_Record_Code__c = :sampleRecordCode
            LIMIT 1
        ];
    }

    /**
     * @description query Contact based on sample record code
     * @param  sampleRecordCode 
     * @return                  Contact
     */
    private static Contact queryContact(String sampleRecordCode){
        return [
            SELECT Id, Name, Email
            FROM Contact
            WHERE reduivy__Sample_Record_Code__c = :sampleRecordCode
            LIMIT 1
        ];
    }

    /**
     * @description query Transaction Payment based on sample record code
     * @param  sampleRecordCode 
     * @return                  
     */
    private static reduivy__Transaction_Payment__c queryTransactionPayment(String sampleRecordCode) {
        return [
            SELECT Id, reduivy__Transaction_Order__c, reduivy__Contact__c, reduivy__Amount__c, reduivy__Status__c
            FROM reduivy__Transaction_Payment__c 
            WHERE reduivy__Sample_Record_Code__c = :sampleRecordCode
            LIMIT 1
        ];
    }

    /**
     * @description query Transaction Payment based on record id
     * @param  recordId 
     * @return 
     */
    private static reduivy__Transaction_Payment__c queryTransactionPaymentId(String recordId){
        return [
            SELECT Id, reduivy__Transaction_Order__c, reduivy__Contact__c, reduivy__Amount__c, reduivy__Status__c
            FROM reduivy__Transaction_Payment__c 
            WHERE Id = :recordId
            LIMIT 1
        ];
    }

    /**
     * @description Setup the Rest request object
     * @param  method      PUT or POST
     * @param  requestBody request body in serialized string
     */
    private static void setupRestRequest(String method, String requestBody){

        RestRequest req = new RestRequest();
        req.httpMethod = method;
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
    }
	
}