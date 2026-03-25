/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for IPS_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class IPS_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String STUDY_PROGRAM = 'BACBIS';
	static final String STUDY_PLAN = 'BACBIS_MajorA';
    
    static final List<String> IPE_INPROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();
    
	@TestSetup
    static void makeData(){
        // Create settings
		testFactory.setupDefaultSettings();
        
        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SPS_Helper.getApiName());
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
				String enrollmentStatus = IPE_INPROGRESS_STATUSES.get(0);
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

            Test.stopTest();
        }
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Plan_Structure__c.getLabel(), IPS_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Plan_Structure__c.getLabelPlural(), IPS_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Plan_Structure__c.getName(), IPS_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description Test record type id method
     */
    @IsTest
    static void testGetRecordTypes(){
        
        Test.startTest();
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.reduivy__Individual_Plan_Structure__c.getRecordtypeInfosByDeveloperName();

        System.Assert.areEqual(rtMap.get('Group').getRecordTypeId(), IPS_Helper.getGroupRecordTypeId());
        System.Assert.areEqual(rtMap.get('Group').getName(), IPS_Helper.getGroupRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('Unit').getRecordTypeId(), IPS_Helper.getUnitRecordTypeId());
        System.Assert.areEqual(rtMap.get('Unit').getName(), IPS_Helper.getUnitRecordTypeLabel());

        Test.stopTest();
        
    }

    /**
     * @description Test get status configs metadata sorted according to Status field for Group record type
     */
    @IsTest
    static void testGetGroupStatusConfig(){
        
        Test.startTest();
        List<String> statuses = new List<String>{'Completed', 'In Progress', 'Not Started'};
        List<reduivy__IdvPs_Status_Config__mdt> configs = IPS_Helper.getGroupStatusConfig();

        System.Assert.areEqual(false, configs.isEmpty());
        System.Assert.areEqual(true, statuses.contains(configs[0].reduivy__Status__c));

        Test.stopTest();
        
    }

    /**
     * @description Test get status configs metadata sorted according to Status field for Unit record type
     */
    @IsTest
    static void testGetUnitStatusConfig(){
        
        Test.startTest();
        List<String> statuses = new List<String>{'Completed', 'In Progress', 'Not Started','Failed','Dropped','Withdrawn'};
        List<reduivy__IdvPs_Status_Config__mdt> configs = IPS_Helper.getUnitStatusConfig();

        System.Assert.areEqual(false, configs.isEmpty());
        System.Assert.areEqual(true, statuses.contains(configs[0].reduivy__Status__c));

        Test.stopTest();
        
    }

    /**
     * @description Test get unit not started statuses
     */
    @IsTest
    static void testGetUnitNotStartedStatuses(){
        
        Test.startTest();
        List<String> statuses = IPS_Helper.getUnitNotStartedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Not Started'));

        Test.stopTest();
        
    }

    /**
     * @description Test get unit in progress statuses
     */
    @IsTest
    static void testGetUnitInProgressStatuses(){
        
        Test.startTest();
        List<String> statuses = IPS_Helper.getUnitInProgressStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('In Progress'));

        Test.stopTest();
        
    }

    /**
     * @description Test get unit completed statuses
     */
    @IsTest
    static void unitCompletedStatuses(){
        
        Test.startTest();
        List<String> statuses = IPS_Helper.getUnitCompletedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Completed'));

        Test.stopTest();
        
    }

    /**
     * @description Test get unit failed statuses
     */
    @IsTest
    static void unitFailedStatuses(){
        
        Test.startTest();
        List<String> statuses = IPS_Helper.getUnitFailedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Failed'));

        Test.stopTest();
        
    }

    /**
     * @description Test get unit withdrawn statuses
     */
    @IsTest
    static void unitWithdrawnStatuses(){
        
        Test.startTest();
        List<String> statuses = IPS_Helper.getUnitWithdrawnStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Withdrawn'));

        Test.stopTest();
        
    }

    /**
     * @description Test get unit dropped statuses
     */
    @IsTest
    static void unitDroppedStatuses(){
        
        Test.startTest();
        List<String> statuses = IPS_Helper.getUnitDroppedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Dropped'));

        Test.stopTest();
        
    }

    /**
     * @description Test get unit non enrollable statuses
     */
    @IsTest
    static void unitNonEnrollableStatuses(){
        
        Test.startTest();
        List<String> statuses = IPS_Helper.getUnitNonEnrollableStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('In Progress'));
        System.Assert.areEqual(true, statuses.contains('Completed'));

        Test.stopTest();
        
    }

    /**
     * @description Test init new unit individual plan structure based on unit study plan structure
     */
    @IsTest
    static void initUnitIPS(){

        Id masterIPERecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId();
        Id ipsGroupRTID = IPS_Helper.getGroupRecordTypeId();
        Id spsUnitRTID = SPS_Helper.getUnitRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroup = [SELECT Id, reduivy__Individual_Program_Enrollment__c, reduivy__Sample_Record_Code__c
                                                    FROM reduivy__Individual_Plan_Structure__c 
                                                    WHERE reduivy__Individual_Program_Enrollment__r.RecordtypeId =: masterIPERecordTypeId AND RecordTypeId =: ipsGroupRTID LIMIT 1];

        List<reduivy__Study_Plan_Structure__c> spsUnit = [SELECT Id, reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c, reduivy__Description__c 
                                                            FROM reduivy__Study_Plan_Structure__c 
                                                            WHERE RecordTypeId =: spsUnitRTID AND reduivy__Category__c =: SPS_Helper.CATEGORY_REQUIRED LIMIT 1];
        
        System.Assert.areEqual(false, ipsGroup.isEmpty(), 'Missing individual plan structure group records.');
        System.Assert.areEqual(false, spsUnit.isEmpty(), 'Missing study plan structure unit records.');

        Test.startTest();
        
        reduivy__Individual_Plan_Structure__c ipsUnit = IPS_Helper.initUnitPlanStructure(ipsGroup[0].reduivy__Individual_Program_Enrollment__c, ipsGroup[0].Id, null, spsUnit[0]);

        Test.stopTest();

        System.Assert.areEqual(ipsUnit.reduivy__Category__c, SPS_Helper.CATEGORY_REQUIRED, 'Incorrect value for individual plan structure unit record.');
    }

    /**
     * @description Test get target unit id for new initiated unit ips. If null, will return either the reduivy__Alternate_Study_Unit__c or reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__c
     */
    @IsTest
    static void getTargetUnitID(){

        Id masterIPERecordTypeId = IPE_Helper.getMasterEnrollmentRecordTypeId();
        Id ipsGroupRTID = IPS_Helper.getGroupRecordTypeId();
        Id spsUnitRTID = SPS_Helper.getUnitRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroup = [SELECT Id, reduivy__Individual_Program_Enrollment__c, reduivy__Sample_Record_Code__c
                                                    FROM reduivy__Individual_Plan_Structure__c 
                                                    WHERE reduivy__Individual_Program_Enrollment__r.RecordtypeId =: masterIPERecordTypeId AND RecordTypeId =: ipsGroupRTID LIMIT 1];

        List<reduivy__Study_Plan_Structure__c> spsUnit = [SELECT Id, reduivy__Allow_Pre_Enrollment__c, reduivy__Category__c, reduivy__Credits__c, reduivy__Hide_in_Enrollment__c, reduivy__Sequence__c, reduivy__Study_Unit__c, reduivy__Description__c
                                                            FROM reduivy__Study_Plan_Structure__c 
                                                            WHERE RecordTypeId =: spsUnitRTID AND reduivy__Category__c =: SPS_Helper.CATEGORY_REQUIRED LIMIT 1];
        
        System.Assert.areEqual(false, ipsGroup.isEmpty(), 'Missing individual plan structure group records.');
        System.Assert.areEqual(false, spsUnit.isEmpty(), 'Missing study plan structure unit records.');

        Test.startTest();
        
        reduivy__Individual_Plan_Structure__c ipsUnit = IPS_Helper.initUnitPlanStructure(ipsGroup[0].reduivy__Individual_Program_Enrollment__c, ipsGroup[0].Id, null, spsUnit[0]);

        Id targetUnitId = IPS_Helper.getTargetUnitId(ipsUnit, spsUnit[0]);

        Test.stopTest();

        System.Assert.areEqual(false, String.isBlank(targetUnitId), 'Incorrect valid target unit Id.');
    }
	
}