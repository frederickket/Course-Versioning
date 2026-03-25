/**
 * @author      WDCi (Lean)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for SPW_DefaultPathway_EXE
 * @changehistory
 * ISS-001797 06-11-2023 Lean - New class
 */
@isTest
public inherited sharing class SPW_DefaultPathway_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    public static final String SPW_ACTIVE_STATUS = SPW_Helper.STATUS_ACTIVE;

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

            testFactory.initMasterData(SPS_Helper.getApiName());

            Test.stopTest();
        }
    }
	
    /**
     * @description Test as admin for unique default study pathway for insert
     */
    @isTest
    static void testNewUniqueDefaultSpwAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id, Name FROM reduivy__Study_Plan__c];
        List<reduivy__Study_Pathway__c> newStudyPathways = new List<reduivy__Study_Pathway__c>();

        //we should have some sample record for testing
        System.Assert.areEqual(true, !studyPlans.isEmpty());

        System.runAs(ADMIN_USER){
            for (reduivy__Study_Plan__c spl : studyPlans) {
                reduivy__Study_Pathway__c spw = REDU_TestData_UTIL.newStudyPathway(spl.Id + '_DEFAULT', spl.Id, spl.Name + ' Default Pathway', SPW_ACTIVE_STATUS, true);

                newStudyPathways.add(spw);
            }
            
            insert newStudyPathways;
        }

        for (reduivy__Study_Plan__c spl : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Pathways__r)
            FROM reduivy__Study_Plan__c
            WHERE Id IN: studyPlans
        ] ) {
            Integer defaultSpwCount = 0;

            for (reduivy__Study_Pathway__c spw : spl.reduivy__Study_Pathways__r) {
                if (spw.reduivy__Default__c) {
                    defaultSpwCount ++;
                }
            }

            //ensure that there is only 1 default spw per spl
            System.Assert.areEqual(1, defaultSpwCount);
        }
    }

    /**
     * @description Test as admin for duplicate default study pathway for insert
     */
    @isTest
    static void testNewDuplicateDefaultSpwAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id, Name FROM reduivy__Study_Plan__c];
        List<reduivy__Study_Pathway__c> newStudyPathways = new List<reduivy__Study_Pathway__c>();

        //we should have some sample record for testing
        System.Assert.areEqual(true, !studyPlans.isEmpty());

        System.runAs(ADMIN_USER){
            for (reduivy__Study_Plan__c spl : studyPlans) {
                reduivy__Study_Pathway__c spw1 = REDU_TestData_UTIL.newStudyPathway(spl.Id + '_DEFAULT', spl.Id, spl.Name + ' Default Pathway', SPW_ACTIVE_STATUS, true);
                reduivy__Study_Pathway__c spw2 = REDU_TestData_UTIL.newStudyPathway(spl.Id + '_DEFAULT', spl.Id, spl.Name + ' Default Pathway', SPW_ACTIVE_STATUS, true);

                newStudyPathways.add(spw1);
                newStudyPathways.add(spw2);
            }
            
            insert newStudyPathways;
        }

        for (reduivy__Study_Plan__c spl : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Pathways__r)
            FROM reduivy__Study_Plan__c
            WHERE Id IN: studyPlans
        ] ) {
            Integer defaultSpwCount = 0;

            for (reduivy__Study_Pathway__c spw : spl.reduivy__Study_Pathways__r) {
                if (spw.reduivy__Default__c) {
                    defaultSpwCount ++;
                }
            }

            //ensure that there is only 1 default spw per spl
            System.Assert.areEqual(1, defaultSpwCount);
        }
    }

    /**
     * @description Test as admin for newly inserted default study pathway
     */
    @isTest
    static void testNewDefaultSpwAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id, Name FROM reduivy__Study_Plan__c];
        List<reduivy__Study_Pathway__c> newStudyPathways = new List<reduivy__Study_Pathway__c>();

        //we should have some sample record for testing
        System.Assert.areEqual(true, !studyPlans.isEmpty());

        System.runAs(ADMIN_USER){
            for (reduivy__Study_Plan__c spl : studyPlans) {
                reduivy__Study_Pathway__c spw = REDU_TestData_UTIL.newStudyPathway(spl.Id + '_DEFAULT', spl.Id, spl.Name + ' Default Pathway', SPW_ACTIVE_STATUS, true);

                newStudyPathways.add(spw);
            }
            
            insert newStudyPathways;
        }

        for (reduivy__Study_Plan__c spl : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Pathways__r)
            FROM reduivy__Study_Plan__c
            WHERE Id IN: studyPlans
        ] ) {
            Integer defaultSpwCount = 0;

            for (reduivy__Study_Pathway__c spw : spl.reduivy__Study_Pathways__r) {
                if (spw.reduivy__Default__c) {
                    defaultSpwCount ++;
                }
            }

            //ensure that there is only 1 default spw per spl
            System.Assert.areEqual(1, defaultSpwCount);
        }

        //insert another new default study pathway for the study plan
        List<reduivy__Study_Pathway__c> anotherNewStudyPathways = new List<reduivy__Study_Pathway__c>();

        System.runAs(ADMIN_USER){
            for (reduivy__Study_Plan__c spl : studyPlans) {
                reduivy__Study_Pathway__c spw = REDU_TestData_UTIL.newStudyPathway(spl.Id + '_DEFAULT', spl.Id, spl.Name + ' Default Pathway', SPW_ACTIVE_STATUS, true);

                anotherNewStudyPathways.add(spw);
            }
            
            insert anotherNewStudyPathways;
        }

        for (reduivy__Study_Plan__c spl : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Pathways__r)
            FROM reduivy__Study_Plan__c
            WHERE Id IN: studyPlans
        ] ) {
            Integer defaultSpwCount = 0;

            for (reduivy__Study_Pathway__c spw : spl.reduivy__Study_Pathways__r) {
                if (spw.reduivy__Default__c) {
                    defaultSpwCount ++;

                    for (reduivy__Study_Pathway__c previousSpw : newStudyPathways) {
                        if (spw.Id == previousSpw.Id) {
                            System.Assert.fail('The previous study pathway ' + spw.Id + ' should not be the default anymore.');
                        }
                    }
                }
            }

            //ensure that there is only 1 default spw per spl
            System.Assert.areEqual(1, defaultSpwCount);
        }
    }

    /**
     * @description Test as admin for newly updated default study pathway
     */
    @isTest
    static void testUpdatedDefaultSpwAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id, Name FROM reduivy__Study_Plan__c];
        List<reduivy__Study_Pathway__c> prevStudyPathways = new List<reduivy__Study_Pathway__c>();

        //we should have some sample record for testing
        System.Assert.areEqual(true, !studyPlans.isEmpty());

        System.runAs(ADMIN_USER){
            //insert default pathway for testing
            for (reduivy__Study_Plan__c spl : studyPlans) {
                reduivy__Study_Pathway__c spw = REDU_TestData_UTIL.newStudyPathway(spl.Id + '_DEFAULT', spl.Id, spl.Name + ' Default Pathway', SPW_ACTIVE_STATUS, true);

                prevStudyPathways.add(spw);
            }
            
            insert prevStudyPathways;
        }

        for (reduivy__Study_Plan__c spl : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Pathways__r)
            FROM reduivy__Study_Plan__c
            WHERE Id IN: studyPlans
        ] ) {
            Integer defaultSpwCount = 0;

            for (reduivy__Study_Pathway__c spw : spl.reduivy__Study_Pathways__r) {
                if (spw.reduivy__Default__c) {
                    defaultSpwCount ++;
                }
            }

            //ensure that there is only 1 default spw per spl
            System.Assert.areEqual(1, defaultSpwCount);
        }

        //insert another new non default study pathway for the study plan
        List<reduivy__Study_Pathway__c> anotherNewStudyPathways = new List<reduivy__Study_Pathway__c>();

        System.runAs(ADMIN_USER){
            for (reduivy__Study_Plan__c spl : studyPlans) {
                reduivy__Study_Pathway__c spw = REDU_TestData_UTIL.newStudyPathway(spl.Id + '_DEFAULT', spl.Id, spl.Name + ' Default Pathway', SPW_ACTIVE_STATUS, false);

                anotherNewStudyPathways.add(spw);
            }
            
            insert anotherNewStudyPathways;
        }

        //ensure that the default pathway has not changed
        for (reduivy__Study_Plan__c spl : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Pathways__r)
            FROM reduivy__Study_Plan__c
            WHERE Id IN: studyPlans
        ] ) {
            Integer defaultSpwCount = 0;

            for (reduivy__Study_Pathway__c spw : spl.reduivy__Study_Pathways__r) {
                if (spw.reduivy__Default__c) {
                    defaultSpwCount ++;

                    for (reduivy__Study_Pathway__c anotherSpw : anotherNewStudyPathways) {
                        if (spw.Id == anotherSpw.Id) {
                            System.Assert.fail('The new study pathway ' + spw.Id + ' should not be the default.');
                        }
                    }
                }
            }

            //ensure that there is only 1 default spw per spl
            System.Assert.areEqual(1, defaultSpwCount);
        }

        System.runAs(ADMIN_USER){
            //we now promote the study pathway to be the default again
            for (reduivy__Study_Pathway__c anotherSpw : anotherNewStudyPathways) {
                anotherSpw.reduivy__Default__c = true;
            }

            update anotherNewStudyPathways;
        }

        //ensure that the new default pathway has been promoted correctly
        for (reduivy__Study_Plan__c spl : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Pathways__r)
            FROM reduivy__Study_Plan__c
            WHERE Id IN: studyPlans
        ] ) {
            Integer defaultSpwCount = 0;

            for (reduivy__Study_Pathway__c spw : spl.reduivy__Study_Pathways__r) {
                if (spw.reduivy__Default__c) {
                    defaultSpwCount ++;

                    for (reduivy__Study_Pathway__c anotherSpw : prevStudyPathways) {
                        if (spw.Id == anotherSpw.Id) {
                            System.Assert.fail('The previous study pathway ' + spw.Id + ' should not be the default anymore.');
                        }
                    }
                }
            }

            //ensure that there is only 1 default spw per spl
            System.Assert.areEqual(1, defaultSpwCount);
        }
    }

    /**
     * @description Test as admin for changed of study plan for a default study pathway
     */
    @isTest
    static void testUpdatedStudyPlanForDefaultSpwAsAdmin() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Plan__c> studyPlans = [SELECT Id, Name FROM reduivy__Study_Plan__c];
        List<reduivy__Study_Pathway__c> newStudyPathways = new List<reduivy__Study_Pathway__c>();

        //we should have some sample record for testing
        System.Assert.areEqual(true, !studyPlans.isEmpty());

        reduivy__Study_Plan__c splForTest1 = studyPlans.get(0);
        reduivy__Study_Plan__c splForTest2 = studyPlans.get(1);

        //insert default pathway for testing
        reduivy__Study_Pathway__c spw1 = REDU_TestData_UTIL.newStudyPathway(splForTest1.Id + '_DEFAULT', splForTest1.Id, splForTest1.Name + ' Default Pathway', SPW_ACTIVE_STATUS, true);
        reduivy__Study_Pathway__c spw2 = REDU_TestData_UTIL.newStudyPathway(splForTest2.Id + '_DEFAULT', splForTest2.Id, splForTest2.Name + ' Default Pathway', SPW_ACTIVE_STATUS, true);

        System.runAs(ADMIN_USER){
            newStudyPathways.add(spw1);
            newStudyPathways.add(spw2);
            
            insert newStudyPathways;
        }

        for (reduivy__Study_Plan__c spl : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Pathways__r)
            FROM reduivy__Study_Plan__c
            WHERE Id =: splForTest1.Id OR Id =: splForTest2.Id
        ] ) {
            Integer defaultSpwCount = 0;

            for (reduivy__Study_Pathway__c spw : spl.reduivy__Study_Pathways__r) {
                if (spw.reduivy__Default__c) {
                    defaultSpwCount ++;
                }
            }

            //ensure that there is only 1 default spw per spl
            System.Assert.areEqual(1, defaultSpwCount);
        }

        System.runAs(ADMIN_USER){
            //we change the study plan
            spw2.reduivy__Study_Plan__c = splForTest1.Id;

            update newStudyPathways;
        }

        for (reduivy__Study_Plan__c spl : [SELECT Id, 
            (SELECT Id, reduivy__Default__c FROM reduivy__Study_Pathways__r)
            FROM reduivy__Study_Plan__c
            WHERE Id =: splForTest1.Id OR Id =: splForTest2.Id
        ] ) {

            if (spl.Id == splForTest1.Id) {
                Integer defaultSpwCount = 0;

                for (reduivy__Study_Pathway__c spw : spl.reduivy__Study_Pathways__r) {
                    if (spw.reduivy__Default__c) {
                        if (spw.Id == spw2.Id) {
                            defaultSpwCount ++;
                        } else {
                            System.Assert.fail('The default study pathway ' + spw.Id + ' for the study plan ' + spl.Id + ' is wrong.');
                        }
                    }
                }

                //ensure that there is only 1 default spw per spl
                System.Assert.areEqual(1, defaultSpwCount);

            } else if (spl.Id == splForTest2.Id) {
                System.Assert.areEqual(true, spl.reduivy__Study_Pathways__r.isEmpty());
            }
        }

    }
	
}