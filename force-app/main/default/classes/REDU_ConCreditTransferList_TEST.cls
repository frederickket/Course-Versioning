/**
 * @author      WDCi (VTan)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for REDU_ConCreditTransferList_LCTRL
 * @changehistory
 * ISS-001659 30-01-2024 VTan - New class
 */
@isTest
private class REDU_ConCreditTransferList_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    static final String STUDY_PLAN_STRUCTURE_GROUP = 'BACBIS_MajorA_GROUPA_1_1';
	static final String STUDY_PLAN_STRUCTURE_UNIT = 'BACBIS_MajorA_BUS101';

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';

    static String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);

    /**
     * @description Default method to setup required data for automated test
     */
    @TestSetup
    static void makeData(){

        // Create rio education ivy settings and sample data
        testFactory.setupDefaultSettings();
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER){
            Test.startTest();

            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (Contact student : testFactory.students.values()) {
				String sampleRecordCode = student.Id + '_' + testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id contactId = student.Id;
				Id studyProgramId = testFactory.studyPrograms.get(STUDY_PROGRAM).Id;
				Id studyPlanId = testFactory.studyPlans.get(STUDY_PLAN).Id;
				Id studyIntakeId = null;
				Id startingTermId = null;
				Id studyPathwayId = null;
				Id defaultCampusId = null;
				String classYear = null;
				String classStanding = null;
				Boolean eligibleToEnroll = true;
				String enrollmentStatus = IPE_INPROGRESS_STATUS;
				Id idvAcademicProfileId = null;
				reduivy__Individual_Program_Enrollment__c ipe = 
					REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
						sampleRecordCode, 
						contactId, 
						studyProgramId, 
						studyPlanId, 
						studyIntakeId, 
						startingTermId, 
						studyPathwayId, 
						defaultCampusId, 
						classYear, 
						classStanding, 
						eligibleToEnroll, 
						enrollmentStatus,
						idvAcademicProfileId
					);

				ipeList.add(ipe);
			}
			
			insert ipeList;

            // Create sample agreement record
            Date agreementStartDate = System.today().addDays(-365);
            reduivy__Agreement__c agreement = REDU_TestData_UTIL.newAgreement('Agreement', null, testFactory.extEduInsts.get('EXTUNIT').Id, 'Agreement', agreementStartDate, agreementStartDate.addDays(90), AGR_Helper.STATUS_ACTIVE, AGR_Helper.TYPE_EXTERNAL);
            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Agreement__c>{agreement});

            // Create sample agreement unit equivalent record
            Set<String> originUnitCodes = new Set<String>{'ABC123'};
            Set<String> targetUnitCodes = new Set<String>{'BUS101'};
            reduivy__Agreement_Unit_Equivalent__c agreementUnitEquiv = REDU_TestData_UTIL.newAgreementUnitEquivalent('AgreementUnitEquiv', agreement.Id, 'Business, Management, and Marketing', originUnitCodes, targetUnitCodes, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_ONETOONE);
            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Agreement_Unit_Equivalent__c>{agreementUnitEquiv});

            // Prepare information for credit transfer application creation
            Id masterIPERecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId();
            List<reduivy__Credit_Transfer_Application__c> ctApplicationList = new List<reduivy__Credit_Transfer_Application__c>();

            for(reduivy__Individual_Program_Enrollment__c ipe : [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = :masterIPERecordTypeId]){

                ctApplicationList.add(REDU_TestData_UTIL.newCreditTransferApplication(ipe.Id, ipe.reduivy__Contact__c, agreementUnitEquiv.Id, ipe.Id, null, 'A', 99, null, null, System.today(), CTA_Helper.STATUS_TYPE_DRAFT, null, new Set<String>{}, CTA_Helper.TYPE_INCOMING));
            }

            REDU_SystemMode_UTIL.doInsert(ctApplicationList);

            Test.stopTest();
        }

    }

    /**
     * @description Test as admin for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        reduivy__Credit_Transfer_Application__c ctApplication = [SELECT Id FROM reduivy__Credit_Transfer_Application__c WHERE reduivy__Contact__c = :masterIPE.reduivy__Contact__c LIMIT 1];
        String ctAppListFields = 'Name;reduivy__Agreement_Unit_Equivalent__c;reduivy__Approved_Unit_Codes__c;reduivy__Credits_Attempted__c;reduivy__Credits_Earned__c;reduivy__Completed_Date__c;reduivy__Status__c';
        String hrefTargetType = '_self';


        System.runAs(ADMIN_USER){
            Test.startTest();

            // Test from contact object
            REDU_LightningResponse objResponse1 = REDU_ConCreditTransferList_LCTRL.getCreditTransferList('Contact', masterIPE.reduivy__Contact__c, 'Id', ctAppListFields , true, hrefTargetType, UserInfo.getLanguage());
            System.Assert.areEqual(true, objResponse1.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            // Test from individual program enrollment object
            REDU_LightningResponse objResponse2 = REDU_ConCreditTransferList_LCTRL.getCreditTransferList('reduivy__Individual_Program_Enrollment__c', masterIPE.Id, 'reduivy__Contact__c', ctAppListFields , true, hrefTargetType, UserInfo.getLanguage());
            System.Assert.areEqual(true, objResponse2.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            // Test credit transfer application submission
            REDU_LightningResponse objResponse3 = REDU_ConCreditTransferList_LCTRL.submitCTApplication(JSON.serialize(ctApplication));
            System.Assert.areEqual(true, objResponse3.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            // Test credit transfer application rejection
            REDU_LightningResponse objResponse5 = REDU_ConCreditTransferList_LCTRL.rejectCTApplication(JSON.serialize(ctApplication));
            System.Assert.areEqual(true, objResponse5.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            Test.stopTest();
        }
    }

    /**
     * @description Test as setup user for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForSetupUser() {

        User setupUser = testFactory.getSetupUser();
        Integer hasError = 0;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        reduivy__Credit_Transfer_Application__c ctApplication = [SELECT Id FROM reduivy__Credit_Transfer_Application__c WHERE reduivy__Contact__c = :masterIPE.reduivy__Contact__c LIMIT 1];
        String ctAppListFields = 'Name;reduivy__Agreement_Unit_Equivalent__c;reduivy__Approved_Unit_Codes__c;reduivy__Credits_Attempted__c;reduivy__Credits_Earned__c;reduivy__Completed_Date__c;reduivy__Status__c';
        String hrefTargetType = '_self';

        Test.startTest();
        System.runAs(setupUser){

            try{
                
                // Test from contact object
                REDU_LightningResponse objResponse1 = REDU_ConCreditTransferList_LCTRL.getCreditTransferList('Contact', masterIPE.reduivy__Contact__c, 'Id', ctAppListFields , true, hrefTargetType, UserInfo.getLanguage());
                System.Assert.areEqual(true, objResponse1.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            } catch (Exception exp) {

                REDU_Logging_UTIL.debug('testForSetupUser', exp.getMessage());
                hasError ++;
            }

            try{
                
                // Test from individual program enrollment object
                REDU_LightningResponse objResponse2 = REDU_ConCreditTransferList_LCTRL.getCreditTransferList('reduivy__Individual_Program_Enrollment__c', masterIPE.Id, 'reduivy__Contact__c', ctAppListFields , true, hrefTargetType, UserInfo.getLanguage());
                System.Assert.areEqual(true, objResponse2.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            } catch (Exception exp) {

                REDU_Logging_UTIL.debug('testForSetupUser', exp.getMessage());
                hasError ++;
            }

            try{
                
                // Test credit transfer application submission
                REDU_LightningResponse objResponse3 = REDU_ConCreditTransferList_LCTRL.submitCTApplication(JSON.serialize(ctApplication));
                System.Assert.areEqual(true, objResponse3.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            } catch (Exception exp) {

                REDU_Logging_UTIL.debug('testForSetupUser', exp.getMessage());
                hasError ++;
            }

            try{
                
                // Test credit transfer application rejection
                REDU_LightningResponse objResponse5 = REDU_ConCreditTransferList_LCTRL.rejectCTApplication(JSON.serialize(ctApplication));
                System.Assert.areEqual(true, objResponse5.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            } catch (Exception exp) {

                REDU_Logging_UTIL.debug('testForSetupUser', exp.getMessage());
                hasError ++;
            }
        }
        Test.stopTest();

        System.Assert.areEqual(4, hasError, 'Setup user should not have access to RIO Education fields.');
    }

    /**
     * @description Test as student user for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        reduivy__Credit_Transfer_Application__c ctApplication = [SELECT Id FROM reduivy__Credit_Transfer_Application__c WHERE reduivy__Contact__c = :masterIPE.reduivy__Contact__c LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];
        String ctAppListFields = 'Name;reduivy__Agreement_Unit_Equivalent__c;reduivy__Approved_Unit_Codes__c;reduivy__Credits_Attempted__c;reduivy__Credits_Earned__c;reduivy__Completed_Date__c;reduivy__Status__c';
        String hrefTargetType = '_self';

        System.runAs(studentUser){
            Test.startTest();

            // Test from contact object
            REDU_LightningResponse objResponse1 = REDU_ConCreditTransferList_LCTRL.getCreditTransferList('Contact', masterIPE.reduivy__Contact__c, 'Id', ctAppListFields , true, hrefTargetType, UserInfo.getLanguage());
            System.Assert.areEqual(true, objResponse1.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            // Test from individual program enrollment object
            REDU_LightningResponse objResponse2 = REDU_ConCreditTransferList_LCTRL.getCreditTransferList('reduivy__Individual_Program_Enrollment__c', masterIPE.Id, 'reduivy__Contact__c', ctAppListFields , true, hrefTargetType, UserInfo.getLanguage());
            System.Assert.areEqual(true, objResponse2.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            // Test credit transfer application submission
            REDU_LightningResponse objResponse3 = REDU_ConCreditTransferList_LCTRL.submitCTApplication(JSON.serialize(ctApplication));
            System.Assert.areEqual(true, objResponse3.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            // Test credit transfer application rejection
            REDU_LightningResponse objResponse5 = REDU_ConCreditTransferList_LCTRL.rejectCTApplication(JSON.serialize(ctApplication));
            System.Assert.areEqual(true, objResponse5.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpeAuditIdvPlanStructure_LCTRL
     */
    @isTest   
    static void testForFacultyUser() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Integer hasError = 0;

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        reduivy__Credit_Transfer_Application__c ctApplication = [SELECT Id FROM reduivy__Credit_Transfer_Application__c WHERE reduivy__Contact__c = :masterIPE.reduivy__Contact__c LIMIT 1];
        String ctAppListFields = 'Name;reduivy__Agreement_Unit_Equivalent__c;reduivy__Approved_Unit_Codes__c;reduivy__Credits_Attempted__c;reduivy__Credits_Earned__c;reduivy__Completed_Date__c;reduivy__Status__c';
        String hrefTargetType = '_self';

        Test.startTest();
        System.runAs(FACULTY_USER){

            try{
                
                // Test from contact object
                REDU_LightningResponse objResponse1 = REDU_ConCreditTransferList_LCTRL.getCreditTransferList('Contact', masterIPE.reduivy__Contact__c, 'Id', ctAppListFields , true, hrefTargetType, UserInfo.getLanguage());
                System.Assert.areEqual(true, objResponse1.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            } catch (Exception exp) {
                System.Assert.fail('This should not fail. Error:' + exp.getMessage());
            }

            try{
                
                // Test from individual program enrollment object
                REDU_LightningResponse objResponse2 = REDU_ConCreditTransferList_LCTRL.getCreditTransferList('reduivy__Individual_Program_Enrollment__c', masterIPE.Id, 'reduivy__Contact__c', ctAppListFields , true, hrefTargetType, UserInfo.getLanguage());
                System.Assert.areEqual(true, objResponse2.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            } catch (Exception exp) {
                System.Assert.fail('This should not fail. Error:' + exp.getMessage());
            }

            try{
                
                // Test credit transfer application submission
                REDU_LightningResponse objResponse3 = REDU_ConCreditTransferList_LCTRL.submitCTApplication(JSON.serialize(ctApplication));
                System.Assert.areEqual(true, objResponse3.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            } catch (Exception exp) {

                REDU_Logging_UTIL.debug('testForFacultyUser', exp.getMessage());
                hasError ++;
            }

            try{
                
                // Test credit transfer application rejection
                REDU_LightningResponse objResponse5 = REDU_ConCreditTransferList_LCTRL.rejectCTApplication(JSON.serialize(ctApplication));
                System.Assert.areEqual(true, objResponse5.isSuccess, 'Failed to get response from REDU_IpeAuditIdvPlanStructure_TEST');

            } catch (Exception exp) {

                REDU_Logging_UTIL.debug('testForFacultyUser', exp.getMessage());
                hasError ++;
            }
        }
        Test.stopTest();

        System.Assert.areEqual(2, hasError, 'Faculty user should not have access to RIO Education fields.');
    }
}