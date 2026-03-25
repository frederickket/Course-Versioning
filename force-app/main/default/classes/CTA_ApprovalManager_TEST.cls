/**
 * @author      WDCi (VTan)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for CTA_ApprovalManager_EXE
 * @changehistory
 * ISS-001659 VTan 30-01-2024 - New class
 * ISS-002136 16-10-2024 Lean - Fixed the credits contribution for IPS unit created via credit transfer application (type = manual)
 */
@IsTest
public inherited sharing class CTA_ApprovalManager_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String APPROVED_GRADE_CT = 'CT';
    static final String APPROVEUNITCODE_BUS101 = 'BUS101';

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
        System.runAs(ADMIN_USER) {

            Test.startTest();

            testFactory.initMasterData(SPS_Helper.getApiName());
			testFactory.initStudentData(CON_Helper.getApiName(), false);

            // Create sample agreement record
            Date agreementStartDate = System.today().addDays(-365);
            reduivy__Agreement__c agreement = REDU_TestData_UTIL.newAgreement('Agreement', null, testFactory.extEduInsts.get('EXTUNIT').Id, 'Agreement', agreementStartDate, agreementStartDate.addDays(90), AGR_Helper.STATUS_ACTIVE, AGR_Helper.TYPE_EXTERNAL);
            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Agreement__c>{agreement});

            // Create sample agreement unit equivalent record
            Set<String> originUnitCodes = new Set<String>{'ABC123'};
            Set<String> targetUnitCodes = new Set<String>{'BUS101'};
            reduivy__Agreement_Unit_Equivalent__c agreementUnitEquiv = REDU_TestData_UTIL.newAgreementUnitEquivalent('AgreementUnitEquiv', agreement.Id, 'Business, Management, and Marketing', originUnitCodes, targetUnitCodes, AUE_Helper.STATUS_ACTIVE, AUE_Helper.TYPE_ONETOONE);
            REDU_SystemMode_UTIL.doInsert(new List<reduivy__Agreement_Unit_Equivalent__c>{agreementUnitEquiv});

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
     * @description Test as admin to approve CTA with study unit
     */
    @isTest   
    static void testCtaToIenAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<String> approvedStatuses = CTA_Helper.getApprovedStatuses();
        List<String> rejectedStatuses = CTA_Helper.getRejectedStatuses();

        // Get credit transfer application to create individual enrollment
        List<reduivy__Credit_Transfer_Application__c> ctaList = [SELECT Id,
            reduivy__Contact__c,
            reduivy__Credits_Attempted__c,
            reduivy__Approved_Letter_Grade__c
            FROM reduivy__Credit_Transfer_Application__c LIMIT 5
        ];
        
        for (reduivy__Credit_Transfer_Application__c cta : ctaList) {
            cta.reduivy__Approved_Unit_Codes__c = APPROVEUNITCODE_BUS101;
            cta.reduivy__Status__c = approvedStatuses[0];
            cta.reduivy__Approved_Letter_Grade__c = APPROVED_GRADE_CT;
        }

        System.runAs(ADMIN_USER){

            Test.startTest();
            
            update ctaList;

            // Individual enrollment
            List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id,
                RecordTypeId,
                reduivy__Contact__c,
                reduivy__Credit_Transfer_Application__c,
                reduivy__Credits_Offered__c,
                reduivy__Letter_Grade__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c,
                reduivy__Credit_Transfer_Received__c,
                reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Credit_Transfer_Application__c IN: ctaList
            ];

            System.Assert.areEqual(false, ienList.isEmpty(), 'Failed to create individual enrollment when credit transfer application is approved');
            System.Assert.areEqual(ctaList.size(), ienList.size());

            for (reduivy__Credit_Transfer_Application__c cta : ctaList) {
                Integer ienCount = 0;

                for (reduivy__Individual_Enrollment__c ien : ienList) {
                    if (cta.Id == ien.reduivy__Credit_Transfer_Application__c) {
                        System.Assert.areEqual(cta.reduivy__Contact__c, ien.reduivy__Contact__c);
                        System.Assert.areEqual(cta.reduivy__Credits_Attempted__c, ien.reduivy__Credits_Offered__c);
                        System.Assert.areEqual(cta.reduivy__Approved_Letter_Grade__c, ien.reduivy__Letter_Grade__c);
                        System.Assert.areEqual(IEN_Helper.getStudentRecordTypeId(), ien.RecordTypeId);
                        System.Assert.areEqual(APPROVEUNITCODE_BUS101, ien.reduivy__Study_Unit__r.reduivy__Unit_Code__c);
                        System.Assert.areEqual(true, ien.reduivy__Credit_Transfer_Received__c);
                        System.Assert.areEqual(IEN_Helper.GRADE_RELEASE_STATUS_RELEASED, ien.reduivy__Grade_Release_Status__c);

                        ienCount ++;
                    }
                }

                System.Assert.areEqual(1, ienCount);
            }

            delete ctaList;

            // Individual enrollment and individual plan structure (unit) are deleted
            ienList = [SELECT Id,
                RecordTypeId,
                reduivy__Contact__c,
                reduivy__Credit_Transfer_Application__c,
                reduivy__Credits_Offered__c,
                reduivy__Letter_Grade__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c,
                reduivy__Credit_Transfer_Received__c,
                reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Credit_Transfer_Application__c IN: ctaList
            ];

            System.Assert.areEqual(true, ienList.isEmpty(), 'Failed to delete individual enrollment when credit transfer application is deleted');

            undelete ctaList;

            // Individual enrollment and individual plan structure (unit) are recreated
            ienList = [SELECT Id,
                RecordTypeId,
                reduivy__Contact__c,
                reduivy__Credit_Transfer_Application__c,
                reduivy__Credits_Offered__c,
                reduivy__Letter_Grade__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c,
                reduivy__Credit_Transfer_Received__c,
                reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Credit_Transfer_Application__c IN: ctaList
            ];

            System.Assert.areEqual(false, ienList.isEmpty(), 'Failed to recreate individual enrollment when credit transfer application is undeleted');

            for (reduivy__Credit_Transfer_Application__c cta : ctaList) {
                cta.reduivy__Status__c = rejectedStatuses[0];
            }

            update ctaList;

            // Individual enrollment and individual plan structure (unit) are deleted
            ienList = [SELECT Id,
                RecordTypeId,
                reduivy__Contact__c,
                reduivy__Credit_Transfer_Application__c,
                reduivy__Credits_Offered__c,
                reduivy__Letter_Grade__c,
                reduivy__Study_Unit__r.reduivy__Unit_Code__c,
                reduivy__Credit_Transfer_Received__c,
                reduivy__Grade_Release_Status__c
                FROM reduivy__Individual_Enrollment__c 
                WHERE reduivy__Credit_Transfer_Application__c IN: ctaList
            ];

            System.Assert.areEqual(true, ienList.isEmpty(), 'Failed to delete individual enrollment when credit transfer application is disapproved');

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin to approve CTA that links to an IPS group
     */
    @isTest   
    static void testCtaToIpsAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<String> approvedStatuses = CTA_Helper.getApprovedStatuses();
        List<String> rejectedStatuses = CTA_Helper.getRejectedStatuses();
        
        // Get credit transfer application to create IPS
        List<reduivy__Credit_Transfer_Application__c> ctaList = [SELECT Id,
            reduivy__Contact__c,
            reduivy__Approved_Letter_Grade__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Credits_Attempted__c,
            reduivy__Credits_Earned__c
            FROM reduivy__Credit_Transfer_Application__c LIMIT 5
        ];

        Map<Id, reduivy__Credit_Transfer_Application__c> contactCtaMap = new Map<Id, reduivy__Credit_Transfer_Application__c>();
        for (reduivy__Credit_Transfer_Application__c cta : ctaList) {
            contactCtaMap.put(cta.reduivy__Contact__c, cta);
            cta.reduivy__Approved_Letter_Grade__c = APPROVED_GRADE_CT;

        }

        // Get credit transfer application to create individual plan (unit)
        Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
        List<reduivy__Individual_Plan_Structure__c> ipsGroupList = new List<reduivy__Individual_Plan_Structure__c>();

        Set<Id> ipeIds = new Set<Id>();
        for (reduivy__Individual_Plan_Structure__c ipsGroup : [SELECT Id,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c
            FROM reduivy__Individual_Plan_Structure__c 
            WHERE reduivy__Individual_Program_Enrollment__r.RecordTypeId =: IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c IN: contactCtaMap.keySet()
            AND RecordTypeId =: IPS_Helper.getGroupRecordTypeId()
        ]) {
            //we will take 1 group from each IPE
            if (!ipeIds.contains(ipsGroup.reduivy__Individual_Program_Enrollment__c)) {
                reduivy__Credit_Transfer_Application__c cta = contactCtaMap.get(ipsGroup.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c);
                cta.reduivy__Individual_Plan_Structure__c = ipsGroup.Id;
                cta.reduivy__Status__c = approvedStatuses[0];
                cta.reduivy__Credits_Earned__c = 3;
                cta.reduivy__Credits_Attempted__c = 3;

                ipeIds.add(ipsGroup.reduivy__Individual_Program_Enrollment__c);

                ipsGroupList.add(ipsGroup);
            }
        }
        
        System.runAs(ADMIN_USER){

            Test.startTest();
            
            update ctaList;

            // Individual plan structure (unit) are created
            List<reduivy__Individual_Plan_Structure__c> ipsUnitList = [SELECT Id,
                reduivy__Individual_Program_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
                reduivy__Credit_Transfer_Application__c,
                reduivy__Credits__c,
                reduivy__Credits_Earned__c,
                reduivy__Parent_Plan_Structure__c,
                reduivy__Status__c,
                reduivy__Primary__c,
                reduivy__Credits_Contribution__c,
                RecordTypeId
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE reduivy__Credit_Transfer_Application__c IN: ctaList
            ];

            System.Assert.areEqual(false, ipsUnitList.isEmpty(), 'Failed to create individual plan structure (unit) when credit transfer application is approved');
            System.Assert.areEqual(ctaList.size(), ipsUnitList.size());

            for (reduivy__Credit_Transfer_Application__c cta : ctaList) {
                Integer ipsCount = 0;

                for (reduivy__Individual_Plan_Structure__c ips : ipsUnitList) {
                    if (cta.Id == ips.reduivy__Credit_Transfer_Application__c) {
                        System.Assert.areEqual(cta.reduivy__Contact__c, ips.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c);
                        System.Assert.areEqual(cta.reduivy__Credits_Attempted__c, ips.reduivy__Credits__c);
                        System.Assert.areEqual(cta.reduivy__Credits_Earned__c, ips.reduivy__Credits_Earned__c);
                        System.Assert.areEqual(IPS_Helper.getUnitRecordTypeId(), ips.RecordTypeId);
                        System.Assert.areEqual(cta.reduivy__Individual_Plan_Structure__c, ips.reduivy__Parent_Plan_Structure__c);
                        System.Assert.areEqual(IPS_Helper.getGroupCompletedStatuses().get(0), ips.reduivy__Status__c);
                        System.Assert.areEqual(true, ips.reduivy__Primary__c);
                        System.Assert.areEqual(IPS_Helper.CREDITS_CONTRIBUTION_YES, ips.reduivy__Credits_Contribution__c);

                        ipsCount ++;
                    }
                }

                System.Assert.areEqual(1, ipsCount);
            }

            delete ctaList;

            // Individual plan structure (unit) are deleted
            ipsUnitList = [SELECT Id,
                reduivy__Individual_Program_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
                reduivy__Credit_Transfer_Application__c,
                reduivy__Credits__c,
                reduivy__Credits_Earned__c,
                reduivy__Parent_Plan_Structure__c,
                reduivy__Status__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE reduivy__Credit_Transfer_Application__c IN: ctaList
            ];

            System.Assert.areEqual(true, ipsUnitList.isEmpty(), 'Failed to delete individual plan structure (unit) when credit transfer application is deleted');

            undelete ctaList;

            // Individual enrollment and individual plan structure (unit) are recreated
            ipsUnitList = [SELECT Id,
                reduivy__Individual_Program_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
                reduivy__Credit_Transfer_Application__c,
                reduivy__Credits__c,
                reduivy__Credits_Earned__c,
                reduivy__Parent_Plan_Structure__c,
                reduivy__Status__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE reduivy__Credit_Transfer_Application__c IN: ctaList
            ];

            System.Assert.areEqual(false, ipsUnitList.isEmpty(), 'Failed to recreate individual plan structure (unit) when credit transfer application is undeleted');

            for (reduivy__Credit_Transfer_Application__c cta : ctaList) {
                cta.reduivy__Status__c = rejectedStatuses[0];
            }

            update ctaList;

            // Individual enrollment and individual plan structure (unit) are deleted
            ipsUnitList = [SELECT Id,
                reduivy__Individual_Program_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
                reduivy__Credit_Transfer_Application__c,
                reduivy__Credits__c,
                reduivy__Credits_Earned__c,
                reduivy__Parent_Plan_Structure__c,
                reduivy__Status__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE reduivy__Credit_Transfer_Application__c IN: ctaList
            ];

            System.Assert.areEqual(true, ipsUnitList.isEmpty(), 'Failed to delete individual plan structure (unit) when credit transfer application is disapproved');

            Test.stopTest();
        }
    }
}