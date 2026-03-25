/**
 * @author      WDCi (CM)
 * @date        Aug 2024
 * @group       Grade Management
 * @description Test class for REDU_StudentGradingRegistry_LCTRL
 * @changehistory
 * ISS-001918 28-08-2024 CM - new class
 * ISS-002259 21-03-2025 Jordan - getFields() tests
 */
@isTest
public inherited sharing class REDU_StudentGradingRegistry_TEST {
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static Set<String> igiFields = new Set<String>{'reduivy__Notes__c'}; //ISS-002259

    static final String IEN_INPROGRESS_STATUSES = String.join(IEN_Helper.getInProgressStatuses(), ';');
    static final String ISN_INPROGRESS_STATUSES = String.join(ISN_Helper.getInProgressStatuses(), ';');

    static final String sseGradedSofSampleCode = 'BUS101_CYT1_SYDNEY';
    static final String sofGradedSofSampleCode = 'BUS102_CYT1_SYDNEY';
    static final String sseGradedSseSampleCode = 'Lecture_BUS101_CYT1_SYDNEY';

    static String IEN_INPROGRESS_STATUS = IEN_Helper.getInProgressStatuses().get(0);
    static String ISN_INPROGRESS_STATUS = ISN_Helper.getInProgressStatuses().get(0);

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
            testFactory.initMasterData(SGI_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(IEN_Helper.getApiName(), false);

            //find student idv enrollment status = enrolled, select first studyOfferingId for each student
            Map<reduivy__Individual_Enrollment__c, reduivy__Study_Offering__c> idvEnrollWithStudyOffer = new Map<reduivy__Individual_Enrollment__c, reduivy__Study_Offering__c>();
            Set<Id> studentIds = new Set<Id>();

            for(reduivy__Individual_Enrollment__c idvEnroll : testFactory.studentIndividualEnrollments.values()){
                if(idvEnroll.reduivy__Enrollment_Status__c == IEN_INPROGRESS_STATUS && idvEnroll.RecordTypeId == IEN_Helper.getStudentRecordTypeId() && !studentIds.contains(idvEnroll.reduivy__Contact__c)){
                    
                    for(reduivy__Study_Offering__c so : testFactory.studyOfferings.values()){
                        if(so.Id == idvEnroll.reduivy__Study_Offering__c){
                            idvEnrollWithStudyOffer.put(idvEnroll, so);
                            studentIds.add(idvEnroll.reduivy__Contact__c);
                        }
                    }

                }
            }

            //enroll students into Lecture study session (create student session enrollment)
            Map<String, reduivy__Individual_Session_Enrollment__c> studentIndividualSessionEnrollments = new Map<String, reduivy__Individual_Session_Enrollment__c>();

            for(reduivy__Individual_Enrollment__c idvEnroll : idvEnrollWithStudyOffer.keySet()){
                for(reduivy__Study_Session__c ss : testFactory.studySessions.values()){
                    if(ss.reduivy__Study_Offering__c == idvEnrollWithStudyOffer.get(idvEnroll).Id && ss.reduivy__Type__c == 'Lecture'){
                        String isnSampleRecord = ss.Name + '_' + idvEnroll.reduivy__Sample_Record_Code__c;
                        studentIndividualSessionEnrollments.put(isnSampleRecord, REDU_TestData_UTIL.newStudentIndividualSessionEnrollment(isnSampleRecord, ss.Id, idvEnroll.Id, ss.reduivy__Start_Date__c, ISN_INPROGRESS_STATUS));
                    }
                }
            }

            REDU_SystemMode_UTIL.doInsert(studentIndividualSessionEnrollments.values());

            if (!testFactory.studyEvents.isEmpty()) {
                //create study event relation for student
                //Map studySessionId + IndividualSessionEnrollment (Map 1) --- match studySessionId
                Map<Id, List<reduivy__Individual_Session_Enrollment__c>> ssIdWithIsnList = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();
                for(reduivy__Individual_Session_Enrollment__c isn : studentIndividualSessionEnrollments.values()){
                    if(isn.RecordTypeId == ISN_Helper.getStudentRecordTypeId()){
                        if (ssIdWithIsnList.containsKey(isn.reduivy__Study_Session__c)) {
                            ssIdWithIsnList.get(isn.reduivy__Study_Session__c).add(isn);
                        } else {
                            ssIdWithIsnList.put(isn.reduivy__Study_Session__c, new List<reduivy__Individual_Session_Enrollment__c>{isn});
                        }
                    }
                }
    
                //Map studySessionTimeId + studySessionId -> Map studySessionId + StudyEvent (Map 2)
                Map<Id, Id> sstIdWithSsId = new Map<Id, Id>();
                for(reduivy__Study_Session_Time__c sst : testFactory.studySessionTimes.values()){
                    sstIdWithSsId.put(sst.Id, sst.reduivy__Study_Session__c);
                }
    
                Map<Id, List<reduivy__Study_Event__c>> ssIdWithSe = new Map<Id, List<reduivy__Study_Event__c>>();
                for(reduivy__Study_Event__c se : testFactory.studyEvents.values()){
                    Id ssId = sstIdWithSsId.get(se.reduivy__Study_Session_Time__c);
                    if(ssId != null){
                        if(!ssIdWithSe.containsKey(ssId)){
                            ssIdWithSe.put(ssId, new List<reduivy__Study_Event__c>());
                        }
                        ssIdWithSe.get(ssId).add(se);
                    }
                }
    
                //match studySessionId Map 1 and Map 2 (for create study event relations)
                Map<Id, reduivy__Individual_Enrollment__c> iensMapById = new Map<Id, reduivy__Individual_Enrollment__c>(testFactory.studentIndividualEnrollments.values());
                Map<String, reduivy__Study_Event_Relation__c> studentStudyEventRelations = new Map<String, reduivy__Study_Event_Relation__c>();
                
                for(Id ssId : ssIdWithIsnList.keySet()){
                    if(ssIdWithSe.containsKey(ssId)){
                        List<reduivy__Study_Event__c> seList = ssIdWithSe.get(ssId);
                        List<reduivy__Individual_Session_Enrollment__c> isnList = ssIdWithIsnList.get(ssId);
                        for (reduivy__Individual_Session_Enrollment__c isn : isnList) {
                            for(reduivy__Study_Event__c se : seList){
                                DateTime startDt = se.reduivy__Start__c;
                                DateTime endDt = se.reduivy__End__c;
                                
                                if(endDt.date() <= System.today()){
                                    Time checkInTime = startDt.time();
                                    Time checkOutTime = endDt.time();
                                    String attendStatus = 'Attended';
                                    String serSampleRecord = isn.reduivy__Sample_Record_Code__c + '_' + se.reduivy__Sample_Record_Code__c;
                                    studentStudyEventRelations.put(serSampleRecord, REDU_TestData_UTIL.newStudentStudyEventRelation(serSampleRecord, iensMapById.get(isn.reduivy__Individual_Enrollment__c).reduivy__Contact__c, se.Id, isn.Id, checkInTime, checkOutTime, attendStatus));
                                }
                            }
                        }
                    }
                }
    
                REDU_SystemMode_UTIL.doInsert(studentStudyEventRelations.values());
            }

            Test.stopTest();

            //Set one of the Study Offerings to be graded by Study Offering
            reduivy__Study_Offering__c sofGradeStudyOffering = [
                SELECT Id, 
                reduivy__Grade_By__c, 
                reduivy__Sample_Record_Code__c
                FROM reduivy__Study_Offering__c
                WHERE reduivy__Sample_Record_Code__c = :sofGradedSofSampleCode
            ];
            sofGradeStudyOffering.reduivy__Grade_By__c = SOF_Helper.GRADE_BY_STUDYOFFERING;
            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Study_Offering__c>{sofGradeStudyOffering});

        }

    }

    /**
     * @description ISS-002259 Test get fields as admin
     */
    @IsTest
    static void testForAdminGetFields(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        System.runAs(ADMIN_USER){
            REDU_LightningResponse response = REDU_StudentGradingRegistry_LCTRL.getFields('reduivy__GradingWizard_Notes', 'reduivy__Individual_Grade_Item__c');
            System.Assert.areEqual(true, response.isSuccess);
            
            List<REDU_DynamicFieldValue_OBJ> fields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);
            for (REDU_DynamicFieldValue_OBJ field : fields) {
                System.Assert.isTrue(igiFields.contains(field.fieldName));
            }
            
        }
        Test.stopTest();
        
    }

    /**
     * @description Test as admin loading a Study Offering record
     */
    @isTest
    static void testForAdminSofGetGradingData() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //Get Study Offering
        reduivy__Study_Offering__c sof = [
            SELECT Id, 
            Name, 
            reduivy__Study_Grade_Setting__c, 
            reduivy__Study_Unit__c, 
            reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
            reduivy__Academic_Term__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Sample_Record_Code__c = :sofGradedSofSampleCode
        ];
        //Get students enrolled in the Study Offering
        List<reduivy__Individual_Enrollment__c> studentIenList = [
            SELECT Id, 
            reduivy__Study_Grade_Setting__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sof.Id 
            AND RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ];
        System.Assert.isFalse(studentIenList.isEmpty(), 'No students enrolled in Study Offering');
        //Get Study Grade Items
        Map<Id, reduivy__Study_Grade_Item__c> sgiMap = new Map<Id, reduivy__Study_Grade_Item__c>([
            SELECT Id, 
            Name, 
            reduivy__Display_Type__c
            FROM reduivy__Study_Grade_Item__c
            WHERE reduivy__Study_Unit__c = :sof.reduivy__Study_Unit__c
        ]);
        System.Assert.isFalse(sgiMap.isEmpty(), 'No Study Grade Items');
        //Get Study Grade Period
        reduivy__Study_Grade_Period_Setting__c defaultSgp = [
            SELECT Id 
            FROM reduivy__Study_Grade_Period_Setting__c
            WHERE reduivy__Academic_Term__c = :sof.reduivy__Academic_Term__c
            AND reduivy__Type__c = 'Final Grade'
        ];
        //Get Study Grading Schemes (based on Study Grade Setting from student individual enrollments)
        Set<Id> studyGradeSettingIds = new Set<Id>();
        Id defaultStudyGradeSetting = String.isNotBlank(sof.reduivy__Study_Grade_Setting__c)
                                    ? sof.reduivy__Study_Grade_Setting__c
                                    : sof.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c;
        studyGradeSettingIds.add(defaultStudyGradeSetting);
        for (reduivy__Individual_Enrollment__c ien : studentIenList){
            if (String.isNotBlank(ien.reduivy__Study_Grade_Setting__c)){
                studyGradeSettingIds.add(ien.reduivy__Study_Grade_Setting__c);
            }
        }
        List<reduivy__Study_Grading_Scheme__c> sgsList = [
            SELECT Id
            FROM reduivy__Study_Grading_Scheme__c
            WHERE reduivy__Study_Grade_Setting__c IN :studyGradeSettingIds 
            AND reduivy__Display_In_Wizard__c = true
        ];
        System.Assert.isFalse(sgsList.isEmpty(), 'No Study Grading Schemes');

        Test.startTest();
        System.runAs(ADMIN_USER){

            //Load component
            REDU_LightningResponse response = REDU_StudentGradingRegistry_LCTRL.getGradingData(sof.Id, SOF_Helper.getApiName(), null, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, 'reduivy__GradingWizard_Notes');
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check returned Datawrapper info
            REDU_StudentGradingRegistry_LCTRL.DataWrapper dw = (REDU_StudentGradingRegistry_LCTRL.DataWrapper) JSON.deserialize(response.responseData, REDU_StudentGradingRegistry_LCTRL.DataWrapper.class);
            System.Assert.areEqual(sof.Id, dw.studyOffering.Id);
            System.Assert.areEqual(sof.Name, dw.recordName);
            System.Assert.areEqual(null, dw.studySession);
            System.Assert.areEqual(studentIenList.size(), dw.studentWrappers.size());
            System.Assert.areEqual(sgiMap.size(), dw.tableColumnSgiList.size()); //May fail if Parent Study Grade Items are introduced
            System.Assert.areEqual(sgsList.size(), dw.studyGradingSchemeList.size());
            System.Assert.areEqual(defaultSgp.Id, dw.sgp.Id);
            System.Assert.isTrue(dw.igdCustomFields.isEmpty());
            System.Assert.areEqual(IGI_Helper.getStatuses().size(), dw.igiStatusList.size());
            System.Assert.isFalse(dw.gradingPeriodOptions.isEmpty());

            //Check returned StudentWrapper info
            for (REDU_StudentGradingRegistry_LCTRL.StudentWrapper sw : dw.studentWrappers){
                System.Assert.isNotNull(sw.igd);
                System.Assert.isNull(sw.igd.Id);
                System.Assert.areEqual(sw.igd, sw.oldIgd);
                System.Assert.isNotNull(sw.ien);
                System.Assert.areEqual(sgiMap.size(), sw.gradeWrapperList.size());
                System.Assert.isTrue(sw.isShown);
                System.Assert.isFalse(sw.hasGradeChanged());
                
                //Check returned GradeWrapper info
                for (REDU_StudentGradingRegistry_LCTRL.GradeWrapper gw : sw.gradeWrapperList){
                    System.Assert.isNotNull(gw.igi);
                    System.Assert.isNull(gw.igi.id);
                    System.Assert.areEqual(gw.igi, gw.oldIgi);
                    System.Assert.isFalse(gw.hasValueChanged());
                    System.Assert.isFalse(gw.hasStatusChanged());
                    System.Assert.isNotNull(gw.sgiId);
                    System.Assert.isFalse(gw.isHiddenParent); //May fail if Parent Study Grade Items are introduced
                    System.Assert.isNull(gw.parentSgiId); //May fail if Parent Study Grade Items are introduced
                }
            }

        }
        Test.stopTest();

    }

    /**
     * @description Test as admin loading a Study Session record
     */
    @isTest
    static void testForAdminSseGetGradingData() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //Get Study Session
        reduivy__Study_Session__c sse = [
            SELECT Id, 
            Name, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c, 
            reduivy__Study_Offering__r.reduivy__Study_Unit__c, 
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
            reduivy__Study_Offering__r.reduivy__Academic_Term__c 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c = :sseGradedSseSampleCode
        ];
        //Get students enrolled in the Study Offering
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [
            SELECT Id, 
            reduivy__Individual_Enrollment__c, 
            reduivy__Study_Session__c, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Grade_Setting__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c = :sse.Id 
            AND RecordTypeId = :ISN_Helper.getStudentRecordTypeId()
        ];
        System.Assert.isFalse(studentIsnList.isEmpty(), 'No students enrolled in Study Session');
        //Get Study Grade Items
        Map<Id, reduivy__Study_Grade_Item__c> sgiMap = new Map<Id, reduivy__Study_Grade_Item__c>([
            SELECT Id, 
            Name, 
            reduivy__Display_Type__c
            FROM reduivy__Study_Grade_Item__c
            WHERE reduivy__Study_Unit__c = :sse.reduivy__Study_Offering__r.reduivy__Study_Unit__c
        ]);
        System.Assert.isFalse(sgiMap.isEmpty(), 'No Study Grade Items');
        //Get Study Grade Period
        reduivy__Study_Grade_Period_Setting__c defaultSgp = [
            SELECT Id 
            FROM reduivy__Study_Grade_Period_Setting__c
            WHERE reduivy__Academic_Term__c = :sse.reduivy__Study_Offering__r.reduivy__Academic_Term__c
            AND reduivy__Type__c = 'Final Grade'
        ];
        //Get Study Grading Schemes (based on Study Grade Setting from student individual enrollments)
        Set<Id> studyGradeSettingIds = new Set<Id>();
        Id defaultStudyGradeSetting = String.isNotBlank(sse.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c)
                                    ? sse.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c
                                    : sse.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c;
        studyGradeSettingIds.add(defaultStudyGradeSetting);
        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList){
            if (String.isNotBlank(isn.reduivy__Individual_Enrollment__r.reduivy__Study_Grade_Setting__c)){
                studyGradeSettingIds.add(isn.reduivy__Individual_Enrollment__r.reduivy__Study_Grade_Setting__c);
            }
        }
        List<reduivy__Study_Grading_Scheme__c> sgsList = [
            SELECT Id
            FROM reduivy__Study_Grading_Scheme__c
            WHERE reduivy__Study_Grade_Setting__c IN :studyGradeSettingIds 
            AND reduivy__Display_In_Wizard__c = true
        ];
        System.Assert.isFalse(sgsList.isEmpty(), 'No Study Grading Schemes');

        Test.startTest();
        System.runAs(ADMIN_USER){

            //Load component
            REDU_LightningResponse response = REDU_StudentGradingRegistry_LCTRL.getGradingData(sse.Id, SSE_Helper.getApiName(), null, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, 'reduivy__GradingWizard_Notes');
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check returned info
            REDU_StudentGradingRegistry_LCTRL.DataWrapper dw = (REDU_StudentGradingRegistry_LCTRL.DataWrapper) JSON.deserialize(response.responseData, REDU_StudentGradingRegistry_LCTRL.DataWrapper.class);
            System.Assert.areEqual(sse.reduivy__Study_Offering__c, dw.studyOffering.Id);
            System.Assert.areEqual(sse.Name, dw.recordName);
            System.Assert.areEqual(sse.Id, dw.studySession.Id);
            System.Assert.areEqual(studentIsnList.size(), dw.studentWrappers.size());
            System.Assert.areEqual(sgiMap.size(), dw.tableColumnSgiList.size()); //May fail if Parent Study Grade Items are introduced
            System.Assert.areEqual(sgsList.size(), dw.studyGradingSchemeList.size());
            System.Assert.areEqual(defaultSgp.Id, dw.sgp.Id);
            System.Assert.isTrue(dw.igdCustomFields.isEmpty());
            System.Assert.areEqual(IGI_Helper.getStatuses().size(), dw.igiStatusList.size());
            System.Assert.isFalse(dw.gradingPeriodOptions.isEmpty());

            //Check returned StudentWrapper info
            for (REDU_StudentGradingRegistry_LCTRL.StudentWrapper sw : dw.studentWrappers){
                System.Assert.isNotNull(sw.igd);
                System.Assert.isNull(sw.igd.Id);
                System.Assert.areEqual(sw.igd, sw.oldIgd);
                System.Assert.isNotNull(sw.ien);
                System.Assert.areEqual(sgiMap.size(), sw.gradeWrapperList.size());
                System.Assert.isTrue(sw.isShown);
                System.Assert.isFalse(sw.hasGradeChanged());
                
                //Check returned GradeWrapper info
                for (REDU_StudentGradingRegistry_LCTRL.GradeWrapper gw : sw.gradeWrapperList){
                    System.Assert.isNotNull(gw.igi);
                    System.Assert.isNull(gw.igi.id);
                    System.Assert.areEqual(gw.igi, gw.oldIgi);
                    System.Assert.isFalse(gw.hasValueChanged());
                    System.Assert.isFalse(gw.hasStatusChanged());
                    System.Assert.isNotNull(gw.sgiId);
                    System.Assert.isFalse(gw.isHiddenParent); //May fail if Parent Study Grade Items are introduced
                    System.Assert.isNull(gw.parentSgiId); //May fail if Parent Study Grade Items are introduced
                }
            }

        }
        Test.stopTest();

    }

    /**
     * @description Test as admin saving Student Grades
     */
    @isTest
    static void testForAdminSaveGradingData() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //Get Study Offering
        reduivy__Study_Offering__c sof = [
            SELECT Id, 
            Name, 
            reduivy__Study_Grade_Setting__c, 
            reduivy__Study_Unit__c, 
            reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
            reduivy__Academic_Term__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Sample_Record_Code__c = :sofGradedSofSampleCode
        ];
        //Get students enrolled in the Study Offering
        List<reduivy__Individual_Enrollment__c> studentIenList = [
            SELECT Id, 
            reduivy__Study_Grade_Setting__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sof.Id 
            AND RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ];
        System.Assert.isFalse(studentIenList.isEmpty(), 'No students enrolled in Study Offering');
        //Get Study Grade Items
        Map<Id, reduivy__Study_Grade_Item__c> sgiMap = new Map<Id, reduivy__Study_Grade_Item__c>([
            SELECT Id, 
            Name, 
            reduivy__Display_Type__c
            FROM reduivy__Study_Grade_Item__c
            WHERE reduivy__Study_Unit__c = :sof.reduivy__Study_Unit__c
        ]);
        System.Assert.isFalse(sgiMap.isEmpty(), 'No Study Grade Items');
        //Get Study Grade Period
        reduivy__Study_Grade_Period_Setting__c defaultSgp = [
            SELECT Id 
            FROM reduivy__Study_Grade_Period_Setting__c
            WHERE reduivy__Academic_Term__c = :sof.reduivy__Academic_Term__c
            AND reduivy__Type__c = 'Final Grade'
        ];
        //Get Study Grading Schemes (based on Study Grade Setting from student individual enrollments)
        Set<Id> studyGradeSettingIds = new Set<Id>();
        Id defaultStudyGradeSetting = String.isNotBlank(sof.reduivy__Study_Grade_Setting__c)
                                    ? sof.reduivy__Study_Grade_Setting__c
                                    : sof.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c;
        studyGradeSettingIds.add(defaultStudyGradeSetting);
        for (reduivy__Individual_Enrollment__c ien : studentIenList){
            if (String.isNotBlank(ien.reduivy__Study_Grade_Setting__c)){
                studyGradeSettingIds.add(ien.reduivy__Study_Grade_Setting__c);
            }
        }
        List<reduivy__Study_Grading_Scheme__c> sgsList = [
            SELECT Id
            FROM reduivy__Study_Grading_Scheme__c
            WHERE reduivy__Study_Grade_Setting__c IN :studyGradeSettingIds 
            AND reduivy__Display_In_Wizard__c = true
        ];
        System.Assert.isFalse(sgsList.isEmpty(), 'No Study Grading Schemes');

        Decimal gradeNumberValue = 95;
        String gradeLetterValue = 'A';
        String igiStatus = IGI_Helper.getStatuses()[0].value;
        String igdStatus = 'Draft';

        Test.startTest();
        System.runAs(ADMIN_USER){

            //Load component
            REDU_LightningResponse response = REDU_StudentGradingRegistry_LCTRL.getGradingData(sof.Id, SOF_Helper.getApiName(), null, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, 'reduivy__GradingWizard_Notes');
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check returned Datawrapper info
            REDU_StudentGradingRegistry_LCTRL.DataWrapper dw = (REDU_StudentGradingRegistry_LCTRL.DataWrapper) JSON.deserialize(response.responseData, REDU_StudentGradingRegistry_LCTRL.DataWrapper.class);
            System.Assert.areEqual(studentIenList.size(), dw.studentWrappers.size());

            //Check returned StudentWrapper info
            for (REDU_StudentGradingRegistry_LCTRL.StudentWrapper sw : dw.studentWrappers){
                System.Assert.isNotNull(sw.igd);
                System.Assert.isNull(sw.igd.Id);
                System.Assert.isNull(sw.igd.reduivy__Status__c);
                System.Assert.areEqual(sgiMap.size(), sw.gradeWrapperList.size());
                
                //Check returned GradeWrapper info
                for (REDU_StudentGradingRegistry_LCTRL.GradeWrapper gw : sw.gradeWrapperList){
                    System.Assert.isNotNull(gw.igi);
                    System.Assert.isNull(gw.igi.id);
                    //Update Individual Grade Item
                    gw.igi.reduivy__Numerical_Grade__c = gradeNumberValue;
                    gw.igi.reduivy__Letter_Grade__c = gradeLetterValue;
                    gw.igi.reduivy__Status__c = igiStatus;
                }
            }

            //Save results
            REDU_LightningResponse saveResponse = REDU_StudentGradingRegistry_LCTRL.saveGradingData(JSON.serialize(dw.studentWrappers), null, igdStatus, null);
            System.Assert.isTrue(response.isSuccess, response.message);

            //Reload the component to ensure changes were retrieved
            response = REDU_StudentGradingRegistry_LCTRL.getGradingData(sof.Id, SOF_Helper.getApiName(), null, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, 'reduivy__GradingWizard_Notes');
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check returned Datawrapper info
            dw = (REDU_StudentGradingRegistry_LCTRL.DataWrapper) JSON.deserialize(response.responseData, REDU_StudentGradingRegistry_LCTRL.DataWrapper.class);
            System.Assert.areEqual(studentIenList.size(), dw.studentWrappers.size());

            //Check returned StudentWrapper info
            for (REDU_StudentGradingRegistry_LCTRL.StudentWrapper sw : dw.studentWrappers){
                System.Assert.isNotNull(sw.igd);
                System.Assert.isNotNull(sw.igd.Id);
                System.Assert.areEqual(igdStatus, sw.igd.reduivy__Status__c);
                System.Assert.areEqual(sgiMap.size(), sw.gradeWrapperList.size());
                
                //Check returned GradeWrapper info
                for (REDU_StudentGradingRegistry_LCTRL.GradeWrapper gw : sw.gradeWrapperList){
                    System.Assert.isNotNull(gw.igi);
                    System.Assert.isNotNull(gw.igi.id);
                    System.Assert.areEqual(gradeNumberValue, gw.igi.reduivy__Numerical_Grade__c);
                    System.Assert.areEqual(gradeLetterValue, gw.igi.reduivy__Letter_Grade__c);
                    System.Assert.areEqual(igiStatus, gw.igi.reduivy__Status__c);
                }
            }

        }
        Test.stopTest();

    }

    /**
     * @description ISS-002259 Test get fields as faculty
     */
    @IsTest
    static void testForFacultyGetFields(){
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();
        System.runAs(FACULTY_USER){
            REDU_LightningResponse response = REDU_StudentGradingRegistry_LCTRL.getFields('reduivy__GradingWizard_Notes', 'reduivy__Individual_Grade_Item__c');
            System.Assert.areEqual(true, response.isSuccess);
            
            List<REDU_DynamicFieldValue_OBJ> fields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);
            for (REDU_DynamicFieldValue_OBJ field : fields) {
                System.Assert.isTrue(igiFields.contains(field.fieldName));
            }
            
        }
        Test.stopTest();
        
    }

    /**
     * @description Test as faculty loading a Study Offering record
     */
    @isTest
    static void testForFacultySofGetGradingData() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //Get Study Offering
        reduivy__Study_Offering__c sof = [
            SELECT Id, 
            Name, 
            reduivy__Study_Grade_Setting__c, 
            reduivy__Study_Unit__c, 
            reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
            reduivy__Academic_Term__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Sample_Record_Code__c = :sofGradedSofSampleCode
        ];
        //Get students enrolled in the Study Offering
        List<reduivy__Individual_Enrollment__c> studentIenList = [
            SELECT Id, 
            reduivy__Study_Grade_Setting__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sof.Id 
            AND RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ];
        System.Assert.isFalse(studentIenList.isEmpty(), 'No students enrolled in Study Offering');
        //Get Study Grade Items
        Map<Id, reduivy__Study_Grade_Item__c> sgiMap = new Map<Id, reduivy__Study_Grade_Item__c>([
            SELECT Id, 
            Name, 
            reduivy__Display_Type__c
            FROM reduivy__Study_Grade_Item__c
            WHERE reduivy__Study_Unit__c = :sof.reduivy__Study_Unit__c
        ]);
        System.Assert.isFalse(sgiMap.isEmpty(), 'No Study Grade Items');
        //Get Study Grade Period
        reduivy__Study_Grade_Period_Setting__c defaultSgp = [
            SELECT Id 
            FROM reduivy__Study_Grade_Period_Setting__c
            WHERE reduivy__Academic_Term__c = :sof.reduivy__Academic_Term__c
            AND reduivy__Type__c = 'Final Grade'
        ];
        //Get Study Grading Schemes (based on Study Grade Setting from student individual enrollments)
        Set<Id> studyGradeSettingIds = new Set<Id>();
        Id defaultStudyGradeSetting = String.isNotBlank(sof.reduivy__Study_Grade_Setting__c)
                                    ? sof.reduivy__Study_Grade_Setting__c
                                    : sof.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c;
        studyGradeSettingIds.add(defaultStudyGradeSetting);
        for (reduivy__Individual_Enrollment__c ien : studentIenList){
            if (String.isNotBlank(ien.reduivy__Study_Grade_Setting__c)){
                studyGradeSettingIds.add(ien.reduivy__Study_Grade_Setting__c);
            }
        }
        List<reduivy__Study_Grading_Scheme__c> sgsList = [
            SELECT Id
            FROM reduivy__Study_Grading_Scheme__c
            WHERE reduivy__Study_Grade_Setting__c IN :studyGradeSettingIds 
            AND reduivy__Display_In_Wizard__c = true
        ];
        System.Assert.isFalse(sgsList.isEmpty(), 'No Study Grading Schemes');

        Test.startTest();
        System.runAs(FACULTY_USER){

            //Load component
            REDU_LightningResponse response = REDU_StudentGradingRegistry_LCTRL.getGradingData(sof.Id, SOF_Helper.getApiName(), null, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, 'reduivy__GradingWizard_Notes');
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check returned Datawrapper info
            REDU_StudentGradingRegistry_LCTRL.DataWrapper dw = (REDU_StudentGradingRegistry_LCTRL.DataWrapper) JSON.deserialize(response.responseData, REDU_StudentGradingRegistry_LCTRL.DataWrapper.class);
            System.Assert.areEqual(sof.Id, dw.studyOffering.Id);
            System.Assert.areEqual(sof.Name, dw.recordName);
            System.Assert.areEqual(null, dw.studySession);
            System.Assert.areEqual(studentIenList.size(), dw.studentWrappers.size());
            System.Assert.areEqual(sgiMap.size(), dw.tableColumnSgiList.size()); //May fail if Parent Study Grade Items are introduced
            System.Assert.areEqual(sgsList.size(), dw.studyGradingSchemeList.size());
            System.Assert.areEqual(defaultSgp.Id, dw.sgp.Id);
            System.Assert.isTrue(dw.igdCustomFields.isEmpty());
            System.Assert.areEqual(IGI_Helper.getStatuses().size(), dw.igiStatusList.size());
            System.Assert.isFalse(dw.gradingPeriodOptions.isEmpty());

            //Check returned StudentWrapper info
            for (REDU_StudentGradingRegistry_LCTRL.StudentWrapper sw : dw.studentWrappers){
                System.Assert.isNotNull(sw.igd);
                System.Assert.isNull(sw.igd.Id);
                System.Assert.areEqual(sw.igd, sw.oldIgd);
                System.Assert.isNotNull(sw.ien);
                System.Assert.areEqual(sgiMap.size(), sw.gradeWrapperList.size());
                System.Assert.isTrue(sw.isShown);
                System.Assert.isFalse(sw.hasGradeChanged());
                
                //Check returned GradeWrapper info
                for (REDU_StudentGradingRegistry_LCTRL.GradeWrapper gw : sw.gradeWrapperList){
                    System.Assert.isNotNull(gw.igi);
                    System.Assert.isNull(gw.igi.id);
                    System.Assert.areEqual(gw.igi, gw.oldIgi);
                    System.Assert.isFalse(gw.hasValueChanged());
                    System.Assert.isFalse(gw.hasStatusChanged());
                    System.Assert.isNotNull(gw.sgiId);
                    System.Assert.isFalse(gw.isHiddenParent); //May fail if Parent Study Grade Items are introduced
                    System.Assert.isNull(gw.parentSgiId); //May fail if Parent Study Grade Items are introduced
                }
            }

        }
        Test.stopTest();

    }

    /**
     * @description Test as faculty loading a Study Session record
     */
    @isTest
    static void testForFacultySseGetGradingData() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //Get Study Session
        reduivy__Study_Session__c sse = [
            SELECT Id, 
            Name, 
            reduivy__Study_Offering__c, 
            reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c, 
            reduivy__Study_Offering__r.reduivy__Study_Unit__c, 
            reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
            reduivy__Study_Offering__r.reduivy__Academic_Term__c 
            FROM reduivy__Study_Session__c
            WHERE reduivy__Sample_Record_Code__c = :sseGradedSseSampleCode
        ];
        //Get students enrolled in the Study Offering
        List<reduivy__Individual_Session_Enrollment__c> studentIsnList = [
            SELECT Id, 
            reduivy__Individual_Enrollment__c, 
            reduivy__Study_Session__c, 
            reduivy__Individual_Enrollment__r.reduivy__Study_Grade_Setting__c
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE reduivy__Study_Session__c = :sse.Id 
            AND RecordTypeId = :ISN_Helper.getStudentRecordTypeId()
        ];
        System.Assert.isFalse(studentIsnList.isEmpty(), 'No students enrolled in Study Session');
        //Get Study Grade Items
        Map<Id, reduivy__Study_Grade_Item__c> sgiMap = new Map<Id, reduivy__Study_Grade_Item__c>([
            SELECT Id, 
            Name, 
            reduivy__Display_Type__c
            FROM reduivy__Study_Grade_Item__c
            WHERE reduivy__Study_Unit__c = :sse.reduivy__Study_Offering__r.reduivy__Study_Unit__c
        ]);
        System.Assert.isFalse(sgiMap.isEmpty(), 'No Study Grade Items');
        //Get Study Grade Period
        reduivy__Study_Grade_Period_Setting__c defaultSgp = [
            SELECT Id 
            FROM reduivy__Study_Grade_Period_Setting__c
            WHERE reduivy__Academic_Term__c = :sse.reduivy__Study_Offering__r.reduivy__Academic_Term__c
            AND reduivy__Type__c = 'Final Grade'
        ];
        //Get Study Grading Schemes (based on Study Grade Setting from student individual enrollments)
        Set<Id> studyGradeSettingIds = new Set<Id>();
        Id defaultStudyGradeSetting = String.isNotBlank(sse.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c)
                                    ? sse.reduivy__Study_Offering__r.reduivy__Study_Grade_Setting__c
                                    : sse.reduivy__Study_Offering__r.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c;
        studyGradeSettingIds.add(defaultStudyGradeSetting);
        for (reduivy__Individual_Session_Enrollment__c isn : studentIsnList){
            if (String.isNotBlank(isn.reduivy__Individual_Enrollment__r.reduivy__Study_Grade_Setting__c)){
                studyGradeSettingIds.add(isn.reduivy__Individual_Enrollment__r.reduivy__Study_Grade_Setting__c);
            }
        }
        List<reduivy__Study_Grading_Scheme__c> sgsList = [
            SELECT Id
            FROM reduivy__Study_Grading_Scheme__c
            WHERE reduivy__Study_Grade_Setting__c IN :studyGradeSettingIds 
            AND reduivy__Display_In_Wizard__c = true
        ];
        System.Assert.isFalse(sgsList.isEmpty(), 'No Study Grading Schemes');

        Test.startTest();
        System.runAs(FACULTY_USER){

            //Load component
            REDU_LightningResponse response = REDU_StudentGradingRegistry_LCTRL.getGradingData(sse.Id, SSE_Helper.getApiName(), null, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, 'reduivy__GradingWizard_Notes');
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check returned info
            REDU_StudentGradingRegistry_LCTRL.DataWrapper dw = (REDU_StudentGradingRegistry_LCTRL.DataWrapper) JSON.deserialize(response.responseData, REDU_StudentGradingRegistry_LCTRL.DataWrapper.class);
            System.Assert.areEqual(sse.reduivy__Study_Offering__c, dw.studyOffering.Id);
            System.Assert.areEqual(sse.Name, dw.recordName);
            System.Assert.areEqual(sse.Id, dw.studySession.Id);
            System.Assert.areEqual(studentIsnList.size(), dw.studentWrappers.size());
            System.Assert.areEqual(sgiMap.size(), dw.tableColumnSgiList.size()); //May fail if Parent Study Grade Items are introduced
            System.Assert.areEqual(sgsList.size(), dw.studyGradingSchemeList.size());
            System.Assert.areEqual(defaultSgp.Id, dw.sgp.Id);
            System.Assert.isTrue(dw.igdCustomFields.isEmpty());
            System.Assert.areEqual(IGI_Helper.getStatuses().size(), dw.igiStatusList.size());
            System.Assert.isFalse(dw.gradingPeriodOptions.isEmpty());

            //Check returned StudentWrapper info
            for (REDU_StudentGradingRegistry_LCTRL.StudentWrapper sw : dw.studentWrappers){
                System.Assert.isNotNull(sw.igd);
                System.Assert.isNull(sw.igd.Id);
                System.Assert.areEqual(sw.igd, sw.oldIgd);
                System.Assert.isNotNull(sw.ien);
                System.Assert.areEqual(sgiMap.size(), sw.gradeWrapperList.size());
                System.Assert.isTrue(sw.isShown);
                System.Assert.isFalse(sw.hasGradeChanged());
                
                //Check returned GradeWrapper info
                for (REDU_StudentGradingRegistry_LCTRL.GradeWrapper gw : sw.gradeWrapperList){
                    System.Assert.isNotNull(gw.igi);
                    System.Assert.isNull(gw.igi.id);
                    System.Assert.areEqual(gw.igi, gw.oldIgi);
                    System.Assert.isFalse(gw.hasValueChanged());
                    System.Assert.isFalse(gw.hasStatusChanged());
                    System.Assert.isNotNull(gw.sgiId);
                    System.Assert.isFalse(gw.isHiddenParent); //May fail if Parent Study Grade Items are introduced
                    System.Assert.isNull(gw.parentSgiId); //May fail if Parent Study Grade Items are introduced
                }
            }

        }
        Test.stopTest();

    }

    /**
     * @description Test as faculty saving Student Grades
     */
    @isTest
    static void testForFacultySaveGradingData() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        //Get Study Offering
        reduivy__Study_Offering__c sof = [
            SELECT Id, 
            Name, 
            reduivy__Study_Grade_Setting__c, 
            reduivy__Study_Unit__c, 
            reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c,
            reduivy__Academic_Term__c 
            FROM reduivy__Study_Offering__c
            WHERE reduivy__Sample_Record_Code__c = :sofGradedSofSampleCode
        ];
        //Get students enrolled in the Study Offering
        List<reduivy__Individual_Enrollment__c> studentIenList = [
            SELECT Id, 
            reduivy__Study_Grade_Setting__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Study_Offering__c = :sof.Id 
            AND RecordTypeId = :IEN_Helper.getStudentRecordTypeId()
        ];
        System.Assert.isFalse(studentIenList.isEmpty(), 'No students enrolled in Study Offering');
        //Get Study Grade Items
        Map<Id, reduivy__Study_Grade_Item__c> sgiMap = new Map<Id, reduivy__Study_Grade_Item__c>([
            SELECT Id, 
            Name, 
            reduivy__Display_Type__c
            FROM reduivy__Study_Grade_Item__c
            WHERE reduivy__Study_Unit__c = :sof.reduivy__Study_Unit__c
        ]);
        System.Assert.isFalse(sgiMap.isEmpty(), 'No Study Grade Items');
        //Get Study Grade Period
        reduivy__Study_Grade_Period_Setting__c defaultSgp = [
            SELECT Id 
            FROM reduivy__Study_Grade_Period_Setting__c
            WHERE reduivy__Academic_Term__c = :sof.reduivy__Academic_Term__c
            AND reduivy__Type__c = 'Final Grade'
        ];
        //Get Study Grading Schemes (based on Study Grade Setting from student individual enrollments)
        Set<Id> studyGradeSettingIds = new Set<Id>();
        Id defaultStudyGradeSetting = String.isNotBlank(sof.reduivy__Study_Grade_Setting__c)
                                    ? sof.reduivy__Study_Grade_Setting__c
                                    : sof.reduivy__Study_Unit__r.reduivy__Study_Grade_Setting__c;
        studyGradeSettingIds.add(defaultStudyGradeSetting);
        for (reduivy__Individual_Enrollment__c ien : studentIenList){
            if (String.isNotBlank(ien.reduivy__Study_Grade_Setting__c)){
                studyGradeSettingIds.add(ien.reduivy__Study_Grade_Setting__c);
            }
        }
        List<reduivy__Study_Grading_Scheme__c> sgsList = [
            SELECT Id
            FROM reduivy__Study_Grading_Scheme__c
            WHERE reduivy__Study_Grade_Setting__c IN :studyGradeSettingIds 
            AND reduivy__Display_In_Wizard__c = true
        ];
        System.Assert.isFalse(sgsList.isEmpty(), 'No Study Grading Schemes');

        Decimal gradeNumberValue = 95;
        String gradeLetterValue = 'A';
        String igiStatus = IGI_Helper.getStatuses()[0].value;
        String igdStatus = 'Draft';

        Test.startTest();
        System.runAs(FACULTY_USER){

            //Load component
            REDU_LightningResponse response = REDU_StudentGradingRegistry_LCTRL.getGradingData(sof.Id, SOF_Helper.getApiName(), null, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, 'reduivy__GradingWizard_Notes');
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check returned Datawrapper info
            REDU_StudentGradingRegistry_LCTRL.DataWrapper dw = (REDU_StudentGradingRegistry_LCTRL.DataWrapper) JSON.deserialize(response.responseData, REDU_StudentGradingRegistry_LCTRL.DataWrapper.class);
            System.Assert.areEqual(studentIenList.size(), dw.studentWrappers.size());

            //Check returned StudentWrapper info
            for (REDU_StudentGradingRegistry_LCTRL.StudentWrapper sw : dw.studentWrappers){
                System.Assert.isNotNull(sw.igd);
                System.Assert.isNull(sw.igd.Id);
                System.Assert.isNull(sw.igd.reduivy__Status__c);
                System.Assert.areEqual(sgiMap.size(), sw.gradeWrapperList.size());
                
                //Check returned GradeWrapper info
                for (REDU_StudentGradingRegistry_LCTRL.GradeWrapper gw : sw.gradeWrapperList){
                    System.Assert.isNotNull(gw.igi);
                    System.Assert.isNull(gw.igi.id);
                    //Update Individual Grade Item
                    gw.igi.reduivy__Numerical_Grade__c = gradeNumberValue;
                    gw.igi.reduivy__Letter_Grade__c = gradeLetterValue;
                    gw.igi.reduivy__Status__c = igiStatus;
                }
            }

            //Save results
            REDU_LightningResponse saveResponse = REDU_StudentGradingRegistry_LCTRL.saveGradingData(JSON.serialize(dw.studentWrappers), null, igdStatus, null);
            System.Assert.isTrue(response.isSuccess, response.message);

            //Reload the component to ensure changes were retrieved
            response = REDU_StudentGradingRegistry_LCTRL.getGradingData(sof.Id, SOF_Helper.getApiName(), null, IEN_INPROGRESS_STATUSES, ISN_INPROGRESS_STATUSES, null, 'reduivy__GradingWizard_Notes');
            System.Assert.isTrue(response.isSuccess, response.message);
            //Check returned Datawrapper info
            dw = (REDU_StudentGradingRegistry_LCTRL.DataWrapper) JSON.deserialize(response.responseData, REDU_StudentGradingRegistry_LCTRL.DataWrapper.class);
            System.Assert.areEqual(studentIenList.size(), dw.studentWrappers.size());

            //Check returned StudentWrapper info
            for (REDU_StudentGradingRegistry_LCTRL.StudentWrapper sw : dw.studentWrappers){
                System.Assert.isNotNull(sw.igd);
                System.Assert.isNotNull(sw.igd.Id);
                System.Assert.areEqual(igdStatus, sw.igd.reduivy__Status__c);
                System.Assert.areEqual(sgiMap.size(), sw.gradeWrapperList.size());
                
                //Check returned GradeWrapper info
                for (REDU_StudentGradingRegistry_LCTRL.GradeWrapper gw : sw.gradeWrapperList){
                    System.Assert.isNotNull(gw.igi);
                    System.Assert.isNotNull(gw.igi.id);
                    System.Assert.areEqual(gradeNumberValue, gw.igi.reduivy__Numerical_Grade__c);
                    System.Assert.areEqual(gradeLetterValue, gw.igi.reduivy__Letter_Grade__c);
                    System.Assert.areEqual(igiStatus, gw.igi.reduivy__Status__c);
                }
            }

        }
        Test.stopTest();

    }

}