/**
 * @author      WDCi (XW)
 * @date        July 2025
 * @group       Test
 * @description Test class for REDU_RequirementChecklistIdvAc_LCTRL
 * @changehistory
 * ISS-002128 03-07-2025 XW - new class
 */
@IsTest
public inherited sharing class REDU_RequirementChecklistIdvAc_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static String SRC_STUDENT_CON = 'sandydoe@redu.example';
    static String SRC_CVS1 = 'CVS1';
    static String SRC_CVS2 = 'CVS2';

    static final String SRS_LOCAL = 'SRS_Local';
    static final String SRS_GENERAL = 'SRS_General';

    static reduivy__Individual_Requirement__c irq;
    static Contact studentCon;

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

            testFactory.initMasterData(SRQ_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IRQ_Helper.getApiName(), true);
            
            Contact student = testFactory.students.get(SRC_STUDENT_CON);
            
            insert REDU_TestData_UTIL.newIndividualAchievement(student.Id + 'Individual_Achievement_2', student.Id, 'Diploma in Business Management - ' + student.FirstName + student.LastName, 'University of Golders Green', IAC_Helper.ACADEMIC_LEVEL_DIPLOMA, IAC_Helper.COMPLETION_STATUS_AWARDED, Date.newInstance(2023, 01, 01), IAC_Helper.VERIFICATION_STATUS_REVIEWING, null);


            
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for getting data related to linking to iac, no document linked to iac
     */
    @IsTest
    static void testFor_NoLinkToIac_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setIrq();
        setCon();

        
		System.runAs(ADMIN_USER){

            insertContentAndLink();
            Map<Id, reduivy__Individual_Achievement__c> expectedIacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList());
            Map<Id, ContentDocument> expectedCdcMap = new Map<Id, ContentDocument>(queryCdcList(true, true));

            REDU_LightningResponse responseResult = REDU_RequirementChecklistIdvAc_LCTRL.getDocumentsAndIACs(irq.Id, studentCon.Id, new List<String> {'Name'});
            DocumentsAndIACWrapper responseData = (DocumentsAndIACWrapper) JSON.deserialize(responseResult.responseData, DocumentsAndIACWrapper.class);

            //iac
            Integer iacSizeCounter = 0;
            for(reduivy__Individual_Achievement__c iac : responseData.RESPONSE_IAC_LIST) {
                System.Assert.isTrue(expectedIacMap.containsKey(iac.Id), 'IAC ' + iac.Name + ' Should be existing in the list!');
                iacSizeCounter++;
            }

            System.Assert.areEqual(expectedIacMap.size(), iacSizeCounter);
            System.Assert.areEqual(2, iacSizeCounter, 'Wrong iac size!');

            //cdc
            Integer cdcSizeCounter = 0;
            for(ContentDocument cdc : responseData.RESPONSE_CDC_LIST) {
                System.Assert.isTrue(expectedCdcMap.containsKey(cdc.Id), 'CDC ' + cdc.Title + ' Should be existing in the list!');
                cdcSizeCounter++;
            }

            System.Assert.areEqual(expectedCdcMap.size(), cdcSizeCounter);
            System.Assert.areEqual(2, cdcSizeCounter, 'Wrong cdc size!');

            //cdc iac map
            Integer cdcIacMap_cdcSizeCounter = 0;
            for(Id cdcId : responseData.RESPONSE_CDC_IAC_MAP.keySet()) {
                Set<Id> iacIdSet = responseData.RESPONSE_CDC_IAC_MAP.get(cdcId);
                System.Assert.areEqual(0, iacIdSet.size(), 'wrong CDC_IAC_MAP iac id set size!');
                cdcIacMap_cdcSizeCounter++;
            }

            System.Assert.areEqual(2, cdcIacMap_cdcSizeCounter);
            

            //cdciac cdlid map
            List<ContentDocumentLink> expectedCdlList = queryCdlList();
            for(ContentDocumentLink expectedCdl : expectedCdlList) {
                String key = expectedCdl.ContentDocumentId + '_' + expectedCdl.LinkedEntityId;
                System.Assert.isTrue(
                    responseData.RESPONSE_CDCIAC_CDLID_MAP.containsKey(key),
                    'CDCIAC_CDLID_MAP should contains the key ' + key + '!'
                );
                System.Assert.areEqual(expectedCdl.Id, responseData.RESPONSE_CDCIAC_CDLID_MAP.get(key), 'Wrong cdl id!');
            }


		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for getting data related to linking to iac, has document linked to iac
     */
    @IsTest
    static void testForGet_HasLinkToIac_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setIrq();
        setCon();

        
		System.runAs(ADMIN_USER){
            insertContentAndLink();
            Map<Id, reduivy__Individual_Achievement__c> expectedIacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList());
            Map<Id, ContentDocument> expectedCdcMap = new Map<Id, ContentDocument>(queryCdcList(true, true));
            
            //insert new content document link
            reduivy__Individual_Achievement__c newLinkIac = expectedIacMap.values()[0];
            ContentDocument newLinkCdc = expectedCdcMap.values()[0];
            ContentDocumentLink newCdl = new ContentDocumentLink(ContentDocumentId = newLinkCdc.Id, LinkedEntityId = newLinkIac.Id);
            insert newCdl;
            

            REDU_LightningResponse responseResult = REDU_RequirementChecklistIdvAc_LCTRL.getDocumentsAndIACs(irq.Id, studentCon.Id, new List<String> {'Name'});
            DocumentsAndIACWrapper responseData = (DocumentsAndIACWrapper) JSON.deserialize(responseResult.responseData, DocumentsAndIACWrapper.class);

            //iac
            Integer iacSizeCounter = 0;
            for(reduivy__Individual_Achievement__c iac : responseData.RESPONSE_IAC_LIST) {
                System.Assert.isTrue(expectedIacMap.containsKey(iac.Id), 'IAC ' + iac.Name + ' Should be existing in the list!');
                iacSizeCounter++;
            }

            System.Assert.areEqual(expectedIacMap.size(), iacSizeCounter);
            System.Assert.areEqual(2, iacSizeCounter, 'Wrong iac size!');

            //cdc
            Integer cdcSizeCounter = 0;
            for(ContentDocument cdc : responseData.RESPONSE_CDC_LIST) {
                System.Assert.isTrue(expectedCdcMap.containsKey(cdc.Id), 'CDC ' + cdc.Title + ' Should be existing in the list!');
                cdcSizeCounter++;
            }

            System.Assert.areEqual(expectedCdcMap.size(), cdcSizeCounter);
            System.Assert.areEqual(2, cdcSizeCounter, 'Wrong cdc size!');

            //cdc iac map
            Integer cdcIacMap_cdcSizeCounter = 0;
            for(Id cdcId : responseData.RESPONSE_CDC_IAC_MAP.keySet()) {
                Set<Id> iacIdSet = responseData.RESPONSE_CDC_IAC_MAP.get(cdcId);

                if(cdcId == newLinkCdc.Id) {
                    System.Assert.isTrue(iacIdSet.contains(newLinkIac.Id), 'ContentDocument should be linked to the iac!');
                    System.Assert.areEqual(1, iacIdSet.size(), 'Wrong size of ContentDocument that has been linked to the iac!');
                } else {
                    System.Assert.areEqual(0, iacIdSet.size(), 'wrong CDC_IAC_MAP iac id set size!');
                }
                cdcIacMap_cdcSizeCounter++;
            }

            System.Assert.areEqual(2, cdcIacMap_cdcSizeCounter);
            

            //cdciac cdlid map
            List<ContentDocumentLink> expectedCdlList = queryCdlList();
            for(ContentDocumentLink expectedCdl : expectedCdlList) {
                String key = expectedCdl.ContentDocumentId + '_' + expectedCdl.LinkedEntityId;
                System.Assert.isTrue(
                    responseData.RESPONSE_CDCIAC_CDLID_MAP.containsKey(key),
                    'CDCIAC_CDLID_MAP should contains the key ' + key + '!'
                );
                System.Assert.areEqual(expectedCdl.Id, responseData.RESPONSE_CDCIAC_CDLID_MAP.get(key), 'Wrong cdl id!');
            }


		}

        Test.stopTest();
		
    }

    /**
     * @description test as admin for insert cdl
     */
    @IsTest
    static void testForInsertCdl_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setIrq();
        setCon();

        System.runAs(ADMIN_USER){
            insertContentAndLink();
            Map<Id, reduivy__Individual_Achievement__c> expectedIacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList());
            Map<Id, ContentDocument> expectedCdcMap = new Map<Id, ContentDocument>(queryCdcList(true, true));

            //insert new content document link
            reduivy__Individual_Achievement__c newLinkIac = expectedIacMap.values()[0];
            ContentDocument newLinkCdc = expectedCdcMap.values()[0];
            Map<String, List<String>> cdcToLinkToIacList = new Map<String, List<String>>{
                newLinkCdc.Id => new List<String> {newLinkIac.Id}
            };

            REDU_RequirementChecklistIdvAc_LCTRL.insertAndDeleteCdl(null, JSON.serialize(cdcToLinkToIacList));
            
            List<ContentDocumentLink> insertedCdl = [
                SELECT Id, LinkedEntityId, ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :newLinkIac.Id 
                AND ContentDocumentId = : newLinkCdc.Id
            ];

            System.Assert.isFalse(insertedCdl.isEmpty(), 'insertedCdl should not be empty!');

            
        }
        

        Test.stopTest();
    }

    /**
     * @description test as admin for delete cdl
     */
    @IsTest
    static void testForDeleteCdl_AsAdmin() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        setIrq();
        setCon();

        System.runAs(ADMIN_USER){
            insertContentAndLink();
            Map<Id, reduivy__Individual_Achievement__c> expectedIacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList());
            Map<Id, ContentDocument> expectedCdcMap = new Map<Id, ContentDocument>(queryCdcList(true, true));

            //insert new content document link
            reduivy__Individual_Achievement__c newLinkIac = expectedIacMap.values()[0];
            ContentDocument newLinkCdc = expectedCdcMap.values()[0];
            ContentDocumentLink newCdl = new ContentDocumentLink(ContentDocumentId = newLinkCdc.Id, LinkedEntityId = newLinkIac.Id);
            insert newCdl;

            //confirm that it is in the db
            List<ContentDocumentLink> insertedCdl = [
                SELECT Id, LinkedEntityId, ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :newLinkIac.Id 
                AND ContentDocumentId = : newLinkCdc.Id
            ];

            System.Assert.isFalse(insertedCdl.isEmpty(), 'insertedCdl should not be empty!');

            REDU_RequirementChecklistIdvAc_LCTRL.insertAndDeleteCdl(new List<String>{ newCdl.Id }, null);
            
            List<ContentDocumentLink> deletedCdl = [
                SELECT Id, LinkedEntityId, ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :newLinkIac.Id 
                AND ContentDocumentId = : newLinkCdc.Id
            ];

            System.Assert.isTrue(deletedCdl.isEmpty(), 'deletedCdl should be empty!');

            
        }
        

        Test.stopTest();
    }
	
    /**
     * @description Test as faculty for getting data related to linking to iac, no document linked to iac
     */
    @IsTest
    static void testFor_NoLinkToIac_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        setIrq();
        setCon();

        
		System.runAs(FACULTY_USER){
            insertContentAndLink();
            Map<Id, reduivy__Individual_Achievement__c> expectedIacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList());
            Map<Id, ContentDocument> expectedCdcMap = new Map<Id, ContentDocument>(queryCdcList(true, true));

            REDU_LightningResponse responseResult = REDU_RequirementChecklistIdvAc_LCTRL.getDocumentsAndIACs(irq.Id, studentCon.Id, new List<String> {'Name'});
            DocumentsAndIACWrapper responseData = (DocumentsAndIACWrapper) JSON.deserialize(responseResult.responseData, DocumentsAndIACWrapper.class);

            //iac
            Integer iacSizeCounter = 0;
            for(reduivy__Individual_Achievement__c iac : responseData.RESPONSE_IAC_LIST) {
                System.Assert.isTrue(expectedIacMap.containsKey(iac.Id), 'IAC ' + iac.Name + ' Should be existing in the list!');
                iacSizeCounter++;
            }

            System.Assert.areEqual(expectedIacMap.size(), iacSizeCounter);
            System.Assert.areEqual(2, iacSizeCounter, 'Wrong iac size!');

            //cdc
            Integer cdcSizeCounter = 0;
            for(ContentDocument cdc : responseData.RESPONSE_CDC_LIST) {
                System.Assert.isTrue(expectedCdcMap.containsKey(cdc.Id), 'CDC ' + cdc.Title + ' Should be existing in the list!');
                cdcSizeCounter++;
            }

            System.Assert.areEqual(expectedCdcMap.size(), cdcSizeCounter);
            System.Assert.areEqual(2, cdcSizeCounter, 'Wrong cdc size!');

            //cdc iac map
            Integer cdcIacMap_cdcSizeCounter = 0;
            for(Id cdcId : responseData.RESPONSE_CDC_IAC_MAP.keySet()) {
                Set<Id> iacIdSet = responseData.RESPONSE_CDC_IAC_MAP.get(cdcId);
                System.Assert.areEqual(0, iacIdSet.size(), 'wrong CDC_IAC_MAP iac id set size!');
                cdcIacMap_cdcSizeCounter++;
            }

            System.Assert.areEqual(2, cdcIacMap_cdcSizeCounter);
            

            //cdciac cdlid map
            List<ContentDocumentLink> expectedCdlList = queryCdlList();
            for(ContentDocumentLink expectedCdl : expectedCdlList) {
                String key = expectedCdl.ContentDocumentId + '_' + expectedCdl.LinkedEntityId;
                System.Assert.isTrue(
                    responseData.RESPONSE_CDCIAC_CDLID_MAP.containsKey(key),
                    'CDCIAC_CDLID_MAP should contains the key ' + key + '!'
                );
                System.Assert.areEqual(expectedCdl.Id, responseData.RESPONSE_CDCIAC_CDLID_MAP.get(key), 'Wrong cdl id!');
            }


		}

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for getting data related to linking to iac, has document linked to iac
     */
    @IsTest
    static void testForGet_HasLinkToIac_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        setIrq();
        setCon();

        
		System.runAs(FACULTY_USER){
            insertContentAndLink();
            Map<Id, reduivy__Individual_Achievement__c> expectedIacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList());
            Map<Id, ContentDocument> expectedCdcMap = new Map<Id, ContentDocument>(queryCdcList(true, true));
            
            //insert new content document link
            reduivy__Individual_Achievement__c newLinkIac = expectedIacMap.values()[0];
            ContentDocument newLinkCdc = expectedCdcMap.values()[0];
            ContentDocumentLink newCdl = new ContentDocumentLink(ContentDocumentId = newLinkCdc.Id, LinkedEntityId = newLinkIac.Id);
            insert newCdl;
            

            REDU_LightningResponse responseResult = REDU_RequirementChecklistIdvAc_LCTRL.getDocumentsAndIACs(irq.Id, studentCon.Id, new List<String> {'Name'});
            DocumentsAndIACWrapper responseData = (DocumentsAndIACWrapper) JSON.deserialize(responseResult.responseData, DocumentsAndIACWrapper.class);

            //iac
            Integer iacSizeCounter = 0;
            for(reduivy__Individual_Achievement__c iac : responseData.RESPONSE_IAC_LIST) {
                System.Assert.isTrue(expectedIacMap.containsKey(iac.Id), 'IAC ' + iac.Name + ' Should be existing in the list!');
                iacSizeCounter++;
            }

            System.Assert.areEqual(expectedIacMap.size(), iacSizeCounter);
            System.Assert.areEqual(2, iacSizeCounter, 'Wrong iac size!');

            //cdc
            Integer cdcSizeCounter = 0;
            for(ContentDocument cdc : responseData.RESPONSE_CDC_LIST) {
                System.Assert.isTrue(expectedCdcMap.containsKey(cdc.Id), 'CDC ' + cdc.Title + ' Should be existing in the list!');
                cdcSizeCounter++;
            }

            System.Assert.areEqual(expectedCdcMap.size(), cdcSizeCounter);
            System.Assert.areEqual(2, cdcSizeCounter, 'Wrong cdc size!');

            //cdc iac map
            Integer cdcIacMap_cdcSizeCounter = 0;
            for(Id cdcId : responseData.RESPONSE_CDC_IAC_MAP.keySet()) {
                Set<Id> iacIdSet = responseData.RESPONSE_CDC_IAC_MAP.get(cdcId);

                if(cdcId == newLinkCdc.Id) {
                    System.Assert.isTrue(iacIdSet.contains(newLinkIac.Id), 'ContentDocument should be linked to the iac!');
                    System.Assert.areEqual(1, iacIdSet.size(), 'Wrong size of ContentDocument that has been linked to the iac!');
                } else {
                    System.Assert.areEqual(0, iacIdSet.size(), 'wrong CDC_IAC_MAP iac id set size!');
                }
                cdcIacMap_cdcSizeCounter++;
            }

            System.Assert.areEqual(2, cdcIacMap_cdcSizeCounter);
            

            //cdciac cdlid map
            List<ContentDocumentLink> expectedCdlList = queryCdlList();
            for(ContentDocumentLink expectedCdl : expectedCdlList) {
                String key = expectedCdl.ContentDocumentId + '_' + expectedCdl.LinkedEntityId;
                System.Assert.isTrue(
                    responseData.RESPONSE_CDCIAC_CDLID_MAP.containsKey(key),
                    'CDCIAC_CDLID_MAP should contains the key ' + key + '!'
                );
                System.Assert.areEqual(expectedCdl.Id, responseData.RESPONSE_CDCIAC_CDLID_MAP.get(key), 'Wrong cdl id!');
            }


		}

        Test.stopTest();
		
    }

    /**
     * @description test as faculty for insert cdl
     */
    @IsTest
    static void testForInsertCdl_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        setIrq();
        setCon();

        System.runAs(FACULTY_USER){
            insertContentAndLink();
            Map<Id, reduivy__Individual_Achievement__c> expectedIacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList());
            Map<Id, ContentDocument> expectedCdcMap = new Map<Id, ContentDocument>(queryCdcList(true, true));

            //insert new content document link
            reduivy__Individual_Achievement__c newLinkIac = expectedIacMap.values()[0];
            ContentDocument newLinkCdc = expectedCdcMap.values()[0];
            Map<String, List<String>> cdcToLinkToIacList = new Map<String, List<String>>{
                newLinkCdc.Id => new List<String> {newLinkIac.Id}
            };

            REDU_RequirementChecklistIdvAc_LCTRL.insertAndDeleteCdl(null, JSON.serialize(cdcToLinkToIacList));
            
            List<ContentDocumentLink> insertedCdl = [
                SELECT Id, LinkedEntityId, ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :newLinkIac.Id 
                AND ContentDocumentId = : newLinkCdc.Id
            ];

            System.Assert.isFalse(insertedCdl.isEmpty(), 'insertedCdl should not be empty!');

            
        }
        

        Test.stopTest();
    }

    /**
     * @description test as faculty for delete cdl
     */
    @IsTest
    static void testForDeleteCdl_AsFaculty() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        setIrq();
        setCon();

        System.runAs(FACULTY_USER){
            insertContentAndLink();
            Map<Id, reduivy__Individual_Achievement__c> expectedIacMap = new Map<Id, reduivy__Individual_Achievement__c>(queryIacList());
            Map<Id, ContentDocument> expectedCdcMap = new Map<Id, ContentDocument>(queryCdcList(true, true));

            //insert new content document link
            reduivy__Individual_Achievement__c newLinkIac = expectedIacMap.values()[0];
            ContentDocument newLinkCdc = expectedCdcMap.values()[0];
            ContentDocumentLink newCdl = new ContentDocumentLink(ContentDocumentId = newLinkCdc.Id, LinkedEntityId = newLinkIac.Id);
            insert newCdl;

            //confirm that it is in the db
            List<ContentDocumentLink> insertedCdl = [
                SELECT Id, LinkedEntityId, ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :newLinkIac.Id 
                AND ContentDocumentId = : newLinkCdc.Id
            ];

            System.Assert.isFalse(insertedCdl.isEmpty(), 'insertedCdl should not be empty!');

            REDU_RequirementChecklistIdvAc_LCTRL.insertAndDeleteCdl(new List<String>{ newCdl.Id }, null);
            
            List<ContentDocumentLink> deletedCdl = [
                SELECT Id, LinkedEntityId, ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :newLinkIac.Id 
                AND ContentDocumentId = : newLinkCdc.Id
            ];

            System.Assert.isTrue(deletedCdl.isEmpty(), 'deletedCdl should be empty!');

            
        }
        

        Test.stopTest();
    }

    // /**
    //  * @description Test as student for getting data related to linking to iac, no document linked to iac
    //  */
    // @IsTest
    // static void testFor_NoLinkToIac_AsStudent() {
    // // Following error returned when trying to create content version as a community user. NetworkId is required but community may not be available yet.
    // // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.: [NetworkId]
		
    // }

    // /**
    //  * @description Test as student for getting data related to linking to iac, has document linked to iac
    //  */
    // @IsTest
    // static void testForGet_HasLinkToIac_AsStudent() {
    // // Following error returned when trying to create content version as a community user. NetworkId is required but community may not be available yet.
    // // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.: [NetworkId]
		
    // }

    // /**
    //  * @description test as student for insert cdl
    //  */
    // @IsTest
    // static void testForInsertCdl_AsStudent() {
    // // Following error returned when trying to create content version as a community user. NetworkId is required but community may not be available yet.
    // // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.: [NetworkId]
		
    // }

    // /**
    //  * @description test as student for delete cdl
    //  */
    // @IsTest
    // static void testForDeleteCdl_AsStudent() {
    // // Following error returned when trying to create content version as a community user. NetworkId is required but community may not be available yet.
    // // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.: [NetworkId]
		
    // }

    static void setIrq(){
        irq = [
            SELECT Id, Name, reduivy__Status__c, reduivy__Submission_Status__c, reduivy__Review_Status__c, reduivy__Submission_Date__c, reduivy__Review_Date__c, reduivy__Object_Relation_Field__c, reduivy__Object_Fields__c, reduivy__Link_To_Individual_Achievement__c
            FROM reduivy__Individual_Requirement__c
            LIMIT 1
        ];
    }

    static void setCon(){
        studentCon = [
            SELECT Id, Name
            FROM Contact
            WHERE reduivy__Sample_Record_Code__c = :SRC_STUDENT_CON
            LIMIT 1
        ];
    }

    static List<reduivy__Individual_Achievement__c> queryIacList(){
        return [ 
            SELECT Id, Name
            FROM reduivy__Individual_Achievement__c
            WHERE reduivy__Contact__c = :studentCon.Id
        ];
    }

    static List<ContentDocument> queryCdcList(Boolean queryCdc1, Boolean queryCdc2){
        return [
            SELECT Id, Title FROM ContentDocument
        ];
    }

    static List<ContentDocumentLink> queryCdlList() {
        return [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :irq.Id
        ];
    }

    static void insertContentAndLink(){
        Blob cvsBody1 = Blob.valueOf('data:image/gif;base64,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');
        Blob cvsBody2 = Blob.valueOf('data:image/gif;base64,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');

        ContentVersion cvs1 = new ContentVersion();
        cvs1.Title = SRC_CVS1;
        cvs1.VersionData = cvsBody1;
        cvs1.PathOnClient = '/' + cvs1.Title;
        
        ContentVersion cvs2 = new ContentVersion();
        cvs2.Title = SRC_CVS2;
        cvs2.VersionData = cvsBody2;
        cvs2.PathOnClient = '/' + cvs2.Title;
        
        insert new List<ContentVersion> {cvs1, cvs2};


        ContentVersion insertedCvs1, insertedCvs2;
        for(ContentVersion cvs : [SELECT Id, ContentDocumentId, reduivy__File_Category__c, Title FROM ContentVersion WHERE Id IN (:cvs1.Id, :cvs2.Id)]) {
            if(cvs.Title == SRC_CVS1) {
                insertedCvs1 = cvs;
            } else {
                insertedCvs2 = cvs;
            }
        }

        ContentDocumentLink irqCdl1 = new ContentDocumentLink();
        irqCdl1.ContentDocumentId = insertedCvs1.ContentDocumentId;
        irqCdl1.LinkedEntityId = irq.Id;
        irqCdl1.ShareType = 'V';
        irqCdl1.Visibility = 'InternalUsers';
        
        
        ContentDocumentLink irqCdl2 = new ContentDocumentLink();
        irqCdl2.ContentDocumentId = insertedCvs2.ContentDocumentId;
        irqCdl2.LinkedEntityId = irq.Id;
        irqCdl2.ShareType = 'V';
        irqCdl2.Visibility = 'InternalUsers';

        insert new List<ContentDocumentLink> {irqCdl1, irqCdl2};
    }

    class DocumentsAndIACWrapper{
        public List<ContentDocument> RESPONSE_CDC_LIST;
        public List<reduivy__Individual_Achievement__c> RESPONSE_IAC_LIST; 
        public Map<Id, Set<Id>> RESPONSE_CDC_IAC_MAP;
        public Map<String, Id> RESPONSE_CDCIAC_CDLID_MAP;

    }

	
}
