/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Test
 * @description Test class for JQH_SetRecordCount_EXE
 * @changehistory
 * ISS-002219 22-01-2025 Lean - new class
 */

@IsTest
public inherited sharing class JQH_SetRecordCount_TEST {
    
    /**
     * @description Initialise test environment
    */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Initialise test data for each test
    */
    @TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(IEN_Helper.getApiName(), false);

            Test.stopTest();
        }
    }

    /**
     * @description Test set record count as admin
    */
    @IsTest
    static void testSetRecordCountAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');

        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        System.runAs(ADMIN_USER){
            reduivy__Job_Queue__c jobQueue = new reduivy__Job_Queue__c();
            jobQueue.reduivy__Job_Operation__c = 'Sample_Job';
            jobQueue.reduivy__Job_Handler_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());
            jobQueue.reduivy__Job_Handler_Success_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());
            jobQueue.reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<String>{ienMaps.values().get(0).Id, ienMaps.values().get(1).Id});
            jobQueue.reduivy__Job_Handler_Warning_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<String>{ienMaps.values().get(0).Id});

            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue__c>{jobQueue});
        }

        reduivy__Job_Queue__c jobQueueRecord = [SELECT Id, Name, reduivy__Number_of_Records__c, reduivy__Number_of_Success_Records__c, reduivy__Number_of_Warning_Records__c, reduivy__Number_of_Error_Records__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        System.Assert.areEqual(ienMaps.keySet().size(), jobQueueRecord.reduivy__Number_of_Records__c);
        System.Assert.areEqual(ienMaps.keySet().size(), jobQueueRecord.reduivy__Number_of_Success_Records__c);
        System.Assert.areEqual(1, jobQueueRecord.reduivy__Number_of_Warning_Records__c);
        System.Assert.areEqual(2, jobQueueRecord.reduivy__Number_of_Error_Records__c);

    }

    /**
     * @description Test set record count change as admin
    */
    @IsTest
    static void testSetRecordCountChangeAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('enrollmentStatus', 'Enrolled');
        params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, 'Sample_Job');
        
        Map<Id, reduivy__Individual_Enrollment__c> ienMaps = new Map<Id, reduivy__Individual_Enrollment__c>([
            SELECT Id FROM reduivy__Individual_Enrollment__c
            WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
        ]);
        
        System.runAs(ADMIN_USER){
            reduivy__Job_Queue__c jobQueue = new reduivy__Job_Queue__c();
            jobQueue.reduivy__Job_Operation__c = 'Sample_Job';
            jobQueue.reduivy__Job_Handler_Record_Ids__c = '';
            jobQueue.reduivy__Job_Handler_Success_Record_Ids__c = '';
            jobQueue.reduivy__Job_Handler_Error_Record_Ids__c = '';
            jobQueue.reduivy__Job_Handler_Warning_Record_Ids__c = '';

            REDU_Database_UTIL.doInsert(new List<reduivy__Job_Queue__c>{jobQueue});
        }

        reduivy__Job_Queue__c jobQueueRecord = [SELECT Id, Name, reduivy__Number_of_Records__c, reduivy__Number_of_Success_Records__c, reduivy__Number_of_Warning_Records__c, reduivy__Number_of_Error_Records__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];
        
        System.Assert.areEqual(0, jobQueueRecord.reduivy__Number_of_Records__c);
        System.Assert.areEqual(0, jobQueueRecord.reduivy__Number_of_Success_Records__c);
        System.Assert.areEqual(0, jobQueueRecord.reduivy__Number_of_Warning_Records__c);
        System.Assert.areEqual(0, jobQueueRecord.reduivy__Number_of_Error_Records__c);

        System.runAs(ADMIN_USER){
            reduivy__Job_Queue__c jobQueueUpdate = new reduivy__Job_Queue__c(Id = jobQueueRecord.Id);
            jobQueueUpdate.reduivy__Job_Operation__c = 'Sample_Job';
            jobQueueUpdate.reduivy__Job_Handler_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());
            jobQueueUpdate.reduivy__Job_Handler_Success_Record_Ids__c = JQH_Helper.serializeRecordIds(ienMaps.keySet());
            jobQueueUpdate.reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<String>{ienMaps.values().get(0).Id, ienMaps.values().get(1).Id});
            jobQueueUpdate.reduivy__Job_Handler_Warning_Record_Ids__c = JQH_Helper.serializeRecordIds(new List<String>{ienMaps.values().get(0).Id});

            REDU_Database_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jobQueueUpdate});
        }

        reduivy__Job_Queue__c jobQueueRecord2 = [SELECT Id, Name, reduivy__Number_of_Records__c, reduivy__Number_of_Success_Records__c, reduivy__Number_of_Warning_Records__c, reduivy__Number_of_Error_Records__c FROM reduivy__Job_Queue__c WHERE reduivy__Job_Operation__c = 'Sample_Job'];

        System.Assert.areEqual(ienMaps.keySet().size(), jobQueueRecord2.reduivy__Number_of_Records__c);
        System.Assert.areEqual(ienMaps.keySet().size(), jobQueueRecord2.reduivy__Number_of_Success_Records__c);
        System.Assert.areEqual(1, jobQueueRecord2.reduivy__Number_of_Warning_Records__c);
        System.Assert.areEqual(2, jobQueueRecord2.reduivy__Number_of_Error_Records__c);
    }

}