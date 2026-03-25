/**
 * @author      WDCi (VTan)
 * @date        Nov 2023
 * @group       Requirement Met
 * @description Test class for REDU_StudyUnitRequirement_UTIL
 * @changehistory
 * ISS-001752 25-10-2023 VTan - new class
 * ISS-001979 12-07-2024 Sueanne - add test for pre-requisite enrollment with enrollment setting
 * ISS-002144 03-01-2025 XW - add tests for prereq (not bypassable)
 * ISS-002486 10-06-2025 XiRouh - updated getCompletedStatuses to getCompletedPassStatuses
 * ISS-002743 15-12-2025 XiRouh - Updated test methods that create IENs to link them with IPF
 */
@isTest
public inherited sharing class REDU_StudyUnitRequirement_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PLAN_STRUCTURE_GROUP = 'BACBIS_MajorA_GROUPA_1_1';
	static final String STUDY_PLAN_STRUCTURE_UNIT = 'BACBIS_MajorA_BUS101';
	static final String STUDY_UNIT = 'BUS101';

    static final String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static final String IEN_COMPLETED_PASS_STATUS = IEN_Helper.getCompletedPassStatuses().get(0);

    static final String IPE_INPROGRESS_STATUS = IPE_Helper.getInProgressStatuses().get(0);
    static final String SPL_MAJOR = 'BACBIS_MajorA';
    static final String SPL_MINOR = 'BACBIS_MinorA';
    static final String STUDY_INTAKE = 'SYDNEY_BACBIS_CYINTAKE';

    static final Integer STUDENT_QTY = 2;
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
            testFactory.initStudentData(IPF_Helper.getApiName(), true);

            List<reduivy__Individual_Program_Enrollment__c> masterIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
            List<reduivy__Individual_Program_Enrollment__c> childIpeList = new List<reduivy__Individual_Program_Enrollment__c>();

            Integer idx = 0;
            for (Contact student : testFactory.students.values()) {
                String masterIpekey = student.reduivy__Sample_Record_Code__c + '_' + SPL_MAJOR;
                String childIpekey = student.reduivy__Sample_Record_Code__c + '_' + SPL_MINOR;

                reduivy__Individual_Program_Enrollment__c newMasterIpe = REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                    masterIpekey, 
                    student.Id, 
                    testFactory.studyPlans.get(SPL_MAJOR).reduivy__Study_Program__c, 
                    testFactory.studyPlans.get(SPL_MAJOR).Id, 
                    testFactory.studyIntakes.get(STUDY_INTAKE).Id, 
                    testFactory.academicTerms.get('CYT1').Id, 
                    testFactory.studyIntakes.get(STUDY_INTAKE).reduivy__Default_Study_Pathway__c, 
                    testFactory.campuses.get('SYDNEY').Id, 
                    String.valueOf(testFactory.academicTerms.get('CYT1').reduivy__Start_Date__c.year()), 
                    'Freshman', 
                    true, 
                    IPE_INPROGRESS_STATUS, 
                    testFactory.individualAcademicProfiles.get(student.reduivy__Sample_Record_Code__c).Id
                );

                reduivy__Individual_Program_Enrollment__c newChildIpe = REDU_TestData_UTIL.newChildIndividualProgramEnrollment(
                    childIpekey, 
                    student.Id, 
                    testFactory.studyPlans.get(SPL_MINOR).reduivy__Study_Program__c, 
                    testFactory.studyPlans.get(SPL_MINOR).Id,
                    null, 
                    IPE_Helper.COMPLETION_REQUIREMENT_MANDATORY, 
                    true, 
                    IPE_INPROGRESS_STATUS
                );

                masterIpeList.add(newMasterIpe);
                childIpeList.add(newChildIpe);

                if (idx < STUDENT_QTY) {
                    idx ++;
                } else {
                    break;
                }
            }

            REDU_SystemMode_UTIL.doInsert(masterIpeList);

            Integer counter = 0;
            for (reduivy__Individual_Program_Enrollment__c childIpe : childIpeList) {
                childIpe.reduivy__Master_Enrollment__c = masterIpeList.get(counter).Id;
            }

            REDU_SystemMode_UTIL.doInsert(childIpeList);

            Test.stopTest();
        }

    }

    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testForAdminRequirementMet() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(ADMIN_USER){

            Test.startTest();

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_COMPLETED_PASS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testForAdminRequirementNotMet() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(ADMIN_USER){

            Test.startTest();

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term
     * ISS-002144 Allow Bypass
     */
    @isTest
    static void testForAdminTermEnrollmentSettingRequirementMetBypassable() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(ADMIN_USER){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term but same term
     * ISS-002144 Allow Bypass
     */
    @isTest
    static void testForAdminTermEnrollmentSettingRequirementNotMetBypassable() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(ADMIN_USER){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, sofMap.values().get(0).reduivy__Academic_Term__c);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    
    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term
     * ISS-002144 Not Allow Bypass
     */
    @isTest
    static void testForAdminTermEnrollmentSettingRequirementMetNotBypassable() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS203' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(ADMIN_USER){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled but not bypassable');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }
    
    
    /**
     * @description Test as admin for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term but same term
     * ISS-002144 Not Allow Bypass
     */
    @isTest
    static void testForAdminTermEnrollmentSettingRequirementNotMetNotBypassable() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS203' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(ADMIN_USER){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, sofMap.values().get(0).reduivy__Academic_Term__c);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled and not bypassable');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }


    /**
     * @description Test as faculty for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testForFacultyRequirementMet() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(FACULTY_USER){

            Test.startTest();

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_COMPLETED_PASS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testForFacultyRequirementNotMet() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(FACULTY_USER){

            Test.startTest();

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term
     * ISS-002144 Allow Bypass
     */
    @isTest
    static void testForFacultyTermEnrollmentSettingRequirementMetBypassable() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(FACULTY_USER){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term but same term
     * ISS-002144 Allow Bypass
     */
    @isTest
    static void testForFacultyTermEnrollmentSettingRequirementNotMetBypassable() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(FACULTY_USER){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, sofMap.values().get(0).reduivy__Academic_Term__c);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    
    /**
     * @description Test as faculty for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term
     * ISS-002144 Not Allow Bypass
     */
    @isTest
    static void testForFacultyTermEnrollmentSettingRequirementMetNotBypassable() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS203' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(FACULTY_USER){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled but is not bypassable');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    
    /**
     * @description Test as faculty for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term but same term
     * ISS-002144 Not Allow Bypass
     */
    @isTest
    static void testForFacultyTermEnrollmentSettingRequirementNotMetNotBypassable() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS203' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        System.runAs(FACULTY_USER){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, sofMap.values().get(0).reduivy__Academic_Term__c);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled and not bypassable');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }


    /**
     * @description Test as student for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testForStudentRequirementMet() {

        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
        
        User studentUser = [SELECT Id FROM User WHERE ContactId =: masterIPE.reduivy__Contact__c];

        System.runAs(studentUser){

            Test.startTest();

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_COMPLETED_PASS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_IpePathwayTermUnitTable_LCTRL
     */
    @isTest
    static void testForStudentRequirementNotMet() {

        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        User studentUser = [SELECT Id FROM User WHERE ContactId =: masterIPE.reduivy__Contact__c];

        System.runAs(studentUser){

            Test.startTest();

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term
     * ISS-002144 Allow Bypass
     */
    @isTest
    static void testForStudentTermEnrollmentSettingRequirementMetBypassable() {

        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        User studentUser = [SELECT Id FROM User WHERE ContactId =: masterIPE.reduivy__Contact__c];

        System.runAs(studentUser){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term but same term
     * ISS-002144 Allow Bypass
     */
    @isTest
    static void testForStudentTermEnrollmentSettingRequirementNotMetBypassable() {

        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS201' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        User studentUser = [SELECT Id FROM User WHERE ContactId =: masterIPE.reduivy__Contact__c];

        System.runAs(studentUser){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, sofMap.values().get(0).reduivy__Academic_Term__c);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS201') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    
    /**
     * @description Test as student for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term
     * ISS-002144 Not Allow Bypass
     */
    @isTest
    static void testForStudentTermEnrollmentSettingRequirementMetNotBypassable() {

        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS203' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        User studentUser = [SELECT Id FROM User WHERE ContactId =: masterIPE.reduivy__Contact__c];

        System.runAs(studentUser){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled but is not bypassable');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }

    
    /**
     * @description Test as student for REDU_IpePathwayTermUnitTable_LCTRL with set enrollmentSetting = 'Allow Enrolled Pre-requisite Units' in academic term but same term
     * ISS-002144 Allow Bypass
     */
    @isTest
    static void testForStudentTermEnrollmentSettingRequirementNotMetNotBypassable() {

        // Query data for testing
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c, reduivy__Credits_Earned__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        Map<Id, reduivy__Study_Unit__c> sUnitMap = new Map<Id, reduivy__Study_Unit__c>([SELECT Id, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS203' OR reduivy__Sample_Record_Code__c = 'BUS101' ]);
        Map<Id, reduivy__Study_Plan_Structure__c> spsUnitMap = new Map<Id, reduivy__Study_Plan_Structure__c>([SELECT Id, Name, reduivy__Requirement_Logic__c, reduivy__Requirement_Description__c, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name FROM reduivy__Study_Plan_Structure__c WHERE reduivy__Study_Unit__c IN : sUnitMap.keySet() AND reduivy__Study_Plan__r.reduivy__Sample_Record_Code__c = 'BACBIS_MajorA']);
        Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>([SELECT Id,
            Name,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.Name,
            reduivy__Study_Unit__r.Name
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey
            AND reduivy__Study_Unit__r.reduivy__Sample_Record_Code__c = 'BUS101'
            AND reduivy__Campus__r.reduivy__Sample_Record_Code__c = 'SYDNEY'
        ]);
 
        User studentUser = [SELECT Id FROM User WHERE ContactId =: masterIPE.reduivy__Contact__c];

        System.runAs(studentUser){

            Test.startTest();

            Map<Id, List<reduivy__Individual_Plan_Structure__c>> unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>> spsRequirementMap = new Map<Id, List<reduivy__Study_Plan_Unit_Requirement__c>>();
            spsRequirementMap = REDU_StudyUnitRequirement_UTIL.getUnitSpsRequirements(spsUnitMap.values());

            System.Assert.areEqual(false, spsRequirementMap.isEmpty(), 'Missing requirements');

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, null, null);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should not met the requirement as BUS101 is not completed');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            reduivy__Individual_Enrollment__c bus101Ien = REDU_TestData_UTIL.newStudentIndividualEnrollment(
                masterIPE.reduivy__Contact__c + '_BUS101',
                masterIPE.reduivy__Contact__c,
                sofMap.values().get(0).Id,
                IEN_INPROGRESS_STATUS,
                1,
                System.today(),
                System.today(),
                System.today(),
                System.today(),
                5,
                null,
                null,
                false
            );

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Individual_Enrollment__c>{bus101Ien});

            //get the latest data after enrolling to BUS101
            unitIpsBySun = new Map<Id, List<reduivy__Individual_Plan_Structure__c>>();
            for(reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, reduivy__Status__c, reduivy__Study_Plan_Structure__c, reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, reduivy__Individual_Enrollment__c, reduivy__Individual_Enrollment__r.reduivy__Enrollment_Status__c, reduivy__Individual_Enrollment__r.reduivy__Academic_Term_Id__c FROM reduivy__Individual_Plan_Structure__c WHERE RecordTypeId = : IPS_Helper.getUnitRecordTypeId() AND reduivy__Individual_Program_Enrollment__c = : masterIPE.Id]){

                if(unitIpsBySun.containsKey(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c)){
                    unitIpsBySun.get(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c).add(ipsUnit);
                }else{
                    List<reduivy__Individual_Plan_Structure__c> ipsUnitList =  new List<reduivy__Individual_Plan_Structure__c>();
                    ipsUnitList.add(ipsUnit);
                    unitIpsBySun.put(ipsUnit.reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c, ipsUnitList);
                }
            }

            for(Id spsUnitId : spsUnitMap.keySet()){

                Boolean isRequirementMet = false;
                Map<String, String> requirementInfo = IPS_Helper.getRequirementInfo(spsUnitMap.get(spsUnitId), sUnitMap.get(spsUnitMap.get(spsUnitId).reduivy__Study_Unit__c), null);
                String requirementLogic = requirementInfo.get(IPS_Helper.REQINFO_LOGIC);

                //allow pre-req
                isRequirementMet = REDU_StudyUnitRequirement_UTIL.isRequirementMet(requirementLogic, masterIPE, spsRequirementMap.get(spsUnitId), unitIpsBySun, STM_Helper.UNIT_ENROLLMENT_ALLOW_PREREQUISITE, sofMap.values().get(0).reduivy__Academic_Term__c);
                
                if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS203') {
                    System.Assert.areEqual(false, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as BUS101 is enrolled and not bypassable');
                } else if (spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name == 'BUS101') {
                    System.Assert.areEqual(true, isRequirementMet, spsUnitMap.get(spsUnitId).reduivy__Study_Unit__r.Name + ' should met the requirement as it does not have requirement');
                } else {
                    System.Assert.fail('Unknown study unit ' + spsUnitMap.get(spsUnitId)?.reduivy__Study_Unit__r?.Name);
                }
            }

            Test.stopTest();
        }
    }



}