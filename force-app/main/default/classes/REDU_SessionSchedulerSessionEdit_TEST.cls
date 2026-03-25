/**
 * @author      WDCi (XW)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for REDU_SessionSchedulerSessionEdit_LCTRL
 * @changehistory
 * ISS-001920 19-08-2024 XW - create new class
 */
@IsTest
public inherited sharing class REDU_SessionSchedulerSessionEdit_TEST {

    private static String INSUFFICIENT_DELETE_ACCESS = 'Insufficient Delete access';
    private static String INSUFFICIENT_UPSERTABLE_ACCESS = 'Insufficient UPSERTABLE access';
    private static String INSUFFICIENT_UPDATABLE_ACCESS = 'Insufficient UPDATABLE access';

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();
            
        	testFactory.initMasterData(null);
            testFactory.initOfferingData(SST_Helper.getApiName());
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            Test.stopTest();
		}
    }
	
    /**
     * @description Test as admin for GetFields
     */
    @IsTest
    static void testForAdminGetFields() {
	
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        String objectName = 'reduivy__Study_Session__c';
        String fieldsetName ='reduivy__SessionScheduler_Form'; 

        List<REDU_DynamicFieldValue_OBJ> expectedFields = REDU_Metadata_UTIL.getFieldSetMembers(objectName, fieldsetName);

		System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse response = REDU_SessionSchedulerSessionEdit_LCTRL.getFields(fieldsetName, objectName);
            List<REDU_DynamicFieldValue_OBJ> resultFields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);

            System.Assert.areEqual(expectedFields.size(), resultFields.size(), 'Wrong fields size!');
            
            try{
                REDU_SessionSchedulerSessionEdit_LCTRL.getFields('', '');
            } catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Invalid field set'), 'Wrong exception: ' + exp.getMessage());
            }
            
            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as student for GetFields
     */
	@IsTest
    static void testForStudentGetFields() {
        
        String objectName = 'reduivy__Study_Session__c';
        String fieldsetName ='reduivy__SessionScheduler_Form'; 

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

        List<REDU_DynamicFieldValue_OBJ> expectedFields = REDU_Metadata_UTIL.getFieldSetMembers(objectName, fieldsetName);

        // TO DO: implement unit test run as student
		System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse response = REDU_SessionSchedulerSessionEdit_LCTRL.getFields(fieldsetName, objectName);
            List<REDU_DynamicFieldValue_OBJ> resultFields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);

            System.Assert.areEqual(expectedFields.size(), resultFields.size(), 'Wrong fields size!');
            
            Test.stopTest();
		}
		
    }
	
    /**
     * @description Test as faculty for GetFields
     */
	@IsTest
    static void testForFacultyGetFields() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        String objectName = 'reduivy__Study_Session__c';
        String fieldsetName ='reduivy__SessionScheduler_Form'; 

        List<REDU_DynamicFieldValue_OBJ> expectedFields = REDU_Metadata_UTIL.getFieldSetMembers(objectName, fieldsetName);
        
        // TO DO: implement unit test run as faculty
		System.runAs(FACULTY_USER){
            Test.startTest();
            REDU_LightningResponse response = REDU_SessionSchedulerSessionEdit_LCTRL.getFields(fieldsetName, objectName);
            List<REDU_DynamicFieldValue_OBJ> resultFields = (List<REDU_DynamicFieldValue_OBJ>) JSON.deserialize(response.responseData, List<REDU_DynamicFieldValue_OBJ>.class);

            System.Assert.areEqual(expectedFields.size(), resultFields.size(), 'Wrong fields size!');
            
            Test.stopTest();
		}
		
    }


    /**
     * @description Test as admin for UpsertSessionsAndSessionTimes
     */
    @IsTest
    static void testForAdminUpsertSessionsAndSessionTimes() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        List<reduivy__Study_Session__c> sseBeforeList = [SELECT Id, 
            Name, 
            reduivy__Start_Date__c, 
            reduivy__End_Date__c, 
            (
                SELECT Id, 
                Name, 
                reduivy__Start_Date__c,
                reduivy__End_Date__c,
                reduivy__Day_of_Week__c,
                reduivy__Recurrence__c,
                reduivy__Default_Facility__c,
                reduivy__End_Time__c,
                reduivy__Start_Time__c
                FROM reduivy__Study_Session_Times__r
            )
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        reduivy__Study_Session_Time__c existingSst = sseBeforeList[0].reduivy__Study_Session_Times__r[0];
        sseBeforeList[0].reduivy__Study_Session_Times__r.add(new reduivy__Study_Session_Time__c(
            Name = 'BUS103 Tutorial - Thursday',
            reduivy__Start_Date__c = existingSst.reduivy__End_Date__c,
            reduivy__End_Date__c = existingSst.reduivy__End_Date__c,
            reduivy__Day_of_Week__c = existingSst.reduivy__Day_of_Week__c,
            reduivy__Recurrence__c = existingSst.reduivy__Recurrence__c,
            reduivy__Default_Facility__c = existingSst.reduivy__Default_Facility__c,
            reduivy__End_Time__c = existingSst.reduivy__End_Time__c,
            reduivy__Start_Time__c = existingSst.reduivy__End_Time__c
        ));

		System.runAs(ADMIN_USER){
            Test.startTest();

            String upsertSst = JSON.serialize(sseBeforeList) ;
            REDU_LightningResponse response = REDU_SessionSchedulerSessionEdit_LCTRL.upsertSessionsAndSessionTimes(upsertSst, new List<String>{existingSst.Id});
            List<reduivy__Study_Session__c> sseResultList = [SELECT Id, 
                Name, 
                reduivy__Start_Date__c, 
                reduivy__End_Date__c, 
                (
                    SELECT Id, 
                    Name, 
                    reduivy__Start_Date__c,
                    reduivy__End_Date__c,
                    reduivy__Day_of_Week__c,
                    reduivy__Recurrence__c,
                    reduivy__Default_Facility__c,
                    reduivy__End_Time__c,
                    reduivy__Start_Time__c
                    FROM reduivy__Study_Session_Times__r
                )
                FROM reduivy__Study_Session__c
                WHERE Id IN :sseBeforeList 
                LIMIT 1
            ];

            for(reduivy__Study_Session_Time__c resultSst: sseResultList[0].reduivy__Study_Session_Times__r) {

                System.Assert.areNotEqual(
                    existingSst.Id, 
                    resultSst.Id,
                    'Study session time should be deleted!');

            }
            Test.stopTest();
		
        }
    }
	
    /**
     * @description Test as student for UpsertSessionsAndSessionTimes
     */
	@IsTest
    static void testForStudentUpsertSessionsAndSessionTimes() {
        
        User studentUser = testFactory.getStudentUser();

        List<reduivy__Study_Session__c> sseBefore = [
            SELECT Id, Name, reduivy__Start_Date__c, reduivy__End_Date__c, (
                SELECT Id, Name, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c
                FROM reduivy__Study_Session_Times__r
            )
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        sseBefore[0].reduivy__Study_Session_Times__r[0].reduivy__Start_Time__c = sseBefore[0].reduivy__Study_Session_Times__r[0].reduivy__Start_Time__c.addHours(1);

		System.runAs(studentUser){
            Test.startTest();

            try{
                REDU_LightningResponse response = REDU_SessionSchedulerSessionEdit_LCTRL.upsertSessionsAndSessionTimes(JSON.serialize(sseBefore), null);
            } catch(Exception error){
                System.Assert.isTrue(error.getMessage().contains(INSUFFICIENT_UPSERTABLE_ACCESS), 'Wrong exception type: '+ error.getMessage());
            }

            Test.stopTest();
		}
		
		
    }
		
    /**
     * @description Test as faculty for UpsertSessionsAndSessionTimes
     */
	@IsTest
    static void testForFacultyUpsertSessionsAndSessionTimes() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        List<reduivy__Study_Session__c> sseBefore = [
            SELECT Id, Name, reduivy__Start_Date__c, reduivy__End_Date__c, (
                SELECT Id, Name, reduivy__Start_Date__c, reduivy__End_Date__c, reduivy__Start_Time__c, reduivy__End_Time__c
                FROM reduivy__Study_Session_Times__r
            )
            FROM reduivy__Study_Session__c
            LIMIT 1
        ];

        sseBefore[0].reduivy__Study_Session_Times__r[0].reduivy__Start_Time__c = sseBefore[0].reduivy__Study_Session_Times__r[0].reduivy__Start_Time__c.addHours(1);

		System.runAs(FACULTY_USER){
            Test.startTest();

            try{
                REDU_LightningResponse response = REDU_SessionSchedulerSessionEdit_LCTRL.upsertSessionsAndSessionTimes(JSON.serialize(sseBefore), null);
            }catch(Exception error){
                System.Assert.isTrue(error.getMessage().contains(INSUFFICIENT_UPSERTABLE_ACCESS), 'Wrong exception type: '+ error.getMessage());
            }

            Test.stopTest();
		}
		
		
    }
	
    /**
     * @description Test as admin for GenerateStudyEvents
     */
    @IsTest
    static void testForAdminGenerateStudyEvents() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Study_Session__c sse = [
            SELECT Id, Name
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Event_Generation_Status__c = :SSE_Helper.STUDY_EVENT_GEN_STATUS_DRAFT
            LIMIT 1
        ];
		System.runAs(ADMIN_USER){
            Test.startTest();
            
            REDU_LightningResponse response = REDU_SessionSchedulerSessionEdit_LCTRL.generateStudyEvent(new List<String>{sse.Id});

            reduivy__Study_Session__c updatedSse = [
                SELECT Id, Name, reduivy__Study_Event_Generation_Status__c
                FROM reduivy__Study_Session__c
                WHERE Id = :sse.Id
                LIMIT 1
            ];
            
            System.Assert.areEqual(SSE_Helper.STUDY_EVENT_GEN_STATUS_GENERATED, updatedSse.reduivy__Study_Event_Generation_Status__c, 'Study event is not generated!');
            

            try{
                REDU_LightningResponse expResponse = REDU_SessionSchedulerSessionEdit_LCTRL.generateStudyEvent(new List<String>{'', 'testing'});
                
            }catch(Exception exp){
                System.Assert.isTrue(exp.getMessage().contains('Invalid id'), 'Wrong exception type: '+ exp.getMessage());
            }

            Test.stopTest();
		}
		
    }
    
    
    /**
     * @description Test as student for GetFields
     */
    @IsTest
    static void testForStudentGenerateStudyEvents() {
        User studentUser = testFactory.getStudentUser();

        reduivy__Study_Session__c sse = [
            SELECT Id, Name
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Event_Generation_Status__c = :SSE_Helper.STUDY_EVENT_GEN_STATUS_DRAFT
            LIMIT 1
        ];
		System.runAs(studentUser){
            Test.startTest();
            
            try {
                REDU_LightningResponse response = REDU_SessionSchedulerSessionEdit_LCTRL.generateStudyEvent(new List<String>{sse.Id});
            } catch(Exception error){
                System.Assert.isTrue(error.getMessage().contains(INSUFFICIENT_UPDATABLE_ACCESS), 'Wrong exception type: '+ error.getMessage());
            }

            Test.stopTest();
		}
		
    }    
    
    /**
     * @description Test as faculty for GetFields
     */
    @IsTest
    static void testForFacultyGenerateStudyEvents() {
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Study_Session__c sse = [
            SELECT Id, Name
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Event_Generation_Status__c = :SSE_Helper.STUDY_EVENT_GEN_STATUS_DRAFT
            LIMIT 1
        ];

		System.runAs(FACULTY_USER){
            Test.startTest();
    
            try {
                REDU_LightningResponse response = REDU_SessionSchedulerSessionEdit_LCTRL.generateStudyEvent(new List<String>{sse.Id});
            } catch(Exception error){
                System.Assert.isTrue(error.getMessage().contains(INSUFFICIENT_UPDATABLE_ACCESS), 'Wrong exception type: '+ error.getMessage());
            }

            Test.stopTest();
		}
		
    }



}