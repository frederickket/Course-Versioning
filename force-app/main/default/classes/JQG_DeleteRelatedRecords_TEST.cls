/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Test
 * @description Test class for JQG_DeleteRelatedRecords_EXE
 * @changehistory
 * ISS-002547 14-07-2025 Lean - new class
 */
@IsTest
public inherited sharing class JQG_DeleteRelatedRecords_TEST {

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
        	
            testFactory.initMasterData(ACC_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            List<reduivy__Job_Queue_Group__c> jqgList = new List<reduivy__Job_Queue_Group__c>();
            List<reduivy__Job_Queue__c> jqhList = new List<reduivy__Job_Queue__c>();
            List<reduivy__Log__c> logList = new List<reduivy__Log__c>();

            //create job queue group
            for (Integer i = 0; i < 10; i ++) {
                reduivy__Job_Queue_Group__c newJqg = REDU_TestData_UTIL.newJobQueueGroup('Test_' + i, 'Test_' + i);

                jqgList.add(newJqg);
            }

            REDU_Database_UTIL.doInsert(jqgList);

            //create job queue and log for job queue group
            for (reduivy__Job_Queue_Group__c jqg : jqgList) {
                for (Integer i = 0; i < 10; i ++) {
                    reduivy__Job_Queue__c newJqh = REDU_TestData_UTIL.newJobQueue(
                        jqg.reduivy__Sample_Record_Code__c + '_Job_' + i, 
                        jqg.Id, 
                        jqg.reduivy__Job_Operation_Context__c, 
                        null, 
                        null, 
                        null, 
                        null, 
                        null, 
                        null, 
                        null, 
                        null, 
                        null
                    );
                    
                    //log for job queue group
                    reduivy__Log__c newLog = REDU_TestData_UTIL.newLog(jqg.reduivy__Sample_Record_Code__c + '_Log_' + i, jqg.Id, null, jqg.reduivy__Sample_Record_Code__c + '_Log_' + i, null, null);

                    jqhList.add(newJqh);
                    logList.add(newLog);
                }
            }

            REDU_Database_UTIL.doInsert(jqhList);

            //create log for job queue
            for (reduivy__Job_Queue__c jqh : jqhList) {
                for (Integer i = 0; i < 10; i ++) {
                    reduivy__Log__c newLog = REDU_TestData_UTIL.newLog(jqh.reduivy__Sample_Record_Code__c + '_Log_' + i, jqh.reduivy__Job_Queue_Group__c, jqh.Id, jqh.reduivy__Sample_Record_Code__c + '_Log_' + i, null, null);

                    logList.add(newLog);
                }
            }

            REDU_Database_UTIL.doInsert(logList);
            
            Integer jobQueueGroupCount = 0;

            for (reduivy__Job_Queue_Group__c jqg : [SELECT Id, 
                reduivy__Sample_Record_Code__c,
                reduivy__Job_Operation_Context__c,
                (
                    SELECT Id, 
                    reduivy__Job_Operation_Context__c
                    FROM reduivy__Job_Queues__r
                ),
                (
                    SELECT Id,
                    reduivy__Job_Queue_Group__c,
                    reduivy__Job_Queue__c
                    FROM reduivy__Logs__r                    
                )
                FROM reduivy__Job_Queue_Group__c
                WHERE reduivy__Sample_Record_Code__c != null
                WITH USER_MODE
            ]) {
                jobQueueGroupCount ++;

                System.Assert.areEqual(10, jqg.reduivy__Job_Queues__r.size());

                Integer jobQueueGroupLogCount = 0;

                for (reduivy__Log__c log : jqg.reduivy__Logs__r) {
                    if (String.isBlank(log.reduivy__Job_Queue__c)) {
                        jobQueueGroupLogCount ++;
                    }
                }

                System.Assert.areEqual(10, jobQueueGroupLogCount, 'There is not job queue group log found for testing.');
            }

            System.Assert.areEqual(10, jobQueueGroupCount, 'There is not job queue group found for testing.');
            
            Integer jobQueueCount = 0;

            for (reduivy__Job_Queue__c jgh : [SELECT Id, 
                reduivy__Sample_Record_Code__c,
                reduivy__Job_Operation_Context__c,
                (
                    SELECT Id,
                    reduivy__Job_Queue_Group__c,
                    reduivy__Job_Queue__c
                    FROM reduivy__Logs__r                    
                )
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Sample_Record_Code__c != null
                WITH USER_MODE
            ]) {
                jobQueueCount ++;

                System.Assert.areEqual(10, jgh.reduivy__Logs__r.size());
            }

            Test.stopTest();
		}
    }
	
    /**
     * @description Test as admin to delete job queue group
     */
    @IsTest
    static void testDeleteJobQueueGroupAsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
		System.runAs(ADMIN_USER){
            List<reduivy__Job_Queue_Group__c> jobQueueGroups = [SELECT Id, 
                reduivy__Sample_Record_Code__c,
                reduivy__Job_Operation_Context__c
                FROM reduivy__Job_Queue_Group__c
                WHERE reduivy__Sample_Record_Code__c != null
            ];

            REDU_Database_UTIL.doDelete(jobQueueGroups);
		}

        Integer jobQueueGroupCount = 0;
        Integer jobQueueGroupLogCount = 0;

        List<reduivy__Job_Queue_Group__c> jobQueueGroupListAfterDeletion = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Job_Operation_Context__c
            FROM reduivy__Job_Queue_Group__c
            WHERE reduivy__Sample_Record_Code__c != null
        ];

        List<reduivy__Job_Queue__c> jobQueueListAfterDeletion = [SELECT Id, 
            reduivy__Sample_Record_Code__c,
            reduivy__Job_Operation_Context__c
            FROM reduivy__Job_Queue__c
            WHERE reduivy__Sample_Record_Code__c != null
        ];

        List<reduivy__Log__c> logListAfterDeletion = [SELECT Id,
            reduivy__Job_Queue_Group__c,
            reduivy__Job_Queue__c
            FROM reduivy__Log__c
            WHERE reduivy__Sample_Record_Code__c != null
        ];

        System.Assert.areEqual(true, jobQueueGroupListAfterDeletion.isEmpty(), 'The job queue group should be deleted');
        System.Assert.areEqual(true, jobQueueListAfterDeletion.isEmpty(), 'The job queue should be deleted.');
        System.Assert.areEqual(true, logListAfterDeletion.isEmpty(), 'The job queue should be deleted.');

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty to delete job queue group
     */
    @IsTest
    static void testDeleteJobQueueGroupAsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
		System.runAs(FACULTY_USER){
            try {
                List<reduivy__Job_Queue_Group__c> jobQueueGroups = [SELECT Id, 
                    reduivy__Sample_Record_Code__c,
                    reduivy__Job_Operation_Context__c
                    FROM reduivy__Job_Queue_Group__c
                    WHERE reduivy__Sample_Record_Code__c != null
                    WITH USER_MODE
                ];

                REDU_Database_UTIL.doDelete(jobQueueGroups);

            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().containsIgnoreCase('sObject type \'reduivy__Job_Queue_Group__c\' is not supported.'), 'Unexpected error: ' + exp.getMessage());
            }
		}

        Test.stopTest();
		
    }

    /**
     * @description Test as student to delete job queue group
     */
    @IsTest
    static void testDeleteJobQueueGroupAsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
		System.runAs(studentUser){
            try {
                List<reduivy__Job_Queue_Group__c> jobQueueGroups = [SELECT Id, 
                    reduivy__Sample_Record_Code__c,
                    reduivy__Job_Operation_Context__c
                    FROM reduivy__Job_Queue_Group__c
                    WHERE reduivy__Sample_Record_Code__c != null
                    WITH USER_MODE
                ];

                REDU_Database_UTIL.doDelete(jobQueueGroups);
                
            } catch(Exception exp) {
                System.Assert.isTrue(exp.getMessage().containsIgnoreCase('sObject type \'reduivy__Job_Queue_Group__c\' is not supported.'), 'Unexpected error: ' + exp.getMessage());
            }
		}

        Test.stopTest();
		
    }
	
}