/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Test
 * @description Test class for REDU_RequirementChecklist_LCTRL
 * @changehistory
 * ISS-002128 17-06-2025 XW - new class
 * ISS-002665 10-11-2025 XiRouh - Updated the statusType variable to reviewStatusType and added testForGetIndividualRequirements_VariousSubmissionStatuses to cover the submission type
 * ISS-002633 03-02-2026 XW - added test cases for children relationship
 */
@IsTest
public inherited sharing class REDU_RequirementChecklist_TEST {

    static final String REQUEST_USERMODE_ADMIN = 'Admin';
    static final String REQUEST_USERMODE_FACULTY = 'Faculty';
    static final String REQUEST_USERMODE_STUDENT = 'Student';

    static final String RESPONSE_TOTAL_REQUIREMENTS_PARAM = 'totalRequirements';
    static final String RESPONSE_TOTAL_REVIEWED_PARAM = 'totalReviewed';
    static final String RESPONSE_TOTAL_SUBMITTED_PARAM = 'totalSubmitted';
    static final String RESPONSE_PARENT_IRS_DATA_PARAM = 'irsParentData';
    static final String RESPONSE_CHILD_IRS_DATA_PARAM = 'irsChildData';
    static final String RESPONSE_CHILD_LABEL_PARAM = 'irsChildRelationshipLabel';
    static final String RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM = 'defaultSubmittedStatus';

    static final String SRS_LOCAL = 'SRS_Local';
    static final String SRS_GENERAL = 'SRS_General';
    static final String SRS_APPLICATION = 'SRS_Application';

    static final String CON_SRC = 'sandydoe@redu.example';
    static final String IPA_SRC = CON_SRC;
    static final String IAC_SRC = CON_SRC + 'Individual_Achievement';

    static final String SRS_GENERAL_UPLOADTRANSCRIPT = 'SRS_General_UploadTranscript';
    static final String SRS_LOCAL_UPLOADID = 'SRS_Local_UploadID';

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
        	
            testFactory.initMasterData(SRQ_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IRQ_Helper.getApiName(), true);

            //delete all the application scoring related srs and srq as they will affect the results
            List<reduivy__Individual_Requirement_Set__c> irsListToDelete = [SELECT Id FROM reduivy__Individual_Requirement_Set__c WHERE reduivy__Study_Requirement_Set__r.reduivy__Sample_Record_Code__c = :SRS_APPLICATION];
            delete irsListToDelete;

            List<reduivy__Study_Requirement_Set__c> srsListToDelete = [SELECT Id FROM reduivy__Study_Requirement_Set__c WHERE reduivy__Sample_Record_Code__c = :SRS_APPLICATION];
            delete srsListToDelete;
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for getting individual requirement set, status all open
     */
    @IsTest
    static void testForGetIndividualRequirements_AllOpen_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IPA_Helper.getApiName()
        ]) {
            expectedIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.Id, irq);
            }
        }


        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_ADMIN, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, null);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualIrsWrapperList.add(rsw);
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(4, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(0, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(0, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(2, actualIrsWrapperList.size(), 'Wrong irs wrapper list size!');
            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualIrsWrapper : actualIrsWrapperList) {
                
                System.Assert.isTrue(expectedIrsMap.containsKey(actualIrsWrapper.irs.Id), actualIrsWrapper.irs.Name + ' should be available!');

                reduivy__Individual_Requirement_Set__c irs = expectedIrsMap.get(actualIrsWrapper.irs.Id);
                
                System.Assert.areEqual(2, actualIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    //reduivy__Individual_Requirement__c irq = expectedIrqMap.get(actualIrqWrapper.irq.Id);
                    System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_OPEN, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                }
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for getting individual requirement set, status Accepted + Conditionally Accepted + Not Required + Not Accepted
     */
    @IsTest
    static void testForGetIndividualRequirements_AllReviewedType_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Contact studentContact = queryStudentContact();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        List<String> statusTypeList = new List<String>{
            IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED
        };

        String notRequiredReviewStatus = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED;
        
        Integer irqSize = 0;
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name, reduivy__Review_Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IPA_Helper.getApiName()
        ]) {
            expectedIrsMap.put(irs.Id, irs);
            System.Assert.areEqual(2, irs.reduivy__Individual_Requirements__r.size(), 'Each IRS should have 2 IRQs');

            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.Id, irq);
                irqSize++;
            }
        }

        List<reduivy__Individual_Requirement__c> irqUpdateList = expectedIrqMap.values();
        Integer statusIndex = 0;
        Boolean notRequiredUsed = false; 

        for(reduivy__Individual_Requirement__c irq : irqUpdateList) {
            if(irq.reduivy__Sample_Record_Code__c.contains(SRS_GENERAL_UPLOADTRANSCRIPT) || irq.reduivy__Sample_Record_Code__c.contains(SRS_LOCAL_UPLOADID)) {
                System.Assert.isTrue(statusIndex <= statusTypeList.size() - 1, 'Index out of bounds');

                irq.reduivy__Review_Status__c = statusTypeList[statusIndex];
                statusIndex++;
            } else {
                if(!notRequiredUsed) {
                    irq.reduivy__Review_Status__c = notRequiredReviewStatus;
                    notRequiredUsed = true;
                } else {
                    System.Assert.isTrue(statusIndex <= statusTypeList.size() - 1, 'Index out of bounds');

                    irq.reduivy__Review_Status__c = statusTypeList[statusIndex];
                    statusIndex++;
                }
            }
        }

        update irqUpdateList;

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_ADMIN, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            System.debug(JSON.serialize(responseMap));
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualIrsWrapperList.add(rsw);
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(4, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(4, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(3, actualTotalSubmitted, 'Wrong total submitted!'); 
            
            System.Assert.areEqual(2, actualIrsWrapperList.size(), 'Wrong irs wrapper list size!');

            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualIrsWrapper : actualIrsWrapperList) {
                
                System.Assert.isTrue(expectedIrsMap.containsKey(actualIrsWrapper.irs.Id), actualIrsWrapper.irs.Name + ' should be available!');

                reduivy__Individual_Requirement_Set__c irs = expectedIrsMap.get(actualIrsWrapper.irs.Id);
                
                System.Assert.areEqual(2, actualIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    
                    if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_CANCELLED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for getting individual requirement set, status Open + Under Review + Accepted + Not Accepted, all submitted
     */
    @IsTest
    static void testForGetIndividualRequirements_MixType_AllSubmitted_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Contact studentContact = queryStudentContact();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        List<String> statusTypeList = new List<String>{
            IRQ_Helper.REVIEW_STATUS_OPEN,
            IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW,
            IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED
        };
        
        Integer irqSize = 0;
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name, reduivy__Review_Status__c
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IPA_Helper.getApiName()
        ]) {
            expectedIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.Id, irq);
                irqSize++;
            }
        }
        List<reduivy__Individual_Requirement__c> irqUpdateList = expectedIrqMap.values();

        for(Integer i = 0; i < irqSize; i++) {
            reduivy__Individual_Requirement__c irq = irqUpdateList.get(i);
            irq.reduivy__Review_Status__c = statusTypeList.get(i);
            irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        }

        update irqUpdateList;

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_ADMIN, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualIrsWrapperList.add(rsw);
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(4, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(2, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(4, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(2, actualIrsWrapperList.size(), 'Wrong irs wrapper list size!');

            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualIrsWrapper : actualIrsWrapperList) {
                
                System.Assert.isTrue(expectedIrsMap.containsKey(actualIrsWrapper.irs.Id), actualIrsWrapper.irs.Name + ' should be available!');

                reduivy__Individual_Requirement_Set__c irs = expectedIrsMap.get(actualIrsWrapper.irs.Id);
                
                System.Assert.areEqual(2, actualIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    
                    if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_OPEN) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_SUBMITTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REVIEWING, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for getting individual requirement set, status all open, with children relationship
     */
    @IsTest
    static void testForGetIndividualRequirements_AllOpen_ChildRelationship_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedParentIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedParentIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAC_Helper.getApiName()
        ]) {
            expectedParentIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedParentIrqMap.put(irq.Id, irq);
            }
        }

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedChildrenIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedChildrenIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAU_Helper.getApiName()
        ]) {
            expectedChildrenIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedChildrenIrqMap.put(irq.Id, irq);
            }
        }

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_ADMIN, new List<String>{'Name', 'Name'}, 'Name', iac.Id, 'reduivy__Individual_Achievement_Units__r', UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualParentIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper> actualChildRecordWrapperList = new List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualTotalIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 

            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualParentIrsWrapperList.add(rsw);
                actualTotalIrsWrapperList.add(rsw);
            }
            
            //child
            for(Object childIrsWrapperObject : (List<Object>) responseMap.get(RESPONSE_CHILD_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper crsw = (REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper) JSON.deserialize(JSON.serialize(childIrsWrapperObject), REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper.class);
                actualChildRecordWrapperList.add(crsw);
                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw : crsw.irsWrapperList) {
                    actualTotalIrsWrapperList.add(rsw);
                }
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(4, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(0, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(0, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(1, actualParentIrsWrapperList.size(), 'Wrong irs wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList.size(), 'Wrong child record wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList[0].irsWrapperList.size(), 'Wrong child irs wrapper list size!');
            
            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualParentIrsWrapper : actualParentIrsWrapperList) {
                
                System.Assert.isTrue(expectedParentIrsMap.containsKey(actualParentIrsWrapper.irs.Id), actualParentIrsWrapper.irs.Name + ' should be available!');

                System.Assert.areEqual(2, actualParentIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualParentIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedParentIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_OPEN, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                }
            }

            for(REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper actualChildRecordWrapper : actualChildRecordWrapperList) {

                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualChildIrsWrapper : actualChildRecordWrapper.irsWrapperList) {

                    System.Assert.areEqual(2, actualChildIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                    for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualChildIrsWrapper.irqWrapperList){
                        System.Assert.isTrue(expectedChildrenIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_OPEN, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }
		}

        Test.stopTest();
    }
	

    /**
     * @description Test as admin for getting individual requirement set, status all reviewed, with children relationship
     */
    @IsTest
    static void testForGetIndividualRequirements_AllReviewedType_ChildRelationship_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        Contact studentContact = queryStudentContact();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedParentIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedParentIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        List<String> statusTypeList = new List<String>{
            IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED
        };
        String notRequiredReviewStatus = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED;

        Integer irqSize = 0;
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name, reduivy__Review_Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAC_Helper.getApiName()
        ]) {
            expectedParentIrsMap.put(irs.Id, irs);
            System.Assert.areEqual(2, irs.reduivy__Individual_Requirements__r.size(), 'Each IRS should have 2 IRQs');

            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedParentIrqMap.put(irq.Id, irq);
                irqSize++;
            }
        }

        
        Map<Id, reduivy__Individual_Requirement_Set__c> expectedChildrenIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedChildrenIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAU_Helper.getApiName()
        ]) {
            expectedChildrenIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedChildrenIrqMap.put(irq.Id, irq);
            }
        }

        List<reduivy__Individual_Requirement__c> irqUpdateList = expectedParentIrqMap.values();
        irqUpdateList.addAll(expectedChildrenIrqMap.values());
        Integer statusIndex = 0;

        irqUpdateList[0].reduivy__Review_Status__c = statusTypeList[0];
        irqUpdateList[1].reduivy__Review_Status__c = statusTypeList[1];
        irqUpdateList[2].reduivy__Review_Status__c = statusTypeList[2];
        irqUpdateList[3].reduivy__Review_Status__c = statusTypeList[0];
        update irqUpdateList;


        Test.startTest();
        
		System.runAs(ADMIN_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_ADMIN, new List<String>{'Name', 'Name'}, 'Name', iac.Id, 'reduivy__Individual_Achievement_Units__r', UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualParentIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper> actualChildRecordWrapperList = new List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualTotalIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 

            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualParentIrsWrapperList.add(rsw);
                actualTotalIrsWrapperList.add(rsw);
            }
            
            //child
            for(Object childIrsWrapperObject : (List<Object>) responseMap.get(RESPONSE_CHILD_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper crsw = (REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper) JSON.deserialize(JSON.serialize(childIrsWrapperObject), REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper.class);
                actualChildRecordWrapperList.add(crsw);
                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw : crsw.irsWrapperList) {
                    actualTotalIrsWrapperList.add(rsw);
                }
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(4, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(4, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(4, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(1, actualParentIrsWrapperList.size(), 'Wrong irs wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList.size(), 'Wrong irs wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList[0].irsWrapperList.size(), 'Wrong child irs wrapper list size!');
            
            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualParentIrsWrapper : actualParentIrsWrapperList) {
                
                System.Assert.isTrue(expectedParentIrsMap.containsKey(actualParentIrsWrapper.irs.Id), actualParentIrsWrapper.irs.Name + ' should be available!');

                System.Assert.areEqual(2, actualParentIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualParentIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedParentIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    
                    if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_CANCELLED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }

            for(REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper actualChildRecordWrapper : actualChildRecordWrapperList) {

                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualChildIrsWrapper : actualChildRecordWrapper.irsWrapperList) {

                    System.Assert.areEqual(2, actualChildIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                    for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualChildIrsWrapper.irqWrapperList){
                        System.Assert.isTrue(expectedChildrenIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                        
                        if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_CANCELLED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        }
                    }
                }
            }
		}

        Test.stopTest();
    }

    @IsTest
    static void testGetCommunityInfo_AsAdmin() {
        
        String expectedCommunityInfo = JSON.serialize(ORG_Helper.getCommunityInfo());
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER) {
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getCommunityInfo();
            System.Assert.areEqual(expectedCommunityInfo, response.responseData, 'Wrong community info!');
        }

        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for getting individual requirement set, status all open
     */
    @IsTest
    static void testForGetIndividualRequirements_AllOpen_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IPA_Helper.getApiName()
        ]) {
            expectedIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.Id, irq);
            }
        }


        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_FACULTY, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            system.debug(JSON.serialize(responseMap));
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualIrsWrapperList.add(rsw);
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(2, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(0, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(0, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(2, actualIrsWrapperList.size(), 'Wrong irs wrapper list size!');

            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualIrsWrapper : actualIrsWrapperList) {
                
                System.Assert.isTrue(expectedIrsMap.containsKey(actualIrsWrapper.irs.Id), actualIrsWrapper.irs.Name + ' should be available!');

                reduivy__Individual_Requirement_Set__c irs = expectedIrsMap.get(actualIrsWrapper.irs.Id);
                
                System.Assert.areEqual(1, actualIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    //reduivy__Individual_Requirement__c irq = expectedIrqMap.get(actualIrqWrapper.irq.Id);
                    System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_OPEN, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                }
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for getting individual requirement set, status Accepted + Conditionally Accepted + Not Required + Not Accepted
     */
    @IsTest
    static void testForGetIndividualRequirements_AllReviewedType_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Contact studentContact = queryStudentContact();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        List<String> statusTypeList = new List<String>{
            IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED
        };

        String notRequiredReviewStatus = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED;
        
        Integer irqSize = 0;
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name, reduivy__Review_Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IPA_Helper.getApiName()
        ]) {
            expectedIrsMap.put(irs.Id, irs);
            System.Assert.areEqual(2, irs.reduivy__Individual_Requirements__r.size(), 'Each IRS should have 2 IRQs');

            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.Id, irq);
                irqSize++;
            }
        }

        List<reduivy__Individual_Requirement__c> irqUpdateList = expectedIrqMap.values();
        Integer statusIndex = 0;
        Boolean notRequiredUsed = false; 

        for(reduivy__Individual_Requirement__c irq : irqUpdateList) {
            if(irq.reduivy__Sample_Record_Code__c.contains(SRS_GENERAL_UPLOADTRANSCRIPT) || irq.reduivy__Sample_Record_Code__c.contains(SRS_LOCAL_UPLOADID)) {
                System.Assert.isTrue(statusIndex <= statusTypeList.size() - 1, 'Index out of bounds');

                irq.reduivy__Review_Status__c = statusTypeList[statusIndex];
                statusIndex++;
            } else {
                if(!notRequiredUsed) {
                    irq.reduivy__Review_Status__c = notRequiredReviewStatus;
                    notRequiredUsed = true;
                } else {
                    System.Assert.isTrue(statusIndex <= statusTypeList.size() - 1, 'Index out of bounds');
                    
                    irq.reduivy__Review_Status__c = statusTypeList[statusIndex];
                    statusIndex++;
                }
            }
        }

        update irqUpdateList;

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_FACULTY, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualIrsWrapperList.add(rsw);
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(2, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(2, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(2, actualTotalSubmitted, 'Wrong total submitted!'); 
            
            System.Assert.areEqual(2, actualIrsWrapperList.size(), 'Wrong irs wrapper list size!');

            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualIrsWrapper : actualIrsWrapperList) {
                
                System.Assert.isTrue(expectedIrsMap.containsKey(actualIrsWrapper.irs.Id), actualIrsWrapper.irs.Name + ' should be available!');

                reduivy__Individual_Requirement_Set__c irs = expectedIrsMap.get(actualIrsWrapper.irs.Id);
                
                System.Assert.areEqual(1, actualIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    
                    if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_CANCELLED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for getting individual requirement set, status Open + Under Review + Accepted + Not Accepted, all submitted
     */
    @IsTest
    static void testForGetIndividualRequirements_MixType_AllSubmitted_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Contact studentContact = queryStudentContact();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        List<String> statusTypeList = new List<String>{
            IRQ_Helper.REVIEW_STATUS_OPEN,
            IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW,
            IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED
        };
        
        Integer irqSize = 0;
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name, reduivy__Review_Status__c
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IPA_Helper.getApiName()
        ]) {
            expectedIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.Id, irq);
                irqSize++;
            }
        }
        List<reduivy__Individual_Requirement__c> irqUpdateList = expectedIrqMap.values();

        for(Integer i = 0; i < irqSize; i++) {
            reduivy__Individual_Requirement__c irq = irqUpdateList.get(i);
            irq.reduivy__Review_Status__c = statusTypeList.get(i);
            irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        }

        update irqUpdateList;

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_FACULTY, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualIrsWrapperList.add(rsw);
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(2, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(1, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(2, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(2, actualIrsWrapperList.size(), 'Wrong irs wrapper list size!');

            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualIrsWrapper : actualIrsWrapperList) {
                
                System.Assert.isTrue(expectedIrsMap.containsKey(actualIrsWrapper.irs.Id), actualIrsWrapper.irs.Name + ' should be available!');

                reduivy__Individual_Requirement_Set__c irs = expectedIrsMap.get(actualIrsWrapper.irs.Id);
                
                System.Assert.areEqual(1, actualIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    
                    if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_OPEN) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_SUBMITTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REVIEWING, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
                
            }
		}

        Test.stopTest();
		
    }
	
    
    /**
     * @description Test as faculty for getting individual requirement set, status all open, with children relationship
     */
    @IsTest
    static void testForGetIndividualRequirements_AllOpen_ChildRelationship_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedParentIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedParentIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAC_Helper.getApiName()
        ]) {
            expectedParentIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedParentIrqMap.put(irq.Id, irq);
            }
        }

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedChildrenIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedChildrenIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAU_Helper.getApiName()
        ]) {
            expectedChildrenIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedChildrenIrqMap.put(irq.Id, irq);
            }
        }

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_FACULTY, new List<String>{'Name', 'Name'}, 'Name', iac.Id, 'reduivy__Individual_Achievement_Units__r', UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualParentIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper> actualChildRecordWrapperList = new List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualTotalIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 

            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualParentIrsWrapperList.add(rsw);
                actualTotalIrsWrapperList.add(rsw);
            }
            
            //child
            for(Object childIrsWrapperObject : (List<Object>) responseMap.get(RESPONSE_CHILD_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper crsw = (REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper) JSON.deserialize(JSON.serialize(childIrsWrapperObject), REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper.class);
                actualChildRecordWrapperList.add(crsw);
                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw : crsw.irsWrapperList) {
                    actualTotalIrsWrapperList.add(rsw);
                }
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(2, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(0, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(0, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(1, actualParentIrsWrapperList.size(), 'Wrong irs wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList.size(), 'Wrong child record wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList[0].irsWrapperList.size(), 'Wrong child irs wrapper list size!');
            
            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualParentIrsWrapper : actualParentIrsWrapperList) {
                
                System.Assert.isTrue(expectedParentIrsMap.containsKey(actualParentIrsWrapper.irs.Id), actualParentIrsWrapper.irs.Name + ' should be available!');

                System.Assert.areEqual(1, actualParentIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualParentIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedParentIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_OPEN, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                }
            }

            for(REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper actualChildRecordWrapper : actualChildRecordWrapperList) {

                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualChildIrsWrapper : actualChildRecordWrapper.irsWrapperList) {

                    System.Assert.areEqual(1, actualChildIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                    for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualChildIrsWrapper.irqWrapperList){
                        System.Assert.isTrue(expectedChildrenIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_OPEN, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }
		}

        Test.stopTest();
    }
	

    /**
     * @description Test as faculty for getting individual requirement set, status all reviewed, with children relationship
     */
    @IsTest
    static void testForGetIndividualRequirements_AllReviewedType_ChildRelationship_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Contact studentContact = queryStudentContact();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedParentIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedParentIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        List<String> statusTypeList = new List<String>{
            IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED
        };
        String notRequiredReviewStatus = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED;

        Integer irqSize = 0;
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name, reduivy__Review_Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAC_Helper.getApiName()
        ]) {
            expectedParentIrsMap.put(irs.Id, irs);
            System.Assert.areEqual(2, irs.reduivy__Individual_Requirements__r.size(), 'Each IRS should have 2 IRQs');

            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedParentIrqMap.put(irq.Id, irq);
                irqSize++;
            }
        }

        
        Map<Id, reduivy__Individual_Requirement_Set__c> expectedChildrenIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedChildrenIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAU_Helper.getApiName()
        ]) {
            expectedChildrenIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedChildrenIrqMap.put(irq.Id, irq);
            }
        }

        List<reduivy__Individual_Requirement__c> irqUpdateList = expectedParentIrqMap.values();
        irqUpdateList.addAll(expectedChildrenIrqMap.values());
        Integer statusIndex = 0;

        irqUpdateList[0].reduivy__Review_Status__c = statusTypeList[0];
        irqUpdateList[1].reduivy__Review_Status__c = statusTypeList[1];
        irqUpdateList[2].reduivy__Review_Status__c = statusTypeList[2];
        irqUpdateList[3].reduivy__Review_Status__c = statusTypeList[0];
        update irqUpdateList;


        Test.startTest();
        
		System.runAs(FACULTY_USER){
            reduivy__Individual_Achievement__c iac = queryIac();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_FACULTY, new List<String>{'Name', 'Name'}, 'Name', iac.Id, 'reduivy__Individual_Achievement_Units__r', UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualParentIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper> actualChildRecordWrapperList = new List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualTotalIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 

            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualParentIrsWrapperList.add(rsw);
                actualTotalIrsWrapperList.add(rsw);
            }
            
            //child
            for(Object childIrsWrapperObject : (List<Object>) responseMap.get(RESPONSE_CHILD_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper crsw = (REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper) JSON.deserialize(JSON.serialize(childIrsWrapperObject), REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper.class);
                actualChildRecordWrapperList.add(crsw);
                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw : crsw.irsWrapperList) {
                    actualTotalIrsWrapperList.add(rsw);
                }
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(2, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(2, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(2, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(1, actualParentIrsWrapperList.size(), 'Wrong irs wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList.size(), 'Wrong irs wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList[0].irsWrapperList.size(), 'Wrong child irs wrapper list size!');
            
            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualParentIrsWrapper : actualParentIrsWrapperList) {
                
                System.Assert.isTrue(expectedParentIrsMap.containsKey(actualParentIrsWrapper.irs.Id), actualParentIrsWrapper.irs.Name + ' should be available!');

                System.Assert.areEqual(1, actualParentIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualParentIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedParentIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    
                    if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_CANCELLED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }

            for(REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper actualChildRecordWrapper : actualChildRecordWrapperList) {

                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualChildIrsWrapper : actualChildRecordWrapper.irsWrapperList) {

                    System.Assert.areEqual(1, actualChildIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                    for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualChildIrsWrapper.irqWrapperList){
                        System.Assert.isTrue(expectedChildrenIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                        
                        if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_CANCELLED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        }
                    }
                }
            }
		}

        Test.stopTest();
    }
	

    @IsTest
    static void testGetCommunityInfo_AsFaculty() {

        String expectedCommunityInfo = JSON.serialize(ORG_Helper.getCommunityInfo());
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        
        System.runAs(FACULTY_USER) {
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getCommunityInfo();
            System.Assert.areEqual(expectedCommunityInfo, response.responseData, 'Wrong community info!');
        }

        Test.stopTest();
    }
	
    /**
     * @description Test as student for getting individual requirement set, status all open
     */
    @IsTest
    static void testForGetIndividualRequirements_AllOpen_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IPA_Helper.getApiName()
        ]) {
            expectedIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.Id, irq);
            }
        }


        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_STUDENT, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualIrsWrapperList.add(rsw);
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(2, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(0, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(0, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(2, actualIrsWrapperList.size(), 'Wrong irs wrapper list size!');

            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualIrsWrapper : actualIrsWrapperList) {
                
                System.Assert.isTrue(expectedIrsMap.containsKey(actualIrsWrapper.irs.Id), actualIrsWrapper.irs.Name + ' should be available!');

                reduivy__Individual_Requirement_Set__c irs = expectedIrsMap.get(actualIrsWrapper.irs.Id);
                
                System.Assert.areEqual(1, actualIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    //reduivy__Individual_Requirement__c irq = expectedIrqMap.get(actualIrqWrapper.irq.Id);
                    System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_OPEN, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                }
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for getting individual requirement set, status Accepted + Conditionally Accepted + Not Required + Not Accepted
     */
    @IsTest
    static void testForGetIndividualRequirements_AllReviewedType_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        Contact studentContact = queryStudentContact();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        List<String> statusTypeList = new List<String>{
            IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED
        };

        String notRequiredReviewStatus = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED;
        
        Integer irqSize = 0;
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name, reduivy__Review_Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IPA_Helper.getApiName()
        ]) {
            expectedIrsMap.put(irs.Id, irs);
            System.Assert.areEqual(2, irs.reduivy__Individual_Requirements__r.size(), 'Each IRS should have 2 IRQs');

            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.Id, irq);
                irqSize++;
            }
        }

        List<reduivy__Individual_Requirement__c> irqUpdateList = expectedIrqMap.values();
        Integer statusIndex = 0;
        Boolean notRequiredUsed = false; 

        for(reduivy__Individual_Requirement__c irq : irqUpdateList) {
            if(irq.reduivy__Sample_Record_Code__c.contains(SRS_GENERAL_UPLOADTRANSCRIPT) || irq.reduivy__Sample_Record_Code__c.contains(SRS_LOCAL_UPLOADID)) {
                System.Assert.isTrue(statusIndex <= statusTypeList.size() - 1, 'Index out of bounds');

                irq.reduivy__Review_Status__c = statusTypeList[statusIndex];
                statusIndex++;
            } else {
                if(!notRequiredUsed) {
                    irq.reduivy__Review_Status__c = notRequiredReviewStatus;
                    notRequiredUsed = true;
                } else {
                    System.Assert.isTrue(statusIndex <= statusTypeList.size() - 1, 'Index out of bounds');
                    
                    irq.reduivy__Review_Status__c = statusTypeList[statusIndex];
                    statusIndex++;
                }
            }
        }

        update irqUpdateList;

        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_STUDENT, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualIrsWrapperList.add(rsw);
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(2, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(2, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(2, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(2, actualIrsWrapperList.size(), 'Wrong irs wrapper list size!');

            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualIrsWrapper : actualIrsWrapperList) {
                
                System.Assert.isTrue(expectedIrsMap.containsKey(actualIrsWrapper.irs.Id), actualIrsWrapper.irs.Name + ' should be available!');

                reduivy__Individual_Requirement_Set__c irs = expectedIrsMap.get(actualIrsWrapper.irs.Id);
                
                System.Assert.areEqual(1, actualIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    
                    if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_CANCELLED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }
		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for getting individual requirement set, status Open + Under Review + Accepted + Not Accepted, all submitted
     */
    @IsTest
    static void testForGetIndividualRequirements_MixType_AllSubmitted_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        Contact studentContact = queryStudentContact();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        List<String> statusTypeList = new List<String>{
            IRQ_Helper.REVIEW_STATUS_OPEN,
            IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW,
            IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED
        };
        
        Integer irqSize = 0;
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name, reduivy__Review_Status__c
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IPA_Helper.getApiName()
        ]) {
            expectedIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedIrqMap.put(irq.Id, irq);
                irqSize++;
            }
        }
        List<reduivy__Individual_Requirement__c> irqUpdateList = expectedIrqMap.values();

        for(Integer i = 0; i < irqSize; i++) {
            reduivy__Individual_Requirement__c irq = irqUpdateList.get(i);
            irq.reduivy__Review_Status__c = statusTypeList.get(i);
            irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
        }

        update irqUpdateList;

        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_STUDENT, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualIrsWrapperList.add(rsw);
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(2, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(1, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(2, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(2, actualIrsWrapperList.size(), 'Wrong irs wrapper list size!');

            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualIrsWrapper : actualIrsWrapperList) {
                
                System.Assert.isTrue(expectedIrsMap.containsKey(actualIrsWrapper.irs.Id), actualIrsWrapper.irs.Name + ' should be available!');

                reduivy__Individual_Requirement_Set__c irs = expectedIrsMap.get(actualIrsWrapper.irs.Id);
                
                System.Assert.areEqual(1, actualIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    
                    if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_OPEN) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_SUBMITTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REVIEWING, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as student for getting individual requirement set, status all open, with children relationship
     */
    @IsTest
    static void testForGetIndividualRequirements_AllOpen_ChildRelationship_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedParentIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedParentIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAC_Helper.getApiName()
        ]) {
            expectedParentIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedParentIrqMap.put(irq.Id, irq);
            }
        }

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedChildrenIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedChildrenIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAU_Helper.getApiName()
        ]) {
            expectedChildrenIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedChildrenIrqMap.put(irq.Id, irq);
            }
        }

        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Achievement__c iac = queryIac();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_STUDENT, new List<String>{'Name', 'Name'}, 'Name', iac.Id, 'reduivy__Individual_Achievement_Units__r', UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualParentIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper> actualChildRecordWrapperList = new List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualTotalIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 

            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualParentIrsWrapperList.add(rsw);
                actualTotalIrsWrapperList.add(rsw);
            }
            
            //child
            for(Object childIrsWrapperObject : (List<Object>) responseMap.get(RESPONSE_CHILD_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper crsw = (REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper) JSON.deserialize(JSON.serialize(childIrsWrapperObject), REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper.class);
                actualChildRecordWrapperList.add(crsw);
                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw : crsw.irsWrapperList) {
                    actualTotalIrsWrapperList.add(rsw);
                }
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(2, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(0, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(0, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(1, actualParentIrsWrapperList.size(), 'Wrong irs wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList.size(), 'Wrong child record wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList[0].irsWrapperList.size(), 'Wrong child irs wrapper list size!');
            
            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualParentIrsWrapper : actualParentIrsWrapperList) {
                
                System.Assert.isTrue(expectedParentIrsMap.containsKey(actualParentIrsWrapper.irs.Id), actualParentIrsWrapper.irs.Name + ' should be available!');

                System.Assert.areEqual(1, actualParentIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualParentIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedParentIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_OPEN, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                }
            }

            for(REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper actualChildRecordWrapper : actualChildRecordWrapperList) {

                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualChildIrsWrapper : actualChildRecordWrapper.irsWrapperList) {

                    System.Assert.areEqual(1, actualChildIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                    for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualChildIrsWrapper.irqWrapperList){
                        System.Assert.isTrue(expectedChildrenIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_OPEN, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }
		}

        Test.stopTest();
    }
	

    /**
     * @description Test as student for getting individual requirement set, status all reviewed, with children relationship
     */
    @IsTest
    static void testForGetIndividualRequirements_AllReviewedType_ChildRelationship_AsStudent() {

        User studentUser = testFactory.getStudentUser();
        Contact studentContact = queryStudentContact();

        Map<Id, reduivy__Individual_Requirement_Set__c> expectedParentIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedParentIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        List<String> statusTypeList = new List<String>{
            IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED,
            IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED
        };
        String notRequiredReviewStatus = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED;

        Integer irqSize = 0;
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name, reduivy__Review_Status__c, reduivy__Sample_Record_Code__c
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAC_Helper.getApiName()
        ]) {
            expectedParentIrsMap.put(irs.Id, irs);
            System.Assert.areEqual(2, irs.reduivy__Individual_Requirements__r.size(), 'Each IRS should have 2 IRQs');

            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedParentIrqMap.put(irq.Id, irq);
                irqSize++;
            }
        }

        
        Map<Id, reduivy__Individual_Requirement_Set__c> expectedChildrenIrsMap = new Map<Id, reduivy__Individual_Requirement_Set__c>();
        Map<Id, reduivy__Individual_Requirement__c> expectedChildrenIrqMap = new Map<Id, reduivy__Individual_Requirement__c>();
        
        for(reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, 
            (
                SELECT Id, Name
                FROM reduivy__Individual_Requirements__r
                WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            )
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Status__c = :IRS_Helper.STATUS_ACTIVE
            AND reduivy__Contact__c = :studentContact.Id
            AND reduivy__Study_Requirement_Set__r.reduivy__Object__c = :IAU_Helper.getApiName()
        ]) {
            expectedChildrenIrsMap.put(irs.Id, irs);
            for(reduivy__Individual_Requirement__c irq : irs.reduivy__Individual_Requirements__r) {
                expectedChildrenIrqMap.put(irq.Id, irq);
            }
        }

        List<reduivy__Individual_Requirement__c> irqUpdateList = expectedParentIrqMap.values();
        irqUpdateList.addAll(expectedChildrenIrqMap.values());
        Integer statusIndex = 0;

        irqUpdateList[0].reduivy__Review_Status__c = statusTypeList[0];
        irqUpdateList[1].reduivy__Review_Status__c = statusTypeList[1];
        irqUpdateList[2].reduivy__Review_Status__c = statusTypeList[2];
        irqUpdateList[3].reduivy__Review_Status__c = statusTypeList[0];
        update irqUpdateList;


        Test.startTest();
        
		System.runAs(studentUser){
            reduivy__Individual_Achievement__c iac = queryIac();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(REQUEST_USERMODE_STUDENT, new List<String>{'Name', 'Name'}, 'Name', iac.Id, 'reduivy__Individual_Achievement_Units__r', UserInfo.getLanguage());
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualParentIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper> actualChildRecordWrapperList = new List<REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper>(); 
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualTotalIrsWrapperList = new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 

            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(JSON.serialize(irsWrapperObject), REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class);
                actualParentIrsWrapperList.add(rsw);
                actualTotalIrsWrapperList.add(rsw);
            }
            
            //child
            for(Object childIrsWrapperObject : (List<Object>) responseMap.get(RESPONSE_CHILD_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper crsw = (REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper) JSON.deserialize(JSON.serialize(childIrsWrapperObject), REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper.class);
                actualChildRecordWrapperList.add(crsw);
                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw : crsw.irsWrapperList) {
                    actualTotalIrsWrapperList.add(rsw);
                }
            }

            Integer actualTotalRequirement = (Integer) responseMap.get(RESPONSE_TOTAL_REQUIREMENTS_PARAM);
            Integer actualTotalReviewed = (Integer) responseMap.get(RESPONSE_TOTAL_REVIEWED_PARAM);
            Integer actualTotalSubmitted = (Integer) responseMap.get(RESPONSE_TOTAL_SUBMITTED_PARAM);

            System.Assert.areEqual(2, actualTotalRequirement, 'Wrong total requirement!');
            System.Assert.areEqual(2, actualTotalReviewed, 'Wrong total reviewed!');
            System.Assert.areEqual(2, actualTotalSubmitted, 'Wrong total submitted!');
            
            System.Assert.areEqual(1, actualParentIrsWrapperList.size(), 'Wrong irs wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList.size(), 'Wrong irs wrapper list size!');
            System.Assert.areEqual(1, actualChildRecordWrapperList[0].irsWrapperList.size(), 'Wrong child irs wrapper list size!');
            
            System.Assert.areEqual(IRQ_Helper.getSubmissionSubmittedStatuses().get(0), (String) responseMap.get(RESPONSE_DEFAULT_SUBMITTED_STATUS_PARAM));

            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualParentIrsWrapper : actualParentIrsWrapperList) {
                
                System.Assert.isTrue(expectedParentIrsMap.containsKey(actualParentIrsWrapper.irs.Id), actualParentIrsWrapper.irs.Name + ' should be available!');

                System.Assert.areEqual(1, actualParentIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualParentIrsWrapper.irqWrapperList){
                    System.Assert.isTrue(expectedParentIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                    
                    if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_CANCELLED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                    }
                }
            }

            for(REDU_RequirementChecklist_LCTRL.ChildRequirementSetWrapper actualChildRecordWrapper : actualChildRecordWrapperList) {

                for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper actualChildIrsWrapper : actualChildRecordWrapper.irsWrapperList) {

                    System.Assert.areEqual(1, actualChildIrsWrapper.irqWrapperList.size(), 'Wrong irq list size!');
                    for(REDU_RequirementChecklist_LCTRL.RequirementWrapper actualIrqWrapper : actualChildIrsWrapper.irqWrapperList){
                        System.Assert.isTrue(expectedChildrenIrqMap.containsKey(actualIrqWrapper.irq.Id), actualIrqWrapper.irq.Name + ' should be available!');
                        
                        if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_ACCEPTED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_ACCEPTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_CANCELLED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        } else if(actualIrqWrapper.irq.reduivy__Review_Status__c == IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED) {
                            System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_TYPE_REJECTED, actualIrqWrapper.reviewStatusType, 'Wrong status type!');
                        }
                    }
                }
            }
		}

        Test.stopTest();
    }
	
    /**
     * @description Test as admin for getting individual requirement's submission status type
     */
    @IsTest
    static void testForGetIndividualRequirements_VariousSubmissionStatuses_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        Contact studentContact = queryStudentContact();

        // Get all IRQs
        List<reduivy__Individual_Requirement__c> irqList = [
            SELECT Id, reduivy__Submission_Status__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__r.reduivy__Contact__c = :studentContact.Id
            AND reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            ORDER BY Id
        ];

        // Map to track which IRQ has which submission status
        Map<Id, String> irqSubmissionStatusMap = new Map<Id, String>();

        // Set different submission statuses for the 4 requirements
        if(irqList.size() >= 4) {
            irqList[0].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_CANCELLED;
            irqSubmissionStatusMap.put(irqList[0].Id, IRQ_Helper.SUBMISSION_STATUS_CANCELLED);
            
            irqList[1].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
            irqSubmissionStatusMap.put(irqList[1].Id, IRQ_Helper.SUBMISSION_STATUS_OPEN);
            
            irqList[2].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_RESUBMISSION_REQUESTED;
            irqSubmissionStatusMap.put(irqList[2].Id, IRQ_Helper.SUBMISSION_STATUS_RESUBMISSION_REQUESTED);
            
            irqList[3].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqSubmissionStatusMap.put(irqList[3].Id, IRQ_Helper.SUBMISSION_STATUS_SUBMITTED);
            
            update irqList;
        }

        Test.startTest();
        
        System.runAs(ADMIN_USER){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(
                REQUEST_USERMODE_ADMIN, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage()
            );
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = 
                new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
                
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = 
                    (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(
                        JSON.serialize(irsWrapperObject), 
                        REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class
                    );
                actualIrsWrapperList.add(rsw);
            }

            Integer cancelledCount = 0, openCount = 0, resubmissionCount = 0, submittedCount = 0;

            // Verify each requirement has correct submission status type
            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper irsWrapper : actualIrsWrapperList) {
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper irqWrapper : irsWrapper.irqWrapperList) {
                    String actualSubmissionStatus = irqWrapper.irq.reduivy__Submission_Status__c;
                    String actualSubmissionType = irqWrapper.submissionStatusType;
                    
                    // Verify the submission status type matches the expected type based on the status
                    if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_CANCELLED) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_CANCELLED, 
                            actualSubmissionType, 
                            'Submission status type should be Cancelled for ' + irqWrapper.irq.Id
                        );
                        cancelledCount++;
                        
                    } else if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_OPEN) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_OPEN, 
                            actualSubmissionType, 
                            'Submission status type should be Open for ' + irqWrapper.irq.Id
                        );
                        openCount++;
                        
                    } else if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_RESUBMISSION_REQUESTED) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_RESUBMISSION_REQUESTED, 
                            actualSubmissionType, 
                            'Submission status type should be Resubmission Requested for ' + irqWrapper.irq.Id
                        );
                        resubmissionCount++;
                        
                    } else if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_SUBMITTED) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_SUBMITTED, 
                            actualSubmissionType, 
                            'Submission status type should be Submitted for ' + irqWrapper.irq.Id
                        );
                        submittedCount++;
                    }
                }
            }

            // Verify we tested all 4 submission statuses
            System.Assert.areEqual(1, cancelledCount, 'Should have 1 Cancelled submission status!');
            System.Assert.areEqual(1, openCount, 'Should have 1 Open submission status!');
            System.Assert.areEqual(1, resubmissionCount, 'Should have 1 Resubmission Requested submission status!');
            System.Assert.areEqual(1, submittedCount, 'Should have 1 Submitted submission status!');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for getting individual requirement's submission status type
     */
    @IsTest
    static void testForGetIndividualRequirements_VariousSubmissionStatuses_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Contact studentContact = queryStudentContact();

        // Get all IRQs
        List<reduivy__Individual_Requirement__c> irqList = [
            SELECT Id, reduivy__Submission_Status__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__r.reduivy__Contact__c = :studentContact.Id
            AND reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            ORDER BY Id
        ];

        // Map to track which IRQ has which submission status
        Map<Id, String> irqSubmissionStatusMap = new Map<Id, String>();

        // Set different submission statuses for the 4 requirements
        if(irqList.size() >= 4) {
            irqList[0].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_CANCELLED;
            irqSubmissionStatusMap.put(irqList[0].Id, IRQ_Helper.SUBMISSION_STATUS_CANCELLED);
            
            irqList[1].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
            irqSubmissionStatusMap.put(irqList[1].Id, IRQ_Helper.SUBMISSION_STATUS_OPEN);
            
            irqList[2].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_RESUBMISSION_REQUESTED;
            irqSubmissionStatusMap.put(irqList[2].Id, IRQ_Helper.SUBMISSION_STATUS_RESUBMISSION_REQUESTED);
            
            irqList[3].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqSubmissionStatusMap.put(irqList[3].Id, IRQ_Helper.SUBMISSION_STATUS_SUBMITTED);
            
            update irqList;
        }

        Test.startTest();
        
        System.runAs(FACULTY_USER){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(
                REQUEST_USERMODE_ADMIN, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage()
            );
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = 
                new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
                
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = 
                    (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(
                        JSON.serialize(irsWrapperObject), 
                        REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class
                    );
                actualIrsWrapperList.add(rsw);
            }

            Integer cancelledCount = 0, openCount = 0, resubmissionCount = 0, submittedCount = 0;

            // Verify each requirement has correct submission status type
            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper irsWrapper : actualIrsWrapperList) {
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper irqWrapper : irsWrapper.irqWrapperList) {
                    String actualSubmissionStatus = irqWrapper.irq.reduivy__Submission_Status__c;
                    String actualSubmissionType = irqWrapper.submissionStatusType;
                    
                    // Verify the submission status type matches the expected type based on the status
                    if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_CANCELLED) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_CANCELLED, 
                            actualSubmissionType, 
                            'Submission status type should be Cancelled for ' + irqWrapper.irq.Id
                        );
                        cancelledCount++;
                        
                    } else if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_OPEN) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_OPEN, 
                            actualSubmissionType, 
                            'Submission status type should be Open for ' + irqWrapper.irq.Id
                        );
                        openCount++;
                        
                    } else if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_RESUBMISSION_REQUESTED) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_RESUBMISSION_REQUESTED, 
                            actualSubmissionType, 
                            'Submission status type should be Resubmission Requested for ' + irqWrapper.irq.Id
                        );
                        resubmissionCount++;
                        
                    } else if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_SUBMITTED) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_SUBMITTED, 
                            actualSubmissionType, 
                            'Submission status type should be Submitted for ' + irqWrapper.irq.Id
                        );
                        submittedCount++;
                    }
                }
            }

            // Verify we tested all 4 submission statuses
            System.Assert.areEqual(1, cancelledCount, 'Should have 1 Cancelled submission status!');
            System.Assert.areEqual(1, openCount, 'Should have 1 Open submission status!');
            System.Assert.areEqual(1, resubmissionCount, 'Should have 1 Resubmission Requested submission status!');
            System.Assert.areEqual(1, submittedCount, 'Should have 1 Submitted submission status!');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for getting individual requirement's submission status type
     */
    @IsTest
    static void testForGetIndividualRequirements_VariousSubmissionStatuses_AsStudent() {
        User studentUser = testFactory.getStudentUser();
        Contact studentContact = queryStudentContact();

        // Get all IRQs
        List<reduivy__Individual_Requirement__c> irqList = [
            SELECT Id, reduivy__Submission_Status__c
            FROM reduivy__Individual_Requirement__c
            WHERE reduivy__Individual_Requirement_Set__r.reduivy__Contact__c = :studentContact.Id
            AND reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE
            ORDER BY Id
        ];

        // Map to track which IRQ has which submission status
        Map<Id, String> irqSubmissionStatusMap = new Map<Id, String>();

        // Set different submission statuses for the 4 requirements
        if(irqList.size() >= 4) {
            irqList[0].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_CANCELLED;
            irqSubmissionStatusMap.put(irqList[0].Id, IRQ_Helper.SUBMISSION_STATUS_CANCELLED);
            
            irqList[1].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_OPEN;
            irqSubmissionStatusMap.put(irqList[1].Id, IRQ_Helper.SUBMISSION_STATUS_OPEN);
            
            irqList[2].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_RESUBMISSION_REQUESTED;
            irqSubmissionStatusMap.put(irqList[2].Id, IRQ_Helper.SUBMISSION_STATUS_RESUBMISSION_REQUESTED);
            
            irqList[3].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            irqSubmissionStatusMap.put(irqList[3].Id, IRQ_Helper.SUBMISSION_STATUS_SUBMITTED);
            
            update irqList;
        }

        Test.startTest();
        
        System.runAs(studentUser){
            reduivy__Individual_Program_Application__c ipa = queryIpa();
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getIndividualRequirements(
                REQUEST_USERMODE_ADMIN, new List<String>{'Name', 'Name'}, 'Name', ipa.Id, null, UserInfo.getLanguage()
            );
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);
            List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper> actualIrsWrapperList = 
                new List<REDU_RequirementChecklist_LCTRL.RequirementSetWrapper>(); 
                
            for(Object irsWrapperObject : (List<Object>) responseMap.get(RESPONSE_PARENT_IRS_DATA_PARAM)) {
                REDU_RequirementChecklist_LCTRL.RequirementSetWrapper rsw = 
                    (REDU_RequirementChecklist_LCTRL.RequirementSetWrapper) JSON.deserialize(
                        JSON.serialize(irsWrapperObject), 
                        REDU_RequirementChecklist_LCTRL.RequirementSetWrapper.class
                    );
                actualIrsWrapperList.add(rsw);
            }

            Integer cancelledCount = 0, openCount = 0, resubmissionCount = 0, submittedCount = 0;

            // Verify each requirement has correct submission status type
            for(REDU_RequirementChecklist_LCTRL.RequirementSetWrapper irsWrapper : actualIrsWrapperList) {
                for(REDU_RequirementChecklist_LCTRL.RequirementWrapper irqWrapper : irsWrapper.irqWrapperList) {
                    String actualSubmissionStatus = irqWrapper.irq.reduivy__Submission_Status__c;
                    String actualSubmissionType = irqWrapper.submissionStatusType;
                    
                    // Verify the submission status type matches the expected type based on the status
                    if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_CANCELLED) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_CANCELLED, 
                            actualSubmissionType, 
                            'Submission status type should be Cancelled for ' + irqWrapper.irq.Id
                        );
                        cancelledCount++;
                        
                    } else if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_OPEN) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_OPEN, 
                            actualSubmissionType, 
                            'Submission status type should be Open for ' + irqWrapper.irq.Id
                        );
                        openCount++;
                        
                    } else if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_RESUBMISSION_REQUESTED) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_RESUBMISSION_REQUESTED, 
                            actualSubmissionType, 
                            'Submission status type should be Resubmission Requested for ' + irqWrapper.irq.Id
                        );
                        resubmissionCount++;
                        
                    } else if(actualSubmissionStatus == IRQ_Helper.SUBMISSION_STATUS_SUBMITTED) {
                        System.Assert.areEqual(
                            IRQ_Helper.SUBMISSION_STATUS_TYPE_SUBMITTED, 
                            actualSubmissionType, 
                            'Submission status type should be Submitted for ' + irqWrapper.irq.Id
                        );
                        submittedCount++;
                    }
                }
            }

            // Verify we tested all 4 submission statuses
            System.Assert.areEqual(1, cancelledCount, 'Should have 1 Cancelled submission status!');
            System.Assert.areEqual(1, openCount, 'Should have 1 Open submission status!');
            System.Assert.areEqual(1, resubmissionCount, 'Should have 1 Resubmission Requested submission status!');
            System.Assert.areEqual(1, submittedCount, 'Should have 1 Submitted submission status!');
        }

        Test.stopTest();
    }

    @IsTest
    static void testGetCommunityInfo_AsStudent() {

        String expectedCommunityInfo = JSON.serialize(ORG_Helper.getCommunityInfo());
        
        User studentUser = testFactory.getStudentUser();
        
        Test.startTest();
        
        System.runAs(studentUser) {
            REDU_LightningResponse response = REDU_RequirementChecklist_LCTRL.getCommunityInfo();
            System.Assert.areEqual(expectedCommunityInfo, response.responseData, 'Wrong community info!');
        }

        Test.stopTest();
    }
	
    static reduivy__Individual_Program_Application__c queryIpa() {
        return [SELECT reduivy__Application_Status__c,
                reduivy__Study_Program__c,
                reduivy__Master_Study_Plan__c,
                reduivy__Secondary_Study_Plan__c,
                reduivy__Application_Date__c,
                reduivy__Contact__c,
                reduivy__Sample_Record_Code__c
                FROM reduivy__Individual_Program_Application__c
                WHERE reduivy__Sample_Record_Code__c =: IPA_SRC
                LIMIT 1
                ];
    }
	
    static reduivy__Individual_Achievement__c queryIac() {
        return [SELECT Id,
                reduivy__Contact__c,
                reduivy__Sample_Record_Code__c
                FROM reduivy__Individual_Achievement__c
                WHERE reduivy__Sample_Record_Code__c =: IAC_SRC
                LIMIT 1
                ];
    }

    static Contact queryStudentContact(){
        return [
            SELECT Id, Name
            FROM Contact
            WHERE reduivy__Sample_Record_Code__c = :CON_SRC
            LIMIT 1
        ];
    }
}