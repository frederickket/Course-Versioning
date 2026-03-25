/**
 * @author      WDCi (Jordan)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for REDU_IpePathwayTermGroup_LCTRL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_IpePathwayTermGroup_TEST {

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
     * @description Test as admin for REDU_IpePathwayTermGroup_LCTRL
     */
    @isTest
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String titleField = 'Name';
        String tableFields = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, Name, (SELECT Id, Name, RecordTypeId FROM reduivy__Individual_Plan_Structures__r WHERE RecordTypeId =: ispGroupRTID ORDER BY reduivy__Sequence_Key__c NULLS LAST) FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID];


        System.runAs(ADMIN_USER){
            Test.startTest();

            for(reduivy__Individual_Plan_Structure__c ipsGroup : ipsGroupList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermGroup_LCTRL.getIndividualPlanStructureGroup(masterIPE.Id, ipsGroup.Id, USR_Helper.USER_MODE_ADMIN, titleField, tableFields);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermGroup_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(ipsGroup.Name, responseData.get(REDU_IpePathwayTermGroup_LCTRL.TITLE_PARAM));
                Map<String, Object> currentGroupIps = (Map<String, Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.IPS_PARAM);
                System.Assert.areEqual(ipsGroup.Id, (String)currentGroupIps.get('Id'));

                List<reduivy__Individual_Plan_Structure__c> childGroupsIps = new List<reduivy__Individual_Plan_Structure__c>();
                for (reduivy__Individual_Plan_Structure__c childIps : ipsGroup.reduivy__Individual_Plan_Structures__r) {
                    childGroupsIps.add(childIps);
                }

                List<Object> childGroupsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.CHILDGROUPSIPS_PARAM);
                if (childGroupsIpsResponse == null) {
                    System.Assert.isTrue(childGroupsIps.isEmpty());
                } else {
                    System.Assert.areEqual(childGroupsIps.size(), childGroupsIpsResponse.size());
                }
            }

            Test.stopTest();
        }

    }

    /**
     * @description Test hidden records with user mode = student as admin for REDU_IpePathwayTermGroup_LCTRL
     */
    @isTest
    static void testHiddenWithStudentModeForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String titleField = 'Name';
        String tableFields = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> topIpsGroupList = [SELECT Id, 
            Name,
            reduivy__Hide_in_Enrollment__c,
            (SELECT Id FROM reduivy__Individual_Plan_Structures__r WHERE RecordTypeId =: ispGroupRTID)
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Parent_Plan_Structure__c = NULL
        ];
        
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            Name,
            reduivy__Hide_in_Enrollment__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Parent_Plan_Structure__c <> NULL
        ];

        for (reduivy__Individual_Plan_Structure__c ips : ipsGroupList) {
            ips.reduivy__Hide_in_Enrollment__c = true;
        }

        update ipsGroupList;

        System.runAs(ADMIN_USER){
            Test.startTest();

            for(reduivy__Individual_Plan_Structure__c ipsGroup : topIpsGroupList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermGroup_LCTRL.getIndividualPlanStructureGroup(masterIPE.Id, ipsGroup.Id, USR_Helper.USER_MODE_STUDENT, titleField, tableFields);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermGroup_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(ipsGroup.Name, responseData.get(REDU_IpePathwayTermGroup_LCTRL.TITLE_PARAM));
                Map<String, Object> currentGroupIps = (Map<String, Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.IPS_PARAM);
                System.Assert.areEqual(ipsGroup.Id, (String)currentGroupIps.get('Id'));

                List<Object> childGroupsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.CHILDGROUPSIPS_PARAM);

                // ips group with child and without child should return empty list
                if (ipsGroup.reduivy__Individual_Plan_Structures__r.isEmpty()) {
                    System.Assert.isTrue(childGroupsIpsResponse == null, 'This should be null');
                } else {
                    System.Assert.isTrue(childGroupsIpsResponse == null, 'This should be null');
                }
            }

            Test.stopTest();
        }

    }

    /**
     * @description Test hidden with user mode = admin as admin for REDU_IpePathwayTermGroup_LCTRL
     */
    @isTest
    static void testHiddenWithAdminModeForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String titleField = 'Name';
        String tableFields = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> topIpsGroupList = [SELECT Id, 
            Name,
            reduivy__Hide_in_Enrollment__c,
            (SELECT Id FROM reduivy__Individual_Plan_Structures__r WHERE RecordTypeId =: ispGroupRTID)
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Parent_Plan_Structure__c = NULL
        ];
        
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            Name,
            reduivy__Hide_in_Enrollment__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Parent_Plan_Structure__c <> NULL
        ];

        for (reduivy__Individual_Plan_Structure__c ips : ipsGroupList) {
            ips.reduivy__Hide_in_Enrollment__c = true;
        }

        update ipsGroupList;

        System.runAs(ADMIN_USER){
            Test.startTest();

            for(reduivy__Individual_Plan_Structure__c ipsGroup : topIpsGroupList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermGroup_LCTRL.getIndividualPlanStructureGroup(masterIPE.Id, ipsGroup.Id, USR_Helper.USER_MODE_ADMIN, titleField, tableFields);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermGroup_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(ipsGroup.Name, responseData.get(REDU_IpePathwayTermGroup_LCTRL.TITLE_PARAM));
                Map<String, Object> currentGroupIps = (Map<String, Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.IPS_PARAM);
                System.Assert.areEqual(ipsGroup.Id, (String)currentGroupIps.get('Id'));

                List<Object> childGroupsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.CHILDGROUPSIPS_PARAM);

                // ips group with child should return child ips list
                if (ipsGroup.reduivy__Individual_Plan_Structures__r.isEmpty()) {
                    System.Assert.isTrue(childGroupsIpsResponse == null, 'This should be null');
                } else {
                    System.Assert.isTrue(childGroupsIpsResponse != null, 'This should not be null');
                    System.Assert.isTrue(!childGroupsIpsResponse.isEmpty(), 'This should not be empty');
                }
            }

            Test.stopTest();
        }

    }

    /**
     * @description Test as student user for REDU_IpePathwayTermGroup_LCTRL
     */
    @isTest   
    static void testForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String titleField = 'Name';
        String tableFields = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c';
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, Name, (SELECT Id, Name, RecordTypeId FROM reduivy__Individual_Plan_Structures__r WHERE RecordTypeId =: ispGroupRTID ORDER BY reduivy__Sequence_Key__c NULLS LAST) FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID];

        System.runAs(studentUser){
            Test.startTest();

            for(reduivy__Individual_Plan_Structure__c ipsGroup : ipsGroupList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermGroup_LCTRL.getIndividualPlanStructureGroup(masterIPE.Id, ipsGroup.Id, USR_Helper.USER_MODE_STUDENT, titleField, tableFields);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermGroup_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(ipsGroup.Name, responseData.get(REDU_IpePathwayTermGroup_LCTRL.TITLE_PARAM));
                Map<String, Object> currentGroupIps = (Map<String, Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.IPS_PARAM);
                System.Assert.areEqual(ipsGroup.Id, (String)currentGroupIps.get('Id'));

                List<reduivy__Individual_Plan_Structure__c> childGroupsIps = new List<reduivy__Individual_Plan_Structure__c>();
                for (reduivy__Individual_Plan_Structure__c childIps : ipsGroup.reduivy__Individual_Plan_Structures__r) {
                    childGroupsIps.add(childIps);
                }

                List<Object> childGroupsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.CHILDGROUPSIPS_PARAM);
                if (childGroupsIpsResponse == null) {
                    System.Assert.isTrue(childGroupsIps.isEmpty());
                } else {
                    System.Assert.areEqual(childGroupsIps.size(), childGroupsIpsResponse.size());
                }
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as student user for REDU_IpePathwayTermGroup_LCTRL
     */
    @isTest   
    static void testHiddenWithStudentModeForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String titleField = 'Name';
        String tableFields = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c';
        
        List<reduivy__Individual_Plan_Structure__c> topIpsGroupList = [SELECT Id, 
            Name,
            reduivy__Hide_in_Enrollment__c,
            (SELECT Id FROM reduivy__Individual_Plan_Structures__r WHERE RecordTypeId =: ispGroupRTID)
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Parent_Plan_Structure__c = NULL
        ];
        
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            Name,
            reduivy__Hide_in_Enrollment__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Parent_Plan_Structure__c <> NULL
        ];

        for (reduivy__Individual_Plan_Structure__c ips : ipsGroupList) {
            ips.reduivy__Hide_in_Enrollment__c = true;
        }

        update ipsGroupList;

        System.runAs(studentUser){
            Test.startTest();

            for(reduivy__Individual_Plan_Structure__c ipsGroup : topIpsGroupList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermGroup_LCTRL.getIndividualPlanStructureGroup(masterIPE.Id, ipsGroup.Id, USR_Helper.USER_MODE_STUDENT, titleField, tableFields);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermGroup_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(ipsGroup.Name, responseData.get(REDU_IpePathwayTermGroup_LCTRL.TITLE_PARAM));
                Map<String, Object> currentGroupIps = (Map<String, Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.IPS_PARAM);
                System.Assert.areEqual(ipsGroup.Id, (String)currentGroupIps.get('Id'));

                List<Object> childGroupsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.CHILDGROUPSIPS_PARAM);

                // ips group with child and without child should return empty list
                if (ipsGroup.reduivy__Individual_Plan_Structures__r.isEmpty()) {
                    System.Assert.isTrue(childGroupsIpsResponse == null, 'This should be null');
                } else {
                    System.Assert.isTrue(childGroupsIpsResponse == null, 'This should be null');
                }
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty user for REDU_IpePathwayTermGroup_LCTRL
     */
    @isTest   
    static void testForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String titleField = 'Name';
        String tableFields = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c';
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, Name, (SELECT Id, Name, RecordTypeId FROM reduivy__Individual_Plan_Structures__r WHERE RecordTypeId =: ispGroupRTID ORDER BY reduivy__Sequence_Key__c NULLS LAST) FROM reduivy__Individual_Plan_Structure__c WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id AND RecordTypeId = : ispGroupRTID];

        System.runAs(FACULTY_USER){

            Test.startTest();

            for(reduivy__Individual_Plan_Structure__c ipsGroup : ipsGroupList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermGroup_LCTRL.getIndividualPlanStructureGroup(masterIPE.Id, ipsGroup.Id, USR_Helper.USER_MODE_STUDENT, titleField, tableFields);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermGroup_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(ipsGroup.Name, responseData.get(REDU_IpePathwayTermGroup_LCTRL.TITLE_PARAM));
                Map<String, Object> currentGroupIps = (Map<String, Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.IPS_PARAM);
                System.Assert.areEqual(ipsGroup.Id, (String)currentGroupIps.get('Id'));

                List<reduivy__Individual_Plan_Structure__c> childGroupsIps = new List<reduivy__Individual_Plan_Structure__c>();
                for (reduivy__Individual_Plan_Structure__c childIps : ipsGroup.reduivy__Individual_Plan_Structures__r) {
                    childGroupsIps.add(childIps);
                }

                List<Object> childGroupsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.CHILDGROUPSIPS_PARAM);
                if (childGroupsIpsResponse == null) {
                    System.Assert.isTrue(childGroupsIps.isEmpty());
                } else {
                    System.Assert.areEqual(childGroupsIps.size(), childGroupsIpsResponse.size());
                }
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test hidden records with user mode = student as faculty for REDU_IpePathwayTermGroup_LCTRL
     */
    @isTest
    static void testHiddenWithStudentModeForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String titleField = 'Name';
        String tableFields = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> topIpsGroupList = [SELECT Id, 
            Name,
            reduivy__Hide_in_Enrollment__c,
            (SELECT Id FROM reduivy__Individual_Plan_Structures__r WHERE RecordTypeId =: ispGroupRTID)
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Parent_Plan_Structure__c = NULL
        ];
        
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            Name,
            reduivy__Hide_in_Enrollment__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Parent_Plan_Structure__c <> NULL
        ];

        for (reduivy__Individual_Plan_Structure__c ips : ipsGroupList) {
            ips.reduivy__Hide_in_Enrollment__c = true;
        }

        update ipsGroupList;

        System.runAs(FACULTY_USER){
            Test.startTest();

            for(reduivy__Individual_Plan_Structure__c ipsGroup : topIpsGroupList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermGroup_LCTRL.getIndividualPlanStructureGroup(masterIPE.Id, ipsGroup.Id, USR_Helper.USER_MODE_STUDENT, titleField, tableFields);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermGroup_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(ipsGroup.Name, responseData.get(REDU_IpePathwayTermGroup_LCTRL.TITLE_PARAM));
                Map<String, Object> currentGroupIps = (Map<String, Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.IPS_PARAM);
                System.Assert.areEqual(ipsGroup.Id, (String)currentGroupIps.get('Id'));

                List<Object> childGroupsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.CHILDGROUPSIPS_PARAM);

                // ips group with child and without child should return empty list
                if (ipsGroup.reduivy__Individual_Plan_Structures__r.isEmpty()) {
                    System.Assert.isTrue(childGroupsIpsResponse == null, 'This should be null');
                } else {
                    System.Assert.isTrue(childGroupsIpsResponse == null, 'This should be null');
                }
            }

            Test.stopTest();
        }

    }

    /**
     * @description Test hidden with user mode = admin as faculty for REDU_IpePathwayTermGroup_LCTRL
     */
    @isTest
    static void testHiddenWithAdminModeForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        String titleField = 'Name';
        String tableFields = 'reduivy__Study_Unit__c.Name;reduivy__Study_Unit__c.reduivy__Unit_Code__c';
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        List<reduivy__Individual_Plan_Structure__c> topIpsGroupList = [SELECT Id, 
            Name,
            reduivy__Hide_in_Enrollment__c,
            (SELECT Id FROM reduivy__Individual_Plan_Structures__r WHERE RecordTypeId =: ispGroupRTID)
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Parent_Plan_Structure__c = NULL
        ];
        
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = [SELECT Id, 
            Name,
            reduivy__Hide_in_Enrollment__c 
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__c = :masterIPE.Id 
            AND RecordTypeId = : ispGroupRTID 
            AND reduivy__Parent_Plan_Structure__c <> NULL
        ];

        for (reduivy__Individual_Plan_Structure__c ips : ipsGroupList) {
            ips.reduivy__Hide_in_Enrollment__c = true;
        }

        update ipsGroupList;

        System.runAs(FACULTY_USER){
            Test.startTest();

            for(reduivy__Individual_Plan_Structure__c ipsGroup : topIpsGroupList){

                REDU_LightningResponse objResponse = REDU_IpePathwayTermGroup_LCTRL.getIndividualPlanStructureGroup(masterIPE.Id, ipsGroup.Id, USR_Helper.USER_MODE_ADMIN, titleField, tableFields);
                System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermGroup_TEST');

                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(objResponse.responseData);
                System.Assert.areEqual(ipsGroup.Name, responseData.get(REDU_IpePathwayTermGroup_LCTRL.TITLE_PARAM));
                Map<String, Object> currentGroupIps = (Map<String, Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.IPS_PARAM);
                System.Assert.areEqual(ipsGroup.Id, (String)currentGroupIps.get('Id'));

                List<Object> childGroupsIpsResponse = (List<Object>)responseData.get(REDU_IpePathwayTermGroup_LCTRL.CHILDGROUPSIPS_PARAM);

                // ips group with child should return child ips list
                if (ipsGroup.reduivy__Individual_Plan_Structures__r.isEmpty()) {
                    System.Assert.isTrue(childGroupsIpsResponse == null, 'This should be null');
                } else {
                    System.Assert.isTrue(childGroupsIpsResponse != null, 'This should not be null');
                    System.Assert.isTrue(!childGroupsIpsResponse.isEmpty(), 'This should not be empty');
                }
            }

            Test.stopTest();
        }

    }

}