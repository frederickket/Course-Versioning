/**
 * @author      WDCi (Sueanne)
 * @date        Apr 2024
 * @group       Test
 * @description Test class for REDU_StudyPathwayTerm_LCTRL
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_StudyPathwayTerm_TEST {
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

            testFactory.initMasterData(SPU_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }


    /**
     * @description Test as admin for REDU_StudyPathwayTerm_LCTRL.getStudyPathwayTerm()
     */
    @isTest
    static void testGetStudyPathwayTermForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Pathway_Term__c studyPwTerm = [SELECT Id FROM reduivy__Study_Pathway_Term__c LIMIT 1];

        reduivy__Study_Pathway_Term__c spt = [
            SELECT Id, Name, reduivy__Study_Pathway__c, reduivy__Term_Number__c, reduivy__Recommended_Credits__c
            FROM reduivy__Study_Pathway_Term__c 
            WHERE Id = :studyPwTerm.Id
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_StudyPathwayTerm_LCTRL.getStudyPathwayTerm(studyPwTerm.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_StudyPathwayTerm_TEST');

            reduivy__Study_Pathway_Term__c studyPwTermResponse = (reduivy__Study_Pathway_Term__c) JSON.deserialize(objResponse.responseData, reduivy__Study_Pathway_Term__c.class);

            // Round the values for comparison
            spt.reduivy__Term_Number__c = Math.round(spt.reduivy__Term_Number__c);
            spt.reduivy__Recommended_Credits__c = Math.round(spt.reduivy__Recommended_Credits__c);
            studyPwTermResponse.reduivy__Term_Number__c = Math.round(studyPwTermResponse.reduivy__Term_Number__c);
            studyPwTermResponse.reduivy__Recommended_Credits__c = Math.round(studyPwTermResponse.reduivy__Recommended_Credits__c);

            System.Assert.areEqual(spt, studyPwTermResponse);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_StudyPathwayTerm_LCTRL.getStudyPathwayUnits()
     */
    @isTest
    static void testGetStudyPathwayUnitsForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //get for test
        reduivy__Study_Pathway_Term__c studyPwTerm = [SELECT Id, reduivy__Study_Pathway__r.reduivy__Study_Plan__c FROM reduivy__Study_Pathway_Term__c LIMIT 1];
        List<Id> selectedSpoSpIds = new List<Id>();
        if(studyPwTerm != null){
            for(reduivy__Study_Plan_Option__c spo : [
                SELECT Id, reduivy__Master_Study_Plan__c 
                FROM reduivy__Study_Plan_Option__c 
                WHERE reduivy__Master_Study_Plan__c = :studyPwTerm.reduivy__Study_Pathway__r.reduivy__Study_Plan__c
            ]){
                selectedSpoSpIds.add(spo.reduivy__Master_Study_Plan__c);
            }
        }

        //to add new spu group & unit with applicable study plan
        List<reduivy__Study_Pathway_Unit__c> toAddSpu = new List<reduivy__Study_Pathway_Unit__c>();

        //spu unit
        reduivy__Study_Unit__c su = [
            SELECT Id FROM reduivy__Study_Unit__c 
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        toAddSpu.add(REDU_TestData_UTIL.newUnitStudyPathwayUnit('test spu unit', studyPwTerm.Id, su.Id, selectedSpoSpIds[0]));

        //delete existing spu 
        reduivy__Study_Pathway_Unit__c suInSpu = [SELECT Id FROM reduivy__Study_Pathway_Unit__c WHERE reduivy__Study_Unit__c = :su.Id WITH SYSTEM_MODE];
        if(suInSpu != null){
            List<reduivy__Study_Pathway_Unit__c> deleteSpuList = new List<reduivy__Study_Pathway_Unit__c>{suInSpu};
            REDU_SystemMode_UTIL.doDelete(deleteSpuList);
        }
        
        //spu group
        reduivy__Study_Plan_Structure__c sps = [
            SELECT Id FROM reduivy__Study_Plan_Structure__c 
            WHERE reduivy__Sample_Record_Code__c != null 
            AND reduivy__Study_Unit__c = null
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        toAddSpu.add(REDU_TestData_UTIL.newGroupStudyPathwayUnit('test spu group', studyPwTerm.Id, sps.Id, 2, selectedSpoSpIds[0])); 

        //doInsert
        REDU_SystemMode_UTIL.doInsert(toAddSpu);


        //expected return query
        List<reduivy__Study_Pathway_Unit__c> studyPwUnitList = new List<reduivy__Study_Pathway_Unit__c>();
        List<reduivy__Study_Pathway_Unit__c> spuList = [
            SELECT reduivy__Study_Unit__r.Name, 
            reduivy__Study_Plan_Group__r.Name, 
            reduivy__Applicable_Study_Plan__r.Name,
            reduivy__Applicable_Study_Plan__c, 
            Id, 
            reduivy__Study_Unit__c
            FROM reduivy__Study_Pathway_Unit__c
            WHERE reduivy__Study_Pathway_Term__c = :studyPwTerm.Id
            WITH USER_MODE
        ];

        Set<Id> studyUnitIdSet = new Set<Id>();
        for(reduivy__Study_Pathway_Unit__c spu : spuList){ 
            if(spu.reduivy__Applicable_Study_Plan__c == null){ 
                studyPwUnitList.add(spu);

                if(spu.reduivy__Study_Unit__c != null){
                    studyUnitIdSet.add(spu.reduivy__Study_Unit__c);
                }
            }
        }

        if(selectedSpoSpIds.size() > 0){
            for(reduivy__Study_Pathway_Unit__c spu: spuList){
                for(Id spoId: selectedSpoSpIds){
                    if(spu.reduivy__Study_Unit__c == null && spu.reduivy__Applicable_Study_Plan__c == spoId){
                        studyPwUnitList.add(spu);
                    }
                    
                    if(spu.reduivy__Study_Unit__c != null && spu.reduivy__Applicable_Study_Plan__c == spoId && !studyUnitIdSet.contains(spu.reduivy__Study_Unit__c)){
                        studyPwUnitList.add(spu);
                        studyUnitIdSet.add(spu.reduivy__Study_Unit__c);
                    }
                }
            }
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_StudyPathwayTerm_LCTRL.getStudyPathwayUnits(studyPwTerm.Id, selectedSpoSpIds);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_StudyPathwayTerm_TEST');

            List<reduivy__Study_Pathway_Unit__c> studyPwUnitListResponse = (List<reduivy__Study_Pathway_Unit__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Pathway_Unit__c>.class);
            
            // Convert both lists to sets for comparison
            Set<reduivy__Study_Pathway_Unit__c> spuSet = new Set<reduivy__Study_Pathway_Unit__c>(studyPwUnitList);
            Set<reduivy__Study_Pathway_Unit__c> studyPwUnitSetResponse = new Set<reduivy__Study_Pathway_Unit__c>(studyPwUnitListResponse);
            
            System.assertEquals(spuSet, studyPwUnitSetResponse, 'Lists do not match');
            
            Test.stopTest();
        }
    }


    /**
     * @description Test as student for REDU_StudyPathwayTerm_LCTRL.getStudyPathwayTerm()
     */
    @isTest
    static void testGetStudyPathwayTermForStudent() {
        //get a student for test & assign permission set
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

        REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(studentUser.Id, new Set<String>{'REDU_Guest'}));

        //get for test
        reduivy__Study_Pathway_Term__c studyPwTerm = [SELECT Id FROM reduivy__Study_Pathway_Term__c LIMIT 1];

        //expected return query
        reduivy__Study_Pathway_Term__c spt = [
            SELECT Id, Name, reduivy__Study_Pathway__c, reduivy__Term_Number__c, reduivy__Recommended_Credits__c
            FROM reduivy__Study_Pathway_Term__c 
            WHERE Id = :studyPwTerm.Id
            WITH USER_MODE
            LIMIT 1
        ];

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_StudyPathwayTerm_LCTRL.getStudyPathwayTerm(studyPwTerm.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_StudyPathwayTerm_TEST');

            reduivy__Study_Pathway_Term__c studyPwTermResponse = (reduivy__Study_Pathway_Term__c) JSON.deserialize(objResponse.responseData, reduivy__Study_Pathway_Term__c.class);

            // Round the values for comparison
            spt.reduivy__Term_Number__c = Math.round(spt.reduivy__Term_Number__c);
            spt.reduivy__Recommended_Credits__c = Math.round(spt.reduivy__Recommended_Credits__c);
            studyPwTermResponse.reduivy__Term_Number__c = Math.round(studyPwTermResponse.reduivy__Term_Number__c);
            studyPwTermResponse.reduivy__Recommended_Credits__c = Math.round(studyPwTermResponse.reduivy__Recommended_Credits__c);

            System.Assert.areEqual(spt, studyPwTermResponse);

            Test.stopTest();
        }
    }

        /**
     * @description Test as student for REDU_StudyPathwayTerm_LCTRL.getStudyPathwayUnits()
     */
    @isTest
    static void testGetStudyPathwayUnitsForStudent() {
        //get a student for test & assign permission set
        List<Contact> studentContacts = [SELECT Id, 
            reduivy__Sample_Record_Code__c 
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];

		User studentUser = [SELECT Id, 
            ContactId, 
            ProfileId 
            FROM User 
            WHERE ProfileId = : REDU_AppSetting_UTIL.getStudentProfileId()
            AND ContactId IN: studentContacts
            LIMIT 1
        ];

        REDU_SystemMode_UTIL.doInsert(REDU_TestData_UTIL.newPermissionSetAssignment(studentUser.Id, new Set<String>{'REDU_Guest'}));


        //get for test
        reduivy__Study_Pathway_Term__c studyPwTerm = [SELECT Id, reduivy__Study_Pathway__r.reduivy__Study_Plan__c FROM reduivy__Study_Pathway_Term__c LIMIT 1];
        List<Id> selectedSpoSpIds = new List<Id>();
        if(studyPwTerm != null){
            for(reduivy__Study_Plan_Option__c spo : [
                SELECT Id, reduivy__Master_Study_Plan__c 
                FROM reduivy__Study_Plan_Option__c 
                WHERE reduivy__Master_Study_Plan__c = :studyPwTerm.reduivy__Study_Pathway__r.reduivy__Study_Plan__c
            ]){
                selectedSpoSpIds.add(spo.reduivy__Master_Study_Plan__c);
            }
        }

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_StudyPathwayTerm_LCTRL.getStudyPathwayUnits(studyPwTerm.Id, selectedSpoSpIds);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_StudyPathwayTerm_TEST');
            
            Test.stopTest();
        }
    }    

    /**
     * @description Test as steup user for REDU_StudyPathwayTerm_LCTRL.getStudyPathwayTerm()
     */
    @isTest
    static void testGetStudyPathwayTermForSetupUser() {
        User setupUser = testFactory.getSetupUser();

        //get for test
        reduivy__Study_Pathway_Term__c studyPwTerm = [SELECT Id FROM reduivy__Study_Pathway_Term__c LIMIT 1];

        System.runAs(setupUser){
            Test.startTest();

            try{
                REDU_LightningResponse objResponse = REDU_StudyPathwayTerm_LCTRL.getStudyPathwayTerm(studyPwTerm.Id);
                Assert.fail('AuraHandledException should be thrown.');
            }catch(AuraHandledException exp){
                System.Assert.isTrue(exp.getMessage().contains('Insufficient READABLE access on following object(s) and field(s)'), 'The exception is invalid: ' + exp.getMessage());
            }
            
            Test.stopTest();
        }
    }

    /**
     * @description Test as setup user for REDU_StudyPathwayTerm_LCTRL.getStudyPathwayUnits()
     */
    @isTest
    static void testGetStudyPathwayUnitsForSetupUser() {
        User setupUser = testFactory.getSetupUser();

        //get for test
        reduivy__Study_Pathway_Term__c studyPwTerm = [SELECT Id, reduivy__Study_Pathway__r.reduivy__Study_Plan__c FROM reduivy__Study_Pathway_Term__c LIMIT 1];
        List<Id> selectedSpoIds = new List<Id>();
        if(studyPwTerm != null){
            for(reduivy__Study_Plan_Option__c spo : [
                SELECT Id, reduivy__Master_Study_Plan__c 
                FROM reduivy__Study_Plan_Option__c 
                WHERE reduivy__Master_Study_Plan__c = :studyPwTerm.reduivy__Study_Pathway__r.reduivy__Study_Plan__c
            ]){
                selectedSpoIds.add(spo.Id);
            }
        }

        System.runAs(setupUser){
            Test.startTest();
            
            try{
                REDU_LightningResponse objResponse = REDU_StudyPathwayTerm_LCTRL.getStudyPathwayUnits(studyPwTerm.Id, selectedSpoIds);
                Assert.fail('QueryException should be thrown.');
            }catch(Exception exp){
                System.Assert.isTrue(exp instanceof QueryException, 'Excepted return QueryException.');
            }
            
            Test.stopTest();
        }
    }
}