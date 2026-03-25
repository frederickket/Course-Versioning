/**
 * @author      WDCi (VTan)
 * @date        Oct 2023
 * @group       Test
 * @description Test class for REDU_IpePathwayTermUnitTable_LCTRL
 * @changehistory
 * ISS-001753 06-11-2023 VTan - New class
 * ISS-002345 23-03-2025 XiRouh - Updated to call the getIndividualPlanStructureUnits with master ipe id
 * ISS-002336 25-03-2025 XiRouh - updated to call the getIndividualPlanStructureUnits with missedFailedUnitListingOption param
 * ISS-002374 14-04-2025 XiRouh - Added test class for getFinalGradeReleasedStatuses()
 * ISS-002400 02-05-2025 XiRouh - Added new test method to cover the scenarios in ISS-002400
 * ISS-002541 14-07-2025 XiRouh - Added new test method to cover the scenarios in ISS-002541
 * ISS-002743 15-12-2025 XiRouh - Added test methods to consider the IEN within the same Individual Academic Profile context and Updated test methods that create IENs to link them with IPF
 */
@isTest
public inherited sharing class REDU_IpePathwayTermUnitTable_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PLAN_STRUCTURE_GROUP = 'BACBIS_MajorA_GROUPA_1_1';
	static final String STUDY_PLAN_STRUCTURE_UNIT = 'BACBIS_MajorA_BUS101';
	static final String STUDY_UNIT = 'BUS101';

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
			testFactory.initStudentData(CTA_Helper.getApiName(), true);

            REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Grade_Item__c WHERE reduivy__Sample_Record_Code__c != null]);
            REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Sample_Record_Code__c != null]);
            REDU_SystemMode_UTIL.doDelete([SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Sample_Record_Code__c != null]);

            Test.stopTest();
        }

    }

    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL with multi currencies
     *              We are not able to really assert the result because the the column metadata is handler by ipePathwayTermUnitCell.js
     */
    @isTest
    static void testForAdminMasterIPEWithMultiCurrencies() {

        if (!ORG_Helper.isMultiCurrenciesOrg()) {
            //we won't run this test in non multi currencies org as it will fail
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name;reduivy__Study_Offering__c.reduivy__Fee_Amount__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];
        reduivy__Study_Plan_Structure__c spsUnitBUS101 = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_UNIT LIMIT 1];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];

        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

        reduivy__Study_Offering__c sof = [SELECT Id, Name, reduivy__Academic_Term__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = : idvPathwayList.get(0).reduivy__Academic_Term__c AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = : STUDY_UNIT AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY' LIMIT 1];

        // Prepare new IPS Unit for upsert
        List<String> ipsInProgressStatus = IPS_Helper.getUnitInProgressStatuses();
        reduivy__Individual_Plan_Structure__c ips = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
            ipsGroupList[0].reduivy__Sample_Record_Code__c + masterIPE.reduivy__Sample_Record_Code__c, 
            masterIPE.Id, 
            ipsGroupList[0].Id,
            spsUnitBUS101.Id,
            IPS_Helper.CATEGORY_REQUIRED, 
            10, 
            true, 
            ipsInProgressStatus[0]
        );

        //Pre-test validation
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
        System.Assert.isTrue(ienList.isEmpty(), 'No Individual Enrollment should be created before the test');

        List<REDU_CustomFilter_OBJ> customFilterConfigs = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter = new REDU_CustomFilter_OBJ();
        customFilter.seq = 1;
        customFilter.showFilter = true;
        customFilter.label = 'Test';
        customFilter.mapping = 'Id!=null';
        customFilterConfigs.add(customFilter);

        System.runAs(ADMIN_USER){

            Test.startTest();

            //upsertEnrollment
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.ips = ips;
            groupIps.sof = sof;
            REDU_LightningResponse ipeStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, JSON.serialize(groupIps), IEN_Helper.ENROLLMENT_ACTION_ENROLL, 'Enrolled');

            ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
            System.Assert.isFalse(ienList.isEmpty(), 'Missing Individual Enrollment Record.');

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[0].Id, 
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                JSON.serialize(customFilterConfigs), 
                'All',
                UserInfo.getLanguage(),
                null
            );

            REDU_LightningResponse studyOfferingStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getStudyOfferingStatuses();
            REDU_LightningResponse ipsUnitStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnitStatuses();
            REDU_LightningResponse ienStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualEnrollmentStatuses();

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, studyOfferingStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ipsUnitStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ienStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ipeStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);

            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM));
            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.IPE_PARAM));
            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.IPW_PARAM));
            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.MASTERIPE_PARAM));
            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.SCE_PARAM));
            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.UNITTABLECOLUMNS_PARAM));

            Boolean foundTestRecord = false;
            List<REDU_IndividualPlanStructure_OBJ> ipsUnitWrappers = (List<REDU_IndividualPlanStructure_OBJ>) JSON.deserialize(JSON.serialize(responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM)), List<REDU_IndividualPlanStructure_OBJ>.class);
            for (REDU_IndividualPlanStructure_OBJ ipsObj : ipsUnitWrappers) {
                if (ipsObj.sof != null) {
                    System.Assert.isTrue(ipsObj.sof.isSet('CurrencyIsoCode'), 'The CurrencyIsoCode is not found.');

                    foundTestRecord = true;
                }
            }

            System.Assert.isTrue(foundTestRecord, 'Test is not validated.');
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testForAdminMasterIPE() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];
        reduivy__Study_Plan_Structure__c spsUnitBUS101 = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_UNIT LIMIT 1];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];
        
        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

        reduivy__Study_Offering__c sof = [SELECT Id, Name, reduivy__Academic_Term__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = : idvPathwayList.get(0).reduivy__Academic_Term__c AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = : STUDY_UNIT AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY' LIMIT 1];

        // Prepare new IPS Unit for upsert
        List<String> ipsInProgressStatus = IPS_Helper.getUnitInProgressStatuses();
        reduivy__Individual_Plan_Structure__c ips = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
            ipsGroupList[0].reduivy__Sample_Record_Code__c + masterIPE.reduivy__Sample_Record_Code__c, 
            masterIPE.Id, 
            ipsGroupList[0].Id,
            spsUnitBUS101.Id,
            IPS_Helper.CATEGORY_REQUIRED, 
            10, 
            true, 
            ipsInProgressStatus[0]
        );

        //Pre-test validation
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
        System.Assert.isTrue(ienList.isEmpty(), 'No Individual Enrollment should be created before the test');

        List<REDU_CustomFilter_OBJ> customFilterConfigs = new List<REDU_CustomFilter_OBJ>();
        REDU_CustomFilter_OBJ customFilter = new REDU_CustomFilter_OBJ();
        customFilter.seq = 1;
        customFilter.showFilter = true;
        customFilter.label = 'Test';
        customFilter.mapping = 'Id!=null';
        customFilterConfigs.add(customFilter);
        
        System.runAs(ADMIN_USER){

            Test.startTest();

            //upsertEnrollment
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.ips = ips;
            groupIps.sof = sof;
            REDU_LightningResponse ipeStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, JSON.serialize(groupIps), IEN_Helper.ENROLLMENT_ACTION_ENROLL, 'Enrolled');

            ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
            System.Assert.isFalse(ienList.isEmpty(), 'Missing Individual Enrollment Record.');
            
            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[0].Id, 
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                JSON.serialize(customFilterConfigs), 
                'All',
                UserInfo.getLanguage(),
                null
            );

            REDU_LightningResponse studyOfferingStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getStudyOfferingStatuses();
            REDU_LightningResponse ipsUnitStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnitStatuses();
            REDU_LightningResponse ienStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualEnrollmentStatuses();

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, studyOfferingStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ipsUnitStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ienStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ipeStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);

            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM));
            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.IPE_PARAM));
            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.IPW_PARAM));
            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.MASTERIPE_PARAM));
            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.SCE_PARAM));
            System.Assert.isTrue(responseData.containsKey(REDU_IpePathwayTermUnitTable_LCTRL.UNITTABLECOLUMNS_PARAM));
        }
    }

    /**
     * @description Test hidden with user mode = student as admin for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testHiddenWithStudentModeForAdminMasterIPE() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];
        reduivy__Study_Plan_Structure__c spsUnitBUS101 = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_UNIT LIMIT 1];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Plan_Structure__c> bus101IpsList = new List<reduivy__Individual_Plan_Structure__c>();
        for (reduivy__Individual_Plan_Structure__c bus101Ips : [SELECT Id,
            reduivy__Hide_in_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Study_Plan_Structure__c =: spsUnitBUS101.Id
        ]) {

            bus101Ips.reduivy__Hide_in_Enrollment__c = true;
            bus101IpsList.add(bus101Ips);
        }

        // update to hide the bus101 IPS
        update bus101IpsList;

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];
        
        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');
        
        System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id, 
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[0].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_STUDENT, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null,
                'All',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            List<REDU_IndividualPlanStructure_OBJ> unitIpsList = (List<REDU_IndividualPlanStructure_OBJ>) JSON.deserialize(JSON.serialize(unitIpsWrapperListResponse), List<REDU_IndividualPlanStructure_OBJ>.class);
            System.Assert.areEqual(3, unitIpsList.size());

            for (REDU_IndividualPlanStructure_OBJ unitIps : unitIpsList) {
                System.Assert.areNotEqual(spsUnitBUS101.Id, unitIps.ips.reduivy__Study_Plan_Structure__c);
            }
        }
    }

    /**
     * @description Test hidden with user mode = admin as admin for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testHiddenWithAdminModeForAdminMasterIPE() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];
        reduivy__Study_Plan_Structure__c spsUnitBUS101 = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_UNIT LIMIT 1];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Plan_Structure__c> bus101IpsList = new List<reduivy__Individual_Plan_Structure__c>();
        for (reduivy__Individual_Plan_Structure__c bus101Ips : [SELECT Id,
            reduivy__Hide_in_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Study_Plan_Structure__c =: spsUnitBUS101.Id
        ]) {

            bus101Ips.reduivy__Hide_in_Enrollment__c = true;
            bus101IpsList.add(bus101Ips);
        }

        // update to hide the bus101 IPS
        update bus101IpsList;

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];
        
        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');
        
        System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id, 
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[0].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null,
                'All',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            List<REDU_IndividualPlanStructure_OBJ> unitIpsList = (List<REDU_IndividualPlanStructure_OBJ>) JSON.deserialize(JSON.serialize(unitIpsWrapperListResponse), List<REDU_IndividualPlanStructure_OBJ>.class);
            System.Assert.areEqual(4, unitIpsList.size());

            Boolean foundBus101 = false;
            for (REDU_IndividualPlanStructure_OBJ unitIps : unitIpsList) {
                if (spsUnitBUS101.Id == unitIps.ips.reduivy__Study_Plan_Structure__c) {
                    foundBus101 = true;
                }
            }

            System.Assert.areEqual(true, foundBus101, 'No BUS101 sps found.');
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL. Run from child individual program enrollment.
     */
    @isTest
    static void testForAdminChildIPE() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c childIPE = [SELECT Id, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c, reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getChildEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :childIPE.Id AND RecordTypeId = : ispGroupRTID];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        // Include variation of study cohort enrollment without class standing.
        reduivy__Study_Cohort_Enrollment__c sce = [SELECT Id, reduivy__Class_Standing__c FROM reduivy__Study_Cohort_Enrollment__c LIMIT 1];
        sce.reduivy__Class_Standing__c = '';
        
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
                                                                    reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
                                                                    FROM reduivy__Individual_Pathway__c 
                                                                    WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : childIPE.reduivy__Master_Enrollment__c];
        
        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

        System.runAs(ADMIN_USER){

            update sce;

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                childIPE.reduivy__Master_Enrollment__c,
                childIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[0].Id, 
                childIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );
            
            REDU_LightningResponse ipeStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualEnrollmentStatuses();

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ipeStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL. Test with custom individual plan structure.
     */
    @isTest
    static void testForAdminCustomIPS() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
                                                                    reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
                                                                    FROM reduivy__Individual_Pathway__c 
                                                                    WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];

        reduivy__Study_Plan_Structure__c spsUnitBUS101 = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_UNIT LIMIT 1];

        reduivy__Study_Offering__c sof = [SELECT Id, Name, reduivy__Academic_Term__c, reduivy__Sample_Record_Code__c
                                            FROM reduivy__Study_Offering__c 
                                            WHERE reduivy__Academic_Term__c = : idvPathwayList.get(0).reduivy__Academic_Term__c AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = : STUDY_UNIT AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY' LIMIT 1];

        //Pre-test validation
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
        System.Assert.isTrue(ienList.isEmpty(), 'No Individual Enrollment should be created before the test');

        System.runAs(ADMIN_USER){

            List<String> ipsInProgressStatus = IPS_Helper.getUnitInProgressStatuses();
            reduivy__Individual_Plan_Structure__c customIPSGroup = REDU_TestData_UTIL.newIndividualGroupPlanStructure(
                                                                'Custom IPS Group', 
                                                                masterIPE.Id, 
                                                                null, 
                                                                null, 
                                                                IPS_Helper.CATEGORY_REQUIRED, 
                                                                10.0, 
                                                                10.0, 
                                                                0, 
                                                                10.0, 
                                                                ipsInProgressStatus[0]);

            insert customIPSGroup;

            // IPS Unit without SPS
            reduivy__Individual_Plan_Structure__c customIPSUnit = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
                                                        customIPSGroup.reduivy__Sample_Record_Code__c + masterIPE.reduivy__Sample_Record_Code__c, 
                                                        masterIPE.Id, 
                                                        customIPSGroup.Id,
                                                        null,
                                                        IPS_Helper.CATEGORY_REQUIRED, 
                                                        10, 
                                                        true, 
                                                        ipsInProgressStatus[0]);
            insert customIPSUnit;

            Test.startTest();

            //upsertEnrollment
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.ips = customIPSGroup;
            groupIps.sof = sof;
            REDU_LightningResponse ipeStatusResponse1 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, JSON.serialize(groupIps), IEN_Helper.ENROLLMENT_ACTION_JOINWAITLIST, 'Waitlisted');
            REDU_LightningResponse ipeStatusResponse2 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, JSON.serialize(groupIps), IEN_Helper.ENROLLMENT_ACTION_ENROLL, 'Enrolled');
            REDU_LightningResponse ipeStatusResponse3 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, JSON.serialize(groupIps), IEN_Helper.ENROLLMENT_ACTION_UNENROLLREQUESTED, 'Withdrawal Requested');
            REDU_LightningResponse ipeStatusResponse4 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, JSON.serialize(groupIps), IEN_Helper.ENROLLMENT_ACTION_UNENROLL, 'Withdrawn');
            REDU_LightningResponse ipeStatusResponse5 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, JSON.serialize(groupIps), IEN_Helper.ENROLLMENT_ACTION_WITHDRAWENROLLREQUESTED, 'Not Started');
            REDU_LightningResponse ipeStatusResponse6 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, JSON.serialize(groupIps), IEN_Helper.ENROLLMENT_ACTION_WITHDRAWWAITLIST, 'Not Started');

            ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
            System.Assert.isFalse(ienList.isEmpty(), 'Missing Individual Enrollment Record.');
            
            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                customIPSGroup.Id, 
                idvPathwayList[0].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ipeStatusResponse1.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
        }
    }

    /**
     * @description Test as setup user for REDU_IpePathwayTermUnitTable_LCTRL.
     */
    @isTest
    static void testForSetupUserMasterIPE() {

        User setupUser = testFactory.getSetupUser();
        Boolean hasError = false;

        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
                                                                    reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
                                                                    FROM reduivy__Individual_Pathway__c 
                                                                    WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];
        
        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

        reduivy__Study_Offering__c sof = [SELECT Id, Name, reduivy__Academic_Term__c, reduivy__Sample_Record_Code__c
                                            FROM reduivy__Study_Offering__c 
                                            WHERE reduivy__Academic_Term__c = : idvPathwayList.get(0).reduivy__Academic_Term__c AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = : STUDY_UNIT AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY' LIMIT 1];

        // Prepare new IPS Unit for upsert
        List<String> ipsInProgressStatus = IPS_Helper.getUnitInProgressStatuses();
        reduivy__Individual_Plan_Structure__c ips = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
                                                    ipsGroupList[0].reduivy__Sample_Record_Code__c + masterIPE.reduivy__Sample_Record_Code__c, 
                                                    masterIPE.Id, 
                                                    ipsGroupList[0].Id,
                                                    null,
                                                    IPS_Helper.CATEGORY_REQUIRED, 
                                                    10, 
                                                    true, 
                                                    ipsInProgressStatus[0]);

        //Pre-test validation
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
        System.Assert.isTrue(ienList.isEmpty(), 'No Individual Enrollment should be created before the test');

        //upsertEnrollment
        REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
        groupIps.ips = ips;
        groupIps.sof = sof;

        String groupIpsJSON = JSON.serialize(groupIps);
        try{

            System.runAs(setupUser){

                Test.startTest();
    
                REDU_LightningResponse ipeStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, groupIpsJSON, IEN_Helper.ENROLLMENT_ACTION_ENROLL, 'Enrolled');
    
                ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
                System.Assert.isFalse(ienList.isEmpty(), 'Missing Individual Enrollment Record.');
                
                REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                    masterIPE.Id, 
                    masterIPE.Id, 
                    ipsGroupList[0].Id, 
                    idvPathwayList[0].Id,  
                    masterIPE.reduivy__Default_Campus__c, 
                    ipsUnitFieldString, 
                    null, 
                    USR_Helper.USER_MODE_ADMIN, 
                    IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                    null, 
                    'All',
                    UserInfo.getLanguage(),
                    null
                );
    
                REDU_LightningResponse studyOfferingStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getStudyOfferingStatuses();
                REDU_LightningResponse ipsUnitStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnitStatuses();
                REDU_LightningResponse ienStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualEnrollmentStatuses();
    
                Test.stopTest();
            }

        } catch (Exception exp) {

            REDU_Logging_UTIL.debug('testForSetupUser', exp.getMessage());
            hasError = true;
        }
        System.Assert.areEqual(true, hasError, 'Setup user should not have access to RIO Education fields.');
    }

    /**
     * @description Test as student user for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testForStudentUserMasterIPE() {

        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];
        reduivy__Study_Plan_Structure__c spsUnitBUS101 = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_UNIT LIMIT 1];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        masterIPE.reduivy__Cohort_ID__c = 'Cohort 1';
        update masterIPE;

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
                                                                    reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
                                                                    FROM reduivy__Individual_Pathway__c 
                                                                    WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];
        
        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

        reduivy__Study_Offering__c sof = [SELECT Id, Name, reduivy__Academic_Term__c, reduivy__Sample_Record_Code__c
                                            FROM reduivy__Study_Offering__c 
                                            WHERE reduivy__Academic_Term__c = : idvPathwayList.get(0).reduivy__Academic_Term__c AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = : STUDY_UNIT AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY' LIMIT 1];

        // Prepare new IPS Unit for upsert
        List<String> ipsInProgressStatus = IPS_Helper.getUnitInProgressStatuses();
        reduivy__Individual_Plan_Structure__c ips = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
                                                    ipsGroupList[0].reduivy__Sample_Record_Code__c + masterIPE.reduivy__Sample_Record_Code__c, 
                                                    masterIPE.Id, 
                                                    ipsGroupList[0].Id,
                                                    spsUnitBUS101.Id,
                                                    IPS_Helper.CATEGORY_REQUIRED, 
                                                    10, 
                                                    true, 
                                                    ipsInProgressStatus[0]);

        //Pre-test validation
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
        System.Assert.isTrue(ienList.isEmpty(), 'No Individual Enrollment should be created before the test');

        System.runAs(studentUser){

            Test.startTest();

            //upsertEnrollment
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.ips = ips;
            groupIps.sof = sof;
            REDU_LightningResponse ipeStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, JSON.serialize(groupIps), IEN_Helper.ENROLLMENT_ACTION_ENROLL, 'Enrolled');

            ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
            System.Assert.isFalse(ienList.isEmpty(), 'Missing Individual Enrollment Record.');
            
            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id, 
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[0].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            REDU_LightningResponse studyOfferingStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getStudyOfferingStatuses();
            REDU_LightningResponse ipsUnitStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnitStatuses();
            REDU_LightningResponse ienStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualEnrollmentStatuses();

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, studyOfferingStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ipsUnitStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ienStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ipeStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
        }
    }

    /**
     * @description Test hidden with user mode = student as faculty for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testHiddenWithStudentModeForStudentUserMasterIPE() {

        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];
        reduivy__Study_Plan_Structure__c spsUnitBUS101 = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_UNIT LIMIT 1];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Plan_Structure__c> bus101IpsList = new List<reduivy__Individual_Plan_Structure__c>();
        for (reduivy__Individual_Plan_Structure__c bus101Ips : [SELECT Id,
            reduivy__Hide_in_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Study_Plan_Structure__c =: spsUnitBUS101.Id
        ]) {

            bus101Ips.reduivy__Hide_in_Enrollment__c = true;
            bus101IpsList.add(bus101Ips);
        }

        // update to hide the bus101 IPS
        update bus101IpsList;

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];
        
        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');
        
        System.runAs(studentUser){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id, 
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[0].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_STUDENT, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null,
                'All',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            List<REDU_IndividualPlanStructure_OBJ> unitIpsList = (List<REDU_IndividualPlanStructure_OBJ>) JSON.deserialize(JSON.serialize(unitIpsWrapperListResponse), List<REDU_IndividualPlanStructure_OBJ>.class);
            System.Assert.areEqual(3, unitIpsList.size());

            for (REDU_IndividualPlanStructure_OBJ unitIps : unitIpsList) {
                System.Assert.areNotEqual(spsUnitBUS101.Id, unitIps.ips.reduivy__Study_Plan_Structure__c);
            }
        }
    }

    /**
     * @description Test as faculty user for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testForFacultyUserMasterIPE() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];
        reduivy__Study_Plan_Structure__c spsUnitBUS101 = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_UNIT LIMIT 1];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        // Include variation of master IPE without class year.
        masterIPE.reduivy__Class_Year__c = '';

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
                                                                    reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
                                                                    FROM reduivy__Individual_Pathway__c 
                                                                    WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];
        
        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

        reduivy__Study_Offering__c sof = [SELECT Id, Name, reduivy__Academic_Term__c, reduivy__Sample_Record_Code__c
                                            FROM reduivy__Study_Offering__c 
                                            WHERE reduivy__Academic_Term__c = : idvPathwayList.get(0).reduivy__Academic_Term__c AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = : STUDY_UNIT AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY' LIMIT 1];

        // Prepare new IPS Unit for upsert
        List<String> ipsInProgressStatus = IPS_Helper.getUnitInProgressStatuses();
        reduivy__Individual_Plan_Structure__c ips = REDU_TestData_UTIL.newIndividualUnitPlanStructure(
                                                    ipsGroupList[0].reduivy__Sample_Record_Code__c + masterIPE.reduivy__Sample_Record_Code__c, 
                                                    masterIPE.Id, 
                                                    ipsGroupList[0].Id,
                                                    spsUnitBUS101.Id,
                                                    IPS_Helper.CATEGORY_REQUIRED, 
                                                    10, 
                                                    true, 
                                                    ipsInProgressStatus[0]);

        //Pre-test validation
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
        System.Assert.isTrue(ienList.isEmpty(), 'No Individual Enrollment should be created before the test');

        System.runAs(FACULTY_USER){

            update masterIPE;

            Test.startTest();

            //upsertEnrollment
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.ips = ips;
            groupIps.sof = sof;
            REDU_LightningResponse ipeStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(idvPathwayList[0].Id, JSON.serialize(groupIps), IEN_Helper.ENROLLMENT_ACTION_ENROLL, 'Enrolled');

            ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = : masterIPE.reduivy__Contact__c];
            System.Assert.isFalse(ienList.isEmpty(), 'Missing Individual Enrollment Record.');
            
            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id, 
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[0].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            REDU_LightningResponse studyOfferingStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getStudyOfferingStatuses();
            REDU_LightningResponse ipsUnitStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnitStatuses();
            REDU_LightningResponse ienStatusResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualEnrollmentStatuses();

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, studyOfferingStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ipsUnitStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ienStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            System.Assert.areEqual(true, ipeStatusResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
        }
    }

    /**
     * @description Test hidden with user mode = student as faculty for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testHiddenWithStudentModeForFacultyUserMasterIPE() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];
        reduivy__Study_Plan_Structure__c spsUnitBUS101 = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_UNIT LIMIT 1];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Plan_Structure__c> bus101IpsList = new List<reduivy__Individual_Plan_Structure__c>();
        for (reduivy__Individual_Plan_Structure__c bus101Ips : [SELECT Id,
            reduivy__Hide_in_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Study_Plan_Structure__c =: spsUnitBUS101.Id
        ]) {

            bus101Ips.reduivy__Hide_in_Enrollment__c = true;
            bus101IpsList.add(bus101Ips);
        }

        // update to hide the bus101 IPS
        update bus101IpsList;

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];
        
        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');
        
        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id, 
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[0].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_STUDENT, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null,
                'All',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            List<REDU_IndividualPlanStructure_OBJ> unitIpsList = (List<REDU_IndividualPlanStructure_OBJ>) JSON.deserialize(JSON.serialize(unitIpsWrapperListResponse), List<REDU_IndividualPlanStructure_OBJ>.class);
            System.Assert.areEqual(3, unitIpsList.size());

            for (REDU_IndividualPlanStructure_OBJ unitIps : unitIpsList) {
                System.Assert.areNotEqual(spsUnitBUS101.Id, unitIps.ips.reduivy__Study_Plan_Structure__c);
            }
        }
    }

    /**
     * @description Test hidden with user mode = admin as faculty for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testHiddenWithAdminModeForFacultyUserMasterIPE() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];
        reduivy__Study_Plan_Structure__c spsUnitBUS101 = [SELECT Id FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Sample_Record_Code__c = : STUDY_PLAN_STRUCTURE_UNIT LIMIT 1];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Plan_Structure__c> bus101IpsList = new List<reduivy__Individual_Plan_Structure__c>();
        for (reduivy__Individual_Plan_Structure__c bus101Ips : [SELECT Id,
            reduivy__Hide_in_Enrollment__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE reduivy__Study_Plan_Structure__c =: spsUnitBUS101.Id
        ]) {

            bus101Ips.reduivy__Hide_in_Enrollment__c = true;
            bus101IpsList.add(bus101Ips);
        }

        // update to hide the bus101 IPS
        update bus101IpsList;

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c = 1 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id];
        
        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');
        
        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id, 
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[0].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null,
                'All',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            List<REDU_IndividualPlanStructure_OBJ> unitIpsList = (List<REDU_IndividualPlanStructure_OBJ>) JSON.deserialize(JSON.serialize(unitIpsWrapperListResponse), List<REDU_IndividualPlanStructure_OBJ>.class);
            System.Assert.areEqual(4, unitIpsList.size());

            Boolean foundBus101 = false;
            for (REDU_IndividualPlanStructure_OBJ unitIps : unitIpsList) {
                if (spsUnitBUS101.Id == unitIps.ips.reduivy__Study_Plan_Structure__c) {
                    foundBus101 = true;
                }
            }

            System.Assert.areEqual(true, foundBus101, 'No BUS101 sps found.');
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL With Missed Failed Option = None
     */
    @isTest
    static void testForAdminWithMissedFailedOptionNone() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Status__c, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c < 3 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id ORDER BY reduivy__Term_Number__c ASC
        ];

        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE Id != :masterIpe.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];

        List<reduivy__Individual_Pathway__c> ipwToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[0].Id,
            reduivy__Academic_Term__c = stm[0].Id,
            reduivy__Individual_Academic_Progress__c = null
        ));

        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[1].Id,
            reduivy__Academic_Term__c = masterIPE.reduivy__Starting_Term__c,
            reduivy__Individual_Academic_Progress__c = null
        ));

        update ipwToBeUpdated;

        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            //Sof for previous term to create ien
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = stm[0].Id,
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

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'None',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);

            List<Object> childUnitsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            System.Assert.areEqual(4, childUnitsIpsResponse.size());

            for (Object obj : childUnitsIpsResponse) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;

                System.Assert.isNotNull(unitObj.get('isMissedFailed'), 'isMissedFailed flag should not be null');
                
                System.Assert.areEqual(false, unitObj.get('isMissedFailed'), 'isMissedFailed should be false');
            }
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL With Missed Failed Option = All
     */
    @isTest
    static void testForAdminWithMissedFailedOptionAll() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Status__c, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c < 3 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id ORDER BY reduivy__Term_Number__c ASC
        ];

        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE Id != :masterIpe.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];

        List<reduivy__Individual_Pathway__c> ipwToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[0].Id,
            reduivy__Academic_Term__c = stm[0].Id,
            reduivy__Individual_Academic_Progress__c = null
        ));

        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[1].Id,
            reduivy__Academic_Term__c = masterIPE.reduivy__Starting_Term__c,
            reduivy__Individual_Academic_Progress__c = null
        ));

        update ipwToBeUpdated;

        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            //Sof for previous term to create ien
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = stm[0].Id,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed Fail',
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 0,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        System.runAs(ADMIN_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);

            List<Object> childUnitsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            System.Assert.areEqual(4, childUnitsIpsResponse.size());

            for (Object obj : childUnitsIpsResponse) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;

                System.Assert.isNotNull(unitObj.get('isMissedFailed'), 'isMissedFailed flag should not be null');
                
                System.Assert.areEqual(true, unitObj.get('isMissedFailed'), 'isMissedFailed should be true');
            }
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathwayTermUnitTable_LCTRL With Missed Failed Option = None
     */
    @isTest
    static void testForFacultyWithMissedFailedOptionNone() {

        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Status__c, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c < 3 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id ORDER BY reduivy__Term_Number__c ASC
        ];

        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE Id != :masterIpe.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];

        List<reduivy__Individual_Pathway__c> ipwToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[0].Id,
            reduivy__Academic_Term__c = stm[0].Id,
            reduivy__Individual_Academic_Progress__c = null
        ));

        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[1].Id,
            reduivy__Academic_Term__c = masterIPE.reduivy__Starting_Term__c,
            reduivy__Individual_Academic_Progress__c = null
        ));

        update ipwToBeUpdated;

        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            //Sof for previous term to create ien
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = stm[0].Id,
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

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_FACULTY, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'None',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);

            List<Object> childUnitsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            System.Assert.areEqual(4, childUnitsIpsResponse.size());

            for (Object obj : childUnitsIpsResponse) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;

                System.Assert.isNotNull(unitObj.get('isMissedFailed'), 'isMissedFailed flag should not be null');
                
                System.Assert.areEqual(false, unitObj.get('isMissedFailed'), 'isMissedFailed should be false');
            }
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathwayTermUnitTable_LCTRL With Missed Failed Option = All
     */
    @isTest
    static void testForFacultyWithMissedFailedOptionAll() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Status__c, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c < 3 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id ORDER BY reduivy__Term_Number__c ASC
        ];

        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE Id != :masterIpe.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];

        List<reduivy__Individual_Pathway__c> ipwToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[0].Id,
            reduivy__Academic_Term__c = stm[0].Id,
            reduivy__Individual_Academic_Progress__c = null
        ));

        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[1].Id,
            reduivy__Academic_Term__c = masterIPE.reduivy__Starting_Term__c,
            reduivy__Individual_Academic_Progress__c = null
        ));

        update ipwToBeUpdated;

        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            //Sof for previous term to create ien
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = stm[0].Id,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed Fail',
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 0,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_FACULTY, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);

            List<Object> childUnitsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            System.Assert.areEqual(4, childUnitsIpsResponse.size());

            for (Object obj : childUnitsIpsResponse) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;

                System.Assert.isNotNull(unitObj.get('isMissedFailed'), 'isMissedFailed flag should not be null');
                
                System.Assert.areEqual(true, unitObj.get('isMissedFailed'), 'isMissedFailed should be true');
            }
        }
    }

    /**
     * @description Test as student for REDU_IpePathwayTermUnitTable_LCTRL With Missed Failed Option = None
     */
    @isTest
    static void testForStudentWithMissedFailedOptionNone() {
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Status__c, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c < 3 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id ORDER BY reduivy__Term_Number__c ASC
        ];

        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE Id != :masterIpe.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];

        List<reduivy__Individual_Pathway__c> ipwToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[0].Id,
            reduivy__Academic_Term__c = stm[0].Id,
            reduivy__Individual_Academic_Progress__c = null
        ));

        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[1].Id,
            reduivy__Academic_Term__c = masterIPE.reduivy__Starting_Term__c,
            reduivy__Individual_Academic_Progress__c = null
        ));

        update ipwToBeUpdated;

        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            //Sof for previous term to create ien
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = stm[0].Id,
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

        System.runAs(studentUser){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_STUDENT, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'None',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);

            List<Object> childUnitsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            System.Assert.areEqual(4, childUnitsIpsResponse.size());

            for (Object obj : childUnitsIpsResponse) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;

                System.Assert.isNotNull(unitObj.get('isMissedFailed'), 'isMissedFailed flag should not be null');
                
                System.Assert.areEqual(false, unitObj.get('isMissedFailed'), 'isMissedFailed should be false');
            }
        }
    }

    /**
     * @description Test as student for REDU_IpePathwayTermUnitTable_LCTRL With Missed Failed Option = All
     */
    @isTest
    static void testForStudentWithMissedFailedOptionAll() {
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Sample_Record_Code__c FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP];

        System.Assert.isFalse(ipsGroupList.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Status__c, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c < 3 AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id ORDER BY reduivy__Term_Number__c ASC
        ];

        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE Id != :masterIpe.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];

        List<reduivy__Individual_Pathway__c> ipwToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[0].Id,
            reduivy__Academic_Term__c = stm[0].Id,
            reduivy__Individual_Academic_Progress__c = null
        ));

        ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
            Id = idvPathwayList[1].Id,
            reduivy__Academic_Term__c = masterIPE.reduivy__Starting_Term__c,
            reduivy__Individual_Academic_Progress__c = null
        ));

        update ipwToBeUpdated;

        System.Assert.isFalse(idvPathwayList.isEmpty(), 'The actual value should be as expected');

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
            }
        }

        for(Id sunId : sunIds) {
            //Sof for previous term to create ien
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = stm[0].Id,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = 'Completed Fail',
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 0,
                reduivy__Bypass_Requirement_Met__c = true
            ));
        }

        insert ienToBeCreated;

        System.runAs(studentUser){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupList[0].Id, 
                idvPathwayList[1].Id, 
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_STUDENT, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Test.stopTest();

            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermUnitTable_LCTRL');
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);

            List<Object> childUnitsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            System.Assert.areEqual(4, childUnitsIpsResponse.size());

            for (Object obj : childUnitsIpsResponse) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;

                System.Assert.isNotNull(unitObj.get('isMissedFailed'), 'isMissedFailed flag should not be null');
                
                System.Assert.areEqual(true, unitObj.get('isMissedFailed'), 'isMissedFailed should be true');
            }
        }
    }

    /**
     * @description Test getInternalGradeReleasedStatuses() as student
     */
    @isTest
    static void testGetInternalGradeReleasedStatusesAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_IpePathwayTermUnitTable_LCTRL.getInternalGradeReleasedStatuses();

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            System.Assert.areEqual(JSON.serialize(IEN_Helper.getInternalGradeReleasedStatuses()), response.responseData);
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getInternalGradeReleasedStatuses() as faculty
     */
    @isTest
    static void testGetInternalGradeReleasedStatusesAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_IpePathwayTermUnitTable_LCTRL.getInternalGradeReleasedStatuses();

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            System.Assert.areEqual(JSON.serialize(IEN_Helper.getInternalGradeReleasedStatuses()), response.responseData);
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getInternalGradeReleasedStatuses() as student
     */
    @isTest
    static void testGetInternalGradeReleasedStatusesAsStudent() {
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
        
        System.runAs(reduStudent){
            Test.startTest();

            REDU_LightningResponse response = REDU_IpePathwayTermUnitTable_LCTRL.getInternalGradeReleasedStatuses();

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            System.Assert.areEqual(JSON.serialize(IEN_Helper.getInternalGradeReleasedStatuses()), response.responseData);
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getFinalGradeReleasedStatuses() as student
     */
    @isTest
    static void testGetFinalGradeReleasedStatusesAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_IpePathwayTermUnitTable_LCTRL.getFinalGradeReleasedStatuses();

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            System.Assert.areEqual(JSON.serialize(IEN_Helper.getFinalGradeReleasedStatuses()), response.responseData);
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getFinalGradeReleasedStatuses() as faculty
     */
    @isTest
    static void testGetFinalGradeReleasedStatusesAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_IpePathwayTermUnitTable_LCTRL.getFinalGradeReleasedStatuses();

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            System.Assert.areEqual(JSON.serialize(IEN_Helper.getFinalGradeReleasedStatuses()), response.responseData);
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getFinalGradeReleasedStatuses() as student
     */
    @isTest
    static void testGetFinalGradeReleasedStatusesAsStudent() {
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
        
        System.runAs(reduStudent){
            Test.startTest();

            REDU_LightningResponse response = REDU_IpePathwayTermUnitTable_LCTRL.getFinalGradeReleasedStatuses();

            // Verify response
            System.Assert.isTrue(response.isSuccess, 'Response should be successful');
            System.Assert.isTrue(String.isNotBlank(response.responseData), 'Response data should not be blank');
            System.Assert.areEqual(JSON.serialize(IEN_Helper.getFinalGradeReleasedStatuses()), response.responseData);
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in completed ipw for credit transferred unit as Admin
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForCreditTransferIenInCompletedIpwAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, reduivy__Status_Override__c FROM reduivy__Study_Offering__c];

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        List<reduivy__Credit_Transfer_Application__c> ctaToBeApproved = [SELECT Id, 
            reduivy__Status__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Approved_Unit_Codes__c
            FROM reduivy__Credit_Transfer_Application__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Status__c =: CTA_Helper.STATUS_TYPE_SUBMITTED
            LIMIT 1
        ]; 

        ctaToBeApproved[0].reduivy__Status__c = CTA_Helper.STATUS_TYPE_APPROVED;
        ctaToBeApproved[0].reduivy__Approved_Unit_Codes__c = STUDY_UNIT;

        update ctaToBeApproved;

        List<reduivy__Individual_Enrollment__c> ienForCreditTransfer = [SELECT Id, 
            reduivy__Grade_Result__c,
            reduivy__Study_Unit__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c =: STUDY_UNIT 
        ];

        System.Assert.areEqual(1, ienForCreditTransfer.size(), 'There should be 1 IEN for BUS101 credit transfer');

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Term__c> stmToBeUpdate = [SELECT Id, 
            reduivy__End_Date__c,
            reduivy__Start_Date__c
            FROM reduivy__Study_Term__c
            WHERE Id = :firstIpw[0].reduivy__Academic_Term__c
        ];

        stmToBeUpdate[0].reduivy__Start_Date__c = Date.today().addDays(-30);
        stmToBeUpdate[0].reduivy__End_Date__c = Date.today().addDays(-29);

        update stmToBeUpdate;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c,
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c, 
                ipsGroupList[0].Id, 
                firstIpw[0].Id, 
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienForCreditTransfer[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(ienForCreditTransfer[0].reduivy__Study_Unit__c, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in completed ipw for credit transferred unit as faculty
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForCreditTransferIenInCompletedIpwAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, reduivy__Status_Override__c FROM reduivy__Study_Offering__c];

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        List<reduivy__Credit_Transfer_Application__c> ctaToBeApproved = [SELECT Id, 
            reduivy__Status__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Approved_Unit_Codes__c
            FROM reduivy__Credit_Transfer_Application__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Status__c =: CTA_Helper.STATUS_TYPE_SUBMITTED
            LIMIT 1
        ]; 

        ctaToBeApproved[0].reduivy__Status__c = CTA_Helper.STATUS_TYPE_APPROVED;
        ctaToBeApproved[0].reduivy__Approved_Unit_Codes__c = STUDY_UNIT;

        update ctaToBeApproved;

        List<reduivy__Individual_Enrollment__c> ienForCreditTransfer = [SELECT Id, 
            reduivy__Grade_Result__c,
            reduivy__Study_Unit__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c =: STUDY_UNIT 
        ];

        System.Assert.areEqual(1, ienForCreditTransfer.size(), 'There should be 1 IEN for BUS101 credit transfer');

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Term__c> stmToBeUpdate = [SELECT Id, 
            reduivy__End_Date__c,
            reduivy__Start_Date__c
            FROM reduivy__Study_Term__c
            WHERE Id = :firstIpw[0].reduivy__Academic_Term__c
        ];

        stmToBeUpdate[0].reduivy__Start_Date__c = Date.today().addDays(-30);
        stmToBeUpdate[0].reduivy__End_Date__c = Date.today().addDays(-29);

        update stmToBeUpdate;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c,
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c, 
                ipsGroupList[0].Id, 
                firstIpw[0].Id, 
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienForCreditTransfer[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(ienForCreditTransfer[0].reduivy__Study_Unit__c, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in completed ipw for credit transferred unit as student
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForCreditTransferIenInCompletedIpwAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, reduivy__Status_Override__c FROM reduivy__Study_Offering__c];

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        List<reduivy__Credit_Transfer_Application__c> ctaToBeApproved = [SELECT Id, 
            reduivy__Status__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Approved_Unit_Codes__c
            FROM reduivy__Credit_Transfer_Application__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Status__c =: CTA_Helper.STATUS_TYPE_SUBMITTED
            LIMIT 1
        ]; 

        ctaToBeApproved[0].reduivy__Status__c = CTA_Helper.STATUS_TYPE_APPROVED;
        ctaToBeApproved[0].reduivy__Approved_Unit_Codes__c = STUDY_UNIT;

        update ctaToBeApproved;

        List<reduivy__Individual_Enrollment__c> ienForCreditTransfer = [SELECT Id, 
            reduivy__Grade_Result__c,
            reduivy__Study_Unit__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c =: STUDY_UNIT 
        ];

        System.Assert.areEqual(1, ienForCreditTransfer.size(), 'There should be 1 IEN for BUS101 credit transfer');

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Term__c> stmToBeUpdate = [SELECT Id, 
            reduivy__End_Date__c,
            reduivy__Start_Date__c
            FROM reduivy__Study_Term__c
            WHERE Id = :firstIpw[0].reduivy__Academic_Term__c
        ];

        stmToBeUpdate[0].reduivy__Start_Date__c = Date.today().addDays(-30);
        stmToBeUpdate[0].reduivy__End_Date__c = Date.today().addDays(-29);

        update stmToBeUpdate;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(reduStudent){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c,
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c, 
                ipsGroupList[0].Id, 
                firstIpw[0].Id, 
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienForCreditTransfer[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(ienForCreditTransfer[0].reduivy__Study_Unit__c, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw with sof offered for credit transferred unit as Admin
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForCreditTransferIenInInProgressIpwWithSofOfferedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        List<reduivy__Credit_Transfer_Application__c> ctaToBeApproved = [SELECT Id, 
            reduivy__Status__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Approved_Unit_Codes__c
            FROM reduivy__Credit_Transfer_Application__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Status__c =: CTA_Helper.STATUS_TYPE_SUBMITTED
            LIMIT 1
        ]; 

        ctaToBeApproved[0].reduivy__Status__c = CTA_Helper.STATUS_TYPE_APPROVED;
        ctaToBeApproved[0].reduivy__Approved_Unit_Codes__c = STUDY_UNIT;

        update ctaToBeApproved;

        List<reduivy__Individual_Enrollment__c> ienForCreditTransfer = [SELECT Id, 
            reduivy__Grade_Result__c,
            reduivy__Study_Unit__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c =: STUDY_UNIT
        ];

        System.Assert.areEqual(1, ienForCreditTransfer.size(), 'There should be 1 IEN for BUS101 credit transfer');

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c
            AND reduivy__Term_Number__c = 1
        ];

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c,
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c, 
                ipsGroupList[0].Id, 
                firstIpw[0].Id, 
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(4, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sunObj = (Map<String, Object>)wrapper.get('sun');
                if (sunObj != null && STUDY_UNIT.equals((String)sunObj.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isNotNull(bus101Wrapper, 'BUS101 entry should be found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.isNotNull(ipsCurrentIen, 'ipsCurrentIen should not be null for BUS101 entry');
            System.Assert.areEqual(ienForCreditTransfer[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(ienForCreditTransfer[0].reduivy__Study_Unit__c, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw with sof offered for credit transferred unit as Faculty
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForCreditTransferIenInInProgressIpwWithSofOfferedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        List<reduivy__Credit_Transfer_Application__c> ctaToBeApproved = [SELECT Id, 
            reduivy__Status__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Approved_Unit_Codes__c
            FROM reduivy__Credit_Transfer_Application__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Status__c =: CTA_Helper.STATUS_TYPE_SUBMITTED
            LIMIT 1
        ]; 

        ctaToBeApproved[0].reduivy__Status__c = CTA_Helper.STATUS_TYPE_APPROVED;
        ctaToBeApproved[0].reduivy__Approved_Unit_Codes__c = STUDY_UNIT;

        update ctaToBeApproved;

        List<reduivy__Individual_Enrollment__c> ienForCreditTransfer = [SELECT Id, 
            reduivy__Grade_Result__c,
            reduivy__Study_Unit__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c =: STUDY_UNIT 
        ];

        System.Assert.areEqual(1, ienForCreditTransfer.size(), 'There should be 1 IEN for BUS101 credit transfer');

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c
            AND reduivy__Term_Number__c = 1
        ];

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c,
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c, 
                ipsGroupList[0].Id, 
                firstIpw[0].Id, 
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(4, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sunObj = (Map<String, Object>)wrapper.get('sun');
                if (sunObj != null && STUDY_UNIT.equals((String)sunObj.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isNotNull(bus101Wrapper, 'BUS101 entry should be found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.isNotNull(ipsCurrentIen, 'ipsCurrentIen should not be null for BUS101 entry');
            System.Assert.areEqual(ienForCreditTransfer[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(ienForCreditTransfer[0].reduivy__Study_Unit__c, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw with sof offered for credit transferred unit as Student
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForCreditTransferIenInInProgressIpwWithSofOfferedAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Credit_Transfer_Application__c> ctaToBeApproved = [SELECT Id, 
            reduivy__Status__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Approved_Unit_Codes__c
            FROM reduivy__Credit_Transfer_Application__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Status__c =: CTA_Helper.STATUS_TYPE_SUBMITTED
            LIMIT 1
        ]; 

        ctaToBeApproved[0].reduivy__Status__c = CTA_Helper.STATUS_TYPE_APPROVED;
        ctaToBeApproved[0].reduivy__Approved_Unit_Codes__c = STUDY_UNIT;

        update ctaToBeApproved;

        List<reduivy__Individual_Enrollment__c> ienForCreditTransfer = [SELECT Id, 
            reduivy__Grade_Result__c,
            reduivy__Study_Unit__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c =: STUDY_UNIT
        ];

        System.Assert.areEqual(1, ienForCreditTransfer.size(), 'There should be 1 IEN for BUS101 credit transfer');

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c
            AND reduivy__Term_Number__c = 1
        ];

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(reduStudent){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c,
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c, 
                ipsGroupList[0].Id, 
                firstIpw[0].Id, 
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(4, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sunObj = (Map<String, Object>)wrapper.get('sun');
                if (sunObj != null && STUDY_UNIT.equals((String)sunObj.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isNotNull(bus101Wrapper, 'BUS101 entry should be found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.isNotNull(ipsCurrentIen, 'ipsCurrentIen should not be null for BUS101 entry');
            System.Assert.areEqual(ienForCreditTransfer[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(ienForCreditTransfer[0].reduivy__Study_Unit__c, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw without sof offered for credit transferred unit as Admin
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForCreditTransferIenInInProgressIpwWithoutSofOfferedAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, reduivy__Status_Override__c FROM reduivy__Study_Offering__c];

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        List<reduivy__Credit_Transfer_Application__c> ctaToBeApproved = [SELECT Id, 
            reduivy__Status__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Approved_Unit_Codes__c
            FROM reduivy__Credit_Transfer_Application__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Status__c =: CTA_Helper.STATUS_TYPE_SUBMITTED
            LIMIT 1
        ]; 

        ctaToBeApproved[0].reduivy__Status__c = CTA_Helper.STATUS_TYPE_APPROVED;
        ctaToBeApproved[0].reduivy__Approved_Unit_Codes__c = STUDY_UNIT;

        update ctaToBeApproved;

        List<reduivy__Individual_Enrollment__c> ienForCreditTransfer = [SELECT Id, 
            reduivy__Grade_Result__c,
            reduivy__Study_Unit__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c =: STUDY_UNIT
        ];

        System.Assert.areEqual(1, ienForCreditTransfer.size(), 'There should be 1 IEN for BUS101 credit transfer');

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c
            AND reduivy__Term_Number__c = 1
        ];

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c,
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c, 
                ipsGroupList[0].Id, 
                firstIpw[0].Id, 
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienForCreditTransfer[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(ienForCreditTransfer[0].reduivy__Study_Unit__c, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw without sof offered for credit transferred unit as Faculty
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForCreditTransferIenInInProgressIpwWithoutSofOfferedAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, reduivy__Status_Override__c FROM reduivy__Study_Offering__c];

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        List<reduivy__Credit_Transfer_Application__c> ctaToBeApproved = [SELECT Id, 
            reduivy__Status__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Approved_Unit_Codes__c
            FROM reduivy__Credit_Transfer_Application__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Status__c =: CTA_Helper.STATUS_TYPE_SUBMITTED
            LIMIT 1
        ]; 

        ctaToBeApproved[0].reduivy__Status__c = CTA_Helper.STATUS_TYPE_APPROVED;
        ctaToBeApproved[0].reduivy__Approved_Unit_Codes__c = STUDY_UNIT;

        update ctaToBeApproved;

        List<reduivy__Individual_Enrollment__c> ienForCreditTransfer = [SELECT Id, 
            reduivy__Grade_Result__c,
            reduivy__Study_Unit__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c =: STUDY_UNIT
        ];

        System.Assert.areEqual(1, ienForCreditTransfer.size(), 'There should be 1 IEN for BUS101 credit transfer');

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c
            AND reduivy__Term_Number__c = 1
        ];

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c,
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c, 
                ipsGroupList[0].Id, 
                firstIpw[0].Id, 
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienForCreditTransfer[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(ienForCreditTransfer[0].reduivy__Study_Unit__c, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw without sof offered for credit transferred unit as Student
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForCreditTransferIenInInProgressIpwWithoutSofOfferedAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, reduivy__Status_Override__c FROM reduivy__Study_Offering__c];

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        List<reduivy__Credit_Transfer_Application__c> ctaToBeApproved = [SELECT Id, 
            reduivy__Status__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
            reduivy__Sample_Record_Code__c,
            reduivy__Approved_Unit_Codes__c
            FROM reduivy__Credit_Transfer_Application__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Status__c =: CTA_Helper.STATUS_TYPE_SUBMITTED
            LIMIT 1
        ]; 

        ctaToBeApproved[0].reduivy__Status__c = CTA_Helper.STATUS_TYPE_APPROVED;
        ctaToBeApproved[0].reduivy__Approved_Unit_Codes__c = STUDY_UNIT;

        update ctaToBeApproved;

        List<reduivy__Individual_Enrollment__c> ienForCreditTransfer = [SELECT Id, 
            reduivy__Grade_Result__c,
            reduivy__Study_Unit__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :studentContacts[0].Id
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c =: STUDY_UNIT
        ];

        System.Assert.areEqual(1, ienForCreditTransfer.size(), 'There should be 1 IEN for BUS101 credit transfer');

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c
            AND reduivy__Term_Number__c = 1
        ];

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(reduStudent){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c,
                ctaToBeApproved[0].reduivy__Individual_Program_Enrollment__c, 
                ipsGroupList[0].Id, 
                firstIpw[0].Id, 
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienForCreditTransfer[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(ienForCreditTransfer[0].reduivy__Study_Unit__c, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in completed ipw for normal ien with completed sof as Admin
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForNormalIenInCompletedIpwWithCompletedSofAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentContacts[0].Id AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Term__c> stmToBeUpdate = [SELECT Id, 
            reduivy__End_Date__c,
            reduivy__Start_Date__c
            FROM reduivy__Study_Term__c
            WHERE Id = :firstIpw[0].reduivy__Academic_Term__c
        ];

        stmToBeUpdate[0].reduivy__Start_Date__c = Date.today().addDays(-30);
        stmToBeUpdate[0].reduivy__End_Date__c = Date.today().addDays(-29);

        update stmToBeUpdate;

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, 
            reduivy__Status_Override__c, 
            reduivy__Study_Unit__c,  
            reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = :stmToBeUpdate[0].Id
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        String bus101StudyUnitId;

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == STUDY_UNIT) {
                reduivy__Individual_Enrollment__c tempIen = new reduivy__Individual_Enrollment__c();
                tempIen.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
                tempIen.reduivy__Contact__c = studentContacts[0].Id;
                tempIen.reduivy__Study_Offering__c = sof.Id;
                tempIen.reduivy__Numerical_Grade__c = 100;
                tempIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

                ienToBeCreated.add(tempIen);

                bus101StudyUnitId = sof.reduivy__Study_Unit__c;
            }

            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        insert ienToBeCreated;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id ,
                masterIPE.Id , 
                ipsGroupList[0].Id, 
                firstIpw[0].Id,  
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienToBeCreated[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(bus101StudyUnitId, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in completed ipw for normal ien with completed sof as Faculty
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForNormalIenInCompletedIpwWithCompletedSofAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentContacts[0].Id AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Term__c> stmToBeUpdate = [SELECT Id, 
            reduivy__End_Date__c,
            reduivy__Start_Date__c
            FROM reduivy__Study_Term__c
            WHERE Id = :firstIpw[0].reduivy__Academic_Term__c
        ];

        stmToBeUpdate[0].reduivy__Start_Date__c = Date.today().addDays(-30);
        stmToBeUpdate[0].reduivy__End_Date__c = Date.today().addDays(-29);

        update stmToBeUpdate;

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, 
            reduivy__Status_Override__c, 
            reduivy__Study_Unit__c,  
            reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = :stmToBeUpdate[0].Id
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        String bus101StudyUnitId;

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == STUDY_UNIT) {
                reduivy__Individual_Enrollment__c tempIen = new reduivy__Individual_Enrollment__c();
                tempIen.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
                tempIen.reduivy__Contact__c = studentContacts[0].Id;
                tempIen.reduivy__Study_Offering__c = sof.Id;
                tempIen.reduivy__Numerical_Grade__c = 100;
                tempIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

                ienToBeCreated.add(tempIen);

                bus101StudyUnitId = sof.reduivy__Study_Unit__c;
            }

            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        insert ienToBeCreated;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id ,
                masterIPE.Id , 
                ipsGroupList[0].Id, 
                firstIpw[0].Id,  
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienToBeCreated[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(bus101StudyUnitId, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in completed ipw for normal ien with completed sof as student
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForNormalIenInCompletedIpwWithCompletedSofAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentContacts[0].Id AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Term__c> stmToBeUpdate = [SELECT Id, 
            reduivy__End_Date__c,
            reduivy__Start_Date__c
            FROM reduivy__Study_Term__c
            WHERE Id = :firstIpw[0].reduivy__Academic_Term__c
        ];

        stmToBeUpdate[0].reduivy__Start_Date__c = Date.today().addDays(-30);
        stmToBeUpdate[0].reduivy__End_Date__c = Date.today().addDays(-29);

        update stmToBeUpdate;

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, 
            reduivy__Status_Override__c, 
            reduivy__Study_Unit__c,  
            reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = :stmToBeUpdate[0].Id
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        String bus101StudyUnitId;

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == STUDY_UNIT) {
                reduivy__Individual_Enrollment__c tempIen = new reduivy__Individual_Enrollment__c();
                tempIen.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
                tempIen.reduivy__Contact__c = studentContacts[0].Id;
                tempIen.reduivy__Study_Offering__c = sof.Id;
                tempIen.reduivy__Numerical_Grade__c = 100;
                tempIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

                ienToBeCreated.add(tempIen);

                bus101StudyUnitId = sof.reduivy__Study_Unit__c;
            }

            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        insert ienToBeCreated;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(reduStudent){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id ,
                masterIPE.Id , 
                ipsGroupList[0].Id, 
                firstIpw[0].Id,  
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienToBeCreated[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(bus101StudyUnitId, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw for normal ien with completed sof as Admin
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForNormalIenInInProgressIpwWithCompletedSofAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentContacts[0].Id AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, 
            reduivy__Status_Override__c, 
            reduivy__Study_Unit__c,  
            reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = :firstIpw[0].reduivy__Academic_Term__c
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        String bus101StudyUnitId;

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == STUDY_UNIT) {
                reduivy__Individual_Enrollment__c tempIen = new reduivy__Individual_Enrollment__c();
                tempIen.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
                tempIen.reduivy__Contact__c = studentContacts[0].Id;
                tempIen.reduivy__Study_Offering__c = sof.Id;
                tempIen.reduivy__Numerical_Grade__c = 100;
                tempIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

                ienToBeCreated.add(tempIen);

                bus101StudyUnitId = sof.reduivy__Study_Unit__c;
            }

            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        insert ienToBeCreated;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id ,
                masterIPE.Id , 
                ipsGroupList[0].Id, 
                firstIpw[0].Id,  
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienToBeCreated[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(bus101StudyUnitId, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw for normal ien with completed sof as faculty
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForNormalIenInInProgressIpwWithCompletedSofAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentContacts[0].Id AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, 
            reduivy__Status_Override__c, 
            reduivy__Study_Unit__c,  
            reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = :firstIpw[0].reduivy__Academic_Term__c
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        String bus101StudyUnitId;

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == STUDY_UNIT) {
                reduivy__Individual_Enrollment__c tempIen = new reduivy__Individual_Enrollment__c();
                tempIen.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
                tempIen.reduivy__Contact__c = studentContacts[0].Id;
                tempIen.reduivy__Study_Offering__c = sof.Id;
                tempIen.reduivy__Numerical_Grade__c = 100;
                tempIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

                ienToBeCreated.add(tempIen);

                bus101StudyUnitId = sof.reduivy__Study_Unit__c;
            }

            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        insert ienToBeCreated;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id ,
                masterIPE.Id , 
                ipsGroupList[0].Id, 
                firstIpw[0].Id,  
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienToBeCreated[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(bus101StudyUnitId, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw for normal ien with completed sof as student
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForNormalIenInInProgressIpwWithCompletedSofAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentContacts[0].Id AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, 
            reduivy__Status_Override__c, 
            reduivy__Study_Unit__c,  
            reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = :firstIpw[0].reduivy__Academic_Term__c
        ];

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        String bus101StudyUnitId;

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == STUDY_UNIT) {
                reduivy__Individual_Enrollment__c tempIen = new reduivy__Individual_Enrollment__c();
                tempIen.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
                tempIen.reduivy__Contact__c = studentContacts[0].Id;
                tempIen.reduivy__Study_Offering__c = sof.Id;
                tempIen.reduivy__Numerical_Grade__c = 100;
                tempIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

                ienToBeCreated.add(tempIen);

                bus101StudyUnitId = sof.reduivy__Study_Unit__c;
            }

            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;

        insert ienToBeCreated;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(reduStudent){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id ,
                masterIPE.Id , 
                ipsGroupList[0].Id, 
                firstIpw[0].Id,  
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(1, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienToBeCreated[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(bus101StudyUnitId, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw for normal ien with multiple sof as Admin
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForNormalIenInInProgressIpwWithMultipleSofAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentContacts[0].Id AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, 
            reduivy__Status_Override__c, 
            reduivy__Study_Unit__c,  
            reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c,
            reduivy__Academic_Term__c,
            reduivy__Campus__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = :firstIpw[0].reduivy__Academic_Term__c
        ];

        List<reduivy__Study_Offering__c> sofToBeCreated = new  List<reduivy__Study_Offering__c>();

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        String bus101StudyUnitId;

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            sofToBeCreated.add(sof.clone(false, true, false, false));

            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == STUDY_UNIT) {
                reduivy__Individual_Enrollment__c tempIen = new reduivy__Individual_Enrollment__c();
                tempIen.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
                tempIen.reduivy__Contact__c = studentContacts[0].Id;
                tempIen.reduivy__Study_Offering__c = sof.Id;
                tempIen.reduivy__Numerical_Grade__c = 100;
                tempIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

                ienToBeCreated.add(tempIen);

                bus101StudyUnitId = sof.reduivy__Study_Unit__c;
            }

            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;
        insert sofToBeCreated;

        insert ienToBeCreated;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id ,
                masterIPE.Id , 
                ipsGroupList[0].Id, 
                firstIpw[0].Id,  
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(4, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

           Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienToBeCreated[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(bus101StudyUnitId, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw for normal ien with multiple sof as faculty
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForNormalIenInInProgressIpwWithMultipleSofAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentContacts[0].Id AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, 
            reduivy__Status_Override__c, 
            reduivy__Study_Unit__c,  
            reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c,
            reduivy__Academic_Term__c,
            reduivy__Campus__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = :firstIpw[0].reduivy__Academic_Term__c
        ];

        List<reduivy__Study_Offering__c> sofToBeCreated = new  List<reduivy__Study_Offering__c>();

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        String bus101StudyUnitId;

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            sofToBeCreated.add(sof.clone(false, true, false, false));

            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == STUDY_UNIT) {
                reduivy__Individual_Enrollment__c tempIen = new reduivy__Individual_Enrollment__c();
                tempIen.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
                tempIen.reduivy__Contact__c = studentContacts[0].Id;
                tempIen.reduivy__Study_Offering__c = sof.Id;
                tempIen.reduivy__Numerical_Grade__c = 100;
                tempIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

                ienToBeCreated.add(tempIen);

                bus101StudyUnitId = sof.reduivy__Study_Unit__c;
            }

            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;
        insert sofToBeCreated;

        insert ienToBeCreated;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id ,
                masterIPE.Id , 
                ipsGroupList[0].Id, 
                firstIpw[0].Id,  
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(4, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienToBeCreated[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(bus101StudyUnitId, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');

            Test.stopTest();
        }
    }

    /**
     * @description Test getIndividualPlanStructureUnits() in in progress ipw for normal ien with multiple sof as student
     */
    @isTest
    static void testGetIndividualPlanStructureUnitsForNormalIenInInProgressIpwWithMultipleSofAsStudent() {
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c = 'sandydoe@redu.example'
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId IN: studentContacts 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c,reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentContacts[0].Id AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Pathway__c> firstIpw = [SELECT Id, 
            reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND reduivy__Term_Number__c = 1
        ];

        List<reduivy__Study_Offering__c> sofToBeUpdated = [SELECT Id, 
            reduivy__Status_Override__c, 
            reduivy__Study_Unit__c,  
            reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c,
            reduivy__Academic_Term__c,
            reduivy__Campus__c
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Academic_Term__c = :firstIpw[0].reduivy__Academic_Term__c
        ];

        List<reduivy__Study_Offering__c> sofToBeCreated = new  List<reduivy__Study_Offering__c>();

        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        String bus101StudyUnitId;

        for(reduivy__Study_Offering__c sof : sofToBeUpdated){
            sofToBeCreated.add(sof.clone(false, true, false, false));

            if(sof.reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c == STUDY_UNIT) {
                reduivy__Individual_Enrollment__c tempIen = new reduivy__Individual_Enrollment__c();
                tempIen.RecordTypeId = IEN_Helper.getStudentRecordTypeId();
                tempIen.reduivy__Contact__c = studentContacts[0].Id;
                tempIen.reduivy__Study_Offering__c = sof.Id;
                tempIen.reduivy__Numerical_Grade__c = 100;
                tempIen.reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

                ienToBeCreated.add(tempIen);

                bus101StudyUnitId = sof.reduivy__Study_Unit__c;
            }

            sof.reduivy__Status_Override__c = SOF_Helper.STATUS_TYPE_COMPLETED;
        }

        update sofToBeUpdated;
        insert sofToBeCreated;

        insert ienToBeCreated;

        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';

        System.runAs(reduStudent){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id ,
                masterIPE.Id , 
                ipsGroupList[0].Id, 
                firstIpw[0].Id,  
                firstIpw[0].reduivy__Individual_Program_Enrollment__r.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY , 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
            List<Object> unitIpsWrapperListResponse = (List<Object>)responseData.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);

            System.Assert.isTrue(unitIpsWrapperListResponse != null && !unitIpsWrapperListResponse.isEmpty(), 'Response should contain unitIpsWrapperList');
            System.Assert.areEqual(4, unitIpsWrapperListResponse.size(), 'unitIpsWrapperListResponse.size() not matched');

            Map<String, Object> bus101Wrapper = null;
            for (Object wrapperObj : unitIpsWrapperListResponse) {
                Map<String, Object> wrapper = (Map<String, Object>)wrapperObj;
                Map<String, Object> sun = (Map<String, Object>)wrapper.get('sun');
                if (sun != null && 'BUS101'.equals((String)sun.get('reduivy__Unit_Code__c'))) {
                    bus101Wrapper = wrapper;
                    break;
                }
            }

            System.Assert.isTrue(bus101Wrapper != null, 'BUS101 wrapper not found in the response');

            Map<String, Object> ipsCurrentIen = (Map<String, Object>)bus101Wrapper.get('ipsCurrentIen');
            System.Assert.areEqual(ienToBeCreated[0].Id, (String)ipsCurrentIen.get('Id'), 'ipsCurrentIen not matched');

            Map<String, Object> ips = (Map<String, Object>)bus101Wrapper.get('ips');
            Map<String, Object> studyPlanStructure = (Map<String, Object>)ips.get('reduivy__Study_Plan_Structure__r');
            System.Assert.areEqual(bus101StudyUnitId, (String)studyPlanStructure.get('reduivy__Study_Unit__c'), 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c not matched');
            Test.stopTest();
        }
    }

    /**
     * @description Test upsertEnrollment() for different existing placeholder scenarios as an admin
     */
    @isTest
    static void testUpsertEnrollmentForDifferentExistingPlaceholderIenScenariosAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c, 
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Account campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        // Create study plan with 'Required Units Only' creation mode
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get required and optional units
        Set<Id> requiredUnits = new Set<Id>();
        Set<Id> optionalUnits = new Set<Id>();
        
        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, reduivy__Study_Unit__c, reduivy__Category__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ]) {
            if (sps.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED) {
                requiredUnits.add(sps.reduivy__Study_Unit__c);
            } else {
                optionalUnits.add(sps.reduivy__Study_Unit__c);
            }
        }

        System.Assert.isFalse(requiredUnits.isEmpty(), 'The required unit should not be empty.');
        System.Assert.isFalse(optionalUnits.isEmpty(), 'The optional unit should not be empty.');

        // Convert sets to lists for easier access
        List<Id> requiredUnitsList = new List<Id>(requiredUnits);
        List<Id> optionalUnitsList = new List<Id>(optionalUnits);

        // Create study offerings
        reduivy__Study_Offering__c sofForFirstRequiredUnit = new reduivy__Study_Offering__c(
            Name = 'RequiredUnitSof',
            reduivy__Study_Unit__c = requiredUnitsList[0],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        reduivy__Study_Offering__c sofForSecondRequiredUnit = new reduivy__Study_Offering__c(
            Name = 'SecondRequiredUnitSof',
            reduivy__Study_Unit__c = requiredUnitsList[1],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        reduivy__Study_Offering__c sofForFirstOptionalUnit = new reduivy__Study_Offering__c(
            Name = 'OptionalUnitSof',
            reduivy__Study_Unit__c = optionalUnitsList[0],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        // Create study offering for scenario 4
        reduivy__Study_Offering__c sofForScenario4 = new reduivy__Study_Offering__c(
            Name = 'Scenario4UnitSof',
            reduivy__Study_Unit__c = requiredUnitsList.size() > 2 ? requiredUnitsList[2] : optionalUnitsList[0],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        insert new List<reduivy__Study_Offering__c>{sofForFirstRequiredUnit, sofForSecondRequiredUnit, sofForFirstOptionalUnit, sofForScenario4};

        reduivy__Individual_Academic_Profile__c ipfToBeCreated = REDU_TestData_UTIL.newIndividualAcademicProfile(students[0].Id + '_' + students[0].Name, students[0].Id, students[0].Name, IPF_Helper.STATUS_ACTIVE, true);
    
        insert ipfToBeCreated;

        // Create Individual Program Enrollment
        reduivy__Individual_Program_Enrollment__c newIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            students[0].Id + '_' + studyPlan.Id, 
            students[0].Id, 
            studyPlan.reduivy__Study_Program__c, 
            studyPlan.Id, 
            null, 
            academicTerm.Id, 
            null, 
            null, 
            null, 
            null, 
            true, 
            IPE_Helper.getInProgressStatuses().get(0), 
            ipfToBeCreated.Id
        );
        insert newIpe;

        // Get the Individual Pathway
        reduivy__Individual_Pathway__c pathway = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :newIpe.Id AND reduivy__Academic_Term__c = :academicTerm.Id LIMIT 1];
        
        // Verify placeholder IENs were created for required units
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Study_Offering__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :newIpe.reduivy__Contact__c
            ORDER BY CreatedDate
        ];
        System.Assert.areEqual(requiredUnits.size(), ienList.size(), 'Placeholder Individual Enrollment should be created for required units.');

        Map<Id, String> createdPlaceholderIen = new Map<Id, String>();
        for(reduivy__Individual_Enrollment__c ien : ienList) {
            // Add a small delay to ensure different CreatedDate for scenario 4
            Test.setCreatedDate(ien.Id, System.now().addMinutes(-5));

            createdPlaceholderIen.put(ien.reduivy__Target_Unit_Id__c, ien.Id);
        }

        // Create additional IENs for testing different scenarios
        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        // Create academicTermIen for scenario 2 (has existing placeholder + academicTermIen)
        ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sofForFirstRequiredUnit.Id,
            reduivy__Enrollment_Status__c = IEN_Helper.getWaitlistedStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        ));

        // Create academicTermIen for scenario 3 (has academicTermIen but no existing placeholder)
        ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sofForFirstOptionalUnit.Id,
            reduivy__Enrollment_Status__c = IEN_Helper.getWaitlistedStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        ));

        insert ienToBeCreated;

        // Create multiple placeholder IENs for scenario 4 (to test latest CreatedDate selection)
        Id scenario4UnitId = sofForScenario4.reduivy__Study_Unit__c;
        // Create first placeholder IEN (older)
        reduivy__Individual_Enrollment__c olderPlaceholderIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = scenario4UnitId,
            reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Study_Offering__c = null, // Placeholder should have null study offering
            reduivy__Individual_Academic_Progress__c = null, // Placeholder should have null IAP
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        );

        insert olderPlaceholderIen;

        // Add a delay to ensure different CreatedDate
        Test.setCreatedDate(olderPlaceholderIen.Id, System.now().addMinutes(-500));

        // Create second placeholder IEN (newer - should be selected)
        reduivy__Individual_Enrollment__c newerPlaceholderIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = scenario4UnitId,
            reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Study_Offering__c = null, // Placeholder should have null study offering
            reduivy__Individual_Academic_Progress__c = null, // Placeholder should have null IAP
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        );

        insert newerPlaceholderIen;

        // Get IPS records for testing
        List<reduivy__Individual_Plan_Structure__c> ipsList = [SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Individual_Program_Enrollment__c, reduivy__Study_Plan_Structure__c,
            reduivy__Parent_Plan_Structure__c, reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :newIpe.Id
            AND reduivy__Target_Unit_Id__c IN :requiredUnitsList
        ];

        System.runAs(ADMIN_USER) {
            Test.startTest();

            // SCENARIO 1: Has existing placeholder IEN, but no academicTermIen
            // Should use the existing placeholder IEN
            reduivy__Individual_Plan_Structure__c ipsForScenario1 = null;
            for(reduivy__Individual_Plan_Structure__c ips : ipsList) {
                if(ips.reduivy__Target_Unit_Id__c == requiredUnitsList[1]) { // Second required unit
                    ipsForScenario1 = ips;
                    break;
                }
            }

            REDU_IndividualPlanStructure_OBJ scenario1Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario1Obj.ips = ipsForScenario1;
            scenario1Obj.sof = sofForSecondRequiredUnit;
            scenario1Obj.academicTermIen = null; // No academicTermIen

            REDU_LightningResponse response1 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario1Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            );

            // SCENARIO 2: Has existing placeholder IEN, and has academicTermIen
            // Should use the academicTermIen (ignore placeholder)
            reduivy__Individual_Plan_Structure__c ipsForScenario2 = null;
            for(reduivy__Individual_Plan_Structure__c ips : ipsList) {
                if(ips.reduivy__Target_Unit_Id__c == requiredUnitsList[0]) { // First required unit
                    ipsForScenario2 = ips;
                    break;
                }
            }

            REDU_IndividualPlanStructure_OBJ scenario2Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario2Obj.ips = ipsForScenario2;
            scenario2Obj.sof = sofForFirstRequiredUnit;
            scenario2Obj.academicTermIen = ienToBeCreated[0]; // Has academicTermIen

            REDU_LightningResponse response2 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario2Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            ); 

            // SCENARIO 3: Has academicTermIen, but no existing placeholder IEN
            // Should use the academicTermIen
            reduivy__Individual_Plan_Structure__c ipsForScenario3 = new reduivy__Individual_Plan_Structure__c(
                reduivy__Individual_Program_Enrollment__c = newIpe.Id,
                reduivy__Category__c = IPS_Helper.CATEGORY_OPTIONAL,
                RecordTypeId = IPS_Helper.getUnitRecordTypeId()
            );
            insert ipsForScenario3;

            REDU_IndividualPlanStructure_OBJ scenario3Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario3Obj.ips = ipsForScenario3;
            scenario3Obj.sof = sofForFirstOptionalUnit;
            scenario3Obj.academicTermIen = ienToBeCreated[1]; // Has academicTermIen

            REDU_LightningResponse response3 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario3Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            );

            // SCENARIO 4: Has multiple existing placeholder IENs, no academicTermIen
            // Should use the oldest created placeholder IEN
            reduivy__Individual_Plan_Structure__c ipsForScenario4 = null;
            for(reduivy__Individual_Plan_Structure__c ips : ipsList) {
                if(ips.reduivy__Target_Unit_Id__c == requiredUnitsList[2]) { // Third required unit
                    ipsForScenario4 = ips;
                    break;
                }
            }

            REDU_IndividualPlanStructure_OBJ scenario4Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario4Obj.ips = ipsForScenario4;
            scenario4Obj.sof = sofForScenario4;
            scenario4Obj.academicTermIen = null; // No academicTermIen

            REDU_LightningResponse response4 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario4Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            );

            Test.stopTest();

            // ASSERTIONS
            System.Assert.areEqual(true, response1.isSuccess, 'Scenario 1 should be successful');
            System.Assert.areEqual(true, response2.isSuccess, 'Scenario 2 should be successful');
            System.Assert.areEqual(true, response3.isSuccess, 'Scenario 3 should be successful');
            System.Assert.areEqual(true, response4.isSuccess, 'Scenario 4 should be successful');

            // Get updated IEN records to verify behavior
            List<reduivy__Individual_Enrollment__c> updatedIenList = [SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Study_Offering__c, 
                reduivy__Enrollment_Status__c, reduivy__Individual_Academic_Progress__c, CreatedDate
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c = :newIpe.reduivy__Contact__c
                ORDER BY CreatedDate
            ];

            // SCENARIO 1 ASSERTIONS: Should have updated existing placeholder IEN
            reduivy__Individual_Enrollment__c scenario1Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.reduivy__Target_Unit_Id__c == requiredUnitsList[1]) {
                    scenario1Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario1Ien, 'Scenario 1 IEN should exist');
            System.Assert.areEqual(createdPlaceholderIen.get(scenario1Ien.reduivy__Target_Unit_Id__c), scenario1Ien.Id, 'Scenario 1 should use the existing placeholder individual enrollment');
            System.Assert.areEqual(sofForSecondRequiredUnit.Id, scenario1Ien.reduivy__Study_Offering__c, 'Scenario 1 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario1Ien.reduivy__Enrollment_Status__c, 'Scenario 1 should have correct enrollment status');

            // SCENARIO 2 ASSERTIONS: Should have used the academicTermIen (not placeholder)
            reduivy__Individual_Enrollment__c scenario2Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == ienToBeCreated[0].Id) {
                    scenario2Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario2Ien, 'Scenario 2 IEN should exist');
            System.Assert.areEqual(sofForFirstRequiredUnit.Id, scenario2Ien.reduivy__Study_Offering__c, 'Scenario 2 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario2Ien.reduivy__Enrollment_Status__c, 'Scenario 2 should have correct enrollment status');
            System.Assert.areNotEqual(createdPlaceholderIen.get(scenario2Ien.reduivy__Target_Unit_Id__c), scenario2Ien.Id, 'Scenario 2 should use the academicTermIen');

            // SCENARIO 3 ASSERTIONS: Should have used the academicTermIen (no placeholder exists)
            reduivy__Individual_Enrollment__c scenario3Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == ienToBeCreated[1].Id) {
                    scenario3Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario3Ien, 'Scenario 3 IEN should exist');
            System.Assert.areEqual(sofForFirstOptionalUnit.Id, scenario3Ien.reduivy__Study_Offering__c, 'Scenario 3 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario3Ien.reduivy__Enrollment_Status__c, 'Scenario 3 should have correct enrollment status');
            System.Assert.areNotEqual(createdPlaceholderIen.get(scenario3Ien.reduivy__Target_Unit_Id__c), scenario3Ien.Id, 'Scenario 3 should use the academicTermIen');

            // SCENARIO 4 ASSERTIONS: Should have used the oldest created placeholder IEN
            reduivy__Individual_Enrollment__c scenario4Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.reduivy__Target_Unit_Id__c == scenario4UnitId && ien.reduivy__Study_Offering__c == sofForScenario4.Id) {
                    scenario4Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario4Ien, 'Scenario 4 IEN should exist');
            System.Assert.areNotEqual(newerPlaceholderIen.Id, scenario4Ien.Id, 'Scenario 4 should use the older placeholder IEN');
            System.Assert.areEqual(olderPlaceholderIen.Id, scenario4Ien.Id, 'Scenario 4 should use the older placeholder IEN');
            System.Assert.areEqual(sofForScenario4.Id, scenario4Ien.reduivy__Study_Offering__c, 'Scenario 4 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario4Ien.reduivy__Enrollment_Status__c, 'Scenario 4 should have correct enrollment status');

            // Verify that the newer placeholder IEN for scenario 4 still exists (wasn't used)
            reduivy__Individual_Enrollment__c createdNewerPlaceholderIen = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == newerPlaceholderIen.Id) {
                    createdNewerPlaceholderIen = ien;
                    break;
                }
            }
            System.Assert.isNotNull(createdNewerPlaceholderIen, 'Newer placeholder IEN should still exist');
            System.Assert.isNull(createdNewerPlaceholderIen.reduivy__Study_Offering__c, 'Newer placeholder IEN should still have null study offering');
            System.Assert.isNull(createdNewerPlaceholderIen.reduivy__Individual_Academic_Progress__c, 'Newer placeholder IEN should still have null Individual Academic Progress');

            // Verify that the placeholder IEN for first required unit still exists (wasn't used in scenario 2)
            String placeholderIenId = createdPlaceholderIen.get(requiredUnitsList[0]);
            reduivy__Individual_Enrollment__c placeholderIen = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == placeholderIenId) {
                    placeholderIen = ien;
                    break;
                }
            }
            System.Assert.isNotNull(placeholderIen, 'Original placeholder IEN should still exist');
            System.Assert.isNull(placeholderIen.reduivy__Study_Offering__c, 'Original placeholder IEN should still have null study offering');
            System.Assert.isNull(placeholderIen.reduivy__Individual_Academic_Progress__c, 'Original placeholder IEN should still have null Individual Academic Progress');
        }
    }

    /**
     * @description Test upsertEnrollment() for different existing placeholder scenarios as an faculty
     */
    @isTest
    static void testUpsertEnrollmentForDifferentExistingPlaceholderIenScenariosAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c, 
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Account campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        // Create study plan with 'Required Units Only' creation mode
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get required and optional units
        Set<Id> requiredUnits = new Set<Id>();
        Set<Id> optionalUnits = new Set<Id>();
        
        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, reduivy__Study_Unit__c, reduivy__Category__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ]) {
            if (sps.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED) {
                requiredUnits.add(sps.reduivy__Study_Unit__c);
            } else {
                optionalUnits.add(sps.reduivy__Study_Unit__c);
            }
        }

        System.Assert.isFalse(requiredUnits.isEmpty(), 'The required unit should not be empty.');
        System.Assert.isFalse(optionalUnits.isEmpty(), 'The optional unit should not be empty.');

        // Convert sets to lists for easier access
        List<Id> requiredUnitsList = new List<Id>(requiredUnits);
        List<Id> optionalUnitsList = new List<Id>(optionalUnits);

        // Create study offerings
        reduivy__Study_Offering__c sofForFirstRequiredUnit = new reduivy__Study_Offering__c(
            Name = 'RequiredUnitSof',
            reduivy__Study_Unit__c = requiredUnitsList[0],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        reduivy__Study_Offering__c sofForSecondRequiredUnit = new reduivy__Study_Offering__c(
            Name = 'SecondRequiredUnitSof',
            reduivy__Study_Unit__c = requiredUnitsList[1],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        reduivy__Study_Offering__c sofForFirstOptionalUnit = new reduivy__Study_Offering__c(
            Name = 'OptionalUnitSof',
            reduivy__Study_Unit__c = optionalUnitsList[0],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        // Create study offering for scenario 4
        reduivy__Study_Offering__c sofForScenario4 = new reduivy__Study_Offering__c(
            Name = 'Scenario4UnitSof',
            reduivy__Study_Unit__c = requiredUnitsList.size() > 2 ? requiredUnitsList[2] : optionalUnitsList[0],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        insert new List<reduivy__Study_Offering__c>{sofForFirstRequiredUnit, sofForSecondRequiredUnit, sofForFirstOptionalUnit, sofForScenario4};

        reduivy__Individual_Academic_Profile__c ipfToBeCreated = REDU_TestData_UTIL.newIndividualAcademicProfile(students[0].Id + '_' + students[0].Name, students[0].Id, students[0].Name, IPF_Helper.STATUS_ACTIVE, true);
    
        insert ipfToBeCreated;

        // Create Individual Program Enrollment
        reduivy__Individual_Program_Enrollment__c newIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            students[0].Id + '_' + studyPlan.Id, 
            students[0].Id, 
            studyPlan.reduivy__Study_Program__c, 
            studyPlan.Id, 
            null, 
            academicTerm.Id, 
            null, 
            null, 
            null, 
            null, 
            true, 
            IPE_Helper.getInProgressStatuses().get(0), 
            ipfToBeCreated.Id
        );
        insert newIpe;

        // Get the Individual Pathway
        reduivy__Individual_Pathway__c pathway = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :newIpe.Id AND reduivy__Academic_Term__c = :academicTerm.Id LIMIT 1];
        
        // Verify placeholder IENs were created for required units
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Study_Offering__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :newIpe.reduivy__Contact__c
            ORDER BY CreatedDate
        ];
        System.Assert.areEqual(requiredUnits.size(), ienList.size(), 'Placeholder Individual Enrollment should be created for required units.');

        Map<Id, String> createdPlaceholderIen = new Map<Id, String>();
        for(reduivy__Individual_Enrollment__c ien : ienList) {
            // Add a small delay to ensure different CreatedDate for scenario 4
            Test.setCreatedDate(ien.Id, System.now().addMinutes(-5));

            createdPlaceholderIen.put(ien.reduivy__Target_Unit_Id__c, ien.Id);
        }

        // Create additional IENs for testing different scenarios
        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        // Create academicTermIen for scenario 2 (has existing placeholder + academicTermIen)
        ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sofForFirstRequiredUnit.Id,
            reduivy__Enrollment_Status__c = IEN_Helper.getWaitlistedStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        ));

        // Create academicTermIen for scenario 3 (has academicTermIen but no existing placeholder)
        ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sofForFirstOptionalUnit.Id,
            reduivy__Enrollment_Status__c = IEN_Helper.getWaitlistedStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        ));

        insert ienToBeCreated;

        // Create multiple placeholder IENs for scenario 4 (to test CreatedDate selection)
        Id scenario4UnitId = sofForScenario4.reduivy__Study_Unit__c;
        
        // Create first placeholder IEN (older)
        reduivy__Individual_Enrollment__c olderPlaceholderIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = scenario4UnitId,
            reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Study_Offering__c = null, // Placeholder should have null study offering
            reduivy__Individual_Academic_Progress__c = null, // Placeholder should have null IAP
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        );

        insert olderPlaceholderIen;

        // Add a delay to ensure different CreatedDate
        Test.setCreatedDate(olderPlaceholderIen.Id, System.now().addMinutes(-500));

        // Create second placeholder IEN (newer - should not be selected)
        reduivy__Individual_Enrollment__c newerPlaceholderIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = scenario4UnitId,
            reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Study_Offering__c = null, // Placeholder should have null study offering
            reduivy__Individual_Academic_Progress__c = null, // Placeholder should have null IAP
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        );

        insert newerPlaceholderIen;

        // Get IPS records for testing
        List<reduivy__Individual_Plan_Structure__c> ipsList = [SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Individual_Program_Enrollment__c, reduivy__Study_Plan_Structure__c,
            reduivy__Parent_Plan_Structure__c, reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :newIpe.Id
            AND reduivy__Target_Unit_Id__c IN :requiredUnitsList
        ];

        System.runAs(FACULTY_USER) {
            Test.startTest();

            // SCENARIO 1: Has existing placeholder IEN, but no academicTermIen
            // Should use the existing placeholder IEN
            reduivy__Individual_Plan_Structure__c ipsForScenario1 = null;
            for(reduivy__Individual_Plan_Structure__c ips : ipsList) {
                if(ips.reduivy__Target_Unit_Id__c == requiredUnitsList[1]) { // Second required unit
                    ipsForScenario1 = ips;
                    break;
                }
            }

            REDU_IndividualPlanStructure_OBJ scenario1Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario1Obj.ips = ipsForScenario1;
            scenario1Obj.sof = sofForSecondRequiredUnit;
            scenario1Obj.academicTermIen = null; // No academicTermIen

            REDU_LightningResponse response1 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario1Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            );

            // SCENARIO 2: Has existing placeholder IEN, and has academicTermIen
            // Should use the academicTermIen (ignore placeholder)
            reduivy__Individual_Plan_Structure__c ipsForScenario2 = null;
            for(reduivy__Individual_Plan_Structure__c ips : ipsList) {
                if(ips.reduivy__Target_Unit_Id__c == requiredUnitsList[0]) { // First required unit
                    ipsForScenario2 = ips;
                    break;
                }
            }

            REDU_IndividualPlanStructure_OBJ scenario2Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario2Obj.ips = ipsForScenario2;
            scenario2Obj.sof = sofForFirstRequiredUnit;
            scenario2Obj.academicTermIen = ienToBeCreated[0]; // Has academicTermIen

            REDU_LightningResponse response2 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario2Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            ); 

            // SCENARIO 3: Has academicTermIen, but no existing placeholder IEN
            // Should use the academicTermIen
            reduivy__Individual_Plan_Structure__c ipsForScenario3 = new reduivy__Individual_Plan_Structure__c(
                reduivy__Individual_Program_Enrollment__c = newIpe.Id,
                reduivy__Category__c = IPS_Helper.CATEGORY_OPTIONAL,
                RecordTypeId = IPS_Helper.getUnitRecordTypeId()
            );
            insert ipsForScenario3;

            REDU_IndividualPlanStructure_OBJ scenario3Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario3Obj.ips = ipsForScenario3;
            scenario3Obj.sof = sofForFirstOptionalUnit;
            scenario3Obj.academicTermIen = ienToBeCreated[1]; // Has academicTermIen

            REDU_LightningResponse response3 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario3Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            );

            // SCENARIO 4: Has multiple existing placeholder IENs, no academicTermIen
            // Should use the latest created placeholder IEN
            reduivy__Individual_Plan_Structure__c ipsForScenario4 = null;
            for(reduivy__Individual_Plan_Structure__c ips : ipsList) {
                if(ips.reduivy__Target_Unit_Id__c == requiredUnitsList[2]) { // Third required unit
                    ipsForScenario4 = ips;
                    break;
                }
            }

            REDU_IndividualPlanStructure_OBJ scenario4Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario4Obj.ips = ipsForScenario4;
            scenario4Obj.sof = sofForScenario4;
            scenario4Obj.academicTermIen = null; // No academicTermIen

            REDU_LightningResponse response4 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario4Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            );

            Test.stopTest();

            // ASSERTIONS
            System.Assert.areEqual(true, response1.isSuccess, 'Scenario 1 should be successful');
            System.Assert.areEqual(true, response2.isSuccess, 'Scenario 2 should be successful');
            System.Assert.areEqual(true, response3.isSuccess, 'Scenario 3 should be successful');
            System.Assert.areEqual(true, response4.isSuccess, 'Scenario 4 should be successful');

            // Get updated IEN records to verify behavior
            List<reduivy__Individual_Enrollment__c> updatedIenList = [SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Study_Offering__c, 
                reduivy__Enrollment_Status__c, reduivy__Individual_Academic_Progress__c, CreatedDate
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c = :newIpe.reduivy__Contact__c
                ORDER BY CreatedDate
            ];

            // SCENARIO 1 ASSERTIONS: Should have updated existing placeholder IEN
            reduivy__Individual_Enrollment__c scenario1Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.reduivy__Target_Unit_Id__c == requiredUnitsList[1]) {
                    scenario1Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario1Ien, 'Scenario 1 IEN should exist');
            System.Assert.areEqual(createdPlaceholderIen.get(scenario1Ien.reduivy__Target_Unit_Id__c), scenario1Ien.Id, 'Scenario 1 should use the existing placeholder individual enrollment');
            System.Assert.areEqual(sofForSecondRequiredUnit.Id, scenario1Ien.reduivy__Study_Offering__c, 'Scenario 1 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario1Ien.reduivy__Enrollment_Status__c, 'Scenario 1 should have correct enrollment status');

            // SCENARIO 2 ASSERTIONS: Should have used the academicTermIen (not placeholder)
            reduivy__Individual_Enrollment__c scenario2Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == ienToBeCreated[0].Id) {
                    scenario2Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario2Ien, 'Scenario 2 IEN should exist');
            System.Assert.areEqual(sofForFirstRequiredUnit.Id, scenario2Ien.reduivy__Study_Offering__c, 'Scenario 2 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario2Ien.reduivy__Enrollment_Status__c, 'Scenario 2 should have correct enrollment status');
            System.Assert.areNotEqual(createdPlaceholderIen.get(scenario2Ien.reduivy__Target_Unit_Id__c), scenario2Ien.Id, 'Scenario 2 should use the academicTermIen');

            // SCENARIO 3 ASSERTIONS: Should have used the academicTermIen (no placeholder exists)
            reduivy__Individual_Enrollment__c scenario3Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == ienToBeCreated[1].Id) {
                    scenario3Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario3Ien, 'Scenario 3 IEN should exist');
            System.Assert.areEqual(sofForFirstOptionalUnit.Id, scenario3Ien.reduivy__Study_Offering__c, 'Scenario 3 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario3Ien.reduivy__Enrollment_Status__c, 'Scenario 3 should have correct enrollment status');
            System.Assert.areNotEqual(createdPlaceholderIen.get(scenario3Ien.reduivy__Target_Unit_Id__c), scenario3Ien.Id, 'Scenario 3 should use the academicTermIen');

            // SCENARIO 4 ASSERTIONS: Should have used the oldest created placeholder IEN
            reduivy__Individual_Enrollment__c scenario4Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.reduivy__Target_Unit_Id__c == scenario4UnitId && ien.reduivy__Study_Offering__c == sofForScenario4.Id) {
                    scenario4Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario4Ien, 'Scenario 4 IEN should exist');
            System.Assert.areNotEqual(newerPlaceholderIen.Id, scenario4Ien.Id, 'Scenario 4 should use the older placeholder IEN');
            System.Assert.areEqual(olderPlaceholderIen.Id, scenario4Ien.Id, 'Scenario 4 should use the older placeholder IEN');
            System.Assert.areEqual(sofForScenario4.Id, scenario4Ien.reduivy__Study_Offering__c, 'Scenario 4 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario4Ien.reduivy__Enrollment_Status__c, 'Scenario 4 should have correct enrollment status');

            // Verify that the newer placeholder IEN for scenario 4 still exists (wasn't used)
            reduivy__Individual_Enrollment__c createdNewerPlaceholderIen = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == newerPlaceholderIen.Id) {
                    createdNewerPlaceholderIen = ien;
                    break;
                }
            }
            System.Assert.isNotNull(createdNewerPlaceholderIen, 'Newer placeholder IEN should still exist');
            System.Assert.isNull(createdNewerPlaceholderIen.reduivy__Study_Offering__c, 'Newer placeholder IEN should still have null study offering');
            System.Assert.isNull(createdNewerPlaceholderIen.reduivy__Individual_Academic_Progress__c, 'Newer placeholder IEN should still have null Individual Academic Progress');

            // Verify that the placeholder IEN for first required unit still exists (wasn't used in scenario 2)
            String placeholderIenId = createdPlaceholderIen.get(requiredUnitsList[0]);
            reduivy__Individual_Enrollment__c placeholderIen = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == placeholderIenId) {
                    placeholderIen = ien;
                    break;
                }
            }
            System.Assert.isNotNull(placeholderIen, 'Original placeholder IEN should still exist');
            System.Assert.isNull(placeholderIen.reduivy__Study_Offering__c, 'Original placeholder IEN should still have null study offering');
            System.Assert.isNull(placeholderIen.reduivy__Individual_Academic_Progress__c, 'Original placeholder IEN should still have null Individual Academic Progress');
        }
    }

    /**
     * @description Test upsertEnrollment() for different existing placeholder scenarios as an student
     */
    @isTest
    static void testUpsertEnrollmentForDifferentExistingPlaceholderIenScenariosAsStudent() {        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c, 
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        User studentUser = [SELECT Id 
            FROM User 
            WHERE ContactId =: students[0].Id 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Account campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        // Create study plan with 'Required Units Only' creation mode
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get required and optional units
        Set<Id> requiredUnits = new Set<Id>();
        Set<Id> optionalUnits = new Set<Id>();
        
        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, reduivy__Study_Unit__c, reduivy__Category__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
        ]) {
            if (sps.reduivy__Category__c == SPS_Helper.CATEGORY_REQUIRED) {
                requiredUnits.add(sps.reduivy__Study_Unit__c);
            } else {
                optionalUnits.add(sps.reduivy__Study_Unit__c);
            }
        }

        System.Assert.isFalse(requiredUnits.isEmpty(), 'The required unit should not be empty.');
        System.Assert.isFalse(optionalUnits.isEmpty(), 'The optional unit should not be empty.');

        // Convert sets to lists for easier access
        List<Id> requiredUnitsList = new List<Id>(requiredUnits);
        List<Id> optionalUnitsList = new List<Id>(optionalUnits);

        // Create study offerings
        reduivy__Study_Offering__c sofForFirstRequiredUnit = new reduivy__Study_Offering__c(
            Name = 'RequiredUnitSof',
            reduivy__Study_Unit__c = requiredUnitsList[0],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        reduivy__Study_Offering__c sofForSecondRequiredUnit = new reduivy__Study_Offering__c(
            Name = 'SecondRequiredUnitSof',
            reduivy__Study_Unit__c = requiredUnitsList[1],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        reduivy__Study_Offering__c sofForFirstOptionalUnit = new reduivy__Study_Offering__c(
            Name = 'OptionalUnitSof',
            reduivy__Study_Unit__c = optionalUnitsList[0],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        // Create study offering for scenario 4
        reduivy__Study_Offering__c sofForScenario4 = new reduivy__Study_Offering__c(
            Name = 'Scenario4UnitSof',
            reduivy__Study_Unit__c = requiredUnitsList.size() > 2 ? requiredUnitsList[2] : optionalUnitsList[0],
            reduivy__Academic_Term__c = academicTerm.Id,
            reduivy__Campus__c = campus.Id,
            reduivy__Capacity__c = 20,
            reduivy__Start_Date__c = System.today(),
            reduivy__End_Date__c = System.today().addDays(30),
            reduivy__UUID__c = System.UUID.randomUUID().toString()
        );

        insert new List<reduivy__Study_Offering__c>{sofForFirstRequiredUnit, sofForSecondRequiredUnit, sofForFirstOptionalUnit, sofForScenario4};

        reduivy__Individual_Academic_Profile__c ipfToBeCreated = REDU_TestData_UTIL.newIndividualAcademicProfile(students[0].Id + '_' + students[0].Name, students[0].Id, students[0].Name, IPF_Helper.STATUS_ACTIVE, true);
    
        insert ipfToBeCreated;

        // Create Individual Program Enrollment
        reduivy__Individual_Program_Enrollment__c newIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            students[0].Id + '_' + studyPlan.Id, 
            students[0].Id, 
            studyPlan.reduivy__Study_Program__c, 
            studyPlan.Id, 
            null, 
            academicTerm.Id, 
            null, 
            null, 
            null, 
            null, 
            true, 
            IPE_Helper.getInProgressStatuses().get(0), 
            ipfToBeCreated.Id
        );
        insert newIpe;

        // Get the Individual Pathway
        reduivy__Individual_Pathway__c pathway = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :newIpe.Id AND reduivy__Academic_Term__c = :academicTerm.Id LIMIT 1];
        
        // Verify placeholder IENs were created for required units
        List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Study_Offering__c, reduivy__Individual_Academic_Progress__c 
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :newIpe.reduivy__Contact__c
            ORDER BY CreatedDate
        ];
        System.Assert.areEqual(requiredUnits.size(), ienList.size(), 'Placeholder Individual Enrollment should be created for required units.');

        Map<Id, String> createdPlaceholderIen = new Map<Id, String>();
        for(reduivy__Individual_Enrollment__c ien : ienList) {
            // Add a small delay to ensure different CreatedDate for scenario 4
            Test.setCreatedDate(ien.Id, System.now().addMinutes(-5));

            createdPlaceholderIen.put(ien.reduivy__Target_Unit_Id__c, ien.Id);
        }

        // Create additional IENs for testing different scenarios
        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();

        // Create academicTermIen for scenario 2 (has existing placeholder + academicTermIen)
        ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sofForFirstRequiredUnit.Id,
            reduivy__Enrollment_Status__c = IEN_Helper.getWaitlistedStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        ));

        // Create academicTermIen for scenario 3 (has academicTermIen but no existing placeholder)
        ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Offering__c = sofForFirstOptionalUnit.Id,
            reduivy__Enrollment_Status__c = IEN_Helper.getWaitlistedStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        )); 

        insert ienToBeCreated;

        // Create multiple placeholder IENs for scenario 4 (to test latest CreatedDate selection)
        Id scenario4UnitId = sofForScenario4.reduivy__Study_Unit__c;
        // Create first placeholder IEN (older)
        reduivy__Individual_Enrollment__c olderPlaceholderIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = scenario4UnitId,
            reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Study_Offering__c = null, // Placeholder should have null study offering
            reduivy__Individual_Academic_Progress__c = null, // Placeholder should have null IAP
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        );

        insert olderPlaceholderIen;

        // Add a delay to ensure different CreatedDate
        Test.setCreatedDate(olderPlaceholderIen.Id, System.now().addMinutes(-500));

        // Create second placeholder IEN (newer - should not be selected)
        reduivy__Individual_Enrollment__c newerPlaceholderIen = new reduivy__Individual_Enrollment__c(
            reduivy__Contact__c = students[0].Id,
            reduivy__Study_Unit__c = scenario4UnitId,
            reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0),
            reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
            reduivy__Study_Offering__c = null, // Placeholder should have null study offering
            reduivy__Individual_Academic_Progress__c = null, // Placeholder should have null IAP
            reduivy__Bypass_Requirement_Met__c = true,
            reduivy__Individual_Academic_Profile__c = ipfToBeCreated.Id
        );

        insert newerPlaceholderIen;

        // Get IPS records for testing
        List<reduivy__Individual_Plan_Structure__c> ipsList = [SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Individual_Program_Enrollment__c, reduivy__Study_Plan_Structure__c,
            reduivy__Parent_Plan_Structure__c, reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :newIpe.Id
            AND reduivy__Target_Unit_Id__c IN :requiredUnitsList
        ];

        System.runAs(studentUser) {
            Test.startTest();

            // SCENARIO 1: Has existing placeholder IEN, but no academicTermIen
            // Should use the existing placeholder IEN
            reduivy__Individual_Plan_Structure__c ipsForScenario1 = null;
            for(reduivy__Individual_Plan_Structure__c ips : ipsList) {
                if(ips.reduivy__Target_Unit_Id__c == requiredUnitsList[1]) { // Second required unit
                    ipsForScenario1 = ips;
                    break;
                }
            }

            REDU_IndividualPlanStructure_OBJ scenario1Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario1Obj.ips = ipsForScenario1;
            scenario1Obj.sof = sofForSecondRequiredUnit;
            scenario1Obj.academicTermIen = null; // No academicTermIen

            REDU_LightningResponse response1 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario1Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            );

            // SCENARIO 2: Has existing placeholder IEN, and has academicTermIen
            // Should use the academicTermIen (ignore placeholder)
            reduivy__Individual_Plan_Structure__c ipsForScenario2 = null;
            for(reduivy__Individual_Plan_Structure__c ips : ipsList) {
                if(ips.reduivy__Target_Unit_Id__c == requiredUnitsList[0]) { // First required unit
                    ipsForScenario2 = ips;
                    break;
                }
            }

            REDU_IndividualPlanStructure_OBJ scenario2Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario2Obj.ips = ipsForScenario2;
            scenario2Obj.sof = sofForFirstRequiredUnit;
            scenario2Obj.academicTermIen = ienToBeCreated[0]; // Has academicTermIen

            REDU_LightningResponse response2 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario2Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            ); 

            // SCENARIO 3: Has academicTermIen, but no existing placeholder IEN
            // Should use the academicTermIen
            reduivy__Individual_Plan_Structure__c ipsForScenario3 = new reduivy__Individual_Plan_Structure__c(
                reduivy__Individual_Program_Enrollment__c = newIpe.Id,
                reduivy__Category__c = IPS_Helper.CATEGORY_OPTIONAL,
                RecordTypeId = IPS_Helper.getUnitRecordTypeId()
            );
            insert ipsForScenario3;

            REDU_IndividualPlanStructure_OBJ scenario3Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario3Obj.ips = ipsForScenario3;
            scenario3Obj.sof = sofForFirstOptionalUnit;
            scenario3Obj.academicTermIen = ienToBeCreated[1]; // Has academicTermIen

            REDU_LightningResponse response3 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario3Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            );

            // SCENARIO 4: Has multiple existing placeholder IENs, no academicTermIen
            // Should use the oldest created placeholder IEN
            reduivy__Individual_Plan_Structure__c ipsForScenario4 = null;
            for(reduivy__Individual_Plan_Structure__c ips : ipsList) {
                if(ips.reduivy__Target_Unit_Id__c == requiredUnitsList[2]) { // Third required unit
                    ipsForScenario4 = ips;
                    break;
                }
            }

            REDU_IndividualPlanStructure_OBJ scenario4Obj = new REDU_IndividualPlanStructure_OBJ();
            scenario4Obj.ips = ipsForScenario4;
            scenario4Obj.sof = sofForScenario4;
            scenario4Obj.academicTermIen = null; // No academicTermIen

            REDU_LightningResponse response4 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway.Id, 
                JSON.serialize(scenario4Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getWaitlistedStatuses().get(0)
            );

            Test.stopTest();

            // ASSERTIONS
            System.Assert.areEqual(true, response1.isSuccess, 'Scenario 1 should be successful');
            System.Assert.areEqual(true, response2.isSuccess, 'Scenario 2 should be successful');
            System.Assert.areEqual(true, response3.isSuccess, 'Scenario 3 should be successful');
            System.Assert.areEqual(true, response4.isSuccess, 'Scenario 4 should be successful');

            // Get updated IEN records to verify behavior
            List<reduivy__Individual_Enrollment__c> updatedIenList = [SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Study_Offering__c, 
                reduivy__Enrollment_Status__c, reduivy__Individual_Academic_Progress__c, CreatedDate
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c = :newIpe.reduivy__Contact__c
                ORDER BY CreatedDate
            ];

            // SCENARIO 1 ASSERTIONS: Should have updated existing placeholder IEN
            reduivy__Individual_Enrollment__c scenario1Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.reduivy__Target_Unit_Id__c == requiredUnitsList[1]) {
                    scenario1Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario1Ien, 'Scenario 1 IEN should exist');
            System.Assert.areEqual(createdPlaceholderIen.get(scenario1Ien.reduivy__Target_Unit_Id__c), scenario1Ien.Id, 'Scenario 1 should use the existing placeholder individual enrollment');
            System.Assert.areEqual(sofForSecondRequiredUnit.Id, scenario1Ien.reduivy__Study_Offering__c, 'Scenario 1 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario1Ien.reduivy__Enrollment_Status__c, 'Scenario 1 should have correct enrollment status');

            // SCENARIO 2 ASSERTIONS: Should have used the academicTermIen (not placeholder)
            reduivy__Individual_Enrollment__c scenario2Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == ienToBeCreated[0].Id) {
                    scenario2Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario2Ien, 'Scenario 2 IEN should exist');
            System.Assert.areEqual(sofForFirstRequiredUnit.Id, scenario2Ien.reduivy__Study_Offering__c, 'Scenario 2 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario2Ien.reduivy__Enrollment_Status__c, 'Scenario 2 should have correct enrollment status');
            System.Assert.areNotEqual(createdPlaceholderIen.get(scenario2Ien.reduivy__Target_Unit_Id__c), scenario2Ien.Id, 'Scenario 2 should use the academicTermIen');

            // SCENARIO 3 ASSERTIONS: Should have used the academicTermIen (no placeholder exists)
            reduivy__Individual_Enrollment__c scenario3Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == ienToBeCreated[1].Id) {
                    scenario3Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario3Ien, 'Scenario 3 IEN should exist');
            System.Assert.areEqual(sofForFirstOptionalUnit.Id, scenario3Ien.reduivy__Study_Offering__c, 'Scenario 3 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario3Ien.reduivy__Enrollment_Status__c, 'Scenario 3 should have correct enrollment status');
            System.Assert.areNotEqual(createdPlaceholderIen.get(scenario3Ien.reduivy__Target_Unit_Id__c), scenario3Ien.Id, 'Scenario 3 should use the academicTermIen');

            // SCENARIO 4 ASSERTIONS: Should have used the oldest created placeholder IEN
            reduivy__Individual_Enrollment__c scenario4Ien = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.reduivy__Target_Unit_Id__c == scenario4UnitId && ien.reduivy__Study_Offering__c == sofForScenario4.Id) {
                    scenario4Ien = ien;
                    break;
                }
            }
            System.Assert.isNotNull(scenario4Ien, 'Scenario 4 IEN should exist');
            System.Assert.areNotEqual(newerPlaceholderIen.Id, scenario4Ien.Id, 'Scenario 4 should use the older placeholder IEN');
            System.Assert.areEqual(olderPlaceholderIen.Id, scenario4Ien.Id, 'Scenario 4 should use the older placeholder IEN');
            System.Assert.areEqual(sofForScenario4.Id, scenario4Ien.reduivy__Study_Offering__c, 'Scenario 4 should use the correct study offering');
            System.Assert.areEqual(IEN_Helper.getWaitlistedStatuses().get(0), scenario4Ien.reduivy__Enrollment_Status__c, 'Scenario 4 should have correct enrollment status');

            // Verify that the newer placeholder IEN for scenario 4 still exists (wasn't used)
            reduivy__Individual_Enrollment__c createdNewerPlaceholderIen = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == newerPlaceholderIen.Id) {
                    createdNewerPlaceholderIen = ien;
                    break;
                }
            }
            System.Assert.isNotNull(createdNewerPlaceholderIen, 'Newer placeholder IEN should still exist');
            System.Assert.isNull(createdNewerPlaceholderIen.reduivy__Study_Offering__c, 'Newer placeholder IEN should still have null study offering');
            System.Assert.isNull(createdNewerPlaceholderIen.reduivy__Individual_Academic_Progress__c, 'Newer placeholder IEN should still have null Individual Academic Progress');

            // Verify that the placeholder IEN for first required unit still exists (wasn't used in scenario 2)
            String placeholderIenId = createdPlaceholderIen.get(requiredUnitsList[0]);
            reduivy__Individual_Enrollment__c placeholderIen = null;
            for(reduivy__Individual_Enrollment__c ien : updatedIenList) {
                if(ien.Id == placeholderIenId) {
                    placeholderIen = ien;
                    break;
                }
            }
            System.Assert.isNotNull(placeholderIen, 'Original placeholder IEN should still exist');
            System.Assert.isNull(placeholderIen.reduivy__Study_Offering__c, 'Original placeholder IEN should still have null study offering');
            System.Assert.isNull(placeholderIen.reduivy__Individual_Academic_Progress__c, 'Original placeholder IEN should still have null Individual Academic Progress');
        }
    }
    
    /**
     * @description Test missed/failed units with multiple IPFs - should only flag units failed under the queried IPF as admin
     */
    @isTest
    static void testMissedFailedOptionAllMultipleIpfsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c, reduivy__Study_Plan__c, reduivy__Study_Program__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE Id != :masterIpe.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];

        List<reduivy__Study_Grade_Setting__c> sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];

        Set<Id> sunIds = new Set<Id>();

        //Removed all individual enrollments
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        //Get study units from pathway
        List<reduivy__Study_Unit__c> studyUnits = new List<reduivy__Study_Unit__c>();
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name, reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3 ORDER BY reduivy__Study_Unit__r.Name]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
                studyUnits.add(spu.reduivy__Study_Unit__r);
            }
        }

        // Create new Individual Academic Profiles
        // IPF1: Original IPF with all units failed
        // IPF2: New IPF with only BUS101 and BUS102 failed, others not enrolled
        
        Id originalIpfId = masterIPE.reduivy__Individual_Academic_Profile__c;
        
        reduivy__Individual_Academic_Profile__c ipf2 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            'Student_NewProfile',
            masterIPE.reduivy__Contact__c,
            'Student_NewProfile',
            IPF_Helper.STATUS_ACTIVE,
            false
        );
        
        insert ipf2;

        reduivy__Individual_Program_Enrollment__c newIPE = masterIPE.clone(false, true, false, false);
        newIPE.reduivy__Individual_Academic_Profile__c = ipf2.Id;
        insert newIPE;

        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Individual_Program_Enrollment__c,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE (reduivy__Individual_Program_Enrollment__c = :masterIPE.Id OR reduivy__Individual_Program_Enrollment__c = :newIPE.Id)
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Plan_Structure__c> ipsGroupListForIpe1 = new List<reduivy__Individual_Plan_Structure__c>();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupListForIpe2 = new List<reduivy__Individual_Plan_Structure__c>();
        for(reduivy__Individual_Plan_Structure__c ipsGrp : ipsGroupList) {
            if(ipsGrp.reduivy__Individual_Program_Enrollment__c == masterIPE.Id) {
                ipsGroupListForIpe1.add(ipsGrp);
            } else {
                ipsGroupListForIpe2.add(ipsGrp);
            }
        }

        System.Assert.isFalse(ipsGroupListForIpe1.isEmpty(), 'The actual value should be as expected');
        System.Assert.isFalse(ipsGroupListForIpe2.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Status__c, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c, reduivy__Term_Number__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c < 3 
            AND (reduivy__Individual_Program_Enrollment__c = :masterIPE.Id OR reduivy__Individual_Program_Enrollment__c = :newIPE.Id)
            ORDER BY reduivy__Term_Number__c ASC
        ];

        List<reduivy__Individual_Pathway__c> idvPathwayListForIpe1 = new List<reduivy__Individual_Pathway__c>();
        List<reduivy__Individual_Pathway__c> idvPathwayListForIpe2 = new List<reduivy__Individual_Pathway__c>();

        List<reduivy__Individual_Pathway__c> ipwToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        for(reduivy__Individual_Pathway__c ipw : idvPathwayList) {
            if(ipw.reduivy__Term_Number__c == 1) {
                ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
                    Id = ipw.Id,
                    reduivy__Academic_Term__c = stm[0].Id,
                    reduivy__Individual_Academic_Progress__c = null
                ));
            } else {
                ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
                    Id = ipw.Id,
                    reduivy__Academic_Term__c = masterIPE.reduivy__Starting_Term__c,
                    reduivy__Individual_Academic_Progress__c = null
                ));
            }

            if(ipw.reduivy__Individual_Program_Enrollment__c == masterIPE.Id) {
                idvPathwayListForIpe1.add(ipw);
            } else {
                idvPathwayListForIpe2.add(ipw);
            }
        }
        
        update ipwToBeUpdated;

        // Create study offerings for previous term
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        for(Id sunId : sunIds) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = stm[0].Id,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        // Create failed IENs under original IPF (all units failed)
        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = IEN_Helper.getCompletedFailStatuses()[0],
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 0,
                reduivy__Bypass_Requirement_Met__c = true,
                reduivy__Individual_Academic_Profile__c = originalIpfId,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM
            ));
        }

        // Create failed IENs under IPF2 (only first 2 units: BUS101, BUS102)
        List<reduivy__Individual_Enrollment__c> ienForIpf2 = new List<reduivy__Individual_Enrollment__c>();
        Integer counter = 0;
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            if(counter < 2) { // Only first 2 units (BUS101, BUS102)
                ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                    reduivy__Study_Offering__c = sof.Id,
                    reduivy__Enrollment_Status__c = IEN_Helper.getCompletedFailStatuses()[0],
                    reduivy__Study_Grade_Setting__c = sgs[0].Id,
                    reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                    reduivy__Numerical_Grade__c = 0,
                    reduivy__Bypass_Requirement_Met__c = true,
                    reduivy__Individual_Academic_Profile__c = ipf2.Id,
                    reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM
                ));
            } else {
                ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                    reduivy__Study_Offering__c = sof.Id,
                    reduivy__Enrollment_Status__c = IEN_Helper.getCompletedPassStatuses()[0],
                    reduivy__Study_Grade_Setting__c = sgs[0].Id,
                    reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                    reduivy__Numerical_Grade__c = 100,
                    reduivy__Bypass_Requirement_Met__c = true,
                    reduivy__Individual_Academic_Profile__c = ipf2.Id,
                    reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM
                ));
            }
            counter++;
        }

        insert ienToBeCreated;

        System.runAs(ADMIN_USER){

            Test.startTest();

            // Test 1: Query with original IPF - all units should be flagged as missed/failed
            REDU_LightningResponse responseOriginalIpf = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupListForIpe1[0].Id, 
                idvPathwayListForIpe1[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY, 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            System.Assert.areEqual(true, responseOriginalIpf.isSuccess, 'Failed to get response with original IPF');
            Map<String, Object> responseDataOriginal = (Map<String, Object>) JSON.deserializeUntyped(responseOriginalIpf.responseData);
            List<Object> unitsOriginalIpf = (List<Object>)responseDataOriginal.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            
            System.Assert.areEqual(4, unitsOriginalIpf.size(), 'Should have 4 units for original IPF');

            Integer failedCountOriginal = 0;
            for (Object obj : unitsOriginalIpf) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;
                Map<String, Object> sunObj = (Map<String, Object>)unitObj.get('sun');
                String unitName = String.valueOf(sunObj.get('Name'));

                System.Assert.isNotNull(unitObj.get('isMissedFailed'), 'isMissedFailed flag should not be null for ' + unitName + ' in original IPF');
                
                if((Boolean)unitObj.get('isMissedFailed')) {
                    failedCountOriginal++;
                }
                
                System.Assert.areEqual(true, unitObj.get('isMissedFailed'), 'All units should be flagged as missed/failed for original IPF: ' + unitName);
            }
            
            System.Assert.areEqual(4, failedCountOriginal, 'All 4 units should be flagged as failed for original IPF');

            masterIPE.reduivy__Individual_Academic_Profile__c = ipf2.Id;
            update masterIPE;

            // Test 2: Query with IPF2 - only 2 units should be flagged as missed/failed
            REDU_LightningResponse responseIpf2 = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                newIPE.Id,
                newIPE.Id, 
                ipsGroupListForIpe2[0].Id, 
                idvPathwayListForIpe2[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY, 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            System.Assert.areEqual(true, responseIpf2.isSuccess, 'Failed to get response with IPF2');
            Map<String, Object> responseDataIpf2 = (Map<String, Object>) JSON.deserializeUntyped(responseIpf2.responseData);
            List<Object> unitsIpf2 = (List<Object>)responseDataIpf2.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            
            System.Assert.areEqual(4, unitsIpf2.size(), 'Should have 4 units for IPF2');

            Integer failedCountIpf2 = 0;
            Integer notFailedCountIpf2 = 0;
            
            for (Object obj : unitsIpf2) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;
                Map<String, Object> sunObj = (Map<String, Object>)unitObj.get('sun');
                String unitName = String.valueOf(sunObj.get('Name'));
                Boolean isFailed = (Boolean)unitObj.get('isMissedFailed');

                System.Assert.isNotNull(isFailed, 'isMissedFailed flag should not be null for ' + unitName + ' in IPF2');
                                
                if(isFailed) {
                    failedCountIpf2++;
                } else {
                    notFailedCountIpf2++;
                }
            }
            
            System.Assert.areEqual(2, failedCountIpf2, 'Only 2 units (BUS101, BUS102) should be flagged as failed for IPF2');
            System.Assert.areEqual(2, notFailedCountIpf2, 'Other 2 units (BUS103, COM101) should NOT be flagged as failed for IPF2');

            Test.stopTest();
        }
    }

    /**
     * @description Test upsertEnrollment() with multiple IPFs - should only use placeholder IEN with matching IPF as Admin
     */
    @isTest
    static void testUpsertEnrollmentWithMultipleIpfsAsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        REDU_TriggerController.muteTriggers(new Set<String>{'IPS_IpeCompletion_EXE', 'IEN_CompletionEngine_EXE'});
        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c, 
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Account campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        // Get study plan
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get required units
        List<Id> requiredUnitsList = new List<Id>();
        List<reduivy__Study_Plan_Structure__c> spsList = new List<reduivy__Study_Plan_Structure__c>();
        List<reduivy__Study_Unit__c> sunList = new List<reduivy__Study_Unit__c>();

        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, reduivy__Study_Unit__c, reduivy__Category__c, reduivy__Requirement_Logic__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
        ]) {
            requiredUnitsList.add(sps.reduivy__Study_Unit__c);

            sps.reduivy__Requirement_Logic__c = '';

            spsList.add(sps);

            sunList.add(new reduivy__Study_Unit__c(
                Id = sps.reduivy__Study_Unit__c,
                reduivy__Requirement_Logic__c = ''
            ));
        }

        update sunList;
        update spsList;
        System.Assert.isFalse(requiredUnitsList.isEmpty(), 'Required units should exist');

        // Create study offerings
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        for(Integer i = 0; i < requiredUnitsList.size(); i++) {
            sofList.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF ' + i,
                reduivy__Study_Unit__c = requiredUnitsList[i],
                reduivy__Academic_Term__c = academicTerm.Id,
                reduivy__Campus__c = campus.Id,
                reduivy__Capacity__c = 20,
                reduivy__Start_Date__c = System.today(),
                reduivy__End_Date__c = System.today().addDays(30),
                reduivy__UUID__c = System.UUID.randomUUID().toString()
            ));
        }
        insert sofList;

        // Create two Individual Academic Profiles
        // IPF1: Will have placeholder IENs created
        // IPF2: New profile, should create new IENs
        
        reduivy__Individual_Academic_Profile__c ipf1 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            students[0].Id + '_IPF1',
            students[0].Id,
            'Student_IPF1',
            IPF_Helper.STATUS_ACTIVE,
            true
        );
        
        reduivy__Individual_Academic_Profile__c ipf2 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            students[0].Id + '_IPF2',
            students[0].Id,
            'Student_IPF2',
            IPF_Helper.STATUS_ACTIVE,
            false
        );
        
        insert new List<reduivy__Individual_Academic_Profile__c>{ipf1, ipf2};

        // Create IPE1 with IPF1 (will have placeholder IENs created automatically)
        reduivy__Individual_Program_Enrollment__c ipe1 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            students[0].Id + '_IPE1', 
            students[0].Id, 
            studyPlan.reduivy__Study_Program__c, 
            studyPlan.Id, 
            null, 
            academicTerm.Id, 
            null, 
            null, 
            null, 
            null, 
            true, 
            IPE_Helper.getInProgressStatuses().get(0), 
            ipf1.Id
        );
        insert ipe1;

        // Get the Individual Pathway for IPE1
        reduivy__Individual_Pathway__c pathway1 = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :ipe1.Id AND reduivy__Academic_Term__c = :academicTerm.Id LIMIT 1];

        // Create IPE2 with IPF2
        reduivy__Individual_Program_Enrollment__c ipe2 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            students[0].Id + '_IPE2', 
            students[0].Id, 
            studyPlan.reduivy__Study_Program__c, 
            studyPlan.Id, 
            null, 
            academicTerm.Id, 
            null, 
            null, 
            null, 
            null, 
            true, 
            IPE_Helper.getInProgressStatuses().get(0), 
            ipf2.Id
        );
        insert ipe2;

        // Verify placeholder IENs were created for IPE1 (linked to IPF1)
        List<reduivy__Individual_Enrollment__c> placeholderIens = [
            SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :students[0].Id
            AND (reduivy__Individual_Academic_Profile__c = :ipf1.Id OR reduivy__Individual_Academic_Profile__c = :ipf2.Id)
            ORDER BY CreatedDate
        ];
        
        List<reduivy__Individual_Enrollment__c> placeholderIensForIpf1 = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> placeholderIensForIpf2 = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Individual_Enrollment__c ien : placeholderIens) {
            if(ien.reduivy__Individual_Academic_Profile__c == ipf1.Id) {
                placeholderIensForIpf1.add(ien);
            } else {
                placeholderIensForIpf2.add(ien);
            }
        }

        delete placeholderIensForIpf2;
        System.Assert.areEqual(requiredUnitsList.size(), placeholderIensForIpf1.size(), 'Placeholder IENs should be created for IPF1');

        // Get the Individual Pathway for IPE2
        reduivy__Individual_Pathway__c pathway2 = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :ipe2.Id AND reduivy__Academic_Term__c = :academicTerm.Id LIMIT 1];

        // Get IPS records for both IPEs
        Map<Id, reduivy__Individual_Plan_Structure__c> ipe1IpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipe2IpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for(reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Individual_Program_Enrollment__c, 
            reduivy__Study_Plan_Structure__c, reduivy__Parent_Plan_Structure__c, 
            reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c, 
            reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c IN (:ipe1.Id, :ipe2.Id)
            AND reduivy__Target_Unit_Id__c IN :requiredUnitsList
        ]) {
            if(ips.reduivy__Individual_Program_Enrollment__c == ipe1.Id) {
                ipe1IpsMap.put(ips.reduivy__Target_Unit_Id__c, ips);
            } else {
                ipe2IpsMap.put(ips.reduivy__Target_Unit_Id__c, ips);
            }
        }

        System.runAs(ADMIN_USER) {

            // SCENARIO A1: IPE1 with IPF1 - Should use existing placeholder IEN with matching IPF
            REDU_IndividualPlanStructure_OBJ scenarioA1Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA1Obj.ips = ipe1IpsMap.get(requiredUnitsList[0]);
            scenarioA1Obj.sof = sofList[0];
            scenarioA1Obj.academicTermIen = null;

            REDU_LightningResponse responseA1 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway1.Id, 
                JSON.serialize(scenarioA1Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            Test.startTest();
            // SCENARIO A2: IPE2 with IPF2 - Should create new IEN (no placeholder exists for IPF2)
            REDU_IndividualPlanStructure_OBJ scenarioA2Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA2Obj.ips = ipe2IpsMap.get(requiredUnitsList[0]);
            scenarioA2Obj.sof = sofList[0];
            scenarioA2Obj.academicTermIen = null;

            REDU_LightningResponse responseA2 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway2.Id, 
                JSON.serialize(scenarioA2Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            // SCENARIO A3: IPE1 with IPF1 - Enroll in second unit (use another placeholder)
            REDU_IndividualPlanStructure_OBJ scenarioA3Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA3Obj.ips = ipe1IpsMap.get(requiredUnitsList[1]);
            scenarioA3Obj.sof = sofList[1];
            scenarioA3Obj.academicTermIen = null;

            REDU_LightningResponse responseA3 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway1.Id, 
                JSON.serialize(scenarioA3Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            // SCENARIO A4: IPE2 with IPF2 - Enroll in second unit (create new IEN for IPF2)
            REDU_IndividualPlanStructure_OBJ scenarioA4Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA4Obj.ips = ipe2IpsMap.get(requiredUnitsList[1]);
            scenarioA4Obj.sof = sofList[1];
            scenarioA4Obj.academicTermIen = null;

            REDU_LightningResponse responseA4 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway2.Id, 
                JSON.serialize(scenarioA4Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            Test.stopTest();

            // ASSERTIONS
            System.Assert.areEqual(true, responseA1.isSuccess, 'Scenario A1 should be successful');
            System.Assert.areEqual(true, responseA2.isSuccess, 'Scenario A2 should be successful');
            System.Assert.areEqual(true, responseA3.isSuccess, 'Scenario A3 should be successful');
            System.Assert.areEqual(true, responseA4.isSuccess, 'Scenario A4 should be successful');

            // Query all IENs to verify behavior
            List<reduivy__Individual_Enrollment__c> allIens = [
                SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Study_Offering__c, 
                reduivy__Individual_Academic_Profile__c, reduivy__Enrollment_Status__c,
                CreatedDate
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c = :students[0].Id
                ORDER BY CreatedDate
            ];

            // Separate IENs by IPF
            Map<Id, List<reduivy__Individual_Enrollment__c>> iensByIpf = new Map<Id, List<reduivy__Individual_Enrollment__c>>{
                ipf1.Id => new List<reduivy__Individual_Enrollment__c>(),
                ipf2.Id => new List<reduivy__Individual_Enrollment__c>()
            };

            for(reduivy__Individual_Enrollment__c ien : allIens) {
                if(iensByIpf.containsKey(ien.reduivy__Individual_Academic_Profile__c)) {
                    iensByIpf.get(ien.reduivy__Individual_Academic_Profile__c).add(ien);
                }
            }

            // SCENARIO A1 & A3 ASSERTIONS: IPF1 should have used existing placeholder IENs
            List<reduivy__Individual_Enrollment__c> ipf1Iens = iensByIpf.get(ipf1.Id);
            System.Assert.areEqual(requiredUnitsList.size(), ipf1Iens.size(), 'IPF1 should have ' + requiredUnitsList.size() + ' IENs (all placeholders)');

            // Verify that the enrolled IENs for IPF1 match the original placeholder IENs
            Map<Id, Id> originalPlaceholderMap = new Map<Id, Id>();
            for(reduivy__Individual_Enrollment__c placeholder : placeholderIensForIpf1) {
                originalPlaceholderMap.put(placeholder.reduivy__Target_Unit_Id__c, placeholder.Id);
            }

            Integer ipf1EnrolledCount = 0;
            for(reduivy__Individual_Enrollment__c ien : ipf1Iens) {
                if(ien.reduivy__Target_Unit_Id__c == requiredUnitsList[0] || ien.reduivy__Target_Unit_Id__c == requiredUnitsList[1]) {
                    ipf1EnrolledCount++;
                    System.Assert.areEqual(
                        originalPlaceholderMap.get(ien.reduivy__Target_Unit_Id__c),
                        ien.Id,
                        'IPF1 should use existing placeholder IEN for unit ' + ien.reduivy__Target_Unit_Id__c
                    );
                    System.Assert.isNotNull(ien.reduivy__Study_Offering__c, 'IPF1 enrolled IEN should have study offering');
                    System.Assert.areEqual(IEN_Helper.getInProgressStatuses().get(0), ien.reduivy__Enrollment_Status__c, 'IPF1 enrolled IEN should have correct status');
                }
            }
            System.Assert.areEqual(2, ipf1EnrolledCount, 'IPF1 should have 2 enrolled IENs');

            // SCENARIO A2 & A4 ASSERTIONS: IPF2 should have created new IENs (no placeholders existed)
            List<reduivy__Individual_Enrollment__c> ipf2Iens = iensByIpf.get(ipf2.Id);
            System.Assert.areEqual(2, ipf2Iens.size(), 'IPF2 should have 2 IENs (newly created)');

            for(reduivy__Individual_Enrollment__c ien : ipf2Iens) {
                System.Assert.areEqual(ipf2.Id, ien.reduivy__Individual_Academic_Profile__c, 'IPF2 IEN should link to IPF2');
                System.Assert.isNotNull(ien.reduivy__Study_Offering__c, 'IPF2 IEN should have study offering');
                System.Assert.areEqual(IEN_Helper.getInProgressStatuses().get(0), ien.reduivy__Enrollment_Status__c, 'IPF2 IEN should have correct status');
                
                // Verify these are NEW IENs (not from the original placeholders)
                System.Assert.isFalse(
                    originalPlaceholderMap.values().contains(ien.Id),
                    'IPF2 should create NEW IEN, not use IPF1 placeholders'
                );
            }

            // Verify IPF isolation: Total IENs should be placeholders for IPF1 + enrolled for IPF2
            Integer totalExpectedIens = requiredUnitsList.size() + 2; // 3 placeholders for IPF1 + 2 enrolled for IPF2
            System.Assert.areEqual(totalExpectedIens, allIens.size(), 'Total IENs should match expected count');

            // Verify no cross-contamination between IPFs
            for(reduivy__Individual_Enrollment__c ien : allIens) {
                if(ien.reduivy__Individual_Academic_Profile__c == ipf1.Id) {
                    System.Assert.isTrue(
                        originalPlaceholderMap.values().contains(ien.Id),
                        'All IPF1 IENs should be from original placeholders'
                    );
                } else if(ien.reduivy__Individual_Academic_Profile__c == ipf2.Id) {
                    System.Assert.isFalse(
                        originalPlaceholderMap.values().contains(ien.Id),
                        'All IPF2 IENs should be newly created'
                    );
                }
            }
        }
    }

    /**
     * @description Test missed/failed units with multiple IPFs - should only flag units failed under the queried IPF as faculty
     */
    @isTest
    static void testMissedFailedOptionAllMultipleIpfsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c, reduivy__Study_Plan__c, reduivy__Study_Program__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE Id != :masterIpe.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];

        List<reduivy__Study_Grade_Setting__c> sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];

        Set<Id> sunIds = new Set<Id>();

        //Removed all individual enrollments
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        //Get study units from pathway
        List<reduivy__Study_Unit__c> studyUnits = new List<reduivy__Study_Unit__c>();
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name, reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3 ORDER BY reduivy__Study_Unit__r.Name]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
                studyUnits.add(spu.reduivy__Study_Unit__r);
            }
        }

        // Create new Individual Academic Profiles
        // IPF1: Original IPF with all units failed
        // IPF2: New IPF with only BUS101 and BUS102 failed, others not enrolled
        
        Id originalIpfId = masterIPE.reduivy__Individual_Academic_Profile__c;
        
        reduivy__Individual_Academic_Profile__c ipf2 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            'Student_NewProfile',
            masterIPE.reduivy__Contact__c,
            'Student_NewProfile',
            IPF_Helper.STATUS_ACTIVE,
            false
        );
        
        insert ipf2;

        reduivy__Individual_Program_Enrollment__c newIPE = masterIPE.clone(false, true, false, false);
        newIPE.reduivy__Individual_Academic_Profile__c = ipf2.Id;
        insert newIPE;

        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Individual_Program_Enrollment__c,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE (reduivy__Individual_Program_Enrollment__c = :masterIPE.Id OR reduivy__Individual_Program_Enrollment__c = :newIPE.Id)
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Plan_Structure__c> ipsGroupListForIpe1 = new List<reduivy__Individual_Plan_Structure__c>();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupListForIpe2 = new List<reduivy__Individual_Plan_Structure__c>();
        for(reduivy__Individual_Plan_Structure__c ipsGrp : ipsGroupList) {
            if(ipsGrp.reduivy__Individual_Program_Enrollment__c == masterIPE.Id) {
                ipsGroupListForIpe1.add(ipsGrp);
            } else {
                ipsGroupListForIpe2.add(ipsGrp);
            }
        }

        System.Assert.isFalse(ipsGroupListForIpe1.isEmpty(), 'The actual value should be as expected');
        System.Assert.isFalse(ipsGroupListForIpe2.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Status__c, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c, reduivy__Term_Number__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c < 3 
            AND (reduivy__Individual_Program_Enrollment__c = :masterIPE.Id OR reduivy__Individual_Program_Enrollment__c = :newIPE.Id)
            ORDER BY reduivy__Term_Number__c ASC
        ];

        List<reduivy__Individual_Pathway__c> idvPathwayListForIpe1 = new List<reduivy__Individual_Pathway__c>();
        List<reduivy__Individual_Pathway__c> idvPathwayListForIpe2 = new List<reduivy__Individual_Pathway__c>();

        List<reduivy__Individual_Pathway__c> ipwToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        for(reduivy__Individual_Pathway__c ipw : idvPathwayList) {
            if(ipw.reduivy__Term_Number__c == 1) {
                ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
                    Id = ipw.Id,
                    reduivy__Academic_Term__c = stm[0].Id,
                    reduivy__Individual_Academic_Progress__c = null
                ));
            } else {
                ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
                    Id = ipw.Id,
                    reduivy__Academic_Term__c = masterIPE.reduivy__Starting_Term__c,
                    reduivy__Individual_Academic_Progress__c = null
                ));
            }

            if(ipw.reduivy__Individual_Program_Enrollment__c == masterIPE.Id) {
                idvPathwayListForIpe1.add(ipw);
            } else {
                idvPathwayListForIpe2.add(ipw);
            }
        }
        
        update ipwToBeUpdated;

        // Create study offerings for previous term
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        for(Id sunId : sunIds) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = stm[0].Id,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        // Create failed IENs under original IPF (all units failed)
        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = IEN_Helper.getCompletedFailStatuses()[0],
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 0,
                reduivy__Bypass_Requirement_Met__c = true,
                reduivy__Individual_Academic_Profile__c = originalIpfId,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM
            ));
        }

        // Create failed IENs under IPF2 (only first 2 units: BUS101, BUS102)
        List<reduivy__Individual_Enrollment__c> ienForIpf2 = new List<reduivy__Individual_Enrollment__c>();
        Integer counter = 0;
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            if(counter < 2) { // Only first 2 units (BUS101, BUS102)
                ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                    reduivy__Study_Offering__c = sof.Id,
                    reduivy__Enrollment_Status__c = IEN_Helper.getCompletedFailStatuses()[0],
                    reduivy__Study_Grade_Setting__c = sgs[0].Id,
                    reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                    reduivy__Numerical_Grade__c = 0,
                    reduivy__Bypass_Requirement_Met__c = true,
                    reduivy__Individual_Academic_Profile__c = ipf2.Id,
                    reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM
                ));
            } else {
                ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                    reduivy__Study_Offering__c = sof.Id,
                    reduivy__Enrollment_Status__c = IEN_Helper.getCompletedPassStatuses()[0],
                    reduivy__Study_Grade_Setting__c = sgs[0].Id,
                    reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                    reduivy__Numerical_Grade__c = 100,
                    reduivy__Bypass_Requirement_Met__c = true,
                    reduivy__Individual_Academic_Profile__c = ipf2.Id,
                    reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM
                ));
            }
            counter++;
        }

        insert ienToBeCreated;

        System.runAs(FACULTY_USER){

            Test.startTest();

            // Test 1: Query with original IPF - all units should be flagged as missed/failed
            REDU_LightningResponse responseOriginalIpf = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupListForIpe1[0].Id, 
                idvPathwayListForIpe1[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY, 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            System.Assert.areEqual(true, responseOriginalIpf.isSuccess, 'Failed to get response with original IPF');
            Map<String, Object> responseDataOriginal = (Map<String, Object>) JSON.deserializeUntyped(responseOriginalIpf.responseData);
            List<Object> unitsOriginalIpf = (List<Object>)responseDataOriginal.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            
            System.Assert.areEqual(4, unitsOriginalIpf.size(), 'Should have 4 units for original IPF');

            Integer failedCountOriginal = 0;
            for (Object obj : unitsOriginalIpf) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;
                Map<String, Object> sunObj = (Map<String, Object>)unitObj.get('sun');
                String unitName = String.valueOf(sunObj.get('Name'));

                System.Assert.isNotNull(unitObj.get('isMissedFailed'), 'isMissedFailed flag should not be null for ' + unitName + ' in original IPF');
                
                if((Boolean)unitObj.get('isMissedFailed')) {
                    failedCountOriginal++;
                }
                
                System.Assert.areEqual(true, unitObj.get('isMissedFailed'), 'All units should be flagged as missed/failed for original IPF: ' + unitName);
            }
            
            System.Assert.areEqual(4, failedCountOriginal, 'All 4 units should be flagged as failed for original IPF');

            masterIPE.reduivy__Individual_Academic_Profile__c = ipf2.Id;
            update masterIPE;

            // Test 2: Query with IPF2 - only 2 units should be flagged as missed/failed
            REDU_LightningResponse responseIpf2 = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                newIPE.Id,
                newIPE.Id, 
                ipsGroupListForIpe2[0].Id, 
                idvPathwayListForIpe2[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY, 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            System.Assert.areEqual(true, responseIpf2.isSuccess, 'Failed to get response with IPF2');
            Map<String, Object> responseDataIpf2 = (Map<String, Object>) JSON.deserializeUntyped(responseIpf2.responseData);
            List<Object> unitsIpf2 = (List<Object>)responseDataIpf2.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            
            System.Assert.areEqual(4, unitsIpf2.size(), 'Should have 4 units for IPF2');

            Integer failedCountIpf2 = 0;
            Integer notFailedCountIpf2 = 0;
            
            for (Object obj : unitsIpf2) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;
                Map<String, Object> sunObj = (Map<String, Object>)unitObj.get('sun');
                String unitName = String.valueOf(sunObj.get('Name'));
                Boolean isFailed = (Boolean)unitObj.get('isMissedFailed');

                System.Assert.isNotNull(isFailed, 'isMissedFailed flag should not be null for ' + unitName + ' in IPF2');
                                
                if(isFailed) {
                    failedCountIpf2++;
                } else {
                    notFailedCountIpf2++;
                }
            }
            
            System.Assert.areEqual(2, failedCountIpf2, 'Only 2 units (BUS101, BUS102) should be flagged as failed for IPF2');
            System.Assert.areEqual(2, notFailedCountIpf2, 'Other 2 units (BUS103, COM101) should NOT be flagged as failed for IPF2');

            Test.stopTest();
        }
    }

    /**
     * @description Test upsertEnrollment() with multiple IPFs - should only use placeholder IEN with matching IPF as faculty
     */
    @isTest
    static void testUpsertEnrollmentWithMultipleIpfsAsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        REDU_TriggerController.muteTriggers(new Set<String>{'IPS_IpeCompletion_EXE', 'IEN_CompletionEngine_EXE', 'IEN_SetIsnStatus_EXE', 'IEN_SetUnitIpsStatus_EXE'});
        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c, 
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Account campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        // Get study plan
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get required units
        List<Id> requiredUnitsList = new List<Id>();
        List<reduivy__Study_Plan_Structure__c> spsList = new List<reduivy__Study_Plan_Structure__c>();
        List<reduivy__Study_Unit__c> sunList = new List<reduivy__Study_Unit__c>();

        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, reduivy__Study_Unit__c, reduivy__Category__c, reduivy__Requirement_Logic__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
        ]) {
            requiredUnitsList.add(sps.reduivy__Study_Unit__c);

            sps.reduivy__Requirement_Logic__c = '';

            spsList.add(sps);

            sunList.add(new reduivy__Study_Unit__c(
                Id = sps.reduivy__Study_Unit__c,
                reduivy__Requirement_Logic__c = ''
            ));
        }

        update sunList;
        update spsList;
        System.Assert.isFalse(requiredUnitsList.isEmpty(), 'Required units should exist');

        // Create study offerings
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        for(Integer i = 0; i < requiredUnitsList.size(); i++) {
            sofList.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF ' + i,
                reduivy__Study_Unit__c = requiredUnitsList[i],
                reduivy__Academic_Term__c = academicTerm.Id,
                reduivy__Campus__c = campus.Id,
                reduivy__Capacity__c = 20,
                reduivy__Start_Date__c = System.today(),
                reduivy__End_Date__c = System.today().addDays(30),
                reduivy__UUID__c = System.UUID.randomUUID().toString()
            ));
        }
        insert sofList;

        // Create two Individual Academic Profiles
        // IPF1: Will have placeholder IENs created
        // IPF2: New profile, should create new IENs
        
        reduivy__Individual_Academic_Profile__c ipf1 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            students[0].Id + '_IPF1',
            students[0].Id,
            'Student_IPF1',
            IPF_Helper.STATUS_ACTIVE,
            true
        );
        
        reduivy__Individual_Academic_Profile__c ipf2 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            students[0].Id + '_IPF2',
            students[0].Id,
            'Student_IPF2',
            IPF_Helper.STATUS_ACTIVE,
            false
        );
        
        insert new List<reduivy__Individual_Academic_Profile__c>{ipf1, ipf2};

        // Create IPE1 with IPF1 (will have placeholder IENs created automatically)
        reduivy__Individual_Program_Enrollment__c ipe1 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            students[0].Id + '_IPE1', 
            students[0].Id, 
            studyPlan.reduivy__Study_Program__c, 
            studyPlan.Id, 
            null, 
            academicTerm.Id, 
            null, 
            null, 
            null, 
            null, 
            true, 
            IPE_Helper.getInProgressStatuses().get(0), 
            ipf1.Id
        );
        insert ipe1;

        // Get the Individual Pathway for IPE1
        reduivy__Individual_Pathway__c pathway1 = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :ipe1.Id AND reduivy__Academic_Term__c = :academicTerm.Id LIMIT 1];

        // Create IPE2 with IPF2
        reduivy__Individual_Program_Enrollment__c ipe2 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            students[0].Id + '_IPE2', 
            students[0].Id, 
            studyPlan.reduivy__Study_Program__c, 
            studyPlan.Id, 
            null, 
            academicTerm.Id, 
            null, 
            null, 
            null, 
            null, 
            true, 
            IPE_Helper.getInProgressStatuses().get(0), 
            ipf2.Id
        );
        insert ipe2;

        // Verify placeholder IENs were created for IPE1 (linked to IPF1)
        List<reduivy__Individual_Enrollment__c> placeholderIens = [
            SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :students[0].Id
            AND (reduivy__Individual_Academic_Profile__c = :ipf1.Id OR reduivy__Individual_Academic_Profile__c = :ipf2.Id)
            ORDER BY CreatedDate
        ];
        
        List<reduivy__Individual_Enrollment__c> placeholderIensForIpf1 = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> placeholderIensForIpf2 = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Individual_Enrollment__c ien : placeholderIens) {
            if(ien.reduivy__Individual_Academic_Profile__c == ipf1.Id) {
                placeholderIensForIpf1.add(ien);
            } else {
                placeholderIensForIpf2.add(ien);
            }
        }

        delete placeholderIensForIpf2;
        System.Assert.areEqual(requiredUnitsList.size(), placeholderIensForIpf1.size(), 'Placeholder IENs should be created for IPF1');

        // Get the Individual Pathway for IPE2
        reduivy__Individual_Pathway__c pathway2 = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :ipe2.Id AND reduivy__Academic_Term__c = :academicTerm.Id LIMIT 1];

        // Get IPS records for both IPEs
        Map<Id, reduivy__Individual_Plan_Structure__c> ipe1IpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipe2IpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for(reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Individual_Program_Enrollment__c, 
            reduivy__Study_Plan_Structure__c, reduivy__Parent_Plan_Structure__c, 
            reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c, 
            reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c IN (:ipe1.Id, :ipe2.Id)
            AND reduivy__Target_Unit_Id__c IN :requiredUnitsList
        ]) {
            if(ips.reduivy__Individual_Program_Enrollment__c == ipe1.Id) {
                ipe1IpsMap.put(ips.reduivy__Target_Unit_Id__c, ips);
            } else {
                ipe2IpsMap.put(ips.reduivy__Target_Unit_Id__c, ips);
            }
        }

        System.runAs(FACULTY_USER) {

            // SCENARIO A1: IPE1 with IPF1 - Should use existing placeholder IEN with matching IPF
            REDU_IndividualPlanStructure_OBJ scenarioA1Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA1Obj.ips = ipe1IpsMap.get(requiredUnitsList[0]);
            scenarioA1Obj.sof = sofList[0];
            scenarioA1Obj.academicTermIen = null;

            REDU_LightningResponse responseA1 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway1.Id, 
                JSON.serialize(scenarioA1Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            Test.startTest();
            // SCENARIO A2: IPE2 with IPF2 - Should create new IEN (no placeholder exists for IPF2)
            REDU_IndividualPlanStructure_OBJ scenarioA2Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA2Obj.ips = ipe2IpsMap.get(requiredUnitsList[0]);
            scenarioA2Obj.sof = sofList[0];
            scenarioA2Obj.academicTermIen = null;

            REDU_LightningResponse responseA2 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway2.Id, 
                JSON.serialize(scenarioA2Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            // SCENARIO A3: IPE1 with IPF1 - Enroll in second unit (use another placeholder)
            REDU_IndividualPlanStructure_OBJ scenarioA3Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA3Obj.ips = ipe1IpsMap.get(requiredUnitsList[1]);
            scenarioA3Obj.sof = sofList[1];
            scenarioA3Obj.academicTermIen = null;

            REDU_LightningResponse responseA3 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway1.Id, 
                JSON.serialize(scenarioA3Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            // SCENARIO A4: IPE2 with IPF2 - Enroll in second unit (create new IEN for IPF2)
            REDU_IndividualPlanStructure_OBJ scenarioA4Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA4Obj.ips = ipe2IpsMap.get(requiredUnitsList[1]);
            scenarioA4Obj.sof = sofList[1];
            scenarioA4Obj.academicTermIen = null;

            REDU_LightningResponse responseA4 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway2.Id, 
                JSON.serialize(scenarioA4Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            Test.stopTest();

            // ASSERTIONS
            System.Assert.areEqual(true, responseA1.isSuccess, 'Scenario A1 should be successful');
            System.Assert.areEqual(true, responseA2.isSuccess, 'Scenario A2 should be successful');
            System.Assert.areEqual(true, responseA3.isSuccess, 'Scenario A3 should be successful');
            System.Assert.areEqual(true, responseA4.isSuccess, 'Scenario A4 should be successful');

            // Query all IENs to verify behavior
            List<reduivy__Individual_Enrollment__c> allIens = [
                SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Study_Offering__c, 
                reduivy__Individual_Academic_Profile__c, reduivy__Enrollment_Status__c,
                CreatedDate
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c = :students[0].Id
                ORDER BY CreatedDate
            ];

            // Separate IENs by IPF
            Map<Id, List<reduivy__Individual_Enrollment__c>> iensByIpf = new Map<Id, List<reduivy__Individual_Enrollment__c>>{
                ipf1.Id => new List<reduivy__Individual_Enrollment__c>(),
                ipf2.Id => new List<reduivy__Individual_Enrollment__c>()
            };

            for(reduivy__Individual_Enrollment__c ien : allIens) {
                if(iensByIpf.containsKey(ien.reduivy__Individual_Academic_Profile__c)) {
                    iensByIpf.get(ien.reduivy__Individual_Academic_Profile__c).add(ien);
                }
            }

            // SCENARIO A1 & A3 ASSERTIONS: IPF1 should have used existing placeholder IENs
            List<reduivy__Individual_Enrollment__c> ipf1Iens = iensByIpf.get(ipf1.Id);
            System.Assert.areEqual(requiredUnitsList.size(), ipf1Iens.size(), 'IPF1 should have ' + requiredUnitsList.size() + ' IENs (all placeholders)');

            // Verify that the enrolled IENs for IPF1 match the original placeholder IENs
            Map<Id, Id> originalPlaceholderMap = new Map<Id, Id>();
            for(reduivy__Individual_Enrollment__c placeholder : placeholderIensForIpf1) {
                originalPlaceholderMap.put(placeholder.reduivy__Target_Unit_Id__c, placeholder.Id);
            }

            Integer ipf1EnrolledCount = 0;
            for(reduivy__Individual_Enrollment__c ien : ipf1Iens) {
                if(ien.reduivy__Target_Unit_Id__c == requiredUnitsList[0] || ien.reduivy__Target_Unit_Id__c == requiredUnitsList[1]) {
                    ipf1EnrolledCount++;
                    System.Assert.areEqual(
                        originalPlaceholderMap.get(ien.reduivy__Target_Unit_Id__c),
                        ien.Id,
                        'IPF1 should use existing placeholder IEN for unit ' + ien.reduivy__Target_Unit_Id__c
                    );
                    System.Assert.isNotNull(ien.reduivy__Study_Offering__c, 'IPF1 enrolled IEN should have study offering');
                    System.Assert.areEqual(IEN_Helper.getInProgressStatuses().get(0), ien.reduivy__Enrollment_Status__c, 'IPF1 enrolled IEN should have correct status');
                }
            }
            System.Assert.areEqual(2, ipf1EnrolledCount, 'IPF1 should have 2 enrolled IENs');

            // SCENARIO A2 & A4 ASSERTIONS: IPF2 should have created new IENs (no placeholders existed)
            List<reduivy__Individual_Enrollment__c> ipf2Iens = iensByIpf.get(ipf2.Id);
            System.Assert.areEqual(2, ipf2Iens.size(), 'IPF2 should have 2 IENs (newly created)');

            for(reduivy__Individual_Enrollment__c ien : ipf2Iens) {
                System.Assert.areEqual(ipf2.Id, ien.reduivy__Individual_Academic_Profile__c, 'IPF2 IEN should link to IPF2');
                System.Assert.isNotNull(ien.reduivy__Study_Offering__c, 'IPF2 IEN should have study offering');
                System.Assert.areEqual(IEN_Helper.getInProgressStatuses().get(0), ien.reduivy__Enrollment_Status__c, 'IPF2 IEN should have correct status');
                
                // Verify these are NEW IENs (not from the original placeholders)
                System.Assert.isFalse(
                    originalPlaceholderMap.values().contains(ien.Id),
                    'IPF2 should create NEW IEN, not use IPF1 placeholders'
                );
            }

            // Verify IPF isolation: Total IENs should be placeholders for IPF1 + enrolled for IPF2
            Integer totalExpectedIens = requiredUnitsList.size() + 2; // 3 placeholders for IPF1 + 2 enrolled for IPF2
            System.Assert.areEqual(totalExpectedIens, allIens.size(), 'Total IENs should match expected count');

            // Verify no cross-contamination between IPFs
            for(reduivy__Individual_Enrollment__c ien : allIens) {
                if(ien.reduivy__Individual_Academic_Profile__c == ipf1.Id) {
                    System.Assert.isTrue(
                        originalPlaceholderMap.values().contains(ien.Id),
                        'All IPF1 IENs should be from original placeholders'
                    );
                } else if(ien.reduivy__Individual_Academic_Profile__c == ipf2.Id) {
                    System.Assert.isFalse(
                        originalPlaceholderMap.values().contains(ien.Id),
                        'All IPF2 IENs should be newly created'
                    );
                }
            }
        }
    }

    /**
     * @description Test missed/failed units with multiple IPFs - should only flag units failed under the queried IPF as student
     */
    @isTest
    static void testMissedFailedOptionAllMultipleIpfsAsStudent() {
        
        User studentUser = testFactory.getStudentUser();

        // Query required data for testing
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String ipsUnitFieldString = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c;reduivy__Study_Plan_Structure__c.Name';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Master_Enrollment__c, reduivy__Default_Campus__c, reduivy__Sample_Record_Code__c, reduivy__Contact__c, reduivy__Individual_Academic_Profile__c, reduivy__Study_Plan__c, reduivy__Study_Program__c FROM reduivy__Individual_Program_Enrollment__c WHERE reduivy__Contact__c =: studentUser.ContactId AND RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        List<reduivy__Study_Term__c> stm = [SELECT Id FROM reduivy__Study_Term__c WHERE Id != :masterIpe.reduivy__Starting_Term__c AND RecordTypeId = :STM_Helper.getAcademicTermRecordTypeId()];

        List<reduivy__Study_Grade_Setting__c> sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c LIMIT 1];

        Set<Id> sunIds = new Set<Id>();

        //Removed all individual enrollments
        List<reduivy__Individual_Enrollment__c> ienToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE reduivy__Contact__c = :masterIpe.reduivy__Contact__c];
        List<reduivy__Individual_Enrollment_Grade__c> iegToBeDeleted = [SELECT Id FROM reduivy__Individual_Enrollment_Grade__c WHERE reduivy__Individual_Enrollment__c IN :ienToBeDeleted];
        delete iegToBeDeleted;
        delete ienToBeDeleted;

        //Get study units from pathway
        List<reduivy__Study_Unit__c> studyUnits = new List<reduivy__Study_Unit__c>();
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name, reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c AND reduivy__Study_Pathway_Term__r.reduivy__Term_Number__c < 3 ORDER BY reduivy__Study_Unit__r.Name]) {
            if(!String.isBlank(spu.reduivy__Study_Unit__c)) {
                sunIds.add(spu.reduivy__Study_Unit__c);
                studyUnits.add(spu.reduivy__Study_Unit__r);
            }
        }

        // Create new Individual Academic Profiles
        // IPF1: Original IPF with all units failed
        // IPF2: New IPF with only BUS101 and BUS102 failed, others not enrolled
        
        Id originalIpfId = masterIPE.reduivy__Individual_Academic_Profile__c;
        
        reduivy__Individual_Academic_Profile__c ipf2 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            'Student_NewProfile',
            masterIPE.reduivy__Contact__c,
            'Student_NewProfile',
            IPF_Helper.STATUS_ACTIVE,
            false
        );
        
        insert ipf2;

        reduivy__Individual_Program_Enrollment__c newIPE = masterIPE.clone(false, true, false, false);
        newIPE.reduivy__Individual_Academic_Profile__c = ipf2.Id;
        insert newIPE;

        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, reduivy__Individual_Program_Enrollment__c,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE (reduivy__Individual_Program_Enrollment__c = :masterIPE.Id OR reduivy__Individual_Program_Enrollment__c = :newIPE.Id)
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Study_Plan_Structure__r.reduivy__Sample_Record_Code__c = :STUDY_PLAN_STRUCTURE_GROUP
        ];

        List<reduivy__Individual_Plan_Structure__c> ipsGroupListForIpe1 = new List<reduivy__Individual_Plan_Structure__c>();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupListForIpe2 = new List<reduivy__Individual_Plan_Structure__c>();
        for(reduivy__Individual_Plan_Structure__c ipsGrp : ipsGroupList) {
            if(ipsGrp.reduivy__Individual_Program_Enrollment__c == masterIPE.Id) {
                ipsGroupListForIpe1.add(ipsGrp);
            } else {
                ipsGroupListForIpe2.add(ipsGrp);
            }
        }

        System.Assert.isFalse(ipsGroupListForIpe1.isEmpty(), 'The actual value should be as expected');
        System.Assert.isFalse(ipsGroupListForIpe2.isEmpty(), 'The actual value should be as expected');

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Status__c, reduivy__Academic_Term__c, reduivy__Individual_Program_Enrollment__c, reduivy__Individual_Program_Enrollment__r.reduivy__Contact__r.reduivy__Sample_Record_Code__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c, reduivy__Sample_Record_Code__c, reduivy__Term_Number__c
            FROM reduivy__Individual_Pathway__c 
            WHERE reduivy__Term_Number__c < 3 
            AND (reduivy__Individual_Program_Enrollment__c = :masterIPE.Id OR reduivy__Individual_Program_Enrollment__c = :newIPE.Id)
            ORDER BY reduivy__Term_Number__c ASC
        ];

        List<reduivy__Individual_Pathway__c> idvPathwayListForIpe1 = new List<reduivy__Individual_Pathway__c>();
        List<reduivy__Individual_Pathway__c> idvPathwayListForIpe2 = new List<reduivy__Individual_Pathway__c>();

        List<reduivy__Individual_Pathway__c> ipwToBeUpdated = new List<reduivy__Individual_Pathway__c>();
        for(reduivy__Individual_Pathway__c ipw : idvPathwayList) {
            if(ipw.reduivy__Term_Number__c == 1) {
                ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
                    Id = ipw.Id,
                    reduivy__Academic_Term__c = stm[0].Id,
                    reduivy__Individual_Academic_Progress__c = null
                ));
            } else {
                ipwToBeUpdated.add(new reduivy__Individual_Pathway__c(
                    Id = ipw.Id,
                    reduivy__Academic_Term__c = masterIPE.reduivy__Starting_Term__c,
                    reduivy__Individual_Academic_Progress__c = null
                ));
            }

            if(ipw.reduivy__Individual_Program_Enrollment__c == masterIPE.Id) {
                idvPathwayListForIpe1.add(ipw);
            } else {
                idvPathwayListForIpe2.add(ipw);
            }
        }
        
        update ipwToBeUpdated;

        // Create study offerings for previous term
        List<reduivy__Study_Offering__c> sofToBeCreated = new List<reduivy__Study_Offering__c>();
        for(Id sunId : sunIds) {
            sofToBeCreated.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF',
                reduivy__Study_Unit__c = sunId,
                reduivy__Academic_Term__c = stm[0].Id,
                reduivy__Campus__c = masterIpe.reduivy__Default_Campus__c,
                reduivy__Capacity__c = 20
            ));
        }

        insert sofToBeCreated;

        // Create failed IENs under original IPF (all units failed)
        List<reduivy__Individual_Enrollment__c> ienToBeCreated = new List<reduivy__Individual_Enrollment__c>();
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                reduivy__Study_Offering__c = sof.Id,
                reduivy__Enrollment_Status__c = IEN_Helper.getCompletedFailStatuses()[0],
                reduivy__Study_Grade_Setting__c = sgs[0].Id,
                reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                reduivy__Numerical_Grade__c = 0,
                reduivy__Bypass_Requirement_Met__c = true,
                reduivy__Individual_Academic_Profile__c = originalIpfId,
                reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM
            ));
        }

        // Create failed IENs under IPF2 (only first 2 units: BUS101, BUS102)
        List<reduivy__Individual_Enrollment__c> ienForIpf2 = new List<reduivy__Individual_Enrollment__c>();
        Integer counter = 0;
        for(reduivy__Study_Offering__c sof : sofToBeCreated) {
            if(counter < 2) { // Only first 2 units (BUS101, BUS102)
                ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                    reduivy__Study_Offering__c = sof.Id,
                    reduivy__Enrollment_Status__c = IEN_Helper.getCompletedFailStatuses()[0],
                    reduivy__Study_Grade_Setting__c = sgs[0].Id,
                    reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                    reduivy__Numerical_Grade__c = 0,
                    reduivy__Bypass_Requirement_Met__c = true,
                    reduivy__Individual_Academic_Profile__c = ipf2.Id,
                    reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM
                ));
            } else {
                ienToBeCreated.add(new reduivy__Individual_Enrollment__c(
                    reduivy__Contact__c = masterIpe.reduivy__Contact__c,
                    reduivy__Study_Offering__c = sof.Id,
                    reduivy__Enrollment_Status__c = IEN_Helper.getCompletedPassStatuses()[0],
                    reduivy__Study_Grade_Setting__c = sgs[0].Id,
                    reduivy__Grade_Release_Status__c = IEN_Helper.GRADE_RELEASE_STATUS_RELEASED,
                    reduivy__Numerical_Grade__c = 100,
                    reduivy__Bypass_Requirement_Met__c = true,
                    reduivy__Individual_Academic_Profile__c = ipf2.Id,
                    reduivy__Enrollment_Type__c = IEN_Helper.ENROLLMENT_TYPE_PROGRAM
                ));
            }
            counter++;
        }

        insert ienToBeCreated;

        System.runAs(studentUser){

            Test.startTest();

            // Test 1: Query with original IPF - all units should be flagged as missed/failed
            REDU_LightningResponse responseOriginalIpf = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                masterIPE.Id,
                masterIPE.Id, 
                ipsGroupListForIpe1[0].Id, 
                idvPathwayListForIpe1[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY, 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            System.Assert.areEqual(true, responseOriginalIpf.isSuccess, 'Failed to get response with original IPF');
            Map<String, Object> responseDataOriginal = (Map<String, Object>) JSON.deserializeUntyped(responseOriginalIpf.responseData);
            List<Object> unitsOriginalIpf = (List<Object>)responseDataOriginal.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            
            System.Assert.areEqual(4, unitsOriginalIpf.size(), 'Should have 4 units for original IPF');

            Integer failedCountOriginal = 0;
            for (Object obj : unitsOriginalIpf) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;
                Map<String, Object> sunObj = (Map<String, Object>)unitObj.get('sun');
                String unitName = String.valueOf(sunObj.get('Name'));

                System.Assert.isNotNull(unitObj.get('isMissedFailed'), 'isMissedFailed flag should not be null for ' + unitName + ' in original IPF');
                
                if((Boolean)unitObj.get('isMissedFailed')) {
                    failedCountOriginal++;
                }
                
                System.Assert.areEqual(true, unitObj.get('isMissedFailed'), 'All units should be flagged as missed/failed for original IPF: ' + unitName);
            }
            
            System.Assert.areEqual(4, failedCountOriginal, 'All 4 units should be flagged as failed for original IPF');

            masterIPE.reduivy__Individual_Academic_Profile__c = ipf2.Id;
            update masterIPE;

            // Test 2: Query with IPF2 - only 2 units should be flagged as missed/failed
            REDU_LightningResponse responseIpf2 = REDU_IpePathwayTermUnitTable_LCTRL.getIndividualPlanStructureUnits(
                newIPE.Id,
                newIPE.Id, 
                ipsGroupListForIpe2[0].Id, 
                idvPathwayListForIpe2[1].Id,  
                masterIPE.reduivy__Default_Campus__c, 
                ipsUnitFieldString, 
                null, 
                USR_Helper.USER_MODE_ADMIN, 
                IPW_Helper.UNIT_LISTING_MODE_PATHWAY, 
                null, 
                'All',
                UserInfo.getLanguage(),
                null
            );

            System.Assert.areEqual(true, responseIpf2.isSuccess, 'Failed to get response with IPF2');
            Map<String, Object> responseDataIpf2 = (Map<String, Object>) JSON.deserializeUntyped(responseIpf2.responseData);
            List<Object> unitsIpf2 = (List<Object>)responseDataIpf2.get(REDU_IpePathwayTermUnitTable_LCTRL.CHILDUNITSIPS_PARAM);
            
            System.Assert.areEqual(4, unitsIpf2.size(), 'Should have 4 units for IPF2');

            Integer failedCountIpf2 = 0;
            Integer notFailedCountIpf2 = 0;
            
            for (Object obj : unitsIpf2) {
                Map<String, Object> unitObj = (Map<String, Object>)obj;
                Map<String, Object> sunObj = (Map<String, Object>)unitObj.get('sun');
                String unitName = String.valueOf(sunObj.get('Name'));
                Boolean isFailed = (Boolean)unitObj.get('isMissedFailed');

                System.Assert.isNotNull(isFailed, 'isMissedFailed flag should not be null for ' + unitName + ' in IPF2');
                                
                if(isFailed) {
                    failedCountIpf2++;
                } else {
                    notFailedCountIpf2++;
                }
            }
            
            System.Assert.areEqual(2, failedCountIpf2, 'Only 2 units (BUS101, BUS102) should be flagged as failed for IPF2');
            System.Assert.areEqual(2, notFailedCountIpf2, 'Other 2 units (BUS103, COM101) should NOT be flagged as failed for IPF2');

            Test.stopTest();
        }
    }

    /**
     * @description Test upsertEnrollment() with multiple IPFs - should only use placeholder IEN with matching IPF as student
     */
    @isTest
    static void testUpsertEnrollmentWithMultipleIpfsAsStudent() {

        REDU_TriggerController.muteTriggers(new Set<String>{'IPS_IpeCompletion_EXE', 'IEN_CompletionEngine_EXE'});
        
        List<Contact> students = [SELECT Id, 
            reduivy__Sample_Record_Code__c, 
            Name
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
		User studentUser = [
            SELECT Id, ContactId FROM User WHERE ProfileId = :REDU_AppSetting_UTIL.getStudentProfileId() AND ContactId = :students LIMIT 1
        ];

        //Get current running term
        reduivy__Study_Term__c academicTerm = [SELECT Id,
            reduivy__Sample_Record_Code__c 
            FROM reduivy__Study_Term__c
            WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() 
            AND reduivy__End_Date__c >= TODAY
            WITH USER_MODE
            ORDER BY reduivy__Start_Date__c
            LIMIT 1
        ];

        Account campus = [SELECT Id FROM Account WHERE Name = 'Sydney Campus' AND RecordTypeId = :ACC_Helper.getCampusRecordTypeId() LIMIT 1];

        // Get study plan
        reduivy__Study_Plan__c studyPlan = [SELECT Id, 
            reduivy__Individual_Enrollment_Creation_Mode__c,
            reduivy__Study_Program__c
            FROM reduivy__Study_Plan__c
            WHERE reduivy__Sample_Record_Code__c = 'BACBIS_MajorA'
            LIMIT 1
        ];

        studyPlan.reduivy__Individual_Enrollment_Creation_Mode__c = SPL_Helper.IEN_CREATION_MODE_REQUIRED_UNITS_ONLY;
        update studyPlan;

        // Get required units
        List<Id> requiredUnitsList = new List<Id>();
        List<reduivy__Study_Plan_Structure__c> spsList = new List<reduivy__Study_Plan_Structure__c>();
        List<reduivy__Study_Unit__c> sunList = new List<reduivy__Study_Unit__c>();

        for (reduivy__Study_Plan_Structure__c sps : [SELECT Id, reduivy__Study_Unit__c, reduivy__Category__c, reduivy__Requirement_Logic__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c = :studyPlan.Id
            AND RecordTypeId = :SPS_Helper.getUnitRecordTypeId()
            AND reduivy__Category__c = :SPS_Helper.CATEGORY_REQUIRED
        ]) {
            requiredUnitsList.add(sps.reduivy__Study_Unit__c);

            sps.reduivy__Requirement_Logic__c = '';

            spsList.add(sps);

            sunList.add(new reduivy__Study_Unit__c(
                Id = sps.reduivy__Study_Unit__c,
                reduivy__Requirement_Logic__c = ''
            ));
        }

        update sunList;
        update spsList;
        System.Assert.isFalse(requiredUnitsList.isEmpty(), 'Required units should exist');

        // Create study offerings
        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        for(Integer i = 0; i < requiredUnitsList.size(); i++) {
            sofList.add(new reduivy__Study_Offering__c(
                Name = 'Test SOF ' + i,
                reduivy__Study_Unit__c = requiredUnitsList[i],
                reduivy__Academic_Term__c = academicTerm.Id,
                reduivy__Campus__c = campus.Id,
                reduivy__Capacity__c = 20,
                reduivy__Start_Date__c = System.today(),
                reduivy__End_Date__c = System.today().addDays(30),
                reduivy__UUID__c = System.UUID.randomUUID().toString()
            ));
        }
        insert sofList;

        // Create two Individual Academic Profiles
        // IPF1: Will have placeholder IENs created
        // IPF2: New profile, should create new IENs
        
        reduivy__Individual_Academic_Profile__c ipf1 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            students[0].Id + '_IPF1',
            students[0].Id,
            'Student_IPF1',
            IPF_Helper.STATUS_ACTIVE,
            true
        );
        
        reduivy__Individual_Academic_Profile__c ipf2 = REDU_TestData_UTIL.newIndividualAcademicProfile(
            students[0].Id + '_IPF2',
            students[0].Id,
            'Student_IPF2',
            IPF_Helper.STATUS_ACTIVE,
            false
        );
        
        insert new List<reduivy__Individual_Academic_Profile__c>{ipf1, ipf2};

        // Create IPE1 with IPF1 (will have placeholder IENs created automatically)
        reduivy__Individual_Program_Enrollment__c ipe1 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            students[0].Id + '_IPE1', 
            students[0].Id, 
            studyPlan.reduivy__Study_Program__c, 
            studyPlan.Id, 
            null, 
            academicTerm.Id, 
            null, 
            null, 
            null, 
            null, 
            true, 
            IPE_Helper.getInProgressStatuses().get(0), 
            ipf1.Id
        );
        insert ipe1;

        // Get the Individual Pathway for IPE1
        reduivy__Individual_Pathway__c pathway1 = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :ipe1.Id AND reduivy__Academic_Term__c = :academicTerm.Id LIMIT 1];

        // Create IPE2 with IPF2
        reduivy__Individual_Program_Enrollment__c ipe2 = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
            students[0].Id + '_IPE2', 
            students[0].Id, 
            studyPlan.reduivy__Study_Program__c, 
            studyPlan.Id, 
            null, 
            academicTerm.Id, 
            null, 
            null, 
            null, 
            null, 
            true, 
            IPE_Helper.getInProgressStatuses().get(0), 
            ipf2.Id
        );
        insert ipe2;

        // Verify placeholder IENs were created for IPE1 (linked to IPF1)
        List<reduivy__Individual_Enrollment__c> placeholderIens = [
            SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Enrollment__c 
            WHERE reduivy__Contact__c = :students[0].Id
            AND (reduivy__Individual_Academic_Profile__c = :ipf1.Id OR reduivy__Individual_Academic_Profile__c = :ipf2.Id)
            ORDER BY CreatedDate
        ];
        
        List<reduivy__Individual_Enrollment__c> placeholderIensForIpf1 = new List<reduivy__Individual_Enrollment__c>();
        List<reduivy__Individual_Enrollment__c> placeholderIensForIpf2 = new List<reduivy__Individual_Enrollment__c>();

        for(reduivy__Individual_Enrollment__c ien : placeholderIens) {
            if(ien.reduivy__Individual_Academic_Profile__c == ipf1.Id) {
                placeholderIensForIpf1.add(ien);
            } else {
                placeholderIensForIpf2.add(ien);
            }
        }

        delete placeholderIensForIpf2;
        System.Assert.areEqual(requiredUnitsList.size(), placeholderIensForIpf1.size(), 'Placeholder IENs should be created for IPF1');

        // Get the Individual Pathway for IPE2
        reduivy__Individual_Pathway__c pathway2 = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :ipe2.Id AND reduivy__Academic_Term__c = :academicTerm.Id LIMIT 1];

        // Get IPS records for both IPEs
        Map<Id, reduivy__Individual_Plan_Structure__c> ipe1IpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        Map<Id, reduivy__Individual_Plan_Structure__c> ipe2IpsMap = new Map<Id, reduivy__Individual_Plan_Structure__c>();
        
        for(reduivy__Individual_Plan_Structure__c ips : [
            SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Individual_Program_Enrollment__c, 
            reduivy__Study_Plan_Structure__c, reduivy__Parent_Plan_Structure__c, 
            reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c, 
            reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c IN (:ipe1.Id, :ipe2.Id)
            AND reduivy__Target_Unit_Id__c IN :requiredUnitsList
        ]) {
            if(ips.reduivy__Individual_Program_Enrollment__c == ipe1.Id) {
                ipe1IpsMap.put(ips.reduivy__Target_Unit_Id__c, ips);
            } else {
                ipe2IpsMap.put(ips.reduivy__Target_Unit_Id__c, ips);
            }
        }

        System.runAs(studentUser) {

            // SCENARIO A1: IPE1 with IPF1 - Should use existing placeholder IEN with matching IPF
            REDU_IndividualPlanStructure_OBJ scenarioA1Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA1Obj.ips = ipe1IpsMap.get(requiredUnitsList[0]);
            scenarioA1Obj.sof = sofList[0];
            scenarioA1Obj.academicTermIen = null;

            REDU_LightningResponse responseA1 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway1.Id, 
                JSON.serialize(scenarioA1Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            Test.startTest();
            // SCENARIO A2: IPE2 with IPF2 - Should create new IEN (no placeholder exists for IPF2)
            REDU_IndividualPlanStructure_OBJ scenarioA2Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA2Obj.ips = ipe2IpsMap.get(requiredUnitsList[0]);
            scenarioA2Obj.sof = sofList[0];
            scenarioA2Obj.academicTermIen = null;

            REDU_LightningResponse responseA2 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway2.Id, 
                JSON.serialize(scenarioA2Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            // SCENARIO A3: IPE1 with IPF1 - Enroll in second unit (use another placeholder)
            REDU_IndividualPlanStructure_OBJ scenarioA3Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA3Obj.ips = ipe1IpsMap.get(requiredUnitsList[1]);
            scenarioA3Obj.sof = sofList[1];
            scenarioA3Obj.academicTermIen = null;

            REDU_LightningResponse responseA3 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway1.Id, 
                JSON.serialize(scenarioA3Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            // SCENARIO A4: IPE2 with IPF2 - Enroll in second unit (create new IEN for IPF2)
            REDU_IndividualPlanStructure_OBJ scenarioA4Obj = new REDU_IndividualPlanStructure_OBJ();
            scenarioA4Obj.ips = ipe2IpsMap.get(requiredUnitsList[1]);
            scenarioA4Obj.sof = sofList[1];
            scenarioA4Obj.academicTermIen = null;

            REDU_LightningResponse responseA4 = REDU_IpePathwayTermUnitTable_LCTRL.upsertEnrollment(
                pathway2.Id, 
                JSON.serialize(scenarioA4Obj), 
                IEN_Helper.ENROLLMENT_ACTION_ENROLL, 
                IEN_Helper.getInProgressStatuses().get(0)
            );

            Test.stopTest();

            // ASSERTIONS
            System.Assert.areEqual(true, responseA1.isSuccess, 'Scenario A1 should be successful');
            System.Assert.areEqual(true, responseA2.isSuccess, 'Scenario A2 should be successful');
            System.Assert.areEqual(true, responseA3.isSuccess, 'Scenario A3 should be successful');
            System.Assert.areEqual(true, responseA4.isSuccess, 'Scenario A4 should be successful');

            // Query all IENs to verify behavior
            List<reduivy__Individual_Enrollment__c> allIens = [
                SELECT Id, reduivy__Target_Unit_Id__c, reduivy__Study_Offering__c, 
                reduivy__Individual_Academic_Profile__c, reduivy__Enrollment_Status__c,
                CreatedDate
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Contact__c = :students[0].Id
                ORDER BY CreatedDate
            ];

            // Separate IENs by IPF
            Map<Id, List<reduivy__Individual_Enrollment__c>> iensByIpf = new Map<Id, List<reduivy__Individual_Enrollment__c>>{
                ipf1.Id => new List<reduivy__Individual_Enrollment__c>(),
                ipf2.Id => new List<reduivy__Individual_Enrollment__c>()
            };

            for(reduivy__Individual_Enrollment__c ien : allIens) {
                if(iensByIpf.containsKey(ien.reduivy__Individual_Academic_Profile__c)) {
                    iensByIpf.get(ien.reduivy__Individual_Academic_Profile__c).add(ien);
                }
            }

            // SCENARIO A1 & A3 ASSERTIONS: IPF1 should have used existing placeholder IENs
            List<reduivy__Individual_Enrollment__c> ipf1Iens = iensByIpf.get(ipf1.Id);
            System.Assert.areEqual(requiredUnitsList.size(), ipf1Iens.size(), 'IPF1 should have ' + requiredUnitsList.size() + ' IENs (all placeholders)');

            // Verify that the enrolled IENs for IPF1 match the original placeholder IENs
            Map<Id, Id> originalPlaceholderMap = new Map<Id, Id>();
            for(reduivy__Individual_Enrollment__c placeholder : placeholderIensForIpf1) {
                originalPlaceholderMap.put(placeholder.reduivy__Target_Unit_Id__c, placeholder.Id);
            }

            Integer ipf1EnrolledCount = 0;
            for(reduivy__Individual_Enrollment__c ien : ipf1Iens) {
                if(ien.reduivy__Target_Unit_Id__c == requiredUnitsList[0] || ien.reduivy__Target_Unit_Id__c == requiredUnitsList[1]) {
                    ipf1EnrolledCount++;
                    System.Assert.areEqual(
                        originalPlaceholderMap.get(ien.reduivy__Target_Unit_Id__c),
                        ien.Id,
                        'IPF1 should use existing placeholder IEN for unit ' + ien.reduivy__Target_Unit_Id__c
                    );
                    System.Assert.isNotNull(ien.reduivy__Study_Offering__c, 'IPF1 enrolled IEN should have study offering');
                    System.Assert.areEqual(IEN_Helper.getInProgressStatuses().get(0), ien.reduivy__Enrollment_Status__c, 'IPF1 enrolled IEN should have correct status');
                }
            }
            System.Assert.areEqual(2, ipf1EnrolledCount, 'IPF1 should have 2 enrolled IENs');

            // SCENARIO A2 & A4 ASSERTIONS: IPF2 should have created new IENs (no placeholders existed)
            List<reduivy__Individual_Enrollment__c> ipf2Iens = iensByIpf.get(ipf2.Id);
            System.Assert.areEqual(2, ipf2Iens.size(), 'IPF2 should have 2 IENs (newly created)');

            for(reduivy__Individual_Enrollment__c ien : ipf2Iens) {
                System.Assert.areEqual(ipf2.Id, ien.reduivy__Individual_Academic_Profile__c, 'IPF2 IEN should link to IPF2');
                System.Assert.isNotNull(ien.reduivy__Study_Offering__c, 'IPF2 IEN should have study offering');
                System.Assert.areEqual(IEN_Helper.getInProgressStatuses().get(0), ien.reduivy__Enrollment_Status__c, 'IPF2 IEN should have correct status');
                
                // Verify these are NEW IENs (not from the original placeholders)
                System.Assert.isFalse(
                    originalPlaceholderMap.values().contains(ien.Id),
                    'IPF2 should create NEW IEN, not use IPF1 placeholders'
                );
            }

            // Verify IPF isolation: Total IENs should be placeholders for IPF1 + enrolled for IPF2
            Integer totalExpectedIens = requiredUnitsList.size() + 2; // 3 placeholders for IPF1 + 2 enrolled for IPF2
            System.Assert.areEqual(totalExpectedIens, allIens.size(), 'Total IENs should match expected count');

            // Verify no cross-contamination between IPFs
            for(reduivy__Individual_Enrollment__c ien : allIens) {
                if(ien.reduivy__Individual_Academic_Profile__c == ipf1.Id) {
                    System.Assert.isTrue(
                        originalPlaceholderMap.values().contains(ien.Id),
                        'All IPF1 IENs should be from original placeholders'
                    );
                } else if(ien.reduivy__Individual_Academic_Profile__c == ipf2.Id) {
                    System.Assert.isFalse(
                        originalPlaceholderMap.values().contains(ien.Id),
                        'All IPF2 IENs should be newly created'
                    );
                }
            }
        }
    }
}