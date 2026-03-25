/**
 * @author      WDCi (Jordan)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for REDU_IpePathwayTermListing_LCTRL
 * @changehistory
 * ISS-002336 25-03-2025 updated to call the getIndividualProgramEnrollment with missedFailedUnitListingOption param
 */
@isTest
public inherited sharing class REDU_IpePathwayTermListing_TEST {

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
     * @description Test as admin for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Pathway__c ipwInCurrentStatus = [SELECT Id, reduivy__Individual_Program_Enrollment__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Status__c = :IPW_Helper.STATUS_CURRENT LIMIT 1];
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name, reduivy__Contact__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() AND Id = :ipwInCurrentStatus.reduivy__Individual_Program_Enrollment__c LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c]) {
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

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_ADMIN, null, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));
                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test hidden with user mode = student as admin for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testHiddenWithStudentModeForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();
        List<reduivy__Individual_Plan_Structure__c> topGroupIpsList = new List<reduivy__Individual_Plan_Structure__c>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);

            ips.reduivy__Hide_in_Enrollment__c = true;
            topGroupIpsList.add(ips);
        }

        // update to hide the top group
        update topGroupIpsList;

        System.runAs(ADMIN_USER){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_STUDENT, null, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));
                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areEqual(0, groupIpsWrapperResponse.size(), 'The response should 0.');
                System.Assert.areNotEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size(), 'The response should not be the same.');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test hidden with user mode = student as admin for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testHiddenWithAdminModeForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();
        List<reduivy__Individual_Plan_Structure__c> topGroupIpsList = new List<reduivy__Individual_Plan_Structure__c>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);

            ips.reduivy__Hide_in_Enrollment__c = true;
            topGroupIpsList.add(ips);
        }

        // update to hide the top group
        update topGroupIpsList;

        System.runAs(ADMIN_USER){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_ADMIN, null, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));
                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areNotEqual(0, groupIpsWrapperResponse.size(), 'The response should not be 0.');
                System.Assert.areEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size(), 'The response should be the same.');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testForAdminUnitListingModePathway() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name, reduivy__Contact__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c]) {
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

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_ADMIN, IPW_Helper.UNIT_LISTING_MODE_PATHWAY, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));

                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                //will return groups of different sizes, including those related to the pathway as well as groups with failed units
                if(idvPathway.reduivy__Term_Number__c == 1) {
                    System.Assert.areEqual(3, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 2) {
                    System.Assert.areEqual(2, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 3) {
                    System.Assert.areEqual(4, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 4) {
                    System.Assert.areEqual(0, groupIpsWrapperResponse.size());
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student user for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testForStudentUser() {

        reduivy__Individual_Pathway__c ipwInCurrentStatus = [SELECT Id, reduivy__Individual_Program_Enrollment__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Status__c = :IPW_Helper.STATUS_CURRENT LIMIT 1];
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__r.Name FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() AND Id = :ipwInCurrentStatus.reduivy__Individual_Program_Enrollment__c LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);
        }

        System.runAs(studentUser){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_STUDENT, null, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));
                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size());
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test hidden with user mode = student as student user for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testHiddenWithStudentModeForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__r.Name FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();
        List<reduivy__Individual_Plan_Structure__c> topGroupIpsList = new List<reduivy__Individual_Plan_Structure__c>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);

            ips.reduivy__Hide_in_Enrollment__c = true;
            topGroupIpsList.add(ips);
        }

        // update to hide the top group
        update topGroupIpsList;

        System.runAs(studentUser){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_STUDENT, null, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));
                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areEqual(0, groupIpsWrapperResponse.size(), 'The response should 0.');
                System.Assert.areNotEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size(), 'The response should not be the same.');
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as student user for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testForStudentUserUnitListingModePathway() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__r.Name, reduivy__Starting_Term__c, reduivy__Study_Pathway__c, reduivy__Default_Campus__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c]) {
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

        System.runAs(studentUser){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_STUDENT, IPW_Helper.UNIT_LISTING_MODE_PATHWAY, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));

                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                //will return groups of different sizes, including those related to the pathway as well as groups with failed units
                if(idvPathway.reduivy__Term_Number__c == 1) {
                    System.Assert.areEqual(3, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 2) {
                    System.Assert.areEqual(2, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 3) {
                    System.Assert.areEqual(4, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 4) {
                    System.Assert.areEqual(0, groupIpsWrapperResponse.size());
                }
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Pathway__c ipwInCurrentStatus = [SELECT Id, reduivy__Individual_Program_Enrollment__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Status__c = :IPW_Helper.STATUS_CURRENT LIMIT 1];
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() AND Id = :ipwInCurrentStatus.reduivy__Individual_Program_Enrollment__c LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);
        }

        System.runAs(FACULTY_USER){

            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_STUDENT, null, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));
                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size());
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test hidden with user mode = student as faculty for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testHiddenWithStudentModeForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();
        List<reduivy__Individual_Plan_Structure__c> topGroupIpsList = new List<reduivy__Individual_Plan_Structure__c>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);

            ips.reduivy__Hide_in_Enrollment__c = true;
            topGroupIpsList.add(ips);
        }

        // update to hide the top group
        update topGroupIpsList;

        System.runAs(FACULTY_USER){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_STUDENT, null, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));
                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areEqual(0, groupIpsWrapperResponse.size(), 'The response should 0.');
                System.Assert.areNotEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size(), 'The response should not be the same.');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test hidden with user mode = student as faculty for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testHiddenWithAdminModeForFaculty() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();
        List<reduivy__Individual_Plan_Structure__c> topGroupIpsList = new List<reduivy__Individual_Plan_Structure__c>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);

            ips.reduivy__Hide_in_Enrollment__c = true;
            topGroupIpsList.add(ips);
        }

        // update to hide the top group
        update topGroupIpsList;

        System.runAs(FACULTY_USER){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_ADMIN, null, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));
                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areNotEqual(0, groupIpsWrapperResponse.size(), 'The response should not be 0.');
                System.Assert.areEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size(), 'The response should be the same.');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpePathwayTermListing_LCTRL
     */
    @isTest   
    static void testForFacultyUserUnitListingModePathway() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Study_Plan__r.Name, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c]) {
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

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_STUDENT, IPW_Helper.UNIT_LISTING_MODE_PATHWAY, null, 'All');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));

                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                //will return groups of different sizes, including those related to the pathway as well as groups with failed units
                if(idvPathway.reduivy__Term_Number__c == 1) {
                    System.Assert.areEqual(3, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 2) {
                    System.Assert.areEqual(2, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 3) {
                    System.Assert.areEqual(4, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 4) {
                    System.Assert.areEqual(0, groupIpsWrapperResponse.size());
                }
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as admin user for REDU_IpePathwayTermListing_LCTRL with missed failed unit option = none + all unit listing (expected: always return 3 top grp no matter in which term)
     */
    @isTest  
    static void testForAdminWtihMissedFailedUnitOptionNoneAndAllUnitListingMode() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Pathway__c ipwInCurrentStatus = [SELECT Id, reduivy__Individual_Program_Enrollment__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Status__c = :IPW_Helper.STATUS_CURRENT LIMIT 1];
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name, reduivy__Contact__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() AND Id = :ipwInCurrentStatus.reduivy__Individual_Program_Enrollment__c LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c]) {
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

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_ADMIN, null, null, 'None');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));

                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));

                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin user for REDU_IpePathwayTermListing_LCTRL with missed failed unit option = None + pathway unit listing (will return groups of different sizes and only shows groups related to the pathway and does not consider failed units)
     */
    @isTest  
    static void testForAdminWtihMissedFailedUnitOptionAllAndPathwayUnitListingMode() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name, reduivy__Contact__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c]) {
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

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_ADMIN, IPW_Helper.UNIT_LISTING_MODE_PATHWAY, null, 'None');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));

                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                if(idvPathway.reduivy__Term_Number__c == 1) {
                    System.Assert.areEqual(3, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 2) {
                    System.Assert.areEqual(2, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 3) {
                    System.Assert.areEqual(2, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 4) {
                    System.Assert.areEqual(0, groupIpsWrapperResponse.size());
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpePathwayTermListing_LCTRL with missed failed unit option = none + all unit listing (expected: always return 3 top grp no matter in which term)
     */
    @isTest  
    static void testForFacultyWtihMissedFailedUnitOptionNoneAndAllUnitListingMode() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Pathway__c ipwInCurrentStatus = [SELECT Id, reduivy__Individual_Program_Enrollment__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Status__c = :IPW_Helper.STATUS_CURRENT LIMIT 1];
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name, reduivy__Contact__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() AND Id = :ipwInCurrentStatus.reduivy__Individual_Program_Enrollment__c LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c]) {
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

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);
        }

        System.runAs(FACULTY_USER){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_FACULTY, null, null, 'None');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));

                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));

                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpePathwayTermListing_LCTRL with missed failed unit option = None + pathway unit listing (will return groups of different sizes and only shows groups related to the pathway and does not consider failed units)
     */
    @isTest  
    static void testForFacultyWtihMissedFailedUnitOptionAllAndPathwayUnitListingMode() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name, reduivy__Contact__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c]) {
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

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_FACULTY, IPW_Helper.UNIT_LISTING_MODE_PATHWAY, null, 'None');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));

                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                if(idvPathway.reduivy__Term_Number__c == 1) {
                    System.Assert.areEqual(3, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 2) {
                    System.Assert.areEqual(2, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 3) {
                    System.Assert.areEqual(2, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 4) {
                    System.Assert.areEqual(0, groupIpsWrapperResponse.size());
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student user for REDU_IpePathwayTermListing_LCTRL with missed failed unit option = none + all unit listing (expected: always return 3 top grp no matter in which term)
     */
    @isTest  
    static void testForStudentWtihMissedFailedUnitOptionNoneAndAllUnitListingMode() {        
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Pathway__c ipwInCurrentStatus = [SELECT Id, reduivy__Individual_Program_Enrollment__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Status__c = :IPW_Helper.STATUS_CURRENT LIMIT 1];
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name, reduivy__Contact__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() AND Id = :ipwInCurrentStatus.reduivy__Individual_Program_Enrollment__c LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c]) {
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

        Id ipsGroupRtId = IPS_Helper.getGroupRecordTypeId();

        String groupIpsSoql = 'SELECT Id, Name, reduivy__Hidden__c ' +
            ' FROM reduivy__Individual_Plan_Structure__c ' + 
            ' WHERE RecordTypeId =: ipsGroupRtId ' +
            ' AND reduivy__Parent_Plan_Structure__c = NULL ' + 
            ' AND reduivy__Individual_Program_Enrollment__c =: individualPeId ' +
            ' ORDER BY reduivy__Sequence_Key__c NULLS LAST';

        Map<String, Object> ipsBindParams = new Map<String, Object>{
            'ipsGroupRtId' => ipsGroupRtId,
            'individualPeId' => masterIPE.Id
        };

        List<REDU_IndividualPlanStructure_OBJ> groupIpsWrapper = new List<REDU_IndividualPlanStructure_OBJ>();

        for (reduivy__Individual_Plan_Structure__c ips : (List<reduivy__Individual_Plan_Structure__c>)Database.queryWithBinds(groupIpsSoql, ipsBindParams, AccessLevel.USER_MODE)) {
            REDU_IndividualPlanStructure_OBJ groupIps = new REDU_IndividualPlanStructure_OBJ();
            groupIps.id = ips.Id;
            groupIps.ips = ips;

            groupIpsWrapper.add(groupIps);
        }

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId = :masterIpe.reduivy__Contact__c 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        System.runAs(reduStudent){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_STUDENT, null, null, 'None');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));

                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));

                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                System.Assert.areEqual(groupIpsWrapper.size(), groupIpsWrapperResponse.size());
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student user for REDU_IpePathwayTermListing_LCTRL with missed failed unit option = None + pathway unit listing (will return groups of different sizes and only shows groups related to the pathway and does not consider failed units)
     */
    @isTest  
    static void testForStudentWtihMissedFailedUnitOptionAllAndPathwayUnitListingMode() {       
        String ipsUnitFieldString = 'Name;reduivy__Individual_Enrollment__r.reduivy__Study_Offering__r.reduivy__Study_Unit__c;reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Attempted__c;reduivy__Individual_Enrollment__r.reduivy__Credits_Earned__c;reduivy__Individual_Enrollment__r.reduivy__Grade_Result__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Study_Plan__r.Name, reduivy__Contact__c, reduivy__Study_Pathway__c, reduivy__Starting_Term__c, reduivy__Default_Campus__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Pathway__c> idvPathwayList = [SELECT Id, reduivy__Term_Number__c FROM reduivy__Individual_Pathway__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id];

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
        for(reduivy__Study_Pathway_Unit__c spu : [SELECT Id, reduivy__Study_Unit__c FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Pathway_Term__r.reduivy__Study_Pathway__c = :masterIpe.reduivy__Study_Pathway__c]) {
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

        User reduStudent = [SELECT Id 
            FROM User 
            WHERE ContactId = :masterIpe.reduivy__Contact__c 
            AND ProfileId =: REDU_AppSetting_UTIL.getStudentProfileId()
        ];

        System.runAs(reduStudent){
            Test.startTest();

            for(reduivy__Individual_Pathway__c idvPathway : idvPathwayList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermListing_LCTRL.getIndividualProgramEnrollment(masterIPE.Id, idvPathway.Id, USR_Helper.USER_MODE_STUDENT, IPW_Helper.UNIT_LISTING_MODE_PATHWAY, null, 'None');
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermListing_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(masterIPE.reduivy__Study_Plan__r.Name, responseData.get(REDU_IpePathwayTermListing_LCTRL.TITLE_PARAM));
                Map<String, Object> ipeRecord = (Map<String, Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.IPE_PARAM);
                System.Assert.areEqual(masterIPE.Id, (String)ipeRecord.get('Id'));

                List<Object> groupIpsWrapperResponse = (List<Object>)responseData.get(REDU_IpePathwayTermListing_LCTRL.TOPGROUPSIPS_PARAM);
                if(idvPathway.reduivy__Term_Number__c == 1) {
                    System.Assert.areEqual(3, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 2) {
                    System.Assert.areEqual(2, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 3) {
                    System.Assert.areEqual(2, groupIpsWrapperResponse.size());

                } else if (idvPathway.reduivy__Term_Number__c == 4) {
                    System.Assert.areEqual(0, groupIpsWrapperResponse.size());
                }
            }

            Test.stopTest();
        }
    }
}