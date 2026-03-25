/**
 * @author      WDCi (Lean)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for SPL_DefaultPlan_EXE
 * @changehistory
 * ISS-001798 06-11-2023 Lean - New class
 */
@isTest
public inherited sharing class SPL_DefaultPlan_TEST {

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

            testFactory.initMasterData(SPG_Helper.getApiName());

            Test.stopTest();
        }
    }
	
    /**
     * @description Test as admin for unique default study plan for insert
     */
    @isTest
    static void testNewUniqueDefaultSplAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Program__c> studyPrograms = [SELECT Id, Name FROM reduivy__Study_Program__c];
        List<reduivy__Study_Plan__c> newStudyPlans = new List<reduivy__Study_Plan__c>();
        
        //we should have some sample record for testing
        System.Assert.areEqual(true, !studyPrograms.isEmpty());
        
        System.runAs(ADMIN_USER){
            for (reduivy__Study_Program__c spg : studyPrograms) {
                reduivy__Study_Plan__c spl = REDU_TestData_UTIL.newStudyPlan(spg.Id + '_Default', spg.Id, null, spg.Id + ' - Major', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, true, 160);

                newStudyPlans.add(spl);
            }
            
            insert newStudyPlans;
        }

        for (reduivy__Study_Program__c spg : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Plans__r)
            FROM reduivy__Study_Program__c
            WHERE Id IN: studyPrograms
        ] ) {
            Integer defaultSplCount = 0;

            for (reduivy__Study_Plan__c spl : spg.reduivy__Study_Plans__r) {
                if (spl.reduivy__Default__c) {
                    defaultSplCount ++;
                }
            }

            //ensure that there is only 1 default spl per spg
            System.Assert.areEqual(1, defaultSplCount);
        }
    }

    /**
     * @description Test as admin for duplicate default study plan for insert
     */
    @isTest
    static void testNewDuplicateDefaultSplAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Program__c> studyPrograms = [SELECT Id, Name FROM reduivy__Study_Program__c];
        List<reduivy__Study_Plan__c> newStudyPlans = new List<reduivy__Study_Plan__c>();

        //we should have some sample record for testing
        System.Assert.areEqual(true, !studyPrograms.isEmpty());

        System.runAs(ADMIN_USER){
            for (reduivy__Study_Program__c spg : studyPrograms) {
                reduivy__Study_Plan__c spl1 = REDU_TestData_UTIL.newStudyPlan(spg.Id + '_Default', spg.Id, null, spg.Id + ' - Major', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, true, 160);
                reduivy__Study_Plan__c spl2 = REDU_TestData_UTIL.newStudyPlan(spg.Id + '_Default', spg.Id, null, spg.Id + ' - Major', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, true, 160);

                newStudyPlans.add(spl1);
                newStudyPlans.add(spl2);
            }
            
            insert newStudyPlans;
        }

        for (reduivy__Study_Program__c spg : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Plans__r)
            FROM reduivy__Study_Program__c
            WHERE Id IN: studyPrograms
        ] ) {
            Integer defaultSplCount = 0;

            for (reduivy__Study_Plan__c spl : spg.reduivy__Study_Plans__r) {
                if (spl.reduivy__Default__c) {
                    defaultSplCount ++;
                }
            }

            //ensure that there is only 1 default spl per spg
            System.Assert.areEqual(1, defaultSplCount);
        }
    }

    /**
     * @description Test as admin for newly inserted default study plan
     */
    @isTest
    static void testNewDefaultSplAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Program__c> studyPrograms = [SELECT Id, Name FROM reduivy__Study_Program__c];
        List<reduivy__Study_Plan__c> newStudyPlans = new List<reduivy__Study_Plan__c>();

        //we should have some sample record for testing
        System.Assert.areEqual(true, !studyPrograms.isEmpty());

        System.runAs(ADMIN_USER){
            for (reduivy__Study_Program__c spg : studyPrograms) {
                reduivy__Study_Plan__c spl = REDU_TestData_UTIL.newStudyPlan(spg.Id + '_Default', spg.Id, null, spg.Id + ' - Major', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, true, 160);

                newStudyPlans.add(spl);
            }
            
            insert newStudyPlans;
        }

        for (reduivy__Study_Program__c spg : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Plans__r)
            FROM reduivy__Study_Program__c
            WHERE Id IN: studyPrograms
        ] ) {
            Integer defaultSplCount = 0;

            for (reduivy__Study_Plan__c spl : spg.reduivy__Study_Plans__r) {
                if (spl.reduivy__Default__c) {
                    defaultSplCount ++;
                }
            }

            //ensure that there is only 1 default spl per spg
            System.Assert.areEqual(1, defaultSplCount);
        }

        List<reduivy__Study_Plan__c> anotherNewStudyPlans = new List<reduivy__Study_Plan__c>();

        System.runAs(ADMIN_USER){
            for (reduivy__Study_Program__c spg : studyPrograms) {
                reduivy__Study_Plan__c spl = REDU_TestData_UTIL.newStudyPlan(spg.Id + '_Default', spg.Id, null, spg.Id + ' - Major', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, true, 160);

                anotherNewStudyPlans.add(spl);
            }
            
            insert anotherNewStudyPlans;
        }

        for (reduivy__Study_Program__c spg : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Plans__r)
            FROM reduivy__Study_Program__c
            WHERE Id IN: studyPrograms
        ] ) {
            Integer defaultSplCount = 0;

            for (reduivy__Study_Plan__c spl : spg.reduivy__Study_Plans__r) {
                if (spl.reduivy__Default__c) {
                    defaultSplCount ++;

                    for (reduivy__Study_Plan__c previousSpl : newStudyPlans) {
                        if (spl.Id == previousSpl.Id) {
                            System.Assert.fail('The previous study plan ' + spl.Id + ' should not be the default anymore.');
                        }
                    }
                }
            }

            //ensure that there is only 1 default spl per spg
            System.Assert.areEqual(1, defaultSplCount);
        }
    }

    /**
     * @description Test as admin for newly updated default study plan
     */
    @isTest
    static void testUpdatedDefaultSplAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Program__c> studyPrograms = [SELECT Id, Name FROM reduivy__Study_Program__c];
        List<reduivy__Study_Plan__c> prevStudyPlans = new List<reduivy__Study_Plan__c>();

        //we should have some sample record for testing
        System.Assert.areEqual(true, !studyPrograms.isEmpty());

        System.runAs(ADMIN_USER){
            for (reduivy__Study_Program__c spg : studyPrograms) {
                reduivy__Study_Plan__c spl = REDU_TestData_UTIL.newStudyPlan(spg.Id + '_Default', spg.Id, null, spg.Id + ' - Major', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, true, 160);

                prevStudyPlans.add(spl);
            }
            
            insert prevStudyPlans;
        }

        for (reduivy__Study_Program__c spg : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Plans__r)
            FROM reduivy__Study_Program__c
            WHERE Id IN: studyPrograms
        ] ) {
            Integer defaultSplCount = 0;

            for (reduivy__Study_Plan__c spl : spg.reduivy__Study_Plans__r) {
                if (spl.reduivy__Default__c) {
                    defaultSplCount ++;
                }
            }

            //ensure that there is only 1 default spl per spg
            System.Assert.areEqual(1, defaultSplCount);
        }

        List<reduivy__Study_Plan__c> anotherNewStudyPlans = new List<reduivy__Study_Plan__c>();

        System.runAs(ADMIN_USER){
            for (reduivy__Study_Program__c spg : studyPrograms) {
                reduivy__Study_Plan__c spl = REDU_TestData_UTIL.newStudyPlan(spg.Id + '_Default', spg.Id, null, spg.Id + ' - Major', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, false, 160);

                anotherNewStudyPlans.add(spl);
            }
            
            insert anotherNewStudyPlans;
        }

        //ensure that the default plan has not changed
        for (reduivy__Study_Program__c spg : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Plans__r)
            FROM reduivy__Study_Program__c
            WHERE Id IN: studyPrograms
        ] ) {
            Integer defaultSplCount = 0;

            for (reduivy__Study_Plan__c spl : spg.reduivy__Study_Plans__r) {
                if (spl.reduivy__Default__c) {
                    defaultSplCount ++;

                    for (reduivy__Study_Plan__c anotherSpl : anotherNewStudyPlans) {
                        if (spl.Id == anotherSpl.Id) {
                            System.Assert.fail('The new study plan ' + spl.Id + ' should not be the default.');
                        }
                    }
                }
            }

            //ensure that there is only 1 default spl per spg
            System.Assert.areEqual(1, defaultSplCount);
        }

        System.runAs(ADMIN_USER){
            //we now promote the study plan to be the default again
            for (reduivy__Study_Plan__c anotherSpl : anotherNewStudyPlans) {
                anotherSpl.reduivy__Default__c = true;
            }

            update anotherNewStudyPlans;
        }

        //ensure that the new default pathway has been promoted correctly
        for (reduivy__Study_Program__c spg : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Plans__r)
            FROM reduivy__Study_Program__c
            WHERE Id IN: studyPrograms
        ] ) {
            Integer defaultSplCount = 0;

            for (reduivy__Study_Plan__c spl : spg.reduivy__Study_Plans__r) {
                if (spl.reduivy__Default__c) {
                    defaultSplCount ++;

                    for (reduivy__Study_Plan__c previousSpl : prevStudyPlans) {
                        if (spl.Id == previousSpl.Id) {
                            System.Assert.fail('The previous study plan ' + spl.Id + ' should not be the default anymore.');
                        }
                    }
                }
            }

            //ensure that there is only 1 default spl per spg
            System.Assert.areEqual(1, defaultSplCount);
        }
    }

    /**
     * @description Test as admin for changed of study program for a default study plan
     */
    @isTest
    static void testUpdatedStudyPlanForDefaultSpwAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Program__c> studyPrograms = [SELECT Id, Name FROM reduivy__Study_Program__c];
        List<reduivy__Study_Plan__c> newStudyPlans = new List<reduivy__Study_Plan__c>();

        //we should have some sample record for testing
        System.Assert.areEqual(true, !studyPrograms.isEmpty());

        reduivy__Study_Program__c spgForTest1 = studyPrograms.get(0);
        reduivy__Study_Program__c spgForTest2 = studyPrograms.get(1);

        //insert default pathway for testing
        reduivy__Study_Plan__c spl1 = REDU_TestData_UTIL.newStudyPlan(spgForTest1.Id + '_Default', spgForTest1.Id, null, spgForTest1.Id + ' - Major', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, true, 160);
        reduivy__Study_Plan__c spl2 = REDU_TestData_UTIL.newStudyPlan(spgForTest2.Id + '_Default', spgForTest2.Id, null, spgForTest2.Id + ' - Major', SPL_Helper.PAYUPFRONT_No, SPL_Helper.STATUS_ACTIVE, true, 160);

        System.runAs(ADMIN_USER){
            newStudyPlans.add(spl1);
            newStudyPlans.add(spl2);
            
            insert newStudyPlans;
        }

        for (reduivy__Study_Program__c spg : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Plans__r)
            FROM reduivy__Study_Program__c
            WHERE Id =: spgForTest1.Id OR Id =: spgForTest2.Id
        ] ) {
            Integer defaultSplCount = 0;

            for (reduivy__Study_Plan__c spl : spg.reduivy__Study_Plans__r) {
                if (spl.reduivy__Default__c) {
                    defaultSplCount ++;
                }
            }

            //ensure that there is only 1 default spw per spl
            System.Assert.areEqual(1, defaultSplCount);
        }

        System.runAs(ADMIN_USER){
            //we change the study plan
            spl2.reduivy__Study_Program__c = spgForTest1.Id;

            update newStudyPlans;
        }

        for (reduivy__Study_Program__c spg : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Plans__r)
            FROM reduivy__Study_Program__c
            WHERE Id =: spgForTest1.Id OR Id =: spgForTest2.Id
        ] ) {

            if (spg.Id == spgForTest1.Id) {
                Integer defaultSplCount = 0;

                for (reduivy__Study_Plan__c spl : spg.reduivy__Study_Plans__r) {
                    if (spl.reduivy__Default__c) {
                        if (spl.Id == spl2.Id) {
                            defaultSplCount ++;
                        } else {
                            System.Assert.fail('The default study plan ' + spl.Id + ' for the study program ' + spg.Id + ' is wrong.');
                        }
                    }
                }

                //ensure that there is only 1 default spw per spl
                System.Assert.areEqual(1, defaultSplCount);

            } else if (spg.Id == spgForTest2.Id) {
                System.Assert.areEqual(true, spg.reduivy__Study_Plans__r.isEmpty());
            }
        }

    }
	
}