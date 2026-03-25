/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Test Class
 * @description Test class for JQH_TermOfferingsCloning_GENERATOR and JQH_TermOfferingsCloning_HANDLER
 * @changehistory
 * ISS-002200 17-03-2025 XiRouh - new class
 * ISS-002364 22-04-2025 XiRouh - Updated to include the test for retaining or renaming the record name
 */
@IsTest
public inherited sharing class JQH_TermOfferingsCloning_TEST {
    private static final String JOB_OPERATION = 'Term_Offerings_Cloning';
    private static final String ACADEMIC_TERM_RECORD_TYPE_ID = STM_Helper.getAcademicTermRecordTypeId();

    private static final String CYT1Key = 'CYT1';
    private static final String CYT2Key = 'CYT2';

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

        	testFactory.initMasterData(null);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(USR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

     /**
     * @description Test the Release Grades job through the Generator
     */
    @IsTest
    static void testTermOfferingsCloningJobFromGenerator(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();
            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            Set<String> sofFields = SOF_Helper.getFieldsForCloning();
            sofFields.add('reduivy__Academic_Term__r.Name');
            sofFields.add('reduivy__Academic_Term__r.reduivy__Alternate_Name__c');

            String sofSoql = 'SELECT ' + String.join(sofFields, ', ') + 
                ' FROM reduivy__Study_Offering__c ' +
                ' WHERE reduivy__Status__c IN :sofStatusesSet ';
            
            List<reduivy__Study_Offering__c> sofs = (List<reduivy__Study_Offering__c>) Database.query(sofSoql);
            Map<Id, reduivy__Study_Offering__c> sofToBeCloned = new Map<Id, reduivy__Study_Offering__c>();

            System.Assert.isTrue(sofs.size() > 0, 'No study offering found');

            Set<Id> sunIds = new Set<Id>();

            String term = '';
            String campus = '';

            String selectedTermName = sofs[0].reduivy__Academic_Term__r.Name;
            String selectedTermAlternateName = sofs[0].reduivy__Academic_Term__r.reduivy__Alternate_Name__c;

            for(reduivy__Study_Offering__c sof : sofs){
                if(String.isBlank(term)) {
                    term = sof.reduivy__Academic_Term__c;
                }

                if(String.isBlank(campus)) {
                    campus = sof.reduivy__Campus__c;
                }

                if(sof.reduivy__Academic_Term__c == term) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                    sofToBeCloned.put(sof.Id, sof);
                }
            }

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, reduivy__Academic_Year__r.reduivy__Educational_Institution__c, Name, reduivy__Alternate_Name__c
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                AND reduivy__Sample_Record_Code__c = :CYT2Key
                LIMIT 1
            ];

            Id currentTermId = stm[0].Id;

            String currentTermName = stm[0].Name;
            String currentTermAlternateName = stm[0].reduivy__Alternate_Name__c;

            Map<String, String> textsToBeReplaced = new Map<String, String>();
            textsToBeReplaced.put(selectedTermName, currentTermName);
            textsToBeReplaced.put(selectedTermAlternateName, currentTermAlternateName);

            Map<String, Object> params = new Map<String, Object>();
            params.put('currentTermId', currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, currentTermId));

            params.put('cloneStudySessionOption', 'true');
            params.put('selectedRetainStudyOfferingNameOption', 'true');
            params.put('selectedRetainStudySessionNameOption', 'true');

            params.put('selectedTermId', term);
            params.put('selectedCampusId', campus);
            params.put('studyOfferingStatuses', studyOfferingStatuses);

            params.put('textsToBeReplaced', JSON.serialize(textsToBeReplaced));

            JQH_JobManager.executeJobGenerator(JOB_OPERATION, new List<Id>(sunIds), params, true);

            Test.stopTest();

            //Check Generator ran
            Integer generatorJobCount = [SELECT COUNT() 
                FROM AsyncApexJob
                WHERE JobType = 'Queueable'
                AND ApexClass.Name = 'JQH_JobGenerator_QUEUE'
                AND Status = 'Completed'
                AND CreatedById =: ADMIN_USER.Id
                WITH USER_MODE
            ];
            System.Assert.areEqual(1, generatorJobCount);

            //Check Job Queue records were created
            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.isTrue(jobQueueCheckList.size() > 0, 'No Job Queue records created');
            System.Assert.areEqual(sunIds.size(), jobQueueCheckList.size(), 'Job Queue records size should match with the number of study units');            
        }
    }

    /**
     * @description Test the term offerings cloning job through the Handler
     */
    @IsTest
    static void testTermOfferingsCloningJobFromHandlerWithRetainSofName(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            Set<String> sofFields = SOF_Helper.getFieldsForCloning();
            Set<String> sseFields = SSE_Helper.getFieldsForCloning();
            Set<String> sstFields = SST_Helper.getFieldsForCloning();

            Set<String> sofFieldsForQuery = SOF_Helper.getFieldsForCloning();
            sofFieldsForQuery.add('Id');
            sofFieldsForQuery.add('reduivy__Academic_Term__r.Name');
            sofFieldsForQuery.add('reduivy__Academic_Term__r.reduivy__Alternate_Name__c');

            String sofSoql = 'SELECT ' + String.join(sofFieldsForQuery, ', ') + 
                ' FROM reduivy__Study_Offering__c ' +
                ' WHERE reduivy__Status__c IN :sofStatusesSet ';
            
            List<reduivy__Study_Offering__c> sofs = (List<reduivy__Study_Offering__c>) Database.query(sofSoql);
            Map<Id, reduivy__Study_Offering__c> sofToBeCloned = new Map<Id, reduivy__Study_Offering__c>();
            
            System.Assert.isTrue(sofs.size() > 0, 'No study offering found');

            Set<Id> sunIds = new Set<Id>();

            String term = '';
            String campus = '';

            String selectedTermName = sofs[0].reduivy__Academic_Term__r.Name;
            String selectedTermAlternateName = sofs[0].reduivy__Academic_Term__r.reduivy__Alternate_Name__c;

            List<reduivy__Study_Offering__c> sofsToBeUpdated = new List<reduivy__Study_Offering__c>();

            for(reduivy__Study_Offering__c sof : sofs){
                reduivy__Study_Offering__c tempSof = sof.clone();

                tempSof.Id = sof.Id;
                tempSof.Name = sof.Name + '_' + selectedTermName + '_' + selectedTermAlternateName;

                sofsToBeUpdated.add(tempSof);
            }

            update sofsToBeUpdated;

            for(reduivy__Study_Offering__c sof : sofsToBeUpdated){
                if(String.isBlank(term)) {
                    term = sof.reduivy__Academic_Term__c;
                }

                if(String.isBlank(campus)) {
                    campus = sof.reduivy__Campus__c;
                }

                if(sof.reduivy__Academic_Term__c == term) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                    sofToBeCloned.put(sof.Id, sof);
                }
            }

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, Name, reduivy__Alternate_Name__c
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                AND reduivy__Sample_Record_Code__c = :CYT2Key
                LIMIT 1
            ];

            Id currentTermId = stm[0].Id;

            String currentTermName = stm[0].Name;
            String currentTermAlternateName = stm[0].reduivy__Alternate_Name__c;

            Map<String, String> textsToBeReplaced = new Map<String, String>();
            textsToBeReplaced.put(selectedTermName, currentTermName);
            textsToBeReplaced.put(selectedTermAlternateName, currentTermAlternateName);

            delete [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId];

            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, stm[0].Name);

            params.put('currentTermId', currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, currentTermId));

            params.put('cloneStudySessionOption', 'false');
            params.put('selectedRetainStudyOfferingNameOption', 'true');
            params.put('selectedRetainStudySessionNameOption', 'true');

            params.put('textsToBeReplaced', JSON.serialize(textsToBeReplaced));
            
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, new List<Id>(sofToBeCloned.keySet()), params);
            JQH_JobManager.queueJob(job, true);

            Test.stopTest();

            //Check sof were cloned
            String sofClonedSoql = 'SELECT ' + String.join(sofFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId';
            String sseClonedSoql = 'SELECT ' + String.join(sseFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Session__c WHERE reduivy__Study_Offering__c IN: clonedSofs';
            String sstClonedSoql = 'SELECT ' + String.join(sstFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Study_Session__c IN: clonedSses';

            List<reduivy__Study_Offering__c> clonedSofs = (List<reduivy__Study_Offering__c>) Database.query(sofClonedSoql);
            List<reduivy__Study_Session__c> clonedSses = (List<reduivy__Study_Session__c>) Database.query(sseClonedSoql);
            List<reduivy__Study_Session_Time__c> cloneSsts = (List<reduivy__Study_Session_Time__c>) Database.query(sstClonedSoql);

            System.Assert.areEqual(sofToBeCloned.keySet().size(), clonedSofs.size(), 'All study offerings should have cloned');
            System.Assert.areEqual(0, clonedSses.size(), 'Study session should not be cloned');
            System.Assert.areEqual(0, cloneSsts.size(), 'Study session time should not be cloned');

            for (reduivy__Study_Offering__c clonedSof : clonedSofs) {
                System.Assert.isTrue(String.isNotBlank(clonedSof.reduivy__Clone_From_Id__c), 'The clone from id should not be blank.');
                System.Assert.isTrue(sofToBeCloned.containsKey(clonedSof.reduivy__Clone_From_Id__c), 'The record is not part of the records to be cloned.');

                reduivy__Study_Offering__c sourceSof = sofToBeCloned.get(clonedSof.reduivy__Clone_From_Id__c);

                for (String field : sofFields) {
                    if (field != 'reduivy__Academic_Term__c') {
                        System.Assert.areEqual(sourceSof.get(field), clonedSof.get(field), field + ' is not the same.');
                    }
                }
            }

            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Number_of_Success_Records__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.areEqual(sofToBeCloned.keySet().size(), jobQueueCheckList[0].reduivy__Number_of_Success_Records__c, 'All study offerings should have successfully cloned');
        }
    }

    /**
     * @description Test the term offerings cloning job through the Handler
     */
    @IsTest
    static void testTermOfferingsCloningJobFromHandlerWithRenameSofName(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            Set<String> sofFields = SOF_Helper.getFieldsForCloning();
            Set<String> sseFields = SSE_Helper.getFieldsForCloning();
            Set<String> sstFields = SST_Helper.getFieldsForCloning();

            Set<String> sofFieldsForQuery = SOF_Helper.getFieldsForCloning();
            sofFieldsForQuery.add('Id');
            sofFieldsForQuery.add('reduivy__Academic_Term__r.Name');
            sofFieldsForQuery.add('reduivy__Academic_Term__r.reduivy__Alternate_Name__c');

            String sofSoql = 'SELECT ' + String.join(sofFieldsForQuery, ', ') + 
                ' FROM reduivy__Study_Offering__c ' +
                ' WHERE reduivy__Status__c IN :sofStatusesSet ';
            
            List<reduivy__Study_Offering__c> sofs = (List<reduivy__Study_Offering__c>) Database.query(sofSoql);
            Map<Id, reduivy__Study_Offering__c> sofToBeCloned = new Map<Id, reduivy__Study_Offering__c>();
            
            System.Assert.isTrue(sofs.size() > 0, 'No study offering found');

            Set<Id> sunIds = new Set<Id>();

            String term = '';
            String campus = '';

            String selectedTermName = sofs[0].reduivy__Academic_Term__r.Name;
            String selectedTermAlternateName = sofs[0].reduivy__Academic_Term__r.reduivy__Alternate_Name__c;

            List<reduivy__Study_Offering__c> sofsToBeUpdated = new List<reduivy__Study_Offering__c>();

            for(reduivy__Study_Offering__c sof : sofs){
                reduivy__Study_Offering__c tempSof = sof.clone();

                tempSof.Id = sof.Id;
                tempSof.Name = sof.Name + '_' + selectedTermName + '_' + selectedTermAlternateName;

                sofsToBeUpdated.add(tempSof);
            }

            update sofsToBeUpdated;

            for(reduivy__Study_Offering__c sof : sofsToBeUpdated){
                if(String.isBlank(term)) {
                    term = sof.reduivy__Academic_Term__c;
                }

                if(String.isBlank(campus)) {
                    campus = sof.reduivy__Campus__c;
                }

                if(sof.reduivy__Academic_Term__c == term) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                    sofToBeCloned.put(sof.Id, sof);
                }
            }

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, Name, reduivy__Alternate_Name__c
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                AND reduivy__Sample_Record_Code__c = :CYT2Key
                LIMIT 1
            ];

            Id currentTermId = stm[0].Id;

            String currentTermName = stm[0].Name;
            String currentTermAlternateName = stm[0].reduivy__Alternate_Name__c;

            Map<String, String> textsToBeReplaced = new Map<String, String>();
            textsToBeReplaced.put(selectedTermName, currentTermName);
            textsToBeReplaced.put(selectedTermAlternateName, currentTermAlternateName);

            delete [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId];

            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, stm[0].Name);

            params.put('currentTermId', currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, currentTermId));

            params.put('cloneStudySessionOption', 'false');
            params.put('selectedRetainStudyOfferingNameOption', 'false');
            params.put('selectedRetainStudySessionNameOption', 'true');

            params.put('textsToBeReplaced', JSON.serialize(textsToBeReplaced));
            
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, new List<Id>(sofToBeCloned.keySet()), params);
            JQH_JobManager.queueJob(job, true);

            Test.stopTest();

            //Check sof were cloned
            String sofClonedSoql = 'SELECT ' + String.join(sofFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId';
            String sseClonedSoql = 'SELECT ' + String.join(sseFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Session__c WHERE reduivy__Study_Offering__c IN: clonedSofs';
            String sstClonedSoql = 'SELECT ' + String.join(sstFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Study_Session__c IN: clonedSses';

            List<reduivy__Study_Offering__c> clonedSofs = (List<reduivy__Study_Offering__c>) Database.query(sofClonedSoql);
            List<reduivy__Study_Session__c> clonedSses = (List<reduivy__Study_Session__c>) Database.query(sseClonedSoql);
            List<reduivy__Study_Session_Time__c> cloneSsts = (List<reduivy__Study_Session_Time__c>) Database.query(sstClonedSoql);

            System.Assert.areEqual(sofToBeCloned.keySet().size(), clonedSofs.size(), 'All study offerings should have cloned');
            System.Assert.areEqual(0, clonedSses.size(), 'Study session should not be cloned');
            System.Assert.areEqual(0, cloneSsts.size(), 'Study session time should not be cloned');

            for (reduivy__Study_Offering__c clonedSof : clonedSofs) {
                System.Assert.isTrue(String.isNotBlank(clonedSof.reduivy__Clone_From_Id__c), 'The clone from id should not be blank.');
                System.Assert.isTrue(sofToBeCloned.containsKey(clonedSof.reduivy__Clone_From_Id__c), 'The record is not part of the records to be cloned.');

                reduivy__Study_Offering__c sourceSof = sofToBeCloned.get(clonedSof.reduivy__Clone_From_Id__c);

                for (String field : sofFields) {
                    if (field != 'reduivy__Academic_Term__c') {
                        if(field != 'Name') {
                            System.Assert.areEqual(sourceSof.get(field), clonedSof.get(field), field + ' is not the same.');
                        } else {
                            System.Assert.areNotEqual(sourceSof.get(field), clonedSof.get(field), field + ' should not be the same.');
                        }
                    }
                }
            }

            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Number_of_Success_Records__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.areEqual(sofToBeCloned.keySet().size(), jobQueueCheckList[0].reduivy__Number_of_Success_Records__c, 'All study offerings should have successfully cloned');
        }
    }

    /**
     * @description Test the term offerings cloning job through the Handler cloneStudySessionOption = false
     */
    @IsTest
    static void testTermOfferingsCloningJobFromHandlerWithoutSession(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            Set<String> sofFields = SOF_Helper.getFieldsForCloning();
            Set<String> sseFields = SSE_Helper.getFieldsForCloning();
            Set<String> sstFields = SST_Helper.getFieldsForCloning();

            Set<String> sofFieldsForQuery = SOF_Helper.getFieldsForCloning();
            sofFieldsForQuery.add('Id');
            sofFieldsForQuery.add('reduivy__Academic_Term__r.Name');
            sofFieldsForQuery.add('reduivy__Academic_Term__r.reduivy__Alternate_Name__c');

            String sofSoql = 'SELECT ' + String.join(sofFieldsForQuery, ', ') + 
                ' FROM reduivy__Study_Offering__c ' +
                ' WHERE reduivy__Status__c IN :sofStatusesSet ';
            
            List<reduivy__Study_Offering__c> sofs = (List<reduivy__Study_Offering__c>) Database.query(sofSoql);
            Map<Id, reduivy__Study_Offering__c> sofToBeCloned = new Map<Id, reduivy__Study_Offering__c>();
            
            System.Assert.isTrue(sofs.size() > 0, 'No study offering found');

            Set<Id> sunIds = new Set<Id>();

            String term = '';
            String campus = '';

            String selectedTermName = sofs[0].reduivy__Academic_Term__r.Name;
            String selectedTermAlternateName = sofs[0].reduivy__Academic_Term__r.reduivy__Alternate_Name__c;

            for(reduivy__Study_Offering__c sof : sofs){
                if(String.isBlank(term)) {
                    term = sof.reduivy__Academic_Term__c;
                }

                if(String.isBlank(campus)) {
                    campus = sof.reduivy__Campus__c;
                }

                if(sof.reduivy__Academic_Term__c == term) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                    sofToBeCloned.put(sof.Id, sof);
                }
            }

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, Name, reduivy__Alternate_Name__c
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                AND reduivy__Sample_Record_Code__c = :CYT2Key
                LIMIT 1
            ];

            Id currentTermId = stm[0].Id;

            String currentTermName = stm[0].Name;
            String currentTermAlternateName = stm[0].reduivy__Alternate_Name__c;

            Map<String, String> textsToBeReplaced = new Map<String, String>();
            textsToBeReplaced.put(selectedTermName, currentTermName);
            textsToBeReplaced.put(selectedTermAlternateName, currentTermAlternateName);

            delete [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId];

            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, stm[0].Name);

            params.put('currentTermId', currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, currentTermId));

            params.put('cloneStudySessionOption', 'false');
            params.put('selectedRetainStudyOfferingNameOption', 'true');
            params.put('selectedRetainStudySessionNameOption', 'true');

            params.put('textsToBeReplaced', JSON.serialize(textsToBeReplaced));

            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, new List<Id>(sofToBeCloned.keySet()), params);
            JQH_JobManager.queueJob(job, true);

            Test.stopTest();

            //Check sof were cloned
            String sofClonedSoql = 'SELECT ' + String.join(sofFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId';
            String sseClonedSoql = 'SELECT ' + String.join(sseFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Session__c WHERE reduivy__Study_Offering__c IN: clonedSofs';
            String sstClonedSoql = 'SELECT ' + String.join(sstFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Study_Session__c IN: clonedSses';

            List<reduivy__Study_Offering__c> clonedSofs = (List<reduivy__Study_Offering__c>) Database.query(sofClonedSoql);
            List<reduivy__Study_Session__c> clonedSses = (List<reduivy__Study_Session__c>) Database.query(sseClonedSoql);
            List<reduivy__Study_Session_Time__c> cloneSsts = (List<reduivy__Study_Session_Time__c>) Database.query(sstClonedSoql);

            System.Assert.areEqual(sofToBeCloned.keySet().size(), clonedSofs.size(), 'All study offerings should have cloned');
            System.Assert.areEqual(0, clonedSses.size(), 'Study session should not be cloned');
            System.Assert.areEqual(0, cloneSsts.size(), 'Study session time should not be cloned');

            for (reduivy__Study_Offering__c clonedSof : clonedSofs) {
                System.Assert.isTrue(String.isNotBlank(clonedSof.reduivy__Clone_From_Id__c), 'The clone from id should not be blank.');
                System.Assert.isTrue(sofToBeCloned.containsKey(clonedSof.reduivy__Clone_From_Id__c), 'The record is not part of the records to be cloned.');

                reduivy__Study_Offering__c sourceSof = sofToBeCloned.get(clonedSof.reduivy__Clone_From_Id__c);

                for (String field : sofFields) {
                    if (field != 'reduivy__Academic_Term__c') {
                        System.Assert.areEqual(sourceSof.get(field), clonedSof.get(field), field + ' is not the same.');
                    }
                }
            }

            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Number_of_Success_Records__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.areEqual(sofToBeCloned.keySet().size(), jobQueueCheckList[0].reduivy__Number_of_Success_Records__c, 'All study offerings should have successfully cloned');
        }
    }

    /**
     * @description Test the term offerings cloning job through the Handler with cloneStudySessionOption = true
     */
    @IsTest
    static void testTermOfferingsCloningJobFromHandlerWithSessionsWithRetainName(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            Set<String> sofFields = SOF_Helper.getFieldsForCloning();
            Set<String> sseFields = SSE_Helper.getFieldsForCloning();
            Set<String> sstFields = SST_Helper.getFieldsForCloning();

            Set<String> sofFieldsForQuery = SOF_Helper.getFieldsForCloning();
            sofFieldsForQuery.add('Id');
            sofFieldsForQuery.add('reduivy__Academic_Term__r.Name');
            sofFieldsForQuery.add('reduivy__Academic_Term__r.reduivy__Alternate_Name__c');

            Set<String> sseFieldsForQuery = SSE_Helper.getFieldsForCloning();
            sseFieldsForQuery.add('Id');

            Set<String> sstFieldsForQuery = SST_Helper.getFieldsForCloning();
            sstFieldsForQuery.add('Id');

            String sofSoql = 'SELECT ' + String.join(sofFieldsForQuery, ', ') + 
                ' FROM reduivy__Study_Offering__c ' +
                ' WHERE reduivy__Status__c IN :sofStatusesSet ' +
                ' AND reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = :CYT1Key';
            
            List<reduivy__Study_Offering__c> sofs = (List<reduivy__Study_Offering__c>) Database.query(sofSoql);
            Map<Id, reduivy__Study_Offering__c> sofToBeCloned = new Map<Id, reduivy__Study_Offering__c>();
            
            System.Assert.isTrue(sofs.size() > 0, 'No study offering found');

            Set<Id> sunIds = new Set<Id>();

            String term = '';
            String campus = '';

            String selectedTermName = sofs[0].reduivy__Academic_Term__r.Name;
            String selectedTermAlternateName = sofs[0].reduivy__Academic_Term__r.reduivy__Alternate_Name__c;

            List<reduivy__Study_Offering__c> sofsToBeUpdated = new List<reduivy__Study_Offering__c>();

            for(reduivy__Study_Offering__c sof : sofs){
                reduivy__Study_Offering__c tempSof = sof.clone();

                tempSof.Id = sof.Id;
                tempSof.Name = sof.Name + '_' + selectedTermName + '_' + selectedTermAlternateName;

                sofsToBeUpdated.add(tempSof);
            }

            update sofsToBeUpdated;

            for(reduivy__Study_Offering__c sof : sofsToBeUpdated){
                if(String.isBlank(term)) {
                    term = sof.reduivy__Academic_Term__c;
                }

                if(String.isBlank(campus)) {
                    campus = sof.reduivy__Campus__c;
                }

                if(sof.reduivy__Academic_Term__c == term) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                    sofToBeCloned.put(sof.Id, sof);
                }
            }

            Set<Id> sofIdsForCloning = sofToBeCloned.keySet();
            String sseSoql = 'SELECT ' + String.join(sseFieldsForQuery, ', ') + ' FROM reduivy__Study_Session__c WHERE reduivy__Study_Offering__c IN: sofIdsForCloning';
            String sstSoql = 'SELECT ' + String.join(sstFieldsForQuery, ', ') + ' FROM reduivy__Study_Session_Time__c WHERE reduivy__Study_Session__r.reduivy__Study_Offering__c IN: sofIdsForCloning';

            Map<Id, reduivy__Study_Session__c> sseToBeCloned = new Map<Id, reduivy__Study_Session__c>((List<reduivy__Study_Session__c>) Database.query(sseSoql));
            Map<Id, reduivy__Study_Session_Time__c> sstToBeCloned = new Map<Id, reduivy__Study_Session_Time__c>((List<reduivy__Study_Session_Time__c>) Database.query(sstSoql));

            System.Assert.isTrue(sseToBeCloned.size() > 0, 'No study session found');
            System.Assert.isTrue(sstToBeCloned.size() > 0, 'No study session time found');

            List<reduivy__Study_Session__c> ssesToBeUpdated = new List<reduivy__Study_Session__c>();

            for(reduivy__Study_Session__c sse : sseToBeCloned.values()){
                reduivy__Study_Session__c tempSse = sse.clone();

                tempSse.Id = sse.Id;
                tempSse.Name = sse.Name + '_' + selectedTermName + '_' + selectedTermAlternateName;

                ssesToBeUpdated.add(tempSse);
                sseToBeCloned.put(sse.Id, tempSse);
            }

            update ssesToBeUpdated;

            List<reduivy__Study_Session_Time__c> sstsToBeUpdated = new List<reduivy__Study_Session_Time__c>();

            for(reduivy__Study_Session_Time__c sst : sstToBeCloned.values()){
                reduivy__Study_Session_Time__c tempSst = sst.clone();

                tempSst.Id = sst.Id;
                tempSst.Name = sst.Name + '_' + selectedTermName + '_' + selectedTermAlternateName;

                sstsToBeUpdated.add(tempSst);
                sstToBeCloned.put(sst.Id, tempSst);
            }

            update sstsToBeUpdated;

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, Name, reduivy__Alternate_Name__c
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                AND reduivy__Sample_Record_Code__c = :CYT2Key
                LIMIT 1
            ];

            Id currentTermId = stm[0].Id;

            String currentTermName = stm[0].Name;
            String currentTermAlternateName = stm[0].reduivy__Alternate_Name__c;

            Map<String, String> textsToBeReplaced = new Map<String, String>();
            textsToBeReplaced.put(selectedTermName, currentTermName);
            textsToBeReplaced.put(selectedTermAlternateName, currentTermAlternateName);

            delete [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId];

            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, stm[0].Name);

            params.put('currentTermId', currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, currentTermId));

            params.put('cloneStudySessionOption', 'true');
            params.put('selectedRetainStudyOfferingNameOption', 'true');
            params.put('selectedRetainStudySessionNameOption', 'true');

            params.put('textsToBeReplaced', JSON.serialize(textsToBeReplaced));

            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, new List<Id>(sofToBeCloned.keySet()), params);
            JQH_JobManager.queueJob(job, true);

            Test.stopTest();

            //Check sof were cloned
            String sofClonedSoql = 'SELECT ' + String.join(sofFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId';
            String sseClonedSoql = 'SELECT ' + String.join(sseFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Session__c WHERE reduivy__Study_Offering__c IN: clonedSofs';
            String sstClonedSoql = 'SELECT ' + String.join(sstFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Study_Session__c IN: clonedSses';

            List<reduivy__Study_Offering__c> clonedSofs = (List<reduivy__Study_Offering__c>) Database.query(sofClonedSoql);
            List<reduivy__Study_Session__c> clonedSses = (List<reduivy__Study_Session__c>) Database.query(sseClonedSoql);
            List<reduivy__Study_Session_Time__c> clonedSsts = (List<reduivy__Study_Session_Time__c>) Database.query(sstClonedSoql);

            System.Assert.areEqual(sofToBeCloned.keySet().size(), clonedSofs.size(), 'All study offerings should have cloned');
            System.Assert.areEqual(sseToBeCloned.keySet().size(), clonedSses.size(), 'All Study session should have cloned');
            System.Assert.areEqual(sstToBeCloned.keySet().size(), clonedSsts.size(), 'All Study session time should have cloned');

            for (reduivy__Study_Offering__c clonedSof : clonedSofs) {
                System.Assert.isTrue(String.isNotBlank(clonedSof.reduivy__Clone_From_Id__c), 'The clone from id should not be blank.');
                System.Assert.isTrue(sofToBeCloned.containsKey(clonedSof.reduivy__Clone_From_Id__c), 'The record is not part of the records to be cloned.');

                reduivy__Study_Offering__c sourceSof = sofToBeCloned.get(clonedSof.reduivy__Clone_From_Id__c);

                for (String field : sofFields) {
                    if (field != 'reduivy__Academic_Term__c') {
                        System.Assert.areEqual(sourceSof.get(field), clonedSof.get(field), field + ' is not the same.');
                    }
                }
            }

            for (reduivy__Study_Session__c clonedSse : clonedSses) {
                System.Assert.isTrue(String.isNotBlank(clonedSse.reduivy__Clone_From_Id__c), 'The clone from id should not be blank.');
                System.Assert.isTrue(sseToBeCloned.containsKey(clonedSse.reduivy__Clone_From_Id__c), 'The record is not part of the records to be cloned.');

                reduivy__Study_Session__c sourceSse = sseToBeCloned.get(clonedSse.reduivy__Clone_From_Id__c);

                for (String field : sseFields) {
                    if (field != 'reduivy__Study_Offering__c') {
                        System.Assert.areEqual(sourceSse.get(field), clonedSse.get(field), field + ' is not the same.');
                    }
                }
            }

            for (reduivy__Study_Session_Time__c clonedSst : clonedSsts) {
                System.Assert.isTrue(String.isNotBlank(clonedSst.reduivy__Clone_From_Id__c), 'The clone from id should not be blank.');
                System.Assert.isTrue(sstToBeCloned.containsKey(clonedSst.reduivy__Clone_From_Id__c), 'The record is not part of the records to be cloned.');

                reduivy__Study_Session_Time__c sourceSst = sstToBeCloned.get(clonedSst.reduivy__Clone_From_Id__c);

                for (String field : sstFields) {
                    if (field != 'reduivy__Study_Session__c') {
                        System.Assert.areEqual(sourceSst.get(field), clonedSst.get(field), field + ' is not the same.');
                    }
                }
            }

            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Number_of_Success_Records__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.areEqual(sofToBeCloned.keySet().size(), jobQueueCheckList[0].reduivy__Number_of_Success_Records__c, 'All study offerings should have successfully cloned');
        }
    }

    /**
     * @description Test the term offerings cloning job through the Handler with cloneStudySessionOption = true
     */
    @IsTest
    static void testTermOfferingsCloningJobFromHandlerWithSessionsWithRenameName(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            Set<String> sofFields = SOF_Helper.getFieldsForCloning();
            Set<String> sseFields = SSE_Helper.getFieldsForCloning();
            Set<String> sstFields = SST_Helper.getFieldsForCloning();

            Set<String> sofFieldsForQuery = SOF_Helper.getFieldsForCloning();
            sofFieldsForQuery.add('Id');
            sofFieldsForQuery.add('reduivy__Academic_Term__r.Name');
            sofFieldsForQuery.add('reduivy__Academic_Term__r.reduivy__Alternate_Name__c');

            Set<String> sseFieldsForQuery = SSE_Helper.getFieldsForCloning();
            sseFieldsForQuery.add('Id');

            Set<String> sstFieldsForQuery = SST_Helper.getFieldsForCloning();
            sstFieldsForQuery.add('Id');

            String sofSoql = 'SELECT ' + String.join(sofFieldsForQuery, ', ') + 
                ' FROM reduivy__Study_Offering__c ' +
                ' WHERE reduivy__Status__c IN :sofStatusesSet ' +
                ' AND reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c = :CYT1Key';
            
            List<reduivy__Study_Offering__c> sofs = (List<reduivy__Study_Offering__c>) Database.query(sofSoql);
            Map<Id, reduivy__Study_Offering__c> sofToBeCloned = new Map<Id, reduivy__Study_Offering__c>();
            
            System.Assert.isTrue(sofs.size() > 0, 'No study offering found');

            Set<Id> sunIds = new Set<Id>();

            String term = '';
            String campus = '';

            String selectedTermName = sofs[0].reduivy__Academic_Term__r.Name;
            String selectedTermAlternateName = sofs[0].reduivy__Academic_Term__r.reduivy__Alternate_Name__c;

            List<reduivy__Study_Offering__c> sofsToBeUpdated = new List<reduivy__Study_Offering__c>();

            for(reduivy__Study_Offering__c sof : sofs){
                reduivy__Study_Offering__c tempSof = sof.clone();

                tempSof.Id = sof.Id;
                tempSof.Name = sof.Name + '_' + selectedTermName + '_' + selectedTermAlternateName;

                sofsToBeUpdated.add(tempSof);
            }

            update sofsToBeUpdated;

            for(reduivy__Study_Offering__c sof : sofsToBeUpdated){
                if(String.isBlank(term)) {
                    term = sof.reduivy__Academic_Term__c;
                }

                if(String.isBlank(campus)) {
                    campus = sof.reduivy__Campus__c;
                }

                if(sof.reduivy__Academic_Term__c == term) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                    sofToBeCloned.put(sof.Id, sof);
                }
            }

            Set<Id> sofIdsForCloning = sofToBeCloned.keySet();
            String sseSoql = 'SELECT ' + String.join(sseFieldsForQuery, ', ') + ' FROM reduivy__Study_Session__c WHERE reduivy__Study_Offering__c IN: sofIdsForCloning';
            String sstSoql = 'SELECT ' + String.join(sstFieldsForQuery, ', ') + ' FROM reduivy__Study_Session_Time__c WHERE reduivy__Study_Session__r.reduivy__Study_Offering__c IN: sofIdsForCloning';

            Map<Id, reduivy__Study_Session__c> sseToBeCloned = new Map<Id, reduivy__Study_Session__c>((List<reduivy__Study_Session__c>) Database.query(sseSoql));
            Map<Id, reduivy__Study_Session_Time__c> sstToBeCloned = new Map<Id, reduivy__Study_Session_Time__c>((List<reduivy__Study_Session_Time__c>) Database.query(sstSoql));

            System.Assert.isTrue(sseToBeCloned.size() > 0, 'No study session found');
            System.Assert.isTrue(sstToBeCloned.size() > 0, 'No study session time found');

            List<reduivy__Study_Session__c> ssesToBeUpdated = new List<reduivy__Study_Session__c>();

            for(reduivy__Study_Session__c sse : sseToBeCloned.values()){
                reduivy__Study_Session__c tempSse = sse.clone();

                tempSse.Id = sse.Id;
                tempSse.Name = sse.Name + '_' + selectedTermName + '_' + selectedTermAlternateName;

                ssesToBeUpdated.add(tempSse);
                sseToBeCloned.put(sse.Id, tempSse);
            }

            update ssesToBeUpdated;

            List<reduivy__Study_Session_Time__c> sstsToBeUpdated = new List<reduivy__Study_Session_Time__c>();

            for(reduivy__Study_Session_Time__c sst : sstToBeCloned.values()){
                reduivy__Study_Session_Time__c tempSst = sst.clone();

                tempSst.Id = sst.Id;
                tempSst.Name = sst.Name + '_' + selectedTermName + '_' + selectedTermAlternateName;

                sstsToBeUpdated.add(tempSst);
                sstToBeCloned.put(sst.Id, tempSst);
            }

            update sstsToBeUpdated;

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, Name, reduivy__Alternate_Name__c
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                AND reduivy__Sample_Record_Code__c = :CYT2Key
                LIMIT 1
            ];

            Id currentTermId = stm[0].Id;

            String currentTermName = stm[0].Name;
            String currentTermAlternateName = stm[0].reduivy__Alternate_Name__c;

            Map<String, String> textsToBeReplaced = new Map<String, String>();
            textsToBeReplaced.put(selectedTermName, currentTermName);
            textsToBeReplaced.put(selectedTermAlternateName, currentTermAlternateName);

            delete [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId];

            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, stm[0].Name);

            params.put('currentTermId', currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, currentTermId));

            params.put('cloneStudySessionOption', 'true');
            params.put('selectedRetainStudyOfferingNameOption', 'true');
            params.put('selectedRetainStudySessionNameOption', 'false');

            params.put('textsToBeReplaced', JSON.serialize(textsToBeReplaced));

            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, new List<Id>(sofToBeCloned.keySet()), params);
            JQH_JobManager.queueJob(job, true);

            Test.stopTest();

            //Check sof were cloned
            String sofClonedSoql = 'SELECT ' + String.join(sofFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId';
            String sseClonedSoql = 'SELECT ' + String.join(sseFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Session__c WHERE reduivy__Study_Offering__c IN: clonedSofs';
            String sstClonedSoql = 'SELECT ' + String.join(sstFields, ', ') + ', reduivy__Clone_From_Id__c FROM reduivy__Study_Session_Time__c WHERE reduivy__Study_Session__c IN: clonedSses';

            List<reduivy__Study_Offering__c> clonedSofs = (List<reduivy__Study_Offering__c>) Database.query(sofClonedSoql);
            List<reduivy__Study_Session__c> clonedSses = (List<reduivy__Study_Session__c>) Database.query(sseClonedSoql);
            List<reduivy__Study_Session_Time__c> clonedSsts = (List<reduivy__Study_Session_Time__c>) Database.query(sstClonedSoql);

            System.Assert.areEqual(sofToBeCloned.keySet().size(), clonedSofs.size(), 'All study offerings should have cloned');
            System.Assert.areEqual(sseToBeCloned.keySet().size(), clonedSses.size(), 'All Study session should have cloned');
            System.Assert.areEqual(sstToBeCloned.keySet().size(), clonedSsts.size(), 'All Study session time should have cloned');

            for (reduivy__Study_Offering__c clonedSof : clonedSofs) {
                System.Assert.isTrue(String.isNotBlank(clonedSof.reduivy__Clone_From_Id__c), 'The clone from id should not be blank.');
                System.Assert.isTrue(sofToBeCloned.containsKey(clonedSof.reduivy__Clone_From_Id__c), 'The record is not part of the records to be cloned.');

                reduivy__Study_Offering__c sourceSof = sofToBeCloned.get(clonedSof.reduivy__Clone_From_Id__c);

                for (String field : sofFields) {
                    if (field != 'reduivy__Academic_Term__c') {
                        System.Assert.areEqual(sourceSof.get(field), clonedSof.get(field), field + ' is not the same.');
                    }
                }
            }

            for (reduivy__Study_Session__c clonedSse : clonedSses) {
                System.Assert.isTrue(String.isNotBlank(clonedSse.reduivy__Clone_From_Id__c), 'The clone from id should not be blank.');
                System.Assert.isTrue(sseToBeCloned.containsKey(clonedSse.reduivy__Clone_From_Id__c), 'The record is not part of the records to be cloned.');

                reduivy__Study_Session__c sourceSse = sseToBeCloned.get(clonedSse.reduivy__Clone_From_Id__c);

                for (String field : sseFields) {
                    if (field != 'reduivy__Study_Offering__c') {
                        if(field != 'Name') {
                            System.Assert.areEqual(sourceSse.get(field), clonedSse.get(field), field + ' is not the same.');
                        } else {
                            System.Assert.areNotEqual(sourceSse.get(field), clonedSse.get(field), field + ' should not be the same.');
                        }

                    }
                }
            }

            for (reduivy__Study_Session_Time__c clonedSst : clonedSsts) {
                System.Assert.isTrue(String.isNotBlank(clonedSst.reduivy__Clone_From_Id__c), 'The clone from id should not be blank.');
                System.Assert.isTrue(sstToBeCloned.containsKey(clonedSst.reduivy__Clone_From_Id__c), 'The record is not part of the records to be cloned.');

                reduivy__Study_Session_Time__c sourceSst = sstToBeCloned.get(clonedSst.reduivy__Clone_From_Id__c);

                for (String field : sstFields) {
                    if (field != 'reduivy__Study_Session__c') {
                        if(field != 'Name') {
                            System.Assert.areEqual(sourceSst.get(field), clonedSst.get(field), field + ' is not the same.');
                        } else {
                            System.Assert.areNotEqual(sourceSst.get(field), clonedSst.get(field), field + ' should not be the same.');
                        }
                    }
                }
            }

            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Number_of_Success_Records__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.areEqual(sofToBeCloned.keySet().size(), jobQueueCheckList[0].reduivy__Number_of_Success_Records__c, 'All study offerings should have successfully cloned');
        }
    }

    /**
     * @description Test the term offerings cloning job through the Handler without 'currentTermId' parameter passed
     */
    @IsTest
    static void negativeTestTermOfferingsCloningJobFromHandler(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            String studyOfferingStatuses = 'Draft;Not Started;Pre-enrollment Opened;Enrollment Opened;Enrollment Closed;Running (Enrollment Opened);Running;Completed';

            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            List<reduivy__Study_Offering__c> sofs = [
                SELECT reduivy__Study_Unit__c, 
                reduivy__Academic_Term__c, 
                reduivy__Campus__c 
                FROM reduivy__Study_Offering__c 
                WHERE reduivy__Status__c IN :sofStatusesSet 
            ];
            
            Set<Id> sunIds = new Set<Id>();
            Set<Id> sofIds = new Set<Id>();

            String term = '';
            String campus = '';

            for(reduivy__Study_Offering__c sof : sofs){
                if(String.isBlank(term)) {
                    term = sof.reduivy__Academic_Term__c;
                }

                if(String.isBlank(campus)) {
                    campus = sof.reduivy__Campus__c;
                }

                if(sof.reduivy__Academic_Term__c == term) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                    sofIds.add(sof.Id);
                }
            }

            List<reduivy__Study_Term__c> stm = [
                SELECT Id, Name
                FROM reduivy__Study_Term__c 
                WHERE RecordTypeId = :ACADEMIC_TERM_RECORD_TYPE_ID
                AND reduivy__Sample_Record_Code__c = :CYT2Key
                LIMIT 1
            ];

            Id currentTermId = stm[0].Id;

            delete [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId];

            Map<String, Object> params = new Map<String, Object>();
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, stm[0].Name);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(JOB_OPERATION, currentTermId));
            
            JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(JOB_OPERATION, new List<Id>(sofIds), params);
            JQH_JobManager.queueJob(job, true);

            Test.stopTest();

            //Check sof were cloned
            List<reduivy__Study_Offering__c> clonedSofs = [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Academic_Term__c = :currentTermId];
            System.Assert.areEqual(0, clonedSofs.size(), 'All study offerings should have failed to clone.');

            List<reduivy__Job_Queue__c> jobQueueCheckList = [
                SELECT Id, reduivy__Number_of_Error_Records__c
                FROM reduivy__Job_Queue__c
                WHERE reduivy__Job_Operation__c = :JOB_OPERATION
            ];

            System.Assert.areEqual(sofIds.size(), jobQueueCheckList[0].reduivy__Number_of_Error_Records__c, 'All study offerings should have encountered a validation rules error due to a missing term.');
        
            List<reduivy__Log__c> logsList = [SELECT Id FROM reduivy__Log__c WHERE reduivy__Record_Id__c IN :sofIds];
            System.Assert.areEqual(sofIds.size(), logsList.size(), 'All study offerings should have encountered a validation rules error due to a missing term.');
        }
    }
}